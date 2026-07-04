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
      description = "Generate SHAP importance, dependence, summary, and contribution artifacts.",
      status = "planned",
      output_artifact_types = c("table", "plot", "text"),
      required_packages = "AutoQuant",
      supports_genai = TRUE,
      supports_code_generation = TRUE
    ),
    catboost_builder = list(
      module_id = "catboost_builder",
      label = "CatBoost Builder",
      category = "Modeling",
      description = "Train CatBoost models and return assessment, insight, and metadata artifacts.",
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
