#!/bin/bash

# Configure Identity service access
crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne
