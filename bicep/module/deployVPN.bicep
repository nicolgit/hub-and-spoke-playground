@description('The name of the VPN Gateway')
param gatewayName string

@description('The location for the resources')
param location string

@description('The name of the virtual network')
param vnetName string

@description('The name of the gateway subnet')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Whether to deploy the VPN Gateway')
param deployGateway bool

@description('Configure Point-to-site VPN for authenticated users in the subscription tenant when the VPN Gateway is deployed')
param configureP2sVpn bool = false

@description('Whether to enable BGP')
param enableBgp bool = false

@description('BGP ASN number (optional - used when BGP is enabled)')
param bgpAsn int = 65515

var gatewayIPName = '${gatewayName}-ip'

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = if (deployGateway) {
  name: gatewayIPName
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource vnetGateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = if (deployGateway) {
  name: gatewayName
  location: location
  properties: {
    ipConfigurations: [ {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, gatewaySubnetName) }
          publicIPAddress: { id: vnetGatewayIP.id }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnClientConfiguration: configureP2sVpn ? {
      vpnClientAddressPool: {
        addressPrefixes: ['172.20.0.0/24']
      }
      vpnClientProtocols: ['OpenVPN']
      vpnAuthenticationTypes: ['AAD']
      aadTenant: '${environment().authentication.loginEndpoint}${tenant().tenantId}'
      aadAudience: 'c632b3df-fb67-4d84-bdcf-b95ad541b5c8'
      aadIssuer: 'https://sts.windows.net/${tenant().tenantId}/'
    } : null
    enableBgp: enableBgp
    bgpSettings: enableBgp ? {
      asn: bgpAsn
    } : null
    sku: { name: 'VpnGw1AZ', tier: 'VpnGw1AZ' }
  }
}

output gatewayId string = deployGateway ? vnetGateway.id : ''
output gatewayIPId string = deployGateway ? vnetGatewayIP.id : ''
output gatewayName string = deployGateway ? vnetGateway.name : ''
