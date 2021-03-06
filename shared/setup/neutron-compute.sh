#!/bin/bash

# Configure Identity service access
crudini --set /etc/nova/nova.conf neutron url http://${NETWORKING_CONTROLLER_HOSTNAME}:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/nova/nova.conf neutron auth_type password

# TODO: Until this change happens https://review.openstack.org/#/c/310173
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_name default
crudini --set /etc/nova/nova.conf neutron user_domain_name default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password ${NEUTRON_PASS}
