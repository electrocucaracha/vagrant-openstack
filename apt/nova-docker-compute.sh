#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Linux container services

apt-get install -y git python-dev

# 1. Install nova-docker
git clone https://github.com/stackforge/nova-docker /tmp/nova-docker
pushd /tmp/nova-docker
git checkout stable/mitaka
cp etc/nova/rootwrap.d/docker.filters /etc/nova/rootwrap.d
curl https://bootstrap.pypa.io/get-pip.py | python
pip install .
popd

# 2. Configure nova-docker driver
touch /etc/nova/nova-docker.conf

crudini --set /etc/nova/nova-docker.conf DEFAULT host docker${CONFIGURATION}
crudini --set /etc/nova/nova-docker.conf DEFAULT compute_driver novadocker.virt.docker.DockerDriver
crudini --set /etc/nova/nova-docker.conf DEFAULT state_path /var/lib/nova-docker
crudini --set /etc/nova/nova-docker.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova-docker.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/nova/nova-docker.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova-docker.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

chown nova:nova /etc/nova/nova-docker.conf

cat <<EOL > /etc/init/nova-docker.conf
# vim: set ft=upstart et ts=2:
description "Nova compute docker worker"
author "Victor Morales <electrocucaracha@gmail.com>"

start on runlevel [2345]
stop on runlevel [!2345]

exec start-stop-daemon --start --chuid root --exec /usr/bin/nova-compute -- --config-file=/etc/nova/nova-docker.conf
EOL

# 3. Install docker
curl -sSL https://get.docker.com/ | sudo sh
usermod -aG docker vagrant

# Glance formats
crudini --set /etc/glance/glance-api.conf DEFAULT container_formats ami,ari,aki,bare,ovf,ova,docker

service nova-docker restart
service glance-api restart

docker pull larsks/thttpd

docker save larsks/thttpd | glance image-create --visibility public --container-format docker \
      --disk-format raw --name larsks/thttpd
