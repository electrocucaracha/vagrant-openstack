#!/bin/bash

# 1. Database creation
mongo --host ${NOSQL_DATABASE_HOSTNAME} --eval "
db = db.getSiblingDB(\"ceilometer\");
db.addUser({user: \"ceilometer\",
pwd: \"${CEILOMETER_DBPASS}\",
roles: [ \"readWrite\", \"dbAdmin\" ]})"

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create ceilometer --password=${CEILOMETER_PASS} --email=ceilometer@example.com
openstack role add admin --user=ceilometer --project=service
openstack service create metering --name=ceilometer --description="OpenStack Telemetry Service"
openstack endpoint create \
  --publicurl=http://${TELEMETRY_CONTROLLER_HOSTNAME}:8777 \
  --internalurl=http://${TELEMETRY_CONTROLLER_HOSTNAME}:8777 \
  --adminurl=http://${TELEMETRY_CONTROLLER_HOSTNAME}:8777 \
  --region regionOne \
  metering

tail -n +2 /etc/ceilometer/ceilometer.conf > /etc/ceilometer/ceilometer.conf

# 3. Configure service
crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:${CEILOMETER_DBPASS}@${NOSQL_DATABASE_HOSTNAME}:27017/ceilometer

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken identity_uri http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user admin
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password ${ADMIN_PASS}

crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password ${CEILOMETER_PASS}
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name regionOne

crudini --set /etc/ceilometer/ceilometer.conf publisher telemetry_secret ${token}

# Enable OSProfiler
if [ ! -z ${ENABLE_PROFILER} ] && [ ${ENABLE_PROFILER} == "True" ]; then
  crudini --set /etc/ceilometer/ceilometer.conf DEFAULT notification_topics notifications,profiler
fi
