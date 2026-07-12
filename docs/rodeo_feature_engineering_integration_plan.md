# Rodeo Feature Engineering Capability Audit and Integration Plan

## Executive Summary

Rodeo is already a broad `data.table`-oriented feature engineering package with both legacy task-specific functions and a newer vNext fit/transform surface. AnalyticsShinyApp now has a conservative Feature Engineering / Model Preparation stage that creates visible prepared-data artifacts, lineage, and project collector output without mutating the active dataset.

The two systems overlap, but they should not collapse into one another.

Rodeo should own deterministic reusable transformations and model-prep execution primitives. AnalyticsShinyApp should own workflow, UI, project state, artifact contracts, lineage, governance, collector integration, and user experience.

Rodeo is not yet ready to become the entire application's feature engineering engine. It is ready to become a selective future execution backend for advanced deterministic transformations and robust partitioning once an app-side adapter contract and integration QA exist.

The recommended near-term decision is:

- keep the existing app-native Feature Engineering / Model Preparation module as the conservative production workflow;
- do not duplicate Rodeo's advanced transformation families inside AnalyticsShinyApp;
- integrate Rodeo vNext later through a narrow adapter, beginning with partitioning/model-prep and then advanced feature transformations;
- avoid direct use of legacy Rodeo APIs from the app unless they are wrapped by a scoring-safe vNext contract.

## Audit Scope

This audit reviewed the Rodeo repository at `C:/Users/Bizon/Documents/GitHub/Rodeo`, including:

- `README.md`
- `DESCRIPTION`
- `NAMESPACE`
- `R/FeatureEngineering_NumericTypes.R`
- `R/FeatureEngineering_CharacterTypes.R`
- `R/FeatureEngineering_CalendarTypes.R`
- `R/FeatureEngineering_CrossRowOperations.R`
- `R/FeatureEngineering_DataSets.R`
- `R/FeatureEngineering_ModelBased.R`
- `R/FeatureEngineering_vNext.R`
- `R/ModelPrep_vNext.R`
- `docs/rodeo_feature_engineering_inventory.md`
- `docs/rodeo_model_prep_inventory.md`
- `docs/rodeo_vnext_architecture.md`

The audit also checked the current R environment. Rodeo is installed under R 4.5.2 and the exported Rodeo vNext QA helpers pass in that environment:

- `qa_rodeo_vnext()`
- `qa_rodeo_vnext_model_prep()`

## Current AnalyticsShinyApp Feature Preparation Scope

AnalyticsShinyApp's current native module is `feature_engineering_model_prep`. It is intentionally conservative. It supports:

- column selection;
- column exclusion;
- missing-value handling through `none`, `median_mode`, `zero_unknown`, and `drop_rows`;
- constant-column detection/removal;
- near-zero variance detection/removal;
- duplicate-column detection/removal;
- basic date feature extraction: year, month, day-of-week;
- categorical conversion to factors;
- optional deterministic train/validation split;
- before/after schema summaries;
- transformation step lineage;
- standard artifacts with `aq_prep_` artifact ids;
- a report plan for preparation review;
- reproducible repeated execution with the same configuration.

The module does not silently replace the active dataset. Prepared datasets are project artifacts.

## Rodeo Capability Matrix

