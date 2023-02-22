// >Azure: Sign In

// Right Click > Deploy Bicep File ...

// targetScope =  'subscription' // Resource group must be deployed under 'subscription' scope

param location string = 'westus'
// param resourceGroupName string
param computerName string
param vmSize string = 'Standard_DS1_v2'
param adminUsername string = 'azureuser'
@secure()
param adminPasswordOrKey string
// param customData string
// param customDataFileLocation string

// resource rg 'Microsoft.Resources/resourceGroups@2022-09-01'= {
//   name: resourceGroupName
//   location: location
// }

module vm 'modules/linux-vm.bicep' = {
  name: 'linux-vm'
  // scope: rg
  

  params: {
    location: location
    computerName: computerName
    vmSize: vmSize
    adminUsername: adminUsername
    adminPasswordOrKey: adminPasswordOrKey
    // customData: customData

    //  Ref : https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-files#loadfileasbase64
    // TODO : Parameterize the cloud-init file location
    customData: loadFileAsBase64('cloud-init/nginx-hello-world.yml')

  }
}

// >Azure: Sign Out
