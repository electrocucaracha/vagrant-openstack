#!/bin/bash

# Source the admin credentials
source /root/admin-openrc.sh

# Create the glance user
openstack user create glance --password=${GLANCE_PASS} --email=glance@example.com

# Add the admin role to the glance user and service project
openstack role add admin --user=glance --project=service

# Create the glance service entity
openstack service create --name glance \
  --description "OpenStack Image service" image

# Create the Image service API endpoints
openstack endpoint create --region RegionOne \
  image public http://${IMAGE_HOSTNAME}:9292
openstack endpoint create --region RegionOne \
  image internal http://${IMAGE_HOSTNAME}:9292
openstack endpoint create --region RegionOne \
  image admin http://${IMAGE_HOSTNAME}:9292

# Configure database access
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:${GLANCE_DBPASS}@${DATABASE_HOSTNAME}/glance

# Configure Identity service access
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password ${GLANCE_PASS}

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

# Configure the local file system store and location of image files
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

# Configure the noop notification driver to disable notifications because they only pertain to the optional Telemetry service
crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver noop

# Configure database access 
crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:${GLANCE_DBPASS}@${DATABASE_HOSTNAME}/glance

# Configure Identity service access
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password ${GLANCE_PASS}

crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

# Configure the noop notification driver to disable notifications because they only pertain to the optional Telemetry service
crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver noop

# Populate the Image service database
su -s /bin/sh -c "glance-manage db_sync" glance

# Enable OSProfiler
if [ ! -z ${ENABLE_PROFILER} ] && [ ${ENABLE_PROFILER} == "True" ]; then
  crudini --set /etc/glance/glance-api.conf profiler enabled True
  crudini --set /etc/glance/glance-api.conf profiler trace_sqlalchemy True
  crudini --set /etc/glance/glance-registry.conf profiler enabled True
  crudini --set /etc/glance/glance-registry.conf profiler trace_sqlalchemy True
fi
