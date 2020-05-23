# IPv6 Forwarding

This repository contains a script that allows forwarding of IPv6 packets
between networks, e.g, a public network and a private or virtual network. It
uses *tc* and the *mirred* action to forward packets between network
interfaces. You can run the script with `tc-mirred-ipv6.sh` and the following
command line arguments:

```
============
Description:
============
./tc-mirred-ipv6.sh - configure forwarding of ipv6 packets between two devices

======
Usage:
======
    ./tc-mirred-ipv6.sh add <ext_dev> <int_dev>
    ./tc-mirred-ipv6.sh ip <ext_dev> <int_dev> <ip_addr>
    ./tc-mirred-ipv6.sh mac <ext_dev> <int_dev> <mac_addr>
    ./tc-mirred-ipv6.sh del <ext_dev> <int_dev>

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
    mac_addr: mac address without ":", e.g., 525400000001
```
