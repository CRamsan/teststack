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

##Install RabbitMQ
func_echo "Install RabbitMQ"
func_install rabbitmq-server

if [ ! -n "$RABBITPASS" ]
then
        func_set_password "RABBITPASS" "RabbitMQ"
        RABBITPASS=$(func_retrieve_value "RABBITPASS")
fi

rabbitmqctl change_password guest $RABBITPASS

