# SOLUTION: configure a DNS on the cloud, and be sure that all machines are reachable via FQDN also from on-premise

## Pre-requisites

In order to apply this solution:

1. deploy HUB playground
2. deploy ONPREMISE-2 playground
3. configure the DNS on the cloud as [documented here](dns-on-prem.md)
4. configure a site-to-site VPN as [documented here](vnet-to-vnet.md)

## Solution

### Configure Azure Firewall for DNS resolution and proxy
Create the following Firewall Policy: `hub-fw-policy`:
* DNS: `Enabled`
    * DNS Servers: `Default (Azure Provided)`
    * DNS Proxy: `Enabled`

associate the policy `hub-fw-policy` to `hub-lab-vnet`. 

On `spoke-01` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4` (internal firewall IP).

On `spoke-02` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4`.

On `spoke-03` virtual network go to DNS Servers and set as DNS Server custom `10.12.3.4`.


### Configure a DNS machine on prem
Open ssh on `lin-onprem` machine and install Bind9:

```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install bind9
```

edit `/etc/bind/named.conf.options` file and fill it with the following:

```
options {
    directory "/var/cache/bind";

    forwarders {
        10.12.3.4;
    };
    forward only;

    dnssec-validation auto;
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
```

this configure the machine ad DNS Server that forward all the requests to the Azure Firewall(`10.12.3.4`)

restart bind9 service to reload the configuration

`sudo service bind9 restart`

### Configure Client machine on-prem-2

# Test Solution
Wait some minute before the following tests.

From ssh on `Lin-onprem` machine type

`nslookup spoke-01-vm.cloudasset.internal 10.12.3.4`

if the answer is 

```
Server:10.12.3.4
Address:10.12.3.4#53

Non-authoritative answer:
Name:spoke-01-vm.cloudasset.interal
Address: 10.13.1.4
```

this means that azure firewall DNS proxy is resolving the cloud internal names properly.

From ssh on `Lin-onprem` machine type

`nslookup spoke-01-vm.cloudasset.internal`



...









<https://www.thegeekstuff.com/2014/01/install-dns-server/>
<https://help.ubuntu.com/community/BIND9ServerHowto>

install bind9





### Configure a cache server
The job of a DNS caching server is to query other DNS servers and cache the response. Next time when the same query is given, it will provide the response from the cache. The cache will be updated periodically.

Please note that even though you can configure bind to work as a Primary and as a Caching server, it is not advised to do so for security reasons. Having a separate caching server is advisable.

All we have to do to configure a Cache NameServer is to add your ISP (Internet Service Provider)’s DNS server or any OpenDNS server to the file /etc/bind/named.conf.options. For Example, for Azure infrastructure we can usewe `168.63.129.16`. Google’s public DNS servers are instead `8.8.8.8` and `8.8.4.4`.

Uncomment and edit the following line as shown below in `/etc/bind/named.conf`.options file.

```
forwarders {
    168.63.129.16;
};

```
restart bind service (do it on each change a config file /etc/bind/* )

`sudo service bind9 restart`

## Test solution
Connect via RDP from xxx machine onprem to spoke-01 VM using the following Names:
* spoke-01-vm.cloudasset.internal
* vm01.spoke01.cloudasset.intenal




---
blog post matrial

Configure DNS in an Azure Hub and Spoke network.

in una architettura hub and spoke, la componente DNS è un elemento di infrastruttura fondamentale. Nella documentazione relativa alla ESLZ esiste una sezione specifica con un elenco di raccomandazioni da tenere a mente in questo contesto.
In questo post descrivo una possibile implementazione della componente DNS, with a special focus on the following requirements:

•	How to associate an FQDN to all VM on Azure
•	Come risolvere questi FQDN from on-prem

In this repo on GitHub, I have implemented a script to generate and hub and spoke “playground” where it is possible to test this configuration and much more. In this blog post you can find more information on it.
Components:

•	Azure Private DNS zone: Azure Private DNS manages and resolves domain names in the virtual network without the need to configure a custom DNS solution.
•	Azure Firewall & DNS. You can configure a custom DNS server and enable DNS proxy for Azure Firewall. The 

DNS server setting lets you configure your own DNS servers for Azure Firewall name resolution. You can configure a single server or multiple servers. If you configure multiple DNS servers, the server used is chosen randomly. You can configure a maximum of 15 DNS servers in Custom DNS.
The solution is shown in the following schema

https://azure.microsoft.com/en-us/blog/new-enhanced-dns-features-in-azure-firewall-now-generally-available/ 
https://docs.microsoft.com/en-us/azure/firewall/dns-settings 
