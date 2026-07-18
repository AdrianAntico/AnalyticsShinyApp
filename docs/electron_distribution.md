# Electron Distribution

Analytics Workstation uses an Electron shell as a desktop wrapper around the local Shiny runtime.

The current Build Week distribution prepares a per-user Electron development shell rather than a signed native installer.

## Runtime Behavior

The Electron main process:

1. Resolves the installed app source.
2. Finds `Rscript.exe`.
3. Selects a localhost port.
4. Starts the installed Shiny app.
5. Waits for an HTTP health response.
6. Opens the Electron window only after the app is reachable.
7. Writes launch logs to `%LOCALAPPDATA%\AnalyticsWorkstation\logs`.
8. Stops the owned R process when the Electron window closes.

It does not kill unrelated R processes.

## Files

Package resources:

```text
inst/electron/package.json
inst/electron/main.js
```

Installed shell:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\electron
```

Launcher:

```text
%LOCALAPPDATA%\Programs\Analytics Workstation\Analytics Workstation Electron.cmd
```

## Node and npm

If Node.js and npm are available, the installer runs:

```text
npm install
```

inside the installed Electron directory.

If Node.js or npm is missing, installation still completes with an Electron warning. The standard R/Shiny launcher remains available.

## Logs

Electron/Shiny launch logs are written to:

```text
%LOCALAPPDATA%\AnalyticsWorkstation\logs\electron-shiny.log
%LOCALAPPDATA%\AnalyticsWorkstation\logs\electron-shiny-error.log
%LOCALAPPDATA%\AnalyticsWorkstation\logs\electron-shiny.pid
```

## Known Limitation

This phase prepares a reliable desktop shell and launcher. It does not yet produce a signed `.exe` installer or automatic taskbar pinning. Those remain distribution hardening tasks after the Build Week package foundation is stable.
