#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# Create a cinder user
openstack user create --domain default cinder --password=${CINDER_PASS} --email=cinder@example.com

# Add the admin role to the cinder user
openstack role add --project service --user cinder admin

# Create the cinderv2 service entity
openstack service create --name cinder \
  --description "OpenStack Block Storage" volume
openstack service create --name cinderv2 \
  --description "OpenStack Block Storage" volumev2

# Create the Block Storage service API endpoints
openstack endpoint create --region RegionOne \
  volume public http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  volume internal http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  volume admin http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
  volumev2 public http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  volumev2 internal http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  volumev2 admin http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s

# Configure database access
crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:${CINDER_DBPASS}@${DATABASE_HOSTNAME}/cinder

# Configure RabbitMQ message queue access
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_plugin password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_id default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_id default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password ${CINDER_PASS}

# Configure the my_ip option to use the management interface IP address of the controller node
crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}

# Configure the lock path
crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lock/cinder

# Configure key manager
crudini --set /etc/cinder/cinder.conf keymgr encryption_auth_url http://${IDENTITY_HOSTNAME}:5000/v3

# Populate the Block Storage database
su -s /bin/sh -c "cinder-manage db sync" cinder
