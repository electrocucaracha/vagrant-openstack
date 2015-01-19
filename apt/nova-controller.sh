#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install OpenStack Compute Controller Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

# 2. Configure Nova Service
echo "my_ip = ${my_ip}" >> /etc/nova/nova.conf
echo "novncproxy_host = 0.0.0.0" >> /etc/nova/nova.conf
echo "novncproxy_port = 6080" >> /etc/nova/nova.conf
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = message-broker" >> /etc/nova/nova.conf
echo "rabbit_password = secure" >> /etc/nova/nova.conf
echo "auth_strategy = keystone" >> /etc/nova/nova.conf

# 3. Configure Database driver
echo "" >> /etc/nova/nova.conf
echo "[database]" >> /etc/nova/nova.conf
echo "connection = mysql://nova:secure@database/nova" >> /etc/nova/nova.conf

# 4. Configure Authentication
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "identity_uri = http://identity:35357" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = secure" >> /etc/nova/nova.conf

echo "" >> /etc/nova/nova.conf
echo "[paste_deploy]" >> /etc/nova/nova.conf
echo "flavor = keystone" >> /etc/nova/nova.conf

echo "" >> /etc/nova/nova.conf
echo "[glance]" >> /etc/nova/nova.conf
echo "host = image" >> /etc/nova/nova.conf

# 4. Remove default database file
rm /var/lib/nova/nova.sqlite

# 5. Generate tables
apt-get install -y python-mysqldb
su -s /bin/sh -c "nova-manage db sync" nova

# 6. Restart services
service nova-api stop
service nova-cert stop
service nova-consoleauth stop
service nova-scheduler stop
service nova-conductor stop
service nova-novncproxy stop

sleep 5
service nova-api start
sleep 15
service nova-cert start
service nova-consoleauth start
service nova-scheduler start
sleep 5
service nova-conductor start
service nova-novncproxy start
