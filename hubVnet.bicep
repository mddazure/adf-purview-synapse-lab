param location string

param VnetName string
param Vnet string 
param VMSubnet string
param PeSubnet string 
param BastionSubnet string
param GatewaySubnet string

param AdfVnetId string
param PvwVnetId string
param SynVnetId string
param AdfVnetName string
param PvwVnetName string
param SynVnetName string

param AdfSourceId string
param AdfDestId string
param SynDataLakeId string

param AdminUserName string
param AdminPassWord string

var P2SRootcert = 'MIIC5zCCAc+gAwIBAgIQF5q+TGAQ+o9AueLqAuog+TANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMjA0MjgwNjU5NTBaFw0zMjA0MjgwNzA5MjlaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAw6+FZnttAU0BlaCS8OTSr9gyKv8q29f6bMBGO0l9BYLp1yzqNWCrcCbwQJkqjnqSc7bCX6n2o+nIes4eE1Gjy+Iyk4ctvW6/Xbcci0oY2selNXTdmjwkolUZr39eUsBIOVUsSQBPOPGyIGKnC6XANbwsyzZ5upMWzpE29Gm347M3lM5UngTdwqRINbLEkg43o5jjC6bdbyGuw0iQbiLkH89Ylu0Nf2yr8Ky6Q+nd0PshUpnuNUTVaRz0F+O4lwzyoYjbyJd6vFuW3aG7+nyDfK8ryYNeClUroGoC7q7GoLm11q2B75R/SC+3Ve3Wxlt0S4JkEEJRL9PxoZR0eF8qmQIDAQABozEwLzAOBgNVHQ8BAf8EBAMCAgQwHQYDVR0OBBYEFAJKjXSscdwzP9dsUzpsTBbt2/yUMA0GCSqGSIb3DQEBCwUAA4IBAQAiqUUENqBn4fF/nLEv7EstKX1JDWvbBpbMXSJZ8H/YdWAbCJlrdBeAtZ+ibjvEiEe8FNyekJ5yHs3MzKdXF84lcF/tzlDaftlSQmlza7Y+PS3JgOwFIfyw7iQzFwhG0YWDgV9cWlUj0ijPc2Q8nIrqOKlRiFPq6fmu1uajSvIrdI0HP+n3q7+bmYT8QrqWV66K/p1/2C5Q/eLS7Ew1/8MotOpTLn+qqtM9g0laC4bMU42rS7GByqJoxbvpg5mzH171Z1hB6oMwZsl358NFsNNGps6zoRVELvh0ykgbxerYfen4sedZPUQLLDnQZrBR7mZY2AOk13dUX5mhanfisWI2'
var vpnpool = '172.16.0.0/24'
var VMName = 'hubVM'

var imageId = '/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/image-gallery-rg/providers/Microsoft.Compute/galleries/mddimagegallery/images/windows2022-networktools/versions/2.0.0'
//var imagePublisher = 'MicrosoftWindowsServer'
//var imageOffer = 'WindowsServer'
//var imageSku = '2022-Datacenter'

