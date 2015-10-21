#!/bin/bash

./proxy.sh
source variables$CONFIGURATION.sh
./openstackrc.sh
source hostnames$CONFIGURATION.sh
echo "source /root/admin-openrc.sh" >> /root/.bashrc
echo "source /home/vagrant/demo-openrc.sh" >> /home/vagrant/.bashrc
echo "export CONFIGURATION=$CONFIGURATION" >> /root/.bashrc
