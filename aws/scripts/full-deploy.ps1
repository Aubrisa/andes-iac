param(
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$Environment,
    [Parameter(Mandatory=$true)][string]$AppUrl,
    [string]$DisplayName = $null,
    [int]$SecretExpiryYears = 1
)

$StackName = "andes-$Environment"

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

Write-Host "Setting parameters..."
$params = Get-Content ../cloudFormation/params/app-dev.json | ConvertFrom-Json | `
    ForEach-Object { "$( $_.ParameterKey )=$( $_.ParameterValue )" }

$appRegistration = .\1-create-app-registration.ps1 `
    -TenantId $TenantId `
    -Environment $Environment `
    -AppUrl $AppUrl `
    -DisplayName $DisplayName `
    -SecretExpiryYears $SecretExpiryYears

$params = ReplaceParameterValue -Params $params `
                                -Key "ClientId" `
                                -Value $appRegistration.ClientId

.\2-deploy-stack.ps1 -StackName $StackName -SetParameters $False

.\3-initialize-database.ps1 -EnvironmentName $Environment

.\4-set-secrets.ps1 -Environment $Environment -EntraApiKey $appRegistration.ClientSecret

.\5-set-parameter-store-values -EnvironmentName $Environment `
                               -TenantId $TenantId `
                               -ClientId $appRegistration.ClientId `
                               -BotTenantId $TenantId `
                               -BotAppId "TODO"