//VNET
resource hubvnet 'Microsoft.Network/virtualNetworks@2021-05-01'={
name: VnetName
location:location
properties:{
  addressSpace:{
    addressPrefixes: [
      Vnet
    ]
  }
  subnets:[
    {
      name: 'vmsubnet'
      properties:{
        addressPrefix: VMSubnet
      }
    }
    {
      name: 'pesubnet'
      properties:{
        addressPrefix: PeSubnet
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }
    {
      name: 'AzureBastionSubnet'
      properties:{
        addressPrefix: BastionSubnet
      }
    }
    {
      name: 'GatewaySubnet'
      properties:{
        addressPrefix: GatewaySubnet
      }
    }
  ]
  dhcpOptions:{
    dnsServers:[
      '10.0.0.4'     
    ]
  }
  }
}
//PIP
resource gwpubip 'Microsoft.Network/publicIPAddresses@2021-05-01'={
  name:'gatewaypip'
  location: location
  sku:{
    name: 'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAllocationMethod: 'Static' 
    publicIPAddressVersion: 'IPv4'
  }
}
//PE
resource sourcepe 'Microsoft.Network/privateEndpoints@2021-05-01'= {
  name: 'sourcepe'
  location: location
  dependsOn:[
    hubvnet
  ]
  properties: {
    privateLinkServiceConnections:[
      {
        name: 'sourcepe'
        properties: {
          privateLinkServiceId: AdfSourceId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',VnetName,'pesubnet')
    }
  }
}

resource destpe 'Microsoft.Network/privateEndpoints@2021-05-01'= {
  name: 'destpe'
  location: location
  dependsOn:[
    hubvnet
  ]
  properties: {
    privateLinkServiceConnections:[
      {
        name: 'destpe'
        properties: {
          privateLinkServiceId: AdfDestId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',VnetName,'pesubnet')
    }
  }
}

resource adlspe 'Microsoft.Network/privateEndpoints@2021-05-01'= {
  name: 'adlspe'
  location: location
  dependsOn:[
    hubvnet
  ]
  properties: {
    privateLinkServiceConnections:[
      {
        name: 'adlspe'
        properties: {
          privateLinkServiceId: SynDataLakeId
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets',VnetName,'pesubnet')
    }
  }
}

//Gateway
resource vnetgateway 'Microsoft.Network/virtualNetworkGateways@2021-05-01'= {
  name: 'vnetgateway'
  location:location
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig1'
        properties:{
          privateIPAllocationMethod: 'Dynamic'
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',hubvnet.name,'GatewaySubnet')
          }
          publicIPAddress:{
            id: gwpubip.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    enableBgp: false
    enablePrivateIpAddress: true
    activeActive: false
    gatewayDefaultSite: null
    sku:{
      name: 'VpnGw1AZ'
      tier: 'VpnGw1AZ'
    }
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnpool
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'Certificate'
      ]
      vpnClientRootCertificates: [
        {
          name: 'P2SRoot'
          properties: {
            publicCertData: P2SRootcert
          }
        }
      ] 
    }
  }
}
//VM
resource nicdns 'Microsoft.Network/networkInterfaces@2021-05-01'={
  name: '${VMName}-nic'
  location: location
  properties:{
    ipConfigurations:[
      {
      name: 'ipconfig1'
      properties:{
        primary: true
        privateIPAllocationMethod: 'Static'
        privateIPAddress: '10.0.0.4'
        privateIPAddressVersion: 'IPv4'
        subnet:{
          id: resourceId('Microsoft.Network/virtualNetworks/subnets',hubvnet.name,'vmsubnet')
          }
        }
      }
    ]
  }
}
resource hubVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: VMName
  location: location
  properties:{
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile:{
      imageReference: {
        id: imageId
        //publisher: imagePublisher
        //offer: imageOffer
        //sku: imageSku
        //version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'      
        }
    }
    osProfile:{
        computerName: VMName
        adminUsername: AdminUserName
        adminPassword: AdminPassWord
        }
    networkProfile: {
      networkInterfaces: [
        {
        id: nicdns.id
        }
      ]
    }  
  }
}
resource ext 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: 'ext'
  parent: hubVM
  location: location
  properties:{
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    protectedSettings:{}
    settings: {
        commandToExecute: 'powershell -ExecutionPolicy Unrestricted Add-DnsServerForwarder -IPAddress 168.63.129.16 -PassThru; powershell -ExecutionPolicy Unrestricted Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername)'
    }
  }  
}


//Bastion
resource bastionPubip 'Microsoft.Network/publicIPAddresses@2021-03-01' ={
  name: '${VnetName}-bastionPubip'
  location: location
  sku:{
    name:'Standard'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}
resource hubBastion 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: '${VnetName}-Bastion'
  dependsOn:[
    hubvnet
  ]
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets','${VnetName}','AzureBastionSubnet')
          } 
          publicIPAddress: {
            id: bastionPubip.id
          }
        }
      }
    ]
  }
}
//vnet peers
resource hubadfpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01'={
  name:'hubadfpeer'
  parent:hubvnet
  dependsOn:[
    vnetgateway
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork:{
      id: AdfVnetId
    }
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}
resource adfhubpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01'={
  name:'${AdfVnetName}/adfhubpeer'
  dependsOn:[
    vnetgateway
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork:{
      id: hubvnet.id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
}
resource hubpvwpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01'={
  name:'hubpvwpeer'
  dependsOn:[
    vnetgateway
  ]
  parent:hubvnet
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork:{
      id: PvwVnetId
    }
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}
resource pvwhubpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01'={
  name:'${PvwVnetName}/pvwhubpeer'
  dependsOn:[
    vnetgateway
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork:{
      id: hubvnet.id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
}
resource hubsynpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01'={
  name:'hubsynpeer'
  dependsOn:[
    vnetgateway
  ]
  parent:hubvnet
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork:{
      id: SynVnetId
    }
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}
resource synhubpeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01'={
  name:'${SynVnetName}/synhubpeer'
  dependsOn:[
    vnetgateway
  ]
  properties:{
    peeringState: 'Connected'
    remoteVirtualNetwork:{
      id: hubvnet.id
    }
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
}
//DNS Zones & links
//Private DNS zones
resource storagednszone 'Microsoft.Network/privateDnsZones@2020-06-01' ={
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
  properties: {
  }
}
resource adlsdnszone 'Microsoft.Network/privateDnsZones@2020-06-01' ={
  name: 'privatelink.dfs.core.windows.net'
  location: 'global'
  properties: {
  }
}
resource sourcednszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01'={
  name: 'adfstoragednszonegroup'
  parent: sourcepe
  properties:{
    privateDnsZoneConfigs:[
      {
        name: 'privatelink-blob-core-windows-net'
        properties:{
          privateDnsZoneId: storagednszone.id
        }
      }
    ]
   }
}
resource destdnszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01'={
  name: 'adfstoragednszonegroup'
  parent: destpe
  properties:{
    privateDnsZoneConfigs:[
      {
        name: 'privatelink-blob-core-windows-net'
        properties:{
          privateDnsZoneId: storagednszone.id
        }
      }
    ]
   }
}
resource adlsdnszonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01'={
  name: 'adfstoragednszonegroup'
  parent: adlspe
  properties:{
    privateDnsZoneConfigs:[
      {
        name: 'privatelink-dfs-core-windows-net'
        properties:{
          privateDnsZoneId: adlsdnszone.id
        }
      }
    ]
   }
}
resource storagednslinkadf 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'storagednslink${AdfVnetName}'
  location: 'global'
  parent: storagednszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: AdfVnetId
    }
  }
}

resource adlsdnslinkadf 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'adlsdnslink${AdfVnetName}'
  location: 'global'
  parent: adlsdnszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: AdfVnetId
    }
  }
}
resource storagednslinkpvw 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'storagednslink${PvwVnetName}'
  location: 'global'
  parent: storagednszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: PvwVnetId
    }
  }
}

resource adlsdnslinkpvw 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'adlsdnslink${PvwVnetName}'
  location: 'global'
  parent: adlsdnszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: PvwVnetId
    }
  }
}
resource storagednslinksyn 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'storagednslink${SynVnetName}'
  location: 'global'
  parent: storagednszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: SynVnetId
    }
  }
}

resource adlsdnslinksyn 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'adlsdnslink${SynVnetName}'
  location: 'global'
  parent: adlsdnszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: SynVnetId
    }
  }
}
resource storagednslinkhub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'storagednslink${VnetName}'
  location: 'global'
  parent: storagednszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: hubvnet.id
    }
  }
}

resource adlsdnslinkhub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01'={
  name: 'adlsdnslink${VnetName}'
  location: 'global'
  parent: adlsdnszone
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: hubvnet.id
    }
  }
}

output vnetId string = hubvnet.id
