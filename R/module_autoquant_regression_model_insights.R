autoquant_regression_model_insights_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_regression_model_insights_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

autoquant_regression_model_insights_unavailable_result <- function() {
  service_result(
    status = "error",
    errors = "AutoQuant::generate_regression_model_insights_artifacts() was not found. Install/update AutoQuant before running this module.",
    metadata = list(
      error_code = "MODULE_DEPENDENCY_MISSING",
      module_id = "autoquant_regression_model_insights"
    )
  )
}

.autoquant_rmi_selected_value <- function(value) {
  value <- selected_value(value)
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }

  value
}

validate_autoquant_regression_model_insights_config <- function(data, config) {
  if (!autoquant_regression_model_insights_available()) {
    return(autoquant_regression_model_insights_unavailable_result())
  }
  if (is.null(data)) {
    return(service_result(
      status = "error",
      errors = "Upload data before running AutoQuant Regression Model Insights.",
      metadata = list(error_code = "DATA_MISSING", module_id = "autoquant_regression_model_insights")
    ))
  }
  if (is.null(config)) {
    config <- list()
  }
  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "AutoQuant Regression Model Insights config must be a list.",
      metadata = list(error_code = "MODULE_CONFIG_INVALID", module_id = "autoquant_regression_model_insights")
    ))
  }

  errors <- character()
  target <- .autoquant_rmi_selected_value(config$target_column)
  prediction <- .autoquant_rmi_selected_value(config$prediction_column)
  features <- config$feature_columns %||% character()
  segment_vars <- config$segment_vars %||% character()
  by_vars <- config$by_vars %||% character()
  date_var <- .autoquant_rmi_selected_value(config$date_var)
  sample_size <- suppressWarnings(as.integer(config$sample_size %||% 100000L))

  if (is.null(target)) {
    errors <- c(errors, "Select a target column.")
  } else if (!target %in% names(data)) {
    errors <- c(errors, paste("Target column was not found:", target))
  } else if (!is.numeric(data[[target]])) {
    errors <- c(errors, "Target column must be numeric for regression model insights.")
  }

  if (is.null(prediction)) {
    errors <- c(errors, "Select a prediction column.")
  } else if (!prediction %in% names(data)) {
    errors <- c(errors, paste("Prediction column was not found:", prediction))
  } else if (!is.numeric(data[[prediction]])) {
    errors <- c(errors, "Prediction column must be numeric.")
  }

  missing_features <- setdiff(features, names(data))
  if (length(missing_features)) {
    errors <- c(errors, paste("Feature columns were not found:", paste(missing_features, collapse = ", ")))
  }
  missing_segments <- setdiff(segment_vars, names(data))
  if (length(missing_segments)) {
    errors <- c(errors, paste("Segment columns were not found:", paste(missing_segments, collapse = ", ")))
  }
  missing_by <- setdiff(by_vars, names(data))
  if (length(missing_by)) {
    errors <- c(errors, paste("By columns were not found:", paste(missing_by, collapse = ", ")))
  }
  if (!is.null(date_var) && !date_var %in% names(data)) {
    errors <- c(errors, paste("Date column was not found:", date_var))
  }
  if (is.na(sample_size) || sample_size < 1L) {
    errors <- c(errors, "SampleSize must be a positive integer.")
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      value = config,
      metadata = list(error_code = "MODULE_CONFIG_INVALID", module_id = "autoquant_regression_model_insights")
    ))
  }

  service_result(
    status = "success",
    value = config,
    messages = "AutoQuant Regression Model Insights config is valid.",
    metadata = list(
      module_id = "autoquant_regression_model_insights",
      n_rows = nrow(data),
      n_cols = ncol(data)
    )
  )
}

.autoquant_rmi_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_regression_model_insights_", format(timestamp, "%Y%m%d%H%M%S"))
}

.autoquant_rmi_r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }
  deparse(value, width.cutoff = 500L)
}

.autoquant_rmi_vec_code <- function(value) {
  if (is.null(value) || !length(value)) {
    return("NULL")
  }
  paste0("c(", paste(vapply(value, .autoquant_rmi_r_string, character(1)), collapse = ", "), ")")
}

