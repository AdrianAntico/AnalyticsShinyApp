param(
  [string]$Version = "1.0.0-buildweek"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$releaseDir = Join-Path $repoRoot "release"
$stageRoot = Join-Path $env:TEMP "AnalyticsWorkstationRelease-$Version"
$stageApp = Join-Path $stageRoot "AnalyticsWorkstation-$Version"
$zipPath = Join-Path $releaseDir "AnalyticsWorkstation-$Version.zip"
$tarballSource = Join-Path $repoRoot "AnalyticsShinyApp_1.0.0.tar.gz"
$tarballPath = Join-Path $releaseDir "AnalyticsShinyApp_1.0.0.tar.gz"
$shaPath = Join-Path $releaseDir "SHA256.txt"

if (Test-Path $stageRoot) {
  Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stageApp | Out-Null
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$excludeDirs = @(".git", ".Rproj.user", ".agents", "AnalyticsShinyApp.Rcheck", "exports", "runtime", "project_artifact_collector", "release", "node_modules")
$excludeFiles = @("*.Rproj", "*.zip", "autoplots_project.rds")

robocopy $repoRoot $stageApp /E /XD $excludeDirs /XF $excludeFiles | Out-Null
$code = $LASTEXITCODE
if ($code -gt 7) {
  throw "robocopy failed with exit code $code"
}

if (Test-Path $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path $stageApp -DestinationPath $zipPath -CompressionLevel Optimal

if (Test-Path $tarballSource) {
  Copy-Item -LiteralPath $tarballSource -Destination $tarballPath -Force
}

$hashLines = @()
foreach ($path in @($zipPath, $tarballPath)) {
  if (Test-Path $path) {
    $hash = Get-FileHash -Algorithm SHA256 -LiteralPath $path
    $hashLines += "$($hash.Hash)  $(Split-Path -Leaf $path)"
  }
}
$hashLines | Set-Content -Path $shaPath -Encoding UTF8

Write-Host "Release package created:"
Write-Host "  $zipPath"
Write-Host "SHA256:"
Write-Host "  $shaPath"
