#!/bin/bash

# 1. Install database server
apt-get update
debconf-set-selections <<< 'mysql-server mysql-server/root_password password secure'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password secure'
apt-get install -qqy mariadb-server

# 2. Configure remote access
sed -i.bak "s/127.0.0.1/192.168.50.11/g" /etc/mysql/my.cnf
sed -i.bak "s/key_buffer/#key_buffer/g" /etc/mysql/my.cnf
sed -i.bak "s/myisam-recover/#myisam-recover/g" /etc/mysql/my.cnf
service mysql restart

#echo -e "\nY\nsecure\nsecure\nY\n" | mysql_secure_installation

# 3 Create OpenStack databases

# 3.1 Create Keystone database
echo "CREATE DATABASE keystone;" >> create_keystone.sql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'secure';" >> create_keystone.sql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'secure';" >> create_keystone.sql

mysql -uroot -psecure < create_keystone.sql

# 3.2 Create Glance database
echo "CREATE DATABASE glance CHARACTER SET utf8 COLLATE utf8_general_ci;" >> create_glance.sql
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
