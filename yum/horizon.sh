#!/bin/bash

cd /root/shared
source configure.sh
cd setup

# 1. Install OpenStack Compute Service and dependencies
yum install -y yum-plugin-priorities
yum install -y http://rdo.fedorapeople.org/openstack-kilo/rdo-release-kilo.rpm
yum install -y http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install -y openstack-selinux deltarpm
yum upgrade -y
yum clean all
yum update -y
yum install -y openstack-dashboard httpd mod_wsgi memcached python-memcached

# 2. Configure settings
sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${IDENTITY_HOSTNAME}\"/g" /etc/openstack-dashboard/local_settings

# 2.1 Configure access
sed -i "s/ALLOWED_HOSTS = \['horizon.example.com', 'localhost']/ALLOWED_HOSTS = '*'/g" /etc/openstack-dashboard/local_settings

# 2.2 Configure memcached
sed -i "s/'django.core.cache.backends.locmem.LocMemCache'/'django.core.cache.backends.memcached.MemcachedCache',\n        'LOCATION': '127.0.0.1:11211'/g" /etc/openstack-dashboard/local_settings

# 2.3 Configure user as default role
sed -i "s/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"_member_\"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/g" /etc/openstack-dashboard/local_settings

# 3. Configure SELinux to permit the web server to connect
setsebool -P httpd_can_network_connect on

# 4. Solve the CSS issue
chown -R apache:apache /usr/share/openstack-dashboard/static

# 5. Enable services
systemctl enable httpd.service memcached.service
systemctl start httpd.service memcached.service
