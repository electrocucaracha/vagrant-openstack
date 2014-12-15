#!/bin/bash

# 1. Install OpenStack Identity Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get --no-install-recommends -qqy install ubuntu-cloud-keyring
apt-get update
apt-get --no-install-recommends -qqy install keystone python-keystoneclient

# 2. Configure Database driver
sqlite="sqlite:////var/lib/keystone/keystone.db"
mysql="mysql://keystone:secure@192.168.50.11/keystone"
sed -i.bak "s/${sqlite//\//\\/}/${mysql//\//\\/}/g" /etc/keystone/keystone.conf 

# 3. Remove default database file
rm /var/lib/keystone/keystone.db

# 4. Generate tables
apt-get --no-install-recommends -qqy install python-mysqldb
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 5. Configurate authorization token
token=`openssl rand -hex 10`
sed -i.bak "s/#admin_token=ADMIN/admin_token=${token}/g" /etc/keystone/keystone.conf 

# 6. Restart service
service keystone restart

sleep 5
export SERVICE_TOKEN="${token}"
export SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0

# 7. Create OpenStack tenants
keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"

# 8. Create OpenStack roles
keystone role-create --name=admin

# 9. Create OpenStack users

# 9.1 Keystone user
keystone user-create --name=admin --pass=secure --email=admin@example.com
keystone user-role-add --user=admin --tenant=admin --role=admin

# 9.2 Glance user
keystone user-create --name=glance --pass=secure --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin

# 9.3 Nova user
keystone user-create --name=nova --pass=secure --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin

# 9.4 Neutron user
keystone user-create --name=neutron --pass=secure --email=neutron@example.com
keystone user-role-add --user=neutron --tenant=service --role=admin

# 10. Create OpenStack services

# 10.1 Keystone service
keystone service-create --name=keystone --type=identity --description="OpenStack Identity Service"

# 10.2 Glance service
keystone service-create --name=glance --type=image --description="OpenStack Image Service"

# 10.3 Nova service
keystone service-create --name=nova --type=compute --description="OpenStack Compute Service"

# 10.4 Nova service
keystone service-create --name=neutron --type=network --description="OpenStack Networking Service"

# 11. Create OpenStack endpoints

# 11.1 Keystone endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl=http://192.168.50.12:5000/v2.0 \
  --internalurl=http://192.168.50.12:5000/v2.0 \
  --adminurl=http://192.168.50.12:35357/v2.0

# 11.2 Glance endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ image / {print $2}') \
  --publicurl=http://192.168.50.13:9292 \
  --internalurl=http://192.168.50.13:9292 \
  --adminurl=http://192.168.50.13:9292

# 11.3 Nova endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl=http://192.168.50.14:8774 \
  --internalurl=http://192.168.50.14:8774 \
  --adminurl=http://192.168.50.14:8774

# 11.4 Neutron endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ network / {print $2}') \
  --publicurl=http://192.168.50.16:9696 \
  --internalurl=http://192.168.50.16:9696 \
  --adminurl=http://192.168.50.16:9696
