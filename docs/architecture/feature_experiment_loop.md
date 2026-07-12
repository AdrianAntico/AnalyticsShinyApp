# Governed Feature Experiment Loop

Phase 26 adds the first bounded end-to-end intelligent feature experiment loop.

The loop is intentionally narrow:

```text
bounded evidence context
-> structured feature proposal
-> explicit approval
-> Rodeo transformation spec
-> deterministic fit/apply
-> challenger prepared dataset artifact
-> frozen CatBoost challenger
-> deterministic comparison
-> outcome interpretation
-> explicit adoption or retained negative evidence
```

It does not add AutoML, arbitrary feature search, arbitrary R execution, automatic dataset activation, or automatic model adoption.

## Ownership

AnalyticsShinyApp owns orchestration, proposal contracts, review state, artifacts, lineage, comparison, adoption, and reconciliation.

Rodeo owns transformation specification validation, fit/apply behavior, learned state, serialization, and schema diagnostics.

AutoQuant owns CatBoost model fitting and model artifacts.

GenAI may propose and interpret, but it does not execute transformations, bypass approval, mutate datasets, or adopt challengers.

## Evidence Context

`feature_experiment_evidence_context()` builds a bounded feature-reasoning context. It includes:

- project id
- active modeling context
- target and feature manifest
- dataset schema summary
- artifact references
- baseline model metadata when available
- prior feature experiment outcomes when feature experiment state is supplied

It does not dump raw rows.

## Proposal Contract

`feature_proposal_v1` records:

- proposal identity and project identity
- source model and source dataset references
- supporting evidence ids
- diagnosed problem
- hypothesis
- transformation type
- source and output columns
- parameters
- risks
- confidence
- Rodeo support status
- approval tier
- experiment pattern
- acceptance, rejection, and confirmation criteria
- proposal status

Supported executable transformation types are limited to the current Rodeo vNext contract:

- `missing_impute`
- `constant_remove`
- `near_zero_variance_remove`
- `factor_levels`
- `date_features`

Unsupported ideas are retained as recommendations but are not executable.

## Governance

Execution requires an approved supported proposal. Unapproved proposals fail before Rodeo translation. Blocked and unsupported proposals cannot execute.

The implementation uses existing service-result and audit-compatible objects rather than introducing a new governance framework.

## Rodeo Execution

`execute_feature_proposal_with_rodeo()`:

1. prevents duplicate execution when an equivalent successful proposal execution already exists
2. validates approval
3. converts the proposal to a Rodeo transformation spec
4. validates source columns and output collisions
5. fits the transformation
6. applies the fitted state
7. serializes the fitted transformation
8. creates proposal, spec, challenger dataset, schema comparison, and diagnostics artifacts
9. verifies the source input was not mutated

Only the challenger dataset artifact is marked as a prepared dataset candidate.

## Challenger Experiment

`feature_experiment_v1` records one baseline-versus-one-challenger experiment.

The frozen baseline preserves:

- target
- feature manifest
- split method / split identity
- seed
- CatBoost parameters
- evaluation metrics

The challenger varies only the transformed dataset and resulting challenger feature manifest.

## Comparison and Interpretation

`feature_comparison_v1` compares baseline and challenger metric tables. When scored output includes target and prediction columns, RMSE and MAE are computed from scored data. Otherwise the comparison records explicit fallback diagnostics.

The deterministic decision is one of:

- `accept`
- `reject`
- `inconclusive`

`interpret_feature_experiment_outcome()` summarizes the deterministic result and surfaces conflicts if a GenAI recommendation disagrees with the deterministic rule.

## Adoption

Adoption is explicit. A favorable comparison is evidence, not authority.

`feature_adoption_v1` records:

- adopted experiment
- challenger dataset artifact
- challenger feature manifest
- prior baseline result
- explicit approval
- adoption status

Rejected, failed, blocked, and inconclusive outcomes remain preserved as evidence.

Duplicate adoption is prevented. If an experiment has already been adopted, the adoption helper returns the existing adoption record with a duplicate-prevention warning instead of creating a second adoption event.

## Reconciliation

`reconcile_feature_experiment_loop()` checks for bounded operational drift:

- proposal without evidence
- approved proposal without execution
- execution without prepared artifact
- experiment without lineage
- accepted experiment without adoption state
- cross-project linkage

It does not create a new ledger.

`feature_experiment_history_table()` provides a compact historical inspection table across proposals, executions, experiments, and adoptions. `feature_experiment_recovery_summary()` turns reconciliation issues into analyst-facing recovery recommendations.

The Project workspace exposes this state in a Feature Experiments panel so analysts and future agents can inspect proposal history, challenger outcomes, explicit adoptions, and recovery needs without searching the raw project state.

## QA

`qa_feature_experiment_loop()` verifies:

- bounded context
- prior feature outcomes in context
- proposal generation
- schema validation
- unsupported classification
- approval enforcement
- rejection preservation
- Rodeo fit/apply
- duplicate execution prevention
- no source mutation
- prepared artifact creation
- serialization/reload
- CatBoost baseline/challenger path when AutoQuant is available
- deterministic comparison
- outcome interpretation
- explicit adoption behavior
- duplicate adoption prevention
- history table generation
- recovery summary generation
- reconciliation

## Known Limitations

- The first implementation supports one-challenger experiments only.
- It does not run exhaustive feature subset search.
- It does not execute arbitrary expressions.
- It does not automatically activate challenger datasets.
- It does not automatically adopt challenger models.
- Improvement Ledger integration is represented through references and reconciliation; full item lifecycle advancement remains a later hardening step.
- Mission Control and Project workspace expose status, history, and recovery signals, but a rich interactive proposal workbench is not yet implemented.
