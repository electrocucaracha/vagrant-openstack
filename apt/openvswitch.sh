#!/bin/bash

apt-get update -y
apt-get install -y openvswitch-switch

# Set OpenDayLight as the manager
ovs-vsctl set-manager tcp:${OPENDAYLIGHT_IP}:6640
