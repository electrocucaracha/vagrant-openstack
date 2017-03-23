#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Networking services

cat << EOF > /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
EOF

sysctl -p

# 1. Install components
apt-get install -y neutron-server neutron-plugin-ml2 \
  neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent

if [ ! -z ${INSTALL_OPENVSWITCH} ] && [ ${INSTALL_OPENVSWITCH} == "True" ]; then
  apt-get install -y linux-headers-`uname -r` vlan bridge-utils dnsmasq-base \
  dnsmasq-utils ipset python-mysqldb ntp openvswitch-switch \
  openvswitch-datapath-dkms neutron-plugin-openvswitch-agent
else
  apt-get install -y neutron-plugin-linuxbridge-agent
fi

./neutron.sh

# Restart the Networking services
service neutron-server restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart

if [ ! -z ${INSTALL_OPENVSWITCH} ] && [ ${INSTALL_OPENVSWITCH} == "True" ]; then
  service openvswitch-switch restart
else
  service neutron-linuxbridge-agent restart
fi
