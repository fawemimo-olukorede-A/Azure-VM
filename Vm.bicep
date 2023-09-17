@description('Username for the Virtual Machine.')

param adminUsername string
@minLength(12)
@secure()
param adminPassword string
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')
param publicIpName string = 'PublicIP'

// unique identifier to acces the vm
param publicIPAllocationMethod string = 'Dynamic'
param publicIpSku string = 'Basic'
param OSVersion string = '2022-datacenter-azure-edition-core'
// OS size 
param vmSize string = 'Standard_D2s_v5'

// using existing resources group
param location string = resourceGroup().location
//name of the vm
param vmName string = 'Myvm'

 var storageAccount = 'bootdiags${uniqueString(resourceGroup().id)}'
//network interface
var nicName = 'Nic'

var addressPrefix = '10.0.0.0/16'

var subnet = 'Subnet'

var subnetPrefix = '10.0.0.0/24'

var virtualNetwork = 'VNET'

var networkSecurityGroup = 'NSG'

 

resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {

  name: storageAccount

  location: location

  sku: {

    name: 'Standard_LRS'

  }

  kind: 'Storage'

}

 

resource pip 'Microsoft.Network/publicIPAddresses@2023-05-01' = {

  name: publicIpName

  location: location

  sku: {

    name: publicIpSku

  }

  properties: {

    publicIPAllocationMethod: publicIPAllocationMethod

    dnsSettings: {

      domainNameLabel: dnsLabelPrefix

    }

  }

}

 

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {

  name: networkSecurityGroup

  location: location

  properties: {

    securityRules: [

      {

        name: 'default-allow-3389'

        properties: {

          priority: 1000

          access: 'Allow'

          direction: 'Inbound'

          destinationPortRange: '3389'

          protocol: 'Tcp'

          sourcePortRange: '*'

          sourceAddressPrefix: '*'

          destinationAddressPrefix: '*'

        }

      }

    ]

  }

}

 

resource vn 'Microsoft.Network/virtualNetworks@2023-05-01' = {

  name: virtualNetwork

  location: location

  properties: {

    addressSpace: {

      addressPrefixes: [

        addressPrefix

      ]

    }

    subnets: [

      {

        name: subnet

        properties: {

          addressPrefix: subnetPrefix

          networkSecurityGroup: {

            id: securityGroup.id

          }

        }

      }

    ]

  }

}

 

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {

  name: nicName

  location: location

  properties: {

    ipConfigurations: [

      {

        name: 'ipconfig1'

        properties: {

          privateIPAllocationMethod: 'Dynamic'

          publicIPAddress: {

            id: pip.id

          }

          subnet: {

            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, subnet)

          }

        }

      }

    ]

  }

}

 

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {

  name: vmName

  location: location

  properties: {

    hardwareProfile: {

      vmSize: vmSize

    }

    osProfile: {

      computerName: vmName

      adminUsername: adminUsername

      adminPassword: adminPassword

    }

    storageProfile: {

      imageReference: {

        publisher: 'MicrosoftWindowsServer'

        offer: 'WindowsServer'

        sku: OSVersion

        version: 'latest'

      }

      osDisk: {

        createOption: 'FromImage'

        managedDisk: {

          storageAccountType: 'StandardSSD_LRS'

        }

      }

      dataDisks: [

        {

          diskSizeGB: 1023

          lun: 0

          createOption: 'Empty'

        }

      ]

    }

    networkProfile: {

      networkInterfaces: [

        {

          id: nic.id

        }

      ]

    }

    diagnosticsProfile: {

      bootDiagnostics: {

        enabled: true

        storageUri: stg.properties.primaryEndpoints.blob

      }

    }

  }

}

 

output hostname string = pip.properties.dnsSettings.fqdn
