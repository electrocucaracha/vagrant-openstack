#!/bin/bash

apt-get install -y software-properties-common python-software-properties
add-apt-repository -y cloud-archive:mitaka
if [ -f /root/shared/sources.list ]
then
  cp /root/scripts/sources.list /etc/apt/sources.list
fi
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini python-mysqldb python-openstackclient

if [ "$CONFIGURATION" !=  "_all-in-one" ]
then
  apt-get install -y mysql-client
fi
