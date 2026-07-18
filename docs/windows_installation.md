# Windows Installation

Analytics Workstation `1.0.0-buildweek` supports a per-user Windows installation. It does not require administrator privileges.

## Prerequisites

- Windows 10 or later.
- R 4.5.x, with `Rscript.exe` available.
- Internet access for first-time R package installation.
- Node.js and npm if you want the Electron desktop shell prepared.

The browser launcher works without Node.js. Electron setup is reported as a warning when Node.js or npm is unavailable.

## Install

From the repository root, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install_windows.ps1
```

For a Desktop shortcut:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install_windows.ps1 -DesktopShortcut
```

Double-click users may run:

```bat
install_windows.cmd
```

## Installed Locations

Main application launcher:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation.cmd
```

The main launcher opens Electron when Electron dependencies are installed. If Electron is not available, it falls back to the browser version.

Electron launcher:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation Electron.cmd
```

Browser fallback launcher:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation Browser.cmd
```

Installed application resources:

```text
R package library: AnalyticsShinyApp/app
```

User-writable state:

```text
%LOCALAPPDATA%\AnalyticsWorkstation
```

Standard subdirectories:

- `config/`
- `logs/`
- `projects/`
- `exports/`
- `cache/`
- `runtime/`

## Open the App

Use:

```text
Start Menu > Analytics Workstation
```

Or run the installed main launcher directly:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation.cmd
```

To force the Electron shell:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation Electron.cmd
```

To force the browser fallback:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation Browser.cmd
```

If Chrome or the default browser opens, the browser fallback path is being used rather than Electron.

## Pin to Taskbar

Windows restricts reliable automatic taskbar pinning.

1. Open Analytics Workstation.
2. Right-click its taskbar icon.
3. Select **Pin to taskbar**.

Pinning the app only saves convenient access. It does not save analytical work.

## Save and Reopen Work

- **Save Project** stores the current workstation state so it can be reopened later.
- **Export Report** creates a shareable analytical deliverable.
- **Close Application** stops the local app session.
- **Pin to Taskbar** creates convenient access to the application.

Projects are stored under:

```text
%LOCALAPPDATA%\AnalyticsWorkstation\projects
```

## Repair

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\repair_windows.ps1
```

Repair reinstalls package/dependency assets, recreates launchers, and preserves user projects by default.

## Uninstall

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall_windows.ps1
```

This removes installed desktop assets and shortcuts. It preserves projects, exports, logs, and configuration.

To also remove user data:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall_windows.ps1 -RemoveUserData
```

## Diagnostics

From R:

```r
library(AnalyticsShinyApp)
workstation_diagnostics()
qa_package_distribution()
qa_electron_distribution()
```

Diagnostics report R, package, user-data, launcher, Node/npm, Electron, dependency, and provider status without exposing secrets.
