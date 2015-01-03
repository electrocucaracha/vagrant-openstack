# 1. Install OpenStack Compute Controller Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

# 2. Configure Nova Service
echo "my_ip = 192.168.50.14" >> /etc/nova/nova.conf
echo "vncserver_listen = 192.168.50.14" >> /etc/nova/nova.conf
echo "vncserver_proxyclient_address = 192.168.50.14" >> /etc/nova/nova.conf
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = 192.168.50.10" >> /etc/nova/nova.conf
echo "auth_strategy = keystone" >> /etc/nova/nova.conf

# 3. Configure Database driver
echo "" >> /etc/nova/nova.conf
echo "[database]" >> /etc/nova/nova.conf
echo "connection = mysql://nova:secure@192.168.50.11/nova" >> /etc/nova/nova.conf

# 4. Configure Authentication
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = secure" >> /etc/nova/nova.conf
echo "auth_port = 35357" >> /etc/nova/nova.conf
echo "auth_host = 192.168.50.12" >> /etc/nova/nova.conf
echo "auth_protocol = http" >> /etc/nova/nova.conf
echo "auth_uri = http://192.168.50.12:5000/" >> /etc/nova/nova.conf

echo "" >> /etc/nova/nova.conf
echo "[paste_deploy]" >> /etc/nova/nova.conf
echo "flavor = keystone" >> /etc/nova/nova.conf

echo "" >> /etc/nova/nova.conf
echo "[glance]" >> /etc/nova/nova.conf
echo "host = 192.168.50.13" >> /etc/nova/nova.conf

# 4. Remove default database file
rm /var/lib/nova/nova.sqlite

# 5. Generate tables
apt-get install -y python-mysqldb
su -s /bin/sh -c "nova-manage db sync" nova

# 6. Enable and start services
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
