# azure-cisco-terraform

This repo will deploy a simulated on-premises datacenter with a Cisco CSR for VPN connectivity.

If you are deploying a Cisco VM image for the first time, you will need to accept the terms and conditions

https://docs.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-accept-terms

```sh
az vm image list -f cisco --all
az vm image terms accept --urn cisco:cisco-csr-1000v:16_10-byol:16.10.220190622
```

> If you don't do the above, you may run into an error message that like this:
> You have not accepted the legal terms on this subscription: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' for this plan. Before the subscription can be used, you need to accept the legal terms of the image. To read and accept legal terms, use the Azure CLI commands described at https://go.microsoft.com/fwlink/?linkid=2110637 or the PowerShell commands available at https://go.microsoft.com/fwlink/?linkid=862451. Alternatively, deploying via the Azure portal provides a UI experience for reading and accepting the legal terms. Offer details: publisher='cisco' offer = 'cisco-csr-1000v', sku = '16_10-byol'

Once the terraform has successfully provisioned the resources, you can run the following command to output the Cisco configuration file. Copy the contents to your clipboard.

```sh
terraform output -raw csr_config
```

When logging into the Cisco CSR, you need to ssh using the proper algorithm:

```sh
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 <ADMIN_USER>@<PUBLIC_IP>
```

Cisco help - https://github.com/jwrightazure/lab/tree/master/csr-vpn-to-azurevpngw-ikev2-nobgp
https://www.cisco.com/c/en/us/td/docs/routers/csr1000/software/azu/b_csr1000config-azure/b_csr1000config-azure_chapter_011.html

```text
# erase configuration if needed
CSR1#write erase

CSR1#configure terminal

CSR1#configure terminal
Enter configuration commands, one per line.  End with CNTL/Z.
```

Paste in the router config (make sure you update the Interface0 and Interface1 IP addresses from Azure) then hit Ctrl+Z

> To find your instance 0 and instance 1 IPs for VPN Gateway on Virtual WAN, go to your virtual hub, click on the VPN (Site to site) link in the left navigation, then click on View/Configure for Gateway configuration.

Validate tunnel0 is up - look for "Tunnel0 is up, line protocol is up"

```text
sh int tu0
Tunnel0 is up, line protocol is up
  Hardware is Tunnel
  Internet address is 172.16.0.5/32
  MTU 9922 bytes, BW 100 Kbit/sec, DLY 50000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation TUNNEL, loopback not set
  Keepalive not set
  Tunnel linestate evaluation up
  Tunnel source 10.55.0.4 (GigabitEthernet1), destination 20.118.155.190
   Tunnel Subblocks:
      src-track:
         Tunnel0 source tracking subblock associated with GigabitEthernet1
          Set of tunnels with source GigabitEthernet1, 2 members (includes iterators), on interface <OK>
  Tunnel protocol/transport IPSEC/IP
  Tunnel TTL 255
  Tunnel transport MTU 1422 bytes
  Tunnel transmit bandwidth 8000 (kbps)
  Tunnel receive bandwidth 8000 (kbps)
  Tunnel protection via IPSec (profile "az-VTI1")
  Last input 00:00:15, output 00:00:15, output hang never
  Last clearing of "show interface" counters 00:00:19
  Input queue: 0/375/0/0 (size/max/drops/flushes); Total output drops: 0
  Queueing strategy: fifo
  Output queue: 0/0 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     6 packets input, 385 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     5 packets output, 280 bytes, 0 underruns
     0 output errors, 0 collisions, 0 interface resets
     0 unknown protocol drops
     0 output buffer failures, 0 output buffers swapped out
```

Validate tunnel1 is up - look for "Tunnel1 is up, line protocol is up"

```text
sh int tu1
Tunnel1 is up, line protocol is up
  Hardware is Tunnel
  Internet address is 172.16.0.6/32
  MTU 9922 bytes, BW 100 Kbit/sec, DLY 50000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation TUNNEL, loopback not set
  Keepalive not set
  Tunnel linestate evaluation up
  Tunnel source 10.55.0.4 (GigabitEthernet1), destination 20.118.155.178
   Tunnel Subblocks:
      src-track:
         Tunnel1 source tracking subblock associated with GigabitEthernet1
          Set of tunnels with source GigabitEthernet1, 2 members (includes iterators), on interface <OK>
  Tunnel protocol/transport IPSEC/IP
  Tunnel TTL 255
  Tunnel transport MTU 1422 bytes
  Tunnel transmit bandwidth 8000 (kbps)
  Tunnel receive bandwidth 8000 (kbps)
  Tunnel protection via IPSec (profile "az-VTI2")
  Last input 00:00:22, output 00:00:22, output hang never
  Last clearing of "show interface" counters 00:00:26
  Input queue: 0/375/0/0 (size/max/drops/flushes); Total output drops: 0
  Queueing strategy: fifo
  Output queue: 0/0 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     6 packets input, 385 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     5 packets output, 280 bytes, 0 underruns
     0 output errors, 0 collisions, 0 interface resets
     0 unknown protocol drops
     0 output buffer failures, 0 output buffers swapped out
```

