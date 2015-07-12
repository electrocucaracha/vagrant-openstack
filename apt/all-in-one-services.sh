#!/bin/bash

# 0. Post-installation
export CONFIGURATION="_all-in-one"
cd /root/shared
source configure.sh
cd setup

apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main" >>  /etc/apt/sources.list.d/kilo.list
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini

# Message broker

# 1. Install database server
apt-get install -y rabbitmq-server

./create_rabbit_user.sh

# Database

# 1. Install database server
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${ROOT_DBPASS}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${ROOT_DBPASS}"
apt-get install -y mariadb-server python-mysqldb

# 2. Configure remote access
sed -i "s/127.0.0.1/${my_ip}/g" /etc/mysql/my.cnf
sed -i "s/\[mysqld\]/\[mysqld\]\ndefault-storage-engine = innodb\ninnodb_file_per_table\ncollation-server = utf8_general_ci\ninit-connect = 'SET NAMES utf8'\ncharacter-set-server = utf8/g" /etc/mysql/my.cnf

service mysql restart

sleep 5

echo -e "${ROOT_DBPASS}\nn\nY\nY\n\Y\n" | mysql_secure_installation

# 1. Install database server
apt-get install -y mongodb-server mongodb-clients python-pymongo

# 2. Configure database server
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongodb.conf
echo "smallfiles = true" >> /etc/mongodb.conf

# 3. Restart the service
service mongodb stop
rm -f /var/lib/mongodb/journal/prealloc.*
service mongodb restart

sleep 5

# Identity Service

# 0. Disable the keystone service from starting automatically after installation
echo "manual" > /etc/init/keystone.override

# 1. Install OpenStack Identity Service and dependencies
apt-get install -y keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache

./keystone.sh
echo "ServerName ${IDENTITY_HOSTNAME}">> /etc/apache2/apache2.conf
cat <<EOL > /etc/apache2/sites-available/wsgi-keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
        ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
         ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>
EOL
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled

# 6. Restart service
service apache2 restart

sleep 5

./create_initial_accounts.sh
rm -f /var/lib/keystone/keystone.db

# Image Service

# 1. Install OpenStack Image Service and dependencies
apt-get install -y glance python-glanceclient

./glance.sh
rm -f /var/lib/glance/glance.sqlite

# 2. Restart services
service glance-registry restart
service glance-api restart

sleep 5

./upload_cirros_image.sh

# Compute services

# 1. Install OpenStack Compute Controller Service and dependencies
apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

./nova.sh
rm /var/lib/nova/nova.sqlite

# 6. Restart services
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

# Controller - Networking services

./setup_legacy_network_controller.sh

service nova-api restart
service nova-scheduler restart
service nova-conductor restart

# Compute - Networking services

apt-get install -y  nova-network

./setup_legacy_network_compute.sh

service nova-network restart

nova network-create demo-net --bridge br100 --fixed-range-v4 203.0.113.24/29

# Dashboard

# 1. Install OpenStack Dashboard and dependencies
apt-get install -y openstack-dashboard

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${IDENTITY_HOSTNAME}\"/g" /etc/openstack-dashboard/local_settings.py

# 3. Restart services
service apache2 restart

# Block Storage services

# 1. Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-api cinder-scheduler python-cinderclient

./cinder.sh
su -s /bin/sh -c "cinder-manage db sync" cinder

# 6. Enable and start services
service cinder-scheduler restart
service cinder-api restart

# Object Storage Service

apt-get install -y swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached

./swift.sh


# Compute services

# 1. Install compute packages
apt-get install -y  nova-compute sysfsutils

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  sed -i "s/kvm/qemu/g" /etc/nova/nova-compute.conf
fi

# 6.1 Enable libvirt tcp port for live-migration
sed -i "s/#listen_tls = 0/listen_tls = 0/g" /etc/libvirt/libvirtd.conf
sed -i "s/#listen_tcp = 1/listen_tcp = 1/g" /etc/libvirt/libvirtd.conf
sed -i "s/^#listen_addr = .*/listen_addr = \"0.0.0.0\"/g" /etc/libvirt/libvirtd.conf
sed -i "s/#auth_tcp = \"sasl\"/auth_tcp = \"none\"/g" /etc/libvirt/libvirtd.conf

sed -i "s/libvirtd_opts=\"-d\"/libvirtd_opts=\"-l -d\"/g" /etc/default/libvirt-bin 
service libvirt-bin restart

# 8. Restart service
service nova-compute restart


# Linux container services

apt-get install -y git python-dev

# 1. Install nova-docker
git clone https://github.com/stackforge/nova-docker /tmp/nova-docker
pushd /tmp/nova-docker
git checkout stable/kilo
cp etc/nova/rootwrap.d/docker.filters /etc/nova/rootwrap.d
curl https://bootstrap.pypa.io/get-pip.py | python
pip install .
popd

# 2. Configure nova-docker driver
touch /etc/nova/nova-docker.conf

