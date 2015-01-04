#!/bin/bash

# 1. Install database server
apt-get update
apt-get install -y rabbitmq-server

# 2. Change default guest user password
rabbitmqctl change_password guest secure
