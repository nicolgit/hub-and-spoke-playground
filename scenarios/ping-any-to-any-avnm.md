# SOLUTION: Allows machines in ANY spoke to communicate with ANY machine in ANY other spoke (Azure Virtual Network Manager)

Azure Virtual Network Manager is a management service that enables you to group, configure, deploy, and manage virtual networks globally across subscriptions. With Virtual Network Manager, you can define network groups to identify and logically segment your virtual networks. Then you can determine the connectivity and security configurations you want and apply them across all the selected virtual networks in network groups at once.

In the Hub and Spoke model, the **routing between different Spokes is a significant element**. Each spoke often identifies an application or a workload, and these enterprise elements have to interact with each other. In this scenario, Azure Virtual Network Manager (AVNM) can simplify and automate the deployment of connectivity between them.

In this solution, I show you how configure the routing between spokes using the **Azure Vitual Network Manager**.

The resulting overall architecture is shown in the following schema.

![any to any routing via direct peering](/images/any-to-any-routing-avnm.png)

_Download a [draw.io file](../images/any-to-any-routing.drawio) of this architecture._

## Pre-requisites

In order to apply this solution you have to deploy hub playground only.

## Solution

Go to Azure Portal > Virtual Network Manager > Create

Basics
* Region: `westeurope`
* Name `avnm-lab`
* Features: Connectivity

Management Scopes

* the subscription where you deployed the hub playground

Click Create.

Once the service is deployed, we can deploy the connectivity between all spokes:

Go to Azure Portal > Virtual Networks Manager > `avnm-lab` > Network groups > Create
* Name `all-spokes`
* click Create

Once created go to `avnm-lab` > Network Groups > `all-spokes` > Add Virtual Networks:
* `spoke-01`
* `spoke-02`
* `spoke-03`
* click add

go to `avnm-lab` > Configurations > Create connectivity configuration:

* Name: `hub-conn-configuration`
* Topology: `Mesh`
* Mesh connectivity between region: `Enable`
* Network groups: `all-spokes`
* click Create

go to `avnm-lab` > Deployments > Deploy Configuration > Deploy Connectivity configuration: 
* Connectivity Configuration: `hub-conn-configuration`
* Target Regions: `westeurope` and `northeurope`
* click Deploy

## Test Solution
Test connections using remote desktop client and ssh from one machine to another.

## More Information
* Azure [Virtual Network Manager](https://learn.microsoft.com/en-us/azure/virtual-network-manager/overview)