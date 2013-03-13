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

func_install ntp

if [ ! -n "$NTPIP" ]
then
	echo "On which host has NTP been installed? Please use the IP and not the hostname"
	NTPIP=$(func_ask_user)
	func_set_value "NTPIP" $NTPIP
fi

func_replace "/etc/ntp.conf" "server 0.ubuntu.pool.ntp.org" "server $NTPIP"

service ntp restart
