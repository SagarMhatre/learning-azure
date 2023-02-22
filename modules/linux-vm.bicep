// Ref : https://community.ops.io/kaiwalter/create-a-disposable-linux-azure-vm-with-powershell-bicep-and-cloud-init-running-rootless-dockerd-and-containerd-47je

param location string = resourceGroup().location
param computerName string
param vmSize string = 'Standard_DS1_v2'

param adminUsername string = 'admin'
@secure()
param adminPasswordOrKey string
param customData string 

var authenticationType = 'password' // 'sshPublicKey' or 'password'
var vmImagePublisher = 'canonical'
var vmImageOffer = '0001-com-ubuntu-server-focal'
var vmImageSku = '20_04-lts-gen2'
var vnetAddressPrefix = '192.168.43.0/27'

var vmPublicIPAddressName = '${computerName}-ip'
var vmVnetName = '${computerName}-vnet'
var vmNsgName = '${computerName}-nsg'
var vmNicName = '${computerName}-nic'
var vmDiagnosticStorageAccountName = '${replace(computerName, '-', '')}${uniqueString(resourceGroup().id)}'

var shutdownTime = '2200'
var shutdownTimeZone = 'W. Europe Standard Time'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var resourceTags = {
  vmName: computerName
}

resource vmNsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: vmNsgName
  location: location
  tags: resourceTags
  properties: {
    securityRules: [
      {
        name: 'in-SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'in-HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmVnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vmVnetName
  location: location
  tags: resourceTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: 'vm'
  parent: vmVnet
  properties: {
    addressPrefix: vnetAddressPrefix
    networkSecurityGroup: {
      id: vmNsg.id
    }
  }
}

resource vmDiagnosticStorage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: vmDiagnosticStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  tags: resourceTags
  properties: {}
}

resource vmPublicIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: vmPublicIPAddressName
  location: location
  tags: resourceTags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    // dnsSettings: {
    //   domainNameLabel: computerName
    // }
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: vmNicName
  location: location
  tags: resourceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vmPublicIP.id
          }
          subnet: {
            id: vmSubnet.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: computerName
  location: location
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      customData: customData
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: vmDiagnosticStorage.properties.primaryEndpoints.blob
      }
    }
  }
}

resource vmShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${computerName}'
  location: location
  tags: resourceTags
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: shutdownTime
    }
    timeZoneId: shutdownTimeZone
    notificationSettings: {
      status: 'Disabled'
    }
    targetResourceId: vm.id
  }
}
