#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_group.sh
echo "source /root/shared/openstackrc-group" >> /root/.bashrc

# 1. Install OpenStack Identity Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-keystone python-keystoneclient

# 2. Configure Database driver
crudini --set /etc/keystone/keystone.conf database connection  mysql://keystone:secure@supporting-services/keystone

# 3. Generate certificates and restrict access
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl

# 4. Generate tables
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 5. Configurate authorization token
token=`openssl rand -hex 10`
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token ${token}

# 6. Restart service
systemctl enable openstack-keystone.service
systemctl start openstack-keystone.service

sleep 5
export SERVICE_TOKEN="${token}"
export SERVICE_ENDPOINT=http://controller-services:35357/v2.0

# 7. Create OpenStack tenants
keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"

# 8. Create OpenStack roles
keystone role-create --name=admin

# 9. Create OpenStack users

# 9.1 Keystone user
keystone user-create --name=admin --pass=secure --email=admin@example.com
keystone user-role-add --user=admin --tenant=admin --role=admin

# 9.2 Glance user
keystone user-create --name=glance --pass=secure --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin

# 9.3 Nova user
keystone user-create --name=nova --pass=secure --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin

# 9.4 Cinder user
keystone user-create --name=cinder --pass=secure --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

# 9.5 Ceilometer user
keystone user-create --name=ceilometer --pass=secure --email=ceilometer@example.com
keystone user-role-add --user=ceilometer --tenant=service --role=admin

# 10. Create OpenStack services

# 10.1 Keystone service
keystone service-create --name=keystone --type=identity --description="OpenStack Identity Service"

# 10.2 Glance service
keystone service-create --name=glance --type=image --description="OpenStack Image Service"

# 10.3 Nova service
keystone service-create --name=nova --type=compute --description="OpenStack Compute Service"

# 10.4 Cinder service
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage Service"
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage Service"

# 10.5 Ceilometer service
keystone service-create --name=ceilometer --type=metering --description="OpenStack Metering Service"

# 11. Create OpenStack endpoints

# 11.1 Keystone endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl=http://controller-services:5000/v2.0 \
  --internalurl=http://controller-services:5000/v2.0 \
  --adminurl=http://controller-services:35357/v2.0 \
  --region=regionOne

# 11.2 Glance endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ image / {print $2}') \
  --publicurl=http://controller-services:9292 \
  --internalurl=http://controller-services:9292 \
  --adminurl=http://controller-services:9292 \
  --region=regionOne

# 11.3 Nova endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl=http://controller-services:8774/v2/%\(tenant_id\)s \
  --internalurl=http://controller-services:8774/v2/%\(tenant_id\)s \
  --adminurl=http://controller-services:8774/v2/%\(tenant_id\)s \
  --region=regionOne

# 11.4 Cinder endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volume / {print $2}') \
  --publicurl=http://controller-services:8776/v1/%\(tenant_id\)s \
  --internalurl=http://controller-services:8776/v1/%\(tenant_id\)s \
  --adminurl=http://controller-services:8776/v1/%\(tenant_id\)s \
  --region=regionOne

keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
  --publicurl=http://controller-services:8776/v2/%\(tenant_id\)s \
  --internalurl=http://controller-services:8776/v2/%\(tenant_id\)s \
  --adminurl=http://controller-services:8776/v2/%\(tenant_id\)s \
  --region=regionOne

# 11.5 Ceilometer endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ metering / {print $2}') \
  --publicurl=http://controller-services:8777 \
  --internalurl=http://controller-services:8777 \
  --adminurl=http://controller-services:8777 \
  --region=regionOne

# Image services

# 1. Install OpenStack Identity Service and dependencies
yum install -y openstack-glance python-glanceclient

# 2. Configure api service
crudini --set /etc/glance/glance-api.conf database connection  mysql://glance:secure@supporting-services/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller-services:5000/v2.0
crudini --set /etc/glance/glance-api.conf keystone_authtoken identity_uri http://controller-services:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_password secure
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

