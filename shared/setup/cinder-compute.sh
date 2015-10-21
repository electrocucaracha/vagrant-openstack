#!/bin/bash

# Configure Compute to use Block Storage
crudini --set /etc/nova/nova.conf cinder os_region_name RegionOne
