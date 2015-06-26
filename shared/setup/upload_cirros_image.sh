#!/bin/bash

cirros_release=0.3.4
source /root/admin-openrc.sh
wget http://download.cirros-cloud.net/${cirros_release}/cirros-${cirros_release}-x86_64-disk.img -P /tmp/
openstack image create --file /tmp/cirros-${cirros_release}-x86_64-disk.img --disk-format qcow2 --container-format bare --public cirros
