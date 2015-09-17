#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install database server
yum -y upgrade
yum install -y mariadb-server

# 2. Configure remote access
cat <<EOL > /etc/my.cnf.d/mariadb_openstack.cnf 
[mysqld]
bind-address = 0.0.0.0
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
EOL
systemctl enable mariadb.service
systemctl start mariadb.service

sleep 5

echo -e "\nY\n${ROOT_DBPASS}\n${ROOT_DBPASS}\nY\n" | mysql_secure_installation

mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists keystone;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists glance;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists nova;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists cinder;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists heat;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists trove;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists sahara;"

if [ "$CONFIGURATION" !=  "_all-in-one" ]
then
  mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.50.%' IDENTIFIED BY '${ROOT_DBPASS}';FLUSH PRIVILEGES;"
fi

mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'${IDENTITY_HOSTNAME}' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'${IMAGE_HOSTNAME}' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'${COMPUTE_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'${BLOCK_STORAGE_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${CINDER_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'${ORCHESTRATION_HOSTNAME}' IDENTIFIED BY '${HEAT_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON trove.* TO 'trove'@'${DATABASE_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${TROVE_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON sahara.* TO 'sahara'@'${DATA_HOSTNAME}' IDENTIFIED BY '${SAHARA_DBPASS}';"
