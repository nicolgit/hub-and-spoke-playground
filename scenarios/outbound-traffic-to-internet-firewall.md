# Using Azure Firewall as a Gateway for All Outbound Traffic to the Internet

Managing and securing outbound traffic is crucial for maintaining the integrity and performance of your network. Azure Firewall can be effectively used as a gateway for all outbound traffic to the internet. 

[Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/overview) is a managed, cloud-based network security service that protects your Azure Virtual Network resources. It is a stateful firewall as a service with built-in high availability and unrestricted cloud scalability. Azure Firewall provides both network and application-level protection across different subscriptions and virtual networks.

Benefits of Using Azure Firewall for Outbound Traffic

* Centralized Security Management: Azure Firewall allows you to manage and enforce [security policies](https://learn.microsoft.com/en-us/azure/firewall/policy-rule-sets) centrally, ensuring consistent security across your network.
* Scalability: Azure Firewall [scales automatically](https://learn.microsoft.com/en-us/azure/firewall/firewall-performance) to meet your changing network traffic needs, providing high availability and resilience.
* Advanced Threat Protection: With features like threat [intelligence-based filtering](https://learn.microsoft.com/en-us/azure/firewall/threat-intel), Azure Firewall can detect and block traffic from known malicious IP addresses and domains.
* Integration with Other Azure Services: Azure Firewall integrates seamlessly with other Azure services like [Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/fundamentals/overview), [Azure Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/overview), and Azure Security Center, providing comprehensive security insights and management.

In this walkthrough, I will show you how to set up Azure Firewall for this purpose.

The target architecture will be the following:

![Azure Firewall as a Gateway for ll outbound Traffic to the Internet](../images/outbound-traffic-internet-firewall.png)

_Download a [draw.io file](../images/outbound-traffic-internet-firewall.drawio) of this schema._

## Pre-requisites

In order to apply this solution, deploy the **hub** playground first.

## Solution

### Create routing table in westeurope and associate it to spokes

Go to Azure portal > route tables > click on Create
* Region: `westeurope`
* Name: `spokes-we-to-hub-routes`
* Click CREATE

Go to Azure Portal > route tables > `spokes-we-to-hub-routes` > routes > ADD
* Name: `to-firewall`
* Destination type: IP Address
* IP Address: `0.0.0.0/0`
* Next hop type: virtual appliance
* next hop address: `10.12.3.4`
* click CREATE

Go to Azure Portal > route tables > `spokes-we-to-hub-routes` > subnets > associate
|subnet name | virtual network |
|------------|-----------------|
| default    | spoke-01 |
| default    | spoke-02 |
| services   | spoke-01 |
| services   | spoke-02 |

### Create routing table in northeurope and associate it to spoke

Go to Azure portal > route tables > click on Create
* Region: `northeurope`
* Name: `spokes-ne-to-hub-routes`
* Click CREATE

Go to Azure Portal > route tables > `spokes-ne-to-hub-routes` > routes > ADD
* Name: `to-firewall`
* Destination type: IP Address
* IP Address: `0.0.0.0/0`
* Next hop type: virtual appliance
* next hop address: `10.12.3.4`
* click CREATE

Go to Azure Portal > route tables > `spokes-ne-to-hub-routes` > subnets > associate
|subnet name | virtual network |
|------------|-----------------|
| default    | spoke-03 |
| services   | spoke-03 |

### Configure azure firewall policy

Go to Azure Portal > Firewall Policies > Create
* Name: `my-firewall-policy`
* policy tier: premium
* parent policy: none
* Rules > Add a Rule Collection
  * Name: `rfc1918-collection`
  * rule collection type: Network
  * priority: `1000`
  * rule collection action: deny
  * rule name: `block-intranet-traffic`
  * source type: ip address
  * source: `10.13.1.0/24,10.13.2.0/24,10.13.3.0/24`
  * protocol: TCP + UDP
  * destination ports: `*`
  * destination type: ip address
  * destination: `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16`
  * add
* Rules > Add a Rule Collection
  * Name: `internet-collection`
  * rule collection type: Network
  * priority: `10000`
  * rule collection action: allow
  * rule name: `to-internet-rule`
  * source type: ip address
  * source: `10.13.1.0/24,10.13.2.0/24,10.13.3.0/24`
  * protocol: TCP + UDP
  * destination ports: `*`
  * destination type: ip address
  * destination: `*`
  * add
* create

Go to Azure Portal > Firewall manager > Azure Firewall policies
* select `my-firewall-policy`
* manage association > associate vnets
  * select `hub-lab-net`
  * cick add

## Test solution

Go to Azure portal > virtual machines > `spoke-01-vm` > connect via bastion

Install and run Noisy as described in <https://nicolgit.github.io/install-and-run-noisy-on-azure-vm/> to generate traffic.

Wait a couple of minutes then go to Azure Portal > firewall > `lab-firewall` > logs > query hub > network rule log data > run

you will see the outbound traffic data to internet from `10.13.1.4` (`spoke-01-vm`)

