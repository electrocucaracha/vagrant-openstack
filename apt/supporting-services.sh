#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_group.sh

apt-get update

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
mongo --host supporting-services --eval '
db = db.getSiblingDB("ceilometer");
db.addUser({user: "ceilometer",
pwd: "secure",
roles: [ "readWrite", "dbAdmin" ]})'
