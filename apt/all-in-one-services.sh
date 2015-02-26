#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_all-in-one.sh
echo "source /root/shared/openstackrc-all-in-one" >> /root/.bashrc

apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update && apt-get dist-upgrade

# Message broker

# 1. Install database server
apt-get install -y rabbitmq-server

# 2. Change default guest user password
rabbitmqctl change_password guest secure

# Database

# 1. Install database server
debconf-set-selections <<< 'mysql-server mysql-server/root_password password secure'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password secure'
apt-get install -y mariadb-server

# 2. Configure remote access
sed -i "s/127.0.0.1/${my_ip}/g" /etc/mysql/my.cnf
sed -i "s/\[mysqld\]/\[mysqld\]\ndefault-storage-engine = innodb\ninnodb_file_per_table\ncollation-server = utf8_general_ci\ninit-connect = 'SET NAMES utf8'\ncharacter-set-server = utf8/g" /etc/mysql/my.cnf

service mysql restart

echo -e "secure\nn\nY\nY\n\Y\n" | mysql_secure_installation

# 3 Create OpenStack databases

# 3.1 Create Keystone database
echo "CREATE DATABASE keystone;" >> create_keystone.sql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'secure';" >> create_keystone.sql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'secure';" >> create_keystone.sql

mysql -uroot -psecure < create_keystone.sql

# 3.2 Create Glance database
echo "CREATE DATABASE glance;" >> create_glance.sql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'secure';" >> create_glance.sql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'secure';" >> create_glance.sql

mysql -uroot -psecure < create_glance.sql

# 3.3 Create Nova database
echo "CREATE DATABASE nova;" >> create_nova.sql
echo "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'secure';" >> create_nova.sql
echo "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'secure';" >> create_nova.sql

mysql -uroot -psecure < create_nova.sql

# 3.4 Create Cinder database
echo "CREATE DATABASE cinder;" >> create_cinder.sql
echo "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'secure';" >> create_cinder.sql
echo "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'secure';" >> create_cinder.sql

mysql -uroot -psecure < create_cinder.sql

# 1. Install database server
apt-get install -y mongodb-server

# 2. Configure database server
sed -i "s/127.0.0.1/${my_ip}/g" /etc/mongodb.conf
echo "smallfiles = true" >> /etc/mongodb.conf

# 3. Restart the service
service mongodb stop
rm /var/lib/mongodb/journal/prealloc.*
service mongodb start

sleep 5

# 4. Create ceilometer database
mongo --host all-in-one --eval '
db = db.getSiblingDB("ceilometer");
db.createUser({user: "ceilometer",
pwd: "secure",
roles: [ "readWrite", "dbAdmin" ]})'

# Identity services

# 1. Install OpenStack Identity Service and dependencies
apt-get install -y keystone python-keystoneclient

# 2. Configure Database driver
sqlite="sqlite:////var/lib/keystone/keystone.db"
mysql="mysql://keystone:secure@all-in-one/keystone"
sed -i "s/${sqlite//\//\\/}/${mysql//\//\\/}/g" /etc/keystone/keystone.conf

# 3. Remove default database file
rm /var/lib/keystone/keystone.db

# 4. Generate tables
apt-get install -y python-mysqldb
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 5. Configurate authorization token
token=`openssl rand -hex 10`
sed -i "s/#admin_token=ADMIN/admin_token=${token}/g" /etc/keystone/keystone.conf

# 6. Restart service
service keystone restart

sleep 5
export SERVICE_TOKEN="${token}"
export SERVICE_ENDPOINT=http://all-in-one:35357/v2.0

# 7. Create OpenStack tenants
keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"

# 8. Create OpenStack roles
keystone role-create --name=admin

# 9. Create OpenStack users

# 9.1 Keystone user
keystone user-create --name=admin --pass=secure --email=admin@example.com
keystone user-role-add --user=admin --tenant=admin --role=admin

# 9.2 Glance user
keystone user-create --name=glance --pass=secure --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin

# 9.3 Nova user
keystone user-create --name=nova --pass=secure --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin

# 9.4 Cinder user
keystone user-create --name=cinder --pass=secure --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

