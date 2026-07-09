# Evidence Strategy UX

Evidence Strategy is the user-facing bridge between business intent and the technical Context Optimization stack.

It maps simple decision-oriented choices into centralized routing configuration used by:

- Context Optimization Policy
- Evidence Routing Policy
- GenAI context construction
- observability logs

It does not create a parallel router.

## Core Idea

For any analytical decision, the workstation should consider:

- marginal benefit
- marginal cost
- contextual utility
- constraints
- uncertainty

The user should not have to think in token budgets first. They should be able to choose the decision posture, then inspect or override the technical settings when needed.

## Business Strategies

### Efficient

Fastest and lowest cost.

Best for:

- quick reads
- exploratory questions
- low-stakes decisions
- local/private usage

Default posture:

- low token budget
- few artifacts
- few tables and images
- no full tables
- no paid provider by default
- local/private friendly

### Balanced

Default mode.

Best for:

- normal business decisions
- routine model interpretation
- project briefings

Default posture:

- moderate token budget
- enough evidence for sound judgment
- safe full tables when small
- no paid provider by default

### Thorough

Broader evidence inclusion.

Best for:

- stakeholder-facing recommendations
- deeper analytical review
- uncertain findings

Default posture:

- more artifacts
- more diagnostics
- more caveats
- more supporting views
- higher token and latency budget

### Critical Decision

Evidence explosion allowed.

Best for:

- high-stakes business decisions
- production model approval
- executive signoff
- expensive media or pricing decisions

Default posture:

- redundancy allowed
- more screenshots
- more tables
- more diagnostics
- more caveats
- still no paid provider unless explicitly allowed

### Cost Is Irrelevant

Use everything reasonable.

Best for:

- offline/local runs
- nearly free token environments
- final review
- research or deep audit

Default posture:

- broadest practical evidence inclusion
- high token and latency limits
- evidence explosion allowed
- local preferred unless explicitly overridden

## Technical Configuration

Each strategy maps to centralized technical settings:

- `routing_profile`
- `marginal_gain_threshold`
- `max_artifacts`
- `max_images`
- `max_tables`
- `max_full_tables`
- `max_estimated_tokens`
- `max_latency_ms`
- `redundancy_tolerance`
- `deep_dive_threshold`
- `full_table_allowed`
- `image_payload_allowed`
- `paid_provider_allowed`
- `local_only`
- `vision_preference`
- `exact_value_bias`
- `diagnostic_bias`
- `caveat_bias`
- `novelty_weight`
- `trust_weight`
- `relevance_weight`
- `cost_weight`

The canonical mapping lives in `evidence_strategy_registry()`.

## Advanced Overrides

Technical users may override strategy settings without changing the business strategy catalog.

Examples:

- raise token budget
- reduce artifact budget
- require local-only providers
- allow paid provider use
- disable full tables
- increase redundancy tolerance
- lower deep-dive threshold
- prefer vision payloads

Overrides are recorded in the evidence plan and observability log.

## Explainability

For every selected strategy, the system should explain:

- what it will include
- what it will avoid
- when it will deep dive
- when it will stop adding evidence
- when it will request more evidence
- when it may use local GenAI
- when it may use paid GenAI

`evidence_strategy_explain()` returns plain-language strategy behavior.

## Evidence Frontier Summary

The system exposes qualitative frontier fields:

- estimated evidence completeness
- estimated token cost
- estimated latency
- expected confidence
- risk of missing nuance
- provider/privacy posture

These fields are intentionally approximate. They should guide decisions without pretending to be precise forecasts.

## Observability

Evidence plans and observability logs record:

- `evidence_strategy`
- `strategy_label`
- `strategy_description`
- `technical_config`
- `user_overrides`
- `business_tradeoff_summary`
- `selected_provider_mode`
- `paid_provider_allowed`
- `local_only`
- `evidence_explosion_allowed`

This allows future analysis of which strategies users prefer and which configurations produce useful answers.

## Non-Goals

Evidence Strategy does not implement:

- Agentic Lab
- autonomous actions
- automatic policy mutation
- automatic paid-provider escalation
- full data transmission by default

## Example

```r
plan <- build_evidence_plan(
  project,
  question = "What are the biggest model risks?",
  evidence_strategy = "critical_decision",
  evidence_strategy_overrides = list(
    technical_config = list(
      paid_provider_allowed = FALSE,
      max_estimated_tokens = 10000L
    )
  )
)
```

This produces a normal Evidence Routing plan, but the plan records the business strategy, technical configuration, overrides, tradeoff summary, and provider constraints.
