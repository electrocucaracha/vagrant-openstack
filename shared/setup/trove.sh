#!/bin/bash

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create trove --password=${TROVE_PASS} --email=trove@example.com
openstack role add admin --user=trove --project=service
openstack service create --name=trove --description="OpenStack Database Service" database
openstack endpoint create \
  --publicurl http://${DATABASE_CONTROLLER_HOSTNAME}:8779/v1.0/%\(tenant_id\)s \
  --internalurl http://${DATABASE_CONTROLLER_HOSTNAME}:8779/v1.0/%\(tenant_id\)s \
  --adminurl http://${DATABASE_CONTROLLER_HOSTNAME}:8779/v1.0/%\(tenant_id\)s \
  --region regionOne \
  database


# 3. Configure api service
wget -O /etc/trove/api-paste.ini https://git.openstack.org/cgit/openstack/trove/plain/etc/trove/api-paste.ini?h=stable/kilo

crudini --set /etc/trove/trove.conf DEFAULT trove_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/trove/trove.conf DEFAULT nova_compute_url http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2
crudini --set /etc/trove/trove.conf DEFAULT cinder_url http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2
crudini --set /etc/trove/trove.conf DEFAULT swift_url http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_
crudini --set /etc/trove/trove.conf DEFAULT connection mysql://trove:${TROVE_DBPASS}@${DATABASE_HOSTNAME}/trove
crudini --set /etc/trove/trove.conf DEFAULT notifier_queue_hostname ${MESSAGE_BROKER_HOSTNAME}

crudini --set /etc/trove/trove-taskmanager.conf DEFAULT trove_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT nova_compute_url http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT cinder_url http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT swift_url http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT connection mysql://trove:${TROVE_DBPASS}@${DATABASE_HOSTNAME}/trove
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT notifier_queue_hostname ${MESSAGE_BROKER_HOSTNAME}

crudini --set /etc/trove/trove-conductor.conf DEFAULT trove_auth_url http://${IDENTITY_HOSTNAME}:5000/v2.0
crudini --set /etc/trove/trove-conductor.conf DEFAULT nova_compute_url http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2
crudini --set /etc/trove/trove-conductor.conf DEFAULT cinder_url http://${BLOCK_STORAGE_CONTROLLER_HOSTNAME}:8776/v2
crudini --set /etc/trove/trove-conductor.conf DEFAULT swift_url http://${OBJECT_STORAGE_CONTROLLER_HOSTNAME}:8080/v1/AUTH_
crudini --set /etc/trove/trove-conductor.conf DEFAULT connection mysql://trove:${TROVE_DBPASS}@${DATABASE_HOSTNAME}/trove
crudini --set /etc/trove/trove-conductor.conf DEFAULT notifier_queue_hostname ${MESSAGE_BROKER_HOSTNAME}

crudini --set /etc/trove/trove.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/trove/trove.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/trove/trove.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/trove/trove-taskmanager.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/trove/trove-taskmanager.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/trove/trove-taskmanager.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/trove/trove-conductor.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/trove/trove-conductor.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/trove/trove-conductor.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/trove/trove.conf DEFAULT add_addresses True
crudini --set /etc/trove/trove.conf DEFAULT network_label_regex ^NETWORK_LABEL$
crudini --set /etc/trove/trove.conf DEFAULT control_exchange trove

crudini --set /etc/trove/trove-taskmanager.conf DEFAULT nova_proxy_admin_user admin
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT nova_proxy_admin_pass ${ADMIN_PASS}
crudini --set /etc/trove/trove-taskmanager.conf DEFAULT nova_proxy_admin_tenant_name service
crudini --set /etc/trove/trove.conf DEFAULT taskmanager_manager trove.taskmanager.manager.Manager

trove-manage db_sync
su -s /bin/sh -c "trove-manage datastore_update mysql ''" trove

export DATASTORE_TYPE="mysql" # mysql, mongodb, percona`
export DATASTORE_VERSION="5.6" # available options: for cassandra 2.0.x, for mysql: 5.x, for mongodb: 2.x.x, etc.
export PACKAGES="mysql-server-5.6" # available options: cassandra=2.0.9, mongodb=2.0.4, etc
wget http://tarballs.openstack.org/trove/images/ubuntu/${DATASTORE_TYPE}.qcow2 --output-document=/tmp/${DATASTORE_TYPE}.qcow2
openstack image create --public --container-format ovf --disk-format qcow2 --file /tmp/${DATASTORE_TYPE}.qcow2 --owner trove trove-image
export IMAGEID=`openstack image list | grep trove-image | awk '{print $2}'`

trove-manage datastore_update ${DATASTORE_TYPE} ""
trove-manage datastore_version_update ${DATASTORE_TYPE} ${DATASTORE_VERSION} ${DATASTORE_TYPE} ${IMAGEID} ${PACKAGES} 1
trove-manage datastore_update ${DATASTORE_TYPE} ${DATASTORE_VERSION}

wget -O /tmp/validation-rules.json https://git.openstack.org/cgit/openstack/trove/plain/trove/templates/${DATASTORE_TYPE}/validation-rules.json?h=stable/kilo
trove-manage db_load_datastore_config_parameters ${DATASTORE_TYPE} ${DATASTORE_VERSION} /tmp/validation-rules.json
