# SOLUTION: connect on-prem and hub with a Site-to-Site IPSec connection

In this solution I show how to configure an IPSec tunnel between an on-premises (simulated on Azure) site and a hub and spoke, using static routing without BGP protocol.

Using static routing instead of BGP in this IPSec connection provides several advantages in certain scenarios like:

- **Simplicity**: Static routing is easier to understand and configure, making it ideal for simple network topologies
- **Predictability**: Routes are explicitly defined and don't change automatically, providing complete control over traffic flow
- **Lower Resource Usage**: No BGP protocol overhead, resulting in slightly lower CPU and memory usage on network devices
- **Better for Small Networks**: Ideal for environments with few subnets and stable network topology

## Pre-requisites

In order to apply this solution you have to deploy `hub` and `on-premises` playgrounds.

## Solution

In order to make this connection, you have to create 2 connections: one from on-prem to cloud and another from cloud to on-prem.

![ipsec schema](/images/ipsec.png)

# Create Local Network Gateways
Create the following gateways:

| Name | IP Address | Address Space | Region |
|---|---|---|---|
|`cloud-net` | `lab-gateway-ip` (hub gateway public ip) | 10.0.0.0/8| West Europe |
|`onprem-net`| `onprem-gateway-virtualip` (onprem gateway public ip) | 192.168.0.0/16 | France Central |

# Connection onprem-to-cloud
Open `on-prem-gateway`, go to Connections and add the following object:
* Connection Name: `onprem-to-cloud`
* Type: Site-to-Site (IPsec)
* Virtual Network Gateway:  `on-prem-gateway`
* Local Network Gateway: `cloud-net`
* Shared Key: `password.123`
* IKE: IKEv2


# Connection cloud-to-onprem
Open `lab-gateway`, go to Connections and add the following object:
* Connection Name: `cloud-to-onprem`
* Type: Site-to-Site (IPsec)
* Virtual Network Gateway:  `lab-gateway`
* Local Network Gateway: `onprem-net`
* Shared Key: `password.123`
* IKE: IKEv2

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

Do the same test also in the opposite direction.