#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
export my_nic=`ip route | awk '/192./ { print $3 }'`
export my_ip=`ip addr | awk "/${my_nic}\$/ { sub(/\/24/, \"\","' $2); print $2}'`

yum install -y deltarpm
yum update -y
yum install -y https://rdo.fedorapeople.org/rdo-release.rpm
yum install -y openstack-packstack

ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
token=`openssl rand -hex 10`
yum install -y yum-plugin-priorities
cat <<EOL > packstack-answer.txt
[general]
CONFIG_SSH_KEY=/root/.ssh/id_rsa.pub
CONFIG_DEFAULT_PASSWORD=secure
CONFIG_REPO=https://repos.fedorapeople.org/repos/openstack/openstack-juno/epel-7/

CONFIG_MARIADB_INSTALL=y
CONFIG_MARIADB_HOST=${my_ip}
CONFIG_MARIADB_USER=root
CONFIG_MARIADB_PW=secure
CONFIG_KEYSTONE_DB_PW=secure
CONFIG_GLANCE_DB_PW=secure
CONFIG_NOVA_DB_PW=secure

CONFIG_KEYSTONE_REGION=RegionOne
CONFIG_KEYSTONE_ADMIN_TOKEN=${token}

CONFIG_KEYSTONE_ADMIN_PW=secure
CONFIG_KEYSTONE_DEMO_PW=secure
CONFIG_GLANCE_KS_PW=secure
CONFIG_NOVA_KS_PW=secure

CONFIG_KEYSTONE_TOKEN_FORMAT=UUID
CONFIG_KEYSTONE_SERVICE_NAME=keystone

CONFIG_GLANCE_INSTALL=y
CONFIG_PROVISION_CIRROS_URL=http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img

CONFIG_NOVA_INSTALL=y
CONFIG_NOVA_COMPUTE_MIGRATE_PROTOCOL=tcp
CONFIG_NOVA_NETWORK_MANAGER=nova.network.manager.FlatDHCPManager
CONFIG_NOVA_NETWORK_PUBIF=${my_nic}
CONFIG_NOVA_NETWORK_PRIVIF=${my_nic}
CONFIG_NOVA_COMPUTE_PRIVIF=${my_nic}
CONFIG_NOVA_NETWORK_FIXEDRANGE=203.0.113.24/29

CONFIG_HORIZON_INSTALL=y
CONFIG_CLIENT_INSTALL=y
CONFIG_CONTROLLER_HOST=${my_ip}
CONFIG_COMPUTE_HOSTS=${my_ip}
CONFIG_AMQP_BACKEND=rabbitmq
CONFIG_AMQP_HOST=${my_ip}
CONFIG_AMQP_AUTH_PASSWORD=secure

CONFIG_CINDER_INSTALL=n
CONFIG_NEUTRON_INSTALL=n
CONFIG_SWIFT_INSTALL=n
CONFIG_CEILOMETER_INSTALL=n
CONFIG_HEAT_INSTALL=n
CONFIG_SAHARA_INSTALL=n
CONFIG_TROVE_INSTALL=n
CONFIG_IRONIC_INSTALL=n
CONFIG_NAGIOS_INSTALL=n
EOL

packstack --answer-file=packstack-answer.txt

#packstack --gen-answer-file=all-in-one.txt
