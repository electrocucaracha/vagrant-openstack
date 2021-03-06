#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# Storage node
apt-get install -y xfsprogs rsync

# Create a partition
cat <<EOL > /tmp/sdc.layout
# partition table of /dev/sdc
unit: sectors

/dev/sdc1 : start=     2048, size= 10483712, Id=83
/dev/sdc2 : start=        0, size=        0, Id= 0
/dev/sdc3 : start=        0, size=        0, Id= 0
/dev/sdc4 : start=        0, size=        0, Id= 0
EOL
sfdisk --force /dev/sdc < /tmp/sdc.layout

# Format the partition
mkfs.xfs /dev/sdc1

# Mount the partition
mkdir -p /srv/node/sdc1
echo "/dev/sdc1 /srv/node/sdc1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 2" >> /etc/fstab
mount /srv/node/sdc1

cat <<EOL > /etc/rsyncd.conf
uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = ${my_ip}

[account]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/account.lock

[container]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/container.lock

[object]
max connections = 2
path = /srv/node/
read only = False
lock file = /var/lock/object.lock
EOL

sed -i "s/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g" /etc/default/rsync

service rsync restart

apt-get install -y swift swift-account swift-container swift-object

./swift-storage.sh
./create_initial.sh
./configure_hashes_storage_policy.sh

service memcached restart
service swift-proxy restart

swift-init all start
