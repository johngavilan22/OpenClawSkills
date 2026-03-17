[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$SubscriptionId,
  [Parameter(Mandatory=$true)][string]$TenantId,
  [Parameter(Mandatory=$true)][string]$ResourceGroup,
  [Parameter(Mandatory=$true)][string]$Location,
  [Parameter(Mandatory=$true)][string]$CsvPath,
  [string]$DomainSuffix,
  [string]$OutputDir = "./generated-envs",
  [int]$PauseSeconds = 2
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $CsvPath)) {
  throw "CSV file not found: $CsvPath"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$createScript = Join-Path $scriptDir "01-create-personal-bot.ps1"

if (-not (Test-Path $createScript)) {
  throw "Missing dependency script: $createScript"
}

if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$rows = Import-Csv -Path $CsvPath
if (-not $rows -or $rows.Count -eq 0) {
  throw "CSV has no rows."
}

$results = @()

foreach ($row in $rows) {
  $alias = $row.alias
  if (-not $alias) {
    Write-Warning "Skipping row with missing alias"
    continue
  }

  $botName = $row.botname
  if (-not $botName) {
    $botName = "oc-$alias-bot"
  }

  $domain = $row.domain
  if (-not $domain -and $DomainSuffix) {
    $domain = "$alias-$DomainSuffix"
  }

  if (-not $domain) {
    Write-Warning "Skipping alias '$alias' because domain is missing (and DomainSuffix not provided)."
    $results += [PSCustomObject]@{ alias=$alias; botname=$botName; domain=$domain; status='skipped'; note='missing domain' }
    continue
  }

  $endpointUrl = "https://$domain/api/messages"
  $envPath = Join-Path $OutputDir ".env.$alias.generated"

  Write-Host "Provisioning alias=$alias bot=$botName endpoint=$endpointUrl"

  try {
    & pwsh $createScript `
      -SubscriptionId $SubscriptionId `
      -TenantId $TenantId `
      -ResourceGroup $ResourceGroup `
      -Location $Location `
      -UserAlias $alias `
      -BotName $botName `
      -EndpointUrl $endpointUrl `
      -OutputEnvPath $envPath

    $results += [PSCustomObject]@{ alias=$alias; botname=$botName; domain=$domain; status='ok'; note=$envPath }
  }
  catch {
    $results += [PSCustomObject]@{ alias=$alias; botname=$botName; domain=$domain; status='failed'; note=$_.Exception.Message }
    Write-Warning "Failed alias=$alias : $($_.Exception.Message)"
  }

  if ($PauseSeconds -gt 0) {
    Start-Sleep -Seconds $PauseSeconds
  }
}

$reportPath = Join-Path $OutputDir "bulk-provision-report.csv"
$results | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host ""
Write-Host "Bulk provisioning complete."
Write-Host "Report: $reportPath"
Write-Host "Generated env files directory: $OutputDir"
