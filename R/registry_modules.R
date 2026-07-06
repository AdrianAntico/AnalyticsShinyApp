module_registry <- function() {
  list(
    autoquant_eda = list(
      module_id = "autoquant_eda",
      label = "AutoQuant EDA",
      category = "EDA",
      description = "Generate EDA artifacts using AutoQuant.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_model_assessment = list(
      module_id = "autoquant_model_assessment",
      label = "AutoQuant Model Readiness",
      category = "Modeling",
      description = "Generate target diagnostics, leakage checks, drift/readiness evidence, and modeling recommendations using AutoQuant.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_regression_model_insights = list(
      module_id = "autoquant_regression_model_insights",
      label = "AutoQuant Regression Model Insights",
      category = "Modeling",
      description = "Generate regression model insight artifacts using AutoQuant.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_binary_model_insights = list(
      module_id = "autoquant_binary_model_insights",
      label = "AutoQuant Binary Classification Model Insights",
      category = "Modeling",
      description = "Generate binary classification model insight artifacts using AutoQuant.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_regression_shap_analysis = list(
      module_id = "autoquant_regression_shap_analysis",
      label = "AutoQuant Regression SHAP Analysis",
      category = "Interpretability",
      description = "Generate regression SHAP analysis artifacts from precomputed Shap_ columns using AutoQuant.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE,
      supported_problem_types = "regression",
      qa_helper = "qa_autoquant_regression_shap_analysis_integration"
    ),
    autoquant_binary_shap_analysis = list(
      module_id = "autoquant_binary_shap_analysis",
      label = "AutoQuant Binary Classification SHAP Analysis",
      category = "Interpretability",
      description = "Generate binary classification SHAP analysis artifacts from precomputed Shap_ columns using AutoQuant.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE,
      supported_problem_types = "binary_classification",
      qa_helper = "qa_autoquant_binary_shap_analysis_integration"
    ),
    autoquant_multiclass_shap_analysis = list(
      module_id = "autoquant_multiclass_shap_analysis",
      label = "AutoQuant Multiclass SHAP Analysis",
      category = "Interpretability",
      description = "Deferred scaffold for multiclass SHAP prediction-surface artifacts using AutoQuant.",
      status = "deferred",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = "AutoQuant",
      supports_genai = FALSE,
      supports_code_generation = TRUE,
      supported_problem_types = "multiclass",
      qa_helper = NA_character_
    ),
    autoquant_catboost_builder = list(
      module_id = "autoquant_catboost_builder",
      label = "AutoQuant CatBoost Builder",
      category = "Modeling",
      description = "Train and score regression or binary CatBoost models through AutoQuant and return standard artifacts plus downstream handoff metadata.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots", "catboost"),
      supports_genai = FALSE,
      supports_code_generation = TRUE,
      supported_problem_types = c("regression", "binary"),
      qa_helper = "qa_autoquant_catboost_builder_integration"
    ),
    eda_report = list(
      module_id = "eda_report",
      label = "EDA Report",
      category = "Exploration",
      description = "Generate exploratory data analysis tables, plots, diagnostics, and notes.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text", "metric"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE
    ),
    target_analysis = list(
      module_id = "target_analysis",
      label = "Target Analysis",
      category = "Target",
      description = "Analyze target distributions, associations, trends, drift, and risk flags.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text", "metric"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE
    ),
    model_assessment = list(
      module_id = "model_assessment",
      label = "Model Assessment",
      category = "Modeling",
      description = "Summarize model performance, diagnostics, calibration, and lift/gains.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text", "metric", "model_summary"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE
    ),
    model_insights = list(
      module_id = "model_insights",
      label = "Model Insights",
      category = "Modeling",
      description = "Generate model interpretation artifacts such as importance and feature effects.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text", "model_summary"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE
    ),
    shap_analysis = list(
      module_id = "shap_analysis",
      label = "SHAP Analysis",
      category = "Interpretability",
      description = "Generic deferred placeholder. Use problem-type-specific SHAP modules for implementation.",
      status = "deferred",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE,
      supported_problem_types = c("regression", "binary_classification", "multiclass"),
      qa_helper = "qa_shap_artifact_contract"
    ),
    catboost_builder = list(
      module_id = "catboost_builder",
      label = "CatBoost Builder",
      category = "Modeling",
      description = "Legacy planned placeholder. Use autoquant_catboost_builder for the implemented AutoQuant-backed v1 adapter.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text", "metric", "model_summary"),
      required_packages = c("AutoQuant", "catboost"),
      supports_genai = TRUE,
      supports_code_generation = TRUE
    ),
    forecasting = list(
      module_id = "forecasting",
      label = "Forecasting",
      category = "Forecasting",
      description = "Generate forecast plots, values, diagnostics, summaries, and caveats.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text", "metric", "forecast_block"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE
    )
  )
}

get_module_registry <- function() {
  module_registry()
}

get_module_definition <- function(module_id) {
  registry <- get_module_registry()
  module <- registry[[module_id]]
  if (is.null(module)) {
    return(NULL)
  }

  module
}

qa_module_registry <- function() {
  registry <- get_module_registry()
  rows <- lapply(registry, function(module) {
    data.table::data.table(
      module_id = module$module_id,
      label = module$label,
      category = module$category,
      description = module$description,
      status = module$status,
      output_artifact_types = paste(module$output_artifact_types, collapse = ", "),
      required_packages = paste(module$required_packages, collapse = ", "),
      supports_genai = isTRUE(module$supports_genai),
      supports_code_generation = isTRUE(module$supports_code_generation)
    )
  })

  data.table::rbindlist(rows, use.names = TRUE)
}
