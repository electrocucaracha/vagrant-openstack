#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install database server
apt-get install -y mongodb-server

# 2. Configure database server
sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongodb.conf
echo "smallfiles = true" >> /etc/mongodb.conf

# 3. Restart the service
service mongodb stop
rm -f /var/lib/mongodb/journal/prealloc.*
service mongodb restart

sleep 5
