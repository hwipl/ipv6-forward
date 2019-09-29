#!/bin/bash

NETNS=testns
BRIDGE=testbr0
DEV1=testveth0
DEV2=testveth1

USAGE="Usage:
    $0 start
    $0 stop
    $0 check
Arguments:
    start: start test network
    stop:  stop test network
    check: check test network device"

# initialize test setup
function start_test_net {
	ip netns add $NETNS
	ip link add $BRIDGE type bridge
	ip link set $BRIDGE up
	ip link add $DEV1 type veth peer name $DEV2
	ip link set $DEV1 master $BRIDGE
	ip link set $DEV1 up
	ip link set $DEV2 netns $NETNS
	ip netns exec $NETNS ip link set $DEV2 up
}

# terminate test setup
function stop_test_net {
	ip link del $DEV1
	ip link del $BRIDGE
	ip netns del $NETNS
}

# check test network device
function check_test_dev {
	ip netns exec $NETNS ip addr show dev $DEV2
	ip netns exec $NETNS ping -c 3 ff02::1
}

# run commands based on command line arguments
case "$1" in
	"start")
		start_test_net
		;;
	"stop")
		stop_test_net
		;;
	"check")
		check_test_dev
		;;
	*)
		echo "$USAGE"
		;;
esac
