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

$deplpoyDate=Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "Deploying Network Resources $userName $deplpoyDate"

New-AzResourceGroupDeployment `
-ResourceGroupName "$resourceGroupName" `
-TemplateParameterFile "arm.vnet.parameters.json" `
-TemplateFile "arm.vnet.json" `
-Mode "Incremental" `
-Name "Network-$deplpoyDate" `
-SkipTemplateParameterPrompt

#$params = @{
#    'updatedBy' = '$userName'
#    'updatedOn' = '$deplpoyDate'
#}
#-TemplateParameterObject $params `
#-updatedBy "Test" `
#-updatedOn "Test" `