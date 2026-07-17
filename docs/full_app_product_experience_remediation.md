# Full-App Product Experience Remediation

Source evidence: founder testing notes from `Product Testing 1.docx`.

This pass treats the Project page findings as a seed sample of broader product-experience defects. The immediate implementation focuses on the Project setup path because it is the first place where workspace, project, data, collector, and AI concepts collide.

## Founder Testing Interpretation Policy

Founder notes are interpreted as evidence of defect classes, not isolated page complaints. A confusing Project-page provider label is therefore treated as a naming-system problem. A path rejection is treated as an input-normalization problem. A floating card is treated as a layout-composition problem. A repeated GenAI click is treated as an action-feedback and request-lifecycle problem.

When a note exposes a shared defect class, remediation should prefer a shared component, label helper, path helper, or QA check over page-specific patching.

## Defect Taxonomy

| Defect Class | Founder Signal | Remediation Direction |
|---|---|---|
| Path tolerance | Backslash Windows paths rejected or unclear | Normalize pasted paths and quoted paths before validation. |
| Opaque infrastructure language | Configured Workspace / Managed Workspace / Native Host Directory | Use user-facing labels and explain choices where the user must choose. |
| Weak hierarchy | Workspace dominated Project | Make Project the primary object and put storage beneath it. |
| Poor confirmation | Use Workspace did not clearly communicate outcome | Keep guard/status feedback near the action and promote Recent Activity. |
| Internal terminology leakage | Manifest, Active Modeling Context, Prepared Artifact | Hide or reframe technical terms on normal user surfaces. |
| Misleading context readout | Rows/source/lineage values felt false or unclear | Show simple Modeling Data facts and move lineage to advanced contexts. |
| Duplicate long-running actions | Repeated GenAI clicks queued multiple outputs | Add busy/duplicate guards and immediate in-progress feedback. |
| Output formatting artifacts | Escaped slashes appeared in AI output | Normalize common escaped punctuation in the project GenAI response path. |
| Layout imbalance | AI Readiness / collector / status cards floated awkwardly | Combine related status content and use a clearer main/sidebar setup layout. |

## Implemented Remediation

- Project setup now leads with the project itself.
- The Project page now uses the locked reference structure: Home, Activity, and Systems.
- Home contains the compact hero, lifecycle actions, project folder selection, current project snapshot, current attention/next action, and recent activity.
- Project location is now part of project management rather than a separate destination.
- Storage provider selection defaults to `Local Folder` and explains each option.
- Storage provider cards are now the actual selection controls.
- Storage copy explicitly says normal Windows backslash paths are accepted.
- Workspace/provider labels are user-facing: `Local Folder`, `Saved Workspace`, `App-Managed Folder`, and `Choose Folder`.
- Recent Activity is promoted into the primary Project setup area.
- Workspace status labels avoid exposing `Manifest` and `render target` as normal user language.
- The former Active Modeling Context surface is reframed as an advanced `Modeling Data` disclosure.
- Project evidence aggregation is described as `Project Evidence Memory` on user-facing surfaces.
- Operations are hidden from the default view and rendered as one selected operational detail at a time.
- Project-level GenAI actions now show in-progress feedback and block immediate duplicate requests.
- Project GenAI output normalizes common escaped punctuation artifacts.
- `qa_founder_testing_remediation()` protects the Project-page fixes and path-tolerance expectations.

## App-Wide Remediation Plan

1. Continue replacing implementation identifiers with user-facing labels on normal surfaces.
2. Keep technical terms available in advanced disclosures, docs, logs, and QA rather than removing them from the system.
3. Use choice-explainer components for small decisions where labels alone are insufficient.
4. Keep long-running actions visibly busy and duplicate-guarded.
5. Route all user-entered local paths through normalization helpers.
6. Treat Recent Activity as the confirmation layer for project-changing actions.
7. Prefer status clusters over floating one-off cards.

## Pages Needing Follow-Up Review

