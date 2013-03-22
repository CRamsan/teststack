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

##Install Nova!
##Install the package
func_install nova-api nova-cert nova-compute nova-compute-qemu nova-doc nova-network nova-objectstore nova-scheduler nova-volume rabbitmq-server novnc nova-consoleauth  

##Check if nova password exists,
##if it does not, ask the user for one.
if [ ! -n "$NOVAPASS" ]
then
        func_set_password "NOVAPASS" "Nova user"
        NOVAPASS=$(func_retrieve_value "NOVAPASS")
fi

##Give Nova access to the database.
mysql -u root -p"$MYSQLPASS" <<EOF
CREATE DATABASE nova;
GRANT ALL ON nova.* TO 'nova'@'%' IDENTIFIED BY "$NOVAPASS";
GRANT ALL ON nova.* TO 'nova'@'localhost' IDENTIFIED BY "$NOVAPASS";
EOF

func_echo "Modify /etc/nova/nova.conf"
read

#echo "s3_host=$SWIFTIP" 				>> /etc/nova/nova.conf
#echo "ec2_host=$NOVAIP" 				>> /etc/nova/nova.conf
#echo "ec2_dmz_host=$NOVAIP" 				>> /etc/nova/nova.conf
#echo "rabbit_host=$KEYSTONEIP" 				>> /etc/nova/nova.conf
#echo "cc_host=$KEYSTONEIP" 				>> /etc/nova/nova.conf
#echo "nova_url=http://$NOVAIP:8774/v1.1/" 		>> /etc/nova/nova.conf
#echo "sql_connection=mysql://nova:"$NOVAPASS"@"$NOVAIP"/nova" >> /etc/nova/nova.conf
#echo "ec2_url=http://"$NOVAIP":8773/services/Cloud" 	>> /etc/nova/nova.conf
#echo "" 						>> /etc/nova/nova.conf
#echo "# Auth" 						>> /etc/nova/nova.conf
#echo "use_deprecated_auth=false"			>> /etc/nova/nova.conf
#echo "auth_strategy=keystone" 				>> /etc/nova/nova.conf
#echo "keystone_ec2_url=http://$KEYSTONEIP:5000/v2.0/ec2tokens" >> /etc/nova/nova.conf
#echo "# Imaging service" 				>> /etc/nova/nova.conf
#echo "glance_api_servers=$GLANCEIP:9292" 		>> /etc/nova/nova.conf
#echo "image_service=nova.image.glance.GlanceImageService" >> /etc/nova/nova.conf
#echo "" 						>> /etc/nova/nova.conf
#echo "# Virt driver" 					>> /etc/nova/nova.conf
#echo "connection_type=libvirt" 				>> /etc/nova/nova.conf
#echo "libvirt_type=qemu" 				>> /etc/nova/nova.conf
#echo "libvirt_use_virtio_for_bridges=true" 		>> /etc/nova/nova.conf
#echo "resume_guests_state_on_host_boot=false" 		>> /etc/nova/nova.conf
#echo "" 						>> /etc/nova/nova.conf
#echo "# Vnc configuration" 				>> /etc/nova/nova.conf
#echo "novnc_enabled=true" 				>> /etc/nova/nova.conf
#echo "novncproxy_base_url=http://$NOVAIP:6080/vnc_auto.html" >> /etc/nova/nova.conf
#echo "novncproxy_port=6080" 				>> /etc/nova/nova.conf
#echo "vncserver_proxyclient_address=$NOVAIP" 		>> /etc/nova/nova.conf
#echo "vncserver_listen=0.0.0.0" 			>> /etc/nova/nova.conf
#echo "" 						>> /etc/nova/nova.conf
#echo "# Network settings" 				>> /etc/nova/nova.conf
#echo "dhcpbridge_flagfile=/etc/nova/nova.conf" 		>> /etc/nova/nova.conf
#echo "dhcpbridge=/usr/bin/nova-dhcpbridge" 		>> /etc/nova/nova.conf
#echo "network_manager=nova.network.manager.VlanManager" >> /etc/nova/nova.conf
#echo "public_interface=eth0" 				>> /etc/nova/nova.conf
#echo "vlan_interface=eth0" 				>> /etc/nova/nova.conf
#echo "fixed_range=192.168.4.32/27" 			>> /etc/nova/nova.conf
#echo "routing_source_ip=$NOVAIP" 			>> /etc/nova/nova.conf
#echo "network_size=32" 					>> /etc/nova/nova.conf
#echo "force_dhcp_release=True" 				>> /etc/nova/nova.conf
#echo "rootwrap_config=/etc/nova/rootwrap.conf" 		>> /etc/nova/nova.conf
#echo "" 						>> /etc/nova/nova.conf
#echo "# Cinder \#" 					>> /etc/nova/nova.conf dsfdsfsdf
#echo "volume_api_class=nova.volume.cinder.API" 		>> /etc/nova/nova.conf
#echo "osapi_volume_listen_port=5900" 			>> /etc/nova/nova.conf
#echo "enabled_apis=ec2,osapi_compute,metadata" 		>> /etc/nova/nova.conf

sudo chown -R nova. /etc/nova
sudo chmod 644 /etc/nova/nova.conf

func_echo "MOdify /etc/nova/api-paste.ini"
read

#func_replace "/etc/nova/api-paste.ini" "auth_host = 127.0.0.1"				"auth_host = $KEYSTONEIP"
#func_replace "/etc/nova/api-paste.ini" "admin_tenant_name = %SERVICE_TENANT_NAME%"	"admin_tenant_name = service"
#func_replace "/etc/nova/api-paste.ini" "admin_user = %SERVICE_USER%"			"admin_user = nova"
#func_replace "/etc/nova/api-paste.ini" "admin_password = %SERVICE_PASSWORD%"		"admin_password = nova"

sudo nova-manage db sync

func_echo "Mare sure your interfaces are configured correclty"
read
nova-manage network create private --fixed_range_v4=192.168.4.32/27 --vlan=100 --num_networks=1 --bridge=br100 --bridge_interface=eth0 --network_size=32

cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done 
service open-iscsi restart
service nova-novncproxy restart

sudo nova-manage service list
