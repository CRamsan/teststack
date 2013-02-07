#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

localrc="localrc"

function func_install {
	COMMAND_INSTALL="apt-get install -y"
	if [ ! -n "$1" ]
	then
		echo "No parameter for install function"
		exit 1
	else
		for package in "$@"
		do
			args="$args $package"
		done
		COMMAND_INSTALL="$COMMAND_INSTALL $args"
		echo "$COMMAND_INSTALL"
		$COMMAND_INSTALL
		if [ $? -eq 0 ]
		then
			echo "Install process of packages $1 run correctly "
		else
			echo "Install process of packages $1 failed"
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
        	echo "No password provided"
		echo "Exiting now"
           	exit 1
       	else
		PASSWORD=$1
		echo mysql-server mysql-server/root_password select $PASSWORD | debconf-set-selections
		echo mysql-server mysql-server/root_password_again select $PASSWORD | debconf-set-selections
	fi
	func_install mysql-server
}

function funct_add_cloud_archive {
	apt-get update
	apt-get upgrade -y
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
		echo "Enter a password used for: $mesg."
		echo "If no password is provided, a random password will be generated:"
	        read -e $var
	        pw=${!var}
	        [[ "$pw" = "`echo $pw | tr -cd [:alnum:]`" ]] && break
	        echo "Invalid chars in password.  Try again:"
	done
	if [ ! $pw ]; then
		pw=`openssl rand -hex 10`
		echo "Password: $pw"
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

	echo "In file $file - Parameter \"$parameter\" is been set to \"$newvalue\""

	oldline=$(sed 's/ //g' $file | grep "^$parameter=")
	sed -i 's/ //g' $file
	newvaluefixed=$(echo $newvalue | sed -e 's/[]\/()$*.^|[]/\\&/g')
	oldlinefixed=$(echo $oldline | sed -e 's/[]\/()$*.^|[]/\\&/g')
	sed -i "s/$oldlinefixed/$parameter=$newvaluefixed/g" $file
	newline=$(cat $file | grep "^$parameter=")

	echo $oldline
	echo "V-V-V-V-V-V-V-V"
	echo $newline
}

###################################################################################

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

func_pre

##Add the Ubuntu Cloud Archive to the repository list.
##This command will also update and upgrade the system.
funct_add_cloud_archive

##Install NTP, set up the NTP server on your controller node so that it 
##receives data by modifying the ntp.conf file and restart the service.
echo "Install NTP"
func_install ntp

echo "Configure NTP"
sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf
echo "Restart NTP service"
service ntp restart

##Install MySQL
##During the install, you'll be prompted for the mysql root password. 
##Enter a password of your choice and verify it.
##Use sed to edit /etc/mysql/my.cnf to change bind-address from localhost (127.0.0.1)
##to any (0.0.0.0) and restart the mysql service.
echo "Install MySQL and related packages"
func_install python-mysqldb

if [ ! -n "$MYSQLPASS" ]
then
	func_set_password "MYSQLPASS" "MySQL Root" 
	MYSQLPASS=$(func_retrieve_value "MYSQLPASS")
fi
func_install_my-sql $MYSQLPASS

echo "Update MySQL config"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
echo "Restart MySQL service"
service mysql restart

##Install RabbitMQ
echo "Install RabbitMQ"
func_install rabbitmq-server

###################################################################################

##Install the identity service, Keystone!
##Install the package
func_install keystone
#Delete the keystone.db file created in the /var/lib/keystone directory.
rm /var/lib/keystone/keystone.db

if [ ! -n "$KEYSTONEPASS" ]
then
	func_set_password "KEYSTONEPASS" "Keystone user"
	KEYSTONEPASS=$(func_retrieve_value "KEYSTONEPASS")
fi

mysql -u root -p"$MYSQLPASS" <<EOF
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONEPASS';
GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONEPASS';
EOF

if [ ! -n "$KEYSTONEIP" ]
then
	echo "On which host has Keystone been installed? Please use the IP and not the hostname"
	KEYSTONEIP=$(func_ask_user)
	func_set_value "KEYSTONEIP" $KEYSTONEIP
fi

func_replace_param "/etc/keystone/keystone.conf" "connection" "mysql://keystone:$KEYSTONEPASS@$KEYSTONEIP/keystone"

if [ ! -n "$ADMINTOKEN" ]
then
	func_set_password "ADMINTOKEN" "Admin token"
	ADMINTOKEN=$(func_retrieve_value "ADMINTOKEN")
fi

if [ ! -n "$DEFTENANTNAME" ] | [ ! -n "$DEFTENANTID"]
then
        echo "What is going to be the name for the default tenant?:"
        DEFTENANTNAME=$(func_ask_user)
        func_set_value "DEFTENANTNAME" $DEFTENANTNAME
	DEFTENANTID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 tenant-create --name "$DEFTENANTNAME" --description "Default Tenant" | grep "id" | sed 's/ //g' | cut -d'|' -f3)
	func_set_value "DEFTENANTID" $DEFTENANTID
fi

if [ ! -n "$ADMINUSERNAME" ] | [ ! -n "$ADMINUSERPASS"]
then
        echo "What is going to be the name for the admin user?:"
        ADMINUSERNAME=$(func_ask_user)
        func_set_value "ADMINUSERNAME" $ADMINUSERNAME

        func_set_password "ADMINUSERPASS" "Admin user's password"
        ADMINUSERPASS=$(func_retrieve_value "ADMINUSERPASS")

	ADMINUSERID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 user-create --tenant-id "$DEFTENANTID"  --name "$ADMINUSERNAME" --pass "$ADMINUSERPASS" | grep "id" | sed 's/ //g' | cut -d'|' -f3)
fi




if [ ! -n "$ADMINROLENAME" ]
then
        echo "What is going to be the name for the admin role?:"
        ADMINROLENAME=$(func_ask_user)
        func_set_value "ADMINROLENAME" $ADMINROLENAME
	ADMINROLEID=$(keystone --token "$ADMINTOKEN" --endpoint http://"$KEYSTONEIP":35357/v2.0 role-create --name "$ADMINROLENAME" | grep "id" | sed 's/ //g' | cut -d'|' -f3)
fi

keystone --token "$ADMINTOKEN" --endpoint http://"KEYSTONEIP":35357/v2.0 user-role-add --user-id "$ADMINUSERID" --tenant-id "$DEFTENANTID" --role-id "$ADMINROLEID"

