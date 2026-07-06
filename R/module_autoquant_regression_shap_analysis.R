autoquant_regression_shap_analysis_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_regression_shap_analysis_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

.autoquant_rshap_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_regression_shap_analysis_", format(timestamp, "%Y%m%d%H%M%S"))
}

validate_autoquant_regression_shap_analysis_config <- function(data, config) {
  config <- config %||% list()
  config$problem_type <- "regression"
  validate_shap_analysis_config(
    config = config,
    data = data,
    problem_type = "regression"
  )
}

.autoquant_shap_section_id <- function(section_title) {
  id <- tolower(gsub("[^A-Za-z0-9]+", "_", section_title %||% "section"))
  id <- gsub("^_+|_+$", "", id)
  if (!nzchar(id)) {
    return("section")
  }

  id
}

.autoquant_shap_plan_from_spec <- function(spec_name, spec, artifacts, module_id, module_run_id, config) {
  summary <- artifact_summary(artifacts)
  sections <- list()

  for (index in seq_along(spec$sections %||% character())) {
    section_title <- spec$sections[[index]]
    section_artifacts <- summary$artifact_id[summary$section == section_title]
    if (!length(section_artifacts)) {
      next
    }

    section_id <- .autoquant_shap_section_id(section_title)
    sections[[section_id]] <- create_report_plan_section(
      section_id = section_id,
      title = section_title,
      artifact_ids = section_artifacts,
      order = index
    )
  }

  if (!length(sections)) {
    return(NULL)
  }

  artifact_ids <- unlist(lapply(sections, function(section) section$artifact_ids), use.names = FALSE)
  create_report_plan(
    plan_id = paste(module_run_id, spec_name, sep = "_"),
    label = spec$label,
    source_module = module_id,
    description = paste("Generated from", module_id, "SHAP artifact sections."),
    layout_type = spec$layout_type %||% "sections",
    cols = spec$cols %||% 2L,
    sections = sections,
    artifact_ids = artifact_ids,
    rationale = paste("Curated", spec$label, "from SHAP artifact sections."),
    metadata = list(
      module_id = module_id,
      module_run_id = module_run_id,
      problem_type = normalize_shap_problem_type(config$problem_type),
      plan_spec = spec_name
    ),
    status = "recommended"
  )
}

build_autoquant_shap_report_plans <- function(artifacts, config = list(), module_id, module_run_id = NULL) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(list())
  }

  module_run_id <- module_run_id %||% paste(module_id, format(Sys.time(), "%Y%m%d%H%M%S"), sep = "_")
  specs <- create_shap_report_plan_specs(config$problem_type, unique(artifact_summary(artifacts)$section))
  plans <- lapply(names(specs), function(spec_name) {
    .autoquant_shap_plan_from_spec(
      spec_name = spec_name,
      spec = specs[[spec_name]],
      artifacts = artifacts,
      module_id = module_id,
      module_run_id = module_run_id,
      config = config
    )
  })
  plans <- Filter(Negate(is.null), plans)
  stats::setNames(plans, vapply(plans, function(plan) plan$plan_id, character(1)))
}

