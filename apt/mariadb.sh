#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get update -y && apt-get dist-upgrade -y

# 1. Install database server
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${ROOT_DBPASS}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${ROOT_DBPASS}"
apt-get install -y mariadb-server

# 2. Configure remote access
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mysql/my.cnf
sed -i "s/\[mysqld\]/\[mysqld\]\ndefault-storage-engine = innodb\ninnodb_file_per_table\ncollation-server = utf8_general_ci\ninit-connect = 'SET NAMES utf8'\ncharacter-set-server = utf8/g" /etc/mysql/my.cnf

service mysql restart

sleep 5

echo -e "${ROOT_DBPASS}\nn\nY\nY\nY\n" | mysql_secure_installation

mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists keystone;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists glance;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists nova;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists nova_api;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists neutron;"
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
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'${COMPUTE_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'${NETWORKING_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${NEUTRON_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'${BLOCK_STORAGE_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${CINDER_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'${ORCHESTRATION_HOSTNAME}' IDENTIFIED BY '${HEAT_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON trove.* TO 'trove'@'${DATABASE_CONTROLLER_HOSTNAME}' IDENTIFIED BY '${TROVE_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON sahara.* TO 'sahara'@'${DATA_HOSTNAME}' IDENTIFIED BY '${SAHARA_DBPASS}';"
