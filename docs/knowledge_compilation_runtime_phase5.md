# Knowledge Compilation Runtime Phase 5

Phase 5 adds governed multi-artifact synthesis.

The runtime now supports:

```text
Question
-> Artifact discovery
-> Artifact relevance
-> Applicability
-> Evidence sufficiency
-> Cross-artifact synthesis plan
-> Progressive retrieval
-> Structured synthesis
-> Validated claims
```

The objective is better synthesis, not larger context.

## Synthesis Planner

`plan_cross_artifact_synthesis()` runs before model invocation. It produces:

- candidate artifacts
- required artifacts
- optional artifacts
- missing artifacts/evidence classes
- retrieval order
- retrieval depth
- bundle selection
- expected evidence classes
- contradictions
- coverage
- required claims
- prohibited claims
- required citations
- supported read-only actions

The LLM should not decide the evidence plan by itself.

## Evidence Classes

The runtime preserves evidence classes rather than merging them:

- Observed
- Experimental
- Randomized
- Observational
- Predictive
- Forecast
- Simulation
- Expert Judgment
- Assumption
- Valuation
- Workflow
- Implementation
- Outcome
- Memory
- Knowledge
- Recommendation
- Decision
- Authority

This distinction prevents predictive, causal, valuation, authority, and outcome evidence from being treated as interchangeable.

## Applicability

Each candidate artifact records:

- population
- time horizon
- organization
- lever range
- decision context
- estimand
- assumptions
- context
- authority
- coverage

The synthesis must explain why an artifact does or does not apply.

## Contradictions

The contradiction engine distinguishes:

- true contradiction
- scope difference
- version supersession
- expected disagreement
- unknown
- none

Contradictory artifacts remain visible. They are not compressed away.

## Evidence Sufficiency

Sufficiency states include:

- sufficient
- probably sufficient
- missing contradictory evidence
- missing causal evidence
- missing valuation
- missing workflow
- missing implementation
- missing outcome
- missing authority
- missing assumptions
- human review required

The model should never silently assume completeness.

## Coverage

Coverage records:

- requested evidence
- retrieved evidence
- omitted evidence
- unavailable evidence
- contradictory evidence
- unresolved evidence
- superseded evidence
- outside-scope evidence
- rejected evidence

Every omission includes a deterministic reason.

## Structured Synthesis

`structured_cross_artifact_synthesis()` returns:

- question
- evidence considered
- evidence omitted
- evidence classes
- contradictions
- agreement
- limitations
- confidence
- supported claims
- prohibited claims
- remaining uncertainty
- recommended next action
- required additional evidence
- citations
- synthesis plan
- runtime diagnostics

Every claim preserves supporting artifacts, contradictory artifacts, applicability, confidence, claim strength, limitations, and review requirement.

## Compression Benchmark

`run_cross_artifact_compression_benchmark()` compares:

- single artifact
- cross-artifact synthesis
- retrieve everything

It records tokens, latency placeholders, corrections, quality, coverage, unsupported claims, contradiction preservation, and reasoning quality per token.

## Boundaries

Phase 5 does not introduce:

- artifact mutation
- automatic evidence attachment
- vector search
- semantic search
- estimators
- optimization
- fine tuning
- autonomous operation

It remains governed synthesis over evidence-bearing artifacts.
