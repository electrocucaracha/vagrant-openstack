#!/bin/bash

# 1. Database creation
mysql -uroot -psecure -e "CREATE DATABASE if not exists cinder;"
mysql -uroot -psecure -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '${CINDER_DBPASS}';"
mysql -uroot -psecure -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '${CINDER_DBPASS}';"

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create cinder --password=${CINDER_PASS} --email=cinder@example.com
openstack role add admin --user=cinder --project=service
openstack service create --name=cinder --description="OpenStack Block Storage Service" volume
openstack service create --name=cinderv2 --description "OpenStack Block Storage Service" volumev2
openstack endpoint create \
  --publicurl http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s \
  --internalurl http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s \
  --adminurl http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s \
  --region regionOne \
  volume
openstack endpoint create \
  --publicurl http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s \
  --internalurl http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s \
  --adminurl http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s \
  --region regionOne \
  volumev2

# 3. Configure api service
crudini --set /etc/cinder/cinder.conf database connection mysql://cinder:${CINDER_DBPASS}@${DATABASE_HOSTNAME}/cinder
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_plugin password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_id default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_id default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password ${CINDER_PASS}

crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}

crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lock/cinder

# 4. Generate tables
su -s /bin/sh -c "cinder-manage db sync" cinder
