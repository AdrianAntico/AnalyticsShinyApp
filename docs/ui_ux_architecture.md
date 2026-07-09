# AnalyticsShinyApp UX/UI Architecture

## Companion Documents

- [Product Vision](vision/product_vision.md): stable product identity and long-term principles.
- [UI/UX Research Sprint](research/ui_ux_research_sprint.md): living research reference with historical patterns, comparisons, concepts, and exploratory ideas.
- [UX Roadmap](roadmap/ux_roadmap.md): actionable phased implementation roadmap.

## Design Philosophy

AnalyticsShinyApp should feel like a premium analytical workstation: compact, intentional, artifact-aware, and workflow-centered. The app should guide beginners without hiding power from advanced users or developers.

The product goal is not to build a nice Shiny application. The goal is to build professional analytical software that happens to use Shiny as its reactive engine.

Shiny provides:

- reactivity
- state management
- module orchestration
- server communication
- routing

Shiny does not define the UX language. Components, layouts, interaction models, and visual hierarchy are owned by the AnalyticsShinyApp design system and can use custom HTML/CSS/JavaScript when that produces a better analytical experience.

The product principle is:

```text
Simple by default
Powerful when expanded
Inspectable when needed
```

The design inspiration should be closer to professional workspaces such as VS Code, Cursor, Figma, Linear, JetBrains IDEs, Adobe Lightroom, and Power BI Desktop than to a traditional dashboard.

## Visual Language

AnalyticsShinyApp is dark-first. This matches the production AutoPlots and AutoQuant artifact/report defaults, where dark themes are the normal analytical rendering path. Light and pimp modes remain available as explicit alternatives, but the app shell, core tokens, artifact previews, and report-oriented surfaces should treat dark mode as the primary design target.

The shared palette uses:

- deep navy base surfaces for the workstation shell
- elevated blue-navy panels for task surfaces
- blue and cyan accents for focus, active navigation, and analytical action
- green, amber, and red for success, warning, and failure states
- compact 8px radii and dense spacing for operational software rather than marketing composition

Color, spacing, radius, focus, and shadow decisions belong in `www/app.css` tokens. Pages should not define one-off palettes.

## Control Styling

All Shiny controls must visually belong to the workstation shell. Pages may use normal Shiny inputs for behavior, but their visual treatment should come from shared CSS selectors and tokens rather than page-specific overrides.

Dark-first control rules:

- `selectInput()` and `selectizeInput()` must use dark input backgrounds, dark dropdown menus, visible active/selected states, and tokenized focus rings.
- `textInput()`, `numericInput()`, `textAreaInput()`, and file/path inputs must use dark input backgrounds, muted placeholders, accessible text contrast, and visible disabled states.
- `checkboxInput()` and `radioButtons()` should inherit dark label styling and use the primary accent for checked states.
- `actionButton()` and download buttons should use the shared dark button styles for default, primary, success, danger, hover, focus, and disabled states.
- Pages should not introduce one-off white controls or browser-default controls.

## Table Styling

Tables are analytical artifacts and should be dark-first in the app shell.

Preferred table path:

```text
render_table()
```

`render_table()` should be used instead of raw `tableOutput()` / `renderTable()` for app pages. This keeps plain HTML tables, reactable tables, and future table renderers aligned with the design system.

Dark-first table rules:

- `auto` table theme resolves to `dark` unless explicitly overridden.
- Plain HTML tables must use dark surfaces, dark headers, tokenized borders, striped rows, and hover states.
- `reactable` should use the shared `get_reactable_theme()` helper.
- Reactable search, filter, pagination, and page-size controls should use dark input styling.
- DT/DataTables are not preferred, but if present they should inherit dark shell styling.
- Tables should never render large white backgrounds inside the dark workstation.

The shared reactable dark theme is based on the existing AutoQuant dark RMarkdown artifact styling: `#0B1326` table background, `#0F1B33` headers, subtle slate borders, blue selected-row emphasis, and compact 13px table typography.

## Workflow Philosophy

The app is organized around the analytical lifecycle:

```text
Project -> Data -> Analysis -> Artifacts -> Reports -> Collector -> AI Ready
```

Every page should answer:

- Where am I?
- What can I do?
- What should I do next?

The Project Workspace is the home surface for overall status. Workflow remains the lifecycle launchpad. Analysis Modules remain the parameterized execution surface.

