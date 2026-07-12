# GenAI Action Layer

Analytics Workstation has a controlled GenAI action layer. It is intentionally narrow.

The governing rule is:

```text
GenAI proposes.
The application validates, authorizes, executes, records, and reports.
```

GenAI cannot execute arbitrary code, call arbitrary functions, mutate project data, save artifacts, generate reports, render reports, expose arbitrary files, or chain actions. The current implementation proves explicit approval execution for four low-risk UI actions, two bounded computational actions, and one persistent project action. The project-scoped bounded computational path supports isolated execution for `dataset_profile`, `model_assessment_regression`, and `model_assessment_binary`.

Persistent future actions must use the workspace/project storage gate described in `docs/architecture/workspace_project_storage.md`. GenAI may propose intent, but application code owns destination resolution. GenAI must not provide workspace roots, project roots, output directories, repository paths, user-profile paths, or arbitrary filenames.

## Maturity Level

| Mode | Name | Status |
| --- | --- | --- |
| Mode 0 | Read only | Implemented |
| Mode 1 | Propose only | Implemented for registered proposals |
| Mode 2 | Explicit approval execution | Implemented for UI-only actions `module.open`, `artifact.inspect`, `report.open`, `result.inspect`; implemented for bounded computational actions `analysis.preflight`, `analysis.run_registered`; implemented for persistent project action `result.persist` |
| Mode 3 | Delegated safe actions | Implemented for session-scoped low-risk UI actions: `module.open`, `artifact.inspect`, `report.open`, `result.inspect` |
| Mode 3.5 | Governed improvement loop | Implemented foundation: durable project improvement items, governed remediation plans, human triage/feedback, attempt history, and re-evaluation. It does not add autonomous fixing. |
| Mode 4 | Bounded autonomy | Not implemented |

Mode 2 now includes durable governance for project-scoped approved actions. Eligible actions write an append-only project audit ledger under `logs/genai_actions/events.ndjson`; see `docs/architecture/genai_action_audit_ledger.md`.

Mode 3 is intentionally narrower than autonomy. A user can grant temporary session authority for a specific low-risk UI action scope. Delegation does not authorize computation, persistence, mutation, arbitrary code execution, or action chaining. See `docs/architecture/genai_delegation_policy.md` and BOUNDARY-GENAI-001 through BOUNDARY-GENAI-004.

Mode 3.5 adds the project-scoped Improvement Ledger documented in `docs/architecture/improvement_ledger.md` and the Governed Remediation Plans documented in `docs/architecture/remediation_plans.md`. GenAI may propose concerns and remediation ideas, but the application validates the concern, binds it to trusted evidence, records it as triage rather than fact when appropriate, and maps remediation only to registered actions or manual steps. A remediation plan can sequence bounded steps, but it still executes one step at a time and pauses for manual input or approval. The ledger records attempts and re-evaluation outcomes; plans do not bypass action approval, delegation policy, audit, or technical debt governance.

## Delegation Policy

Eligible delegated actions:

- `module.open`
- `artifact.inspect`
- `report.open`
- `result.inspect`

Ineligible actions that remain approval-required:

- `analysis.preflight`
- `analysis.run_registered`
- `result.persist`

Delegation is session-local, action-specific, project/provider-bound, short-lived, revocable, and use-limited. A structured proposal is still required. Proposal validation, resource resolution, resource fingerprint checks, project/provider checks, deterministic handlers, session audit, and durable audit still run.

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

### `analysis.run_registered`

Purpose: run exactly one allowlisted registered analysis module against the trusted active dataset and create a temporary session-local result.

Allowed argument:

```json
{
  "module_id": "dataset_profile",
  "dataset_id": "active_dataset"
}
```

This is the first full analytical execution action. It is medium risk because it performs meaningful computation over trusted project data. It is still not persistence. It does not create artifacts, create report plans, write collector entries, modify project metadata, mutate datasets, export files, or chain another action.

