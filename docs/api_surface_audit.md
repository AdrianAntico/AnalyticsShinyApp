# API Surface Audit

## Purpose

This is an aggressive pre-product API and product-surface audit across:

- AnalyticsShinyApp
- AutoQuant
- AutoPlots
- Rodeo
- PolarsFE
- Benchmarks

Current most important customer: Adrian.

Breaking changes are acceptable before monetizable product fit when they reduce public API complexity, align with artifact-first workflows, improve copy/paste usage, or remove legacy confusion.

## API Philosophy

Prefer:

- fewer public functions
- flat, explicit parameters
- one obvious path per task
- generator-first workflows
- examples users can copy, paste, and modify at work
- stable output contracts
- internal helper complexity hidden from users

Avoid:

- clever nested config objects unless needed
- too many tiny public helpers
- forcing users to learn package internals
- preserving old APIs solely because they exist
- exposing implementation details as user-facing choices

## Classification Legend

| classification | meaning |
| --- | --- |
| preferred path | the path future examples and app integrations should use |
| convenience wrapper | acceptable helper around a preferred path; must not own new behavior |
| keep internal | app/package helper that should remain undocumented and non-user-facing |
| exported accidentally | currently public but should likely be hidden or consolidated |
| legacy compatibility | useful during transition, but should not shape new work |
| deprecation candidate | should be retired after migration docs/examples exist |
| breaking-change candidate | worth changing before productization even if it breaks old code |
| needs copy/paste example | useful API whose docs are not yet work-ready |

## Highest-Priority Breaking Changes

| priority | repo | change | why now |
| --- | --- | --- | --- |
| P0 | AutoQuant | Split pre-model readiness from post-model assessment in names and examples. | `Model Assessment` must mean trained-model evaluation only. Pre-model work should become `Model Readiness`. |
| P0 | AutoQuant | Make `ModelInsightsReport()` legacy-only and remove it from modern examples. | Problem-specific renderers now exist and reduce confusion. |
| P0 | AutoQuant | Treat report functions as renderers/convenience wrappers; analytical args belong to generators or `...`. | Keeps generator-first architecture clean. |
| P0 | AnalyticsShinyApp | Keep module adapters internal; do not create a broad package-style public API from app helpers. | Product surface should be the app, artifacts, projects, and exports. |
| P1 | AutoPlots | Stop teaching `Plot.*` and `e_*_full()` helpers in modern examples. | Users should call high-level plot functions and display helpers. |
| P1 | Rodeo | Lead all docs with vNext plan/spec APIs; mark broad legacy helpers as transition-only. | vNext is the copy/paste future. |
| P1 | PolarsFE | Keep `__all__` vNext-only and label submodule helpers as direct/legacy helpers. | Prevents old helper sprawl from shaping the new API. |
| P1 | Benchmarks | Keep benchmark runners as documented commands, not package APIs. | Benchmarks provides evidence, not production APIs. |

## Ecosystem Public Surface To Keep

The future ecosystem should converge on these public shapes:

### AutoQuant

```r
artifact_result <- generate_<workflow>_artifacts(data = data, ...)
<Workflow>Report(artifact_result = artifact_result, OutputPath = ".", OutputFile = "report.html")
```

### AutoPlots

```r
plot <- AutoPlots::Bar(data = data, XVar = "Channel", YVar = "Revenue")
AutoPlots::display_plots_grid(list(plot), cols = 1)
```

### Rodeo

```r
plan <- rodeo_feature_plan(...)
fit <- rodeo_fit_feature_plan(train, plan)
scored <- rodeo_transform_feature_plan(new_data, fit)
artifacts <- generate_rodeo_feature_engineering_artifacts(train, plan)
```

### PolarsFE

```python
plan = PolarsFE.polars_feature_plan(...)
fit = PolarsFE.polars_fit_feature_plan(train, plan)
scored = PolarsFE.polars_transform_feature_plan(new_data, fit)
artifacts = PolarsFE.generate_polars_feature_engineering_artifacts(train, plan)
```

### AnalyticsShinyApp

The user-facing API is the app:

- load data
- run modules
- manage artifacts
- edit report plans
- preview layouts
- export reports/code
- save/load projects
- run trusted local custom code through Code Runner

## AnalyticsShinyApp Audit

AnalyticsShinyApp is not a package API today. Its R functions are app internals. The product surface is the Shiny/Electron app, project files, exported HTML/R code, and local artifacts.

