#!/bin/bash

# Global variables
export token=`openssl rand -hex 10`
export my_nic=`ip route | awk '/192./ { print $3 }'`
export my_ip=`ip addr | awk "/${my_nic}\$/ { sub(/\/24/, \"\","' $2); print $2}'`

export ENABLE_PROFILER="True"

# List of hostnames
export MESSAGE_BROKER_HOSTNAME=supporting-services
export DATABASE_HOSTNAME=supporting-services
export IDENTITY_HOSTNAME=controller-services
export IMAGE_HOSTNAME=controller-services
export COMPUTE_CONTROLLER_HOSTNAME=controller-services
export BLOCK_STORAGE_CONTROLLER_HOSTNAME=controller-services
export OBJECT_STORAGE_CONTROLLER_HOSTNAME=controller-services
export NOSQL_DATABASE_HOSTNAME=supporting-services
export TELEMETRY_CONTROLLER_HOSTNAME=controller-services

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
