feature_preparation_module_id <- function() {
  "feature_engineering_model_prep"
}

feature_preparation_run_id <- function(timestamp = Sys.time()) {
  paste0("feature_prep_", format(timestamp, "%Y%m%d%H%M%S"))
}

feature_prep_clean_choices <- function(value) {
  value <- as.character(value %||% character())
  unique(value[!is.na(value) & nzchar(value)])
}

feature_prep_scalar_choice <- function(value) {
  value <- feature_prep_clean_choices(value)
  if (length(value)) value[[1]] else ""
}

feature_prep_schema_summary <- function(data) {
  dt <- data.table::as.data.table(data)
  data.table::data.table(
    column = names(dt),
    class = vapply(dt, function(x) paste(class(x), collapse = "/"), character(1)),
    missing = vapply(dt, function(x) sum(is.na(x)), integer(1)),
    missing_pct = round(vapply(dt, function(x) mean(is.na(x)), numeric(1)) * 100, 2),
    unique_values = vapply(dt, function(x) data.table::uniqueN(x, na.rm = TRUE), integer(1))
  )
}

feature_prep_mode <- function(x) {
  values <- x[!is.na(x)]
  if (!length(values)) {
    return(NA)
  }
  tab <- sort(table(values), decreasing = TRUE)
  names(tab)[[1]]
}

feature_prep_duplicate_columns <- function(data) {
  dt <- data.table::as.data.table(data)
  columns <- names(dt)
  duplicates <- character()
  if (length(columns) < 2L) {
    return(duplicates)
  }
  signatures <- vapply(columns, function(column) {
    paste0(utils::capture.output(str(dt[[column]])), collapse = "|")
  }, character(1))
  for (i in seq_along(columns)) {
    if (columns[[i]] %in% duplicates) next
    for (j in seq_len(i - 1L)) {
      if (j < 1L) next
      if (identical(signatures[[i]], signatures[[j]]) &&
          identical(dt[[columns[[i]]]], dt[[columns[[j]]]])) {
        duplicates <- c(duplicates, columns[[i]])
        break
      }
    }
  }
  unique(duplicates)
}

feature_prep_near_zero_variance_columns <- function(data, threshold = 0.95) {
  dt <- data.table::as.data.table(data)
  columns <- names(dt)
  columns[vapply(columns, function(column) {
    x <- dt[[column]]
    if (!is.numeric(x) && !is.integer(x)) {
      return(FALSE)
    }
    usable <- x[!is.na(x)]
    if (!length(usable)) {
      return(TRUE)
    }
    tab <- sort(table(usable), decreasing = TRUE)
    as.numeric(tab[[1]]) / length(usable) >= threshold
  }, logical(1))]
}

feature_prep_default_config <- function(data = NULL) {
  choices <- names(data %||% data.frame())
  numeric_choices <- if (is.null(data)) character() else choices[vapply(data, is.numeric, logical(1))]
  context <- if (exists("analysis_context_from_data", mode = "function")) {
    analysis_context_from_data(data)
  } else {
    list(target = NA_character_, date = NA_character_, group = NA_character_, features = choices)
  }
  list(
    include_columns = choices,
    exclude_columns = character(),
    target_col = feature_prep_scalar_choice(context$target %||% character()),
    date_col = feature_prep_scalar_choice(context$date %||% character()),
    group_cols = feature_prep_clean_choices(context$group %||% character()),
    missing_method = "median_mode",
    drop_constant = TRUE,
    drop_near_zero_variance = TRUE,
    near_zero_variance_threshold = 0.95,
    drop_duplicate_columns = TRUE,
    add_date_features = TRUE,
    categorical_as_factor = TRUE,
    create_validation_split = FALSE,
    validation_fraction = 0.20,
    split_seed = 20260711L,
    prepared_data_name = "Prepared Modeling Data",
    numeric_columns = numeric_choices
  )
}

