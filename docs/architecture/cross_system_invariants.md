# Cross-System Contracts and Invariants

Phase 16 consolidates invariants that already exist across Analytics Workstation. It does not introduce a new orchestration layer, persistence engine, or governance framework.

The systems reviewed together are:

- Workspace and project storage
- Module results
- Project Artifact Collector
- Active modeling context
- GenAI action proposals and executions
- GenAI job execution
- GenAI delegation policy
- GenAI action audit ledger
- Improvement Ledger
- Remediation Plans
- Mission Control

## Contract Boundaries

The platform now treats these systems as one governed runtime, but each system still owns its local schema and lifecycle. The consolidation point is the contract boundary:

```text
Identity
Lifecycle
Health
Persistence
Audit
Replay
Schema version
```

No persisted schema is renamed in Phase 16. Existing readers remain strict where strict validation already existed.

## Identity Invariants

Durable ids must be storage-safe and stable enough to appear in JSON, NDJSON, RDS metadata, file names, and cross-ledger references.

Existing identity families include:

| Identity | Owner | Examples |
| --- | --- | --- |
| Project | Workspace storage | `project_id` |
| Module | Module registry | `module_id` |
| Artifact | Artifact model / collector | `artifact_id` |
| Active modeling context | Project state / module metadata | trusted `active_dataset` plus `modeling_context_v1` lineage |
| GenAI proposal | GenAI action layer | `proposal_id` |
| GenAI execution | GenAI action layer / job manager | `execution_id` |
| GenAI job | Job manager | `job_id` |
| Audit event | Action audit ledger | `audit_event_id` |
| Improvement item | Improvement Ledger | `item_id` |
| Remediation plan | Remediation Plans | `plan_id` |
| Plan event | Remediation Plans | `plan_event_id` |
| Checkpoint | Ledger-specific | latest event metadata |

The app uses `storage_resource_id_is_valid()` as the common safety rule for ids that may become file names or resource handles.

## Lifecycle Invariants

Subsystem states do not need identical names. They do need compatible semantics.

Shared lifecycle meanings:

- Created or proposed state is not execution.
- Pending, queued, awaiting approval, and awaiting input are non-terminal waiting states.
- Running means work is actively executing or being attempted.
- Completed means the local operation completed.
- Completed technical execution does not automatically mean an analytical issue is resolved.
- Failed, cancelled, expired, superseded, rejected, duplicate, and archived-like states are historical or terminal depending on subsystem.
- Terminal remediation plans cannot resume.
- State transitions are validated by the owning subsystem before execution continues.
- Terminal historical records remain inspectable.

The following systems already centralize transition rules:

- GenAI jobs through `genai_job_transition_map()`
- Remediation plans through `remediation_plan_lifecycle()`
- Improvement items through `improvement_status_transition_map()`

Mission Control may summarize these states, but it must not redefine their lifecycle semantics.

## Modeling Context Invariants

The app currently has one trusted dataset identity for actions: `active_dataset`. Phase 25 adds `modeling_context_v1` so that identity is no longer opaque. The context records whether the active data is the original source/project dataset or an explicitly activated prepared dataset artifact, plus the source label, active prepared artifact id, preparation execution id, feature manifest, activation timestamp, and lineage summary.

Invariants:

- Prepared datasets never silently replace source data.
- Activation is explicit and user-triggered.
- The original source data is preserved in session where possible and can be restored through an explicit revert action.
- Project save/load persists the active modeling context as metadata.
- Missing prepared artifacts fail validation; the app must not silently substitute another dataset.
- CatBoost Builder records the exact active modeling context and feature manifest in historical model result metadata.
- GenAI resource resolution may summarize the context, but it may still reference only the trusted `active_dataset` id.

## Health Invariants

Health reporting is diagnostic, not a second state machine.

Common health values include:

- `healthy`
- `missing`
- `unavailable`
- `malformed`
- `partial`
- `partial_tail`
- `unsupported_schema`
- `event_history_mismatch`
- `hash_chain_mismatch`

Systems may expose a narrower vocabulary when appropriate, but replay and ledger systems must distinguish missing state from corrupted state.

## Persistence Invariants

Persistent writes must flow through trusted project storage.

The following rules already exist and remain invariant:

