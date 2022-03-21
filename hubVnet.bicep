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

var P2SRootcert = 'MIIC5zCCAc+gAwIBAgIQZztZYHmjtL5NxRSFqeFj8TANBgkqhkiG9w0BAQsFADAWMRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMTA0MDMxMzEzNDhaFw0yMjA0MDMxMzMzNDhaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsrCNfBxfFd3zwEwkUsiQI++7vawcjlgGlRSWxgETkwxWHN/PMz9yZy6mPe2+3x+/fuqOVUCt0tKi0KjBT5LsMKEGby23m6RbRJ9FV8Hvkx2TY7q0e+6jFRDbNB+Vosx7ta+Rx/IytJ8GEJTq0KHht36XivgtO/HnsLYS0wcUidD9yo4aYzTGiq6x/Ir9Xn9mkJYnb6t8MDpN9HU22XX9YbINo/WDt8pVKF7oILkeJ81UJbpRHGEaEKrdvp0fA0zqyE/IErUzKK8wdJp8XQeOChwWAkJYLk41iN5xKIyNB/QkSjeZwerP7ZlsEoYc604q16ms4UYktKqzISn+M2RhxQIDAQABozEwLzAOBgNVHQ8BAf8EBAMCAgQwHQYDVR0OBBYEFIzIo1ejScaSuToAEVq7WertaUfqMA0GCSqGSIb3DQEBCwUAA4IBAQCyF/PaJGECjqzuIpAUkOpHkogkM8zLapOThwkpT7VXnO0EL0G+6FDimGJjMN3oo9bzwdBEMzz+1fIIg+OfTGwERvq3wqybc/81HqMnvFb+nR1hTFT8yh025HJMlT06VZ0dhgIRpGor0exWomeZINdUvkKWTUchIam813hM7LEHhvWXVk//7hrOjeD8k+KbGaujOEY4+jLUhvXnXrlzZTRNrA3glQuhm7Gf5zllKDeqIGmn3LG6OZ9OsDSB9zkP6a5bOP6HaqE7i4TQxlidE7+LiY8YN5VLorHUTER4xivUDUoLAOOe+NC0ov+7QApAibH5AKgoN4SGt5wF9ZtcpdkK'
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
