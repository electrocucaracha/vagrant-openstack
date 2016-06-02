#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# External network creation

neutron net-create External --router:external true
neutron subnet-create --name=external-subnet1 --dns-nameserver 8.8.4.4 External 192.168.50.16/28

wget -O /tmp/ubuntu.img http://uec-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
openstack image create --file /tmp/ubuntu.img --disk-format qcow2 --container-format bare --public ubuntu

