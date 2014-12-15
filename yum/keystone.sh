#!/bin/bash

# 0. Workaround for vagrant boxes
sed -i "s/10.0.2.3/8.8.8.8/g" /etc/resolv.conf

# 1. Install OpenStack Identity Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-keystone python-keystoneclient

# 2. Configure Database driver
crudini --set /etc/keystone/keystone.conf database connection  mysql://keystone:secure@192.168.50.11/keystone

# 3. Generate certificates and restrict access
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
chown -R keystone:keystone /var/log/keystone
chown -R keystone:keystone /etc/keystone/ssl
chmod -R o-rwx /etc/keystone/ssl

# 4. Generate tables
su -s /bin/sh -c "keystone-manage db_sync" keystone

# 5. Configurate authorization token
token=`openssl rand -hex 10`
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token ${token}

# 6. Restart service
systemctl enable openstack-keystone.service
systemctl start openstack-keystone.service

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