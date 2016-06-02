#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Compute services

# 1. Install compute packages
apt-get install -y nova-compute

./nova-compute.sh

# Enable libvirt tcp port for live-migration
sed -i "s/#listen_tls = 0/listen_tls = 0/g" /etc/libvirt/libvirtd.conf
sed -i "s/#listen_tcp = 1/listen_tcp = 1/g" /etc/libvirt/libvirtd.conf
sed -i "s/^#listen_addr = .*/listen_addr = \"0.0.0.0\"/g" /etc/libvirt/libvirtd.conf
sed -i "s/#auth_tcp = \"sasl\"/auth_tcp = \"none\"/g" /etc/libvirt/libvirtd.conf

sed -i "s/libvirtd_opts=\"-d\"/libvirtd_opts=\"-l -d\"/g" /etc/default/libvirt-bin
service libvirt-bin restart

# Compute - Telemetry services

apt-get install -y ceilometer-agent-compute

./configure_ceilometer_compute.sh

service ceilometer-agent-compute restart

# Network services

cat << EOF > /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

sysctl -p

apt-get install -y neutron-plugin-linuxbridge-agent

./neutron-compute.sh

service nova-compute restart
service neutron-linuxbridge-agent restart
