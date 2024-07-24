<#
.SYNOPSIS
    Deploys the infrastructure and applications required to run the solution.
.PARAMETER DeploymentName
	The name of the deployment.
.PARAMETER Location
    The location of the deployment.
.PARAMETER SkipInfrastructure
    Whether to skip the infrastructure deployment. Requires InfrastructureOutputs.json to exist in the infra directory.
.EXAMPLE
    .\Setup-Environment.ps1 -DeploymentName 'my-deployment' -Location 'swedencentral' -SkipInfrastructure $false
.NOTES
    Author: James Croft
#>

param
(
    [Parameter(Mandatory = $true)]
    [string]$DeploymentName,
    [Parameter(Mandatory = $true)]
    [string]$Location,
    [Parameter(Mandatory = $true)]
    [string]$SkipInfrastructure
)

Write-Host "Starting environment setup..."

if ($SkipInfrastructure -eq '$false' -or -not (Test-Path -Path './infra/InfrastructureOutputs.json')) {
    Write-Host "Deploying infrastructure..."
    $InfrastructureOutputs = (./infra/Deploy-Infrastructure.ps1 `
            -DeploymentName $DeploymentName `
            -Location $Location)
}
else {
    Write-Host "Skipping infrastructure deployment. Using existing outputs..."
    $InfrastructureOutputs = Get-Content -Path './infra/InfrastructureOutputs.json' -Raw | ConvertFrom-Json
}

$PromptFlowOutputs = (./promptflow/Deploy-PromptFlows.ps1 `
        -SubscriptionId $InfrastructureOutputs.subscriptionInfo.value.id `
        -ResourceGroup $InfrastructureOutputs.resourceGroupInfo.value.name `
        -AIHubProjectName $InfrastructureOutputs.aiHubProjectInfo.value.name `
        -StorageAccountName $InfrastructureOutputs.storageAccountInfo.value.name `
        -DocumentImageContainerName $InfrastructureOutputs.storageAccountInfo.value.documentImageContainerName `
        -OpenAIServicesConnectionName $InfrastructureOutputs.aiHubInfo.value.openAIServicesConnectionName `
        -ModelDeploymentName $InfrastructureOutputs.aiServicesInfo.value.modelDeploymentName `
        -DocumentDataExtractionPromptFlowName 'data-extraction' `
        -DocumentDataExtractionEvalPromptFlowName 'data-extraction-eval')

Pop-Location

Write-Host "Environment setup finished."

return @{
    infrastructureOutputs = $InfrastructureOutputs
    promptFlowOutputs     = $PromptFlowOutputs
}