| Family | Public API | Inputs | Outputs | Determinism | Fit/apply behavior | Serialization support | Existing QA | Documentation status | Assessment |
|---|---|---|---|---|---|---|---|---|---|
| Numeric transforms, legacy | `Apply_Asin`, `Apply_Asinh`, `Apply_BoxCox`, `Apply_Log`, `Apply_LogPlus1`, `Apply_Logit`, `Apply_Sqrt`, `Apply_YeoJohnson`, inverse functions, `Estimate_BoxCox_Lambda`, `Estimate_YeoJohnson_Lambda`, `Standardize`, `StandardizeScoring`, `PercRank`, `PercRankScoring`, `AutoTransformationCreate`, `AutoTransformationScore` | `data.table`/vectors, selected columns, transform parameters | transformed columns/data, scoring tables in some cases | Generally deterministic, parameter dependent | Mixed; some explicit scoring variants, some legacy functions mutate supplied tables | Partial through scoring tables/files in legacy patterns | Legacy examples plus vNext QA for subset | README and inventory docs | Strong transformation inventory, but direct app use should wait for vNext/adapters because mutation and scoring semantics vary. |
| Numeric transforms, vNext | `rodeo_feature_plan`, `rodeo_fit_feature_plan`, `rodeo_transform_feature_plan`, `rodeo_fit_transform_feature_plan` | data plus plan numeric columns/transforms | engineered data, fitted plan, manifest, diagnostics, warnings | Deterministic for fixed data/plan | Explicit fit/transform; fitted plan stores means, standard deviations, winsor bounds | Fitted plan is a structured R object | `qa_rodeo_vnext_numeric`, `qa_rodeo_vnext_fit_transform` pass | vNext architecture doc and README | Good candidate for future app backend for scaling, centering, `log1p`, `sqrt`, and winsorization. |
| Categorical/text-like, legacy | `DummifyDT`, `DummyVariables`, `CategoricalEncoding`, `EncodeCharacterVariables`, `Encoding` | categorical columns, levels/encoding options | dummy/encoded columns, optional factor level metadata | Deterministic with fixed levels/settings | Mixed; `DummifyDT` has imported factor-level support | Partial via saved factor levels/metadata | Legacy examples plus vNext QA for one-hot/rare/unseen | README and inventory docs | Useful but direct app use is risky without an adapter because target-aware encodings need leakage controls. |
| Categorical, vNext | `rodeo_feature_plan` categorical family | data plus categorical columns/top-N/rare/unseen settings | one-hot/top-N features, rare and unseen handling, manifest | Deterministic | Explicit fit/transform; fitted plan stores levels and generated dummy names | Fitted plan structured object | `qa_rodeo_vnext_categorical` passes | vNext architecture doc and README | Good future owner for rare-level handling and scoring-safe categorical expansion. |
| Calendar/date, legacy | `CreateCalendarVariables`, `CreateHolidayVariables`, `CalendarVariables`, `HolidayVariables`, `TimeSeriesFeatures`, `TimeSeriesFill`, `TimeSeriesFillRoll`, `LB`, `weekdays_in_month` | date columns and calendar/holiday settings | calendar, holiday, filling, lookback features | Deterministic with fixed calendars/settings | Calendar unit features are generally scoring-safe; holiday/window features need saved settings | Partial/legacy dependent | Legacy examples plus vNext calendar QA | README and inventory docs | Richer than current app date extraction, but holiday/time-series wrappers need explicit contracts before app use. |
| Calendar, vNext | `rodeo_feature_plan` calendar family | date columns and selected calendar features | year, month, day, weekday, week, quarter, weekend | Deterministic | Explicit fit/transform | Fitted plan structured object | `qa_rodeo_vnext_calendar` passes | vNext architecture doc and README | Good future replacement for app's basic date extraction once adapter exists. |
| Text, vNext | `rodeo_feature_plan` text family | text columns and feature flags | character count, word count, digit count, punctuation count, upper ratio, blank flag | Deterministic | Explicit fit/transform | Fitted plan structured object | `qa_rodeo_vnext_text` passes | vNext architecture doc | Belongs in Rodeo. App should expose only when needed by modeling workflows. |
| Missingness indicators, vNext | `rodeo_feature_plan` missingness family | selected columns | binary missingness flags | Deterministic | Explicit fit/transform | Fitted plan structured object | Covered by aggregate vNext QA | vNext architecture doc | Belongs in Rodeo. App currently owns simple imputation/drop-row handling, not indicator generation. |
| Interactions, legacy | `AutoInteraction`, `Interact`, `CreateInteractions`, `MEOW` | numeric/categorical columns and interaction settings | generated interaction features | Deterministic, but feature count can explode | Mixed; cardinality and cap behavior matter | Partial/legacy dependent | Legacy examples plus vNext interaction QA | README and inventory docs | Belongs in Rodeo, not app. App should avoid implementing interaction feature logic directly. |
| Interactions, vNext | `rodeo_feature_plan` interactions family | numeric pairs, categorical-numeric specs, categorical pairs, caps | interaction columns and manifest | Deterministic | Explicit fit/transform with capped features | Fitted plan structured object | `qa_rodeo_vnext_interactions` passes | vNext architecture doc | Good future backend for controlled interaction features. |
| Cross-row operations | `AutoDiffLagN`, `DiffDT`, `DiffLagN`, `AutoLagRollMode`, `AutoLagRollStats`, `AutoLagRollStatsScoring` | data, grouping/sort/time windows, selected columns | lag, diff, rolling statistics, rolling modes | Deterministic if sort/group contracts are explicit | Some explicit scoring support exists; vNext wrappers deferred | Partial/legacy dependent | Legacy examples; no vNext cross-row QA observed | Inventory docs | Belongs in Rodeo, but not ready for app integration until vNext has explicit group/sort/leakage contracts. |
| Model prep, legacy | `AutoDataPartition`, `PartitionData`, `ModelDataPrep`, `DT_GDL_Feature_Engineering`, `Partial_DT_GDL_Feature_Engineering*` | data and model-prep arguments | partitioned/prepared data | Deterministic with fixed seed/settings | Mixed; legacy behavior should remain compatibility surface | Mixed | Legacy examples | README and model prep inventory | Do not call directly from the app unless wrapped behind vNext/adapters. |
| Model prep, vNext | `rodeo_partition_plan`, `rodeo_fit_partition_plan`, `rodeo_apply_partition_plan`, `rodeo_create_folds`, `generate_rodeo_model_prep_artifacts` | data plus partition plan, target/group/date/seed/fractions/k | prepared data with partition/fold columns, fitted plan, manifests, diagnostics, warnings | Deterministic with fixed seed | Explicit fit/apply; grouped/time/stratified behavior encoded in fitted plan | Fitted plan structured object | `qa_rodeo_vnext_model_prep`, `qa_generate_rodeo_model_prep_artifacts` pass | README and model prep inventory | Strongest first integration candidate. It is more capable than the app's current simple validation split. |
| Model-based features | H2O clustering, autoencoder, isolation forest, Word2Vec helpers | data and model settings | model-derived features | Model/training dependent | Requires leakage-safe redesign | Mixed | Legacy examples | Inventory says deferred | Out of scope for current app integration. Do not use as part of deterministic Phase 21 prep. |
| Rodeo artifact generators | `generate_rodeo_feature_engineering_artifacts`, `generate_rodeo_model_prep_artifacts` | data plus plan/fitted plan | app-agnostic `artifacts`, `metadata`, `warnings`, `diagnostics`, `value` | Deterministic if underlying plan deterministic | Uses vNext fit/transform or partition plan | Structured R lists | QA passes | vNext docs and README | Useful adapter input, but not a replacement for AnalyticsShinyApp's standard artifact model. |