The initial allowlisted module was `dataset_profile` (`Dataset Profile`). It was selected because it is deterministic, non-model-fitting, metadata-first, bounded, read-only, free of external network calls, free of report rendering, and implemented as a staged temporary handler. The existing AutoQuant EDA artifact generator was not selected for this path because its normal production path creates artifacts, screenshots, tables, and sidecar files. That is useful for the ordinary workflow, but it would violate the separation between temporary computation and persistence.

Phase 10 added `model_assessment` for regression scored-output diagnostics. Phase 11 extended the same registered module with binary classification scored-output diagnostics. These slices evaluate an already scored dataset using trusted app-state configuration for target, prediction, problem type, class, threshold, probability scale, and optional weight fields. GenAI may still supply only `module_id` and `dataset_id`. It may not supply target or prediction columns. Temporary execution computes bounded in-memory metrics, diagnostics, tables, and plot specifications. It does not train or tune a model, modify predictions, create artifacts, generate report plans, render screenshots, or write files.

All other modules fail validation with `module_not_enabled_for_genai_execution`. The action id remains generic so future modules can adopt the same contract, but the current policy intentionally enables only `dataset_profile` and the regression/binary scored-output `model_assessment` slices.

`analysis.run_registered` may be proposed only with the module id and the trusted dataset id. GenAI may not supply target variables, predictors, formulas, filters, joins, transformations, module options, sample sizes, row limits, timeouts, output names, output paths, report settings, persistence flags, callbacks, package names, SQL, R code, Python code, shell commands, URLs, or filesystem paths.

### Model Assessment Regression Contract

`model_assessment` is the first non-trivial registered module onboarded to the action layer.

Selection rationale:

- It is post-model and scored-output only.
- It uses existing trusted app state for target/prediction configuration.
- It can be bounded without calling the artifact/report generation pipeline.
- It creates useful evidence for evaluating model quality while preserving the approval boundary.

Preflight checks include:

- active dataset availability
- trusted regression task configuration
- target and prediction column presence
- target and prediction numeric type
- target/prediction distinctness
- sufficient complete finite pairs
- non-constant target
- prediction constancy warning
- optional nonnegative numeric weights
- missingness and resource warnings

Temporary execution stages are:

1. validate trusted configuration
2. compute bounded regression metrics
3. compute residual diagnostics
4. build bounded diagnostic tables
5. build bounded plot specifications
6. return a temporary result with `temporary_result_type = "model_assessment_regression"`

The output contract requires `summary`, `metrics`, `tables`, `diagnostics`, `warnings`, `resource_usage`, and `plots`. Plot entries are JSON-safe specifications with bounded tabular data. They are not rendered widgets and do not trigger screenshots in the temporary execution path.

### `result.persist`

Purpose: persist one completed temporary supported result into the active project's trusted result storage.

Allowed argument:

```json
{
  "temporary_result_id": "tmp_analysis_..."
}
```

This is the first persistent GenAI action. It is high risk, requires explicit approval, and is only enabled for supported temporary results created by `analysis.run_registered`. Current supported result types are `dataset_profile` and `model_assessment_regression`.

The model may not supply provider identity, workspace roots, project identity, output directories, filenames, persisted result ids, overwrite flags, formats, tags, retention settings, code, callbacks, module ids, dataset ids, or timestamps. All identity, destination, and serialization decisions come from trusted application state.

Strict project continuity is required. The active project at persistence time must match the project bound to the temporary result at execution time. A no-project temporary result cannot be adopted into a project in this phase.

Durable audit behavior:

- approval and execution-start events are written before the persistent mutation
- successful commits emit `persistence_committed` plus the terminal execution event
- idempotent recovery emits `persistence_recovered`
- if post-commit audit writing fails, the persisted result remains valid and the execution reports `audit_write_failed`
- reconciliation on the Project page surfaces missing or duplicate persistence audit records

The persisted resource model is a dedicated result bundle:

```text
project/results/<persisted_result_id>/
  manifest.json
  summary.json
  diagnostics.json
  warnings.json
  resource_usage.json
  metrics.json
  tables/
    <table_id>.json
  plots/
    <plot_id>.json
```

