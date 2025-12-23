<#
     ___         __         _               ___              __              
    /   | __  __/ /_  _____(_)________ _   /   |  ____  ____/ /__  _____
   / /| |/ / / / __ \/ ___/ / ___/ __ `/  / /| | / __ \/ __  / _ \/ ___/
  / ___ / /_/ / /_/ / /  / (__  ) /_/ /  / ___ |/ / / / /_/ /  __(__  )   
 /_/  |_\__,_/_.___/_/  /_/____/\__,_/  /_/  |_/_/ /_/\__,_/\___/____/  

 Copyright (c) 2025 Aubrisa. All rights reserved.

 .SYNOPSIS
 Upload Generated Teams Manifest via MS Graph

 .PARAMETER AppId
  Aubrisa Andes Chat Bot App ID.
#>

param(
    [Parameter(Mandatory=$true)][string]$Manifest,
    [bool]$LogInfo = $true,
    [bool]$Connect = $true
)

if($Connect) {
    $scopes = @(
        "AppCatalog.ReadWrite.All"
    )
    
    # Connect to Microsoft Graph (interactive)
    Write-Host "Connecting to Microsoft Graph. You will be prompted to sign in with an admin account..."

    Connect-MgGraph -Scopes $scopes -NoWelcome
}

$zipBytes = [System.IO.File]::ReadAllBytes($Manifest)

Invoke-MgGraphRequest ` 
    -Method POST ` 
    -Uri "https://graph.microsoft.com/v1.0/appCatalogs/teamsApps" ` 
    -ContentType "application/zip" ` 
    -Body $zipBytes

if($Connect) {
    if (Get-MgContext) {
        Disconnect-MgGraph | Out-Null
    }
}