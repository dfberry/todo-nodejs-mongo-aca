targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('The image name for the api service')
param apiImageName string = ''

@description('The image name for the web service')
param webImageName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    principalId: principalId
    apiImageName: apiImageName
    webImageName: webImageName
  }
}

output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.applicationInsightsConnectionString
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.containerRegistryEndpoint
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.containerRegistryName
output AZURE_COSMOS_CONNECTION_STRING_KEY string = resources.outputs.cosmosConnectionStringKey
output AZURE_COSMOS_DATABASE_NAME string = resources.outputs.cosmosDatabaseName
output AZURE_KEY_VAULT_ENDPOINT string = resources.outputs.keyVaultEndpoint
output REACT_APP_API_BASE_URL string = resources.outputs.apiUri
output REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.applicationInsightsConnectionString
output REACT_APP_WEB_BASE_URL string = resources.outputs.webUri
