# Decision Workflow Intelligence Architecture

Decision Workflow Intelligence is the governed follow-through layer after Decision Valuation. It allows Analytics Workstation to preserve the path from a valued recommendation to review, approval, implementation planning, realized implementation, monitoring, outcome review, realized-value assessment, and follow-up candidates.

## Placement

```text
Authored Decision
-> Decision Valuation
-> Decision Workflow
-> Project Artifact Collector
-> Mission Control / GenAI bounded context / reports
```

The app authors workflow state. AutoQuant owns the deterministic workflow contracts and QA.

## App State

Project state stores `decision_workflow_state` alongside semantic workspace, authored decision lifecycle, decision valuation, causal intelligence, and causal evidence states. The state contains:

- workflow rows
- review requests
- reviews
- approvals
- conditions
- implementation plans
- realized implementation evidence
- monitoring plans
- realized value records
- deterministic run results
- registered workflow artifacts
- event history

Older projects without `decision_workflow_state` remain valid and are normalized to an empty workflow state during project load.

## Workbench

The Semantic Intelligence page includes a Decision Workflow workbench after Decision Valuation. It supports:

- a guided decision summary before raw contract fields
- deterministic proportional-workflow classification
- next-action guidance across authoring, valuation, review, approval, implementation, outcome review, and collector registration
- a bounded evidence inbox populated from explicit decision evidence refs and project artifact metadata
- evidence-gap guidance that distinguishes required blockers from advisory gaps
- stale-state explanation with affected objects and recovery order
- human-readable version comparison for material workflow changes
- selecting or creating a workflow for the active authored decision
- linking valuation evidence
- saving review and approval records
- saving approval conditions
- creating an implementation plan
- recording realized implementation evidence
- adding KPI/guardrail monitoring
- recording realized value
- running deterministic workflow assessment
- registering the workflow artifact

The workbench is not a workflow designer and does not execute approved actions.

## Operational UX Philosophy

Phase 2 adds an operational UX layer over the deterministic contracts. The governing rule is:

```text
Preserve consequential rigor while eliminating non-consequential effort.
```

Users should spend effort on defining the decision, distinguishing alternatives, evaluating assumptions, exercising authority, and interpreting outcomes. The app should reduce effort spent copying IDs, rediscovering known context, remembering prerequisites, and interpreting stale state.

The app uses progressive disclosure. Guided panels appear before raw fields. Raw fields remain available because the deterministic contract is still the source of truth. Context is reused before new authoring: existing objectives, tactics, levers, evidence, valuation results, and workflow records are summarized and linked rather than copied invisibly.

Lightweight decisions may remain advisory. High-consequence decisions receive stronger review and monitoring recommendations. Human override remains possible, but consequential changes require explicit rationale and visible records.

## Mission Control

Mission Control surfaces:

- a bounded Decision Work Queue
- the deterministic next action and why it is next
- workflow not assessed
- review readiness gaps
- open or breached conditions
- implementation deviations
- follow-up decision candidates
- unregistered workflow artifact

Decision Lifecycle, Decision Valuation, and Decision Workflow remain separate tiles because they answer different questions.

## Artifact Collector

Registered workflow evidence becomes a standard project artifact under the Semantic Intelligence module. The artifact includes readiness, review/approval status, implementation reconciliation, decision-quality state, realized-value status, and follow-up candidates.

## GenAI Context

GenAI receives only a bounded workflow summary:

- workflow count and active ID
- readiness
- review/approval counts
- open conditions
- implementation deviations
- decision-quality state
- follow-up count
- campaign seed summary

GenAI may explain workflow state or draft review language. It may not approve decisions, impersonate reviewers, waive conditions, fabricate implementation evidence, or execute actions.

## Practical Workflow Guide

Shortest valid route:

1. Author the business context needed for the decision: objective, tactic or lever, KPI, authority, and coverage.
2. Create a decision context with a clear question.
3. Add a current-policy baseline and one competing alternative.
4. Add minimum decision criteria and financial or utility evidence.
5. Assess the authored decision.
6. Run decision valuation.
7. Create a proportional workflow.
8. Run workflow assessment.
9. Freeze/register evidence and request review.
10. Record review, approval, implementation, monitoring, realized value, and follow-up candidates as they become available.

Advanced route:

1. Reuse organizational context and existing artifacts from the evidence inbox.
2. Add explicit uncertainty, optionality, constraints, guardrails, and causal or experimental evidence.
3. Use proportional complexity classification to select stronger review depth only where consequence, authority, uncertainty, or exposure justify it.
4. Resolve gap guidance before review.
5. Use stale-state explanation after edits to decide whether the assessment, valuation, evidence package, review, or approval must be refreshed.
6. Preserve the final workflow artifact to the Project Artifact Collector.

## Recovery

Stale state is not repaired silently. The workbench explains:

- what changed
- which downstream objects are affected
- which records remain historically viewable
- the recommended recovery sequence

Typical recovery order is:

```text
reassess authored decision
-> rerun valuation
-> rerun workflow assessment
-> refresh review package
-> refresh approval if material fields changed
```

## Limitations

Phase 2 intentionally does not implement identity infrastructure, electronic signatures, ERP integration, autonomous approval, autonomous execution, portfolio allocation, MMM, observational causal estimation, bulk import, semantic vector search, or reviewer-only routes.
