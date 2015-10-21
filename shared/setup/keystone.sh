#!/bin/bash

# Define the value of the initial administration token
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token ${token}

# Configure database access
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${KEYSTONE_DBPASS}@${DATABASE_HOSTNAME}/keystone

# Configure the Memcache service
crudini --set /etc/keystone/keystone.conf memcache servers localhost:11211

# Configure the UUID token provider and Memcached drive
crudini --set /etc/keystone/keystone.conf token provider uuid
# It seems like there are issues with python-memcache(https://bugs.launchpad.net/keystone/+bug/1462152/comments/6)
#crudini --set /etc/keystone/keystone.conf token driver memcache

# Configure the SQL revocation driver
crudini --set /etc/keystone/keystone.conf revoke driver sql

# Populate the Identity service database 
su -s /bin/sh -c "keystone-manage db_sync" keystone

