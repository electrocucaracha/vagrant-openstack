#!/bin/bash

apt-get update
apt-get install -y git openjdk-7-jdk maven

distribution_name='distribution-karaf'
release_name='0.4.0-Beryllium'
folder=${distribution_name}-${release_name}
filename=${folder}.zip

wget https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/$distribution_name/$release_name/$filename -O /tmp/$filename

unzip /tmp/$filename
rm /tmp/$filename
cd $folder/
# Enable OpenStack features
sed -i "s/featuresBoot=config,standard,region,package,kar,ssh,management/featuresBoot=config,standard,region,package,kar,ssh,management,odl-base-all,odl-aaa-authn,odl-restconf,odl-nsf-all,odl-adsal-northbound,odl-mdsal-apidocs,odl-ovsdb-openstack,odl-ovsdb-northbound,odl-dlux-core/g" etc/org.apache.karaf.features.cfg
./bin/start