validate_feature_preparation_config <- function(data, config = list()) {
  module_id <- feature_preparation_module_id()
  if (is.null(data)) {
    return(service_result(
      status = "error",
      errors = "Load data before preparing modeling features.",
      metadata = list(error_code = "DATA_MISSING", module_id = module_id)
    ))
  }
  if (!is.data.frame(data)) {
    return(service_result(
      status = "error",
      errors = "Feature preparation requires a data.frame or data.table.",
      metadata = list(error_code = "DATA_INVALID", module_id = module_id)
    ))
  }
  if (nrow(data) < 1L || ncol(data) < 1L) {
    return(service_result(
      status = "error",
      errors = "Feature preparation requires at least one row and one column.",
      metadata = list(error_code = "DATA_EMPTY", module_id = module_id)
    ))
  }
  config <- modifyList(feature_prep_default_config(data), config %||% list())
  include_columns <- feature_prep_clean_choices(config$include_columns)
  exclude_columns <- feature_prep_clean_choices(config$exclude_columns)
  config$target_col <- feature_prep_scalar_choice(config$target_col)
  config$date_col <- feature_prep_scalar_choice(config$date_col)
  config$group_cols <- feature_prep_clean_choices(config$group_cols)
  selected_columns <- if (length(include_columns)) include_columns else names(data)
  missing_columns <- setdiff(unique(c(selected_columns, exclude_columns, config$target_col, config$date_col, config$group_cols)), c(names(data), "", NA))
  if (length(missing_columns)) {
    return(service_result(
      status = "error",
      errors = paste("Selected preparation columns are missing:", paste(missing_columns, collapse = ", ")),
      metadata = list(error_code = "COLUMN_MISSING", module_id = module_id, missing_columns = missing_columns)
    ))
  }
  selected_after_exclusion <- setdiff(selected_columns, exclude_columns)
  if (!length(selected_after_exclusion)) {
    return(service_result(
      status = "error",
      errors = "Column selection removes every column. Keep at least one column.",
      metadata = list(error_code = "NO_COLUMNS_SELECTED", module_id = module_id)
    ))
  }
  if (!config$missing_method %in% c("none", "median_mode", "zero_unknown", "drop_rows")) {
    return(service_result(
      status = "error",
      errors = "Missing value handling must be one of: none, median_mode, zero_unknown, drop_rows.",
      metadata = list(error_code = "INVALID_MISSING_METHOD", module_id = module_id)
    ))
  }
  threshold <- suppressWarnings(as.numeric(config$near_zero_variance_threshold %||% 0.95))
  if (is.na(threshold) || threshold <= 0 || threshold > 1) {
    return(service_result(
      status = "error",
      errors = "Near-zero variance threshold must be greater than 0 and less than or equal to 1.",
      metadata = list(error_code = "INVALID_NZV_THRESHOLD", module_id = module_id)
    ))
  }
  validation_fraction <- suppressWarnings(as.numeric(config$validation_fraction %||% 0.20))
  if (isTRUE(config$create_validation_split) && (is.na(validation_fraction) || validation_fraction <= 0 || validation_fraction >= 1)) {
    return(service_result(
      status = "error",
      errors = "Validation fraction must be greater than 0 and less than 1.",
      metadata = list(error_code = "INVALID_VALIDATION_FRACTION", module_id = module_id)
    ))
  }

  config$include_columns <- selected_columns
  config$exclude_columns <- exclude_columns
  config$selected_columns <- selected_after_exclusion
  config$near_zero_variance_threshold <- threshold
  config$validation_fraction <- validation_fraction

  service_result(
    status = "success",
    value = config,
    messages = "Feature preparation config is valid.",
    metadata = list(module_id = module_id, n_rows = nrow(data), n_cols = ncol(data))
  )
}

