#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install OpenStack Identity Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-glance python-glanceclient

# 2. Configure api service
crudini --set /etc/glance/glance-api.conf database connection  mysql://glance:secure@database/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://identity:5000/v2.0
crudini --set /etc/glance/glance-api.conf keystone_authtoken identity_uri http://identity:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_password secure
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

# 3. Configure registry service
crudini --set /etc/glance/glance-registry.conf database connection  mysql://glance:secure@database/glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://identity:5000/v2.0
crudini --set /etc/glance/glance-registry.conf keystone_authtoken identity_uri http://identity:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_password secure
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

# 4. Generate tables
su -s /bin/sh -c "glance-manage db_sync" glance

# 5. Enable and start services
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service
