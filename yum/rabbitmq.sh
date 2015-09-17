#!/bin/bash

cd /root/shared
source configure.sh
cd setup

version='3.5.1'

# 1. Install message broker server
yum -y update

yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y http://packages.erlang-solutions.com/site/esl/esl-erlang/FLAVOUR_1_general/esl-erlang_18.0-1~centos~7_amd64.rpm
yum update -y
yum install -y erlang

yum install -y http://www.rabbitmq.com/releases/rabbitmq-server/v$version/rabbitmq-server-$version-1.noarch.rpm
yum update -y
rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
yum install -y rabbitmq-server

# 2. Enable and start service
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

./create_rabbit_user.sh
