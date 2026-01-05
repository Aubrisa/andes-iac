<#
     ___         __         _               ___              __              
    /   | __  __/ /_  _____(_)________ _   /   |  ____  ____/ /__  _____
   / /| |/ / / / __ \/ ___/ / ___/ __ `/  / /| | / __ \/ __  / _ \/ ___/
  / ___ / /_/ / /_/ / /  / (__  ) /_/ /  / ___ |/ / / / /_/ /  __(__  )   
 /_/  |_\__,_/_.___/_/  /_/____/\__,_/  /_/  |_/_/ /_/\__,_/\___/____/  

 Copyright (c) 2025 Aubrisa. All rights reserved.

 .SYNOPSIS
 Entra App Registration

 .PARAMETER TenantId
  Tenant (directory) Id to connect to.

.PARAMETER Environment
  Environment label used in the app display name (e.g., "dev", "prod").

.PARAMETER AppUrl
  SPA redirect URI (e.g., "https://andes.aubrisa.com").

.PARAMETER DisplayName
  Optional display name. If omitted, script uses "Aubrisa Andes - [Environment]".

.PARAMETER SecretExpiryYears
  Number of years until the client secret expires (default 1).

.PARAMETER CopySecretToClipboard
  Copy the generated client secret to the clipboard (default false).

.EXAMPLE
  .\create-app-registration.ps1 -TenantId "aubrisa.com" `
    -Environment "dev" `
    -AppUrl "https://andes.aubrisa.com"
    -DisplayName "Aubrisa Andes - Dev"
#>

param(
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$Environment,
    [Parameter(Mandatory=$true)][string]$AppUrl,
    [string]$DisplayName = $null,
    [int]$SecretExpiryYears = 1,
    [bool]$CopySecretToClipboard = $False,
    [bool]$AutoDisconnect = $True
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

function Write-KeyValue {
    param(
        [string]$Text,
        [string]$KeyColor = "Cyan",
        [string]$ValueColor = "White"
    )
    
    $parts = $Text -split ':', 2
    if ($parts.Count -eq 2) {
        Write-Host ($parts[0] + ":") -NoNewline -ForegroundColor $KeyColor
        Write-Host $parts[1] -ForegroundColor $ValueColor
    } else {
        Write-Host $Text -ForegroundColor $KeyColor
    }
}

# Check for Microsoft.Graph module 
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) { 
    Write-Host "" 
    Write-Host "ERROR: The Microsoft.Graph PowerShell module is not installed." `
        -ForegroundColor Red 
    Write-Host "" 
    Write-Host "Install it by running (in an elevated or normal PowerShell session):" `
        -ForegroundColor Yellow 
    Write-Host "" 
    Write-Host " Install-Module Microsoft.Graph -Scope CurrentUser" `
        -ForegroundColor Cyan 
    Write-Host "" 
    Write-Host "After installing, re-run this script." `
        -ForegroundColor Green 
    exit 1 
}

if (-not $DisplayName) { $DisplayName = "Aubrisa Andes - $Environment" }

$domain = ($AppUrl -replace '^https?://','').TrimEnd('/') -split '/' | Select-Object -First 1

$identifierUri = "api://$environment.$domain"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor DarkCyan
Write-Host "   Aubrisa Andes Entra ID Application Registration"    -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor DarkCyan
Write-Host ""

Write-Host "Connecting to Microsoft Graph. You will be prompted to sign in with an admin account..."


Write-Host "Display Name:     $DisplayName"
Write-Host "SPA Redirect URI: $AppUrl"
Write-Host "Identifier URI:   $identifierUri"

$app = $null
$sp = $null

$clientId = $null
$secretValue = $null

try {
    # Connect to Microsoft Graph (interactive)
    Write-Host "Connecting to Microsoft Graph. You will be prompted to sign in with an admin account..."

    $scopes = @(
        "Application.ReadWrite.All",
        "AppRoleAssignment.ReadWrite.All",
        "DelegatedPermissionGrant.ReadWrite.All",
        "Directory.Read.All", 
        "Application.Read.All"
    )

    Connect-MgGraph -Scopes $scopes -NoWelcome

    # Ensure Microsoft Graph service principal is available (resource app)
    $graphAppId = "00000003-0000-0000-c000-000000000000"

    $graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'"

    if (-not $graphSp) {
        throw "Microsoft Graph service principal not found in this tenant."
    }

    $delegatedScopes = @("User.Read","email","offline_access","openid","profile")

    $appRoles = @("Group.Read.All","GroupMember.Read.All","User.Read.All","Mail.Send")

    $resourceAccessList = @()

    foreach ($scopeName in $delegatedScopes) {
        $scopeObj = $graphSp.Oauth2PermissionScopes | Where-Object { $_.Value -eq $scopeName }
        if ($scopeObj) {
            $resourceAccessList += New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphResourceAccess -Property @{
                Id = $scopeObj.Id
                Type = "Scope"
            }
        }
    }

    foreach ($roleName in $appRoles) {
        $roleObj = $graphSp.AppRoles | Where-Object { $_.Value -eq $roleName }
        if ($roleObj) {
            $resourceAccessList += New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphResourceAccess -Property @{
                Id = $roleObj.Id
                Type = "Role"
            }
        }
    }

    $requiredResourceAccess = @(
        (New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess -Property @{
            ResourceAppId = $graphSp.AppId
            ResourceAccess = $resourceAccessList
        })
    )

    Write-Host "Creating application..."

    $app = New-MgApplication -DisplayName $DisplayName `
        -SignInAudience "AzureADMyOrg" `
        -Spa @{ RedirectUris = @($AppUrl) } `
        -RequiredResourceAccess $requiredResourceAccess `
        -Web @{ 
            HomePageUrl = $AppUrl
            ImplicitGrantSettings = @{ 
                EnableIdTokenIssuance = $true
                EnableAccessTokenIssuance = $true 
            } 
        }
    if (-not $app) { throw "Failed to create application." }

    Write-Host "$([char]0x2713) Application created" -ForegroundColor Green

    # Update the application to set AccessTokenAcceptedVersion to 2
    Update-MgApplication -ApplicationId $app.Id `
        -IdentifierUris @($identifierUri) -Api @{ RequestedAccessTokenVersion = 2 }

    $logoPath = ".\images\andes_logo.png"

    if ($Environment -like "*dev*") {
        $logoPath = ".\images\andes_logo_dev.png"
    }
    elseif ($Environment -like "*uat*") {
        $logoPath = ".\images\andes_logo_uat.png"
    }

    if (Test-Path $logoPath) {
        Write-Host "Uploading application logo..."
        try {
            Set-MgApplicationLogo -ApplicationId $app.Id -InFile $logoPath

            Write-Host "$([char]0x2713) Logo uploaded" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to upload logo: $_"
        }
    }

    # Create a service principal for the app to assign app roles and grant consent

    Write-Host "Creating service principal for the application..."

    $sp = New-MgServicePrincipal -AppId $app.AppId

    if (-not $sp) { throw "Failed to create service principal." }

    Write-Host "$([char]0x2713) service principal created" -ForegroundColor Green

    # Assign application permissions (app roles) to the service principal 
    # (tenant admin consent for app permissions)
    Write-Host "Assigning application permissions (app roles) to the service principal..."

    foreach ($roleName in $appRoles) {
        $roleObj = $graphSp.AppRoles | Where-Object { $_.Value -eq $roleName -and
                $_.AllowedMemberTypes -contains "Application" }

        if ($roleObj) {
            New-MgServicePrincipalAppRoleAssignment `
                -ServicePrincipalId $sp.Id `
                -PrincipalId $sp.Id `
                -ResourceId $graphSp.Id `
                -AppRoleId  $roleObj.Id | Out-Null

            Write-Host "   Assigned app role: $roleName" `
                -ForegroundColor Gray
        } else {
            Write-Warning "Skipping app role assignment; role not found: $roleName"
        }
    }

    Write-Host "$([char]0x2713) App roles assigned" -ForegroundColor Green

    # Grant tenant-wide admin consent for delegated scopes by creating an OAuth2PermissionGrant
    $delegatedScopeString = ($delegatedScopes -join " ")

    Write-Host "Granting tenant-wide admin consent for delegated scopes: $delegatedScopeString"

    New-MgOauth2PermissionGrant -ClientId $sp.Id `
                                -ConsentType "AllPrincipals" `
                                -ResourceId $graphSp.Id `
                                -Scope $delegatedScopeString | Out-Null

    Write-Host "$([char]0x2713) Admin consent granted for delegated scopes" -ForegroundColor Green

    # Create client secret
    $endDate = (Get-Date).AddYears([int]$SecretExpiryYears)

    Write-Host "Creating client secret (expires $endDate)..."

    $passwordCredential = @{
        DisplayName = "API Client Secret"
        EndDateTime = $endDate
    }

    $secret = Add-MgApplicationPassword -ApplicationId $app.Id `
                                        -PasswordCredential $passwordCredential

    if (-not $secret) { throw "Failed to create client secret." }

    Write-Host "$([char]0x2713) Client secret created" -ForegroundColor Green

    # Output results
    $clientId = $app.AppId
    $secretValue = $secret.SecretText

    Write-Host "`n---------------------------------------------------------------------" `
        -ForegroundColor DarkCyan
    Write-Host "Andes Entra ID Application Registration created" `
        -ForegroundColor White
    Write-Host "---------------------------------------------------------------------" `
        -ForegroundColor DarkCyan

    Write-Host "`nSettings Required for Andes configuration:`n"
    Write-KeyValue "  Tenant Id             : $TenantId"
    Write-KeyValue "  Client Id (App Id)    : $clientId"
    Write-KeyValue "  Client Secret Value   : $secretValue" -ValueColor Yellow
    
    Write-Host "`nAdditional`n"
    Write-KeyValue "  Display Name          : $DisplayName"
    Write-KeyValue "  Application Object Id : $($app.Id)"
    Write-KeyValue "  Service Principal Id  : $($sp.Id)"
    Write-KeyValue "  Identifier URI        : $identifierUri"
    Write-KeyValue "  Access token version  : v2"


    if($CopySecretToClipboard) {    
        Set-Clipboard -Value $secretValue
        Write-Host "`n$([char]0x2713) Client secret has been copied to your clipboard." -ForegroundColor Green
    }

    Write-Host "`nIMPORTANT: The client secret cannot be retrievable later." -ForegroundColor Yellow

    $env:ClientId = $clientId
    $env:ClientSecret = $secretValue

    Write-Host "`nTo remove this app registration:`n"
    Write-Host '    Connect-MgGraph -Scopes "Application.ReadWrite.All"'
    Write-Host "    Remove-MgApplication -ApplicationId `"$clientId`""
    Write-Host "    Disconnect-MgGraph"

} catch {
    Write-Host "`n$([char]0x274C) Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    
    # Cleanup on error - rollback created resources
    if ($sp) {
        Write-Host "`nCleaning up: Removing service principal..." -ForegroundColor Yellow
        try {
            Remove-MgServicePrincipal -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue
            Write-Host "Service principal removed." -ForegroundColor Yellow
        } catch {
            Write-Warning "Could not remove service principal: $_"
        }
    }
    
    if ($app) {
        Write-Host "Cleaning up: Removing application..." -ForegroundColor Yellow
        try {
            Remove-MgApplication -ApplicationId $app.Id -ErrorAction SilentlyContinue
            Write-Host "Application removed." -ForegroundColor Yellow
        } catch {
            Write-Warning "Could not remove application: $_"
        }
    }
    
    throw
    
} finally {
if ((Get-MgContext) -and $AutoDisconnect) {
    Disconnect-MgGraph | Out-Null
}
}

return @{
    ClientId = $clientId
    ClientSecret = $secretValue
}