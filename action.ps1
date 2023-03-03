# HelloID-Task-SA-Target-AzureActiveDirectory-AccountDisable
###########################################################
# Form mapping
$formObject = @{
    id                = $form.id
    userPrincipalName = $form.UserPrincipalName
    accountEnabled    = $false
}

try {
    Write-Information "Executing AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)]"
    Write-Information "Retrieving Microsoft Graph AccessToken for tenant: [$AADTenantID]"
    $splatTokenParams = @{
        Uri         = "https://login.microsoftonline.com/$AADTenantID/oauth2/token"
        ContentType = 'application/x-www-form-urlencoded'
        Method      = 'POST'
        Verbose     = $false
        Body = @{
            grant_type    = 'client_credentials'
            client_id     = $AADAppID
            client_secret = $AADAppSecret
            resource      = 'https://graph.microsoft.com'
        }
    }
    $accessToken = (Invoke-RestMethod @splatTokenParams).access_token
    $splatCreateUserParams = @{
        Uri     = "https://graph.microsoft.com/v1.0/users/$($formObject.userPrincipalName)"
        Method  = 'PATCH'
        Body    = $formObject | ConvertTo-Json -Depth 10
        Verbose = $false
        Headers = @{
            Authorization  = "Bearer $accessToken"
            Accept         = 'application/json'
            'Content-Type' = 'application/json'
        }
    }
    $null = Invoke-RestMethod @splatCreateUserParams
    $auditLog = @{
        Action            = 'DisableAccount'
        System            = 'AzureActiveDirectory'
        TargetIdentifier  = $formObject.id
        TargetDisplayName = $formObject.userPrincipalName
        Message           = "AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)] executed successfully"
        IsError           = $false
    }
    Write-Information -Tags 'Audit' -MessageData $auditLog
    Write-Information "AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)] executed successfully"
} catch {
    $ex = $_
    $auditLog = @{
        Action            = 'DisableAccount'
        System            = 'AzureActiveDirectory'
        TargetIdentifier  = ''
        TargetDisplayName = $formObject.userPrincipalName
        Message           = "Could not execute AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)], error: $($ex.Exception.Message)"
        IsError           = $true
    }
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException')){
        $auditLog.Message = "Could not execute AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)]"
        Write-Error "Could not execute AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)], error: $($ex.ErrorDetails)"
    }
    Write-Information -Tags "Audit" -MessageData $auditLog
    Write-Error "Could not execute AzureActiveDirectory action: [DisableAccount] for: [$($formObject.UserPrincipalName)], error: $($ex.Exception.Message)"
}
###########################################################
