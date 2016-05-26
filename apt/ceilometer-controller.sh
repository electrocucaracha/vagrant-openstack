#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Metering service

# 1. Install OpenStack Telemetry Controller Service and dependencies

apt-get install -y ceilometer-api ceilometer-collector \
  ceilometer-agent-central ceilometer-agent-notification \
  python-ceilometerclient mongodb-clients python-pymongo

./ceilometer.sh

service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
