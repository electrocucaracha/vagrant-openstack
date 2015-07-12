#!/bin/bash

crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver messagingv2
crudini --set /etc/glance/glance-api.conf DEFAULT rpc_backend rabbit
crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_userid openstack
crudini --set /etc/glance/glance-api.conf DEFAULT rabbit_password ${RABBIT_PASS}

crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver messagingv2
crudini --set /etc/glance/glance-registry.conf DEFAULT rpc_backend rabbit
crudini --set /etc/glance/glance-registry.conf DEFAULT rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/glance/glance-registry.conf DEFAULT rabbit_userid openstack
crudini --set /etc/glance/glance-registry.conf DEFAULT rabbit_password ${RABBIT_PASS}
