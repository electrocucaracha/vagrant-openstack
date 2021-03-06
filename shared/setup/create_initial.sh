#! /bin/bash

pushd /etc/swift/
swift-ring-builder account.builder create 10 1 1
swift-ring-builder account.builder add \
  --region 1 --zone 1 --ip ${my_ip} --port 6002 --device sdc --weight 100
swift-ring-builder account.builder rebalance

swift-ring-builder container.builder create 10 1 1
swift-ring-builder container.builder add \
  --region 1 --zone 1 --ip ${my_ip} --port 6001 --device sdc --weight 100
swift-ring-builder container.builder rebalance

swift-ring-builder object.builder create 10 1 1
swift-ring-builder object.builder add r1z1-${my_ip}:6000/sdc 100
swift-ring-builder object.builder rebalance

# Copy the account.ring.gz, container.ring.gz, and object.ring.gz files to the /etc/swift directory on each storage node and any additional nodes running the proxy service.

popd
