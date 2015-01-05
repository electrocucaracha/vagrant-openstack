#!/bin/bash

# 0. Workaround for vagrant boxes
sed -i "s/10.0.2.3/8.8.8.8/g" /etc/resolv.conf

# 0.1 Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

# 2. Configure Nova Service
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_host 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_port 6080
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host message-broker
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password secure
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone

# 3. Configure Database driver
crudini --set /etc/nova/nova.conf database connection mysql://nova:secure@database/nova

# 4. Configure Authentication
crudini --set /etc/nova/nova.conf keystone_authtoken identity_uri http://identity:35357
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password secure

crudini --set /etc/nova/nova.conf paste_deploy flavor keystone

crudini --set /etc/nova/nova.conf glance host image

# 5. Generate tables
su -s /bin/sh -c "nova-manage db sync" nova

# 6. Enable and start services
systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
