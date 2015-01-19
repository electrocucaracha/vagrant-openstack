#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install Logical Volume Manager
apt-get update
apt-get install -y lvm2

# 2. Create a partition based on other partition
cat <<EOL > sdb.layout
# partition table of /dev/sdb
unit: sectors

/dev/sdb1 : start=     2048, size= 83884032, Id=83, bootable
/dev/sdb2 : start=        0, size=        0, Id= 0
/dev/sdb3 : start=        0, size=        0, Id= 0
/dev/sdb4 : start=        0, size=        0, Id= 0
EOL
sfdisk /dev/sdb < sdb.layout

# 3. Create the LVM physical volume /dev/sdb1
pvcreate /dev/sdb1

# 4. Create the LVM volume group cinder-volumes
vgcreate cinder-volumes /dev/sdb1

# 5. Add a filter that accepts the /dev/sdb device and rejects all other devices
sed -i "s/filter = \[ \"a\/.*\/\"/filter = \[ \"a\/sdb\/\", \"r\/.\*\/\"/g" /etc/lvm/lvm.conf

# 6. Install OpenStack Block Storage Service and dependencies
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update
apt-get install -y ubuntu-cloud-keyring
apt-get update
apt-get install -y cinder-volume python-mysqldb

# 7. Configure message broker service
echo "rpc_backend = rabbit" >> /etc/cinder/cinder.conf
echo "rabbit_host = message-broker" >> /etc/cinder/cinder.conf
echo "rabbit_password = secure" >> /etc/cinder/cinder.conf

echo "my_ip = ${my_ip}" >> /etc/cinder/cinder.conf

# 8. Configure Identity Service
#echo "auth_strategy = keystone" >> /etc/cinder/cinder.conf
echo "" >> /etc/cinder/cinder.conf
echo "[keystone_authtoken]" >> /etc/cinder/cinder.conf
echo "identity_uri = http://identity:35357" >> /etc/cinder/cinder.conf
echo "admin_tenant_name = service" >> /etc/cinder/cinder.conf
echo "admin_user = cinder" >> /etc/cinder/cinder.conf
echo "admin_password = secure" >> /etc/cinder/cinder.conf

# 9. Configure Database driver
echo "" >> /etc/cinder/cinder.conf
echo "[database]" >> /etc/cinder/cinder.conf
echo "connection = mysql://cinder:secure@database/cinder" >> /etc/cinder/cinder.conf

# 10. Configure Image Service
echo "" >> /etc/cinder/cinder.conf
echo "[glance]" >> /etc/cinder/cinder.conf
echo "host = image" >> /etc/cinder/cinder.conf

# 11. Restart services
service tgt restart
service cinder-volume restart

# 12. Remove unnecessary files
rm -f /var/lib/cinder/cinder.sqlite
