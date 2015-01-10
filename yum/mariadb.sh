#!/bin/bash

# 0. Workaround for vagrant boxes
sed -i "s/10.0.2.3/8.8.8.8/g" /etc/resolv.conf

my_ip=$(ip addr | awk '/enp0s8$/ { sub(/\/24/, "", $2); print $2}')

# 1. Install database server
yum -y upgrade
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
