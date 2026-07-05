autoquant_binary_model_insights_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_binary_classification_model_insights_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

autoquant_binary_model_insights_unavailable_result <- function() {
  service_result(
    status = "error",
    errors = "AutoQuant::generate_binary_classification_model_insights_artifacts() was not found. Install/update AutoQuant before running this module.",
    metadata = list(
      error_code = "MODULE_DEPENDENCY_MISSING",
      module_id = "autoquant_binary_model_insights"
    )
  )
}

.autoquant_bmi_expected_args <- function() {
  c(
    "TrainDataInclude", "FeatureColumnNames", "SampleSize", "ModelObject",
    "ModelID", "SourcePath", "OutputPath", "TestData", "PredictionColumnName",
    "TargetColumnName", "PositiveClass", "Threshold", "OptimizeMetric",
    "UtilityTP", "UtilityTN", "UtilityFP", "UtilityFN", "Beta", "Theme"
  )
}

.autoquant_bmi_supported_args <- function() {
  if (!autoquant_binary_model_insights_available()) {
    return(.autoquant_bmi_expected_args())
  }

  fn <- get("generate_binary_classification_model_insights_artifacts", envir = asNamespace("AutoQuant"))
  names(formals(fn))
}

.autoquant_bmi_supports_arg <- function(arg) {
  supported <- .autoquant_bmi_supported_args()
  arg %in% supported || "..." %in% supported
}

.autoquant_bmi_selected_value <- function(value) {
  value <- selected_value(value)
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }

  value
}

.autoquant_bmi_optimize_metrics <- function() {
  c("Utility", "Accuracy", "BalancedAccuracy", "F1", "FBeta", "MatthewsCorrelation", "YoudensJ", "CohenKappa")
}

validate_autoquant_binary_model_insights_config <- function(data, config) {
  if (!autoquant_binary_model_insights_available()) {
    return(autoquant_binary_model_insights_unavailable_result())
  }
  if (is.null(config)) {
    config <- list()
  }
  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "AutoQuant Binary Classification Model Insights config must be a list.",
      metadata = list(error_code = "MODULE_CONFIG_INVALID", module_id = "autoquant_binary_model_insights")
    ))
  }

  errors <- character()
  target <- .autoquant_bmi_selected_value(config$target_column)
  prediction <- .autoquant_bmi_selected_value(config$prediction_column)
  positive_class <- .autoquant_bmi_selected_value(config$positive_class)
  source_path <- .autoquant_bmi_selected_value(config$source_path)
  model_id <- .autoquant_bmi_selected_value(config$model_id)
  features <- config$feature_columns %||% character()
  sample_size <- suppressWarnings(as.integer(config$sample_size %||% 100000L))
  threshold <- suppressWarnings(as.numeric(config$threshold %||% 0.5))
  beta <- suppressWarnings(as.numeric(config$beta %||% 1))
  optimize_metric <- .autoquant_bmi_selected_value(config$optimize_metric) %||% "Utility"
  utilities <- suppressWarnings(as.numeric(c(
    config$utility_tp %||% 1,
    config$utility_tn %||% 0,
    config$utility_fp %||% -1,
    config$utility_fn %||% -5
  )))

  if (is.na(sample_size) || sample_size < 1L) {
    errors <- c(errors, "SampleSize must be a positive integer.")
  }
  if (is.na(threshold) || threshold < 0 || threshold > 1) {
    errors <- c(errors, "Threshold must be between 0 and 1.")
  }
  if (is.na(beta) || beta <= 0) {
    errors <- c(errors, "Beta must be positive.")
  }
  if (length(utilities) != 4L || any(is.na(utilities))) {
    errors <- c(errors, "Utility inputs must be numeric.")
  }
  if (!optimize_metric %in% .autoquant_bmi_optimize_metrics()) {
    errors <- c(errors, paste("OptimizeMetric must be one of:", paste(.autoquant_bmi_optimize_metrics(), collapse = ", ")))
  }
  if (!is.null(source_path) && !dir.exists(source_path)) {
    errors <- c(errors, paste("SourcePath does not exist:", source_path))
  }
  if (!is.null(source_path) && is.null(model_id)) {
    errors <- c(errors, "ModelID is required when SourcePath is supplied.")
  }

  if (is.null(data) && is.null(source_path) && is.null(config$model_object)) {
    errors <- c(errors, "Upload data or provide SourcePath/ModelID before running Binary Model Insights.")
  }

  if (!is.null(data)) {
    if (is.null(target)) {
      errors <- c(errors, "Select a target column.")
    } else if (!target %in% names(data)) {
      errors <- c(errors, paste("Target column was not found:", target))
    } else {
      target_values <- unique(stats::na.omit(data[[target]]))
      if (length(target_values) != 2L) {
        errors <- c(errors, "Target column must contain exactly two non-missing classes.")
      }
      if (!is.null(positive_class) && !positive_class %in% as.character(target_values)) {
        errors <- c(errors, "PositiveClass was not found in the target column.")
      }
    }

    if (is.null(prediction)) {
      errors <- c(errors, "Select a prediction column.")
    } else if (!prediction %in% names(data)) {
      errors <- c(errors, paste("Prediction column was not found:", prediction))
    } else if (!is.numeric(data[[prediction]])) {
      errors <- c(errors, "PredictionColumnName must be numeric.")
    }

    missing_features <- setdiff(features, names(data))
    if (length(missing_features)) {
      errors <- c(errors, paste("Feature columns were not found:", paste(missing_features, collapse = ", ")))
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      value = config,
      metadata = list(error_code = "MODULE_CONFIG_INVALID", module_id = "autoquant_binary_model_insights")
    ))
  }

  service_result(
    status = "success",
    value = config,
    messages = "AutoQuant Binary Classification Model Insights config is valid.",
    metadata = list(
      module_id = "autoquant_binary_model_insights",
      n_rows = if (is.null(data)) NA_integer_ else nrow(data),
      n_cols = if (is.null(data)) NA_integer_ else ncol(data)
    )
  )
}

