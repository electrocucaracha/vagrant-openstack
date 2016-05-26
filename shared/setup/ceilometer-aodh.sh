#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# Create the aodh user
openstack user create aodh --domain default --password=${AODH_PASS} --email=aodh@example.com

# Add the admin role to the aodh user
openstack role add admin --user=aodh --project=service

# Create the aodh service entity
openstack service create --name aodh \
  --description "Telemetry" alarming

# Create the Telemetry module API endpoint
openstack endpoint create --region RegionOne \
  alarming public http://${ALARMING_HOSTNAME}:8042
openstack endpoint create --region RegionOne \
  alarming internal http://${ALARMING_HOSTNAME}:8042
openstack endpoint create --region RegionOne \
  alarming admin http://${ALARMING_HOSTNAME}:8042

# Configure database access
crudini --set /etc/aodh/aodh.conf database connection mysql+pymysql://aodh:${CEILOMETER_DBPASS}@${NOSQL_DATABASE_HOSTNAME}/aodh

# Configure RabbitMQ message queue access
crudini --set /etc/aodh/aodh.conf DEFAULT rpc_backend rabbit
crudini --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/aodh/aodh.conf DEFAULT auth_strategy keystone
crudini --set /etc/aodh/aodh.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/aodh/aodh.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/aodh/aodh.conf keystone_authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/aodh/aodh.conf keystone_authtoken auth_type password
crudini --set /etc/aodh/aodh.conf keystone_authtoken project_domain_name default
crudini --set /etc/aodh/aodh.conf keystone_authtoken user_domain_name default
crudini --set /etc/aodh/aodh.conf keystone_authtoken project_name service
crudini --set /etc/aodh/aodh.conf keystone_authtoken username aodh
crudini --set /etc/aodh/aodh.conf keystone_authtoken password ${AODH_PASS}

# Configure service credentials
crudini --set /etc/aodh/aodh.conf service_credentials os_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/aodh/aodh.conf service_credentials os_username aodh
crudini --set /etc/aodh/aodh.conf service_credentials os_tenant_name service
crudini --set /etc/aodh/aodh.conf service_credentials os_password ${AODH_PASS}
crudini --set /etc/aodh/aodh.conf service_credentials os_endpoint_type internalURL
crudini --set /etc/aodh/aodh.conf service_credentials os_region_name RegionOne

crudini --set /etc/aodh/api_paste.ini filter:authtoken oslo_config_project aodh

# Populate database
su -s /bin/sh -c "aodh-dbsync --config-file=/etc/aodh/aodh.conf" aodh
