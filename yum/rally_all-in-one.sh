#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames_all-in-one.sh
echo "source /root/shared/openstackrc-all-in-one" >> /root/.bashrc
source /root/.bashrc

# 1. Install git 
yum upgrade -y
yum clean all
yum update -y
yum install -y git

if [ -z "${http_proxy}" ]; then
  git config --global http.proxy $http_proxy
fi

if [ -z "${https_proxy}" ]; then
  git config --global https.proxy $https_proxy
fi

git clone https://git.openstack.org/stackforge/rally
./rally/install_rally.sh

# 1. Registering an OpenStack deployment
rally deployment create --fromenv --name=all-in-one

# 2. Getting samples
cp -R rally/samples/tasks/scenarios/ samples

# 3. Running sample
sed -i "s/m1.nano/m1.tiny/g" samples/nova/boot-and-delete.json
sed -i "s/\.\*uec//g" samples/nova/boot-and-delete.json
rally task start samples/nova/boot-and-delete.json
