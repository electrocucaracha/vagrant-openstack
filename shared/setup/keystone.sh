#!/bin/bash

# Define the value of the initial administration token
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token ${token}

# Configure database access
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${KEYSTONE_DBPASS}@${DATABASE_HOSTNAME}/keystone

# Configure the Fernet token provider
crudini --set /etc/keystone/keystone.conf token provider fernet

# Populate the Identity service database 
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialize Fernet keys
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