The bundle contains bounded summaries, metrics where applicable, diagnostics, warnings, bounded tables, bounded plot specifications where applicable, resource usage, provenance, relative paths, and content hashes. It does not contain raw dataset rows, the original dataset object, prompts, code, functions, callbacks, credentials, or provider secrets.

Persistence uses staged same-project storage and an atomic directory commit. Completed manifests are discoverable after restart through project result discovery. Staging directories and incomplete or hash-invalid bundles are ignored.

Approval binds to a composite persistence fingerprint covering proposal hash, temporary result id/fingerprint/type, source execution, module and dataset versions, schema version, active project id, project root identity, provider id/type, workspace root identity, provider capability version, provider write policy, storage policy version, output contract version, and persistence schema version. Provider changes, capability changes, write-policy changes, project changes, and result changes invalidate approval.

Idempotency is based on action id, proposal id, source temporary result id, source execution id, active project id, and workspace provider id. If a completed commit is found for the same idempotency key, execution returns the existing result with `already_committed = true` instead of creating a duplicate.

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

### `result.inspect`

Purpose: open the Project page Persisted Results browser and select one existing healthy persisted result for inspection.

Allowed argument:

```json
{
  "persisted_result_id": "result_20260710_..."
}
```

This is a low-risk UI-only action. It does not persist, modify, repair, delete, export, regenerate, rerun, convert, or report on a result. Current supported persisted result types are `dataset_profile` and `model_assessment_regression`.

The model may not supply project ids, provider ids, workspace roots, project roots, result paths, manifest paths, filenames, result types, module ids, dataset ids, routes, tabs, callbacks, repair flags, export formats, SQL, code, shell commands, URLs, or filesystem paths. Application code resolves the active project, provider, result root, manifest, hash validation, browser destination, and selected-result state.

Approval binds to a persisted-result resource fingerprint covering the trusted persisted result id, active project id, provider id/type, manifest schema, persistence schema, result type, module and dataset versions, manifest status, content-hash summary, and persisted-result fingerprint. Execution re-resolves the result and rejects stale approvals if the result, project, provider, manifest, or hashes changed.

Successful execution reports:

```text
ui_state_changed = true
project_state_changed = false
persistent_changes = false
computation_performed = false
temporary_result_created = false
persisted_result_created = false
artifact_created = false
report_created = false
```

## Persisted Results Browser

The Project page now includes a project-scoped Persisted Results browser. It discovers bundles only under the active project `results/` root through trusted storage helpers. It validates manifest readability, required fields, project ownership, complete status, supported persistence schema, supported result type, required resource files, and content hashes.

Healthy bundles are shown separately from invalid or unsupported bundles. Invalid bundles show safe diagnostics only: result id when available, detected status, manifest/hash status, validation errors, and a project-relative location. The browser does not render partial analytical content from invalid bundles and does not repair them.

Opening a healthy result renders bounded summary, provenance, diagnostics, warnings, resource usage, and table previews. It shows project-relative locations only and does not expose raw absolute paths, provider roots, project roots, full manifests, raw dataset rows, prompts, credentials, or serialization internals.

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

## Registered Analysis Execution

`analysis.run_registered` adds a provider-independent executable-module contract. The registry stores:

- module id
- module version
- display name
- whether GenAI execution is enabled
- execution risk
- configuration schema
- input contract
- output contract
- resource profile
- progress support
- cancellation support
- execute handler

Executable handlers are internal application code. They are not exposed in action metadata returned to GenAI.

The first executable registry contains exactly one module:

| Module | Status | Reason |
| --- | --- | --- |
| `dataset_profile` | Enabled | Deterministic bounded data profiling with no model fitting, no artifact persistence, and isolated worker execution in ready projects. |
| `model_assessment` regression | Enabled | Trusted scored-output diagnostics for regression with bounded metrics, diagnostics, tables, and plot specs. |
| `model_assessment` binary classification | Enabled | Trusted scored-output diagnostics for binary classification with bounded threshold, calibration, lift, metrics, tables, and plot specs. |

