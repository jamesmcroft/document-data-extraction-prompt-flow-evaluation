#!/bin/bash

source ./scripts/functions.sh

# The usage function to display script usage
usage() {
    echo "Usage: $0 [--deploymentName <deploymentName>] [--location <location>] [--skipInfrastructure]" >&2
    echo "Options:" >&2
    echo "  --deploymentName <deploymentName>  The name of the Bicep deployment." >&2
    echo "  --location <location>              The location for the deployed resources." >&2
    echo "  --skipInfrastructure               Skip the infrastructure deployment. Requires InfrastructureOutputs.json to exist in the infra directory." >&2
    exit 1
}

# The script parameters to setup the environment
declare -A params=(
    # The name of the Bicep deployment
    [deploymentName]="doc-extract-eval-pf"
    # The location for the deployed resources
    [location]="swedencentral"
    # Whether to skip the infrastructure deployment. Requires InfrastructureOutputs.json to exist in the infra directory.
    [skipInfrastructure]=0
)

parse_args params $@

# Install required tools
install_jq

# Check if mandatory parameters are set
if [ -z "$deploymentName" ] || [ -z "$location" ]; then
    usage
fi

echo "Starting environment setup..." >&2

if [ $skipInfrastructure -eq 0 ] || [ ! -f ./infra/InfrastructureOutputs.json ]; then
    echo "Deploying infrastructure..." >&2
    ./infra/deploy.sh --deploymentName $deploymentName --location $location
else
    echo "Skipping infrastructure deployment. Using existing outputs..." >&2
fi

infrastructureOutputs=$(cat ./infra/InfrastructureOutputs.json | jq '.')

promptFlowOutputs=$(./promptflow/deploy.sh \
    --subscriptionId $(echo $infrastructureOutputs | jq -r '.subscriptionInfo.value.id') \
    --resourceGroupName $(echo $infrastructureOutputs | jq -r '.resourceGroupInfo.value.name') \
    --aiHubProjectName $(echo $infrastructureOutputs | jq -r '.aiHubProjectInfo.value.name') \
    --storageAccountName $(echo $infrastructureOutputs | jq -r '.storageAccountInfo.value.name') \
    --documentImageContainerName $(echo $infrastructureOutputs | jq -r '.storageAccountInfo.value.documentImageContainerName') \
    --openAIServicesConnectionName $(echo $infrastructureOutputs | jq -r '.aiHubInfo.value.openAIServicesConnectionName') \
    --modelDeploymentName $(echo $infrastructureOutputs | jq -r '.aiServicesInfo.value.modelDeploymentName') \
    --documentDataExtractionPromptFlowName 'data-extraction' \
    --documentDataExtractionEvalPromptFlowName 'data-extraction-eval')

outputs="{ \"infrastructureOutputs\": $infrastructureOutputs, \"promptFlowOutputs\": $promptFlowOutputs }"

echo "$outputs" | jq '.' >'./EnvironmentOutputs.json'

echo "Environment setup finished." >&2

echo "$outputs"
