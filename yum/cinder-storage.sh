#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install Logical Volume Manager
yum update -y
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
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-selinux deltarpm
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-cinder targetcli python-oslo-db MySQL-python

./configure_cinder_storage.sh

# Block storage - Telemetry services

./configure_ceilometer_block_storage.sh

# 5. Start services
systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service
