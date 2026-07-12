# GenAI Service Architecture

Analytics Workstation uses a provider-agnostic GenAI service layer. The app should call shared functions such as `genai_chat()`, `genai_generate()`, `genai_summarize_artifact()`, and `genai_brief_project()` rather than calling a provider directly.

This layer is intentionally not Agentic Lab. GenAI text helpers remain read-only. The separate GenAI Action Layer may propose tightly registered app actions, but application code validates, approves, executes, and audits them. Project-scoped approved actions can also write the durable audit ledger documented in `docs/architecture/genai_action_audit_ledger.md`.

Phase 13 adds bounded Improvement Ledger context. GenAI may receive a compact summary of open project concerns, severity, priority, confidence, evidence counts, and remediation summaries through application-owned context helpers. The full ledger is not injected into every prompt. GenAI may suggest triage or remediation, but the application owns durable state, validates evidence IDs, and keeps remediation bound to registered actions or manual steps. See `docs/architecture/improvement_ledger.md`.

## Product Philosophy

The workstation is local-first and evidence-centered. GenAI should reason over project evidence, not raw data dumps.

All GenAI calls should respect the Context Optimization Policy: deterministic knowledge first, Evidence Routing second, optional probabilistic routing only when useful, and final reasoning only over an optimized evidence bundle.

Default context priority:

1. Project metadata
2. Project Artifact Collector summary
3. Artifact captions and labels
4. Artifact Quality Policy metadata
5. Diagnostics and recommendations
6. Preview tables and table policy metadata
7. CSV/JSON/screenshot sidecar references

Full datasets and huge tables are not sent by default.

## Service Contract

Each provider contract defines:

- `provider_id`
- `display_name`
- `default_base_url`
- `default_model`
- normalized capabilities
- availability check
- model listing
- chat
- generate
- structured JSON behavior where available
- timeout and error handling
- normalized response output

All provider calls return `service_result()` objects. Unavailable providers return `warning` or `needs_input`; they should not crash app startup.

## Capabilities

Capabilities are represented as normalized booleans:

- `chat`
- `generate`
- `structured_json`
- `embeddings`
- `vision`
- `streaming`
- `tool_calling`
- `local`
- `remote`
- `free`
- `paid`
- `offline`
- `privacy_preserving`

UI surfaces can show these capabilities without knowing provider-specific details.

## Configuration

Configuration is read from `genai_config()` and may be supplied through environment variables:

- `ANALYTICS_GENAI_PROVIDER`
- `ANALYTICS_GENAI_BASE_URL`
- `ANALYTICS_GENAI_MODEL`
- `ANALYTICS_GENAI_TEMPERATURE`
- `ANALYTICS_GENAI_MAX_TOKENS`
- `ANALYTICS_GENAI_TIMEOUT`
- `ANALYTICS_GENAI_STREAM`

No provider is required. With no configured provider, the app starts normally.

When no explicit environment provider is set, the app may auto-detect a reachable local Ollama endpoint and use the first available local model. Explicit environment configuration always wins over auto-detection.

Use `genai_provider_diagnostics()` to inspect:

- provider/model/base URL
- R version and `.libPaths()`
- required package availability
- Ollama reachability
- discovered Ollama models
- missing config fields
- detection errors

Current R runtime note:

`mirai` and the GenAI HTTP dependencies are installed under the R 4.5 user library in this workstation setup. Launching the app under R 4.2.1 will not see packages installed only under R 4.5.

Install commands for the current R 4.5 runtime:

```r
install.packages(c("mirai", "httr2", "jsonlite", "curl", "httr"))
```

## Provider Adapters

### Ollama

Ollama is the first local adapter target.

Typical setup:

```text
ANALYTICS_GENAI_PROVIDER=ollama
ANALYTICS_GENAI_BASE_URL=http://127.0.0.1:11434
ANALYTICS_GENAI_MODEL=llama3.1
```

The adapter targets:

- `/api/tags`
- `/api/chat`
- `/api/generate`

Structured JSON is requested through Ollama's `format = "json"` when the caller asks for JSON output.

### LM Studio

LM Studio is prepared through the OpenAI-compatible adapter shape.

Typical local endpoint:

```text
ANALYTICS_GENAI_PROVIDER=lm_studio
ANALYTICS_GENAI_BASE_URL=http://127.0.0.1:1234/v1
```

