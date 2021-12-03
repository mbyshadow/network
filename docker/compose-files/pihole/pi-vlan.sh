#!/usr/bin/env bash
ip link add macvlan-shim link eth0 type macvlan mode bridge
ip addr add 172.19.32.60/28 dev macvlan-shim
ip link set macvlan-shim up
ifconfig macvlan-shim
