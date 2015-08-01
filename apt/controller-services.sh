#!/bin/bash

# 0. Post-installation
export CONFIGURATION="_group"
cd /root/scripts/

./keystone.sh
./glance.sh
./nova-controller.sh
./horizon.sh
./cinder-controller.sh
./swift-controller.sh
./heat-controller.sh
./ceilometer-controller.sh
./trove-controller.sh
