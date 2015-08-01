#!/bin/bash

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create nova --password=${NOVA_PASS} --email=nova@example.com
openstack role add admin --user=nova --project=service
openstack service create compute --name=nova --description="OpenStack Compute Service"
openstack endpoint create \
  --publicurl=http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2/%\(tenant_id\)s \
  --internalurl=http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2/%\(tenant_id\)s \
  --adminurl=http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2/%\(tenant_id\)s \
  --region regionOne \
  compute

# 3. Configure api service
crudini --set /etc/nova/nova.conf database connection mysql://nova:${NOVA_DBPASS}@${DATABASE_HOSTNAME}/nova
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${NOVA_PASS}
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address ${my_ip}
crudini --set /etc/nova/nova.conf glance host ${HOSTNAME}
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

# 4. Generate tables
su -s /bin/sh -c "nova-manage db sync" nova
