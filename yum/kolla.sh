#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_all-in-one.sh

yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y deltarpm openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y git python-keystoneclient python-glanceclient python-novaclient

# Install docker
yum install -y docker
systemctl enable docker
systemctl start docker

# Install compose
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install -U docker-compose

git clone https://github.com/stackforge/kolla.git
cd kolla
sed -i "s/ADMIN_USER_PASSWORD=steakfordinner/ADMIN_USER_PASSWORD=secure/g" tools/genenv
./tools/genenv
cp compose/openstack.env .
./tools/start
