#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# Create the swift user
openstack user create --domain default swift --password=${SWIFT_PASS} --email=swift@example.com

# Add the admin role to the swift user
openstack role add --project service --user swift admin

# Create the swift service entity
openstack service create --name swift \
  --description "OpenStack Object Storage" object-store

# Create the Object Storage service API endpoints
openstack endpoint create --region RegionOne \
  object-store public http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  object-store internal http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  object-store admin http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1

mkdir -p /etc/swift 

wget -O /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/mitaka

# Configure the bind port, user, and configuration directory
crudini --set /etc/swift/proxy-server.conf DEFAULT bind_port 8080
crudini --set /etc/swift/proxy-server.conf DEFAULT user swift
crudini --set /etc/swift/proxy-server.conf DEFAULT swift_dir /etc/swift

# Enable the appropriate modules
crudini --set /etc/swift/proxy-server.conf pipeline:main pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server"

# Enable automatic account creation
crudini --set /etc/swift/proxy-server.conf app:proxy-server use "egg:swift#proxy"
crudini --set /etc/swift/proxy-server.conf app:proxy-server account_autocreate True

# Configure the operator roles
crudini --set /etc/swift/proxy-server.conf filter:keystoneauth use "egg:swift#keystoneauth"
crudini --set /etc/swift/proxy-server.conf filter:keystoneauth operator_roles admin,user

# Configure Identity service access
crudini --set /etc/swift/proxy-server.conf filter:authtoken paste.filter_factory "keystonemiddleware.auth_token:filter_factory"
crudini --set /etc/swift/proxy-server.conf filter:authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/swift/proxy-server.conf filter:authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/swift/proxy-server.conf filter:authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/swift/proxy-server.conf filter:authtoken auth_type password
crudini --set /etc/swift/proxy-server.conf filter:authtoken project_domain_name default
crudini --set /etc/swift/proxy-server.conf filter:authtoken user_domain_name default
crudini --set /etc/swift/proxy-server.conf filter:authtoken project_name service
crudini --set /etc/swift/proxy-server.conf filter:authtoken username swift
crudini --set /etc/swift/proxy-server.conf filter:authtoken password ${SWIFT_PASS}
crudini --set /etc/swift/proxy-server.conf filter:authtoken delay_auth_decision True

# Configure the memcached location
crudini --set /etc/swift/proxy-server.conf filter:cache use "egg:swift#memcache"
crudini --set /etc/swift/proxy-server.conf filter:cache memcache_servers ${MEMCACHED_HOSTNAME}:11211
