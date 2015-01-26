#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh

# 1. Install database server
apt-get update
apt-get install -y mongodb-server

# 2. Configure database server
sed -i "s/127.0.0.1/${my_ip}/g" /etc/mongodb.conf
echo "smallfiles = true" >> /etc/mongodb.conf

# 3. Restart the service
service mongodb stop
rm /var/lib/mongodb/journal/prealloc.*
service mongodb start

sleep 5

# 4. Create ceilometer database
mongo --host nosql-database --eval '
db = db.getSiblingDB("ceilometer");
db.createUser({user: "ceilometer",
pwd: "secure",
roles: [ "readWrite", "dbAdmin" ]})'
