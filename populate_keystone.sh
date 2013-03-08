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

##Check for the existance of a default tenant's name and their ID.
if [ ! -n "$DEFTENANTNAME" ] || [ ! -n "$DEFTENANTID" ]
then
        echo "What is going to be the name for the default tenant?:"
        DEFTENANTNAME=$(func_ask_user)
        func_set_value "DEFTENANTNAME" $DEFTENANTNAME

	#func_echo "func_create_tenant \"$ADMINTOKEN\" \"$KEYSTONEIP\" \"$DEFTENANTNAME\""

	DEFTENANTID=$(func_create_tenant "$ADMINTOKEN" "$KEYSTONEIP" "$DEFTENANTNAME" )
	func_set_value "DEFTENANTID" $DEFTENANTID
fi

##Check for the existance of an admin user(name, password and ID). If it doess not exist, create one.
##This user will belong to the default tenant.
if [ ! -n "$ADMINUSERNAME" ] || [ ! -n "$ADMINUSERPASS" ] || [ ! -n "$ADMINUSERID" ]
then
        echo "What is going to be the name for the admin user?:"
        ADMINUSERNAME=$(func_ask_user)
        func_set_value "ADMINUSERNAME" $ADMINUSERNAME

        func_set_password "ADMINUSERPASS" "Admin user's password"
        ADMINUSERPASS=$(func_retrieve_value "ADMINUSERPASS")

	#func_echo "func_create_user \"$ADMINTOKEN\" \"$KEYSTONEIP\" \"$DEFTENANTID\"  \"$ADMINUSERNAME\" \"$ADMINUSERPASS\""

	ADMINUSERID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$DEFTENANTID"  "$ADMINUSERNAME" "$ADMINUSERPASS")
	func_set_value "ADMINUSERID" $ADMINUSERID
fi

##Check for the existance of an admin role. IF it does not exist, create one.
if [ ! -n "$ADMINROLENAME" ] || [ ! -n "$ADMINROLEID" ]
then
        echo "What is going to be the name for the admin role?:"
        ADMINROLENAME=$(func_ask_user)
        func_set_value "ADMINROLENAME" $ADMINROLENAME
	ADMINROLEID=$(func_create_role "$ADMINTOKEN" "$KEYSTONEIP" "$ADMINROLENAME")
	func_set_value "ADMINROLEID" $ADMINROLEID
fi

##Add the admin user to the admin role. This command produces no output.
func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$ADMINUSERID" "$DEFTENANTID" "$ADMINROLEID"

##Create another tenant. This tenant will hold all the OpenStack services.
func_echo "Creating tenant for OpenStack services"
if [ ! -n "$SERVTENANTID" ]
then
	func_echo "Creating service user"
	SERVTENANTID=$(func_create_tenant "$ADMINTOKEN" "$KEYSTONEIP" "service")
	func_set_value "SERVTENANTID" $SERVTENANTID
fi

##Start with the creation of users for the services that use Keystone
if [ ! -n "$USERNOVAID" ]
then
	func_echo "Creating user Nova"
	SERVNOVAID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "nova" "nova")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$USERNOVAID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "USERNOVAID" $USERNOVAID
 	func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "nova" "compute" "Compute Service"
fi

if [ ! -n "$USERGLANCEID" ]
then
	func_echo "Creating user Glance"
	SERVGLANCEID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "glance" "glance")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$USERGLANCEID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "USERGLANCEID" $USERGLANCEID
fi

if [ ! -n "$USERCINDERID" ]
then
        func_echo "Creating user Cinder"
        SERVCINDERID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "cinder" "cinder")
        func_echo "Adding user to service tenant"
        func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$USERCINDERID" "$SERVTENANTID" "$ADMINROLEID"
        func_set_value "USERCINDERID" $USERCINDERID
fi

if [ ! -n "$USERQUANTUMID" ]
then
        func_echo "Creating user Quantum"
        SERVGLANCEID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "quantum" "quantum")
        func_echo "Adding user to service tenant"
        func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$USERQUANTUMID" "$SERVTENANTID" "$ADMINROLEID"
        func_set_value "USERQUANTUMID" $USERQUANTUMID
fi

if [ ! -n "$USEREC2ID" ]
then
	func_echo "Creating user EC2"
	SERVEC2ID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "ec2" "ec2")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$USEREC2ID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "USEREC2ID" $USEREC2ID
fi

if [ ! -n "$USERSWIFTID" ]
then
	func_echo "Creating user Swift"
	SERVSWIFTID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "swift" "swiftpass")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$USERSWIFTID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "USERSWIFTID" $USERSWIFTID
fi

192.168.0.50	keystone
192.168.0.51	glance
192.168.0.52	cinder
192.168.0.53	horizon
192.168.0.54	swift
192.168.0.55	quantum
192.168.0.56	nova

func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "nova" "compute" "Compute Service" "192.168.0.56"
func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "cinder" "volume" "Volume Service" "192.168.0.52"
func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "glance" "image" "Image Service" "192.168.0.51"
func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "swift" "object-store" "Object Storage Service" "192.168.0.54"
func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "keystone" "indentity" "Identity Service" "192.168.0.50"
func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "ec2" "ec2" "EC2 Compatibility Service" "192.168.0.56"
func_create_service "$ADMINTOKEN" "$KEYSTONEIP" "quantum" "network" "Network Service" "192.168.0.55"


