#!/bin/bash

# 0. Workaround for vagrant boxes
sed -i "s/10.0.2.3/8.8.8.8/g" /etc/resolv.conf

# 0.1 Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install Logical Volume Manager
yum update
yum install -y lvm2

# 1.1 Enable the LVM services
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service

# 2. Create a partition based on other partition
cat <<EOL > sdb.layout
# partition table of /dev/sdb
unit: sectors

/dev/sdb1 : start=     2048, size= 83884032, Id=83, bootable
/dev/sdb2 : start=        0, size=        0, Id= 0
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOL
sfdisk /dev/sdb < sdb.layout

# 3. Create the LVM physical volume /dev/sdb1
pvcreate /dev/sdb1

# 4. Create the LVM volume group cinder-volumes
vgcreate cinder-volumes /dev/sdb1

# 5. Add a filter that accepts the /dev/sdb device and rejects all other devices
sed -i "s/filter = \[ \"a\/.*\/\"/filter = \[ \"a\/sdb\/\", \"r\/.\*\/\"/g" /etc/lvm/lvm.conf

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-cinder targetcli python-oslo-db MySQL-python

# 2. Configure Database driver
crudini --set /etc/cinder/cinder.conf database connection  mysql://cinder:secure@database/cinder

# 3. Configure message broker service
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_host message-broker
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_password secure

# 4. Configure Identity Service
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://identity:5000/v2.0
crudini --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://identity:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_password secure

crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/cinder/cinder.conf DEFAULT glance_host image
#crudini --set /etc/cinder/cinder.conf DEFAULT iscsi_helper lioadm
crudini --set /etc/cinder/cinder.conf DEFAULT iscsi_helper tgtadm

# 5. Start services
systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service