# 9.5 Ceilometer user
keystone user-create --name=ceilometer --pass=secure --email=ceilometer@example.com
keystone user-role-add --user=ceilometer --tenant=service --role=admin

# 10. Create OpenStack services

# 10.1 Keystone service
keystone service-create --name=keystone --type=identity --description="OpenStack Identity Service"

# 10.2 Glance service
keystone service-create --name=glance --type=image --description="OpenStack Image Service"

# 10.3 Nova service
keystone service-create --name=nova --type=compute --description="OpenStack Compute Service"

# 10.4 Cinder service
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage Service"
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage Service"

# 10.5 Ceilometer service
keystone service-create --name=ceilometer --type=metering --description="OpenStack Metering Service"

# 11. Create OpenStack endpoints

# 11.1 Keystone endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl=http://all-in-one:5000/v2.0 \
  --internalurl=http://all-in-one:5000/v2.0 \
  --adminurl=http://all-in-one:35357/v2.0 \
  --region=regionOne

# 11.2 Glance endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ image / {print $2}') \
  --publicurl=http://all-in-one:9292 \
  --internalurl=http://all-in-one:9292 \
  --adminurl=http://all-in-one:9292 \
  --region=regionOne

# 11.3 Nova endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl=http://all-in-one:8774/v2/%\(tenant_id\)s \
  --internalurl=http://all-in-one:8774/v2/%\(tenant_id\)s \
  --adminurl=http://all-in-one:8774/v2/%\(tenant_id\)s \
  --region=regionOne

# 11.4 Cinder endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volume / {print $2}') \
  --publicurl=http://all-in-one:8776/v1/%\(tenant_id\)s \
  --internalurl=http://all-in-one:8776/v1/%\(tenant_id\)s \
  --adminurl=http://all-in-one:8776/v1/%\(tenant_id\)s \
  --region=regionOne

keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
  --publicurl=http://all-in-one:8776/v2/%\(tenant_id\)s \
  --internalurl=http://all-in-one:8776/v2/%\(tenant_id\)s \
  --adminurl=http://all-in-one:8776/v2/%\(tenant_id\)s \
  --region=regionOne

# 11.5 Ceilometer endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ metering / {print $2}') \
  --publicurl=http://all-in-one:8777 \
  --internalurl=http://all-in-one:8777 \
  --adminurl=http://all-in-one:8777 \
  --region=regionOne

# Image Service

# 1. Install OpenStack Image Service and dependencies
apt-get install -y glance python-glanceclient

# 2. Configure Database driver
sqlite="sqlite:////var/lib/glance/glance.sqlite"
mysql="mysql://glance:secure@all-in-one/glance"
sed -i "s/#connection = <None>/connection=${mysql//\//\\/}/g" /etc/glance/glance-registry.conf

# 3. Remove default database file
rm -f /var/lib/glance/glance.sqlite

# 4. Generate tables
apt-get install -y python-mysqldb
su -s /bin/sh -c "glance-manage db_sync" glance

# 5. Configurate authorization token
sed -i "s/identity_uri = http:\/\/127.0.0.1:35357/identity_uri = http:\/\/all-in-one:35357/g" /etc/glance/glance-api.conf
sed -i "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/glance-api.conf
sed -i "s/%SERVICE_USER%/glance/g" /etc/glance/glance-api.conf
sed -i "s/%SERVICE_PASSWORD%/secure/g" /etc/glance/glance-api.conf
sed -i "s/#flavor=/flavor=keystone/g" /etc/glance/glance-api.conf

sed -i "s/identity_uri = http:\/\/127.0.0.1:35357/identity_uri = http:\/\/all-in-one:35357/g" /etc/glance/glance-registry.conf
sed -i "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/glance-registry.conf
sed -i "s/%SERVICE_USER%/glance/g" /etc/glance/glance-registry.conf
sed -i "s/%SERVICE_PASSWORD%/secure/g" /etc/glance/glance-registry.conf
sed -i "s/#flavor=/flavor=keystone/g" /etc/glance/glance-registry.conf

# 6. Restart services
service glance-registry restart
service glance-api restart

sleep 5

source /root/.bashrc
apt-get install -y python-glanceclient
wget http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
glance image-create --name cirrus --file cirros-0.3.3-x86_64-disk.img --disk-format qcow2  --container-format bare --is-public True

