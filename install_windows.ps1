param(
  [switch]$DesktopShortcut
)

$ErrorActionPreference = "Stop"

function Find-Rscript {
  $candidates = @(
    "$env:R_HOME\bin\Rscript.exe",
    "C:\Program Files\R\R-4.5.2\bin\Rscript.exe",
    "C:\Program Files\R\R-4.5.1\bin\Rscript.exe",
    "C:\Program Files\R\R-4.4.3\bin\Rscript.exe",
    "Rscript.exe"
  )

  foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
    $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($resolved) { return $resolved.Source }
    if (Test-Path $candidate) { return $candidate }
  }

  throw "Rscript.exe was not found. Install R 4.5.x or add Rscript.exe to PATH."
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $repoRoot "scripts\install_workstation.R"
if (!(Test-Path $scriptPath)) {
  throw "Cannot find scripts\install_workstation.R. Run this installer from the AnalyticsShinyApp repository root."
}

$logRoot = Join-Path $env:LOCALAPPDATA "AnalyticsWorkstation\logs"
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $logRoot "install_windows_$timestamp.log"
$rscript = Find-Rscript

Write-Host "Analytics Workstation installer"
Write-Host "Repository: $repoRoot"
Write-Host "Rscript:    $rscript"
Write-Host "Log:        $logPath"
Write-Host ""

$args = @($scriptPath)
if ($DesktopShortcut) {
  $args += "--desktop"
}

Push-Location $repoRoot
try {
  & $rscript @args 2>&1 | Tee-Object -FilePath $logPath
  if ($LASTEXITCODE -ne 0) {
    throw "Installation failed with exit code $LASTEXITCODE. See log: $logPath"
  }
}
finally {
  Pop-Location
}

Write-Host ""
Write-Host "Analytics Workstation installation completed."
Write-Host ""
Write-Host "To open:"
Write-Host "  Start Menu > Analytics Workstation"
Write-Host ""
Write-Host "To pin to the taskbar:"
Write-Host "  1. Open Analytics Workstation."
Write-Host "  2. Right-click its taskbar icon."
Write-Host "  3. Select `"Pin to taskbar.`""
Write-Host ""
Write-Host "Logs:"
Write-Host "  $logPath"
