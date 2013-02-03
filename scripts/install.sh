#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

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

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

function funct_add_cloud_archive {
	apt-get update
	apt-get upgrade -y
	apt-get install ubuntu-cloud-keyring
	echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main" > /etc/apt/source.d/folsom.list
	apt-get update
}

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
func_install python-mysqldb mysql-server
echo "Update MySQL config"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
echo "Restart MySQL service"
service mysql restart

##Install RabbitMQ
echo "Install RabbitMQ"
func_install rabbitmq-server
