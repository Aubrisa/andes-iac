param(
    [Parameter(Mandatory=$true)][string]$Environment,
    [Parameter(Mandatory=$true)][string]$EntraApiKey
)

Write-Host "Setting Entra API Key secret..." -ForegroundColor Cyan

aws secretsmanager update-secret `
  --secret-id andes/${Environment}/entraid-api-key `
  --secret-string "{`"key`": `"$EntraApiKey`"}"