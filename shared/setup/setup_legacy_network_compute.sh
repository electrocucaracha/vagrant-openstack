#!/bin/bash

crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api nova
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.libvirt.firewall.IptablesFirewallDriver
crudini --set /etc/nova/nova.conf DEFAULT network_manager nova.network.manager.FlatDHCPManager
crudini --set /etc/nova/nova.conf DEFAULT network_size 254
crudini --set /etc/nova/nova.conf DEFAULT allow_same_net_traffic False
crudini --set /etc/nova/nova.conf DEFAULT multi_host True
crudini --set /etc/nova/nova.conf DEFAULT send_arp_for_ha True
crudini --set /etc/nova/nova.conf DEFAULT share_dhcp_address True 
crudini --set /etc/nova/nova.conf DEFAULT force_dhcp_release True
crudini --set /etc/nova/nova.conf DEFAULT flat_network_bridge br100
crudini --set /etc/nova/nova.conf DEFAULT flat_interface ${my_nic}
crudini --set /etc/nova/nova.conf DEFAULT public_interface ${my_nic}
