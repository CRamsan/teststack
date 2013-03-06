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

##Run all the prerequisites
func_pre

##Add the Ubuntu Cloud Archive to the repository list.
##This command will also update and upgrade the system.
funct_add_cloud_archive
#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

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
