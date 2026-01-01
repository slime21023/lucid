$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot\..

New-Item -ItemType Directory -Force coverage | Out-Null

$coverageJson = "coverage/coverage.json"
$coverageCsv = "coverage/unreachable.csv"
$summaryTxt = "coverage/summary.txt"

crystal tool unreachable --tallies -f codecov spec/runner.cr | Out-File -FilePath $coverageJson -Encoding UTF8
crystal tool unreachable --tallies -f csv spec/runner.cr | Out-File -FilePath $coverageCsv -Encoding UTF8

$rows = Import-Csv -Path $coverageCsv
$srcRows = $rows | Where-Object { $_.file -match '^src[\\/]' }

if (-not $srcRows -or $srcRows.Count -eq 0) {
  "No methods found under src/." | Out-File -FilePath $summaryTxt -Encoding UTF8
  Write-Output "No methods found under src/."
  exit 0
}

$total = $srcRows.Count
$covered = ($srcRows | Where-Object { [int]$_.count -gt 0 }).Count
$pct = [math]::Round(($covered * 100.0) / $total, 2)

$summary = @(
  "Reachability (methods under src/): $covered/$total ($pct%)"
  "Report files:"
  "- coverage/coverage.json (codecov format)"
  "- coverage/unreachable.csv (counts + locations)"
) -join "`r`n"

$summary | Out-File -FilePath $summaryTxt -Encoding UTF8
Write-Output $summary
