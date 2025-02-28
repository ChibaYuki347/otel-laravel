@description('Web app name.')
@minLength(2)
param webAppName string

@description('Location for all resources.')
param location string = resourceGroup().location

// Reference Properties
param appServicePlanId string

@description('use default image for sidecar')
param useDefaultImageForSidecar bool = true

@description('ACR Login Server for the container image.')
param acrLoginServer string

@description('Main container image tag.')
param mainImageTag string = 'laravel:latest'

@description('otelcollector container image tag.')
param otelcollectorImageSource string = 'opentelemetry:latest'

@description('OpenTelemetry Collector container port.')
param otelcollectorPort string = '4317'

// Microsoft.Web/sites/config
@secure()
param appSettings object = {}

// Application Insights
@description('Application Insights name.')
param applicationInsightsName string = ''

// Define using Managed Identity or not
@description('Use Managed Identity for ACR')
param useUserAssignedManagedIdentity bool = false

// Managed Identity ID
@description('Managed Identity ID')
param managedIdentityId string = ''

// Ref to exsiting Managed Identity
@description('Managed Identity name')
param managedIdentityName string = ''




resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'sitecontainers'
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
    }
  }
  identity: {
    type: useUserAssignedManagedIdentity ? 'UserAssigned' : 'SystemAssigned'
    userAssignedIdentities: useUserAssignedManagedIdentity ?  {
      'subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${managedIdentityName}': {}
} : {}
  }
}

// Updates to the single Microsoft.sites/web/config resources that need to be performed sequentially
// sites/web/config 'appsettings'
module configAppSettings 'appservice-appsettings.bicep' = {
  name: '${webAppName}-appSettings'
  params: {
    name: webApp.name
    appSettings: union(appSettings,
      !empty(applicationInsightsName) ? { APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString } : {})
  }
}

resource laravelcontainer 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: webApp
  name: 'laravelcontainer'
  properties: {
    image: useDefaultImageForSidecar ? '${acrLoginServer}/${mainImageTag}' : ''
    targetPort: '80'
    isMain: true
    authType: useUserAssignedManagedIdentity ? 'UserAssigned' : 'Anonymous'
    userManagedIdentityClientId: useUserAssignedManagedIdentity ? managedIdentityId: ''
  }
}

resource otelcollector_sidecar 'Microsoft.Web/sites/sitecontainers@2024-04-01' = {
  parent: webApp
  name: 'sidecarotelcollector'
  properties: {
    image: '${acrLoginServer}/${otelcollectorImageSource}'
    targetPort: otelcollectorPort
    isMain: false
    authType: useUserAssignedManagedIdentity ? 'UserAssigned' : 'Anonymous'
    userManagedIdentityClientId: useUserAssignedManagedIdentity ? managedIdentityId : ''
    startUpCommand: ''
    environmentVariables: []
    volumeMounts: []
  }
}

// sites/web/config 'logs'
resource configLogs 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'logs'
  parent: webApp
  properties: {
    applicationLogs: { fileSystem: { level: 'Verbose' } }
    detailedErrorMessages: { enabled: true }
    failedRequestsTracing: { enabled: true }
    httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
  }
  dependsOn: [configAppSettings]
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!empty(applicationInsightsName)) {
  name: applicationInsightsName
}

output identityPrincipalId string = useUserAssignedManagedIdentity ? '' : webApp.identity.principalId
output name string = webApp.name
output uri string = 'https://${webApp.properties.defaultHostName}'
