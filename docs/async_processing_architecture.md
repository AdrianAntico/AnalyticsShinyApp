# Async Processing Architecture

## Purpose

Analytics Workstation has long-running analytical work:

- EDA
- Model Readiness
- model build
- model assessment
- model insights
- SHAP analysis
- artifact screenshot generation
- Project Artifact Collector writes
- GenAI experiments
- report generation
- future evidence routing and context strategy studies

These should not freeze the workstation.

Async processing is therefore not only a performance concern. It is a UX architecture concern. Long-running work should become an observable workstation event with status, elapsed time, warnings, failures, logs, artifacts created, and collector updates.

## Design Principle

The application should call a generic async job service:

```r
async_backend_config()
async_backend_available()
async_job_submit()
async_job_status()
async_job_result()
async_job_cancel()
async_job_log()
async_job_registry()
```

The app should not hard-code its long-running workflows directly to `mirai`.

`mirai` is the first backend, not the architecture.

Future backends may include:

- callr
- future
- promises
- local cluster workers
- local serial fallback

## Why mirai

`mirai` is a good first spike candidate because it evaluates R expressions asynchronously in background R processes or persistent daemons. The package returns immediately with a `mirai` object that later resolves to data, and it provides `unresolved()` for polling. It also supports persistent daemons, timeouts, cancellation through dispatcher-backed execution, and clean-process evaluation.

The clean-process behavior is important. It forces Analytics Workstation to respect serialization boundaries rather than accidentally passing large live Shiny state to workers.

Reference:

- https://mirai.r-lib.org/reference/mirai.html
- https://mirai.r-lib.org/reference/daemons.html

## Backend Abstraction

The current service supports:

- `mirai` backend when installed
- synchronous fallback when configured
- graceful unavailable status when no backend is available and fallback is disabled

The service reports backend availability using `service_result`.

If `mirai` is unavailable:

- the app still starts
- Mission Control can still render
- job submission can return `unavailable`
- jobs can run synchronously if the caller explicitly configures fallback

## Job Lifecycle

Canonical statuses:

- `queued`
- `running`
- `completed`
- `failed`
- `cancelled`
- `timed_out`
- `unavailable`

Phase 1 supports coarse progress:

- submitted
- running
- completed
- failed

Fine-grained progress can be added later when module producers expose progress callbacks or write progress sidecars.

## Job Object

The standard job object records:

- `job_id`
- `job_type`
- `module_id`
- `project_id`
- `run_id`
- `status`
- `submitted_at`
- `started_at`
- `completed_at`
- `elapsed_seconds`
- `backend`
- `function_name`
- `arguments_summary`
- `result_path`
- `error`
- `warnings`
- `artifacts_created`
- `collector_updated`
- `progress`
- `logs`

The live worker handle is kept in process memory. Durable handoff happens through `result_path`.

## Serialization Boundary

Do not pass Shiny reactive objects to worker processes.

Preferred worker inputs:

- project paths
- data paths
- serialized project snapshots
- module configuration lists
- output directories
- scalar IDs

Preferred worker outputs:

- `service_result`
- result RDS path
- artifact bundle
- collector metadata
- warning/error summaries

This boundary prevents background execution from depending on live reactive state that cannot be safely serialized.

## Worker Execution Pattern

The Phase 1 worker calls functions by name.

For app-defined functions, the worker sources `app.R` inside an isolated environment, retrieves the named function from `app_env`, and calls it with serialized arguments.

This avoids passing the full application environment to the worker.

Important implementation note:

Synchronous fallback also sources `app.R` in an isolated environment. This prevents fallback execution from replacing the caller's `app_env`.

## Prototype Workflow

The prototype workflow is:

```r
async_run_artifact_studio_demo_seed()
```

It submits:

```r
create_artifact_studio_demo_project()
```

as a named job.

This was chosen because the demo seed is an existing project-level workflow that can produce:

- synthetic data
- EDA artifacts when AutoQuant is available
- Model Readiness artifacts when AutoQuant is available
- SHAP artifacts when AutoQuant is available
- collector output
- screenshots
- table sidecars
- project RDS

The async layer does not rewrite that workflow. It only changes how it is invoked and observed.

Current local spike note:

In the validation environment used for this spike, `mirai` was not installed and the AutoQuant artifact generator functions were not available through the normal app library path. The async service therefore validated synchronous fallback and result retrieval successfully, while the prototype demo seed completed with a warning and zero generated artifacts. That is a dependency/integration condition, not an async-service failure.

## True mirai Validation

A focused validation pass was run after `mirai` was installed locally.

Important runtime finding:

- `mirai` was installed for R 4.5 under `C:/Users/Bizon/AppData/Local/R/win-library/4.5`.
- The older R 4.2.1 runtime did not see `mirai`.
- R 4.5.2 successfully sourced `app.R` and detected `mirai`.

The true async validation used:

```text
R version: R 4.5.2
mirai version: 2.7.1
backend: mirai
fallback: none
```

### Minimal Success Job

A small job was submitted through `async_job_submit()` using the `mirai` backend with synchronous fallback disabled.

