#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_all-in-one.sh
echo "source /root/shared/openstackrc-all-in-one" >> /root/.bashrc

yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y

# 1. Install message broker server
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

yum install -y erlang

wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.2/rabbitmq-server-3.2.2-1.noarch.rpm
rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
yum install -y rabbitmq-server-3.2.2-1.noarch.rpm

# 2. Enable and start service
chkconfig rabbitmq-server on
/sbin/service rabbitmq-server start

# 3. Change default guest user password
rabbitmqctl change_password guest secure

# Database

# 1. Install database server
yum install -y mariadb-server

# 2. Configure remote access
cat <<EOL > /etc/my.cnf
[mysqld]
bind-address = ${my_ip}
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
symbolic-links=0

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

!includedir /etc/my.cnf.d
EOL
systemctl enable mariadb.service
systemctl start mariadb.service

echo -e "\nY\nsecure\nsecure\nY\n" | mysql_secure_installation

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

# NoSQL Database

# 1. Install nosql database server
cat <<EOL > /etc/yum.repos.d/mongodb.repo
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOL
yum -y upgrade
yum install -y mongodb-org

# 2. Configure remote access
sed -i "s/127.0.0.1/${my_ip}/g" /etc/mongod.conf
echo "smallfiles = true" >> /etc/mongod.conf

# 3. Start services
service mongod start
chkconfig mongod on

sleep 5

# 4. Create ceilometer database
mongo --host all-in-one --eval '
db = db.getSiblingDB("ceilometer");
db.createUser({user: "ceilometer",
pwd: "secure",
roles: [ "readWrite", "dbAdmin" ]})'

# Identity Service

# 1. Install OpenStack Identity Service and dependencies
yum install -y openstack-keystone python-keystoneclient

# 2. Configure Database driver
crudini --set /etc/keystone/keystone.conf database connection  mysql://keystone:secure@all-in-one/keystone

# 3. Generate certificates and restrict access
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl

# 4. Generate tables
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 5. Configurate authorization token
token=`openssl rand -hex 10`
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token ${token}

# 6. Restart service
systemctl enable openstack-keystone.service
systemctl start openstack-keystone.service

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
  --publicurl=http://all-in-one:8774/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --internalurl=http://all-in-one:8774/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --adminurl=http://all-in-one:8774/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --region=regionOne

# 11.4 Cinder endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volume / {print $2}') \
  --publicurl=http://all-in-one:8776/v1/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --internalurl=http://all-in-one:8776/v1/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --adminurl=http://all-in-one:8776/v1/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --region=regionOne

keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
  --publicurl=http://all-in-one:8776/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --internalurl=http://all-in-one:8776/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --adminurl=http://all-in-one:8776/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --region=regionOne

# 11.5 Ceilometer endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ metering / {print $2}') \
  --publicurl=http://all-in-one:8777 \
  --internalurl=http://all-in-one:8777 \
  --adminurl=http://all-in-one:8777 \
  --region=regionOne

# Image services

# 1. Install OpenStack Identity Service and dependencies
yum install -y openstack-glance python-glanceclient

# 2. Configure api service
crudini --set /etc/glance/glance-api.conf database connection  mysql://glance:secure@all-in-one/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://all-in-one:5000/v2.0
crudini --set /etc/glance/glance-api.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_user glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken admin_password secure
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

# 3. Configure registry service
crudini --set /etc/glance/glance-registry.conf database connection  mysql://glance:secure@all-in-one/glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://all-in-one:5000/v2.0
crudini --set /etc/glance/glance-registry.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_user glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken admin_password secure
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

# 4. Generate tables
su -s /bin/sh -c "glance-manage db_sync" glance

# 5. Enable and start services
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service

# Compute controller services

# 1. Install OpenStack Compute Service and dependencies
yum install -y openstack-nova-api openstack-nova-cert openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler python-novaclient

# 2. Configure Nova Service
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_host 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_port 6080
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host all-in-one
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password secure
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone

# 3. Configure Database driver
crudini --set /etc/nova/nova.conf database connection mysql://nova:secure@all-in-one/nova

# 4. Configure Authentication
crudini --set /etc/nova/nova.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password secure

crudini --set /etc/nova/nova.conf paste_deploy flavor keystone

crudini --set /etc/nova/nova.conf glance host image

# 5. Generate tables
su -s /bin/sh -c "nova-manage db sync" nova

# 6. Enable and start services
systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

# OpenStack Dashboard

