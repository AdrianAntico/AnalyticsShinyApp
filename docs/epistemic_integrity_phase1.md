# Epistemic Integrity Phase 1

Phase 1 makes epistemic integrity executable enough for runtime use.

The goal is not to build a complete bias/fallacy catalog. The goal is to establish the first governed path:

```
human assertion or intervention
-> structured provenance
-> deterministic reasoning-risk findings
-> claim-to-evidence assessment
-> epistemic significance
-> quality gate
-> human adjudication state
-> compiled AI guidance
```

## Portable Contracts

AutoQuant now owns the portable epistemic contracts:

- `aq_epistemic_intervention_event()`
- `aq_epistemic_claim_record()`
- `aq_detect_epistemic_findings()`
- `aq_assess_epistemic_claims()`
- `aq_epistemic_quality_gates()`
- `aq_epistemic_adjudication()`
- `aq_epistemic_integrity_artifact()`
- `aq_epistemic_risk_registry()`
- `qa_epistemic_integrity_contracts()`

AnalyticsShinyApp consumes these contracts through `R/epistemic_integrity_workspace.R`.

## Initial Risk Coverage

The deterministic registry covers these observable risks:

- post-result population change
- metric or outcome switching
- favorable time-window change
- undocumented exclusion
- robustness cherry-picking
- contradictory-evidence omission
- causal-language overreach
- estimand drift
- claim strength beyond evidence
- authority-requested analytical change
- missing independent review
- unsupported narrative strengthening

The registry is extensible, but Phase 1 only implements detectors where the signal can be represented in structured records.

## Claim Governance

Claims preserve:

- claim text
- claim type
- requested claim strength
- evidence strength
- evidence references
- causal-language flag
- decision context
- estimand reference
- review status

The claim assessment reports:

- support status
- allowed strength
- overclaim flag
- review requirement
- permitted wording
- prohibited wording

## Quality Gates

Epistemic gates are deterministic:

- critical findings block decision-ready claims until review/adjudication;
- high findings warn and must be carried as caveats;
- claim strength beyond evidence blocks unsupported wording;
- absence of findings produces a pass gate.

These gates do not prove truth. They enforce evidence discipline.

## Adjudication

Adjudication records preserve:

- finding id
- adjudicator id/role
- adjudication state
- decision
- rationale

The system can represent pending, valid, not material, false positive, and superseded finding states without assigning actor reputation or hidden credibility scores.

## Runtime Compilation

The Knowledge Compilation Runtime now treats `../AutoQuant/R/epistemic_integrity.R` as an authoritative portable-schema source.

The `epistemic_integrity_explanation` bundle includes `epi_executable_contracts`, which tells the AI runtime that epistemic policy is executable governance, not just condensed prose.

The project-context digest includes a compact epistemic summary when available:

- status
- event count
- claim count
- finding count
- blocking gate count
- high/critical finding count
- review-required claim count
- last run timestamp

## Provider Availability Cleanup

Decision valuation and decision workflow QA now distinguish:

- provider package unavailable
- installed provider stale
- required export missing
- available

This fixed the prior aggregate QA ambiguity. In this environment the installed AutoQuant package was stale; refreshing the package from source restored the required exports.

## Boundaries

Deferred:

- broad autonomous document extraction
- full fallacy/cognitive-bias catalog
- vector search
- actor reputation scoring
- hidden credibility scoring
- autonomous adjudication
- automatic approval
- consequential action execution

The implementation supports deterministic governance plus token-efficient AI guidance. It does not let the model adjudicate, approve, or execute.

## QA

Focused QA:

- `AutoQuant::qa_epistemic_integrity_contracts()`
- `qa_epistemic_integrity_workspace()`
- `qa_knowledge_compilation_runtime()`

Aggregate QA includes the app-side epistemic workspace and the compiled runtime.
