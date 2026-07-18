param(
  [switch]$RemoveUserData,
  [switch]$RemoveRPackage
)

$ErrorActionPreference = "Stop"

$programDir = Join-Path $env:LOCALAPPDATA "Programs\Analytics Workstation"
$userDataDir = Join-Path $env:LOCALAPPDATA "AnalyticsWorkstation"
$startShortcut = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs\Analytics Workstation.lnk"
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Analytics Workstation.lnk"

Write-Host "Uninstalling Analytics Workstation desktop assets."
Write-Host "User projects and configuration are preserved unless -RemoveUserData is supplied."

foreach ($path in @($startShortcut, $desktopShortcut)) {
  if (Test-Path $path) {
    Remove-Item -LiteralPath $path -Force
    Write-Host "Removed shortcut: $path"
  }
}

if (Test-Path $programDir) {
  Remove-Item -LiteralPath $programDir -Recurse -Force
  Write-Host "Removed installed application: $programDir"
}

if ($RemoveRPackage) {
  $rscript = Get-Command Rscript.exe -ErrorAction SilentlyContinue
  if ($rscript) {
    & $rscript.Source -e "if ('AnalyticsShinyApp' %in% rownames(installed.packages())) remove.packages('AnalyticsShinyApp')" | Write-Host
  } else {
    Write-Host "Rscript.exe not found; skipped R package removal."
  }
}

if ($RemoveUserData) {
  if (Test-Path $userDataDir) {
    Remove-Item -LiteralPath $userDataDir -Recurse -Force
    Write-Host "Removed user data: $userDataDir"
  }
} else {
  Write-Host "Preserved user data: $userDataDir"
}

Write-Host "Analytics Workstation uninstall completed."
