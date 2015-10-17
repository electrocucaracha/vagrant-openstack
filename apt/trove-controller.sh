#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Database services
apt-get install -y python-trove python-troveclient python-glanceclient trove-common trove-api trove-taskmanager trove-conductor

./trove.sh

service trove-api restart
service trove-conductor restart
service trove-taskmanager restart
