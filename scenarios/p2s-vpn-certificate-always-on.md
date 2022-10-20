# SOLUTION: Configure a P2S VPN with Certificate Authentication and user tunnel Always-ON

This solution shows how to configure a P2S VPN to allow individual clients running Windows 10 to an Azure Virtual Network using **Azure certificate authentication** and **always On VPN user tunnel**. 

A new feature of the Windows 10 or later VPN client, Always On, is the ability to maintain a VPN connection. With Always On, the active VPN profile can connect automatically and remain connected based on triggers, such as user sign-in, network state change, or device screen active.

You can use gateways with Always On to establish persistent user tunnels and device tunnels to Azure.

Always On VPN connections include either of two types of tunnels:

* Device tunnel: Connects to specified VPN servers before users sign in to the device. Pre-sign-in connectivity scenarios and device management use a device tunnel.

* User tunnel: Connects only after users sign in to the device. By using user tunnels, you can access organization resources through VPN servers.

Device tunnels and user tunnels operate independent of their VPN profiles. They can be connected at the same time, and they can use different authentication methods and other VPN configuration settings, as appropriate.

More information on this procedure: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-always-on-user-tunnel 

## Pre-requisites

In order to apply this solution, you have to deploy [Configure a P2S VPN with Certificate Authentication solution](p2s-vpn-certificate.md) before.

## Solution
* Uninstall Azure client VPN, if you installed to test the pre-requisite solution.
* in point-to-site configuration change Tunnel type to `IKEv2`, the only supported protocol
* Copy the following text, and save it as usercert.ps1:

```
Param(
[string]$xmlFilePath,
[string]$ProfileName
)

$a = Test-Path $xmlFilePath
echo $a

$ProfileXML = Get-Content $xmlFilePath

echo $XML

$ProfileNameEscaped = $ProfileName -replace ' ', '%20'

$Version = 201606090004

$ProfileXML = $ProfileXML -replace '<', '&lt;'
$ProfileXML = $ProfileXML -replace '>', '&gt;'
$ProfileXML = $ProfileXML -replace '"', '&quot;'

$nodeCSPURI = './Vendor/MSFT/VPNv2'
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_VPNv2_01"

$session = New-CimSession

try
{
$newInstance = New-Object Microsoft.Management.Infrastructure.CimInstance $className, $namespaceName
$property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ParentID", "$nodeCSPURI", 'String', 'Key')
$newInstance.CimInstanceProperties.Add($property)
$property = [Microsoft.Management.Infrastructure.CimProperty]::Create("InstanceID", "$ProfileNameEscaped", 'String', 'Key')
$newInstance.CimInstanceProperties.Add($property)
$property = [Microsoft.Management.Infrastructure.CimProperty]::Create("ProfileXML", "$ProfileXML", 'String', 'Property')
$newInstance.CimInstanceProperties.Add($property)

$session.CreateInstance($namespaceName, $newInstance)
$Message = "Created $ProfileName profile."
Write-Host "$Message"
}
catch [Exception]
{
$Message = "Unable to create $ProfileName profile: $_"
Write-Host "$Message"
exit
}
$Message = "Complete."
Write-Host "$Message"
```

Copy the following text, and save it as `VPNProfile.xml` in the same folder as `usercert.ps1`. Edit the following text to match your environment:

* <Servers>azuregateway-1234-56-78dc.cloudapp.net</Servers> <= Can be found in the generic\VpnSettings.xml in the downloaded profile zip file
* <routes>: can e found in generic\VpnSettings.xml

```
<VPNProfile>  
   <NativeProfile>  
 <Servers>azuregateway-aa420069-de4b-479d-92ec-2976794df855-abdb6574d293.vpn.azure.com</Servers>  
 <NativeProtocolType>IKEv2</NativeProtocolType>  
 <Authentication>  
 <UserMethod>Eap</UserMethod>
 <Eap>
 <Configuration>
 <EapHostConfig xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapMethod><Type xmlns="http://www.microsoft.com/provisioning/EapCommon">13</Type><VendorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorId><VendorType xmlns="http://www.microsoft.com/provisioning/EapCommon">0</VendorType><AuthorId xmlns="http://www.microsoft.com/provisioning/EapCommon">0</AuthorId></EapMethod><Config xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><Eap xmlns="http://www.microsoft.com/provisioning/BaseEapConnectionPropertiesV1"><Type>13</Type><EapType xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV1"><CredentialsSource><CertificateStore><SimpleCertSelection>true</SimpleCertSelection></CertificateStore></CredentialsSource><ServerValidation><DisableUserPromptForServerValidation>false</DisableUserPromptForServerValidation><ServerNames></ServerNames></ServerValidation><DifferentUsername>false</DifferentUsername><PerformServerValidation xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</PerformServerValidation><AcceptServerName xmlns="http://www.microsoft.com/provisioning/EapTlsConnectionPropertiesV2">false</AcceptServerName></EapType></Eap></Config></EapHostConfig>
 </Configuration>
 </Eap>
 </Authentication>  
 <RoutingPolicyType>SplitTunnel</RoutingPolicyType>  
  <!-- disable the addition of a class based route for the assigned IP address on the VPN interface -->
 <DisableClassBasedDefaultRoute>true</DisableClassBasedDefaultRoute>  
   </NativeProfile> 
   <!-- use host routes(/32) to prevent routing conflicts -->  
<Route>  
<Address>10.12.0.0</Address>  
<PrefixSize>16</PrefixSize>  
  </Route>  
  <Route>  
<Address>10.13.2.0</Address>  
<PrefixSize>24</PrefixSize>  
  </Route>  
  <Route>  
<Address>10.13.3.0</Address>  
<PrefixSize>24</PrefixSize>  
  </Route>  
<Route>  
<Address>10.13.1.0</Address>  
<PrefixSize>24</PrefixSize>  
</Route>
 <!-- traffic filters for the routes specified above so that only this traffic can go over the device tunnel --> 
   <TrafficFilter>  
 <RemoteAddressRanges>192.168.3.4, 192.168.3.5</RemoteAddressRanges>  
   </TrafficFilter>
 <!-- need to specify always on = true --> 
 <AlwaysOn>true</AlwaysOn>
 <RememberCredentials>true</RememberCredentials>
 <!--new node to register client IP address in DNS to enable manage out -->
 <RegisterDNS>true</RegisterDNS>
 </VPNProfile>

```


* Run Powershell as Administrator
* In PowerShell, switch to the folder where `usercert.ps1` and `VPNProfile.xml` are located, and run the following command: `.\usercert.ps1 .\VPNProfile.xml UserAlwaysOn`

result:

```
AlwaysOn                :
ByPassForLocal          :
DeviceTunnel            :
DnsSuffix               :
EdpModeId               :
InstanceID              : UserAlwaysOn
LockDown                :
ParentID                : ./Vendor/MSFT/VPNv2
ProfileXML              :
RegisterDNS             :
RememberCredentials     :
TrustedNetworkDetection :
PSComputerName          :

Created UserTest profile.
Complete.

```


## Test Solution

* Under VPN Settings, look for the UserTest entry, and then select Connect.
* If the connection succeeds, you've successfully configured an Always On user tunnel.
* open a `remote desktop connection` app and connect to `10.13.1.4`
