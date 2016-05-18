#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Block Storage services

# Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-api cinder-scheduler

./cinder.sh

./cinder-compute.sh

# Telemetry services

./configure_ceilometer_block_storage_controller.sh

# Restart the Compute API service
service nova-api restart

# Restart the Block Storage services
service cinder-scheduler restart
service cinder-api restart

rm -f /var/lib/cinder/cinder.sqlite
