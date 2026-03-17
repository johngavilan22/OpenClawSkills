[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$SubscriptionId,
  [Parameter(Mandatory=$true)][string]$TenantId,
  [Parameter(Mandatory=$true)][string]$ResourceGroup,
  [Parameter(Mandatory=$true)][string]$Location,
  [Parameter(Mandatory=$true)][string]$UserAlias,
  [Parameter(Mandatory=$true)][string]$BotName,
  [Parameter(Mandatory=$true)][string]$EndpointUrl,
  [string]$OutputEnvPath = "./.env.$($UserAlias).generated"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI (az) not found"
}

az login --tenant $TenantId | Out-Null
az account set --subscription $SubscriptionId
az extension add --name botservice --upgrade | Out-Null

$app = az ad app list --display-name $BotName --query "[0]" -o json | ConvertFrom-Json
if (-not $app) {
  $app = az ad app create --display-name $BotName -o json | ConvertFrom-Json
}
$appId = $app.appId

$secret = az ad app credential reset --id $appId --append --display-name "openclaw-$UserAlias-secret" --years 2 --query password -o tsv

$sp = az ad sp list --filter "appId eq '$appId'" --query "[0]" -o json | ConvertFrom-Json
if (-not $sp) {
  az ad sp create --id $appId | Out-Null
}

az group create --name $ResourceGroup --location $Location | Out-Null

$exists = az bot show --name $BotName --resource-group $ResourceGroup --query name -o tsv 2>$null
if (-not $exists) {
  az bot create `
    --resource-group $ResourceGroup `
    --name $BotName `
    --kind registration `
    --location global `
    --endpoint $EndpointUrl `
    --appid $appId `
    --password $secret | Out-Null
} else {
  az bot update --resource-group $ResourceGroup --name $BotName --endpoint $EndpointUrl | Out-Null
}

az bot msteams create --resource-group $ResourceGroup --name $BotName | Out-Null

$envContent = @"
# Personal bot env for user alias: $UserAlias
MICROSOFT_APP_ID=$appId
MICROSOFT_APP_PASSWORD=$secret
AZURE_TENANT_ID=$TenantId
TEAMS_BOT_ENDPOINT=$EndpointUrl
TEAMS_BOT_NAME=$BotName
AZURE_SUBSCRIPTION_ID=$SubscriptionId
AZURE_RESOURCE_GROUP=$ResourceGroup
OPENCLAW_INSTANCE_ALIAS=$UserAlias
"@

Set-Content -Path $OutputEnvPath -Value $envContent -NoNewline

Write-Host "Personal bot bootstrap complete"
Write-Host "UserAlias=$UserAlias"
Write-Host "MICROSOFT_APP_ID=$appId"
Write-Host "MICROSOFT_APP_PASSWORD=$secret"
Write-Host "Generated env file: $OutputEnvPath"
Write-Host "Apply these values only to the dedicated OpenClaw instance for this user."
