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

###################################################################################

func_install cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt

##Check if keystone password exists,
##if it does not, ask the user for one.
if [ ! -n "$CINDERPASS" ]
then
        func_set_password "CINDERPASS" "Cinder user"
        CINDERPASS=$(func_retrieve_value "CINDERPASS")
fi

##Give Keystone access to the database.
mysql -u root -p"$MYSQLPASS" <<EOF
CREATE DATABASE cinder;
GRANT ALL ON cinder.* TO 'cinder'@'%' IDENTIFIED BY "$CINDERPASS";
GRANT ALL ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY "$CINDERPASS";
EOF

##Check the ip of the keystone service.
if [ ! -n "$CINDERIP" ]
then
        echo "On which host has Cinder been installed? Please use the IP and not the hostname"
        CINDERIP=$(func_ask_user)
        func_set_value "CINDERIP" $CINDERIP
fi

func_replace "/etc/cinder/api-paste.ini" "service_host = 127.0.0.1"			"service_host = $CINDERIP"
func_replace "/etc/cinder/api-paste.ini" "auth_host = 127.0.0.1"			"auth_host = $KEYSTONEIP"
func_replace "/etc/cinder/api-paste.ini" "admin_tenant_name = %SERVICE_TENANT_NAME%"	"admin_tenant_name = service"
func_replace "/etc/cinder/api-paste.ini" "admin_user = %SERVICE_USER%"			"admin_user = cinder"
func_replace "/etc/cinder/api-paste.ini" "admin_password = %SERVICE_PASSWORD%"		"admin_password = cinder"

echo "sql_connection = mysql://cinder:$CINDERPASS@$CINDERIP/cinder" >> /etc/cinder/cinder.conf
echo "rabbit_host = $KEYSTONEIP"  >> /etc/cinder/cinder.conf
echo "rabbit_port = 5672" >> /etc/cinder/cinder.conf
echo "rabbit_userid = guest" >> /etc/cinder/cinder.conf
echo "rabbit_password = $RABBITPASS" >> /etc/cinder/cinder.conf
echo "rabbit_virtual_host = /" >> /etc/cinder/cinder.conf

func_replace "/etc/lvm/lvm.conf" "filter = [ \"a/.*/\" ]" "filter = [ \"a/sdb1/\", \"r/.*/\"]"

sh -c "echo 'include $volumes_dir/*' >> /etc/tgt/conf.d/cinder.conf"

sudo restart tgt

cinder-manage db sync

dd if=/dev/zero of=cinder-volumes bs=1 count=0 seek=2G

losetup /dev/loop2 cinder-volumes

pvcreate /dev/loop2
vgcreate cinder-volumes /dev/loop2
pvscan

service cinder-volume restart
service cinder-api restart
service cinder-scheduler restart

#cinder create --display_name test 1
#cinder list
