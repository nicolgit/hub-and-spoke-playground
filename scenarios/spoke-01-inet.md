# SOLUTION: filter internet traffic and spokes connectivity

## Pre-requisites

In order to apply this solution you have to deploy hub playground only.

## Solution
This configuration allows `spoke-01` to: 
  * communicate with `spoke-02` 
  * allow HTTP/S internet traffic avoiding access to `*.google.com` and `*.microsoft.com`  


Create the following route tables in `west europe`: 

Route: `route-01`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-all | 0.0.0.0/0 | Virtual Appliance | 10.12.3.4 |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-01 |

Route: `route-02`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-02 | 10.13.1.0/24 | Virtual Appliance | 10.12.3.4 |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-02 |


Create the following `IP Groups` in `west europe`:
* `group-spoke-01`: 10.13.1.0/24
* `group-spoke-02`: 10.13.2.0/24

Create the following Firewall Policy: `internet-policy`

**Network Rules**:

| priority | collection name | rule name | source | port | protocol | destination | Action |
|---|---|---|---|---|---|---|---|
| 1000 | net-coll-01| to-spoke-02 | group-spoke-01 | * | Any | group-spoke-02 | Allow |
| 1000 | net-coll-01| to-spoke-01 | group-spoke-02 | * | Any | group-spoke-01 | Allow |

**Application Rules**:

| priority | collection name | rule name | source | protocol | destination| action |
|---|---|---|---|---|---|---|
|1000|filtered-collection| no-goog-msft| * | HTTP,HTTPS | *.google.com,<br>*.microsoft.com | Deny |
|2000|allow-inet-coll| allow-inet| * | HTTP,HTTPS | * | Allow | 

Associate the policy `hub-fw-policy` to `lab-firewall` via Firewall Manager.

## Test solution
* Verify mutual reachability via remote desktop client

* Open browser and verify that google.com and microsoft.com are not available.