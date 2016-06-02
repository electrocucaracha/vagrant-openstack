#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

add-apt-repository -y ppa:ubuntu-lxc/lxd-git-master
apt-get update -y
apt-get install -y lxd git python-dev

# 1. Install nova-docker
git clone https://github.com/lxc/nova-lxd /tmp/nova-lxd
pushd /tmp/nova-lxd
git checkout stable/mitaka
cp etc/nova/rootwrap.d/lxd.filters /etc/nova/rootwrap.d
curl https://bootstrap.pypa.io/get-pip.py | python
pip install .
popd

# 2. Configure nova-compute-lxd driver
touch /etc/nova/nova-compute-lxd.conf

crudini --set /etc/nova/nova-compute-lxd.conf DEFAULT host lxd${CONFIGURATION}
crudini --set /etc/nova/nova-compute-lxd.conf DEFAULT compute_driver nova_lxd.nova.virt.lxd.LXDDriver
crudini --set /etc/nova/nova-compute-lxd.conf DEFAULT state_path /var/lib/nova-compute-lxd
crudini --set /etc/nova/nova-compute-lxd.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova-compute-lxd.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/nova/nova-compute-lxd.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova-compute-lxd.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

chown nova:nova /etc/nova/nova-compute-lxd.conf

cat <<EOL > /etc/init/nova-compute-lxd.conf
# vim: set ft=upstart et ts=2:
description "Nova compute LXD worker"
author "Victor Morales <electrocucaracha@gmail.com>"

start on runlevel [2345]
stop on runlevel [!2345]

exec start-stop-daemon --start --chuid root --exec /usr/bin/nova-compute -- --config-file=/etc/nova/nova-compute-lxd.conf
EOL

service nova-compute-lxd restart

# Add images
curl -o /tmp/xenial-server.tar.gz http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-root.tar.gz
glance image-create --name xenial --disk-format raw --container-format bare --file /tmp/xenial-server.tar.gz
