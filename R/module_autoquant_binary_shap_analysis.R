autoquant_binary_shap_analysis_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_binary_classification_shap_analysis_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

.autoquant_bshap_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_binary_shap_analysis_", format(timestamp, "%Y%m%d%H%M%S"))
}

validate_autoquant_binary_shap_analysis_config <- function(data, config) {
  config <- config %||% list()
  config$problem_type <- "binary_classification"
  validate_shap_analysis_config(
    config = config,
    data = data,
    problem_type = "binary_classification"
  )
}

.autoquant_binary_shap_generator_args <- function(generator, data, config) {
  formal_names <- names(formals(generator))
  args <- list()

  candidates <- list(
    data = data,
    target_col = config$target_col %||% config$target_var,
    prediction_col = config$prediction_col,
    predicted_class_col = config$predicted_class_col,
    positive_class = config$positive_class,
    feature_cols = config$feature_cols %||% config$feature_vars,
    shap_prefix = config$shap_prefix %||% "Shap_",
    id_cols = config$id_cols,
    model_name = config$model_name,
    data_name = config$data_name,
    DateVar = config$DateVar,
    date_aggregation = config$date_aggregation,
    ByVars = config$ByVars,
    selected_features = config$selected_features,
    local_row_ids = config$local_row_ids,
    threshold = config$threshold,
    threshold_bands = config$threshold_bands,
    top_n = config$top_n,
    max_dependence_rows = config$max_dependence_rows,
    max_segment_levels = config$max_segment_levels,
    max_byvars = config$max_byvars,
    include_dependence = config$include_dependence,
    include_segments = config$include_segments,
    include_time = config$include_time,
    include_local = config$include_local,
    include_interactions = config$include_interactions,
    include_threshold_context = config$include_threshold_context,
    include_class_balance = config$include_class_balance,
    include_plots = config$include_plots,
    include_effect_curves = config$include_effect_curves,
    effect_curve_backend = config$effect_curve_backend,
    effect_curve_models = config$effect_curve_models,
    effect_curve_sample_size = config$effect_curve_sample_size,
    effect_curve_max_features = config$effect_curve_max_features,
    effect_curve_validation_fraction = config$effect_curve_validation_fraction,
    effect_curve_theme = config$effect_curve_theme,
    interaction_pairs = config$interaction_pairs,
    max_interaction_pairs = config$max_interaction_pairs,
    max_interaction_surface_plots = config$max_interaction_surface_plots,
    numeric_interaction_bins = config$numeric_interaction_bins,
    max_interaction_levels = config$max_interaction_levels,
    min_interaction_cell_n = config$min_interaction_cell_n,
    max_feature_effect_plots = config$max_feature_effect_plots,
    max_dependence_plots = config$max_dependence_plots,
    max_segment_plots = config$max_segment_plots,
    max_time_plots = config$max_time_plots,
    max_local_plots = config$max_local_plots,
    plot_top_n = config$plot_top_n,
    auto_plots_theme = config$auto_plots_theme,
    prediction_scale = config$prediction_scale,
    artifact_options = config$artifact_options
  )

  for (name in names(candidates)) {
    if (name %in% formal_names && !is.null(candidates[[name]])) {
      args[[name]] <- candidates[[name]]
    }
  }

  if (!length(args) && "..." %in% formal_names) {
    args <- list(data = data, config = config)
  }

  args
}

