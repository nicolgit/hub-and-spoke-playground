# SOLUTION: connect on-prem and hub with a Site-to-Site IPSec ACTIVE-ACTIVE connection 

## Pre-requisites

In order to apply this solution you have to deploy `hub` and `on-premises` playgrounds.

## Solution

In this configuration, each Azure gateway instance have a unique public IP address, and each establishes an IPsec/IKE S2S VPN tunnel to on-premises VPN device specified in local network gateway and connection. Note that both VPN tunnels are actually part of the same connection. You will need to configure your on-premises VPN device to accept or establish two S2S VPN tunnels to those two Azure VPN gateway public IP addresses.

Because the Azure gateway instances are in active-active configuration, the traffic from your Azure virtual network to your on-premises network will be routed through both tunnels simultaneously, even if your on-premises VPN device may favor one tunnel over the other. For a single TCP or UDP flow, Azure attempts to use the same tunnel when sending packets to your on-premises network. However, your on-premises network could use a different tunnel to send packets to Azure.

When a planned maintenance or unplanned event happens to one gateway instance, the IPsec tunnel from that instance to your on-premises VPN device will be disconnected. The corresponding routes on your VPN devices should be removed or withdrawn automatically so that the traffic will be switched over to the other active IPsec tunnel. On the Azure side, the switch over will happen automatically from the affected instance to the active instance.

![ipsec-active-active](/images/ipsec-aa.png)

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