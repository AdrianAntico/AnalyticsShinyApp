# Analytics Workstation 1.0.0-buildweek

Release candidate: Build Week package and desktop installation foundation.

## What This Release Is

Analytics Workstation is an evidence-governed AI investigation platform. This release packages the Build Week experience as a Windows-oriented per-user desktop product.

## Included

- Installable R package: `AnalyticsShinyApp` version `1.0.0`.
- Product release label: `1.0.0-buildweek`.
- One-command Windows installer: `install_windows.ps1`.
- Double-click wrapper: `install_windows.cmd`.
- Repair and uninstall scripts.
- Per-user application install under `%LOCALAPPDATA%\Programs\Analytics Workstation`.
- Per-user writable state under `%LOCALAPPDATA%\AnalyticsWorkstation`.
- Stable Start Menu launcher.
- Electron shell resources and launcher preparation.
- Dependency installer covering direct dependencies, optional capability packages, first-party packages, and recursive dependencies.
- Package, installation, dependency, and Electron diagnostics.
- Build Week governed investigation demo.

## Known Limitations

- Electron dependency installation requires Node.js and npm. If unavailable, the installer completes with an explicit warning and the browser launcher remains available.
- This release prepares a desktop Electron shell but does not yet produce a signed native `.exe` installer.
- Windows taskbar pinning is manual because modern Windows restricts reliable programmatic taskbar pinning.

## Install

From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install_windows.ps1
```

## Validate

Inside R:

```r
library(AnalyticsShinyApp)
workstation_diagnostics()
qa_package_distribution()
qa_electron_distribution()
```