## Gap Analysis Against AnalyticsShinyApp Requirements

| Requirement | AnalyticsShinyApp support | Rodeo support | Status | Recommended owner | Notes |
|---|---:|---:|---|---|---|
| Column selection | Yes | Partial through plan columns | Covered in app | AnalyticsShinyApp | This is UI/workflow intent, not a reusable transformation engine concern. |
| Column exclusion | Yes | Not primary vNext behavior | Covered in app | AnalyticsShinyApp | Keep app-side because it is tied to project and user workflow. |
| Missing-value handling | Yes: none, median/mode, zero/unknown, drop rows | Partial: vNext missingness indicators; legacy model prep may include broader handling | Partial overlap | Both | App owns conservative imputation/drop-row workflow now. Rodeo should own future fitted reusable imputation and indicators. |
| Constant-column removal | Yes | Not observed in vNext docs/API | App only | AnalyticsShinyApp for now | Could move to Rodeo later if implemented as a reusable scoring-safe plan step. |
| Near-zero variance removal | Yes | Not observed in vNext docs/API | App only | AnalyticsShinyApp for now | Diagnostic/removal is useful app prep behavior. Rodeo could own reusable selector plans later. |
| Duplicate-column removal | Yes | Not observed in vNext docs/API | App only | AnalyticsShinyApp for now | Keep app-side until a Rodeo selector/removal contract exists. |
| Date feature extraction | Basic year/month/day-of-week | vNext richer calendar units; legacy richer holiday/calendar functions | Overlap | Rodeo long-term; app short-term | Rodeo should own richer calendar feature generation. App's current basic extraction is acceptable as a conservative bridge. |
| Factor conversion | Yes | Categorical one-hot/top-N/rare/unseen; legacy encodings | Partial overlap | Both | App can own simple type coercion. Rodeo should own feature-producing encodings. |
| Train/validation preparation | Simple deterministic random validation split | vNext random, stratified, grouped, time partitions and folds | Rodeo stronger | Rodeo long-term | This is the clearest first migration candidate. |
| Schema preservation | Before/after schema artifacts | Manifests and diagnostics, but app-specific artifacts not native | Both | AnalyticsShinyApp | Rodeo returns facts; app turns them into durable project evidence. |
| Transformation lineage | Yes, app artifact lineage | Fitted plan/manifest/warnings/diagnostics | Both | AnalyticsShinyApp for project lineage; Rodeo for transform lineage | App should adapt Rodeo plan manifests into standard lineage artifacts. |
| Artifact generation | Standard `aq_prep_` artifacts and report plan | App-agnostic Rodeo artifact lists | Both | AnalyticsShinyApp | Rodeo should not know the Project Artifact Collector. |
| Deterministic execution | Yes | Yes for vNext with fixed plan/seed | Covered | Both | Contract tests should verify no source mutation and deterministic repeated output. |
| Reproducibility | Yes within app config | Yes via fitted plans/partition plans | Covered | Both | App must persist enough Rodeo plan metadata when integration arrives. |

