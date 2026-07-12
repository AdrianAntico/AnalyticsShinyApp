# Workflow Architecture

## Purpose

Workflow UX v1 organizes the existing Analytics Shiny App modules into a flexible analytical lifecycle:

Explore Data (EDA) -> Model Readiness / Target Analysis -> Feature Engineering / Model Preparation -> CatBoost Builder -> Model Assessment -> Model Insights -> SHAP Insights -> Report / Export

The Workflow page is a launchpad, not a wizard. It does not run modules automatically, force a sequence, or create a second execution system.

The page should use user-facing lifecycle language. Technical ids such as `eda`, `llm_docx`, `not_created`, and `workspace_ready` may remain in code and persisted metadata, but UI summaries, badges, and callouts should translate them into readable labels.

## Lifecycle Stages

| order | stage_id | label | status | module/page | purpose |
| --- | --- | --- | --- | --- | --- |
| 1 | `eda` | Explore Data | implemented | `autoquant_eda` | Understand data structure, distributions, correlations, and trends. EDA remains the technical context. |
| 2 | `model_readiness` | Model Readiness | implemented | `autoquant_model_readiness` | Target diagnostics, leakage/collider risk, drift, class balance, and modeling recommendations. |
| 3 | `feature_engineering_model_prep` | Feature Engineering / Model Preparation | implemented | `feature_engineering_model_prep` | Prepare deterministic modeling data with visible transformations, lineage, and reusable prepared-data artifacts. |
| 4 | `catboost_builder` | CatBoost Builder | experimental | `autoquant_catboost_builder` | Train and score CatBoost regression or binary classification models. |
| 5 | `model_assessment` | Model Assessment | experimental | post-model evaluation only | Evaluate trained/scored regression model performance through the current GenAI temporary result slice; broader UI/report integration remains future work. |
| 6 | `model_insights` | Model Insights | implemented | `autoquant_regression_model_insights`, `autoquant_binary_model_insights` | Understand model behavior, diagnostics, and feature effects. |
| 7 | `shap_insights` | SHAP Insights | implemented | `autoquant_regression_shap_analysis`, `autoquant_binary_shap_analysis` | Understand prediction-surface behavior using precomputed SHAP columns. |
| 8 | `report_export` | Report / Export | implemented | Layouts and Export pages | Compose, export, and share artifacts. |

## Terminology Rule

Model Readiness is pre-model. In the current app it maps directly to the Target Analysis / readiness adapter, `autoquant_model_readiness`.

Model Assessment is post-model. It is reserved for evaluation of an already trained/scored model and must not be used as the user-facing label for target/readiness diagnostics. The current `model_assessment` registry entry has an experimental GenAI-only regression scored-output slice. The broader human-facing post-model evaluator remains future work. The legacy `autoquant_model_assessment` id is compatibility only and aliases to `autoquant_model_readiness`.

## Module Actions

Workflow stage buttons deep-link to the existing Analysis Modules page when a stage maps to implemented module ids. The Workflow page does not duplicate module runner logic. Analysis Modules remains the owner of:

- module-specific controls
- validation
- execution
- artifact normalization
- report plan creation
- CatBoost downstream handoff actions

## Feature Engineering / Model Preparation

Feature Engineering / Model Preparation is a native deterministic app module. It does not mutate the active dataset. It creates standard project artifacts that describe the prepared data and every visible transformation:

- prepared dataset table artifact
- transformation sequence table
- before/after schema summary
- narrative summary

Supported transformations are intentionally conservative: column selection/exclusion, missing-value handling, constant-column detection, near-zero variance detection, duplicate-column detection, basic date feature extraction, categorical factor conversion, and optional train/validation split creation.

Rodeo remains the preferred long-term owner for advanced deterministic reusable transformations and richer model-prep partitioning. The current app-native module is a conservative workflow baseline, not a replacement for Rodeo. The detailed capability audit and integration plan are documented in `docs/rodeo_feature_engineering_integration_plan.md`.

Artifacts created from a Code Runner request tagged with `workflow_stage = "feature_engineering_model_prep"` are counted under the same Workflow stage. The producing surface remains Code Runner; the workflow stage supplies lifecycle placement.

Prepared dataset artifacts can be explicitly activated from the Analysis Modules run status area. Activation makes the prepared table the active modeling dataset for downstream modules such as CatBoost Builder while preserving the original source dataset as the preparation input in lineage metadata. This is a user-triggered handoff, not silent dataset replacement.

## Custom Code Hooks

Every workflow stage can draft custom code through the existing Code Runner architecture:

- pre-stage code
- post-stage code
- standalone exploratory code

Hooks create draft Code Runner requests only. They must include:

- `custom_code_hook = TRUE`
- `workflow_stage`
- `hook_timing`
- `source = "manual"`
- `auto_run = FALSE`

Hooks never auto-run and never bypass `local_trusted` controls.

## Workflow State Summary

`workflow_state_summary()` summarizes existing state rather than creating new state:

- artifact counts by workflow stage
- report plan counts by workflow stage
- latest custom code hook status
- custom code hook draft/history counts
- CatBoost handoff availability when detectable

The Artifact Library remains the inventory. Report plans remain the curated report selection. Workflow is only an orientation and launch surface.

Workflow summaries should surface the next useful step near the status readout so users do not have to infer what to do from a table alone.

## Integrated Analyst Flow

Phase 20 tightens the analyst-facing continuity between existing modules without changing the execution architecture.

Expected transitions:

