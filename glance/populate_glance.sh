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

glance	--os-username="$ADMINUSERNAME" \
	--os-password="$ADMINUSERPASS" \
	--os-tenant-id="$DEFTENANTID" \
	--os-auth-url="http://$GLANCEIP:5000/v2.0/" \
 	image-create \
	--location http://uec-images.ubuntu.com/releases/12.04/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img \
	--is-public true \
	--disk-format qcow2 \
	--container-format bare \
	--name "Ubuntu"

wget http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img
glance 	--os-username="$ADMINUSERNAME" \
       	--os-password="$ADMINUSERPASS" \
       	--os-tenant-id="$DEFTENANTID" \
       	--os-auth-url="http://$GLANCEIP:5000/v2.0/" \
	image-create \
	--is-public true \
	--disk-format qcow2 \
	--container-format bare \
	--name "CirrOS 0.3.1" < cirros-0.3.1-x86_64-disk.img

glance 	-os-username="$ADMINUSERNAME" \
        --os-password="$ADMINUSERPASS" \
        --os-tenant-id="$DEFTENANTID" \
        --os-auth-url="http://$GLANCEIP:5000/v2.0/" \
	image-list
