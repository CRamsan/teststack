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

func_install swift rsync memcached python-netifaces python-xattr python-memcache

mkdir -p /etc/swift
chown -R swift:swift /etc/swift/

if [ ! -n "$SWIFTHASH" ]
then
        func_set_password "SWIFTHASH" "Swift Hash"
        SWIFTHASH=$(func_retrieve_value "SWIFTHASH")
fi

echo "[swift-hash]" > /etc/swift/swift.conf
echo "# random unique string that can never change (DO NOT LOSE)" > /etc/swift/swift.conf
echo "swift_hash_path_suffix = $SWIFTHASH" > /etc/swift/swift.conf


