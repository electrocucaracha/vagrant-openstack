#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh

# 1. Install nosql database server
cat <<EOL > /etc/yum.repos.d/mongodb.repo
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
EOL
yum -y upgrade
yum install -y mongodb-org

# 2. Configure remote access
sed -i "s/127.0.0.1/${my_ip}/g" /etc/mongod.conf
echo "smallfiles = true" >> /etc/mongod.conf

# 3. Start services
service mongod start
chkconfig mongod on

sleep 5

# 4. Create ceilometer database
mongo --host nosql-database --eval '
db = db.getSiblingDB("ceilometer");
db.createUser({user: "ceilometer",
pwd: "secure",
roles: [ "readWrite", "dbAdmin" ]})'