## Mission Control

Mission Control is the operational awareness mode for the project. It is not a dashboard and not a replacement for Artifact Studio. It answers:

- What is happening?
- What is healthy?
- What needs attention?
- What should I do next?

Mission Control treats the project as the world, modules as evidence producers, artifacts as evidence, and the Project Artifact Collector as project memory. The mode should feel like a compact analytical control room: calm, dense, status-rich, and immediately scannable.

Operational awareness is organized into four layers:

- Project Health: top-level health tiles for project, dataset, collector, AI readiness, artifact quality, workflow, reports, warnings, and QA.
- System Status: module and workflow status using the workflow registry so future modules can integrate without page-specific logic.
- Alerts / Open Decisions: an actionable queue for quality warnings, missing evidence, collector gaps, and future analytical decisions. This is not an error log.
- Run Timeline: recent project activity reconstructed from project state, artifacts, collector state, and report activity.

Health hierarchy:

1. Failed or missing project-critical evidence
2. Collector and manifest readiness
3. Artifact quality and warning count
4. Workflow coverage
5. AI/readiness and report readiness

Alert philosophy:

- Alerts should be sparse, prioritized, and actionable.
- High priority means modeling or evidence generation is blocked or absent.
- Medium priority means generated evidence needs review.
- Low priority means the project can continue but has visibility gaps.
- A healthy project should say so clearly rather than leaving an empty panel.

Timeline philosophy:

- Timeline entries are compact operational events, not prose summaries.
- The timeline should make a project run reconstructable at a glance.
- Future entries may come from permanent run history, collector manifests, report generation, and AI actions.

## Layout Principles

- Use `ui_page()` for page shells.
- Use `ui_card()` for bounded task surfaces.
- Use `ui_status_tile()` and `ui_health_summary()` for operational project health.
- Use `ui_workflow_status()` for module and workflow status boards.
- Use `ui_alert_card()` for Mission Control alert and decision queues.
- Use `ui_timeline()` for compact project activity timelines.
- Use `ui_action_bar()` for persistent local action zones.
- Use `ui_workspace_grid()` for main/sidebar or multi-column workstation layouts.
- Use `ui_split_panel()` for analytical work areas with an inspector/sidebar.
- Use `ui_stat_grid()` and `ui_stat_tile()` for project status, artifact counts, collector state, and QA summaries.
- Use `ui_action_row()` for action placement.
- Use `ui_callout()` for contextual information, warnings, and success states.
- Use `ui_progress_steps()` for workflow/stage progress.
- Use `ui_artifact_preview_card()` for artifact gallery and result surfaces.
- Use `ui_collector_status_panel()` anywhere collector state needs to be visible.
- Use `ui_quality_panel()` for artifact/report quality summaries.
- Use `ui_ai_readiness_panel()` for LLM collector readiness.
- Use `ui_loading_state()` for compact execution/loading feedback.
- Use `ui_empty_state()` whenever a panel has no content.
- Use `render_table()` for app tables; avoid raw `tableOutput()` / `renderTable()` in page files.
- Keep dense operational pages compact; avoid landing-page composition inside the app.

Stock Shiny controls are acceptable as internal inputs, but they should usually sit inside reusable workstation components rather than defining a page's interaction pattern.

## Progressive Disclosure

Controls should follow this order:

1. Required
2. Common Options
3. Advanced Options
4. Artifact Settings
5. Developer Tools
6. QA

Use `ui_disclosure()` for collapsible sections. Required inputs should be visible; advanced and developer controls should be available without dominating the page.

## Artifact Philosophy

Artifacts are first-class project outputs. Pages should surface:

- plots
- tables
- narratives
- diagnostics
- recommendations
- report plans
- collector DOCX
- CSV/JSON sidecars where relevant

Generated work should not be hidden behind deep navigation.

## Parameter Philosophy

Defaults should be excellent. Required parameters should be minimal. Advanced parameters should remain accessible, but not compete visually with the primary action.

## Current UX Audit

