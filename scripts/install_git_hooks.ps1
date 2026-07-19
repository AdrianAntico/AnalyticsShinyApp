$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$sourceHook = Join-Path $repoRoot ".githooks\pre-push"
$targetDir = Join-Path $repoRoot ".git\hooks"
$targetHook = Join-Path $targetDir "pre-push"

if (!(Test-Path $sourceHook)) {
  throw "Source hook not found: $sourceHook"
}

if (!(Test-Path $targetDir)) {
  throw "Git hooks directory not found: $targetDir"
}

Copy-Item -LiteralPath $sourceHook -Destination $targetHook -Force

Write-Host "Installed Analytics Workstation pre-push hook:"
Write-Host $targetHook
Write-Host ""
Write-Host "The hook runs scripts/pre_push_release_check.R before every push."
Write-Host "For an emergency bypass, set AW_SKIP_PRE_PUSH=1 explicitly before pushing."
