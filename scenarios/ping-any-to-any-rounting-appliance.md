# SOLUTION: Allows machines in ANY spoke to communicate with ANY machine in ANY other spoke (Azure Virtual Network Routing Appliance)

The **Azure Virtual Network routing appliance** is a high-performance, Azure-managed network routing solution that provides a scalable forwarding layer for virtual networks. Unlike traditional network virtual appliances (NVAs) that run on virtual machines, the routing appliance runs on specialized networking hardware to deliver low latency and high throughput for traffic flows.

Key characteristics of the Azure Virtual Network routing appliance:

- **Azure-native managed service**: Deployed and managed as a top-level Azure resource using familiar Azure tools
- **High performance**: Delivers up to 200 Gbps of bandwidth with millions of concurrent flows
- **Purpose-built for east-west traffic**: Optimized for spoke-to-spoke communication in hub-and-spoke topologies
- **Dedicated subnet deployment**: Resides in a special subnet named `VirtualNetworkApplianceSubnet`
- **Built-in high availability**: Provides zone-resilient operations without additional load balancers

In this solution, I show you how to configure the routing between spokes using a **Virtual Network routing appliance** in the middle.

The resulting overall architecture is shown in the following schema.

![any to any routing via Virtual Network Gateway](/images/any-to-any-routing-appliance.png)

_Download a [draw.io file](../images/any-to-any-routing.drawio) of this architecture._

## Pre-requisites

In order to apply this solution, you have to deploy hub playground only.

## Solution

> Azure Virtual Network Appliance is currently in preview. In order to use it, you have to sign up for the preview using this form <https://forms.office.com/r/kqEKRr5mpB> and wait for approval from the product group. When the approval process is completed, you can continue with the following steps:

Go to Azure Portal > Azure Virtual Network Routing appliances > [create]

- Name: `net-appliance-01`
- region: `westeurope`
- Capacity: `50Gbps`
- Virtual Network: `hub-lab-01`
- subnet: `VirtualNetworkApplianceSubnet`
- Address Space: `10.12.5.0/24`
- press [Review and Create]

Create the following route table in `west europe`: `spokes-we-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual Appliance | 10.12.5.4 |
| to-spoke-02 | 10.13.2.0/24 | Virtual Appliance | 10.12.5.4 |
| to-spoke-03 | 10.13.3.0/24 | Virtual Appliance | 10.12.5.4 |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-01 |
| services | spoke-01 |
| default | spoke-02 |
| services | spoke-02 |

Create the following route table in `north europe`: `spokes-ne-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual Appliance | 10.12.5.4 |
| to-spoke-02 | 10.13.2.0/24 | Virtual Appliance | 10.12.5.4 |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-03 |
| services | spoke-03 |

## Test solution
Via Bastion, access one of the machines in the spokes and via SSH/Remote Desktop client, access one of the other VMs in the other spokes.

## More information

* <https://learn.microsoft.com/en-gb/azure/virtual-network/virtual-network-routing-appliance-overview>
* <https://blog.cloudtrooper.net/2026/03/07/what-is-the-azure-virtual-network-routing-appliance/>
