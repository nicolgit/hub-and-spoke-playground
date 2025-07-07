# SOLUTION: connect on-prem and hub with a Site-to-Site IPSec connection with BGP

In this solution I show how to configure an IPSec tunnel between an on-premises (simulated on Azure) site and a hub and spoke, using BGP protocol.

Using BGP (Border Gateway Protocol) in this IPSec connection provides several advantages like:

- **Dynamic Routing**: BGP automatically exchanges routing information between on-premises and Azure, eliminating the need to manually configure static routes
- **Simplified Management**: Reduces administrative overhead by automating route management and updates

## Pre-requisites

In order to apply this solution you have to deploy `hub` and `on-premises` playgrounds.

## Solution

In order to make this connection, you have to create 2 connections: one from on-prem to cloud and another from cloud to on-prem.

![ipsec schema](/images/ipsec-bgp.png)

# Enable BGP on virtual network gateways
Go to Azure Portal > Virtual network gateways > VPN Gateways > `lab-gateway` > Configuration > Configure BGP
* ASN: `65050`
* click SAVE
  
Go to Azure Portal > Virtual network gateways > VPN Gateways > `onprem-gateway` > Configuration > Configure BGP
* ASN: `65051`
* click SAVE


# Create Local Network Gateways
Go to Azure Portal > Local Network Gateways and create the following gateways:

| Name | pub ip | ip range | configure BGP | ASN | BGP peer IP | region |
|---|---|---|---|---|---|---|
|`cloud-net` | `lab-gateway-ip` (hub gateway public ip) | // | yes | 65050 | 10.12.4.254 | West Europe |
|`onprem-net`| `onprem-gateway-virtualip` (onprem gateway public ip) | // | yes | 65051 | 192.168.3.254 | France Central |

# Connection onprem-to-cloud
Go to Azure Portal > Virtual Network Gateways > VPN Gateways > `on-prem-gateway` > Connections > Add:

* Connection Name: `onprem-to-cloud`
* Type: Site-to-Site (IPsec)
* Virtual Network Gateway:  `on-prem-gateway`
* Local Network Gateway: `cloud-net`
* Shared Key: `password.123`
* IKE: IKEv2
* Enable BGP: `true`


# Connection cloud-to-onprem
Go to Azure Portal > Virtual Network Gateways > VPN Gateways > `lab-gateway` > Connections > Add:

* Connection Name: `cloud-to-onprem`
* Type: Site-to-Site (IPsec)
* Virtual Network Gateway:  `lab-gateway`
* Local Network Gateway: `onprem-net`
* Shared Key: `password.123`
* IKE: IKEv2
* Enable BGP: `true`

After **few minutes**, you will see, on  `on-prem-gateway` connections:

| Name | Status | Connection Type | Peer |
|---|---|---|---|
|onprem-to-cloud | connected  |Site-to-Site (IPsec)| cloud-net|

and on `lab-gateway` connections:

| Name | Status | Connection Type | Peer |
|---|---|---|---|
|cloud-to-onprem | connected  |Site-to-Site (IPsec)| onprem-net |

## Test solution
Via Bastion go to `W11-onprem` (`192.168.1.4`) and open an RDP connection to hub-vm-01 (`10.12.1.4`).

