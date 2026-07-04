autoquant_model_assessment_function_name <- function() {
  candidates <- c(
    "generate_model_assessment_artifacts",
    "generate_autoquant_model_assessment_artifacts",
    "generate_model_assessment_report_artifacts",
    "generate_regression_model_assessment_artifacts",
    "generate_classification_model_assessment_artifacts"
  )

  if (!requireNamespace("AutoQuant", quietly = TRUE)) {
    return(NULL)
  }

  exports <- getNamespaceExports("AutoQuant")
  matches <- candidates[candidates %in% exports]
  if (!length(matches)) {
    return(NULL)
  }

  matches[[1]]
}

autoquant_model_assessment_available <- function() {
  !is.null(autoquant_model_assessment_function_name())
}

autoquant_model_assessment_unavailable_result <- function() {
  service_result(
    status = "error",
    errors = "AutoQuant model assessment artifact generator was not found. Install/update AutoQuant before running this module.",
    metadata = list(
      error_code = "MODULE_DEPENDENCY_MISSING",
      module_id = "autoquant_model_assessment"
    )
  )
}

.autoquant_ma_selected_value <- function(value) {
  value <- selected_value(value)
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }

  value
}

.autoquant_ma_problem_type <- function(config) {
  problem_type <- config$problem_type %||% config$assessment_problem_type %||% "Regression"
  if (tolower(problem_type) %in% c("binary", "binary classification", "classification")) {
    return("Binary Classification")
  }

  "Regression"
}

validate_autoquant_model_assessment_config <- function(data, config) {
  if (!requireNamespace("AutoQuant", quietly = TRUE)) {
    return(autoquant_model_assessment_unavailable_result())
  }

  if (is.null(data)) {
    return(service_result(
      status = "error",
      errors = "Upload data before running AutoQuant Model Assessment.",
      metadata = list(
        error_code = "DATA_MISSING",
        module_id = "autoquant_model_assessment"
      )
    ))
  }

  if (is.null(config)) {
    config <- list()
  }

  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "AutoQuant Model Assessment config must be a list.",
      metadata = list(
        error_code = "MODULE_CONFIG_INVALID",
        module_id = "autoquant_model_assessment"
      )
    ))
  }

  errors <- character()
  problem_type <- .autoquant_ma_problem_type(config)
  actual_var <- .autoquant_ma_selected_value(config$actual_var)
  prediction_var <- .autoquant_ma_selected_value(config$prediction_var)
  predicted_class_var <- .autoquant_ma_selected_value(config$predicted_class_var)
  date_var <- .autoquant_ma_selected_value(config$date_var)
  group_var <- .autoquant_ma_selected_value(config$group_var)

  if (is.null(actual_var)) {
    errors <- c(errors, "Select an actual/target column.")
  } else if (!actual_var %in% names(data)) {
    errors <- c(errors, paste("Actual column was not found:", actual_var))
  }

  if (is.null(prediction_var)) {
    errors <- c(errors, "Select a prediction/probability column.")
  } else if (!prediction_var %in% names(data)) {
    errors <- c(errors, paste("Prediction column was not found:", prediction_var))
  } else if (!is.numeric(data[[prediction_var]])) {
    errors <- c(errors, "prediction_var must be numeric.")
  }

  if (!is.null(predicted_class_var) && !predicted_class_var %in% names(data)) {
    errors <- c(errors, paste("Predicted class column was not found:", predicted_class_var))
  }
  if (!is.null(date_var) && !date_var %in% names(data)) {
    errors <- c(errors, paste("Date column was not found:", date_var))
  }
  if (!is.null(group_var) && !group_var %in% names(data)) {
    errors <- c(errors, paste("Group column was not found:", group_var))
  }

  if (!is.null(actual_var) && actual_var %in% names(data)) {
    if (identical(problem_type, "Regression")) {
      if (!is.numeric(data[[actual_var]])) {
        errors <- c(errors, "For Regression, actual_var must be numeric.")
      }
    } else {
      classes <- unique(stats::na.omit(data[[actual_var]]))
      if (length(classes) < 2L) {
        errors <- c(errors, "For Binary Classification, actual_var must contain at least two classes.")
      }
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      value = config,
      metadata = list(
        error_code = "MODULE_CONFIG_INVALID",
        module_id = "autoquant_model_assessment"
      )
    ))
  }

  if (!autoquant_model_assessment_available()) {
    return(autoquant_model_assessment_unavailable_result())
  }

  service_result(
    status = "success",
    value = config,
    messages = "AutoQuant Model Assessment config is valid.",
    metadata = list(
      module_id = "autoquant_model_assessment",
      problem_type = problem_type,
      n_rows = nrow(data),
      n_cols = ncol(data)
    )
  )
}

