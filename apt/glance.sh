#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Image Service

# 1. Install OpenStack Image Service and dependencies
apt-get install -y glance python-glanceclient

./glance.sh
rm -f /var/lib/glance/glance.sqlite

# Image - Telemetry services

./configure_ceilometer_image.sh

# 2. Restart services
service glance-registry restart
service glance-api restart

sleep 5

./upload_cirros_image.sh
