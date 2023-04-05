param rgName string = 'adf-pvw-syn-3'
param location string = 'westeurope'

param hubVnetName string = 'hubVnet'
param hubVnet string = '10.0.0.0/16'
param hubVMSubnet string = '10.0.0.0/24'
param hubPeSubnet string = '10.0.1.0/24'
param hubBastionSubnet string = '10.0.2.0/24'
param hubGatewaySubnet string = '10.0.255.0/24'

param onpremVnetName string = 'onpremVnet'
param onpremVnet string = '172.17.0.0/16'
param onpremVMSubnet string = '172.17.0.0/24'
param opremBastionSubnet string = '172.17.1.0/24'
param onpremGatewaySubnet string = '172.17.2.0/24'


param adfVnetName string = 'adfVnet'
param adfVnet string = '10.1.0.0/16'
param adfShirSubnet string = '10.1.0.0/24'
param adfPeSubnet string = '10.1.1.0/24'
param adfShirName string = 'adfShir'
param adfTestVM string = 'adfTest'


param pvwVnetName string = 'pvwVnet'
param pvwVnet string = '10.2.0.0/16'
param pvwShirSubnet string = '10.2.0.0/24'
param pvwPeSubnet string = '10.2.1.0/24'
param pvwShirName string = 'pvwShir'
param pvwTestVM string = 'pvwTest'

param synVnetName string = 'synVnet'
param synVnet string = '10.3.0.0/16'
param synShirSubnet string = '10.3.0.0/24'
param synPeSubnet string = '10.3.1.0/24'
param synShirName string = 'synShir'
param synTestVM string = 'synTest'

param adminUsername string = 'AzureAdmin'

param adminPassword string = 'Adfpvwsyn-21'

param adfName string = 'adf-mdd'
param adfSource string = 'DefaultEndpointsProtocol=https;AccountName=adfsourcemdd;AccountKey=SOiupgQID03ipVUh0fPnf8iYstgTiCr1sGGrPSW0HFXwJJJkf5ULuj2MK6wPoQlGB/JoOeVJEKeEz4sHGSny+A=='
param adfSourceId string ='/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/adf-pvw-syn-linkedservices/providers/Microsoft.Storage/storageAccounts/adfsourcemdd'
param adfDest string = 'DefaultEndpointsProtocol=https;AccountName=adfdestmdd;AccountKey=srGPFyUqVKaL6tOa7jrJUppGc13pmlBcjAm16u7JocJkqMf9OG7x4P4RkVm5zMbJ5D2PdmELy8C0HuT5l/lOXA=='
param adfDestId string = '/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/adf-pvw-syn-linkedservices/providers/Microsoft.Storage/storageAccounts/adfdestmdd'

param adfMgdVnetName string = 'adf-mdd-mgdvnet'

param pvwName string = 'pvw-mdd'

param synName string = 'syn-mdd'
param synDataLakeFile string = 'users'
param synDataLakeURL string = 'https://syndatalakemdd.dfs.core.windows.net'
param synDataLakeId string = '/subscriptions/0245be41-c89b-4b46-a3cc-a705c90cd1e8/resourceGroups/adf-pvw-syn-linkedservices/providers/Microsoft.Storage/storageAccounts/syndatalakemdd'

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

    ShirName: synShirName
    TestName: synTestVM
    AdminUserName: adminUsername
    AdminPassWord: adminPassword
  }
}

module hubMod 'hubVnet.bicep' ={
  name: 'hubMod'
  scope: dataVnetRg
  dependsOn:[
    adfMod
    pvwMod
    synMod
  ]
  params:{
    location: location

    VnetName: hubVnetName
    Vnet: hubVnet
    VMSubnet: hubVMSubnet
    PeSubnet: hubPeSubnet  
    BastionSubnet: hubBastionSubnet
    GatewaySubnet: hubGatewaySubnet

    OnpremVnetName: onpremVnetName
    OnpremVnet: onpremVnet
    OnpremVMSubnet: onpremVMSubnet
    OnpremBastionSubnet: opremBastionSubnet
    OnpremGatewaySubnet: onpremGatewaySubnet

    AdfVnetId: adfMod.outputs.vnetId
    PvwVnetId: pvwMod.outputs.vnetId
    SynVnetId: synMod.outputs.vnetId
    AdfVnetName: adfVnetName
    PvwVnetName: pvwVnetName
    SynVnetName: synVnetName

    AdfSourceId: adfSourceId
    AdfDestId: adfDestId
    SynDataLakeId: synDataLakeId
    
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
    PlsId: hubMod.outputs.plsId

    AdfMgdVnetName: adfMgdVnetName

    PvwName: pvwName
    PvwVnetId: pvwMod.outputs.vnetId

    SynName: synName
    SynVnetId: synMod.outputs.vnetId


    SynDataLakeFile: synDataLakeFile
    SynDataLakeURL: synDataLakeURL
    SynDataLakeId: synDataLakeId 


  }
}