.autoquant_bmi_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_binary_model_insights_", format(timestamp, "%Y%m%d%H%M%S"))
}

.autoquant_bmi_r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }
  deparse(value, width.cutoff = 500L)
}

.autoquant_bmi_vec_code <- function(value) {
  if (is.null(value) || !length(value)) {
    return("NULL")
  }
  paste0("c(", paste(vapply(value, .autoquant_bmi_r_string, character(1)), collapse = ", "), ")")
}

.autoquant_bmi_code <- function(config) {
  paste(
    "binary_model_insights_artifacts <- AutoQuant::generate_binary_classification_model_insights_artifacts(",
    "  TrainDataInclude = FALSE,",
    paste0("  FeatureColumnNames = ", .autoquant_bmi_vec_code(config$feature_columns), ","),
    paste0("  SampleSize = ", as.integer(config$sample_size %||% 100000L), ","),
    "  ModelObject = NULL,",
    paste0("  ModelID = ", .autoquant_bmi_r_string(config$model_id %||% NULL), ","),
    paste0("  SourcePath = ", .autoquant_bmi_r_string(config$source_path %||% NULL), ","),
    "  TestData = data,",
    paste0("  PredictionColumnName = ", .autoquant_bmi_r_string(config$prediction_column %||% NULL), ","),
    paste0("  TargetColumnName = ", .autoquant_bmi_r_string(config$target_column %||% NULL), ","),
    paste0("  PositiveClass = ", .autoquant_bmi_r_string(config$positive_class %||% NULL), ","),
    paste0("  Threshold = ", as.numeric(config$threshold %||% 0.5), ","),
    paste0("  OptimizeMetric = ", .autoquant_bmi_r_string(config$optimize_metric %||% "Utility"), ","),
    paste0("  UtilityTP = ", as.numeric(config$utility_tp %||% 1), ","),
    paste0("  UtilityTN = ", as.numeric(config$utility_tn %||% 0), ","),
    paste0("  UtilityFP = ", as.numeric(config$utility_fp %||% -1), ","),
    paste0("  UtilityFN = ", as.numeric(config$utility_fn %||% -5), ","),
    paste0("  Beta = ", as.numeric(config$beta %||% 1), ","),
    paste0("  Theme = ", .autoquant_bmi_r_string(config$theme %||% "light")),
    ")",
    "",
    "# Optional AutoQuant-native renderer:",
    "# AutoQuant::BinaryClassificationModelInsightsReport(",
    "#   artifacts = binary_model_insights_artifacts,",
    "#   OutputPath = getwd()",
    "# )",
    sep = "\n"
  )
}

