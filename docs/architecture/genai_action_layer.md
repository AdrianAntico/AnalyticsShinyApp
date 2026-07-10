# GenAI Action Layer

Analytics Workstation has a controlled GenAI action layer. It is intentionally narrow.

The governing rule is:

```text
GenAI proposes.
The application validates, authorizes, executes, records, and reports.
```

GenAI cannot execute arbitrary code, call arbitrary functions, mutate project data, save artifacts, generate reports, render reports, expose arbitrary files, or chain actions. The current implementation proves explicit approval execution for three low-risk UI actions and one bounded computational action.

## Maturity Level

| Mode | Name | Status |
| --- | --- | --- |
| Mode 0 | Read only | Implemented |
| Mode 1 | Propose only | Implemented for registered proposals |
| Mode 2 | Explicit approval execution | Implemented for UI-only actions `module.open`, `artifact.inspect`, `report.open`; implemented for bounded computational action `analysis.preflight` |
| Mode 3 | Delegated safe actions | Not implemented |
| Mode 4 | Bounded autonomy | Not implemented |

## Registered Actions

Actions are registered in `R/genai_actions.R`. Only registered actions may execute. The registry stores executable handlers internally, but metadata exposed to GenAI omits handlers.

### `module.open`

Purpose: navigate to an existing registered Analytics Workstation module.

Allowed argument:

```json
{
  "module_id": "autoquant_eda"
}
```

The action may open the Analysis Modules workspace and select the requested module. It may not run analysis, execute code, save artifacts, mutate project data, persist layout, generate reports, or trigger additional actions.

### `artifact.inspect`

Purpose: open Artifact Studio and select one existing artifact for inspection.

Allowed argument:

```json
{
  "artifact_id": "artifact_qa_plot_001"
}
```

The action accepts only a stable artifact identifier already present in trusted app state. It rejects model-provided paths, URLs, project ids, function names, callbacks, module ids, SQL, code, route names, and arbitrary tab names.

### `report.open`

Purpose: open Layout Studio and select one existing report plan for inspection.

Allowed argument:

```json
{
  "report_id": "report_qa_diagnostics_001"
}
```

In the current application, the openable report resource is the `aq_report_plan`. Its stable `plan_id` is exposed to GenAI as `report_id`. `report.open` does not generate, render, export, rebuild, save, delete, rename, or mutate a report. It only navigates to the existing report workspace and selects the trusted report plan.

### `analysis.preflight`

Purpose: run a bounded, read-only readiness assessment for one registered module against the trusted active dataset.

Allowed argument:

```json
{
  "module_id": "autoquant_eda",
  "dataset_id": "active_dataset"
}
```

This is the first computational action. It is medium risk because it reads trusted project data and performs bounded checks. It does not run a full analysis, fit models, generate reports, create artifacts, save outputs, mutate project state, modify the dataset, invoke Code Runner, or trigger a second action.

In Phase 4, the application has one trusted dataset identity: `active_dataset`, representing the current project/uploaded dataset already loaded into app state. The model may reference only that id; it may not provide paths, URLs, target variables, formulas, filters, joins, sampling sizes, timeouts, package names, or arbitrary parameters.

## Artifact Resolution

`artifact.inspect` resolves the artifact through trusted application state:

- `ctx$all_artifacts()` is the active artifact catalog.
- `artifact_id` is the stable artifact identifier.
- active project identity is derived from the loaded collector/project state or trusted app state.
- Artifact Studio selection is performed by `ctx$inspect_artifact()`.

The resolver reports:

- `exists`
- `available`
- `current_project_match`
- `artifact_type`
- `display_name`
- `artifact_version`
- `artifact_status`
- `inspection_supported`

The action is rejected if the artifact does not exist, is deleted, is unavailable, belongs to another project, has an unsupported type, has a malformed id, or changes after approval.

## Report Resolution

`report.open` resolves the report through trusted report-plan state:

- `ctx$report_plan_state$plans` is the active report catalog.
- `report_id` maps to an existing `aq_report_plan$plan_id`.
- active project identity is derived from trusted app state.
- Layout Studio selection is performed by `ctx$open_report()`.

The resolver reports:

- `exists`
- `available`
- `current_project_match`
- `display_name`
- `report_type`
- `report_version`
- `report_status`
- `render_status`
- `open_supported`
- `resource_origin`

The action is rejected if the report does not exist, has a malformed id, belongs to another project, is deleted, archived, unavailable, still generating, failed rendering, has missing/failed preview state, uses an unsupported layout type, or changes after approval.

## Preflight Resource Resolution

`analysis.preflight` resolves two trusted resources:

- `module_id` through `get_module_registry()` / `get_module_definition()`.
- `dataset_id` through the active project data in `ctx$uploaded_data()` / `ctx$project_data()`.

The module resolver reports:

- module id
- display name
- module version
- category
- status
- whether analysis is supported
- whether preflight is supported
- declared required/optional roles when available
- minimum rows and columns
- supported data types
- preflight handler id

The dataset resolver reports:

