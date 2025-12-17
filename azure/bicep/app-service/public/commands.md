# Setup

## Key Vault
Setup
`az keyvault create --name aubrisa-general-keyvault --resource-group "aubrisa-general" --location "UK South"`

Add keys

`az keyvault secret set --vault-name "aubrisa-general-keyvault" --name "entraid-api-key" --value "Azure AD API key"`
`az keyvault secret set --vault-name "aubrisa-general-keyvault" --name "github-token" --value "Github PAT"`

Upload Certificate
`az keyvault certificate import --vault-name "aubrisa-general-keyvault" -n "aubrisa-com" -f "/path/to/STAR_aubrisa_com.pem" -p PASSWORD`

Enable for template deployment:
`az keyvault update  --name aubrisa-general-keyvault --enabled-for-template-deployment true`

# Set to subscription
`az account set -s [subscription id]`

# Create Resource Group
`az group create --name andes-dev-01 --location "UK South"`

# Deploy main.bicep file
`az deployment group create --resource-group andes-dev-01 --template-file main.bicep --parameters main.parameters.json`

# Cleanup
`az group delete --name andes-dev-01`
