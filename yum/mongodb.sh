#!/bin/bash

cd /root/shared
source configure.sh
cd setup

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
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf
echo "smallfiles = true" >> /etc/mongod.conf

# 3. Start services
service mongod start
chkconfig mongod on

sleep 5