# Compute services

# 1. Install OpenStack Compute Controller Service and dependencies
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

# 2. Configure Nova Service
echo "my_ip = ${my_ip}" >> /etc/nova/nova.conf
echo "novncproxy_host = 0.0.0.0" >> /etc/nova/nova.conf
echo "novncproxy_port = 6080" >> /etc/nova/nova.conf
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = all-in-one" >> /etc/nova/nova.conf
echo "rabbit_password = secure" >> /etc/nova/nova.conf
echo "auth_strategy = keystone" >> /etc/nova/nova.conf

# 3. Configure Database driver
echo "" >> /etc/nova/nova.conf
echo "[database]" >> /etc/nova/nova.conf
echo "connection = mysql://nova:secure@all-in-one/nova" >> /etc/nova/nova.conf

# 4. Configure Authentication
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "identity_uri = http://all-in-one:35357" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = secure" >> /etc/nova/nova.conf

echo "" >> /etc/nova/nova.conf
echo "[paste_deploy]" >> /etc/nova/nova.conf
echo "flavor = keystone" >> /etc/nova/nova.conf

echo "" >> /etc/nova/nova.conf
echo "[glance]" >> /etc/nova/nova.conf
echo "host = all-in-one" >> /etc/nova/nova.conf

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

# Controller - Networking services

sed -i "s/\[DEFAULT\]/\[DEFAULT\]\nnetwork_api_class = nova.network.api.API\nsecurity_group_api = nova/g" /etc/nova/nova.conf

service nova-api restart
service nova-scheduler restart
service nova-conductor restart

# Compute - Networking services

apt-get install -y  nova-network

sed -i "s/\[DEFAULT\]/\[DEFAULT\]\nnetwork_manager=nova.network.manager.FlatDHCPManager\nfirewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver\npublic_interface=eth0\nvlan_interface=eth0\nflat_network_bridge=br100\nflat_interface=eth0/g" /etc/nova/nova.conf

service nova-network restart

nova network-create demo-net --bridge br100 --fixed-range-v4 203.0.113.24/29

# Dashboard

# 1. Install OpenStack Dashboard and dependencies
apt-get install -y openstack-dashboard apache2 libapache2-mod-wsgi memcached python-memcache

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"all-in-one\"/g" /etc/openstack-dashboard/local_settings.py

# 3. Restart services
service apache2 restart
service memcached restart

# Block Storage services

# 1. Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-api cinder-scheduler python-cinderclient

# 2. Configure message broker service
echo "rabbit_host = all-in-one" >> /etc/cinder/cinder.conf
echo "rabbit_password = secure" >> /etc/cinder/cinder.conf
echo "auth_strategy = keystone" >> /etc/cinder/cinder.conf

echo "my_ip = ${my_ip}" >> /etc/cinder/cinder.conf

# 3. Configure Identity Service
echo "auth_strategy = keystone" >> /etc/cinder/cinder.conf
echo "" >> /etc/cinder/cinder.conf
echo "[keystone_authtoken]" >> /etc/cinder/cinder.conf
echo "identity_uri = http://all-in-one:35357" >> /etc/cinder/cinder.conf
echo "admin_tenant_name = service" >> /etc/cinder/cinder.conf
echo "admin_user = cinder" >> /etc/cinder/cinder.conf
echo "admin_password = secure" >> /etc/cinder/cinder.conf

# 4. Configure Database driver
echo "" >> /etc/cinder/cinder.conf
echo "[database]" >> /etc/cinder/cinder.conf
echo "connection = mysql://cinder:secure@all-in-one/cinder" >> /etc/cinder/cinder.conf

# 5. Generate tables
apt-get install -y python-mysqldb
rm -f /var/lib/cinder/cinder.sqlite
su -s /bin/sh -c "cinder-manage db sync" cinder

# 6. Enable and start services
service cinder-scheduler restart
service cinder-api restart

# Metering services

# 1. Install OpenStack Telemetry Controller Service and dependencies
apt-get install -y ceilometer-api ceilometer-collector ceilometer-agent-central ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier python-ceilometerclient

# 2. Configure database connection
sed -i "s/#connection=<None>/connection = mongodb:\/\/ceilometer:secure@all-in-one:27017\/ceilometer/g" /etc/ceilometer/ceilometer.conf

