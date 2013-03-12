#!/bin/bash

func_replace "/etc/sysctl.conf" "#net.ipv4.conf.default.rp_filter=1" "net.ipv4.conf.default.rp_filter=1"
func_replace "/etc/sysctl.conf" "#net.ipv4.conf.all.rp_filter=1" "net.ipv4.conf.all.rp_filter=1"

service networking restart