run_feature_preparation_pipeline <- function(data, config = list()) {
  validation <- validate_feature_preparation_config(data, config)
  if (!identical(validation$status, "success")) {
    return(validation)
  }
  config <- validation$value
  timestamp <- Sys.time()
  module_id <- feature_preparation_module_id()
  run_id <- feature_preparation_run_id(timestamp)
  input_dt <- data.table::as.data.table(data)
  before_schema <- feature_prep_schema_summary(input_dt)
  prepared <- data.table::copy(input_dt[, config$selected_columns, with = FALSE])
  steps <- list()
  add_step <- function(step, details, columns = character(), rows_before = nrow(prepared), rows_after = nrow(prepared)) {
    steps[[length(steps) + 1L]] <<- data.table::data.table(
      order = length(steps) + 1L,
      step = step,
      details = details,
      columns = paste(columns, collapse = ", "),
      rows_before = rows_before,
      rows_after = rows_after
    )
  }

  add_step("column_selection", paste("Selected", length(config$selected_columns), "column(s)."), config$selected_columns)
  if (length(config$exclude_columns)) {
    add_step("column_exclusion", paste("Excluded", length(config$exclude_columns), "column(s)."), config$exclude_columns)
  }

  if (identical(config$missing_method, "drop_rows")) {
    before <- nrow(prepared)
    prepared <- stats::na.omit(prepared)
    add_step("missing_drop_rows", paste("Dropped", before - nrow(prepared), "row(s) with missing values."), rows_before = before, rows_after = nrow(prepared))
  } else if (identical(config$missing_method, "median_mode")) {
    changed <- character()
    for (column in names(prepared)) {
      missing <- is.na(prepared[[column]])
      if (!any(missing)) next
      if (is.numeric(prepared[[column]]) || is.integer(prepared[[column]])) {
        replacement <- stats::median(prepared[[column]], na.rm = TRUE)
      } else {
        replacement <- feature_prep_mode(prepared[[column]])
      }
      if (!is.na(replacement)) {
        data.table::set(prepared, which(missing), column, replacement)
        changed <- c(changed, column)
      }
    }
    if (length(changed)) {
      add_step("missing_median_mode", "Filled missing numeric values with medians and categorical values with modes.", changed)
    }
  } else if (identical(config$missing_method, "zero_unknown")) {
    changed <- character()
    for (column in names(prepared)) {
      missing <- is.na(prepared[[column]])
      if (!any(missing)) next
      replacement <- if (is.numeric(prepared[[column]]) || is.integer(prepared[[column]])) 0 else "Unknown"
      data.table::set(prepared, which(missing), column, replacement)
      changed <- c(changed, column)
    }
    if (length(changed)) {
      add_step("missing_zero_unknown", "Filled missing numeric values with zero and categorical values with Unknown.", changed)
    }
  }

  constant_columns <- names(prepared)[vapply(prepared, function(x) data.table::uniqueN(x, na.rm = FALSE) <= 1L, logical(1))]
  if (isTRUE(config$drop_constant) && length(constant_columns)) {
    prepared[, (constant_columns) := NULL]
    add_step("drop_constant_columns", paste("Dropped", length(constant_columns), "constant column(s)."), constant_columns)
  }

  nzv_columns <- feature_prep_near_zero_variance_columns(prepared, config$near_zero_variance_threshold)
  protected <- feature_prep_clean_choices(c(config$target_col, config$date_col, config$group_cols))
  nzv_columns <- setdiff(nzv_columns, protected)
  if (isTRUE(config$drop_near_zero_variance) && length(nzv_columns)) {
    prepared[, (nzv_columns) := NULL]
    add_step("drop_near_zero_variance_columns", paste("Dropped", length(nzv_columns), "near-zero variance column(s)."), nzv_columns)
  }

  duplicate_columns <- feature_prep_duplicate_columns(prepared)
  duplicate_columns <- setdiff(duplicate_columns, protected)
  if (isTRUE(config$drop_duplicate_columns) && length(duplicate_columns)) {
    prepared[, (duplicate_columns) := NULL]
    add_step("drop_duplicate_columns", paste("Dropped", length(duplicate_columns), "duplicate column(s)."), duplicate_columns)
  }

  date_col <- config$date_col %||% ""
  if (isTRUE(config$add_date_features) && nzchar(date_col) && date_col %in% names(prepared)) {
    dates <- as.Date(prepared[[date_col]])
    if (!all(is.na(dates))) {
      year_col <- paste0(date_col, "_year")
      month_col <- paste0(date_col, "_month")
      dow_col <- paste0(date_col, "_dow")
      prepared[, (year_col) := as.integer(format(dates, "%Y"))]
      prepared[, (month_col) := as.integer(format(dates, "%m"))]
      prepared[, (dow_col) := as.integer(format(dates, "%u"))]
      add_step("date_feature_extraction", "Added deterministic year, month, and day-of-week columns.", c(year_col, month_col, dow_col))
    }
  }

  if (isTRUE(config$categorical_as_factor)) {
    factorized <- names(prepared)[vapply(prepared, function(x) is.character(x) || is.factor(x), logical(1))]
    if (length(factorized)) {
      for (column in factorized) {
        data.table::set(prepared, j = column, value = as.factor(prepared[[column]]))
      }
      add_step("categorical_as_factor", "Converted character/categorical columns to factors.", factorized)
    }
  }

  if (isTRUE(config$create_validation_split)) {
    set.seed(as.integer(config$split_seed %||% 20260711L))
    split <- rep("train", nrow(prepared))
    validation_n <- max(1L, floor(nrow(prepared) * config$validation_fraction))
    validation_idx <- sample(seq_len(nrow(prepared)), validation_n)
    split[validation_idx] <- "validation"
    prepared[, model_split := split]
    add_step("validation_split", paste("Created train/validation split with", validation_n, "validation row(s)."), "model_split")
  }

  after_schema <- feature_prep_schema_summary(prepared)
  step_table <- if (length(steps)) data.table::rbindlist(steps, use.names = TRUE, fill = TRUE) else data.table::data.table()
  schema_compare <- data.table::data.table(
    metric = c("rows", "columns", "missing_values", "new_columns", "removed_columns"),
    before = c(nrow(input_dt), ncol(input_dt), sum(before_schema$missing), NA_integer_, NA_integer_),
    after = c(nrow(prepared), ncol(prepared), sum(after_schema$missing), NA_integer_, NA_integer_),
    detail = c(
      "Row count",
      "Column count",
      "Total missing values",
      paste(setdiff(names(prepared), names(input_dt)), collapse = ", "),
      paste(setdiff(names(input_dt), names(prepared)), collapse = ", ")
    )
  )

  list(
    prepared_data = prepared,
    before_schema = before_schema,
    after_schema = after_schema,
    transformation_steps = step_table,
    schema_compare = schema_compare,
    config = config,
    timestamp = timestamp,
    module_run_id = run_id
  )
}

