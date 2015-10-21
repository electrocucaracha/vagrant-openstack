#!/bin/bash

export OS_TOKEN=${token}
export OS_URL=http://${IDENTITY_HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
unset OS_PROJECT_DOMAIN_ID OS_IMAGE_API_VERSION OS_USER_DOMAIN_ID \
  OS_PROJECT_NAME OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME

# Create the service entity and API endpoints

openstack service create \
  --name keystone --description "OpenStack Identity" identity

openstack endpoint create --region RegionOne \
  identity public http://${IDENTITY_HOSTNAME}:5000/v2.0

openstack endpoint create --region RegionOne \
  identity internal http://${IDENTITY_HOSTNAME}::5000/v2.0

openstack endpoint create --region RegionOne \
  identity admin http://${IDENTITY_HOSTNAME}:35357/v2.0

openstack project create --domain default \
  --description "Admin Project" admin
openstack user create --domain default \
  --password "${ADMIN_PASS}" admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" demo

openstack user create --domain default \
  --password "${DEMO_PASS}" demo
openstack role create user
openstack role add --project demo --user demo user

unset OS_TOKEN OS_URL
