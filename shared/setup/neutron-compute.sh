#!/bin/bash

# Configure Identity service access
crudini --set /etc/nova/nova.conf neutron url http://${NETWORKING_CONTROLLER_HOSTNAME}:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_id default
crudini --set /etc/nova/nova.conf neutron user_domain_id default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password ${NEUTRON_PASS}

crudini --set /etc/nova/nova.conf neutron admin_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/nova/nova.conf neutron admin_tenant_name service
crudini --set /etc/nova/nova.conf neutron admin_username neutron
crudini --set /etc/nova/nova.conf neutron admin_password ${NEUTRON_PASS}

crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret ${METADATA_SECRET}