# 1. Install OpenStack Compute Service and dependencies
yum install -y openstack-dashboard httpd mod_wsgi memcached python-memcached

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"all-in-one\"/g" /etc/openstack-dashboard/local_settings

# 3. Configure memcached
sed -i "s/'django.core.cache.backends.locmem.LocMemCache'/'django.core.cache.backends.memcached.MemcachedCache',\n        'LOCATION': '127.0.0.1:11211'/g" /etc/openstack-dashboard/local_settings

# 4. Configure SELinux to permit the web server to connect
setsebool -P httpd_can_network_connect on

# Block storage service

# 4. Configure SELinux to permit the web server to connect
setsebool -P httpd_can_network_connect on

# 5. Solve the CSS issue
chown -R apache:apache /usr/share/openstack-dashboard/static

# 6. Enable services
systemctl enable httpd.service memcached.service
systemctl start httpd.service memcached.service

# 1. Install OpenStack Block Storage Service and dependencies
yum install -y openstack-cinder python-cinderclient python-oslo-db

# 1.1 Workaround for cinder-api dependency
yum install -y python-keystonemiddleware

# 2. Configure Database driver
crudini --set /etc/cinder/cinder.conf database connection  mysql://cinder:secure@all-in-one/cinder

# 3. Configure message broker service
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_host all-in-one
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_password secure

# 4. Configure Identity Service
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://all-in-one:5000/v2.0
crudini --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_password secure

crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}

# 5. Generate tables
su -s /bin/sh -c "cinder-manage db sync" cinder

# 6. Enable and start services
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service

# Telemetry service

# 1. Install OpenStack Telemetry Service and dependencies
yum install -y openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central openstack-ceilometer-alarm python-ceilometerclient

# 2. Configure database connection
crudini --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:secure@all-in-one:27017/ceilometer

# 3. Configure message broker connection
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT rabbit_host all-in-one
crudini --set /etc/ceilometer/ceilometer.conf rabbit_password secure
crudini --set /etc/ceilometer/ceilometer.conf auth_strategy keystone

# 4. Configure authentication
crudini --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://all-in-one:5000/v2.0
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_user ceilometer
crudini --set /etc/ceilometer/ceilometer.conf keystone_authtoken admin_password secure

# 5 Configure service credentials
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_auth_url http://all-in-one:35357
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_username ceilometer
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_tenant_name service
crudini --set /etc/ceilometer/ceilometer.conf service_credentials os_password secure

token=`openssl rand -hex 10`
crudini --set /etc/ceilometer/ceilometer.conf publisher metering_secret ${token}

systemctl enable openstack-ceilometer-api.service openstack-ceilometer-notification.service  openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service
systemctl start openstack-ceilometer-api.service openstack-ceilometer-notification.service openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service

# Compute Service

# 1. Install OpenStack Compute Service and dependencies
yum install -y openstack-nova-compute sysfsutils

# 2. Configure message broker service
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host all-in-one
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password secure

# 3. Configure VNC Server
crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen 127.0.0.1
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address 127.0.0.1
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://all-in-one:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}

# 4. Configure Identity Service
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://all-in-one:5000/v2.0
crudini --set /etc/nova/nova.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password secure

# 5. Configure Image Service
crudini --set /etc/nova/nova.conf glance host all-in-one

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  crudini --set /etc/nova/nova.conf libvirt virt_type qemu
fi

# 7. Restart services
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service
systemctl start openstack-nova-compute.service

# Logical Volume

# 1. Install Logical Volume Manager
yum install -y lvm2

# 1.1 Enable the LVM services
systemctl enable lvm2-lvmetad.service
systemctl start lvm2-lvmetad.service

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

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-cinder targetcli python-oslo-db MySQL-python

# 2. Configure Database driver
crudini --set /etc/cinder/cinder.conf database connection  mysql://cinder:secure@all-in-one/cinder

# 3. Configure message broker service
crudini --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_host all-in-one
crudini --set /etc/cinder/cinder.conf DEFAULT rabbit_password secure

# 4. Configure Identity Service
crudini --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
crudini --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://all-in-one:5000/v2.0
crudini --set /etc/cinder/cinder.conf keystone_authtoken identity_uri http://all-in-one:35357
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_user cinder
crudini --set /etc/cinder/cinder.conf keystone_authtoken admin_password secure

crudini --set /etc/cinder/cinder.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/cinder/cinder.conf DEFAULT glance_host all-in-one
#crudini --set /etc/cinder/cinder.conf DEFAULT iscsi_helper lioadm
crudini --set /etc/cinder/cinder.conf DEFAULT iscsi_helper tgtadm

# 5. Start services
systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service
