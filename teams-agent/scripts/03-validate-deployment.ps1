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

Write-Host "==> Azure bot info"
$endpoint = az bot show --resource-group $ResourceGroup --name $BotName --query properties.endpoint -o tsv
Write-Host "Configured endpoint: $endpoint"

if ($endpoint -ne $EndpointUrl) {
  Write-Warning "Endpoint mismatch. Expected: $EndpointUrl"
}

Write-Host "==> Teams channel status"
$teams = az bot msteams show --resource-group $ResourceGroup --name $BotName -o json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $teams) {
  Write-Warning "Teams channel not found/enabled."
} else {
  Write-Host "Teams channel enabled."
}

Write-Host "==> Public endpoint probe"
try {
  $resp = Invoke-WebRequest -Uri $EndpointUrl -Method Get -MaximumRedirection 0 -ErrorAction Stop
  Write-Host "HTTP status: $($resp.StatusCode)"
} catch {
  if ($_.Exception.Response) {
    Write-Host "HTTP status: $([int]$_.Exception.Response.StatusCode)"
  } else {
    Write-Warning "Endpoint request failed: $($_.Exception.Message)"
  }
}
