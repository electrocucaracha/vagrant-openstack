#!/bin/bash

# 1. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create swift --password=${SWIFT_PASS} --email=swift@example.com
openstack role add admin --user=swift --project=service
openstack service create object-storage --name=swift --description="OpenStack Object Storage Service"
openstack endpoint create \
  --publicurl "http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_%(tenant_id)s" \
  --internalurl "http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_%(tenant_id)s" \
  --adminurl "http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080" \
  --region RegionOne \
  object-store

mkdir -p /etc/swift 

wget -O /etc/swift/proxy-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/proxy-server.conf-sample?h=stable/kilo

# 3. Configure api service
crudini --set /etc/swift/proxy-server.conf DEFAULT bind_port 8080
crudini --set /etc/swift/proxy-server.conf DEFAULT user swift
crudini --set /etc/swift/proxy-server.conf DEFAULT swift_dir /etc/swift

crudini --set /etc/swift/proxy-server.conf pipeline:main pipeline "catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo proxy-logging proxy-server"

crudini --set /etc/swift/proxy-server.conf app:proxy-server account_autocreate true
crudini --set /etc/swift/proxy-server.conf filter:keystoneauth use egg:swift
crudini --set /etc/swift/proxy-server.conf filter:keystoneauth operator_roles admin,user

crudini --set /etc/swift/proxy-server.conf filter:authtoken paste.filter_factory "keystonemiddleware.auth_token:filter_factory"
crudini --set /etc/swift/proxy-server.conf filter:authtoken auth_uri http://${IDENTITY_CONTROLLER}:5000
crudini --set /etc/swift/proxy-server.conf filter:authtoken auth_url http://${IDENTITY_CONTROLLER}:35357
crudini --set /etc/swift/proxy-server.conf filter:authtoken auth_plugin password
crudini --set /etc/swift/proxy-server.conf filter:authtoken project_domain_id default
crudini --set /etc/swift/proxy-server.conf filter:authtoken user_domain_id default
crudini --set /etc/swift/proxy-server.conf filter:authtoken project_name service
crudini --set /etc/swift/proxy-server.conf filter:authtoken username swift
crudini --set /etc/swift/proxy-server.conf filter:authtoken password ${SWIFT_PASS}
crudini --set /etc/swift/proxy-server.conf filter:authtoken delay_auth_decision true

crudini --set /etc/swift/proxy-server.conf filter:cache memcache_servers 127.0.0.1:11211

# 4. Generate tables
su -s /bin/sh -c "nova-manage db sync" nova
