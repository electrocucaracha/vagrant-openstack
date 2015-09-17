#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install OpenStack Identity Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-selinux deltarpm crudini
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-glance python-glance python-glanceclient

./glance.sh

# Image - Telemetry services

./configure_ceilometer_image.sh

systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl restart openstack-glance-api.service openstack-glance-registry.service

sleep 5

./upload_cirros_image.sh
