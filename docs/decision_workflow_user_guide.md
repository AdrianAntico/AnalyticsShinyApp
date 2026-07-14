# From Business Question To Closed Decision

This guide describes the practical Decision Workflow route in Analytics Workstation. It is intentionally operational. The architecture remains deterministic, but the user experience should feel like guided decision work rather than schema editing.

## Governing Principle

Preserve consequential rigor while eliminating non-consequential effort.

The analyst should spend time on:

- defining the decision
- distinguishing alternatives
- evaluating assumptions
- reviewing tradeoffs
- exercising authority
- interpreting outcomes

The app should reduce repeated work such as copying internal IDs, reconstructing existing relationships, locating scattered evidence, and remembering lifecycle prerequisites.

## Shortest Valid Route

1. Create or select the relevant objective, tactic, lever, KPI, authority, and coverage.
2. Create a decision context with a clear decision question.
3. Add the current-policy baseline.
4. Add at least one competing alternative.
5. Add minimum criteria and financial or utility evidence.
6. Assess the authored decision.
7. Run decision valuation.
8. Create a proportional workflow.
9. Run workflow assessment.
10. Register valuation and workflow artifacts to the collector.
11. Record review, approval, implementation, monitoring, and outcome evidence as those events occur.

## Advanced Route

Use the advanced route when the decision is high consequence, cross-functional, uncertain, or authority-sensitive:

1. Add uncertainty, optionality, constraints, guardrails, risks, and assumptions.
2. Attach causal, experimental, predictive, forecasting, financial, and contradictory evidence through explicit evidence references.
3. Inspect the evidence inbox for candidate project artifacts.
4. Resolve evidence-gap guidance before review.
5. Use complexity classification to choose the minimum sufficient workflow level.
6. Freeze a version-specific evidence package.
7. Request scoped reviews.
8. Record approval conditions and authority basis.
9. Compare approved intent to realized implementation.
10. Complete realized-value and decision-quality review.
11. Preserve follow-up candidates as future decision seeds.

## Proportional Workflow Levels

Analytics Workstation classifies workflow complexity deterministically from available project state:

- lightweight advisory
- standard decision
- high-consequence decision
- cross-functional decision
- executive escalation

This classification recommends review depth and monitoring level. It does not approve anything and does not prevent governed human override.

## Evidence Inbox

The evidence inbox is bounded and deterministic. It suggests evidence from:

- explicit decision evidence references
- project artifacts
- artifact metadata
- module provenance
- analytical intent

Suggested evidence is not automatically accepted. Users must attach, reject, or ignore evidence explicitly.

## Stale State Recovery

When decision inputs change, downstream objects may become stale. The workbench should explain:

- what changed
- which downstream objects are affected
- which evidence remains historically viewable
- the recovery sequence

Recommended recovery order:

```text
reassess authored decision
-> rerun valuation
-> rerun workflow assessment
-> refresh review package
-> refresh approval if material fields changed
```

## GenAI Guardrails

GenAI may help draft, summarize, and explain. It may not:

- invent alternatives as facts
- invent financial values
- approve decisions
- waive authority
- suppress negative evidence
- execute implementation
- silently mutate workflow state

All generated content must be reviewable and grounded in supplied evidence.

