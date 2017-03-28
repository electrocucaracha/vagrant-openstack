#!/bin/bash

# Configure database access
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${KEYSTONE_DBPASS}@${DATABASE_HOSTNAME}/keystone

# Configure the Fernet token provider
crudini --set /etc/keystone/keystone.conf token provider fernet

# Populate the Identity service database 
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialize Fernet keys
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

keystone-manage bootstrap --bootstrap-password ${ADMIN_PASS} \
  --bootstrap-admin-url http://${IDENTITY_HOSTNAME}:35357/v3/ \
  --bootstrap-internal-url http://${IDENTITY_HOSTNAME}:5000/v3/ \
  --bootstrap-public-url http://${IDENTITY_HOSTNAME}:5000/v3/ \
  --bootstrap-region-id RegionOne