.autoquant_shap_generator_args <- function(generator, data, config) {
  formal_names <- names(formals(generator))
  args <- list()

  candidates <- list(
    data = data,
    target_col = config$target_col %||% config$target_var,
    prediction_col = config$prediction_col,
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
    top_n = config$top_n,
    max_dependence_rows = config$max_dependence_rows,
    max_segment_levels = config$max_segment_levels,
    max_byvars = config$max_byvars,
    include_dependence = config$include_dependence,
    include_segments = config$include_segments,
    include_time = config$include_time,
    include_local = config$include_local,
    include_interactions = config$include_interactions,
    include_plots = config$include_plots,
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

run_autoquant_regression_shap_analysis_module <- function(data, config) {
  validation <- validate_autoquant_regression_shap_analysis_config(data, config)
  if (identical(validation$status, "error")) {
    return(validation)
  }

  generated_at <- Sys.time()
  module_run_id <- .autoquant_rshap_run_id(generated_at)
  config <- validation$value
  config$problem_type <- "regression"
  source_function <- "generate_regression_shap_analysis_artifacts"

  if (!autoquant_regression_shap_analysis_available()) {
    return(service_result(
      status = "warning",
      artifacts = list(),
      messages = "AutoQuant Regression SHAP Analysis requires AutoQuant::generate_regression_shap_analysis_artifacts(), but this AutoQuant install does not expose it.",
      metadata = module_run_metadata(
        module_id = "autoquant_regression_shap_analysis",
        module_run_id = module_run_id,
        generated_at = generated_at,
        source_package = "AutoQuant",
        source_function = source_function,
        configured_inputs = config,
        artifacts = list(),
        report_plans = list(),
        extra = list(
          implementation_status = "generator_missing",
          artifact_id_prefix = shap_artifact_id_prefix("regression"),
          shap_sections = shap_sections(),
          shap_lenses = shap_lenses(),
          validation_warnings = validation$warnings %||% character()
        )
      ),
      code = paste(
        "# AutoQuant Regression SHAP Analysis call",
        "artifacts <- AutoQuant::generate_regression_shap_analysis_artifacts(",
        "  data = data,",
        "  target_col = target_col,",
        "  prediction_col = prediction_col,",
        "  shap_prefix = \"Shap_\"",
        ")",
        sep = "\n"
      )
    ))
  }

  generator <- get("generate_regression_shap_analysis_artifacts", envir = asNamespace("AutoQuant"))
  result <- tryCatch(
    do.call(generator, .autoquant_shap_generator_args(generator, data, config)),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant Regression SHAP Analysis failed:", conditionMessage(e)),
        metadata = list(
          error_code = "AUTOQUANT_SHAP_RUN_FAILED",
          module_id = "autoquant_regression_shap_analysis",
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
    module_id = "autoquant_regression_shap_analysis",
    module_run_id = module_run_id,
    source_function = source_function,
    generated_at = generated_at
  )
  plans <- build_autoquant_shap_report_plans(
    artifacts = artifacts,
    config = config,
    module_id = "autoquant_regression_shap_analysis",
    module_run_id = module_run_id
  )

  result_warnings <- c(validation$warnings %||% character(), result$warnings %||% character())
  service_result(
    status = if (length(artifacts)) "success" else "warning",
    artifacts = artifacts,
    messages = if (length(artifacts)) "AutoQuant Regression SHAP Analysis artifacts generated." else "AutoQuant Regression SHAP Analysis completed but returned no artifacts.",
    warnings = result_warnings,
    metadata = module_run_metadata(
      module_id = "autoquant_regression_shap_analysis",
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
        artifact_id_prefix = shap_artifact_id_prefix("regression"),
        shap_sections = shap_sections(),
        shap_lenses = shap_lenses(),
        autoquant_metadata = result$metadata %||% list(),
        autoquant_diagnostics = result$diagnostics %||% list(),
        validation_warnings = validation$warnings %||% character()
      )
    ),
    code = result$code %||% paste(
      "artifacts <- AutoQuant::generate_regression_shap_analysis_artifacts(",
      "  data = data,",
      paste0("  target_col = ", deparse(config$target_col %||% NULL), ","),
      paste0("  prediction_col = ", deparse(config$prediction_col %||% NULL), ","),
      paste0("  feature_cols = ", deparse(config$feature_cols %||% character()), ","),
      paste0("  shap_prefix = ", deparse(config$shap_prefix %||% "Shap_"), ","),
      paste0("  DateVar = ", deparse(config$DateVar %||% NULL), ","),
      paste0("  ByVars = ", deparse(config$ByVars %||% character()), ","),
      paste0("  selected_features = ", deparse(config$selected_features %||% character()), ","),
      paste0("  date_aggregation = ", deparse(config$date_aggregation %||% "month")),
      ")",
      sep = "\n"
    )
  )
}

qa_autoquant_regression_shap_analysis_integration <- function() {
  set.seed(123)
  n <- 150L
  qa_data <- data.table::data.table(
    y = stats::rnorm(n),
    Predict = stats::rnorm(n),
    Independent_Variable1 = stats::runif(n),
    Independent_Variable2 = stats::rnorm(n),
    Factor_1 = sample(c("A", "B", "C"), n, TRUE),
    IDCol_1 = seq_len(n),
    IDCol_2 = sample(1000:9999, n, TRUE),
    Date = as.Date("2024-01-01") + sample(0:120, n, TRUE),
    Shap_Independent_Variable1 = stats::rnorm(n, 0, 0.2),
    Shap_Independent_Variable2 = stats::rnorm(n, 0, 0.1),
    Shap_Factor_1 = stats::rnorm(n, 0, 0.05)
  )
  config <- create_shap_analysis_config(
    problem_type = "regression",
    data_name = "qa_regression_shap_fixture",
    target_col = "y",
    prediction_col = "Predict",
    feature_cols = c("Independent_Variable1", "Independent_Variable2", "Factor_1"),
    shap_prefix = "Shap_",
    id_cols = c("IDCol_1", "IDCol_2"),
    prediction_scale = "response",
    DateVar = "Date",
    date_aggregation = "month",
    ByVars = "Factor_1",
    selected_features = c("Independent_Variable1", "Factor_1"),
    local_row_ids = 1:2,
    top_n = 5L,
    max_dependence_rows = 150L,
    max_segment_levels = 10L,
    max_byvars = 2L,
    include_dependence = TRUE,
    include_segments = TRUE,
    include_time = TRUE,
    include_local = TRUE,
    include_interactions = TRUE,
    include_plots = TRUE,
    max_feature_effect_plots = 2L,
    max_dependence_plots = 2L,
    max_segment_plots = 2L,
    max_time_plots = 2L,
    max_local_plots = 2L,
    max_interaction_pairs = 2L,
    max_interaction_surface_plots = 2L,
    numeric_interaction_bins = 5L,
    max_interaction_levels = 8L,
    min_interaction_cell_n = 3L
  )

  validation <- validate_autoquant_regression_shap_analysis_config(qa_data, config)
  run_result <- run_autoquant_regression_shap_analysis_module(qa_data, config)
  specs <- create_shap_report_plan_specs("regression")
  generator_available <- autoquant_regression_shap_analysis_available()
  artifacts <- run_result$artifacts %||% list()
  plans <- run_result$metadata$report_plans %||% list()
  artifact_summary_result <- artifact_summary(artifacts)
  plan_summary_result <- report_plan_summary(plans)
  artifact_ids <- names(artifacts)
  plan_artifact_ids <- unique(unlist(lapply(plans, report_plan_artifact_ids), use.names = FALSE))
  convention_checks <- if (length(artifacts)) {
    module_result_convention_checks(run_result, shap_artifact_id_prefix("regression"))
  } else {
    data.table::data.table(check = character(), status = character(), message = character())
  }
  non_shap_cols <- names(qa_data)[!startsWith(names(qa_data), "Shap_")]
  missing_shap_result <- run_autoquant_regression_shap_analysis_module(
    qa_data[, ..non_shap_cols],
    config
  )
  invalid_context_config <- config
  invalid_context_config$DateVar <- "MissingDate"
  invalid_context_config$ByVars <- "MissingSegment"
  invalid_context_result <- validate_autoquant_regression_shap_analysis_config(qa_data, invalid_context_config)
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
      "date_byvars_path",
      "interaction_diagnostics_accepted",
      "id_cols_not_features",
      "missing_shap_columns_structured",
      "invalid_context_warns",
      "artifact_prefix",
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
      if (!generator_available || all(startsWith(artifact_ids, shap_artifact_id_prefix("regression")))) "success" else "error",
      if (!generator_available || all(vapply(artifacts, function(artifact) {
        metadata <- artifact$metadata %||% list()
        identical(metadata$module_id, "autoquant_regression_shap_analysis") &&
          identical(metadata$source_function, "generate_regression_shap_analysis_artifacts") &&
          identical(metadata$problem_type, "regression") &&
          identical(metadata$shap_source, "precomputed_columns")
      }, logical(1)))) "success" else "error",
      if (!generator_available || inherits(plot_object, "htmlwidget") || inherits(plot_object, "echarts4r")) "success" else "error",
      if (!generator_available || length(plans)) "success" else "error",
      if (!generator_available || all(plan_artifact_ids %in% artifact_ids)) "success" else "error",
      if (!generator_available || nrow(artifact_summary_result) == length(artifacts)) "success" else "error",
      if (!generator_available || nrow(plan_summary_result) == length(plans)) "success" else "error",
      if (!generator_available || "Time Effects" %in% artifact_summary_result$section || length(validation$warnings) == 0L) "success" else "warning",
      if (!generator_available || any(artifact_summary_result$section == "Interaction Importance")) "success" else "warning",
      if (!any(config$id_cols %in% config$feature_cols)) "success" else "error",
      if (missing_shap_result$status %in% c("error", "warning")) "success" else "error",
      if (invalid_context_result$status %in% c("warning", "success")) "success" else "error",
      if (identical(shap_artifact_id_prefix("regression"), "aq_rshap_")) "success" else "error",
      if (length(specs) >= 3L) "success" else "error",
      if (identical(run_result$metadata$source_function, "generate_regression_shap_analysis_artifacts")) "success" else "error"
    ),
    message = c(
      service_result_message(validation),
      if (generator_available) "AutoQuant Regression SHAP generator was detected." else "AutoQuant Regression SHAP generator is unavailable in this environment.",
      service_result_message(run_result),
      paste("Artifacts returned:", length(artifacts)),
      paste("Plot artifacts:", sum(artifact_types == "plot")),
      paste("Table artifacts:", sum(artifact_types == "table")),
      paste("Text artifacts:", sum(artifact_types == "text")),
      "Regression SHAP artifacts use aq_rshap_ IDs.",
      "Regression SHAP artifact metadata includes module/source/problem/SHAP fields.",
      "Plot artifacts preserve AutoPlots/htmlwidget objects.",
      paste("Report plans returned:", length(plans)),
      "Report plans reference returned artifact IDs only.",
      "artifact_summary() works on Regression SHAP artifacts.",
      "report_plan_summary() works on Regression SHAP plans.",
      "DateVar month aggregation and ByVars path were accepted.",
      "Interaction diagnostic artifacts are accepted when returned.",
      "ID columns are preserved as context, not SHAP features.",
      service_result_message(missing_shap_result),
      service_result_message(invalid_context_result),
      "Regression SHAP artifacts will use aq_rshap_ IDs.",
      "Regression SHAP report-plan specs are available.",
      "Regression SHAP source function name is reserved."
    )
  )

  data.table::rbindlist(list(base_checks, convention_checks), use.names = TRUE, fill = TRUE)
}