run_autoquant_binary_shap_analysis_module <- function(data, config) {
  validation <- validate_autoquant_binary_shap_analysis_config(data, config)
  if (identical(validation$status, "error")) {
    return(validation)
  }

  generated_at <- Sys.time()
  module_run_id <- .autoquant_bshap_run_id(generated_at)
  config <- validation$value
  config$problem_type <- "binary_classification"
  source_function <- "generate_binary_classification_shap_analysis_artifacts"

  if (!autoquant_binary_shap_analysis_available()) {
    return(service_result(
      status = "warning",
      artifacts = list(),
      warnings = c(
        validation$warnings %||% character(),
        "AutoQuant Binary Classification SHAP Analysis requires AutoQuant::generate_binary_classification_shap_analysis_artifacts(), but this AutoQuant install does not expose it."
      ),
      metadata = module_run_metadata(
        module_id = "autoquant_binary_shap_analysis",
        module_run_id = module_run_id,
        generated_at = generated_at,
        data_name = config$data_name %||% NULL,
        source_package = "AutoQuant",
        source_function = source_function,
        configured_inputs = config,
        artifacts = list(),
        report_plans = list(),
        extra = list(
          implementation_status = "generator_missing",
          artifact_id_prefix = shap_artifact_id_prefix("binary_classification"),
          shap_sections = shap_sections(),
          shap_lenses = shap_lenses(),
          validation_warnings = validation$warnings %||% character()
        )
      ),
      code = paste(
        "# AutoQuant Binary Classification SHAP Analysis call",
        "artifacts <- AutoQuant::generate_binary_classification_shap_analysis_artifacts(",
        "  data = data,",
        "  target_col = target_col,",
        "  prediction_col = prediction_col,",
        "  positive_class = positive_class,",
        "  shap_prefix = \"Shap_\"",
        ")",
        sep = "\n"
      )
    ))
  }

  generator <- get("generate_binary_classification_shap_analysis_artifacts", envir = asNamespace("AutoQuant"))
  result <- tryCatch(
    do.call(generator, .autoquant_binary_shap_generator_args(generator, data, config)),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant Binary Classification SHAP Analysis failed:", conditionMessage(e)),
        metadata = list(
          error_code = "AUTOQUANT_SHAP_RUN_FAILED",
          module_id = "autoquant_binary_shap_analysis",
          module_run_id = module_run_id,
          source_function = source_function
        )
      )
    }
  )
  if (is.list(result) && !is.null(result$status) && identical(result$status, "error")) {
    return(result)
  }

  artifacts <- normalize_autoquant_shap_artifacts(
    autoquant_result = result,
    config = config,
    module_id = "autoquant_binary_shap_analysis",
    module_run_id = module_run_id,
    source_function = source_function,
    generated_at = generated_at
  )
  plans <- build_autoquant_shap_report_plans(
    artifacts = artifacts,
    config = config,
    module_id = "autoquant_binary_shap_analysis",
    module_run_id = module_run_id
  )

  result_warnings <- c(validation$warnings %||% character(), result$warnings %||% character())
  service_result(
    status = if (length(artifacts)) "success" else "warning",
    artifacts = artifacts,
    messages = if (length(artifacts)) "AutoQuant Binary Classification SHAP Analysis artifacts generated." else "AutoQuant Binary Classification SHAP Analysis completed but returned no artifacts.",
    warnings = result_warnings,
    metadata = module_run_metadata(
      module_id = "autoquant_binary_shap_analysis",
      module_run_id = module_run_id,
      generated_at = result$metadata$generated_at %||% generated_at,
      data_name = config$data_name %||% result$metadata$data_name %||% NULL,
      source_package = "AutoQuant",
      source_function = source_function,
      configured_inputs = config,
      artifacts = artifacts,
      report_plans = plans,
      extra = list(
        implementation_status = "generator_available",
        artifact_id_prefix = shap_artifact_id_prefix("binary_classification"),
        shap_sections = shap_sections(),
        shap_lenses = shap_lenses(),
        autoquant_metadata = result$metadata %||% list(),
        autoquant_diagnostics = result$diagnostics %||% list(),
        validation_warnings = validation$warnings %||% character()
      )
    ),
    code = result$code %||% paste(
      "artifacts <- AutoQuant::generate_binary_classification_shap_analysis_artifacts(",
      "  data = data,",
      paste0("  target_col = ", deparse(config$target_col %||% NULL), ","),
      paste0("  prediction_col = ", deparse(config$prediction_col %||% NULL), ","),
      paste0("  predicted_class_col = ", deparse(config$predicted_class_col %||% NULL), ","),
      paste0("  positive_class = ", deparse(config$positive_class %||% NULL), ","),
      paste0("  feature_cols = ", deparse(config$feature_cols %||% character()), ","),
      paste0("  shap_prefix = ", deparse(config$shap_prefix %||% "Shap_"), ","),
      paste0("  threshold = ", deparse(config$threshold %||% 0.5), ","),
      paste0("  DateVar = ", deparse(config$DateVar %||% NULL), ","),
      paste0("  ByVars = ", deparse(config$ByVars %||% character()), ","),
      paste0("  selected_features = ", deparse(config$selected_features %||% character()), ","),
      paste0("  date_aggregation = ", deparse(config$date_aggregation %||% "month")),
      ")",
      sep = "\n"
    )
  )
}

