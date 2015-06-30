#!/bin/bash

# 0. Post-installation
export CONFIGURATION="_all-in-one"
pushd /root/shared
source configure.sh
popd

yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-kilo/rdo-release-kilo-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-utils deltarpm
yum upgrade -y
yum clean all
yum update -y
yum install -y git python-keystoneclient python-glanceclient python-novaclient


# TODO : Replace curl by wget

# Install docker
curl -O -sSL https://get.docker.com/rpm/1.7.0/centos-6/RPMS/x86_64/docker-engine-1.7.0-1.el6.x86_64.rpm
yum localinstall -y --nogpgcheck docker-engine-1.7.0-1.el6.x86_64.rpm
systemctl enable docker
systemctl start docker

# Install compose
curl -s https://bootstrap.pypa.io/get-pip.py | python
git clone https://github.com/docker/compose.git
pushd compose
python setup.py install
popd

#pip install -U docker-compose

# Workaround for https://github.com/docker/compose/issues/1290
#yum install -y gcc python-devel
#pip install -U websocket

git clone https://github.com/stackforge/kolla.git
pushd kolla
./tools/genenv
cp compose/openstack.env .
sed -i "s/ADMIN_USER_PASSWORD=steakfordinner/ADMIN_USER_PASSWORD=secure/g" openstack.env
sed -i "s/FLAT_INTERFACE=eth1/FLAT_INTERFACE=${my_nic}/g" openstack.env
./tools/kolla start
popd
