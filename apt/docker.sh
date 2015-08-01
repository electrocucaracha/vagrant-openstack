#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_all-in-one.sh

# Install docker
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y mariadb-client python-keystoneclient python-glanceclient
curl -sSL https://get.docker.com/ubuntu/ | sudo sh

# Install compose
curl -L https://github.com/docker/compose/releases/download/1.1.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker build -t electrocucaracha/openstack-database /home/vagrant/docker/database
docker build -t electrocucaracha/openstack-identity /home/vagrant/docker/identity
docker build -t electrocucaracha/openstack-image /home/vagrant/docker/image

docker run -d --name message-broker rabbitmq:latest
docker run -d -v /var/lib/mysql --name db-volume ubuntu:latest

sleep 5

docker run -d --volumes-from db-volume --name keystone-db -e MYSQL_ROOT_PASSWORD=secure electrocucaracha/openstack-database:latest
docker run -d --volumes-from db-volume --name glance-db -e MYSQL_ROOT_PASSWORD=secure electrocucaracha/openstack-database:latest
docker run -d --volumes-from db-volume --name nova-db -e MYSQL_ROOT_PASSWORD=secure electrocucaracha/openstack-database:latest
docker run -d --volumes-from db-volume --name cinder-db -e MYSQL_ROOT_PASSWORD=secure electrocucaracha/openstack-database:latest

sleep 5

docker run -d --link keystone-db:database --name keystone electrocucaracha/openstack-identity keystone-all
docker run -d --link glance-db:database   --name glance-registry electrocucaracha/openstack-image glance-registry
docker run -d --name glance-api electrocucaracha/openstack-image glance-api

sleep 5

docker exec message-broker rabbitmqctl change_password guest secure

keystone_db_ip=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' keystone-db`
mysql -h $keystone_db_ip -psecure << END
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'secure';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'secure';
END
docker exec keystone rm /var/lib/keystone/keystone.db
docker exec keystone su -s /bin/sh -c "keystone-manage db_sync" keystone

sqlite="sqlite:////var/lib/keystone/keystone.db"
mysql="mysql://keystone:secure@database/keystone"
sed -i "s/${sqlite//\//\\/}/${mysql//\//\\/}/g" keystone.conf
token=`openssl rand -hex 10`
sed -i "s/#admin_token=ADMIN/admin_token=${token}/g" keystone.conf
 
docker restart keystone

export SERVICE_TOKEN="${token}"
export SERVICE_ENDPOINT=http://$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' keystone):35357/v2.0

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

# 10. Create OpenStack services

# 10.1 Keystone service
keystone service-create --name=keystone --type=identity --description="OpenStack Identity Service"

# 10.2 Glance service
keystone service-create --name=glance --type=image --description="OpenStack Image Service"

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

glance_db_ip=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' glance-db`
mysql -h $glance_db_ip -psecure << END
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'secure';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'secure';
END
sqlite="sqlite:////var/lib/glance/glance.sqlite"
mysql="mysql://glance:secure@database/glance"
sed -i "s/${sqlite//\//\\/}/${mysql//\//\\/}/g" glance-registry.conf
docker exec glance-registry rm -f /var/lib/glance/glance.sqlite
docker exec glance-registry su -s /bin/sh -c "glance-manage db_sync" glance

sed -i "s/identity_uri = http:\/\/127.0.0.1:35357/identity_uri = http:\/\/identity:35357/g" glance-api.conf
sed -i "s/%SERVICE_TENANT_NAME%/service/g" glance-api.conf
sed -i "s/%SERVICE_USER%/glance/g" glance-api.conf
sed -i "s/%SERVICE_PASSWORD%/secure/g" glance-api.conf
sed -i "s/#flavor=/flavor=keystone/g" glance-api.conf

sed -i "s/identity_uri = http:\/\/127.0.0.1:35357/identity_uri = http:\/\/identity:35357/g" glance-registry.conf
sed -i "s/%SERVICE_TENANT_NAME%/service/g" glance-registry.conf
sed -i "s/%SERVICE_USER%/glance/g" glance-registry.conf
sed -i "s/%SERVICE_PASSWORD%/secure/g" glance-registry.conf
sed -i "s/#flavor=/flavor=keystone/g" glance-registry.conf

docker restart glance-registry
docker restart glance-api
