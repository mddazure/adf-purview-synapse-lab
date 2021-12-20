param rgName string = 'adf-pvw-syn'
param location string = 'westeurope'

param adfVnetName string = 'adfVnet'
param adfVnet string = '10.1.0.0/16'
param adfShirSubnet string = '10.1.0.0/24'
param adfPeSubnet string = '10.1.1.0/24'
param adfBastionSubnet string = '10.1.2.0/24'
param adfShirName string = 'adfShir'
param adfTestVM string = 'adfTest'


param pvwVnetName string = 'pvwVnet'
param pvwVnet string = '10.2.0.0/16'
param pvwShirSubnet string = '10.2.0.0/24'
param pvwPeSubnet string = '10.2.1.0/24'
param pvwBastionSubnet string = '10.2.2.0/24'
param pvwShirName string = 'pvwShir'
param pvwTestVM string = 'pvwTest'

param synVnetName string = 'synVnet'
param synVnet string = '10.3.0.0/16'
param synShirSubnet string = '10.3.0.0/24'
param synPeSubnet string = '10.3.1.0/24'
param synBastionSubnet string = '10.3.2.0/24'
param synShirName string = 'synShir'
param synTestVM string = 'synTest'

param adminUsername string = 'AzureAdmin'

param adminPassword string = 'Adfpvwsyn-21'

param adfName string = 'adf-mdd'
param adfSource string = 'DefaultEndpointsProtocol=https;AccountName=adfsourcemdd;AccountKey=SOiupgQID03ipVUh0fPnf8iYstgTiCr1sGGrPSW0HFXwJJJkf5ULuj2MK6wPoQlGB/JoOeVJEKeEz4sHGSny+A=='
param adfDest string = 'DefaultEndpointsProtocol=https;AccountName=adfdestmdd;AccountKey=srGPFyUqVKaL6tOa7jrJUppGc13pmlBcjAm16u7JocJkqMf9OG7x4P4RkVm5zMbJ5D2PdmELy8C0HuT5l/lOXA=='

param pvwName string = 'pvw-mdd'

param synName string = 'syn-mdd'

targetScope = 'subscription'

resource dataVnetRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module adfMod 'shirVnets.bicep' = {
  name : 'adfMod'
  scope : dataVnetRg
  params : {
    location : location

    VnetName: adfVnetName
    Vnet : adfVnet
    ShirSubnet : adfShirSubnet
    PeSubnet : adfPeSubnet
    BastionSubnet : adfBastionSubnet

    ShirName: adfShirName
    TestName: adfTestVM
    AdminUserName: adminUsername
    AdminPassWord: adminPassword
  }
}

module pvwMod 'shirVnets.bicep' = {
  name : 'pvwMod'
  scope : dataVnetRg
  params : {
    location : location

    VnetName: pvwVnetName
    Vnet : pvwVnet
    ShirSubnet : pvwShirSubnet
    PeSubnet : pvwPeSubnet
    BastionSubnet : pvwBastionSubnet

    ShirName: pvwShirName
    TestName: pvwTestVM
    AdminUserName: adminUsername
    AdminPassWord: adminPassword
  }
}

module synMod 'shirVnets.bicep' = {
  name : 'synMod'
  scope : dataVnetRg
  params : {
    location : location

    VnetName: synVnetName
    Vnet : synVnet
    ShirSubnet : synShirSubnet
    PeSubnet : synPeSubnet
    BastionSubnet : synBastionSubnet

    ShirName: synShirName
    TestName: synTestVM
    AdminUserName: adminUsername
    AdminPassWord: adminPassword
  }
}

module dsMod 'dataServices.bicep' = {
  name : 'dsMod'
  scope : dataVnetRg

  params: {
    location : location

    AdfName: adfName
    AdfSource: adfSource
    AdfDest: adfDest
    AdfVnetId: adfMod.outputs.vnetId

    PvwName: pvwName
    PvwVnetId: pvwMod.outputs.vnetId

    SynName: synName
    SynVnetId: synMod.outputs.vnetId

  }
}


