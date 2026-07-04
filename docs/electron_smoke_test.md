# Electron Smoke Test Notes

## Electron wrapper repository

The Electron wrapper repository is separate from the Analytics Shiny App repository.

The Analytics Shiny App repository owns:

- Shiny app logic
- AutoPlots calls
- project state
- export behavior
- generated report code
- UI behavior inside the Shiny app

The Electron wrapper repository owns:

- Electron startup
- R/Shiny process launch
- desktop window behavior
- packaging
- local server lifecycle
- Electron-specific file/path behavior

When Electron smoke tests fail, first classify the issue as app-level or wrapper-level before changing code.

If the failure happens in both browser Shiny and Electron, fix the Analytics Shiny App repository.

Likely app-level failures:

- plot build fails in browser and Electron
- project save/load fails in browser and Electron
- export function fails in browser and Electron
- generated report code is wrong
- Shiny UI observer or reactive logic fails in both environments
- AutoPlots arguments are generated incorrectly

If the failure happens only in Electron, inspect and fix the Electron wrapper repository.

Likely wrapper-level failures:

- Electron app does not launch
- R/Shiny backend does not start
- browser Shiny works but Electron does not
- file paths behave differently only in Electron
- export permissions differ only in Electron
- app closes but the R process remains running
- packaged app cannot find R, packages, or app files
- environment variables or API keys are unavailable only in Electron

This boundary keeps Shiny app behavior and desktop runtime behavior from being tangled together during debugging.
