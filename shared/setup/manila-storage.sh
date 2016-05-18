#!/bin/bash

# Configure database access
crudini --set /etc/manila/manila.conf database connection mysql+pymysql://manila:${MANILA_DBPASS}@${DATABASE_HOSTNAME}/manila

# Configure RabbitMQ message queue access
crudini --set /etc/manila/manila.conf DEFAULT rpc_backend rabbit
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/manila/manila.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/manila/manila.conf DEFAULT default_share_type default_share_type
crudini --set /etc/manila/manila.conf DEFAULT rootwrap_config /etc/manila/rootwrap.conf

# Configure Identity service access
crudini --set /etc/manila/manila.conf neutron auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/manila/manila.conf neutron auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/manila/manila.conf neutron memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/manila/manila.conf neutron auth_type password
crudini --set /etc/manila/manila.conf neutron project_domain_name default
crudini --set /etc/manila/manila.conf neutron user_domain_name default
crudini --set /etc/manila/manila.conf neutron project_name service
crudini --set /etc/manila/manila.conf neutron username manila
crudini --set /etc/manila/manila.conf neutron password ${MANILA_PASS}

# Configure the my_ip option to use the management interface IP address of the controller node
crudini --set /etc/manila/manila.conf DEFAULT my_ip ${my_ip}

# Configure the lock path
crudini --set /etc/manila/manila.conf oslo_concurrency lock_path /var/lib/manila/tmp

# Driver support for share servers management

crudini --set /etc/manila/manila.conf DEFAULT enabled_share_backends generic
crudini --set /etc/manila/manila.conf DEFAULT enabled_share_protocols NFS,CIFS

crudini --set /etc/manila/manila.conf neutron auth_uri http://${NETWORKING_CONTROLLER_HOSTNAME}:9696
crudini --set /etc/manila/manila.conf neutron auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/manila/manila.conf neutron auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/manila/manila.conf neutron memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/manila/manila.conf neutron auth_type password
crudini --set /etc/manila/manila.conf neutron project_domain_name default
crudini --set /etc/manila/manila.conf neutron user_domain_name default
crudini --set /etc/manila/manila.conf neutron region_name RegionOne
crudini --set /etc/manila/manila.conf neutron project_name service
crudini --set /etc/manila/manila.conf neutron username neutron
crudini --set /etc/manila/manila.conf neutron password ${NEUTRON_PASS}

crudini --set /etc/manila/manila.conf nova auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/manila/manila.conf nova auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/manila/manila.conf nova memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/manila/manila.conf nova auth_plugin password
crudini --set /etc/manila/manila.conf nova project_domain_name default
crudini --set /etc/manila/manila.conf nova user_domain_name default
crudini --set /etc/manila/manila.conf nova region_name RegionOne
crudini --set /etc/manila/manila.conf nova project_name service
crudini --set /etc/manila/manila.conf nova username nova
crudini --set /etc/manila/manila.conf nova password ${NOVA_PASS}

crudini --set /etc/manila/manila.conf cinder auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/manila/manila.conf cinder auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/manila/manila.conf cinder memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/manila/manila.conf cinder auth_type password
crudini --set /etc/manila/manila.conf cinder project_domain_name default
crudini --set /etc/manila/manila.conf cinder user_domain_name default
crudini --set /etc/manila/manila.conf cinder region_name RegionOne
crudini --set /etc/manila/manila.conf cinder project_name service
crudini --set /etc/manila/manila.conf cinder username cinder
crudini --set /etc/manila/manila.conf cinder password ${CINDER_PASS}

crudini --set /etc/manila/manila.conf generic share_backend_name GENERIC
crudini --set /etc/manila/manila.conf generic share_driver manila.share.drivers.generic.GenericShareDriver
crudini --set /etc/manila/manila.conf generic driver_handles_share_servers True
crudini --set /etc/manila/manila.conf generic service_instance_flavor_id 100
crudini --set /etc/manila/manila.conf generic service_image_name manila-service-image
crudini --set /etc/manila/manila.conf generic service_instance_user manila
crudini --set /etc/manila/manila.conf generic service_instance_password manila
crudini --set /etc/manila/manila.conf generic interface_driver manila.network.linux.interface.BridgeInterfaceDriver
