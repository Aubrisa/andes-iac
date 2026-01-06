param(
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "andes",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "eu-west-2"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================================" -ForegroundColor DarkCyan
Write-Host "   Aubrisa Andes - Database Initialization"                                    -ForegroundColor White
Write-Host "=============================================================================" -ForegroundColor DarkCyan
Write-Host ""

Write-Host "Initializing database for environment: $EnvironmentName" -ForegroundColor Cyan

# Step 1: Get RDS instance endpoint
Write-Host "`nGetting RDS instance endpoint..." -ForegroundColor Yellow
$dbInstanceId = "$AppName-$EnvironmentName-sql"

try {
    $rdsInstance = aws rds describe-db-instances `
        --db-instance-identifier $dbInstanceId `
        --region $Region `
        --query 'DBInstances[0].Endpoint.Address' `
        --output text
    
    if ([string]::IsNullOrWhiteSpace($rdsInstance)) {
        throw "RDS instance not found: $dbInstanceId"
    }
    
    Write-Host "  RDS Endpoint: $rdsInstance" -ForegroundColor Green
}
catch {
    Write-Error "Failed to retrieve RDS instance: $_"
    exit 1
}

# Step 2: Retrieve secrets from AWS Secrets Manager
Write-Host "`nRetrieving secrets from AWS Secrets Manager..." -ForegroundColor Yellow

function Get-SecretPassword {
    param(
        [string]$SecretName,
        [string]$Region
    )
    
    try {
        $secretValue = aws secretsmanager get-secret-value `
            --secret-id $SecretName `
            --region $Region `
            --query 'SecretString' `
            --output text
        
        $secretJson = $secretValue | ConvertFrom-Json
        return $secretJson.password
    }
    catch {
        Write-Error "Failed to retrieve secret '$SecretName': $_"
        throw
    }
}

$secrets = @{
    rds_password = "$AppName/$EnvironmentName/rds-password"
    api_app_password = "$AppName/$EnvironmentName/api/app-password"
    api_security_password = "$AppName/$EnvironmentName/api/security-password"
    load_password = "$AppName/$EnvironmentName/load-service/load-password"
    murex_password = "$AppName/$EnvironmentName/murex-service/store-password"
    reporting_password = "$AppName/$EnvironmentName/reporting-service/store-password"
    adjustments_password = "$AppName/$EnvironmentName/adjustments-service/store-password"
}

$passwords = @{}

foreach ($key in $secrets.Keys) {
    Write-Host "  Retrieving: $($secrets[$key])" -ForegroundColor Gray
    $passwords[$key] = Get-SecretPassword -SecretName $secrets[$key] -Region $Region
}

Write-Host "  All secrets retrieved successfully" -ForegroundColor Green

# Step 3: Prepare SQL script with variable substitution
Write-Host "`nPreparing SQL script..." -ForegroundColor Yellow

$scriptPath = Join-Path $PSScriptRoot "./sql/initialize-database.sql"
if (-not (Test-Path $scriptPath)) {
    Write-Error "SQL script not found: $scriptPath"
    exit 1
}

$sqlContent = Get-Content $scriptPath -Raw

# Replace placeholders with actual passwords
# Note: For SQLCMD, we need to escape single quotes by doubling them
$sqlContent = $sqlContent -replace '\$\{api_app_password\}', $passwords.api_app_password.Replace("'", "''")
$sqlContent = $sqlContent -replace '\$\{api_security_password\}', $passwords.api_security_password.Replace("'", "''")
$sqlContent = $sqlContent -replace '\$\{reporting_password\}', $passwords.reporting_password.Replace("'", "''")
$sqlContent = $sqlContent -replace '\$\{load_password\}', $passwords.load_password.Replace("'", "''")
$sqlContent = $sqlContent -replace '\$\{adjustments_password\}', $passwords.adjustments_password.Replace("'", "''")
$sqlContent = $sqlContent -replace '\$\{murex_password\}', $passwords.murex_password.Replace("'", "''")

# Save the processed SQL to a temporary file
$tempSqlFile = Join-Path $env:TEMP "database-init-$EnvironmentName-$(Get-Date -Format 'yyyyMMddHHmmss').sql"
$sqlContent | Out-File -FilePath $tempSqlFile -Encoding UTF8 -NoNewline

Write-Host "  SQL script prepared: $tempSqlFile" -ForegroundColor Green

# Step 4: Execute SQL script against RDS
Write-Host "`nExecuting SQL script on RDS..." -ForegroundColor Yellow

$serverAddress = "$rdsInstance,1433"
$username = "dbadmin"
$password = $passwords.rds_password

try {
    # Using sqlcmd to execute the script
    # Note: You may need to install SQL Server command-line tools if not already installed
    # https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility
    
    Write-Host "  Connecting to: $serverAddress" -ForegroundColor Gray
    Write-Host "  User: $username" -ForegroundColor Gray
    
    $sqlcmdArgs = @(
        "-S", $serverAddress,
        "-U", $username,
        "-P", $password,
        "-i", $tempSqlFile,
        "-I",  # Enable quoted identifiers
        "-b"   # Exit with error code on SQL error
    )
    
    & sqlcmd @sqlcmdArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDatabase initialization completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Error "SQL script execution failed with exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}
catch {
    Write-Error "Failed to execute SQL script: $_"
    exit 1
}
finally {
    # Clean up temporary file
    if (Test-Path $tempSqlFile) {
        Remove-Item $tempSqlFile -Force
        
        Write-Host "  Temporary file cleaned up" -ForegroundColor Gray
    }
}

Write-Host "`nScript execution completed!" -ForegroundColor Cyan
