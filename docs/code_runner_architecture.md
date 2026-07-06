# Code Runner And Code Tracker Architecture

## Purpose

The Code Runner lets users write, run, track, reuse, and eventually convert R code outputs into report artifacts.

Core pattern:

- user or GenAI proposes code
- app validates execution policy
- user approves when required
- code runs
- code tracker records execution
- outputs are captured
- selected outputs become artifacts

The app now includes a manual `local_trusted` execution prototype. It can run manually entered R code after explicit policy changes, capture output, and track the run.

This is trusted local execution, not a sandbox. The blocked-function scan is a workflow guardrail, not a security boundary.

GenAI code execution is still not implemented.

Implemented model functions:

- `create_code_execution_policy()`
- `validate_code_execution_policy()`
- `create_code_run_request()`
- `validate_code_run_request()`
- `create_code_run_result()`
- `create_code_tracker_record()`
- `code_tracker_summary()`
- `run_code_local_trusted()`
- `code_output_to_artifact_candidates()`
- `qa_code_runner_model()`
- `qa_code_runner_local_trusted()`

## Separation Of Duties

Code Runner owns:

- code editing
- execution requests
- execution policy checks
- output capture
- run status
- code tracker records

Artifact system owns:

- storing artifacts
- rendering artifacts
- layout/display/export

GenAI owns:

- proposing code
- explaining code
- reviewing code

GenAI must not execute code directly.

## Custom Code Hooks

Every workflow stage may expose user-triggered custom code hooks, but hooks must reuse the existing Code Runner architecture. The app must not create a second execution system for workflow code.

Supported hook timings:

- `pre_stage`: user-authored code to run before a workflow stage.
- `post_stage`: user-authored code to run after a workflow stage.
- `standalone`: exploratory code between stages.

Supported hook output intent:

- modified dataset
- plots
- tables
- text artifacts
- metrics
- handoff notes

Custom code hooks create ordinary Code Runner requests with `source = "manual"` and hook metadata in `context`:

- `custom_code_hook = TRUE`
- `workflow_stage`
- `hook_timing`
- `auto_run = FALSE`

Hooks must not auto-run. A page may create or prefill a draft hook request, but execution still requires the user to use Code Runner controls and pass the existing `local_trusted` policy checks. Output-to-artifact conversion also remains user-triggered through the existing Code Runner conversion flow.

The first hook helper layer is:

- `custom_code_hook_stages()`
- `custom_code_hook_timings()`
- `custom_code_hook_output_types()`
- `create_custom_code_hook_request()`
- `validate_custom_code_hook_request()`
- `custom_code_hook_summary()`
- `qa_custom_code_hooks()`

## Execution Modes

The app recognizes these execution modes:

- `disabled`: code execution is unavailable.
- `local_trusted`: code may run locally after policy checks and any required approval. This is implemented for manually entered code only.
- `local_restricted`: code may run locally under tighter restrictions.
- `external_worker`: code may run outside the Shiny process in a future worker.

Only `local_trusted` is implemented. `local_restricted` and `external_worker` are still future work.

## Execution Policy

`create_code_execution_policy()` defines:

- `code_execution_enabled`
- `execution_mode`
- `allow_manual_code`
- `allow_genai_code`
- `require_approval_for_genai_code`
- `allow_file_read`
- `allow_file_write`
- `allow_network`
- `allow_package_install`
- `allow_system_calls`
- `max_runtime_seconds`
- `max_memory_mb`
- `allowed_packages`
- `blocked_functions`

`validate_code_execution_policy()` returns `service_result()`.

## Permission Hooks

Future permission hooks:

- `can_use_code_runner`
- `can_run_manual_code`
- `can_run_genai_code`
- `can_approve_genai_code`
- `can_write_files_from_code`
- `can_install_packages_from_code`
- `can_use_network_from_code`
- `can_view_code_history`
- `can_delete_code_runs`

Project state must never grant these permissions by itself.

## Code Run Request

`create_code_run_request()` defines:

