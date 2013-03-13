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
