# EdgeOS Inter-VLAN Routing.
 - [EdgeRouter ER-6P](https://www.ui.com/edgemax/edgerouter-6p/)
 - [Edgeswitch 10XP](https://www.ui.com/edgemax/edgeswitch-10xp/)
 - [Unifi UAP‑LR wifi 6](https://www.ubnt.com/unifi/unifi-ap/)
### Network overview:
```bash
--- Edgerouter 6P ---
eth0: WAN         - DHCP
eth1: Management 
eth2: Edgeswitch  - 172.19.2.2/30
eth2.2: vlan_2    - 172.19.20.xxx
eth2.3: vlan_3    - 172.19.30.xxx
eth3: LAN         - 172.19.3.xxx
eth4:
eth5:

--- Edgeswitch 10 XP ---
sw0/1: Management 
sw0/2: Edgerouter 172.19.2.1
sw0/3: Unifi ap
sw0/4: Lan dumb sw3 
  vlan 20 : 172.19.20.xxx
  vlan 30 : 172.19.30.xxx
```

_The UAP will tag the wireless network with vLAN30. All untagged traffic from switch is sent untagged on vLAN20._

## Edgeswitch config.

#### Enter privileged mode and create the VLANs and VLAN-Interfaces (SVIs)
```
enable
vlan database   
 vlan 20,30  
 vlan routing 20  
 vlan routing 30  
 exit
```

#### Enter configuration mode and assign ports to the VLANs.
```
configure

interface 0/4
 description sw3
 vlan pvid 20  
 vlan participation exclude 1,30  
 vlan participation include 20  
 exit

interface 0/3  
 description uap  
 vlan tagging 30  
 vlan pvid 20  
 vlan participation exclude 1  
 vlan participation include 20,30  
 exit
```

#### Enable routing functionality on the uplink port (0/2) and assign it an IP address.
```
interface 0/2 
 description er6p  
 routing  
 ip address 172.19.2.2 255.255.255.252  
 exit
```

#### Associate the VLAN20 and VLA30 SVIs with IP addresses and enable routing.
```
interface vlan 20  
 ip address 172.19.20.2 255.255.255.0  
 routing   
 exit

interface vlan 30  
 ip address 172.19.30.3 255.255.255.0  
 routing  
 exit
```

#### Globally enable the routing functionality and create a default route to the EdgeRouter.
```
ip routing  
ip route 0.0.0.0 0.0.0.0 172.19.2.1 
```

#### Exit back to privileged mode and write the changes to the startup configuration.
```
exit  
write memory
```