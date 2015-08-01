#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get install -y ubuntu-cloud-keyring
cat << EOL > /etc/apt/sources.list.d/kilo.list
deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main
EOL
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini

# Object Storage Service

apt-get install -y swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached

./swift.sh

# Object Storage - Telemetry services

# Workaround for https://bugs.launchpad.net/openstack-manuals/+bug/1462947
apt-get install -y python-pip
pip install ceilometermiddleware==0.1.0

./configure_ceilometer_object_storage_controller.sh

service swift-proxy restart
