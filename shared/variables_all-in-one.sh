#!/bin/bash

# Global variables
export token=`openssl rand -hex 10`
export my_nic=`ip route get 192.168.50.1 | awk '{ print $3; exit }'`
export my_ip=`ip route get 192.168.50.1 | awk '{ print $NF; exit }'`

export ENABLE_PROFILER="False"

# List of hostnames
export MESSAGE_BROKER_HOSTNAME=all-in-one
export DATABASE_HOSTNAME=all-in-one
export IDENTITY_HOSTNAME=all-in-one
export IMAGE_HOSTNAME=all-in-one
export COMPUTE_CONTROLLER_HOSTNAME=all-in-one
export NETWORKING_CONTROLLER_HOSTNAME=all-in-one
export BLOCK_STORAGE_CONTROLLER_HOSTNAME=all-in-one
export SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME=all-in-one
export OBJECT_STORAGE_CONTROLLER_HOSTNAME=all-in-one
export NOSQL_DATABASE_HOSTNAME=all-in-one
export TELEMETRY_CONTROLLER_HOSTNAME=all-in-one
export ALARMING_HOSTNAME=all-in-one
export ORCHESTRATION_HOSTNAME=all-in-one
export DATABASE_CONTROLLER_HOSTNAME=all-in-one
export DATA_HOSTNAME=all-in-one
export MEMCACHED_HOSTNAME=all-in-one
export OPENDAYLIGHT_IP=${my_ip}

# Service passwords
export AODH_DBPASS=secure
export AODH_PASS=secure
export ROOT_DBPASS=secure
export ADMIN_PASS=secure
export CEILOMETER_DBPASS=secure
export CEILOMETER_PASS=secure
export CINDER_DBPASS=secure
export CINDER_PASS=secure
export MANILA_DBPASS=secure
export MANILA_PASS=secure
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