.autoquant_ma_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_model_assessment_", format(timestamp, "%Y%m%d%H%M%S"))
}

.autoquant_ma_r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }

  deparse(value, width.cutoff = 500L)
}

.autoquant_ma_code <- function(config, function_name = autoquant_model_assessment_function_name()) {
  function_name <- function_name %||% "generate_model_assessment_artifacts"
  paste(
    paste0("model_assessment_result <- AutoQuant::", function_name, "("),
    "  data = data,",
    paste0("  ProblemType = ", .autoquant_ma_r_string(.autoquant_ma_problem_type(config)), ","),
    paste0("  ActualVar = ", .autoquant_ma_r_string(config$actual_var %||% NULL), ","),
    paste0("  PredictionVar = ", .autoquant_ma_r_string(config$prediction_var %||% NULL), ","),
    paste0("  PredictedClassVar = ", .autoquant_ma_r_string(config$predicted_class_var %||% NULL), ","),
    paste0("  PositiveClass = ", .autoquant_ma_r_string(config$positive_class %||% NULL), ","),
    paste0("  DateVar = ", .autoquant_ma_r_string(config$date_var %||% NULL), ","),
    paste0("  GroupVar = ", .autoquant_ma_r_string(config$group_var %||% NULL), ","),
    paste0("  ModelName = ", .autoquant_ma_r_string(config$model_name %||% "Model"), ","),
    paste0("  Theme = ", .autoquant_ma_r_string(config$theme %||% "light")),
    ")",
    "",
    "# TODO: Add app-side artifact/report-plan conversion when exporting a complete module replay script.",
    sep = "\n"
  )
}

.autoquant_ma_call_args <- function(data, config, function_name) {
  args <- list(
    data = data,
    ProblemType = .autoquant_ma_problem_type(config),
    ActualVar = config$actual_var %||% NULL,
    TargetVar = config$actual_var %||% NULL,
    TargetColumnName = config$actual_var %||% NULL,
    PredictionVar = config$prediction_var %||% NULL,
    PredictionColumnName = config$prediction_var %||% NULL,
    PredictedClassVar = config$predicted_class_var %||% NULL,
    PositiveClass = config$positive_class %||% NULL,
    DateVar = config$date_var %||% NULL,
    DateColumnName = config$date_var %||% NULL,
    GroupVar = config$group_var %||% NULL,
    SegmentVars = config$group_var %||% NULL,
    ModelName = config$model_name %||% "Model",
    Theme = config$theme %||% "light",
    MaxRows = config$max_rows %||% 1000L,
    MaxGroups = config$max_groups %||% 25L
  )

  fn <- get(function_name, envir = asNamespace("AutoQuant"))
  allowed <- names(formals(fn))
  args[names(args) %in% allowed]
}

.autoquant_ma_section <- function(path, config = list()) {
  text <- tolower(paste(path, collapse = " "))
  if (grepl("overview|summary|model", text)) return("Model Overview")
  if (grepl("metric|performance|error|accuracy|auc|rmse|mae|r2", text)) {
    if (identical(.autoquant_ma_problem_type(config), "Binary Classification")) {
      return("Classification Metrics")
    }
    return("Performance Metrics")
  }
  if (grepl("residual", text)) return("Residual Diagnostics")
  if (grepl("prediction|actual|fitted", text)) return("Prediction Diagnostics")
  if (grepl("threshold|confusion", text)) return("Threshold Diagnostics")
  if (grepl("roc|pr|precision|recall", text)) return("ROC / PR Analysis")
  if (grepl("calibration", text)) return("Calibration")
  if (grepl("lift|gain", text)) return("Lift / Gains")
  if (grepl("segment|group|date|time|trend", text)) return("Segment / Time Diagnostics")
  config$artifact_section %||% "Model Assessment"
}

.autoquant_ma_slug <- function(value) {
  slug <- tolower(value)
  slug <- gsub("[^a-z0-9]+", "_", slug)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) "artifact" else slug
}

