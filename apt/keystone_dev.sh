#!/bin/bash

# 0. Declare variables
token=`openssl rand -hex 10`
echo "export SERVICE_TOKEN=${token}" >> openrc
echo "export SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0" >> openrc

# 1. Install prerequisites
apt-get update
apt-get install --no-install-recommends -qqy git screen python-pip python-virtualenv python-dev libxml2-dev libxslt1-dev libsasl2-dev libsqlite3-dev libssl-dev libldap2-dev libffi-dev

# 2. Clone repository
git clone https://github.com/openstack/keystone.git
cd keystone

# 3. Configure settings
python tools/install_venv.py
cp etc/keystone.conf.sample etc/keystone.conf
sed -i.bak "s/#admin_token=ADMIN/admin_token=${token}/g" etc/keystone.conf

# 4. Synchronize tables
tools/with_venv.sh bin/keystone-manage db_sync

screen -dmS "keystone_service" tools/with_venv.sh bin/keystone-all
