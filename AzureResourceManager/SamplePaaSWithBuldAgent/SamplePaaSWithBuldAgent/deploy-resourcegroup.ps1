##########
###
### Requires Az: 
###     Install-Module -Name Az -AllowClobber -Scope CurrentUser
##########
Param (
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$vsSubscriptionId, 
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$resourceGroupName,
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$location,
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$createdBy
)

. ".\helpers\login.ps1"

ConnectAndContext $vsSubscriptionId

$deplpoyDate=Get-Date -Format "yyyyMMdd-HHmmss"

New-AzResourceGroup `
   -Name $resourceGroupName `
   -Location $location `
   -Tag @{CreatedBy="$createdBy";UpdatedOn="$deplpoyDate"} 