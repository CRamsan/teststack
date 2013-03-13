\#!/bin/bash
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

##Install the package
func_install nova-compute-kvm

/etc/nova/api-paste.ini

/etc/nova/nova-compute.conf

/etc/nova/nova.conf

service nova-compute restart