| surface | examples | classification | keep/rename/hide/deprecate | recommendation |
| --- | --- | --- | --- | --- |
| App shell | `server()`, `build_app_ui()` | preferred path | keep | Keep minimal app entry points. |
| Page modules | `page_*_ui()`, `page_*_server()` | preferred path | keep internal | Good architecture. Do not expose as package API. |
| Workflow UX | `page_workflow_*()`, workflow stage registry | preferred path | keep internal | Workflow is a launchpad, not an automation engine. |
| Analysis module registry | `module_registry()`, `run_analysis_module()` | preferred path | keep internal | Stable app orchestration; should not expose module internals to users. |
| AutoQuant module adapters | `run_autoquant_*_module()`, `normalize_autoquant_*_artifacts()` | keep internal | hide | These are adapter plumbing. Keep out of README except status docs. |
| Artifact model | `create_artifact()`, `validate_artifact()`, `artifact_summary()` | preferred path | keep internal unless app becomes a package | Central contract. Add architecture examples, not user API docs. |
| Report plans | `create_report_plan()`, `validate_report_plan()`, `apply_report_plan_to_layout_state()` | preferred path | keep internal | Report plans are a product feature, not a standalone API yet. |
| Code Runner | `create_code_run_request()`, `run_code_local_trusted()`, `duplicate_code_run_request()` | preferred path | keep internal | Only execution system. Keep policy and history immutable. |
| Custom code hooks | `create_custom_code_hook_request()` | preferred path | keep internal | Hooks draft Code Runner requests only; never auto-run. |
| UI helpers | `ui_card()`, `ui_page()`, `ui_status_badge()` | keep internal | hide | App-owned component layer. No package ambitions. |
| Table helpers | `render_table()`, `export_table_csv()`, `export_table_xlsx()` | preferred path | keep internal | Shared app helper surface; hide reactable details. |
| QA helpers | `qa_*()` | convenience wrapper | keep internal | QA-as-law. If packaged later, expose only aggregate QA. |

### AnalyticsShinyApp Examples That Should Exist

- Run EDA -> artifacts -> report plan -> layout.
- Run CatBoost Builder -> scored data -> downstream handoff.
- Draft pre-stage custom code hook -> run through Code Runner.
- Save/load project with artifacts, report plans, and code history.

### AnalyticsShinyApp QA Invariants

- Module runs return `service_result()`.
- Modules never mutate Layout state directly.
- Code Runner is the only execution system.
- Custom code hooks never auto-run.
- Hidden artifacts stay in Artifact Library but not Layouts.
- Project save/load restores artifacts, report plans, active plan, and code history.

## AutoQuant Audit

AutoQuant should become the analytical artifact generator and report-rendering package. Its current surface is large because it also contains old modeling, plotting, SQL, object conversion, and report utilities.

### AutoQuant Public API To Keep

| surface | functions | classification | recommendation |
| --- | --- | --- | --- |
| EDA artifacts | `generate_eda_artifacts()` | preferred path | Keep and make docs generator-first. |
| Model Readiness artifacts | current pre-model/target diagnostics generator | breaking-change candidate | Rename/clarify to Model Readiness if still named assessment/target analysis. |
| Post-model assessment | `generate_model_assessment_artifacts()` | preferred path | Keep for trained/scored model evaluation only. |
| Regression Model Insights | `generate_regression_model_insights_artifacts()`, `RegressionModelInsightsReport()` | preferred path | Keep. Report renders artifacts or calls generator via `...`. |
| Binary Model Insights | `generate_binary_classification_model_insights_artifacts()`, `BinaryClassificationModelInsightsReport()` | preferred path | Keep. Report renders artifacts or calls generator via `...`. |
| Regression SHAP | `generate_regression_shap_analysis_artifacts()`, `RegressionShapAnalysisReport()` | preferred path | Keep generator-first. |
| Binary SHAP | `generate_binary_classification_shap_analysis_artifacts()`, `BinaryClassificationShapAnalysisReport()` | preferred path | Keep generator-first. |
| CatBoost Builder | `generate_catboost_builder_artifacts()` | preferred path | Keep one generator with flat `problem_type`, not separate public functions unless complexity proves it necessary. |

### AutoQuant Rename Candidates

| current | proposed | classification | reason |
| --- | --- | --- | --- |
| `TargetAnalysisReport()` | `ModelReadinessReport()` or retire in favor of artifact generator | breaking-change candidate | Target Analysis is narrower than readiness and creates terminology drift. |
| pre-model use of `generate_model_assessment_artifacts()` | `generate_model_readiness_artifacts()` | breaking-change candidate | `Model Assessment` is reserved for post-model evaluation. |
| `ModelInsightsReport()` | keep only as legacy wrapper | legacy compatibility | Regression/Binary-specific paths are clearer. |

