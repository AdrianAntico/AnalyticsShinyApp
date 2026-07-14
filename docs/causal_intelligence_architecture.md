# Causal Intelligence Architecture

Causal Intelligence is the planning layer that sits after authored business intent and before any causal estimation.

Phase 1 implements causal question and identification planning only. It does not estimate treatment effects, fit causal models, discover DAGs, or convert predictive artifacts into causal claims.

## Workflow Position

```text
Business intent
-> Authored decision context
-> Lever / intervention
-> Outcome
-> Causal question
-> Estimand
-> Question-relative variable roles
-> Causal graph assumptions
-> Identification planning
-> Adjustment guidance
-> Design eligibility
-> Causal planning artifact
```

The app owns authoring, project state, UI, artifact registration, collector integration, Mission Control visibility, and bounded GenAI context. AutoQuant owns the causal planning contracts and deterministic diagnostics.

## User-Facing Workbench

The Causal Intelligence page provides:

- causal question authoring,
- estimand selection,
- intervention and comparison definition,
- question-relative causal variable roles,
- directed relationship assumptions,
- identification assessment,
- graph diagnostics,
- adjustment guidance,
- design eligibility,
- investigation-plan output,
- planning artifact registration.

The page is intentionally bounded. It is not a DAG editor, causal effect estimator, or AutoML interface.

## Core Distinctions

### Predictive vs Causal

Predictive importance can motivate a causal question, but it does not answer one. The workbench therefore asks users to explicitly author exposure, outcome, intervention, comparison, timing, and assumptions.

### Global Semantics vs Question-Relative Roles

Variable semantics describe durable business and analytical meaning. Causal roles are relative to a specific question. The same variable may be a predictor in one analysis, an exposure in one causal question, a confounder candidate in another, and a mediator candidate in a third.

### Estimand Before Estimator

The estimand defines the target effect before any computational method is considered.

### Identification Before Computation

Graph diagnostics, adjustment guidance, and design eligibility are planning outputs. They determine what evidence is still needed before an effect estimate would be meaningful.

## Project Integration

Causal Intelligence state is persisted in saved project state under `causal_intelligence_state`.

Mission Control receives a compact causal summary:

- questions,
- roles,
- relationships,
- assessment status,
- identification status,
- registered artifacts.

The GenAI bounded context receives only summary counts/statuses and campaign seed types by default. Full graphs, roles, assumptions, and raw data are intentionally omitted unless a future explicit context strategy asks for them.

## Artifact Contract

Registered causal artifacts are canonical project artifacts with:

- `artifact_type = "table"`,
- `source_module = "causal_intelligence"`,
- `analytical_intent = "Causal Planning"`,
- `no_effect_estimated = TRUE`,
- prohibited claims,
- graph diagnostics,
- adjustment guidance,
- identification status,
- design eligibility.

The Project Artifact Collector can preserve these artifacts, but the collector does not interpret or estimate causal effects.

## Known Limitations

- No causal estimator is implemented.
- No automatic DAG discovery is implemented.
- No graph drawing canvas is implemented.
- Adjustment guidance is deterministic planning guidance, not a complete adjustment-set optimizer.
- Design eligibility is advisory and evidence-driven; it does not create an estimator.
- The app degrades gracefully when the updated AutoQuant causal API has not been loaded or installed.

## Future Phases

Likely future phases include:

- richer graph visualization,
- explicit evidence-to-edge provenance,
- adjustment-set enumeration,
- overlap and positivity diagnostics,
- experimental-design recommendation,
- estimator eligibility checks,
- causal estimator execution under governed action controls,
- decision outcome learning tied back to causal assumptions.

## Phase 2: Governed Experiment Design

Phase 2 extends the workbench from identification planning into governed experiment-design planning. The app still does not execute treatments or estimate causal effects.

The user-facing flow is:

```text
Causal question
-> Experiment question
-> Design specification
-> Governed experiment plan
-> Project artifact registration
-> Future completed-experiment analysis
```

The experiment-design state is persisted under `causal_experiment_state`. Material edits to the experiment question or design specification mark the generated plan stale until regenerated.

Phase 2 records:

- experiment question and hypothesis,
- treatment and comparison,
- assignment population,
- primary outcome and guardrails,
- design type,
- assignment unit,
- treatment delivery unit,
- analysis unit,
- cluster/block/stratification choices,
- deterministic assignment proposal,
- balance diagnostics,
- power and timing assumptions,
- measurement plan,
- validity threats,
- interference/spillover plan,
- authority and coverage gates,
- information-value assessment.

Mission Control warns when a plan is stale, approval is required, or a generated experiment artifact has not been registered. GenAI receives bounded summary context only and cannot approve or execute an experiment.

The boundary remains explicit:

- no treatment execution,
- no exposure delivery,
- no completed-experiment analysis,
- no effect estimation,
- no autonomous approval.

## Phase 3: Completed Experiment Evidence

Phase 3 extends the workbench from governed experiment design into completed or in-progress experiment evidence ingestion. The app still does not estimate causal effects.

The user-facing flow is:

```text
Governed experiment plan
-> Completed experiment record
-> Evidence column mappings
-> Assignment / delivery / exposure / outcome ingestion
-> Execution reconciliation
-> Estimand preservation
-> Analysis-readiness classification
-> Project artifact registration
-> Future ITT estimator if ready
```

