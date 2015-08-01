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

# Image Service

# 1. Install OpenStack Image Service and dependencies
apt-get install -y glance python-glanceclient

./glance.sh
rm -f /var/lib/glance/glance.sqlite

# Image - Telemetry services

./configure_ceilometer_image.sh

# 2. Restart services
service glance-registry restart
service glance-api restart

sleep 5

./upload_cirros_image.sh