Validate tunnel status is "READY".

```text
sh crypto ikev2 sa
 IPv4 Crypto IKEv2  SA

Tunnel-id Local                 Remote                fvrf/ivrf            Status
2         10.55.0.4/4500        20.118.155.178/4500   none/none            READY
      Encr: AES-CBC, keysize: 256, PRF: SHA1, Hash: SHA96, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/39 sec

Tunnel-id Local                 Remote                fvrf/ivrf            Status
1         10.55.0.4/4500        20.118.155.190/4500   none/none            READY
      Encr: AES-CBC, keysize: 256, PRF: SHA1, Hash: SHA96, DH Grp:2, Auth sign: PSK, Auth verify: PSK
      Life/Active Time: 86400/40 sec

 IPv6 Crypto IKEv2  SA
```

Validate crypto session - look for "Session status: UP-ACTIVE"

```text
show crypto session
Crypto session current status

Interface: Tunnel1
Profile: az-PROFILE2
Session status: UP-ACTIVE
Peer: 20.118.155.178 port 4500
  Session ID: 2
  IKEv2 SA: local 10.55.0.4/4500 remote 20.118.155.178/4500 Active
  IPSEC FLOW: permit ip 0.0.0.0/0.0.0.0 0.0.0.0/0.0.0.0
        Active SAs: 2, origin: crypto map

Interface: Tunnel0
Profile: az-PROFILE1
Session status: UP-ACTIVE
Peer: 20.118.155.190 port 4500
  Session ID: 1
  IKEv2 SA: local 10.55.0.4/4500 remote 20.118.155.190/4500 Active
  IPSEC FLOW: permit ip 0.0.0.0/0.0.0.0 0.0.0.0/0.0.0.0
        Active SAs: 2, origin: crypto map
```

Check that DC1 is controlling outbound BGP advertisement

```text
sh ip bgp neighbors 10.44.0.12 advertised-routes
BGP table version is 5, local router ID is 172.16.0.4
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.55.0.0/26     0.0.0.0                  0         32768 i
 *>   10.55.0.64/26    0.0.0.0                  0         32768 i

Total number of prefixes 2

sh ip bgp neighbors 10.44.0.13 advertised-routes
BGP table version is 5, local router ID is 172.16.0.4
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, m multipath, b backup-path, f RT-Filter,
              x best-external, a additional-path, c RIB-compressed,
              t secondary path, L long-lived-stale,
Origin codes: i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

     Network          Next Hop            Metric LocPrf Weight Path
 *>   10.55.0.0/26     0.0.0.0                  0         32768 i
 *>   10.55.0.64/26    0.0.0.0                  0         32768 i

Total number of prefixes 2
```

Make sure BGP learned routes are now in the route table. Note there are 2 next hops. This is due to the max path configurations under BGP. Traffic to that destination will load share across both tunnels. You can prepend routes if you want to prefer a specific tunnel.

```text
sh ip route bgp
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2, m - OMP
       n - NAT, Ni - NAT inside, No - NAT outside, Nd - NAT DIA
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       H - NHRP, G - NHRP registered, g - NHRP registration summary
       o - ODR, P - periodic downloaded static route, l - LISP
       a - application route
       + - replicated route, % - next hop override, p - overrides from PfR

Gateway of last resort is 10.55.0.1 to network 0.0.0.0

      10.0.0.0/8 is variably subnetted, 9 subnets, 4 masks
B        10.44.0.0/24 [20/0] via 10.44.0.13, 00:05:01
                      [20/0] via 10.44.0.12, 00:05:01
B        10.44.1.0/24 [20/0] via 10.44.0.13, 00:05:01
                      [20/0] via 10.44.0.12, 00:05:01
```

More key Cisco commands:

```text
show interface tunnel 11
show crypto session
show ip route (make sure Azure prefix is pointing to tu11)
show crypto ipsec transform-set
show crypto ikev2 proposal
```

Enable the webui

```text
!
ip dhcp pool WEBUIPool
network 192.168.1.0 255.255.255.0
default-router 192.168.1.1
username webui privilege 15 password cisco
```