- `run_id`
- `label`
- `code`
- `source`: `manual`, `genai`, `module`, `rerun`
- `execution_mode`
- `requested_outputs`
- `context`
- `requires_approval`
- `status`
- `created_at`
- `updated_at`

Allowed request statuses:

- `draft`
- `pending_approval`
- `approved`
- `rejected`
- `running`
- `success`
- `warning`
- `error`
- `cancelled`

`validate_code_run_request()` returns `service_result()`. If a policy is supplied, executable statuses require enabled code execution.

## Code Run Result

`create_code_run_result()` defines:

- `run_id`
- `status`: `pending`, `approved`, `running`, `success`, `warning`, `error`, `cancelled`
- `value`
- `outputs`
- `artifacts`
- `artifact_ids`
- `logs`
- `warnings`
- `errors`
- `diagnostics`
- `started_at`
- `ended_at`
- `runtime_seconds`
- `metadata`

Result objects are records of a run outcome.

## Code Tracker Record

`create_code_tracker_record()` defines:

- `run_id`
- `label`
- `code_hash`
- `code`
- `source`
- `status`
- `artifact_ids`
- `dataset_id`
- `data_name`
- `project_id`
- `proposal_id`
- `package_versions`
- `created_at`
- `started_at`
- `ended_at`
- `runtime_seconds`
- `warnings_summary`
- `errors_summary`
- `metadata`

`code_hash` uses `digest` when available. If `digest` is not installed, the app uses a simple fallback hash and does not add a new dependency.

`code_tracker_summary()` returns a compact table with run ID, label, source, status, data name, artifact count, created time, runtime, and warning/error flags.

## Output-To-Artifact Conversion

Future conversion rules:

- `data.frame`/`data.table` -> table artifact
- `htmlwidget` -> plot artifact
- character/markdown -> text artifact
- numeric scalar/list of scalars -> metric artifact
- list of supported outputs -> multiple artifacts
- unsupported output -> code run output only, not artifact

The Code Runner may propose artifacts, but the Artifact system stores and renders them.

Current conversion support is user-approved through the Code Runner page:

- `data.frame`/`data.table` -> table artifact
- `htmlwidget` -> plot artifact
- character/markdown -> text artifact
- numeric scalar/list of numeric scalars -> metric artifact

## GenAI Integration

Future GenAI action types:

- `propose_code`
- `run_code`
- `explain_code`
- `convert_code_output_to_artifact`

GenAI code execution should require approval by default and must pass policy checks.

## UI Concept

Future pages or panels:

- Code Workspace
- Code History
- Code Run Details
- Output Preview
- Convert Output to Artifact

Current implementation:

- Code Workspace exists with a plain `textAreaInput`.
- Code History exists and displays `code_tracker_summary()`.
- Run Details exists for inspecting saved requests and tracker records.
- Policy controls exist and validate with `validate_code_execution_policy()`.
- `Run Code` exists for manual `local_trusted` execution only.
- `Create Artifact from Output` exists and requires a user click.
- Code History supports duplicate and rerun workflows.
- Reruns create new run IDs and tracker records.
- Original run records are immutable history and should not be overwritten by reruns.
- Tracker records can store notes in `metadata$notes`.
- Artifact relationships are tracked through `artifact_ids` on the code tracker record.

The next execution work should harden the local trusted runner and add better output capture. Do not add GenAI execution until proposal/action/policy gates exist.

## Project State

Project state should eventually save:

- code run records
- code labels
- code history
- artifact relationships
- run notes
- execution settings if allowed

Project state may remember settings but must not grant permissions.

`validate_project_state()` includes lightweight optional placeholders for:

- `code_run_records`
- `code_run_requests`
- `code_run_results`
- `code_runner_policy`

Full save/load wiring is intentionally deferred.

## Safety Rules

- no untracked code execution
- no GenAI direct execution without policy check
- no file/network/system actions unless allowed
- no project state privilege escalation
- user can inspect code before running
- failed runs should not corrupt project state
- Code Runner must return `service_result()` from validation and execution-facing service boundaries
- trusted local execution must be labeled as not sandboxed
- blocked function scanning is not a complete security system
