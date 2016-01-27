#!/bin/bash

cirros_release=0.3.4

# Source the admin credentials to gain access
source /root/admin-openrc.sh

wget -O /tmp/cirros.img http://download.cirros-cloud.net/${cirros_release}/cirros-${cirros_release}-x86_64-disk.img
openstack image create --file /tmp/cirros.img --disk-format qcow2 --container-format bare --public cirros
