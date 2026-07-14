# Knowledge Compilation Runtime Phase 2

Phase 2 expands the private AnalyticsShinyApp runtime from compact guidance into a governed AI operator runtime.

This remains app-private product intelligence. AutoQuant owns portable analytics contracts. AnalyticsShinyApp owns compiled runtime bundles, model-tier routing, operator cards, diagnostics, benchmarking, and UI orchestration.

## Implemented Scope

Phase 2 adds:

- Epistemic runtime bundles that include portable epistemic integrity contracts.
- Operator runtime bundles for bounded app tasks.
- Action classes 0 through 4, with Phase 2 support limited to classes 0 through 2.
- Deterministic task routing for supported AI operator tasks.
- Tier-specific context compilation for deterministic, local/free, paid-standard, and frontier models.
- Model-tier capability profiles with supported tasks, unsupported tasks, weaknesses, strengths, verification requirements, escalation triggers, and token budgets.
- Runtime diagnostics that expose task, bundle, model tier, token usage, validation state, fallback, escalation, cache status, context hash, and runtime version.
- Deterministic cache keys for compiled bundles and context packages.
- Model-tier benchmark fixtures for fitness-for-task comparison.
- A read-only AI Runtime developer page.

## Supported Operator Tasks

The Phase 2 operator supports bounded proposal/diagnostic paths for:

- Navigate page.
- Open artifact.
- Run deterministic validation.
- Generate workflow summary.
- Generate observational summary.
- Create review draft.
- Create campaign draft.
- Attach existing artifact reference.
- Open Mission Control item.

The runtime validates proposals, but it does not autonomously mutate project state. Any actual app action remains governed by the existing deterministic action layer and its user approval requirements.

## Action Classes

| Class | Name | Confirmation | Mutation |
|---:|---|---|---|
| 0 | Pure explanation | Not required | No |
| 1 | Navigation | Not required | No |
| 2 | Draft generation / bounded validation proposal | Optional or required by handler | No |
| 3 | Project mutation | Required | Blocked in Phase 2 |
| 4 | Consequential action | Explicit governed workflow | Blocked in Phase 2 |

## Validation Gates

Every operator proposal is checked for:

- Required schema fields.
- Supported action id.
- Action class support.
- Registered existing app handler where applicable.
- Context hash match.
- Bundle version match.
- Artifact id resolution when artifact references are used.
- Prohibited claims.
- No project mutation by the compiled operator.

Unsupported actions are rejected before execution.

## Model-Tier Routing

Model tiers are treated as fitness-for-task profiles rather than generic intelligence rankings.

- `deterministic_only`: routing, validation, status, and benchmark fixtures.
- `local_free_model`: compact private synthesis, bounded summaries, simple epistemic explanations.
- `paid_standard_model`: richer drafts, review summaries, and multi-evidence synthesis when privacy and cost permit.
- `frontier_model`: complex ambiguity and contradiction synthesis after deterministic routing.
- `human_review_required`: sensitive, consequential, or authority-bound decisions.

Local/free models receive smaller scope, explicit rules, and examples. Frontier models receive fewer examples and more unresolved evidence because they are expected to reason over ambiguity after deterministic filtering.

## Runtime Diagnostics

The AI Runtime page exposes:

- Task.
- Bundle.
- Context hash.
- Model tier.
- Token budget and estimate.
- Validation status.
- Proposal JSON.
- Runtime diagnostics JSON.
- Deterministic benchmark summary.

This page is intentionally developer-oriented and read-only.

## Compression Philosophy

The runtime does not send architecture documents to the model. It sends compact compiled bundles plus project context digests. Compression quality is measured through deterministic token estimates, bundle/task fit, structured-output validation, and benchmark scenarios.

## Deferred Scope

Phase 2 does not implement:

- Autonomous execution.
- Automatic approval.
- Direct workflow transitions.
- Evidence mutation.
- Decision selection.
- Observational estimation.
- Portfolio optimization.
- MMM.
- Fine tuning.
- Vector databases.
- Semantic search.
- Identity management.
- Provider-specific logic.

## QA

`qa_knowledge_compilation_runtime()` validates source registry, curated units, dependencies, bundles, task routing, action classes, context packages, operator proposals, unsupported-action rejection, confirmation boundaries, model-tier profiles, caching, benchmarking, compression, and no-autonomous-execution guarantees.

`qa_ai_runtime_page()` validates the developer runtime page, task controls, diagnostics snapshot, and benchmark availability.
