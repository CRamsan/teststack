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

###################################################################################



dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G

losetup /dev/loop2 cinder-volumes

pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2
pvscan

service cinder-volume restart
service cinder-api restart
service cinder-scheduler restart

#cinder create --display_name test 1
#cinder list