## Future Capability Ownership

| Future capability | Recommended owner | Current evidence |
|---|---|---|
| Scaling and centering | Rodeo | Legacy `Standardize`/`StandardizeScoring`; vNext `standardize`. |
| Log transforms | Rodeo | Legacy `Apply_Log`, `Apply_LogPlus1`; vNext `log1p`. |
| Box-Cox / Yeo-Johnson | Rodeo | Legacy functions and estimators exist; vNext wrap-later. |
| Winsorization | Rodeo | vNext `winsorize` implemented. |
| Clipping | Rodeo | Natural extension of vNext numeric plan. |
| Missingness indicators | Rodeo | vNext missingness family implemented. |
| Fitted imputation | Rodeo eventually | App has simple imputation; Rodeo should own reusable train/scoring-safe imputation if formalized. |
| Rare-level handling | Rodeo | vNext categorical rare/unseen handling implemented. |
| Frequency/count encoding | Rodeo | Legacy categorical encodings exist; vNext extension candidate. |
| Target-aware encodings | Rodeo eventually, with app governance | Legacy encodings exist, but leakage-safe vNext design is required before app integration. |
| Cyclic date encoding | Rodeo | Natural vNext calendar extension. |
| Interaction features | Rodeo | Legacy and vNext interaction support. |
| Ratio features | Rodeo | Reusable deterministic transformation engine concern. |
| Polynomial features | Rodeo | Reusable deterministic transformation engine concern. |
| Group aggregations | Rodeo | Belongs with cross-row/grouped transformation contracts. |
| Rolling statistics | Rodeo | Legacy `AutoLagRollStats`; vNext deferred. |
| Lag features | Rodeo | Legacy lag/diff functions; vNext deferred until group/sort contracts. |
| UI controls | AnalyticsShinyApp | App owns analyst workflow and progressive disclosure. |
| Project artifacts and collector | AnalyticsShinyApp | App owns artifact model and collector. |
| Governance, approvals, audit | AnalyticsShinyApp | App owns project execution context. |
| User-facing lineage | AnalyticsShinyApp | App owns project memory and evidence trail. |

## Ownership Boundary

Rodeo owns:

- deterministic transformation execution;
- fit/apply transformation plans;
- reusable fitted transformation metadata;
- partition and fold assignment algorithms;
- transformation-family QA;
- performance-sensitive `data.table` implementation details;
- leakage-safe transformation contracts when target-aware features are added.

AnalyticsShinyApp owns:

- project workflow;
- module UI;
- stateful project context;
- artifact creation and normalization;
- collector append behavior;
- report plans;
- project-level lineage;
- governance and approval;
- user-facing diagnostics;
- cross-system QA;
- optional dependency handling;
- graceful failure behavior when Rodeo is unavailable.

Both own:

- deterministic reproducibility, but at different levels;
- diagnostics, with Rodeo producing execution diagnostics and the app translating them into project evidence;
- documentation, with Rodeo documenting transformation semantics and the app documenting workflow semantics.

Neither should own:

- speculative LLM-generated feature engineering without deterministic validation;
- hidden mutation of project datasets;
- direct training inside feature engineering;
- broad feature-store semantics;
- generic ETL workflow orchestration.

## Recommended Transformation Contract

If Rodeo becomes an execution backend, the app should call only public Rodeo APIs through a narrow adapter.

The app should send:

- source dataset;
- transformation specification;
- parameter values;
- selected role columns, such as target, date, group, id, and partition columns;
- execution metadata, such as seed and intended workflow stage;
- optional fitted plan for scoring/replay.

Rodeo should return:

- prepared dataset;
- fitted plan or partition plan;
- transformation manifest;
- before/after summaries where available;
- diagnostics;
- warnings;
- reproducibility metadata;
- any app-agnostic artifact payloads.

