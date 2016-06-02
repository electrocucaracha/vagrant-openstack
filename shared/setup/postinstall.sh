#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

wget -O /tmp/ubuntu.img http://uec-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
openstack image create --file /tmp/ubuntu.img --disk-format qcow2 --container-format bare --public ubuntu
