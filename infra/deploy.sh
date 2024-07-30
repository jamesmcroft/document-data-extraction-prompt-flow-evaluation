#!/bin/bash

# Set the current directory to the directory of the script
pushd . >/dev/null
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null

source ../scripts/functions.sh

# The usage function to display script usage
usage() {
    echo "Usage: $0 [--deploymentName <deploymentName>] [--location <location>]" >&2
    echo "Options:" >&2
    echo "  --deploymentName <deploymentName>  The name of the Bicep deployment." >&2
    echo "  --location <location>              The location for the deployed resources." >&2
    exit 1
}

# The script parameters to setup the environment
declare -A params=(
    # The name of the Bicep deployment
    [deploymentName]="doc-extract-eval-pf"
    # The location for the deployed resources
    [location]="swedencentral"
)

parse_args params $@

# Install required tools
install_jq

# Check if mandatory parameters are set
if [ -z "$deploymentName" ] || [ -z "$location" ]; then
    usage
fi

echo "Starting infrastructure deployment..." >&2

az --version

userPrincipalId=$(az rest --method GET --uri "https://graph.microsoft.com/v1.0/me" | jq -r '.id')

deploymentOutputs=$(
    az deployment sub create --name $deploymentName --location $location --template-file './main.bicep' \
        --parameters './main.bicepparam' \
        --parameters workloadName=$deploymentName \
        --parameters location=$location \
        --parameters userPrincipalId=$userPrincipalId \
        --query properties.outputs -o json
)

echo "$deploymentOutputs" | jq '.' >'./InfrastructureOutputs.json'

echo "Infrastructure deployment completed." >&2

echo "$deploymentOutputs"

popd >/dev/null
