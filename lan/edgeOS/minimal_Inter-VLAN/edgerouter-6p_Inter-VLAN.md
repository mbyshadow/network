# EdgeOS Inter-VLAN Routing. 
 - [EdgeRouter ER-6P](https://www.ui.com/edgemax/edgerouter-6p/)
 - [Edgeswitch 10XP](https://www.ui.com/edgemax/edgeswitch-10xp/)
 - [Unifi UAP‑LR wifi 6](https://www.ubnt.com/unifi/unifi-ap/)

## Network overview:
```
---
eth0: WAN         - DHCP
eth1: Management 
eth2: Edgeswitch  - 172.19.2.2/30
eth2.2: vlan_2    - 172.19.20.xxx
eth2.3: vlan_3    - 172.19.30.xxx
eth3: LAN         - 172.19.3.xxx
eth4:
eth5:
```

## Edgesrouter config.
### Configure the routeur
#### Global configurations

```bash
configure

set service dns forwarding cache-size 400
set service dns forwarding name-server 8.8.8.8
set service dns forwarding name-server 8.8.4.4

set system host-name er6p
set system domain-name er6p.local
#set system time-zone {$TZ}
set system name-server 127.0.0.1

set system ntp server 0.pool.ntp.org
set system ntp server 1.pool.ntp.org
set system ntp server 2.pool.ntp.org
set system ntp server 3.pool.ntp.org
delete system ntp server 0.ubnt.pool.ntp.org
delete system ntp server 1.ubnt.pool.ntp.org
delete system ntp server 2.ubnt.pool.ntp.org
delete system ntp server 3.ubnt.pool.ntp.org

set system offload ipv4 forwarding enable
set system offload ipv4 gre enable
set system offload ipv4 pppoe enable
set system offload ipv4 vlan enable
set system traffic-analysis dpi disable
set system traffic-analysis export disable

commit; save; exit
```

#### Configure `eth0` for WAN

```bash
configure
delete interfaces ethernet eth0 # remove previous configurations!

set interfaces ethernet eth0 description "WAN"
set interfaces ethernet eth0 address dhcp

set interfaces ethernet eth0 firewall in name WAN_IN
set interfaces ethernet eth0 firewall local name WAN_LOCAL

set interfaces ethernet eth0 mtu 1500
set interfaces ethernet eth0 poe output off
set interfaces ethernet eth0 speed auto
set interfaces ethernet eth0 duplex auto

#set interfaces ethernet eth0 default-route update
#set interfaces ethernet eth0 default-route-distance 210
#set interfaces ethernet eth0 name-server update

commit; save; exit
```

#### Configure `eth2` LAN
```bash
configure
delete interfaces ethernet eth2 

set interfaces ethernet eth2 description "es10xp"
set interfaces ethernet eth2 address 172.19.2.2/30

set interfaces ethernet eth2 duplex auto
set interfaces ethernet eth2 mtu 1500
set interfaces ethernet eth2 poe output off
set interfaces ethernet eth2 speed auto

#set service dns forwarding listen-on eth2

commit; save; exit
```

#### Configure `eth2.20` vLAN
```bash
configure
delete interfaces ethernet eth2.20

set interfaces ethernet eth2 vif 20 description "vlan_2"
set interfaces ethernet eth2 vif 20 address 172.19.20.1/24
set interfaces ethernet eth2 vif 20 firewall local name DHCP_DNS_MDNS_LOCAL

edit service dhcp-server shared-network-name dhcp_vlan_2
set authoritative disable
set subnet 172.19.20.0/24 start 172.19.20.10 stop 172.19.20.100
set subnet 172.19.20.0/24 default-router 172.19.20.1
set subnet 172.19.20.0/24 dns-server 172.19.20.1
set subnet 172.19.20.0/24 lease 86400
top
set service dns forwarding listen-on eth2.20

commit; save; exit
```

#### Configure `eth2.30` vLAN
```bash
configure
delete interfaces ethernet eth2.30

set interfaces ethernet eth2 vif 30 description "vlan_3"
set interfaces ethernet eth2 vif 30 address 172.19.30.1/24

#this one outside adwall
edit service dhcp-server shared-network-name dhcp_vlan_3
set authoritative disable
set subnet 172.19.30.0/24 start 172.19.30.10 stop 172.19.30.100
set subnet 172.19.30.0/24 default-router 172.19.30.1
set subnet 172.19.30.0/24 dns-server 8.8.8.8
set subnet 172.19.30.0/24 dns-server 8.8.4.4
set subnet 172.19.30.0/24 lease 86400
top
set service dns forwarding listen-on eth2.30

commit; save; exit
```

#### Configure `eth3` LAN
```bash
configure
delete interfaces ethernet eth3

edit interfaces ethernet eth3
set description "eth3_lan"
set address 172.19.3.1/24
top

edit service dhcp-server shared-network-name dhcp_3
set authoritative disable
set subnet 172.19.3.0/24 start 172.19.3.10 stop 172.19.3.100
set subnet 172.19.3.0/24 default-router 172.19.3.1
set subnet 172.19.3.0/24 dns-server 172.19.3.1
set subnet 172.19.3.0/24 lease 86400
top
set service dns forwarding listen-on eth3

commit;save
```

#### Firewall

##### Configure the firewall globally
```bash
configure

set firewall all-ping enable
set firewall broadcast-ping disable
set firewall ipv6-receive-redirects disable
set firewall ipv6-src-route disable
set firewall ip-src-route disable
set firewall log-martians enable
set firewall receive-redirects disable
set firewall send-redirects enable
set firewall source-validation disable
set firewall syn-cookies enable

commit;save
```

##### Add Firewall rules for WAN
```bash
configure

edit firewall name WAN_IN
set description 'WAN to internal'
set default-action drop
#set enable-default-log
top

edit firewall name WAN_IN rule 10
set description "Allow established/related"
set action accept
#set protocol all
#set log disable
set state established enable
#set state invalid disable
#set state new disable
set state related enable
top

edit firewall name WAN_IN rule 20
set description "Drop invalid state"
set action drop
#set protocol all
#set log disable
#set state established disable
set state invalid enable
#set state new disable
#set state related disable
top

edit firewall name WAN_LOCAL
set description "WAN to router"
set default-action drop
#set enable-default-log
top

edit firewall name WAN_LOCAL rule 10
set description "Allow established/related"
set action accept
#set protocol all
#set log disable
set state established enable
set state related enable
top

edit firewall name WAN_LOCAL rule 20
set description "Drop invalid state"
set action drop
#set protocol all
#set log disable
set state invalid enable
top

commit; save; exit
``` 

#### Configure NAT
```bash
configure

edit service nat
set rule 5000 description "Masquerade for WAN"
set rule 5000 log disable
set rule 5000 outbound-interface eth0
set rule 5000 protocol all
set rule 5000 type masquerade
top

commit; save; exit
```

