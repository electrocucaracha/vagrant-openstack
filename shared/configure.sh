#!/bin/bash

./proxy.sh
source variables$CONFIGURATION.sh
./openstackrc.sh
source hostnames$CONFIGURATION.sh
echo "source /root/admin-openrc.sh" >> /root/.bashrc