feature_preparation_code <- function(config) {
  paste(
    "feature_prep_result <- run_feature_preparation_pipeline(",
    "  data = data,",
    paste0("  config = ", deparse(config, width.cutoff = 500L)),
    ")",
    "",
    "# The source dataset is not mutated. The prepared dataset is returned as a standard artifact.",
    sep = "\n"
  )
}

run_feature_preparation_module <- function(data, config = list()) {
  pipeline <- run_feature_preparation_pipeline(data, config)
  if (!is.list(pipeline) || !is.null(pipeline$status)) {
    return(pipeline)
  }
  module_id <- feature_preparation_module_id()
  run_id <- pipeline$module_run_id
  timestamp <- pipeline$timestamp
  common_extra <- list(
    workflow_stage = "feature_engineering_model_prep",
    transformation_lineage = list(
      input_artifact = "active_dataset",
      output_artifact = paste0("aq_prep_", run_id, "_prepared_dataset"),
      parameters = pipeline$config,
      timestamp = timestamp,
      row_count_before = nrow(data),
      row_count_after = nrow(pipeline$prepared_data),
      column_count_before = ncol(data),
      column_count_after = ncol(pipeline$prepared_data),
      transformation_sequence = pipeline$transformation_steps$step %||% character()
    )
  )
  metadata <- function(name, section, index, extra = list()) {
    module_artifact_metadata(
      module_id = module_id,
      module_run_id = run_id,
      source_module = module_id,
      original_name = name,
      original_section = section,
      normalized_section = section,
      artifact_index = index,
      generated_at = timestamp,
      extra = c(common_extra, extra)
    )
  }

  artifacts <- list(
    prepared_dataset = create_artifact(
      artifact_id = paste0("aq_prep_", run_id, "_prepared_dataset"),
      artifact_type = "table",
      label = pipeline$config$prepared_data_name %||% "Prepared Modeling Data",
      source_module = module_id,
      object = pipeline$prepared_data,
      metadata = metadata("prepared_dataset", "Prepared Dataset", 1L, list(prepared_dataset = TRUE, artifact_importance = "critical", analytical_intent = "Data")),
      section = "Prepared Dataset",
      order = 1L
    ),
    transformation_steps = create_artifact(
      artifact_id = paste0("aq_prep_", run_id, "_transformation_steps"),
      artifact_type = "table",
      label = "Feature Preparation Transformation Steps",
      source_module = module_id,
      object = pipeline$transformation_steps,
      metadata = metadata("transformation_steps", "Transformation Lineage", 2L, list(artifact_importance = "critical", analytical_intent = "Diagnostic")),
      section = "Transformation Lineage",
      order = 2L
    ),
    schema_compare = create_artifact(
      artifact_id = paste0("aq_prep_", run_id, "_schema_compare"),
      artifact_type = "table",
      label = "Feature Preparation Before / After Summary",
      source_module = module_id,
      object = pipeline$schema_compare,
      metadata = metadata("schema_compare", "Preparation Summary", 3L, list(artifact_importance = "critical", analytical_intent = "Comparison")),
      section = "Preparation Summary",
      order = 3L
    ),
    narrative = create_artifact(
      artifact_id = paste0("aq_prep_", run_id, "_narrative"),
      artifact_type = "text",
      label = "Feature Preparation Summary",
      source_module = module_id,
      content = paste(
        "Prepared modeling data created without mutating the source dataset.",
        paste("Rows:", nrow(data), "->", nrow(pipeline$prepared_data)),
        paste("Columns:", ncol(data), "->", ncol(pipeline$prepared_data)),
        paste("Steps:", paste(pipeline$transformation_steps$step, collapse = ", "))
      ),
      metadata = metadata("narrative", "Preparation Summary", 4L, list(artifact_importance = "recommended", analytical_intent = "Narrative")),
      section = "Preparation Summary",
      order = 4L
    )
  )

  report_plans <- list(
    list(
      report_id = paste0("feature_prep_summary_", run_id),
      label = "Feature Preparation Summary",
      source_module = module_id,
      artifact_ids = vapply(artifacts, function(artifact) artifact$artifact_id, character(1)),
      metadata = list(module_id = module_id, workflow_stage = "feature_engineering_model_prep", module_run_id = run_id)
    )
  )

  service_result(
    status = "success",
    value = pipeline,
    artifacts = artifacts,
    messages = "Feature Engineering / Model Preparation completed.",
    metadata = module_run_metadata(
      module_id = module_id,
      module_run_id = run_id,
      generated_at = timestamp,
      data_name = pipeline$config$prepared_data_name,
      source_package = "AnalyticsShinyApp",
      source_function = "run_feature_preparation_module",
      configured_inputs = pipeline$config,
      artifacts = artifacts,
      report_plans = report_plans,
      extra = list(workflow_stage = "feature_engineering_model_prep", transformation_lineage = common_extra$transformation_lineage)
    ),
    code = feature_preparation_code(pipeline$config)
  )
}

