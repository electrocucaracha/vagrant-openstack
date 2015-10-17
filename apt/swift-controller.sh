#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Object Storage Service

apt-get install -y swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached

./swift.sh

# Object Storage - Telemetry services

# Workaround for https://bugs.launchpad.net/openstack-manuals/+bug/1462947
apt-get install -y python-pip
pip install ceilometermiddleware==0.1.0

./configure_ceilometer_object_storage_controller.sh

service swift-proxy restart