- Application source is not runtime storage.
- Persistent writes require a ready workspace and ready project.
- Persistent writes must remain inside the active project root.
- GenAI actions do not supply arbitrary output directories.
- Result persistence is idempotent.
- Persisted result manifests include schema versions and content hashes.
- Workspace and project provider fingerprints protect persistence approvals from stale provider state.

## Ledger Invariants

Event ledgers are append-only.

Existing append-only ledgers:

- GenAI action audit events
- Improvement Ledger events
- Remediation plan events

Ledger invariants:

- Events are bounded.
- Events include schema versions.
- Events carry timestamps.
- Events are hash chained where implemented.
- Replay must be deterministic.
- Malformed or hash-inconsistent histories are reported as unhealthy.
- Unhealthy remediation event histories reject further appends.
- Checkpoints accelerate recovery but do not replace event history.
- Audit history is never silently rewritten.

## Action Governance Invariants

GenAI action execution remains governed.

- Only registered actions can execute.
- Model output may propose actions but cannot execute directly.
- Proposals are validated against the registry.
- Risk tiers may not be understated.
- Approval and delegation policy remain separate.
- Delegation is bounded and session scoped.
- Persistent actions remain storage-gated.
- Arbitrary code execution is not part of the GenAI action layer.

## Improvement and Remediation Invariants

The Improvement Ledger records durable findings and issues. Remediation Plans describe bounded paths for accepted items.

Invariants:

- Findings are not automatically durable improvement items.
- Attempts are not resolution.
- Re-evaluation is required before a remediation item is resolved.
- Remediation plans are created from accepted improvement items.
- Plans execute one governed step at a time.
- Manual checkpoints pause execution.
- Approval checkpoints pause execution.
- Expired plans fail closed.
- Superseded plans remain historical.
- Completed remediation plans remain readable after the source item is resolved.

## Artifact Invariants

Artifacts are analytical evidence, not transient UI output.

Current invariants:

- Artifact bundles are standardized before collector append.
- The collector operates on bundle contracts, not module-specific logic.
- Artifact quality is assessed as metadata and does not alone fail collection.
- Human and LLM render targets are separate delivery contracts.
- Table artifacts carry policy metadata when the producer knows analytical intent.

## Feature Experiment Invariants

Feature experiments are governed evidence loops, not AutoML searches.

Current invariants:

- Feature proposals must reference bounded evidence.
- Proposal records store metadata and parameters only; they do not store executable code.
- Unsupported transformations are preserved as recommendations, not executed through workarounds.
- Rodeo execution requires an approved supported proposal.
- Rodeo fit/apply must not mutate the source dataset.
- Challenger prepared datasets are artifacts and are not activated automatically.
- CatBoost challengers use a frozen baseline target, seed, split identity, parameters, and feature manifest.
- Baseline-versus-challenger comparison is deterministic before GenAI interpretation.
- Accepted challengers still require explicit adoption.
- Rejected, inconclusive, blocked, and failed outcomes remain evidence.
- Reconciliation must detect approved proposals without execution, executions without prepared artifacts, experiments without lineage, and accepted results without adoption state.

## Error Handling Invariants

The platform should fail safely.

- Validation failures return structured `service_result()` errors.
- Missing resources are not silently fabricated.
- Corrupted persisted state is classified, not repaired without policy.
- Schema mismatches fail closed for writes and unsafe opens.
- Replay failures surface ledger health.
- Hash failures block trust in the affected bundle or ledger.
- UI surfaces should explain what is missing or blocked without crashing the app.

## QA

`qa_cross_system_invariants()` verifies:

- lifecycle summaries exist for core systems
- lifecycle groups reference known states
- remediation terminal transitions are closed
- GenAI job terminal exceptions are intentional
- generated identity samples are storage-safe
- schema versions are declared and documented
- shared health vocabulary covers replay and hash failures
- ledger readers expose health-aware reads
- GenAI job events appear in the action audit event vocabulary
- remediation and improvement events cover terminal and resolution outcomes
- required architecture documents exist

This QA is part of `qa_analysis_modules_integration()` so contract drift is visible during aggregate smoke validation.

## Intentional Duplication

Some duplication remains intentional:

- Each subsystem keeps its own schema version function.
- Each subsystem keeps local validation for domain-specific required fields.
- Lifecycle states remain domain-specific instead of being forced into one universal status enum.
- Health values are common enough to compare, but each reader may expose only the values it can actually produce.
- Ledger event schemas remain separate because they capture different evidence.

This keeps the architecture explicit without creating a generic framework that would obscure ownership.
