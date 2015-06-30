#!/bin/bash

# 0. Post-installation
export CONFIGURATION="_all-in-one"
pushd /root/shared
source configure.sh
popd

apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/kolla main" >>  /etc/apt/sources.list.d/kilo.list
apt-get update && apt-get dist-upgrade
apt-get install -y git python-keystoneclient python-glanceclient python-novaclient

# Install docker
curl -sSL https://get.docker.com/ubuntu/ | sudo sh

# Install compose
curl -s https://bootstrap.pypa.io/get-pip.py | python
git clone https://github.com/docker/compose.git
pushd compose
python setup.py install
popd

git clone https://github.com/stackforge/kolla.git
pushd kolla
./tools/genenv
cp compose/openstack.env .
sed -i "s/ADMIN_USER_PASSWORD=steakfordinner/ADMIN_USER_PASSWORD=secure/g" openstack.env
sed -i "s/FLAT_INTERFACE=eth1/FLAT_INTERFACE=${my_nic}/g" openstack.env
./tools/kolla start
popd
