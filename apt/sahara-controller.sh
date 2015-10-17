#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Install OpenStack Data Service
yes | pip install sahara
#apt-get install -y sahara sahara-api sahara-engine

./sahara.sh

service sahara-all restart
