#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Install OpenStack Data Service
apt-get install -y sahara

./sahara.sh

service sahara restart
