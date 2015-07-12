#!/bin/bash

# 1. Database creation
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists glance;"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';"

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create glance --password=${GLANCE_PASS} --email=glance@example.com
openstack role add admin --user=glance --project=service
openstack service create image --name=glance --description="OpenStack Image Service"
openstack endpoint create \
  --publicurl=http://${IMAGE_HOSTNAME}:9292 \
  --internalurl=http://${IMAGE_HOSTNAME}:9292 \
  --adminurl=http://${IMAGE_HOSTNAME}:9292 \
  --region regionOne \
  image

# 2. Configure api service
crudini --set /etc/glance/glance-api.conf database connection mysql://glance:${GLANCE_DBPASS}@${DATABASE_HOSTNAME}/glance

crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password ${GLANCE_PASS}
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver noop

# 3. Configure registry service
crudini --set /etc/glance/glance-registry.conf database connection  mysql://glance:${GLANCE_DBPASS}@${DATABASE_HOSTNAME}/glance

crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password ${GLANCE_PASS}
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver noop

# Enable OSProfiler
if [ ! -z ${ENABLE_PROFILER} ] && [ ${ENABLE_PROFILER} == "True" ]; then
  crudini --set /etc/glance/glance-api.conf profiler enabled True
  crudini --set /etc/glance/glance-api.conf profiler trace_sqlalchemy True
  crudini --set /etc/glance/glance-registry.conf profiler enabled True
  crudini --set /etc/glance/glance-registry.conf profiler trace_sqlalchemy True
fi

# 4. Generate tables
su -s /bin/sh -c "glance-manage db_sync" glance
