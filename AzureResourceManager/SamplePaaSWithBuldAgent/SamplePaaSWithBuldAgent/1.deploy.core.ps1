##########
###
### Readme:
###     This script faciliates the steps to create resource groups, key vault and storage for this demo
### 
##########

exit #dont allow invocation via command line

Get-ChildItem . -Filter *parameters.json | Rename-Item -NewName "$($_.Name).ignore"
Get-ChildItem . -Filter *parameters.json.ignore | Rename-Item -NewName $_.Name.substring($_.Name.length -7)

########
### Step 1: set vars; 
$subscriptionId = "#####" # get the subscription guid where you want to deploy the demo
$location = "eastus" # desired location
$createdBy = "demo" # used for tags mainly
$rando = Get-Random # used to generate random number appended to most resources names/passwords to give uniquness
$demoPrefix = "demo" # prefix used in resources names
$commonName = "$demoPrefix$rando" # common name used in resources
$vaultName = "kv-$commonName" 
$networkRg = "rg-demo-$($rando)-Network"
$paasRg = "rg-demo-$($rando)-PaaS"
$accessToken = "a pat value" # this is the personal access token from azure devops

########
### Step 2: Login and set context

. ".\helpers\login.ps1"

ConnectAndContext $subscriptionId

########
### Step 3: Create PaaS and Network RGs - our ARM templates require these exist New-AzResourceGroupDeployment
.\deploy-resourcegroup.ps1 -vsSubscriptionId $subscriptionId `
    -resourceGroupName $networkRg `
    -location $location `
    -createdBy $createdBy

.\deploy-resourcegroup.ps1 -vsSubscriptionId $subscriptionId `
    -resourceGroupName $paasRg `
    -location $location `
    -createdBy $createdBy


########
### Step 4: Create storage account & container (holds our CustomScriptExtension artifact files)

# Create storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $networkRg `
  -Name "st$commonName" `
  -Location $location `
  -SkuName "Standard_LRS"

$ctx = $storageAccount.Context

$containerName = "vstsagentscripts"

# Create storage container
New-AzStorageContainer `
    -Name $containerName `
    -Context $ctx `
    -Permission blob 

# Add file our VM Extension will use
Set-AzStorageBlobContent -File "scripts\InstallVstsAgent.ps1" `
  -Container $containerName `
  -Blob "InstallVstsAgent.ps1" `
  -Context $ctx 


  
########
### Step 5: Add keyvault and secrets

New-AzKeyVault `
  -VaultName $vaultName `
  -resourceGroupName $networkRg `
  -Location $location `
  -EnabledForTemplateDeployment

# you will need to set access policies in Azure to add users or via pshell
$userId=(Get-AzADUser).Id
Set-AzKeyVaultAccessPolicy -VaultName $vaultName `
                           -ResourceGroupName $networkRg `
                           -ObjectId $userId `
                           -PermissionsToSecrets set,get,list

########
### Step 4: Add secrets

$databaseCatalog = $demoPrefix
$password = "JK_kP*$rando"
$databaseUser = $demoPrefix


Write-Host "Password is: $password"

$connectionString = ConvertTo-SecureString "Server=tcp:sqldb-$($commonName).database.windows.net,1433;Initial Catalog=$($databaseCatalog);Persist Security Info=False;User ID=web;Password=$($password);MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" -AsPlainText -Force
$dbPassword = ConvertTo-SecureString $password -AsPlainText -Force
$vmAdminPassword = ConvertTo-SecureString $password -AsPlainText -Force
$pat = ConvertTo-SecureString $accessToken -AsPlainText -Force

Set-AzKeyVaultSecret -VaultName $vaultName  -Name 'connectionString' -SecretValue $connectionString
Set-AzKeyVaultSecret -VaultName $vaultName  -Name 'dbPassword' -SecretValue $dbPassword
Set-AzKeyVaultSecret -VaultName $vaultName  -Name 'vmPasswordMgmt' -SecretValue $vmAdminPassword
Set-AzKeyVaultSecret -VaultName $vaultName  -Name 'agentPAT' -SecretValue $pat

#Note: The user who deploys the template must have the Microsoft.KeyVault/vaults/deploy/action 
#permission for the scope of the resource group and key vault. 
#The Owner and Contributor roles both grant this access.

########
### Step 4: Deploy ARM Templates

. ".\2a.deploy.network.resources.ps1" -vsSubscriptionId $subscriptionId `
    -resourceGroupName $networkRg

    Write-Host $commonName
    Write-Host "plan-$commonName"
    #update app plan name

. ".\2b.deploy.paas.resources.ps1" -vsSubscriptionId $subscriptionId `
    -resourceGroupName $paasRg

#update blob location in params file
Get-AzStorageBlob -Container $containerName -Context $ctx

. ".\3.deploy.agent.ps1" -vsSubscriptionId $subscriptionId `
    -resourceGroupName $networkRg