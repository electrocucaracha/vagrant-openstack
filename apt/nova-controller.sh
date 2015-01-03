#!/bin/bash

# 0. Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install OpenStack Compute Controller Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

# 2. Configure Nova Service
echo "my_ip = ${my_ip}" >> /etc/nova/nova.conf
echo "vncserver_listen = ${my_ip}" >> /etc/nova/nova.conf
echo "vncserver_proxyclient_address = ${my_ip}" >> /etc/nova/nova.conf
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = message-broker" >> /etc/nova/nova.conf
echo "auth_strategy = keystone" >> /etc/nova/nova.conf

# 3. Configure Database driver
echo "" >> /etc/nova/nova.conf
echo "[database]" >> /etc/nova/nova.conf
echo "connection = mysql://nova:secure@database/nova" >> /etc/nova/nova.conf

# 4. Configure Authentication
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = secure" >> /etc/nova/nova.conf
echo "auth_port = 35357" >> /etc/nova/nova.conf
echo "auth_host = identity" >> /etc/nova/nova.conf
echo "auth_protocol = http" >> /etc/nova/nova.conf
echo "auth_uri = http://identity:5000/" >> /etc/nova/nova.conf

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
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
