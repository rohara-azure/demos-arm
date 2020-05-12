function ConnectAndContext($subscriptionId)
{
    $context = Get-AzContext

    if (!$context -or ($context.Subscription.Id -ne $subscriptionId)) 
    {
        Connect-AzAccount -Subscription $subscriptionId
        $context = Get-AzSubscription -SubscriptionId $subscriptionId
        Set-AzContext $context
    } 
    else 
    {
        Write-Host "SubscriptionId '$subscriptionId' already connected. Skipping authentication."
    }
}