# Technical Debt Register

Source of truth: `config/technical_debt.yml`

## Relationship To The Improvement Ledger

The technical debt register remains the source of truth for architectural, compatibility, and intentional-boundary debt. The project-scoped Improvement Ledger may reference technical debt IDs when a project concern, active remediation, or user-requested improvement depends on known debt.

Resolving an improvement item does not automatically resolve a technical debt entry. Debt resolution still requires the acceptance criteria in `config/technical_debt.yml`, an explicit register update, Markdown synchronization, and `qa_technical_debt_register()`.

The Improvement Ledger is appropriate for project-scoped findings, failed runs, UX friction, low-confidence concerns, user feedback, attempt history, and re-evaluation. The technical debt register is appropriate for durable architecture governance across projects.

Total registered items: 37

## Purpose

This register captures known limitations, intentional safety boundaries, deferred capabilities, and compatibility behavior from Phases 1-12. It prevents completion summaries from losing important constraints as GenAI execution expands.

The YAML register is authoritative. This Markdown file is the human-readable summary and must remain synchronized with the YAML.

## Classification Definitions

| Category | Meaning |
| --- | --- |
| `intentional_boundary` | A deliberate product or safety boundary. It limits capability by design and must not be treated as a defect. |
| `deferred_capability` | A wanted feature that is intentionally postponed. |
| `technical_debt` | An implementation weakness or maintainability risk that should eventually be corrected. |
| `compatibility_debt` | Legacy naming, schema, behavior, or aliases retained for backward compatibility. |

## Severity Definitions

| Severity | Meaning |
| --- | --- |
| `low` | Localized limitation or future ergonomics issue. |
| `medium` | Material product or maintainability constraint, but not blocking current safe operation. |
| `high` | Blocks a major planned capability, safety posture, or deployment mode. |
| `critical` | Blocks safe use of the current product. No current Phase 10.5 item is classified critical. |

## Status Definitions

| Status | Meaning |
| --- | --- |
| `open` | Known and unresolved. |
| `accepted` | Deliberately retained as a current boundary or compatibility behavior. |
| `planned` | Expected to be addressed in a known future phase. |
| `in_progress` | Work has started but acceptance criteria are not met. |
| `resolved` | Acceptance criteria are met and resolution metadata is recorded. |
| `superseded` | Replaced by another registered item or architecture decision. |

## Summary Counts

### By Category

| Category | Count |
| --- | ---: |
| `technical_debt` | 18 |
| `deferred_capability` | 8 |
| `intentional_boundary` | 8 |
| `compatibility_debt` | 3 |

### By Severity

| Severity | Count |
| --- | ---: |
| `high` | 6 |
| `medium` | 18 |
| `low` | 13 |
| `critical` | 0 |

### By Status

| Status | Count |
| --- | ---: |
| `open` | 21 |
| `accepted` | 10 |
| `planned` | 1 |
| `resolved` | 4 |
| `superseded` | 1 |

## Open Technical Debt

| ID | Title | Severity | Resolution Trigger |
| --- | --- | --- | --- |
| TD-GENAI-003 | Oversized GenAI action layer file | medium | Before adding a third executable module or materially changing persistence/audit behavior. |
| TD-GENAI-004 | Duplicated result-type branching | low | Before adding a third executable module or module-specific browser/render behavior that cannot use descriptors. |
| TD-GENAI-005 | Module-specific preflight logic is not yet abstracted | medium | Before adding several modules with overlapping role/type/sufficiency checks. |
| TD-GENAI-006 | Hosted worker process availability | medium | Before hosted deployments assume child R process creation and hard termination are available. |
| TD-STORAGE-001 | No cross-process project locking | high | Before concurrent writers or hosted multi-user project sharing. |
| TD-STORAGE-002 | No cross-process persistence locking | medium | Before concurrent GenAI persistence targets the same project from multiple sessions. |
| TD-AUDIT-001 | No cross-process audit locking | medium | Before multiple app processes write to the same project audit ledger. |
| TD-AUDIT-002 | Audit reconciliation focuses on persisted results | low | When UI action history becomes a user-facing governance surface. |
| TD-AUDIT-003 | Proposal lifecycle events are not emitted from every UI surface | low | Before audit history is presented as a complete compliance ledger. |
| TD-RESULT-001 | Temporary results are session-local | medium | If expensive temporary computations need to survive browser refresh before approval. |
| TD-RESULT-003 | Invalid persisted bundles are diagnosed but not repaired | low | After schema migration and user-confirmation policies are defined. |
| TD-SCHEMA-001 | Schema migration strategy is limited | medium | Before breaking durable schema changes. |
| TD-LOCKING-001 | No distributed locking or multi-user conflict handling | high | Before shared project editing or hosted collaborative workspaces. |
| TD-IMPROVEMENT-001 | Improvement ledger deduplication is signature-based | medium | Before high-volume automatic ingestion from many diagnostics or GenAI concern proposals. |
| TD-IMPROVEMENT-002 | Improvement ledger indexes and performance policy are minimal | medium | Before hosted projects or long-running projects depend on thousands of improvement items or high-frequency automatic ingestion. |

