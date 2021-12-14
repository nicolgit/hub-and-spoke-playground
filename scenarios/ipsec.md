# SOLUTION: connect on-prem and hub with a Site-to-Site IPSec connection
in order to make this connection, you have to create 2 connections one from on-prem to cloud and another from cloud to onprem

# create Local Network Gateways
create the following gateways

| Name | IP Address | Address Space |
|---|---|---|
|cloud-net | (public-ip-gw-cloud) | 10.0.0.0/8|
|onprem-net| (public-ip-onprem) | 192.168.0.0/16 |

## connection onprem-to-cloud
Open `on-prem-gateway`, go to Connections and add the following object
* Connection Name: onprem-to-cloud
* Type: Site-to-Site (IPsec)
* virtual Network Gateway:  `lab-gateway`
* Local Network Gateway: `cloud-net`
* Shared Key: `password.123`
* IKE: IKEv2


## connection cloud-to-onprem
Open `lab-gateway`, go to Connections and add the following object
* Connection Name: cloud-to-onprem
* Type: Site-to-Site (IPsec)
* virtual Network Gateway:  `lab-gateway`
* Local Network Gateway: `onprem-net`
* Shared Key: `password.123`
* IKE: IKEv2

after few minutes, you will see, on  `on-prem-gateway` connections:

| Name | Status | Connection Type | Peer |
|---|---|---|---|
|onprem-to-cloud | connected  |Site-to-Site (IPsec)| cloud-net|

and on `lab-gateway` connections:

| Name | Status | Connection Type | Peer |
|---|---|---|---|
|cloud-to-onprem | connected  |Site-to-Site (IPsec)| onprem-net |

## TEST
Via bastion go to W10onprem (192.168.1.4) and from there open RDP to hub-vm-01 (10.12.1.4).
Ddthe same in the opposite direction