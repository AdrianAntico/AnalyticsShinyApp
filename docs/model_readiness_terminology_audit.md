# Model Readiness Terminology Audit

## Rule

`Model Assessment` is reserved for evaluation of an already-trained model.

Pre-model diagnostics should use `Model Readiness`. This includes target diagnostics, class balance, leakage detection, collider detection, missingness, constant/NZV features, high-cardinality warnings, correlation diagnostics, drift diagnostics, sample-size/readiness diagnostics, and modeling recommendations.

## Files Changed

### AnalyticsShinyApp

- `R/module_autoquant_model_assessment.R`
  - Updated user-facing messages, fallback artifact labels, default artifact section, report-plan labels, report-plan descriptions, rationale text, generated-result message, QA fixture section names, and missing-generator text from Model Assessment to Model Readiness.
  - Preserved legacy internal names such as `autoquant_model_assessment`, `normalize_autoquant_model_assessment_artifacts()`, and `qa_autoquant_model_assessment_integration()`.
- `R/page_analysis_modules.R`
  - Updated the Analysis Modules page label from `AutoQuant Model Assessment` to `AutoQuant Model Readiness`.
  - Updated the default artifact section for the readiness adapter to `Model Readiness`.
- `R/registry_modules.R`
  - Updated the `autoquant_model_assessment` registry label and description to describe model readiness.
  - Left the separate planned `model_assessment` registry entry unchanged because it refers to post-model model performance diagnostics.
- `docs/autoquant_model_assessment_module.md`
  - Reframed the document as AutoQuant Model Readiness.
  - Added a compatibility note that legacy internal names are preserved.
- `docs/analysis_modules_status.md`
  - Updated the `autoquant_model_assessment` row to Model Readiness terminology.
  - Clarified the legacy `aq_ma_` artifact prefix.
- `docs/product_backlog.md`
  - Updated backlog item labels for the pre-model AutoQuant adapter and recommended report plan to Model Readiness.
- `docs/product_backlog.csv`
  - Updated the corresponding CSV backlog entries and notes.
- `docs/model_readiness_terminology_audit.md`
  - Added this audit report.

### AutoQuant

- `R/target_model_readiness_artifacts.R`
  - Updated the generator section heading, roxygen title, description, example variable names, and example output path from Model Assessment to Model Readiness.
  - Updated the sidecar-export default output folder to `model_readiness_artifacts`.
  - Preserved the exported function name `generate_model_assessment_artifacts()` and the legacy class name `model_assessment_artifacts`.
- `man/generate_model_assessment_artifacts.Rd`
  - Mirrored the roxygen terminology updates so installed docs read as Model Readiness.
- `README.md`
  - Updated the Model Readiness example variable and output path names.

### AutoPlots

- No files changed. No `Model Assessment` / `Model Readiness` references were found in the AutoPlots repository.

## References Intentionally Left Unchanged

These references use `Model Assessment` for post-model evaluation of an already-trained/scored model and were left unchanged:

- `AnalyticsShinyApp/R/module_autoquant_catboost_builder.R`
  - CatBoost downstream handoff labels and warnings that refer to running Model Assessment from scored CatBoost output.
- `AnalyticsShinyApp/R/page_analysis_modules.R`
  - `Run Model Assessment` button in the CatBoost handoff panel.
- `AnalyticsShinyApp/R/registry_modules.R`
  - Planned `model_assessment` module entry for model performance, calibration, lift/gains, and diagnostics.
- `AnalyticsShinyApp/docs/analysis_module_architecture.md`
  - `Model Assessment` section describing model metrics, ROC / PR, confusion matrix, calibration, lift/gains, and residual diagnostics.
- `AnalyticsShinyApp/docs/catboost_builder_architecture.md`
  - CatBoost downstream handoff references to Model Assessment.
- `AnalyticsShinyApp/docs/shap_analysis_architecture.md`
  - Opening distinction between Model Assessment, Model Insights, and SHAP Analysis.
- `AnalyticsShinyApp/docs/electron_smoke_test_results.md`
  - Historical smoke-test records.
- `AnalyticsShinyApp/docs/product_backlog.csv`
  - `BL-104` CatBoost downstream handoff UX, because it refers to post-model scored output.
- `AutoQuant/README.md`
  - CatBoost Builder downstream handoff wording, because it refers to scored output feeding post-model Model Assessment.
- `AutoQuant/R/generate_catboost_builder_artifacts.R`
  - Downstream handoff message for scored CatBoost output.
- `AutoQuant/man/generate_catboost_builder_artifacts.Rd`
  - Downstream handoff documentation for scored CatBoost output.
- `AutoQuant/inst/r-markdowns/Binary_Classification_ModelInsights_Artifact_Renderer.Rmd`
  - Binary classification model assessment and threshold diagnostics.
- `AutoQuant/inst/r-markdowns/Regression_ModelInsights_Artifact_Renderer.Rmd`
  - Regression model assessment, calibration, and interpretation.

## Legacy Identifiers Intentionally Preserved

The following names are historically established identifiers and were not renamed in this pass:

- `AutoQuant::generate_model_assessment_artifacts()`
- `model_assessment_artifacts` class name in AutoQuant
- `autoquant_model_assessment` module ID in AnalyticsShinyApp
- `aq_ma_` artifact ID prefix
- `qa_autoquant_model_assessment_integration()`
- related internal helper names such as `run_autoquant_model_assessment_module()`

These should be treated as compatibility names for the pre-model Model Readiness workflow until a deliberate API migration is planned.

## Remaining Ambiguous Terminology

- `AutoQuant::generate_model_assessment_artifacts()` is still a misleading exported function name because it generates Model Readiness artifacts. A future API pass could introduce `generate_model_readiness_artifacts()` and keep the old name as a compatibility wrapper.
- `autoquant_model_assessment` remains a misleading app module ID for the same reason. A future migration could introduce `autoquant_model_readiness` while keeping project-state compatibility for existing saved projects.
- CatBoost Builder currently exposes a post-model `Run Model Assessment` handoff action. That wording is correct, but the app should eventually ensure that the downstream target is a true post-model assessment adapter rather than the legacy readiness adapter.