crudini --set /etc/nova/nova-docker.conf DEFAULT host docker${CONFIGURATION}
crudini --set /etc/nova/nova-docker.conf DEFAULT compute_driver novadocker.virt.docker.DockerDriver
crudini --set /etc/nova/nova-docker.conf DEFAULT state_path /var/lib/nova-docker
crudini --set /etc/nova/nova-docker.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova-docker.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/nova/nova-docker.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova-docker.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

chown nova:nova /etc/nova/nova-docker.conf

cat <<EOL > /etc/init/nova-docker.conf
# vim: set ft=upstart et ts=2:
description "Nova compute docker worker"
author "Victor Morales <electrocucaracha@gmail.com>"

start on runlevel [2345]
stop on runlevel [!2345]

exec start-stop-daemon --start --chuid root --exec /usr/bin/nova-compute -- --config-file=/etc/nova/nova-docker.conf
EOL

# 3. Install docker
curl -sSL https://get.docker.com/ubuntu/ | sudo sh

# Glance formats
crudini --set /etc/glance/glance-api.conf DEFAULT container_formats ami,ari,aki,bare,ovf,ova,docker

service nova-docker restart
service glance-api restart

docker pull larsks/thttpd
docker save larsks/thttpd | glance image-create --is-public True --container-format docker \
  --disk-format raw --name larsks/thttpd

# Logical volume

# 1. Install Logical Volume Manager
apt-get install -y lvm2

# 2. Create a partition based on other partition
cat <<EOL > /tmp/sdb.layout
# partition table of /dev/sdb
unit: sectors

/dev/sdb1 : start=     2048, size= 83884032, Id=83, bootable
/dev/sdb2 : start=        0, size=        0, Id= 0
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOL
sfdisk /dev/sdb < /tmp/sdb.layout

# 3. Create the LVM physical volume /dev/sdb1
pvcreate /dev/sdb1

# 4. Create the LVM volume group cinder-volumes
vgcreate cinder-volumes /dev/sdb1

# 5. Add a filter that accepts the /dev/sdb device and rejects all other devices
sed -i "s/filter = \[ \"a\/.*\/\"/filter = \[ \"a\/sdb\/\", \"r\/.\*\/\"/g" /etc/lvm/lvm.conf

# 6. Install OpenStack Block Storage Service and dependencies
apt-get install -y cinder-volume python-mysqldb

./block-storage.sh
rm -f /var/lib/cinder/cinder.sqlite

# 11. Restart services
service tgt restart
service cinder-volume restart

# Storage node
apt-get install -y xfsprogs rsync

# Create a partition 
cat <<EOL > /tmp/sdc.layout
# partition table of /dev/sdc
unit: sectors

/dev/sdc1 : start=     2048, size= 83884032, Id=83, bootable
/dev/sdc2 : start=        0, size=        0, Id= 0
/dev/sdc3 : start=        0, size=        0, Id= 0
/dev/sdc4 : start=        0, size=        0, Id= 0
EOL
sfdisk /dev/sdc < /tmp/sdc.layout

# Format the partition
mkfs.xfs /dev/sdc1

# Mount the partition
mkdir -p /srv/node/sdc1
echo "/dev/sdc1 /srv/node/sdc1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab
mount /srv/node/sdc1

cat <<EOL > /etc/rsyncd.conf
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = ${my_ip}
 
[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock
 
[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock
 
[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock
EOL

sed -i "s/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g" /etc/default/rsync

service rsync start

apt-get install -y  swift swift-account swift-container swift-object

./swift-storage.sh
./create_initial.sh
./configure_hashes_storage_policy.sh

service memcached restart
service swift-proxy restart

swift-init all start

# Orchestration service

apt-get install -y  heat-api heat-api-cfn heat-engine python-heatclient

./heat.sh

service heat-api restart
service heat-api-cfn restart
service heat-engine restart

rm -f /var/lib/heat/heat.sqlite

# Metering service

# 1. Install OpenStack Telemetry Controller Service and dependencies

apt-get install -y ceilometer-api ceilometer-collector ceilometer-agent-central ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier python-ceilometerclient python-awsauth

./ceilometer.sh 

sleep 5

# 6. Restart service
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart

# Configure telemetry services

# Compute Node

apt-get install -y ceilometer-agent-compute

./configure_ceilometer_compute.sh

service ceilometer-agent-compute restart
service nova-compute restart

# Image Controller

./configure_ceilometer_image.sh

service glance-registry restart
service glance-api restart

# Block Storage Controller

./configure_ceilometer_block_storage_controller.sh

service cinder-api restart
service cinder-scheduler restart

# Block Storage Node

./configure_ceilometer_block_storage.sh

service cinder-volume restart

# Object Storage Controller

# Workaround for https://bugs.launchpad.net/openstack-manuals/+bug/1462947
apt-get install -y python-pip
pip install ceilometermiddleware==0.1.0

./configure_ceilometer_object_storage_controller.sh

service swift-proxy restart
