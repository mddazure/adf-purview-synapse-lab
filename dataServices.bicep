param location string

param AdfName string
param AdfSource string
param AdfDest string
param AdfVnetId string 

param PvwName string
param PvwVnetId string

param SynName string
param SynVnetId string
param SynDataLakeFile string
param SynDataLakeURL string 
param SynDataLakeId string


resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: AdfName
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource adfshir 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${AdfName}-shir'
  parent: adf
  dependsOn: [
    adf
  ]
  properties: {
    type: 'SelfHosted'
  } 
}

resource adfls_source 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${AdfName}-ls-source'
  parent: adf
  dependsOn:[
    adf
  ]
  properties:{

    type: 'AzureBlobStorage'
    typeProperties:{
      connectionString: AdfSource
          }    
      }
}

resource adfls_dest 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${AdfName}-ls-dest'
  parent: adf
  dependsOn:[
    adf
  ]
  properties:{

    type: 'AzureBlobStorage'
    typeProperties:{
      connectionString: AdfDest
          }    
      }
}
resource pvw 'Microsoft.Purview/accounts@2021-07-01' = {
  name: PvwName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    publicNetworkAccess: 'Enabled'
    managedResourceGroupName: '${PvwName}-managed'
  }
}
resource syn 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: SynName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    defaultDataLakeStorage:{
      resourceId: SynDataLakeId
      accountUrl: SynDataLakeURL
      filesystem: SynDataLakeFile
    }
    managedResourceGroupName: '${SynName}-managed'
    publicNetworkAccess: 'Enabled'
  }
}
resource synShir 'Microsoft.Synapse/workspaces/integrationRuntimes@2021-06-01' = {
  name: '${SynName}-shir'
  parent: syn
  dependsOn: [
    syn
  ]
  properties: {
    type: 'SelfHosted'
  } 
}
