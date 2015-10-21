#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Dashboard

# 1. Install OpenStack Dashboard and dependencies
apt-get install -y openstack-dashboard

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${IDENTITY_HOSTNAME}\"/g" /etc/openstack-dashboard/local_settings.py

# 3. Restart services
service apache2 reload