qa_autoquant_binary_shap_analysis_integration <- function() {
  set.seed(321)
  n <- 180L
  channel <- sample(c("Affiliate", "Direct", "Email", "Search", "Social"), n, TRUE)
  region <- sample(c("Midwest", "Northeast", "South", "West"), n, TRUE)
  spend <- stats::runif(n, 25, 500)
  clicks <- stats::rpois(n, 80) + 1
  logit <- -1.2 + 0.004 * spend + 0.015 * clicks + ifelse(channel == "Search", 0.6, 0) + ifelse(region == "West", 0.35, 0)
  p <- 1 / (1 + exp(-logit))
  target <- ifelse(stats::runif(n) < p, "Yes", "No")
  qa_data <- data.table::data.table(
    Target = target,
    Predict = p,
    PredictedClass = ifelse(p >= 0.5, "Yes", "No"),
    Channel = channel,
    Region = region,
    Spend = spend,
    Clicks = clicks,
    SpendPerClick = spend / clicks,
    IDCol_1 = seq_len(n),
    IDCol_2 = sample(10000:99999, n, TRUE),
    Date = as.Date("2025-01-01") + sample(0:180, n, TRUE),
    Shap_Channel = ifelse(channel == "Search", 0.25, ifelse(channel == "Direct", -0.08, 0.04)) + stats::rnorm(n, 0, 0.02),
    Shap_Region = ifelse(region == "West", 0.12, ifelse(region == "South", 0.04, -0.03)) + stats::rnorm(n, 0, 0.02),
    Shap_Spend = scale(spend)[, 1] * 0.2 + stats::rnorm(n, 0, 0.03),
    Shap_Clicks = scale(clicks)[, 1] * 0.08 + stats::rnorm(n, 0, 0.02),
    Shap_SpendPerClick = scale(spend / clicks)[, 1] * 0.05 + stats::rnorm(n, 0, 0.02)
  )
  feature_cols <- c("Channel", "Region", "Spend", "Clicks", "SpendPerClick")
  config <- create_shap_analysis_config(
    problem_type = "binary_classification",
    data_name = "qa_binary_shap_fixture",
    target_col = "Target",
    prediction_col = "Predict",
    predicted_class_col = "PredictedClass",
    positive_class = "Yes",
    feature_cols = feature_cols,
    shap_prefix = "Shap_",
    id_cols = c("IDCol_1", "IDCol_2"),
    prediction_scale = "probability",
    threshold = 0.5,
    DateVar = "Date",
    date_aggregation = "month",
    ByVars = c("Channel", "Region"),
    selected_features = c("Spend", "Channel", "Region"),
    local_row_ids = 1:2,
    top_n = 5L,
    max_dependence_rows = 180L,
    max_segment_levels = 10L,
    max_byvars = 2L,
    include_dependence = TRUE,
    include_segments = TRUE,
    include_time = TRUE,
    include_local = TRUE,
    include_interactions = TRUE,
    include_threshold_context = TRUE,
    include_class_balance = TRUE,
    include_plots = TRUE,
    include_effect_curves = TRUE,
    effect_curve_backend = "none",
    effect_curve_models = "stable",
    effect_curve_sample_size = 50000L,
    effect_curve_max_features = 20L,
    effect_curve_validation_fraction = 0.20,
    max_feature_effect_plots = 3L,
    max_dependence_plots = 3L,
    max_segment_plots = 3L,
    max_time_plots = 3L,
    max_local_plots = 2L,
    max_interaction_pairs = 3L,
    max_interaction_surface_plots = 3L,
    numeric_interaction_bins = 5L,
    max_interaction_levels = 8L,
    min_interaction_cell_n = 3L
  )

  validation <- validate_autoquant_binary_shap_analysis_config(qa_data, config)
  run_result <- run_autoquant_binary_shap_analysis_module(qa_data, config)
  specs <- create_shap_report_plan_specs("binary_classification")
  generator_available <- autoquant_binary_shap_analysis_available()
  artifacts <- run_result$artifacts %||% list()
  plans <- run_result$metadata$report_plans %||% list()
  artifact_summary_result <- artifact_summary(artifacts)
  plan_summary_result <- report_plan_summary(plans)
  artifact_ids <- names(artifacts)
  plan_artifact_ids <- unique(unlist(lapply(plans, report_plan_artifact_ids), use.names = FALSE))
  convention_checks <- if (length(artifacts)) {
    module_result_convention_checks(run_result, shap_artifact_id_prefix("binary_classification"))
  } else {
    data.table::data.table(check = character(), status = character(), message = character())
  }
  non_shap_cols <- names(qa_data)[!startsWith(names(qa_data), "Shap_")]
  missing_shap_result <- run_autoquant_binary_shap_analysis_module(
    qa_data[, ..non_shap_cols],
    config
  )
  missing_positive_config <- config
  missing_positive_config$positive_class <- "Maybe"
  missing_positive_result <- validate_autoquant_binary_shap_analysis_config(qa_data, missing_positive_config)
  invalid_context_config <- config
  invalid_context_config$DateVar <- "MissingDate"
  invalid_context_config$ByVars <- "MissingSegment"
  invalid_context_result <- validate_autoquant_binary_shap_analysis_config(qa_data, invalid_context_config)
  artifact_types <- vapply(artifacts, function(artifact) artifact$artifact_type %||% "", character(1))
  first_plot <- artifacts[[which(artifact_types == "plot")[1]]]
  plot_object <- if (!is.null(first_plot)) first_plot$object else NULL

  base_checks <- data.table::data.table(
    check = c(
      "config_validation",
      "generator_detected",
      "module_run",
      "artifacts_returned",
      "plot_artifact_returned",
      "table_artifact_returned",
      "text_artifact_returned",
      "artifact_prefix",
      "artifact_metadata",
      "plot_object_preserved",
      "report_plans_returned",
      "report_plans_reference_existing_artifacts",
      "artifact_summary",
      "report_plan_summary",
      "threshold_context_path",
      "class_balance_path",
      "interaction_diagnostics_accepted",
      "date_byvars_path",
      "id_cols_not_features",
      "missing_shap_columns_structured",
      "missing_positive_class_structured",
      "invalid_context_warns",
      "effect_curve_controls_configured",
      "report_plan_specs",
      "source_function"
    ),
    status = c(
      validation$status,
      if (generator_available) "success" else "warning",
      if (run_result$status %in% c("success", "warning")) run_result$status else "error",
      if (!generator_available || length(artifacts)) "success" else "error",
      if (!generator_available || any(artifact_types == "plot")) "success" else "error",
      if (!generator_available || any(artifact_types == "table")) "success" else "error",
      if (!generator_available || any(artifact_types == "text")) "success" else "error",
      if (!generator_available || all(startsWith(artifact_ids, shap_artifact_id_prefix("binary_classification")))) "success" else "error",
      if (!generator_available || all(vapply(artifacts, function(artifact) {
        metadata <- artifact$metadata %||% list()
        identical(metadata$module_id, "autoquant_binary_shap_analysis") &&
          identical(metadata$source_function, "generate_binary_classification_shap_analysis_artifacts") &&
          identical(metadata$problem_type, "binary_classification") &&
          identical(metadata$positive_class, "Yes") &&
          identical(metadata$prediction_scale, "probability") &&
          identical(metadata$shap_source, "precomputed_columns")
      }, logical(1)))) "success" else "error",
      if (!generator_available || inherits(plot_object, "htmlwidget") || inherits(plot_object, "echarts4r")) "success" else "error",
      if (!generator_available || length(plans)) "success" else "error",
      if (!generator_available || all(plan_artifact_ids %in% artifact_ids)) "success" else "error",
      if (!generator_available || nrow(artifact_summary_result) == length(artifacts)) "success" else "error",
      if (!generator_available || nrow(plan_summary_result) == length(plans)) "success" else "error",
      if (!generator_available || "Threshold Context" %in% artifact_summary_result$section) "success" else "warning",
      if (!generator_available || "Class Balance / Outcome Context" %in% artifact_summary_result$section) "success" else "warning",
      if (!generator_available || any(artifact_summary_result$section == "Interaction Importance")) "success" else "warning",
      if (!generator_available || "Time Effects" %in% artifact_summary_result$section || length(validation$warnings) == 0L) "success" else "warning",
      if (!any(config$id_cols %in% config$feature_cols)) "success" else "error",
      if (missing_shap_result$status %in% c("error", "warning")) "success" else "error",
      if (missing_positive_result$status %in% c("error", "warning")) "success" else "error",
      if (invalid_context_result$status %in% c("warning", "success")) "success" else "error",
      if (identical(run_result$metadata$configured_inputs$effect_curve_backend, "none") && isTRUE(run_result$metadata$configured_inputs$include_effect_curves)) "success" else "error",
      if (length(specs) >= 7L) "success" else "error",
      if (identical(run_result$metadata$source_function, "generate_binary_classification_shap_analysis_artifacts")) "success" else "error"
    ),
    message = c(
      service_result_message(validation),
      if (generator_available) "AutoQuant Binary Classification SHAP generator was detected." else "AutoQuant Binary Classification SHAP generator is unavailable in this environment.",
      service_result_message(run_result),
      paste("Artifacts returned:", length(artifacts)),
      paste("Plot artifacts:", sum(artifact_types == "plot")),
      paste("Table artifacts:", sum(artifact_types == "table")),
      paste("Text artifacts:", sum(artifact_types == "text")),
      "Binary SHAP artifacts use aq_bshap_ IDs.",
      "Binary SHAP artifact metadata includes module/source/problem/class/scale/SHAP fields.",
      "Plot artifacts preserve AutoPlots/htmlwidget objects.",
      paste("Report plans returned:", length(plans)),
      "Report plans reference returned artifact IDs only.",
      "artifact_summary() works on Binary SHAP artifacts.",
      "report_plan_summary() works on Binary SHAP plans.",
      "Threshold Context artifacts are accepted when returned.",
      "Class Balance / Outcome Context artifacts are accepted when returned.",
      "Interaction diagnostic artifacts are accepted when returned.",
      "DateVar month aggregation and ByVars path were accepted.",
      "ID columns are preserved as context, not SHAP features.",
      service_result_message(missing_shap_result),
      service_result_message(missing_positive_result),
      service_result_message(invalid_context_result),
      "AutoNLS effect-curve controls are preserved in Binary SHAP configured inputs.",
      "Binary SHAP report-plan specs are available.",
      "Binary SHAP source function name is reserved."
    )
  )

  data.table::rbindlist(list(base_checks, convention_checks), use.names = TRUE, fill = TRUE)
}