### AutoQuant APIs To Hide/Internalize

| functions | classification | recommendation |
| --- | --- | --- |
| `ObjectTo*`, `ObjectFileTo*`, `ObjectTextToOpenAIInput()` | exported accidentally | Consolidate behind one future artifact/export/GenAI conversion contract if needed. |
| `multiplot()`, `utility_surface_plot()` | exported accidentally | Hide or mark internal. |
| `DataTable()`, `DataTable2()` | deprecation candidate | Replace with shared report/reactable table helpers. |
| `ChartTheme()` | deprecation candidate | Theme ownership should live in AutoPlots/report helpers. |
| `PlotGUI()` | deprecation candidate | UI belongs outside AutoQuant. |

### AutoQuant Legacy Compatibility

| functions | classification | transition stance |
| --- | --- | --- |
| `AutoCatBoostRegression()`, `AutoCatBoostClassifier()`, `AutoCatBoostScoring()` | legacy compatibility | Keep as core engines, but app/product examples should use CatBoost Builder artifacts. |
| `AutoH2o*`, `AutoXGBoost*`, `AutoLightGBM*`, `AutoBandit*` | legacy compatibility | Keep for existing package users. Do not expand app support yet. |
| time-series/CARMA/forecasting functions | legacy compatibility | Keep outside current app scope until wrapped as artifact generators. |
| `PostGRE_*`, `SQL_*` | deprecation candidate | Database utilities are product-scope creep. |
| AutoQuant plot helpers like `BarPlot()`, `HeatMapPlot()`, `ROCPlot()` | deprecation candidate | Plotting belongs in AutoPlots. Keep compatibility but stop teaching them. |

### AutoQuant Examples That Should Exist

- EDA artifact generator and report renderer.
- Model Readiness artifact generator with target/class-balance/leakage examples.
- CatBoost Builder regression and binary examples.
- CatBoost Builder output feeding Model Insights and SHAP.
- Regression/Binary SHAP generator-first plus report-renderer examples.
- Regression/Binary Model Insights generator-first plus report-renderer examples.

### AutoQuant QA Invariants

- Every generator returns stable artifacts, metadata, code, warnings, and diagnostics.
- Report functions render supplied `artifact_result` without recomputing.
- Binary/regression paths do not share ambiguous generic report names.
- SHAP interaction pairs are canonical unordered pairs unless explicitly directional.
- Report tables use consistent reactable filtering/rounding.
- AutoPlots high-level functions are used for plot artifacts.

## AutoPlots Audit

AutoPlots should expose plot functions, themes, and display helpers. It should not expose echarts wiring as the user-facing surface.

### AutoPlots Public API To Keep

| surface | functions | classification | recommendation |
| --- | --- | --- | --- |
| Core plots | `Line()`, `Bar()`, `Box()`, `Scatter()`, `HeatMap()`, `Histogram()`, `Density()`, `CorrMatrix()` | preferred path | Keep and document as the obvious path. |
| Analytical plots | `ROC()`, `Gains()`, `Lift()`, `VariableImportance()`, `ShapImportance()`, `PartialDependence.*()`, `Residuals.*()` | preferred path | Keep; tie examples to AutoQuant artifact outputs. |
| Display helpers | `display_plots_grid()`, `display_plots_sections()`, `display_plots_tabs()` | preferred path | Keep. Add report-row resizing examples. |
| Export helper | `save_image()` | convenience wrapper | Keep if stable. Needs copy/paste examples. |

### AutoPlots APIs To Hide/Internalize

| functions | classification | recommendation |
| --- | --- | --- |
| `e_*_full()` helpers | exported accidentally | Internalize or mark developer-only. Users should not need echarts internals. |
| `Plot.*` family | legacy compatibility | Keep during transition but remove from modern README examples. |
| `Plots.ModelEvaluation()`, `Plot.StandardPlots()` | legacy compatibility | Keep only if still needed by old workflows. |

### AutoPlots Breaking-Change Candidates

- Remove or stop exporting low-level `e_*_full()` helpers before productization if downstream packages do not require public access.
- Collapse `Plot.*` examples into concise high-level function names.
- Make display helpers the only blessed way to render lists of AutoPlots widgets in reports.

### AutoPlots Examples That Should Exist

- One copy/paste example per high-level plot family.
- Display grid/sections/tabs with two or more plots.
- Resizable report row/card behavior.
- Theme examples showing default axis formatting without manual axis hacking.

### AutoPlots QA Invariants

- High-level plot functions respect theme defaults.
- Display helpers render lists of widgets without direct echarts manipulation by callers.
- Box tooltips can be disabled globally where intended.
- Heatmap label/tooltip behavior scales with category count.

