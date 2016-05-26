#!/bin/bash

# Global variables
export token=`openssl rand -hex 10`
export my_nic=`ip route get 192.168.50.1 | awk '{ print $3; exit }'`
export my_ip=`ip route get 192.168.50.1 | awk '{ print $NF; exit }'`

export ENABLE_PROFILER="False"

# List of hostnames
export MESSAGE_BROKER_HOSTNAME=message-broker
export DATABASE_HOSTNAME=database
export IDENTITY_HOSTNAME=identity
export IMAGE_HOSTNAME=image
export COMPUTE_CONTROLLER_HOSTNAME=compute-controller
export NETWORKING_CONTROLLER_HOSTNAME=networking-controller
export BLOCK_STORAGE_CONTROLLER_HOSTNAME=block-storage-controller
export SHARED_FILE_STORAGE_CONTROLLER_HOSTNAME=shared-file-storage-controller
export OBJECT_STORAGE_CONTROLLER_HOSTNAME=object-storage-controller
export NOSQL_DATABASE_HOSTNAME=nosql-datababase
export ORCHESTRATION_HOSTNAME=orchestration
export TELEMETRY_CONTROLLER_HOSTNAME=telemetry-controller
export ALARMING_HOSTNAME=alarming-controller
export DATABASE_CONTROLLER_HOSTNAME=database-controller
export DATA_HOSTNAME=data
export MEMCACHED_HOSTNAME=memcached
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
