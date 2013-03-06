#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

localrc="localrc"

source functions.sh

###################################################################################

##Check for admin rights
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

##Run all the prerequisites
func_pre

##Add the Ubuntu Cloud Archive to the repository list.
##This command will also update and upgrade the system.
funct_add_cloud_archive

##Install NTP, set up the NTP server on your controller node so that it 
##receives data by modifying the ntp.conf file and restart the service.
func_echo "Install NTP"
func_install ntp

func_echo "Configure NTP"
sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf
func_echo "Restart NTP service"
service ntp restart

##Install MySQL
##During the install, you'll be prompted for the mysql root password. 
##Enter a password of your choice and verify it.
##Use sed to edit /etc/mysql/my.cnf to change bind-address from localhost (127.0.0.1)
##to any (0.0.0.0) and restart the mysql service.
func_echo "Install MySQL and related packages"
func_install python-mysqldb

if [ ! -n "$MYSQLPASS" ]
then
	func_set_password "MYSQLPASS" "MySQL Root" 
	MYSQLPASS=$(func_retrieve_value "MYSQLPASS")
fi
func_install_my-sql $MYSQLPASS

func_echo "Update MySQL config"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
func_echo "Restart MySQL service" func_create_user
service mysql restart

TMP=$(mysql -u root -p"$MYSQLPASS" -e "quit")
if [ -n "$TMP" ]
then
	func_echo "Error accessing database."
	exit
else
	func_echo "Database access successful"
fi

##Install RabbitMQ
func_echo "Install RabbitMQ"
func_install rabbitmq-server


###################################################################################

##Install the identity service, Keystone!
##Install the package
func_install keystone
#Delete the keystone.db file created in the /var/lib/keystone directory.
rm /var/lib/keystone/keystone.db

##Check if keystone password exists,
##if it does not, ask the user for one.
if [ ! -n "$KEYSTONEPASS" ]
then
	func_set_password "KEYSTONEPASS" "Keystone user"
	KEYSTONEPASS=$(func_retrieve_value "KEYSTONEPASS")
fi

##Give Keystone access to the database.
mysql -u root -p"$MYSQLPASS" <<EOF
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY "$KEYSTONEPASS";
GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY "$KEYSTONEPASS";
EOF

##Check the ip of the keystone service.
if [ ! -n "$KEYSTONEIP" ]
then
	echo "On which host has Keystone been installed? Please use the IP and not the hostname"
	KEYSTONEIP=$(func_ask_user)
	func_set_value "KEYSTONEIP" $KEYSTONEIP
fi

##Configure Keystone to use mysql.
func_replace_param "/etc/keystone/keystone.conf" "connection" "mysql://keystone:$KEYSTONEPASS@$KEYSTONEIP/keystone"

##Check for the existance of an AdminToken.
if [ ! -n "$ADMINTOKEN" ]
then
	func_set_password "ADMINTOKEN" "Admin token"
	ADMINTOKEN=$(func_retrieve_value "ADMINTOKEN")
fi

##And set the admin-token
func_replace_param "/etc/keystone/keystone.conf" "admin_token" "$ADMINTOKEN"

##Next, restart the keystone service so that it picks up the new database configuration.
##Lastly, initialize the new keystone database.
service keystone restart
keystone-manage db_sync

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
if [ ! -n "$ADMINUSERNAME" ] || [ ! -n "$ADMINUSERPASS"] || [ ! -n "$ADMINUSERID"]
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

if [ ! -n "$SERVGLANCEID" ]
then
	func_echo "Creating user Glance"
	SERVGLANCEID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "glance" "glance")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVGLANCEID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "SERVGLANCEID" $SERVGLANCEID
fi

if [ ! -n "$SERVCINDERID" ]
then
        func_echo "Creating user Cinder"
        SERVCINDERID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "cinder" "cinder")
        func_echo "Adding user to service tenant"
        func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVCINDERID" "$SERVTENANTID" "$ADMINROLEID"
        func_set_value "SERVCINDERID" $SERVCINDERID
fi

if [ ! -n "$SERVQUANTUMID" ]
then
        func_echo "Creating user Quantum"
        SERVGLANCEID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "quantum" "quantum")
        func_echo "Adding user to service tenant"
        func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVQUANTUMID" "$SERVTENANTID" "$ADMINROLEID"
        func_set_value "SERVQUANTUMID" $SERVQUANTUMID
fi


if [ ! -n "$SERVNOVAID" ]
then
	func_echo "Creating user Nova"
	SERVNOVAID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "nova" "nova")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVNOVAID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "SERVNOVAID" $SERVNOVAID
fi

if [ ! -n "$SERVEC2ID" ]
then
	func_echo "Creating user EC2"
	SERVEC2ID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "ec2" "ec2")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVEC2ID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "SERVEC2ID" $SERVEC2ID
fi

if [ ! -n "$SERVSWIFTID" ]
then
	func_echo "Creating user Swift"
	SERVSWIFTID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "swift" "swiftpass")
	func_echo "Adding user to service tenant"
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVSWIFTID" "$SERVTENANTID" "$ADMINROLEID"
	func_set_value "SERVSWIFTID" $SERVSWIFTID
fi
