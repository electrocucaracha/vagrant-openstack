#!/bin/bash

export OS_TOKEN=${token}
export OS_URL=http://${IDENTITY_HOSTNAME}:35357/v2.0

openstack service create \
  --name keystone --description "OpenStack Identity" identity

openstack endpoint create \
  --publicurl http://${IDENTITY_HOSTNAME}:5000/v2.0 \
  --internalurl http://${IDENTITY_HOSTNAME}:5000/v2.0 \
  --adminurl http://${IDENTITY_HOSTNAME}:35357/v2.0 \
  --region regionOne \
  identity

openstack project create --description "Admin Project" admin
openstack user create --password "${ADMIN_PASS}" admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --description "Service Project" service
openstack project create --description "Demo Project" demo

openstack user create --password "${DEMO_PASS}" demo
openstack role create user
openstack role add --project demo --user demo user

unset OS_TOKEN OS_URL
