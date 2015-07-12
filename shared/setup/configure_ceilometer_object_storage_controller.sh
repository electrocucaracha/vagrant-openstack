#!/bin/bash

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack role create ResellerAdmin
openstack role add --project service --user ceilometer ResellerAdmin

crudini --set /etc/swift/proxy-server.conf filter:keystoneauth operator_roles "admin,user,ResellerAdmin"

crudini --set /etc/swift/proxy-server.conf pipeline:main pipeline "authtoken cache healthcheck keystoneauth proxy-logging ceilometer proxy-server"

crudini --set /etc/swift/proxy-server.conf filter:ceilometer paste.filter_factory ceilometermiddleware.swift:filter_factory
crudini --set /etc/swift/proxy-server.conf filter:ceilometer control_exchange swift
crudini --set /etc/swift/proxy-server.conf filter:ceilometer url rabbit://openstack:${RABBIT_PASS}@${MESSAGE_BROKER_HOSTNAME}:5672/
crudini --set /etc/swift/proxy-server.conf filter:ceilometer driver messagingv2
crudini --set /etc/swift/proxy-server.conf filter:ceilometer topic notifications
crudini --set /etc/swift/proxy-server.conf filter:ceilometer log_level WARN

usermod -a -G ceilometer swift
