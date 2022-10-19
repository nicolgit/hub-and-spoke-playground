# SOLUTION: Configure a P2S VPN with Certificate Authentication

This solution shows how to configure a P2S VPN to allow individual clients running Windows, Linux, or macOS to an Azure Virtual Network using **Azure certificate authentication**. Point-to-site VPN connections are useful when you want to connect to your VNet from a remote location, such as when you're telecommuting from home or a conference. 

Point-to-site VPN can use one of the following protocols:

* **OpenVPN® Protoco**l, an SSL/TLS based VPN protocol. A TLS VPN solution can penetrate firewalls, since most firewalls open TCP port 443 outbound, which TLS uses. OpenVPN can be used to connect from Android, iOS (versions 11.0 and above), Windows, Linux, and Mac devices (macOS versions 10.13 and above).

* S**ecure Socket Tunneling Protocol** (SSTP), a proprietary TLS-based VPN protocol. A TLS VPN solution can penetrate firewalls, since most firewalls open TCP port 443 outbound, which TLS uses. SSTP is only supported on Windows devices. Azure supports all versions of Windows that have SSTP and support TLS 1.2 (Windows 8.1 and later).

* **IKEv2 VPN**, a standards-based IPsec VPN solution. IKEv2 VPN can be used to connect from Mac devices (macOS versions 10.11 and above).

Before Azure accepts a P2S VPN connection, the user has to be authenticated first. There are two mechanisms that Azure offers to authenticate a connecting user:

* **Certificate Authentication**: When using the native Azure certificate authentication, a client certificate that is present on the device is used to authenticate the connecting user.
* **Azure Active Directory Authentication**: Azure AD authentication allows users to connect to Azure using their Azure Active Directory credentials. Native Azure AD authentication is only supported for OpenVPN protocol and also requires the use of the Azure VPN Client

More information:
* on P2S VPN: https://learn.microsoft.com/en-us/azure/vpn-gateway/point-to-site-about
* configure Certificate Authentication: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal


## Pre-requisites

In order to apply this solution:

1. deploy the **hub** playground
2. deploy the **on-premise** playground

## Solution

### Generate Root Certificates
Point-to-site connections use certificates to authenticate. The PowerShell cmdlets that you use will use to generate certificates are part of the operating system and don't work on other versions of Windows. The host operating system is only used to generate the certificates. Once the certificates are generated, you can upload them or install them on any supported client operating system.

* Access to `W10-OnPrem` via RDP/Bastion
* Create the self-signed root certificate `playground-certificate` with the following powershell command

```
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=playground-certificate" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
```

* create a client certificate `playground-client-certificate` with the following powershell command

```
New-SelfSignedCertificate -Type Custom -DnsName MyP2SClientCert01 -KeySpec Signature `
-Subject "CN=playground-client-certificate" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

``` 

For more information, [this article shows](https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site) you how to create a self-signed root certificate and generate client certificates using PowerShell on Windows 10 or later, or Windows Server 2016 or later.

### Export the root certificate

* Open `certmgr.exe` and locate the self-signed root certificate, in "Certificates - **Current User**\Personal\Certificates\`playground-certificate`", and right-click. Click All Tasks -> Export. This opens the Certificate Export Wizard.
* select **NO, do NOT export the private key**
* select `Base-64 encoded (.CER)`
* filename: `c:\root-cert-exported.cer` 

### Export the client certificate
Because we will test the P2S VPN from the client computer used to create the certificate, you do not need to export it. If you want to create a P2S connection from a client computer other than the one you used to generate the client certificates, you need to install a client certificate. When installing a client certificate, you need the password that was created when the client certificate was exported.

Make sure the client certificate was exported as a .pfx along with the entire certificate chain (which is the default). Otherwise, the root certificate information isn't present on the client computer and the client won't be able to authenticate properly.

more information: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site#clientexport 


### Add the VPN client address pool
The client address pool is a range of private IP addresses that you specify. The clients that connect over a point-to-site VPN dynamically receive an IP address from this range. Use a private IP address range that doesn't overlap with the on-premises location that you connect from, or the VNet that you want to connect to. If you configure multiple protocols and SSTP is one of the protocols, then the configured address pool is split between the configured protocols equally.

Go to `lab-gateway` > Point 2 Site Configuration > Configure Now:
* Address pool: `10.14.1.0/24`
* Tunnel Type: `Open VPN`
* Authentication Type: `Azure Certificate`
* Root Certificate Name: `my-root-certificate`
* open file `c:\root-cert-exported.cer` saved before with Notepad and copy all the text between ---BEGIN--- and ---END CERTIFICATE--- rows in the `public certificate data` field:

```
-----BEGIN CERTIFICATE-----
MIIC/TCCAeWgAwIBAgIQF2MY6gVnqKRB9OqCSvetITANBgkqhkiG9w0BAQsFADAh
MR8wHQYDVQQDDBZwbGF5Z3JvdW5kLWNlcnRpZmljYXRlMB4XDTIyMTAxOTA4MzE1
NFoXDTIzMTAxOTA4NTE1NFowITEfMB0GA1UEAwwWcGxheWdyb3VuZC1jZXJ0aWZp

... <removed rows> ...

jHX5Wtexk5abytL0fjBB4SMzPkzVC+bGmSBdsZHuYnsmYyw9KaflYAAob9WK3a8U
gQ==
-----END CERTIFICATE-----
```

* click **SAVE**

## Test Solution
* Download VPN connection data from Azure Portal on `W10-OnPrem`.
* Download and install the latest version of the Azure VPN Client install files using one of the following links: https://aka.ms/azvpnclientdownload
* open Azure VPN Client and click on (+) > import
* select azurevpnconfig.xml
* Authentication Type: `Certificate`
* Certificate Information: select `playground-client-certificate`
* Click SAVE
* Click CONNECT

Once connected, open a `remote desktop connection` app and connect to `10.13.1.4`