Observed behavior:

- submit result: success
- initial job status: running
- immediate poll status: running
- backend: mirai
- app/R session remained responsive while the job slept
- final status: completed
- elapsed time: about 3 seconds
- result was retrievable
- known return value matched expected value

This proves at least one true `mirai` job completes successfully without using synchronous fallback.

### Failure Job

An intentional failing job was submitted through the same `mirai` backend.

Observed behavior:

- submit result: success
- initial job status: running
- final status: failed
- backend: mirai
- captured error: `Intentional async QA failure.`
- job log/status remained inspectable
- app process did not crash

This proves worker failures are captured as job status rather than escaping into the app process.

### Prototype Workflow

The prototype workflow `async_run_artifact_studio_demo_seed()` was run through true `mirai`.

Observed behavior:

- submit result: success
- initial status: running
- Mission Control status counts reported one running job after submit
- final status: completed
- backend: mirai
- elapsed time: about 25 seconds
- result RDS path existed
- worker service result status: success
- artifact count: 12
- screenshot count: 9
- table sidecar count: 6
- project RDS path existed
- warnings: none
- errors: none
- Mission Control status counts reported one completed job after completion

This validates the current prototype path as a real asynchronous workstation job.

### Worker Environment Audit

The helper `async_worker_environment_check()` compares the app process and worker process.

In the true `mirai` validation:

- app R version and worker R version matched: R 4.5.2
- app working directory and worker working directory matched the AnalyticsShinyApp repo
- app `.libPaths()` and worker `.libPaths()` matched
- worker could load `mirai`
- worker could load `AutoQuant`
- worker could load `AutoPlots`
- worker could load `shiny`
- worker could load `data.table`
- worker could see sourced app functions including:
  - `async_job_submit`
  - `create_artifact_studio_demo_project`
  - `service_result`

The worker environment is therefore sufficient for the current prototype workflow when the app is run under R 4.5.2.

Known limitation:

Running the app under R 4.2.1 still reports `mirai` unavailable because `mirai` is not installed in that R library path. This is expected and should remain a graceful fallback/unavailable condition unless the package is also installed for R 4.2.1 or the app runtime is standardized on R 4.5.2.

## Mission Control Integration

Mission Control now has minimal async visibility:

- async job health tile
- async job card
- latest job statuses
- elapsed time
- status badges

This is intentionally not a full job console.

Future UI should add:

- job detail drawer
- logs
- cancel action
- retry action
- artifact links
- collector links
- progress bars
- queued/running/completed filters

## Fallback Behavior

The service must degrade gracefully.

If backend availability fails:

- `async_backend_available()` returns warning, not a crash
- `async_job_submit()` returns `unavailable` when fallback is disabled
- `async_job_submit()` runs synchronously when fallback is explicitly set to `sync`

This preserves existing synchronous behavior and lets modules migrate incrementally.

## Risks

### App Sourcing Cost

Workers currently source `app.R` to load app-defined functions. This is simple and reliable for a spike, but heavy.

Future improvement:

- source a smaller worker bootstrap file
- define module worker entry points in a lighter namespace
- avoid UI sourcing in workers

### Dependency Drift

Workers must have the same library paths and package availability as the app.

Future improvement:

- persist worker library diagnostics
- record `.libPaths()`
- record package availability
- expose dependency failures in Mission Control

### Progress Reporting

Most existing modules do not yet emit progress.

Future improvement:

- progress sidecar files
- per-module stage checkpoints
- collector append events
- screenshot batch progress

### Cancellation

Cancellation depends on backend support. `mirai::stop_mirai()` is used when available, but cancellation is not guaranteed for uninterruptible compiled code.

### Result Size

Large results should not be passed repeatedly through memory.

Future module conversions should return:

- RDS result path
- artifact bundle path
- manifest path
- summary metadata

## Future Module Conversion Plan

Recommended order:

1. Artifact Studio demo seed
2. GenAI context strategy experiments
3. screenshot generation batches
4. Project Artifact Collector writes
5. AutoQuant EDA
6. Model Readiness
7. SHAP Analysis
8. report generation
9. model build

The order should prioritize low-risk, path-based workflows before live project/module server workflows.

## QA

`qa_async_job_service()` validates:

- backend config exists
- mirai availability check degrades gracefully
- unavailable backend returns unavailable status
- synchronous fallback completes
- failed job returns captured error
- mirai or fallback submission works
- result retrieval works
- job registry records status
- result RDS is written
- `app.R` still sources

After true `mirai` validation, `qa_async_job_service()` passed with the `mirai` backend active and reported `Backend used: mirai`.

## Acceptance State

Current spike delivers:

- async job service abstraction
- mirai availability detection
- synchronous fallback
- job registry
- status/result/log/cancel APIs
- result-path persistence
- prototype workflow wrapper
- Mission Control status surface
- QA coverage

It does not yet deliver:

- full module conversion
- fine-grained progress
- durable job registry across app restarts
- full job console
- production cancellation UX
- worker bootstrap optimization
