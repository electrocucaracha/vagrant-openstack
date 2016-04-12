#!/bin/bash

export OS_TOKEN=${token}
export OS_URL=http://${IDENTITY_HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
unset OS_PROJECT_DOMAIN_NAME OS_IMAGE_API_VERSION OS_USER_DOMAIN_NAME \
  OS_PROJECT_NAME OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME

# Create the service entity for the Identity service
openstack service create \
  --name keystone --description "OpenStack Identity" identity

# Create the Identity service API enpoints
openstack endpoint create --region RegionOne \
  identity public http://${IDENTITY_HOSTNAME}:5000/v3

openstack endpoint create --region RegionOne \
  identity internal http://${IDENTITY_HOSTNAME}::5000/v3

openstack endpoint create --region RegionOne \
  identity admin http://${IDENTITY_HOSTNAME}:35357/v3

# Create default domain
openstack domain create --description "Default Domain" default

# Create the admin project
openstack project create --domain default \
  --description "Admin Project" admin

# Create the admin user
openstack user create --domain default \
  --password "${ADMIN_PASS}" admin

# Create the admin role
openstack role create admin

# Add the admin role tod the admin project and user
openstack role add --project admin --user admin admin

# Create the servcie project
openstack project create --domain default \
  --description "Service Project" service

# Create the demo project
openstack project create --domain default \
  --description "Demo Project" demo

# Create the demo user
openstack user create --domain default \
  --password "${DEMO_PASS}" demo

# Create the user role
openstack role create user

# Add the user role to the demo project and user
openstack role add --project demo --user demo user

unset OS_TOKEN OS_URL
