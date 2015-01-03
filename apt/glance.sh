#!/bin/bash

# 0. Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install OpenStack Image Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y glance python-glanceclient

# 2. Configure Database driver
sqlite="sqlite:////var/lib/glance/glance.sqlite"
mysql="mysql://glance:secure@database/glance"
sed -i "s/#connection = <None>/connection=${mysql//\//\\/}/g" /etc/glance/glance-registry.conf

# 3. Remove default database file
rm -f /var/lib/glance/glance.sqlite

# 4. Generate tables
apt-get install -y python-mysqldb
su -s /bin/sh -c "glance-manage db_sync" glance

# 5. Configurate authorization token
sed -i "s/identity_uri = http:\/\/127.0.0.1:35357/identity_uri = http:\/\/identity:35357/g" /etc/glance/glance-api.conf
sed -i "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/glance-api.conf
sed -i "s/%SERVICE_USER%/glance/g" /etc/glance/glance-api.conf
sed -i "s/%SERVICE_PASSWORD%/secure/g" /etc/glance/glance-api.conf
sed -i "s/#flavor=/flavor=keystone/g" /etc/glance/glance-api.conf

sed -i "s/identity_uri = http:\/\/127.0.0.1:35357/identity_uri = http:\/\/identity:35357/g" /etc/glance/glance-registry.conf
sed -i "s/%SERVICE_TENANT_NAME%/service/g" /etc/glance/glance-registry.conf
sed -i "s/%SERVICE_USER%/glance/g" /etc/glance/glance-registry.conf
sed -i "s/%SERVICE_PASSWORD%/secure/g" /etc/glance/glance-registry.conf
sed -i "s/#flavor=/flavor=keystone/g" /etc/glance/glance-registry.conf

# 6. Restart services
service glance-registry restart
service glance-api restart
