[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$SubscriptionId,
  [Parameter(Mandatory=$true)][string]$TenantId,
  [Parameter(Mandatory=$true)][string]$ResourceGroup,
  [Parameter(Mandatory=$true)][string]$Location,
  [Parameter(Mandatory=$true)][string]$BotName,
  [Parameter(Mandatory=$true)][string]$EndpointUrl
)

$ErrorActionPreference = 'Stop'

function Require-Cli {
  param([string]$Name)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required CLI not found: $Name"
  }
}

Require-Cli -Name az

Write-Host "==> Azure login"
az login --tenant $TenantId | Out-Null
az account set --subscription $SubscriptionId

Write-Host "==> Ensure bot extension"
az extension add --name botservice --upgrade | Out-Null

Write-Host "==> Create/lookup AAD app"
$app = az ad app list --display-name $BotName --query "[0]" -o json | ConvertFrom-Json
if (-not $app) {
  $app = az ad app create --display-name $BotName -o json | ConvertFrom-Json
}
$appId = $app.appId

Write-Host "==> Reset/create client secret"
$secret = az ad app credential reset --id $appId --append --display-name "openclaw-teams-secret" --years 2 --query password -o tsv

Write-Host "==> Ensure service principal"
$sp = az ad sp list --filter "appId eq '$appId'" --query "[0]" -o json | ConvertFrom-Json
if (-not $sp) {
  az ad sp create --id $appId | Out-Null
}

Write-Host "==> Ensure resource group"
az group create --name $ResourceGroup --location $Location | Out-Null

Write-Host "==> Create/update Azure Bot"
$botExists = az bot show --name $BotName --resource-group $ResourceGroup --query name -o tsv 2>$null
if (-not $botExists) {
  az bot create `
    --resource-group $ResourceGroup `
    --name $BotName `
    --kind registration `
    --endpoint $EndpointUrl `
    --appid $appId `
    --password $secret `
    --location global | Out-Null
} else {
  az bot update `
    --resource-group $ResourceGroup `
    --name $BotName `
    --endpoint $EndpointUrl | Out-Null
}

Write-Host "==> Enable Microsoft Teams channel"
az bot msteams create --resource-group $ResourceGroup --name $BotName | Out-Null

Write-Host ""
Write-Host "Deployment complete. Save these securely:"
Write-Host "MICROSOFT_APP_ID=$appId"
Write-Host "MICROSOFT_APP_PASSWORD=$secret"
Write-Host "AZURE_TENANT_ID=$TenantId"
Write-Host "BOT_ENDPOINT=$EndpointUrl"
