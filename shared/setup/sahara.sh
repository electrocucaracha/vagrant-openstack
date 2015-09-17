#!/bin/bash

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create sahara --password=${SAHARA_PASS} --email=sahara@example.com
openstack role add admin --user=sahara --project=service
openstack service create --name=sahara --description="OpenStack Data Processing Service" data-processing
openstack endpoint create \
  --publicurl http://${DATA_HOSTNAME}:8386/v1.1/%\(tenant_id\)s \
  --internalurl http://${DATA_HOSTNAME}:8386/v1.1/%\(tenant_id\)s \
  --adminurl http://${DATA_HOSTNAME}:8386/v1.1/%\(tenant_id\)s \
  --region regionOne \
  data-processing

# 3. Configure api service
crudini --set /etc/sahara/sahara.conf database connection mysql://sahara:${SAHARA_DBPASS}@${DATABASE_HOSTNAME}/sahara
crudini --set /etc/sahara/sahara.conf DEFAULT rpc_backend rabbit
crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/sahara/sahara.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/sahara/sahara.conf DEFAULT auth_strategy keystone
crudini --set /etc/sahara/sahara.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/sahara/sahara.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/sahara/sahara.conf keystone_authtoken auth_plugin password
crudini --set /etc/sahara/sahara.conf keystone_authtoken project_domain_id default
crudini --set /etc/sahara/sahara.conf keystone_authtoken user_domain_id default
crudini --set /etc/sahara/sahara.conf keystone_authtoken project_name service
crudini --set /etc/sahara/sahara.conf keystone_authtoken username sahara
crudini --set /etc/sahara/sahara.conf keystone_authtoken password ${SAHARA_PASS}

# 4. Generate tables
su -s /bin/sh -c "sahara-db-manage upgrade head" sahara
