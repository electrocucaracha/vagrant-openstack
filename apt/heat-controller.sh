#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Orchestration service

apt-get install -y heat-api heat-api-cfn heat-engine

./heat.sh

service heat-api restart
service heat-api-cfn restart
service heat-engine restart
