@minLength(3)
@maxLength(24)
param storageName string

@allowed([
  'nonprod'
  'prod'
])
param environmentType string

var storageAccountSkuName = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'

resource exampleStorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageName
  location: resourceGroup().location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
}

