param filename string
param fileContents string
param fileShareName string
param location string
param storageAccountName string

@secure()
param storageAccountKey string

var name = 'deployscript-upload-file-${filename}'

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccountName
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccountKey
      }
      {
        name: 'CONTENT'
        value: fileContents
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${filename} && az storage file upload --source ${filename} -s ${fileShareName}'
  }
}