.autoquant_ma_label <- function(name) {
  clean <- gsub("^tables_?|^plots_?|^texts_?|^narratives_?", "", name)
  clean <- gsub("([a-z])([A-Z])", "\\1 \\2", clean)
  clean <- gsub("[_.]+", " ", clean)
  clean <- gsub("\\s+", " ", clean)
  clean <- trimws(clean)
  if (!nzchar(clean) || grepl("^item [0-9]+$", tolower(clean))) {
    return("Model Assessment Artifact")
  }

  label <- tools::toTitleCase(clean)
  replacements <- c(
    "Roc" = "ROC",
    "Pr" = "PR",
    "Rmse" = "RMSE",
    "Mae" = "MAE",
    "Auc" = "AUC",
    "R2" = "R-squared"
  )
  for (from in names(replacements)) {
    label <- gsub(paste0("\\b", from, "\\b"), replacements[[from]], label)
  }
  trimws(label)
}

.autoquant_ma_flatten <- function(x, path = character()) {
  if (is.null(x)) {
    return(list())
  }

  if (inherits(x, "htmlwidget") || data.table::is.data.table(x) || is.data.frame(x) || is.character(x)) {
    name <- paste(path, collapse = "_")
    return(stats::setNames(list(x), name))
  }

  if (!is.list(x)) {
    return(list())
  }

  parts <- list()
  item_names <- names(x)
  if (is.null(item_names)) {
    item_names <- paste0("item_", seq_along(x))
  }

  for (index in seq_along(x)) {
    parts <- c(parts, .autoquant_ma_flatten(x[[index]], c(path, item_names[[index]])))
  }

  parts
}

.autoquant_ma_artifact_type <- function(value, root_name) {
  if (data.table::is.data.table(value) || is.data.frame(value)) {
    return("table")
  }
  if (is.character(value)) {
    return("text")
  }
  if (inherits(value, "htmlwidget")) {
    return("plot")
  }
  if (identical(root_name, "plots")) {
    return("plot")
  }
  NULL
}

