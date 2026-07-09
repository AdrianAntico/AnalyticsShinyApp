module_registry <- function() {
  list(
    autoquant_eda = list(
      module_id = "autoquant_eda",
      label = "Explore Data",
      category = "EDA",
      description = "Generate exploratory data evidence: distributions, missingness, correlations, and trends.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_model_readiness = list(
      module_id = "autoquant_model_readiness",
      label = "Model Readiness",
      category = "Modeling",
      description = "Review target diagnostics, leakage risk, drift, class balance, and modeling recommendations.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_regression_model_insights = list(
      module_id = "autoquant_regression_model_insights",
      label = "Regression Model Insights",
      category = "Modeling",
      description = "Inspect regression model diagnostics, feature effects, and residual behavior.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_binary_model_insights = list(
      module_id = "autoquant_binary_model_insights",
      label = "Binary Classification Model Insights",
      category = "Modeling",
      description = "Inspect classification thresholds, diagnostics, feature effects, and score behavior.",
      status = "experimental",
      output_artifact_types = c("plot", "table", "text"),
      required_packages = c("AutoQuant", "AutoPlots"),
      supports_genai = FALSE,
      supports_code_generation = TRUE
    ),
    autoquant_regression_shap_analysis = list(
      module_id = "autoquant_regression_shap_analysis",
      label = "Regression SHAP Insights",
      category = "Interpretability",
      description = "Explain regression predictions using precomputed SHAP contribution columns.",
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
      label = "Binary Classification SHAP Insights",
      category = "Interpretability",
      description = "Explain classification scores using precomputed SHAP contribution columns.",
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
      label = "Multiclass SHAP Insights",
      category = "Interpretability",
      description = "Deferred scaffold for multiclass prediction explanation artifacts.",
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
      label = "CatBoost Builder",
      category = "Modeling",
      description = "Train and score regression or binary CatBoost models and return downstream evidence.",
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
      description = "Planned placeholder. Use the implemented CatBoost Builder module for current workflows.",
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

module_id_aliases <- function() {
  c(
    autoquant_model_assessment = "autoquant_model_readiness"
  )
}

normalize_module_id <- function(module_id) {
  if (is.null(module_id) || !length(module_id)) {
    return(module_id)
  }
  module_id <- module_id[[1L]]
  aliases <- module_id_aliases()
  alias <- unname(aliases[module_id])
  if (!length(alias) || is.na(alias)) {
    return(module_id)
  }
  alias
}

get_module_definition <- function(module_id) {
  registry <- get_module_registry()
  module_id <- normalize_module_id(module_id)
  module <- registry[[module_id]]
  if (is.null(module)) {
    return(NULL)
  }

  module
}

module_display_label <- function(module_id, fallback = NULL) {
  module_id <- module_id %||% fallback
  if (is.null(module_id) || !length(module_id) || is.na(module_id[[1]]) || !nzchar(module_id[[1]])) {
    return(fallback %||% "Unknown module")
  }

  module <- get_module_definition(module_id)
  if (!is.null(module) && !is.null(module$label) && nzchar(module$label)) {
    return(module$label)
  }

  labels <- c(
    plot_builder = "Plot Builder",
    code_runner = "Code Runner",
    manual_text = "Manual Text",
    table_builder = "Table Builder",
    genai_narrative = "GenAI Narrative",
    project = "Project",
    eda = "Explore Data",
    qa = "QA",
    qa_render_targets = "Render Target QA",
    qa_artifact_quality_policy = "Artifact Quality QA",
    qa_table_artifact_policy = "Table Artifact QA",
    qa_artifact_producer_semantics = "Producer Semantics QA"
  )
  label <- unname(labels[module_id])
  if (length(label) && !is.na(label) && nzchar(label)) {
    return(label)
  }

  cleaned <- gsub("^autoquant_", "", module_id)
  cleaned <- gsub("_", " ", cleaned)
  tools::toTitleCase(cleaned)
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

qa_module_terminology_consistency <- function(root = ".") {
  canonical_id <- "autoquant_model_readiness"
  legacy_id <- "autoquant_model_assessment"
  post_model_id <- "model_assessment"
  readiness_prefix <- "aq_mr_"

  result_row <- function(rule, result, file, issue, recommendation) {
    data.table::data.table(
      rule = rule,
      result = result,
      status = switch(result, PASS = "success", WARNING = "warning", FAIL = "error"),
      file = file,
      issue = issue,
      recommendation = recommendation,
      message = paste(issue, recommendation, sep = " Recommendation: ")
    )
  }

  read_file <- function(path) {
    full_path <- file.path(root, path)
    if (!file.exists(full_path)) {
      return(character())
    }
    readLines(full_path, warn = FALSE)
  }

  file_contains <- function(path, pattern, fixed = TRUE) {
    lines <- read_file(path)
    length(lines) && any(grepl(pattern, lines, fixed = fixed))
  }

  rows <- list()
  add <- function(rule, result, file, issue, recommendation) {
    rows[[length(rows) + 1L]] <<- result_row(rule, result, file, issue, recommendation)
  }

  registry <- get_module_registry()
  module_ids <- vapply(registry, function(module) module$module_id %||% NA_character_, character(1))
  registry_names <- names(registry)

  add(
    "canonical_pre_model_module",
    if (canonical_id %in% names(registry) && canonical_id %in% module_ids) "PASS" else "FAIL",
    "R/registry_modules.R",
    paste("Canonical module id present:", canonical_id),
    "Register Model Readiness with module_id autoquant_model_readiness."
  )
  add(
    "canonical_pre_model_module",
    if (file_contains("R/module_result.R", paste0('identical(module_id, "', canonical_id, '")')) &&
        file_contains("R/module_result.R", "run_autoquant_model_readiness_module") &&
        file_contains("R/module_result.R", "qa_autoquant_model_readiness_integration")) "PASS" else "FAIL",
    "R/module_result.R",
    "Routing and aggregate QA use canonical Model Readiness helpers.",
    "Route validation, execution, and aggregate QA through autoquant_model_readiness."
  )
  add(
    "canonical_pre_model_module",
    if (file_contains("R/page_analysis_modules.R", canonical_id)) "PASS" else "FAIL",
    "R/page_analysis_modules.R",
    "Analysis Modules page exposes canonical Model Readiness module id.",
    "Use autoquant_model_readiness in the module selector and module config branch."
  )
  add(
    "canonical_pre_model_module",
    if (file_contains("R/page_workflow.R", paste0('modules = list("', canonical_id, '")'))) "PASS" else "FAIL",
    "R/page_workflow.R",
    "Workflow Model Readiness stage maps to canonical module id.",
    "Map workflow stage model_readiness to autoquant_model_readiness only."
  )
  add(
    "canonical_pre_model_module",
    if (file_contains("R/module_autoquant_model_readiness.R", paste0('module_id = "', canonical_id, '"')) &&
        file_contains("R/module_autoquant_model_readiness.R", paste0('source_module = "', canonical_id, '"'))) "PASS" else "FAIL",
    "R/module_autoquant_model_readiness.R",
    "Readiness artifact generation metadata uses canonical module id.",
    "Normalize generated artifact metadata to autoquant_model_readiness."
  )

  aliases <- module_id_aliases()
  add(
    "compatibility_alias",
    if (identical(unname(aliases[[legacy_id]]), canonical_id) &&
        identical(normalize_module_id(legacy_id), canonical_id)) "PASS" else "FAIL",
    "R/registry_modules.R",
    "Legacy id resolves deterministically to canonical Model Readiness id.",
    "Keep autoquant_model_assessment only in module_id_aliases() as a compatibility alias."
  )
  add(
    "compatibility_alias",
    if (!legacy_id %in% names(registry) && !legacy_id %in% module_ids) "PASS" else "FAIL",
    "R/registry_modules.R",
    "Legacy id is not registered as a preferred module.",
    "Do not add autoquant_model_assessment back to module_registry()."
  )
  add(
    "compatibility_alias",
    if (file_contains("R/module_autoquant_model_readiness.R", "Legacy compatibility only.") &&
        file_contains("R/module_autoquant_model_readiness.R", "qa_autoquant_model_assessment_integration <- qa_autoquant_model_readiness_integration")) "PASS" else "FAIL",
    "R/module_autoquant_model_readiness.R",
    "Legacy helper names are thin wrappers only.",
    "Keep legacy helpers as aliases to Model Readiness functions; do not duplicate implementation."
  )
  add(
    "compatibility_alias",
    if (!file_contains("R/page_analysis_modules.R", legacy_id) &&
        !file_contains("R/page_workflow.R", legacy_id) &&
        !file_contains("R/module_result.R", legacy_id)) "PASS" else "FAIL",
    "R/page_analysis_modules.R; R/page_workflow.R; R/module_result.R",
    "Preferred routing and UI surfaces do not use the legacy id.",
    "Use autoquant_model_readiness outside alias/wrapper compatibility code."
  )

  post_model <- registry[[post_model_id]]
  workflow <- workflow_stage_registry()
  readiness_stage <- workflow[[which(vapply(workflow, function(stage) identical(stage$stage_id, "model_readiness"), logical(1)))]]
  assessment_stage <- workflow[[which(vapply(workflow, function(stage) identical(stage$stage_id, "model_assessment"), logical(1)))]]
  add(
    "planned_post_model_module",
    if (!is.null(post_model) && identical(post_model$status, "planned")) "PASS" else "FAIL",
    "R/registry_modules.R",
    "Post-model Model Assessment remains planned.",
    "Do not mark model_assessment implemented until a true post-model evaluator exists."
  )
  add(
    "planned_post_model_module",
    if (identical(workflow_stage_module_ids(readiness_stage), canonical_id) &&
        !post_model_id %in% workflow_stage_module_ids(readiness_stage)) "PASS" else "FAIL",
    "R/page_workflow.R",
    "Readiness workflow does not invoke post-model Model Assessment.",
    "Keep model_readiness mapped to autoquant_model_readiness only."
  )
  add(
    "planned_post_model_module",
    if (is.null(workflow_stage_module_ids(assessment_stage)) || !length(workflow_stage_module_ids(assessment_stage))) "PASS" else "FAIL",
    "R/page_workflow.R",
    "Model Assessment workflow stage has no implemented module binding.",
    "Leave model_assessment unbound until the post-model adapter is implemented."
  )
  add(
    "planned_post_model_module",
    if (file_contains("R/module_autoquant_catboost_builder.R", 'configs <- list(model_assessment = common_assessment)') &&
        !file_contains("R/module_autoquant_catboost_builder.R", paste0("configs <- list(", canonical_id))) "PASS" else "FAIL",
    "R/module_autoquant_catboost_builder.R",
    "CatBoost post-model handoff targets model_assessment, not readiness.",
    "Keep CatBoost scored-output evaluation separate from pre-model readiness."
  )

  add(
    "artifact_naming",
    if (file_contains("R/module_autoquant_model_readiness.R", paste0('module_result_convention_checks(binary_result, "', readiness_prefix, '")')) &&
        file_contains("R/module_autoquant_model_readiness.R", 'base_id <- paste("aq_mr"')) "PASS" else "FAIL",
    "R/module_autoquant_model_readiness.R",
    paste("Readiness artifacts use prefix", readiness_prefix),
    "Generate new readiness artifact ids with aq_mr_."
  )
  add(
    "artifact_naming",
    if (!file_contains("R/module_autoquant_model_readiness.R", '"aq_ma"') &&
        !file_contains("docs/analysis_modules_status.md", "aq_ma_")) "PASS" else "FAIL",
    "R/module_autoquant_model_readiness.R; docs/analysis_modules_status.md",
    "Legacy aq_ma_ prefix is not used for current readiness generation or current module docs.",
    "Do not generate new Model Readiness artifacts with aq_ma_."
  )

  add(
    "registry_consistency",
    if (!anyDuplicated(registry_names) && !anyDuplicated(module_ids)) "PASS" else "FAIL",
    "R/registry_modules.R",
    "No duplicate registry names or module_id values.",
    "Keep registry names and module_id values unique."
  )
  add(
    "registry_consistency",
    if (identical(normalize_module_id("unknown_module_id"), "unknown_module_id") &&
        is.null(get_module_definition("unknown_module_id"))) "PASS" else "FAIL",
    "R/registry_modules.R",
    "Unknown module ids fail gracefully.",
    "Unknown ids should remain unchanged through alias normalization and return NULL from get_module_definition()."
  )
  add(
    "workflow_consistency",
    if (file_contains("R/page_analysis_modules.R", canonical_id) &&
        file_contains("R/page_workflow.R", canonical_id) &&
        file_contains("R/module_result.R", canonical_id) &&
        canonical_id %in% module_ids) "PASS" else "FAIL",
    "R/page_analysis_modules.R; R/page_workflow.R; R/module_result.R; R/registry_modules.R",
    "Workflow, module page, routing, and registry agree on canonical readiness id.",
    "Keep all launch and routing surfaces aligned on autoquant_model_readiness."
  )

  docs_to_scan <- c(
    "README.md",
    "docs/analysis_modules_status.md",
    "docs/workflow_architecture.md",
    "docs/autoquant_model_readiness_module.md",
    "docs/model_readiness_terminology_audit.md",
    "docs/electron_smoke_test_results.md"
  )
  allowed_legacy_docs <- c(
    "docs/autoquant_model_readiness_module.md",
    "docs/model_readiness_terminology_audit.md",
    "docs/electron_smoke_test_results.md",
    "docs/workflow_architecture.md",
    "README.md"
  )
  for (doc in docs_to_scan) {
    lines <- read_file(doc)
    legacy_lines <- grep(legacy_id, lines, fixed = TRUE, value = TRUE)
    if (!length(legacy_lines)) {
      add("documentation_consistency", "PASS", doc, "No legacy module id references found.", "No action needed.")
      next
    }
    lower_context <- tolower(paste(legacy_lines, collapse = " "))
    allowed_context <- doc %in% allowed_legacy_docs &&
      (identical(doc, "docs/electron_smoke_test_results.md") ||
         grepl("legacy|compatibility|historical|old|alias|smoke-test records", lower_context))
    add(
      "documentation_consistency",
      if (allowed_context) "WARNING" else "FAIL",
      doc,
      paste("Legacy id reference(s):", paste(utils::head(trimws(legacy_lines), 3L), collapse = " | ")),
      if (allowed_context) {
        "Allowed historical, migration, or compatibility reference. Do not rewrite historical records."
      } else {
        "Current documentation should instruct users to use autoquant_model_readiness, not autoquant_model_assessment."
      }
    )
  }

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
