#!/bin/bash

TC=/usr/bin/tc

# command line arguments
CMD=$1

# external and internal interface
DEV_EXT=$2
DEV_INT=$3

# IP or MAC address
ADDR=$4

USAGE="============
Description:
============
$0 - configure forwarding of ipv6 packets between two devices

======
Usage:
======
    $0 add <ext_dev> <int_dev>
    $0 ip <ext_dev> <int_dev> <ip_addr>
    $0 mac <ext_dev> <int_dev> <mac_addr>
    $0 del <ext_dev> <int_dev>

==========
Arguments:
==========
    add:      initialize forwarding between ext_dev and int_dev
    ip:       add unicast forwarding for an ip address
    mac:      add unicast forwarding for a mac address
    del:      remove all forwarding settings from ext_dev and int_dev

    ext_dev:  external network device
    int_dev:  internal network device
    ip_addr:  ip address with prefix length, e.g., fe80::1/128 or fe80::/64
    mac_addr: mac address without \":\", e.g., 525400000001"

# icmp multicast forwarding
function add_icmp_mcast {
	# add tc settings
	echo "Adding icmp multicast forwarding for $DEV_EXT and $DEV_INT."
	
	# create ingress qdisc on internal and external device
	$TC qdisc add dev "$DEV_EXT" ingress
	$TC qdisc add dev "$DEV_INT" ingress

	# forward icmpv6 multicast external device -> internal device
	$TC filter add dev "$DEV_EXT" parent ffff: prio 100 protocol ipv6 u32 \
		match ip6 protocol 58 0xff \
		match ip6 dst ff02::/16 \
		action mirred egress mirror dev "$DEV_INT"

	# forward icmpv6 multicast internal device -> external device
	$TC filter add dev "$DEV_INT" parent ffff: prio 100 protocol ipv6 u32 \
		match ip6 protocol 58 0xff \
		match ip6 dst ff02::/16 \
		action mirred egress mirror dev "$DEV_EXT"

	exit
}

# ip based unicast forwarding
function add_ip {
	# make sure addr contains something
	if [ -z "$ADDR" ]; then
		echo "$USAGE"
		exit
	fi

	# add ip forwarding
	echo "Adding unicast forwarding for $ADDR to $DEV_EXT and $DEV_INT."

	# forward ipv6 unicast to IP from external to internal device
	$TC filter add dev "$DEV_EXT" parent ffff: prio 101 protocol ipv6 u32 \
		match ip6 dst "$ADDR" \
		action mirred egress mirror dev "$DEV_INT"

	# forward ipv6 unicast from IP from internal to external device
	$TC filter add dev "$DEV_INT" parent ffff: prio 101 protocol ipv6 u32 \
		match ip6 src "$ADDR" \
		action mirred egress mirror dev "$DEV_EXT"
	
	exit
}

# mac based unicast forwarding
function add_mac {
	# make sure addr contains something
	if [ -z "$ADDR" ]; then
		echo "$USAGE"
		exit
	fi
	
	# add mac forwarding
	echo "Adding unicast forwarding for $ADDR to $DEV_EXT and $DEV_INT."

	# forward source MAC from internal device to external device
	$TC filter add dev "$DEV_INT" parent ffff: prio 101 protocol ipv6 u32 \
		match u16 0x86DD 0xFFFF at -2 \
		match u16 0x"${ADDR:8:4}" 0xFFFF at -4 \
		match u32 0x"${ADDR:0:8}" 0xFFFFFFFF at -8 \
		action mirred egress mirror dev "$DEV_EXT"

	# forward destination MAC from external device to internal device
	$TC filter add dev "$DEV_EXT" parent ffff: prio 101 protocol ipv6 u32 \
		match u16 0x86DD 0xFFFF at -2 \
		match u32 0x"${ADDR:4:8}" 0xFFFFFFFF at -12 \
		match u16 0x"${ADDR:0:4}" 0xFFFF at -14 \
		action mirred egress mirror dev "$DEV_INT"

	exit
}

# delete all tc settings
function del_all {
	# remove tc settings again
	echo "Deleting all tc settings on $DEV_EXT and $DEV_INT."

	# delete filters
	$TC filter delete dev "$DEV_EXT" parent ffff:
	$TC filter delete dev "$DEV_INT" parent ffff:
	
	# delete qdiscs
	$TC qdisc delete dev "$DEV_EXT" ingress
	$TC qdisc delete dev "$DEV_INT" ingress

       	exit
}

# handle common command line parameters
if [ -z "$DEV_EXT" ] || [ -z "$DEV_INT" ]; then
	echo "$USAGE"
	exit
fi

# run commands based on command line arguments
case "$CMD" in
	"add")
		add_icmp_mcast
		;;
	"ip")
		add_ip
		;;
	"mac")
		add_mac
		;;
	"del")
		del_all
		;;
	*)
		echo "$USAGE"
		;;
esac