# 3. Configure message broker connection
sed -i "s/#rpc_backend=rabbit/rpc_backend = rabbit/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#rabbit_host=localhost/rabbit_host = all-in-one/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#rabbit_password=guest/rabbit_password = secure/g" /etc/ceilometer/ceilometer.conf

# 4. Configure OpenStack Identity service
sed -i "s/#auth_uri=<None>/auth_uri = http:\/\/all-in-one:5000\/v2.0/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#identity_uri=<None>/identity_uri = http:\/\/all-in-one:35357\/v2.0/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#admin_tenant_name=admin/admin_tenant_name = service/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#admin_user=<None>/admin_user = ceilometer/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#admin_password=<None>/admin_password = secure/g" /etc/ceilometer/ceilometer.conf

# 5. Configure service
sed -i "s/#os_auth_url=http:\/\/localhost:5000\/v2.0/os_auth_url=http:\/\/all-in-one:5000\/v2.0/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#os_username=ceilometer/os_username = ceilometer/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#os_tenant_name=admin/os_tenant_name = admin/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#os_password=admin/os_password = secure/g" /etc/ceilometer/ceilometer.conf

token=`openssl rand -hex 10`
sed -i "s/#metering_secret=change this or be hacked/metering_secret = ${token}/g" /etc/ceilometer/ceilometer.conf

# 6. Restart service
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart

# Compute services

# 1. Install compute packages
apt-get install -y  nova-compute sysfsutils

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  sed -i "s/kvm/qemu/g" /etc/nova/nova-compute.conf
fi

# 7. Remove default database file
rm /var/lib/nova/nova.sqlite

# 8. Restart service
service nova-compute restart

# Logical volume

# 1. Install Logical Volume Manager
apt-get install -y lvm2

# 2. Create a partition based on other partition
cat <<EOL > sdb.layout
# partition table of /dev/sdb
unit: sectors

/dev/sdb1 : start=     2048, size= 83884032, Id=83, bootable
/dev/sdb2 : start=        0, size=        0, Id= 0
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOL
sfdisk /dev/sdb < sdb.layout

# 3. Create the LVM physical volume /dev/sdb1
pvcreate /dev/sdb1

# 4. Create the LVM volume group cinder-volumes
vgcreate cinder-volumes /dev/sdb1

# 5. Add a filter that accepts the /dev/sdb device and rejects all other devices
sed -i "s/filter = \[ \"a\/.*\/\"/filter = \[ \"a\/sdb\/\", \"r\/.\*\/\"/g" /etc/lvm/lvm.conf

# 6. Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-volume python-mysqldb

# 7. Configure message broker service
echo "rpc_backend = rabbit" >> /etc/cinder/cinder.conf
echo "rabbit_host = all-in-one" >> /etc/cinder/cinder.conf
echo "rabbit_password = secure" >> /etc/cinder/cinder.conf

echo "my_ip = ${my_ip}" >> /etc/cinder/cinder.conf

# 8. Configure Identity Service
#echo "auth_strategy = keystone" >> /etc/cinder/cinder.conf
echo "" >> /etc/cinder/cinder.conf
echo "[keystone_authtoken]" >> /etc/cinder/cinder.conf
echo "identity_uri = http://all-in-one:35357" >> /etc/cinder/cinder.conf
echo "admin_tenant_name = service" >> /etc/cinder/cinder.conf
echo "admin_user = cinder" >> /etc/cinder/cinder.conf
echo "admin_password = secure" >> /etc/cinder/cinder.conf

# 9. Configure Database driver
echo "" >> /etc/cinder/cinder.conf
echo "[database]" >> /etc/cinder/cinder.conf
echo "connection = mysql://cinder:secure@all-in-one/cinder" >> /etc/cinder/cinder.conf

# 10. Configure Image Service
echo "" >> /etc/cinder/cinder.conf
echo "[glance]" >> /etc/cinder/cinder.conf
echo "host = all-in-one" >> /etc/cinder/cinder.conf

# 11. Restart services
service tgt restart
service cinder-volume restart

# 12. Remove unnecessary files
rm -f /var/lib/cinder/cinder.sqlite