- dataset id
- display name
- active project id
- dataset version
- schema version
- availability
- row count
- column count
- source type
- last updated timestamp

There is no broad dataset registry yet. `active_dataset` is intentionally the only model-facing dataset id for this phase.

## Resource Fingerprints

Approval for resource-scoped actions is bound to both:

- `proposal_hash`
- `approval_resource_fingerprint`

The resource fingerprint is computed from trusted fields:

- `artifact_id`
- active project id
- artifact version
- artifact type
- availability state
- inspection support

For reports, the fingerprint is computed from:

- `report_id`
- active project id
- report version
- report type
- report status
- render status
- availability state
- open support

For analysis preflight, the composite fingerprint is computed from:

- active project id
- module id
- module version
- dataset id
- dataset version
- schema version
- dataset availability

It intentionally excludes secrets, credentials, raw prompts, full artifact contents, and large sidecar data.

If the artifact, report, module, dataset, schema, project, status, render status, or availability changes after approval, execution fails safely and requires a new proposal.

## Proposal Lifecycle

Model-provided lifecycle fields are never authoritative. Application code creates and controls trusted proposal fields such as ids, timestamps, hashes, approval source, and execution records.

Supported statuses:

- `proposed`
- `validated`
- `rejected`
- `awaiting_approval`
- `approved`
- `executing`
- `succeeded`
- `failed`
- `expired`
- `cancelled`
- `timed_out`

Terminal states (`rejected`, `cancelled`, `succeeded`, `failed`, `expired`, `timed_out`) cannot execute. A completed proposal must not be reused for a second execution attempt.

## Validation

Every proposal is treated as untrusted input. Validation checks:

- required proposal structure
- registered action id
- matching action version
- exact argument schema
- no unsupported arguments
- risk tier does not understate registered risk
- `persistence_requested` is false
- `state_mutations` is empty
- proposal is not expired
- proposal hash matches trusted proposal payload
- execution mode permits proposal display
- execution mode permits approved execution
- approval is required

For `artifact.inspect`, validation also checks:

- `artifact_id` is present and scalar
- artifact id is not a path or URL
- artifact resolves through trusted state
- artifact belongs to the active project
- artifact is available
- artifact type supports inspection
- resource fingerprint is available

For `report.open`, validation also checks:

- `report_id` is present and scalar
- report id is not a path or URL
- no rendering or generation parameters are supplied
- report resolves through trusted state
- report belongs to the active project
- report is available
- report can be opened safely
- report is not archived, generating, deleted, unavailable, or failed
- resource fingerprint is available

For `analysis.preflight`, validation also checks:

- `module_id` and `dataset_id` are present and scalar
- neither id is a path or URL
- no extra arguments are supplied
- no target, formula, timeout, sample size, code, callback, package, or output path is supplied
- module resolves through trusted registry
- module supports preflight
- dataset resolves through trusted app state
- dataset belongs to the active project
- dataset is available and schema-readable
- composite resource fingerprint is available
- risk tier is at least medium

Validation returns a structured `service_result()` with errors, warnings, policy decision, resource resolution, and resource fingerprint where applicable.

## Approval UI

The floating Guide renders a proposal review panel when a GenAI response contains a parseable proposal. The panel displays trusted metadata:

- action display name
- target module or artifact display name
- target report display name
- artifact type
- report type
- active project
- artifact version
- artifact status
- report version
- report status
- render status
- module display name and category
- dataset display name, row count, column count
- dataset and schema version
- expected bounded checks
- execution limit summary
- temporary-result behavior
- resource fingerprint
- rationale
- evidence references
- expected effects
- risk tier
- persistence behavior
- UI state behavior
- project mutation behavior
- expiration
- validation errors and warnings

Approval is disabled when validation fails. Nothing executes before explicit approval.

## Execution Semantics

Execution happens outside the LLM layer:

```text
approved proposal
-> revalidate proposal
-> verify proposal hash
-> verify resource fingerprint when applicable
-> verify policy permits approved execution
-> execute registered handler
-> capture result
-> write audit event
```

`module.open`, `artifact.inspect`, and `report.open` are UI actions. They may change temporary UI state, but they do not mutate project data, artifact contents, artifact metadata, persisted layout, stored recommendations, report state, or collector state.

`analysis.preflight` is a bounded computational action. It creates a session-local temporary result and may update temporary UI state. It does not mutate project data, artifacts, reports, collector state, layout, or persistent files.

Execution result fields distinguish:

- `ui_state_changed`
- `project_state_changed`
- `persistent_changes`

For all three current actions:

```text
ui_state_changed = true
project_state_changed = false
persistent_changes = false
```

For `analysis.preflight`:

```text
ui_state_changed = true
project_state_changed = false
persistent_changes = false
computation_performed = true
temporary_result_created = true
```

## Preflight Contract

The preflight result is a temporary session object with:

- preflight result id
- execution id and proposal id through the action result
- module id and dataset id
- created/completed/expires timestamps
- readiness
- structured checks
- warnings and errors
- resource assessment
- configuration requirements
- compact data summary

