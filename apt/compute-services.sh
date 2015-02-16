#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_group.sh
echo "source /root/shared/openstackrc-group" >> /root/.bashrc
source /root/.bashrc

# 1. Install compute packages
apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update && apt-get dist-upgrade
apt-get install -y nova-compute sysfsutils nova-network nova-api-metadata

# 2. Configure message broker service
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = supporting-services" >> /etc/nova/nova.conf
echo "rabbit_password = secure" >> /etc/nova/nova.conf

# 3. Configure VNC Server
echo "my_ip = ${my_ip}" >> /etc/nova/nova.conf
echo "vnc_enabled = True" >> /etc/nova/nova.conf
echo "vncserver_listen = 0.0.0.0" >> /etc/nova/nova.conf
echo "vncserver_proxyclient_address = ${my_ip}" >> /etc/nova/nova.conf
echo "novncproxy_base_url = http://controller-services:6080/vnc_auto.html" >> /etc/nova/nova.conf
echo "network_manager=nova.network.manager.FlatDHCPManager" >> /etc/nova/nova.conf 
echo "firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver" >> /etc/nova/nova.conf 
echo "public_interface=eth0" >> /etc/nova/nova.conf
echo "vlan_interface=eth0" >> /etc/nova/nova.conf 
echo "flat_network_bridge=br100" >> /etc/nova/nova.conf
echo "flat_interface=eth0" >> /etc/nova/nova.conf

# 4. Configure Identity Service
echo "auth_strategy = keystone" >> /etc/nova/nova.conf
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "auth_uri = http://controller-services:5000/v2.0" >> /etc/nova/nova.conf
echo "identity_uri = http://controller-services:35357" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = secure" >> /etc/nova/nova.conf

# 5. Configure Image Service
echo "" >> /etc/nova/nova.conf
echo "[glance]" >> /etc/nova/nova.conf
echo "host = controller-services" >> /etc/nova/nova.conf

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  sed -i "s/kvm/qemu/g" /etc/nova/nova-compute.conf
fi

# 7. Remove default database file
rm /var/lib/nova/nova.sqlite

# 8. Restart service
service nova-compute restart
service nova-network restart
service nova-api-metadata restart

#nova network-create demo-net --bridge br100 --fixed-range-v4 203.0.113.24/29
