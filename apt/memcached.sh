#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get update -y && apt-get dist-upgrade -y

# Memcached service

# 1. Install database server
apt-get install -y memcached python-memcache

service memcached restart
