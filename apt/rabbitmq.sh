#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get update -y
apt-get install -y crudini

# Message broker

# 1. Install database server
apt-get install -y rabbitmq-server

./create_rabbit_user.sh
