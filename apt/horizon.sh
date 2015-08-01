#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get install -y ubuntu-cloud-keyring
cat << EOL > /etc/apt/sources.list.d/kilo.list
deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main
EOL
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini

# Dashboard

# 1. Install OpenStack Dashboard and dependencies
apt-get install -y openstack-dashboard

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${IDENTITY_HOSTNAME}\"/g" /etc/openstack-dashboard/local_settings.py

# 3. Restart services
service apache2 restart
