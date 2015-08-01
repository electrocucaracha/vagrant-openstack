#!/bin/bash

cd /root/shared
source configure.sh
cd setup

apt-get install -y ubuntu-cloud-keyring
cat << EOL > /etc/apt/sources.list.d/kilo.list
deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kilo main
EOL
apt-get update -y && apt-get dist-upgrade -y

apt-get install -y crudini python-mysqldb mysql-client

# Compute - Networking services

apt-get install -y nova-network

./setup_legacy_network_compute.sh

service nova-network restart

nova network-create demo-net --bridge br100 --fixed-range-v4 203.0.113.24/29

# Compute - Telemetry services

apt-get install -y ceilometer-agent-compute

./configure_ceilometer_compute.sh

service ceilometer-agent-compute restart
service nova-compute restart

# Compute services

# 1. Install compute packages
apt-get install -y  nova-compute sysfsutils

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  sed -i "s/kvm/qemu/g" /etc/nova/nova-compute.conf
fi

# 6.1 Enable libvirt tcp port for live-migration
sed -i "s/#listen_tls = 0/listen_tls = 0/g" /etc/libvirt/libvirtd.conf
sed -i "s/#listen_tcp = 1/listen_tcp = 1/g" /etc/libvirt/libvirtd.conf
sed -i "s/^#listen_addr = .*/listen_addr = \"0.0.0.0\"/g" /etc/libvirt/libvirtd.conf
sed -i "s/#auth_tcp = \"sasl\"/auth_tcp = \"none\"/g" /etc/libvirt/libvirtd.conf

sed -i "s/libvirtd_opts=\"-d\"/libvirtd_opts=\"-l -d\"/g" /etc/default/libvirt-bin
service libvirt-bin restart

# 8. Restart service
service nova-compute restart

# Linux container services

apt-get install -y git python-dev

# 1. Install nova-docker
git clone https://github.com/stackforge/nova-docker /tmp/nova-docker
pushd /tmp/nova-docker
git checkout stable/kilo
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
curl -sSL https://get.docker.com/ubuntu/ | sudo sh

# Glance formats
crudini --set /etc/glance/glance-api.conf DEFAULT container_formats ami,ari,aki,bare,ovf,ova,docker

service nova-docker restart
service glance-api restart

docker pull larsks/thttpd

docker save larsks/thttpd | glance image-create --is-public True --container-format docker \
      --disk-format raw --name larsks/thttpd

# LXD

add-apt-repository -y ppa:ubuntu-lxc/lxd-git-master
apt-get update -y
apt-get install -y lxd git python-dev

# 1. Install nova-docker
git clone https://github.com/lxc/nova-compute-lxd /tmp/nova-compute-lxd
pushd /tmp/nova-compute-lxd
git checkout stable/kilo
cp etc/nova/rootwrap.d/lxd.filters /etc/nova/rootwrap.d
curl https://bootstrap.pypa.io/get-pip.py | python
pip install .
popd

# 2. Configure nova-compute-lxd driver
touch /etc/nova/nova-compute-lxd.conf

crudini --set /etc/nova/nova-compute-lxd.conf DEFAULT host lxd${CONFIGURATION}
crudini --set /etc/nova/nova-compute-lxd.conf DEFAULT compute_driver nclxd.nova.virt.lxd.LXDDriver
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
wget -O vivid-server-cloudimg-amd64-root.tar.gz https://cloud-images.ubuntu.com/vivid/current/ vivid-server-cloudimg-amd64-root.tar.gz
glance image-create --name='lxc' --container-format=bare --disk-format=raw --file=vivid-server-cloudimg-amd64-root.tar.gz