The completed-experiment state is persisted under `causal_completed_experiment_state`. Material edits to the completed record or evidence mappings mark readiness stale until reassessed.

Phase 3 records:

- completed or in-progress experiment metadata,
- plan, causal question, decision context, and estimand linkage,
- original assignment evidence,
- realized assignment evidence,
- treatment delivery evidence,
- exposure evidence,
- treatment-received / compliance evidence,
- primary outcome evidence,
- guardrail evidence,
- exclusions and post-assignment exclusion risks,
- missingness and attrition diagnostics,
- treatment fidelity diagnostics,
- interference/spillover measurement status,
- estimand-preservation status,
- analysis-readiness state,
- planned-analysis handoff record.

Mission Control warns when completed-experiment readiness is stale, original assignment is missing, outcome evidence is missing, guardrails require review, estimand blockers exist, or a completed-readiness artifact has not been registered. GenAI receives bounded summary context only: readiness state, assignment/outcome availability, guardrail status, campaign seed types, and prohibited claims.

The boundary remains explicit:

- no causal effect estimation,
- no hypothesis testing,
- no outcome imputation,
- no treatment redefinition from exposure or treatment received,
- no silent post-assignment exclusion,
- no autonomous analysis approval.

## Phase 4: Randomized ITT Estimation

Phase 4 adds the first governed causal estimator to the workbench. It supports randomized intent-to-treat estimation only, and only after completed-experiment readiness is current and ITT-compatible.

The user-facing flow is:

```text
Completed-experiment readiness
-> Frozen randomized ITT specification
-> Readiness gate
-> Randomized analysis population
-> Primary unadjusted ITT estimate
-> Optional approved pre-treatment precision adjustment
-> Sensitivity / missingness / guardrail / materiality evidence
-> Human review
-> Project artifact registration
-> Decision evidence
```

The randomized ITT state is persisted under `causal_itt_state`. The state stores estimator specs, run results, review status, registered effect artifacts, and event history. It does not store full outcome tables.

Phase 4 records:

- active completed experiment linkage,
- treatment and comparison arm labels,
- primary outcome and outcome type,
- approved baseline covariates,
- optional cluster variable,
- uncertainty method,
- minimum meaningful effect,
- readiness gate result,
- primary estimate and uncertainty interval,
- adjusted precision estimate when available,
- missingness sensitivity,
- guardrail evidence,
- materiality state,
- permitted and prohibited claims,
- review status,
- campaign seed suggestions.

Mission Control warns when an ITT spec has not been run, the readiness gate blocks estimation, effect evidence requires review, an effect artifact has not been registered, or materiality suggests possible harm.

GenAI receives bounded summary context only: status, estimate, confidence interval, materiality state, review status, artifact count, campaign seed types, and prohibited claims. Assignment logs, source outcomes, and full source tables are intentionally omitted by default.

The boundary remains explicit:

- randomized ITT only,
- no treatment-on-treated or CACE/TOT estimation,
- no observational estimator,
- no propensity score or matching estimator,
- no instrumental-variable estimator,
- no difference-in-differences,
- no synthetic control,
- no mediation,
- no causal forests,
- no adaptive experiments,
- no optimization,
- no autonomous rollout or decision execution.

## Phase 5: Randomized Analysis Depth and Causal Reporting

Phase 5 deepens randomized causal evidence without adding observational estimators or autonomous decisioning. The app continues to use `causal_itt_state`, but ITT run records may now include:

- `design_depth`;
- `causal_report`;
- method eligibility;
- CUPED variance-reduction evidence;
- block/stratum or cluster/geography diagnostics;
- carryover evidence for temporal designs;
- randomization-inference evidence when eligible;
- multiplicity records;
- guardrail decision state;
- materiality regions;
- robustness matrix rows;
- report-section availability.

The user-facing workbench adds governed design controls to the existing Randomized ITT Estimation card:

- randomized design type;
- eligible analysis modes;
- block and stratum fields;
- period field;
- pre-period fields;
- factorial terms;
- maximum acceptable harm.

Only the provider package owns the statistical contract. The app does not implement separate estimators. It calls AutoQuant's randomized design-analysis contract when available and degrades gracefully when an older installed AutoQuant package is active.

Mission Control surfaces:

- unavailable randomized design-depth evidence after an ITT result;
- available causal-effect report contracts;
- existing review, artifact registration, blocked readiness, and possible harm signals.

Bounded GenAI context includes design-depth status, report status, and robustness row counts. It does not include raw assignment logs, full outcome data, or source tables by default. GenAI may explain design-specific limitations and robustness, but it may not select the most favorable analysis, alter the specification, suppress guardrails, or approve evidence.

Cleanup classification:

- The remaining aggregate app warning is `module_terminology_consistency`.
- It is a known terminology compatibility warning preserving historical `autoquant_model_assessment` references while the canonical pre-model module remains `autoquant_model_readiness`.
- It is not caused by causal Phase 4 or Phase 5.

Build artifact policy:

- AutoQuant release tarballs are treated as tracked repository content when already present.
- Validation builds should be written to isolated temporary build directories rather than regenerating tracked tarballs in the source tree.