- Data Workspace: verify loaded-data ownership is clear after project creation and reload.
- Analysis Modules: review whether module names and generated code still expose package internals.
- Artifact Studio: verify collector/evidence-memory wording is consistent.
- Workflow: decide whether `Project Artifact Collector` should remain visible or be reframed for nontechnical users.
- Export/Layout: check whether report-plan and manifest concepts are clearly separated from project evidence memory.
- Mission Control and Guide: align next-action language with the new Project setup hierarchy.

## Retest Guide

1. Paste `C:\Users\Bizon\Documents\GitHub` into the Home project folder path and click `Use This Folder`.
2. Create a new project and verify the project, recent activity, and location feedback are understandable without reading docs.
3. Load data and confirm the Project Signals table shows the dataset as belonging to the active project.
4. Open `Modeling Data` and verify it is accurate, compact, and not visually dominant.
5. Click `Brief Project` twice rapidly and verify the second request does not queue a duplicate.
6. Click `Suggest Next Action` and verify immediate feedback appears before the final response.
7. Inspect Project Evidence Memory before and after running an analysis module.
8. Resize the app from narrow width to ultrawide and verify the Home, Activity, and Systems modes remain balanced.

## Remaining Risks

- GenAI calls are still synchronous on the Project page. If local model latency is high, these should move through the async job surface.
- Provider choice cards are the actual radio controls, but native radio affordances remain visible for clarity.
- Some architecture terminology intentionally remains in technical docs, QA, and advanced surfaces.
- This pass remediates the highest-signal Project flow first; it does not certify every page.

## Full Application Industrial Design Sweep

This sweep propagates the Project reference experience as a philosophy, not as a copied layout. The common rule is that each page should now begin from a dominant object and user intent before exposing controls, tables, or implementation depth.

### Shared Component

`ui_object_spine()` is the app-wide composition primitive added for pages that previously opened directly into controls or status cards. It gives each surface:

- a dominant object;
- the intent of the surface;
- current state;
- next action;
- a depth boundary that tells the user what belongs lower on the page.

This addresses repeated UX defect classes found during founder testing: pages feeling like independent Shiny modules, controls appearing before purpose, internal implementation language leaking too early, and weak next-action hierarchy.

### Page Intent Audit

