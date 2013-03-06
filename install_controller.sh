#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

localrc="localrc"

source functions.sh
source $localrc

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

if [ ! -n "$RABBITPASS" ]
then
        func_set_password "RABBITPASS" "RabbitMQ"
        RABBITPASS=$(func_retrieve_value "RABBITPASS")
fi

rabbitmqctl change_password guest $RABBITPASS
