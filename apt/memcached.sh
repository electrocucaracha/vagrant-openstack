#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get update -y

# Memcached service

# 1. Install memcached service
apt-get install -y memcached python-memcache

# 2. Configure to listen a specific service
sed -i "s/-l 127.0.0.1/-l 0.0.0.0/g" /etc/memcached.conf

service memcached restart
