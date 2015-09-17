#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install OpenStack Block Storage Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-selinux deltarpm crudini
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-cinder python-cinderclient python-oslo-db

# 1.1 Workaround for cinder-api dependency
yum install -y python-keystonemiddleware

./cinder.sh

# Block Storage - Telemetry services

./configure_ceilometer_block_storage_controller.sh

# 6. Enable and start services
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
