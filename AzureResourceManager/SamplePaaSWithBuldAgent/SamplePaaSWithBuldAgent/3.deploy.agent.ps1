##########
###
### Requires Az: 
###     Install-Module -Name Az -AllowClobber -Scope CurrentUser
##########

Param (
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$vsSubscriptionId, 
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$resourceGroupName
)
. ".\helpers\login.ps1"

ConnectAndContext $vsSubscriptionId

# Note: Make sure there are no agents named vmAgentJumpBox in the Default pool in DevOps before running

$deplpoyDate=Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Deploying Win 10 VM with VSTS Agent"

$result = New-AzResourceGroupDeployment `
-ResourceGroupName $resourceGroupName `
-TemplateParameterFile "arm.agent.parameters.json" `
-TemplateFile "arm.agent.json" `
-Mode "Incremental" `
-Name "VMwithAgent$deplpoyDate" `
-SkipTemplateParameterPrompt

return $result.Outputs.adminUsername