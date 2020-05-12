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

Write-Host "Deploying Web Resources"

New-AzResourceGroupDeployment `
-ResourceGroupName "$resourceGroupName" `
-TemplateParameterFile "arm.web.parameters.json" `
-TemplateFile "arm.web.json" `
-Mode "Incremental" `
-Name "Web-$deplpoyDate" `
-SkipTemplateParameterPrompt

Write-Host "Deploying DB Resources"

New-AzResourceGroupDeployment `
-ResourceGroupName "$resourceGroupName" `
-TemplateParameterFile "arm.db.parameters.json" `
-TemplateFile "arm.db.json" `
-Mode "Incremental" `
-Name "DB-$deplpoyDate" `
-SkipTemplateParameterPrompt
