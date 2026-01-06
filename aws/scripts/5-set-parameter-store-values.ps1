#Requires -Version 7.0
<#
.SYNOPSIS
    Sets Entra ID configuration values in AWS Systems Manager Parameter Store
.DESCRIPTION
    This script sets TenantId, ClientId, and BotTenantId values in Parameter Store.
    These values are read by ECS tasks at runtime and won't be overwritten by stack updates.
.PARAMETER AppName
    Application name (default: andes)
.PARAMETER EnvironmentName
    Environment name (dev, staging, prod)
.PARAMETER TenantId
    Entra ID Tenant ID
.PARAMETER ClientId
    Entra ID Client ID (App Registration ID)
.PARAMETER BotTenantId
    Bot Tenant ID (typically same as TenantId)
.PARAMETER BotAppId
    Bot App ID
.PARAMETER Region
    AWS region (default: eu-west-2)
.EXAMPLE
    .\5-set-parameter-store-values.ps1 -EnvironmentName dev -TenantId "c86ffa82-a661-4004-ba5b-19e95025869a" -ClientId "your-client-id" -BotTenantId "c86ffa82-a661-4004-ba5b-19e95025869a" -BotAppId "c29c2c66-75a0-4966-bb62-157f16872486"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$AppName = "andes",
    
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$BotTenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$BotAppId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "eu-west-2"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================================" -ForegroundColor DarkCyan
Write-Host "   Aubrisa Andes - Setting Parameter Store Values"                                    -ForegroundColor White
Write-Host "=============================================================================" -ForegroundColor DarkCyan
Write-Host ""

# Set Tenant ID
$tenantIdParamName = "/$AppName/$EnvironmentName/entraid/tenant-id"
Write-Host "Setting Tenant ID parameter: $tenantIdParamName" -ForegroundColor Green
aws ssm put-parameter `
    --name $tenantIdParamName `
    --value $TenantId `
    --type String `
    --overwrite `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set Tenant ID parameter"
    exit 1
}

# Set Client ID
$clientIdParamName = "/$AppName/$EnvironmentName/entraid/client-id"
Write-Host "Setting Client ID parameter: $clientIdParamName" -ForegroundColor Green
aws ssm put-parameter `
    --name $clientIdParamName `
    --value $ClientId `
    --type String `
    --overwrite `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set Client ID parameter"
    exit 1
}

# Set Bot Tenant ID
$botTenantIdParamName = "/$AppName/$EnvironmentName/bot/tenant-id"
Write-Host "Setting Bot Tenant ID parameter: $botTenantIdParamName" -ForegroundColor Green
aws ssm put-parameter `
    --name $botTenantIdParamName `
    --value $BotTenantId `
    --type String `
    --overwrite `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set Bot Tenant ID parameter"
    exit 1
}

# Set Bot App ID
$botAppIdParamName = "/$AppName/$EnvironmentName/bot/app-id"
Write-Host "Setting Bot App ID parameter: $botAppIdParamName" -ForegroundColor Green
aws ssm put-parameter `
    --name $botAppIdParamName `
    --value $BotAppId `
    --type String `
    --overwrite `
    --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set Bot App ID parameter"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Parameter Store values set successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Parameters created:" -ForegroundColor Yellow
Write-Host "  - $tenantIdParamName" -ForegroundColor White
Write-Host "  - $clientIdParamName" -ForegroundColor White
Write-Host "  - $botTenantIdParamName" -ForegroundColor White
Write-Host "  - $botAppIdParamName" -ForegroundColor White
Write-Host ""
