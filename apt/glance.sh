#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Image Service

# 1. Install the packages
apt-get install -y glance python-glanceclient

./glance.sh
rm -f /var/lib/glance/glance.sqlite

# Image - Telemetry services

./configure_ceilometer_image.sh

# 2. Restart services
service glance-registry restart
service glance-api restart
