# SOLUTION: expose via Azure front door an internal web server located on vm on a spoke

TO BE COMPLETED with the following information


what is azure fornt door?

Why is important do not expose on internet the origin of an azure frontdoor endpoint

Why to use Azure Frontdoor instead of Application Gateway

Why use Azure Frontdoor instead of a public load balancer

the final architecture involvese the following resources

## Pre-requisites

In order to apply this solution you have to deploy the `hub-playground` only. 
For this sample I have installed all hub's resources in `northeurope`.

## Solution

### Activate a web server on `spoke-01-vm`

Go to Azure Portal > virtual machines > spoke-01-vm > connect via bastion

once logged open powershell and type the following:

``` powershell
Install-WindowsFeature -name Web-Server -IncludeManagementTools
Remove-Item -Path 'C:\inetpub\wwwroot\iisstart.htm'
Add-Content -Path 'C:\inetpub\wwwroot\iisstart.htm' -Value $($env:computername)
```

### create an internal load balancer

Go to Azure Portal > Load balancers > Create > standard load balancer

#### Basic
* name: `nlb-01`
* region: `northeurope`

#### Frontend IP configuration

Add frontend IP Configuration:
* name: `nlb-frontend-01`
* IP version: ipv4
* virtual network: `spoke-01`
* subnet: `default`
* assignment: dynamic
* availability zone: zone redundant


#### Backend pools

Add a backend pool: 
* name: `nlb-backend-01`
* backend pool configuration: NIC
  * resource name: `spoke-01-vm`
* click **SAVE**

#### inbound rules

Add a load balancing rule:

* name: `lb-rule-01`
* ip version: v4
* frontend ip address: `nlb-frontend-01`
* backend pool: `nlb-backend-01`
* protocol: TCP
* inbound port: `80`
* backend port: `80`
* create a new health probe:
  * name: `probe-01`
  * protocol: http
  * port: `80`
  * path: `/`
  * interval: `5` sec
  * click **SAVE**
* click **SAVE**

#### outbound rule

none.

#### Review and create

click **CREATE**

### create a private link service

Go to Azure Portal > private link services > create

#### Basics
* Name: `pls-nlb-01`
* Region: `northeurope`

#### outbound settings
* Load Balancer: `nlb-01`
* Load balancer frontend ip address: `10.13.1.5`
* source nat subnet: `default`

#### review and create
click **CREATE**.

### create an Azure Front Door

Go to Azure Portal > Front Doors > Create > Azure Front Door/quick create

###
* Name: `afd-01`
* Tier: premium
* Endpoint name: `afd-01`
* sku: standard
* origin type: custom
* origin host name: `10.13.1.5` (internal load balancer, front end ip)
* private link service: ENABLE
* select private link: in my directory
* resource: `pls-nlb-01`
* Request message: `please approve me`
* WAF policy: create new:
  * Name: `afdwaf01`
  * bot protection: ON
  * click **CREATE**
* click **CREATE**

Go to Azure Portal > Private link services > **pls-nlb-01** > private endpoint connections. 
You will find 1 private endpoint connections, select both, then click to **APPROVE**

The connection state should change to Approved. It might take a couple of minutes for the connection to fully establish. 
You can now access your internal load balancer from Azure Front Door.

Go to Azure Portal > **afd-01** > Frontdoor manager > **default-route** > update and change forwarding protocol to **HTTP only** (because your backend VM exoposes an HTTP only web server).

## Test solution
Because Azure Frontdoor is a globally distribuited service, each update can require up to 10/20 miuntes to propagate everywhere. After this time,  open `afd-01` endpoint hostname public url, you found on overview page (something like `https://afd-01-abcefgh.b01.azurefd.net`). You will see `spoke-01-vm`.

# More information

* <https://learn.microsoft.com/en-us/azure/frontdoor/private-link>
* <https://learn.microsoft.com/en-us/azure/private-link/create-private-link-service-portal?tabs=dynamic-ip>
* <https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-enable-private-link-internal-load-balancer>