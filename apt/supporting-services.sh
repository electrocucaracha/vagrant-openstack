#!/bin/bash

# 0. Post-installation
export CONFIGURATION="_group"
cd /root/scripts/

./rabbitmq.sh
./mariadb.sh
./mongodb.sh