The adapter targets OpenAI-compatible `/models` and `/chat/completions` endpoints.

### llama.cpp Server

llama.cpp server is represented as a local generate-capable provider.

Typical endpoint:

```text
ANALYTICS_GENAI_PROVIDER=llama_cpp
ANALYTICS_GENAI_BASE_URL=http://127.0.0.1:8080
```

The adapter is prepared for `/health` and `/completion`.

### OpenAI-Compatible Endpoint

The `openai_compatible` provider exists for local or remote APIs that follow the OpenAI chat-completions shape. Remote providers may require keys later, but Phase 1 does not require a paid provider.

## Read-Only Use Cases

Implemented service functions:

- `genai_summarize_artifact()`
- `genai_brief_project()`
- `genai_explain_alerts()`
- `genai_suggest_next_action()`

These functions generate text only. They do not execute commands or change project state.

## Safe Action Context

Project context now exposes two result inventories:

- `persistable_temporary_results`: completed session-local supported temporary results that can be proposed for `result.persist`. Current supported types are `dataset_profile` and `model_assessment_regression`.
- `inspectable_persisted_results`: active-project persisted result ids, display names, result types, module/dataset labels, health status, timestamps, and evidence refs that can be proposed for `result.inspect`.

These inventories intentionally omit raw paths, provider roots, project roots, full manifests, raw result payloads, raw rows, serialization internals, callbacks, prompts, credentials, and secrets.

Supported action ids in the prompt contract are:

- `module.open`
- `artifact.inspect`
- `report.open`
- `result.inspect`
- `analysis.preflight`
- `analysis.run_registered`
- `result.persist`

`analysis.run_registered` currently supports exactly two executable modules: `dataset_profile` and `model_assessment`. The `model_assessment` module is mode-aware and supports regression plus binary classification scored-output diagnostics. Both modes use trusted application configuration for analytical roles; GenAI may not supply target, prediction, positive class, threshold, probability scale, weights, filters, metrics, paths, or code. Binary classification accepts only trusted probability predictions in `[0,1]` and uses the trusted threshold without optimization. See BOUNDARY-GENAI-008.

`result.inspect` may use only a `persisted_result_id` from `inspectable_persisted_results`. It is UI-only and read-only; it cannot repair, export, rerun, persist, or convert a result. See TD-RESULT-003, DEFERRED-RESULT-001, and DEFERRED-RESULT-004.

## Information Transfer Efficiency

Analytics Workstation instruments GenAI calls so we can learn which artifact representations communicate the most useful information to an LLM for the lowest cost.

Every instrumented GenAI call records:

- `context_strategy`
- `included_components`
- `estimated_input_tokens`
- `reported_input_tokens` when the provider reports usage
- `estimated_output_tokens`
- `reported_output_tokens` when the provider reports usage
- `total_estimated_tokens`
- `latency_ms`
- `provider`
- `model`
- `image_payload_used`
- `image_payload_count`
- `image_payload_bytes`
- `image_payload_format`
- `image_reference_only`
- `vision_model_detected`
- `vision_capability_declared`
- `vision_capability_verified`
- `vision_downgrade_reason`
- `output_quality_score` placeholder
- `accuracy_score` placeholder
- `user_rating` placeholder

Tracked context components:

- `screenshot`
- `caption`
- `metadata`
- `diagnostics`
- `recommendations`
- `table_preview`
- `full_table`
- `json_summary`
- `sidecar_reference`

Initial comparison strategies:

- `screenshot_only`
- `caption_metadata`
- `screenshot_caption`
- `table_preview_only`
- `full_table`
- `screenshot_caption_preview`
- `structured_json_summary`
- `balanced`

The purpose is empirical. We should not assume screenshots are always better, and we should not assume structured data is always better. Different artifact types may have different tradeoff frontiers.

Future UI can use this telemetry to recommend context strategies based on constraints:

- minimize tokens
- maximize accuracy
- balanced
- local/private
- fastest response

Automatic strategy optimization is intentionally not implemented yet.

## Context Optimization Policy

Context Optimization is the governing contract above the GenAI service. The service provides provider abstraction, capability normalization, context strategy construction, telemetry, and read-only calls. It should not decide to bypass deterministic routing.

