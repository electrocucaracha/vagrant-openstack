#!/bin/bash

# Global variables
export token=`openssl rand -hex 10`
export my_nic=`ip route get 192.168.50.1 | awk '{ print $3; exit }'`
export my_ip=`ip route get 192.168.50.1 | awk '{ print $NF; exit }'`

export ENABLE_PROFILER="False"

# List of hostnames
export MESSAGE_BROKER_HOSTNAME=supporting-services
export DATABASE_HOSTNAME=supporting-services
export IDENTITY_HOSTNAME=controller-services
export IMAGE_HOSTNAME=controller-services
export COMPUTE_CONTROLLER_HOSTNAME=controller-services
export NETWORKING_CONTROLLER_HOSTNAME=controller-services
export BLOCK_STORAGE_CONTROLLER_HOSTNAME=controller-services
export OBJECT_STORAGE_CONTROLLER_HOSTNAME=controller-services
export NOSQL_DATABASE_HOSTNAME=supporting-services
export TELEMETRY_CONTROLLER_HOSTNAME=controller-services
export ORCHESTRATION_HOSTNAME=controller-services
export DATABASE_CONTROLLER_HOSTNAME=controller-services
export DATA_HOSTNAME=controller-services
export MEMCACHED_HOSTNAME=controller-services
export OPENDAYLIGHT_IP=${my_ip}

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
export METADATA_SECRET=secure
