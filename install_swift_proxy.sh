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

func_install swift-proxy memcached python-swiftclient python-keystone-auth-token
echo "What is the local IP"
NODEIP=$(func_ask_user)
func_set_value "NODEIP" $NODEIP

cd /etc/swift
openssl req -new -x509 -nodes -out cert.crt -keyout cert.key


func_replace "/etc/memcached.conf" "-l 127.0.0.1" "-l $NODEIP"

service memcached restart

echo "[DEFAULT]" 				> /etc/swift/proxy-server.conf
echo "bind_port = 8888" 			>> /etc/swift/proxy-server.conf
echo "user = demo" 				>> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[pipeline:main]" 				>> /etc/swift/proxy-server.conf
echo "pipeline = healthcheck cache authtoken swift3 keystone proxy-server" >> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[app:proxy-server]" 			>> /etc/swift/proxy-server.conf
echo "use = egg:swift#proxy" 			>> /etc/swift/proxy-server.conf
echo "allow_account_management = true" 		>> /etc/swift/proxy-server.conf
echo "account_autocreate = true" 		>> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[filter:keystone]" 			>> /etc/swift/proxy-server.conf
echo "paste.filter_factory = keystone.middleware.swift_auth:filter_factory" >> /etc/swift/proxy-server.conf
echo "operator_roles = Member,admin, swiftoperator" >> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[filter:authtoken]" 			>> /etc/swift/proxy-server.conf
echo "paste.filter_factory = keystone.middleware.auth_token:filter_factory" >> /etc/swift/proxy-server.conf
echo "# Delaying the auth decision is required to support token-less" >> /etc/swift/proxy-server.conf
echo "# usage for anonymous referrers ('.r:*')." >> /etc/swift/proxy-server.conf
echo "delay_auth_decision = 10" 		>> /etc/swift/proxy-server.conf
echo "service_port = 5000" 			>> /etc/swift/proxy-server.conf
echo "service_host = $KEYSTONEIP" 		>> /etc/swift/proxy-server.conf
echo "auth_port = 35357" 			>> /etc/swift/proxy-server.conf
echo "auth_host = $KEYSTONEIP" 			>> /etc/swift/proxy-server.conf
echo "auth_protocol = http" 			>> /etc/swift/proxy-server.conf
echo "auth_uri = http://$KEYSTONEIP:5000/" 	>> /etc/swift/proxy-server.conf
echo "auth_token = $SERVICETOKEN" 		>> /etc/swift/proxy-server.conf
echo "admin_token = 012345SECRET99TOKEN012345" 	>> /etc/swift/proxy-server.conf
echo "admin_tenant_name = service" 		>> /etc/swift/proxy-server.conf
echo "admin_user = swift" 			>> /etc/swift/proxy-server.conf
echo "admin_password = swift" 			>> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[filter:cache]" 				>> /etc/swift/proxy-server.conf
echo "use = egg:swift#memcache" 		>> /etc/swift/proxy-server.conf
echo "set log_name = cache" 			>> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[filter:catch_errors]" 			>> /etc/swift/proxy-server.conf
echo "use = egg:swift#catch_errors" 		>> /etc/swift/proxy-server.conf
echo "" 					>> /etc/swift/proxy-server.conf
echo "[filter:healthcheck]" 			>> /etc/swift/proxy-server.conf
echo "use = egg:swift#healthcheck" 		>> /etc/swift/proxy-server.conf

cd /etc/swift
swift-ring-builder account.builder create 5 3 1
swift-ring-builder container.builder create 5 3 1
swift-ring-builder object.builder create 5 3 1


echo "Give the IP of a storage node"
NODEIP=$(func_ask_user)
func_set_value "NODEIP" $NODEIP

swift-ring-builder account.builder add z1-$NODEIP:6002/sdb1 100
swift-ring-builder container.builder add z1-$NODEIP:6001/sdb1 100
swift-ring-builder object.builder add z1-$NODEIP:6000/sdb1 100

swift-ring-builder account.builder
swift-ring-builder container.builder
swift-ring-builder object.builder

swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance

chown -R swift:swift /etc/swift
swift-init proxy start
