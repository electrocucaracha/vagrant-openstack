#!/bin/bash

# 2. User, service and endpoint creation
source /root/admin-openrc.sh
openstack user create heat --password=${HEAT_PASS} --email=heat@example.com
openstack role add admin --user=heat --project=service
openstack role create heat_stack_owner
openstack role add --project demo --user demo heat_stack_owner
openstack role create heat_stack_user
openstack service create --name=heat --description="OpenStack Orchestration Service" orchestration
openstack service create --name=heat-cfn --description "OpenStack CloudFormation Service" cloudformation
openstack endpoint create \
  --publicurl http://${ORCHESTRATION_HOSTNAME}:8004/v1/%\(tenant_id\)s \
  --internalurl http://${ORCHESTRATION_HOSTNAME}:8004/v1/%\(tenant_id\)s \
  --adminurl http://${ORCHESTRATION_HOSTNAME}:8004/v1/%\(tenant_id\)s \
  --region regionOne \
  orchestration
openstack endpoint create \
  --publicurl http://${ORCHESTRATION_HOSTNAME}:8000/v1 \
  --internalurl http://${ORCHESTRATION_HOSTNAME}:8000/v1 \
  --adminurl http://${ORCHESTRATION_HOSTNAME}:8000/v1 \
  --region regionOne \
  cloudformation

# 3. Configure api service
crudini --set /etc/heat/heat.conf database connection mysql://heat:${HEAT_DBPASS}@${DATABASE_HOSTNAME}/heat

crudini --set /etc/heat/heat.conf DEFAULT rpc_backend rabbit
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/heat/heat.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

crudini --set /etc/heat/heat.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/heat/heat.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/heat/heat.conf keystone_authtoken auth_plugin password
crudini --set /etc/heat/heat.conf keystone_authtoken project_domain_id default
crudini --set /etc/heat/heat.conf keystone_authtoken user_domain_id default
crudini --set /etc/heat/heat.conf keystone_authtoken project_name service
crudini --set /etc/heat/heat.conf keystone_authtoken username heat
crudini --set /etc/heat/heat.conf keystone_authtoken password ${HEAT_PASS}
crudini --set /etc/heat/heat.conf ec2authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000/v2.0

crudini --set /etc/heat/heat.conf DEFAULT heat_metadata_server_url http://${ORCHESTRATION_HOSTNAME}:8000
crudini --set /etc/heat/heat.conf DEFAULT heat_waitcondition_server_url http://${ORCHESTRATION_HOSTNAME}:8000/v1/waitcondition

crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin heat_domain_admin
crudini --set /etc/heat/heat.conf DEFAULT stack_domain_admin_password ${HEAT_DOMAIN_PASS}
crudini --set /etc/heat/heat.conf DEFAULT stack_user_domain_name heat_user_domain

heat-keystone-setup-domain \
  --stack-user-domain-name heat_user_domain \
  --stack-domain-admin heat_domain_admin \
  --stack-domain-admin-password ${HEAT_DOMAIN_PASS}

su -s /bin/sh -c "heat-manage db_sync" heat
