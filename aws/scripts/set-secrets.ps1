param(
    [Parameter(Mandatory=$true)]
    [string]$AppName,
    
    [Parameter(Mandatory=$true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory=$true)]
    [string]$EntraApiKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ChatApiKey,
    
    [Parameter(Mandatory=$true)]
    [string]$AiApiKey
)

Write-Host "Setting secrets for $AppName-$EnvironmentName..."

# Set Entra API Key
aws secretsmanager update-secret `
    --secret-id "$AppName/$EnvironmentName/entra-api-key" `
    --secret-string "{`"key`": `"$EntraApiKey`"}"

Write-Host "✓ Updated entra-api-key"

# Set Chat API Key
aws secretsmanager update-secret `
    --secret-id "$AppName/$EnvironmentName/chat-api-key" `
    --secret-string "{`"key`": `"$ChatApiKey`"}"

Write-Host "✓ Updated chat-api-key"

# Set AI API Key
aws secretsmanager update-secret `
    --secret-id "$AppName/$EnvironmentName/ai-api-key" `
    --secret-string "{`"key`": `"$AiApiKey`"}"

Write-Host "✓ Updated ai-api-key"

Write-Host "All secrets updated successfully!"