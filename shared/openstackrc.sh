#!/bin/bash

cat << EOF > /root/admin-openrc.sh
export OS_VOLUME_API_VERSION=2
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=http://${IDENTITY_HOSTNAME}:35357/v3
EOF
