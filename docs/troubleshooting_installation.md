# Installation Troubleshooting

## Rscript Not Found

Symptom:

```text
Rscript.exe was not found
```

Install R 4.5.x or add R to PATH. The installer checks common locations including:

```text
C:\Program Files\R\R-4.5.2\bin\Rscript.exe
```

## Package Dependency Missing

Run the dependency installer directly:

```powershell
Rscript .\scripts\install_app_dependencies.R
```

Then rerun:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\repair_windows.ps1
```

The dependency installer checks direct app dependencies, optional capabilities, first-party packages, and dependency dependencies through normal R package installation.

## AutoQuant, AutoPlots, AutoNLS, or Rodeo Missing

The installer looks for first-party sibling repositories next to `AnalyticsShinyApp`:

```text
..\AutoQuant
..\AutoPlots
..\AutoNLS
..\Rodeo
```

If one is unavailable, the installer reports it explicitly. Place the repository in the expected sibling location or install the package manually into the active R library.

## Electron Does Not Open

Check whether Node.js and npm are available:

```powershell
node --version
npm --version
```

Then rerun repair:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\repair_windows.ps1
```

The browser launcher remains available even if Electron is not prepared.

## Blank Electron Window

The Electron shell waits for Shiny before opening the application. If startup fails, it should display an error screen.

Check logs:

```text
%LOCALAPPDATA%\AnalyticsWorkstation\logs\electron-shiny.log
%LOCALAPPDATA%\AnalyticsWorkstation\logs\electron-shiny-error.log
```

## Shortcut Opens Old Code

Run repair. Shortcuts should point to:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation.cmd
```

They should not point to a temporary checkout.

## Diagnostics

Inside R:

```r
library(AnalyticsShinyApp)
workstation_diagnostics()
qa_package_distribution()
qa_electron_distribution()
```

Use these before debugging individual screens. They classify missing package, runtime, dependency, Electron, and provider states explicitly.
