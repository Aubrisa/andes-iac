<#
     ___         __         _               ___              __              
    /   | __  __/ /_  _____(_)________ _   /   |  ____  ____/ /__  _____
   / /| |/ / / / __ \/ ___/ / ___/ __ `/  / /| | / __ \/ __  / _ \/ ___/
  / ___ / /_/ / /_/ / /  / (__  ) /_/ /  / ___ |/ / / / /_/ /  __(__  )   
 /_/  |_\__,_/_.___/_/  /_/____/\__,_/  /_/  |_/_/ /_/\__,_/\___/____/  

 Copyright (c) 2025 Aubrisa. All rights reserved.

 .SYNOPSIS
 Deploy application
#>

param(
    [Parameter(Mandatory=$true)][string]$StackName,
    [bool]$SetParameters = $True
)

function ReplaceParameterValue {
    param(
        [Parameter(Mandatory=$true)][array]$Params,
        [Parameter(Mandatory=$true)][string]$Key,
        [Parameter(Mandatory=$true)][string]$Value
    )
    
    $updated = $Params | Where-Object { $_ -notlike "$Key=*" }
    $updated += "$Key=$Value"
    return $updated
}

Write-Host ""
Write-Host "=============================================================================" `
    -ForegroundColor DarkCyan
Write-Host "   Aubrisa Andes - AWS CloudFormation Deployment"      -ForegroundColor White
Write-Host "=============================================================================" `
    -ForegroundColor DarkCyan
Write-Host ""

Write-Host "Packaging..."

aws cloudformation package `
   --template-file ../cloudFormation/templates/app.yaml `
   --s3-bucket andes-cfn-templates-eu-west-2 `
   --output-template-file ../cloudFormation/templates/app-packaged.yaml `
   --force-upload  | Out-Null

if($SetParameters -eq $True) {
   Write-Host "Setting parameters..."
   $params = Get-Content ../cloudFormation/params/app-dev.json | ConvertFrom-Json | `
      ForEach-Object { "$( $_.ParameterKey )=$( $_.ParameterValue )" }
}

Write-Host "Deploying stack $StackName..."

aws cloudformation deploy `
   --stack-name $StackName `
   --template-file ../cloudFormation/templates/app-packaged.yaml `
   --parameter-overrides $params `
   --capabilities CAPABILITY_NAMED_IAM `
   --tags project=andes env=dev `
   --region eu-west-2