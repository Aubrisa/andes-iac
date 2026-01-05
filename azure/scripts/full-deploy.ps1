param(
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$Environment,
    [Parameter(Mandatory=$true)][string]$AppUrl,
    [string]$DisplayName = $null,
    [int]$SecretExpiryYears = 1
)

$appRegistration = .\1-create-app-registration.ps1 `
    -TenantId $TenantId `
    -Environment $Environment `
    -AppUrl $AppUrl `
    -DisplayName $DisplayName `
    -SecretExpiryYears $SecretExpiryYears `
    -AutoDisconnect $False

az deployment group create `
  --resource-group $ResourceGroup `
  --template-file ..\bicep\app-service\public\main.bicep `
  --parameters ..\bicep\app-service\public\parameters\andes-01.parameters.json `
  --parameters apiKey=$($appRegistration.ClientSecret) clientId=$($appRegistration.ClientId)