#!/bin/bash

export my_ip=$(ip addr | awk '/eth1$/ { sub(/\/24/, "", $2); print $2}')
if [ -z "${my_ip}" ]; then
  export my_ip=$(ip addr | awk '/enp0s8$/ { sub(/\/24/, "", $2); print $2}')
fi

message_broker_ip=192.168.50.10
database_ip=192.168.50.11
identity_ip=192.168.50.12
image_ip=192.168.50.13
compute_controller_ip=192.168.50.14
compute_ip=192.168.50.15
dashboard_ip=192.168.50.17
block_storage_controller_ip=192.168.50.18
block_storage_ip=192.168.50.19
nosql_database_ip=192.168.50.22
telemetry_controller_ip=192.168.50.23

sed -i "/127.0.1.1/d" /etc/hosts
sed -i "/127.0.0.1/d" /etc/hosts 

echo "${message_broker_ip-192.168.50.10} message-broker message-broker" >> /etc/hosts
echo "${database_ip-192.168.50.11} database database" >> /etc/hosts
echo "${identity_ip-192.168.50.12} identity identity" >> /etc/hosts
echo "${image_ip-192.168.50.13} image image" >> /etc/hosts
echo "${compute_controller_ip-192.168.50.14} compute-controller compute-controller" >> /etc/hosts
echo "${compute_ip-192.168.50.15} compute compute" >> /etc/hosts
echo "${dashboard_ip-192.168.50.17} dashboard dashboard" >> /etc/hosts
echo "${block_storage_controller_ip-192.168.50.18} block-storage-controller block-storage-controller" >> /etc/hosts
echo "${block_storage_ip-192.168.50.19} block-storage block-storage" >> /etc/hosts
echo "${nosql_database_ip-192.168.50.22} nosql-database nosql-database" >> /etc/hosts
echo "${telemetry_controller_ip-192.168.50.23} telemetry-controller telemetry-controller" >> /etc/hosts
