#!/bin/bash

crudini --set /etc/cinder/cinder.conf oslo_messaging_notifications driver messagingv2