## Trusted Configuration Snapshots

A full run requires trusted configuration beyond `module_id` and `dataset_id`. The model does not author that configuration.

For `dataset_profile`, the app creates an immutable configuration snapshot from deterministic application defaults:

- include schema profile
- include missingness profile
- include numeric summary
- include categorical summary
- include diagnostics

The snapshot records:

- configuration snapshot id
- module id and version
- dataset id and version
- schema version
- active project id
- configuration schema version
- allowlisted configuration values
- validation status, errors, and warnings
- configuration fingerprint

The configuration schema rejects unsupported fields, functions, environments, formulas, connections, callbacks, non-scalar values, and non-logical flags. If configuration changes after approval, the execution fingerprint changes and the run is blocked until a new proposal is approved.

## Preflight Binding

`analysis.run_registered` requires a current acceptable preflight before execution. The app may reuse a session-local preflight only when it still matches:

- module id
- module version
- dataset id
- dataset version
- schema version
- active project id

If no matching preflight exists, the app runs the same bounded trusted preflight internally as a pre-execution validation. This is not a separate GenAI action and does not grant any extra model authority.

Accepted readiness values:

- `ready`
- `ready_with_warnings`

Rejected readiness values:

- `blocked`
- `cancelled`
- `timed_out`
- `failed`

## Composite Execution Fingerprint

Approval for `analysis.run_registered` binds to one composite execution fingerprint. It includes:

- proposal hash
- active project id
- module id and version
- dataset id and version
- schema version
- configuration fingerprint
- preflight result id
- preflight fingerprint
- executable-module policy id

Execution re-resolves all trusted resources immediately before invoking the handler. A module change, dataset change, schema change, configuration change, active project change, stale preflight, disabled module, changed policy, expired proposal, or modified proposal blocks execution.

## Managed Job Lifecycle

Each approved run creates a session-local job record:

- job id
- execution id
- proposal id
- action id
- module id
- dataset id
- configuration snapshot id
- status
- timestamps
- progress stage and message
- cancellation flag
- timeout flag
- error
- temporary result id

Supported job statuses:

```text
queued
validating
running
cancelling
succeeded
failed
cancelled
timed_out
```

In a ready workspace/project, registered analysis execution runs in an isolated `callr` worker through `R/genai_job_manager.R` and `R/genai_worker_runtime.R`. Cancellation and timeout are enforced by the job manager through process termination. Legacy no-project compatibility can still use the older synchronous staged path, but canonical project-scoped execution is isolated.

Timeout is also app-owned. The model cannot extend or override it. A timeout stops remaining stages, marks the job as `timed_out`, avoids creating a successful temporary result, and writes the state to the audit event.

## Temporary Result Lifecycle

A successful run creates a session-local temporary result. Known limitation: TD-RESULT-001.

- temporary result id
- execution id
- proposal id
- job id
- module id and version
- dataset id and version
- configuration snapshot id
- creation and expiration time
- summary
- bounded tables
- diagnostics
- warnings
- resource usage
- result fingerprint

The result is explicitly labeled temporary. It is read-only after completion, expires in the session, does not become an artifact, does not become a report plan, does not update project metadata, does not update the collector, and does not write project files unless a separate `result.persist` proposal is approved.

The safe GenAI-facing summary includes only:

- module and dataset display names
- execution status
- summary
- bounded table names and shapes
- diagnostic labels
- warnings
- resource usage
- recommended human next step

It does not expose raw rows, the full dataset, full serialized plot objects, internal file paths, credentials, callbacks, or executable objects.

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

`analysis.run_registered` is a bounded computational action. It creates a session-local temporary analysis result and may update temporary UI/job state. It does not mutate project data, artifacts, reports, collector state, layout, or persistent files.

Execution result fields distinguish:

- `ui_state_changed`
- `project_state_changed`
- `persistent_changes`

For UI-only actions:

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

For `analysis.run_registered`:

