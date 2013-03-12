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

echo "What is the local IP"
NODEIP=$(func_ask_user)
func_set_value "NODEIP" $NODEIP

mkfs.xfs -i size=1024 /dev/sdb1
echo "/dev/sdb1 /srv/node/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0" >> /etc/fstab
mkdir -p /srv/node/sdb1
mount /srv/node/sdb1
chown -R swift:swift /srv/node


printf "%s" "uid = swift\n\
gid = swift\n\
log file = /var/log/rsyncd.log\n\
pid file = /var/run/rsyncd.pid\n\
address = $NODEIP\n\
\n\
[account]\n\
max connections = 2\n\
path = /srv/node/\n\
read only = false\n\
lock file = /var/lock/account.lock\n\
\n\
[container]\n\
max connections = 2\n\
path = /srv/node/\n\
read only = false\n\
lock file = /var/lock/container.lock\n\
\n\
[object]\n\
max connections = 2\n\
path = /srv/node/\n\
read only = false\n\
lock file = /var/lock/object.lock >> /etc/rsyncd.conf

func_replace "/etc/default/rsync" "RSYNC_ENABLE=false" "RSYNC_ENABLE = true"

service rsync start








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