## Rodeo Audit

Rodeo should be the R feature engineering and model prep package. vNext is the future; legacy APIs should not shape it.

### Rodeo Public API To Keep

| surface | functions | classification | recommendation |
| --- | --- | --- | --- |
| Feature plan | `rodeo_feature_plan()` | preferred path | Keep as main entry point. |
| Fit/transform | `rodeo_fit_feature_plan()`, `rodeo_transform_feature_plan()`, `rodeo_fit_transform_feature_plan()` | preferred path | Keep scoring-safe contract. |
| Feature artifacts | `generate_rodeo_feature_engineering_artifacts()` | preferred path | Keep artifact-first path. |
| Partition/model prep | `rodeo_partition_plan()`, `rodeo_fit_partition_plan()`, `rodeo_apply_partition_plan()`, `rodeo_create_folds()` | preferred path | Keep. |
| Model prep artifacts | `generate_rodeo_model_prep_artifacts()` | preferred path | Keep. |

### Rodeo APIs To Hide/Deprecate

| functions | classification | recommendation |
| --- | --- | --- |
| `Install()`, `UpdateDocs()` | exported accidentally | Hide/internalize. |
| `DT_GDL_Feature_Engineering()`, `Partial_DT_GDL_Feature_Engineering*()` | deprecation candidate | Too implementation-specific. |
| `AutoWord2Vec*`, `Word2Vec_H2O()` | deprecation candidate | Model-Based Features redesign is deferred. |
| H2O clustering/autoencoder/isolation forest helpers | deprecation candidate | Broader than vNext feature engineering/model prep mission. |

### Rodeo Legacy Compatibility

Keep old helpers during transition:

- transformations: `Apply_*`, `InvApply_*`, `Estimate_*`, `Test_*`
- categorical helpers: `CategoricalEncoding()`, `Encoding()`, `DummifyDT()`
- calendar/time-series helpers
- interactions helpers
- legacy partition/prep helpers

But docs should lead with vNext, and app integrations should not call legacy helpers directly.

### Rodeo Examples That Should Exist

- Numeric/categorical/calendar/text/interactions plan.
- Fit on train, transform score data.
- Model prep random/stratified/group/time splits.
- Artifact generator returning manifest/diagnostics.

### Rodeo QA Invariants

- Fitted specs are scoring-safe.
- Transform does not relearn from scoring data.
- Manifest explains generated columns.
- Model prep preserves leakage-safe grouped/time behavior.
- Legacy APIs remain untouched unless intentionally retired.

## PolarsFE Audit

PolarsFE should mirror Rodeo concepts in Python/Polars while hiding orchestration internals.

### PolarsFE Public API To Keep

| surface | functions | classification | recommendation |
| --- | --- | --- | --- |
| Feature plan | `polars_feature_plan()` | preferred path | Keep in `__all__`. |
| Fit/transform | `polars_fit_feature_plan()`, `polars_transform_feature_plan()`, `polars_fit_transform_feature_plan()` | preferred path | Keep. |
| Feature artifacts | `generate_polars_feature_engineering_artifacts()` | preferred path | Keep. |
| Model prep | `polars_partition_plan()`, `polars_fit_partition_plan()`, `polars_apply_partition_plan()`, `polars_create_folds()` | preferred path | Keep. |
| Model prep artifacts | `generate_polars_model_prep_artifacts()` | preferred path | Keep. |

### PolarsFE Legacy Compatibility

| functions | classification | recommendation |
| --- | --- | --- |
| `calendar.*`, `character.*`, `numeric.*`, `window.*`, `datasets.*` direct helpers | legacy compatibility | Keep as direct helper examples below vNext. Do not expand as the primary API. |
| underscored helpers in `vnext.py` | keep internal | Keep out of `__all__` and docs. |

### PolarsFE Breaking-Change Candidates

- Keep `__all__` vNext-only; do not export legacy helpers from package root.
- Rename any legacy docs headings so users understand they are direct helpers, not the recommended workflow.
- If a legacy direct helper conflicts with vNext semantics, favor vNext before productization.

### PolarsFE Examples That Should Exist

- Feature plan fit/transform.
- Artifact generator.
- Model prep split/folds.
- Safe note about large Python benchmarks and crash isolation living in Benchmarks, not PolarsFE.

### PolarsFE QA Invariants

- `__all__` stays vNext-focused.
- Fitted plans are scoring-safe.
- Transform does not mutate/relearn state.
- vNext internals may optimize with batched Polars expressions without changing API.

## Benchmarks Audit

