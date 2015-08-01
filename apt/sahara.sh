#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get install -y ubuntu-cloud-keyring
cat << EOL > /etc/apt/sources.list.d/kilo.list
deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main
EOL
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini python-mysqldb

if [ "$CONFIGURATION" !=  "_all-in-one" ]
then
  apt-get install -y mysql-client
fi

# Install OpenStack Data Service
apt-get install -y sahara sahara-api sahara-engine

./sahara.sh

service sahara-all restart
