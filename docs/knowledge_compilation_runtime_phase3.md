# Knowledge Compilation Runtime Phase 3

Phase 3 adds deterministic AI model qualification and benchmark telemetry on top of the compiled runtime introduced in Phases 1 and 2.

The goal is not autonomous execution. The goal is to know, task by task, whether a configured model is allowed to explain, draft, navigate, propose a validated Class 2 action, or require human/frontier escalation.

## Qualification Contract

`ai_model_qualification` is scoped to:

- provider
- model
- model version
- task
- bundle id and bundle version
- runtime version

Qualification statuses are:

- `qualified`
- `qualified_with_validation`
- `qualified_for_low_consequence`
- `draft_only`
- `explanation_only`
- `navigation_only`
- `requires_frontier`
- `requires_human`
- `not_qualified`
- `unknown`

Qualifications expire when runtime version, bundle version, or expiration time changes. This prevents stale qualification from silently surviving policy or compiler changes.

## Benchmarking

The runtime registers benchmark tasks for:

- workflow explanation
- next action
- artifact summary
- claim extraction
- epistemic finding explanation
- observational summary
- campaign draft
- review draft
- Mission Control explanation
- runtime explanation

Each benchmark row records model/provider, bundle, context hash, qualification status, confidence, schema correctness, evidence fidelity, hallucinated ids, action validity, estimated tokens, latency, and validator outcome.

Unavailable providers are represented as unqualified benchmark rows. They do not fail application startup.

## Epistemic Fidelity

The benchmark evaluates deterministic epistemic risks:

- unsupported certainty
- suppressed uncertainty
- narrative overreach
- claim-strength inflation
- authority substitution
- missing contradiction or limitation
- unsupported causal language
- recommendation beyond evidence

These are not hidden credibility scores. They are observable validation dimensions used to decide whether a response can be trusted for a task.

## Action Safety

Phase 3 keeps the Phase 2 authority boundary:

- summaries are allowed
- drafts are allowed
- navigation proposals are allowed
- Class 2 actions require deterministic validation and explicit confirmation
- approval, deletion, evidence mutation, override, and autonomous execution remain prohibited

Hallucinated action ids and unsupported artifact ids are rejected before dispatch.

## Bundle Variants

The runtime can compare bundle variants:

- minimal
- standard
- expanded
- few examples
- many examples

The comparison records token estimates, expected quality, quality per token, correction-rate placeholders, escalation expectations, and validity against tier budgets.

## Human Review

Human adjudication labels can be attached to benchmark artifacts:

- correct
- acceptable
- unsafe
- hallucinated
- overclaimed
- underexplained
- needs escalation

These labels are intended to become benchmark truth for future calibration and fine tuning.

## UI Surfaces

The AI Runtime page now shows:

- current task and bundle
- validation status
- qualification status
- qualification confidence
- benchmark reference
- qualification benchmark table

Mission Control can surface AI runtime qualification availability, unqualified tasks, and expired qualification alerts.

## QA

Phase 3 adds deterministic QA for:

- qualification contract fields
- canonical qualification states
- hallucinated action rejection
- qualification expiration after runtime changes
- benchmark telemetry
- tier recommendations
- compression variants
- epistemic fidelity dimensions
- cold-start cases
- human review adjudication
- Class 2 validation and confirmation boundary

The implementation remains app-private. AutoQuant is not required for model qualification because the policy governs AI operator behavior inside AnalyticsShinyApp.
