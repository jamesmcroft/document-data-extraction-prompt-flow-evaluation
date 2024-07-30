#!/bin/bash

# Set the current directory to the directory of the script
pushd . >/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null

source ../scripts/functions.sh

# The usage function to display script usage
usage() {
    echo "Usage: $0 [--subscriptionId <subscriptionId>] [--resourceGroupName <resourceGroupName>] [--aiHubProjectName <aiHubProjectName>] [--storageAccountName <storageAccountName>] [--documentImageContainerName <documentImageContainerName>] [--openAIServicesConnectionName <openAIServicesConnectionName>] [--modelDeploymentName <modelDeploymentName>] [--documentDataExtractionPromptFlowName <documentDataExtractionPromptFlowName>] [--documentDataExtractionEvalPromptFlowName <documentDataExtractionEvalPromptFlowName>]" >&2
    echo "Options:" >&2
    echo "  --subscriptionId <subscriptionId>                              The ID of the subscription to deploy the resources." >&2
    echo "  --resourceGroupName <resourceGroupName>                        The name of the resource group to deploy the resources." >&2
    echo "  --aiHubProjectName <aiHubProjectName>                          The name of the Azure AI Hub project." >&2
    echo "  --storageAccountName <storageAccountName>                      The name of the storage account where the document images are stored." >&2
    echo "  --documentImageContainerName <documentImageContainerName>      The name of the container in the storage account where the document images are stored." >&2
    echo "  --openAIServicesConnectionName <openAIServicesConnectionName>  The name of the Azure AI Hub connection to the Open AI Services." >&2
    echo "  --modelDeploymentName <modelDeploymentName>                    The name of the model deployment in the Azure AI Services." >&2
    echo "  --documentDataExtractionPromptFlowName <documentDataExtractionPromptFlowName>  The name of the Prompt Flow for data extraction." >&2
    echo "  --documentDataExtractionEvalPromptFlowName <documentDataExtractionEvalPromptFlowName>  The name of the Prompt Flow for data extraction evaluation." >&2
    exit 1
}

# The script parameters to setup the environment
declare -A params=(
    # The ID of the subscription to deploy the resources
    [subscriptionId]=""
    # The name of the resource group to deploy the resources
    [resourceGroupName]=""
    # The name of the Azure AI Hub project
    [aiHubProjectName]=""
    # The name of the storage account where the document images are stored
    [storageAccountName]=""
    # The name of the container in the storage account where the document images are stored
    [documentImageContainerName]=""
    # The name of the Azure AI Hub connection to the Open AI Services
    [openAIServicesConnectionName]=""
    # The name of the model deployment in the Azure AI Services
    [modelDeploymentName]=""
    # The name of the Prompt Flow for data extraction
    [documentDataExtractionPromptFlowName]=""
    # The name of the Prompt Flow for data extraction evaluation
    [documentDataExtractionEvalPromptFlowName]=""
)

parse_args params $@

# Install required tools
install_jq
install_yq
install_promptflow

# Check if mandatory parameters are set
if [ -z "$subscriptionId" ] || [ -z "$resourceGroupName" ] || [ -z "$aiHubProjectName" ] || [ -z "$storageAccountName" ] || [ -z "$documentImageContainerName" ] || [ -z "$openAIServicesConnectionName" ] || [ -z "$modelDeploymentName" ] || [ -z "$documentDataExtractionPromptFlowName" ] || [ -z "$documentDataExtractionEvalPromptFlowName" ]; then
    usage
fi

echo "Starting Prompt Flow deployment..." >&2

documentDataExtractionFlowFile="./document-data-extraction/flow.dag.yaml"

echo "Updating ${documentDataExtractionFlowFile} with connection and deployment names..." >&2
set_yaml_field "$documentDataExtractionFlowFile" "inputs.storage_account_name.default" $storageAccountName
set_yaml_field "$documentDataExtractionFlowFile" "inputs.blob_container_name.default" $documentImageContainerName
yq eval '(.nodes[] | select(.name == "extract_document_data") | .inputs.aoai_connection) = "'$openAIServicesConnectionName'"' -i $documentDataExtractionFlowFile
yq eval '(.nodes[] | select(.name == "extract_document_data") | .inputs.model_deployment) = "'$modelDeploymentName'"' -i $documentDataExtractionFlowFile

echo "Getting existing prompt flows in ${aiHubProjectName}..." >&2
existingPromptFlows=$(pfazure flow list --subscription $subscriptionId --resource-group $resourceGroupName --workspace-name $aiHubProjectName | jq -r '.[]')

echo "Checking if ${documentDataExtractionPromptFlowName} prompt flow exists in ${aiHubProjectName}..." >&2
dataExtractionFlowExists=$(echo $existingPromptFlows | jq -r "select(.display_name == \"$documentDataExtractionPromptFlowName\")")

if [ -n "$dataExtractionFlowExists" ]; then
    echo "${documentDataExtractionPromptFlowName} prompt flow already exists in ${aiHubProjectName}. Skipping deployment..." >&2
    dataExtractionFlowResult=$dataExtractionFlowExists
else
    echo "Creating ${documentDataExtractionPromptFlowName} prompt flow in ${aiHubProjectName}..." >&2
    dataExtractionFlowResult=$(pfazure flow create --flow "./document-data-extraction" --subscription "$subscriptionId" --resource-group "$resourceGroupName" --workspace-name "$aiHubProjectName" --set display_name="${documentDataExtractionPromptFlowName}" type="standard")
fi

echo "Checking if ${documentDataExtractionEvalPromptFlowName} prompt flow exists in ${aiHubProjectName}..." >&2
dataExtractionEvalFlowExists=$(echo $existingPromptFlows | jq -r "select(.display_name == \"$documentDataExtractionEvalPromptFlowName\")")

if [ -n "$dataExtractionEvalFlowExists" ]; then
    echo "${documentDataExtractionEvalPromptFlowName} prompt flow already exists in ${aiHubProjectName}. Skipping deployment..." >&2
    dataExtractionEvalFlowResult=$dataExtractionEvalFlowExists
else
    echo "Creating ${documentDataExtractionEvalPromptFlowName} prompt flow in ${aiHubProjectName}..." >&2
    dataExtractionEvalFlowResult=$(pfazure flow create --flow "./document-data-extraction-evaluation" --subscription "$subscriptionId" --resource-group "$resourceGroupName" --workspace-name "$aiHubProjectName" --set display_name="${documentDataExtractionEvalPromptFlowName}" type="evaluation")
fi

resultsOutputs=$(jq -n --argjson dataExtractionFlowResult "$dataExtractionFlowResult" --argjson dataExtractionEvalFlowResult "$dataExtractionEvalFlowResult" '{ dataExtractionFlowResult: $dataExtractionFlowResult, dataExtractionEvalFlowResult: $dataExtractionEvalFlowResult }')

echo "$resultsOutputs" | jq '.' >'./PromptFlowOutputs.json'

echo "Prompt Flow deployment completed." >&2

echo "$resultsOutputs"

popd >/dev/null
