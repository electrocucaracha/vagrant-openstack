#!/bin/bash

# Source the admin credentials to gain access to admin-only CLI commands
source /root/admin-openrc.sh

# Create the heat user
openstack user create --domain default heat --password=${HEAT_PASS} --email=heat@example.com

# Add the admin role to the heat user
openstack role add --project service --user heat admin

# Create the heat and heat-cfn service entities
openstack service create --name heat \
  --description "Orchestration" orchestration
openstack service create --name heat-cfn \
  --description "Orchestration"  cloudformation

# Create the Orchestration service API endpoints
openstack endpoint create --region RegionOne \
  orchestration public http://${ORCHESTRATION_HOSTNAME}:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  orchestration internal http://${ORCHESTRATION_HOSTNAME}:8004/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  orchestration admin http://${ORCHESTRATION_HOSTNAME}:8004/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  cloudformation public http://${ORCHESTRATION_HOSTNAME}:8000/v1
openstack endpoint create --region RegionOne \
  cloudformation internal http://${ORCHESTRATION_HOSTNAME}:8000/v1
openstack endpoint create --region RegionOne \
  cloudformation admin http://${ORCHESTRATION_HOSTNAME}:8000/v1

# Create the heat domain that contains projects and users for stack
openstack domain create --description "Stack projects and users" heat

# Create the heat_domain_admin user to manage projects and users in the heat domain
openstack user create --domain heat --password=${HEAT_DOMAIN_PASS} heat_domain_admin

# Add the admin role to the heat_domain_admin user in the heat domain to enable administrative stack management privileges by the heat_domain_admin user
openstack role add --domain heat --user-domain heat --user heat_domain_admin admin

# Create the heat_stack_owner role
openstack role create heat_stack_owner

# Add the heat_stack_owner role to the demo project and user to enable stack management by the demo user
openstack role add --project demo --user demo heat_stack_owner

# Create the heat_stack_user role
openstack role create heat_stack_user

# Configure database access
crudini --set /etc/heat/heat.conf database connection mysql+pymysql://heat:${HEAT_DBPASS}@${DATABASE_HOSTNAME}/heat

# Configure RabbitMQ message queue access
crudini --set /etc/heat/heat.conf DEFAULT rpc_backend rabbit
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/heat/heat.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/heat/heat.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/heat/heat.conf keystone_authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/heat/heat.conf keystone_authtoken auth_type password
crudini --set /etc/heat/heat.conf keystone_authtoken project_domain_name default
crudini --set /etc/heat/heat.conf keystone_authtoken user_domain_name default
crudini --set /etc/heat/heat.conf keystone_authtoken project_name service
crudini --set /etc/heat/heat.conf keystone_authtoken username heat
crudini --set /etc/heat/heat.conf keystone_authtoken password ${HEAT_PASS}

crudini --set /etc/heat/heat.conf trustee auth_plugin password
crudini --set /etc/heat/heat.conf trustee auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/heat/heat.conf trustee username heat
crudini --set /etc/heat/heat.conf trustee password ${HEAT_PASS}
crudini --set /etc/heat/heat.conf trustee user_domain_name default

crudini --set /etc/heat/heat.conf clients_keystone auth_uri http://${IDENTITY_HOSTNAME}:35357

crudini --set /etc/heat/heat.conf ec2authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000

# Configure the metadata and wait condition URLs
crudini --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://${ORCHESTRATION_HOSTNAME}:8000
crudini --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://${ORCHESTRATION_HOSTNAME}:8000/v1/waitcondition

# Configure information about the heat Identity service domain
crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin heat_domain_admin
crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password ${HEAT_DOMAIN_PASS}
crudini --set /etc/heat/heat.conf DEFAULT stack_user_domain_name heat_user_domain

# Populate the Orchestration database
su -s /bin/sh -c "heat-manage db_sync" heat
