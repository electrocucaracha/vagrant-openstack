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

# 1. Install OpenStack Compute Controller Service and dependencies
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

./nova.sh
rm /var/lib/nova/nova.sqlite

./setup_legacy_network_controller.sh

# 6. Restart services
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
