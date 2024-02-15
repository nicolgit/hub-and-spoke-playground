# SOLUTION: ???

what is Azure OpenAI
why is reccomended to have a single open AI instance inbside the enterprise
why is important to have an common API manager in the enterprise and what are their benefit
Why Enterprise should use the hub and spoke network architecure



## Pre-requisites

In order to apply this solution you have to deploy the `hub-01` and the `any-to-any` routing, so that you have a fully configured hub-and-spoke network with firewall and routing between spokes.

## Solution

### Deploy Azure OpenAI Service
Go to Azure Portal > Azure AI | Azure OpenAI > Create
* region: West Europe
* Name: `aoai-01`
* pricing tier: `standard S0`

Network
* Type: `disabled`
* add private endpoint
  * Location: west europe
  * Name: `aoai-01-pe`
  * Virtual Network: `spoke-01`
  * Subnet: `services`
  * Integrate with private dns zone: No
* click [create]

Go to Azure Portal > private DNS zone > create
* name: `aoai-01.openai.azure.com`
* Click [Create] 

Take note ok the `KEY1` found in Resource Management >Keys and Endpoint > KEY1.

Go to Azure Portal > Private DNS zones > `aoai-011.openai.azure.com` > + Record set

* Name: `*`
* Type: `A`
* IP: `10.13.1.68` (Azure Open AI private endpoint IP)
* Click [OK]

Go to Virtual Network links > Add
* name: `spoke-01-link`
* subnet `spoke-01`
* click [OK]

Go to Virtual Network links > Add
* name: `spoke-02-link`
* subnet `spoke-02`
* click [OK]

### Deploy a model
Go to Portal > Azure AI | Azure OpenAI > `aoai-01` > Azure Open AI Studio > Deplymments > Create

* Model: gpt-35-turbo
* Name `mygpt`
* click [Create]


### API Management Service public IP
Go to Azure Portal > Public IP addresses > Create

Basic
* Region: West Europe
* Name: `apiman-ip-02`
* IP version: `v4`
* SKU: `standard`
* DNS name label: `apiman-02-ip`
* click [create]

### API Management subnet NSG
Go top Azure Portal > Network security groups > create
* Name: `apiman-nsg`
* Region: Wer Europe
* click [create]

Go to Azure Portal > Network security groups > `apiman-nsg` > subnets > associate:
* virtual network: `spoke-02`
* subnet: `services`

### Api Management Service Instance
Go to Azure Portal > API Management Service > Create

Basics
* Region: West Europe
* Name: `apiman-02`
* Organization: `contoso`
* Organization email: `admin@contoso.com`
* Tier: Developer

Virtual Network
* Connectivity Type: `virtual network`
* Type: `internal`
* Virtual Network: `spoke-02`
* Subnet: `Services`
* public ip address: `apiman-ip-02`
* click [create]

### Import OPEN AI Rest interface in APIM using his swagger specification
Azure OpenAI provides you with REST API references, that can easily be imported into Azure API Management. In this scenario we will implement only the completition endpoint.

* download [completition endpoint swagger specification](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference#completions) from Microsoft


....................

### configure API Key in API configuration

...................


## Test solution
Connect via bastion/ssh to spoke-03-vm and type the following:

......................................................

## More information

* Deploy your Azure API Management instance to a virtual network - internal mode https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2 
  
* Azure Open AI https://learn.microsoft.com/en-us/azure/ai-services/openai/
* Azure API Management Service https://learn.microsoft.com/en-us/azure/api-management/ 
  * vnet internal deployment: https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet
* Private endpoint https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview
* Publish Open AI via APIM https://techcommunity.microsoft.com/t5/apps-on-azure-blog/build-an-enterprise-ready-azure-openai-solution-with-azure-api/ba-p/3907562 



