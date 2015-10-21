#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup
cd /root/shared
source configure.sh
cd setup

# Compute services

# 1. Install and configure components
apt-get install -y nova-api nova-cert nova-conductor \
  nova-consoleauth nova-novncproxy nova-scheduler \
  python-novaclient

./nova.sh

# Block Storage services

./cinder-compute.sh

# 2. Finalize installation

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

rm -f /var/lib/nova/nova.sqlite
