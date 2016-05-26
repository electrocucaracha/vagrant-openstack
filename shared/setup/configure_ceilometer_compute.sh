#!/bin/bash

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
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken password ${CEILOMETER_PASS}

# Configure service credentials
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password ${CEILOMETER_PASS}
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_endpoint_type internalURL
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_region_name RegionOne

# Configure notifications
crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
crudini --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
crudini --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
crudini --set /etc/nova/nova.conf DEFAULT notification_driver messagingv2
