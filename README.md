# Create an AZURE hub-and-spoke playground to test configurations and customer scenarios

Read also this [blog post](https://nicolgit.github.io/azure-hub-and-spoke-playground/) for more info on this project.

This repo contains an ARM template to that can be used to deploy a playground composed by:
  * an hub and spoke network topology aligned with with <a href="https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/architecture" target="_blank">Microsoft Enterprise scale landing zone</a> reference architecture
  * a simulated on-premise architecture composed by network, client machine(s) and a gateway to be used to test connectivity with the cloud

## Deploy to Azure
You can use the following button to deploy the demo to your Azure subscription:

| playground parts| &nbsp; |
|---|---|
| deploys HUB playground | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnicolgit%2Fhub-and-spoke-playground%2Fmain%2Fcloud-deploy.json)
| deploys ON PREMISE playground | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnicolgit%2Fhub-and-spoke-playground%2Fmain%2Fon-prem-deploy.json) |
| deploys ON PREMISE-2 playground | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnicolgit%2Fhub-and-spoke-playground%2Fmain%2Fon-prem-deploy-2.json) |

## Architecture
This diagrams shows the overall architecture:

![Architecture](images/architecture.png)


the ARM template [cloud-deploy](cloud-deploy.json) deploys:
* 4 Azure Virtual Networks:
    * `hub-lab-net` with 4 subnets:
        * default subnet: this subnet is used to connect the hub-vm-01 machine
        * AzureFirewallSubet: this subnet is used by Azure Firewall
        * AzureBastionSubnet: this subnet is used bu Azure Bastion
        * GatewaySubnet: this subnet is used by Azure Gateway
    * `spoke-01` with 1 subnet used to connect spoke-01-vm machine
    * `spoke-02` with 1 subnet used to connect spoke-02-vm machine
    * `spoke-03`, located in North Europe, used to connect spoke-03-vm machine
* An Azure Bastion resource that provides secure and seamless SSH connectivity to the jumpbox virtual machine directly in the Azure portal over SSL
* An Azure Firewall resource that provide a cloud-native, fully stateful, firewall as a service with built-in high availability and unrestricted cloud scalability. It provides both east-west and north-south traffic inspection.
* An Azure VPN Gateway resource that is used to send encrypted traffic between the hub virtual network to the on-premises simulated location.
* `hub-vm-01`: a Windows Server virtual machine that simulates a server located in the hub location
* `spoke-01-vm`: a Windows Server virtual machine that simulates a server located in the spoke-01 landing zone
* `spoke-02-vm`: a Windows Server virtual machine that simulates a server located in the spoke-02 landing zone
* `spoke-03-vm`: a Linux virtual machine that simulates a server located in the spoke-01 landing zone

The ARM template [on-prem-deploy](on-prem-deploy.json) deploys:
* `on-prem-net`: an Azure Virtual Network located in France with 3 subnets
    * default subnet: this subnet is used to connect the w10-onprem-vm machine
    * AzureBastionSubnet: this subnet is used bu Azure Bastion
    * GatewaySubnet: this subnet is used by Azure Gateway
* An Azure Bastion resource that provides secure and seamless SSH connectivity to the jumpbox virtual machine directly in the Azure portal over SSL
* An Azure VPN Gateway resource that is used to send encrypted traffic between the hub virtual network to the on-premises simulated location.
* `w10-onprem-vm`: A Windows 10 VM with the objective to simulate a desktop client in an on-premise location

The ARM template [on-prem-deploy-2](on-prem-deploy-2.json) deploys:
* `on-prem-2-net`: an Azure Virtual Network located in Germany with 3 subnets
    * default subnet: this subnet is used to connect the w10-onprem-vm machine
    * AzureBastionSubnet: this subnet is used bu Azure Bastion
    * GatewaySubnet: this subnet is used by Azure Gateway
* An Azure Bastion resource that provides secure and seamless SSH connectivity to the jumpbox virtual machine directly in the Azure portal over SSL
* An Azure VPN Gateway resource that is used to send encrypted traffic between the hub virtual network to the on-premises simulated location.
* `lin-onprem-vm`: A linux VM with the objective to simulate a linux client in an on-premise location

The site to site VPN connection shown in the architecture is not automatically deployed and configure: its configuration is covered by one of the playground scenarios.

All machines have the same account parameters (as following):
* username: `nicola`
* password: `password.123`

## Playground's scenarios
* allows machines in any spoke to communicate with any machine in any other spoke
  * solution using [azure firewall](scenarios/ping-any-to-any-firewall.md)
  * solution using [virtual gateway](scenarios/ping-any-to-any-gateway.md)
* allows spoke-01 to: 
  * talk with spoke-2 
  * allow HTTP/S internet traffic avoiding access to *.google.com and *.microsoft.com 
  * [solution-spoke-01-inet](scenarios/spoke-01-inet.md)
* DNAT: expose on public IP, via RDP (port 3389) machines spoke-01-vm and spoke-02-vm [solution-dnat-01-02](scenarios/dnat-01-02.md)
* Connect on-prem with cloud with a VNet-toVNet Connection [solution-vnet-tovnet](scenarios/vnet-to-vnet.md)
* Connect on-prem with cloud with a Site-toSite (IPSec) Connection  [solution-ipsec](scenarios/ipsec.md)
* Configure a DNS on the cloud, so that all machines are reachable via FQDN [solution-dns](scenarios/dns.md)
* Troubleshooting connection on Azure Firewall using logs [solutions-log-firewall](scenarios/logs.md)
* public web page filtered with firewall [solution-web-public](scenarios/web.md) 
* enable cross-on-premises communication [solution-cross-on-premise-routing](scenarios/cross-on-premise-routing.md)
* Use Azure Firewall for traffic inspection between on-premise and spoke network in cloud (North/South Traffic Inspection) [solution-north-south-inspection](scenarios/solution-north-south-inspection.md)

future solutions:

* Resolve from on-prem, names of all cloud machines, and vice-versa