#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

localrc="localrc"

source functions.sh
source $localrc

###################################################################################

##Check for admin rights
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Give the IP of a storage node"
NODEIP=$(func_ask_user)
func_set_value "NODEIP" $NODEIP

cd /etc/swift

swift-ring-builder account.builder add z1-$NODEIP:6002/sdb1 100
swift-ring-builder container.builder add z1-$NODEIP:6001/sdb1 100
swift-ring-builder object.builder add z1-$NODEIP:6000/sdb1 100

swift-ring-builder account.builder
swift-ring-builder container.builder
swift-ring-builder object.builder

swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

func_echo "Now we are going to copy the ring files to the storage node"
func_echo "As which user are you going to do the transfer?[Not Root]"
TUSERNAME=$(func_ask_user)

scp account.ring.gz "$TUSERNAME"@"$NODEIP":~
scp container.ring.gz "$TUSERNAME"@"$NODEIP":~
scp object.ring.gz "$TUSERNAME"@"$NODEIP":~

read
func_echo "Press enter when you are ready"

chown -R swift:swift /etc/swift
swift-init proxy start
