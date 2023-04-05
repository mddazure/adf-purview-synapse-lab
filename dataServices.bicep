param location string

param AdfName string
param AdfSource string
param AdfDest string
param AdfVnetId string 
param PlsId string

param AdfMgdVnetName string

param PvwName string
param PvwVnetId string

param SynName string
param SynVnetId string
param SynDataLakeFile string
param SynDataLakeURL string 
param SynDataLakeId string

// df customer owned vnet with shir 
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

resource mgdvnetdefault 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: 'default'
  parent: adf
  properties: {}
}


resource mgdpe 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01'= {
  name: '${AdfMgdVnetName}-mgdpe'
  parent: mgdvnetdefault
  properties: {
    connectionState: {}
    privateLinkResourceId: PlsId
    groupId: ''
    fqdns: ['mgdpe.dedroog.net']
  }
}


resource adfmgdir 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${AdfMgdVnetName}-mgdir'
  parent: adf
  properties: {
    description: 'Managed IR'
    type: 'Managed'
    managedVirtualNetwork: {
      referenceName: mgdvnetdefault.name
      type: 'ManagedVirtualNetworkReference'
    }
    typeProperties:{
      computeProperties:{
        copyComputeScaleProperties:{
          dataIntegrationUnit: 4
          timeToLive: 10
        }
        dataFlowProperties:{

        }
        location: location
        nodeSize: 'Standard_DS2_v2'
      }
    }
    // For remaining properties, see IntegrationRuntime objects
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
    managedVirtualNetwork: 'default'
    managedVirtualNetworkSettings: {}
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
