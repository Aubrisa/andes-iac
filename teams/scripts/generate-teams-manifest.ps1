<#
     ___         __         _               ___              __              
    /   | __  __/ /_  _____(_)________ _   /   |  ____  ____/ /__  _____
   / /| |/ / / / __ \/ ___/ / ___/ __ `/  / /| | / __ \/ __  / _ \/ ___/
  / ___ / /_/ / /_/ / /  / (__  ) /_/ /  / ___ |/ / / / /_/ /  __(__  )   
 /_/  |_\__,_/_.___/_/  /_/____/\__,_/  /_/  |_/_/ /_/\__,_/\___/____/  

 Copyright (c) 2025 Aubrisa. All rights reserved.

 .SYNOPSIS
 Generate Teams App Manifest for Chat Bot

 .PARAMETER AppId
  Aubrisa Andes Chat Bot App ID.

.PARAMETER ApiDomain
  Chat bot API Endpoint (e.g., "https://chat-api.andes.aubrisa.com")
#>

param(
    [Parameter(Mandatory=$true)][string]$BotAppId,
    [Parameter(Mandatory=$true)][string]$ApiDomain,
    [string]$BotName = $null,
    [bool]$LogInfo = $true
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if (-not $BotName) { $BotName = "Andes" }

if($LogInfo) {
  Write-Host ""
  Write-Host "========================================================" -ForegroundColor DarkCyan
  Write-Host "  Aubrisa Andes Chat Bot Teams App Manifest Generator"    -ForegroundColor White
  Write-Host "========================================================" -ForegroundColor DarkCyan
  Write-Host ""
  Write-Host "This will generate a packaged manifest for the Teams Chat Bot App."
  Write-Host ""
}

$SourceFolder = ".\manifest"
$outputFolder = ".\output"
$workingFolder = ".\working"

if (Test-Path $workingFolder) {
    Remove-Item -Recurse -Force $workingFolder
}

New-Item -ItemType Directory -Path $workingFolder | Out-Null

Write-Host "Copied icon files to working folder" -ForegroundColor DarkGray

Copy-Item -Path "$SourceFolder\*" -Destination $workingFolder -Recurse -Force

$templatePath = Join-Path $workingFolder "manifest.template.json" 
$manifestPath = Join-Path $workingFolder "manifest.json"

Write-Host "Generating manifest.json file" -ForegroundColor DarkGray

$template = Get-Content $templatePath -Raw

$manifest = $template `
  -replace '#{ClientBotApiDomain}', $ApiDomain `
  -replace '#{ClientBotAppId}', $BotAppId `
  -replace '#{BotName}', $BotName

if (-not (Test-Path $OutputFolder)) { 
  New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

$manifest | Out-File $manifestPath -Encoding utf8 

Write-Host "Manifest updated: $manifestPath" -ForegroundColor DarkGray

$zipPath = Join-Path $outputFolder "${BotName}_Teams_App.zip" 

Write-Host "Building package" -ForegroundColor DarkGray

Compress-Archive -Path @(
  "$workingFolder\manifest.json", 
  "$workingFolder\color.png", 
  "$workingFolder\outline.png"
) -DestinationPath $zipPath -Force

Write-Host "Package created: $zipPath" -ForegroundColor Green

if($LogInfo) {
  Write-Host ""
  Write-Host "Next steps:"
  Write-Host ""
  Write-Host "- Open the Teams Admin Center (https://admin.teams.microsoft.com/policies/manage-apps)"
  Write-Host "- Click Actions - Upload new app"
  Write-Host "- Upload the generate manifest file"
}

return $zipPath

