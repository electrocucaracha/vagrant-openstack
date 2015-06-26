#!/bin/bash

# 1. Database creation
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE if not exists keystone;"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"

# 2. Configure Database driver
crudini --set /etc/keystone/keystone.conf database connection mysql://keystone:${KEYSTONE_DBPASS}@${DATABASE_HOSTNAME}/keystone
crudini --set /etc/keystone/keystone.conf revoke driver keystone.contrib.revoke.backends.sql.Revoke

# 2.1 Configure Memcached
crudini --set /etc/keystone/keystone.conf memcache servers localhost:11211
crudini --set /etc/keystone/keystone.conf memcache provider keystone.token.providers.uuid.Provider
crudini --set /etc/keystone/keystone.conf memcache driver keystone.token.persistence.backends.memcache.Token

# 3. Generate tables
su -s /bin/sh -c "keystone-manage db_sync" keystone

mkdir -p /var/www/cgi-bin/keystone
wget -O /var/www/cgi-bin/keystone/main http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo
cp /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin

chown -R keystone:keystone /var/www/cgi-bin/keystone
chmod 755 /var/www/cgi-bin/keystone/*

# 5. Configurate authorization token
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token ${token}
