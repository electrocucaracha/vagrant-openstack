#!/bin/bash

# 1. Install OpenStack Image Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get --no-install-recommends -qqy install ubuntu-cloud-keyring
apt-get update
apt-get --no-install-recommends -qqy install glance python-glanceclient

# 2. Configure Database driver
sqlite="sqlite:////var/lib/glance/glance.sqlite"
mysql="mysql://glance:secure@192.168.50.11/glance"
sed -i.bak "s/#connection = <None>/connection=${mysql//\//\\/}/g" /etc/glance/glance-registry.conf

# 3. Remove default database file
rm -f /var/lib/glance/glance.sqlite

# 4. Generate tables
apt-get --no-install-recommends -qqy install python-mysqldb
su -s /bin/sh -c "glance-manage db_sync" glance

# 5. Configurate authorization token
sed -i.bak "s/auth_host = 127.0.0.1/auth_host = 192.168.50.12/g" /etc/glance/glance-api.conf
sed -i.bak "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/glance-api.conf
sed -i.bak "s/%SERVICE_USER%/glance/g" /etc/glance/glance-api.conf
sed -i.bak "s/%SERVICE_PASSWORD%/secure/g" /etc/glance/glance-api.conf
sed -i.bak "s/#flavor=/flavor=keystone/g" /etc/glance/glance-api.conf

sed -i.bak "s/auth_host = 127.0.0.1/auth_host = 192.168.50.12/g" /etc/glance/glance-registry.conf
sed -i.bak "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/glance-registry.conf
sed -i.bak "s/%SERVICE_USER%/glance/g" /etc/glance/glance-registry.conf
sed -i.bak "s/%SERVICE_PASSWORD%/secure/g" /etc/glance/glance-registry.conf
sed -i.bak "s/#flavor=/flavor=keystone/g" /etc/glance/glance-registry.conf

# 6. Restart services
service glance-registry restart
service glance-api restart
