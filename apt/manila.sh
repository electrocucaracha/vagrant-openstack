#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Shared File Service

# Install the packages
apt-get install -y manila-api manila-scheduler \
  python-manilaclient

./manila.sh

# Finalize installation
service manila-scheduler restart
service manila-api restart
