#!/bin/bash

pushd /root/shared
source configure.sh
popd
./repo.sh
cd /root/shared/setup

# 1. Install Logical Volume Manager
apt-get install -y lvm2

# 2. Create a partition based on other partition
cat <<EOL > /tmp/sdb.layout
# partition table of /dev/sdb
unit: sectors

/dev/sdb1 : start=     2048, size= 10483712, Id=83
/dev/sdb2 : start=        0, size=        0, Id= 0
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOL
sfdisk --force /dev/sdb < /tmp/sdb.layout

# 3. Create the LVM physical volume /dev/sdb1
pvcreate /dev/sdb1

# 4. Create the LVM volume group cinder-volumes
vgcreate cinder-volumes /dev/sdb1

# 5. Add a filter that accepts the /dev/sdb device and rejects all other devices
sed -i "s/filter = \[ \"a\/.*\/\"/filter = \[ \"a\/sdb\/\", \"r\/.\*\/\"/g" /etc/lvm/lvm.conf

apt-get install -y cinder-volume

./cinder-storage.sh

# Block storage - Telemetry services

./configure_ceilometer_block_storage.sh

# Restart the Block Storage volume service including its dependencies
service tgt restart
service cinder-volume restart

rm -f /var/lib/cinder/cinder.sqlite
