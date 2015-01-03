#!/bin/bash

my_ip=$(ip addr | awk '/eth1$/ { sub(/\/24/, "", $2); print $2}')

# 1. Install database server
apt-get update
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

# 3.4 Create Neutron database
echo "CREATE DATABASE neutron;" >> create_neutron.sql
echo "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'secure';" >> create_neutron.sql
echo "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'secure';" >> create_neutron.sql

mysql -uroot -psecure < create_neutron.sql
