# Causal Intelligence Hardening Phase 1

## Scope

This phase is a productization and hardening pass for the implemented causal paths:

- randomized assignment: governed ITT and randomized design-depth analysis;
- cross-sectional observational assignment: frozen adjustment design and AIPW evidence;
- time-based observational intervention: frozen classic two-group Difference-in-Differences evidence.

It does not add Regression Discontinuity, synthetic control, instrumental variables, event studies, staggered DiD, mediation, causal forests, continuous treatment, automatic estimator selection, or estimator shopping.

## Aggregate QA Timeout Diagnosis

`qa_analysis_modules_integration()` was reproduced as a long-running aggregate suite rather than a true hang.

Observed timing from the diagnostic run:

- full linear aggregate completed in approximately 216 seconds;
- a 180-second command timeout can therefore fail even when all child suites eventually succeed;
- no causal child suite was the cause of the timeout;
- the slowest components were `qa_evidence_routing_calibration()`, `qa_render_targets()`, nested knowledge-compilation runtime phase suites, evidence strategy configuration, cross-repository validation, cross-repository impact analysis, Mission Control, and remediation hardening.

Classification:

- aggregate-suite architecture problem;
- duplicate/nested validation work;
- insufficient timing observability before this phase;
- not a functional causal regression.

Remediation:

- `qa_analysis_modules_integration()` now records per-suite timing, start time, completion time, check counts, warnings, and errors;
- the default bounded profile executes operational QA and explicitly marks heavyweight suites as `deferred`;
- `qa_analysis_modules_integration(profile = "deep")` executes the deferred heavyweight suites;
- `qa_analysis_modules_integration(profile = "full")` preserves the historical all-in-one behavior.

The bounded and deep suites together preserve coverage while avoiding an unexplained monolithic timeout.

## Shared Causal Effect Contract

AnalyticsShinyApp now has an app-side shared causal-effect evidence vocabulary for reviewing randomized, AIPW, and DiD artifacts without pretending the designs are interchangeable.

The shared vocabulary includes:

- causal question ID;
- estimand ID;
- decision-context ID;
- treatment or intervention;
- comparison;
- target and analysis populations;
- assignment mechanism;
- design family;
- estimator family;
- time horizon;
- outcome and guardrail;
- effect scale;
- point estimate and uncertainty;
- materiality;
- readiness;
- assumptions, diagnostics, and sensitivity;
- applicability;
- permitted and prohibited claims;
- review status;
- lineage;
- supported actions.

Method-specific diagnostics remain method-specific. The shared contract exists so artifacts can be compared, reviewed, reported, and routed consistently.

## Cross-Method Review Rules

Multiple causal artifacts may be reviewed together only after comparability checks.

The review layer detects mismatches in:

- estimand;
- treatment or intervention;
- comparison;
- population;
- time horizon;
- outcome;
- effect scale.

When mismatches are present, the artifacts are classified as methodologically incomparable until reconciled. The system does not average estimates merely because they concern similar outcomes.

## Report Shell

The unified causal report shell separates:

- business decision;
- causal question;
- estimand;
- design family and rationale;
- treatment and comparison;
- population and timing;
- readiness;
- primary estimate and uncertainty;
- materiality;
- method-specific diagnostics;
- guardrails;
- sensitivity and falsification;
- applicability;
- contradictory evidence;
- permitted and prohibited claims;
- decision implications;
- recommended next action;
- review status;
- evidence lineage.

## Public/Private Placement

This document and the shared cross-method contract live in AnalyticsShinyApp.

Reason:

- the work concerns integrated workflow, evidence review, reporting, Mission Control visibility, and AI/product orchestration;
- no new portable estimator or public AutoQuant API was introduced;
- AutoQuant remains the owner of portable estimator contracts and diagnostics.

This document exposes private product orchestration and should not be treated as public AutoQuant package documentation.

## Remaining Limitations

- The shared contract normalizes artifact metadata but does not yet enforce all fields at artifact creation time.
- Cross-method review classifies pairwise compatibility but does not yet provide a full visual evidence review interface.
- Decision Valuation can consume causal metadata, but deeper causal-specific valuation QA remains future work.
- Epistemic checks for post-result causal manipulation are not yet exhaustively wired to every causal artifact lifecycle.
- Benchmark worlds are still represented by existing deterministic causal QA fixtures rather than a named benchmark-world registry.

## Recommended Next Program

Before adding another estimator family, harden user-facing causal workflow:

1. make the Causal Intelligence page read as one end-to-end workflow rather than separate forms;
2. add explicit causal report generation from the unified shell;
3. expand benchmark-world QA across randomized, AIPW, and DiD;
4. deepen Decision Valuation checks for causal applicability and uncertainty;
5. then reassess whether Regression Discontinuity is the next highest-value estimator.
