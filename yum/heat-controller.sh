#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install OpenStack Orchestration Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-selinux deltarpm crudini
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-heat-api openstack-heat-api-cfn openstack-heat-engine python-heatclient

cp /usr/share/heat/heat-dist.conf /etc/heat/heat.conf
chown -R heat:heat /etc/heat/heat.conf

./heat.sh

systemctl enable openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
systemctl start openstack-heat-api.service openstack-heat-api-cfn.service openstack-heat-engine.service