## Compatibility Debt

| ID | Title | Status | Canonical Behavior |
| --- | --- | --- | --- |
| COMPAT-MODULE-001 | Historical autoquant_model_assessment alias retained | accepted | Active UI and preferred docs use `autoquant_model_readiness`. |
| COMPAT-PROJECT-001 | Legacy project path compatibility retained | accepted | Project paths normalize through the current storage model. |
| COMPAT-SCHEMA-001 | Deprecated object names retained in old reports | accepted | New work uses the canonical artifact/report model. |

## Intentional Boundaries

| ID | Title | Severity | Reason |
| --- | --- | --- | --- |
| BOUNDARY-GENAI-001 | No delegated persistence | high | Durable project mutation requires explicit approval. |
| BOUNDARY-GENAI-002 | No action chaining | high | Approval and audit must remain scoped to one action. |
| BOUNDARY-GENAI-003 | No arbitrary Code Runner execution through GenAI | high | Arbitrary code has a different risk profile from registered handlers. |
| BOUNDARY-GENAI-004 | Session-only delegation | medium | Avoids silent long-lived authority. |
| BOUNDARY-GENAI-005 | Delegation invalidated on project reload | medium | Grants bind to project/provider/resource identity. |
| BOUNDARY-GENAI-006 | Durable audit is project-scoped only | low | Durable memory needs a trusted project owner. |
| BOUNDARY-GENAI-007 | Model Assessment regression-only slice superseded | medium | Superseded by Phase 11 mode-aware Model Assessment. |
| BOUNDARY-GENAI-008 | Model Assessment excludes multiclass and model mutation | medium | Multiclass, model mutation, and threshold optimization require separate contracts. |

## Deferred Capabilities

| ID | Title | Status | Trigger |
| --- | --- | --- | --- |
| TD-PROJECT-001 | Active dataset is the only trusted dataset ID | planned | When projects support multiple named datasets or scored datasets. |
| TD-PROJECT-002 | Provider and workspace selection depends on host capability | open | When a deployment target exposes trusted picker/open-folder APIs. |
| DEFERRED-RESULT-001 | Persisted-result export absent | open | When persisted results become delivery artifacts. |
| DEFERRED-RESULT-002 | Persisted-result rename absent | open | After metadata mutation policy exists. |
| DEFERRED-RESULT-003 | Persisted-result delete absent | open | When result lifecycle management becomes necessary. |
| DEFERRED-RESULT-004 | Persisted-result migration absent | open | Before breaking persisted-result schema changes. |
| DEFERRED-GENAI-001 | Binary Model Assessment deferred | resolved | Resolved in Phase 11 by `model_assessment_binary`. |
| DEFERRED-MISSION-001 | Mission Control debt counts not yet surfaced | open | When Mission Control architecture-health alert policy is defined. |

## Resolution Triggers

Resolution triggers are intentionally concrete. A future phase does not need to resolve every item, but it must update the YAML when it crosses a trigger. Examples:

- A third executable GenAI module triggers TD-GENAI-003, TD-GENAI-004, and TD-GENAI-005 review.
- Multiclass Model Assessment, model training/tuning, external scoring, or threshold optimization triggers BOUNDARY-GENAI-008 review.
- Multi-user or hosted shared projects trigger TD-STORAGE-001, TD-STORAGE-002, TD-AUDIT-001, and TD-LOCKING-001 review.
- Breaking schema changes trigger TD-SCHEMA-001 and DEFERRED-RESULT-004 review.

## Current Blockers

- Collaborative/shared project editing is blocked by TD-STORAGE-001 and TD-LOCKING-001.
- Delegated computation remains blocked by BOUNDARY-GENAI-001; computational actions still require explicit approval.
- Hosted isolated execution guarantees are blocked by TD-GENAI-006 until the deployment target confirms child process support or a hosted-safe backend exists.
- Breaking durable schema changes are blocked by TD-SCHEMA-001.

## Architecture Consolidation Review

`R/genai_actions.R` has accumulated too many responsibilities:

