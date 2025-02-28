#!/bin/sh
set -e

# Set env get-values from azd
eval $(azd env get-values)

# Confirm the values
echo "Get values from azd"
echo "APPLICATION_INSIGHTS_CONNECTION_STRING: $APPLICATION_INSIGHTS_CONNECTION_STRING"
echo "AZURE_ENV_NAME: $AZURE_ENV_NAME"
echo "AZURE_LOCATION: $AZURE_LOCATION"
echo "AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
echo "AZURE_TENANT_ID: $AZURE_TENANT_ID"
echo "LARAVEL_APP_KEY: $LARAVEL_APP_KEY"
echo "CONTAINER_REGISTRY_NAME: $CONTAINER_REGISTRY_NAME"
echo "WEB_APP_NAME: $WEB_APP_NAME"

# Create a new environment variable by concatenating strings
AZURE_RESOURCE_GROUP="rg-${AZURE_ENV_NAME}"
echo "AZURE_RESOURCE_GROUP: $AZURE_RESOURCE_GROUP"

# Make sure az commands use the same subscription
az account set -s $AZURE_SUBSCRIPTION_ID

# Create ACR
az acr create --resource-group $AZURE_RESOURCE_GROUP --name $CONTAINER_REGISTRY_NAME --sku Basic

# Login to ACR
az acr login --name $CONTAINER_REGISTRY_NAME

printf "\nBuilding and uploading laravel image. Please wait..."
# Build the image Laravel Container
az acr build --resource-group $AZURE_RESOURCE_GROUP \
    --registry $CONTAINER_REGISTRY_NAME \
    --image laravel:latest \
    --file ./src/laravel/Dockerfile ./src/laravel


printf "\nBuilding and uploading otel-collector image. Please wait..."
# docker build -t $CONTAINER_REGISTRY_NAME.azurecr.io/otel-collector:latest -f ./src/opentelemetry/Dockerfile ./src/opentelemetry --build-arg APPLICATION_INSIGHTS_CONNECTION_STRING=$APPLICATION_INSIGHTS_CONNECTION_STRING
az acr build --resource-group $AZURE_RESOURCE_GROUP \
    --registry $CONTAINER_REGISTRY_NAME \
    --image otel-collector:latest \
    --file ./src/opentelemetry/Dockerfile ./src/opentelemetry
