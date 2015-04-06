#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install OpenStack Block Storage Service and dependencies
apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update && apt-get dist-upgrade

apt-get install -y cinder-api cinder-scheduler python-cinderclient

# 2. Configure message broker service
echo "rabbit_host = message-broker" >> /etc/cinder/cinder.conf
echo "rabbit_password = secure" >> /etc/cinder/cinder.conf
echo "auth_strategy = keystone" >> /etc/cinder/cinder.conf

echo "my_ip = ${my_ip}" >> /etc/cinder/cinder.conf

# 3. Configure Identity Service
echo "auth_strategy = keystone" >> /etc/cinder/cinder.conf
echo "" >> /etc/cinder/cinder.conf
echo "[keystone_authtoken]" >> /etc/cinder/cinder.conf
echo "identity_uri = http://identity:35357" >> /etc/cinder/cinder.conf
echo "admin_tenant_name = service" >> /etc/cinder/cinder.conf
echo "admin_user = cinder" >> /etc/cinder/cinder.conf
echo "admin_password = secure" >> /etc/cinder/cinder.conf

# 4. Configure Database driver
echo "" >> /etc/cinder/cinder.conf
echo "[database]" >> /etc/cinder/cinder.conf
echo "connection = mysql://cinder:secure@database/cinder" >> /etc/cinder/cinder.conf

# 5. Generate tables
apt-get install -y python-mysqldb
rm -f /var/lib/cinder/cinder.sqlite
su -s /bin/sh -c "cinder-manage db sync" cinder

# 6. Enable and start services
service cinder-scheduler restart
service cinder-api restart
