param(
  [string]$Remote = "origin",
  [string]$Refspec = "HEAD"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$rscript = Get-Command Rscript -ErrorAction SilentlyContinue
if ($null -ne $rscript) {
  $rscriptPath = $rscript.Source
} else {
  $candidates = @(
    "C:\Program Files\R\R-4.5.2\bin\Rscript.exe",
    "C:\Program Files\R\R-4.5.1\bin\Rscript.exe",
    "C:\Program Files\R\R-4.5.0\bin\Rscript.exe",
    "C:\Program Files\R\R-4.4.3\bin\Rscript.exe"
  )
  $rscriptPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($rscriptPath)) {
  throw "Rscript was not found. Install R or add Rscript.exe to PATH before guarded push."
}

Write-Host "Analytics Workstation guarded push"
Write-Host "Repository: $repoRoot"
Write-Host "Remote:     $Remote"
Write-Host "Refspec:    $Refspec"
Write-Host "Rscript:    $rscriptPath"

& $rscriptPath scripts/pre_push_release_check.R

if ($LASTEXITCODE -ne 0) {
  throw "Release-steward validation failed. Push aborted."
}

$env:AW_PRE_PUSH_ALREADY_VALIDATED = "1"
git push $Remote $Refspec

if ($LASTEXITCODE -ne 0) {
  throw "git push failed."
}

Write-Host ""
Write-Host "Guarded push completed."
