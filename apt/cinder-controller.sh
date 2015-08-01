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

# Block Storage services

# 1. Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-api cinder-scheduler python-cinderclient

./cinder.sh
su -s /bin/sh -c "cinder-manage db sync" cinder

# Block Storage - Telemetry services

./configure_ceilometer_block_storage_controller.sh

# 6. Enable and start services
service cinder-scheduler restart
service cinder-api restart
