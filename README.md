# azure-cisco-terraform

This repo will deploy a simulated on-premises datacenter with a Cisco CSR for VPN connectivity.

If you are deploying a Cisco VM image for the first time, you will need to accept the terms and conditions

https://docs.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-accept-terms

```sh
az vm image list -f cisco --all
az vm image terms accept --urn cisco:cisco-csr-1000v:16_10-byol:16.10.220190622
```

Make sure your VPN gateway is provisioned in Azure and update the csr-\*.config file (depending on which VPN gateway you deployed in Azure)

```sh
Instance0=20.190.21.177
Instance1=20.190.21.202
PreSharedKey=p2YRdayEozibObiMG5OvYzBEOXoQArFa
sed -i -e "s/\"Instance0\"/${Instance0}/g" -e "s/\"Instance1\"/${Instance1}/g" -e "s/Msft123Msft123/${PreSharedKey}/g" csr-vwan.config
```

When logging into the Cisco CSR, you need to ssh using the proper algorithm:

```sh
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 <ADMIN_USER>@<PUBLIC_IP>
```

Cisco help - https://github.com/jwrightazure/lab/tree/master/csr-vpn-to-azurevpngw-ikev2-nobgp
https://www.cisco.com/c/en/us/td/docs/routers/csr1000/software/azu/b_csr1000config-azure/b_csr1000config-azure_chapter_011.html

```text
configure terminal

# erase configuration if needed
CSR1#write erase

CSR1#configure terminal
Enter configuration commands, one per line.  End with CNTL/Z.

# paste in the router config (make sure you update the Interface0 and Interface1 IP addresses from Azure)

Ctrl+Z

# validate tunnel0 is up
sh int tu0

# validate tunnel0 is up
sh int tu1

# validate tunnel11 is up
sh int tu11

# validate tunnel status is "READY".
sh crypto ikev2 sa

# validate crypto session "Session status: UP-ACTIVE"
show crypto session

# Check that DC1 is controlling outbound BGP advertisement
sh ip bgp neighbors 192.168.0.12 advertised-routes
sh ip bgp neighbors 192.168.0.13 advertised-routes

# Make sure BGP learned routes are now in the route table. Note there are 2 next hops. This is due to the max path configurations under BGP. Traffic to that destination will load share across both tunnels. You can prepend routes if you want to prefer a specific tunnel.
sh ip route bgp

# Source ping from inside interface of CSR1 to the VMs in VNET 10/20**
ping 10.10.10.4 source gi2
ping 10.20.10.4 source gi2
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