feature_preparation_prepared_artifact_id <- function(result) {
  lineage <- result$metadata$transformation_lineage %||% list()
  artifact_id <- lineage$output_artifact %||% NA_character_
  if (is.character(artifact_id) && length(artifact_id) == 1L && nzchar(artifact_id)) {
    return(artifact_id)
  }

  artifacts <- result$artifacts %||% list()
  matches <- vapply(
    artifacts,
    function(artifact) isTRUE((artifact$metadata %||% list())$prepared_dataset),
    logical(1)
  )
  if (any(matches)) {
    return(artifacts[[which(matches)[[1]]]]$artifact_id)
  }

  NA_character_
}

is_prepared_dataset_artifact <- function(artifact) {
  if (!inherits(artifact, "aq_artifact")) {
    return(FALSE)
  }
  metadata <- artifact$metadata %||% list()
  is_table <- identical(artifact$artifact_type, "table")
  source_supported <- identical(artifact$source_module, feature_preparation_module_id()) ||
    (identical(artifact$source_module, "feature_experiment_loop") &&
       isTRUE(metadata$feature_experiment_dataset))
  is_table &&
    source_supported &&
    isTRUE(metadata$prepared_dataset) &&
    identical(metadata$original_name %||% artifact$artifact_id, "prepared_dataset")
}

prepared_dataset_activation_result <- function(artifact, current_dataset_name = NULL) {
  if (!is_prepared_dataset_artifact(artifact)) {
    return(service_result(
      status = "error",
      errors = "Selected artifact is not a prepared dataset artifact.",
      metadata = list(error_code = "PREPARED_DATASET_ARTIFACT_REQUIRED")
    ))
  }

  data <- artifact$object
  if (!is.data.frame(data)) {
    return(service_result(
      status = "error",
      errors = "Prepared dataset artifact does not contain tabular data.",
      metadata = list(
        error_code = "PREPARED_DATASET_DATA_MISSING",
        artifact_id = artifact$artifact_id
      )
    ))
  }

  data <- data.table::as.data.table(data.table::copy(data))
  data_info <- list(
    path = NULL,
    name = artifact$label %||% "Prepared Modeling Data",
    source = "prepared_artifact",
    source_artifact_id = artifact$artifact_id,
    source_module = artifact$source_module,
    activated_at = Sys.time(),
    previous_dataset_name = current_dataset_name
  )

  service_result(
    status = "success",
    value = list(
      data = data,
      data_info = data_info,
      artifact_id = artifact$artifact_id
    ),
    messages = sprintf(
      "Prepared dataset '%s' is now the active modeling dataset.",
      data_info$name
    ),
    metadata = list(
      workflow_stage = "feature_engineering_model_prep",
      activation_type = "prepared_dataset",
      artifact_id = artifact$artifact_id,
      row_count = nrow(data),
      column_count = ncol(data)
    )
  )
}

