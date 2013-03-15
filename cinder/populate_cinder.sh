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

func_echo "Make sure the partition $CINDERDEV is formatted and ready to be used by LVM, press [ENTER] when ready"
read 

if [ ! -n "$CINDERDEV" ]
then
	func_echo "Variable CINDERDEV is not defined. Source the RC file or run the install_cinder sript"
	exit
fi

pvcreate /dev/"$CINDERDEV"
vgcreate cinder-volumes /dev/"$CINDERDEV"
pvscan

service cinder-volume restart
service cinder-api restart
service cinder-scheduler restart

cinder --os-username "$ADMINUSERNAME" --os-password "$ADMINUSERPASS" --os-tenant-name "$DEFTENANTNAME" --os-auth-url "http://$KEYSTONEIP:5000/v2.0/" create --display_name test 1
cinder --os-username "$ADMINUSERNAME" --os-password "$ADMINUSERPASS" --os-tenant-name "$DEFTENANTNAME" --os-auth-url "http://$KEYSTONEIP:5000/v2.0/" list
