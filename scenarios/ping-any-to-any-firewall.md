# SOLUTION: Allows machines in ANY spoke to communicate with ANY machine in ANY other spoke

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
| default | spoke-02 |

Create the following route table in `north europe`: `spokes-ne-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual Appliance | 10.12.3.4 |
| to-spoke-02 | 10.13.2.0/24 | Virtual Appliance | 10.12.3.4 |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-03 |

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