```text
ui_state_changed = true
project_state_changed = false
persistent_changes = false
computation_performed = true
temporary_result_created = true
artifact_created = false
report_created = false
```

For `result.persist`:

```text
ui_state_changed = true
project_state_changed = true
persistent_changes = true
computation_performed = false
temporary_result_created = false
persisted_result_created = true
artifact_created = false
report_created = false
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

Project-scoped action audit persistence is implemented through the durable GenAI action audit ledger. The session-local audit stream remains available for immediate UI feedback. Durable events intentionally avoid provider credentials, secrets, raw prompt content, raw rows, full result payloads, and sensitive absolute paths.

## GenAI Contract

Advisory GenAI responses continue to work when no proposal is present. Malformed proposals, unknown actions, unsupported fields, invalid arguments, expired timestamps, stale fingerprints, mismatched risk tiers, and invented artifact ids fail safely and do not break the normal text response.

The current prompt allows one fenced JSON proposal under `action_proposal` for:

- `module.open`
- `artifact.inspect`
- `report.open`
- `analysis.preflight`
- `analysis.run_registered`
- `result.persist`

The prompt gives only compact artifact, report, module, dataset, and persistable temporary-result metadata. It does not inject full artifact bodies, report contents, raw rows, full datasets, provider roots, project roots, result bundle internals, or manifest contents merely to support action selection.

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
31. Ask Guide to run the allowlisted temporary dataset profile.
32. Confirm a proposal for `analysis.run_registered` contains only `module_id` and `dataset_id`.
33. Confirm trusted configuration, preflight readiness, resource limits, cancellation semantics, and no-persistence notice are displayed.
34. Approve the proposal.
35. Confirm a temporary result is created and clearly labeled temporary.
36. Confirm no artifact, report plan, collector entry, project metadata, or dataset state changed.
37. Attempt to run any non-allowlisted module and confirm `module_not_enabled_for_genai_execution`.
38. Ask Guide to retain a completed `dataset_profile` temporary result.
39. Confirm a `result.persist` proposal contains only `temporary_result_id`, `risk_tier = high`, and `persistence_requested = true`.
40. Confirm the approval panel shows provider/project/readiness and safe relative destination, not raw managed roots.
41. Approve persistence.
42. Confirm one result bundle is created under `project/results/<persisted_result_id>/`.
43. Confirm `manifest.json` validates, hashes match, and no raw rows are persisted.
44. Attempt duplicate persistence of the same temporary result and confirm it is blocked.
45. Change provider/project before execution and confirm approval is invalidated.

## Current Limitations

- No autonomous execution exists. See BOUNDARY-GENAI-002.
- No action chaining exists. See BOUNDARY-GENAI-002.
- No Code Runner action exists. See BOUNDARY-GENAI-003.
- No report generation, report rendering, report export, or report mutation action exists. This remains outside the current action allowlist.
- Only two temporary analytical execution modules exist: `dataset_profile` and `model_assessment`. `model_assessment` currently supports exactly two trusted modes: regression scored-output diagnostics and binary classification scored-output diagnostics. See BOUNDARY-GENAI-008.
- The only persistence action is `result.persist` for completed supported temporary results. Delegated persistence is intentionally blocked. See BOUNDARY-GENAI-001.
- No artifact modification, creation, save, delete, or rename action exists. This remains outside the current action allowlist.
- No report generation, artifact creation, collector append, or arbitrary result persistence action exists. This remains outside the current action allowlist.
- Preflight role checks are generic unless module registry metadata declares richer role requirements. See TD-GENAI-005.
- There is no broad dataset registry yet; the current action layer exposes only `active_dataset`. See TD-PROJECT-001.
- Session audit remains local, and eligible project-scoped actions also write durable project audit events. See BOUNDARY-GENAI-006 and TD-AUDIT-003.
- Full authentication and user identity are not implemented.
- `R/genai_actions.R` still requires decomposition before continued module expansion. Phase 11 extracted stable result/mode contracts, but proposal, execution, persistence, UI helpers, and QA remain concentrated. See TD-GENAI-003.
- Result-type branching is partially centralized through `R/genai_result_contracts.R`; remaining serialization/browser branches should be consolidated before broader result-type expansion. See TD-GENAI-004.

## Recommended Next Action

The next candidate should be another bounded, read-only module whose configuration is already trusted by app state, or a consolidation pass that moves more result/persistence behavior behind descriptors. Broader persistence for artifacts or reports should remain separate and explicitly approved.

## Phase 11 Binary Model Assessment

Phase 11 extends the existing `model_assessment` registered module with `binary_classification` mode and `model_assessment_binary` result type. It does not add a new action or a third analytical module.

The proposal shape remains:

```json
{
  "module_id": "model_assessment",
  "dataset_id": "active_dataset"
}
```

GenAI still cannot supply target column, prediction column, positive class, threshold, probability scale, weights, filters, metrics, plot settings, persistence settings, paths, or code.

Trusted binary configuration comes from app state and is validated before preflight and execution:

- `task_type = "binary_classification"`
- `target_column`
- `prediction_column`
- explicit `positive_class`
- optional derived negative class from the two target classes
- `decision_threshold` in `[0,1]`
- `prediction_scale = "probability"`
- optional valid `weight_column`

The supported prediction-scale policy is deliberately narrow: probability values must be numeric and within `[0,1]`. Logits, percentages, arbitrary scores, class labels, and mixed scales are blocked with structured validation/preflight errors. Thresholds are trusted inputs; the action does not optimize or search thresholds.

Binary execution is bounded and staged:

1. validate trusted configuration
2. resolve bounded analytical data
3. normalize target classes
4. validate probability predictions
5. compute core metrics
6. compute threshold metrics
7. compute calibration and lift diagnostics
8. construct bounded tables
9. construct normalized bounded plot specifications
10. validate the output contract

Temporary execution writes no files, creates no artifacts, creates no reports, and does not mutate project state. Persistence remains a separate `result.persist` action.

The `model_assessment_binary` temporary result contract includes bounded summaries, scalar metrics, `threshold_metrics`, diagnostics, warnings, bounded tables, bounded plot specs, resource usage, mode/result identifiers, configuration snapshot identifiers, and output contract version. It excludes raw rows, unrestricted probability vectors, datasets, model objects, functions, environments, arbitrary paths, and executable content.

Persisted binary bundles reuse `result_persistence_v1` and add safe sidecars such as `threshold_metrics.json` alongside `summary.json`, `metrics.json`, `diagnostics.json`, `warnings.json`, `resource_usage.json`, `tables/`, and `plots/`.

Durable audit records mode/result identifiers, trusted class/threshold/scale fields, configuration/preflight/result identifiers, fingerprints, resource usage status, and persistence identifiers. It does not write metric payloads or raw analytical tables to the ledger.

## Phase 12 Isolated Execution

Project-scoped `analysis.run_registered` now uses the GenAI Job Execution layer documented in `docs/architecture/genai_job_execution.md`.

Enabled isolated handlers:

- `dataset_profile`
- `model_assessment_regression`
- `model_assessment_binary`

The proposal schema did not change. GenAI still proposes only:

```json
{
  "module_id": "trusted-module-id",
  "dataset_id": "active_dataset"
}
```

The application resolves the trusted module, dataset, configuration snapshot, preflight fingerprint, resource limits, worker handler ID, and dataset snapshot. The model cannot supply worker backend, timeout, paths, code, callbacks, or persistence options.

Successful isolated execution reports:

- `computation_performed = true`
- `temporary_result_created = true`
- `project_state_changed = false`
- `persistent_changes = false`
- `worker_isolated = true`
- `hard_cancellation_supported = true`

Cancelled or timed-out execution reports no temporary result and discards incomplete handoff output.

Completed validated handoffs can reconstruct temporary results after restart through the job recovery path. Reconstructed results remain temporary and require a separate explicit `result.persist` proposal before becoming durable project results.