.autoquant_bmi_call_args <- function(data, config) {
  fn <- get("generate_binary_classification_model_insights_artifacts", envir = asNamespace("AutoQuant"))
  allowed <- names(formals(fn))
  supports_dots <- "..." %in% allowed
  args <- list(
    TrainDataInclude = isTRUE(config$train_data_include),
    FeatureColumnNames = config$feature_columns %||% NULL,
    SampleSize = as.integer(config$sample_size %||% 100000L),
    ModelObject = config$model_object %||% NULL,
    ModelID = config$model_id %||% NULL,
    SourcePath = config$source_path %||% NULL,
    OutputPath = config$output_path %||% NULL,
    PredictionColumnName = config$prediction_column %||% NULL,
    TargetColumnName = config$target_column %||% NULL,
    PositiveClass = config$positive_class %||% NULL,
    Threshold = as.numeric(config$threshold %||% 0.5),
    OptimizeMetric = config$optimize_metric %||% "Utility",
    UtilityTP = as.numeric(config$utility_tp %||% 1),
    UtilityTN = as.numeric(config$utility_tn %||% 0),
    UtilityFP = as.numeric(config$utility_fp %||% -1),
    UtilityFN = as.numeric(config$utility_fn %||% -5),
    Beta = as.numeric(config$beta %||% 1),
    Theme = config$theme %||% "light"
  )
  if (!is.null(data)) {
    args$TestData <- data
  }
  if (!supports_dots) {
    args <- args[names(args) %in% allowed]
  }
  args
}

.autoquant_bmi_slug <- function(value) {
  slug <- tolower(value)
  slug <- gsub("[^a-z0-9]+", "_", slug)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) "artifact" else slug
}

.autoquant_bmi_label <- function(name, fallback_type = "Artifact") {
  clean <- gsub("^artifacts_?|^tables_?|^plots_?|^widgets_?|^texts_?|^narratives_?", "", name)
  clean <- gsub("([a-z])([A-Z])", "\\1 \\2", clean)
  clean <- gsub("[_.]+", " ", clean)
  clean <- trimws(gsub("\\s+", " ", clean))
  if (!nzchar(clean) || grepl("^item [0-9]+$", tolower(clean))) {
    return(paste("Binary Model Insights", fallback_type))
  }
  label <- tools::toTitleCase(clean)
  replacements <- c(
    "Model Overview" = "Model Overview",
    "Classification Metrics" = "Classification Metrics",
    "Threshold Metrics" = "Threshold Metrics",
    "Threshold Optimizer" = "Threshold Optimizer",
    "Selected Threshold Summary" = "Selected Threshold Summary",
    "Optimized Confusion Matrix" = "Confusion Matrix",
    "Roc Curve" = "ROC Curve",
    "Precision Recall Curve" = "Precision-Recall Curve",
    "Calibration Plot" = "Calibration Plot",
    "Gains Plot" = "Gains Plot",
    "Lift Plot" = "Lift Plot",
    "Feature Importance Proxy" = "Variable Importance"
  )
  if (label %in% names(replacements)) replacements[[label]] else trimws(label)
}

.autoquant_bmi_section <- function(path, fallback = "Appendix") {
  text <- tolower(paste(path, collapse = " "))
  if (grepl("overview|metadata|model", text)) return("Model Overview")
  if (grepl("classification metric|metric", text)) return("Classification Metrics")
  if (grepl("threshold|confusion", text)) return("Threshold Diagnostics")
  if (grepl("roc|precision|recall|pr", text)) return("ROC / PR Analysis")
  if (grepl("calibration", text)) return("Calibration")
  if (grepl("gain|lift", text)) return("Lift / Gains")
  if (grepl("importance|interaction", text)) return("Global Importance")
  if (grepl("partial|dependence|feature effect", text)) return("Feature Effects")
  fallback %||% "Appendix"
}

.autoquant_bmi_artifact_type <- function(value, declared_type = NULL) {
  if (!is.null(declared_type) && declared_type %in% c("plot", "table", "text")) return(declared_type)
  if (data.table::is.data.table(value) || is.data.frame(value)) return("table")
  if (is.character(value)) return("text")
  if (inherits(value, "htmlwidget")) return("plot")
  NULL
}

