#! /bin/bash

curl -o /etc/swift/swift.conf https://git.openstack.org/cgit/openstack/swift/plain/etc/swift.conf-sample?h=stable/liberty

HASH_PATH_PREFIX=`openssl rand -hex 10`
HASH_PATH_SUFFIX=`openssl rand -hex 10`

crudini --set /etc/swift/swift.conf swift-hash swift_hash_path_suffix ${HASH_PATH_PREFIX}
crudini --set /etc/swift/swift.conf swift-hash swift_hash_path_prefix ${HASH_PATH_SUFFIX}

crudini --set /etc/swift/swift.conf storage-policy:0 name Policy-0
crudini --set /etc/swift/swift.conf storage-policy:0 default yes

chown -R swift:swift /etc/swift
