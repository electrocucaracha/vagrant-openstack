#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Metering service

# 1. Install OpenStack Telemetry Controller Service and dependencies

apt-get install -y aodh-api aodh-evaluator aodh-notifier \
  aodh-listener aodh-expirer python-ceilometerclient

./ceilometer-aodh.sh

service aodh-api restart
service aodh-evaluator restart
service aodh-notifier restart
service aodh-listener restart