.autoquant_bmi_flat_artifacts <- function(autoquant_result) {
  if (!is.null(autoquant_result$artifacts) && is.list(autoquant_result$artifacts)) {
    return(autoquant_result$artifacts)
  }
  list()
}

normalize_autoquant_binary_model_insights_artifacts <- function(
  autoquant_result,
  config,
  module_run_id = .autoquant_bmi_run_id(),
  generated_at = Sys.time()
) {
  raw_artifacts <- .autoquant_bmi_flat_artifacts(autoquant_result)
  artifacts <- list()
  used_ids <- character()
  order <- 1L

  for (raw_name in names(raw_artifacts)) {
    raw <- raw_artifacts[[raw_name]]
    raw_object <- if (is.list(raw) && "object" %in% names(raw)) raw$object else raw
    raw_artifact_name <- if (is.list(raw)) raw$name %||% raw_name else raw_name
    raw_label <- if (is.list(raw)) raw$label %||% NULL else NULL
    raw_type <- if (is.list(raw)) raw$type %||% raw$artifact_type %||% NULL else NULL
    raw_section <- if (is.list(raw)) raw$section %||% NULL else NULL
    artifact_type <- .autoquant_bmi_artifact_type(raw_object, raw_type)
    if (is.null(artifact_type)) {
      next
    }

    base_id <- paste("aq_bmi", module_run_id, .autoquant_bmi_slug(raw_artifact_name), sep = "_")
    artifact_id <- base_id
    suffix <- 2L
    while (artifact_id %in% used_ids) {
      artifact_id <- paste0(base_id, "_", suffix)
      suffix <- suffix + 1L
    }
    used_ids <- c(used_ids, artifact_id)

    label <- raw_label %||% .autoquant_bmi_label(raw_artifact_name, artifact_type)
    section <- raw_section %||% .autoquant_bmi_section(c(raw_name, label))
    if (tolower(label) %in% c("unnamed", "plot_1", "table_1", "artifact", "binary model insights artifact")) {
      label <- paste(section, "Artifact", order)
    }

    object <- NULL
    content <- NULL
    if (identical(artifact_type, "table")) {
      object <- data.table::as.data.table(raw_object)
    } else if (identical(artifact_type, "text")) {
      content <- if (is.character(raw_object)) paste(raw_object, collapse = "\n\n") else paste(utils::capture.output(str(raw_object)), collapse = "\n")
    } else {
      object <- raw_object
    }

    artifacts[[artifact_id]] <- create_artifact(
      artifact_id = artifact_id,
      artifact_type = artifact_type,
      label = label,
      source_module = "autoquant_binary_model_insights",
      object = object,
      content = content,
      config = config,
      code = .autoquant_bmi_code(config),
      metadata = module_artifact_metadata(
        module_id = "autoquant_binary_model_insights",
        module_run_id = module_run_id,
        source_module = "autoquant_binary_model_insights",
        original_name = raw_artifact_name,
        original_section = raw_section %||% section,
        normalized_section = section,
        artifact_index = order,
        generated_at = generated_at,
        extra = list(
          model_id = config$model_id %||% NULL,
          source_path = config$source_path %||% NULL,
          train_data_include = isTRUE(config$train_data_include),
          sample_size = as.integer(config$sample_size %||% 100000L),
          target_column = config$target_column %||% NULL,
          prediction_column = config$prediction_column %||% NULL,
          positive_class = config$positive_class %||% NULL,
          threshold = as.numeric(config$threshold %||% 0.5),
          optimize_metric = config$optimize_metric %||% "Utility",
          timestamp = generated_at,
          autoquant_metadata = if (is.list(raw)) raw$metadata %||% list() else list()
        )
      ),
      section = section,
      order = order,
      status = "ready"
    )
    order <- order + 1L
  }

  artifacts
}

.autoquant_bmi_section_order <- function() {
  c(
    "Model Overview",
    "Classification Metrics",
    "Threshold Diagnostics",
    "ROC / PR Analysis",
    "Calibration",
    "Lift / Gains",
    "Global Importance",
    "Feature Effects",
    "Appendix"
  )
}