Benchmarks owns evidence, not product APIs.

### Benchmarks Public Surface To Keep

| surface | classification | recommendation |
| --- | --- | --- |
| smoke benchmark commands | preferred path | Keep documented and safe by default. |
| moderate/focused runners | preferred path | Keep as explicit commands with guardrails. |
| large/overnight runners | convenience wrapper | Keep opt-in only with safety flags. |
| summarizer scripts | preferred path | Keep stable output summaries. |
| decision reports | preferred path | Treat as implementation evidence. |

### Benchmarks APIs To Avoid

- Do not turn benchmark helper internals into package APIs.
- Do not let benchmark scripts mutate Rodeo/PolarsFE production code.
- Do not commit huge outputs.
- Do not run Python 10M+ jobs unless explicitly enabled with subprocess isolation and timeouts.

### Benchmarks Examples That Should Exist

- smoke command
- focused Rodeo command
- focused PolarsFE command
- moderate-safe command
- large opt-in command with crash-risk warning

### Benchmarks QA Invariants

- Outputs are ignored unless intentionally summarized.
- Python large benchmarks are opt-in.
- Medium/wide Python shapes are disabled by default.
- Spark remains skipped unless explicitly scoped.
- Summaries record skips/failures as evidence.

## Cross-Repo Rename/Hide/Deprecate Plan

| action | repo | target | timing |
| --- | --- | --- | --- |
| Rename | AutoQuant | pre-model target/assessment language to Model Readiness | before productization |
| Hide | AutoPlots | low-level `e_*_full()` helpers | before public docs polish |
| Hide | Rodeo | `Install()`, `UpdateDocs()` | before vNext release docs |
| Deprecate | AutoQuant | old plot/table helpers duplicated by AutoPlots/report helpers | after modern examples exist |
| Deprecate | AutoQuant | `ModelInsightsReport()` as modern path | now in docs, code later |
| Keep legacy | Rodeo | old transformation/encoding helpers | transition only |
| Keep legacy | PolarsFE | submodule direct helpers | transition only |
| Keep internal | AnalyticsShinyApp | page modules/adapters/services | always unless packaged deliberately |

## Required Docs Changes

### AnalyticsShinyApp

- Link this audit from README.
- Keep architecture docs clear that app helpers are internal.
- Add workflow examples for Code Runner hooks and CatBoost handoff.

### AutoQuant

- Rewrite README examples around generators first.
- Add explicit legacy labels for `ModelInsightsReport()` and `TargetAnalysisReport()`.
- Add Model Readiness terminology.
- Add report renderer examples using `artifact_result`.

### AutoPlots

- Lead README with concise high-level plot names.
- Move `Plot.*` and low-level helper docs out of primary examples.
- Add display helper examples.

### Rodeo

- Lead README with vNext feature engineering and model prep.
- Move legacy helper examples into a transition/legacy section.
- Add migration notes from common legacy helpers to vNext.

### PolarsFE

- Keep README vNext-first.
- Label submodule examples as direct helper examples.
- Add warnings that performance benchmarking belongs in Benchmarks.

### Benchmarks

- Keep safety guardrails in README.
- Keep decision reports current after focused runs.
- Document that benchmark failures/crashes are evidence, not just errors.

## Required QA Invariants

| repo | invariants |
| --- | --- |
| AnalyticsShinyApp | module service_result, artifact normalization, report plan validation, project save/load, Code Runner policy, workflow does not auto-run |
| AutoQuant | generator output shape, report renderer reuse of artifact_result, problem-specific report names, no generic model insight path in app adapters |
| AutoPlots | high-level plot functions keep theme defaults, display helpers render lists, no caller-facing echarts internals required |
| Rodeo | vNext scoring-safe specs, manifest stability, model prep leakage safety |
| PolarsFE | vNext root exports, scoring-safe fitted plans, batched internals do not change outputs |
| Benchmarks | safe defaults, output ignore rules, summary reproducibility, large Python opt-in only |

## Final Recommendation

Before productization, the ecosystem should intentionally break or hide APIs that create confusion:

1. Rename pre-model assessment concepts to Model Readiness.
2. Make AutoQuant generator-first examples the default everywhere.
3. Keep report functions as artifact renderers.
4. Stop teaching generic or legacy report names.
5. Stop teaching AutoPlots `Plot.*` and `e_*_full()` helpers.
6. Keep Rodeo and PolarsFE vNext paths as the only modern feature-engineering/model-prep examples.
7. Keep AnalyticsShinyApp internals internal.
8. Keep Benchmarks as evidence, not product API.

Legacy paths can remain during transition, but they should no longer define the future shape of the product.
