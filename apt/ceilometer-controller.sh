#!/bin/bash

# 0. Post-installation
/root/shared/proxy.sh
source /root/shared/hostnames.sh
echo "source /root/shared/openstackrc" >> /root/.bashrc

# 1. Install OpenStack Telemetry Controller Service and dependencies
apt-get install -y ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main" >>  /etc/apt/sources.list.d/juno.list
apt-get update && apt-get dist-upgrade

apt-get install -y ceilometer-api ceilometer-collector ceilometer-agent-central ceilometer-agent-notification ceilometer-alarm-evaluator ceilometer-alarm-notifier python-ceilometerclient

# 2. Configure database connection
sed -i "s/#connection=<None>/connection = mongodb:\/\/ceilometer:secure@nosql-database:27017\/ceilometer/g" /etc/ceilometer/ceilometer.conf

# 3. Configure message broker connection
sed -i "s/#rpc_backend=rabbit/rpc_backend = rabbit/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#rabbit_host=localhost/rabbit_host = message-broker/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#rabbit_password=guest/rabbit_password = secure/g" /etc/ceilometer/ceilometer.conf

# 4. Configure OpenStack Identity service
sed -i "s/#auth_uri=<None>/auth_uri = http:\/\/identity:5000\/v2.0/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#identity_uri=<None>/identity_uri = http:\/\/identity:35357\/v2.0/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#admin_tenant_name=admin/admin_tenant_name = service/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#admin_user=<None>/admin_user = ceilometer/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#admin_password=<None>/admin_password = secure/g" /etc/ceilometer/ceilometer.conf

# 5. Configure service
sed -i "s/#os_auth_url=http:\/\/localhost:5000\/v2.0/os_auth_url=http:\/\/identity:5000\/v2.0/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#os_username=ceilometer/os_username = ceilometer/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#os_tenant_name=admin/os_tenant_name = admin/g" /etc/ceilometer/ceilometer.conf
sed -i "s/#os_password=admin/os_password = secure/g" /etc/ceilometer/ceilometer.conf

token=`openssl rand -hex 10`
sed -i "s/#metering_secret=change this or be hacked/metering_secret = ${token}/g" /etc/ceilometer/ceilometer.conf

# 6. Restart service
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart
