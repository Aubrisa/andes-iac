# Secure Chat API for Microsoft Bot Framework

## Overview

This configuration enables public access to the chat API endpoint while restricting it to Microsoft Bot Framework using multiple security layers.

## Security Layers

### 1. Security Group (Network Layer)
- **Location**: `network.yaml` - `AlbChatSecurityGroup`
- **Protection**: Restricts ingress to Microsoft Bot Framework IP addresses only
- **IP Ranges**: Updated with official Microsoft Bot Service IPs (Americas, Europe, Asia Pacific)
- **Ports**: HTTPS (443) for Bot Framework, HTTP (80) for redirect only

### 2. WAF (Application Layer)
- **Location**: `waf-chat.yaml`
- **Protection**: 
  - IP allowlist verification (double-checks Bot Framework IPs)
  - Rate limiting (2000 requests per 5 minutes per IP)
  - AWS Managed Rules for common attacks
  - Known bad inputs blocking
- **Logging**: CloudWatch Logs in `/aws/wafv2/{AppName}-{Environment}-chat`

### 3. Application Authentication (Required)
⚠️ **CRITICAL**: Your chat API application code **MUST** validate JWT tokens from Microsoft Bot Framework.

**Implementation Required**:
```csharp
// In your chat API, validate the token from Bot Framework
// Microsoft.Bot.Connector.Authentication NuGet package
var authHeader = Request.Headers["Authorization"];
var credentials = new MicrosoftAppCredentials(appId, appPassword);
var claimsIdentity = await JwtTokenValidation.ValidateAuthHeader(
    authHeader, 
    credentials, 
    channelId, 
    serviceUrl
);
```

## Architecture

```
Microsoft Bot Framework → Internet → Public ALB (WAF + SG) → Private Subnet (ECS Chat Service)
```

- **Public ALB**: Internet-facing load balancer in public subnets
- **ECS Service**: Remains in private subnets (no direct internet access)
- **Network Flow**: Bot Framework → Public ALB → Private ECS containers

## Files Modified/Created

### New Files
1. `alb-chat-public.yaml` - Public ALB for chat API only
2. `waf-chat.yaml` - WAF with IP restrictions and rate limiting

### Modified Files
1. `network.yaml` - Added `AlbChatSecurityGroup` with Bot Framework IPs
2. `app.yaml` - Added WAF and public ALB stacks
3. `params/app-dev.json` - Added required parameters

## Deployment Steps

### 1. Configure Parameters

Edit `params/app-dev.json`:

```json
{
  "ParameterKey": "PublicSubnet1Id",
  "ParameterValue": "subnet-xxxxxxxxx"  // Your public subnet in AZ1
},
{
  "ParameterKey": "PublicSubnet2Id",
  "ParameterValue": "subnet-yyyyyyyyy"  // Your public subnet in AZ2
},
{
  "ParameterKey": "ChatDomainName",
  "ParameterValue": "chat-api.aubrisa.dev"  // Your public domain for chat API
}
```

### 2. Ensure Public Subnets Exist

Your VPC needs public subnets with:
- Internet Gateway attached
- Route table with `0.0.0.0/0` → IGW route
- Auto-assign public IP enabled (or ALB will handle)

### 3. Deploy Stack

```powershell
cd aws\scripts
.\2-deploy-stack.ps1
```

### 4. Get Chat API URL

After deployment:
```powershell
aws cloudformation describe-stacks `
  --stack-name andes-dev `
  --query "Stacks[0].Outputs[?OutputKey=='ChatApiUrl'].OutputValue" `
  --output text
```

### 5. Configure Bot Framework

1. Go to Azure Portal → Bot Services → Your Bot
2. Navigate to **Configuration** → **Messaging endpoint**
3. Set endpoint to: `https://chat-api.aubrisa.dev/api/messages`
4. Save and test connection

## Monitoring

### WAF Logs
```powershell
# View blocked requests
aws logs tail /aws/wafv2/andes-dev-chat --follow
```

### ALB Access Logs
Enable ALB access logs in `alb-chat-public.yaml` if needed for detailed traffic analysis.

### CloudWatch Metrics
- WAF: `AWS/WAFV2` namespace
- ALB: `AWS/ApplicationELB` namespace
- Metrics: `AllowedRequests`, `BlockedRequests`, `RequestCount`

## Maintenance

### Updating Bot Framework IPs

Microsoft may add new IP ranges. Update both:

1. **network.yaml** - `AlbChatSecurityGroup` ingress rules
2. **waf-chat.yaml** - `BotFrameworkIpSet` addresses

Check official list: https://learn.microsoft.com/azure/bot-service/bot-service-ip-addresses

Then redeploy:
```powershell
.\2-deploy-stack.ps1
```

## Cost Estimate

- **ALB**: ~$16-25/month (internet-facing)
- **WAF**: ~$5/month + $1 per million requests
- **Data Transfer**: Varies based on usage
- **Total**: ~$25-35/month baseline

## Troubleshooting

### Bot Framework Can't Connect

1. **Check Security Group**: Verify IPs in `network.yaml` match Microsoft's latest list
2. **Check WAF**: Review WAF logs for blocked requests
3. **Check DNS**: Ensure chat domain resolves to ALB
4. **Check Certificate**: ACM certificate must be validated

### Rate Limiting Issues

Increase rate limit in WAF:
```yaml
RateLimitPerFiveMinutes: 5000  # Increase from 2000
```

### View Blocked Requests
```powershell
aws wafv2 get-sampled-requests `
  --web-acl-arn <WebAclArn> `
  --rule-metric-name RateLimitRule `
  --scope REGIONAL `
  --time-window StartTime=<timestamp>,EndTime=<timestamp> `
  --max-items 100
```

## Security Best Practices

✅ **Implemented**:
- Network-level IP restrictions (Security Group)
- Application-level IP restrictions (WAF)
- Rate limiting
- HTTPS only (TLS 1.3)
- Managed WAF rules for common attacks

⚠️ **Required in Application Code**:
- JWT token validation from Bot Framework
- Request signature verification
- Activity type validation
- Conversation ID validation

## Alternative: Disable WAF

If you want to rely on Security Groups only (not recommended but cost-saving):

1. Remove `WafWebAclArn` parameter from `alb-chat-public.yaml`
2. Comment out `WafChatStack` in `app.yaml`
3. Redeploy

Security will still rely on Security Group IP restrictions, but without rate limiting or managed rules.
