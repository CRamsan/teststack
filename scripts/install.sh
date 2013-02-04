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
	func_clear_values
}

function func_install_my-sql {
	if [ ! -n "$1" ]
	then
        	echo "No password provided"
		echo "Exiting now"
           	exit 1
       	else
		echo mysql-server mysql-server/root_password select PASSWORD | debconf-set-selections
		echo mysql-server mysql-server/root_password_again select PASSWORD | debconf-set-selections
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
	if [ -n "$1" ]
	then
		msg=$1
		echo $msg
	fi
	read -e $val
	echo $val
}

function func_set_value {
	key=$1
	val=$2
	eval "$key=$val"
        echo "$key=$val" >> $localrc
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
	fi
	func_set_value "$var" "$pw"
}

function func_retrieve_value {
	key=$1
	grep "$key" "$localrc"
}

function func_clear_values {
	rm "$localrc"
}

function func_replace_param {
	file=$1
	parameter=$2
	newvalue=$3

	oldline=$(sed -i 's/ //g' $file | grep '^$parameter=')
	newline=$(sed -i 's/$oldline/$parameter=$newvalue/g')
	echo $oldline
	echo "V-V-V-V-V-V-V-V"
	echo $newline
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

func_pre

##Add the Ubuntu Cloud Archive to the repository list.
##This command will also update and upgrade the system.
#funct_add_cloud_archive

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
connection = mysql://keystone:[YOUR_KEYSTONEDB_PASSWORD]@192.168.206.130/keystonefunc_install python-mysqldb

func_get_password "ROOTPASS" "MySQL Root" 
MYSQLPASS=$(func_retrieve_value "ROOTPASS")
func_install_my-sql $MYSQLPASS

echo "Update MySQL config"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
echo "Restart MySQL service"
service mysql restart

##Install RabbitMQ
echo "Install RabbitMQ"
func_install rabbitmq-server


##Install the identity service, Keystone!
##Install the package
func_install keystone
#Delete the keystone.db file created in the /var/lib/keystone directory.
rm /var/lib/keystone/keystone.db


func_set_password "KEYSTONEPASS" "Keystone user"
KEYSTONEPASS=$(func_retrieve_value "KEYSTONEPASS")

mysql -u root -p"$MYSQLPASS" <<EOF
CREATE DATABASE keystone;
GRANT ALL ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONEPASS';
GRANT ALL ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONEPASS';
EOF

func_replace_param "/etc/keystone/keystone.conf" "connection" "mysql://keystone:$KEYSTONEPASS@192.168.206.130/keystone"
