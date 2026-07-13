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