1. Import Data
2. Explore Data
3. Model Readiness
4. Feature Engineering / Model Preparation
5. CatBoost Builder
6. Model Assessment
7. Model Insights
8. SHAP Insights
9. Artifact Studio
10. Layout / Export
11. Findings, improvement items, and remediation plans

Analysis Modules now shows a visible dataset context panel before module-specific controls. The panel summarizes detected target, prediction, date, group, row count, and column count. These values are used only as visible defaults. Users can override them before running a module.

Context-preservation rules:

- Target, prediction, date, group, feature, and SHAP-column candidates are inferred from the loaded dataset using deterministic column-name rules.
- Inferred context pre-populates module controls where the destination module expects the same analytical role.
- The app does not silently execute downstream modules.
- After a successful module run, the module status area shows the next natural analytical action.
- Failed runs recommend resolving the failure before continuing.
- Feature Preparation exposes an explicit prepared-dataset activation action before CatBoost.
- CatBoost scored-output handoff remains the explicit bridge from training to Model Assessment, Model Insights, and SHAP Insights.
- Prepared datasets are preserved as artifacts with lineage. They replace the active modeling dataset only when the user chooses the explicit downstream consumption path.

This preserves the existing architecture while reducing repeated user setup and making the analytical path easier to follow.

## Governed Feature Experiment Flow

Phase 26 adds a bounded intelligent feature experiment path after model evidence exists:

1. Review model evidence.
2. Generate a small ranked set of feature proposals from bounded evidence context.
3. Review, approve, reject, or retain unsupported recommendations.
4. Execute approved supported proposals through Rodeo.
5. Review the challenger prepared dataset artifact.
6. Run a frozen-baseline CatBoost challenger.
7. Compare baseline and challenger deterministically.
8. Interpret the outcome.
9. Explicitly adopt, reject, defer, or retain inconclusive evidence.
10. Continue to insights, SHAP, report, or another governed investigation.

The app does not silently execute downstream work. It does not automatically activate challenger data or adopt challenger models. A feature experiment result is evidence until the user explicitly decides what to do with it.

Phase 27 hardens the repeated-use path:

- prior feature experiment outcomes are included in future bounded evidence context
- duplicate Rodeo executions for equivalent successful proposals are prevented
- duplicate challenger adoptions are prevented
- proposal, execution, experiment, and adoption history is visible in the Project workspace
- reconciliation issues produce analyst-facing recovery recommendations

This makes the loop safer for analysts and future agents that repeatedly inspect, resume, or replay project state.

## Agent-Led Analytical Improvement Campaign

Phase 28 added a bounded campaign coordinator above the feature experiment loop:

1. Build bounded evidence context.
2. Discover and rank opportunities.
3. Create a campaign plan.
4. Pause for proposal approval.
5. Execute approved deterministic feature experiment actions.
6. Reuse prior proposal, execution, experiment, and adoption memory.
7. Produce campaign synthesis and next-action guidance.

The campaign does not introduce AutoML or autonomous adoption. It sequences existing operators and stops at approval, missing-baseline, blocked-execution, or adoption-decision gates.

Campaign state is stored in project state, surfaced through Mission Control, and validated by deterministic QA.

Phase 29 extends campaigns from one bounded opportunity into an adaptive sequence:

- only one opportunity executes at a time
- completed opportunities update compact campaign memory
- accepted, rejected, failed, superseded, and completed outcomes influence remaining rankings
- dependent opportunities remain blocked until prerequisites are completed
- repeated execute calls cannot pass through approval, baseline, adoption, or blocked gates
- campaign synthesis includes remaining opportunities, timeline, lineage, and supporting evidence references

This keeps campaigns useful as an analyst-led investigation loop without creating a generic workflow engine.

Phase 30 adds deterministic evidence sufficiency to the same campaign path:

- campaigns assess whether evidence is insufficient, preliminary, reasonable, or strong
- insufficient evidence blocks opportunity discovery and tells the analyst what is missing
- preliminary evidence can still rank bounded opportunities but remains explicit about uncertainty and likely baseline pauses
- Mission Control surfaces campaign evidence readiness alongside remaining opportunity progress

This lets campaigns stop because the evidence is weak, not merely because execution failed.

Phase 31 adds deterministic campaign learning quality:

- every completed opportunity records both model outcome and learning outcome
- rejected challenger experiments can still reduce uncertainty by retiring weak hypotheses
- campaign memory distinguishes facts learned, evidence collected, supported hypotheses, rejected hypotheses, and uncertain hypotheses
- repeated low-learning opportunities are deprioritized
- synthesis explains what was learned, what remains uncertain, and what new questions emerged
- Mission Control surfaces campaign learning progress through the existing campaign status tile

This makes campaigns more like analytical investigations than experiment queues.

Phase 32 adds governed campaign closure and knowledge promotion:

- campaigns compute deterministic closure recommendations
- campaign confidence explains evidence sufficiency, uncertainty reduction, unresolved questions, failures, and remaining opportunities
- reusable knowledge is promoted only when supported by enough campaign evidence
- weak or inconclusive findings remain historical campaign evidence rather than assumed truth
- reopening guidance records concrete triggers such as new data, new model, new evidence, new operator capability, or significant regression
- future campaigns can consume promoted guidance without being forced to obey it

This completes the campaign lifecycle: evidence -> investigation -> learning -> knowledge -> closure.

## Non-Goals

- no rigid wizard
- no DAG builder
- no automatic downstream module execution
- no second code execution system
- no new analytics
- no advanced automated feature engineering
- no feature store
- no module-specific export systems