.autoquant_bmi_select_rows <- function(summary, plan_type) {
  if (identical(plan_type, "full")) return(summary)
  sections <- if (identical(plan_type, "threshold")) {
    "Threshold Diagnostics"
  } else if (identical(plan_type, "feature_effects")) {
    c("Global Importance", "Feature Effects")
  } else {
    .autoquant_bmi_section_order()
  }
  rows <- summary[section %in% sections]
  rows[, utils::head(.SD[order(order, artifact_id)], 6L), by = section]
}

.autoquant_bmi_create_plan <- function(summary, plan_type, module_run_id, config) {
  selected <- .autoquant_bmi_select_rows(summary, plan_type)
  if (!nrow(selected)) return(NULL)
  labels <- c(
    recommended = "Recommended Binary Classification Model Insights Report",
    full = "Full Binary Classification Model Insights Report",
    threshold = "Threshold Diagnostics Report",
    feature_effects = "Feature Effects Only"
  )
  sections <- list()
  for (section_title in .autoquant_bmi_section_order()) {
    rows <- selected[section == section_title][order(order, artifact_id)]
    if (!nrow(rows)) next
    section_id <- .autoquant_bmi_slug(section_title)
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
    source_module = "autoquant_binary_model_insights",
    description = paste(labels[[plan_type]], "generated from AutoQuant binary classification model insight artifacts."),
    layout_type = "sections",
    cols = 2L,
    sections = sections,
    artifact_ids = artifact_ids,
    rationale = "AutoQuant Binary Classification Model Insights plan generated from standard artifact sections.",
    metadata = list(
      module_id = "autoquant_binary_model_insights",
      module_run_id = module_run_id,
      plan_type = plan_type,
      model_id = config$model_id %||% NULL
    ),
    status = "recommended"
  )
}

build_autoquant_binary_model_insights_report_plans <- function(artifacts, config = list(), module_run_id = NULL) {
  if (is.null(artifacts) || !length(artifacts)) return(list())
  module_run_id <- module_run_id %||% .autoquant_bmi_run_id()
  summary <- artifact_summary(artifacts)
  plans <- list(
    recommended = .autoquant_bmi_create_plan(summary, "recommended", module_run_id, config),
    full = .autoquant_bmi_create_plan(summary, "full", module_run_id, config),
    threshold = .autoquant_bmi_create_plan(summary, "threshold", module_run_id, config),
    feature_effects = .autoquant_bmi_create_plan(summary, "feature_effects", module_run_id, config)
  )
  plans <- Filter(Negate(is.null), plans)
  names(plans) <- vapply(plans, function(plan) plan$plan_id, character(1))
  plans
}

run_autoquant_binary_model_insights_module <- function(data, config) {
  validation <- validate_autoquant_binary_model_insights_config(data, config)
  if (!identical(validation$status, "success")) {
    validation$code <- .autoquant_bmi_code(config)
    return(validation)
  }

  generated_at <- Sys.time()
  module_run_id <- .autoquant_bmi_run_id(generated_at)
  result <- tryCatch(
    do.call(
      get("generate_binary_classification_model_insights_artifacts", envir = asNamespace("AutoQuant")),
      .autoquant_bmi_call_args(data, config)
    ),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant Binary Classification Model Insights failed:", conditionMessage(e)),
        diagnostics = list(condition = e),
        metadata = list(
          error_code = "RUNTIME_ERROR",
          module_id = "autoquant_binary_model_insights",
          module_run_id = module_run_id,
          generated_at = generated_at,
          run_timestamp = generated_at
        )
      )
    }
  )
  if (is.list(result) && identical(result$status, "error")) {
    result$code <- .autoquant_bmi_code(config)
    return(result)
  }

  artifacts <- normalize_autoquant_binary_model_insights_artifacts(result, config, module_run_id, generated_at)
  plans <- build_autoquant_binary_model_insights_report_plans(artifacts, config, module_run_id)
  counts <- module_artifact_counts(artifacts)
  service_result(
    status = "success",
    value = result,
    artifacts = artifacts,
    messages = sprintf(
      "Generated %s binary model insights artifacts: %s plots, %s tables, %s text blocks. Created %s recommended report plan(s).",
      counts$artifact_count,
      counts$plot_count,
      counts$table_count,
      counts$text_count,
      length(plans)
    ),
    metadata = module_run_metadata(
      module_id = "autoquant_binary_model_insights",
      module_run_id = module_run_id,
      generated_at = generated_at,
      data_name = config$model_id %||% NULL,
      source_function = "generate_binary_classification_model_insights_artifacts",
      configured_inputs = list(
        model_id = config$model_id %||% NULL,
        source_path = config$source_path %||% NULL,
        train_data_include = isTRUE(config$train_data_include),
        feature_columns = config$feature_columns %||% character(),
        sample_size = as.integer(config$sample_size %||% 100000L),
        prediction_column = config$prediction_column %||% NULL,
        target_column = config$target_column %||% NULL,
        positive_class = config$positive_class %||% NULL,
        threshold = as.numeric(config$threshold %||% 0.5),
        optimize_metric = config$optimize_metric %||% "Utility",
        theme = config$theme %||% "light"
      ),
      artifacts = artifacts,
      report_plans = plans,
      extra = list(
        model_id = config$model_id %||% NULL,
        source_path = config$source_path %||% NULL,
        train_data_include = isTRUE(config$train_data_include),
        sample_size = as.integer(config$sample_size %||% 100000L)
      )
    ),
    code = .autoquant_bmi_code(config)
  )
}

