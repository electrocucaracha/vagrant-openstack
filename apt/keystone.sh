#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Identity Service

# 1. Install and configure components
apt-get install -y keystone

./keystone.sh

# 2.Configure the Apache HTTP Server

echo "ServerName ${IDENTITY_HOSTNAME}">> /etc/apache2/apache2.conf

# 3. Finalize the installation

service apache2 restart
rm -f /var/lib/keystone/keystone.db

sleep 5

#./create_initial_accounts.sh
