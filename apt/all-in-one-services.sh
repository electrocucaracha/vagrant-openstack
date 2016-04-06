#!/bin/bash

# 0. Post-installation
export CONFIGURATION="_all-in-one"
cd /root/scripts

./rabbitmq.sh
./mariadb.sh
./mongodb.sh
./opendaylight.sh

./keystone.sh
./glance.sh
./nova-controller.sh
./neutron-controller.sh
./horizon.sh
./cinder-controller.sh
./heat-controller.sh
./ceilometer-controller.sh
./swift-controller.sh
#./trove-controller.sh
./sahara-controller.sh

./nova-compute.sh

./cinder-storage.sh

./swift-storage.sh