qa_autoquant_binary_model_insights_integration <- function() {
  if (!autoquant_binary_model_insights_available()) {
    return(data.table::data.table(
      check = "dependency",
      status = "warning",
      message = "AutoQuant::generate_binary_classification_model_insights_artifacts() is not available."
    ))
  }

  set.seed(42)
  data <- data.table::data.table(
    x1 = stats::rnorm(160),
    x2 = stats::runif(160),
    segment = rep(c("A", "B"), 80L)
  )
  logit <- -0.4 + 1.2 * data$x1 - 0.7 * data$x2 + ifelse(data$segment == "A", 0.3, 0)
  prob <- 1 / (1 + exp(-logit))
  data[, target := stats::rbinom(.N, 1L, prob)]
  data[, p1 := pmin(pmax(prob + stats::rnorm(.N, 0, 0.08), 0.001), 0.999)]
  config <- list(
    train_data_include = FALSE,
    feature_columns = c("x1", "x2", "segment"),
    sample_size = 160L,
    model_id = "QA Binary Model",
    prediction_column = "p1",
    target_column = "target",
    positive_class = "1",
    threshold = 0.5,
    optimize_metric = "Utility",
    utility_tp = 1,
    utility_tn = 0,
    utility_fp = -1,
    utility_fn = -5,
    beta = 1,
    theme = "light"
  )
  result <- run_autoquant_binary_model_insights_module(data, config)
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
  labels <- vapply(artifacts, function(artifact) artifact$label, character(1))
  threshold_labels <- c("Threshold Metrics", "Threshold Optimizer", "Selected Threshold Summary", "Confusion Matrix")
  base_checks <- data.table::data.table(
    check = c(
      "run_module",
      "artifacts_returned",
      "report_plans_returned",
      "artifact_labels",
      "artifact_sections",
      "threshold_artifacts",
      "artifact_summary",
      "report_plan_summary"
    ),
    status = c(
      result$status,
      if (length(artifacts)) "success" else "error",
      if (length(plans)) "success" else "error",
      if (all(nzchar(labels))) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$section, character(1))))) "success" else "error",
      if (all(threshold_labels %in% labels)) "success" else "error",
      if (nrow(artifact_summary_result) == length(artifacts)) "success" else "error",
      if (nrow(plan_summary_result) == length(plans)) "success" else "error"
    ),
    message = c(
      result$messages,
      paste("Artifacts:", length(artifacts)),
      paste("Report plans:", length(plans)),
      "All artifact labels are non-empty.",
      "All artifact sections are non-empty.",
      paste("Threshold artifacts present:", paste(intersect(threshold_labels, labels), collapse = ", ")),
      paste("Artifact summary rows:", nrow(artifact_summary_result)),
      paste("Report plan summary rows:", nrow(plan_summary_result))
    )
  )
  data.table::rbindlist(
    list(base_checks, module_result_convention_checks(result, "aq_bmi_")),
    use.names = TRUE,
    fill = TRUE
  )
}
