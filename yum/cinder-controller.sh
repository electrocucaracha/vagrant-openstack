#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install OpenStack Block Storage Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-cinder python-cinderclient python-oslo-db

# 1.1 Workaround for cinder-api dependency
yum install -y python-keystonemiddleware

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

# 5. Generate tables
su -s /bin/sh -c "cinder-manage db sync" cinder

# 6. Enable and start services
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
