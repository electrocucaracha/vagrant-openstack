#!/bin/bash

crudini --set /etc/glance/glance-api.conf DEFAULT rpc_backend rabbit
crudini --set /etc/glance/glance-api.conf oslo_messaging_notifications driver messagingv2
crudini --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/glance/glance-api.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/glance/glance-registry.conf DEFAULT rpc_backend rabbit
crudini --set /etc/glance/glance-registry.conf oslo_messaging_notifications driver messagingv2
crudini --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
