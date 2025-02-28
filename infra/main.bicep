targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

param logAnalyticsName string = ''
param applicationInsightsName string = ''
param applicationInsightsDashboardName string = ''

//Laravel App Key
param laravelAppKey string = ''

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })
#disable-next-line no-unused-vars
var apiServiceName = 'api'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Add resources to be provisioned below.
// A full example that leverages azd bicep modules can be seen in the todo-python-mongo template:
// https://github.com/Azure-Samples/todo-python-mongo/tree/main/infra

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// ACR with Managed Identity
module acrwithmi 'acr-mi.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    location: location
  }
}

module appserviceplan 'core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
  }
}

// module appservice 'core/host/appservice-w-sidecar.bicep' = {
//   name: 'appservice'
//   scope: rg
//   params: {
//     location: location
//     appServicePlanId: appserviceplan.outputs.id
//     applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
//     acrLoginServer: acrwithmi.outputs.ACR_NAME
//     webAppName: '${abbrs.webSitesAppService}${resourceToken}'
//     useUserAssignedManagedIdentity: true
//     managedIdentityName: acrwithmi.outputs.MI_NAME
//     appSettings: {
//       // For OpenTelemetry Collector  
//       OTEL_TRACES_EXPORTER: 'otlp'
//       OTEL_METRICS_EXPORTER: 'otlp'
//       OTEL_LOGS_EXPORTER: 'otlp'
//       OTEL_EXPORTER_OTLP_COMPRESSION: 'gzip'
//       OTEL_EXPORTER_OTLP_ENDPOINT: 'http://localhost:4318'
//       OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE: 'cumulative'
//       OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION: 'explicit_bucket_histogram'
//       OTEL_TRACES_SAMPLER: 'parentbased_traceidratio'
//       OTEL_TRACES_SAMPLER_ARG: 1
//       // For Laravel
//       APP_KEY: laravelAppKey
//       DB_LARAVEL_HOST:  psqldb.outputs.POSTGRES_DOMAIN_NAME
//       DB_LARAVEL_PORT: '5432'
//       DB_LARAVEL_NAME: 'laravel'
//       DB_LARAVEL_USER: 'postgresadmin'
//       DB_LARAVEL_PASS: 'password'
//       DB_LARAVEL_SSLMODE: 'disable'
//       OTEL_PHP_AUTOLOAD_ENABLED: true
//     }
//   }
// }

module psqldb 'core/database/postgresql/flexibleserver.bicep' = {
  name: 'psqldb'
  scope: rg
  params: {
    name: '${abbrs.dBforPostgreSQLServers}${resourceToken}'
    location: location
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
      capacity: 1
    }
    storage: {
      autoGrow: true
      storageSizeGB: 512
    }
    administratorLogin: 'postgresadmin'
    administratorLoginPassword: 'password'
    databaseNames: [
      'laravel'
    ]
    version: '13'
    allowAzureIPsFirewall: true
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output APPLICATION_INSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output CONTAINER_REGISTRY_NAME string = acrwithmi.outputs.ACR_NAME
// output WEB_APP_NAME string = appservice.outputs.name

