#!/bin/bash

# 1. Install prerequisites
apt-get update
apt-get install --no-install-recommends -qqy git screen python-pip python-virtualenv python-dev libxml2-dev libxslt1-dev libsasl2-dev libsqlite3-dev libldap2-dev libffi-dev libmysqlclient-dev libpq-dev curl
#apt-get build-dep -y glance

# 2. Clone repository
git clone https://github.com/openstack/glance.git
cd glance

# 3. Install python dependencies
python tools/install_venv.py
. .venv/bin/activate
python setup.py develop

# 4. Configuration files
sed -i "s/\/var\/log\/glance\/api.log/api.log/g" etc/glance-api.conf
sed -i "s/\/var\/log\/glance\/registry.log/registry.log/g" etc/glance-registry.conf
sed -i "s/#connection = <None>/connection=sqlite:\/\/\/glance-api.db/g" etc/glance-api.conf
sed -i "s/#connection = <None>/connection=sqlite:\/\/\/glance-registry.db/g" etc/glance-registry.conf

# 5. Synchronize tables
glance-manage --config-file etc/glance-registry.conf db_sync
glance-manage --config-file etc/glance-api.conf db_sync

# 6. Start services
screen -dmS "glance_api_service" tools/with_venv.sh glance-api --config-file etc/glance-api.conf --debug
screen -dmS "glance_registry_service" tools/with_venv.sh glance-registry --config-file etc/glance-registry.conf --debug
