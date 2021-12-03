# Create an hub-and-spoke playground to test configurations and customer scenarios

This repo contains an ARM template to that can be used to deploy a playground composed by:
  * a hub and spoke network topoly aligned with with <a href="https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/enterprise-scale/architecture" target="_blank">Microsoft Enterprise scale landing zone</a> reference architecture
  * a simulated on-premise architecture composed by a network, a client machine and a gateway to be used to test connectivity with the cloud

## Deploy to Azure
You can use the following button to deploy the demo to your Azure subscription:

* [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnicolgit%2Fhub-and-spoke-playground%2Fmain%2Fcloud-deploy.json) hub and spoke playground part
* [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https%3A%2F%2Fraw.githubusercontent.com%2Fnicolgit%2Fhub-and-spoke-playground%2Fmain%2Fon-prem-deploy.json) on premises playground part

## Architecture
This diagrams shows the overall architecture:

architecture image HERE

the ARM template [cloud-deploy](cloud-deploy.json) deploys:
* 4 new Azure Virtual Networks:
    * hub-lab-net with 4 subnets:
        * default subnet: this subnet is used to connect the hub-vm-01 machine
        * AzureFirewallSubet: this subnet is used by Azure Firewall
        * AzureBastionSubnet: this subnet is used bu Azure Bastion
        * GatewaySubnet: this subnet is used by Azure Gateway
    * spoke-01 with 1 subnet used to connect spoke-01-vm machine
    * spoke-02 with 1 subnet used to connect spoke-02-vm machine
    * spoke-03, located in North Europe, used to connect spoke-03-vm machine
* An Azure Bastion resource that provides secure and seamless SSH connectivity to the jumpbox virtual machine directly in the Azure portal over SSL
* An Azure Firewall resource that provide a cloud-native, fully stateful, firewall as a service with built-in high availability and unrestricted cloud scalability. It provides both east-west and north-south traffic inspection.
* An Azure VPN Gateway resource that is used to send encrypted traffic between the hub virtual network to the on-premises simulated location.
* hub-vm-01: a Windows Server virtual machine that simulates a server located in the hub location
* spoke-01-vm: a Windows Server virtual machine that simulates a server located in the spoke-01 landing zone
* spoke-02-vm: a Windows Server virtual machine that simulates a server located in the spoke-02 landing zone
* spoke-03-vm: a Linux virtual machine that simulates a server located in the spoke-01 landing zone

The ARM template [on-prem-deploy](on-prem-deploy.json) deploys:
* on-prem-net: an Azure Virtual Network located in France with 3 subnets
    * default subnet: this subnet is used to connect the w10-onprem-vm machine
    * AzureBastionSubnet: this subnet is used bu Azure Bastion
    * GatewaySubnet: this subnet is used by Azure Gateway
* w10-onprem-vm: A Windows 10 VM with the objective to simulate a desktop client in an on-premise location



# main components and information on the scenario
lorem ipsut dixit



az provider register --namespace 'Microsoft.Network'


az group create --name hub-and-spoke-playground --location westeurope

az deployment group create --resource-group hub-and-spoke-playground --template-uri https://raw.githubusercontent.com/nicolgit/hub-and-spoke-playground/main/azuredeploy.json