| Page | Dominant Object | Intent | Structural Change | Defect Class Addressed | Remaining Founder Question |
|---|---|---|---|---|---|
| Guide | Business question | Orient the user around evidence-centered work. | Existing mentor hero remains the dominant object. | Entry-point ambiguity. | Should the Guide become the universal first-run surface for all demo worlds? |
| Evidence Review | Evidence claim | Separate supported claims, gaps, contradictions, and justified actions. | Added object spine before the evidence room. | Reasoning state hidden behind panels. | Which claims should be visually promoted first during live demos? |
| Decision Management | Governed decision | Convert evidence into accountable choice. | Added object spine before the decision room. | Alternatives and governance felt like metadata. | Should executive decision language be shorter in demo mode? |
| Knowledge Library | Knowledge source | Read the book, architecture, research, and ontology in-app. | Added object spine above the three-column reader. | Documentation surface looked like a utility page. | Should the table of contents become sticky per document? |
| Mission Control | Operational state | Summarize project health and the next operational action. | Added object spine before health, priority, and queues. | Status cards lacked a single mental model. | Which alert classes belong in the first viewport? |
| Project | Project | Create, load, locate, and inspect the current project. | Existing Project reference experience remains canonical. | Project setup trust and path semantics. | Should saved locations become a separate lightweight manager? |
| Data | Dataset | Load one working dataset and verify its shape. | Added object spine above loader/status/preview. | Loader competed with preview and next action. | Should schema facts be visible before preview rows? |
| Workflow | Analytical lifecycle | Show which evidence-producing stage should happen next. | Added object spine above workflow summary and stage cards. | Workflow looked like a registry rather than a lifecycle. | Should planned stages be hidden until relevant? |
| Analysis Modules | Analysis run | Run one analytical operator and preserve evidence. | Added object spine above module settings and run output. | Package/module identity dominated the page. | Which modules need friendlier grouped workflows? |
| Plots | Plot artifact | Author one production plot and save it as evidence. | Added object spine above plot controls/preview. | Plot builder felt control-first. | Should core mappings stay sticky while options scroll? |
| Artifact Studio | Evidence object | Browse and inspect artifacts as evidence. | Added object spine while preserving gallery/inspector/filmstrip. | Artifact volume needed clearer framing. | Should the selected artifact become a persistent URL/state? |
| Semantic Intelligence | Decision context | Author business meaning, levers, KPIs, and governed decisions. | Added object spine before authored workspaces. | Dense authoring panels lacked an anchor. | Which parts should be hidden for non-developer demos? |
| Causal Intelligence | Causal question | Plan intervention evidence before estimation. | Added object spine before causal planning forms. | Estimator depth appeared before causal purpose. | Should randomized, observational, and DiD be separate modes later? |
| Layout | Report plan | Curate evidence into a reusable report structure. | Added object spine above report layout controls. | Report planning felt like code/layout plumbing. | Should report plan preview lead the page when artifacts exist? |
| Export | Delivery package | Deliver selected report outputs without changing evidence. | Added object spine above export controls. | Export destination/options lacked delivery framing. | Should successful export open a delivery receipt? |
| Code Runner | Code run | Capture trusted local R code with policy visible. | Added object spine and developer eyebrow. | Developer surface lacked risk framing. | Should execution policy move to a persistent side panel? |
| AI Runtime | AI operating contract | Inspect what AI may know, propose, persist, and route. | Added object spine above runtime diagnostics. | AI diagnostics surfaced before operating contract. | Which details should be founder-visible versus developer-only? |
| Product Experience | Product experience runtime | Evaluate the workstation through deterministic worlds and replay evidence. | Added object spine above golden-workflow runtime panels. | Experience lab looked like a collection of test artifacts. | Which scenario should remain the canonical investor workflow? |
| Command Palette | Command | Jump to pages and actions without navigating the shell. | Existing modal composition remains intentionally separate. | Command surface needs speed over page framing. | Should command results be grouped by user intent rather than page? |

### Composition Rules Established

- Start with purpose before controls.
- Make the page's central object explicit.
- Keep implementation details in lower sections, disclosure panels, code panels, or developer pages.
- Prefer semantic labels over package identifiers on normal user surfaces.
- Use shared object framing where the page does not already have a stronger bespoke composition.
- Preserve page-specific workflows rather than forcing every page into the same layout.

### Major Structural Changes

- Added an app-wide object spine primitive.
- Applied object framing to Data, Workflow, Analysis Modules, Plots, Artifact Studio, Knowledge Library, Mission Control, Evidence Review, Decision Management, Semantic Intelligence, Causal Intelligence, Layout, Export, Code Runner, AI Runtime, and Product Experience.
- Registered the primitive in `qa_ui_consistency()`.
- Kept the Project page as the reference implementation and avoided shell-wide navigation changes.

### Visual QA Evidence

Desktop and responsive screenshots for the primary app pages are generated under:

`exports/industrial_design_sweep/screenshots/`

The screenshot pass covers Guide, Evidence Review, Decision Management, Knowledge Library, Mission Control, AI Runtime, Product Experience, Project, Data, Plots, Workflow, Analysis Modules, Semantic Intelligence, Causal Intelligence, Code Runner, Artifact Studio, Layout, and Export.

Browser validation confirmed each tab could be selected through its accessible tab label and produced a screenshot at both desktop and responsive widths. A separate existing Project-page warning remains visible in browser logs: duplicate Shiny output IDs for `project-project_message_panel` and `project-recent_activity`. That warning is not introduced by this sweep, but it should be cleaned up in the next Project maintenance pass.

### Remaining Founder Questions

- Should demo/investor mode hide developer-oriented pages by default?
- Should dense authored pages use mode switching rather than long scroll depth?
- Should command palette actions be organized around user goals instead of destinations?
- Should Evidence Review and Decision Management become the primary golden-workflow surfaces after Project?
- Which page states deserve “empty but useful” demo fixtures so screenshots never look inert?
