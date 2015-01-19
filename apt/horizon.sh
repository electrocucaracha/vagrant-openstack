#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install OpenStack Dashboard and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get install -y ubuntu-cloud-keyring
apt-get update && apt-get dist-upgrade
apt-get install -y openstack-dashboard apache2 libapache2-mod-wsgi memcached python-memcache

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"identity\"/g" /etc/openstack-dashboard/local_settings.py

# 3. Restart services
service apache2 restart
service memcached restart
