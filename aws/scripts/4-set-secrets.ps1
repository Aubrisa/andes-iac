param(
    [Parameter(Mandatory=$true)][string]$Environment,
    [Parameter(Mandatory=$true)][string]$EntraApiKey
)

Write-Host ""
Write-Host "=============================================================================" -ForegroundColor DarkCyan
Write-Host "   Aubrisa Andes - Secrets"                                                    -ForegroundColor White
Write-Host "=============================================================================" -ForegroundColor DarkCyan
Write-Host ""

Write-Host "Setting Entra API Key secret..." -ForegroundColor Cyan

aws secretsmanager update-secret `
  --secret-id andes/${Environment}/entraid-api-key `
  --secret-string "{`"key`": `"$EntraApiKey`"}"