Provider adapters should expose enough capability information for deterministic policy decisions:

- local versus remote
- free versus paid
- privacy preserving
- vision support
- structured JSON support
- latency and timeout behavior

Paid providers are optional. The app must continue to start and deterministic routing must continue to work when no GenAI provider is configured.

## Experiment Harness

The reusable harness compares artifact representations across controlled dimensions:

- artifact type
- artifact id
- question type
- context strategy
- provider
- model

Core helpers:

- `build_genai_experiment_grid()`
- `run_genai_artifact_experiment()`
- `run_genai_project_experiment()`
- `score_genai_experiment_result()`
- `write_genai_experiment_results()`
- `qa_genai_experiment_harness()`

The default artifact experiment samples a small number of plot and table artifacts from a project, builds one prompt per strategy/question combination, calls the configured provider abstraction, and records comparable telemetry. Ollama can be used as the default local provider, but the harness accepts any configured provider, including the deterministic mock provider used by QA.

Experiment outputs are written to:

- `exports/genai_experiments/<experiment_id>/results.csv`
- `exports/genai_experiments/<experiment_id>/responses.json`
- `exports/genai_experiments/<experiment_id>/summary.md`

Manual scoring fields are included but intentionally blank:

- `output_quality_score`
- `accuracy_score`
- `user_rating`
- `reviewer_notes`

Full-table context is guarded. The `full_table` strategy is only used when the table is below the configured row and column thresholds. Oversized or unavailable tables are downgraded to `table_preview_only`, and the downgrade is recorded in the experiment notes. This prevents accidental dataset dumping while still allowing explicit small-table experiments.

## Image Vs Data Experiments

Screenshot strategies are classified explicitly:

- `screenshot_only`: true vision transfer only when an image payload is attached
- `screenshot_caption`: vision plus text when an image payload is attached
- `screenshot_caption_preview`: vision plus text/table preview when an image payload is attached
- `caption_metadata`, `table_preview_only`, `full_table`, and `structured_json_summary`: text/data strategies only
- `balanced`: provider-dependent; the experiment records what was actually sent

A strategy is only considered true image transfer when `image_payload_used = TRUE`. If the run only provides a screenshot path or thumbnail path, the row is classified as `image_reference_only = TRUE`.

Local Ollama vision models use the Ollama `images` payload field on `/api/generate`. Supported examples include `llava`, `llama3.2-vision`, and other locally installed models whose names indicate vision capability. The app does not hard-code one model. Configure vision experiments with:

- `provider`
- `model`
- `base_url`
- `vision_enabled`
- `max_image_bytes`
- `max_image_count`
- `timeout`

If vision is disabled, the selected model is not detected as vision-capable, the provider does not declare vision support, the screenshot is missing, or the image exceeds the configured size limit, the experiment downgrades gracefully and records `vision_downgrade_reason`. It does not fail the whole run.

`run_genai_image_vs_data_experiment()` is the convenience harness for comparing image-based artifact transfer against caption, table preview, full-table, JSON, and balanced strategies. It uses existing artifact screenshot paths only and does not create a screenshot pipeline.

## Plot-Type-Aware Strategy Research

Context strategy research now records artifact family, context provenance, repeat IDs, question applicability, manual scoring fields, and derived metrics. Use `run_genai_context_strategy_study()` for targeted artifact-family studies and `recommend_context_strategy()` only as a conservative research stub.

Detailed research guidance lives in `docs/genai_context_strategy_research.md`.

## UI Surfaces

Provider status and read-only actions appear in:

- Mission Control
- Artifact Studio Inspector
- Project Workspace
- Floating Guide / AI Assistance

The UI shows provider, model, availability, capabilities, and local/privacy status.

## Action Layer Status

The GenAI action layer is documented in `docs/architecture/genai_action_layer.md`.

Current maturity:

- Mode 0: Read only - implemented.
- Mode 1: Propose only - implemented for registered proposals.
- Mode 2: Explicit approval execution - implemented for UI-only actions `module.open`, `artifact.inspect`, `report.open`, `result.inspect`; implemented for bounded computational actions `analysis.preflight`, `analysis.run_registered`; implemented for persistent project action `result.persist`.
- Mode 3: Delegated safe actions - implemented for session-scoped, low-risk UI-only actions.
- Mode 4: Bounded autonomy - not implemented.

