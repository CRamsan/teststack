#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

localrc="localrc"

function func_install {
	COMMAND_INSTALL="apt-get install -y"
	if [ ! -n "$1" ]
	then
		func_echo "No parameter for install function"
		exit 1
	else
		for package in "$@"
		do
			args="$args $package"
		done
		COMMAND_INSTALL="$COMMAND_INSTALL $args"
		func_echo "$COMMAND_INSTALL"
		$COMMAND_INSTALL
		if [ $? -eq 0 ]
		then
			func_echo "Install process of packages $1 run correctly "
		else
			func_echo "Install process of packages $1 failed"
			exit 1
		fi
	fi
}

function func_pre {
	func_install debconf
}

function func_install_my-sql {
	if [ ! -n "$1" ]
	then
        	func_echo "No password provided"
		func_echo "Exiting now"
           	exit 1
       	else
		PASSWORD=$1
		echo mysql-server mysql-server/root_password select $PASSWORD | debconf-set-selections
		echo mysql-server mysql-server/root_password_again select $PASSWORD | debconf-set-selections
	fi
	func_install mysql-server
}

function funct_add_cloud_archive {
#	apt-get update
#	apt-get upgrade -y
	apt-get install ubuntu-cloud-keyring
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main" > /etc/apt/source.d/folsom.list
	apt-get update
}

function func_ask_user {
	read -e val
	echo $val
}

function func_set_value {
	key=$1
	val=$2
	eval "$key=$val"
        echo "export $key=$val" >> $localrc
}

function func_set_password {
	var=$1
	mesg=$2
	pw=" "
	while true; do
		func_echo "Enter a password used for: $mesg."
		func_echo "If no password is provided, a random password will be generated:"
	        read -e $var
	        pw=${!var}
	        [[ "$pw" = "`echo $pw | tr -cd [:alnum:]`" ]] && break
	        func_echo "Invalid chars in password.  Try again:"
	done
	if [ ! $pw ]; then
		pw=`openssl rand -hex 10`
		func_echo "Password: $pw"
	fi
	func_set_value "$var" "$pw"
}

function func_retrieve_value {
	key=$1
	grep "$key" "$localrc" | cut -d'=' -f2 | sed 's/export //g'
}

function func_clear_values {
	rm "$localrc"
}

function func_replace_param {
	file=$1
	parameter=$2
	newvalue=$3
	func_echo "In file $file - Parameter \"$parameter\" is been set to \"$newvalue\""
	oldline=$(sed 's/ =//g' $file | grep "^$parameter=")
	sed -i 's/ =/=/g' $file
	newvaluefixed=$(echo $newvalue | sed -e 's/[]\/()$*.^|[]/\\&/g')
	oldlinefixed=$(echo $oldline | sed -e 's/[]\/()$*.^|[]/\\&/g')
	sed -i "s/$oldlinefixed/$parameter=$newvaluefixed/g" $file
	newline=$(cat $file | grep "^$parameter=")
	func_echo $oldline
	func_echo "V-V-V-V-V-V-V-V"
	func_echo $newline
}

function func_create_tenant {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	TENANTNAME=$3
	DESCRIPTION="No description"
       	TENANTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 tenant-create --name "$TENANTNAME" --description "$DESCRIPTION" | grep "id" | sed 's/ //g')
	echo $TENANTID
}

function func_create_user {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	TENANTID=$3
	USERNAME=$4
	PASSWORD=$5
	ADMINUSERID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 user-create --tenant-id "$TENANTID"  --name "$USERNAME" --pass "$PASSWORD" | grep "id" | sed 's/ //g' | cut -d'|' -f3)	
	echo $USERID
}

function func_create_role {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	ROLEID=$3
	ADMINROLEID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 role-create --name "$ROLENAME" | grep "id" | sed 's/ //g' | cut -d'|' -f3)
	echo $ROLEID
}

function func_user_role_add {
	ADMINTOKEN=$1
	KEYSTONEIP=$2
	USERID=$3
	TENANTID=$4
	ROLEID=$5
	keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 user-role-add --user-id "$USERID" --tenant-id "$TENANTID" --role-id "$ROLEID"
}

function func_echo {
	MSG=$1
	echo -e "\E[32m$MSG"
	tput sgr0
}

###################################################################################

##Check for admin rights
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

##Run all the prerequisites
#func_pre

##Add the Ubuntu Cloud Archive to the repository list.
##This command will also update and upgrade the system.
#funct_add_cloud_archive

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
fund_echo "Install RabbitMQ"
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
if [ ! -n "$DEFTENANTNAME" ] || [ ! -n "$DEFTENANTID"]
then
        echo "What is going to be the name for the default tenant?:"
        DEFTENANTNAME=$(func_ask_user)
        func_set_value "DEFTENANTNAME" $DEFTENANTNAME
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
if [ ! -n "$SERVTENANTID" ]
then
	SERVTENATID=$(func_create_tenant "$ADMINTOKEN" "$KEYSTONEIP" "service")
	func_set_value "SERVTENANTID" $SERVTENANTID
fi

if [ ! -n "$SERVGLANCEID" ]
then
	SERVGLANCEID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "glance" "glance")
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVGALNCEID" "$SERVTENANTID" "$ADMINROLEID"
fi

if [ ! -n "$SERVNOVAID" ]
then
	SERVNOVAID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "nova" "nova")
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVNOVAID" "$SERVTENANTID" "$ADMINROLEID"
fi

if [ ! -n "$SERVEC2ID" ]
then
	SERVEC2ID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTEANTID" "ec2" "ec2")
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVEC2ID" "$SERVTENANTID" "$ADMINROLEID"
fi

if [ ! -n "$SERVSWIFTID" ]
then
	SERVSWIFTID=$(func_create_user "$ADMINTOKEN" "$KEYSTONEIP" "$SERVTENANTID" "swift" "swiftpass")
	func_user_role_add "$ADMINTOKEN" "$KEYSTONEIP" "$SERVSWIFTID" "$SERVTENANTID" "$ADMINROLEID"
fi

func_replace_param "/etc/keystone/keystone.conf" "driver" "keystone.catalog.backends.sql.Catalog"
