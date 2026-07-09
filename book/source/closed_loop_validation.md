# Closed Loop Validation

This document stress-tests whether Ontology v1 can explain difficult or failing analytical workflows.

## Validation Verdict

The loop holds.

The ontology can explain both successful and failing workflows using existing concepts. The main issues are implementation gaps and calibration gaps, not missing foundational concepts.

Execution Mode / Delegation Policy does not invalidate this verdict. It overlays the loop with delegation rules rather than adding a new analytical layer. The same loop can run manually, with guided approval, with assisted automation, autonomously under policy, or in research step-by-step mode.

## Stress Test 1: Poor Model

Condition:

The trained model performs poorly.

Ontology explanation:

- Model Assessment and Model Insights produce weak evidence.
- Artifact Quality may still be complete.
- Trustworthiness is low.
- Knowledge State records weak findings and low confidence.
- Decision Readiness remains Insufficient Evidence or Preliminary.
- Future Evidence may request feature engineering, data review, model rebuild, or additional diagnostics.
- Mission Control should surface risk.

Loop status: complete.

Gap: Trustworthiness scoring needs refinement.

## Stress Test 2: Weak Evidence

Condition:

Evidence exists but is sparse, incomplete, low quality, or indirect.

Ontology explanation:

- Artifact Quality records component completeness.
- Trustworthiness marks evidence weak.
- Knowledge State records assumptions and low confidence.
- Evidence Sufficiency fails for high-confidence decisions.
- MIG may still recommend low-cost additional evidence.

Loop status: complete.

Gap: Need operational weak/strong evidence criteria.

## Stress Test 3: Conflicting Artifacts

Condition:

Two artifacts imply different conclusions.

Ontology explanation:

- Contradiction records conflict.
- Knowledge State lowers confidence.
- Evidence Sufficiency may fail.
- Future Evidence identifies analysis needed to resolve conflict.
- Evidence Routing can select both supporting and contradicting evidence for GenAI explanation.

Loop status: complete.

Gap: Contradiction detection is not implemented.

## Stress Test 4: Sparse Data

Condition:

Segment or interaction analysis is sparse.

Ontology explanation:

- Diagnostics and Artifact Quality record limitations.
- Weak Evidence applies.
- Knowledge State records assumption burden and unknowns.
- Decision Readiness remains below High Confidence.
- Future Evidence may request more data or aggregation changes.

Loop status: complete.

Gap: Sparse-data trustworthiness policy could be formalized.

## Stress Test 5: Vision Unavailable

Condition:

The provider cannot use image payloads.

Ontology explanation:

- Provider Capability records no vision.
- Context Optimization constrains representation.
- Context Strategy downgrades from screenshot-based to table/metadata/JSON.
- Observability records downgrade reason.
- Knowledge State is unaffected except confidence may be lower if visual evidence was important.

Loop status: complete.

Gap: Need strategy recommendation rules by artifact family.

## Stress Test 6: Tiny Token Budget

Condition:

User has a very small context budget.

Ontology explanation:

- Evidence Strategy is Efficient or token-saver.
- Context Optimization tightens budget.
- MIG prioritizes high-value, low-cost evidence.
- Evidence Routing selects critical artifacts only.
- Context Strategy favors captions, metadata, summaries, and sidecar references.
- Knowledge State records remaining uncertainty.

Loop status: complete.

Gap: Need calibrated compression policies.

## Stress Test 7: Unlimited Token Budget

Condition:

Cost is irrelevant.

Ontology explanation:

- Evidence Strategy is Cost Is Irrelevant or Critical Decision.
- Context Optimization relaxes budget.
- MIG still guards against redundancy, though threshold lowers.
- Evidence Routing expands coverage.
- Context Strategy may include screenshots, previews, JSON, diagnostics, and full tables when safe.

Loop status: complete.

Gap: Need avoid "send everything" degeneracy even under unlimited budget.

## Stress Test 8: Critical Decision

Condition:

Decision has high stakes.

Ontology explanation:

- Decision Readiness target becomes Critical Decision Ready.
- Evidence Sufficiency threshold rises.
- Context Optimization prioritizes confidence over cost.
- Evidence Routing includes contradictions, diagnostics, weak evidence, missing evidence, and supporting evidence.
- Knowledge State must expose assumptions and limitations.
- Observability records the evidence basis.

Loop status: complete.

Gap: Critical-decision thresholds need calibration.

## Stress Test 9: Missing SHAP

Condition:

SHAP artifacts are absent.

Ontology explanation:

- Missing Evidence records absent SHAP.
- Knowledge State records unknown model drivers.
- Evidence Sufficiency may fail for explanation questions.
- Future Evidence requests SHAP generation if available.
- Evidence Routing may select alternative evidence such as model metrics or variable importance.

Loop status: complete.

Gap: Need fallback explanation policies.

## Stress Test 10: Missing Diagnostics

Condition:

Artifacts exist but diagnostics are absent.

Ontology explanation:

- Artifact Quality records missing diagnostics.
- Trustworthiness is reduced.
- Knowledge State records assumption or limitation.
- Decision Readiness may be capped.
- Future Evidence requests diagnostics.

Loop status: complete.

Gap: Need policy for how missing diagnostics affects readiness.

## Stress Test 11: Report Generation Failure

Condition:

Report or DOCX write fails.

Ontology explanation:

- Delivery failure is not evidence failure.
- Collector may still preserve artifact bundles and manifest.
- Observability records failure.
- Knowledge State remains valid if evidence exists.
- Future Evidence is not necessarily required; delivery retry may be required.

Loop status: complete.

Gap: Need UI distinction between evidence failure and delivery failure.

## Stress Test 12: Contradictory GenAI Response

Condition:

GenAI produces a response that conflicts with evidence.

Ontology explanation:

- GenAI response is not source of truth.
- Observability records response.
- Contradiction can be logged if response is preserved.
- Knowledge State should not update silently.
- Human review or deterministic check required.

Loop status: complete.

Gap: Need policy for promoting GenAI output into knowledge.

## Closed Loop Failure Modes

The loop can break if:

- artifacts are generated without metadata
- collector does not preserve evidence
- Knowledge State is not updated after reasoning
- routing happens without a knowledge need
- context strategies are not recorded
- GenAI output updates knowledge silently
- delivery artifacts are mistaken for truth
- missing evidence is hidden
- contradictions are ignored
- execution mode bypasses required delegation gates
- autonomous execution hides evidence, cost, provider, or approval decisions

Each failure can be explained using existing ontology.

No new top-level concept is required.

## Delegation Stress Test

Condition:

The same business question is run under different delegation levels.

Ontology explanation:

- Evidence Strategy controls how much evidence is gathered.
- Execution Mode controls who advances the loop and where approval gates appear.
- Manual mode requires user approval for each major step.
- Guided mode recommends the next step and asks for approval.
- Assisted mode automates routine work but pauses at major gates.
- Autonomous mode can proceed only within explicit provider, privacy, cost, and safety policy.
- Research / Step-by-Step mode exposes intermediate decisions for validation.
- Observability records the path regardless of mode.

Loop status: complete.

Gap: Gate defaults and promotion-to-knowledge policy require future implementation and calibration.

## Final Closed Loop

```text
Business Question
-> Knowledge State
-> Knowledge Gap
-> Evidence Sufficiency
-> Context Optimization
-> Evidence Routing
-> Evidence Plan
-> Context Strategy
-> Reasoning
-> Decision / Finding / Recommendation
-> Collector / Delivery
-> Observability
-> Learning
-> Updated Knowledge State
```

Status: validated.