The app adapter should convert Rodeo output into:

- `service_result`;
- standard AnalyticsShinyApp artifacts;
- artifact quality metadata;
- table artifacts and sidecars where applicable;
- collector bundle entries;
- report plan entries;
- project lineage metadata;
- user-facing warning/failure diagnostics.

The adapter should not depend on Rodeo internal helper functions, undocumented list shapes beyond the documented public return contract, or legacy mutation side effects.

## LLM Readiness Assessment

Rodeo vNext is directionally compatible with future LLM-generated feature proposals because its plans are deterministic, parameterized, reproducible, and independently executable. However, LLM feature generation should not be enabled yet.

Required before LLM proposal execution:

- a strict schema for allowed transformation proposals;
- deterministic validation before execution;
- risk classification for transformations;
- explicit target-leakage checks;
- bounded feature-count/cardinality controls;
- fitted-plan persistence;
- source-data mutation protection;
- replay tests;
- clear user approval for higher-risk transformations;
- project audit ledger entries;
- app-side artifact and lineage conversion.

Rodeo vNext is best viewed as a future deterministic executor for validated proposals. It should not become a probabilistic planner.

## Migration Opportunities

| Area | Current duplication risk | Recommendation | Rationale |
|---|---|---|---|
| App basic date features vs Rodeo calendar vNext | Medium | Leave as-is short term; migrate to Rodeo when adapter exists | App implementation is small and conservative; Rodeo is richer long-term. |
| App simple validation split vs Rodeo partition plan | High | Migrate first when integration begins | Rodeo vNext is clearly better for random, stratified, grouped, time, and fold splits. |
| App missing imputation vs future Rodeo fitted imputation | Medium | Leave as-is; do not expand app imputation | Rodeo does not currently expose vNext imputation, but this belongs there long-term. |
| Constant/NZV/duplicate removal | Low | Keep app-side until Rodeo adds selector/removal plan family | These are preparation diagnostics tightly tied to user review. |
| Advanced numeric transforms | High if added to app | Do not add to app; use Rodeo vNext | Rodeo already owns this domain. |
| Rare-level/categorical expansion | High if added to app | Do not add to app; use Rodeo vNext | Rodeo already supports scoring-safe rare/unseen behavior. |
| Interactions | High if added to app | Do not add to app; use Rodeo vNext | Feature explosion controls belong in the execution engine. |
| Cross-row lag/rolling features | High future risk | Wait for Rodeo vNext group/sort contracts | Legacy exists, but app integration should require leakage-safe contracts. |
| Rodeo artifact generators vs app artifacts | Medium | Do not replace app artifacts; adapt Rodeo outputs | Rodeo artifact lists are app-agnostic; app collector contract is project-specific. |

## Recommended Integration Strategy

1. Keep Phase 21 as the current production baseline.

   The app-native module is small, deterministic, and directly integrated with artifacts, lineage, workflow, and QA. It satisfies the current conservative workflow requirement.

2. Define an optional Rodeo adapter only when feature scope exceeds the app baseline.

   The adapter should sit at the app/module boundary and convert app configs to Rodeo public plans. It should be optional and fail gracefully when Rodeo is unavailable.

3. Integrate Rodeo model-prep vNext first.

   Partitioning is the strongest first candidate because Rodeo already has a clear `rodeo_partition_plan` -> `rodeo_fit_partition_plan` -> `rodeo_apply_partition_plan` contract and QA for random, stratified, grouped, time, and fold assignments.

4. Integrate Rodeo feature-plan vNext second.

   Add advanced numeric, categorical, calendar, text, missingness-indicator, and interaction options only through Rodeo plans. Do not implement those transformation families directly in the app.

5. Treat Rodeo legacy APIs as compatibility baselines, not app integration points.

   Legacy functions are powerful but mixed on by-reference mutation and scoring semantics. They should be called by app code only through a scoring-safe Rodeo wrapper or app adapter that copies source data and normalizes outputs.

6. Keep artifact ownership in AnalyticsShinyApp.

   Rodeo can generate app-agnostic artifact payloads, but the app owns `create_artifact`, artifact quality policy, collector append, report plans, project storage, and UI.

## Suggested Migration Plan

### Phase A: No-Code Boundary Lock

- Keep the current module unchanged.
- Document that the native module is a conservative bridge, not a replacement for Rodeo.
- Prevent additional advanced transformations from being added directly to the app.

### Phase B: Contract Tests

Before using Rodeo from the app, add integration QA that verifies:

