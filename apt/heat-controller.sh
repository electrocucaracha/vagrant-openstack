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

# Orchestration service

apt-get install -y  heat-api heat-api-cfn heat-engine python-heatclient

./heat.sh

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

rm -f /var/lib/heat/heat.sqlite
