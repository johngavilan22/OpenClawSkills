[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$SubscriptionId,
  [Parameter(Mandatory=$true)][string]$ResourceGroup,
  [Parameter(Mandatory=$true)][string]$BotName,
  [Parameter(Mandatory=$true)][string]$EndpointUrl
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI (az) not found"
}

az account set --subscription $SubscriptionId

$configuredEndpoint = az bot show --resource-group $ResourceGroup --name $BotName --query properties.endpoint -o tsv
Write-Host "Configured endpoint: $configuredEndpoint"
if ($configuredEndpoint -ne $EndpointUrl) {
  Write-Warning "Endpoint mismatch (expected $EndpointUrl)"
}

$teams = az bot msteams show --resource-group $ResourceGroup --name $BotName -o json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $teams) {
  Write-Warning "Teams channel not enabled"
} else {
  Write-Host "Teams channel: enabled"
}

try {
  $resp = Invoke-WebRequest -Uri $EndpointUrl -Method Get -MaximumRedirection 0 -ErrorAction Stop
  Write-Host "Endpoint HTTP status: $($resp.StatusCode)"
} catch {
  if ($_.Exception.Response) {
    Write-Host "Endpoint HTTP status: $([int]$_.Exception.Response.StatusCode)"
  } else {
    Write-Warning "Endpoint probe failed: $($_.Exception.Message)"
  }
}