- Rodeo is optional;
- app startup succeeds without Rodeo;
- unavailable Rodeo returns a clear diagnostic;
- source data is not mutated;
- repeated execution is deterministic;
- warnings and diagnostics pass through to artifacts;
- Rodeo fitted plans are serializable enough for project save/load;
- app artifacts preserve lineage to the Rodeo plan.

### Phase C: Partition Adapter

- Map app split settings to `rodeo_partition_plan`.
- Convert `partition_manifest`, `fold_manifest`, `assignment_manifest`, diagnostics, and warnings into app artifacts.
- Keep app's simple split as fallback if Rodeo is unavailable.
- Add UI only for partition choices that are actually supported and tested.

### Phase D: Feature Plan Adapter

- Map selected app transformations to `rodeo_feature_plan`.
- Start with numeric transforms, categorical rare/unseen handling, calendar features, missingness indicators, and capped interactions.
- Do not expose legacy target-aware encodings until leakage-safe vNext contracts exist.

### Phase E: Prepared Dataset Consumption

- Add an explicit user action to use a prepared dataset artifact as the input for model training.
- Do not silently replace the active dataset.
- Record the selected prepared artifact in project lineage.

## Risks

- Legacy Rodeo functions often work by reference. Direct calls could mutate active project data unless wrapped carefully.
- Some legacy transformations have train/scoring behavior that is not uniform across families.
- Target-aware encodings carry leakage risk and require stronger contracts before use.
- Cross-row features require explicit group, sort, and time-window semantics to avoid leakage.
- Rodeo fitted plans need project save/load compatibility testing before app integration.
- Rodeo package availability must remain optional; app startup cannot require it.
- App and Rodeo documentation could drift if responsibilities are not kept explicit.
- The app could gradually duplicate Rodeo if advanced feature requests are handled quickly inside Shiny instead of routed to Rodeo.

## Technical Debt Discovered

- The app-native module now owns small preparation logic that partly overlaps with future Rodeo responsibilities. This is acceptable only if it remains conservative.
- There is no formal AnalyticsShinyApp-to-Rodeo adapter contract yet.
- There are no app-side contract tests for Rodeo output adaptation.
- Prepared datasets are artifacts but are not yet selectable as downstream model-training inputs.
- Rodeo vNext artifact payloads are structurally useful but not yet aligned to app artifact quality/table policies.
- Legacy Rodeo functions remain broader than vNext, but their mixed mutation/scoring behavior makes them unsuitable as direct app dependencies.

## QA Review

Rodeo currently provides exported QA helpers for the vNext surface:

- `qa_rodeo_vnext_numeric()`
- `qa_rodeo_vnext_categorical()`
- `qa_rodeo_vnext_calendar()`
- `qa_rodeo_vnext_text()`
- `qa_rodeo_vnext_interactions()`
- `qa_rodeo_vnext_fit_transform()`
- `qa_generate_rodeo_feature_engineering_artifacts()`
- `qa_rodeo_vnext()`
- `qa_rodeo_vnext_model_prep()`
- `qa_generate_rodeo_model_prep_artifacts()`

AnalyticsShinyApp currently provides `qa_feature_preparation_integration()` for the native module.

Recommended future app-side integration QA:

- `qa_rodeo_feature_adapter_optional_dependency()`
- `qa_rodeo_partition_adapter_contract()`
- `qa_rodeo_feature_plan_adapter_contract()`
- `qa_rodeo_prepared_artifact_lineage()`
- `qa_rodeo_no_source_mutation()`
- `qa_rodeo_project_save_load_replay()`
- `qa_rodeo_warning_diagnostics_passthrough()`

These should be added only when the adapter is implemented.

## Readiness Assessment

Rodeo is ready for selective integration planning.

Rodeo is not ready to replace the app-native Feature Engineering / Model Preparation module wholesale.

The most production-ready Rodeo integration target is vNext model prep partitioning. The next best target is vNext feature plans for advanced deterministic transformations. Legacy Rodeo APIs should remain out of direct app execution until wrapped behind scoring-safe vNext contracts or a narrow defensive adapter.

The current division of responsibilities is healthy:

```text
AnalyticsShinyApp
  owns workflow, UI, project state, artifacts, lineage, governance, collector

Rodeo
  owns deterministic reusable transformation and model-prep execution
```

The practical next step is not migration. It is boundary discipline: keep app-native preparation conservative, and route future advanced transformation work toward Rodeo vNext.
