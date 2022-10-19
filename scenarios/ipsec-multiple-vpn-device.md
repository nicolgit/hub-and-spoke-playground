# SOLUTION: connect on-prem and hub with a Site-to-Site IPSec ACTIVE-ACTIVE connection 

# *** STILL TO BE REVIEWED ***

## Pre-requisites

In order to apply this solution you have to deploy `hub` and `on-premises` playgrounds.

## Solution

This configuration provides multiple active tunnels from the same Azure VPN gateway to your on-premises devices in the same location. There are some requirements and constraints:

* You need to create multiple S2S VPN connections from your VPN devices to Azure. When you connect multiple VPN devices from the same on-premises network to Azure, you need to create one local network gateway for each VPN device, and one connection from your Azure VPN gateway to each local network gateway.
* The local network gateways corresponding to your VPN devices must have unique public IP addresses in the "GatewayIpAddress" property.
* BGP is required for this configuration. Each local network gateway representing a VPN device must have a unique BGP peer IP address specified in the "BgpPeerIpAddress" property.
* You should use BGP to advertise the same prefixes of the same on-premises network prefixes to your Azure VPN gateway, and the traffic will be forwarded through these tunnels simultaneously.
* You must use Equal-cost multi-path routing (ECMP).
* Each connection is counted against the maximum number of tunnels for your Azure VPN gateway, 10 for Basic and Standard SKUs, and 30 for HighPerformance SKU.

In this configuration, the Azure VPN gateway is still in active-standby mode, so the same failover behavior and brief interruption will still happen as described above. But this setup guards against failures or interruptions on your on-premises network and VPN devices.


![ipsec-active-active](/images/ipsec-----)

More information on [Highly Available cross-premises and VNet-to-VNet connectivity](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-highlyavailable#active-active-vpn-gateways).

















### Enable Active-Active mode
Go to Virtual Network Gateway `lab-gateway` in Configuration:
* Active-active mode: Enables
* Second Public IP Address: `hub-gateway-virtualip-2` 
  * SKU: Standard
* Configure BGP: disabled

# create Local Network Gateways
create the following gateways

| Name | IP Address | Address Space | Region |
|---|---|---|---|
|cloud-net | (hub-gateway-virtualip) | 10.0.0.0/8| West Europe |
|cloud-net-2 | (hub-gateway-virtualip-2) | 10.0.0.0/8| West Europe |
|onprem-net| (onprem-gateway-virtualip) | 192.168.0.0/16 | France Central |

# connection onprem-to-cloud (1)
Open `on-prem-gateway`, go to Connections and add the following object
* Connection Name: `onprem-to-cloud`
* Type: Site-to-Site (IPsec)
* virtual Network Gateway:  `on-prem-gateway`
* Local Network Gateway: `cloud-net`
* Shared Key: `password.123`
* IKE: IKEv2


# connection cloud-to-onprem
Open `lab-gateway`, go to Connections and add the following object
* Connection Name: `cloud-to-onprem`
* Type: Site-to-Site (IPsec)
* virtual Network Gateway:  `lab-gateway`
* Local Network Gateway: `onprem-net`
* Shared Key: `password.123`
* IKE: IKEv2

# connection onprem-to-cloud (2)
Open `on-prem-gateway`, go to Connections and add the following object
* Connection Name: `onprem-to-cloud-2`
* Type: Site-to-Site (IPsec)
* virtual Network Gateway:  `on-prem-gateway`
* Local Network Gateway: `cloud-net-2`
* Shared Key: `password.123`
* IKE: IKEv2



after few minutes, you will see, on  `on-prem-gateway` connections:

| Name | Status | Connection Type | Peer |
|---|---|---|---|
|onprem-to-cloud | connected  |Site-to-Site (IPsec)| cloud-net|
|onprem-to-cloud-2 | connected  |Site-to-Site (IPsec)| cloud-net-2|

and on `lab-gateway` connections:

| Name | Status | Connection Type | Peer |
|---|---|---|---|
|cloud-to-onprem | connected  |Site-to-Site (IPsec)| onprem-net |

## Test solution
Via bastion go to W10onprem (`192.168.1.4`) and open a RDP connection to hub-vm-01 (`10.12.1.4`).

Do the same test also from hub-vm-01 to W10onprem.