normalize_autoquant_model_assessment_artifacts <- function(
  autoquant_result,
  config,
  module_run_id = .autoquant_ma_run_id(),
  run_timestamp = Sys.time()
) {
  roots <- c("tables", "plots", "texts", "text", "narratives")
  artifacts <- list()
  used_ids <- character()
  order <- 1L

  for (root in roots) {
    flattened <- .autoquant_ma_flatten(autoquant_result[[root]], root)
    for (name in names(flattened)) {
      value <- flattened[[name]]
      artifact_type <- .autoquant_ma_artifact_type(value, root)
      if (is.null(artifact_type)) {
        next
      }

      base_id <- paste("aq_ma", module_run_id, .autoquant_ma_slug(name), sep = "_")
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

      section <- .autoquant_ma_section(strsplit(name, "_", fixed = TRUE)[[1]], config)
      artifacts[[artifact_id]] <- create_artifact(
        artifact_id = artifact_id,
        artifact_type = artifact_type,
        label = .autoquant_ma_label(name),
        source_module = "autoquant_model_assessment",
        object = object,
        content = content,
        config = config,
        code = .autoquant_ma_code(config),
        metadata = list(
          module_id = "autoquant_model_assessment",
          module_run_id = module_run_id,
          run_timestamp = run_timestamp,
          model_name = config$model_name %||% "Model",
          problem_type = .autoquant_ma_problem_type(config),
          actual_var = config$actual_var %||% NULL,
          prediction_var = config$prediction_var %||% NULL,
          original_name = name,
          autoquant_section = root
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

.autoquant_ma_section_order <- function(problem_type) {
  if (identical(problem_type, "Binary Classification")) {
    return(c(
      "Model Overview",
      "Classification Metrics",
      "Threshold Diagnostics",
      "ROC / PR Analysis",
      "Calibration",
      "Lift / Gains",
      "Segment / Time Diagnostics",
      "Appendix"
    ))
  }

  c(
    "Model Overview",
    "Performance Metrics",
    "Prediction Diagnostics",
    "Residual Diagnostics",
    "Segment / Time Diagnostics",
    "Appendix"
  )
}

.autoquant_ma_select_rows <- function(summary, plan_type) {
  if (identical(plan_type, "full")) {
    return(summary)
  }

  diagnostic_sections <- c(
    "Prediction Diagnostics",
    "Residual Diagnostics",
    "Threshold Diagnostics",
    "ROC / PR Analysis",
    "Calibration",
    "Lift / Gains",
    "Segment / Time Diagnostics"
  )

  rows <- if (identical(plan_type, "diagnostics")) {
    summary[section %in% diagnostic_sections]
  } else {
    summary
  }

  rows[, utils::head(.SD[order(order, artifact_id)], 6L), by = section]
}

.autoquant_ma_create_plan <- function(summary, plan_type, module_run_id, config, section_order) {
  selected <- .autoquant_ma_select_rows(summary, plan_type)
  if (!nrow(selected)) {
    return(NULL)
  }

  labels <- c(
    recommended = "Recommended Model Assessment Report",
    full = "Full Model Assessment Report",
    diagnostics = "Diagnostics Only"
  )
  descriptions <- c(
    recommended = "Curated model assessment report grouped by assessment sections.",
    full = "Complete model assessment report containing every generated artifact.",
    diagnostics = "Focused model diagnostics report."
  )

  sections <- list()
  for (section_title in section_order) {
    rows <- selected[section == section_title][order(order, artifact_id)]
    if (!nrow(rows)) {
      next
    }

    section_id <- .autoquant_ma_slug(section_title)
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
    source_module = "autoquant_model_assessment",
    description = descriptions[[plan_type]],
    layout_type = "sections",
    cols = 2L,
    sections = sections,
    artifact_ids = artifact_ids,
    rationale = paste("AutoQuant Model Assessment", plan_type, "plan generated from assessment artifacts."),
    metadata = list(
      module_id = "autoquant_model_assessment",
      module_run_id = module_run_id,
      model_name = config$model_name %||% "Model",
      problem_type = .autoquant_ma_problem_type(config),
      plan_type = plan_type
    ),
    status = "recommended"
  )
}

build_autoquant_model_assessment_report_plans <- function(artifacts, config = list(), module_run_id = NULL) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(list())
  }

  module_run_id <- module_run_id %||% .autoquant_ma_run_id()
  summary <- artifact_summary(artifacts)
  section_order <- .autoquant_ma_section_order(.autoquant_ma_problem_type(config))
  plans <- list(
    recommended = .autoquant_ma_create_plan(summary, "recommended", module_run_id, config, section_order),
    full = .autoquant_ma_create_plan(summary, "full", module_run_id, config, section_order),
    diagnostics = .autoquant_ma_create_plan(summary, "diagnostics", module_run_id, config, section_order)
  )
  plans <- Filter(Negate(is.null), plans)
  names(plans) <- vapply(plans, function(plan) plan$plan_id, character(1))
  plans
}

run_autoquant_model_assessment_module <- function(data, config) {
  validation <- validate_autoquant_model_assessment_config(data, config)
  if (!identical(validation$status, "success")) {
    validation$code <- .autoquant_ma_code(config)
    return(validation)
  }

  run_timestamp <- Sys.time()
  module_run_id <- .autoquant_ma_run_id(run_timestamp)
  function_name <- autoquant_model_assessment_function_name()

  result <- tryCatch(
    do.call(
      get(function_name, envir = asNamespace("AutoQuant")),
      .autoquant_ma_call_args(data, config, function_name)
    ),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant Model Assessment failed:", conditionMessage(e)),
        diagnostics = list(condition = e),
        metadata = list(
          error_code = "RUNTIME_ERROR",
          module_id = "autoquant_model_assessment",
          module_run_id = module_run_id,
          run_timestamp = run_timestamp
        )
      )
    }
  )

  if (is.list(result) && identical(result$status, "error")) {
    result$code <- .autoquant_ma_code(config, function_name)
    return(result)
  }

  artifacts <- normalize_autoquant_model_assessment_artifacts(
    result,
    config,
    module_run_id = module_run_id,
    run_timestamp = run_timestamp
  )
  plans <- build_autoquant_model_assessment_report_plans(artifacts, config, module_run_id = module_run_id)

  artifact_counts <- if (length(artifacts)) {
    table(vapply(artifacts, function(artifact) artifact$artifact_type, character(1)))
  } else {
    integer()
  }
  artifact_count <- function(type) {
    if (type %in% names(artifact_counts)) as.integer(artifact_counts[[type]]) else 0L
  }

  service_result(
    status = "success",
    value = result,
    artifacts = artifacts,
    messages = sprintf(
      "Generated %s model assessment artifacts: %s plots, %s tables, %s text blocks. Created %s report plan(s).",
      length(artifacts),
      artifact_count("plot"),
      artifact_count("table"),
      artifact_count("text"),
      length(plans)
    ),
    metadata = list(
      module_id = "autoquant_model_assessment",
      module_run_id = module_run_id,
      run_timestamp = run_timestamp,
      model_name = config$model_name %||% "Model",
      problem_type = .autoquant_ma_problem_type(config),
      actual_var = config$actual_var %||% NULL,
      prediction_var = config$prediction_var %||% NULL,
      n_artifacts = length(artifacts),
      artifact_counts = list(
        plot = artifact_count("plot"),
        table = artifact_count("table"),
        text = artifact_count("text")
      ),
      n_report_plans = length(plans),
      report_plans = plans
    ),
    code = .autoquant_ma_code(config, function_name)
  )
}

qa_autoquant_model_assessment_integration <- function() {
  binary_data <- data.table::data.table(
    y = rep(c(0L, 1L), 50L),
    p = seq(0.01, 0.99, length.out = 100L),
    predicted_class = as.integer(seq(0.01, 0.99, length.out = 100L) >= 0.5),
    segment = rep(c("A", "B"), each = 50L)
  )
  regression_data <- data.table::data.table(
    y = seq(1, 100),
    yhat = seq(1, 100) + sin(seq(1, 100) / 5),
    segment = rep(c("A", "B"), each = 50L)
  )

  binary_config <- list(
    assessment_problem_type = "Binary Classification",
    actual_var = "y",
    prediction_var = "p",
    predicted_class_var = "predicted_class",
    positive_class = "1",
    group_var = "segment",
    model_name = "QA Binary Model",
    artifact_section = "Model Assessment",
    theme = "light"
  )
  regression_config <- list(
    assessment_problem_type = "Regression",
    actual_var = "y",
    prediction_var = "yhat",
    group_var = "segment",
    model_name = "QA Regression Model",
    artifact_section = "Model Assessment",
    theme = "light"
  )

  binary_result <- run_autoquant_model_assessment_module(binary_data, binary_config)
  regression_validation <- validate_autoquant_model_assessment_config(regression_data, regression_config)

  if (!autoquant_model_assessment_available()) {
    friendly <- identical(binary_result$status, "error") &&
      identical(binary_result$metadata$error_code, "MODULE_DEPENDENCY_MISSING")
    regression_friendly <- identical(regression_validation$status, "error") &&
      identical(regression_validation$metadata$error_code, "MODULE_DEPENDENCY_MISSING")
    return(data.table::data.table(
      check = c("dependency", "friendly_result", "regression_validation"),
      status = c("missing", if (friendly) "success" else "error", if (regression_friendly) "success" else regression_validation$status),
      message = c(
        "AutoQuant model assessment artifact generator is not available.",
        paste(binary_result$errors, collapse = " "),
        paste(c(regression_validation$messages, regression_validation$errors), collapse = " ")
      )
    ))
  }

  artifacts <- binary_result$artifacts
  plans <- binary_result$metadata$report_plans %||% list()
  artifact_summary_result <- artifact_summary(artifacts)
  plan_summary_result <- report_plan_summary(plans)

  data.table::data.table(
    check = c(
      "binary_run",
      "regression_validation",
      "artifacts_returned",
      "report_plans_returned",
      "artifact_labels",
      "artifact_sections",
      "artifact_summary",
      "report_plan_summary"
    ),
    status = c(
      binary_result$status,
      regression_validation$status,
      if (length(artifacts)) "success" else "error",
      if (length(plans)) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$label, character(1))))) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$section, character(1))))) "success" else "error",
      if (nrow(artifact_summary_result) == length(artifacts)) "success" else "error",
      if (nrow(plan_summary_result) == length(plans)) "success" else "error"
    ),
    message = c(
      paste(c(binary_result$messages, binary_result$warnings, binary_result$errors), collapse = " "),
      paste(c(regression_validation$messages, regression_validation$errors), collapse = " "),
      paste("Artifacts:", length(artifacts)),
      paste("Report plans:", length(plans)),
      "All artifact labels are non-empty.",
      "All artifact sections are non-empty.",
      paste("Artifact summary rows:", nrow(artifact_summary_result)),
      paste("Report plan summary rows:", nrow(plan_summary_result))
    )
  )
}
