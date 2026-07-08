# UI/UX Evolution and Innovation Research Sprint

Date: 2026-07-08

Scope: research only. No implementation recommendations here assume stock Shiny components. Custom HTML/CSS/JavaScript, Shiny wrappers, local state, keyboard systems, browser APIs, and future AI-agent orchestration are all considered available.

Living reference note: this document intentionally preserves the exploratory research sprint. It is not a polished specification and should not be treated as finished doctrine. Future UI/UX discoveries, product experiments, and implementation learnings should extend it rather than replace it.

Framing note: when this sprint discusses Mission Control, Artifact Studio, and Agentic Analysis Lab, treat them as Workstation Modes rather than ordinary pages. The user remains inside one project while switching operational modes, similar to Lightroom modules or IDE workspaces.

## Executive Thesis

AnalyticsShinyApp should not become a prettier dashboard. The frontier move is to become an analytical operating environment: part IDE, part Bloomberg Terminal, part Lightroom, part Tableau, part JupyterLab, part AI-agent cockpit.

The best tools in history converge on the same pattern:

```text
fast command surface
+ persistent project context
+ flexible workbench layout
+ inspectable artifacts
+ visible system state
+ reversible operations
+ progressive power
+ strong defaults
+ AI that plans, explains, and executes with evidence
```

For Analytics Workstation, the most important product bet is this:

```text
The project is the world.
Modules are producers.
Artifacts are evidence.
The collector is memory.
The AI is a copilot/analyst who navigates evidence, not a chat box bolted on the side.
```

## Source Map

Primary and reference sources used:

