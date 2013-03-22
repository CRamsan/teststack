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

func_install swift-account swift-container swift-object xfsprogs

if [ ! -n "$NODEIP" ] 
then
	echo "What is the local IP"
	NODEIP=$(func_ask_user)
	func_set_value "NODEIP" $NODEIP
fi

if [ ! -n "$SWIFTDEV" ]
then
        func_echo "On which device will Swift store the data? Please choose one on the form [sda2, sda3, sdb1, etc...]"
        func_echo "More devices can be configured later"
        SWIFTDEV=$(func_ask_user)
        func_set_value "SWIFTDEV" $SWIFTDEV
fi

mkfs.xfs -i size=1024 /dev/$SWIFTDEV
echo "/dev/$SWIFTDEV /srv/node/device xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
mkdir -p /srv/node/device
mount /srv/node/device
chown -R swift:swift /srv/node

func_echo "Modify /etc/rsyncd.conf"
: <<'END'
echo "uid = swift" 			> /etc/rsyncd.conf
echo "gid = swift" 			>> /etc/rsyncd.conf
echo "log file = /var/log/rsyncd.log" 	>> /etc/rsyncd.conf
echo "pid file = /var/run/rsyncd.pid" 	>> /etc/rsyncd.conf
echo "address = $NODEIP" 		>> /etc/rsyncd.conf
echo "" 				>> /etc/rsyncd.conf
echo "[account]"			>> /etc/rsyncd.conf
echo "max connections = 2" 		>> /etc/rsyncd.conf
echo "path = /srv/node/" 		>> /etc/rsyncd.conf
echo "read only = false" 		>> /etc/rsyncd.conf
echo "lock file = /var/lock/account.lock" >> /etc/rsyncd.conf
echo "" 				>> /etc/rsyncd.conf
echo "[container]" 			>> /etc/rsyncd.conf
echo "max connections = 2" 		>> /etc/rsyncd.conf
echo "path = /srv/node/" 		>> /etc/rsyncd.conf
echo "read only = false" 		>> /etc/rsyncd.conf
echo "lock file = /var/lock/container.lock" >> /etc/rsyncd.conf
echo "" 				>> /etc/rsyncd.conf
echo "[object]" 			>> /etc/rsyncd.conf
echo "max connections = 2" 		>> /etc/rsyncd.conf
echo "path = /srv/node/" 		>> /etc/rsyncd.conf
echo "read only = false" 		>> /etc/rsyncd.conf
echo "lock file = /var/lock/object.lock" >> /etc/rsyncd.conf
END

func_replace "/etc/default/rsync" "RSYNC_ENABLE=false" "RSYNC_ENABLE = true"

service rsync start

#func_replace "/etc/swift/account-server.conf" 	"bind_ip = 0.0.0.0" "bind_ip = $NODEIP"
func_echo "Modify /etc/swift/account-server.conf"
read

#func_replace "/etc/swift/container-server.conf"	"bind_ip = 0.0.0.0" "bind_ip = $NODEIP"
func_echo "Modify /etc/swift/container-server.conf"
read

#func_replace "/etc/swift/object-server.conf"	"bind_ip = 0.0.0.0" "bind_ip = $NODEIP"
func_echo "Modify /etc/swift/object-server.conf"
read

swift-init object-server start
swift-init object-replicator start
swift-init object-updater start
swift-init object-auditor start
swift-init container-server start
swift-init container-replicator start
swift-init container-updater start
swift-init container-auditor start
swift-init account-server start
swift-init account-replicator start
swift-init account-auditor start
