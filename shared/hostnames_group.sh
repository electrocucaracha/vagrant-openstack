#!/bin/bash

cat << EOF > /etc/hosts
192.168.50.2 supporting-services
192.168.50.3 controller-services
192.168.50.4 compute-services
192.168.50.5 block-storage-services
EOF
