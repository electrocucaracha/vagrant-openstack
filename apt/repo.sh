#!/bin/bash

apt-get install -y ubuntu-cloud-keyring
cp /root/scripts/sources.list /etc/apt/sources.list
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini python-mysqldb python-openstackclient

if [ "$CONFIGURATION" !=  "_all-in-one" ]
then
  apt-get install -y mysql-client
fi