- action registry
- proposal schema and parsing
- validation and policy checks
- approval rendering helpers
- resource resolution
- action execution
- temporary result contracts
- persistence handoff
- result inspection
- module-specific preflight
- module-specific execution
- action QA

This is registered as TD-GENAI-003. Phase 11 performed a targeted extraction of stable result-type and Model Assessment mode descriptors into `R/genai_result_contracts.R`. Phase 12 kept worker orchestration out of `R/genai_actions.R` by adding `R/genai_worker_contracts.R`, `R/genai_worker_runtime.R`, and `R/genai_job_manager.R`. The action layer still owns proposal policy, execution normalization, persistence, UI helpers, and broad QA. The recommended future decomposition is:

```text
R/genai_action_registry.R
R/genai_action_proposals.R
R/genai_action_policy.R
R/genai_action_execution.R
R/genai_action_results.R
R/genai_action_persistence.R
R/genai_action_modules.R
```

Extraction should be behavior-preserving and should run the full GenAI action QA after each split.

## Duplication Audit

Phase 10 introduced the second temporary result type. The following findings are registered:

| Area | Classification | Registered ID | Notes |
| --- | --- | --- | --- |
| Temporary result creation | partially descriptor-driven | TD-GENAI-004 | Result types and output contract versions now route through `R/genai_result_contracts.R`; temporary payload assembly still branches on common optional fields. |
| Output validation | partially descriptor-driven | TD-GENAI-004 | Required fields now come from result descriptors; binary-specific metric reconciliation remains explicit. |
| Persistence serialization | technical debt | TD-GENAI-004 | Shared bundle writer handles metrics, threshold metrics, tables, and plot specs, but serializer policy is not fully descriptor-owned. |
| Browser rendering | shared abstraction candidate | TD-GENAI-004 | Metrics/table/plot sections are generic; specialized binary presentation is still minimal. |
| Module-specific preflight | technical debt | TD-GENAI-005 | Role/type/sufficiency checks should become composable. |
| Audit fields | acceptable specialization | none | Current added fields are generic enough: result type, output contract, config fingerprint, preflight id. |
| Resource-limit handling | acceptable specialization for now | TD-GENAI-004 | Module resource profiles work; future descriptors may own limits. |

Phase 11 extraction reduced result-type duplication enough to safely add `model_assessment_binary`, but TD-GENAI-004 remains open at lower severity because serialization and browser behavior are not fully descriptor-driven.

## Phase-Gate Policy

Every future implementation summary must include:

```text
Debt and Boundary Review

New debt introduced:
- ...

Existing debt resolved:
- ...

Existing debt changed:
- ...

Intentional constraints added:
- ...

Compatibility behavior retained:
- ...
```

A phase is incomplete if new debt is introduced but not registered, existing debt changes but is not updated, a known limitation is mentioned only in prose, compatibility aliases are added without a compatibility-debt entry, or a safety boundary changes without updating the register.

## How Entries Are Updated

1. Edit `config/technical_debt.yml`.
2. Preserve stable IDs unless an entry is explicitly superseded.
3. Update `last_reviewed_phase` for materially reviewed items.
4. Add `resolved_phase` and `resolution_summary` when marking an item resolved.
5. Update this Markdown summary.
6. Run `qa_technical_debt_register()`.

## Phase 11 Update

Phase 11 resolved DEFERRED-GENAI-001 by adding `model_assessment_binary` under the existing `model_assessment` registered module. It also superseded BOUNDARY-GENAI-007 and introduced BOUNDARY-GENAI-008 for the remaining exclusions: multiclass assessment, model training/tuning, threshold optimization, external scoring, artifact generation, and report generation.

Current Phase 11 decision: binary scored-output diagnostics are supported only through trusted app-state configuration, explicit approval, bounded temporary execution, separate persistence approval, persisted-result discovery, read-only inspection, and durable audit reconciliation.

## Phase 12 Update

Phase 12 resolved:

- TD-GENAI-001: project-scoped `analysis.run_registered` now executes through an isolated `callr` worker for `dataset_profile`, `model_assessment_regression`, and `model_assessment_binary`.
- TD-GENAI-002: isolated project-scoped registered analysis supports hard worker termination, cancellation status, and incomplete-handoff discard.
- TD-RESULT-002: durable job records classify restart state and completed validated handoffs can reconstruct session temporary results without automatic persistence.

Phase 12 changed:

- TD-GENAI-003: worker orchestration was extracted into dedicated files, but the action layer remains broad and still needs future decomposition.

Phase 12 introduced:

- TD-GENAI-006: hosted worker process availability remains open because some hosted Shiny environments may prohibit child R processes.