.autoquant_rmi_code <- function(config) {
  paste(
    "model_insights_artifacts <- AutoQuant::generate_regression_model_insights_artifacts(",
    "  ModelObject = NULL,",
    paste0("  Algo = ", .autoquant_rmi_r_string(config$algo %||% "external_predictions"), ","),
    "  TrainData = data,",
    "  TestData = data,",
    paste0("  TargetColumnName = ", .autoquant_rmi_r_string(config$target_column %||% NULL), ","),
    paste0("  PredictionColumnName = ", .autoquant_rmi_r_string(config$prediction_column %||% "Predict"), ","),
    paste0("  FeatureColumnNames = ", .autoquant_rmi_vec_code(config$feature_columns), ","),
    paste0("  SegmentVars = ", .autoquant_rmi_vec_code(config$segment_vars), ","),
    paste0("  ByVars = ", .autoquant_rmi_vec_code(config$by_vars), ","),
    paste0("  DateVar = ", .autoquant_rmi_r_string(config$date_var %||% NULL), ","),
    paste0("  Theme = ", .autoquant_rmi_r_string(config$theme %||% "light")),
    ")",
    "",
    "# Optional AutoQuant-native renderer:",
    "# AutoQuant::RegressionModelInsightsReport(",
    "#   artifacts = model_insights_artifacts,",
    "#   OutputPath = getwd()",
    "# )",
    sep = "\n"
  )
}

.autoquant_rmi_call_args <- function(data, config) {
  args <- list(
    ModelObject = config$model_object %||% NULL,
    Algo = config$algo %||% "external_predictions",
    TrainData = data,
    TestData = data,
    TargetColumnName = config$target_column %||% NULL,
    PredictionColumnName = config$prediction_column %||% "Predict",
    FeatureColumnNames = config$feature_columns %||% NULL,
    SegmentVars = config$segment_vars %||% NULL,
    ByVars = config$by_vars %||% NULL,
    DateVar = config$date_var %||% NULL,
    Theme = config$theme %||% "light",
    GenerateCalibrationPDP = config$generate_calibration_pdp %||% FALSE,
    GenerateUpliftPDP = config$generate_uplift_pdp %||% FALSE,
    GenerateStratifiedEffects = config$generate_stratified_effects %||% FALSE,
    DetectSimpsonsParadox = config$detect_simpsons_paradox %||% FALSE,
    SampleSize = as.integer(config$sample_size %||% 100000L),
    MaxPDPFeatures = as.integer(config$max_pdp_features %||% 10L),
    MaxByLevels = as.integer(config$max_by_levels %||% 10L),
    MaxCategoricalLevels = as.integer(config$max_categorical_levels %||% 25L),
    MaxSegmentLevels = as.integer(config$max_segment_levels %||% 25L),
    ExportPNG = FALSE,
    ExportHTML = FALSE
  )
  allowed <- names(formals(AutoQuant::generate_regression_model_insights_artifacts))
  args[names(args) %in% allowed]
}

.autoquant_rmi_section <- function(path) {
  text <- tolower(paste(path, collapse = " "))
  if (grepl("metadata|audit|readiness|overview|context|extraction|warning", text)) return("Model Overview")
  if (grepl("importance|interaction", text)) return("Global Importance")
  if (grepl("pdp|calibration_by_feature|uplift|stratified|effect", text)) return("Feature Effects")
  if (grepl("evaluation|actual|predicted|prediction|calibration|error_analysis", text)) return("Prediction Diagnostics")
  if (grepl("residual|outlier|top_error", text)) return("Residual Diagnostics")
  if (grepl("segment|stability|feature_qa|diagnostic|qa", text)) return("Feature Diagnostics")
  "Appendix"
}

.autoquant_rmi_slug <- function(value) {
  slug <- tolower(value)
  slug <- gsub("[^a-z0-9]+", "_", slug)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) "artifact" else slug
}

.autoquant_rmi_label <- function(name) {
  clean <- gsub("^tables_?|^widgets_?|^plots_?|^qa_?|^context_?|^texts_?|^narratives_?", "", name)
  clean <- gsub("([a-z])([A-Z])", "\\1 \\2", clean)
  clean <- gsub("[_.]+", " ", clean)
  clean <- trimws(gsub("\\s+", " ", clean))
  if (!nzchar(clean) || grepl("^item [0-9]+$", tolower(clean))) return("Regression Model Insight")
  label <- tools::toTitleCase(clean)
  replacements <- c(
    "Model Metadata" = "Model Overview",
    "Evaluation" = "Model Metrics",
    "Residuals" = "Residual Diagnostics",
    "Importance" = "Variable Importance",
    "Calibration" = "Calibration Plot",
    "Error Analysis" = "Error Analysis",
    "Segment Performance" = "Segment Performance",
    "Feature Qa" = "Feature QA"
  )
  if (label %in% names(replacements)) return(replacements[[label]])
  label <- gsub("\\bPdp\\b", "PDP", label)
  label <- gsub("\\bQa\\b", "QA", label)
  trimws(label)
}

