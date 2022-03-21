# SOLUTION: Use Azure Network Watcher for network logging and troubleshooting

In this solution, we will use Azure Network Watcher and NGS flow logs for logging and network troubleshooting on the following virtual networks/subnets.

* `hub-lab-net` > `default` subnet
* `spoke-01` > `default` subnet
* `spoke-02` > `default` subnet

Common NSG flow logs troubleshooting use cases include:

* **Network Monitoring**: Identify unknown or undesired traffic. Monitor traffic levels and bandwidth consumption. Filter flow logs by IP and port to understand application behavior. Export Flow Logs to analytics and visualization tools of your choice to set up monitoring dashboards.
* **Usage monitoring and optimization**: Identify top talkers in your network. Combine with GeoIP data to identify cross-region traffic. Understand traffic growth for capacity forecasting. Use data to remove overtly restrictive traffic rules.
* **Compliance**: Use flow data to verify network isolation and compliance with enterprise access rules
* **Network forensics & Security analysis**: Analyze network flows from compromised IPs and network interfaces. Export flow logs to any SIEM or IDS tool of your choice.

## Pre-requisites

In order to apply this solution, deploy **hub** playground first.

## Solution
### 01 - Create a Storage Account
Create an Azure Storage Account to collect the NSG flow logs.

* Name: `<storagename>`
* Region: `west europe`
* Performance: `Standard`
* Redundancy: `LRS`

Under Data Protection TAB, **disable** all recovery options. 


### 02 - Create Network Security Groups
Create a Network Security Group with the following characteristics:

* Name: `nsg-playground`
* region: `west europe`
* inbound/outbound rules: leave all on defaults

Associate NSG to the following subnets: 

| virtual network | subnet | 
|---|---|
| `hub-lab-net` | `default` |
| `spoke-01` | `default` |
| `spoke-02` | `default` |

under NSG flow logs, click on **create a NSG Flow log**:
* Select NSG: `nsg-playground`
* Storage Accounts: `<storagename>`
* Retention days: `20`
* Traffic Analytics: `Enable`
* Traffic Analytics processing interval: `10 minutes`
* Log Analytics Workspace: `<your-preferred-loganalytics-workspace>`

## Test Solution
Simulate a connection:

* Connect via RDP/Bastion to `spoke-01-vm`
* From the virtual desktop connect via RDP to 10.12.1.4 (hub-vm-01)

check data in Flow logs:

* open: `<storagename>` > Containers > Insights-logs-networksecuritygroupflowevent
* open the following folder:
  * resourceId=
  * SUBSCRIPTIONS
  * `<GUID>`
  * RESOURCEGROUPS
  * `<RESOURCEGROUPNAME>`
  * PROVIDERS
  * MICROSOFT.NETWORK 
  * NETWORKSECURITYGROUPS
  * year > month > day > hour > minute > 
  * macAddress of spoke-01-vm 
    * _you can find it on azure vm page under > Network interface > properties_
  * open file PT1H.json

> Flow logs operate at Layer 4 and record all IP flows going in and out of an NSG. Logs are collected at 1-min interval through the Azure platform and do not affect customer resources or network performance in any way. Logs are written in the JSON format and show outbound and inbound flows on a per NSG rule basis.
> here more information on the format and fields meaning: <https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-overview#log-format>

in json file, you will find FlowTuples to 10.12.1.4 on 3389 port

> "1647878148,10.13.1.4, **10.12.1.4** ,51896, **3389** ,T,O,A,E,214,20643,278,36774",

### See Traffic Analytics
Go to Azure search bar and type Network Watcher.
Select Traffic Analytics.

> remember that you have to wait at least 10 minutes before to see your data here.

