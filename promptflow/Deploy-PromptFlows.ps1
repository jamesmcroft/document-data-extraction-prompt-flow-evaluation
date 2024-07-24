<#
.SYNOPSIS
    Deploys the prompt flows required for the AI Document Data Extraction Evaluation to an Azure AI Hub project.
.DESCRIPTION
    This script deploys a standard prompt flow containing the document data extraction task and an evaluation prompt flow to an Azure AI Hub project.
    The script will check if the prompt flows already exist in the AI Hub project and create them if they do not.
.EXAMPLE
    .\Deploy-PromptFlows.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -ResourceGroup "rg-ai-doc-eval" -AIHubProjectName "ai-doc-eval" -StorageAccountName "aidocevalstorage" -DocumentImageContainerName "document-images" -OpenAIServicesConnectionName "openai-connection" -ModelDeploymentName "gpt-4o" -DocumentDataExtractionPromptFlowName "document-data-extraction" -DocumentDataExtractionEvalPromptFlowName "document-data-extraction-evaluation"
.NOTES
    Author: James Croft
#>

param
(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,
    [Parameter(Mandatory = $true)]
    [string]$AIHubProjectName,
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    [Parameter(Mandatory = $true)]
    [string]$DocumentImageContainerName,
    [Parameter(Mandatory = $true)]
    [string]$OpenAIServicesConnectionName,
    [Parameter(Mandatory = $true)]
    [string]$ModelDeploymentName,
    [Parameter(Mandatory = $true)]
    [string]$DocumentDataExtractionPromptFlowName,
    [Parameter(Mandatory = $true)]
    [string]$DocumentDataExtractionEvalPromptFlowName
)

Write-Host "Starting prompt flow deployment..."

Push-Location -Path $PSScriptRoot

# Check if pf or pfazure commands are available
Write-Host "Checking for required CLI tools..."

if (-not (Get-Command pf -ErrorAction SilentlyContinue)) {
    Write-Host "Prompt Flow CLI not found. Installing..."
    pip install promptflow --upgrade
}

if (-not (Get-Command pfazure -ErrorAction SilentlyContinue)) {
    Write-Host "Prompt Flow Azure CLI not found. Installing..."
    pip install promptflow[azure] --upgrade
}

if (-not (Get-Module -Name powershell-yaml -ErrorAction SilentlyContinue)) {
    Write-Host "powershell-yaml module not found. Installing..."
    Install-Module -Name powershell-yaml
}

Import-Module powershell-yaml

function Get-Yaml {
    param (
        [string]$Path
    )

    [string[]]$fileContent = Get-Content $Path
    $content = ''
    foreach ($line in $fileContent) { $content = $content + "`n" + $line }
    $yml = ConvertFrom-YAML $content
    Write-Output $yml
}

function Set-Yaml {
    param (
        [string]$Path,
        [object]$Content
    )

    $result = ConvertTo-YAML $Content
    Set-Content -Path $Path -Value $result
}

az --version

# Update the document data extraction prompt flow with default values from the deployment
Write-Host "Updating ./document-data-extraction/flow.dag.yaml with connection and deployment names..."

$promptFlowYaml = Get-Yaml -Path "./document-data-extraction/flow.dag.yaml"
$promptFlowYaml.inputs.storage_account_name.default = $StorageAccountName
$promptFlowYaml.inputs.blob_container_name.default = $DocumentImageContainerName
$promptFlowYaml.nodes | ForEach-Object {
    if ($_.name -eq 'extract_document_data') {
        $_.inputs.aoai_connection = $OpenAIServicesConnectionName
        $_.inputs.model_deployment = $ModelDeploymentName
    }
}
Set-Yaml -Path "./document-data-extraction/flow.dag.yaml" -Content $promptFlowYaml
    
# Deploy the prompt flows
Write-Host "Getting existing flows in ${AIHubProjectName}..."

$ExistingFlows = (pfazure flow list --subscription $SubscriptionId --resource-group $ResourceGroup --workspace-name $AIHubProjectName) | ConvertFrom-Json

Write-Host "Checking if ${DocumentDataExtractionPromptFlowName} flow exists in ${AIHubProjectName}..."

$DataExtractionFlowExists = $ExistingFlows | Where-Object { $_.display_name -eq $DocumentDataExtractionPromptFlowName }
if ($DataExtractionFlowExists) {
    Write-Host "${DocumentDataExtractionPromptFlowName} flow already exists in ${AIHubProjectName}. Skipping deployment..."
}
else {
    Write-Host "Creating ${DocumentDataExtractionPromptFlowName} flow..."
    $DataExtractionFlowResult = (pfazure flow create --flow "./document-data-extraction" --subscription $SubscriptionId --resource-group $ResourceGroup --workspace-name $AIHubProjectName --set display_name="${DocumentDataExtractionPromptFlowName}" type="standard")
}

Write-Host "Checking if ${DocumentDataExtractionEvalPromptFlowName} flow exists in ${AIHubProjectName}..."
$DataExtractionEvalFlowExists = $ExistingFlows | Where-Object { $_.display_name -eq $DocumentDataExtractionEvalPromptFlowName }
if ($DataExtractionEvalFlowExists) {
    Write-Host "${DocumentDataExtractionEvalPromptFlowName} flow already exists in ${AIHubProjectName}. Skipping deployment..."
}
else {
    Write-Host "Creating ${DocumentDataExtractionEvalPromptFlowName} flow..."
    $DataExtractionEvalFlowResult = (pfazure flow create --flow "./document-data-extraction-evaluation" --subscription $SubscriptionId --resource-group $ResourceGroup --workspace-name $AIHubProjectName --set display_name="${DocumentDataExtractionEvalPromptFlowName}" type="evaluation")
}

$ResultOutputs = @{
    DataExtractionFlowResult     = $DataExtractionFlowResult
    DataExtractionEvalFlowResult = $DataExtractionEvalFlowResult
}
$ResultOutputs | ConvertTo-Json | Out-File -FilePath './PromptFlowOutputs.json' -Encoding utf8

Pop-Location

return $ResultOutputs