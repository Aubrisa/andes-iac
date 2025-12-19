# Aubrisa Andes - Azure Deployment

## Architecture Overview

```mermaid
graph TB
    %% External
    Internet[Internet Users]
    AzureFrontDoor[Azure Front Door<br/>Global CDN & WAF]
    
    %% Compute Layer
    subgraph AppServicePlan["App Service Plan (Linux, P1v3)"]
        subgraph WebServices["Web-Facing Services"]
            UIApp[UI App Service<br/>app-service-[env]-ui]
            APIApp[API App Service<br/>app-service-[env]-api]
            ChatApp[Chat API App Service<br/>app-service-[env]-chat-api]
        end
        subgraph BackendServices["Backend Services"]
            ReportService[Report Service<br/>app-service-[env]-report-service]
            LoadService[Load Service<br/>app-service-[env]-load-service]
            AdjustmentService[Adjustment Service<br/>app-service-[env]-adjustment-service]
            MurexService[Murex Calculation Service<br/>app-service-[env]-murex-calculation-service]
        end
    end
    
    %% Database Layer
    subgraph SQLServer["SQL Server ([env]-database-server)"]
        StoreDB[(Andes_Store_[Env]<br/>Hyperscale Gen5)]
        AppDB[(Andes_App_[Env]<br/>Hyperscale Gen5)]
    end
    
    %% Storage & Messaging
    StorageAccount[Storage Account<br/>[env]apistorage]
    ServiceBus[Service Bus<br/>service-bus-[env]]
    
    %% Monitoring & Logging
    LogAnalytics[Log Analytics Workspace<br/>log-analytics-workspace-[env]]
    AppInsights[Application Insights<br/>app-insights-[env]]
    
    %% Connections
    Internet --> AzureFrontDoor
    AzureFrontDoor -.->|"[env].[domain]"| UIApp
    AzureFrontDoor -.->|"api.[env].[domain]"| APIApp
    AzureFrontDoor -.->|"chat.[env].[domain]"| ChatApp
    
    UIApp --> StoreDB
    UIApp --> AppDB
    APIApp --> StoreDB
    APIApp --> AppDB
    APIApp --> StorageAccount
    APIApp --> ServiceBus
    
    ChatApp --> ServiceBus
    ChatApp --> AppInsights
    
    ReportService --> StoreDB
    ReportService --> StorageAccount
    ReportService --> ServiceBus
    LoadService --> StoreDB
    LoadService --> StorageAccount
    LoadService --> ServiceBus
    AdjustmentService --> StoreDB
    AdjustmentService --> ServiceBus
    MurexService --> StoreDB
    MurexService --> ServiceBus
    
    %% Monitoring connections
    UIApp --> AppInsights
    APIApp --> AppInsights
    ReportService --> AppInsights
    LoadService --> AppInsights
    AdjustmentService --> AppInsights
    MurexService --> AppInsights
    
    AppInsights --> LogAnalytics
```

## Resource Inventory

| Resource Type | Resource Name | Description |
| --- | --- | --- |
| **App Service Plan** | `app-service-plan-[env]` | Linux-based P1v3 plan hosting all application services |
| **App Services** | `app-service-[env]-ui`<br/>`app-service-[env]-api`<br/>`app-service-[env]-chat-api`<br/>`app-service-[env]-report-service`<br/>`app-service-[env]-load-service`<br/>`app-service-[env]-adjustment-service`<br/>`app-service-[env]-murex-calculation-service` | Web-facing services (UI, API, Chat) + backend services (Report, Load, Adjustment, Murex) |
| **SQL Server** | `[env]-database-server` | Azure SQL Server with admin authentication |
| **SQL Databases** | `Andes_Store_[DisplayName]`<br/>`Andes_App_[DisplayName]` | Hyperscale Gen5 (2 vCore) databases for store and application data |
| **SQL Firewall Rules** | `AllowAzureServices` | Enables Azure services to access SQL Server (0.0.0.0-0.0.0.0) |
| **Storage Account** | `[env]apistorage` | Standard LRS storage with multiple file shares |
| **File Shares** | `andes-api-data`<br/>`andes-api-reports`<br/>`andes-load-data`<br/>`andes-load-definitions`<br/>`andes-load-messages` | Shared storage for different services and data types |
| **Service Bus Namespace** | `service-bus-[env]` | Standard tier messaging service |
| **Log Analytics Workspace** | `log-analytics-workspace-[env]` | Centralized logging with 90-day retention, 1GB daily quota |
| **Application Insights** | `app-insights-[env]` | Application performance monitoring and telemetry |
| **Azure Front Door Profile** | `aubrisa-main-fd` | Global CDN and load balancer (Standard tier) |
| **Front Door Endpoints** | `ui-[env]`<br/>`api-[env]`<br/>`chat-api-[env]` | Custom domain routing to respective app services |
| **WAF Policy** | `aubrisa-main-waf` | Web Application Firewall policy for Front Door |
| **DNS Records** | `[env].[domain]`<br/>`api.[env].[domain]`<br/>`chat.[env].[domain]` | Custom domain CNAME records pointing to Front Door |

## Key Features

### Security
- **Azure SQL Server** with firewall rules allowing only Azure services
- **Azure Front Door** with Web Application Firewall (WAF) protection
- **Key Vault integration** for sensitive configuration (passwords, API keys)
- **Managed identities** for secure service-to-service communication

### Scalability
- **App Service Plan** can be scaled up/down based on demand
- **Hyperscale databases** provide automatic scaling capabilities
- **Azure Front Door** provides global load balancing and caching

### Monitoring & Observability
- **Application Insights** for application performance monitoring
- **Log Analytics Workspace** for centralized logging
- **Connection strings** configured for all services to report telemetry

### High Availability
- **Azure Front Door** provides global distribution and failover
- **Multiple app services** can be deployed across availability zones
- **SQL Server** includes automated backups and geo-replication options

## Prerequisites

1. **Azure Subscription** with Contributor access
2. **Resource Group** for deployment
3. **Azure Key Vault** with required secrets:
   - `db-admin-password-dev01` - Database admin password
   - `github-token` - Container registry authentication
   - `azuread-api-key` - Azure AD API key
   - `chat-api-key` - Chat service API key
   - `ai-api-key` - AI service API key
   - `ai-search-api-key` - AI Search service API key
4. **DNS Zone** in Azure DNS or external provider
5. **Container Registry** access (GitHub Container Registry)
6. **Azure CLI** with appropriate permissions

## Deployment Steps

1. **Configure Parameters**: Update environment-specific parameter files
2. **Deploy Infrastructure**: Run Bicep deployment command
3. **Configure Custom Domains**: Set up DNS records for Front Door
4. **Verify Services**: Ensure all app services are running and accessible

## Service Configuration

Each app service includes:
- **Container deployment** from GitHub Container Registry
- **Environment variables** for database connections, API keys, and service configuration
- **Application Insights** integration for monitoring
- **File share mounts** for persistent storage (where applicable)
- **Service Bus** connectivity for inter-service messaging