| Page | Strengths | Weaknesses | Friction Points | Recommendation | Priority | Estimated User Impact |
| --- | --- | --- | --- | --- | --- | --- |
| Project Workspace | Central place for project files and state | Previously file-operation focused | Users could not quickly see data/artifact/collector status | Added stat tiles, workspace status, recent activity, collector visibility, and progressive bundle options | P0 | High |
| Data | Clear upload role | Could better connect to next workflow action | Users may not know what to run after upload | Add next-action card and dataset quality summary | P1 | High |
| Plot Builder | Powerful AutoPlots surface | Dense options can feel disconnected from artifact lifecycle | Saved outputs need stronger artifact framing | Group parameters by required/common/advanced and surface generated artifact status | P1 | Medium |
| Workflow | Strong lifecycle registry | Summary table and stage cards compete visually | Users need quick scan plus launchpad | Keep stage cards, add compact top-level stage progress indicators later | P1 | High |
| Analysis Modules | Broad module coverage | Many controls exposed together | Beginners may see too many options | Apply required/common/advanced/artifact/developer disclosure structure per module | P0 | High |
| Code Runner | Developer power surface | Developer-heavy by nature | Needs clearer safety and artifact-output framing | Keep developer surface but add artifact-output status and workflow context | P2 | Medium |
| Artifact Library | Artifact-centric foundation | Can become a long list | Users need filtering by type, module, intent, importance | Add artifact filters and quality badges | P1 | High |
| Layouts / Export | Existing report composition | Separate from collector mental model | Human report vs LLM DOCX distinction can blur | Add render-target language and collector handoff cues | P1 | Medium |

## Implemented UX Infrastructure

- Page headers now support eyebrow labels and right-aligned primary actions.
- The app shell now defaults to the dark workstation theme.
- Shared CSS tokens define dark-first surfaces, focus rings, spacing, borders, shadows, and status colors.
- Shared form-control, selectize, button, checkbox/radio, table, reactable, and DT fallback selectors keep stock Shiny controls from rendering as light/default browser widgets.
- The shared table theme now resolves `auto` to `dark` and ports the AutoQuant dark reactable styling into the app design system.
- Project Workspace surfaces dataset, artifact, report plan, collector status, lifecycle progress, and AI readiness.
- Data Workspace uses a split-panel source/preview layout.
- Plot Builder uses shared controls, preview, saved-artifact, and code panels.
- Layout Studio uses shared split-panel, disclosure, preview, report plan, and code panels.
- Artifact Library surfaces inventory stats before metadata controls.
- Workflow and Analysis Modules now use shared collector/code primitives instead of standalone headings.
- Export is framed as a report/export workspace.
- Shared stat tiles support compact project status readouts.
- Shared workspace grids standardize main/sidebar and multi-column layouts.
- Shared action bars, split panels, callouts, workflow progress steps, artifact preview cards, collector panels, quality panels, loading states, and AI-readiness panels establish the internal design system.
- Shared disclosure sections support progressive parameter exposure.
- Empty states are reinforced for project and workflow surfaces.
- `qa_ui_consistency()` verifies layout primitives, dark-first tokens, dark controls, selectize dropdowns, buttons, table styling, raw table-output avoidance, action placement, disclosure usage, artifact presentation, collector visibility, render-target visibility, workflow consistency, page adoption, empty states, and responsive layouts.

## Custom Component Opportunities

Existing Shiny widgets should be replaced or wrapped when they limit the analytical experience:

- Navigation: long-term replacement for stock `tabsetPanel()` with a custom workspace rail or command-aware tabbed workspace.
- Module parameters: custom progressive parameter panels with required/common/advanced/developer/QA zones.
- Artifact Library: custom searchable gallery with filters for artifact type, module, intent, importance, quality, and render target.
- Workflow: custom progress/timeline component with completed, active, pending, skipped, and planned stages.
- Collector: reusable status panel with DOCX, manifest, quality, and artifact bundle details.
- Command Palette: keyboard-first navigation and action execution.
- Dockable Inspector: metadata, diagnostics, QA, and render target details without cluttering the primary work area.

## Future Direction

- Add stage progress indicators to the Workflow page.
- Add module-specific progressive disclosure sections.
- Add artifact filters by type, module, intent, importance, quality, and render target.
- Add execution progress surfaces for module runs, collector append, report generation, and QA.
- Add consistent result summary panels after module execution.
- Introduce custom JavaScript-backed components where they clearly improve workflow speed or artifact inspection.
- Add keyboard and accessibility review once the main UX surfaces stabilize.
