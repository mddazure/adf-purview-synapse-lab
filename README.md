# Adf-Purview-Synapse Lab

A lab environment for network experimentation with Azure Data Factory, Purview and Synapse.

![image](images/adf-pvw-syn-lab.png)

## Deployment
Log in to Azure Cloud Shell at https://shell.azure.com/ and select Bash.

Ensure Azure CLI and extensions are up to date:
  
`az upgrade --yes`
  
If necessary select your target subscription:
  
`az account set --subscription <Name or ID of subscription>`
  
Clone the  GitHub repository:
  
`git clone https://github.com/mddazure/adf-purview-synapse-lab`
  
Change directory:
  
`cd ./adf-purview-synapse-lab`

Deploy the bicep template:

`az deployment sub create --name lab --location westeurope --template-file main.bicep`


## Components

All components are deployed in a single Resource Group named *adf-pvw-syn*.

The lab assumes that the RG *adf-pvw-syn-linkedservices*, with storage accounts as shown, is already in place.

### VNETs with Self-hosted runtime VMs
The template deploys VNETs containing the adfShir, pvwShir and synShir VMs respectively. 

The VMs are created from an image that already contains the Self-hosted Integration Runtime executable. The image is stored in an Image Gallery which cannot be shared generally; please contact me if you want to use this image. Alternatively, modify the shirVnets.bicep and hubVnet.bicep template files to use a standard Marketplace image and install the [Self-hosted Integration Runtime](https://www.microsoft.com/en-us/download/details.aspx?id=39717) manually.

Each of the Shir VMs needs to be configured to connect to its respective service, per the documentation for [ADF](https://docs.microsoft.com/en-us/azure/data-factory/create-self-hosted-integration-runtime?tabs=data-factory#create-a-self-hosted-ir-via-ui), [Purview](https://docs.microsoft.com/en-us/azure/purview/manage-integration-runtimes) and [Synapse]().

VM Credentials:

adminUsername = AzureAdmin

adminPassword = Adfpvwsyn-21

### Hub VNET
The Hub VNET is peered with each of the Shir VNETs. It contains a central Bastion instance, a VM (credentials above) and a VNET Gateway with P2S configuration.

The Hub VNET contains Private Endpoints connected to the blob storage and data lake accounts. Private DNS zones contain A records for the PEs and are linked to the Hub VNET and the Shir VNETs. 

### Data services
The template creates ADF, Purview and Synapse accounts. Public Network Access is set to Enabled, so that the Studio portal of each is publically accessible.

The template provisions Self-hosted Integration Runtimes in the ADF and Synapse accounts. Purview does not have the capability to provision Self-hosted Integration Runtimes via code.

The ADF account has Linked Services to the storage accounts in the *adf-pvw-syn-linkedservices* RG, the Synapse account has a Default Data Lake Storage link to the data lake account.







