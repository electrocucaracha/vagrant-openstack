#!/bin/bash

apt-get update -y
apt-get install -y openjdk-7-jre python-networking-odl unzip

distribution_name='distribution-karaf'
release_name='0.4.0-Beryllium'
folder=${distribution_name}-${release_name}
filename=${folder}.zip

wget https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/$distribution_name/$release_name/$filename -O /tmp/$filename

pushd /tmp/
unzip /tmp/$filename
cd $folder/
# Enable OpenStack features
sed -i "s/featuresBoot=config,standard,region,package,kar,ssh,management/featuresBoot=config,standard,region,package,kar,ssh,management,odl-base-all,odl-aaa-authn,odl-restconf,odl-nsf-all,odl-adsal-northbound,odl-mdsal-apidocs,odl-ovsdb-openstack,odl-ovsdb-northbound,odl-dlux-core,odl-dlux-node,odl-dlux-yangui,odl-dlux-yangvisualizer/g" etc/org.apache.karaf.features.cfg
./bin/start
popd
