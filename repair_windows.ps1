param(
  [switch]$DesktopShortcut
)

$ErrorActionPreference = "Stop"
$installer = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "install_windows.ps1"
if (!(Test-Path $installer)) {
  throw "install_windows.ps1 was not found. Repair must be run from the AnalyticsShinyApp repository root."
}

Write-Host "Repairing Analytics Workstation."
Write-Host "Projects, exports, logs, and user configuration are preserved."

$args = @()
if ($DesktopShortcut) {
  $args += "-DesktopShortcut"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $installer @args
exit $LASTEXITCODE
