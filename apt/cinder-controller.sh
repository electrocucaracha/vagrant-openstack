#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Block Storage services

# 1. Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-api cinder-scheduler python-cinderclient

./cinder.sh

# Block Storage - Telemetry services

./configure_ceilometer_block_storage_controller.sh

# 6. Enable and start services
service cinder-scheduler restart
service cinder-api restart
