# UI Architecture Doctrine

## Core UI Principle

Use as few external UI frameworks as practical.

Prefer app-owned UI helper functions, registries, and small composable conventions over adding UI dependencies. The UI should stay boring in the best sense: predictable, local-first, easy to inspect, and easy to extend without learning a new framework for every feature.

## Approved Baseline

The intended UI stack is:

- `shiny`
- `htmltools`
- minimal custom CSS
- a table package only when the app has a concrete table workflow that needs it

The app should use one primary layout or theme framework only if the need is clear. If a framework such as `bslib` or `bs4Dash` is added later, it should become the single app-level layout/theme framework rather than one of several competing systems.

Do not add dashboard, component, or styling packages unless they fit this baseline and solve a durable app-level problem.

## Dependency Rule

Add a new UI dependency only when it solves a hard, reusable problem.

Good reasons include:

- accessibility or keyboard behavior that is difficult to implement correctly
- robust table behavior needed across multiple workflows
- a single app-wide layout/theme system
- complex interactive controls that will be reused broadly

Weak reasons include:

- minor spacing or color tweaks
- one-off button or card styling
- replacing a small app-owned helper
- adding a package because one screen would be slightly quicker to build

Small visual needs should usually be handled with app-owned helper functions and minimal CSS.

## Internal UI Component Layer

The app should grow a small internal component layer before it grows external UI framework dependencies.

Planned helpers:

- `ui_card()`
- `ui_section_header()`
- `ui_empty_state()`
- `ui_status_badge()`
- `ui_action_row()`
- `ui_control_group()`
- `ui_preview_panel()`
- `ui_code_panel()`

These helpers should be plain Shiny/htmltools functions. They should standardize markup, labels, status display, spacing, and common interaction patterns without hiding business logic.

## Custom Widget And Module Extension Model

Custom functionality should be added through registries, not ad hoc Shiny observers.

Registries make the app inspectable and keep extension points explicit. A new plot type, option group, export target, artifact type, or GenAI-assisted tool should be discoverable through a registry entry before it appears in the UI.

Example registries:

- `plot_registry`
- `option_registry`
- `module_registry`
- `artifact_registry`
- `export_registry`
- `genai_tool_registry`

Registry entries should describe what the app shell needs to render, validate, execute, display, export, and save state. They should not require the app shell to know module-specific implementation details.

## Module Contract

A custom module should define:

- `id`
- `label`
- `ui` function
- `server` function, if needed
- `validate` function
- `run` function
- returned artifact types
- generated code
- metadata

Modules should return standard `service_result` objects. The shell can then handle messages, warnings, errors, artifacts, generated code, and metadata consistently.

The module contract should keep UI controls, validation, execution, and generated artifacts close to the module while still letting the app shell own navigation, state, layout, and persistence.

## Separation of Duties

Analytical modules create artifacts. Display and report pages select, arrange, and render artifacts.

### Artifact Generator Modules

Examples:

- Plot Builder
- EDA
- Forecasting
- Modeling
- Target Analysis
- GenAI Narrative

Artifact Generator modules own module-specific analytical work.

Responsibilities:

- collect module-specific configuration
- validate inputs
- run analysis, modeling, or forecasting
- create artifacts
- preview artifacts internally for tuning and customization
- return standard artifact objects

Non-responsibilities:

- final report layout
- global section ordering
- export orchestration
- project-level display decisions

Generator modules may include internal previews so users can tune a plot, model, forecast, table, or narrative before saving it. Those previews are local to the module workflow and should not become the final report composition system.

### Display / Report Pages

Display and Report pages own report composition.

Responsibilities:

- show artifact library
- select artifacts for report
- assign sections
- set ordering
- configure display mode
- render combined output
- export combined output

Non-responsibilities:

- running forecasting, modeling, or EDA logic
- owning module-specific configuration
- modifying raw analytical results

Display pages should treat artifacts as inputs. They can decide what is visible, where it appears, and how it is arranged, but they should not recalculate or mutate the analytical result behind the artifact.

### Artifact Library

The Artifact Library is the bridge between Artifact Generator modules and Display / Report pages.

It should track:

- `artifact_id`
- `artifact_type`
- `source_module`
- `label`
- `section`
- `order`
- `visible`
- `status`
- `config`
- `code`
- `metadata`

Generator modules add or update artifacts in the library. Display pages read from the library to compose reports. Project save/load should persist enough artifact metadata, configuration, and generated code to rebuild or repair report state without storing fragile runtime-only objects.

### Forecasting Example

A Forecasting module may generate several artifacts from one workflow:

- forecast plot
- actual vs fitted plot
- residual plot
- backtest metrics table
- forecast values table
- forecast summary text
- methodology/caveat text

The Forecasting module can preview these artifacts internally so the user can tune horizon, grouping, model settings, confidence intervals, backtest windows, and narrative settings. After the module returns standard artifacts, the Display page decides which artifacts belong in the report, which section they appear in, how they are ordered, and which display mode renders them.

### Display Function Direction

Preserve the current AutoPlots display direction for plot-only reports:

- `display_plots_grid()`
- `display_plots_sections()`

Potential plot-only additions:

- `display_plots_carousel()`

For mixed artifact reports, consider app-level or package-level display functions that handle plots, tables, text, metrics, and narrative artifacts:

- `display_report_grid()`
- `display_report_sections()`
- `display_report_carousel()`
- `display_report_canvas()`

The current `display_plots_grid()` and `display_plots_sections()` direction should remain valid for plot-focused reports. Mixed artifact display should extend the report layer without forcing generator modules to own report layout.

### Core Rule

Generator modules may preview artifacts internally, but final report composition belongs to the Display layer.

## Anti-Patterns

Avoid:

- mixing multiple dashboard frameworks
- one-off CSS hacks everywhere
- business logic inside UI code
- module-specific global state
- random JavaScript unless isolated
- adding packages for small visual tweaks
- custom observers that bypass the relevant registry
- UI code that mutates project state without going through standard app services

If a feature needs JavaScript, isolate it behind a narrow app-owned helper or module boundary and document why Shiny/htmltools alone is not enough.

## App Shell Rule

The app shell owns:

- navigation
- layout
- state
- artifact display
- export
- project save/load

Modules own:

- their own controls
- validation
- execution
- artifact generation

Modules should return standard `service_result` objects. The shell should interpret those results and decide how to display messages, artifacts, generated code, and saved metadata.
