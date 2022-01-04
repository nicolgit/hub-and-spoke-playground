# SOLUTION: Allows machines in ANY spoke to communicate with ANY machine in ANY other spoke

In order to allow this communication, via **Azure Virtual Gateway**:

Verify that gateway transit is Enabled, on `hub-lab-net` > peerings

| Name | Peering Status | Peer | Gateway Transit |
|---|---|---|---|
| hub-to-spoke01 | Connected | spoke-01 | Enabled |
| hub-to-spoke02 | Connected | spoke-02 | Enabled |
| hub-to-spoke03 | Connected | spoke-03 | Enabled |

Create the following route table in `west europe`: `spokes-we-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual network gateway | - |
| to-spoke-02 | 10.13.2.0/24 | Virtual network gateway | - |
| to-spoke-03 | 10.13.3.0/24 | Virtual network gateway | - |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-01 |
| default | spoke-02 |

Create the following route table in `north europe`: `spokes-ne-to-hub-routes`

| Name | Address Prefix | Next hop type | Next hop IP addr |
|---|---|---|---|
| to-spoke-01 | 10.13.1.0/24 | Virtual network gateway | - |
| to-spoke-02 | 10.13.2.0/24 | Virtual network gateway | - |

| subnet Name | Virtual Network |
|---|---|
| default | spoke-03 |

## Test
Test connections using remote desktop client and ssh from one machine to another.
