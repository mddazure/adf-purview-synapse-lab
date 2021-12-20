param location string

param VnetName string
param Vnet string
param ShirSubnet string
param PeSubnet string
param BastionSubnet string

param ShirName string
param TestName string
param AdminUserName string
param AdminPassWord string

//var imagePublisher = 'MicrosoftWindowsServer'
//var imageOffer = 'WindowsServer'
//var imageSku = '2022-Datacenter'
var imageId = '/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/image-gallery-rg/providers/Microsoft.Compute/galleries/mddimagegallery/images/windows2022-networktools/versions/2.0.0'

//VNET
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: VnetName
  location: location
  properties:{
    addressSpace:{
      addressPrefixes: [
        Vnet
      ]
    }
    subnets:[
      {
        name: 'shirsubnet'
        properties:{
          addressPrefix: ShirSubnet
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
    ]
  }
}


//SHIR
resource shir  'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: ShirName
  location: location
  dependsOn:[
    nicShir
  ]
  properties: {
    hardwareProfile:{
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile:  {
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
        computerName: ShirName
        adminUsername: AdminUserName
        adminPassword: AdminPassWord
      }
      networkProfile: {
        networkInterfaces: [
        {
          id: nicShir.id
        }
      ]
    }
  }
}
resource nicShir 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${ShirName}-nic'
  location: location
  dependsOn:[
    vnet
  ]
  properties:{
    ipConfigurations: [
      {
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',VnetName,'shirsubnet')
          }
        }
      }
    ]
  }
}
//TestVM
resource testVM  'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: TestName
  location: location
  dependsOn:[
    nicTestVM
  ]
  properties: {
    hardwareProfile:{
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile:  {
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
        computerName: TestName
        adminUsername: AdminUserName
        adminPassword: AdminPassWord
      }
      networkProfile: {
        networkInterfaces: [
        {
          id: nicTestVM.id
        }
      ]
    }
  }
}
resource nicTestVM 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: '${TestName}-nic'
  location: location
  dependsOn:[
    vnet
  ]
  properties:{
    ipConfigurations: [
      {
        name: 'ipv4config0'
        properties:{
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets',VnetName,'shirsubnet')
          }
        }
      }
    ]
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
    vnet
    bastionPubip
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



output vnetId string = vnet.id