- GUI evolution: GUI history and transition from command line to desktop metaphor, skeuomorphism, flat design, and material design [The Evolution of the Graphical User Interface](https://ejournals.epublishing.ekt.gr/index.php/DAC/article/view/27466)
- CLI history and shell workflows: CLI origins, command history, aliases, scripting, and automation [Contentstack CLI history](https://www.contentstack.com/blog/tech-talk/the-evolution-of-command-line-interface-cli-a-historical-insight)
- Bloomberg Terminal: command line plus mnemonics, help key, integrated market data, analytics, communication, and AI transition [Bloomberg Terminal](https://professional.bloomberg.com/products/bloomberg-terminal/), [Bloomberg guide PDF](https://blogs.kent.ac.uk/kbs-news-events/files/2017/10/Bloomberg-Terminal-Guide.pdf), [Wired ASKB coverage](https://www.wired.com/story/the-bloomberg-terminal-is-getting-an-ai-makeover-like-it-or-not)
- VS Code: editor groups, primary/secondary sidebars, panel, status bar, customizable layout [VS Code UI docs](https://code.visualstudio.com/docs/editing/userinterface), [VS Code custom layout](https://code.visualstudio.com/docs/configure/custom-layout), [VS Code sidebar guidelines](https://code.visualstudio.com/api/ux-guidelines/sidebars)
- Figma: collaborative canvas, product-development workspace, design/build/AI convergence [Figma](https://www.figma.com/), [Figma code layers](https://www.figma.com/blog/building-figmas-code-layers/)
- Power BI: report/data/model/DAX views, filter/visual/data panes [Power BI filters](https://learn.microsoft.com/en-us/power-bi/create-reports/power-bi-report-add-filter), [Power BI visualizations pane](https://learn.microsoft.com/en-us/power-bi/visuals/power-bi-report-visualizations)
- Tableau: workspace with data pane, cards, shelves, worksheets, dashboards, stories [Tableau workspace](https://help.tableau.com/current/pro/desktop/en-us/environment_workspace.htm), [Shelves and cards](https://help.tableau.com/current/pro/desktop/en-us/buildmanual_shelves.htm)
- JupyterLab: flexible interface for notebooks, code, data, terminals, file browser, rich outputs [Jupyter](https://jupyter.org/), [JupyterLab docs](https://jupyterlab.readthedocs.io/)
- Observable: notebooks, collaborative data canvas, data apps, explorable explanations [Observable notebooks](https://observablehq.com/documentation/notebooks/), [Observable Framework](https://observablehq.com/framework/what-is-framework), [Observable Canvases](https://observablehq.com/platform/canvases)
- Cursor: AI-native coding agent, multi-agent interface, plans, agent sidebars [Cursor](https://cursor.com/), [Cursor 2.0 changelog](https://cursor.com/changelog/2-0)
- Linear: speed, focus, AI workflows, cycles, command-driven product operations [Linear](https://linear.app/), [Linear concepts](https://linear.app/docs/conceptual-model)
- Notion: blocks, pages, databases, command/search, AI over workspace content [Notion databases](https://www.notion.com/help/intro-to-databases), [Notion search](https://www.notion.com/help/search), [Notion AI](https://www.notion.com/help/guides/everything-you-can-do-with-notion-ai)
- NASA/control-room human factors: user control, transparency, fault tolerance, information load, integrated systems, displays and controls [NASA NTRS human factors control room](https://ntrs.nasa.gov/citations/19830009969), [NASA human factors](https://www.nasa.gov/reference/jsc-human-factors-performance/)
- Lightroom: module-based workflow, persistent filmstrip, left navigator/history/presets, right adjustment panels [Lightroom workspace basics](https://helpx.adobe.com/lightroom-classic/help/workspace-basics.html), [Lightroom Develop module](https://helpx.adobe.com/lightroom-classic/help/develop-module-tools.html)
- Material design: surfaces, elevation, motion, spatial hierarchy [Material Design introduction](https://m2.material.io/design/introduction), [Material elevation](https://m2.material.io/design/environment/elevation.html)
- Dark mode usability: dark mode popularity, contrast cautions, light mode readability tradeoffs [NN/g dark mode issues](https://www.nngroup.com/articles/dark-mode-users-issues/), [NN/g dark mode vs light mode](https://www.nngroup.com/articles/dark-mode/)
- Data storytelling: branching narrative dashboards, narrative plus visuals plus context [Susie Lu dashboard storytelling](https://susielu.com/data-viz/storytelling-in-dashboards), [Power BI data storytelling](https://www.microsoft.com/en-us/power-platform/products/power-bi/topics/data-storytelling)
- Command palettes and dockable panels: keyboard action layer, navigation/search/actions, docked/resizable panes [Designing command palettes](https://solomon.io/designing-command-palettes/), [Command palette pattern](https://mobbin.com/glossary/command-palette), [Docking/splitter UI notes](https://pixeleuphoria.com/blog/index.php/notes-on-docking-splitter-auis/)

## 1. Historical Evolution

### 1. CLI Era: Precision, Speed, Memory, Composability

Core patterns:

- Commands as verbs.
- Output as immediate feedback.
- History as memory.
- Aliases as personalization.
- Pipes/scripts as automation.
- Low visual overhead.
- High expert ceiling.

What it teaches Analytics Workstation:

- Every UI action should have an equivalent command/action id.
- The workstation should maintain an activity transcript.
- Users should be able to replay workflows.
- The command palette should not be a decoration; it should be the fastest way to do real work.
- Generated R code and artifacts are not exports only; they are the audit trail.

Analytics translation:

```text
upload data
run readiness
fit catboost
generate shap
append collector
ask ai summarize leakage
export llm docx
```

These should be executable through UI, command palette, keyboard, and eventually agent plan.

### 2. GUI/Desktop Metaphor: Discoverability and Spatial Memory

The desktop GUI replaced raw text with windows, icons, menus, and pointers. Its power was not beauty; it was spatial discoverability. Users could see available objects.

What it teaches:

- Analytics objects should be visible as objects: datasets, runs, artifacts, report plans, collector bundles.
- Users need spatial memory: “my artifacts are in the right rail,” “my run timeline is below,” “my inspector is always on the right.”
- A workspace can be both visual and powerful if layout is stable.

Risk:

- Traditional GUI can become click-heavy and slow.

Analytics translation:

- Keep the UI discoverable, but pair it with keyboard and command surfaces.

### 3. Skeuomorphism: Comfort Through Familiar Metaphors

Skeuomorphism helped users understand new digital actions through real-world metaphors. It eventually became visually heavy, but its deeper lesson remains useful.

Useful metaphors for Analytics Workstation:

- “Project” as a case file.
- “Artifact Collector” as evidence binder.
- “Run” as lab notebook entry.
- “Model Readiness” as pre-flight checklist.
- “SHAP” as explanation dossier.
- “AI briefing” as analyst memo.

Avoid:

- Fake leather/file-folder visual styling.
- Decorative metaphor that reduces information density.

### 4. Flat Design: Clarity, but Also Ambiguity

Flat design removed visual clutter but often erased affordances. In high-stakes professional tools, overly flat UI can make controls and states hard to distinguish.

Analytics translation:

- Use restrained depth.
- Use borders, state badges, compact shadows, and clear hover/focus behavior.
- The app should feel dense and exact, not soft and vague.

### 5. Material Design: Surfaces, Elevation, Motion

Material Design’s durable idea is not “Google cards.” It is spatial hierarchy: surfaces exist at different elevations; motion communicates causality.

Analytics translation:

- Dataset surface, analysis surface, artifact surface, inspector surface, and agent surface should have distinct hierarchy.
- Transitions should communicate lifecycle: queued -> running -> validating -> artifact generated -> collector appended.
- Avoid motion for spectacle; use motion to show state transitions.

### 6. Dark-First Professional Tools

Dark-first tools dominate many pro contexts: IDEs, terminals, trading, video/photo tools, security, operations rooms. They reduce glare and let content and status colors stand out, but require careful contrast.

Analytics translation:

- Dark-first is right for long analytical sessions.
- Tables and controls must be first-class dark citizens.
- Text-heavy reports may still need light render targets.
- Human Rmd and LLM DOCX can have separate render policies.

### 7. AI-Agent Interfaces

The first generation of AI UI was “chat next to the app.” Frontier tools are moving toward:

- agent sidebars
- plan/execute loops
- diff previews
- multiple agents
- isolated workspaces
- source grounding
- resumable tasks
- workflow automation

Analytics translation:

- AI should inspect project state, artifacts, diagnostics, and collector manifest.
- AI actions should propose plans before execution.
- AI should preview changes/artifacts before committing.
- Multiple agents could investigate competing model hypotheses.

### 8. Spatial / Interactive Workspaces

Figma, Observable Canvases, whiteboards, and model-diagram tools show a move from pages to canvases. Spatial systems are powerful when relationships matter.

Analytics translation:

- Workflow graph: EDA -> Readiness -> CatBoost -> Assessment -> SHAP -> Collector.
- Model landscape map: features, metrics, drift, importance, effects, risks.
- Artifact canvas: organize plots/tables/diagnostics by analytical theme.

## 2. Category Pattern Findings

### Command Line / Terminal Workflows

Signature strengths:

- blazing speed
- composability
- repeatability
- compact history
- low ceremony
- scriptability

Transferable patterns:

- command palette with natural-language and exact-command modes
- command history with replay
- saved workflows as scripts
- keyboard-first navigation
- named aliases/macros
- output transcript

Analytics opportunity:

```text
Cmd+K -> "run binary shap with autonls effect curves"
Cmd+K -> "show artifacts from last run"
Cmd+K -> "compare run 003 vs run 004"
Cmd+K -> "brief me on model risks"
```

### Bloomberg Terminal / Trading Terminals

Signature strengths:

- extreme information density
- mnemonic commands
- real-time status
- multi-panel layouts
- deep keyboard culture
- integrated data, analytics, news, communication
- specialized color semantics

Transferable patterns:

- command line that understands domain mnemonics
- persistent status bands
- multi-monitor-ready layouts
- function pages with dense tables and charts
- alert/watchlist panels
- “help me find the function” fallback

Analytics opportunity:

- Module mnemonics:
  - `EDA`
  - `MRDY`
  - `CATB`
  - `ASSESS`
  - `SHAP`
  - `COLL`
  - `BRIEF`
- A bottom command/status strip:

```text
[Project: churn_q3] [Run: 007] [Data: 182k x 74] [Collector: 214 artifacts] [AI-ready: partial]  > _
```

### Desktop IDEs: VS Code / JetBrains

Signature strengths:

- primary sidebar
- secondary sidebar
- bottom panel
- editor groups
- tabs
- command palette
- problems/status panel
- extensions
- split panes
- inspector-like tools

Transferable patterns:

- dockable side panels
- bottom console/status/progress drawer
- command center
- artifact tabs
- source/result split
- project explorer
- problems/diagnostics panel

Analytics opportunity:

- Left rail: Project, Data, Workflow, Modules, Artifacts, Reports, AI, QA.
- Primary sidebar: current page navigator.
- Main editor/workspace: module/config/artifact.
- Right inspector: metadata, quality, diagnostics, recommendations.
- Bottom drawer: run logs, warnings, generated code, agent plan.

### Creative Tools: Lightroom / Adobe

Signature strengths:

- workflow modules
- persistent filmstrip
- before/after comparison
- history panel
- presets
- non-destructive editing
- focused canvas
- right-side parameter inspector

Transferable patterns:

- persistent artifact filmstrip
- before/after model comparison
- run history
- reusable analysis presets
- non-destructive module configs
- visual inspection-first workflow

Analytics opportunity:

- Bottom artifact filmstrip always visible.
- Click artifact -> center preview.
- Right inspector -> caption, table, diagnostics, sidecars, quality score.
- Before/after: compare model v1/v2 metrics, SHAP, lift, residuals.

### BI Tools: Power BI / Tableau

Signature strengths:

- distinct workflow modes/views
- visual canvas
- data/model/report separation
- filters and visualization panes
- drag/drop field mapping
- cards/shelves/marks
- dashboards and stories

Transferable patterns:

- Analysis view vs Report view vs Model view.
- Field shelf for plot/model setup.
- Filter pane as durable context.
- Visual grammar controls.
- Story pages for curated narrative.

Analytics opportunity:

- “Data View”: raw data, summary, missingness, types.
- “Model View”: target, features, leakage, relationships, build state.
- “Artifact View”: evidence gallery and collector.
- “Story View”: human report and AI briefing.

### Notebook Environments: JupyterLab / Observable / Databricks

Signature strengths:

- code + output + markdown
- flexible workspace
- terminals/files/data side by side
- rich outputs
- reactive notebooks
- collaborative data apps
- exploration to publication bridge

Transferable patterns:

- execution cells as auditable units
- markdown narratives beside outputs
- collapsible outputs
- reactive dependencies
- notebook-to-report conversion
- inline diagnostics

Analytics opportunity:

- “Analysis Notebook” view generated from module runs:

```text
Cell 1: Load data
Cell 2: Readiness config
Cell 3: Run readiness
Output: readiness artifacts
Cell 4: Run SHAP
Output: SHAP evidence
Cell 5: AI briefing
```

But avoid making notebooks the only interface. The workstation should generate notebook-like audit trails automatically.

### Design Tools: Figma

Signature strengths:

- infinite canvas
- multiplayer
- components
- inspector
- layers
- comments
- design systems
- handoff to code

Transferable patterns:

- canvas of artifacts
- componentized UI primitives
- comments/annotations on artifacts
- inspector for selected artifact
- variants/states
- design-system governance

Analytics opportunity:

- Artifact canvas where users cluster evidence by “risk,” “performance,” “interpretability,” “data quality.”
- Comments on artifacts: “Investigate this sparse segment.”
- Inspector shows artifact metadata and underlying table.

### AI-Native Tools: Cursor / Modern Agent Workspaces

Signature strengths:

- agent plan
- agent execution
- diff preview
- multi-agent parallelism
- persistent chat plus code context
- sidebars for plans/runs
- source-aware assistance

Transferable patterns:

- AI-generated analysis plans
- preview-before-commit
- run in isolated project run
- compare agent outputs
- “accept artifact bundle” flow
- confidence/status signaling

Analytics opportunity:

```text
Ask: "Find the top reasons this model might fail in production."

AI Plan:
1. Inspect readiness diagnostics.
2. Inspect drift artifacts.
3. Inspect SHAP global importance.
4. Inspect effect curves.
5. Check sparse segments.
6. Draft risk memo.

User clicks: Run Plan
```

### Control-Room / Mission-Control Interfaces

Signature strengths:

- shared situational awareness
- clear status hierarchy
- fault tolerance
- alerts
- escalation
- stable displays
- low ambiguity
- operator control
- transparency

Transferable patterns:

- project health center
- status lights
- alert queue
- evidence-driven recommendations
- transparent system state
- graceful degradation

Analytics opportunity:

- A “Mission Control” page:
  - Data status
  - Module status
  - Collector status
  - Artifact quality
  - Warnings
  - Open decisions
  - AI readiness
  - Export readiness

### Report / Storytelling Interfaces

Signature strengths:

- narrative order
- context around visuals
- annotations
- guided reading
- branching based on data
- executive summaries
- explorable sections

Transferable patterns:

- story builder
- narrative outline
- artifact-to-claim linking
- evidence cards
- caveat callouts
- AI-generated briefings grounded in artifacts

Analytics opportunity:

- “Storyline from evidence”: drag artifacts into a narrative spine:

```text
1. Target and data quality
2. Readiness risks
3. Model performance
4. Feature importance
5. Marginal effects
6. Production caveats
7. Recommendations
```

## 3. Pattern Library

### Navigation Patterns

| Pattern | Best source analog | Use in Analytics Workstation |
| --- | --- | --- |
| Command palette | VS Code, Linear, Notion | Fast navigation, module runs, artifact search, AI commands |
| Side rail | VS Code, Slack, Figma | Global workspace navigation |
| Primary sidebar | VS Code, Tableau data pane | Page-specific navigation and source objects |
| Secondary sidebar | VS Code, Cursor | AI, inspector, diagnostics |
| Bottom drawer | IDE terminals/problems | Logs, generated code, warnings, agent trace |
| Breadcrumb/status strip | Bloomberg, IDEs | Project/run/data/render target state |
| Mode switcher | Power BI, Lightroom | Data, Workflow, Artifacts, Reports, AI, QA |

### Workspace Layout Patterns

| Pattern | Best source analog | Use |
| --- | --- | --- |
| Split panes | IDEs, JupyterLab | Controls/preview, artifact/inspector |
| Dockable panels | Adobe, JetBrains | Custom workspaces for power users |
| Resizable inspector | Figma, Lightroom | Artifact metadata, diagnostics, config |
| Bottom filmstrip | Lightroom | Persistent artifact gallery |
| Canvas workspace | Figma, Observable | Artifact map, workflow graph, model landscape |
| Card wall | Linear, Notion | Artifact cards, QA issues, recommendations |
| Timeline | Linear, Power Apps | Runs, collector appends, module execution |
| Status center | Mission control | Project health and failures |

### Interaction Patterns

| Pattern | Why it matters | Analytics version |
| --- | --- | --- |
| Progressive disclosure | Manages complexity | Required/Common/Advanced/Developer/QA |
| Keyboard-first workflows | Expert speed | Cmd+K everything |
| Drag/drop | Natural composition | Artifacts into reports/storylines |
| Hover previews | Fast inspection | Hover artifact thumbnail to show caption/table stats |
| Live search | Scale | Search artifacts/modules/runs/features |
| Preview-before-commit | Trust | AI plans, module configs, report exports |
| Confidence/status signaling | Avoids hidden failure | Badges for success/warning/error/unknown |
| Agent plan/execute | Control | AI proposes grounded steps before running |
| Compare mode | Decision support | Run A vs Run B, model A vs model B |
| Non-destructive presets | Reproducibility | Save/readiness/shap/export configs |

### Artifact Patterns

| Pattern | Use |
| --- | --- |
| Artifact card | Compact summary with type, caption, quality, module, run |
| Artifact inspector | Preview, metadata, diagnostics, sidecars, JSON |
| Artifact filmstrip | Persistent recent artifacts |
| Artifact canvas | Spatial organization of evidence |
| Artifact diff | Compare same artifact type across runs |
| Artifact lineage | Source data -> module -> artifact -> collector -> report |
| Evidence bundle | Group artifacts by analytical question |
| AI-readable evidence score | Completeness for LLM consumption |

### AI Patterns

| Pattern | Use |
| --- | --- |
| AI command mode | Natural language over actions |
| Agent plan panel | Steps, required data, expected artifacts |
| Evidence grounding panel | Sources/artifacts used in answer |
| Agent run timeline | What the AI inspected/executed |
| Multi-agent hypotheses | Competing model/risk analyses |
| Accept/reject artifacts | Preview before adding generated outputs |
| AI briefing composer | Produce executive/technical/LLM brief |

## 4. 30 Candidate UI Ideas

1. Global command palette with exact commands and natural-language intent.
2. Persistent bottom command/status strip inspired by Bloomberg and IDEs.
3. Artifact filmstrip across bottom of all analytical pages.
4. Right-side artifact inspector with screenshot, caption, diagnostics, table, JSON, sidecars.
5. Mission Control page for project health, warnings, collector readiness, AI readiness.
6. Workflow graph with stage nodes and artifact counts.
7. Run timeline showing module runs, warnings, artifacts added, collector appends, exports.
8. “Open Decisions” panel: target choice, feature exclusions, leakage risks, model acceptance.
9. AI Plan/Execute panel where AI proposes grounded analysis plans before running.
10. Multi-agent analysis mode: “Risk Agent,” “Performance Agent,” “Interpretability Agent.”
11. Preview-before-commit for module runs: config summary, expected artifacts, estimated runtime.
12. Artifact search with filters for module, run, type, intent, importance, quality, render target.
13. Model landscape map: metrics, feature importance, drift, residuals, SHAP, effect curves in one spatial view.
14. Report storyline builder: drag artifacts into narrative sections.
15. Evidence bundle builder: group artifacts around claims like “target leakage risk.”
16. Before/after comparison for runs and model versions.
17. “Explain this artifact” action grounded in caption/table/metadata/diagnostics.
18. Hover preview for artifacts with mini screenshot and key metadata.
19. Keyboard shortcuts overlay and command discoverability hints.
20. Saved workspace layouts: Analyst, Builder, Executive, QA, AI Review.
21. Adaptive inspector: changes controls based on selected object type.
22. Collapsible bottom drawer for logs, generated code, warnings, and AI traces.
23. Feature shelf inspired by Tableau: drag variables into Target, Features, Group, Date, SHAP.
24. Collector manifest viewer with run tree.
25. LLM DOCX readiness meter: screenshots, tables, captions, narratives, diagnostics, JSON.
26. “What changed?” run diff after each module execution.
27. Alert queue for missingness, leakage, sparse groups, failed screenshots, incomplete artifacts.
28. Artifact lineage graph from data through collector.
29. AI briefing modes: Executive, Technical, Risk, LLM Training, Stakeholder.
30. One-click “morning briefing”: summarize yesterday’s project state and next best actions.

## 5. Signature “Holy Shit” Moments

### 1. The Model Landscape Map

A single spatial canvas shows the entire analytical world:

```text
Data quality -> Readiness -> Model build -> Assessment -> SHAP -> Effect curves -> Collector -> Reports
```

Each node glows by status. Click a node and the right inspector reveals artifacts, diagnostics, warnings, and recommendations. The user can zoom from “whole project” to “one suspicious feature” in seconds.

Why it is memorable:

- It turns invisible analytical state into a navigable map.
- It makes the app feel like a command center, not a form runner.

### 2. AI Evidence Briefing

User clicks:

```text
Brief Me
```

The app produces:

- top model risks
- strongest drivers
- unstable effects
- sparse segments
- missing artifacts
- recommended next runs
- every claim linked to artifacts

Not chat. A grounded briefing with evidence cards.

Why it is memorable:

- It feels like an expert analyst reviewed the whole project.
- It reinforces the collector architecture.

### 3. Artifact Filmstrip + Inspector

Every generated artifact appears instantly in a bottom filmstrip. Selecting one opens a rich inspector:

- screenshot
- caption
- source module
- run id
- table preview
- JSON
- quality score
- “explain this”
- “add to story”
- “compare across runs”

Why it is memorable:

- It makes artifacts feel tangible.
- It borrows Lightroom’s best professional workflow idea.

### 4. Agent Plan Before Execution

User asks:

```text
Can this model be trusted for production?
```

The AI replies with an executable checklist:

```text
1. Inspect readiness warnings
2. Review leakage diagnostics
3. Check drift
4. Compare calibration/lift
5. Review SHAP stability
6. Check effect curve plausibility
7. Draft production risk memo
```

Each step has expected artifacts and can be accepted/rejected before running.

Why it is memorable:

- It gives AI power without surrendering control.
- It turns AI into a transparent analyst.

### 5. Run Diff: “What Changed?”

After any rerun, the app shows:

```text
Run 008 vs Run 007
Metric improved
Leakage warning resolved
SHAP rank changed
Effect curve became unstable
Collector added 19 artifacts
AI readiness improved from 72% to 91%
```

Why it is memorable:

- Users no longer manually compare outputs.
- It makes iteration feel intelligent.

## 6. Three Radically Different Workspace Concepts

### Concept A: Mission Control Workstation

Best for: operators, analysts, executives, project status, QA.

Philosophy: everything important is visible; failures cannot hide.

ASCII wireframe:

```text
+----------------------------------------------------------------------------------+
| Analytics Workstation       Project: Churn Q3        Run: 008       AI: Partial   |
+------+---------------------------------------------------------------------------+
| Rail |  PROJECT HEALTH                                                            |
|      | +-------------+ +-------------+ +-------------+ +-------------+             |
| P    | | Data        | | Readiness   | | Collector   | | AI Ready    |             |
| D    | | 182k x 74   | | 3 warnings  | | 214 arts    | | 82%         |             |
| W    | +-------------+ +-------------+ +-------------+ +-------------+             |
| M    |                                                                            |
| A    |  WORKFLOW STATUS                                                           |
| R    |  [EDA OK] -> [Readiness WARN] -> [CatBoost OK] -> [SHAP OK] -> [Report P] |
| AI   |                                                                            |
| QA   |  ACTIVE ALERTS                         RECENT ARTIFACTS                   |
|      | +-------------------------------+      +-------------------------------+   |
|      | | Leakage candidate: acct_age   |      | [Target Dist] [Missingness]   |   |
|      | | Sparse segment: channel=Z     |      | [SHAP Top 25] [Lift Curve]    |   |
|      | | Effect curve failed: income   |      | [Effect Age] [Collector Doc]  |   |
|      | +-------------------------------+      +-------------------------------+   |
|      |                                                                            |
|      |  RUN TIMELINE                                                              |
|      |  08:10 Data loaded -> 08:12 EDA -> 08:18 Readiness -> 08:23 SHAP           |
+------+---------------------------------------------------------------------------+
| Cmd  | > brief me on production risks                                             |
+------+---------------------------------------------------------------------------+
```

Key components:

- Global status header.
- Left rail.
- Health tiles.
- Workflow status chain.
- Alert queue.
- Artifact strip.
- Run timeline.
- Bottom command bar.

Strengths:

- Strong situational awareness.
- Great for high-stakes validation.
- Clear next actions.

Risks:

- Less flexible for deep artifact editing.
- Needs careful density management.

### Concept B: Artifact Studio

Best for: analysts building evidence, reports, LLM DOCX, storylines.

Philosophy: artifacts are the primary material.

ASCII wireframe:

```text
+----------------------------------------------------------------------------------+
| Artifact Studio       Search: [shap age]      Filters: Run 008 | SHAP | Warning   |
+-------------+----------------------------------------------------+---------------+
| Collections | Artifact Gallery                                   | Inspector     |
|             | +----------------+ +----------------+ +-----------+ |               |
| All         | | SHAP Top 25    | | Age Effect    | | Lift      | | Screenshot    |
| Data Quality| | importance     | | nonlinear     | | decile    | | +-----------+ |
| Readiness   | | quality 94%    | | quality 88%   | | 91%       | | | preview   | |
| SHAP        | +----------------+ +----------------+ +-----------+ | +-----------+ |
| Reports     | +----------------+ +----------------+ +-----------+ | Caption       |
| AI Briefing | | Missingness    | | Drift Table    | | Residuals | | Diagnostics   |
|             | | table          | | warning        | | plot      | | Backing table |
|             | +----------------+ +----------------+ +-----------+ | JSON/sidecars |
|             |                                                    | Actions       |
|             | STORYLINE                                           | [Explain]     |
|             | 1 Data quality                                      | [Compare]     |
|             | 2 Readiness risks                                   | [Add Story]   |
|             | 3 Model performance                                 |               |
+-------------+----------------------------------------------------+---------------+
| Filmstrip: [Target] [Corr] [Readiness] [SHAP] [Effects] [Collector]              |
+----------------------------------------------------------------------------------+
```

Key components:

- Collections sidebar.
- Artifact cards.
- Inspector.
- Storyline builder.
- Persistent filmstrip.

Strengths:

- Perfectly aligned with collector architecture.
- Great for report/LLM DOCX curation.
- Makes artifact quality visible.

Risks:

- Could under-emphasize workflow execution unless paired with command/status layer.

### Concept C: Agentic Analysis Lab

Best for: frontier AI workflows, power users, experimental analysis.

Philosophy: user directs multiple transparent analytical agents over the project evidence graph.

ASCII wireframe:

```text
+----------------------------------------------------------------------------------+
| Agentic Analysis Lab       Goal: Assess production risk for Churn Q3              |
+---------------+-------------------------------+----------------------------------+
| Agent Queue   | Plan / Execute                 | Evidence Workspace               |
|               |                               |                                  |
| Risk Agent    | Proposed Plan                  | +------------------------------+ |
| running       | 1 Inspect readiness            | | Readiness warnings           | |
|               | 2 Check leakage                | | leakage: acct_age            | |
| SHAP Agent    | 3 Review SHAP stability        | +------------------------------+ |
| done          | 4 Check effect curves          | +------------------------------+ |
|               | 5 Draft memo                   | | SHAP rank changes            | |
| Report Agent  |                               | | income moved 2 -> 8          | |
| queued        | [Run Step] [Run All] [Edit]    | +------------------------------+ |
|               |                               | +------------------------------+ |
|               | Agent Trace                   | | Effect curve: age            | |
|               | - opened collector manifest   | | nonlinear plateau            | |
|               | - read shap_importance.json   | +------------------------------+ |
|               | - found sparse segment        |                                  |
+---------------+-------------------------------+----------------------------------+
| Draft Brief: Production risk is medium-high because... [Accept] [Revise] [Export] |
+----------------------------------------------------------------------------------+
```

Key components:

- Agent queue/sidebar.
- Plan/execute center.
- Evidence workspace.
- Agent trace.
- Draft briefing panel.

Strengths:

- Frontier feel.
- Turns AI into visible process.
- Supports parallel analytical hypotheses.

Risks:

- Requires excellent grounding and permissions.
- Must avoid “AI theater.”

## 7. Recommended Frontier Direction

Do not choose only one concept. Combine them as modes over a shared shell:

```text
Mission Control = project state
Artifact Studio = evidence handling
Agentic Lab     = AI reasoning and automation
```

The shell should remain constant:

```text
Top: project/run/status
Left: global rail
Center: active workspace
Right: inspector/AI/details
Bottom: command/log/artifact filmstrip
```

## 8. Design Principles for Analytics Workstation

1. Project-first, not page-first.
2. Artifacts are evidence, not outputs.
3. Every action has state, lineage, and replay.
4. Every artifact has caption, quality, metadata, backing table/JSON where possible.
5. AI must be grounded, inspectable, and preview-before-commit.
6. Keyboard-first for experts, visible controls for learners.
7. Dense but calm.
8. Dark-first but contrast-disciplined.
9. Progressive disclosure always.
10. Reports and LLM documents are render targets, not separate worlds.
11. Failures should become diagnostics, not dead ends.
12. The app should produce understanding, not just charts.

## 9. Near-Term Build Strategy

### Phase UX-1: Shell and Command Layer

- Global side rail.
- Top project status bar.
- Bottom command/status strip.
- Command palette action registry.
- Keyboard shortcuts.

### Phase UX-2: Artifact Studio

- Artifact gallery.
- Artifact inspector.
- Artifact filmstrip.
- Artifact search/filter.
- Add-to-story action.
- Compare artifact action.

### Phase UX-3: Mission Control

- Project health center.
- Run timeline.
- Warning/alert queue.
- Collector readiness panel.
- AI readiness meter.

### Phase UX-4: Agentic Lab

- AI plan panel.
- Evidence grounding panel.
- Agent trace.
- Preview-before-commit.
- Multi-agent experiment surface.

### Phase UX-5: Spatial Model Landscape

- Workflow graph.
- Artifact lineage graph.
- Model landscape map.
- Drilldown inspector.

## 10. What to Avoid

- More page tabs without a unifying shell.
- More standalone cards without hierarchy.
- Chat box bolted onto a form app.
- White tables/controls in dark UI.
- Decorative dashboards that hide the work.
- Over-reliance on Shiny defaults.
- AI answers without evidence links.
- Reports as dead-end exports.
- One giant canvas for everything.
- Motion without state meaning.

## 11. The Morning Decision

If choosing one high-leverage next design move, build:

```text
Artifact Studio + persistent right inspector + bottom artifact filmstrip
```

Why:

- It amplifies the collector architecture already built.
- It makes generated evidence tangible.
- It supports human reports and LLM DOCX.
- It gives AI something concrete to reason over.
- It is visually differentiated from normal Shiny apps.
- It creates the fastest path to a “holy shit” UX moment.

Second move:

```text
Command palette + bottom command/status strip
```

Third move:

```text
Mission Control page
```

The frontier product shape is not “analytics dashboard.” It is:

```text
an evidence-centered analytical command environment
```
