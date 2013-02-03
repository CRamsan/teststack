#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

function func_install {
	COMMAND_INSTALL="apt-get install -y $1"
	if [ "$1" -n ]
	then
		echo "No parameter for install function"
		exit 1
	else
		echo "$COMMAND_INSTALL"
		`$COMMAND_INSTALL`
		if [ $? -eq 0 ]
		then
			echo "Install process of packages $1 run correctly "
			exit 0
		else
			echo "Install process of packages $1 failed"
		fi
	fi
}

##Install NTP, set up the NTP server on your controller node so that it 
##receives data by modifying the ntp.conf file and restart the service.
func_install ntp
sed -i 's/server ntp.ubuntu.com/server ntp.ubuntu.com\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10/g' /etc/ntp.conf
service ntp restart

##Install MySQL
##During the install, you'll be prompted for the mysql root password. 
##Enter a password of your choice and verify it.
##Use sed to edit /etc/mysql/my.cnf to change bind-address from localhost (127.0.0.1)
##to any (0.0.0.0) and restart the mysql service.
func_install python-mysqldb mysql-server
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
service mysql restart