.autoquant_rmi_flatten <- function(x, path = character()) {
  if (is.null(x)) return(list())
  if (inherits(x, "htmlwidget") || data.table::is.data.table(x) || is.data.frame(x) || is.character(x)) {
    return(stats::setNames(list(x), paste(path, collapse = "_")))
  }
  if (!is.list(x)) return(list())
  item_names <- names(x)
  if (is.null(item_names)) item_names <- paste0("item_", seq_along(x))
  parts <- list()
  for (index in seq_along(x)) {
    parts <- c(parts, .autoquant_rmi_flatten(x[[index]], c(path, item_names[[index]])))
  }
  parts
}

.autoquant_rmi_artifact_type <- function(value, root_name) {
  if (data.table::is.data.table(value) || is.data.frame(value)) return("table")
  if (is.character(value)) return("text")
  if (inherits(value, "htmlwidget")) return("plot")
  if (root_name %in% c("plots", "widgets")) return("plot")
  NULL
}

normalize_autoquant_regression_model_insights_artifacts <- function(
  autoquant_result,
  config,
  module_run_id = .autoquant_rmi_run_id(),
  generated_at = Sys.time()
) {
  roots <- c("tables", "widgets", "plots", "qa", "context", "texts", "text", "narratives")
  artifacts <- list()
  used_ids <- character()
  order <- 1L
  for (root in roots) {
    flattened <- .autoquant_rmi_flatten(autoquant_result[[root]], root)
    for (name in names(flattened)) {
      value <- flattened[[name]]
      artifact_type <- .autoquant_rmi_artifact_type(value, root)
      if (is.null(artifact_type)) next
      base_id <- paste("aq_rmi", module_run_id, .autoquant_rmi_slug(name), sep = "_")
      artifact_id <- base_id
      suffix <- 2L
      while (artifact_id %in% used_ids) {
        artifact_id <- paste0(base_id, "_", suffix)
        suffix <- suffix + 1L
      }
      used_ids <- c(used_ids, artifact_id)
      object <- NULL
      content <- NULL
      if (identical(artifact_type, "table")) {
        object <- data.table::as.data.table(value)
      } else if (identical(artifact_type, "text")) {
        content <- paste(value, collapse = "\n\n")
      } else {
        object <- value
      }
      section <- .autoquant_rmi_section(strsplit(name, "_", fixed = TRUE)[[1]])
      label <- .autoquant_rmi_label(name)
      if (tolower(label) %in% c("unnamed", "plot_1", "table_1", "artifact", "regression model insight")) {
        label <- paste(section, "Artifact", order)
      }
      artifacts[[artifact_id]] <- create_artifact(
        artifact_id = artifact_id,
        artifact_type = artifact_type,
        label = label,
        source_module = "autoquant_regression_model_insights",
        object = object,
        content = content,
        config = config,
        code = .autoquant_rmi_code(config),
        metadata = module_artifact_metadata(
          module_id = "autoquant_regression_model_insights",
          module_run_id = module_run_id,
          source_module = "autoquant_regression_model_insights",
          original_name = name,
          original_section = root,
          normalized_section = section,
          artifact_index = order,
          generated_at = generated_at,
          extra = list(
            model_id = config$model_id %||% config$algo %||% "external_predictions",
            source_path = config$source_path %||% NULL,
            train_data_include = config$train_data_include %||% TRUE,
            sample_size = as.integer(config$sample_size %||% 100000L)
          )
        ),
        section = section,
        order = order,
        status = "ready"
      )
      order <- order + 1L
    }
  }
  artifacts
}

.autoquant_rmi_section_order <- function() {
  c(
    "Model Overview",
    "Global Importance",
    "Feature Effects",
    "Prediction Diagnostics",
    "Residual Diagnostics",
    "Feature Diagnostics",
    "Appendix"
  )
}

