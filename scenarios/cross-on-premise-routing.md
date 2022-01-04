enable cross on-premise communication

Resource Group "hub-and-spoke-playground" > lab-gateway > Configuration:
* Configure BGP: ENABLE
* ASN: 65514
* BGP peer IP: 10.12.4.254
(if the portals shows an ERROR on save, just refresh the page, probably the configuration is ok anyway)



Resource Group "on-prem-germany-playground" > germany-gateway > Configuration:
* Configure BGP: ENABLE
* ASN: 65513
* BGP peer IP: 10.20.3.254
(if the portals shows an ERROR on save, just refresh the page, probably the configuration is ok anyway)


Resource Group "on-prem-playground" > on-prem-gateway > Configuration:
* Configure BGP: ENABLE
* ASN: 65512
* BGP peer IP: 192.168.3.254
(if the portals shows an ERROR on save, just refresh the page, probably the configuration is ok anyway)

verify the BGP peers page:
* on-prem gateway should have hub and on-prem-2 learned route
* on-prem-2 gateway should have hub and on-prem learned route




Overview og BGP in Azure VPN Gateway Context: https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-bgp-overview

How to configure BGP: https://docs.microsoft.com/en-us/azure/vpn-gateway/bgp-howto