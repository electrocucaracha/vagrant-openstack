#!/bin/bash

cat << EOF > /etc/hosts
192.168.50.2 message-broker
192.168.50.3 database
192.168.50.4 identity
192.168.50.5 image
192.168.50.6 compute-controller
192.168.50.7 compute
192.168.50.8 network-controller
192.168.50.9 dashboard
192.168.50.10 block-storage-controller
192.168.50.11 block-storage
192.168.50.12 nosql-database
192.168.50.13 telemetry-controller
EOF