.autoquant_rmi_select_rows <- function(summary, plan_type) {
  if (identical(plan_type, "full")) return(summary)
  sections <- if (identical(plan_type, "feature_effects")) {
    c("Global Importance", "Feature Effects")
  } else if (identical(plan_type, "diagnostics")) {
    c("Prediction Diagnostics", "Residual Diagnostics", "Feature Diagnostics")
  } else {
    .autoquant_rmi_section_order()
  }
  rows <- summary[section %in% sections]
  rows[, utils::head(.SD[order(order, artifact_id)], 6L), by = section]
}

.autoquant_rmi_create_plan <- function(summary, plan_type, module_run_id, config) {
  selected <- .autoquant_rmi_select_rows(summary, plan_type)
  if (!nrow(selected)) return(NULL)
  labels <- c(
    recommended = "Recommended Regression Model Insights Report",
    full = "Full Regression Model Insights Report",
    feature_effects = "Feature Effects Only",
    diagnostics = "Diagnostics Only"
  )
  sections <- list()
  for (section_title in .autoquant_rmi_section_order()) {
    rows <- selected[section == section_title][order(order, artifact_id)]
    if (!nrow(rows)) next
    section_id <- .autoquant_rmi_slug(section_title)
    sections[[section_id]] <- create_report_plan_section(
      section_id = section_id,
      title = section_title,
      description = paste(labels[[plan_type]], "-", section_title),
      artifact_ids = rows$artifact_id,
      order = length(sections) + 1L
    )
  }
  artifact_ids <- unlist(lapply(sections, function(section) section$artifact_ids), use.names = FALSE)
  create_report_plan(
    plan_id = paste(module_run_id, plan_type, sep = "_"),
    label = labels[[plan_type]],
    source_module = "autoquant_regression_model_insights",
    description = paste(labels[[plan_type]], "generated from AutoQuant regression model insight artifacts."),
    layout_type = "sections",
    cols = 2L,
    sections = sections,
    artifact_ids = artifact_ids,
    rationale = "AutoQuant Regression Model Insights plan generated from standard artifact sections.",
    metadata = list(
      module_id = "autoquant_regression_model_insights",
      module_run_id = module_run_id,
      plan_type = plan_type
    ),
    status = "recommended"
  )
}

build_autoquant_regression_model_insights_report_plans <- function(artifacts, config = list(), module_run_id = NULL) {
  if (is.null(artifacts) || !length(artifacts)) return(list())
  module_run_id <- module_run_id %||% .autoquant_rmi_run_id()
  summary <- artifact_summary(artifacts)
  plans <- list(
    recommended = .autoquant_rmi_create_plan(summary, "recommended", module_run_id, config),
    full = .autoquant_rmi_create_plan(summary, "full", module_run_id, config),
    feature_effects = .autoquant_rmi_create_plan(summary, "feature_effects", module_run_id, config),
    diagnostics = .autoquant_rmi_create_plan(summary, "diagnostics", module_run_id, config)
  )
  plans <- Filter(Negate(is.null), plans)
  names(plans) <- vapply(plans, function(plan) plan$plan_id, character(1))
  plans
}

