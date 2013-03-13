\#!/bin/bash
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

##Install the package
func_install kvm libvirt-bin pm-utils

func_echo "Configuring the Hypervisor"
func_replace "/etc/libvirt/qemu.conf" "#cgroup_device_acl = [" 					"cgroup_device_acl = ["
func_replace "/etc/libvirt/qemu.conf" "#    \"/dev/null\", \"/dev/full\", \"/dev/zero\","	"    \"/dev/null\", \"/dev/full\", \"/dev/zero\","
func_replace "/etc/libvirt/qemu.conf" "#    \"/dev/random\", \"/dev/urandom\","			"    \"/dev/random\", \"/dev/urandom\","
func_replace "/etc/libvirt/qemu.conf" "#    \"/dev/ptmx\", \"/dev/kvm\", \"/dev/kqemu\","	"    \"/dev/ptmx\", \"/dev/kvm\", \"/dev/kqemu\","
func_replace "/etc/libvirt/qemu.conf" "#    \"/dev/rtc\", \"/dev/hpet\","			"    \"/dev/rtc\", \"/dev/hpet\", \"/dev/net/tun\""
func_replace "/etc/libvirt/qemu.conf" "#]"							"]"

virsh net-destroy default
virsh net-undefine default

func_replace "/etc/libvirt/libvirtd.conf" "#listen_tls = 0" 		"listen_tls = 0"
func_replace "/etc/libvirt/libvirtd.conf" "#listen_tcp = 1" 		"listen_tcp = 1"
func_replace "/etc/libvirt/libvirtd.conf" "#auth_tcp = \"sasl\"" 	"auth_tcp = \"none\" "

func_replace "/etc/init/libvirt-bin.conf" "env libvirtd_opts=\"-d\"" "env libvirtd_opts=\"-d -l\" "

service libvirt-bin restart
exit
func_install nova-compute-kvm
exit

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

##Check for the existance of an AdminToken.
if [ ! -n "$ADMINTOKEN" ]
then
	func_set_password "ADMINTOKEN" "Admin token"
	ADMINTOKEN=$(func_retrieve_value "ADMINTOKEN")
fi

##Configure Keystone to use mysql.
func_replace "/etc/keystone/keystone.conf" "connection = sqlite:////var/lib/keystone/keystone.db" "connection = mysql://keystone:$KEYSTONEPASS@$KEYSTONEIP/keystone"

##And set the admin-token
func_replace "/etc/keystone/keystone.conf" "# admin_token = ADMIN" "admin_token = $ADMINTOKEN"

#Certs are not bundled so we will download them manually
mkdir /etc/keystone/ssl
wget http://ubuntu-cloud.archive.canonical.com/ubuntu/pool/main/k/keystone/keystone_2013.1.g3.orig.tar.gz
tar xzf keystone_2013.1.g3.orig.tar.gz
mv keystone-2013.1.g3/examples/pki/* /etc/keystone/ssl/
rm -r keystone-2013.1.g3
rm -r keystone_2013.1.g3.orig.tar.gz

##Next, restart the keystone service so that it picks up the new database configuration.
##Lastly, initialize the new keystone database.
service keystone restart
keystone-manage db_sync

echo "export OS_AUTH_URL=\"http://$KEYSTONEIP:5000/v2.0/\" " > keystonerc
echo "export SERVICE_ENDPOINT=\"http://$KEYSTONEIP:35357/v2.0\" " >> keystonerc
echo "export SERVICE_TOKEN=$ADMINTOKEN" >> keystonerc

