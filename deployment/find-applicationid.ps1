<#
.SYNOPSIS
    This script can be used to retreive an app id based on an application service principal id
.DESCRIPTION
    Based on the application name, this script can retreive the appId. An appId is needed if you want to give the app SQL access via MSI
    The registered client (can be your devops client) in AzureAD must have Microsoft Graph Directory.Read.All rights
    .PARAMETER tenantId
    The tenantId where the devops service connection is connecting to. The tenantId is used to request a token to connect to the Azure SQL as only 
    AzureAD users/apps can give other AzureAD users access to the Azure SQL DB.
    .PARAMETER clientId
    The clientId of the devops service connection app registration
    .PARAMETER clientSecret
    The clientSecret of the devops service conneciton app registration. This is needed to be able to request a token.
    .PARAMETER appServicePrincipalId
    The application id of the app. This id can be retreived via your ARM template. Ex: "[reference(concat(resourceId('Microsoft.Web/sites', variables('webAppName')), '/providers/Microsoft.ManagedIdentity/Identities/default'), '2018-11-30').principalId]"
    .PARAMETER outputVariableName
    The variable name that is injected in the devops pipeline. Defaults to appId
#>
param (
    [Parameter(Mandatory=$true)][string]$tenantId,
    [Parameter(Mandatory=$true)][string]$clientId,
    [Parameter(Mandatory=$true)][string]$clientSecret,
    [Parameter(Mandatory=$true)][string]$appServicePrincipalId,
    [string]$outputVariableName = "appId"
)

$graphResource = 'https://graph.microsoft.com/'


$tokenResponse = Invoke-RestMethod -Method Post -UseBasicParsing `
    -Uri "https://login.windows.net/$($tenantId)/oauth2/token" `
    -Body @{
        resource=$graphResource
        client_id=$clientId
        grant_type='client_credentials'
        client_secret=$clientSecret
    } -ContentType 'application/x-www-form-urlencoded'

if ($tokenResponse) {
    Write-debug "Access token type is $($tokenResponse.token_type), expires $($tokenResponse.expires_on)"
    $token = $tokenResponse.access_token


    $appInfo = Invoke-RestMethod -Method Get `
        -uri "https://graph.microsoft.com/beta/servicePrincipals/$appServicePrincipalId" `
        -Headers @{"Authorization" = $token}
    $result = $appInfo.appId
    Write-Host "Found AppId: $result"
}
Write-Host ("##vso[task.setvariable variable=$outputVariableName;issecret=true;]$result")
