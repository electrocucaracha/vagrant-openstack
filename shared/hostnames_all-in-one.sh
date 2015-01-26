#!/bin/bash

export my_ip=$(ip addr | awk '/eth1$/ { sub(/\/24/, "", $2); print $2}')
if [ -z "${my_ip}" ]; then
  export my_ip=$(ip addr | awk '/enp0s8$/ { sub(/\/24/, "", $2); print $2}')
fi

all_in_one_ip=192.168.50.10

sed -i "/127.0.1.1/d" /etc/hosts
sed -i "/127.0.0.1/d" /etc/hosts

echo "${all_in_one_ip-192.168.50.10} all-in-one all-in-one" >> /etc/hosts