GenAI remains non-autonomous. It may produce a structured proposal, but the application validates, requires explicit user approval or an active session delegation grant, executes deterministic registered handlers, and records audit events. Session-local audit remains available for immediate UI feedback; eligible project-scoped actions also write append-only durable events under the active project.

Session delegation is limited to `module.open`, `artifact.inspect`, `report.open`, and `result.inspect`. Delegation does not apply to computational, persistent, or data-mutating actions such as `analysis.preflight`, `analysis.run_registered`, or `result.persist`. Grants are explicit user opt-ins, action-specific, project/provider-bound, use-limited, time-limited, and revocable. See BOUNDARY-GENAI-001 and BOUNDARY-GENAI-004.

Current approved-execution UI-only actions:

- `module.open`: opens a registered analysis module without running it.
- `artifact.inspect`: opens Artifact Studio and selects one existing artifact by trusted artifact id.
- `report.open`: opens Layout Studio and selects one existing report plan by trusted report id.
- `result.inspect`: opens the Project page Persisted Results browser and selects one healthy persisted result by trusted persisted result id.

Current approved-execution bounded computational actions:

- `analysis.preflight`: runs bounded, read-only readiness checks for one registered module against the trusted active dataset id, `active_dataset`.
- `analysis.run_registered`: runs one allowlisted temporary registered analysis module against `active_dataset` and creates a session-local temporary result. Current isolated project-scoped handlers are `dataset_profile`, `model_assessment_regression`, and `model_assessment_binary`.
- `result.persist`: persists one completed supported temporary result into trusted active-project result storage.

`artifact.inspect` is resource-scoped. Approval is bound to both the proposal hash and a trusted artifact fingerprint so changed projects, deleted artifacts, unavailable artifacts, or changed artifact versions invalidate execution.

`report.open` is also resource-scoped. In the current app, `report_id` maps to an existing `aq_report_plan$plan_id`; it does not open arbitrary files or URLs. Approval is bound to both the proposal hash and a trusted report fingerprint so changed projects, deleted reports, archived reports, failed/generating render states, unavailable reports, or changed report versions invalidate execution. The action is UI-only and never generates, renders, exports, saves, or mutates a report.

`result.inspect` is resource-scoped to persisted project results. It resolves through active project storage, validates manifests and content hashes, and opens only healthy supported result bundles. Approval is bound to proposal hash and a persisted-result fingerprint so provider changes, project changes, unsupported schemas, incomplete manifests, missing content, hash mismatches, or result changes invalidate execution. The action is UI-only and never modifies, repairs, exports, reruns, deletes, converts, or persists a result.

`analysis.preflight` is resource-scoped across both a module and dataset. Approval is bound to the proposal hash plus a composite fingerprint built from active project id, module id/version, dataset id/version, schema version, and dataset availability. It performs metadata-first checks and a bounded row/column scan under app-defined limits. It creates only a session-local temporary result and never returns raw rows, runs the full analysis, creates artifacts, creates report plans, mutates data, or writes persistent files.

`analysis.run_registered` is also resource-scoped across a module, dataset, trusted configuration snapshot, and preflight binding. It supports `dataset_profile`, a deterministic bounded data-profile handler, and `model_assessment` scored-output handlers for regression and binary classification. Approval is bound to proposal hash, resource versions, configuration fingerprint, preflight fingerprint, and active project identity. In a ready project/workspace, the computation runs in an isolated `callr` worker and the main process validates the worker handoff before creating a temporary result. The result may be inspected or summarized, but it is not an artifact, report plan, collector entry, export, or project mutation. No-project compatibility remains narrow and synchronous; hosted child-process availability is tracked by TD-GENAI-006.

`result.persist` is provider-bound and project-bound. The model may supply only `temporary_result_id`; application code resolves the active provider, workspace, project, destination, persisted result id, bundle format, manifest, hashes, and idempotency key. The action is high risk, requires explicit approval, writes only allowlisted bounded supported result content, and never reruns analysis or generates a report.

## Future Agentic Lab Integration

Future Agentic Lab work should use this service layer rather than introducing provider-specific calls. Agentic behavior must remain separate from this contract and should add explicit permission, planning, preview-before-commit, and action policies before any executable actions are allowed.
