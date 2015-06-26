#!/bin/bash

crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api nova
