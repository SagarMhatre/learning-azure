// >Azure: Sign In

// Right Click > Deploy Bicep File ...

@minLength(3)
@maxLength(24)
param storageName string

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'examplevnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

module storageService 'modules/storage.bicep' = {
  name: 'storageService'
  params: {
    storageName: storageName
    environmentType: environmentType
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: 'examplevnet'
  location: resourceGroup().location
  properties: {
    
  }
} 

// >Azure: Sign Out
