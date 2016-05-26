#!/bin/bash

# Create the ceilometer database
mongo --host ${NOSQL_DATABASE_HOSTNAME} --eval "
db = db.getSiblingDB(\"ceilometer\");
db.addUser({user: \"ceilometer\",
pwd: \"${CEILOMETER_DBPASS}\",
roles: [ \"readWrite\", \"dbAdmin\" ]})"

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# Create the ceilometer user
openstack user create ceilometer --domain default --password=${CEILOMETER_PASS} --email=ceilometer@example.com

# Add the admin role to the ceilometer user
openstack role add admin --user=ceilometer --project=service

# Create the ceilometer service entity
openstack service create --name ceilometer \
  --description "Telemetry" metering

# Create the Telemetry module API endpoint
openstack endpoint create --region RegionOne \
  metering public http://${TELEMETRY_CONTROLLER_HOSTNAME}:8777
openstack endpoint create --region RegionOne \
  metering internal http://${TELEMETRY_CONTROLLER_HOSTNAME}:8777
openstack endpoint create --region RegionOne \
  metering admin http://${TELEMETRY_CONTROLLER_HOSTNAME}:8777

#tail -n +2 /etc/ceilometer/ceilometer.conf > /etc/ceilometer/ceilometer.conf

# Configure database access
crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:${CEILOMETER_DBPASS}@${NOSQL_DATABASE_HOSTNAME}:27017/ceilometer

# Configure RabbitMQ message queue access
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken password ${ADMIN_PASS}

# Configure service credentials
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password ${CEILOMETER_PASS}
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name RegionOne

# Enable OSProfiler
if [ ! -z ${ENABLE_PROFILER} ] && [ ${ENABLE_PROFILER} == "True" ]; then
  crudini --set /etc/ceilometer/ceilometer.conf DEFAULT notification_topics notifications,profiler
fi
