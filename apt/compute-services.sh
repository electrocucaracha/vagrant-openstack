#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_group.sh
echo "source /root/shared/openstackrc-group" >> /root/.bashrc

# 1. Install compute packages
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y  nova-compute sysfsutils

# 2. Configure message broker service
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = supporting-services" >> /etc/nova/nova.conf
echo "rabbit_password = secure" >> /etc/nova/nova.conf

# 3. Configure VNC Server
echo "vnc_enabled = True" >> /etc/nova/nova.conf
echo "vncserver_listen = 127.0.0.1" >> /etc/nova/nova.conf
echo "vncserver_proxyclient_address = 127.0.0.1" >> /etc/nova/nova.conf
echo "novncproxy_base_url = http://controller-services:6080/vnc_auto.html" >> /etc/nova/nova.conf

echo "my_ip = ${my_ip}" >> /etc/nova/nova.conf

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
