# Terminate the script if an error occurs
$ErrorActionPreference = "Stop"

# Set env get-values from azd
$envValues = azd env get-values | Out-String
$envValues -split "`n" | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$") {
        $name = $matches[1]
        $value = $matches[2].Trim('"')
        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

# Confirm the values
Write-Output "Get values from azd"
Write-Output "APPLICATION_INSIGHTS_CONNECTION_STRING: $env:APPLICATION_INSIGHTS_CONNECTION_STRING"
Write-Output "AZURE_ENV_NAME: $env:AZURE_ENV_NAME"
Write-Output "AZURE_LOCATION: $env:AZURE_LOCATION"
Write-Output "AZURE_SUBSCRIPTION_ID: $env:AZURE_SUBSCRIPTION_ID"
Write-Output "AZURE_TENANT_ID: $env:AZURE_TENANT_ID"
Write-Output "LARAVEL_APP_KEY: $env:LARAVEL_APP_KEY"
Write-Output "CONTAINER_REGISTRY_NAME: $env:CONTAINER_REGISTRY_NAME"

# Create a new environment variable by concatenating strings
$env:AZURE_RESOURCE_GROUP = "rg-$env:AZURE_ENV_NAME"
Write-Output "AZURE_RESOURCE_GROUP: $env:AZURE_RESOURCE_GROUP"

# Make sure az commands use the same subscription
az account set --subscription $env:AZURE_SUBSCRIPTION_ID

Write-Output "`nBuilding and uploading laravel image. Please wait..."
# Build the image Laravel Container
az acr build --resource-group $env:AZURE_RESOURCE_GROUP `
    --registry $env:CONTAINER_REGISTRY_NAME `
    --image laravel:latest `
    --file ./src/laravel/Dockerfile ./src/laravel

Write-Output "`nBuilding and uploading otel-collector image completed."
az acr build --resource-group $env:AZURE_RESOURCE_GROUP \
    --registry $env:CONTAINER_REGISTRY_NAME \
    --image otel-collector:latest \
    --file ./src/opentelemetry/Dockerfile ./src/opentelemetry
