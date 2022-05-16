# SOLUTION: Secure a WEB workload with both Azure Firewall Premium and Azure Web Application Firewall

To secure a web Azure application workloads, you use protective measures, such as authentication and encryption, in the applications themselves. You can also add security layers to the virtual machine (VM) networks that host the applications. The layers protect inbound flows from users. They also protect outbound flows to the internet that your application might require.

This solutions shows how secure a workload with Azure Firewall Premium and Azure Application Firewall, when it is hosted in a Hub-and-spoke architecture.

* [Hub-and-Spoke reference architecture](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke): a hub virtual network acts as a central point of connectivity to many spoke virtual networks. The hub can also be used as the connectivity point to your on-premises networks. The spoke virtual networks peer with the hub and can be used to isolate workloads. The benefits of using a hub and spoke configuration include cost savings, overcoming subscription limits, and workload isolation.
* [Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features): is a managed next-generation firewall that offers NAT, packet filtering, threat intelligence to identify malicious IP address, TLS inspection and Intrusion Detection and Protection System (IDPS)
* [Azure Application Gateway](https://docs.microsoft.com/en-us/azure/application-gateway/) with Web Application Firewall: is a managed web traffic load balancer and HTTP(S) full reverse proxy that can do Secure Socket Layer (SSL) encryption and decryption. Application Gateway also uses [Web Application Firewall](https://docs.microsoft.com/en-us/azure/web-application-firewall) to inspect web traffic and detect attacks at the HTTP layer

the proposed solution is shown in the image below:

![WAF + Firewall](/images/waf-fw.png)

In this option, inbound web traffic goes through both Azure Firewall and WAF. The WAF provides protection at the web application layer. Azure Firewall acts as a central logging and control point, and it inspects traffic between the Application Gateway and the backend servers. The Application Gateway and Azure Firewall aren't sitting in parallel, but one after the other. Gateway and workload are deployed in 2 spoke connected via a central hub.

more information on this approach: [Application Gateway before Firewall scenario](https://docs.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway#application-gateway-before-firewall)

## Pre-requisites

In order to apply this solution you have to deploy hub playground only.

## Solution

### Step 1 - Create Gateway Virtual Network
Create the following Virtual Network:
* Name: `spoke-gateway`
* Region: `west-europe`
* IPv4 address space: `10.13.4.0/24`
* subnet
  * Name: `AppGatewaySubnet`
  * subnet range: `10.13.4.0/24`

create network peering with `hub-lab-net`

* Peering Name to hub: `gateway-to-hub`
* Peering Name from hub: `hub-to-gateway`

### Step 2 - create Application Gateway with WAF

Create the following Azure Application Gateway

* Name: `hub-gateway`
* Region: `west-europe`
* Tier: `waf-v2`
* Minimum instance count: `1`
* Create WAF Policy
  * Name: hub-gateway-waf-policy
* Virtual Network: `spoke-gateway`
* Virtual Network: `AppGatewaySubnet`
* Front ends > Create public IP
  * Name: `hub-gateway-ip`
* Backends > Add backend pool
  * Name: `backend-01`
  * Target type `IP`: `10.13.3.4`
* Configuration > Add a routing rule
  * Name: `rule-01`
  * Priority: `100`
  * Listener
    * Name: `Listener-01`
    * Frontend: `public ip`
    * protocol: `http`
    * type: `basic`
  * Backend targets
    * type: backend pool > `backend-01`
    * backend settings > new
      * Name: `settings-01`
      * protocol: `HTTP`
      * port: `80`
      * Hoverride new hostname: `NO`
    * clock **ADD**


### Step 3 - Create user defined routing tables


Create the following route table in `west europe`: `spokes-we-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-03 | 10.13.3.0/24 | Virtual Appliance | 10.12.3.4 (fw) |


| subnet Name | Virtual Network |
|---|---|
| AppGatewaySubnet | spoke-gateway |

Create the following route table in `north europe`: `spokes-ne-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-gateway | 10.13.4.0/24 | Virtual Appliance | 10.12.3.4 (fw) |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-03 |

### Step 04 - configure firewall for routing 

Create the following `IP Groups` in `west europe`:
* `group-01`: `10.13.3.0/24`, `10.13.4.0/24`

Create the following Firewall Policy: `hub-fw-policy`

**Network Rules**:
* Rule Collection Name: `my-collection`
* Rule Collection type: `Network`
* Priority: `1000`
* Rule Colletion action: `Allow`
* Rule Collection group: `DefaultNetworkRuleCollectionGroup`


| rule name | source | port | protocol | destination | 
|---|---|---|---|---|
| all-to-all | `group-01` | * | Any | `group-01` | 

Associate the policy `hub-fw-policy` to `lab-firewall` via Firewall Manager.

**Enable logging**

Create a Log Analytics Workspace named `playground-workspace` in `west-europe`.
In order to analyze firewall logs go to `lab-firewall` -> Diagnostic Settings -> Add Diagnostic Settings:
* Name: `firewall-diagnostics `
* Logs: Category Group -> All logs
* Metrics: All Metrics
* Destination details: Send to Log Analytics Workspace -> `playground-workspace`
* click **SAVE**

### Step 5 - install a web server on `spoke-03-vm` 

Access to spoke-03-vm via Bastion and type

```
sudo apt-get update
sudo apt-get upgrade
sudo apt install nginx -y
```

test web server installation status

`wget http://10.13.3.4 -S -O -`

response

```
Connecting to 10.13.3.4:80... connected.
HTTP request sent, awaiting response... 
  HTTP/1.1 200 OK
  Server: nginx/1.14.0 (Ubuntu)

  ...
```

# Test Solution

from a brower open `http://xxxx/` where **xxx** is `hub-gateway-ip`'s public IP you should see the following:

```
Welcome to nginx!
If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

For online documentation and support please refer to nginx.org.
Commercial support is available at nginx.com.

Thank you for using nginx.
```

go to `lab-firewall` -> Logs -> click on `Run` button in **Network Rule Log Data** Box.

In the Result pane, the first row should be something like:

| Time | msg | Protocol | SourceIP | srcport| TargetIp | target port | Action |
|---|---|----|---|---|---|---|---|
|...|...|TCP|10.13.4.6|xxx|10.13.3.4|80|**Allow**|

> Log ingestion from Azure Firewall can require from 60 seconds to 15 minutes, so if nothing is displayed, wait some minute and try again.