qa_feature_preparation_integration <- function() {
  data <- data.frame(
    id = 1:8,
    event_date = as.Date("2026-01-01") + 0:7,
    target = c(1, 0, 1, 0, 1, 0, 1, 0),
    spend = c(10, 10, 10, NA, 12, 13, 14, 15),
    duplicate_spend = c(10, 10, 10, NA, 12, 13, 14, 15),
    constant_flag = 1,
    channel = c("Search", "Search", NA, "Social", "Social", "Email", "Email", "Email")
  )
  config <- feature_prep_default_config(data)
  config$target_col <- "target"
  config$date_col <- "event_date"
  config$group_cols <- "channel"
  config$create_validation_split <- TRUE
  config$validation_fraction <- 0.25
  config$split_seed <- 42L
  result <- run_feature_preparation_module(data, config)
  prepared <- result$value$prepared_data
  lineage <- result$metadata$transformation_lineage
  invalid <- validate_feature_preparation_config(data, list(include_columns = "missing_column"))
  repeat_result <- run_feature_preparation_pipeline(data, config)
  prepared_artifact_id <- feature_preparation_prepared_artifact_id(result)
  activation <- prepared_dataset_activation_result(
    result$artifacts$prepared_dataset,
    current_dataset_name = "Source Data"
  )
  invalid_activation <- prepared_dataset_activation_result(result$artifacts$schema_compare)

  convention <- module_result_convention_checks(result, "aq_prep_")
  checks <- data.table::data.table(
    check = c(
      "module_success",
      "source_not_mutated",
      "prepared_dataset_artifact",
      "lineage_recorded",
      "constant_removed",
      "duplicate_removed",
      "missing_handled",
      "date_features_added",
      "validation_split_added",
      "reproducible_output",
      "invalid_config_rejected",
      "report_plan_created",
      "prepared_dataset_id_resolved",
      "prepared_dataset_activation",
      "invalid_activation_rejected"
    ),
    status = c(
      if (identical(result$status, "success")) "success" else "error",
      if ("constant_flag" %in% names(data) && "duplicate_spend" %in% names(data)) "success" else "error",
      if (length(result$artifacts) >= 4L && identical(result$artifacts$prepared_dataset$metadata$prepared_dataset, TRUE)) "success" else "error",
      if (is.list(lineage) && identical(lineage$input_artifact, "active_dataset") && nzchar(lineage$output_artifact)) "success" else "error",
      if (!"constant_flag" %in% names(prepared)) "success" else "error",
      if (!"duplicate_spend" %in% names(prepared)) "success" else "error",
      if (sum(is.na(prepared$spend)) == 0L && sum(is.na(prepared$channel)) == 0L) "success" else "error",
      if (all(c("event_date_year", "event_date_month", "event_date_dow") %in% names(prepared))) "success" else "error",
      if ("model_split" %in% names(prepared) && all(c("train", "validation") %in% unique(prepared$model_split))) "success" else "error",
      if (identical(prepared, repeat_result$prepared_data)) "success" else "error",
      if (identical(invalid$status, "error")) "success" else "error",
      if (length(result$metadata$report_plans %||% list()) == 1L) "success" else "error",
      if (identical(prepared_artifact_id, result$artifacts$prepared_dataset$artifact_id)) "success" else "error",
      if (identical(activation$status, "success") &&
          identical(activation$value$data_info$source, "prepared_artifact") &&
          identical(activation$value$artifact_id, prepared_artifact_id)) "success" else "error",
      if (identical(invalid_activation$status, "error")) "success" else "error"
    ),
    message = c(
      "Feature preparation returns a successful service_result.",
      "The source data remains unchanged.",
      "Prepared data is returned as a standard table artifact.",
      "Transformation lineage records input, output, parameters, timestamp, and sequence.",
      "Constant columns can be removed.",
      "Duplicate columns can be removed.",
      "Missing values are handled deterministically.",
      "Date feature extraction adds year, month, and day-of-week.",
      "Optional train/validation split is deterministic.",
      "Repeated execution with the same config returns the same prepared data.",
      "Invalid column configuration is rejected.",
      "A report plan is created for preparation review.",
      "Prepared dataset artifact id resolves from lineage.",
      "Prepared dataset artifacts can be explicitly activated for downstream modeling.",
      "Only prepared dataset artifacts can be activated."
    )
  )

  data.table::rbindlist(list(checks, convention), use.names = TRUE, fill = TRUE)
}
