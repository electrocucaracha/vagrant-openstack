#!/bin/bash

# 0. Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install compute packages
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y  nova-compute sysfsutils

# 2. Configure message broker service
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = message_broker" >> /etc/nova/nova.conf
echo "rabbit_password = secure" >> /etc/nova/nova.conf

# 3. Configure VNC Server
echo "vnc_enabled = True" >> /etc/nova/nova.conf
echo "vncserver_listen = 127.0.0.1" >> /etc/nova/nova.conf
echo "vncserver_proxyclient_address = 127.0.0.1" >> /etc/nova/nova.conf
echo "novncproxy_base_url = http://compute-controller:6080/vnc_auto.html" >> /etc/nova/nova.conf
echo "my_ip = ${my_ip}" >> /etc/nova/nova.conf

# 4. Configure Identity Service
echo "auth_strategy = keystone" >> /etc/nova/nova.conf
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "auth_uri = http://identity:5000/v2.0" >> /etc/nova/nova.conf
echo "identity_uri = http://identity:35357" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = secure" >> /etc/nova/nova.conf

# 5. Configure Image Service
echo "" >> /etc/nova/nova.conf
echo "[glance]" >> /etc/nova/nova.conf
echo "host = image" >> /etc/nova/nova.conf

# 6. Use KVM or QEMU
supports_hardware_acceleration=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if [ $supports_hardware_acceleration -eq 0 ]; then
  sed -i "s/kvm/qemu/g" /etc/nova/nova-compute.conf
fi

# 7. Remove default database file
rm /var/lib/nova/nova.sqlite

# 8. Restart service
service nova-compute restart
