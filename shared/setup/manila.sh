#!/bin/bash

# Source the admin credentials to gain access to admin-only CLI commands
source /root/admin-openrc.sh

# Create the manila user
openstack user create --domain default manila --password=${MANILA_PASS} --email=manila@example.com

# Add the admin role to the manila user
openstack role add --project service --user manila admin

# Create the manila and manilav2 service entitiesC
openstack service create --name manila \
  --description "OpenStack Shared File Systems" share
openstack service create --name manilav2 \
  --description "OpenStack Shared File Systems" sharev2

# Create the Shared File Systems service API endpoints
openstack endpoint create --region RegionOne \
  share public http://${SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME}:8786/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  share internal http://${SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME}:8786/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  share admin http://${SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME}:8786/v1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  sharev2 public http://${SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME}:8786/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  sharev2 internal http://${SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME}:8786/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  sharev2 admin http://${SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME}:8786/v2/%\(tenant_id\)s

# Configure database access
crudini --set /etc/manila/manila.conf database connection mysql+pymysql://manila:${MANILA_DBPASS}@${DATABASE_HOSTNAME}/manila

# Configure RabbitMQ message queue access
crudini --set /etc/manila/manila.conf DEFAULT rpc_backend rabbit
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/manila/manila.conf DEFAULT default_share_type default_share_type
crudini --set /etc/manila/manila.conf DEFAULT rootwrap_config /etc/manila/rootwrap.conf

# Configure Identity service access
crudini --set /etc/manila/manila.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/manila/manila.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/manila/manila.conf keystone_authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/manila/manila.conf keystone_authtoken auth_type password
crudini --set /etc/manila/manila.conf keystone_authtoken project_domain_name default
crudini --set /etc/manila/manila.conf keystone_authtoken user_domain_name default
crudini --set /etc/manila/manila.conf keystone_authtoken project_name service
crudini --set /etc/manila/manila.conf keystone_authtoken username manila
crudini --set /etc/manila/manila.conf keystone_authtoken password ${MANILA_PASS}

# Configure the my_ip option to use the management interface IP address of the controller node
crudini --set /etc/manila/manila.conf DEFAULT my_ip ${my_ip}

# Configure the lock path
crudini --set /etc/manila/manila.conf oslo_concurrency lock_path /var/lib/manila/tmp

# Populate the Share File System database
su -s /bin/sh -c "manila-manage db sync" manila
