#!/bin/bash

export my_nic=`ip route | awk '/192./ { print $3 }'`
export my_ip=`ip addr | awk "/${my_nic}\$/ { sub(/\/24/, \"\","' $2); print $2}'`

supporting_services_ip=192.168.50.10
controller_services_ip=192.168.50.11
compute_services_ip=192.168.50.12
block_storage_services_ip=192.168.50.13

sed -i "/127.0.1.1/d" /etc/hosts
sed -i "/127.0.0.1/d" /etc/hosts

echo "${supporting_services_ip-192.168.50.10} supporting-services supporting-services" >> /etc/hosts
echo "${controller_services_ip-192.168.50.11} controller-services controller-services" >> /etc/hosts
echo "${compute_services_ip-192.168.50.12} compute-services compute-services" >> /etc/hosts
echo "${block_storage_services_ip-192.168.50.13} block-storage-services block-storage-services" >> /etc/hosts
