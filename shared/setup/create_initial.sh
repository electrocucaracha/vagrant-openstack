#! /bin/bash

pushd /etc/swift/
swift-ring-builder account.builder create 10 3 1
swift-ring-builder account.builder add r1z1-${my_ip}:6002/sdc1 100
swift-ring-builder account.builder rebalance

swift-ring-builder container.builder create 10 3 1
swift-ring-builder container.builder add r1z1-${my_ip}:6001/sdc1 100
swift-ring-builder container.builder rebalance

swift-ring-builder object.builder create 10 3 1
swift-ring-builder object.builder add r1z1-${my_ip}:6000/sdc1 100
swift-ring-builder object.builder rebalance

# Copy the account.ring.gz, container.ring.gz, and object.ring.gz files to the /etc/swift directory on each storage node and any additional nodes running the proxy service.

popd
