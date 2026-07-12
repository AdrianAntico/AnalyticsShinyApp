# GenAI Job Execution Architecture

Phase 12 moves approved bounded GenAI analytical execution out of the main Shiny process and into a trusted isolated worker process.

This layer applies to the existing `analysis.run_registered` action only. It does not add a new GenAI action, does not broaden delegation, and does not let GenAI choose worker options.

## Backend Selection

The selected backend is `callr`.

Rationale:

- `callr` starts a separate R process and exposes a process handle.
- The process can be hard-killed on Windows.
- stdout and stderr can be routed to project-scoped runtime logs.
- The main Shiny process remains responsive while computation runs.
- The implementation is independent of Electron.

`mirai` remains useful for async work, but Phase 12 needs hard cancellation and explicit child-process lifecycle control more than a worker-pool abstraction. The app still starts if `callr` or `ps` are unavailable; isolated execution reports unavailable instead of crashing.

Hosted deployments that disallow child R processes cannot use this backend. That limitation is registered as `TD-GENAI-006`.

## Scope

Enabled worker handlers:

- `dataset_profile`
- `model_assessment_regression`
- `model_assessment_binary`

Unsupported handlers fail closed with `worker_handler_not_enabled`.

## Execution Flow

```text
proposal
-> validation
-> explicit approval
-> trusted resource resolution
-> trusted configuration snapshot
-> bounded dataset snapshot
-> durable job record
-> isolated callr worker
-> progress file
-> strict result handoff
-> main-process validation
-> temporary result registration
-> optional separate result.persist approval
```

The worker never registers temporary results directly. It writes a handoff under the trusted job runtime directory. The main process validates the handoff before creating a session temporary result.

## Durable Runtime Layout

Project-scoped jobs are written under:

```text
<project>/runtime/genai_jobs/<job_id>/
  job.json
  request.rds
  progress.ndjson
  result/handoff.rds
  error.json
  complete.marker
  stdout.log
  stderr.log
  snapshot/dataset.rds
```

`job.json` is durable and safe to inspect. It does not contain raw dataset rows, process handles, function bodies, callbacks, secrets, or the internal absolute path bundle.

The trusted internal `request.rds` may contain absolute paths required by the worker. Those paths are application-created and are not exposed to GenAI, audit summaries, or the UI as arbitrary model-supplied paths.

## Worker Request Contract

The worker request is versioned as `genai_worker_request_v1`.

Required fields include:

- `job_id`
- `action_id`
- `handler_id`
- `module_id`
- `result_type`
- `dataset_snapshot`
- `dataset_snapshot_metadata`
- `configuration_snapshot`
- `resource_limits`
- `execution_fingerprint`
- `progress_path`
- `result_path`
- `runtime_dir`

Requests reject prohibited fields such as callbacks, functions, code, prompts, secrets, API keys, or tokens.

## Dataset Snapshot Policy

The main process creates a bounded RDS snapshot under project runtime storage.

Snapshot metadata records:

- original and transferred row counts
- original and transferred column counts
- sampling mode
- content hash
- safe relative location
- creation and expiry timestamps

The worker verifies the content hash before analysis. Tampered snapshots are rejected.

## Isolation Controls

The worker:

- sources the trusted application code
- maps only allowlisted handler IDs to trusted functions
- uses a restricted working directory inside the job runtime directory
- receives bounded data snapshots rather than reactive Shiny state
- writes only progress, error, and result handoff files
- does not persist results
- does not create artifacts or reports
- does not invoke Code Runner
- does not receive model-supplied paths or code

Common GenAI provider environment variables are cleared for the child process. This is not an operating-system sandbox; it is a scoped worker process for trusted bounded analytical handlers.

## Cancellation And Timeout

Cancellation is process-level for isolated jobs.

```text
cancel_requested
-> terminate worker process
-> delete incomplete handoff
-> cancelled
```

Timeout is enforced by the job manager, not the worker. The worker cannot extend its own timeout.

The job timeout budget is separate from the handler compute limit. The timeout includes worker startup and app sourcing overhead, while handler limits continue to bound the analytical work itself.

## Progress And Heartbeat

Progress is written as bounded NDJSON events:

- monotonic sequence
- timestamp
- stage id
- bounded message
- optional fraction
- heartbeat flag

The progress stream is intentionally compact and excludes raw rows and secrets.

## Result Handoff

The worker writes `genai_worker_result_v1`.

The main process validates:

- schema version
- job id
- execution fingerprint
- result type
- output contract
- bounded content

Invalid handoffs are rejected and never become temporary results.

## Recovery

On restart, the project runtime can classify jobs as completed, terminal, failed, orphaned, or invalid.

A completed validated handoff can reconstruct a session temporary result through `genai_job_reconstruct_temporary_result()`. Reconstructed results remain temporary, are marked `recovered = TRUE`, and are not persisted automatically.

Persistence still requires a new explicit `result.persist` proposal and approval.

## Cleanup

Successful collection removes stale dataset snapshots. Cancellation and timeout discard incomplete handoffs. Durable audit history and job records remain.

## QA

Primary QA:

- `qa_genai_isolated_execution()`
- `qa_genai_action_layer()`

Validated behaviors include:

- backend availability
- handler allowlist
- request-field rejection
- dataset snapshot hash rejection
- isolated dataset profile
- isolated regression Model Assessment
- isolated binary Model Assessment
- hard cancellation
- external timeout
- progress monotonicity
- bounded progress messages
- completed-job temporary-result reconstruction
- no raw rows or process handles in durable job records

