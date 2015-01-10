#!/bin/bash

# 0. Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install OpenStack Identity Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y keystone python-keystoneclient

# 2. Configure Database driver
sqlite="sqlite:////var/lib/keystone/keystone.db"
mysql="mysql://keystone:secure@database/keystone"
sed -i "s/${sqlite//\//\\/}/${mysql//\//\\/}/g" /etc/keystone/keystone.conf 

# 3. Remove default database file
rm /var/lib/keystone/keystone.db

# 4. Generate tables
apt-get install -y python-mysqldb
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 5. Configurate authorization token
token=`openssl rand -hex 10`
sed -i "s/#admin_token=ADMIN/admin_token=${token}/g" /etc/keystone/keystone.conf 

# 6. Restart service
service keystone restart

sleep 5
export SERVICE_TOKEN="${token}"
export SERVICE_ENDPOINT=http://localhost:35357/v2.0

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

# 9.4 Cinder user
keystone user-create --name=cinder --pass=secure --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

# 10. Create OpenStack services

# 10.1 Keystone service
keystone service-create --name=keystone --type=identity --description="OpenStack Identity Service"

# 10.2 Glance service
keystone service-create --name=glance --type=image --description="OpenStack Image Service"

# 10.3 Nova service
keystone service-create --name=nova --type=compute --description="OpenStack Compute Service"

# 10.4 Cinder service
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage Service"
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage Service"

# 11. Create OpenStack endpoints

# 11.1 Keystone endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ identity / {print $2}') \
  --publicurl=http://identity:5000/v2.0 \
  --internalurl=http://identity:5000/v2.0 \
  --adminurl=http://identity:35357/v2.0 \
  --region=regionOne

# 11.2 Glance endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ image / {print $2}') \
  --publicurl=http://image:9292 \
  --internalurl=http://image:9292 \
  --adminurl=http://image:9292 \
  --region=regionOne

# 11.3 Nova endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ compute / {print $2}') \
  --publicurl=http://compute-controller:8774/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --internalurl=http://compute-controller:8774/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --adminurl=http://compute-controller:8774/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --region=regionOne

# 11.4 Cinder endpoint
keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volume / {print $2}') \
  --publicurl=http://block-storage-controller:8776/v1/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --internalurl=http://block-storage-controller:8776/v1/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --adminurl=http://block-storage-controller:8776/v1/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --region=regionOne

keystone endpoint-create \
  --service_id=$(keystone service-list | awk '/ volumev2 / {print $2}') \
  --publicurl=http://block-storage-controller:8776/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --internalurl=http://block-storage-controller:8776/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --adminurl=http://block-storage-controller:8776/v2/$(keystone tenant-list | awk '/ admin / {print $2}') \
  --region=regionOne
