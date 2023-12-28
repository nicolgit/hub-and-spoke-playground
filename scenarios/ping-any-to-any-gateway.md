# SOLUTION: Allows machines in ANY spoke to communicate with ANY machine in ANY other spoke (Virtual Network Gateway)

The Azure Virtual Network Gateway is a specific type of virtual network gateway that is used to send encrypted traffic between an Azure virtual network and an on-premises location over the public Internet. It can also send traffic between Azure virtual networks. Over a virtual network gateway, you can send traffic from one virtual network to another in a very secure manner.

The main capabilities of Azure Virtual Network Gateway include:
* VPN Connectivity: It provides VPN connectivity, enabling secure communication channels between different locations.
* Cross-Premises Connectivity: It allows you to connect your on-premises network to Azure's network, essentially extending your on-premises network to the cloud.
* Inter-VNET Connectivity: It can be used to connect different Azure Virtual Networks, enabling resources in different Virtual Networks to communicate with each other.
* Point-to-Site VPN: It enables individual clients to connect to the Azure network from anywhere, making it ideal for remote workers or individual devices.
* Advanced Routing: It has advanced routing capabilities, including Border Gateway Protocol (BGP) support and dynamic routing.

In the context of a hub and spoke architecture in Azure, the Virtual Network Gateway can be used to enable routing between different spokes. Normally, peering relationships in Azure are non-transitive, meaning that if spoke 1 is connected to the hub, and spoke 2 is also connected to the hub, spoke 1 and spoke 2 cannot communicate with each other by default.

However, by leveraging a Virtual Network Gateway in the hub network, you can configure it to allow traffic to flow between spokes. This is done by enabling 'Use Remote Gateways' and 'Allow Gateway Transit' settings in the peering settings. The Virtual Network Gateway essentially acts as a router, directing traffic between different virtual networks. This can be particularly useful in scenarios where you have resources in different spokes that need to communicate with each other.

In this solution, I show you how configure the routing between spokes using a **Virtual Network Gateway** in the middle.

The resulting overall architecture is shown in the following schema.

![any to any routing via Virtual Network Gateway](/images/any-to-any-routing-gateway.png)

_Download a [draw.io file](../images/any-to-any-routing.drawio) of this architecture._

## Pre-requisites

In order to apply this solution you have to deploy hub playground only.

## Solution

In order to allow this communication, via **Azure Virtual Gateway**:

Verify that gateway transit is Enabled, on `hub-lab-net` > peerings

| Name | Peering Status | Peer | Gateway Transit |
|---|---|---|---|
| hub-to-spoke01 | Connected | spoke-01 | Enabled |
| hub-to-spoke02 | Connected | spoke-02 | Enabled |
| hub-to-spoke03 | Connected | spoke-03 | Enabled |

Create the following route table in `west europe`: `spokes-we-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual Appliance | 10.12.3.4 |
| to-spoke-02 | 10.13.2.0/24 | Virtual Appliance | 10.12.3.4 |
| to-spoke-03 | 10.13.3.0/24 | Virtual Appliance | 10.12.3.4 |


| subnet Name | Virtual Network |
|---|---|
| default | spoke-01 |
| services | spoke-01 |
| default | spoke-02 |
| services | spoke-02 |

Create the following route table in `north europe`: `spokes-ne-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual Appliance | 10.12.3.4 |
| to-spoke-02 | 10.13.2.0/24 | Virtual Appliance | 10.12.3.4 |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-03 |
| services | spoke-03 |

## Test Solution
Test connections using remote desktop client and ssh from one machine to another.