Readiness values are:

- `ready`
- `ready_with_warnings`
- `blocked`
- `cancelled`
- `timed_out`
- `failed`

Check statuses are:

- `pass`
- `warning`
- `error`
- `not_applicable`
- `not_evaluated`

The generic preflight checks include row/column availability, duplicate column names, unsupported column types, all-missing columns, constant columns, high-cardinality fields, identifier-like fields, missing-value severity, declared role requirements, and workload class. If shared module role metadata is unavailable, role checks are explicitly marked `not_applicable` or `not_evaluated` rather than guessed.

## Bounded Computation

Trusted app limits control:

- maximum elapsed time
- maximum rows inspected
- maximum columns inspected
- maximum sampled rows
- maximum returned warnings
- maximum check details

The model cannot override these limits. The checker prefers metadata first, then performs a bounded scan only within trusted row/column limits. Results record whether evidence came from metadata, sample, or full bounded scan. No raw rows are returned.

Cancellation and timeout are cooperative. A cancelled or timed-out preflight is not reported as ready.

## Audit Behavior

Successful execution writes a session-local audit event. Resource-scoped audit records include:

- proposal id and hash
- execution id
- action id and version
- risk tier
- approval source
- policy decision
- arguments
- evidence references
- result status
- artifact id
- artifact display name
- artifact type
- artifact version
- report id
- report display name
- report type
- report version
- report status
- render status
- module id
- module display name
- module version
- dataset id
- dataset display name
- dataset version
- schema version
- active project id
- execution limit profile
- rows and columns considered
- inspection mode
- readiness
- preflight result id
- cancellation and timeout flags
- computation performed
- temporary result created
- resource fingerprint
- resource validation result
- UI state changed
- project state changed
- persistent changes
- warnings
- errors

Audit persistence is not yet implemented. The audit event intentionally avoids provider credentials, secrets, unnecessary raw prompt content, and full artifact contents.

## GenAI Contract

Advisory GenAI responses continue to work when no proposal is present. Malformed proposals, unknown actions, unsupported fields, invalid arguments, expired timestamps, stale fingerprints, mismatched risk tiers, and invented artifact ids fail safely and do not break the normal text response.

The current prompt allows one fenced JSON proposal under `action_proposal` for:

- `module.open`
- `artifact.inspect`
- `report.open`
- `analysis.preflight`

The prompt gives only compact artifact, report, module, and dataset metadata. It does not inject full artifact bodies, report contents, raw rows, or full datasets merely to support action selection.

## Manual QA

1. Start the app.
2. Open a project containing at least one inspectable artifact and one report plan.
3. Ask Guide to suggest the next action or explain an alert connected to that artifact.
4. Confirm a proposal to inspect the artifact can appear.
5. Confirm the proposal panel shows trusted artifact metadata, not only a raw id.
6. Confirm nothing happens before approval.
7. Approve the proposal.
8. Confirm Artifact Studio opens and selects the expected artifact.
9. Confirm artifact contents and metadata were not modified.
10. Confirm an audit event was recorded.
11. Repeat with an invalid artifact id and confirm a clear validation failure.
12. Repeat after changing projects before approval and confirm execution is blocked.
13. Repeat after invalidating the artifact before execution and confirm execution is blocked.
14. Ask Guide to propose opening an existing report plan.
15. Confirm trusted report metadata appears.
16. Confirm nothing happens before approval.
17. Approve the proposal.
18. Confirm Layout Studio opens and the expected report plan is selected.
19. Confirm the report was not regenerated, rendered, exported, or changed.
20. Attempt to approve an unknown report id and confirm it fails safely.
21. Change projects or report version/status before execution and confirm stale-resource blocking.
22. Ask Guide whether the active dataset is ready for a registered module.
23. Confirm a proposal for `analysis.preflight` can appear with trusted module/dataset metadata.
24. Confirm nothing computes before approval.
25. Approve the proposal.
26. Confirm a temporary structured readiness result is created.
27. Confirm no full analysis ran and no artifact/report was created.
28. Confirm project data and dataset contents were not modified.
29. Repeat with an incompatible or empty dataset.
30. Test cancellation, timeout, stale dataset/schema, and replay blocking.

## Current Limitations

- No autonomous execution exists.
- No action chaining exists.
- No Code Runner action exists.
- No report generation, report rendering, report export, or report mutation action exists.
- No full analysis execution action exists.
- No artifact modification, creation, save, delete, or rename action exists.
- Preflight role checks are generic unless module registry metadata declares richer role requirements.
- There is no broad dataset registry yet; Phase 4 exposes only `active_dataset`.
- Audit is session-local and not yet persisted to project files.
- Full authentication and user identity are not implemented.

## Recommended First Full Analysis Action

The next full-analysis candidate should be an explicit-approval dry-run-to-run bridge for `autoquant_eda`, because EDA is the lowest-risk artifact-producing module and already has the clearest generic data contract. It should still require a successful preflight, explicit user approval, no action chaining, and clear artifact/collector previews before any persistent write.
