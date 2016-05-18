#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Shared File Service

# Install the packages
apt-get install -y manila-share python-pymysql

./manila-storage.sh

# Driver support for share servers management

apt-get install -y neutron-plugin-linuxbridge-agent

# Finalize installation
service manila-share restart
