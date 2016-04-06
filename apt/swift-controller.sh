#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Object Storage Service

apt-get install -y swift swift-proxy python-swiftclient \
  python-keystoneclient python-keystonemiddleware \
  memcached

# Object Storage - Telemetry services

apt-get install -y python-ceilometermiddleware

./swift.sh

./configure_ceilometer_object_storage_controller.sh

service swift-proxy restart
