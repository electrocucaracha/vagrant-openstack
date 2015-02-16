#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_group.sh
echo "source /root/shared/openstackrc-group" >> /root/.bashrc
source /root/.bashrc

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-nova-compute openstack-nova-network openstack-nova-api sysfsutils

# 2. Configure message broker service
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host supporting-services
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password secure

# 3. Configure VNC Server
crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://controller-services:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}

# 4. Configure Identity Service
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller-services:5000/v2.0
crudini --set /etc/nova/nova.conf keystone_authtoken identity_uri http://controller-services:35357
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password secure

# 5. Configure Image Service
crudini --set /etc/nova/nova.conf glance host controller-services

# 6. Configure Network Service
crudini --set /etc/nova/nova.conf DEFAULT network_manager nova.network.manager.FlatDHCPManager
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.libvirt.firewall.IptablesFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT public_interface eth0
crudini --set /etc/nova/nova.conf DEFAULT vlan_interface eth0
crudini --set /etc/nova/nova.conf DEFAULT flat_network_bridge br100
crudini --set /etc/nova/nova.conf DEFAULT flat_interface eth0

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  crudini --set /etc/nova/nova.conf libvirt virt_type qemu
fi

# 7. Restart services
systemctl enable libvirtd.service openstack-nova-compute.service openstack-nova-network.service openstack-nova-metadata-api.service
systemctl start libvirtd.service openstack-nova-compute.service openstack-nova-network.service openstack-nova-metadata-api.service

#nova network-create demo-net --bridge br100 --fixed-range-v4 203.0.113.24/29
