#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh

# 1. Install message broker server
yum -y update

wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

yum install -y erlang

wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.2.2/rabbitmq-server-3.2.2-1.noarch.rpm
rpm --import http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
yum install -y rabbitmq-server-3.2.2-1.noarch.rpm

# 2. Enable and start service
chkconfig rabbitmq-server on
/sbin/service rabbitmq-server start

# 3. Change default guest user password
rabbitmqctl change_password guest secure
