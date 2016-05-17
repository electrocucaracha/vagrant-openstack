#!/bin/bash

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers opendaylight
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan

crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_odl username admin
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_odl password admin
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_odl url "http://${OPENDAYLIGHT_IP}:8080/controller/nb/v2/neutron"

mysql -uroot -p${ROOT_DBPASS} -e "DROP DATABASE IF EXISTS neutron_ml2;"
mysql -uroot -p${ROOT_DBPASS} -e "CREATE DATABASE neutron_ml2 character set utf8;"
mysql -uroot -p${ROOT_DBPASS} -e "GRANT all on neutron_ml2.* to 'neutron'@'%';"

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
