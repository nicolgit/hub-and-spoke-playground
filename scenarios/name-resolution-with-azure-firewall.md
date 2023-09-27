# SOLUTION: Configure a DNS on the cloud, and be sure that all machines are reachable via FQDN also from on-premise (Azure Firewall Version)

read also [this blog post](https://nicolgit.github.io/dns-forwarding-azure-hub-and-spoke/) for more information on this solution.

## Pre-requisites

In order to apply this solution:

1. deploy HUB playground
2. deploy ONPREMISE-2 playground
3. configure the DNS on the cloud as [documented here](dns.md)
4. configure a site-to-site VPN as [documented here](vnet-to-vnet-2.md)

## Solution

The solution implemented is described in the following schema.

![DNS](/images/dns.png)

### Configure Azure Firewall for DNS resolution and proxy
Create the following Firewall Policy:
* Name: `hub-fw-policy`
* DNS: `Enabled`
    * DNS Servers: `Default (Azure Provided)`
    * DNS Proxy: `Enabled`

Associate the policy `hub-fw-policy` to `hub-lab-vnet`. 

On `spoke-01` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4` (the internal firewall IP).

On `spoke-02` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4` (the internal firewall IP).

On `spoke-03` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4` (the internal firewall IP).

On `hub-lab-net` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4` (the internal firewall IP).

### Configure a DNS machine on prem
Open ssh on `lin-onprem` machine and install [Bind9](https://www.isc.org/bind/):

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install bind9
```

Edit `/etc/bind/named.conf.options` file (i.e. with `sudo nano /etc/bind/named.conf.options`) and fill it with the following:

```
options {
    directory "/var/cache/bind";

    allow-query { localhost; 10.20.1.0/24; };

    recursion yes;
    forwarders {
        10.12.3.4;
    };
    forward only;

    dnssec-validation no; # needed for private dns zones
    auth-nxdomain no;     # conform to RFC1035
    listen-on-v6 { any; };
};
```

> in this configuration, on-prem DNS (`10.20.1.4`) forwards all request to Azure Firewall (`10.12.3.4`) that acts as DNS proxy for the Azure managed DNS accessible from the hub. allow-query parameter allows machines on-prem to use this DNS. dnssec validation off is required to manage the private DNS zone.

Restart Bind9 service to load the updated configuration.

`sudo service bind9 restart`

### Configure Client machine on-prem-2

Open ssh on `lin-onprem-2` and set `Lin-onprem` as DNS server. To do it type `sudo nano /etc/resolv.conf` and replace _nameserver_ row with the following:

`nameserver 10.20.1.4` 
> this is `lin-onprem` machine IP

# Test Solution
From ssh on `Lin-onprem` machine type:

`nslookup spoke-01-vm.cloudasset.internal 10.12.3.4` (direct query to Azure Firewall)

or

`nslookup spoke-01-vm.cloudasset.internal` (query to `lin-onprem` that forward the request to Azure Firewall)

if the answer is 

```
Server:10.12.3.4
Address:10.12.3.4#53

Non-authoritative answer:
Name:spoke-01-vm.cloudasset.interal
Address: 10.13.1.4
```

On premise machine `Lin-onprem-2` is able to resolve FQDN names for cloud machines (*.clouadasset.internal), with on premise DNS server - `Lin-onprem` - that forwards DNS queries to Azure Firewall on the cloud. Azure Firewall forwards the request to the Azure managed DNS. Azure managed DNS is able to resolve `cloudasset.internal` domain because `hub-lab-vnet` has been linked with the corresponding private zone.

