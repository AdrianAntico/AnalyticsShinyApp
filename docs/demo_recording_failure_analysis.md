# Demo Recording Failure Analysis

## Failure

The previous `docs/media/demo.webm` was recorded before the public demo route had proven that the workstation shell, CSS, and required assets were fully applied. The result looked like browser-default UI instead of Analytics Workstation.

## Root Cause

The recorder treated DOM presence as readiness. Shiny had served enough HTML for Playwright to continue, but the recording pipeline did not require:

- a connected Shiny session;
- the target route to be active and visible;
- `aw-assets/app.css` to be loaded;
- Analytics Workstation CSS variables to exist on `body`;
- layout dimensions to stabilize;
- required assets to avoid failed requests.

That made the recording pipeline capable of producing a technically valid video with invalid styling.

## Fix

The app now publishes a deterministic DOM readiness signal through `window.__awDomReady`. The signal becomes ready only when:

- Shiny is connected;
- the active route has rendered;
- `aw-assets/app.css` is present;
- core CSS variables are populated;
- the active pane has stable dimensions.

The public Build Week recorder waits for that signal and then performs computed-style assertions before recording the primary sequence.

## Prevention

The recorder now fails loudly when:

- the page background is browser-default white;
- workstation CSS variables are missing;
- the logo is not visible;
- the Build Week route is not rendered;
- primary controls are unstyled;
- required assets fail to load.

The recording should never again produce misleading public media just because the page technically loaded.
