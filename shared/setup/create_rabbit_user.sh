#!/bin/bash

# 1. Add the openstack user
rabbitmqctl add_user openstack "${RABBIT_PASS}"
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
