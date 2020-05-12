##########
###
### Requires Az: 
###     Install-Module -Name Az -AllowClobber -Scope CurrentUser
##########

Param (
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$vsSubscriptionId, 
    [Parameter(Mandatory=$True)] [ValidateNotNull()] [string]$resourceGroupName,
)

. ".\helpers\login.ps1"

ConnectAndContext $vsSubscriptionId

Write-Host "Deleting Win 10 VM with VSTS Agent in $resourceGroupName"

#Remove VM
$vm = Get-AzVm -Name "vmAgentJumpBox" -ResourceGroupName $resourceGroupName

if ($vm){
    $null = $vm | Remove-AzVM -Force
    #Remove-AzureRmResource 

    #Remove NIC
    foreach($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
        $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
        Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force

        foreach($ipConfig in $nic.IpConfigurations) {
            if($ipConfig.PublicIpAddress -ne $null) {
                Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
            }
        }
    }
    #Remove Disk
    $osDiskName = $vm.StorageProfile.OSDisk.Name

    Remove-AzDisk -ResourceGroupName $rgName -DiskName $osDiskName -Force;
}