# 3. Configure registry service
crudini --set /etc/glance/glance-registry.conf database connection  mysql://glance:secure@supporting-services/glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller-services:5000/v2.0
crudini --set /etc/glance/glance-registry.conf keystone_authtoken identity_uri http://controller-services:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_password secure
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

# 4. Generate tables
su -s /bin/sh -c "glance-manage db_sync" glance

# 5. Enable and start services
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

# 6. Include default image
source /root/.bashrc
wget http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
glance image-create --name cirrus --file cirros-0.3.3-x86_64-disk.img --disk-format qcow2  --container-format bare --is-public True

# Compute controller services

# 1. Install OpenStack Compute Service and dependencies
yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

# 2. Configure Nova Service
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_host 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_port 6080
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host supporting-services
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password secure
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone

# 3. Configure Database driver
crudini --set /etc/nova/nova.conf database connection mysql://nova:secure@supporting-services/nova

# 4. Configure Authentication
crudini --set /etc/nova/nova.conf keystone_authtoken identity_uri http://controller-services:35357
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password secure

crudini --set /etc/nova/nova.conf paste_deploy flavor keystone

crudini --set /etc/nova/nova.conf glance host controller-services

# 5. Generate tables
su -s /bin/sh -c "nova-manage db sync" nova

# 6. Enable and start services
systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

# OpenStack Dashboard

# 1. Install OpenStack Compute Service and dependencies
yum install -y openstack-dashboard httpd mod_wsgi memcached python-memcached

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"controller-services\"/g" /etc/openstack-dashboard/local_settings

# 3. Configure memcached
sed -i "s/'django.core.cache.backends.locmem.LocMemCache'/'django.core.cache.backends.memcached.MemcachedCache',\n        'LOCATION': '127.0.0.1:11211'/g" /etc/openstack-dashboard/local_settings

# 4. Configure SELinux to permit the web server to connect
setsebool -P httpd_can_network_connect on

# 5. Solve the CSS issue
chown -R apache:apache /usr/share/openstack-dashboard/static

# 6. Enable services
systemctl enable httpd.service memcached.service
systemctl start httpd.service memcached.service

# Block storage service

# 1. Install OpenStack Block Storage Service and dependencies
yum install -y openstack-cinder python-cinderclient python-oslo-db

# 1.1 Workaround for cinder-api dependency
yum install -y python-keystonemiddleware

# 2. Configure Database driver
crudini --set /etc/cinder/cinder.conf database connection  mysql://cinder:secure@supporting-services/cinder

# 3. Configure message broker service
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_host supporting-services
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_password secure

# 4. Configure Identity Service
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://controller-services:5000/v2.0
crudini --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://controller-services:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_password secure

crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}

# 5. Generate tables
su -s /bin/sh -c "cinder-manage db sync" cinder

# 6. Enable and start services
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service

# Telemetry service

# 1. Install OpenStack Telemetry Service and dependencies
yum install -y openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central openstack-ceilometer-alarm python-ceilometerclient

# 2. Configure database connection
crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:secure@supporting-services:27017/ceilometer

# 3. Configure message broker connection
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_host supporting-services
crudini --set /etc/ceilometer/ceilometer.conf rabbit_password secure
crudini --set /etc/ceilometer/ceilometer.conf auth_strategy keystone

# 4. Configure authentication
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://controller-services:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken identity_uri http://controller-services:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user ceilometer
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password secure

# 5 Configure service credentials
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://controller-services:35357
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password secure

token=`openssl rand -hex 10`
crudini --set /etc/ceilometer/ceilometer.conf publisher metering_secret ${token}

systemctl enable openstack-ceilometer-api.service openstack-ceilometer-notification.service  openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service
systemctl start openstack-ceilometer-api.service openstack-ceilometer-notification.service openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service
