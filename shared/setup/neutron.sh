#!/bin/bash

# Source the admin credentials to gain access
source /root/admin-openrc.sh

# Create the neutron user
openstack user create --domain default neutron --password ${NEUTRON_PASS} --email neutron@example.com

# Add the admin role to the neutron user
openstack role add --project service --user neutron admin

# Create the neutron service entity
openstack service create --name neutron \
  --description "OpenStack Networking" network

# Create the Networking service API endpoints
openstack endpoint create --region RegionOne \
  network public http://${NETWORKING_CONTROLLER_HOSTNAME}:9696
openstack endpoint create --region RegionOne \
  network internal http://${NETWORKING_CONTROLLER_HOSTNAME}:9696
openstack endpoint create --region RegionOne \
  network admin http://${NETWORKING_CONTROLLER_HOSTNAME}:9696

# Configure database access
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:${NEUTRON_DBPASS}@${DATABASE_HOSTNAME}/neutron

# Enable the Modular Layer 2 (ML2) plug-in, router service, and overlapping IP addresses
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

# Configure RabbitMQ message queue access
crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host ${MESSAGE_BROKER_HOSTNAME}
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}

# Configure Identity service access
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://${IDENTITY_HOSTNAME}:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers ${MEMCACHED_HOSTNAME}:11211
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password ${NEUTRON_PASS}

# Configure Networking to notify Compute of network topology changes
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT nova_url http://${COMPUTE_CONTROLLER_HOSTNAME}:8774/v2

crudini --set /etc/neutron/neutron.conf nova auth_url http://${IDENTITY_HOSTNAME}:35357
crudini --set /etc/neutron/neutron.conf nova auth_type password
crudini --set /etc/neutron/neutron.conf nova project_domain_name default
crudini --set /etc/neutron/neutron.conf nova user_domain_name default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password ${NOVA_PASS}

# Configure the Modular Layer 2 (ML2) plug-in

# Enable flat, VLAN, and VXLAN networks
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan

# Enable VXLAN project (private) networks
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan

# Enable the Linux bridge and layer-2 population mechanisms
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population

# Enable the port security extension driver
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

# Configure the public flat provider network
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider

# Configure the VXLAN network identifier range for private networks
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

# Enable ipset to increase efficiency of security group rules
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True

# Configure teh Linux bridge agent

# Map the public virtual network to the public physical network interface
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings public:${my_nic}

# Enable VXLAN overlay networks
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan enable_vxlan True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan local_ip ${my_ip}
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini vxlan l2_population True

# Enable security groups, enable ipset, and configure the Linux bridge iptables firewall driver
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# Configure the layer-3 agent

# Configure the Linux bridge interface driver and external network bridge
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge " "

# Configure the DHCP agent

# Configure the Linux bridge interface driver, Dnsmasq DHCP driver, and enable isolated metadata
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True

# Configure the metada agent

# Configure the metadata host and shared secret
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip ${COMPUTE_CONTROLLER_HOSTNAME}
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret ${METADATA_SECRET}

# Finalize installation

# Populate the database
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
