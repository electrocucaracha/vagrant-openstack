#!/bin/bash

# Configure database access 
crudini --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:${CINDER_DBPASS}@${DATABASE_HOSTNAME}/cinder

# Configure RabbitMQ message queue access
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
crudini --set /etc/cinder/cinder.conf keystone_authtoken project_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken username cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken password ${CINDER_PASS}

# Configure the my_ip option
crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}

# Configure the LVM back end with the LVM driver, cinder-volumes volume group, iSCSI protocol, and appropriate iSCSI service
crudini --set /etc/cinder/cinder.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
crudini --set /etc/cinder/cinder.conf lvm volume_group cinder-volumes 
crudini --set /etc/cinder/cinder.conf lvm iscsi_protocol iscsi
crudini --set /etc/cinder/cinder.conf lvm iscsi_helper tgtadm

# Enable the LVM back end
crudini --set /etc/cinder/cinder.conf DEFAULT enabled_backends lvm

# Configure the location of the Image service
crudini --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://${IMAGE_HOSTNAME}:9292

# Configure the lock path
crudini --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
