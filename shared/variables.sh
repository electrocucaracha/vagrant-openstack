#!/bin/bash

# Global variables
export token=`openssl rand -hex 10`
export my_nic=`ip route | awk '/192./ { print $3 }'`
export my_ip=`ip addr | awk "/${my_nic}\$/ { sub(/\/24/, \"\","' $2); print $2}'`

export ENABLE_PROFILER="True"

# List of hostnames
export MESSAGE_BROKER_HOSTNAME=message-broker
export DATABASE_HOSTNAME=database
export IDENTITY_HOSTNAME=identity
export IMAGE_HOSTNAME=image
export COMPUTE_CONTROLLER_HOSTNAME=compute-controller
export BLOCK_STORAGE_CONTROLLER_HOSTNAME=block-storage-controller
export OBJECT_STORAGE_CONTROLLER_HOSTNAME=object-storage-controller
export NOSQL_DATABASE_HOSTNAME=nosql-datababase
export TELEMETRY_CONTROLLER_HOSTNAME=telemetry-controller

# Service passwords
export ROOT_DBPASS=secure
export ADMIN_PASS=secure
export CEILOMETER_DBPASS=secure
export CEILOMETER_PASS=secure
export CINDER_DBPASS=secure
export CINDER_PASS=secure
export DASH_DBPASS=secure
export DEMO_PASS=secure
export GLANCE_DBPASS=secure
export GLANCE_PASS=secure
export HEAT_DBPASS=secure
export HEAT_DOMAIN_PASS=secure
export HEAT_PASS=secure
export KEYSTONE_DBPASS=secure
export NEUTRON_DBPASS=secure
export NEUTRON_PASS=secure
export NOVA_DBPASS=secure
export NOVA_PASS=secure
export RABBIT_PASS=secure
export SAHARA_DBPASS=secure
export SWIFT_PASS=secure
export TROVE_DBPASS=secure
export TROVE_PASS=secure
