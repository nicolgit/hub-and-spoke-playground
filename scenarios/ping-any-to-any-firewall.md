# SOLUTION: Allows machines in ANY spoke to communicate with ANY machine in ANY other spoke (Azure Firewall)

In the dynamic realm of cloud computing, efficiently managing and scaling your networks are of paramount importance.
An integral part of this network management is setting up a 'Hub and Spoke' topology and enabling connectivity between spokes.

In the Hub and Spoke model, the **routing between different Spokes is a significant element**. Each spoke identify often an application or a workload, and there enterprise elements have to interact each other.

There are 3 main approaches to allow this traffic:

* Direct spokes peering
* Virtual Network Gateway in the Hub
* Firewall in the Hub

each approach has pros and cons.

### Direct Spokes Peering
Pros: 
* Direct Spokes peering allows more efficient data transfer as it reduces latency caused by passing through the hub.
  
Cons:
* It may create a complex network with multiple connection points, making it harder to monitor and manage.
* Potential security risks can increase as each Spoke is exposed to the other, increasing the risk of vulnerability.

### Network Gateway in the Hub as Default Gateway

Pros:

* It is an appliance already used for S2S VPN so you do not need an additional element to manage.
* The network topology is simple because only one peering for each spoke is required.
* Streamlines operations by providing a uniform route for data traffic, potentially increasing efficiency

Cons: 

* It might introduce additional latency as all traffic must pass through the hub before reaching the destination Spoke.
* Potential for the hub add for the gateway **to become a bottleneck**, because it already is used also for S2S and P2S VPNs.
* Potential security risks can increase as each Spoke is exposed to the other, increasing the risk of vulnerability.

### Firewall in the Hub as Network Appliance

Pros:

* Streamlines operations by providing a uniform route for data traffic, potentially increasing efficiency
* Enhanced security measures as the firewall provides a protective layer preventing unauthorized access.
* It ensures that all traffic can be inspected and sanitized before it reaches its destination.
* Centralized network policy enforcement improves manageability and control.

Cons

* It might introduce additional latency as all traffic must pass through the hub before reaching the destination Spoke.
* Increased costs due to the need for the firewall appliance and traffic logging
* Potential for the firewall to be a single point of failure if not properly configured.


In this solution, I show you how configure the routing between spokes using an **Azure Firewall** in the middle.

Azure Firewall (PaaS) holds a significant edge over a traditional firewall on Azure.
Here are a few reasons why:
* **Fully Integrated**: Azure Firewall is natively integrated with Azure. This means that it works seamlessly with other Azure services and tools, including Azure Monitor, Azure Security Center and Azure Log Analytics.
* **Scalability**: Unlike traditional firewalls which may need manual configuration to scale, Azure Firewall PaaS automatically scales up and down based on network traffic loads. 
* **Advanced Threat Intelligence**: Azure Firewall PaaS is backed by Microsoft's global threat intelligence, helping to identify and block known malicious IPs and domains.
* **Built-in High Availability**: Azure Firewall PaaS offers built-in high availability, eliminating the need for additional load balancers or other devices to ensure constant uptime.
* **Zero Maintenance**: As a fully managed service, Azure Firewall PaaS doesn't require any patching or maintenance.

The resulting overall architecture is shown in the following schema.

![any to any routing via Azure Firewall](/images/any-to-any-routing-firewall.png)

_Download a [draw.io file](../images/any-to-any-routing.drawio) of this architecture._


## Pre-requisites

In order to apply this solution you have to deploy hub playground only.

## Solution

In order to allow this communication, via **Azure Firewall**:

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

Create the following `IP Groups` in `west europe`:
* `group-spoke-01`: 10.13.1.0/24
* `group-spoke-02`: 10.13.2.0/24
* `group-spoke-03`: 10.13.3.0/24

Create the following Firewall Policy: `hub-fw-policy`

**Network Rules**:
* Rule Collection Name: `my-collection`
* Rule Collection type: Network
* Priority: `1000`
* Rule Colletion action: `Allow`
* Rule Collection group: `DefaultNetworkRuleCollectionGroup`


| rule name | source | port | protocol | destination | 
|---|---|---|---|---|
| all-to-all | group-spoke-01<br> group-spoke-02<br> group-spoke-03 | * | Any | group-spoke-01<br> group-spoke-02<br> group-spoke-03 | 

Associate the policy `hub-fw-policy` to `lab-firewall` via Firewall Manager.

## Test Solution
Test connections using remote desktop client and ssh from one machine to another.

# More information
* Azure [Firewall](https://learn.microsoft.com/en-us/azure/firewall/overview)
* Azure [route tables](https://learn.microsoft.com/en-us/azure/virtual-network/manage-route-table)
* Azure [Firewall policy](https://learn.microsoft.com/en-us/azure/firewall-manager/policy-overview)