run_autoquant_regression_model_insights_module <- function(data, config) {
  validation <- validate_autoquant_regression_model_insights_config(data, config)
  if (!identical(validation$status, "success")) {
    validation$code <- .autoquant_rmi_code(config)
    return(validation)
  }
  generated_at <- Sys.time()
  module_run_id <- .autoquant_rmi_run_id(generated_at)
  result <- tryCatch(
    do.call(AutoQuant::generate_regression_model_insights_artifacts, .autoquant_rmi_call_args(data, config)),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant Regression Model Insights failed:", conditionMessage(e)),
        diagnostics = list(condition = e),
        metadata = list(
          error_code = "RUNTIME_ERROR",
          module_id = "autoquant_regression_model_insights",
          module_run_id = module_run_id,
          generated_at = generated_at,
          run_timestamp = generated_at
        )
      )
    }
  )
  if (is.list(result) && identical(result$status, "error")) {
    result$code <- .autoquant_rmi_code(config)
    return(result)
  }
  artifacts <- normalize_autoquant_regression_model_insights_artifacts(result, config, module_run_id, generated_at)
  plans <- build_autoquant_regression_model_insights_report_plans(artifacts, config, module_run_id)
  counts <- module_artifact_counts(artifacts)
  service_result(
    status = "success",
    value = result,
    artifacts = artifacts,
    messages = sprintf(
      "Generated %s regression model insights artifacts: %s plots, %s tables, %s text blocks. Created %s report plan(s).",
      counts$artifact_count,
      counts$plot_count,
      counts$table_count,
      counts$text_count,
      length(plans)
    ),
    metadata = module_run_metadata(
      module_id = "autoquant_regression_model_insights",
      module_run_id = module_run_id,
      generated_at = generated_at,
      data_name = config$data_name %||% NULL,
      source_function = "generate_regression_model_insights_artifacts",
      configured_inputs = list(
        model_id = config$model_id %||% config$algo %||% "external_predictions",
        target_column = config$target_column %||% NULL,
        prediction_column = config$prediction_column %||% NULL,
        feature_columns = config$feature_columns %||% character(),
        segment_vars = config$segment_vars %||% character(),
        by_vars = config$by_vars %||% character(),
        date_var = config$date_var %||% NULL,
        theme = config$theme %||% "light",
        sample_size = as.integer(config$sample_size %||% 100000L)
      ),
      artifacts = artifacts,
      report_plans = plans,
      extra = list(
        model_id = config$model_id %||% config$algo %||% "external_predictions",
        source_path = config$source_path %||% NULL,
        train_data_include = config$train_data_include %||% TRUE,
        sample_size = as.integer(config$sample_size %||% 100000L)
      )
    ),
    code = .autoquant_rmi_code(config)
  )
}

qa_autoquant_regression_model_insights_integration <- function() {
  if (!autoquant_regression_model_insights_available()) {
    return(data.table::data.table(
      check = "dependency",
      status = "warning",
      message = "AutoQuant::generate_regression_model_insights_artifacts() is not available."
    ))
  }
  set.seed(1)
  data <- data.table::data.table(
    y = rnorm(100),
    x1 = rnorm(100),
    x2 = runif(100),
    segment = rep(c("A", "B"), 50L),
    date = as.Date("2024-01-01") + 0:99
  )
  fit <- stats::lm(y ~ x1 + x2, data = data)
  data[["Predict"]] <- as.numeric(stats::predict(fit, newdata = data))
  config <- list(
    algo = "lm",
    target_column = "y",
    prediction_column = "Predict",
    feature_columns = c("x1", "x2"),
    segment_vars = "segment",
    by_vars = "segment",
    date_var = "date",
    theme = "light",
    sample_size = 100L,
    max_pdp_features = 2L,
    generate_calibration_pdp = FALSE,
    generate_uplift_pdp = FALSE,
    generate_stratified_effects = FALSE,
    detect_simpsons_paradox = FALSE
  )
  result <- run_autoquant_regression_model_insights_module(data, config)
  if (!identical(result$status, "success")) {
    return(data.table::data.table(
      check = "run_module",
      status = result$status,
      message = paste(c(result$messages, result$warnings, result$errors), collapse = " ")
    ))
  }
  artifacts <- result$artifacts
  plans <- result$metadata$report_plans %||% list()
  artifact_summary_result <- artifact_summary(artifacts)
  plan_summary_result <- report_plan_summary(plans)
  base_checks <- data.table::data.table(
    check = c("run_module", "artifacts_returned", "report_plans_returned", "artifact_labels", "artifact_sections", "artifact_summary", "report_plan_summary"),
    status = c(
      result$status,
      if (length(artifacts)) "success" else "error",
      if (length(plans)) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$label, character(1))))) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$section, character(1))))) "success" else "error",
      if (nrow(artifact_summary_result) == length(artifacts)) "success" else "error",
      if (nrow(plan_summary_result) == length(plans)) "success" else "error"
    ),
    message = c(
      result$messages,
      paste("Artifacts:", length(artifacts)),
      paste("Report plans:", length(plans)),
      "All artifact labels are non-empty.",
      "All artifact sections are non-empty.",
      paste("Artifact summary rows:", nrow(artifact_summary_result)),
      paste("Report plan summary rows:", nrow(plan_summary_result))
    )
  )
  data.table::rbindlist(
    list(base_checks, module_result_convention_checks(result, "aq_rmi_")),
    use.names = TRUE,
    fill = TRUE
  )
}
