#!/bin/bash

# 1. Add the openstack user
rabbitmqctl add_user openstack "${RABBIT_PASS}"
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

cat <<EOL >  /etc/rabbitmq/rabbitmq.config
[{rabbit, [{loopback_users, []}]}].
EOL

# rabbitmq-plugins enable rabbitmq_management
