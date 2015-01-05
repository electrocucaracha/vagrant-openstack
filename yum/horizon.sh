#!/bin/bash

# 0. Workaround for vagrant boxes
sed -i "s/10.0.2.3/8.8.8.8/g" /etc/resolv.conf

# 0.1 Setting Hostnames
if [ -f /root/hostnames.sh ]
then
  source /root/hostnames.sh
  echo "source /root/openstackrc" > /root/.bashrc
fi

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://repos.fedorapeople.org/repos/openstack/openstack-juno/rdo-release-juno-1.noarch.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
yum install -y openstack-utils
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-dashboard httpd mod_wsgi memcached python-memcached

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"identity\"/g" /etc/openstack-dashboard/local_settings

# 3. Configure memcached
sed -i "s/'django.core.cache.backends.locmem.LocMemCache'/'django.core.cache.backends.memcached.MemcachedCache',\n        'LOCATION': '127.0.0.1:11211'/g" /etc/openstack-dashboard/local_settings

# 4. Configure SELinux to permit the web server to connect
setsebool -P httpd_can_network_connect on

# 5. Solve the CSS issue
chown -R apache:apache /usr/share/openstack-dashboard/static

# 6. Enable services
systemctl enable httpd.service memcached.service
systemctl start httpd.service memcached.service
