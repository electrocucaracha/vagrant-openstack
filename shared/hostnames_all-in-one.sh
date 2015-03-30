#!/bin/bash

export my_nic=`ip route | awk '/192./ { print $3 }'`
export my_ip=`ip addr | awk "/${my_nic}\$/ { sub(/\/24/, \"\","' $2); print $2}'`

all_in_one_ip=192.168.50.10

sed -i "/127.0.1.1/d" /etc/hosts
sed -i "/127.0.0.1/d" /etc/hosts

echo "${all_in_one_ip-192.168.50.10} all-in-one all-in-one" >> /etc/hosts
