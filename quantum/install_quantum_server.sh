#!/bin/bash
#This script is based on the tutorial that can be found at:
#http://docs.openstack.org/trunk/openstack-compute/install/apt/content/

exit

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

##Install the identity service, Quantum!
##Install the package
func_install quantum-server

##Check if quantum password exists,
##if it does not, ask the user for one.
if [ ! -n "$QUANTUMPASS" ]
then
	func_set_password "QUANTUMPASS" "Quantum user"
	QUANTUMPASS=$(func_retrieve_value "QUANTUMPASS")
fi

##Give Quantum access to the database.
mysql -u root -p"$MYSQLPASS" <<EOF
CREATE DATABASE quantum;
GRANT ALL ON quantum.* TO 'quantum'@'%' IDENTIFIED BY "$QUANTUMPASS";
GRANT ALL ON quantum.* TO 'quantum'@'localhost' IDENTIFIED BY "$QUANTUMPASS";
EOF

##Check the ip of the quantum service.
if [ ! -n "$QUANTUMIP" ]
then
	echo "On which host has Quantum been installed? Please use the IP and not the hostname"
	QUANTUMIP=$(func_ask_user)
	func_set_value "QUANTUMIP" $QUANTUMIP
fi

##Configure Quantum to use mysql.
func_replace "/etc/quantum/quantum.conf" "# fake_rabbit = False" 	"fake_rabbit = False"
func_replace "/etc/quantum/quantum.conf" "# rabbit_host = localhost" 	"rabbit_host = $RABBITIP"
func_replace "/etc/quantum/quantum.conf" "# rabbit_password = guest"	"rabbit_password = $RABBITPASS"

func_replace "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" "sql_connection = sqlite:////var/lib/quantum/ovs.sqlite" "sql_connection = mysql://quantum:$QUANTUMPASS@$QUANTUMIP/quantum"
func_replace "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" "# Example: tenant_network_type = gre"			"tenant_network_type = gre"
func_replace "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" "# Default: enable_tunneling = False"			"enable_tunneling = True"
func_replace "/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini" "# Example: tunnel_id_ranges = 1:1000"			"tunnel_id_ranges = 1:1000"

service quantum-server restart
