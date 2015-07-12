#!/bin/bash

wget -O /etc/swift/account-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/account-server.conf-sample?h=stable/kilo

wget -O /etc/swift/container-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/container-server.conf-sample?h=stable/kilo

wget -O /etc/swift/object-server.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/object-server.conf-sample?h=stable/kilo

wget -O /etc/swift/container-reconciler.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/container-reconciler.conf-sample?h=stable/kilo

wget -O /etc/swift/object-expirer.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/object-expirer.conf-sample?h=stable/kilo

crudini --set /etc/swift/account-server.conf DEFAULT bind_ip 0.0.0.0
crudini --set /etc/swift/account-server.conf DEFAULT bind_port 6002
crudini --set /etc/swift/account-server.conf DEFAULT user swift
crudini --set /etc/swift/account-server.conf DEFAULT swift_dir /etc/swift
crudini --set /etc/swift/account-server.conf DEFAULT devices /srv/node

crudini --set /etc/swift/account-server.conf pipeline:main pipeline "healthcheck recon account-server"
crudini --set /etc/swift/account-server.conf filter:recon recon_cache_path /var/cache/swift

crudini --set /etc/swift/container-server.conf DEFAULT bind_ip 0.0.0.0
crudini --set /etc/swift/container-server.conf DEFAULT bind_port 6001
crudini --set /etc/swift/container-server.conf DEFAULT user swift
crudini --set /etc/swift/container-server.conf DEFAULT swift_dir /etc/swift
crudini --set /etc/swift/container-server.conf DEFAULT devices /srv/node

crudini --set /etc/swift/container-server.conf pipeline:main pipeline "healthcheck recon container-server"
crudini --set /etc/swift/container-server.conf filter:recon recon_cache_path /var/cache/swift

crudini --set /etc/swift/object-server.conf DEFAULT bind_ip 0.0.0.0
crudini --set /etc/swift/object-server.conf DEFAULT bind_port 6000
crudini --set /etc/swift/object-server.conf DEFAULT user swift
crudini --set /etc/swift/object-server.conf DEFAULT swift_dir /etc/swift
crudini --set /etc/swift/object-server.conf DEFAULT devices /srv/node

crudini --set /etc/swift/object-server.conf pipeline:main pipeline "healthcheck recon object-server"
crudini --set /etc/swift/object-server.conf filter:recon recon_cache_path /var/cache/swift
crudini --set /etc/swift/object-server.conf filter:recon recon_lock_path /var/lock

chown -R swift:swift /srv/node
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift

