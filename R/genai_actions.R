genai_action_risk_levels <- function() {
  c("none", "low", "medium", "high", "critical")
}

genai_action_statuses <- function() {
  c(
    "proposed", "validated", "rejected", "awaiting_approval", "approved",
    "executing", "succeeded", "failed", "expired", "cancelled", "timed_out"
  )
}

genai_action_execution_modes <- function() {
  c("read_only", "approval_required")
}

genai_action_policy <- function(
  execution_mode = "approval_required",
  allow_proposals = TRUE,
  allow_approved_execution = TRUE
) {
  execution_mode <- match.arg(execution_mode, genai_action_execution_modes())
  if (identical(execution_mode, "read_only")) {
    allow_approved_execution <- FALSE
  }
  structure(
    list(
      execution_mode = execution_mode,
      allow_proposals = isTRUE(allow_proposals),
      allow_approved_execution = isTRUE(allow_approved_execution)
    ),
    class = c("aq_genai_action_policy", "list")
  )
}

genai_action_definition <- function(
  action_id,
  action_version = "1.0",
  display_name,
  description,
  risk_tier = "low",
  input_schema = list(),
  required_permissions = character(),
  allowed_execution_modes = "approval_required",
  side_effects = character(),
  reversible = TRUE,
  approval_required = TRUE,
  persistence_requested = FALSE,
  handler
) {
  if (!is.function(handler)) {
    stop("handler must be a function.", call. = FALSE)
  }
  structure(
    list(
      action_id = action_id,
      action_version = action_version,
      display_name = display_name,
      description = description,
      risk_tier = risk_tier,
      input_schema = input_schema,
      required_permissions = required_permissions,
      allowed_execution_modes = allowed_execution_modes,
      side_effects = side_effects,
      reversible = reversible,
      approval_required = isTRUE(approval_required),
      persistence_requested = isTRUE(persistence_requested),
      handler = handler
    ),
    class = c("aq_genai_action_definition", "list")
  )
}

genai_action_registry_create <- function(actions = list()) {
  registry <- new.env(parent = emptyenv())
  for (action in actions) {
    genai_action_registry_register(registry, action)
  }
  registry
}

genai_action_registry_register <- function(registry, action) {
  if (!inherits(action, "aq_genai_action_definition")) {
    stop("Action must be created with genai_action_definition().", call. = FALSE)
  }
  if (exists(action$action_id, envir = registry, inherits = FALSE)) {
    stop(paste("Duplicate GenAI action id:", action$action_id), call. = FALSE)
  }
  assign(action$action_id, action, envir = registry)
  invisible(registry)
}

genai_action_registry_get <- function(action_id, registry = genai_action_registry()) {
  if (!exists(action_id, envir = registry, inherits = FALSE)) {
    return(NULL)
  }
  get(action_id, envir = registry, inherits = FALSE)
}

genai_action_registry_exists <- function(action_id, registry = genai_action_registry()) {
  !is.null(genai_action_registry_get(action_id, registry))
}

genai_action_registry_list <- function(registry = genai_action_registry(), include_handlers = FALSE) {
  ids <- ls(registry, all.names = TRUE)
  actions <- lapply(ids, function(id) {
    action <- get(id, envir = registry, inherits = FALSE)
    if (!isTRUE(include_handlers)) {
      action$handler <- NULL
    }
    action
  })
  stats::setNames(actions, ids)
}

genai_action_module_open_handler <- function(arguments, ctx = NULL) {
  module_id <- arguments$module_id %||% ""
  module <- get_module_definition(module_id)
  if (is.null(module)) {
    return(service_result(status = "error", errors = paste("Unknown module:", module_id)))
  }
  if (is.null(ctx)) {
    return(service_result(
      status = "success",
      value = list(module_id = normalize_module_id(module_id), label = module$label),
      messages = paste("Validated module navigation target:", module$label),
      metadata = list(
        state_changed = FALSE,
        ui_state_changed = FALSE,
        project_state_changed = FALSE,
        persistent_changes = FALSE
      )
    ))
  }
  if (is.function(ctx$select_analysis_module) && normalize_module_id(module_id) %in% names(get_module_registry())) {
    ctx$select_analysis_module(normalize_module_id(module_id))
  } else if (is.function(ctx$navigate_to)) {
    ctx$navigate_to(module$label %||% "Analysis Modules")
  }
  service_result(
    status = "success",
    value = list(module_id = normalize_module_id(module_id), label = module$label),
    messages = paste("Opened module:", module$label),
    metadata = list(
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_artifact_id_is_valid <- function(artifact_id) {
  is.character(artifact_id) &&
    length(artifact_id) == 1L &&
    !is.na(artifact_id) &&
    nzchar(artifact_id) &&
    grepl("^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$", artifact_id)
}

genai_resource_id_is_valid <- function(resource_id) {
  genai_artifact_id_is_valid(resource_id)
}

genai_artifact_lookup <- function(artifacts, artifact_id) {
  if (is.null(artifacts) || !length(artifacts) || !genai_artifact_id_is_valid(artifact_id)) {
    return(NULL)
  }
  if (artifact_id %in% names(artifacts)) {
    return(artifacts[[artifact_id]])
  }
  ids <- vapply(artifacts, function(artifact) artifact$artifact_id %||% "", character(1))
  index <- match(artifact_id, ids)
  if (is.na(index)) NULL else artifacts[[index]]
}

genai_report_lookup <- function(reports, report_id) {
  if (is.null(reports) || !length(reports) || !genai_resource_id_is_valid(report_id)) {
    return(NULL)
  }
  if (report_id %in% names(reports)) {
    return(reports[[report_id]])
  }
  ids <- vapply(reports, function(report) report$plan_id %||% report$report_id %||% "", character(1))
  index <- match(report_id, ids)
  if (is.na(index)) NULL else reports[[index]]
}

genai_active_project_id <- function(ctx = NULL) {
  if (!is.null(ctx) && !is.null(ctx$project_collector_state$collector)) {
    collector <- ctx$project_collector_state$collector
    if (inherits(collector, "project_artifact_collector")) {
      return(collector$project_id %||% "active_project")
    }
  }
  if (!is.null(ctx) && is.function(ctx$project_collector_project_id)) {
    return(ctx$project_collector_project_id())
  }
  "active_project"
}

genai_preflight_limits <- function(
  max_elapsed_ms = 5000L,
  max_rows_inspected = 5000L,
  max_columns_inspected = 100L,
  max_sample_rows = 1000L,
  max_warnings = 25L,
  max_check_details = 20L
) {
  list(
    max_elapsed_ms = as.integer(max_elapsed_ms),
    max_rows_inspected = as.integer(max_rows_inspected),
    max_columns_inspected = as.integer(max_columns_inspected),
    max_sample_rows = as.integer(max_sample_rows),
    max_warnings = as.integer(max_warnings),
    max_check_details = as.integer(max_check_details)
  )
}

genai_module_version <- function(module) {
  as.character(module$module_version %||% module$version %||% module$status %||% "unversioned")
}

genai_module_preflight_supported <- function(module) {
  status <- tolower(module$status %||% "")
  !status %in% c("deferred", "disabled", "unavailable")
}

genai_resolve_module_for_preflight <- function(module_id, ctx = NULL) {
  errors <- character()
  warnings <- character()
  if (!genai_resource_id_is_valid(module_id)) {
    return(service_result(status = "error", errors = "module_id is malformed or not a scalar stable identifier.", value = list(
      module_id = module_id,
      exists = FALSE,
      analysis_supported = FALSE,
      preflight_supported = FALSE
    )))
  }
  module <- get_module_definition(module_id)
  if (is.null(module)) {
    return(service_result(status = "error", errors = paste("Module does not exist:", module_id), value = list(
      module_id = module_id,
      exists = FALSE,
      analysis_supported = FALSE,
      preflight_supported = FALSE
    )))
  }
  status <- tolower(module$status %||% "available")
  disabled <- status %in% c("disabled", "unavailable")
  preflight_supported <- genai_module_preflight_supported(module)
  if (disabled) errors <- c(errors, paste("Module is not available:", module$status %||% "unknown"))
  if (!preflight_supported) errors <- c(errors, "Module does not support preflight checks.")

  value <- list(
    resource_type = "analysis_preflight",
    module_id = normalize_module_id(module_id),
    display_name = module$label %||% module_id,
    module_version = genai_module_version(module),
    module_category = module$category %||% "Analysis",
    module_status = module$status %||% "unknown",
    analysis_supported = !disabled,
    preflight_supported = preflight_supported,
    required_roles = module$required_roles %||% character(),
    optional_roles = module$optional_roles %||% character(),
    minimum_columns = as.integer(module$minimum_columns %||% 1L),
    minimum_rows = as.integer(module$minimum_rows %||% 1L),
    supported_data_types = module$supported_data_types %||% c("numeric", "integer", "character", "factor", "logical", "Date", "POSIXct", "POSIXlt"),
    preflight_handler_id = module$preflight_handler_id %||% "generic_dataset_preflight"
  )
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(module = module)
  )
}

genai_dataset_id <- function(ctx = NULL) {
  if (!is.null(ctx) && is.function(ctx$current_dataset_id)) {
    return(ctx$current_dataset_id())
  }
  "active_dataset"
}

genai_dataset_version <- function(data, info = list()) {
  .genai_action_hash(list(
    rows = if (is.null(data)) NA_integer_ else nrow(data),
    columns = if (is.null(data)) NA_integer_ else ncol(data),
    names = if (is.null(data)) character() else names(data),
    source_name = info$name %||% NA_character_,
    active_dataset_source = info$source %||% NA_character_,
    active_dataset_artifact_id = info$source_artifact_id %||% NA_character_
  ))
}

genai_schema_version <- function(data) {
  if (is.null(data)) return("schema_missing")
  classes <- vapply(data, function(x) paste(class(x), collapse = "/"), character(1))
  .genai_action_hash(list(names = names(data), classes = classes))
}

genai_resolve_dataset <- function(dataset_id, ctx = NULL, data = NULL, active_project_id = NULL) {
  errors <- character()
  warnings <- character()
  if (!genai_resource_id_is_valid(dataset_id)) {
    return(service_result(status = "error", errors = "dataset_id is malformed or not a scalar stable identifier.", value = list(
      dataset_id = dataset_id,
      exists = FALSE,
      available = FALSE,
      current_project_match = FALSE
    )))
  }
  trusted_dataset_id <- genai_dataset_id(ctx)
  if (!identical(dataset_id, trusted_dataset_id)) {
    return(service_result(status = "error", errors = paste("Dataset does not exist in trusted app state:", dataset_id), value = list(
      dataset_id = dataset_id,
      exists = FALSE,
      available = FALSE,
      current_project_match = FALSE,
      active_project_id = active_project_id %||% genai_active_project_id(ctx)
    )))
  }
  data <- data %||% if (!is.null(ctx) && is.function(ctx$uploaded_data)) {
    tryCatch(ctx$uploaded_data(), error = function(e) NULL)
  } else if (!is.null(ctx) && is.function(ctx$project_data)) {
    tryCatch(ctx$project_data(), error = function(e) NULL)
  } else {
    NULL
  }
  info <- if (!is.null(ctx) && is.function(ctx$project_data_info)) {
    tryCatch(ctx$project_data_info(), error = function(e) list())
  } else {
    list()
  }
  active_project_id <- active_project_id %||% genai_active_project_id(ctx)
  modeling_context <- if (!is.null(ctx) && is.function(ctx$current_modeling_context)) {
    tryCatch(ctx$current_modeling_context(), error = function(e) NULL)
  } else {
    NULL
  }
  if (is.null(data)) {
    errors <- c(errors, "Dataset is unavailable or not loaded.")
  }
  row_count <- if (is.null(data)) 0L else nrow(data)
  column_count <- if (is.null(data)) 0L else ncol(data)
  if (!is.null(data) && is.null(names(data))) {
    errors <- c(errors, "Dataset schema is unavailable.")
  }
  value <- list(
    resource_type = "analysis_preflight_dataset",
    dataset_id = dataset_id,
    display_name = info$name %||% "Active Dataset",
    active_project_id = active_project_id,
    dataset_version = if (is.null(data)) "unavailable" else genai_dataset_version(data, info),
    schema_version = genai_schema_version(data),
    availability = if (is.null(data)) "unavailable" else "available",
    exists = !is.null(data),
    available = !is.null(data),
    current_project_match = TRUE,
    row_count = as.integer(row_count),
    column_count = as.integer(column_count),
    data_source_type = if (!is.null(info$path)) tools::file_ext(info$path) else "session",
    modeling_context = modeling_context,
    active_dataset_source = (modeling_context %||% list())$active_dataset_source %||% info$source %||% "source_dataset",
    active_dataset_artifact_id = (modeling_context %||% list())$active_dataset_artifact_id %||% info$source_artifact_id %||% NA_character_,
    lineage_summary = (modeling_context %||% list())$lineage_summary %||% NA_character_,
    last_updated_at = as.character(info$updated_at %||% Sys.time())
  )
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(data = data)
  )
}

genai_preflight_resource_fingerprint <- function(module_resolution, dataset_resolution) {
  .genai_action_hash(list(
    resource_type = "analysis_preflight",
    active_project_id = dataset_resolution$active_project_id %||% NA_character_,
    module_id = module_resolution$module_id %||% NA_character_,
    module_version = module_resolution$module_version %||% NA_character_,
    dataset_id = dataset_resolution$dataset_id %||% NA_character_,
    dataset_version = dataset_resolution$dataset_version %||% NA_character_,
    schema_version = dataset_resolution$schema_version %||% NA_character_,
    dataset_availability = dataset_resolution$availability %||% NA_character_
  ))
}

genai_preflight_check <- function(check_id, label, status, message, details = NULL, source = "metadata") {
  list(
    check_id = check_id,
    label = label,
    status = status,
    message = as.character(message %||% ""),
    details = details,
    source = source
  )
}

genai_preflight_readiness <- function(checks, cancelled = FALSE, timed_out = FALSE) {
  statuses <- vapply(checks, function(x) x$status %||% "not_evaluated", character(1))
  if (isTRUE(cancelled)) return("cancelled")
  if (isTRUE(timed_out)) return("timed_out")
  if (any(statuses == "error")) return("blocked")
  if (any(statuses == "warning")) return("ready_with_warnings")
  "ready"
}

genai_run_generic_preflight <- function(module_resolution, dataset_resolution, data, limits = genai_preflight_limits(), cancel_requested = function() FALSE) {
  started <- Sys.time()
  deadline <- started + (limits$max_elapsed_ms / 1000)
  checks <- list()
  add_check <- function(...) {
    checks[[length(checks) + 1L]] <<- genai_preflight_check(...)
  }
  timed_out <- function() Sys.time() > deadline
  if (isTRUE(cancel_requested())) {
    return(list(readiness = "cancelled", checks = checks, warnings = "Preflight was cancelled before checks began.", errors = character(), inspection_mode = "metadata"))
  }

  rows_total <- dataset_resolution$row_count %||% 0L
  cols_total <- dataset_resolution$column_count %||% 0L
  cols_inspected <- min(cols_total, limits$max_columns_inspected)
  rows_inspected <- min(rows_total, limits$max_rows_inspected)
  inspection_mode <- if (rows_total <= limits$max_rows_inspected && cols_total <= limits$max_columns_inspected) "full_bounded_scan" else "sample"
  inspected_data <- if (is.null(data) || cols_inspected < 1L) {
    data.frame()
  } else {
    as.data.frame(data)[seq_len(rows_inspected), seq_len(cols_inspected), drop = FALSE]
  }

  add_check("module_exists", "Module exists", "pass", paste("Module resolved:", module_resolution$display_name), source = "metadata")
  add_check("dataset_exists", "Dataset exists", if (isTRUE(dataset_resolution$available)) "pass" else "error", dataset_resolution$availability, source = "metadata")
  add_check("row_count_nonzero", "Rows available", if (rows_total > 0L) "pass" else "error", paste(rows_total, "rows"), source = "metadata")
  add_check("column_count_nonzero", "Columns available", if (cols_total > 0L) "pass" else "error", paste(cols_total, "columns"), source = "metadata")
  add_check("minimum_rows", "Minimum rows", if (rows_total >= (module_resolution$minimum_rows %||% 1L)) "pass" else "error", paste("Requires at least", module_resolution$minimum_rows %||% 1L, "rows."), source = "metadata")
  add_check("minimum_columns", "Minimum columns", if (cols_total >= (module_resolution$minimum_columns %||% 1L)) "pass" else "error", paste("Requires at least", module_resolution$minimum_columns %||% 1L, "columns."), source = "metadata")
  if (timed_out()) {
    return(list(readiness = "timed_out", checks = checks, warnings = "Preflight timed out during metadata checks.", errors = character(), inspection_mode = inspection_mode))
  }

  duplicate_names <- names(data)[duplicated(names(data))]
  add_check("duplicate_column_names", "Duplicate column names", if (length(duplicate_names)) "warning" else "pass", if (length(duplicate_names)) paste("Duplicate names:", paste(unique(duplicate_names), collapse = ", ")) else "No duplicate column names detected.", source = "metadata")

  classes <- if (is.null(data)) character() else vapply(data, function(x) class(x)[[1]], character(1))
  supported <- module_resolution$supported_data_types %||% character()
  unsupported <- names(classes)[!classes %in% supported]
  add_check("unsupported_column_types", "Unsupported column types", if (length(unsupported)) "warning" else "pass", if (length(unsupported)) paste("Unsupported or unusual columns:", paste(utils::head(unsupported, limits$max_check_details), collapse = ", ")) else "No unsupported column types detected.", source = "metadata")

  if (isTRUE(cancel_requested())) {
    return(list(readiness = "cancelled", checks = checks, warnings = "Preflight was cancelled.", errors = character(), inspection_mode = inspection_mode))
  }
  if (timed_out()) {
    return(list(readiness = "timed_out", checks = checks, warnings = "Preflight timed out before bounded data checks completed.", errors = character(), inspection_mode = inspection_mode))
  }

  all_missing <- names(inspected_data)[vapply(inspected_data, function(x) all(is.na(x)), logical(1))]
  add_check("all_missing_columns", "All-missing columns", if (length(all_missing)) "warning" else "pass", if (length(all_missing)) paste("All-missing columns:", paste(utils::head(all_missing, limits$max_check_details), collapse = ", ")) else "No all-missing columns detected in bounded scan.", source = inspection_mode)

  constant_cols <- names(inspected_data)[vapply(inspected_data, function(x) length(unique(x[!is.na(x)])) <= 1L, logical(1))]
  add_check("constant_columns", "Constant columns", if (length(constant_cols)) "warning" else "pass", if (length(constant_cols)) paste("Constant columns:", paste(utils::head(constant_cols, limits$max_check_details), collapse = ", ")) else "No constant columns detected in bounded scan.", source = inspection_mode)

  high_cardinality <- names(inspected_data)[vapply(inspected_data, function(x) {
    is.character(x) || is.factor(x)
  }, logical(1)) & vapply(inspected_data, function(x) length(unique(x[!is.na(x)])) > min(100L, max(10L, floor(length(x) * 0.8))), logical(1))]
  add_check("high_cardinality_fields", "High-cardinality fields", if (length(high_cardinality)) "warning" else "pass", if (length(high_cardinality)) paste("High-cardinality fields:", paste(utils::head(high_cardinality, limits$max_check_details), collapse = ", ")) else "No extreme high-cardinality fields detected in bounded scan.", source = inspection_mode)

  id_like <- names(inspected_data)[grepl("(^id$|_id$|id_|uuid|guid)", names(inspected_data), ignore.case = TRUE)]
  add_check("identifier_like_fields", "Identifier-like fields", if (length(id_like)) "warning" else "not_applicable", if (length(id_like)) paste("Identifier-like fields:", paste(utils::head(id_like, limits$max_check_details), collapse = ", ")) else "No obvious identifier-like fields by name.", source = "metadata")

  missing_fraction <- vapply(inspected_data, function(x) mean(is.na(x)), numeric(1))
  severe_missing <- names(missing_fraction)[missing_fraction >= 0.5]
  add_check("missing_value_severity", "Missing value severity", if (length(severe_missing)) "warning" else "pass", if (length(severe_missing)) paste("Columns with >=50% missingness:", paste(utils::head(severe_missing, limits$max_check_details), collapse = ", ")) else "No severe missingness detected in bounded scan.", source = inspection_mode)

  required_roles <- module_resolution$required_roles %||% character()
  if (length(required_roles)) {
    add_check("required_roles", "Required variable roles", "not_evaluated", "No shared role registry is available yet; module-specific role requirements were not evaluated.", source = "metadata")
  } else {
    add_check("required_roles", "Required variable roles", "not_applicable", "No required roles declared by the module registry.", source = "metadata")
  }
  add_check("resource_workload", "Estimated workload", if (rows_total > limits$max_rows_inspected || cols_total > limits$max_columns_inspected) "warning" else "pass", if (identical(inspection_mode, "sample")) "Future full run may require sampling or stricter limits." else "Dataset is within bounded preflight scan limits.", source = "metadata")

  readiness <- genai_preflight_readiness(checks)
  warnings <- vapply(checks, function(x) if (identical(x$status, "warning")) x$message else NA_character_, character(1))
  warnings <- stats::na.omit(warnings)
  errors <- vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))
  errors <- stats::na.omit(errors)
  list(
    readiness = readiness,
    checks = checks,
    warnings = utils::head(as.character(warnings), limits$max_warnings),
    errors = as.character(errors),
    inspection_mode = inspection_mode,
    rows_considered = as.integer(rows_inspected),
    columns_considered = as.integer(cols_inspected)
  )
}

genai_run_model_assessment_regression_preflight <- function(module_resolution, dataset_resolution, data, configuration_snapshot, limits = genai_preflight_limits(), cancel_requested = function() FALSE) {
  started <- Sys.time()
  deadline <- started + (limits$max_elapsed_ms / 1000)
  checks <- list()
  add_check <- function(...) {
    checks[[length(checks) + 1L]] <<- genai_preflight_check(...)
  }
  timed_out <- function() Sys.time() > deadline
  config <- configuration_snapshot$configuration_values %||% list()
  target <- as.character(config$target_column %||% "")
  prediction <- as.character(config$prediction_column %||% "")
  weight <- as.character(config$weight_column %||% "")
  has_weight <- nzchar(weight) && !is.na(weight)

  if (isTRUE(cancel_requested())) {
    return(list(readiness = "cancelled", checks = checks, warnings = "Preflight was cancelled before checks began.", errors = character(), inspection_mode = "metadata"))
  }
  rows_total <- dataset_resolution$row_count %||% 0L
  cols_total <- dataset_resolution$column_count %||% 0L
  rows_inspected <- min(rows_total, limits$max_rows_inspected)
  cols_inspected <- min(cols_total, limits$max_columns_inspected)
  inspection_mode <- if (rows_total <= limits$max_rows_inspected && cols_total <= limits$max_columns_inspected) "full_bounded_scan" else "sample"
  inspected <- if (is.null(data) || rows_inspected < 1L || cols_inspected < 1L) data.frame() else as.data.frame(data)[seq_len(rows_inspected), , drop = FALSE]

  add_check("module_exists", "Module exists", "pass", paste("Module resolved:", module_resolution$display_name), source = "metadata")
  add_check("dataset_exists", "Dataset exists", if (isTRUE(dataset_resolution$available)) "pass" else "error", dataset_resolution$availability, source = "metadata")
  add_check("configuration_task_type", "Regression mode", if (identical(config$task_type %||% "", "regression")) "pass" else "error", "Only regression Model Assessment is enabled.", source = "trusted_configuration")
  add_check("target_configured", "Target column configured", if (nzchar(target) && !is.na(target)) "pass" else "error", if (nzchar(target) && !is.na(target)) target else "Trusted target column is missing.", source = "trusted_configuration")
  add_check("prediction_configured", "Prediction column configured", if (nzchar(prediction) && !is.na(prediction)) "pass" else "error", if (nzchar(prediction) && !is.na(prediction)) prediction else "Trusted prediction column is missing.", source = "trusted_configuration")
  add_check("target_prediction_distinct", "Target and prediction differ", if (nzchar(target) && nzchar(prediction) && !identical(target, prediction)) "pass" else "error", "Target and prediction columns must be different.", source = "trusted_configuration")
  if (timed_out()) return(list(readiness = "timed_out", checks = checks, warnings = "Preflight timed out during configuration checks.", errors = character(), inspection_mode = inspection_mode))

  names_data <- names(data %||% data.frame())
  target_exists <- target %in% names_data
  pred_exists <- prediction %in% names_data
  weight_exists <- !has_weight || weight %in% names_data
  add_check("target_exists", "Target column exists", if (target_exists) "pass" else "error", if (target_exists) target else "Configured target column is not in the active dataset.", source = "schema")
  add_check("prediction_exists", "Prediction column exists", if (pred_exists) "pass" else "error", if (pred_exists) prediction else "Configured prediction column is not in the active dataset.", source = "schema")
  add_check("weight_exists", "Weight column exists", if (weight_exists) "pass" else "error", if (has_weight) weight else "No weight column configured.", source = "schema")
  if (!target_exists || !pred_exists || !weight_exists) {
    readiness <- genai_preflight_readiness(checks)
    errors <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))))
    return(list(readiness = readiness, checks = checks, warnings = character(), errors = errors, inspection_mode = inspection_mode, rows_considered = as.integer(rows_inspected), columns_considered = as.integer(cols_inspected)))
  }

  y <- inspected[[target]]
  p <- inspected[[prediction]]
  w <- if (has_weight) inspected[[weight]] else NULL
  target_numeric <- is.numeric(y)
  pred_numeric <- is.numeric(p)
  weight_numeric <- is.null(w) || is.numeric(w)
  add_check("target_numeric", "Target is numeric", if (target_numeric) "pass" else "error", paste(target, "class:", paste(class(y), collapse = "/")), source = "schema")
  add_check("prediction_numeric", "Prediction is numeric", if (pred_numeric) "pass" else "error", paste(prediction, "class:", paste(class(p), collapse = "/")), source = "schema")
  add_check("weight_numeric", "Weight is numeric", if (weight_numeric) "pass" else "error", if (has_weight) paste(weight, "class:", paste(class(w), collapse = "/")) else "No weight column configured.", source = "schema")
  if (!target_numeric || !pred_numeric || !weight_numeric) {
    readiness <- genai_preflight_readiness(checks)
    errors <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))))
    return(list(readiness = readiness, checks = checks, warnings = character(), errors = errors, inspection_mode = inspection_mode, rows_considered = as.integer(rows_inspected), columns_considered = as.integer(cols_inspected)))
  }

  finite <- is.finite(y) & is.finite(p)
  if (!is.null(w)) finite <- finite & is.finite(w) & !is.na(w)
  complete_pairs <- sum(finite, na.rm = TRUE)
  missing_rate <- 1 - (complete_pairs / max(1L, length(y)))
  target_constant <- length(unique(y[finite])) <= 1L
  prediction_constant <- length(unique(p[finite])) <= 1L
  invalid_weight <- !is.null(w) && (any(w[finite] < 0, na.rm = TRUE) || sum(w[finite], na.rm = TRUE) <= 0)
  add_check("complete_pairs", "Complete finite pairs", if (complete_pairs >= 5L) "pass" else "error", paste(complete_pairs, "complete finite target/prediction pairs."), source = inspection_mode)
  add_check("target_not_constant", "Target not constant", if (!target_constant) "pass" else "error", "Regression assessment requires non-constant target values.", source = inspection_mode)
  add_check("prediction_not_constant", "Prediction not constant", if (!prediction_constant) "pass" else "warning", "Constant predictions make diagnostics weak but metrics can still be computed.", source = inspection_mode)
  add_check("missingness_severity", "Missingness severity", if (missing_rate > 0.35) "warning" else "pass", paste0(round(missing_rate * 100, 1), "% of inspected rows lack finite target/prediction values."), source = inspection_mode)
  add_check("weight_valid", "Weights valid", if (invalid_weight) "error" else if (has_weight) "pass" else "not_applicable", if (has_weight) "Configured weights are finite, nonnegative, and positive in sum." else "No weight column configured.", source = inspection_mode)
  add_check("resource_workload", "Estimated workload", if (rows_total > limits$max_rows_inspected) "warning" else "pass", if (rows_total > limits$max_rows_inspected) "Execution will use a bounded sample." else "Dataset is within bounded execution limits.", source = "metadata")

  readiness <- genai_preflight_readiness(checks)
  warnings <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "warning")) x$message else NA_character_, character(1))))
  errors <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))))
  list(
    readiness = readiness,
    checks = checks,
    warnings = utils::head(warnings, limits$max_warnings),
    errors = errors,
    inspection_mode = inspection_mode,
    rows_considered = as.integer(rows_inspected),
    columns_considered = as.integer(cols_inspected)
  )
}

genai_binary_class_labels <- function(x) {
  out <- as.character(x)
  out[is.na(x)] <- NA_character_
  out
}

genai_binary_auc <- function(y01, score, weight = NULL) {
  valid <- is.finite(y01) & is.finite(score)
  y01 <- as.integer(y01[valid])
  score <- as.numeric(score[valid])
  if (!length(y01) || length(unique(y01)) != 2L) return(NA_real_)
  pos <- y01 == 1L
  neg <- y01 == 0L
  denom <- sum(pos) * sum(neg)
  if (!is.finite(denom) || denom <= 0) return(NA_real_)
  ranks <- rank(score, ties.method = "average")
  auc <- (sum(ranks[pos]) - sum(seq_len(sum(pos)))) / denom
  max(0, min(1, auc))
}

genai_binary_curve_tables <- function(y01, probability, weight = NULL, max_points = 100L) {
  valid <- is.finite(y01) & is.finite(probability)
  y01 <- as.integer(y01[valid])
  probability <- as.numeric(probability[valid])
  weight <- as.numeric((weight %||% rep(1, length(valid)))[valid])
  if (!length(y01) || length(unique(y01)) != 2L) {
    empty <- data.frame(threshold = numeric(), stringsAsFactors = FALSE)
    return(list(roc = empty, pr = empty))
  }
  thresholds <- sort(unique(probability), decreasing = TRUE)
  if (length(thresholds) > max_points) {
    thresholds <- as.numeric(stats::quantile(thresholds, probs = seq(0, 1, length.out = max_points), na.rm = TRUE))
    thresholds <- sort(unique(thresholds), decreasing = TRUE)
  }
  rows <- lapply(thresholds, function(th) {
    pred <- probability >= th
    tp <- sum(weight[pred & y01 == 1L])
    fp <- sum(weight[pred & y01 == 0L])
    tn <- sum(weight[!pred & y01 == 0L])
    fn <- sum(weight[!pred & y01 == 1L])
    sensitivity <- if ((tp + fn) > 0) tp / (tp + fn) else NA_real_
    specificity <- if ((tn + fp) > 0) tn / (tn + fp) else NA_real_
    precision <- if ((tp + fp) > 0) tp / (tp + fp) else NA_real_
    data.frame(
      threshold = th,
      false_positive_rate = 1 - specificity,
      true_positive_rate = sensitivity,
      recall = sensitivity,
      precision = precision,
      stringsAsFactors = FALSE
    )
  })
  all <- data.table::rbindlist(rows, fill = TRUE)
  list(
    roc = all[, c("threshold", "false_positive_rate", "true_positive_rate"), with = FALSE],
    pr = all[, c("threshold", "recall", "precision"), with = FALSE]
  )
}

genai_run_model_assessment_binary_preflight <- function(module_resolution, dataset_resolution, data, configuration_snapshot, limits = genai_preflight_limits(), cancel_requested = function() FALSE) {
  started <- Sys.time()
  deadline <- started + (limits$max_elapsed_ms / 1000)
  checks <- list()
  add_check <- function(...) checks[[length(checks) + 1L]] <<- genai_preflight_check(...)
  timed_out <- function() Sys.time() > deadline
  config <- configuration_snapshot$configuration_values %||% list()
  target <- as.character(config$target_column %||% "")
  prediction <- as.character(config$prediction_column %||% "")
  positive <- as.character(config$positive_class %||% "")
  threshold <- suppressWarnings(as.numeric(config$decision_threshold %||% NA_real_))
  scale <- tolower(as.character(config$prediction_scale %||% ""))
  weight <- as.character(config$weight_column %||% "")
  has_weight <- nzchar(weight) && !is.na(weight)
  if (isTRUE(cancel_requested())) {
    return(list(readiness = "cancelled", checks = checks, warnings = "Preflight was cancelled before checks began.", errors = character(), inspection_mode = "metadata"))
  }
  rows_total <- dataset_resolution$row_count %||% 0L
  rows_inspected <- min(rows_total, limits$max_rows_inspected)
  inspection_mode <- if (rows_total <= limits$max_rows_inspected) "full_bounded_scan" else "sample"
  inspected <- if (is.null(data) || rows_inspected < 1L) data.frame() else as.data.frame(data)[seq_len(rows_inspected), , drop = FALSE]
  add_check("module_exists", "Module exists", "pass", paste("Module resolved:", module_resolution$display_name), source = "metadata")
  add_check("dataset_exists", "Dataset exists", if (isTRUE(dataset_resolution$available)) "pass" else "error", dataset_resolution$availability, source = "metadata")
  add_check("configuration_task_type", "Binary classification mode", if (identical(config$task_type %||% "", "binary_classification")) "pass" else "error", "Trusted task type must be binary_classification.", source = "trusted_configuration")
  add_check("target_configured", "Target column configured", if (nzchar(target) && !is.na(target)) "pass" else "error", target %||% "Trusted target column is missing.", source = "trusted_configuration")
  add_check("prediction_configured", "Prediction column configured", if (nzchar(prediction) && !is.na(prediction)) "pass" else "error", prediction %||% "Trusted probability prediction column is missing.", source = "trusted_configuration")
  add_check("target_prediction_distinct", "Target and prediction differ", if (nzchar(target) && nzchar(prediction) && !identical(target, prediction)) "pass" else "error", "Target and prediction columns must be different.", source = "trusted_configuration")
  add_check("positive_class_configured", "Positive class configured", if (nzchar(positive) && !is.na(positive)) "pass" else "error", positive %||% "Positive class must come from trusted state.", source = "trusted_configuration")
  add_check("prediction_scale_supported", "Prediction scale supported", if (identical(scale, "probability")) "pass" else "error", "Only probability values in [0,1] are supported.", source = "trusted_configuration")
  add_check("threshold_valid", "Trusted threshold valid", if (is.finite(threshold) && threshold >= 0 && threshold <= 1) "pass" else "error", paste("Threshold:", threshold), source = "trusted_configuration")
  if (timed_out()) return(list(readiness = "timed_out", checks = checks, warnings = "Preflight timed out during configuration checks.", errors = character(), inspection_mode = inspection_mode))
  names_data <- names(data %||% data.frame())
  target_exists <- target %in% names_data
  pred_exists <- prediction %in% names_data
  weight_exists <- !has_weight || weight %in% names_data
  add_check("target_exists", "Target column exists", if (target_exists) "pass" else "error", if (target_exists) target else "Configured target column is not in the active dataset.", source = "schema")
  add_check("prediction_exists", "Prediction column exists", if (pred_exists) "pass" else "error", if (pred_exists) prediction else "Configured prediction column is not in the active dataset.", source = "schema")
  add_check("weight_exists", "Weight column exists", if (weight_exists) "pass" else "error", if (has_weight) weight else "No weight column configured.", source = "schema")
  if (!target_exists || !pred_exists || !weight_exists) {
    readiness <- genai_preflight_readiness(checks)
    errors <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))))
    return(list(readiness = readiness, checks = checks, warnings = character(), errors = errors, inspection_mode = inspection_mode, rows_considered = rows_inspected, columns_considered = ncol(data %||% data.frame())))
  }
  y_raw <- genai_binary_class_labels(inspected[[target]])
  p <- inspected[[prediction]]
  w <- if (has_weight) inspected[[weight]] else NULL
  pred_numeric <- is.numeric(p)
  weight_numeric <- is.null(w) || is.numeric(w)
  add_check("prediction_numeric", "Prediction is numeric probability", if (pred_numeric) "pass" else "error", paste(prediction, "class:", paste(class(p), collapse = "/")), source = "schema")
  add_check("weight_numeric", "Weight is numeric", if (weight_numeric) "pass" else "error", if (has_weight) paste(weight, "class:", paste(class(w), collapse = "/")) else "No weight column configured.", source = "schema")
  classes <- sort(unique(y_raw[!is.na(y_raw) & nzchar(y_raw)]))
  negative <- setdiff(classes, positive)
  add_check("target_binary", "Target has exactly two classes", if (length(classes) == 2L) "pass" else "error", paste("Classes:", paste(classes, collapse = ", ")), source = inspection_mode)
  add_check("positive_class_present", "Positive class present", if (positive %in% classes) "pass" else "error", paste("Positive class:", positive), source = inspection_mode)
  add_check("negative_class_present", "Negative class present", if (length(negative) == 1L) "pass" else "error", paste("Negative class:", paste(negative, collapse = ", ")), source = inspection_mode)
  if (!pred_numeric || !weight_numeric || length(classes) != 2L || !positive %in% classes) {
    readiness <- genai_preflight_readiness(checks)
    errors <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))))
    return(list(readiness = readiness, checks = checks, warnings = character(), errors = errors, inspection_mode = inspection_mode, rows_considered = rows_inspected, columns_considered = ncol(data %||% data.frame())))
  }
  y01 <- as.integer(y_raw == positive)
  p <- as.numeric(p)
  weights <- if (is.null(w)) rep(1, length(p)) else as.numeric(w)
  complete <- !is.na(y01) & is.finite(p) & is.finite(weights) & !is.na(weights)
  complete_pairs <- sum(complete)
  p_complete <- p[complete]
  y_complete <- y01[complete]
  w_complete <- weights[complete]
  invalid_scale <- any(p_complete < 0 | p_complete > 1, na.rm = TRUE)
  invalid_weights <- any(w_complete < 0, na.rm = TRUE) || sum(w_complete, na.rm = TRUE) <= 0
  pos_n <- sum(y_complete == 1L)
  neg_n <- sum(y_complete == 0L)
  add_check("complete_pairs", "Complete target/probability pairs", if (complete_pairs >= 5L) "pass" else "error", paste(complete_pairs, "complete pairs."), source = inspection_mode)
  add_check("positive_observations", "Positive observations present", if (pos_n > 0L) "pass" else "error", paste(pos_n, "positive rows."), source = inspection_mode)
  add_check("negative_observations", "Negative observations present", if (neg_n > 0L) "pass" else "error", paste(neg_n, "negative rows."), source = inspection_mode)
  add_check("probability_range", "Probability values in [0,1]", if (!invalid_scale) "pass" else "error", if (invalid_scale) "unsupported_prediction_scale" else "All inspected probabilities are within [0,1].", source = inspection_mode)
  add_check("probability_variance", "Probability variance", if (length(unique(p_complete)) > 1L) "pass" else "warning", "Nearly constant probabilities weaken ranking diagnostics.", source = inspection_mode)
  add_check("weight_valid", "Weights valid", if (invalid_weights) "error" else if (has_weight) "pass" else "not_applicable", if (has_weight) "Configured weights are finite, nonnegative, and positive in sum." else "No weight column configured.", source = inspection_mode)
  add_check("class_balance", "Class balance", if (min(pos_n, neg_n) < 10L) "warning" else if (min(pos_n, neg_n) / max(1, complete_pairs) < 0.05) "warning" else "pass", paste("Positive:", pos_n, "Negative:", neg_n), source = inspection_mode)
  add_check("metric_readiness", "Metric readiness", if (complete_pairs >= 5L && pos_n > 0L && neg_n > 0L && !invalid_scale) "pass" else "error", "ROC, PR, confusion, Brier, log loss, calibration, and lift readiness.", source = inspection_mode)
  add_check("resource_workload", "Estimated workload", if (rows_total > limits$max_rows_inspected) "warning" else "pass", if (rows_total > limits$max_rows_inspected) "Execution will use a bounded sample." else "Dataset is within bounded execution limits.", source = "metadata")
  readiness <- genai_preflight_readiness(checks)
  warnings <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "warning")) x$message else NA_character_, character(1))))
  errors <- as.character(stats::na.omit(vapply(checks, function(x) if (identical(x$status, "error")) x$message else NA_character_, character(1))))
  list(readiness = readiness, checks = checks, warnings = utils::head(warnings, limits$max_warnings), errors = errors, inspection_mode = inspection_mode, rows_considered = as.integer(rows_inspected), columns_considered = as.integer(ncol(data %||% data.frame())))
}

genai_registered_analysis_limits <- function(
  max_elapsed_ms = 5000L,
  max_rows_inspected = 5000L,
  max_columns_inspected = 100L,
  max_sample_rows = 1000L,
  max_generated_plots = 0L,
  max_generated_tables = 6L,
  max_table_rows = 50L,
  max_category_levels = 25L,
  max_result_size = 250000L,
  max_warnings = 25L,
  max_diagnostics = 25L
) {
  list(
    max_elapsed_ms = as.integer(max_elapsed_ms),
    max_rows_inspected = as.integer(max_rows_inspected),
    max_columns_inspected = as.integer(max_columns_inspected),
    max_sample_rows = as.integer(max_sample_rows),
    max_generated_plots = as.integer(max_generated_plots),
    max_generated_tables = as.integer(max_generated_tables),
    max_table_rows = as.integer(max_table_rows),
    max_category_levels = as.integer(max_category_levels),
    max_result_size = as.integer(max_result_size),
    max_warnings = as.integer(max_warnings),
    max_diagnostics = as.integer(max_diagnostics)
  )
}

genai_registered_analysis_job_statuses <- function() {
  c("queued", "validating", "running", "cancelling", "succeeded", "failed", "cancelled", "timed_out")
}

genai_registered_analysis_initial_module_id <- function() {
  "dataset_profile"
}

genai_registered_analysis_second_module_id <- function() {
  "model_assessment"
}

genai_model_assessment_result_type <- function() {
  genai_model_assessment_regression_result_type()
}

genai_registered_analysis_config_schema <- function(module_id = genai_registered_analysis_initial_module_id()) {
  module_id <- normalize_module_id(module_id)
  if (identical(module_id, genai_registered_analysis_second_module_id())) {
    return(list(
      configuration_schema_version = "model_assessment_config_union_v1",
      allowlisted_fields = c(
        "task_type", "target_column", "prediction_column", "positive_class",
        "negative_class", "decision_threshold", "prediction_scale", "weight_column"
      ),
      required_fields = c("task_type", "target_column", "prediction_column"),
      optional_fields = c("positive_class", "negative_class", "decision_threshold", "prediction_scale", "weight_column"),
      supported_modes = genai_model_assessment_supported_modes()
    ))
  }
  if (!identical(module_id, genai_registered_analysis_initial_module_id())) {
    return(NULL)
  }
  list(
    configuration_schema_version = "dataset_profile_config_v1",
    allowlisted_fields = c(
      "include_schema", "include_missingness", "include_numeric_summary",
      "include_categorical_summary", "include_diagnostics"
    ),
    required_fields = c(
      "include_schema", "include_missingness", "include_numeric_summary",
      "include_categorical_summary", "include_diagnostics"
    )
  )
}

genai_registered_analysis_default_config <- function(module_id = genai_registered_analysis_initial_module_id()) {
  module_id <- normalize_module_id(module_id)
  if (identical(module_id, genai_registered_analysis_second_module_id())) {
    return(list(
      task_type = "regression",
      target_column = NA_character_,
      prediction_column = NA_character_,
      positive_class = NA_character_,
      negative_class = NA_character_,
      decision_threshold = NA_real_,
      prediction_scale = NA_character_,
      weight_column = NA_character_
    ))
  }
  if (!identical(module_id, genai_registered_analysis_initial_module_id())) {
    return(list())
  }
  list(
    include_schema = TRUE,
    include_missingness = TRUE,
    include_numeric_summary = TRUE,
    include_categorical_summary = TRUE,
    include_diagnostics = TRUE
  )
}

genai_validate_configuration_values <- function(module_id, configuration_values, schema = genai_registered_analysis_config_schema(module_id)) {
  errors <- character()
  warnings <- character()
  module_id <- normalize_module_id(module_id)
  if (is.null(schema)) {
    errors <- c(errors, "No trusted configuration schema exists for this module.")
  }
  if (!is.list(configuration_values)) {
    errors <- c(errors, "Configuration values must be a serializable list.")
    configuration_values <- list()
  }
  allowed <- schema$allowlisted_fields %||% character()
  required <- schema$required_fields %||% character()
  extra <- setdiff(names(configuration_values), allowed)
  missing <- setdiff(required, names(configuration_values))
  if (length(extra)) errors <- c(errors, paste("Configuration contains unsupported fields:", paste(extra, collapse = ", ")))
  if (length(missing)) errors <- c(errors, paste("Configuration is missing required fields:", paste(missing, collapse = ", ")))
  unsafe <- names(configuration_values)[vapply(configuration_values, function(value) {
    is.function(value) || inherits(value, "environment") || inherits(value, "connection") || inherits(value, "formula")
  }, logical(1))]
  if (length(unsafe)) errors <- c(errors, paste("Configuration contains unsupported executable or environment fields:", paste(unsafe, collapse = ", ")))
  non_scalar <- names(configuration_values)[vapply(configuration_values, function(value) length(value) != 1L, logical(1))]
  if (length(non_scalar)) errors <- c(errors, paste("Configuration fields must be scalar:", paste(non_scalar, collapse = ", ")))
  if (identical(module_id, genai_registered_analysis_second_module_id())) {
    task_type <- tolower(as.character(configuration_values$task_type %||% ""))
    target <- as.character(configuration_values$target_column %||% "")
    prediction <- as.character(configuration_values$prediction_column %||% "")
    positive_class <- as.character(configuration_values$positive_class %||% "")
    negative_class <- as.character(configuration_values$negative_class %||% "")
    prediction_scale <- tolower(as.character(configuration_values$prediction_scale %||% ""))
    threshold <- suppressWarnings(as.numeric(configuration_values$decision_threshold %||% NA_real_))
    weight <- as.character(configuration_values$weight_column %||% "")
    mode_id <- genai_model_assessment_mode_from_config(list(task_type = task_type))
    if (!mode_id %in% genai_model_assessment_supported_modes()) errors <- c(errors, "module_configuration_incomplete: only regression and binary classification Model Assessment are enabled.")
    if (!nzchar(target) || is.na(target)) errors <- c(errors, "module_configuration_incomplete: target_column is required.")
    if (!nzchar(prediction) || is.na(prediction)) errors <- c(errors, "module_configuration_incomplete: prediction_column is required.")
    if (nzchar(target) && nzchar(prediction) && identical(target, prediction)) errors <- c(errors, "target_column and prediction_column must differ.")
    if (identical(mode_id, "binary_classification")) {
      if (!nzchar(positive_class) || is.na(positive_class)) errors <- c(errors, "module_configuration_incomplete: positive_class is required for binary classification.")
      if (!identical(prediction_scale, "probability")) errors <- c(errors, "unsupported_prediction_scale: only probability values in [0,1] are supported.")
      if (!is.finite(threshold) || threshold < 0 || threshold > 1) errors <- c(errors, "decision_threshold must be finite and between 0 and 1.")
    }
    configuration_values$task_type <- if (identical(mode_id, "binary_classification")) "binary_classification" else "regression"
    configuration_values$target_column <- target
    configuration_values$prediction_column <- prediction
    configuration_values$positive_class <- if (nzchar(positive_class) && !is.na(positive_class)) positive_class else NA_character_
    configuration_values$negative_class <- if (nzchar(negative_class) && !is.na(negative_class)) negative_class else NA_character_
    configuration_values$decision_threshold <- if (is.finite(threshold)) threshold else NA_real_
    configuration_values$prediction_scale <- if (nzchar(prediction_scale) && !is.na(prediction_scale)) prediction_scale else NA_character_
    configuration_values$weight_column <- if (nzchar(weight) && !is.na(weight)) weight else NA_character_
  } else {
    non_logical <- names(configuration_values)[vapply(configuration_values, function(value) !is.logical(value), logical(1))]
    if (length(non_logical)) errors <- c(errors, paste("Configuration fields must be logical flags:", paste(non_logical, collapse = ", ")))
  }
  service_result(
    status = if (length(errors)) "error" else "success",
    value = configuration_values,
    warnings = warnings,
    errors = errors
  )
}

genai_configuration_fingerprint <- function(snapshot) {
  .genai_action_hash(list(
    module_id = snapshot$module_id %||% NA_character_,
    module_version = snapshot$module_version %||% NA_character_,
    mode_id = snapshot$mode_id %||% NA_character_,
    result_type = snapshot$result_type %||% NA_character_,
    dataset_id = snapshot$dataset_id %||% NA_character_,
    dataset_version = snapshot$dataset_version %||% NA_character_,
    schema_version = snapshot$schema_version %||% NA_character_,
    active_project_id = snapshot$active_project_id %||% NA_character_,
    configuration_schema_version = snapshot$configuration_schema_version %||% NA_character_,
    configuration_values = snapshot$configuration_values %||% list()
  ))
}

genai_normalize_registered_analysis_config <- function(module_id, values) {
  module_id <- normalize_module_id(module_id)
  values <- values %||% list()
  if (identical(module_id, genai_registered_analysis_second_module_id())) {
    problem_type <- tolower(as.character(values$assessment_problem_type %||% values$task_type %||% "regression"))
    task_type <- if (grepl("binary", problem_type)) "binary_classification" else "regression"
    threshold <- suppressWarnings(as.numeric(values$decision_threshold %||% values$threshold %||% values$bmi_threshold %||% 0.5))
    list(
      task_type = task_type,
      target_column = as.character(values$target_column %||% values$actual_var %||% ""),
      prediction_column = as.character(values$prediction_column %||% values$prediction_var %||% ""),
      positive_class = as.character(values$positive_class %||% ""),
      negative_class = as.character(values$negative_class %||% ""),
      decision_threshold = if (identical(task_type, "binary_classification")) threshold else NA_real_,
      prediction_scale = as.character(values$prediction_scale %||% if (identical(task_type, "binary_classification")) "probability" else ""),
      weight_column = as.character(values$weight_column %||% values$case_weight_var %||% "")
    )
  } else {
    values
  }
}

genai_create_configuration_snapshot <- function(module_resolution, dataset_resolution, ctx = NULL) {
  module_id <- module_resolution$module_id %||% ""
  schema <- genai_registered_analysis_config_schema(module_id)
  values <- if (!is.null(ctx) && is.function(ctx$genai_registered_analysis_config)) {
    tryCatch(ctx$genai_registered_analysis_config(module_id), error = function(e) NULL)
  } else {
    NULL
  }
  values <- genai_normalize_registered_analysis_config(module_id, values %||% genai_registered_analysis_default_config(module_id))
  validation <- genai_validate_configuration_values(module_id, values, schema)
  snapshot <- list(
    configuration_snapshot_id = paste0("config_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    module_id = module_id,
    module_version = module_resolution$module_version %||% "unversioned",
    mode_id = if (identical(module_id, genai_registered_analysis_second_module_id())) genai_model_assessment_mode_from_config(values) else NA_character_,
    result_type = genai_module_result_type(module_id, values),
    dataset_id = dataset_resolution$dataset_id %||% "active_dataset",
    dataset_version = dataset_resolution$dataset_version %||% "unavailable",
    schema_version = dataset_resolution$schema_version %||% "schema_missing",
    active_project_id = dataset_resolution$active_project_id %||% genai_active_project_id(ctx),
    configuration_schema_version = schema$configuration_schema_version %||% "unknown",
    configuration_values = values,
    created_at = Sys.time(),
    validation_status = validation$status,
    validation_errors = validation$errors %||% character(),
    validation_warnings = validation$warnings %||% character()
  )
  snapshot$configuration_fingerprint <- genai_configuration_fingerprint(snapshot)
  service_result(
    status = validation$status,
    value = snapshot,
    warnings = validation$warnings,
    errors = validation$errors
  )
}

genai_executable_module_definition <- function(
  module_id,
  module_version,
  display_name,
  genai_execution_enabled = TRUE,
  execution_risk = "medium",
  configuration_schema,
  input_contract,
  output_contract,
  resource_profile,
  supports_progress = TRUE,
  supports_cancellation = TRUE,
  execute_handler
) {
  if (!is.function(execute_handler)) {
    stop("execute_handler must be a function.", call. = FALSE)
  }
  structure(
    list(
      module_id = normalize_module_id(module_id),
      module_version = module_version,
      display_name = display_name,
      genai_execution_enabled = isTRUE(genai_execution_enabled),
      execution_risk = execution_risk,
      configuration_schema = configuration_schema,
      input_contract = input_contract,
      output_contract = output_contract,
      resource_profile = resource_profile,
      supports_progress = isTRUE(supports_progress),
      supports_cancellation = isTRUE(supports_cancellation),
      execute_handler = execute_handler
    ),
    class = c("aq_genai_executable_module", "list")
  )
}

genai_executable_module_registry_create <- function(modules = list()) {
  registry <- new.env(parent = emptyenv())
  for (module in modules) {
    if (!inherits(module, "aq_genai_executable_module")) stop("Executable module is invalid.", call. = FALSE)
    if (exists(module$module_id, envir = registry, inherits = FALSE)) stop(paste("Duplicate executable module id:", module$module_id), call. = FALSE)
    if (is.null(module$output_contract) || !length(module$output_contract)) stop("Executable module requires an output contract.", call. = FALSE)
    if (is.null(module$resource_profile) || !length(module$resource_profile)) stop("Executable module requires a resource profile.", call. = FALSE)
    assign(module$module_id, module, envir = registry)
  }
  registry
}

genai_dataset_profile_execute <- function(data, module_resolution, dataset_resolution, configuration_snapshot, limits, cancel_requested = function() FALSE, progress = function(stage, message) NULL) {
  started <- Sys.time()
  deadline <- started + (limits$max_elapsed_ms / 1000)
  timed_out <- function() Sys.time() > deadline
  check_stop <- function(stage) {
    if (isTRUE(cancel_requested())) {
      return(list(status = "cancelled", stage = stage, message = "Execution was cancelled between bounded stages."))
    }
    if (timed_out()) {
      return(list(status = "timed_out", stage = stage, message = "Execution timed out before all bounded stages completed."))
    }
    NULL
  }
  warnings <- character()
  diagnostics <- list()
  tables <- list()
  rows_total <- nrow(data)
  cols_total <- ncol(data)
  rows_considered <- min(rows_total, limits$max_rows_inspected)
  cols_considered <- min(cols_total, limits$max_columns_inspected)
  inspection_mode <- if (rows_total <= limits$max_rows_inspected && cols_total <= limits$max_columns_inspected) "full_bounded_scan" else "sample"
  inspected <- as.data.frame(data)[seq_len(rows_considered), seq_len(cols_considered), drop = FALSE]

  progress("schema", "Building schema profile.")
  stopped <- check_stop("schema")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  classes <- vapply(inspected, function(x) paste(class(x), collapse = "/"), character(1))
  tables$schema <- utils::head(data.frame(
    column = names(inspected),
    class = classes,
    missing = vapply(inspected, function(x) sum(is.na(x)), integer(1)),
    unique_values = vapply(inspected, function(x) length(unique(x[!is.na(x)])), integer(1)),
    stringsAsFactors = FALSE
  ), limits$max_table_rows)

  progress("missingness", "Computing missingness summary.")
  stopped <- check_stop("missingness")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  miss <- data.frame(
    column = names(inspected),
    missing_count = vapply(inspected, function(x) sum(is.na(x)), integer(1)),
    missing_rate = vapply(inspected, function(x) mean(is.na(x)), numeric(1)),
    stringsAsFactors = FALSE
  )
  miss <- miss[order(-miss$missing_rate, miss$column), , drop = FALSE]
  tables$missingness <- utils::head(miss, limits$max_table_rows)
  if (any(miss$missing_rate >= 0.5)) {
    warnings <- c(warnings, "At least one inspected column has missingness of 50% or higher.")
  }

  progress("numeric", "Computing numeric profile.")
  stopped <- check_stop("numeric")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  numeric_names <- names(inspected)[vapply(inspected, is.numeric, logical(1))]
  if (length(numeric_names)) {
    numeric_summary <- lapply(numeric_names, function(name) {
      x <- inspected[[name]]
      data.frame(
        column = name,
        mean = mean(x, na.rm = TRUE),
        sd = stats::sd(x, na.rm = TRUE),
        min = suppressWarnings(min(x, na.rm = TRUE)),
        median = stats::median(x, na.rm = TRUE),
        max = suppressWarnings(max(x, na.rm = TRUE)),
        stringsAsFactors = FALSE
      )
    })
    tables$numeric_summary <- utils::head(data.table::rbindlist(numeric_summary, fill = TRUE), limits$max_table_rows)
  }

  progress("categorical", "Computing categorical profile.")
  stopped <- check_stop("categorical")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  categorical_names <- names(inspected)[vapply(inspected, function(x) is.character(x) || is.factor(x) || is.logical(x), logical(1))]
  if (length(categorical_names)) {
    categorical_summary <- lapply(categorical_names, function(name) {
      x <- inspected[[name]]
      data.frame(
        column = name,
        unique_values = length(unique(x[!is.na(x)])),
        top_value = names(sort(table(x, useNA = "no"), decreasing = TRUE))[1] %||% NA_character_,
        top_count = as.integer(sort(table(x, useNA = "no"), decreasing = TRUE)[1] %||% NA_integer_),
        stringsAsFactors = FALSE
      )
    })
    tables$categorical_summary <- utils::head(data.table::rbindlist(categorical_summary, fill = TRUE), limits$max_table_rows)
  }

  progress("diagnostics", "Computing bounded diagnostics.")
  stopped <- check_stop("diagnostics")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  constant_cols <- names(inspected)[vapply(inspected, function(x) length(unique(x[!is.na(x)])) <= 1L, logical(1))]
  id_like <- names(inspected)[grepl("(^id$|_id$|id_|uuid|guid)", names(inspected), ignore.case = TRUE)]
  high_cardinality <- names(inspected)[vapply(inspected, function(x) {
    (is.character(x) || is.factor(x)) && length(unique(x[!is.na(x)])) > min(100L, max(10L, floor(length(x) * 0.8)))
  }, logical(1))]
  diagnostics <- list(
    constant_columns = utils::head(constant_cols, limits$max_diagnostics),
    identifier_like_columns = utils::head(id_like, limits$max_diagnostics),
    high_cardinality_columns = utils::head(high_cardinality, limits$max_diagnostics)
  )
  if (length(constant_cols)) warnings <- c(warnings, "Constant columns were detected in the bounded scan.")
  if (length(id_like)) warnings <- c(warnings, "Identifier-like columns were detected by name.")
  if (length(high_cardinality)) warnings <- c(warnings, "High-cardinality categorical columns were detected in the bounded scan.")

  tables <- tables[seq_len(min(length(tables), limits$max_generated_tables))]
  summary <- paste0(
    "Temporary Dataset Profile completed for ", dataset_resolution$display_name %||% dataset_resolution$dataset_id,
    ": ", format(rows_total, big.mark = ","), " rows, ",
    format(cols_total, big.mark = ","), " columns; inspected ",
    format(rows_considered, big.mark = ","), " rows and ",
    format(cols_considered, big.mark = ","), " columns."
  )
  completed <- Sys.time()
  list(
    status = "success",
    summary = summary,
    tables = tables,
    plots = list(),
    diagnostics = diagnostics,
    warnings = utils::head(warnings, limits$max_warnings),
    resource_usage = list(
      configured_limits = limits,
      actual_rows_considered = as.integer(rows_considered),
      actual_columns_considered = as.integer(cols_considered),
      inspection_mode = inspection_mode,
      elapsed_time_ms = as.integer(difftime(completed, started, units = "secs") * 1000),
      result_size = as.integer(nchar(.genai_action_json(tables), type = "bytes"))
    ),
    execution_stages = c("schema", "missingness", "numeric", "categorical", "diagnostics")
  )
}

genai_model_assessment_regression_execute <- function(data, module_resolution, dataset_resolution, configuration_snapshot, limits, cancel_requested = function() FALSE, progress = function(stage, message) NULL) {
  started <- Sys.time()
  deadline <- started + (limits$max_elapsed_ms / 1000)
  timed_out <- function() Sys.time() > deadline
  check_stop <- function(stage) {
    if (isTRUE(cancel_requested())) return(list(status = "cancelled", stage = stage, message = "Execution was cancelled between bounded stages."))
    if (timed_out()) return(list(status = "timed_out", stage = stage, message = "Execution timed out before all bounded stages completed."))
    NULL
  }
  config <- configuration_snapshot$configuration_values %||% list()
  target <- as.character(config$target_column %||% "")
  prediction <- as.character(config$prediction_column %||% "")
  weight <- as.character(config$weight_column %||% "")
  has_weight <- nzchar(weight) && !is.na(weight) && weight %in% names(data)
  warnings <- character()
  diagnostics <- list()
  tables <- list()
  plots <- list()

  progress("validate_configuration", "Validating trusted regression assessment configuration.")
  stopped <- check_stop("validate_configuration")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  if (!target %in% names(data) || !prediction %in% names(data)) {
    stop("Trusted target or prediction column is missing from active dataset.", call. = FALSE)
  }
  rows_total <- nrow(data)
  rows_considered <- min(rows_total, limits$max_rows_inspected)
  bounded <- as.data.frame(data)[seq_len(rows_considered), c(target, prediction, if (has_weight) weight else character()), drop = FALSE]
  y <- bounded[[target]]
  p <- bounded[[prediction]]
  w <- if (has_weight) bounded[[weight]] else rep(1, length(y))
  valid <- is.finite(y) & is.finite(p) & is.finite(w) & !is.na(w) & w >= 0
  y <- as.numeric(y[valid])
  p <- as.numeric(p[valid])
  w <- as.numeric(w[valid])
  if (!length(y) || length(y) < 5L) stop("No sufficient complete finite target/prediction pairs are available.", call. = FALSE)
  if (sum(w) <= 0) stop("Configured weights have nonpositive sum.", call. = FALSE)
  residual <- y - p
  abs_residual <- abs(residual)

  progress("compute_core_metrics", "Computing bounded regression metrics.")
  stopped <- check_stop("compute_core_metrics")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  wmean <- function(x) sum(w * x, na.rm = TRUE) / sum(w, na.rm = TRUE)
  mae <- wmean(abs_residual)
  mse <- wmean(residual^2)
  rmse <- sqrt(mse)
  mean_target <- wmean(y)
  mean_prediction <- wmean(p)
  bias <- mean_prediction - mean_target
  sse <- sum(w * residual^2)
  sst <- sum(w * (y - mean_target)^2)
  r_squared <- if (isTRUE(sst > 0)) 1 - (sse / sst) else NA_real_
  metric_summary <- data.frame(
    metric = c("rows_total", "complete_pairs", "mae", "mse", "rmse", "median_absolute_error", "r_squared", "mean_target", "mean_prediction", "prediction_bias"),
    value = c(rows_total, length(y), mae, mse, rmse, stats::median(abs_residual), r_squared, mean_target, mean_prediction, bias),
    stringsAsFactors = FALSE
  )
  tables$metric_summary <- metric_summary

  progress("compute_residual_diagnostics", "Computing residual diagnostics.")
  stopped <- check_stop("compute_residual_diagnostics")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  residual_summary <- data.frame(
    statistic = c("mean", "median", "sd", "p05", "p25", "p50", "p75", "p95", "abs_p50", "abs_p90", "abs_p95"),
    value = c(
      mean(residual), stats::median(residual), stats::sd(residual),
      as.numeric(stats::quantile(residual, 0.05, na.rm = TRUE)),
      as.numeric(stats::quantile(residual, 0.25, na.rm = TRUE)),
      as.numeric(stats::quantile(residual, 0.50, na.rm = TRUE)),
      as.numeric(stats::quantile(residual, 0.75, na.rm = TRUE)),
      as.numeric(stats::quantile(residual, 0.95, na.rm = TRUE)),
      as.numeric(stats::quantile(abs_residual, 0.50, na.rm = TRUE)),
      as.numeric(stats::quantile(abs_residual, 0.90, na.rm = TRUE)),
      as.numeric(stats::quantile(abs_residual, 0.95, na.rm = TRUE))
    ),
    stringsAsFactors = FALSE
  )
  tables$residual_summary <- residual_summary
  diagnostics <- list(
    target_column = target,
    prediction_column = prediction,
    weight_column = if (has_weight) weight else NA_character_,
    complete_pair_count = as.integer(length(y)),
    excluded_row_count = as.integer(rows_considered - length(y)),
    missing_or_nonfinite_rate = round((rows_considered - length(y)) / max(1L, rows_considered), 4),
    target_constant = length(unique(y)) <= 1L,
    prediction_constant = length(unique(p)) <= 1L,
    prediction_bias = bias
  )
  if (isTRUE(diagnostics$prediction_constant)) warnings <- c(warnings, "Predictions are constant across complete pairs.")
  if (abs(bias) > stats::sd(y, na.rm = TRUE)) warnings <- c(warnings, "Prediction bias is larger than the target standard deviation.")

  progress("build_bounded_tables", "Building bounded diagnostic tables.")
  stopped <- check_stop("build_bounded_tables")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  bins <- min(10L, max(2L, length(unique(p))))
  cut_points <- unique(stats::quantile(p, probs = seq(0, 1, length.out = bins + 1L), na.rm = TRUE))
  if (length(cut_points) > 2L) {
    bin <- cut(p, breaks = cut_points, include.lowest = TRUE, ordered_result = TRUE)
    binned <- data.frame(bin = bin, target = y, prediction = p, residual = residual, abs_residual = abs_residual)
    bin_summary <- stats::aggregate(
      binned[, c("target", "prediction", "residual", "abs_residual")],
      by = list(bin = binned$bin),
      FUN = mean
    )
    bin_counts <- stats::aggregate(rep(1, nrow(binned)), by = list(bin = binned$bin), FUN = sum)
    names(bin_counts)[2] <- "n"
    tables$observed_vs_predicted_bins <- merge(bin_counts, bin_summary, by = "bin", all.x = TRUE)
  }
  sample_n <- min(length(y), limits$max_sample_rows)
  sample_index <- unique(round(seq(1, length(y), length.out = sample_n)))
  tables$observed_vs_predicted_sample <- utils::head(data.frame(
    observed = y[sample_index],
    predicted = p[sample_index],
    residual = residual[sample_index],
    stringsAsFactors = FALSE
  ), limits$max_table_rows)

  progress("construct_plot_specs", "Constructing safe bounded plot specifications.")
  stopped <- check_stop("construct_plot_specs")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  plots$observed_vs_predicted <- list(
    plot_id = "observed_vs_predicted",
    plot_type = "scatter",
    title = "Observed vs Predicted",
    x_label = "Predicted",
    y_label = "Observed",
    bounded_data = data.frame(observed = y[sample_index], predicted = p[sample_index], residual = residual[sample_index], stringsAsFactors = FALSE)
  )
  plots$residual_distribution <- list(
    plot_id = "residual_distribution",
    plot_type = "histogram",
    title = "Residual Distribution",
    x_label = "Residual",
    y_label = "Count",
    bounded_data = data.frame(residual = residual[sample_index], stringsAsFactors = FALSE)
  )

  tables <- tables[seq_len(min(length(tables), limits$max_generated_tables))]
  completed <- Sys.time()
  summary <- paste0(
    "Temporary Regression Model Assessment completed for ", dataset_resolution$display_name %||% dataset_resolution$dataset_id,
    ": RMSE ", signif(rmse, 4), ", MAE ", signif(mae, 4),
    ", complete pairs ", format(length(y), big.mark = ","), "."
  )
  list(
    status = "success",
    summary = summary,
    metrics = as.list(stats::setNames(metric_summary$value, metric_summary$metric)),
    tables = tables,
    plots = plots,
    diagnostics = diagnostics,
    warnings = utils::head(warnings, limits$max_warnings),
    resource_usage = list(
      configured_limits = limits,
      actual_rows_considered = as.integer(rows_considered),
      actual_columns_considered = as.integer(length(c(target, prediction, if (has_weight) weight else character()))),
      inspection_mode = if (rows_total <= limits$max_rows_inspected) "full_bounded_scan" else "sample",
      elapsed_time_ms = as.integer(difftime(completed, started, units = "secs") * 1000),
      result_size = as.integer(nchar(.genai_action_json(list(tables = tables, plots = plots, diagnostics = diagnostics)), type = "bytes"))
    ),
    execution_stages = c("validate_configuration", "compute_core_metrics", "compute_residual_diagnostics", "build_bounded_tables", "construct_plot_specs")
  )
}

genai_model_assessment_binary_execute <- function(data, module_resolution, dataset_resolution, configuration_snapshot, limits, cancel_requested = function() FALSE, progress = function(stage, message) NULL) {
  started <- Sys.time()
  deadline <- started + (limits$max_elapsed_ms / 1000)
  timed_out <- function() Sys.time() > deadline
  check_stop <- function(stage) {
    if (isTRUE(cancel_requested())) return(list(status = "cancelled", stage = stage, message = "Execution was cancelled between bounded stages."))
    if (timed_out()) return(list(status = "timed_out", stage = stage, message = "Execution timed out before all bounded stages completed."))
    NULL
  }
  config <- configuration_snapshot$configuration_values %||% list()
  target <- as.character(config$target_column %||% "")
  prediction <- as.character(config$prediction_column %||% "")
  positive <- as.character(config$positive_class %||% "")
  threshold <- suppressWarnings(as.numeric(config$decision_threshold %||% 0.5))
  scale <- tolower(as.character(config$prediction_scale %||% ""))
  weight <- as.character(config$weight_column %||% "")
  has_weight <- nzchar(weight) && !is.na(weight) && weight %in% names(data)
  warnings <- character()
  diagnostics <- list()
  tables <- list()
  plots <- list()

  progress("validate_configuration", "Validating trusted binary assessment configuration.")
  stopped <- check_stop("validate_configuration")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  if (!identical(config$task_type %||% "", "binary_classification")) stop("Trusted task type is not binary_classification.", call. = FALSE)
  if (!target %in% names(data) || !prediction %in% names(data)) stop("Trusted target or probability prediction column is missing from active dataset.", call. = FALSE)
  if (!identical(scale, "probability")) stop("unsupported_prediction_scale: only probability values in [0,1] are supported.", call. = FALSE)
  if (!is.finite(threshold) || threshold < 0 || threshold > 1) stop("Trusted threshold is outside [0,1].", call. = FALSE)

  progress("resolve_bounded_data", "Resolving bounded scored-output data.")
  stopped <- check_stop("resolve_bounded_data")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  rows_total <- nrow(data)
  rows_considered <- min(rows_total, limits$max_rows_inspected)
  bounded <- as.data.frame(data)[seq_len(rows_considered), c(target, prediction, if (has_weight) weight else character()), drop = FALSE]
  y_label <- genai_binary_class_labels(bounded[[target]])
  p <- as.numeric(bounded[[prediction]])
  w <- if (has_weight) as.numeric(bounded[[weight]]) else rep(1, length(p))
  classes <- sort(unique(y_label[!is.na(y_label) & nzchar(y_label)]))
  negative <- setdiff(classes, positive)
  if (length(classes) != 2L || !positive %in% classes || length(negative) != 1L) stop("Trusted positive class does not define a binary class mapping.", call. = FALSE)
  y01 <- as.integer(y_label == positive)
  valid <- !is.na(y01) & is.finite(p) & p >= 0 & p <= 1 & is.finite(w) & !is.na(w) & w >= 0
  y01 <- y01[valid]
  p <- p[valid]
  w <- w[valid]
  if (length(y01) < 5L || length(unique(y01)) != 2L) stop("Insufficient complete positive and negative target/probability pairs.", call. = FALSE)
  if (sum(w) <= 0) stop("Configured weights have nonpositive sum.", call. = FALSE)

  progress("compute_core_metrics", "Computing binary ranking, probability, and threshold metrics.")
  stopped <- check_stop("compute_core_metrics")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  eps <- 1e-15
  p_clip <- pmin(pmax(p, eps), 1 - eps)
  pred01 <- as.integer(p >= threshold)
  tp <- sum(w[pred01 == 1L & y01 == 1L])
  tn <- sum(w[pred01 == 0L & y01 == 0L])
  fp <- sum(w[pred01 == 1L & y01 == 0L])
  fn <- sum(w[pred01 == 0L & y01 == 1L])
  safe_rate <- function(num, den) if (is.finite(den) && den > 0) num / den else NA_real_
  sensitivity <- safe_rate(tp, tp + fn)
  specificity <- safe_rate(tn, tn + fp)
  precision <- safe_rate(tp, tp + fp)
  npv <- safe_rate(tn, tn + fn)
  accuracy <- safe_rate(tp + tn, tp + tn + fp + fn)
  f1 <- if (is.finite(precision + sensitivity) && (precision + sensitivity) > 0) 2 * precision * sensitivity / (precision + sensitivity) else NA_real_
  brier <- sum(w * (p - y01)^2) / sum(w)
  log_loss <- -sum(w * (y01 * log(p_clip) + (1 - y01) * log(1 - p_clip))) / sum(w)
  roc_auc <- genai_binary_auc(y01, p, w)
  pr_auc <- NA_real_
  weighted_complete_pairs <- sum(w)
  metrics <- list(
    rows_total = rows_total,
    complete_pairs = length(y01),
    weighted_complete_pairs = weighted_complete_pairs,
    positive_count = sum(y01 == 1L),
    negative_count = sum(y01 == 0L),
    observed_positive_rate = mean(y01 == 1L),
    mean_predicted_probability = mean(p),
    prediction_bias = mean(p) - mean(y01 == 1L),
    roc_auc = roc_auc,
    pr_auc = pr_auc,
    brier_score = brier,
    log_loss = log_loss,
    threshold = threshold,
    true_positives = tp,
    true_negatives = tn,
    false_positives = fp,
    false_negatives = fn,
    sensitivity = sensitivity,
    specificity = specificity,
    precision = precision,
    negative_predictive_value = npv,
    accuracy = accuracy,
    balanced_accuracy = mean(c(sensitivity, specificity), na.rm = TRUE),
    f1 = f1,
    false_positive_rate = safe_rate(fp, fp + tn),
    false_negative_rate = safe_rate(fn, fn + tp)
  )
  threshold_metrics <- data.frame(
    threshold = threshold,
    true_positives = tp,
    true_negatives = tn,
    false_positives = fp,
    false_negatives = fn,
    sensitivity = sensitivity,
    specificity = specificity,
    precision = precision,
    accuracy = accuracy,
    balanced_accuracy = metrics$balanced_accuracy,
    f1 = f1,
    stringsAsFactors = FALSE
  )
  tables$confusion_matrix <- data.frame(
    actual = c(positive, positive, negative[[1]], negative[[1]]),
    predicted = c(positive, negative[[1]], positive, negative[[1]]),
    count = c(tp, fn, fp, tn),
    stringsAsFactors = FALSE
  )
  tables$threshold_metrics <- threshold_metrics

  progress("compute_calibration_lift", "Computing bounded calibration and lift diagnostics.")
  stopped <- check_stop("compute_calibration_lift")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  bin_count <- min(10L, max(2L, length(unique(p))))
  cuts <- unique(stats::quantile(p, probs = seq(0, 1, length.out = bin_count + 1L), na.rm = TRUE))
  if (length(cuts) > 2L) {
    probability_bin <- cut(p, breaks = cuts, include.lowest = TRUE, ordered_result = TRUE)
    cal <- data.frame(probability_bin = probability_bin, observed = y01, probability = p, weight = w)
    cal_summary <- stats::aggregate(cal[, c("observed", "probability", "weight")], by = list(probability_bin = cal$probability_bin), FUN = mean)
    cal_counts <- stats::aggregate(w, by = list(probability_bin = cal$probability_bin), FUN = sum)
    names(cal_counts)[2] <- "weighted_count"
    tables$calibration_bins <- merge(cal_counts, cal_summary[, c("probability_bin", "observed", "probability")], by = "probability_bin", all.x = TRUE)
  }
  order_idx <- order(p, decreasing = TRUE)
  groups <- cut(seq_along(order_idx), breaks = min(10L, length(order_idx)), labels = FALSE, include.lowest = TRUE)
  lift_input <- data.frame(rank_bin = groups, observed = y01[order_idx], probability = p[order_idx], weight = w[order_idx])
  lift <- stats::aggregate(lift_input[, c("observed", "probability", "weight")], by = list(rank_bin = lift_input$rank_bin), FUN = sum)
  lift$positive_rate <- ifelse(lift$weight > 0, lift$observed / lift$weight, NA_real_)
  lift$cumulative_positives <- cumsum(lift$observed)
  lift$cumulative_weight <- cumsum(lift$weight)
  lift$cumulative_gain <- lift$cumulative_positives / max(1e-12, sum(lift_input$observed))
  lift$lift <- lift$positive_rate / max(1e-12, mean(y01))
  tables$lift_bins <- utils::head(lift, limits$max_table_rows)
  curves <- genai_binary_curve_tables(y01, p, w, max_points = min(100L, limits$max_sample_rows))

  progress("construct_plot_specs", "Constructing safe bounded binary plot specifications.")
  stopped <- check_stop("construct_plot_specs")
  if (!is.null(stopped)) return(c(stopped, list(warnings = warnings, diagnostics = diagnostics)))
  plots$roc_curve <- list(plot_id = "roc_curve", plot_type = "line", title = "ROC Curve", x_label = "False Positive Rate", y_label = "True Positive Rate", bounded_data = utils::head(curves$roc, limits$max_sample_rows))
  plots$precision_recall_curve <- list(plot_id = "precision_recall_curve", plot_type = "line", title = "Precision-Recall Curve", x_label = "Recall", y_label = "Precision", bounded_data = utils::head(curves$pr, limits$max_sample_rows))
  if (!is.null(tables$calibration_bins)) {
    plots$calibration <- list(plot_id = "calibration", plot_type = "line", title = "Calibration by Probability Bin", x_label = "Mean Predicted Probability", y_label = "Observed Positive Rate", bounded_data = tables$calibration_bins)
  }
  plots$lift <- list(plot_id = "lift", plot_type = "line", title = "Lift by Rank Bin", x_label = "Rank Bin", y_label = "Lift", bounded_data = tables$lift_bins)
  sample_n <- min(length(y01), limits$max_sample_rows)
  sample_idx <- unique(round(seq(1, length(y01), length.out = sample_n)))
  plots$probability_distribution <- list(plot_id = "probability_distribution", plot_type = "histogram", title = "Predicted Probability Distribution by Observed Class", x_label = "Predicted Probability", y_label = "Count", bounded_data = data.frame(observed_class = ifelse(y01[sample_idx] == 1L, positive, negative[[1]]), probability = p[sample_idx], stringsAsFactors = FALSE))
  diagnostics <- list(
    mode_id = "binary_classification",
    target_column = target,
    prediction_column = prediction,
    positive_class = positive,
    negative_class = negative[[1]],
    decision_threshold = threshold,
    prediction_scale = scale,
    complete_pair_count = as.integer(length(y01)),
    excluded_row_count = as.integer(rows_considered - length(y01)),
    class_balance = list(positive = sum(y01 == 1L), negative = sum(y01 == 0L)),
    probability_range = range(p),
    probability_constant = length(unique(p)) <= 1L,
    calibration_bins = nrow(tables$calibration_bins %||% data.frame()),
    lift_bins = nrow(tables$lift_bins %||% data.frame())
  )
  if (isTRUE(diagnostics$probability_constant)) warnings <- c(warnings, "Predicted probabilities are constant across complete pairs.")
  if (min(diagnostics$class_balance$positive, diagnostics$class_balance$negative) < 10L) warnings <- c(warnings, "Binary target has a small class count in the bounded execution data.")
  tables$metric_summary <- data.frame(metric = names(metrics), value = unlist(metrics, use.names = FALSE), stringsAsFactors = FALSE)
  tables <- tables[seq_len(min(length(tables), limits$max_generated_tables))]
  plots <- plots[seq_len(min(length(plots), limits$max_generated_plots))]
  completed <- Sys.time()
  summary <- paste0(
    "Temporary Binary Classification Model Assessment completed for ", dataset_resolution$display_name %||% dataset_resolution$dataset_id,
    ": ROC AUC ", signif(roc_auc, 4), ", Brier ", signif(brier, 4),
    ", threshold ", signif(threshold, 4), ", complete pairs ", format(length(y01), big.mark = ","), "."
  )
  list(
    status = "success",
    summary = summary,
    metrics = metrics,
    threshold_metrics = threshold_metrics,
    tables = tables,
    plots = plots,
    diagnostics = diagnostics,
    warnings = utils::head(warnings, limits$max_warnings),
    resource_usage = list(
      configured_limits = limits,
      actual_rows_considered = as.integer(rows_considered),
      actual_columns_considered = as.integer(length(c(target, prediction, if (has_weight) weight else character()))),
      inspection_mode = if (rows_total <= limits$max_rows_inspected) "full_bounded_scan" else "sample",
      elapsed_time_ms = as.integer(difftime(completed, started, units = "secs") * 1000),
      result_size = as.integer(nchar(.genai_action_json(list(metrics = metrics, tables = tables, plots = plots, diagnostics = diagnostics)), type = "bytes"))
    ),
    execution_stages = c("validate_configuration", "resolve_bounded_data", "compute_core_metrics", "compute_calibration_lift", "construct_plot_specs")
  )
}

genai_model_assessment_execute <- function(data, module_resolution, dataset_resolution, configuration_snapshot, limits, cancel_requested = function() FALSE, progress = function(stage, message) NULL) {
  mode_id <- configuration_snapshot$mode_id %||% genai_model_assessment_mode_from_config(configuration_snapshot$configuration_values %||% list())
  if (identical(mode_id, "binary_classification")) {
    return(genai_model_assessment_binary_execute(data, module_resolution, dataset_resolution, configuration_snapshot, limits, cancel_requested, progress))
  }
  if (identical(mode_id, "regression")) {
    return(genai_model_assessment_regression_execute(data, module_resolution, dataset_resolution, configuration_snapshot, limits, cancel_requested, progress))
  }
  stop("Unsupported trusted Model Assessment mode.", call. = FALSE)
}

genai_executable_module_registry <- function() {
  module <- get_module_definition(genai_registered_analysis_initial_module_id())
  assessment_module <- get_module_definition(genai_registered_analysis_second_module_id())
  genai_executable_module_registry_create(list(
    genai_executable_module_definition(
      module_id = "dataset_profile",
      module_version = genai_module_version(module),
      display_name = module$label %||% "Dataset Profile",
      genai_execution_enabled = TRUE,
      execution_risk = "medium",
      configuration_schema = genai_registered_analysis_config_schema("dataset_profile"),
      input_contract = list(dataset_id = "active_dataset", no_model_supplied_configuration = TRUE),
      output_contract = list(
        required_fields = c("status", "summary", "tables", "diagnostics", "warnings", "resource_usage"),
        max_generated_plots = 0L,
        temporary_only = TRUE,
        raw_rows_allowed = FALSE
      ),
      resource_profile = genai_registered_analysis_limits(),
      supports_progress = TRUE,
      supports_cancellation = TRUE,
      execute_handler = genai_dataset_profile_execute
    ),
    genai_executable_module_definition(
      module_id = genai_registered_analysis_second_module_id(),
      module_version = genai_module_version(assessment_module),
      display_name = assessment_module$label %||% "Model Assessment",
      genai_execution_enabled = TRUE,
      execution_risk = "medium",
      configuration_schema = genai_registered_analysis_config_schema(genai_registered_analysis_second_module_id()),
      input_contract = list(dataset_id = "active_dataset", no_model_supplied_configuration = TRUE, enabled_modes = genai_model_assessment_supported_modes()),
      output_contract = list(
        required_fields = genai_result_required_output_fields(genai_model_assessment_regression_result_type()),
        max_generated_plots = 5L,
        temporary_only = TRUE,
        raw_rows_allowed = FALSE,
        supported_result_types = genai_module_supported_result_types(genai_registered_analysis_second_module_id())
      ),
      resource_profile = genai_registered_analysis_limits(max_generated_plots = 5L, max_generated_tables = 6L),
      supports_progress = TRUE,
      supports_cancellation = TRUE,
      execute_handler = genai_model_assessment_execute
    )
  ))
}

genai_executable_module_get <- function(module_id, registry = genai_executable_module_registry()) {
  module_id <- normalize_module_id(module_id)
  if (!exists(module_id, envir = registry, inherits = FALSE)) return(NULL)
  get(module_id, envir = registry, inherits = FALSE)
}

genai_executable_module_metadata <- function(registry = genai_executable_module_registry()) {
  modules <- lapply(ls(registry, all.names = TRUE), function(id) {
    module <- get(id, envir = registry, inherits = FALSE)
    data.table::data.table(
      module_id = module$module_id,
      module_version = module$module_version,
      display_name = module$display_name,
      genai_execution_enabled = isTRUE(module$genai_execution_enabled),
      execution_risk = module$execution_risk,
      supports_progress = isTRUE(module$supports_progress),
      supports_cancellation = isTRUE(module$supports_cancellation)
    )
  })
  data.table::rbindlist(modules, fill = TRUE)
}

genai_resolve_registered_analysis_resources <- function(module_id, dataset_id, ctx = NULL) {
  module_resolution <- genai_resolve_module_for_preflight(module_id, ctx = ctx)
  dataset_resolution <- genai_resolve_dataset(dataset_id, ctx = ctx)
  errors <- c(module_resolution$errors %||% character(), dataset_resolution$errors %||% character())
  warnings <- c(module_resolution$warnings %||% character(), dataset_resolution$warnings %||% character())
  executable <- genai_executable_module_get(module_id)
  if (is.null(executable)) {
    errors <- c(errors, "module_not_enabled_for_genai_execution")
  }
  if (!is.null(executable) && !isTRUE(executable$genai_execution_enabled)) {
    errors <- c(errors, "module_not_enabled_for_genai_execution")
  }
  snapshot <- if (!length(errors)) {
    genai_create_configuration_snapshot(module_resolution$value, dataset_resolution$value, ctx = ctx)
  } else {
    service_result(status = "error", errors = errors)
  }
  if (!identical(snapshot$status, "success")) {
    errors <- c(errors, snapshot$errors %||% "Configuration snapshot is invalid.")
    warnings <- c(warnings, snapshot$warnings %||% character())
  }
  preflight <- if (!length(errors)) {
    genai_resolve_or_run_registered_preflight(module_resolution$value, dataset_resolution$value, dataset_resolution$metadata$data, ctx = ctx)
  } else {
    service_result(status = "error", errors = errors)
  }
  if (!identical(preflight$status, "success")) {
    errors <- c(errors, preflight$errors %||% "Preflight binding is not acceptable.")
    warnings <- c(warnings, preflight$warnings %||% character())
  }
  value <- c(
    list(resource_type = "analysis_run_registered"),
    module_resolution$value %||% list(),
    list(
      dataset_id = dataset_resolution$value$dataset_id %||% dataset_id,
      dataset_display_name = dataset_resolution$value$display_name %||% dataset_id,
      dataset_version = dataset_resolution$value$dataset_version %||% NA_character_,
      schema_version = dataset_resolution$value$schema_version %||% NA_character_,
      dataset_availability = dataset_resolution$value$availability %||% NA_character_,
      row_count = dataset_resolution$value$row_count %||% NA_integer_,
      column_count = dataset_resolution$value$column_count %||% NA_integer_,
      active_project_id = dataset_resolution$value$active_project_id %||% genai_active_project_id(ctx),
      mode_id = snapshot$value$mode_id %||% NA_character_,
      result_type = snapshot$value$result_type %||% NA_character_,
      configuration_snapshot_id = snapshot$value$configuration_snapshot_id %||% NA_character_,
      configuration_schema_version = snapshot$value$configuration_schema_version %||% NA_character_,
      configuration_fingerprint = snapshot$value$configuration_fingerprint %||% NA_character_,
      preflight_result_id = preflight$value$preflight_result_id %||% NA_character_,
      preflight_readiness = preflight$value$readiness %||% NA_character_,
      preflight_fingerprint = preflight$value$preflight_fingerprint %||% NA_character_
    )
  )
  value$resource_fingerprint <- genai_registered_analysis_execution_fingerprint(value)
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(
      module_resolution = module_resolution,
      dataset_resolution = dataset_resolution,
      configuration_snapshot = snapshot$value,
      preflight = preflight$value,
      executable_module = executable,
      data = dataset_resolution$metadata$data
    )
  )
}

genai_registered_analysis_preflight_matches <- function(preflight, module_resolution, dataset_resolution) {
  if (is.null(preflight) || !is.list(preflight)) return(FALSE)
  identical(preflight$module_id %||% "", module_resolution$module_id %||% "") &&
    identical(preflight$dataset_id %||% "", dataset_resolution$dataset_id %||% "") &&
    identical(preflight$active_project_id %||% "", dataset_resolution$active_project_id %||% "") &&
    (preflight$module_version %||% module_resolution$module_version %||% "") == (module_resolution$module_version %||% "") &&
    (preflight$dataset_version %||% dataset_resolution$dataset_version %||% "") == (dataset_resolution$dataset_version %||% "") &&
    (preflight$schema_version %||% dataset_resolution$schema_version %||% "") == (dataset_resolution$schema_version %||% "")
}

genai_resolve_or_run_registered_preflight <- function(module_resolution, dataset_resolution, data, ctx = NULL) {
  acceptable <- c("ready", "ready_with_warnings")
  snapshot <- genai_create_configuration_snapshot(module_resolution, dataset_resolution, ctx = ctx)
  if (!identical(snapshot$status, "success")) {
    return(service_result(status = "error", value = snapshot$value, warnings = snapshot$warnings, errors = c("module_configuration_incomplete", snapshot$errors %||% character())))
  }
  stored <- if (!is.null(ctx) && !is.null(ctx$genai_preflight_state$results)) {
    tryCatch(ctx$genai_preflight_state$results, error = function(e) list())
  } else {
    list()
  }
  matches <- Filter(function(item) {
    genai_registered_analysis_preflight_matches(item, module_resolution, dataset_resolution) &&
      (item$readiness %||% "") %in% acceptable
  }, stored)
  if (length(matches)) {
    item <- matches[[length(matches)]]
    item$preflight_fingerprint <- genai_preflight_resource_fingerprint(module_resolution, dataset_resolution)
    if (identical(module_resolution$module_id %||% "", genai_registered_analysis_second_module_id()) &&
        !identical(item$configuration_fingerprint %||% "", snapshot$value$configuration_fingerprint %||% "")) {
      matches <- list()
    } else {
    return(service_result(status = "success", value = item, warnings = item$warnings %||% character()))
    }
  }
  limits <- if (!is.null(ctx) && is.function(ctx$genai_preflight_limits)) ctx$genai_preflight_limits() else genai_preflight_limits()
  preflight <- if (identical(module_resolution$module_id %||% "", genai_registered_analysis_second_module_id())) {
    mode_id <- snapshot$value$mode_id %||% genai_model_assessment_mode_from_config(snapshot$value$configuration_values)
    if (identical(mode_id, "binary_classification")) {
      genai_run_model_assessment_binary_preflight(
        module_resolution = module_resolution,
        dataset_resolution = dataset_resolution,
        data = data,
        configuration_snapshot = snapshot$value,
        limits = limits,
        cancel_requested = function() FALSE
      )
    } else {
      genai_run_model_assessment_regression_preflight(
        module_resolution = module_resolution,
        dataset_resolution = dataset_resolution,
        data = data,
        configuration_snapshot = snapshot$value,
        limits = limits,
        cancel_requested = function() FALSE
      )
    }
  } else {
    genai_run_generic_preflight(
      module_resolution = module_resolution,
      dataset_resolution = dataset_resolution,
      data = data,
      limits = limits,
      cancel_requested = function() FALSE
    )
  }
  preflight_id <- paste0("preflight_internal_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
  result <- list(
    preflight_result_id = preflight_id,
    module_id = module_resolution$module_id,
    module_version = module_resolution$module_version,
    module_display_name = module_resolution$display_name,
    dataset_id = dataset_resolution$dataset_id,
    dataset_version = dataset_resolution$dataset_version,
    schema_version = dataset_resolution$schema_version,
    dataset_display_name = dataset_resolution$display_name,
    active_project_id = dataset_resolution$active_project_id,
    readiness = preflight$readiness,
    checks = preflight$checks,
    warnings = preflight$warnings %||% character(),
    errors = preflight$errors %||% character(),
    preflight_fingerprint = genai_preflight_resource_fingerprint(module_resolution, dataset_resolution),
    configuration_snapshot_id = snapshot$value$configuration_snapshot_id,
    configuration_fingerprint = snapshot$value$configuration_fingerprint,
    configuration_schema_version = snapshot$value$configuration_schema_version,
    resource_assessment = list(
      rows_considered = preflight$rows_considered %||% 0L,
      columns_considered = preflight$columns_considered %||% 0L,
      inspection_mode = preflight$inspection_mode %||% "metadata"
    )
  )
  if (!is.null(ctx) && is.function(ctx$store_genai_preflight_result)) {
    result$preflight_result_id <- ctx$store_genai_preflight_result(result)
  }
  if (!result$readiness %in% acceptable) {
    return(service_result(status = "error", value = result, warnings = result$warnings, errors = c("Preflight is not acceptable for execution:", result$readiness)))
  }
  service_result(status = "success", value = result, warnings = result$warnings)
}

genai_registered_analysis_execution_fingerprint <- function(value, limits = NULL) {
  .genai_action_hash(list(
    resource_type = "analysis_run_registered",
    active_project_id = value$active_project_id %||% NA_character_,
    module_id = value$module_id %||% NA_character_,
    module_version = value$module_version %||% NA_character_,
    mode_id = value$mode_id %||% NA_character_,
    result_type = value$result_type %||% NA_character_,
    dataset_id = value$dataset_id %||% NA_character_,
    dataset_version = value$dataset_version %||% NA_character_,
    schema_version = value$schema_version %||% NA_character_,
    configuration_fingerprint = value$configuration_fingerprint %||% NA_character_,
    preflight_result_id = value$preflight_result_id %||% NA_character_,
    preflight_fingerprint = value$preflight_fingerprint %||% NA_character_,
    execution_limits = limits %||% list(),
    policy_module = genai_registered_analysis_initial_module_id()
  ))
}

genai_create_registered_analysis_job <- function(proposal, resolution, execution_id) {
  now <- Sys.time()
  list(
    job_id = paste0("job_", format(now, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    execution_id = execution_id,
    proposal_id = proposal$proposal_id,
    action_id = proposal$action_id,
    module_id = resolution$module_id,
    dataset_id = resolution$dataset_id,
    configuration_snapshot_id = resolution$configuration_snapshot_id,
    status = "queued",
    created_at = now,
    started_at = NA,
    completed_at = NA,
    progress_stage = "queued",
    progress_message = "Queued for approved execution.",
    cancel_requested = FALSE,
    timed_out = FALSE,
    error = NA_character_,
    temporary_result_id = NA_character_
  )
}

genai_validate_registered_analysis_output <- function(output, limits = genai_registered_analysis_limits(), result_type = "dataset_profile") {
  errors <- character()
  required <- genai_result_required_output_fields(result_type)
  missing <- setdiff(required, names(output))
  if (length(missing)) errors <- c(errors, paste("Output missing required fields:", paste(missing, collapse = ", ")))
  plots <- output$plots %||% list()
  if (length(plots) > limits$max_generated_plots) errors <- c(errors, "Output contains too many plots.")
  for (plot_name in names(plots)) {
    plot <- plots[[plot_name]]
    if (!is.list(plot) || any(vapply(plot, function(value) is.function(value) || inherits(value, "environment") || inherits(value, "htmlwidget"), logical(1)))) {
      errors <- c(errors, paste("Output plot spec has unsupported content:", plot_name))
    }
    if (!all(c("plot_id", "plot_type", "title", "bounded_data") %in% names(plot))) {
      errors <- c(errors, paste("Output plot spec missing required fields:", plot_name))
    }
    bounded <- plot$bounded_data
    if (!(is.data.frame(bounded) || data.table::is.data.table(bounded))) {
      errors <- c(errors, paste("Output plot spec bounded_data is not tabular:", plot_name))
    } else if (nrow(bounded) > limits$max_sample_rows) {
      errors <- c(errors, paste("Output plot spec exceeds point limit:", plot_name))
    }
  }
  tables <- output$tables %||% list()
  if (length(tables) > limits$max_generated_tables) errors <- c(errors, "Output contains too many tables.")
  for (table_name in names(tables)) {
    table <- tables[[table_name]]
    if (!(is.data.frame(table) || data.table::is.data.table(table))) {
      errors <- c(errors, paste("Output table has unsupported type:", table_name))
    } else if (nrow(table) > limits$max_table_rows) {
      errors <- c(errors, paste("Output table exceeds row limit:", table_name))
    }
  }
  unsafe <- vapply(output, function(value) is.function(value) || inherits(value, "environment"), logical(1))
  if (any(unsafe)) errors <- c(errors, "Output contains executable functions or environments.")
  if (!is.null(output$data) || !is.null(output$dataset) || !is.null(output$raw_rows)) errors <- c(errors, "Output contains raw dataset or raw row payload fields.")
  if (result_type %in% genai_module_supported_result_types(genai_registered_analysis_second_module_id())) {
    metrics <- output$metrics %||% list()
    bad_metrics <- names(metrics)[!vapply(metrics, function(value) is.numeric(value) && length(value) == 1L, logical(1))]
    if (length(bad_metrics)) errors <- c(errors, paste("Metric values must be scalar numeric:", paste(bad_metrics, collapse = ", ")))
  }
  if (identical(result_type, genai_model_assessment_binary_result_type())) {
    metrics <- output$metrics %||% list()
    rate_names <- intersect(names(metrics), c("observed_positive_rate", "mean_predicted_probability", "roc_auc", "brier_score", "threshold", "sensitivity", "specificity", "precision", "negative_predictive_value", "accuracy", "balanced_accuracy", "f1", "false_positive_rate", "false_negative_rate"))
    out_of_bounds <- rate_names[vapply(metrics[rate_names], function(value) is.finite(value) && (value < 0 || value > 1), logical(1))]
    if (length(out_of_bounds)) errors <- c(errors, paste("Binary rate/probability metrics are outside [0,1]:", paste(out_of_bounds, collapse = ", ")))
    counts <- unlist(metrics[c("true_positives", "true_negatives", "false_positives", "false_negatives")], use.names = TRUE)
    if (length(counts) && any(!is.finite(counts) | counts < 0)) errors <- c(errors, "Binary confusion counts must be finite and nonnegative.")
    expected_total <- metrics$weighted_complete_pairs %||% metrics$complete_pairs
    if (length(counts) == 4L && is.numeric(expected_total) && abs(sum(counts) - expected_total) > 1e-6) errors <- c(errors, "Binary confusion counts do not reconcile with weighted_complete_pairs.")
    if (!is.data.frame(output$threshold_metrics) && !data.table::is.data.table(output$threshold_metrics)) errors <- c(errors, "Binary threshold_metrics must be tabular.")
  }
  serialized_size <- nchar(.genai_action_json(output), type = "bytes")
  if (serialized_size > limits$max_result_size) errors <- c(errors, "Output exceeds maximum serialized result size.")
  service_result(
    status = if (length(errors)) "error" else "success",
    value = list(serialized_size = serialized_size),
    errors = errors
  )
}

genai_safe_temporary_result_summary <- function(result) {
  tables <- result$tables %||% list()
  plots <- result$plots %||% list()
  list(
    temporary_result_id = result$temporary_result_id,
    result_type = result$temporary_result_type %||% "dataset_profile",
    mode_id = result$mode_id %||% NA_character_,
    module_display_name = result$module_display_name,
    dataset_display_name = result$dataset_display_name,
    status = result$status,
    summary = result$summary,
    metrics = result$metrics %||% list(),
    threshold_metrics_available = !is.null(result$threshold_metrics),
    trusted_configuration = list(
      target_column = result$configuration_values$target_column %||% NA_character_,
      prediction_column = result$configuration_values$prediction_column %||% NA_character_,
      positive_class = result$configuration_values$positive_class %||% NA_character_,
      decision_threshold = result$configuration_values$decision_threshold %||% NA_real_,
      prediction_scale = result$configuration_values$prediction_scale %||% NA_character_
    ),
    table_names = names(tables),
    table_shapes = lapply(tables, function(table) list(rows = nrow(table), columns = ncol(table))),
    plot_descriptions = lapply(plots, function(plot) list(plot_id = plot$plot_id %||% NA_character_, plot_type = plot$plot_type %||% NA_character_, title = plot$title %||% NA_character_)),
    diagnostic_labels = names(result$diagnostics %||% list()),
    warnings = result$warnings %||% character(),
    resource_usage = result$resource_usage %||% list(),
    recommended_human_next_step = "Inspect the temporary result, then decide whether to persist a formal artifact through the normal app workflow."
  )
}

genai_result_persistence_output_contract_version <- function(result_type = "dataset_profile") {
  genai_result_output_contract_version(result_type)
}

genai_persistence_content_hash <- function(value) {
  .genai_action_hash(value)
}

genai_resolve_temporary_result <- function(temporary_result_id, ctx = NULL, active_project_id = NULL, allow_already_persisted = FALSE) {
  errors <- character()
  if (!genai_resource_id_is_valid(temporary_result_id)) {
    return(service_result(status = "error", errors = "temporary_result_id is malformed or not a scalar stable identifier."))
  }
  results <- if (!is.null(ctx) && !is.null(ctx$genai_analysis_run_state$results)) {
    tryCatch(ctx$genai_analysis_run_state$results, error = function(e) list())
  } else if (!is.null(ctx) && !is.null(ctx$genai_analysis_state$results)) {
    tryCatch(ctx$genai_analysis_state$results, error = function(e) list())
  } else {
    list()
  }
  result <- results[[temporary_result_id]]
  if (is.null(result)) {
    return(service_result(status = "error", errors = "temporary_result_not_found"))
  }
  now <- Sys.time()
  expires_at <- tryCatch(as.POSIXct(result$expires_at), error = function(e) NA)
  if (is.na(expires_at) || expires_at < now) errors <- c(errors, "temporary_result_expired")
  if (!(result$status %||% "") %in% c("temporary_success", "success", "complete")) errors <- c(errors, "temporary_result_incomplete")
  if (!identical(result$source_action_id %||% "analysis.run_registered", "analysis.run_registered")) errors <- c(errors, "temporary_result_source_action_not_enabled")
  supported_type <- (result$temporary_result_type %||% "dataset_profile") %in% genai_supported_temporary_result_types()
  if (isTRUE(result$cancel_requested) || identical(result$status, "cancelled")) errors <- c(errors, "temporary_result_cancelled")
  if (isTRUE(result$timed_out) || identical(result$status, "timed_out")) errors <- c(errors, "temporary_result_timed_out")
  if (identical(result$status, "failed")) errors <- c(errors, "temporary_result_failed")
  if (isTRUE(result$persisted) && !isTRUE(allow_already_persisted) &&
      identical(result$persisted_project_id %||% "", active_project_id %||% result$active_project_id %||% "")) {
    errors <- c(errors, "temporary_result_already_persisted")
  }
  project_at_execution <- result$active_project_id_at_execution %||% result$active_project_id %||% NA_character_
  if (!nzchar(project_at_execution %||% "")) errors <- c(errors, "temporary_result_has_no_project_binding")
  if (!is.null(active_project_id) && nzchar(active_project_id) && !identical(project_at_execution, active_project_id)) {
    errors <- c(errors, "temporary_result_project_mismatch")
  }
  expected_fingerprint <- .genai_action_hash(list(
    summary = result$summary,
    metrics = result$metrics %||% list(),
    threshold_metrics = result$threshold_metrics %||% NULL,
    tables = result$tables,
    plots = result$plots %||% list(),
    diagnostics = result$diagnostics,
    resource_usage = result$resource_usage
  ))
  if (!identical(result$result_fingerprint %||% "", expected_fingerprint)) {
    errors <- c(errors, "temporary_result_fingerprint_invalid")
  }
  output <- list(
    status = "success",
    summary = result$summary,
    metrics = result$metrics %||% list(),
    threshold_metrics = result$threshold_metrics %||% NULL,
    tables = result$tables %||% list(),
    plots = result$plots %||% list(),
    diagnostics = result$diagnostics %||% list(),
    warnings = result$warnings %||% character(),
    resource_usage = result$resource_usage %||% list()
  )
  result_type <- result$temporary_result_type %||% "dataset_profile"
  expected_types <- genai_module_supported_result_types(result$module_id %||% "")
  if (!isTRUE(supported_type) || !result_type %in% expected_types) errors <- c(errors, "temporary_result_type_not_enabled_for_persistence")
  executable <- genai_executable_module_get(result$module_id %||% "")
  limits <- executable$resource_profile %||% genai_registered_analysis_limits()
  contract <- genai_validate_registered_analysis_output(output, limits = limits, result_type = result_type)
  if (!identical(contract$status, "success")) {
    errors <- c(errors, "temporary_result_output_contract_invalid", contract$errors %||% character())
  }
  value <- list(
    temporary_result_id = temporary_result_id,
    temporary_result = result,
    temporary_result_type = result_type,
    source_action_id = result$source_action_id %||% "analysis.run_registered",
    source_execution_id = result$execution_id %||% NA_character_,
    source_proposal_id = result$proposal_id %||% NA_character_,
    module_id = result$module_id %||% NA_character_,
    module_version = result$module_version %||% NA_character_,
    mode_id = result$mode_id %||% NA_character_,
    module_display_name = result$module_display_name %||% "Dataset Profile",
    dataset_id = result$dataset_id %||% NA_character_,
    dataset_version = result$dataset_version %||% NA_character_,
    dataset_display_name = result$dataset_display_name %||% "Active Dataset",
    schema_version = result$schema_version %||% NA_character_,
    active_project_id_at_execution = project_at_execution,
    configuration_snapshot_id = result$configuration_snapshot_id %||% NA_character_,
    configuration_fingerprint = result$configuration_fingerprint %||% NA_character_,
    positive_class = result$configuration_values$positive_class %||% NA_character_,
    decision_threshold = result$configuration_values$decision_threshold %||% NA_real_,
    prediction_scale = result$configuration_values$prediction_scale %||% NA_character_,
    preflight_result_id = result$preflight_result_id %||% NA_character_,
    created_at = result$created_at %||% NA,
    expires_at = result$expires_at %||% NA,
    status = result$status %||% NA_character_,
    result_fingerprint = result$result_fingerprint %||% NA_character_,
    output_contract_version = result$output_contract_version %||% genai_result_persistence_output_contract_version(result$temporary_result_type %||% "dataset_profile"),
    already_persisted = isTRUE(result$persisted),
    persisted_result_id = result$persisted_result_id %||% NA_character_,
    summary = result$summary %||% ""
  )
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    errors = errors
  )
}

genai_result_persistence_fingerprint <- function(proposal, temp_resolution, workspace, project, gate) {
  provider <- workspace$provider %||% list()
  .genai_action_hash(list(
    proposal_hash = proposal$proposal_hash %||% NA_character_,
    temporary_result_id = temp_resolution$temporary_result_id %||% NA_character_,
    temporary_result_fingerprint = temp_resolution$result_fingerprint %||% NA_character_,
    temporary_result_type = temp_resolution$temporary_result_type %||% NA_character_,
    source_execution_id = temp_resolution$source_execution_id %||% NA_character_,
    module_id = temp_resolution$module_id %||% NA_character_,
    module_version = temp_resolution$module_version %||% NA_character_,
    dataset_id = temp_resolution$dataset_id %||% NA_character_,
    dataset_version = temp_resolution$dataset_version %||% NA_character_,
    schema_version = temp_resolution$schema_version %||% NA_character_,
    active_project_id = project$project_id %||% NA_character_,
    project_root_identity = storage_root_identity(project$project_root %||% ""),
    workspace_provider_id = gate$metadata$workspace_provider_id %||% provider$provider_id %||% workspace$provider_id %||% NA_character_,
    workspace_provider_type = gate$metadata$workspace_provider_type %||% provider$provider_type %||% workspace$provider_type %||% NA_character_,
    workspace_is_managed = isTRUE(gate$metadata$workspace_is_managed %||% provider$managed),
    workspace_state = gate$metadata$workspace_state %||% workspace$workspace_state %||% NA_character_,
    workspace_root_identity = storage_root_identity(workspace$workspace_root %||% provider$root_path %||% ""),
    provider_capability_version = gate$metadata$provider_capability_version %||% storage_provider_capability_version(provider),
    provider_write_policy = gate$metadata$provider_write_policy %||% storage_provider_write_policy_id(provider),
    provider_validation_result = gate$metadata$provider_validation_result %||% gate$status %||% NA_character_,
    project_provider_match = isTRUE(gate$metadata$project_provider_match),
    storage_policy_version = storage_policy_version,
    output_contract_version = temp_resolution$output_contract_version %||% genai_result_persistence_output_contract_version(),
    persistence_schema_version = persistence_schema_version
  ))
}

genai_resolve_result_persistence_resources <- function(temporary_result_id, ctx = NULL, proposal = NULL) {
  if (is.null(ctx) || !is.function(ctx$current_workspace) || !is.function(ctx$current_project)) {
    return(service_result(status = "error", errors = "result.persist requires active workspace/project application context."))
  }
  workspace <- ctx$current_workspace()
  project <- ctx$current_project()
  if (is.null(workspace) || !identical(workspace$workspace_state %||% "", "workspace_ready")) {
    return(service_result(status = "error", errors = "workspace_not_ready"))
  }
  if (is.null(project) || !identical(project$project_state %||% "", "project_ready")) {
    return(service_result(status = "error", errors = "project_not_ready"))
  }
  temp <- genai_resolve_temporary_result(temporary_result_id, ctx = ctx, active_project_id = project$project_id)
  if (!identical(temp$status, "success")) {
    return(service_result(status = "error", value = temp$value, errors = temp$errors))
  }
  provisional_id <- paste0("result_preview_", safe_path_component(temporary_result_id, "temporary_result"))
  target <- project_result_path(project, provisional_id)
  gate <- persistent_write_gate(workspace, project, target, "result")
  if (!identical(gate$status, "success")) {
    return(service_result(status = "error", value = temp$value, errors = gate$errors, metadata = list(write_gate = gate)))
  }
  persistence_fingerprint <- if (!is.null(proposal)) {
    genai_result_persistence_fingerprint(proposal, temp$value, workspace, project, gate)
  } else {
    gate$metadata$persistence_fingerprint %||% temp$value$result_fingerprint
  }
  value <- c(temp$value, list(
    resource_type = "result_persistence",
    active_project_id = project$project_id,
    project_name = project$project_name,
    provider_display_name = (workspace$provider %||% list())$display_name %||% workspace$provider_display_name %||% "Storage Provider",
    workspace_provider_id = gate$metadata$workspace_provider_id %||% NA_character_,
    workspace_provider_type = gate$metadata$workspace_provider_type %||% NA_character_,
    workspace_is_managed = isTRUE(gate$metadata$workspace_is_managed),
    provider_capability_version = gate$metadata$provider_capability_version %||% NA_character_,
    provider_write_policy = gate$metadata$provider_write_policy %||% NA_character_,
    provider_validation_result = gate$metadata$provider_validation_result %||% NA_character_,
    project_provider_match = isTRUE(gate$metadata$project_provider_match),
    safe_relative_location = "results/<server-generated-result-id>/",
    safe_destination = gate$metadata$safe_destination %||% "Project / results",
    persistence_fingerprint = persistence_fingerprint,
    storage_policy_version = storage_policy_version,
    persistence_schema_version = persistence_schema_version,
    write_gate = gate
  ))
  service_result(status = "success", value = value, metadata = list(write_gate = gate))
}

genai_generate_persisted_result_id <- function(project, prefix = "result") {
  repeat {
    id <- paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample(sprintf("%06d", 0:999999), 1L))
    path <- project_result_path(project, id)
    if (!dir.exists(path) && storage_resource_id_is_valid(id)) {
      return(id)
    }
  }
}

genai_persisted_result_idempotency_key <- function(proposal, temp_resolution, project, workspace) {
  .genai_action_hash(list(
    action_id = proposal$action_id,
    proposal_id = proposal$proposal_id,
    source_temporary_result_id = temp_resolution$temporary_result_id,
    source_execution_id = temp_resolution$source_execution_id,
    active_project_id = project$project_id,
    workspace_provider_id = workspace$provider_id %||% (workspace$provider %||% list())$provider_id %||% NA_character_
  ))
}

genai_find_persisted_result_by_idempotency <- function(project, idempotency_key) {
  existing <- list_project_persisted_results(project)
  if (!nrow(existing)) return(NULL)
  matches <- lapply(seq_len(nrow(existing)), function(i) {
    manifest <- read_persisted_result_manifest(existing$manifest_path[[i]])
    if (identical(manifest$idempotency_key %||% "", idempotency_key)) manifest else NULL
  })
  matches <- Filter(Negate(is.null), matches)
  if (length(matches)) matches[[1]] else NULL
}

genai_persist_dataset_profile_result <- function(proposal, temp_resolution, workspace, project, persistence_fingerprint, idempotency_key) {
  result <- temp_resolution$temporary_result
  result_type <- temp_resolution$temporary_result_type %||% "dataset_profile"
  persisted_result_id <- genai_generate_persisted_result_id(project)
  final_dir <- project_result_path(project, persisted_result_id)
  staging_dir <- project_result_path(project, paste0(".staging_", persisted_result_id))
  if (dir.exists(final_dir)) {
    return(service_result(status = "error", errors = "persisted_result_destination_exists"))
  }
  if (dir.exists(staging_dir)) unlink(staging_dir, recursive = TRUE, force = TRUE)
  dir.create(staging_dir, recursive = TRUE, showWarnings = FALSE)
  cleanup_staging <- TRUE
  on.exit({
    if (isTRUE(cleanup_staging) && dir.exists(staging_dir)) unlink(staging_dir, recursive = TRUE, force = TRUE)
  }, add = TRUE)
  tables_dir <- file.path(staging_dir, "tables")
  plots_dir <- file.path(staging_dir, "plots")
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(plots_dir, recursive = TRUE, showWarnings = FALSE)
  summary_path <- file.path(staging_dir, "summary.json")
  metrics_path <- file.path(staging_dir, "metrics.json")
  threshold_metrics_path <- file.path(staging_dir, "threshold_metrics.json")
  diagnostics_path <- file.path(staging_dir, "diagnostics.json")
  warnings_path <- file.path(staging_dir, "warnings.json")
  resource_usage_path <- file.path(staging_dir, "resource_usage.json")
  atomic_save_json(list(summary = result$summary %||% ""), summary_path)
  atomic_save_json(result$metrics %||% list(), metrics_path)
  atomic_save_json(result$threshold_metrics %||% list(), threshold_metrics_path)
  atomic_save_json(result$diagnostics %||% list(), diagnostics_path)
  atomic_save_json(result$warnings %||% character(), warnings_path)
  atomic_save_json(result$resource_usage %||% list(), resource_usage_path)
  table_paths <- list()
  for (table_name in names(result$tables %||% list())) {
    safe_name <- safe_path_component(table_name, "table")
    table_path <- file.path(tables_dir, paste0(safe_name, ".json"))
    atomic_save_json(result$tables[[table_name]], table_path)
    table_paths[[paste0("table_", safe_name)]] <- file.path("tables", paste0(safe_name, ".json"))
  }
  plot_paths <- list()
  for (plot_name in names(result$plots %||% list())) {
    safe_name <- safe_path_component(plot_name, "plot")
    plot_path <- file.path(plots_dir, paste0(safe_name, ".json"))
    atomic_save_json(result$plots[[plot_name]], plot_path)
    plot_paths[[paste0("plot_", safe_name)]] <- file.path("plots", paste0(safe_name, ".json"))
  }
  relative_paths <- c(
    list(
      summary = "summary.json",
      metrics = "metrics.json",
      threshold_metrics = "threshold_metrics.json",
      diagnostics = "diagnostics.json",
      warnings = "warnings.json",
      resource_usage = "resource_usage.json"
    ),
    table_paths,
    plot_paths
  )
  content_hashes <- lapply(relative_paths, function(rel) storage_file_hash(file.path(staging_dir, rel)))
  manifest <- list(
    persisted_result_id = persisted_result_id,
    persistence_schema_version = persistence_schema_version,
    result_type = result_type,
    display_name = temp_resolution$module_display_name %||% if (identical(result_type, "dataset_profile")) "Dataset Profile" else "Model Assessment",
    project_id = project$project_id,
    workspace_provider_id = workspace$provider_id %||% (workspace$provider %||% list())$provider_id %||% NA_character_,
    workspace_provider_type = workspace$provider_type %||% (workspace$provider %||% list())$provider_type %||% NA_character_,
    source_temporary_result_id = temp_resolution$temporary_result_id,
    source_action_id = temp_resolution$source_action_id,
    source_execution_id = temp_resolution$source_execution_id,
    source_proposal_id = temp_resolution$source_proposal_id,
    module_id = temp_resolution$module_id,
    module_version = temp_resolution$module_version,
    mode_id = temp_resolution$mode_id %||% NA_character_,
    dataset_id = temp_resolution$dataset_id,
    dataset_version = temp_resolution$dataset_version,
    schema_version = temp_resolution$schema_version,
    configuration_snapshot_id = temp_resolution$configuration_snapshot_id,
    configuration_fingerprint = temp_resolution$configuration_fingerprint,
    positive_class = temp_resolution$positive_class %||% NA_character_,
    decision_threshold = temp_resolution$decision_threshold %||% NA_real_,
    prediction_scale = temp_resolution$prediction_scale %||% NA_character_,
    preflight_result_id = temp_resolution$preflight_result_id,
    temporary_result_fingerprint = temp_resolution$result_fingerprint,
    persisted_result_fingerprint = genai_persistence_content_hash(list(relative_paths = relative_paths, content_hashes = content_hashes)),
    created_at = as.character(temp_resolution$created_at),
    persisted_at = storage_now(),
    application_version = APP_VERSION %||% NA_character_,
    output_contract_version = temp_resolution$output_contract_version,
    relative_resource_paths = relative_paths,
    content_hashes = content_hashes,
    status = "complete",
    idempotency_key = idempotency_key,
    persistence_fingerprint = persistence_fingerprint
  )
  manifest_path <- file.path(staging_dir, "manifest.json")
  atomic_save_json(manifest, manifest_path)
  validation <- validate_persisted_result_bundle(staging_dir, project = project)
  if (!identical(validation$status, "success")) {
    return(service_result(status = "error", errors = validation$errors))
  }
  if (!file.rename(staging_dir, final_dir)) {
    return(service_result(status = "error", errors = "persisted_result_atomic_commit_failed"))
  }
  cleanup_staging <- FALSE
  final_validation <- validate_persisted_result_bundle(final_dir, project = project)
  if (!identical(final_validation$status, "success")) {
    return(service_result(status = "error", errors = final_validation$errors))
  }
  files <- list.files(final_dir, recursive = TRUE, full.names = TRUE)
  service_result(
    status = "success",
    value = list(
      persisted_result_id = persisted_result_id,
      manifest = manifest,
      bundle_dir = final_dir,
      safe_relative_location = file.path("results", persisted_result_id),
      files_written = length(files),
      bytes_written = sum(file.info(files)$size, na.rm = TRUE)
    ),
    messages = paste("Persisted", result_type, "result:", persisted_result_id)
  )
}

genai_action_result_persist_handler <- function(arguments, ctx = NULL, proposal = NULL, execution_id = NULL) {
  started <- Sys.time()
  proposal <- proposal %||% list(proposal_id = NA_character_, action_id = "result.persist")
  if (is.null(ctx) || !is.function(ctx$current_workspace) || !is.function(ctx$current_project)) {
    return(service_result(status = "error", errors = "result.persist requires application workspace/project context."))
  }
  workspace <- ctx$current_workspace()
  project <- ctx$current_project()
  temp <- genai_resolve_temporary_result(arguments$temporary_result_id %||% "", ctx = ctx, active_project_id = project$project_id)
  if (!identical(temp$status, "success")) {
    return(service_result(status = "error", errors = temp$errors, metadata = list(
      computation_performed = FALSE,
      temporary_result_created = FALSE,
      project_state_changed = FALSE,
      persistent_changes = FALSE,
      persisted_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE
    )))
  }
  target <- project_result_path(project, paste0("approval_check_", safe_path_component(temp$value$temporary_result_id, "temporary")))
  gate <- persistent_write_gate(workspace, project, target, "result")
  if (!identical(gate$status, "success")) {
    return(service_result(status = "error", errors = gate$errors, metadata = list(
      computation_performed = FALSE,
      temporary_result_created = FALSE,
      project_state_changed = FALSE,
      persistent_changes = FALSE,
      persisted_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE
    )))
  }
  persistence_fingerprint <- genai_result_persistence_fingerprint(proposal, temp$value, workspace, project, gate)
  idempotency_key <- genai_persisted_result_idempotency_key(proposal, temp$value, project, workspace)
  existing <- genai_find_persisted_result_by_idempotency(project, idempotency_key)
  if (!is.null(existing)) {
    return(service_result(
      status = "success",
      value = list(
        persisted_result_id = existing$persisted_result_id,
        safe_relative_location = file.path("results", existing$persisted_result_id),
        already_committed = TRUE
      ),
      messages = paste("Recovered existing persisted result:", existing$persisted_result_id),
      metadata = list(
        source_temporary_result_id = temp$value$temporary_result_id,
        source_execution_id = temp$value$source_execution_id,
        temporary_result_fingerprint = temp$value$result_fingerprint,
        result_type = temp$value$temporary_result_type,
        temporary_result_type = temp$value$temporary_result_type,
        output_contract_version = temp$value$output_contract_version,
        module_id = temp$value$module_id,
        module_display_name = temp$value$module_display_name,
        module_version = temp$value$module_version,
        dataset_id = temp$value$dataset_id,
        dataset_display_name = temp$value$dataset_display_name,
        dataset_version = temp$value$dataset_version,
        schema_version = temp$value$schema_version,
        active_project_id = project$project_id,
        workspace_provider_id = gate$metadata$workspace_provider_id,
        workspace_provider_type = gate$metadata$workspace_provider_type,
        workspace_is_managed = isTRUE(gate$metadata$workspace_is_managed),
        provider_capability_version = gate$metadata$provider_capability_version,
        provider_write_policy = gate$metadata$provider_write_policy,
        provider_validation_result = gate$metadata$provider_validation_result,
        project_provider_match = isTRUE(gate$metadata$project_provider_match),
        project_root_identity = storage_root_identity(project$project_root),
        persistence_fingerprint = persistence_fingerprint,
        persistence_schema_version = persistence_schema_version,
        persisted_result_id = existing$persisted_result_id,
        safe_relative_location = file.path("results", existing$persisted_result_id),
        idempotency_key = idempotency_key,
        already_committed = TRUE,
        computation_performed = FALSE,
        temporary_result_created = FALSE,
        project_state_changed = TRUE,
        persistent_changes = TRUE,
        persisted_result_created = TRUE,
        artifact_created = FALSE,
        report_created = FALSE,
        state_changed = TRUE,
        ui_state_changed = TRUE
      )
    ))
  }
  lock_id <- temp$value$temporary_result_id
  if (!is.null(ctx$genai_persistence_locks[[lock_id]])) {
    return(service_result(status = "error", errors = "result_persistence_locked"))
  }
  ctx$genai_persistence_locks[[lock_id]] <- TRUE
  on.exit({ ctx$genai_persistence_locks[[lock_id]] <- NULL }, add = TRUE)
  persisted <- genai_persist_dataset_profile_result(proposal, temp$value, workspace, project, persistence_fingerprint, idempotency_key)
  if (!identical(persisted$status, "success")) {
    return(service_result(status = "error", errors = persisted$errors, metadata = list(
      source_temporary_result_id = temp$value$temporary_result_id,
      persistence_fingerprint = persistence_fingerprint,
      computation_performed = FALSE,
      temporary_result_created = FALSE,
      project_state_changed = FALSE,
      persistent_changes = FALSE,
      persisted_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE
    )))
  }
  if (!is.null(ctx) && is.function(ctx$mark_genai_analysis_result_persisted)) {
    ctx$mark_genai_analysis_result_persisted(
      temporary_result_id = temp$value$temporary_result_id,
      persisted_result_id = persisted$value$persisted_result_id,
      persisted_project_id = project$project_id
    )
  }
  completed <- Sys.time()
  service_result(
    status = "success",
    value = list(
      execution_id = execution_id,
      proposal_id = proposal$proposal_id,
      action_id = "result.persist",
      status = "succeeded",
      started_at = started,
      completed_at = completed,
      message = persisted$messages,
      source_temporary_result_id = temp$value$temporary_result_id,
      persisted_result_id = persisted$value$persisted_result_id,
      safe_relative_location = persisted$value$safe_relative_location,
      outputs = list(manifest = "manifest.json"),
      warnings = character(),
      errors = character(),
      ui_state_changed = TRUE,
      project_state_changed = TRUE,
      persistent_changes = TRUE,
      computation_performed = FALSE,
      temporary_result_created = FALSE,
      persisted_result_created = TRUE,
      artifact_created = FALSE,
      report_created = FALSE,
      already_committed = FALSE
    ),
    messages = persisted$messages,
    metadata = list(
      source_temporary_result_id = temp$value$temporary_result_id,
      source_execution_id = temp$value$source_execution_id,
      temporary_result_fingerprint = temp$value$result_fingerprint,
      result_type = temp$value$temporary_result_type,
      temporary_result_type = temp$value$temporary_result_type,
      output_contract_version = temp$value$output_contract_version,
      module_id = temp$value$module_id,
      module_display_name = temp$value$module_display_name,
      module_version = temp$value$module_version,
      dataset_id = temp$value$dataset_id,
      dataset_display_name = temp$value$dataset_display_name,
      dataset_version = temp$value$dataset_version,
      schema_version = temp$value$schema_version,
      configuration_snapshot_id = temp$value$configuration_snapshot_id,
      configuration_fingerprint = temp$value$configuration_fingerprint,
      preflight_result_id = temp$value$preflight_result_id,
      active_project_id = project$project_id,
      workspace_provider_id = gate$metadata$workspace_provider_id,
      workspace_provider_type = gate$metadata$workspace_provider_type,
      workspace_is_managed = isTRUE(gate$metadata$workspace_is_managed),
      provider_capability_version = gate$metadata$provider_capability_version,
      provider_write_policy = gate$metadata$provider_write_policy,
      provider_validation_result = gate$metadata$provider_validation_result,
      project_provider_match = isTRUE(gate$metadata$project_provider_match),
      project_root_identity = storage_root_identity(project$project_root),
      persistence_fingerprint = persistence_fingerprint,
      persistence_schema_version = persistence_schema_version,
      persisted_result_id = persisted$value$persisted_result_id,
      safe_relative_location = persisted$value$safe_relative_location,
      content_hashes = .genai_action_json(persisted$value$manifest$content_hashes %||% list()),
      bytes_written = persisted$value$bytes_written,
      files_written = persisted$value$files_written,
      idempotency_key = idempotency_key,
      already_committed = FALSE,
      computation_performed = FALSE,
      temporary_result_created = FALSE,
      project_state_changed = TRUE,
      persistent_changes = TRUE,
      persisted_result_created = TRUE,
      artifact_created = FALSE,
      report_created = FALSE,
      state_changed = TRUE,
      ui_state_changed = TRUE
    )
  )
}

genai_register_worker_handoff_temporary_result <- function(project, job, handoff, output, validation, resolution, snapshot, proposal, execution_id, ctx = NULL) {
  completed <- Sys.time()
  temporary_result <- list(
    temporary_result_id = paste0("tmp_analysis_", format(completed, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    temporary_result_type = handoff$result_type,
    mode_id = snapshot$mode_id %||% NA_character_,
    source_action_id = "analysis.run_registered",
    execution_id = execution_id,
    proposal_id = proposal$proposal_id %||% NA_character_,
    job_id = job$job_id,
    module_id = resolution$value$module_id,
    module_version = resolution$value$module_version,
    module_display_name = resolution$value$display_name,
    dataset_id = resolution$value$dataset_id,
    dataset_version = resolution$value$dataset_version,
    dataset_display_name = resolution$value$dataset_display_name,
    schema_version = resolution$value$schema_version,
    active_project_id = resolution$value$active_project_id,
    active_project_id_at_execution = resolution$value$active_project_id,
    configuration_snapshot_id = snapshot$configuration_snapshot_id,
    configuration_fingerprint = snapshot$configuration_fingerprint,
    configuration_values = snapshot$configuration_values,
    preflight_result_id = resolution$value$preflight_result_id,
    created_at = completed,
    expires_at = completed + 60 * 60,
    status = "temporary_success",
    output_contract_version = genai_result_output_contract_version(handoff$result_type),
    persisted = FALSE,
    recovered = isTRUE(job$recovered),
    summary = output$summary,
    metrics = output$metrics %||% list(),
    threshold_metrics = output$threshold_metrics %||% NULL,
    tables = output$tables,
    plots = output$plots %||% list(),
    diagnostics = output$diagnostics,
    warnings = output$warnings %||% character(),
    resource_usage = output$resource_usage,
    result_fingerprint = handoff$result_fingerprint %||% .genai_action_hash(list(summary = output$summary, metrics = output$metrics %||% list(), threshold_metrics = output$threshold_metrics %||% NULL, tables = output$tables, plots = output$plots %||% list(), diagnostics = output$diagnostics, resource_usage = output$resource_usage))
  )
  stored_id <- if (!is.null(ctx) && is.function(ctx$store_genai_analysis_result)) {
    ctx$store_genai_analysis_result(temporary_result)
  } else {
    temporary_result$temporary_result_id
  }
  temporary_result$temporary_result_id <- stored_id
  temporary_result
}

genai_action_analysis_run_registered_isolated <- function(arguments, ctx = NULL, proposal = NULL, execution_id = NULL, resolution = NULL, limits = NULL) {
  project <- if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  workspace <- if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  if (!is.list(project) || !identical(project$project_state %||% "", "project_ready") || !is.list(workspace) || !identical(workspace$workspace_state %||% "", "workspace_ready")) {
    return(service_result(status = "error", errors = "isolated_analysis_execution_requires_ready_project", metadata = list(worker_isolated = FALSE)))
  }
  resolution <- resolution %||% genai_resolve_registered_analysis_resources(arguments$module_id %||% "", arguments$dataset_id %||% "", ctx = ctx)
  if (!identical(resolution$status, "success")) {
    return(service_result(status = "error", errors = resolution$errors, warnings = resolution$warnings, metadata = list(resource_resolution = resolution$value)))
  }
  executable <- resolution$metadata$executable_module
  limits <- limits %||% executable$resource_profile %||% genai_registered_analysis_limits()
  snapshot <- resolution$metadata$configuration_snapshot
  handler_id <- genai_worker_handler_id(resolution$value$module_id, snapshot$mode_id %||% NA_character_, snapshot$result_type %||% NULL)
  if (!genai_worker_handler_enabled(handler_id)) {
    return(service_result(status = "error", errors = "worker_handler_not_enabled", metadata = list(handler_id = handler_id)))
  }
  proposal <- proposal %||% list(proposal_id = NA_character_, action_id = "analysis.run_registered")
  execution_id <- execution_id %||% paste0("execution_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
  if (!identical(snapshot$configuration_fingerprint %||% "", resolution$value$configuration_fingerprint %||% "")) {
    return(service_result(status = "error", errors = "Configuration fingerprint mismatch.", metadata = list(resource_resolution = resolution$value)))
  }
  job <- genai_job_create_record(project, proposal, resolution, execution_id, limits, handler_id)
  snapshot_info <- genai_job_create_snapshot(project, job$job_id, resolution$metadata$data, limits, resolution$value)
  request <- genai_job_build_worker_request(project, job, resolution, limits, snapshot_info)
  if (!identical(request$status, "success")) {
    return(service_result(status = "error", errors = request$errors, metadata = list(job_id = job$job_id, worker_isolated = FALSE)))
  }
  genai_job_persist_record(project, job)
  if (!is.null(ctx) && is.function(ctx$store_genai_analysis_job)) {
    ctx$store_genai_analysis_job(job)
  }
  if (exists("genai_record_durable_audit", mode = "function")) {
    genai_record_durable_audit("job_created", proposal, execution = c(job, list(status = "created", result_status = "created")), ctx = ctx)
  }
  started <- genai_job_start(project, job, genai_job_request_path(project, job$job_id), repo_root = storage_repo_root())
  if (!identical(started$status, "success")) {
    return(service_result(status = "error", errors = started$errors %||% started$warnings, metadata = list(job_id = job$job_id, worker_isolated = FALSE)))
  }
  job <- started$value
  if (exists("genai_record_durable_audit", mode = "function")) {
    genai_record_durable_audit("worker_started", proposal, execution = c(job, list(status = "running", result_status = "running")), ctx = ctx)
  }
  deadline <- Sys.time() + as.numeric(job$timeout_seconds %||% 30)
  repeat {
    poll <- genai_job_poll(project, job$job_id)
    job <- poll$value %||% job
    if (!is.null(ctx) && is.function(ctx$update_genai_analysis_job)) {
      ctx$update_genai_analysis_job(job$job_id, job)
    }
    if (job$status %in% genai_job_terminal_statuses()) break
    if (Sys.time() > deadline) {
      timeout <- genai_job_timeout(project, job$job_id)
      job <- timeout$value %||% job
      break
    }
    Sys.sleep(0.05)
  }
  if (identical(job$status, "cancelled")) {
    if (exists("genai_record_durable_audit", mode = "function")) genai_record_durable_audit("job_cancelled", proposal, execution = c(job, list(status = "cancelled", result_status = "cancelled", worker_terminated = TRUE)), ctx = ctx)
    return(service_result(status = "success", value = job, warnings = "Job cancelled; incomplete output discarded.", metadata = list(job_id = job$job_id, worker_isolated = TRUE, hard_cancellation_supported = TRUE, worker_terminated = TRUE, temporary_result_created = FALSE, project_state_changed = FALSE, persistent_changes = FALSE, artifact_created = FALSE, report_created = FALSE)))
  }
  if (identical(job$status, "timed_out")) {
    if (exists("genai_record_durable_audit", mode = "function")) genai_record_durable_audit("job_timed_out", proposal, execution = c(job, list(status = "timed_out", result_status = "timed_out", timed_out = TRUE, worker_terminated = TRUE)), ctx = ctx)
    return(service_result(status = "success", value = job, warnings = "Job timed out; worker terminated and incomplete output discarded.", metadata = list(job_id = job$job_id, worker_isolated = TRUE, hard_cancellation_supported = TRUE, worker_terminated = TRUE, timed_out = TRUE, temporary_result_created = FALSE, project_state_changed = FALSE, persistent_changes = FALSE, artifact_created = FALSE, report_created = FALSE)))
  }
  if (!identical(job$status, "succeeded")) {
    if (exists("genai_record_durable_audit", mode = "function")) genai_record_durable_audit("job_failed", proposal, execution = c(job, list(status = "failed", result_status = "failed")), ctx = ctx)
    return(service_result(status = "error", errors = job$error_message %||% "isolated_worker_failed", metadata = list(job_id = job$job_id, worker_isolated = TRUE, temporary_result_created = FALSE, project_state_changed = FALSE, persistent_changes = FALSE)))
  }
  collected <- genai_job_collect_handoff(project, job$job_id, expected_fingerprint = job$execution_fingerprint, expected_result_type = job$result_type, limits = limits)
  if (!identical(collected$status, "success")) {
    if (exists("genai_record_durable_audit", mode = "function")) genai_record_durable_audit("result_handoff_rejected", proposal, execution = c(job, list(status = "failed", result_status = "failed", error_code = "result_handoff_rejected", errors = collected$errors)), ctx = ctx)
    return(service_result(status = "error", errors = collected$errors, metadata = list(job_id = job$job_id, worker_isolated = TRUE, temporary_result_created = FALSE, project_state_changed = FALSE, persistent_changes = FALSE)))
  }
  handoff <- collected$value$handoff
  output <- collected$value$output
  temporary_result <- genai_register_worker_handoff_temporary_result(project, job, handoff, output, collected$value$validation, resolution, snapshot, proposal, execution_id, ctx)
  job <- genai_job_update(project, job, list(temporary_result_id = temporary_result$temporary_result_id, result_fingerprint = temporary_result$result_fingerprint, progress_stage = "temporary_result_created", progress_message = "Validated handoff registered as temporary result."))$value
  if (exists("genai_record_durable_audit", mode = "function")) {
    genai_record_durable_audit("job_succeeded", proposal, execution = c(job, list(status = "succeeded", result_status = "succeeded", temporary_result_id = temporary_result$temporary_result_id, result_fingerprint = temporary_result$result_fingerprint, resource_usage_status = "bounded")), ctx = ctx)
  }
  genai_job_cleanup(project, job$job_id, remove_snapshot = TRUE)
  service_result(
    status = "success",
    value = genai_safe_temporary_result_summary(temporary_result),
    messages = paste("Temporary result - not saved to the project.", output$summary),
    warnings = temporary_result$warnings,
    metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      job_id = job$job_id,
      temporary_result_id = temporary_result$temporary_result_id,
      result_type = temporary_result$temporary_result_type,
      mode_id = snapshot$mode_id %||% NA_character_,
      temporary_result_type = temporary_result$temporary_result_type,
      output_contract_version = temporary_result$output_contract_version,
      module_id = resolution$value$module_id,
      module_display_name = resolution$value$display_name,
      module_version = resolution$value$module_version,
      dataset_id = resolution$value$dataset_id,
      dataset_display_name = resolution$value$dataset_display_name,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id,
      configuration_snapshot_id = snapshot$configuration_snapshot_id,
      configuration_fingerprint = snapshot$configuration_fingerprint,
      preflight_result_id = resolution$value$preflight_result_id,
      preflight_fingerprint = resolution$value$preflight_fingerprint,
      composite_execution_fingerprint = resolution$value$resource_fingerprint,
      execution_limit_profile = .genai_action_json(limits),
      execution_stages = paste(output$execution_stages %||% character(), collapse = ", "),
      rows_considered = output$resource_usage$actual_rows_considered %||% NA_integer_,
      columns_considered = output$resource_usage$actual_columns_considered %||% NA_integer_,
      inspection_mode = output$resource_usage$inspection_mode %||% NA_character_,
      elapsed_time = output$resource_usage$elapsed_time_ms %||% NA_integer_,
      result_size = collected$value$validation$value$serialized_size %||% NA_integer_,
      readiness = resolution$value$preflight_readiness,
      worker_backend = job$worker_backend,
      worker_pid_hash_or_safe_id = job$worker_pid_hash_or_safe_id,
      worker_isolated = TRUE,
      hard_cancellation_supported = TRUE,
      recovered = FALSE,
      cancel_requested = FALSE,
      timed_out = FALSE,
      computation_performed = TRUE,
      temporary_result_created = TRUE,
      artifact_created = FALSE,
      report_created = FALSE,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_action_analysis_run_registered_handler <- function(arguments, ctx = NULL, proposal = NULL, execution_id = NULL) {
  if (!is.null(ctx) && is.function(ctx$reset_genai_analysis_cancel)) {
    ctx$reset_genai_analysis_cancel()
  }
  resolution <- genai_resolve_registered_analysis_resources(arguments$module_id %||% "", arguments$dataset_id %||% "", ctx = ctx)
  if (!identical(resolution$status, "success")) {
    return(service_result(status = "error", errors = resolution$errors, warnings = resolution$warnings, metadata = list(resource_resolution = resolution$value)))
  }
  executable <- resolution$metadata$executable_module
  limits <- executable$resource_profile %||% genai_registered_analysis_limits()
  if (!is.null(ctx) && is.function(ctx$genai_registered_analysis_limits)) {
    ctx_limits <- ctx$genai_registered_analysis_limits()
    default_limits <- genai_registered_analysis_limits()
    changed_fields <- names(ctx_limits)[vapply(names(ctx_limits), function(field) {
      !identical(ctx_limits[[field]], default_limits[[field]])
    }, logical(1))]
    for (field in changed_fields) limits[[field]] <- ctx_limits[[field]]
  }
  snapshot <- resolution$metadata$configuration_snapshot
  data <- resolution$metadata$data
  execution_id <- execution_id %||% paste0("execution_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
  proposal <- proposal %||% list(proposal_id = NA_character_, action_id = "analysis.run_registered")
  project <- if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  workspace <- if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  if (is.list(project) && identical(project$project_state %||% "", "project_ready") &&
      is.list(workspace) && identical(workspace$workspace_state %||% "", "workspace_ready") &&
      exists("genai_job_start", mode = "function")) {
    return(genai_action_analysis_run_registered_isolated(arguments, ctx = ctx, proposal = proposal, execution_id = execution_id, resolution = resolution, limits = limits))
  }
  job <- genai_create_registered_analysis_job(proposal, resolution$value, execution_id)
  if (!is.null(ctx) && is.function(ctx$store_genai_analysis_job)) {
    job$job_id <- ctx$store_genai_analysis_job(job)
  }
  update_job <- function(fields) {
    if (!is.null(ctx) && is.function(ctx$update_genai_analysis_job)) {
      ctx$update_genai_analysis_job(job$job_id, fields)
    }
    for (field in names(fields)) job[[field]] <<- fields[[field]]
    invisible(job)
  }
  update_job(list(status = "validating", started_at = Sys.time(), progress_stage = "validating", progress_message = "Validating trusted configuration and preflight binding."))
  if (!identical(snapshot$configuration_fingerprint %||% "", resolution$value$configuration_fingerprint %||% "")) {
    update_job(list(status = "failed", completed_at = Sys.time(), error = "Configuration fingerprint mismatch."))
    return(service_result(status = "error", errors = "Configuration fingerprint mismatch.", metadata = list(job_id = job$job_id, resource_resolution = resolution$value)))
  }
  cancel_fun <- if (!is.null(ctx) && is.function(ctx$genai_analysis_cancel_requested)) ctx$genai_analysis_cancel_requested else function() FALSE
  progress <- function(stage, message) {
    update_job(list(status = "running", progress_stage = stage, progress_message = message))
    NULL
  }
  update_job(list(status = "running", progress_stage = "start", progress_message = "Running bounded temporary analysis."))
  started <- Sys.time()
  output <- tryCatch(
    executable$execute_handler(
      data = data,
      module_resolution = resolution$value,
      dataset_resolution = list(
        dataset_id = resolution$value$dataset_id,
        display_name = resolution$value$dataset_display_name,
        dataset_version = resolution$value$dataset_version,
        schema_version = resolution$value$schema_version,
        active_project_id = resolution$value$active_project_id
      ),
      configuration_snapshot = snapshot,
      limits = limits,
      cancel_requested = cancel_fun,
      progress = progress
    ),
    error = function(e) list(status = "failed", summary = conditionMessage(e), tables = list(), diagnostics = list(), warnings = character(), errors = conditionMessage(e), resource_usage = list(), execution_stages = character())
  )
  completed <- Sys.time()
  if (identical(output$status, "cancelled")) {
    update_job(list(status = "cancelled", completed_at = completed, cancel_requested = TRUE, progress_stage = output$stage %||% "cancelled", progress_message = output$message %||% "Cancelled."))
    return(service_result(status = "success", value = output, warnings = output$warnings %||% character(), metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      job_id = job$job_id,
      module_id = resolution$value$module_id,
      module_display_name = resolution$value$display_name,
      module_version = resolution$value$module_version,
      mode_id = snapshot$mode_id %||% NA_character_,
      dataset_id = resolution$value$dataset_id,
      dataset_display_name = resolution$value$dataset_display_name,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id,
      configuration_snapshot_id = snapshot$configuration_snapshot_id,
      configuration_fingerprint = snapshot$configuration_fingerprint,
      positive_class = snapshot$configuration_values$positive_class %||% NA_character_,
      decision_threshold = snapshot$configuration_values$decision_threshold %||% NA_real_,
      prediction_scale = snapshot$configuration_values$prediction_scale %||% NA_character_,
      preflight_result_id = resolution$value$preflight_result_id,
      preflight_fingerprint = resolution$value$preflight_fingerprint,
      execution_limit_profile = .genai_action_json(limits),
      cancel_requested = TRUE,
      timed_out = FALSE,
      computation_performed = TRUE,
      temporary_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )))
  }
  if (identical(output$status, "timed_out")) {
    update_job(list(status = "timed_out", completed_at = completed, timed_out = TRUE, progress_stage = output$stage %||% "timed_out", progress_message = output$message %||% "Timed out."))
    return(service_result(status = "success", value = output, warnings = output$warnings %||% character(), metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      job_id = job$job_id,
      module_id = resolution$value$module_id,
      module_display_name = resolution$value$display_name,
      module_version = resolution$value$module_version,
      dataset_id = resolution$value$dataset_id,
      dataset_display_name = resolution$value$dataset_display_name,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id,
      configuration_snapshot_id = snapshot$configuration_snapshot_id,
      configuration_fingerprint = snapshot$configuration_fingerprint,
      preflight_result_id = resolution$value$preflight_result_id,
      preflight_fingerprint = resolution$value$preflight_fingerprint,
      execution_limit_profile = .genai_action_json(limits),
      cancel_requested = FALSE,
      timed_out = TRUE,
      computation_performed = TRUE,
      temporary_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )))
  }
  result_type <- snapshot$result_type %||% genai_module_result_type(resolution$value$module_id, snapshot$configuration_values)
  validation <- genai_validate_registered_analysis_output(output, limits, result_type = result_type)
  if (!identical(validation$status, "success")) {
    update_job(list(status = "failed", completed_at = completed, error = paste(validation$errors, collapse = "; ")))
    return(service_result(status = "error", errors = validation$errors, warnings = output$warnings %||% character(), metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      job_id = job$job_id,
      module_id = resolution$value$module_id,
      dataset_id = resolution$value$dataset_id,
      computation_performed = TRUE,
      temporary_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )))
  }
  temporary_result <- list(
    temporary_result_id = paste0("tmp_analysis_", format(completed, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    temporary_result_type = result_type,
    mode_id = snapshot$mode_id %||% NA_character_,
    source_action_id = "analysis.run_registered",
    execution_id = execution_id,
    proposal_id = proposal$proposal_id %||% NA_character_,
    job_id = job$job_id,
    module_id = resolution$value$module_id,
    module_version = resolution$value$module_version,
    module_display_name = resolution$value$display_name,
    dataset_id = resolution$value$dataset_id,
    dataset_version = resolution$value$dataset_version,
    dataset_display_name = resolution$value$dataset_display_name,
    schema_version = resolution$value$schema_version,
    active_project_id = resolution$value$active_project_id,
    active_project_id_at_execution = resolution$value$active_project_id,
    configuration_snapshot_id = snapshot$configuration_snapshot_id,
    configuration_fingerprint = snapshot$configuration_fingerprint,
    configuration_values = snapshot$configuration_values,
    preflight_result_id = resolution$value$preflight_result_id,
    created_at = completed,
    expires_at = completed + 60 * 60,
    status = "temporary_success",
    output_contract_version = genai_result_output_contract_version(result_type),
    persisted = FALSE,
    summary = output$summary,
    metrics = output$metrics %||% list(),
    threshold_metrics = output$threshold_metrics %||% NULL,
    tables = output$tables,
    plots = output$plots %||% list(),
    diagnostics = output$diagnostics,
    warnings = output$warnings %||% character(),
    resource_usage = output$resource_usage,
    result_fingerprint = .genai_action_hash(list(summary = output$summary, metrics = output$metrics %||% list(), threshold_metrics = output$threshold_metrics %||% NULL, tables = output$tables, plots = output$plots %||% list(), diagnostics = output$diagnostics, resource_usage = output$resource_usage))
  )
  stored_id <- if (!is.null(ctx) && is.function(ctx$store_genai_analysis_result)) {
    ctx$store_genai_analysis_result(temporary_result)
  } else {
    temporary_result$temporary_result_id
  }
  temporary_result$temporary_result_id <- stored_id
  update_job(list(status = "succeeded", completed_at = completed, progress_stage = "complete", progress_message = "Temporary result created.", temporary_result_id = stored_id))
  service_result(
    status = "success",
    value = genai_safe_temporary_result_summary(temporary_result),
    messages = paste("Temporary result - not saved to the project.", output$summary),
    warnings = temporary_result$warnings,
    metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      job_id = job$job_id,
      temporary_result_id = stored_id,
      result_type = result_type,
      mode_id = snapshot$mode_id %||% NA_character_,
      temporary_result_type = result_type,
      output_contract_version = temporary_result$output_contract_version,
      module_id = resolution$value$module_id,
      module_display_name = resolution$value$display_name,
      module_version = resolution$value$module_version,
      dataset_id = resolution$value$dataset_id,
      dataset_display_name = resolution$value$dataset_display_name,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id,
      configuration_snapshot_id = snapshot$configuration_snapshot_id,
      configuration_fingerprint = snapshot$configuration_fingerprint,
      preflight_result_id = resolution$value$preflight_result_id,
      preflight_fingerprint = resolution$value$preflight_fingerprint,
      composite_execution_fingerprint = resolution$value$resource_fingerprint,
      execution_limit_profile = .genai_action_json(limits),
      execution_stages = paste(output$execution_stages %||% character(), collapse = ", "),
      rows_considered = output$resource_usage$actual_rows_considered %||% NA_integer_,
      columns_considered = output$resource_usage$actual_columns_considered %||% NA_integer_,
      inspection_mode = output$resource_usage$inspection_mode %||% NA_character_,
      elapsed_time = output$resource_usage$elapsed_time_ms %||% as.integer(difftime(completed, started, units = "secs") * 1000),
      result_size = validation$value$serialized_size %||% NA_integer_,
      readiness = resolution$value$preflight_readiness,
      cancel_requested = FALSE,
      timed_out = FALSE,
      computation_performed = TRUE,
      temporary_result_created = TRUE,
      artifact_created = FALSE,
      report_created = FALSE,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_report_version <- function(report) {
  metadata <- report$metadata %||% list()
  as.character(
    metadata$report_version %||%
      metadata$version %||%
      report$updated_at %||%
      report$created_at %||%
      "unversioned"
  )
}

genai_report_open_supported <- function(report) {
  inherits(report, "aq_report_plan") &&
    (report$layout_type %||% "") %in% c("grid", "sections", "carousel", "canvas")
}

genai_artifact_version <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  as.character(
    metadata$artifact_version %||%
      metadata$version %||%
      artifact$updated_at %||%
      artifact$created_at %||%
      metadata$generated_at %||%
      "unversioned"
  )
}

genai_artifact_inspection_supported <- function(artifact) {
  type <- artifact$artifact_type %||% ""
  type %in% artifact_types && !type %in% c("section_header")
}

genai_persisted_result_inspection_supported <- function(result_type, persistence_schema = persistence_schema_version) {
  identical(persistence_schema, persistence_schema_version) &&
    (result_type %||% "") %in% genai_supported_temporary_result_types()
}

genai_resolve_persisted_result <- function(persisted_result_id, ctx = NULL, project = NULL, workspace = NULL) {
  errors <- character()
  warnings <- character()
  if (!genai_resource_id_is_valid(persisted_result_id)) {
    errors <- c(errors, "persisted_result_id is malformed or not a scalar trusted persisted result identifier.")
    return(service_result(status = "error", errors = errors, value = list(
      persisted_result_id = persisted_result_id,
      exists = FALSE,
      available = FALSE,
      active_project_match = FALSE,
      inspection_supported = FALSE
    )))
  }

  project <- project %||% if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  workspace <- workspace %||% if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
    errors <- c(errors, "A ready active project is required to inspect persisted results.")
    return(service_result(status = "error", errors = errors, value = list(
      persisted_result_id = persisted_result_id,
      exists = FALSE,
      available = FALSE,
      active_project_match = FALSE,
      inspection_supported = FALSE
    )))
  }

  resolved <- resolve_project_persisted_result(project, persisted_result_id)
  if (!identical(resolved$status, "success")) {
    return(service_result(status = "error", errors = resolved$errors, warnings = resolved$warnings, value = list(
      persisted_result_id = persisted_result_id,
      exists = FALSE,
      available = FALSE,
      active_project_id = project$project_id %||% NA_character_,
      active_project_match = FALSE,
      inspection_supported = FALSE,
      manifest_status = "unavailable",
      hash_status = "failed"
    )))
  }

  manifest <- resolved$value$manifest
  provider_id <- workspace$provider_id %||% (workspace$provider %||% list())$provider_id %||% NA_character_
  provider_type <- workspace$provider_type %||% (workspace$provider %||% list())$provider_type %||% NA_character_
  project_match <- identical(manifest$project_id %||% "", project$project_id %||% "")
  provider_match <- identical(manifest$workspace_provider_id %||% provider_id, provider_id)
  type_supported <- genai_persisted_result_inspection_supported(manifest$result_type, manifest$persistence_schema_version)
  if (!project_match) errors <- c(errors, "Persisted result does not belong to the active project.")
  if (!provider_match) errors <- c(errors, "Persisted result storage provider binding does not match the active workspace.")
  if (!type_supported) errors <- c(errors, "Persisted result type or schema is not supported for inspection.")
  if (!identical(manifest$status %||% "", "complete")) errors <- c(errors, "Persisted result is not complete.")
  content_hash_summary <- genai_persistence_content_hash(manifest$content_hashes %||% list())

  value <- list(
    resource_type = "persisted_result",
    persisted_result_id = persisted_result_id,
    exists = TRUE,
    available = !length(errors),
    active_project_match = project_match,
    active_project_id = project$project_id %||% NA_character_,
    active_project_name = project$project_name %||% NA_character_,
    workspace_provider_id = provider_id,
    workspace_provider_type = provider_type,
    manifest_workspace_provider_id = manifest$workspace_provider_id %||% NA_character_,
    manifest_workspace_provider_type = manifest$workspace_provider_type %||% NA_character_,
    project_provider_match = provider_match,
    result_type = manifest$result_type %||% NA_character_,
    display_name = manifest$display_name %||% persisted_result_id,
    manifest_schema_version = manifest$manifest_schema_version %||% "manifest_v1",
    persistence_schema_version = manifest$persistence_schema_version %||% NA_character_,
    module_id = manifest$module_id %||% NA_character_,
    module_version = manifest$module_version %||% NA_character_,
    mode_id = manifest$mode_id %||% NA_character_,
    dataset_id = manifest$dataset_id %||% NA_character_,
    dataset_version = manifest$dataset_version %||% NA_character_,
    schema_version = manifest$schema_version %||% NA_character_,
    created_at = manifest$created_at %||% NA_character_,
    persisted_at = manifest$persisted_at %||% NA_character_,
    source_execution_id = manifest$source_execution_id %||% NA_character_,
    source_temporary_result_id = manifest$source_temporary_result_id %||% NA_character_,
    positive_class = manifest$positive_class %||% NA_character_,
    decision_threshold = manifest$decision_threshold %||% NA_real_,
    prediction_scale = manifest$prediction_scale %||% NA_character_,
    manifest_status = manifest$status %||% NA_character_,
    hash_status = "validated",
    inspection_supported = type_supported,
    persisted_result_fingerprint = manifest$persisted_result_fingerprint %||% NA_character_,
    content_hash_summary = content_hash_summary,
    safe_relative_location = file.path("results", persisted_result_id)
  )
  value$resource_fingerprint <- genai_resource_fingerprint(value)
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(manifest = manifest, bundle_dir = resolved$value$bundle_dir)
  )
}

genai_resolve_report <- function(report_id, ctx = NULL, reports = NULL, active_project_id = NULL) {
  errors <- character()
  warnings <- character()
  if (!genai_resource_id_is_valid(report_id)) {
    errors <- c(errors, "report_id is malformed or not a scalar stable identifier.")
    return(service_result(status = "error", errors = errors, value = list(
      report_id = report_id,
      exists = FALSE,
      available = FALSE,
      current_project_match = FALSE,
      open_supported = FALSE
    )))
  }

  reports <- reports %||% if (!is.null(ctx) && !is.null(ctx$report_plan_state$plans)) {
    tryCatch(ctx$report_plan_state$plans, error = function(e) list())
  } else {
    list()
  }
  reports <- repair_report_plan_collection(reports)
  active_project_id <- active_project_id %||% genai_active_project_id(ctx)
  report <- genai_report_lookup(reports, report_id)
  if (is.null(report)) {
    errors <- c(errors, paste("Report does not exist in the active project:", report_id))
    return(service_result(status = "error", errors = errors, value = list(
      report_id = report_id,
      exists = FALSE,
      available = FALSE,
      current_project_match = FALSE,
      active_project_id = active_project_id,
      open_supported = FALSE
    )))
  }

  metadata <- report$metadata %||% list()
  report_project_id <- metadata$project_id %||% report$project_id %||% active_project_id
  status <- report$status %||% metadata$status %||% "draft"
  render_status <- metadata$render_status %||% metadata$preview_status %||% "preview_available"
  deleted <- identical(tolower(status), "deleted") || isTRUE(metadata$deleted)
  archived <- identical(tolower(status), "archived") || isTRUE(metadata$archived)
  unavailable <- deleted ||
    archived ||
    tolower(status) %in% c("unavailable", "missing", "failed", "render_failed", "generating", "rendering") ||
    tolower(render_status) %in% c("missing", "failed", "render_failed", "generating", "rendering", "unavailable")
  project_match <- identical(as.character(report_project_id), as.character(active_project_id))
  open_supported <- genai_report_open_supported(report)
  validation <- validate_report_plan(report, repair = TRUE)
  version <- genai_report_version(report)
  display_name <- report$label %||% metadata$title %||% report$plan_id %||% report_id

  if (!project_match) errors <- c(errors, "Report does not belong to the active project.")
  if (deleted) errors <- c(errors, "Report was deleted.")
  if (archived) errors <- c(errors, "Report is archived and cannot be opened by GenAI.")
  if (unavailable) errors <- c(errors, paste("Report is unavailable:", status, "/", render_status))
  if (!open_supported) errors <- c(errors, paste("Report type cannot be opened:", report$layout_type %||% "unknown"))
  if (identical(validation$status, "error")) errors <- c(errors, validation$errors %||% "Report plan validation failed.")
  warnings <- c(warnings, validation$warnings %||% character())
  if (is.null(report$layout_type) || !nzchar(report$layout_type)) warnings <- c(warnings, "Report metadata is incomplete: layout_type is missing.")

  value <- list(
    resource_type = "report",
    report_id = report_id,
    exists = TRUE,
    available = !unavailable && !identical(validation$status, "error"),
    current_project_match = project_match,
    display_name = display_name,
    report_type = report$layout_type %||% NA_character_,
    report_version = version,
    report_status = status,
    render_status = render_status,
    open_supported = open_supported,
    resource_origin = "report_plan",
    active_project_id = active_project_id,
    created_at = as.character(report$created_at %||% NA_character_),
    updated_at = as.character(report$updated_at %||% NA_character_),
    source_artifact_id = paste(report_plan_artifact_ids(report), collapse = ", "),
    content_type = "report_plan",
    is_generated = isTRUE(metadata$is_generated %||% FALSE),
    is_archived = archived
  )
  value$resource_fingerprint <- genai_resource_fingerprint(value)
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(report = report)
  )
}

genai_resolve_artifact <- function(artifact_id, ctx = NULL, artifacts = NULL, active_project_id = NULL) {
  errors <- character()
  warnings <- character()
  if (!genai_artifact_id_is_valid(artifact_id)) {
    errors <- c(errors, "artifact_id is malformed or not a scalar stable identifier.")
    return(service_result(status = "error", errors = errors, value = list(
      exists = FALSE,
      available = FALSE,
      current_project_match = FALSE,
      inspection_supported = FALSE
    )))
  }

  artifacts <- artifacts %||% if (!is.null(ctx) && is.function(ctx$all_artifacts)) {
    tryCatch(ctx$all_artifacts(), error = function(e) list())
  } else {
    list()
  }
  active_project_id <- active_project_id %||% genai_active_project_id(ctx)
  artifact <- genai_artifact_lookup(artifacts, artifact_id)
  if (is.null(artifact)) {
    errors <- c(errors, paste("Artifact does not exist in the active project:", artifact_id))
    return(service_result(status = "error", errors = errors, value = list(
      artifact_id = artifact_id,
      exists = FALSE,
      available = FALSE,
      current_project_match = FALSE,
      active_project_id = active_project_id,
      inspection_supported = FALSE
    )))
  }

  metadata <- artifact$metadata %||% list()
  artifact_project_id <- metadata$project_id %||% artifact$project_id %||% active_project_id
  status <- artifact$status %||% metadata$status %||% "ready"
  deleted <- identical(tolower(status), "deleted") || isTRUE(metadata$deleted)
  unavailable <- deleted || tolower(status) %in% c("unavailable", "missing", "needs_data", "missing_columns", "rebuild_failed")
  project_match <- identical(as.character(artifact_project_id), as.character(active_project_id))
  supported <- genai_artifact_inspection_supported(artifact)
  version <- genai_artifact_version(artifact)
  display_name <- artifact$label %||% metadata$title %||% artifact$artifact_id %||% artifact_id

  if (!project_match) errors <- c(errors, "Artifact does not belong to the active project.")
  if (deleted) errors <- c(errors, "Artifact was deleted.")
  if (unavailable) errors <- c(errors, paste("Artifact is unavailable:", status))
  if (!supported) errors <- c(errors, paste("Artifact type cannot be inspected:", artifact$artifact_type %||% "unknown"))
  if (is.null(artifact$artifact_type) || !nzchar(artifact$artifact_type)) warnings <- c(warnings, "Artifact metadata is incomplete: artifact_type is missing.")

  value <- list(
    artifact_id = artifact_id,
    exists = TRUE,
    available = !unavailable,
    current_project_match = project_match,
    artifact_type = artifact$artifact_type %||% NA_character_,
    display_name = display_name,
    artifact_version = version,
    artifact_status = status,
    inspection_supported = supported,
    active_project_id = active_project_id
  )
  value$resource_fingerprint <- genai_resource_fingerprint(value)
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(artifact = artifact)
  )
}

genai_resource_fingerprint <- function(resolution_value) {
  resource_type <- resolution_value$resource_type %||% if (!is.null(resolution_value$report_id)) "report" else "artifact"
  if (identical(resource_type, "analysis_preflight")) {
    return(.genai_action_hash(list(
      resource_type = "analysis_preflight",
      active_project_id = resolution_value$active_project_id %||% NA_character_,
      module_id = resolution_value$module_id %||% NA_character_,
      module_version = resolution_value$module_version %||% NA_character_,
      dataset_id = resolution_value$dataset_id %||% NA_character_,
      dataset_version = resolution_value$dataset_version %||% NA_character_,
      schema_version = resolution_value$schema_version %||% NA_character_,
      dataset_availability = resolution_value$dataset_availability %||% NA_character_
    )))
  }
  if (identical(resource_type, "analysis_run_registered")) {
    return(genai_registered_analysis_execution_fingerprint(resolution_value))
  }
  if (identical(resource_type, "report")) {
    return(.genai_action_hash(list(
      resource_type = "report",
      report_id = resolution_value$report_id %||% NA_character_,
      active_project_id = resolution_value$active_project_id %||% NA_character_,
      report_version = resolution_value$report_version %||% NA_character_,
      report_type = resolution_value$report_type %||% NA_character_,
      report_status = resolution_value$report_status %||% NA_character_,
      render_status = resolution_value$render_status %||% NA_character_,
      available = isTRUE(resolution_value$available),
      current_project_match = isTRUE(resolution_value$current_project_match),
      open_supported = isTRUE(resolution_value$open_supported)
    )))
  }
  if (identical(resource_type, "persisted_result")) {
    return(.genai_action_hash(list(
      resource_type = "persisted_result",
      persisted_result_id = resolution_value$persisted_result_id %||% NA_character_,
      active_project_id = resolution_value$active_project_id %||% NA_character_,
      workspace_provider_id = resolution_value$workspace_provider_id %||% NA_character_,
      workspace_provider_type = resolution_value$workspace_provider_type %||% NA_character_,
      manifest_schema_version = resolution_value$manifest_schema_version %||% NA_character_,
      persistence_schema_version = resolution_value$persistence_schema_version %||% NA_character_,
      result_type = resolution_value$result_type %||% NA_character_,
      module_id = resolution_value$module_id %||% NA_character_,
      module_version = resolution_value$module_version %||% NA_character_,
      dataset_id = resolution_value$dataset_id %||% NA_character_,
      dataset_version = resolution_value$dataset_version %||% NA_character_,
      manifest_status = resolution_value$manifest_status %||% NA_character_,
      hash_status = resolution_value$hash_status %||% NA_character_,
      content_hash_summary = resolution_value$content_hash_summary %||% NA_character_,
      persisted_result_fingerprint = resolution_value$persisted_result_fingerprint %||% NA_character_,
      available = isTRUE(resolution_value$available),
      active_project_match = isTRUE(resolution_value$active_project_match),
      project_provider_match = isTRUE(resolution_value$project_provider_match),
      inspection_supported = isTRUE(resolution_value$inspection_supported)
    )))
  }
  .genai_action_hash(list(
    resource_type = "artifact",
    artifact_id = resolution_value$artifact_id %||% NA_character_,
    active_project_id = resolution_value$active_project_id %||% NA_character_,
    artifact_version = resolution_value$artifact_version %||% NA_character_,
    artifact_type = resolution_value$artifact_type %||% NA_character_,
    available = isTRUE(resolution_value$available),
    current_project_match = isTRUE(resolution_value$current_project_match),
    inspection_supported = isTRUE(resolution_value$inspection_supported)
  ))
}

genai_resolve_analysis_preflight_resources <- function(module_id, dataset_id, ctx = NULL) {
  module_resolution <- genai_resolve_module_for_preflight(module_id, ctx = ctx)
  dataset_resolution <- genai_resolve_dataset(dataset_id, ctx = ctx)
  errors <- c(module_resolution$errors %||% character(), dataset_resolution$errors %||% character())
  warnings <- c(module_resolution$warnings %||% character(), dataset_resolution$warnings %||% character())
  value <- c(
    list(resource_type = "analysis_preflight"),
    module_resolution$value %||% list(),
    list(
      dataset_id = dataset_resolution$value$dataset_id %||% dataset_id,
      dataset_display_name = dataset_resolution$value$display_name %||% dataset_id,
      dataset_version = dataset_resolution$value$dataset_version %||% NA_character_,
      schema_version = dataset_resolution$value$schema_version %||% NA_character_,
      dataset_availability = dataset_resolution$value$availability %||% NA_character_,
      row_count = dataset_resolution$value$row_count %||% NA_integer_,
      column_count = dataset_resolution$value$column_count %||% NA_integer_,
      data_source_type = dataset_resolution$value$data_source_type %||% NA_character_,
      active_project_id = dataset_resolution$value$active_project_id %||% genai_active_project_id(ctx)
    )
  )
  value$resource_fingerprint <- genai_preflight_resource_fingerprint(module_resolution$value %||% list(), dataset_resolution$value %||% list())
  service_result(
    status = if (length(errors)) "error" else "success",
    value = value,
    warnings = warnings,
    errors = errors,
    metadata = list(
      module_resolution = module_resolution,
      dataset_resolution = dataset_resolution,
      data = dataset_resolution$metadata$data
    )
  )
}

genai_action_artifact_inspect_handler <- function(arguments, ctx = NULL) {
  resolution <- genai_resolve_artifact(arguments$artifact_id %||% "", ctx = ctx)
  if (!identical(resolution$status, "success")) {
    return(service_result(status = "error", errors = resolution$errors, warnings = resolution$warnings, metadata = list(resource_resolution = resolution$value)))
  }
  if (is.null(ctx)) {
    return(service_result(
      status = "success",
      value = resolution$value,
      messages = paste("Validated artifact inspection target:", resolution$value$display_name),
      metadata = list(
        resource_resolution = resolution$value,
        resource_fingerprint = resolution$value$resource_fingerprint,
        state_changed = FALSE,
        ui_state_changed = FALSE,
        project_state_changed = FALSE,
        persistent_changes = FALSE
      )
    ))
  }
  if (!is.function(ctx$inspect_artifact)) {
    return(service_result(status = "error", errors = "Artifact Studio inspection handler is not available."))
  }
  ctx$inspect_artifact(resolution$value$artifact_id)
  service_result(
    status = "success",
    value = resolution$value,
    messages = paste("Opened Artifact Studio for:", resolution$value$display_name),
    metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      artifact_id = resolution$value$artifact_id,
      artifact_display_name = resolution$value$display_name,
      artifact_type = resolution$value$artifact_type,
      artifact_version = resolution$value$artifact_version,
      active_project_id = resolution$value$active_project_id,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_action_report_open_handler <- function(arguments, ctx = NULL) {
  resolution <- genai_resolve_report(arguments$report_id %||% "", ctx = ctx)
  if (!identical(resolution$status, "success")) {
    return(service_result(status = "error", errors = resolution$errors, warnings = resolution$warnings, metadata = list(resource_resolution = resolution$value)))
  }
  if (is.null(ctx)) {
    return(service_result(
      status = "success",
      value = resolution$value,
      messages = paste("Validated report open target:", resolution$value$display_name),
      metadata = list(
        resource_resolution = resolution$value,
        resource_fingerprint = resolution$value$resource_fingerprint,
        state_changed = FALSE,
        ui_state_changed = FALSE,
        project_state_changed = FALSE,
        persistent_changes = FALSE
      )
    ))
  }
  if (!is.function(ctx$open_report)) {
    return(service_result(status = "error", errors = "Report viewer handler is not available."))
  }
  ctx$open_report(resolution$value$report_id)
  service_result(
    status = "success",
    value = resolution$value,
    messages = paste("Opened Layout Studio for:", resolution$value$display_name),
    metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      report_id = resolution$value$report_id,
      report_display_name = resolution$value$display_name,
      report_type = resolution$value$report_type,
      report_version = resolution$value$report_version,
      report_status = resolution$value$report_status,
      render_status = resolution$value$render_status,
      active_project_id = resolution$value$active_project_id,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_action_analysis_preflight_handler <- function(arguments, ctx = NULL) {
  limits <- if (!is.null(ctx) && is.function(ctx$genai_preflight_limits)) {
    ctx$genai_preflight_limits()
  } else {
    genai_preflight_limits()
  }
  if (!is.null(ctx) && is.function(ctx$reset_genai_preflight_cancel)) {
    ctx$reset_genai_preflight_cancel()
  }
  resolution <- genai_resolve_analysis_preflight_resources(arguments$module_id %||% "", arguments$dataset_id %||% "", ctx = ctx)
  if (!identical(resolution$status, "success")) {
    return(service_result(status = "error", errors = resolution$errors, warnings = resolution$warnings, metadata = list(resource_resolution = resolution$value)))
  }
  data <- resolution$metadata$data
  preflight_id <- paste0("preflight_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
  cancel_fun <- if (!is.null(ctx) && is.function(ctx$genai_preflight_cancel_requested)) {
    ctx$genai_preflight_cancel_requested
  } else {
    function() FALSE
  }
  started <- Sys.time()
  preflight_dataset <- list(
      dataset_id = resolution$value$dataset_id,
      display_name = resolution$value$dataset_display_name,
      active_project_id = resolution$value$active_project_id,
      available = identical(resolution$value$dataset_availability, "available"),
      availability = resolution$value$dataset_availability,
      row_count = resolution$value$row_count,
      column_count = resolution$value$column_count
    )
  snapshot <- genai_create_configuration_snapshot(resolution$value, preflight_dataset, ctx = ctx)
  preflight <- tryCatch(
    if (identical(resolution$value$module_id %||% "", genai_registered_analysis_second_module_id())) {
      if (!identical(snapshot$status, "success")) {
        list(
          readiness = "blocked",
          checks = list(genai_preflight_check("trusted_configuration", "Trusted configuration", "error", paste(c("module_configuration_incomplete", snapshot$errors), collapse = "; "), source = "trusted_configuration")),
          warnings = snapshot$warnings %||% character(),
          errors = c("module_configuration_incomplete", snapshot$errors %||% character()),
          inspection_mode = "metadata",
          rows_considered = 0L,
          columns_considered = 0L
        )
      } else {
        if (identical(snapshot$value$mode_id %||% "", "binary_classification")) {
          genai_run_model_assessment_binary_preflight(
            module_resolution = resolution$value,
            dataset_resolution = preflight_dataset,
            data = data,
            configuration_snapshot = snapshot$value,
            limits = limits,
            cancel_requested = cancel_fun
          )
        } else {
          genai_run_model_assessment_regression_preflight(
            module_resolution = resolution$value,
            dataset_resolution = preflight_dataset,
            data = data,
            configuration_snapshot = snapshot$value,
            limits = limits,
            cancel_requested = cancel_fun
          )
        }
      }
    } else {
      genai_run_generic_preflight(
        module_resolution = resolution$value,
        dataset_resolution = preflight_dataset,
        data = data,
        limits = limits,
        cancel_requested = cancel_fun
      )
    },
    error = function(e) list(
      readiness = "failed",
      checks = list(genai_preflight_check("handler_failure", "Preflight handler", "error", conditionMessage(e))),
      warnings = character(),
      errors = conditionMessage(e),
      inspection_mode = "metadata",
      rows_considered = 0L,
      columns_considered = 0L
    )
  )
  completed <- Sys.time()
  result <- list(
    preflight_result_id = preflight_id,
    module_id = resolution$value$module_id,
    module_display_name = resolution$value$display_name,
    dataset_id = resolution$value$dataset_id,
    dataset_display_name = resolution$value$dataset_display_name,
    active_project_id = resolution$value$active_project_id,
    mode_id = snapshot$value$mode_id %||% NA_character_,
    result_type = snapshot$value$result_type %||% NA_character_,
    created_at = started,
    completed_at = completed,
    expires_at = completed + 60 * 60,
    readiness = preflight$readiness,
    summary = paste("Preflight", preflight$readiness, "for", resolution$value$display_name, "against", resolution$value$dataset_display_name),
    checks = preflight$checks,
    warnings = preflight$warnings %||% character(),
    errors = preflight$errors %||% character(),
    resource_assessment = list(
      rows_considered = preflight$rows_considered %||% 0L,
      columns_considered = preflight$columns_considered %||% 0L,
      inspection_mode = preflight$inspection_mode %||% "metadata",
      limits = limits
    ),
    configuration_requirements = list(
      required_roles = resolution$value$required_roles %||% character(),
      configuration_schema_version = snapshot$value$configuration_schema_version %||% NA_character_,
      configuration_snapshot_id = snapshot$value$configuration_snapshot_id %||% NA_character_,
      configuration_fingerprint = snapshot$value$configuration_fingerprint %||% NA_character_
    ),
    data_summary = list(row_count = resolution$value$row_count, column_count = resolution$value$column_count)
  )
  result$configuration_snapshot_id <- snapshot$value$configuration_snapshot_id %||% NA_character_
  result$configuration_fingerprint <- snapshot$value$configuration_fingerprint %||% NA_character_
  stored_id <- if (!is.null(ctx) && is.function(ctx$store_genai_preflight_result)) {
    ctx$store_genai_preflight_result(result)
  } else {
    preflight_id
  }
  result$preflight_result_id <- stored_id
  status <- switch(result$readiness, cancelled = "cancelled", timed_out = "timed_out", failed = "error", "success")
  service_result(
    status = if (identical(status, "error")) "error" else "success",
    value = result,
    messages = result$summary,
    warnings = result$warnings,
    errors = result$errors,
    metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      module_id = resolution$value$module_id,
      module_display_name = resolution$value$display_name,
      module_version = resolution$value$module_version,
      dataset_id = resolution$value$dataset_id,
      dataset_display_name = resolution$value$dataset_display_name,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id,
      execution_limit_profile = .genai_action_json(limits),
      rows_considered = result$resource_assessment$rows_considered,
      columns_considered = result$resource_assessment$columns_considered,
      inspection_mode = result$resource_assessment$inspection_mode,
      readiness = result$readiness,
      preflight_result_id = stored_id,
      cancel_requested = identical(result$readiness, "cancelled"),
      timed_out = identical(result$readiness, "timed_out"),
      computation_performed = TRUE,
      temporary_result_created = TRUE,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_action_result_inspect_handler <- function(arguments, ctx = NULL) {
  resolution <- genai_resolve_persisted_result(arguments$persisted_result_id %||% "", ctx = ctx)
  if (!identical(resolution$status, "success")) {
    return(service_result(status = "error", errors = resolution$errors, warnings = resolution$warnings, metadata = list(resource_resolution = resolution$value)))
  }
  if (is.null(ctx)) {
    return(service_result(
      status = "success",
      value = resolution$value,
      messages = paste("Validated persisted result inspection target:", resolution$value$display_name),
      metadata = list(
        resource_resolution = resolution$value,
        resource_fingerprint = resolution$value$resource_fingerprint,
        state_changed = FALSE,
        ui_state_changed = FALSE,
        project_state_changed = FALSE,
        persistent_changes = FALSE,
        computation_performed = FALSE,
        temporary_result_created = FALSE,
        persisted_result_created = FALSE,
        artifact_created = FALSE,
        report_created = FALSE
      )
    ))
  }
  if (!is.function(ctx$inspect_persisted_result)) {
    return(service_result(status = "error", errors = "Persisted Results browser inspection handler is not available."))
  }
  bridge <- ctx$inspect_persisted_result(resolution$value$persisted_result_id)
  if (identical(bridge$status %||% "success", "error")) {
    return(service_result(status = "error", errors = bridge$errors %||% "Persisted result browser selection failed."))
  }
  service_result(
    status = "success",
    value = resolution$value,
    messages = paste("Opened Persisted Results browser for:", resolution$value$display_name),
    metadata = list(
      resource_resolution = resolution$value,
      resource_fingerprint = resolution$value$resource_fingerprint,
      persisted_result_id = resolution$value$persisted_result_id,
      result_type = resolution$value$result_type,
      module_id = resolution$value$module_id,
      module_version = resolution$value$module_version,
      dataset_id = resolution$value$dataset_id,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id,
      workspace_provider_id = resolution$value$workspace_provider_id,
      workspace_provider_type = resolution$value$workspace_provider_type,
      project_provider_match = isTRUE(resolution$value$project_provider_match),
      persistence_schema_version = resolution$value$persistence_schema_version,
      safe_relative_location = resolution$value$safe_relative_location,
      content_hashes = resolution$value$content_hash_summary,
      persisted_result_fingerprint = resolution$value$persisted_result_fingerprint,
      manifest_status = resolution$value$manifest_status,
      hash_status = resolution$value$hash_status,
      computation_performed = FALSE,
      temporary_result_created = FALSE,
      persisted_result_created = FALSE,
      artifact_created = FALSE,
      report_created = FALSE,
      state_changed = TRUE,
      ui_state_changed = TRUE,
      project_state_changed = FALSE,
      persistent_changes = FALSE
    )
  )
}

genai_action_registry <- function() {
  registry <- genai_action_registry_create()
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "module.open",
      action_version = "1.0",
      display_name = "Open Module",
      description = "Navigate to an existing registered Analytics Workstation module.",
      risk_tier = "low",
      input_schema = list(
        required = "module_id",
        properties = list(module_id = list(type = "string", enum = names(get_module_registry()))),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = "temporary_navigation",
      reversible = TRUE,
      approval_required = TRUE,
      handler = genai_action_module_open_handler
    )
  )
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "artifact.inspect",
      action_version = "1.0",
      display_name = "Inspect Artifact",
      description = "Open Artifact Studio and select one existing artifact by stable artifact id.",
      risk_tier = "low",
      input_schema = list(
        required = "artifact_id",
        properties = list(artifact_id = list(type = "string")),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = "temporary_navigation",
      reversible = TRUE,
      approval_required = TRUE,
      handler = genai_action_artifact_inspect_handler
    )
  )
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "report.open",
      action_version = "1.0",
      display_name = "Open Report",
      description = "Open Layout Studio and select one existing report plan by stable report id.",
      risk_tier = "low",
      input_schema = list(
        required = "report_id",
        properties = list(report_id = list(type = "string")),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = "temporary_navigation",
      reversible = TRUE,
      approval_required = TRUE,
      handler = genai_action_report_open_handler
    )
  )
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "result.inspect",
      action_version = "1.0",
      display_name = "Inspect Persisted Result",
      description = "Open the project Persisted Results browser and select one healthy persisted result.",
      risk_tier = "low",
      input_schema = list(
        required = "persisted_result_id",
        properties = list(persisted_result_id = list(type = "string")),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = "temporary_navigation",
      reversible = TRUE,
      approval_required = TRUE,
      persistence_requested = FALSE,
      handler = genai_action_result_inspect_handler
    )
  )
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "analysis.preflight",
      action_version = "1.0",
      display_name = "Preflight Analysis",
      description = "Run bounded, read-only module and dataset readiness checks without running the full analysis.",
      risk_tier = "medium",
      input_schema = list(
        required = c("module_id", "dataset_id"),
        properties = list(module_id = list(type = "string"), dataset_id = list(type = "string")),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = c("bounded_computation", "temporary_session_result"),
      reversible = TRUE,
      approval_required = TRUE,
      handler = genai_action_analysis_preflight_handler
    )
  )
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "analysis.run_registered",
      action_version = "1.0",
      display_name = "Run Registered Analysis",
      description = "Run one allowlisted registered analysis module against the trusted active dataset and create a temporary session-local result.",
      risk_tier = "medium",
      input_schema = list(
        required = c("module_id", "dataset_id"),
        properties = list(module_id = list(type = "string"), dataset_id = list(type = "string")),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = c("bounded_computation", "temporary_session_result"),
      reversible = TRUE,
      approval_required = TRUE,
      handler = genai_action_analysis_run_registered_handler
    )
  )
  genai_action_registry_register(
    registry,
    genai_action_definition(
      action_id = "result.persist",
      action_version = "1.0",
      display_name = "Persist Temporary Result",
      description = "Persist one completed supported temporary result into the active project's trusted result storage.",
      risk_tier = "high",
      input_schema = list(
        required = "temporary_result_id",
        properties = list(temporary_result_id = list(type = "string")),
        additional_properties = FALSE
      ),
      required_permissions = "can_approve_genai_action",
      allowed_execution_modes = "approval_required",
      side_effects = c("persistent_project_write", "project_result_created"),
      reversible = "limited",
      approval_required = TRUE,
      persistence_requested = TRUE,
      handler = genai_action_result_persist_handler
    )
  )
  registry
}

genai_action_metadata <- function(registry = genai_action_registry()) {
  rows <- lapply(genai_action_registry_list(registry), function(action) {
    data.table::data.table(
      action_id = action$action_id,
      action_version = action$action_version,
      display_name = action$display_name,
      description = action$description,
      risk_tier = action$risk_tier,
      approval_required = isTRUE(action$approval_required),
      reversible = as.character(action$reversible %||% NA_character_),
      persistence_requested = isTRUE(action$persistence_requested),
      side_effects = paste(action$side_effects, collapse = ", "),
      allowed_execution_modes = paste(action$allowed_execution_modes, collapse = ", ")
    )
  })
  data.table::rbindlist(rows, fill = TRUE)
}

.genai_action_json <- function(x) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    return(as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA)))
  }
  paste(capture.output(str(x, give.attr = FALSE)), collapse = "\n")
}

.genai_action_hash <- function(x) {
  payload <- .genai_action_json(x)
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(payload, algo = "sha256"))
  }
  raw <- as.integer(charToRaw(payload))
  paste0("fallback_", sprintf("%08x", sum(raw * seq_along(raw)) %% .Machine$integer.max))
}

genai_action_hash_payload <- function(proposal) {
  list(
    proposal_version = proposal$proposal_version,
    action_id = proposal$action_id,
    action_version = proposal$action_version,
    arguments = proposal$arguments,
    rationale = proposal$rationale,
    evidence_refs = proposal$evidence_refs,
    expected_effects = proposal$expected_effects,
    state_mutations = proposal$state_mutations,
    persistence_requested = isTRUE(proposal$persistence_requested),
    risk_tier = proposal$risk_tier,
    confidence = proposal$confidence,
    proposal_id = proposal$proposal_id,
    created_at = as.character(proposal$created_at),
    expires_at = as.character(proposal$expires_at)
  )
}

genai_action_compute_hash <- function(proposal) {
  .genai_action_hash(genai_action_hash_payload(proposal))
}

genai_action_proposal <- function(
  action_id,
  arguments,
  rationale,
  evidence_refs = character(),
  expected_effects = character(),
  state_mutations = list(),
  persistence_requested = FALSE,
  risk_tier = "low",
  confidence = NA_real_,
  action_version = "1.0",
  proposal_version = "1.0",
  proposal_id = NULL,
  created_at = Sys.time(),
  expires_at = created_at + 15 * 60,
  status = "proposed"
) {
  proposal <- list(
    proposal_id = proposal_id %||% paste0("proposal_", format(created_at, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    proposal_version = proposal_version,
    action_id = action_id,
    action_version = action_version,
    arguments = arguments,
    rationale = rationale,
    evidence_refs = evidence_refs %||% character(),
    expected_effects = expected_effects %||% character(),
    state_mutations = state_mutations %||% list(),
    persistence_requested = isTRUE(persistence_requested),
    risk_tier = risk_tier,
    confidence = suppressWarnings(as.numeric(confidence)),
    created_at = created_at,
    expires_at = expires_at,
    status = status
  )
  proposal$proposal_hash <- genai_action_compute_hash(proposal)
  structure(proposal, class = c("aq_genai_action_proposal", "list"))
}

genai_action_proposal_from_model <- function(x, now = Sys.time()) {
  if (!is.list(x)) {
    return(service_result(status = "error", errors = "Proposal payload must be a JSON object or list."))
  }
  proposal <- tryCatch(
    genai_action_proposal(
      action_id = x$action_id %||% "",
      action_version = x$action_version %||% "1.0",
      proposal_version = x$proposal_version %||% "1.0",
      arguments = x$arguments %||% list(),
      rationale = x$rationale %||% "",
      evidence_refs = x$evidence_refs %||% character(),
      expected_effects = x$expected_effects %||% character(),
      state_mutations = x$state_mutations %||% list(),
      persistence_requested = isTRUE(x$persistence_requested),
      risk_tier = x$risk_tier %||% "low",
      confidence = x$confidence %||% NA_real_,
      created_at = now,
      expires_at = now + 15 * 60,
      status = "proposed"
    ),
    error = function(e) e
  )
  if (inherits(proposal, "error")) {
    return(service_result(status = "error", errors = conditionMessage(proposal)))
  }
  service_result(status = "success", value = proposal, messages = "GenAI action proposal parsed.")
}

genai_extract_action_proposal <- function(text) {
  if (!nzchar(text %||% "")) {
    return(service_result(status = "needs_input", warnings = "No text to parse."))
  }
  candidates <- character()
  fenced <- regmatches(text, gregexpr("```(?:json)?\\s*\\{[\\s\\S]*?\\}\\s*```", text, perl = TRUE))[[1]]
  if (length(fenced)) {
    candidates <- c(candidates, gsub("^```(?:json)?\\s*|\\s*```$", "", fenced, perl = TRUE))
  }
  raw_json <- regmatches(text, gregexpr("\\{[\\s\\S]*\\}", text, perl = TRUE))[[1]]
  candidates <- unique(c(candidates, raw_json))
  if (!length(candidates)) {
    return(service_result(status = "needs_input", warnings = "No action proposal JSON found."))
  }
  for (candidate in candidates) {
    parsed <- tryCatch(genai_from_json(candidate), error = function(e) NULL)
    if (is.list(parsed)) {
      payload <- parsed$action_proposal %||% parsed$proposal %||% parsed
      result <- genai_action_proposal_from_model(payload)
      if (identical(result$status, "success")) {
        return(result)
      }
    }
  }
  service_result(status = "warning", warnings = "Malformed or unsupported action proposal ignored.")
}

genai_attach_action_proposal <- function(result) {
  if (!identical(result$status, "success")) {
    return(result)
  }
  text <- result$value$text %||% ""
  parsed <- genai_extract_action_proposal(text)
  result$metadata$action_proposal_parse_status <- parsed$status
  if (identical(parsed$status, "success")) {
    result$metadata$action_proposal <- parsed$value
  } else {
    result$metadata$action_proposal_warnings <- parsed$warnings %||% parsed$errors
  }
  result
}

genai_action_risk_rank <- function(risk_tier) {
  levels <- genai_action_risk_levels()
  match(risk_tier %||% "none", levels, nomatch = length(levels) + 1L)
}

genai_validate_action_proposal <- function(
  proposal,
  registry = genai_action_registry(),
  policy = genai_action_policy(),
  now = Sys.time(),
  ctx = NULL
) {
  errors <- character()
  warnings <- character()
  resource_resolution <- NULL
  resource_fingerprint <- NULL
  if (!is.list(proposal)) {
    errors <- c(errors, "Proposal must be a list.")
    return(service_result(status = "error", value = list(valid = FALSE, errors = errors, warnings = warnings)))
  }
  required <- c(
    "proposal_id", "proposal_version", "action_id", "action_version", "arguments",
    "rationale", "evidence_refs", "expected_effects", "state_mutations",
    "persistence_requested", "risk_tier", "confidence", "created_at", "expires_at",
    "proposal_hash", "status"
  )
  missing <- setdiff(required, names(proposal))
  if (length(missing)) errors <- c(errors, paste("Missing proposal fields:", paste(missing, collapse = ", ")))

  action <- genai_action_registry_get(proposal$action_id %||% "", registry)
  if (is.null(action)) {
    errors <- c(errors, paste("Unknown action_id:", proposal$action_id %||% ""))
  } else {
    if (!identical(proposal$action_version %||% "", action$action_version)) {
      errors <- c(errors, paste("Unsupported action_version:", proposal$action_version %||% ""))
    }
    if (genai_action_risk_rank(proposal$risk_tier) < genai_action_risk_rank(action$risk_tier)) {
      errors <- c(errors, "Proposal risk_tier understates registered action risk.")
    }
  }

  if (isTRUE(proposal$persistence_requested) && !isTRUE(action$persistence_requested %||% FALSE)) {
    errors <- c(errors, "Persistence is not allowed for this GenAI action.")
  }
  if (!is.null(action) && isTRUE(action$persistence_requested %||% FALSE) && !isTRUE(proposal$persistence_requested)) {
    errors <- c(errors, "This action requires persistence_requested = true.")
  }
  if (length(proposal$state_mutations %||% list()) && !identical(proposal$action_id %||% "", "result.persist")) {
    errors <- c(errors, "State mutations must be empty for GenAI UI actions.")
  }
  if (!nzchar(proposal$rationale %||% "")) {
    errors <- c(errors, "Proposal rationale is required.")
  }
  if (!proposal$status %in% genai_action_statuses()) {
    errors <- c(errors, paste("Unsupported proposal status:", proposal$status %||% ""))
  }
  if (proposal$status %in% c("rejected", "cancelled", "succeeded", "failed", "expired")) {
    errors <- c(errors, paste("Proposal is no longer approvable:", proposal$status))
  }
  expires_at <- tryCatch(as.POSIXct(proposal$expires_at), error = function(e) NA)
  if (is.na(expires_at) || expires_at < now) {
    errors <- c(errors, "Proposal is expired.")
  }
  expected_hash <- tryCatch(genai_action_compute_hash(proposal), error = function(e) NA_character_)
  if (!identical(proposal$proposal_hash %||% "", expected_hash)) {
    errors <- c(errors, "Proposal hash is invalid or stale.")
  }

  if (!is.null(action) && identical(action$action_id, "module.open")) {
    args <- proposal$arguments %||% list()
    extra <- setdiff(names(args), "module_id")
    if (!"module_id" %in% names(args) || !nzchar(args$module_id %||% "")) {
      errors <- c(errors, "module.open requires arguments$module_id.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("module.open received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    module <- get_module_definition(args$module_id %||% "")
    if (is.null(module)) {
      errors <- c(errors, paste("Unknown module_id:", args$module_id %||% ""))
    }
  }
  if (!is.null(action) && identical(action$action_id, "artifact.inspect")) {
    args <- proposal$arguments %||% list()
    extra <- setdiff(names(args), "artifact_id")
    artifact_id <- args$artifact_id
    if (!"artifact_id" %in% names(args) || !genai_artifact_id_is_valid(artifact_id)) {
      errors <- c(errors, "artifact.inspect requires arguments$artifact_id as a stable scalar artifact identifier.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("artifact.inspect received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    if (is.character(artifact_id) && length(artifact_id) == 1L &&
        (grepl("[/\\\\]", artifact_id) || grepl("^[A-Za-z]:", artifact_id) || grepl("^https?://", artifact_id, ignore.case = TRUE))) {
      errors <- c(errors, "artifact.inspect does not accept paths or URLs.")
    }
    if (!length(errors)) {
      resolution <- genai_resolve_artifact(artifact_id, ctx = ctx)
      resource_resolution <- resolution$value
      resource_fingerprint <- resolution$value$resource_fingerprint %||% NULL
      warnings <- c(warnings, resolution$warnings %||% character())
      if (!identical(resolution$status, "success")) {
        errors <- c(errors, resolution$errors %||% "Artifact resolution failed.")
      }
    }
  }
  if (!is.null(action) && identical(action$action_id, "report.open")) {
    args <- proposal$arguments %||% list()
    extra <- setdiff(names(args), "report_id")
    report_id <- args$report_id
    if (!"report_id" %in% names(args) || !genai_resource_id_is_valid(report_id)) {
      errors <- c(errors, "report.open requires arguments$report_id as a stable scalar report identifier.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("report.open received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    if (is.character(report_id) && length(report_id) == 1L &&
        (grepl("[/\\\\]", report_id) || grepl("^[A-Za-z]:", report_id) || grepl("^https?://", report_id, ignore.case = TRUE))) {
      errors <- c(errors, "report.open does not accept paths or URLs.")
    }
    if (!length(errors)) {
      resolution <- genai_resolve_report(report_id, ctx = ctx)
      resource_resolution <- resolution$value
      resource_fingerprint <- resolution$value$resource_fingerprint %||% NULL
      warnings <- c(warnings, resolution$warnings %||% character())
      if (!identical(resolution$status, "success")) {
        errors <- c(errors, resolution$errors %||% "Report resolution failed.")
      }
    }
  }
  if (!is.null(action) && identical(action$action_id, "result.inspect")) {
    args <- proposal$arguments %||% list()
    extra <- setdiff(names(args), "persisted_result_id")
    persisted_result_id <- args$persisted_result_id
    if (!"persisted_result_id" %in% names(args) || !genai_resource_id_is_valid(persisted_result_id)) {
      errors <- c(errors, "result.inspect requires arguments$persisted_result_id as a trusted scalar persisted result identifier.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("result.inspect received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    prohibited <- intersect(
      names(args),
      c(
        "project_id", "provider_id", "provider_type", "workspace_root", "project_root",
        "result_path", "manifest_path", "filename", "path", "url", "result_type",
        "module_id", "dataset_id", "view_route", "tab_name", "callback", "function_name",
        "repair", "repair_flag", "export_format", "format", "sql", "code", "r_code",
        "python_code", "shell"
      )
    )
    if (length(prohibited)) {
      errors <- c(errors, paste("result.inspect cannot accept model-supplied storage, route, repair, export, or code fields:", paste(prohibited, collapse = ", ")))
    }
    if (is.character(persisted_result_id) && length(persisted_result_id) == 1L &&
        (grepl("[/\\\\]", persisted_result_id) || grepl("^[A-Za-z]:", persisted_result_id) || grepl("^https?://", persisted_result_id, ignore.case = TRUE))) {
      errors <- c(errors, "result.inspect does not accept paths or URLs.")
    }
    if (!length(errors)) {
      resolution <- genai_resolve_persisted_result(persisted_result_id, ctx = ctx)
      resource_resolution <- resolution$value
      resource_fingerprint <- resolution$value$resource_fingerprint %||% NULL
      warnings <- c(warnings, resolution$warnings %||% character())
      if (!identical(resolution$status, "success")) {
        errors <- c(errors, resolution$errors %||% "Persisted result resolution failed.")
      }
    }
  }
  if (!is.null(action) && identical(action$action_id, "analysis.preflight")) {
    args <- proposal$arguments %||% list()
    extra <- setdiff(names(args), c("module_id", "dataset_id"))
    module_id <- args$module_id
    dataset_id <- args$dataset_id
    if (!"module_id" %in% names(args) || !genai_resource_id_is_valid(module_id)) {
      errors <- c(errors, "analysis.preflight requires arguments$module_id as a stable scalar registered module identifier.")
    }
    if (!"dataset_id" %in% names(args) || !genai_resource_id_is_valid(dataset_id)) {
      errors <- c(errors, "analysis.preflight requires arguments$dataset_id as a stable scalar trusted dataset identifier.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("analysis.preflight received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    for (value in c(module_id, dataset_id)) {
      if (is.character(value) && length(value) == 1L &&
          (grepl("[/\\\\]", value) || grepl("^[A-Za-z]:", value) || grepl("^https?://", value, ignore.case = TRUE))) {
        errors <- c(errors, "analysis.preflight does not accept paths or URLs.")
      }
    }
    if (!length(errors)) {
      resolution <- genai_resolve_analysis_preflight_resources(module_id, dataset_id, ctx = ctx)
      resource_resolution <- resolution$value
      resource_fingerprint <- resolution$value$resource_fingerprint %||% NULL
      warnings <- c(warnings, resolution$warnings %||% character())
      if (!identical(resolution$status, "success")) {
        errors <- c(errors, resolution$errors %||% "Analysis preflight resource resolution failed.")
      }
    }
  }
  if (!is.null(action) && identical(action$action_id, "analysis.run_registered")) {
    args <- proposal$arguments %||% list()
    extra <- setdiff(names(args), c("module_id", "dataset_id"))
    module_id <- args$module_id
    dataset_id <- args$dataset_id
    if (!"module_id" %in% names(args) || !genai_resource_id_is_valid(module_id)) {
      errors <- c(errors, "analysis.run_registered requires arguments$module_id as a stable scalar registered module identifier.")
    }
    if (!"dataset_id" %in% names(args) || !genai_resource_id_is_valid(dataset_id)) {
      errors <- c(errors, "analysis.run_registered requires arguments$dataset_id as the trusted active dataset identifier.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("analysis.run_registered received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    prohibited <- intersect(
      names(args),
      c(
        "target", "target_variable", "predictors", "predictor_variables", "grouping",
        "formula", "filters", "joins", "transformations", "feature_engineering",
        "module_options", "chart_settings", "sample_size", "row_limit", "column_limit",
        "timeout", "memory_limit", "threads", "output_format", "output_name",
        "output_path", "report_settings", "persistence", "project_id", "user_id",
        "function_name", "callback", "package", "sql", "code", "r_code", "python_code",
        "shell", "url", "path"
      )
    )
    if (length(prohibited)) {
      errors <- c(errors, paste("analysis.run_registered cannot accept model-supplied execution configuration:", paste(prohibited, collapse = ", ")))
    }
    for (value in c(module_id, dataset_id, unlist(args, use.names = FALSE))) {
      if (is.character(value) && length(value) == 1L &&
          (grepl("[/\\\\]", value) || grepl("^[A-Za-z]:", value) || grepl("^https?://", value, ignore.case = TRUE))) {
        errors <- c(errors, "analysis.run_registered does not accept paths or URLs.")
      }
    }
    if (!length(errors)) {
      resolution <- genai_resolve_registered_analysis_resources(module_id, dataset_id, ctx = ctx)
      resource_resolution <- resolution$value
      resource_fingerprint <- resolution$value$resource_fingerprint %||% NULL
      warnings <- c(warnings, resolution$warnings %||% character())
      if (!identical(resolution$status, "success")) {
        errors <- c(errors, resolution$errors %||% "Registered analysis resource resolution failed.")
      }
    }
  }
  if (!is.null(action) && identical(action$action_id, "result.persist")) {
    args <- proposal$arguments %||% list()
    temporary_result_id <- args$temporary_result_id
    extra <- setdiff(names(args), "temporary_result_id")
    if (!"temporary_result_id" %in% names(args) || !genai_resource_id_is_valid(temporary_result_id)) {
      errors <- c(errors, "result.persist requires arguments$temporary_result_id as a trusted scalar temporary result identifier.")
    }
    if (length(extra)) {
      errors <- c(errors, paste("result.persist received prohibited arguments:", paste(extra, collapse = ", ")))
    }
    prohibited <- intersect(
      names(args),
      c(
        "provider_id", "provider_type", "workspace_root", "workspace_directory",
        "project_id", "project_root", "output_directory", "output_path", "filename",
        "persisted_result_id", "display_name", "artifact_id", "report_id", "format",
        "overwrite", "overwrite_flag", "version", "tags", "retention", "export_options",
        "code", "callback", "callbacks", "formula", "dataset_id", "module_id", "timestamp"
      )
    )
    if (length(prohibited)) {
      errors <- c(errors, paste("result.persist cannot accept model-supplied persistence configuration:", paste(prohibited, collapse = ", ")))
    }
    for (value in unlist(args, use.names = FALSE)) {
      if (is.character(value) && length(value) == 1L &&
          (grepl("[/\\\\]", value) || grepl("^[A-Za-z]:", value) || grepl("^https?://", value, ignore.case = TRUE))) {
        errors <- c(errors, "result.persist does not accept paths or URLs.")
      }
    }
    if (!length(errors)) {
      resolution <- genai_resolve_result_persistence_resources(temporary_result_id, ctx = ctx, proposal = proposal)
      resource_resolution <- resolution$value
      resource_fingerprint <- resolution$value$persistence_fingerprint %||% NULL
      warnings <- c(warnings, resolution$warnings %||% character())
      if (!identical(resolution$status, "success")) {
        errors <- c(errors, resolution$errors %||% "Result persistence resource resolution failed.")
      }
    }
  }

  mode <- policy$execution_mode %||% "read_only"
  if (!isTRUE(policy$allow_proposals)) {
    errors <- c(errors, "Current policy does not allow GenAI proposals.")
  }
  if (!is.null(action) && !mode %in% action$allowed_execution_modes) {
    errors <- c(errors, paste("Current execution mode does not permit this action:", mode))
  }
  if (!isTRUE(action$approval_required %||% TRUE)) {
    errors <- c(errors, "Phase 1 actions must require approval.")
  }
  if (identical(mode, "read_only")) {
    warnings <- c(warnings, "Read-only mode may display proposals but cannot execute them.")
  }

  valid <- !length(errors)
  service_result(
    status = if (valid) "success" else "error",
    value = list(
      valid = valid,
      errors = errors,
      warnings = warnings,
      policy_decision = if (valid) "awaiting_approval" else "rejected",
      requires_approval = TRUE,
      resource_resolution = resource_resolution,
      resource_fingerprint = resource_fingerprint
    ),
    warnings = warnings,
    errors = errors,
    metadata = list(
      action_id = proposal$action_id %||% NA_character_,
      resource_resolution = resource_resolution,
      resource_fingerprint = resource_fingerprint
    )
  )
}

genai_approve_action_proposal <- function(proposal, validation, approval_source = "user") {
  if (!identical(validation$status, "success") || !isTRUE(validation$value$valid)) {
    return(service_result(status = "error", errors = "Cannot approve an invalid GenAI action proposal."))
  }
  if (identical(approval_source, "genai")) {
    return(service_result(status = "error", errors = "GenAI cannot approve its own proposal."))
  }
  proposal$status <- "approved"
  proposal$approved_at <- Sys.time()
  proposal$approval_source <- approval_source
  proposal$approval_hash <- proposal$proposal_hash
  proposal$approval_resource_fingerprint <- validation$value$resource_fingerprint %||% NULL
  service_result(status = "success", value = proposal, messages = "Proposal approved.")
}

genai_reject_action_proposal <- function(proposal, approval_source = "user") {
  proposal$status <- "rejected"
  proposal$rejected_at <- Sys.time()
  proposal$approval_source <- approval_source
  service_result(status = "success", value = proposal, messages = "Proposal rejected.")
}

genai_cancel_action_proposal <- function(proposal, approval_source = "user") {
  proposal$status <- "cancelled"
  proposal$cancelled_at <- Sys.time()
  proposal$approval_source <- approval_source
  service_result(status = "success", value = proposal, messages = "Proposal cancelled.")
}

genai_action_audit_event <- function(proposal, execution = NULL, validation = NULL) {
  data.table::data.table(
    proposal_id = proposal$proposal_id %||% NA_character_,
    proposal_hash = proposal$proposal_hash %||% NA_character_,
    execution_id = execution$execution_id %||% NA_character_,
    action_id = proposal$action_id %||% NA_character_,
    action_version = proposal$action_version %||% NA_character_,
    risk_tier = proposal$risk_tier %||% NA_character_,
    proposal_created_at = as.character(proposal$created_at %||% NA_character_),
    approved_at = as.character(proposal$approved_at %||% NA_character_),
    executed_at = as.character(execution$completed_at %||% NA_character_),
    approval_source = proposal$approval_source %||% NA_character_,
    policy_decision = validation$value$policy_decision %||% NA_character_,
    arguments = .genai_action_json(proposal$arguments %||% list()),
    evidence_refs = paste(proposal$evidence_refs %||% character(), collapse = "; "),
    result_status = execution$status %||% proposal$status %||% NA_character_,
    artifact_id = execution$artifact_id %||% NA_character_,
    artifact_display_name = execution$artifact_display_name %||% NA_character_,
    artifact_type = execution$artifact_type %||% NA_character_,
    artifact_version = execution$artifact_version %||% NA_character_,
    report_id = execution$report_id %||% NA_character_,
    report_display_name = execution$report_display_name %||% NA_character_,
    report_type = execution$report_type %||% NA_character_,
    report_version = execution$report_version %||% NA_character_,
    report_status = execution$report_status %||% NA_character_,
    render_status = execution$render_status %||% NA_character_,
    module_id = execution$module_id %||% NA_character_,
    module_display_name = execution$module_display_name %||% NA_character_,
    module_version = execution$module_version %||% NA_character_,
    mode_id = execution$mode_id %||% NA_character_,
    dataset_id = execution$dataset_id %||% NA_character_,
    dataset_display_name = execution$dataset_display_name %||% NA_character_,
    dataset_version = execution$dataset_version %||% NA_character_,
    schema_version = execution$schema_version %||% NA_character_,
    active_project_id = execution$active_project_id %||% NA_character_,
    execution_limit_profile = execution$execution_limit_profile %||% NA_character_,
    rows_considered = execution$rows_considered %||% NA_integer_,
    columns_considered = execution$columns_considered %||% NA_integer_,
    inspection_mode = execution$inspection_mode %||% NA_character_,
    readiness = execution$readiness %||% NA_character_,
    preflight_result_id = execution$preflight_result_id %||% NA_character_,
    preflight_fingerprint = execution$preflight_fingerprint %||% NA_character_,
    configuration_snapshot_id = execution$configuration_snapshot_id %||% NA_character_,
    configuration_fingerprint = execution$configuration_fingerprint %||% NA_character_,
    positive_class = execution$positive_class %||% NA_character_,
    decision_threshold = execution$decision_threshold %||% NA_real_,
    prediction_scale = execution$prediction_scale %||% NA_character_,
    composite_execution_fingerprint = execution$composite_execution_fingerprint %||% NA_character_,
    job_id = execution$job_id %||% NA_character_,
    temporary_result_id = execution$temporary_result_id %||% NA_character_,
    source_temporary_result_id = execution$source_temporary_result_id %||% NA_character_,
    source_execution_id = execution$source_execution_id %||% NA_character_,
    temporary_result_fingerprint = execution$temporary_result_fingerprint %||% NA_character_,
    workspace_provider_id = execution$workspace_provider_id %||% NA_character_,
    workspace_provider_type = execution$workspace_provider_type %||% NA_character_,
    workspace_is_managed = isTRUE(execution$workspace_is_managed),
    provider_capability_version = execution$provider_capability_version %||% NA_character_,
    provider_write_policy = execution$provider_write_policy %||% NA_character_,
    provider_validation_result = execution$provider_validation_result %||% NA_character_,
    project_provider_match = isTRUE(execution$project_provider_match),
    project_root_identity = execution$project_root_identity %||% NA_character_,
    persistence_fingerprint = execution$persistence_fingerprint %||% NA_character_,
    persistence_schema_version = execution$persistence_schema_version %||% NA_character_,
    persisted_result_id = execution$persisted_result_id %||% NA_character_,
    persisted_result_type = execution$result_type %||% NA_character_,
    persisted_result_fingerprint = execution$persisted_result_fingerprint %||% NA_character_,
    manifest_status = execution$manifest_status %||% NA_character_,
    hash_status = execution$hash_status %||% NA_character_,
    safe_relative_location = execution$safe_relative_location %||% NA_character_,
    content_hashes = execution$content_hashes %||% NA_character_,
    bytes_written = execution$bytes_written %||% NA_real_,
    files_written = execution$files_written %||% NA_integer_,
    idempotency_key = execution$idempotency_key %||% NA_character_,
    already_committed = isTRUE(execution$already_committed),
    execution_stages = execution$execution_stages %||% NA_character_,
    elapsed_time = execution$elapsed_time %||% NA_integer_,
    result_size = execution$result_size %||% NA_integer_,
    cancel_requested = isTRUE(execution$cancel_requested),
    timed_out = isTRUE(execution$timed_out),
    computation_performed = isTRUE(execution$computation_performed),
    temporary_result_created = isTRUE(execution$temporary_result_created),
    persisted_result_created = isTRUE(execution$persisted_result_created),
    artifact_created = isTRUE(execution$artifact_created),
    report_created = isTRUE(execution$report_created),
    resource_fingerprint = execution$resource_fingerprint %||% validation$value$resource_fingerprint %||% NA_character_,
    resource_validation_result = validation$status %||% NA_character_,
    ui_state_changed = isTRUE(execution$ui_state_changed),
    project_state_changed = isTRUE(execution$project_state_changed),
    persistent_changes = isTRUE(execution$persistent_changes),
    warnings = paste(c(validation$warnings %||% character(), execution$warnings %||% character()), collapse = "; "),
    errors = paste(c(validation$errors %||% character(), execution$errors %||% character()), collapse = "; ")
  )
}

genai_execute_action_proposal <- function(
  proposal,
  ctx = NULL,
  registry = genai_action_registry(),
  policy = genai_action_policy(),
  approval_hash = proposal$approval_hash %||% NULL
) {
  started_at <- Sys.time()
  execution_id <- paste0("execution_", format(started_at, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
  validation <- genai_validate_action_proposal(proposal, registry = registry, policy = policy, now = started_at, ctx = ctx)
  if (!identical(validation$status, "success")) {
    return(service_result(status = "error", errors = validation$errors, metadata = list(validation = validation)))
  }
  if (!identical(proposal$status %||% "", "approved")) {
    return(service_result(status = "error", errors = "Proposal must be explicitly approved before execution."))
  }
  if (!identical(approval_hash %||% "", proposal$proposal_hash %||% "")) {
    return(service_result(status = "error", errors = "Approval hash does not match the current proposal."))
  }
  if (!is.null(validation$value$resource_fingerprint %||% NULL) &&
      !identical(proposal$approval_resource_fingerprint %||% "", validation$value$resource_fingerprint %||% "")) {
    return(service_result(status = "error", errors = "Approved resource fingerprint is stale or missing.", metadata = list(validation = validation)))
  }
  if (!isTRUE(policy$allow_approved_execution)) {
    return(service_result(status = "error", errors = "Current policy does not allow approved GenAI action execution."))
  }
  if (!is.null(ctx) && is.function(ctx$genai_action_proposal_executed) &&
      isTRUE(ctx$genai_action_proposal_executed(proposal$proposal_id %||% ""))) {
    return(service_result(status = "error", errors = "Approved proposal has already been executed. A new attempt requires a new proposal.", metadata = list(validation = validation)))
  }
  durable_audit_results <- list()
  if (exists("genai_record_durable_audit", mode = "function")) {
    start_execution <- list(
      execution_id = execution_id,
      proposal_id = proposal$proposal_id,
      action_id = proposal$action_id,
      status = "running",
      started_at = started_at,
      completed_at = NA_character_,
      warnings = character(),
      errors = character(),
      persistent_changes = isTRUE(proposal$persistence_requested),
      project_state_changed = isTRUE(proposal$persistence_requested)
    )
    durable_audit_results$approval_granted <- genai_record_durable_audit("approval_granted", proposal, start_execution, validation, ctx)
    durable_audit_results$execution_started <- genai_record_durable_audit("execution_started", proposal, start_execution, validation, ctx)
    durable_start_failed <- any(vapply(durable_audit_results, function(x) identical(x$status, "error"), logical(1)))
    if (isTRUE(durable_start_failed) && identical(proposal$action_id %||% "", "result.persist")) {
      return(service_result(
        status = "error",
        errors = paste("Durable audit write failed before persistent execution:", paste(vapply(durable_audit_results, function(x) paste(x$errors %||% character(), collapse = " "), character(1)), collapse = " ")),
        metadata = list(validation = validation, durable_audit = durable_audit_results)
      ))
    }
  }
  action <- genai_action_registry_get(proposal$action_id, registry)
  handler_result <- tryCatch(
    if (action$action_id %in% c("analysis.run_registered", "result.persist")) {
      action$handler(proposal$arguments, ctx = ctx, proposal = proposal, execution_id = execution_id)
    } else {
      action$handler(proposal$arguments, ctx = ctx)
    },
    error = function(e) service_result(status = "error", errors = conditionMessage(e))
  )
  completed_at <- Sys.time()
  execution_status <- if (isTRUE(handler_result$metadata$timed_out %||% FALSE)) {
    "timed_out"
  } else if (isTRUE(handler_result$metadata$cancel_requested %||% FALSE)) {
    "cancelled"
  } else if (identical(handler_result$status, "success")) {
    "succeeded"
  } else {
    "failed"
  }
  execution <- list(
    execution_id = execution_id,
    proposal_id = proposal$proposal_id,
    action_id = proposal$action_id,
    status = execution_status,
    started_at = started_at,
    completed_at = completed_at,
    message = service_result_message(handler_result),
    outputs = handler_result$value %||% list(),
    warnings = handler_result$warnings %||% character(),
    errors = handler_result$errors %||% character(),
    state_changed = isTRUE(handler_result$metadata$state_changed %||% FALSE),
    ui_state_changed = isTRUE(handler_result$metadata$ui_state_changed %||% FALSE),
    project_state_changed = isTRUE(handler_result$metadata$project_state_changed %||% FALSE),
    persistent_changes = isTRUE(handler_result$metadata$persistent_changes %||% FALSE),
    artifact_id = handler_result$metadata$artifact_id %||% NA_character_,
    artifact_display_name = handler_result$metadata$artifact_display_name %||% NA_character_,
    artifact_type = handler_result$metadata$artifact_type %||% NA_character_,
    artifact_version = handler_result$metadata$artifact_version %||% NA_character_,
    report_id = handler_result$metadata$report_id %||% NA_character_,
    report_display_name = handler_result$metadata$report_display_name %||% NA_character_,
    report_type = handler_result$metadata$report_type %||% NA_character_,
    report_version = handler_result$metadata$report_version %||% NA_character_,
    report_status = handler_result$metadata$report_status %||% NA_character_,
    render_status = handler_result$metadata$render_status %||% NA_character_,
    module_id = handler_result$metadata$module_id %||% NA_character_,
    module_display_name = handler_result$metadata$module_display_name %||% NA_character_,
    module_version = handler_result$metadata$module_version %||% NA_character_,
    dataset_id = handler_result$metadata$dataset_id %||% NA_character_,
    dataset_display_name = handler_result$metadata$dataset_display_name %||% NA_character_,
    dataset_version = handler_result$metadata$dataset_version %||% NA_character_,
    schema_version = handler_result$metadata$schema_version %||% NA_character_,
    active_project_id = handler_result$metadata$active_project_id %||% NA_character_,
    execution_limit_profile = handler_result$metadata$execution_limit_profile %||% NA_character_,
    rows_considered = handler_result$metadata$rows_considered %||% NA_integer_,
    columns_considered = handler_result$metadata$columns_considered %||% NA_integer_,
    inspection_mode = handler_result$metadata$inspection_mode %||% NA_character_,
    readiness = handler_result$metadata$readiness %||% NA_character_,
    preflight_result_id = handler_result$metadata$preflight_result_id %||% NA_character_,
    preflight_fingerprint = handler_result$metadata$preflight_fingerprint %||% NA_character_,
    configuration_snapshot_id = handler_result$metadata$configuration_snapshot_id %||% NA_character_,
    configuration_fingerprint = handler_result$metadata$configuration_fingerprint %||% NA_character_,
    composite_execution_fingerprint = handler_result$metadata$composite_execution_fingerprint %||% NA_character_,
    job_id = handler_result$metadata$job_id %||% NA_character_,
    temporary_result_id = handler_result$metadata$temporary_result_id %||% NA_character_,
    source_temporary_result_id = handler_result$metadata$source_temporary_result_id %||% NA_character_,
    source_execution_id = handler_result$metadata$source_execution_id %||% NA_character_,
    temporary_result_fingerprint = handler_result$metadata$temporary_result_fingerprint %||% NA_character_,
    workspace_provider_id = handler_result$metadata$workspace_provider_id %||% NA_character_,
    workspace_provider_type = handler_result$metadata$workspace_provider_type %||% NA_character_,
    workspace_is_managed = isTRUE(handler_result$metadata$workspace_is_managed %||% FALSE),
    provider_capability_version = handler_result$metadata$provider_capability_version %||% NA_character_,
    provider_write_policy = handler_result$metadata$provider_write_policy %||% NA_character_,
    provider_validation_result = handler_result$metadata$provider_validation_result %||% NA_character_,
    project_provider_match = isTRUE(handler_result$metadata$project_provider_match %||% FALSE),
    project_root_identity = handler_result$metadata$project_root_identity %||% NA_character_,
    persistence_fingerprint = handler_result$metadata$persistence_fingerprint %||% NA_character_,
    persistence_schema_version = handler_result$metadata$persistence_schema_version %||% NA_character_,
    persisted_result_id = handler_result$metadata$persisted_result_id %||% NA_character_,
    result_type = handler_result$metadata$result_type %||% NA_character_,
    manifest_status = handler_result$metadata$manifest_status %||% NA_character_,
    hash_status = handler_result$metadata$hash_status %||% NA_character_,
    persisted_result_fingerprint = handler_result$metadata$persisted_result_fingerprint %||% NA_character_,
    safe_relative_location = handler_result$metadata$safe_relative_location %||% NA_character_,
    content_hashes = handler_result$metadata$content_hashes %||% NA_character_,
    bytes_written = handler_result$metadata$bytes_written %||% NA_real_,
    files_written = handler_result$metadata$files_written %||% NA_integer_,
    idempotency_key = handler_result$metadata$idempotency_key %||% NA_character_,
    already_committed = isTRUE(handler_result$metadata$already_committed %||% FALSE),
    execution_stages = handler_result$metadata$execution_stages %||% NA_character_,
    elapsed_time = handler_result$metadata$elapsed_time %||% NA_integer_,
    result_size = handler_result$metadata$result_size %||% NA_integer_,
    cancel_requested = isTRUE(handler_result$metadata$cancel_requested %||% FALSE),
    timed_out = isTRUE(handler_result$metadata$timed_out %||% FALSE),
    worker_isolated = isTRUE(handler_result$metadata$worker_isolated %||% FALSE),
    hard_cancellation_supported = isTRUE(handler_result$metadata$hard_cancellation_supported %||% FALSE),
    worker_terminated = isTRUE(handler_result$metadata$worker_terminated %||% FALSE),
    recovered = isTRUE(handler_result$metadata$recovered %||% FALSE),
    computation_performed = isTRUE(handler_result$metadata$computation_performed %||% FALSE),
    temporary_result_created = isTRUE(handler_result$metadata$temporary_result_created %||% FALSE),
    persisted_result_created = isTRUE(handler_result$metadata$persisted_result_created %||% FALSE),
    artifact_created = isTRUE(handler_result$metadata$artifact_created %||% FALSE),
    report_created = isTRUE(handler_result$metadata$report_created %||% FALSE),
    resource_fingerprint = handler_result$metadata$resource_fingerprint %||% validation$value$resource_fingerprint %||% NA_character_
  )
  if (!is.null(ctx) && is.function(ctx$mark_genai_action_proposal_executed)) {
    ctx$mark_genai_action_proposal_executed(proposal$proposal_id %||% "")
  }
  proposal$status <- execution$status
  if (exists("genai_record_durable_audit", mode = "function")) {
    terminal_event <- if (identical(execution$status, "succeeded")) {
      "execution_succeeded"
    } else if (identical(execution$status, "cancelled")) {
      "execution_cancelled"
    } else if (identical(execution$status, "timed_out")) {
      "execution_timed_out"
    } else {
      "execution_failed"
    }
    durable_audit_results[[terminal_event]] <- genai_record_durable_audit(terminal_event, proposal, execution, validation, ctx)
    if (identical(proposal$action_id %||% "", "result.persist") && identical(execution$status, "succeeded")) {
      persistence_event <- if (isTRUE(execution$already_committed)) "persistence_recovered" else "persistence_committed"
      durable_audit_results[[persistence_event]] <- genai_record_durable_audit(persistence_event, proposal, execution, validation, ctx)
    }
  }
  durable_audit_failed <- length(durable_audit_results) &&
    any(vapply(durable_audit_results, function(x) identical(x$status, "error"), logical(1)))
  if (isTRUE(durable_audit_failed)) {
    audit_errors <- paste(vapply(durable_audit_results, function(x) paste(x$errors %||% character(), collapse = " "), character(1)), collapse = " ")
    execution$warnings <- c(execution$warnings, paste("audit_write_failed:", audit_errors))
    execution$audit_write_failed <- TRUE
    if (identical(proposal$action_id %||% "", "result.persist") && identical(execution$status, "succeeded")) {
      execution$result_status_detail <- "persistence_committed_audit_write_failed"
    }
  }
  session_audit_event <- genai_action_audit_event(proposal, execution, validation)
  service_result(
    status = handler_result$status,
    value = execution,
    messages = execution$message,
    warnings = execution$warnings,
    errors = execution$errors,
    metadata = list(audit_event = session_audit_event, validation = validation, durable_audit = durable_audit_results)
  )
}

ui_genai_action_proposal_review <- function(proposal, validation = NULL, ns = identity) {
  if (is.null(proposal)) {
    return(NULL)
  }
  validation <- validation %||% genai_validate_action_proposal(proposal)
  action <- genai_action_registry_get(proposal$action_id %||% "")
  valid <- identical(validation$status, "success")
  resource <- validation$value$resource_resolution %||% validation$metadata$resource_resolution %||% list()
  module_id <- proposal$arguments$module_id %||% ""
  module <- if (identical(proposal$action_id %||% "", "module.open")) get_module_definition(module_id) else NULL
  target_label <- if (identical(proposal$action_id %||% "", "artifact.inspect")) {
    resource$display_name %||% proposal$arguments$artifact_id %||% "Unknown artifact"
  } else if (identical(proposal$action_id %||% "", "report.open")) {
    resource$display_name %||% proposal$arguments$report_id %||% "Unknown report"
  } else if (identical(proposal$action_id %||% "", "result.inspect")) {
    resource$display_name %||% proposal$arguments$persisted_result_id %||% "Unknown persisted result"
  } else if (identical(proposal$action_id %||% "", "analysis.preflight")) {
    paste(resource$display_name %||% proposal$arguments$module_id %||% "Unknown module", "->", resource$dataset_display_name %||% proposal$arguments$dataset_id %||% "Unknown dataset")
  } else if (identical(proposal$action_id %||% "", "analysis.run_registered")) {
    paste(resource$display_name %||% proposal$arguments$module_id %||% "Unknown module", "->", resource$dataset_display_name %||% proposal$arguments$dataset_id %||% "Unknown dataset")
  } else if (identical(proposal$action_id %||% "", "result.persist")) {
    paste(resource$module_display_name %||% "Dataset Profile", "temporary result", resource$temporary_result_id %||% proposal$arguments$temporary_result_id %||% "Unknown")
  } else {
    module$label %||% module_id %||% "Unknown"
  }
  target_kind <- if (identical(proposal$action_id %||% "", "artifact.inspect")) {
    "Target artifact"
  } else if (identical(proposal$action_id %||% "", "report.open")) {
    "Target report"
  } else if (identical(proposal$action_id %||% "", "result.inspect")) {
    "Target persisted result"
  } else if (identical(proposal$action_id %||% "", "analysis.preflight")) {
    "Preflight target"
  } else if (identical(proposal$action_id %||% "", "analysis.run_registered")) {
    "Execution target"
  } else if (identical(proposal$action_id %||% "", "result.persist")) {
    "Persistence target"
  } else {
    "Target module"
  }
  tags$section(
    class = "aq-genai-proposal-review",
    tags$header(
      class = "aq-genai-proposal-header",
      tags$p(class = "aq-section-eyebrow", "Action proposal"),
      tags$h4(action$display_name %||% proposal$action_id %||% "Unknown action"),
      ui_status_badge(if (valid) "Awaiting approval" else "Invalid", status = if (valid) "warning" else "error")
    ),
    tags$dl(
      class = "aq-metadata-grid",
      tags$dt(target_kind), tags$dd(target_label),
      if (identical(proposal$action_id %||% "", "artifact.inspect")) tagList(
        tags$dt("Artifact type"), tags$dd(resource$artifact_type %||% "Unknown"),
        tags$dt("Active project"), tags$dd(resource$active_project_id %||% "Unknown"),
        tags$dt("Artifact version"), tags$dd(resource$artifact_version %||% "Unknown"),
        tags$dt("Artifact status"), tags$dd(resource$artifact_status %||% "Unknown"),
        tags$dt("Resource fingerprint"), tags$dd(resource$resource_fingerprint %||% "Unavailable")
      ),
      if (identical(proposal$action_id %||% "", "report.open")) tagList(
        tags$dt("Report type"), tags$dd(resource$report_type %||% "Unknown"),
        tags$dt("Active project"), tags$dd(resource$active_project_id %||% "Unknown"),
        tags$dt("Report version"), tags$dd(resource$report_version %||% "Unknown"),
        tags$dt("Report status"), tags$dd(resource$report_status %||% "Unknown"),
        tags$dt("Render status"), tags$dd(resource$render_status %||% "Unknown"),
        tags$dt("Resource origin"), tags$dd(resource$resource_origin %||% "Unknown"),
        tags$dt("Resource fingerprint"), tags$dd(resource$resource_fingerprint %||% "Unavailable")
      ),
      if (identical(proposal$action_id %||% "", "result.inspect")) tagList(
        tags$dt("Persisted result ID"), tags$dd(resource$persisted_result_id %||% "Unknown"),
        tags$dt("Result type"), tags$dd(resource$result_type %||% "Unknown"),
        tags$dt("Module"), tags$dd(resource$module_id %||% "Unknown"),
        tags$dt("Module version"), tags$dd(resource$module_version %||% "Unknown"),
        tags$dt("Dataset"), tags$dd(resource$dataset_id %||% "Unknown"),
        tags$dt("Dataset version"), tags$dd(resource$dataset_version %||% "Unknown"),
        tags$dt("Persisted"), tags$dd(format(as.POSIXct(resource$persisted_at), "%Y-%m-%d %H:%M:%S")),
        tags$dt("Active project"), tags$dd(resource$active_project_name %||% resource$active_project_id %||% "Unknown"),
        tags$dt("Storage provider"), tags$dd(paste(resource$workspace_provider_id %||% "unknown", paste0("(", resource$workspace_provider_type %||% "unknown", ")"))),
        tags$dt("Manifest status"), tags$dd(resource$manifest_status %||% "Unknown"),
        tags$dt("Content hashes"), tags$dd(resource$hash_status %||% "Unknown"),
        tags$dt("Location"), tags$dd(resource$safe_relative_location %||% "results/<id>"),
        tags$dt("Project mutation"), tags$dd("No"),
        tags$dt("Persistence behavior"), tags$dd("None. This opens an existing trusted result for inspection only."),
        tags$dt("Resource fingerprint"), tags$dd(resource$resource_fingerprint %||% "Unavailable")
      ),
      if (identical(proposal$action_id %||% "", "analysis.preflight")) tagList(
        tags$dt("Module"), tags$dd(resource$display_name %||% "Unknown"),
        tags$dt("Module category"), tags$dd(resource$module_category %||% "Unknown"),
        tags$dt("Module version"), tags$dd(resource$module_version %||% "Unknown"),
        tags$dt("Dataset"), tags$dd(resource$dataset_display_name %||% "Unknown"),
        tags$dt("Rows"), tags$dd(format(resource$row_count %||% 0L, big.mark = ",")),
        tags$dt("Columns"), tags$dd(format(resource$column_count %||% 0L, big.mark = ",")),
        tags$dt("Dataset version"), tags$dd(resource$dataset_version %||% "Unknown"),
        tags$dt("Schema version"), tags$dd(resource$schema_version %||% "Unknown"),
        tags$dt("Active project"), tags$dd(resource$active_project_id %||% "Unknown"),
        tags$dt("Expected checks"), tags$dd("Schema, row/column counts, missingness, constants, cardinality, role declaration, and workload class."),
        tags$dt("Limit profile"), tags$dd("Bounded app-defined scan; model cannot override row, column, timeout, or sample limits."),
        tags$dt("Temporary result"), tags$dd("Session-local only; no artifact or report is saved."),
        tags$dt("Resource fingerprint"), tags$dd(resource$resource_fingerprint %||% "Unavailable")
      ),
      if (identical(proposal$action_id %||% "", "analysis.run_registered")) tagList(
        tags$dt("Module"), tags$dd(resource$display_name %||% "Unknown"),
        tags$dt("Module version"), tags$dd(resource$module_version %||% "Unknown"),
        tags$dt("Dataset"), tags$dd(resource$dataset_display_name %||% "Unknown"),
        tags$dt("Rows"), tags$dd(format(resource$row_count %||% 0L, big.mark = ",")),
        tags$dt("Columns"), tags$dd(format(resource$column_count %||% 0L, big.mark = ",")),
        tags$dt("Active project"), tags$dd(resource$active_project_id %||% "Unknown"),
        tags$dt("Dataset version"), tags$dd(resource$dataset_version %||% "Unknown"),
        tags$dt("Schema version"), tags$dd(resource$schema_version %||% "Unknown"),
        tags$dt("Configuration snapshot"), tags$dd(resource$configuration_snapshot_id %||% "Unavailable"),
        tags$dt("Mode"), tags$dd(resource$mode_id %||% "default"),
        tags$dt("Result type"), tags$dd(resource$result_type %||% "dataset_profile"),
        tags$dt("Configuration schema"), tags$dd(resource$configuration_schema_version %||% "Unavailable"),
        tags$dt("Configuration fingerprint"), tags$dd(resource$configuration_fingerprint %||% "Unavailable"),
        tags$dt("Preflight readiness"), tags$dd(resource$preflight_readiness %||% "Unavailable"),
        tags$dt("Preflight result"), tags$dd(resource$preflight_result_id %||% "Unavailable"),
        tags$dt("Expected stages"), tags$dd("Mode-specific bounded stages: validation, diagnostics, bounded tables, and normalized plot specs where supported."),
        tags$dt("Resource limits"), tags$dd("App-owned bounded profile; model cannot override rows, columns, timeout, table limits, or output size."),
        tags$dt("Cancellation"), tags$dd("Cooperative between bounded execution stages."),
        tags$dt("Temporary output"), tags$dd("Session-local result only; not saved as an artifact, report, collector entry, or project change."),
        tags$dt("Execution fingerprint"), tags$dd(resource$resource_fingerprint %||% "Unavailable")
      ),
      if (identical(proposal$action_id %||% "", "result.persist")) tagList(
        tags$dt("Temporary result"), tags$dd(resource$temporary_result_id %||% "Unknown"),
        tags$dt("Result type"), tags$dd(resource$temporary_result_type %||% "Unknown"),
        tags$dt("Source action"), tags$dd(resource$source_action_id %||% "Unknown"),
        tags$dt("Module"), tags$dd(resource$module_display_name %||% resource$module_id %||% "Unknown"),
        tags$dt("Module version"), tags$dd(resource$module_version %||% "Unknown"),
        tags$dt("Dataset"), tags$dd(resource$dataset_display_name %||% resource$dataset_id %||% "Unknown"),
        tags$dt("Created"), tags$dd(format(as.POSIXct(resource$created_at), "%Y-%m-%d %H:%M:%S")),
        tags$dt("Expires"), tags$dd(format(as.POSIXct(resource$expires_at), "%Y-%m-%d %H:%M:%S")),
        tags$dt("Active project"), tags$dd(resource$project_name %||% resource$active_project_id %||% "Unknown"),
        tags$dt("Storage provider"), tags$dd(paste(resource$provider_display_name %||% "Storage Provider", paste0("(", resource$workspace_provider_type %||% "unknown", ")"))),
        tags$dt("Managed provider"), tags$dd(if (isTRUE(resource$workspace_is_managed)) "Yes" else "No"),
        tags$dt("Destination"), tags$dd(resource$safe_relative_location %||% "results/<server-generated-result-id>/"),
        tags$dt("Will persist"), tags$dd("summary, metrics where applicable, diagnostics, warnings, bounded tables, bounded plot specifications where applicable, resource usage, manifest provenance, and content hashes"),
        tags$dt("Will exclude"), tags$dd("raw dataset rows, source data object, paths supplied by GenAI, code, functions, callbacks, prompts, and credentials"),
        tags$dt("No overwrite policy"), tags$dd("A new server-generated result id will be created. Existing results are never overwritten."),
        tags$dt("Persistence fingerprint"), tags$dd(resource$persistence_fingerprint %||% "Unavailable")
      ),
      tags$dt("Rationale"), tags$dd(proposal$rationale %||% "No rationale supplied."),
      tags$dt("Expected effect"), tags$dd(paste(proposal$expected_effects %||% "Open selected module", collapse = "; ")),
      tags$dt("Evidence"), tags$dd(paste(proposal$evidence_refs %||% "Not supplied", collapse = "; ")),
      tags$dt("Risk"), tags$dd(proposal$risk_tier %||% "unknown"),
      tags$dt("Persistence"), tags$dd(if (isTRUE(proposal$persistence_requested)) "Requested" else "Not requested"),
      tags$dt("UI state change"), tags$dd("Yes, after approval"),
      if (!identical(proposal$action_id %||% "", "result.persist")) tagList(
        tags$dt("Project mutation"), tags$dd("No")
      ),
      if (identical(proposal$action_id %||% "", "result.persist")) tagList(
        tags$dt("Project mutation"), tags$dd("Yes, create one persisted project result"),
        tags$dt("Persistent warning"), tags$dd("This will create a permanent result in the active project. The analysis will not be rerun.")
      ),
      tags$dt("Persistent changes"), tags$dd(if (isTRUE(proposal$persistence_requested)) "Requested" else "None"),
      tags$dt("State mutations"), tags$dd(if (length(proposal$state_mutations %||% list())) "Requested" else "None"),
      tags$dt("Expires"), tags$dd(format(as.POSIXct(proposal$expires_at), "%Y-%m-%d %H:%M:%S"))
    ),
    if (length(validation$errors %||% character())) {
      ui_callout("Validation errors", paste(validation$errors, collapse = " "), status = "error")
    },
    if (length(validation$warnings %||% character())) {
      ui_callout("Policy note", paste(validation$warnings, collapse = " "), status = "warning")
    },
    if (identical(proposal$action_id %||% "", "analysis.preflight")) {
      ui_callout(
        "Bounded read-only computation",
        "This will inspect the selected dataset using bounded, read-only checks. It will not run the full analysis or save an artifact.",
        status = "info"
      )
    },
    if (identical(proposal$action_id %||% "", "analysis.run_registered")) {
      ui_callout(
        "Temporary registered analysis",
        "This will run the selected registered analysis using the current trusted configuration. The result will be temporary and session-local. It will not be saved as an artifact, report, or project change.",
        status = "warning"
      )
    },
    if (identical(proposal$action_id %||% "", "result.persist")) {
      ui_callout(
        "Permanent project result",
        "This will create a permanent result in the active project. The analysis will not be rerun. The existing temporary result will be validated and written into trusted project storage. No existing result will be overwritten.",
        status = "warning"
      )
    },
    if (identical(proposal$action_id %||% "", "result.inspect")) {
      ui_callout(
        "Read-only persisted result inspection",
        "This will open an existing persisted result for inspection. The result will not be modified, regenerated, exported, deleted, or repaired.",
        status = "info"
      )
    },
    tags$div(
      class = "aq-genai-proposal-actions",
      actionButton(ns("approve_proposal"), "Approve", class = "btn-primary btn-sm", disabled = if (!valid) "disabled" else NULL),
      actionButton(ns("reject_proposal"), "Reject", class = "btn-secondary btn-sm"),
      actionButton(ns("cancel_proposal"), "Cancel", class = "btn-secondary btn-sm")
    )
  )
}

qa_genai_registered_analysis_action <- function() {
  qa_data <- data.frame(
    id = seq_len(120),
    value = c(seq_len(110), rep(NA, 10)),
    group = rep(c("A", "B", "C"), length.out = 120),
    constant = "x",
    stringsAsFactors = FALSE
  )
  qa_data_v2 <- qa_data
  qa_data_v2$new_col <- seq_len(nrow(qa_data_v2))
  make_ctx <- function(data = qa_data, project_id = "qa_project", cancel = FALSE, limits = genai_registered_analysis_limits()) {
    env <- new.env(parent = emptyenv())
    env$project_data <- function() data
    env$uploaded_data <- function() data
    env$project_data_info <- function() list(name = "QA Dataset", path = NULL)
    env$current_dataset_id <- function() "active_dataset"
    env$project_collector_project_id <- function() project_id
    env$genai_preflight_limits <- function() genai_preflight_limits()
    env$genai_registered_analysis_limits <- function() limits
    env$genai_preflight_state <- list(results = list())
    env$genai_analysis_state <- list(jobs = list(), results = list())
    env$executed_proposal_ids <- character()
    env$store_genai_preflight_result <- function(result) {
      env$genai_preflight_state$results[[result$preflight_result_id]] <- result
      result$preflight_result_id
    }
    env$store_genai_analysis_job <- function(job) {
      env$genai_analysis_state$jobs[[job$job_id]] <- job
      job$job_id
    }
    env$update_genai_analysis_job <- function(job_id, fields = list()) {
      job <- env$genai_analysis_state$jobs[[job_id]] %||% list(job_id = job_id)
      for (field in names(fields)) job[[field]] <- fields[[field]]
      env$genai_analysis_state$jobs[[job_id]] <- job
      job
    }
    env$store_genai_analysis_result <- function(result) {
      env$genai_analysis_state$results[[result$temporary_result_id]] <- result
      result$temporary_result_id
    }
    env$reset_genai_analysis_cancel <- function() TRUE
    env$genai_analysis_cancel_requested <- function() isTRUE(cancel)
    env$genai_action_proposal_executed <- function(proposal_id) proposal_id %in% env$executed_proposal_ids
    env$mark_genai_action_proposal_executed <- function(proposal_id) {
      env$executed_proposal_ids <- unique(c(env$executed_proposal_ids, proposal_id))
      TRUE
    }
    env
  }
  make_run <- function(module_id = "dataset_profile", dataset_id = "active_dataset") {
    genai_action_proposal(
      action_id = "analysis.run_registered",
      action_version = "1.0",
      arguments = list(module_id = module_id, dataset_id = dataset_id),
      rationale = "Run the allowlisted temporary dataset profile after bounded validation.",
      evidence_refs = c("dataset:active_dataset"),
      expected_effects = c("Create a temporary session-local result", "Do not save artifacts or reports"),
      risk_tier = "medium",
      confidence = 0.91
    )
  }
  ctx <- make_ctx()
  ctx_v2 <- make_ctx(qa_data_v2)
  cancel_ctx <- make_ctx(cancel = TRUE)
  timeout_ctx <- make_ctx(limits = genai_registered_analysis_limits(max_elapsed_ms = -1L))
  valid <- make_run()
  validation <- genai_validate_action_proposal(valid, ctx = ctx)
  approval <- genai_approve_action_proposal(valid, validation, "user")
  execution <- genai_execute_action_proposal(approval$value, ctx = ctx, approval_hash = approval$value$approval_hash)
  replay <- genai_execute_action_proposal(approval$value, ctx = ctx, approval_hash = approval$value$approval_hash)
  stale <- genai_execute_action_proposal(approval$value, ctx = ctx_v2, approval_hash = approval$value$approval_hash)
  cancelled <- genai_execute_action_proposal(genai_approve_action_proposal(make_run(), genai_validate_action_proposal(make_run(), ctx = cancel_ctx), "user")$value, ctx = cancel_ctx)
  timed_out <- genai_execute_action_proposal(genai_approve_action_proposal(make_run(), genai_validate_action_proposal(make_run(), ctx = timeout_ctx), "user")$value, ctx = timeout_ctx)
  invalid_extra <- valid
  invalid_extra$arguments$target <- "value"
  invalid_extra$proposal_hash <- genai_action_compute_hash(invalid_extra)
  invalid_path <- valid
  invalid_path$arguments$output_path <- "C:/tmp/out.csv"
  invalid_path$proposal_hash <- genai_action_compute_hash(invalid_path)
  non_enabled <- make_run("autoquant_eda")
  invented_dataset <- make_run("dataset_profile", "invented_dataset")
  parsed <- genai_extract_action_proposal(paste0("```json\n", .genai_action_json(list(action_proposal = list(
    action_id = "analysis.run_registered",
    action_version = "1.0",
    proposal_version = "1.0",
    arguments = list(module_id = "dataset_profile", dataset_id = "active_dataset"),
    rationale = "Run the temporary dataset profile.",
    evidence_refs = list("dataset:active_dataset"),
    expected_effects = list("Create a temporary result"),
    state_mutations = list(),
    persistence_requested = FALSE,
    risk_tier = "medium",
    confidence = 0.9
  ))), "\n```"))

  data.table::data.table(
    check = c(
      "run_registered_action_registered", "run_registered_risk_medium", "run_registered_handler_hidden",
      "run_registered_executable_allowlist", "run_registered_valid_args", "run_registered_extra_arg_rejected",
      "run_registered_path_rejected", "run_registered_non_enabled_module_rejected", "run_registered_invented_dataset_rejected",
      "run_registered_configuration_snapshot", "run_registered_configuration_fingerprint",
      "run_registered_preflight_bound", "run_registered_execution_fingerprint_bound",
      "run_registered_approved_executes", "run_registered_temporary_result_created",
      "run_registered_no_artifact_created", "run_registered_no_report_created",
      "run_registered_no_project_mutation", "run_registered_no_persistent_changes",
      "run_registered_no_raw_rows", "run_registered_output_tables_bounded",
      "run_registered_job_recorded", "run_registered_audit_fields",
      "run_registered_stale_schema_blocks", "run_registered_replay_blocks", "run_registered_cancelled_no_result",
      "run_registered_timeout_no_result", "run_registered_parse_valid_json",
      "run_registered_safe_summary_exposed"
    ),
    status = c(
      if (inherits(genai_action_registry_get("analysis.run_registered"), "aq_genai_action_definition")) "success" else "error",
      if (identical(genai_action_registry_get("analysis.run_registered")$risk_tier, "medium")) "success" else "error",
      if (!"handler" %in% names(genai_action_registry_list()[["analysis.run_registered"]])) "success" else "error",
      if (identical(sort(genai_executable_module_metadata()$module_id), sort(c("dataset_profile", "model_assessment")))) "success" else "error",
      if (identical(validation$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(invalid_extra, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(invalid_path, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(non_enabled, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(invented_dataset, ctx = ctx)$status, "error")) "success" else "error",
      if (nzchar(validation$value$resource_resolution$configuration_snapshot_id %||% "")) "success" else "error",
      if (nzchar(validation$value$resource_resolution$configuration_fingerprint %||% "")) "success" else "error",
      if (nzchar(validation$value$resource_resolution$preflight_result_id %||% "") && validation$value$resource_resolution$preflight_readiness %in% c("ready", "ready_with_warnings")) "success" else "error",
      if (identical(approval$value$approval_resource_fingerprint, validation$value$resource_fingerprint)) "success" else "error",
      if (identical(execution$status, "success") && identical(execution$value$status, "succeeded")) "success" else "error",
      if (isTRUE(execution$value$temporary_result_created) && length(ctx$genai_analysis_state$results) == 1L) "success" else "error",
      if (isFALSE(execution$value$artifact_created)) "success" else "error",
      if (isFALSE(execution$value$report_created)) "success" else "error",
      if (isFALSE(execution$value$project_state_changed)) "success" else "error",
      if (isFALSE(execution$value$persistent_changes)) "success" else "error",
      if (!"rows" %in% names(execution$value$outputs) && !"raw_data" %in% names(execution$value$outputs)) "success" else "error",
      if (all(vapply(ctx$genai_analysis_state$results[[1]]$tables, nrow, integer(1)) <= genai_registered_analysis_limits()$max_table_rows)) "success" else "error",
      if (length(ctx$genai_analysis_state$jobs) == 1L && identical(ctx$genai_analysis_state$jobs[[1]]$status, "succeeded")) "success" else "error",
      if (data.table::is.data.table(execution$metadata$audit_event) && all(c("configuration_snapshot_id", "preflight_fingerprint", "job_id", "temporary_result_id", "artifact_created", "report_created") %in% names(execution$metadata$audit_event))) "success" else "error",
      if (identical(stale$status, "error")) "success" else "error",
      if (identical(replay$status, "error")) "success" else "error",
      if (identical(cancelled$value$status, "cancelled") && isFALSE(cancelled$value$temporary_result_created)) "success" else "error",
      if (identical(timed_out$value$status, "timed_out") && isFALSE(timed_out$value$temporary_result_created)) "success" else "error",
      if (identical(parsed$status, "success") && identical(genai_validate_action_proposal(parsed$value, ctx = ctx)$status, "success")) "success" else "error",
      if (all(c("summary", "table_names", "resource_usage", "recommended_human_next_step") %in% names(execution$value$outputs))) "success" else "error"
    ),
    message = c(
      "analysis.run_registered is registered.", "analysis.run_registered is medium risk.", "Action metadata hides executable handlers.",
      "Exactly the expected GenAI executable modules are enabled.", "Valid module and active dataset validate.", "Model-supplied target/configuration is rejected.",
      "Model-supplied paths are rejected.", "Non-allowlisted modules are rejected.", "Invented dataset ids are rejected.",
      "Trusted configuration snapshot is created.", "Configuration fingerprint is created.",
      "A current acceptable preflight is bound.", "Approval binds to the composite execution fingerprint.",
      "Approved proposal executes.", "Temporary session-local result is created.",
      "No artifact is created.", "No report is created.",
      "No project mutation is reported.", "No persistent changes are reported.",
      "Execution output does not expose raw rows.", "Output tables are bounded.",
      "Managed session-local job is recorded.", "Audit event includes registered-run fields.",
      "Schema/resource changes invalidate approval.", "Completed proposal replay is blocked.", "Cancellation creates no successful result.",
      "Timeout creates no successful result.", "Valid proposal JSON parses.",
      "Only a safe result summary is exposed to GenAI."
    )
  )
}

qa_genai_second_registered_analysis_module <- function(output_dir = file.path(tempdir(), "genai_second_module_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  qa_data <- data.frame(
    id = seq_len(60),
    actual = seq(10, 69),
    predicted = seq(11, 70),
    segment = rep(c("A", "B"), length.out = 60),
    stringsAsFactors = FALSE
  )
  qa_data$actual[60] <- NA_real_
  qa_data$predicted[59] <- NA_real_
  make_ctx <- function(data = qa_data, config = list(assessment_problem_type = "Regression", actual_var = "actual", prediction_var = "predicted"), project_id = "qa_second_module_project") {
    provider <- storage_provider("configured_workspace", "configured_workspace", "Configured Workspace", file.path(output_dir, paste0("workspace_", project_id)), available = TRUE, capabilities = list(supports_external_projects = TRUE, can_choose_directory = FALSE))
    workspace <- validate_workspace_root(provider$root_path, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
    project <- create_project_in_workspace(workspace, "Second Module QA", project_id = project_id)$value
    env <- new.env(parent = emptyenv())
    env$uploaded_data <- function() data
    env$project_data <- function() data
    env$project_data_info <- function() list(name = "Scored QA Dataset", path = NULL)
    env$current_dataset_id <- function() "active_dataset"
    env$project_collector_project_id <- function() project$project_id
    env$current_workspace <- function() workspace
    env$current_project <- function() project
    env$genai_preflight_limits <- function() genai_preflight_limits()
    env$genai_preflight_state <- list(results = list())
    env$genai_analysis_run_state <- list(jobs = list(), results = list())
    env$genai_persistence_locks <- list()
    env$executed_proposal_ids <- character()
    env$selected_persisted_result_id <- NULL
    env$genai_registered_analysis_config <- function(module_id) {
      if (identical(normalize_module_id(module_id), "model_assessment")) config else genai_registered_analysis_default_config(module_id)
    }
    env$store_genai_preflight_result <- function(result) {
      env$genai_preflight_state$results[[result$preflight_result_id]] <- result
      result$preflight_result_id
    }
    env$store_genai_analysis_job <- function(job) {
      env$genai_analysis_run_state$jobs[[job$job_id]] <- job
      job$job_id
    }
    env$update_genai_analysis_job <- function(job_id, fields = list()) {
      job <- env$genai_analysis_run_state$jobs[[job_id]] %||% list(job_id = job_id)
      for (field in names(fields)) job[[field]] <- fields[[field]]
      env$genai_analysis_run_state$jobs[[job_id]] <- job
      job
    }
    env$store_genai_analysis_result <- function(result) {
      env$genai_analysis_run_state$results[[result$temporary_result_id]] <- result
      result$temporary_result_id
    }
    env$mark_genai_analysis_result_persisted <- function(temporary_result_id, persisted_result_id, persisted_project_id) {
      result <- env$genai_analysis_run_state$results[[temporary_result_id]]
      if (is.null(result)) return(FALSE)
      result$persisted <- TRUE
      result$persisted_result_id <- persisted_result_id
      result$persisted_project_id <- persisted_project_id
      env$genai_analysis_run_state$results[[temporary_result_id]] <- result
      TRUE
    }
    env$reset_genai_analysis_cancel <- function() TRUE
    env$genai_analysis_cancel_requested <- function() FALSE
    env$genai_action_proposal_executed <- function(proposal_id) proposal_id %in% env$executed_proposal_ids
    env$mark_genai_action_proposal_executed <- function(proposal_id) {
      env$executed_proposal_ids <- unique(c(env$executed_proposal_ids, proposal_id))
      TRUE
    }
    env$inspect_persisted_result <- function(persisted_result_id) {
      resolution <- genai_resolve_persisted_result(persisted_result_id, ctx = env)
      if (!identical(resolution$status, "success")) return(resolution)
      env$selected_persisted_result_id <- persisted_result_id
      service_result(status = "success", value = resolution$value)
    }
    env
  }
  make_proposal <- function(action_id, args, risk = "medium", persist = FALSE, mutation = list()) genai_action_proposal(
    action_id = action_id,
    action_version = "1.0",
    arguments = args,
    rationale = paste("QA proposal for", action_id),
    evidence_refs = "qa:evidence",
    expected_effects = "QA bounded effect",
    state_mutations = mutation,
    persistence_requested = persist,
    risk_tier = risk,
    confidence = 0.93
  )
  ctx <- make_ctx()
  incomplete_ctx <- make_ctx(config = list(assessment_problem_type = "Regression", actual_var = "", prediction_var = "predicted"), project_id = "qa_second_module_incomplete")
  wrong_type_ctx <- make_ctx(data = transform(qa_data, actual = as.character(actual)), project_id = "qa_second_module_wrong_type")
  preflight <- make_proposal("analysis.preflight", list(module_id = "model_assessment", dataset_id = "active_dataset"))
  preflight_validation <- genai_validate_action_proposal(preflight, ctx = ctx)
  preflight_exec <- genai_execute_action_proposal(genai_approve_action_proposal(preflight, preflight_validation, "user")$value, ctx = ctx)
  run <- make_proposal("analysis.run_registered", list(module_id = "model_assessment", dataset_id = "active_dataset"))
  run_validation <- genai_validate_action_proposal(run, ctx = ctx)
  run_exec <- genai_execute_action_proposal(genai_approve_action_proposal(run, run_validation, "user")$value, ctx = ctx)
  tmp_id <- run_exec$value$temporary_result_id
  tmp <- ctx$genai_analysis_run_state$results[[tmp_id]]
  persist <- make_proposal("result.persist", list(temporary_result_id = tmp_id), risk = "high", persist = TRUE, mutation = "Create one persisted project result")
  persist_validation <- genai_validate_action_proposal(persist, ctx = ctx)
  persist_exec <- genai_execute_action_proposal(genai_approve_action_proposal(persist, persist_validation, "user")$value, ctx = ctx)
  persisted_id <- persist_exec$value$persisted_result_id
  listed <- list_project_persisted_results(ctx$current_project())
  bundle <- read_persisted_result_bundle(ctx$current_project(), persisted_id)
  inspect <- make_proposal("result.inspect", list(persisted_result_id = persisted_id), risk = "low")
  inspect_validation <- genai_validate_action_proposal(inspect, ctx = ctx)
  inspect_exec <- genai_execute_action_proposal(genai_approve_action_proposal(inspect, inspect_validation, "user")$value, ctx = ctx)
  reconcile <- genai_reconcile_persisted_results_audit(ctx$current_project())
  extra_arg <- make_proposal("analysis.run_registered", list(module_id = "model_assessment", dataset_id = "active_dataset", target_column = "actual"))
  incomplete_validation <- genai_validate_action_proposal(run, ctx = incomplete_ctx)
  wrong_type_validation <- genai_validate_action_proposal(preflight, ctx = wrong_type_ctx)
  wrong_type_exec <- if (identical(wrong_type_validation$status, "success")) {
    genai_execute_action_proposal(genai_approve_action_proposal(preflight, wrong_type_validation, "user")$value, ctx = wrong_type_ctx)
  } else {
    service_result(status = "error", errors = wrong_type_validation$errors %||% "validation_failed")
  }
  metadata <- genai_executable_module_metadata()
  data.table::data.table(
    check = c(
      "second_module_registered", "only_two_modules_enabled", "model_supplied_config_rejected",
      "missing_config_blocks", "wrong_type_blocks", "preflight_ready", "preflight_has_model_checks",
      "run_validation_success", "temporary_result_type", "metrics_present", "tables_bounded",
      "plot_specs_bounded", "no_artifacts_or_reports", "safe_summary_has_metrics",
      "persistence_validates", "persistence_succeeds", "bundle_discovered",
      "bundle_contains_metrics", "bundle_contains_plot_specs", "result_inspect_validates",
      "result_inspect_succeeds", "audit_reconciliation_runs"
    ),
    status = c(
      if ("model_assessment" %in% metadata$module_id) "success" else "error",
      if (identical(sort(metadata$module_id), sort(c("dataset_profile", "model_assessment")))) "success" else "error",
      if (identical(genai_validate_action_proposal(extra_arg, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(incomplete_validation$status, "error")) "success" else "error",
      if (identical(wrong_type_validation$status, "error") ||
          isTRUE((wrong_type_exec$value$outputs$readiness %||% "") %in% c("blocked", "failed"))) "success" else "error",
      if (identical(preflight_validation$status, "success") && isTRUE((preflight_exec$value$outputs$readiness %||% "") %in% c("ready", "ready_with_warnings"))) "success" else "error",
      if (any(vapply(preflight_exec$value$outputs$checks %||% list(), function(x) identical(x$check_id, "complete_pairs"), logical(1)))) "success" else "error",
      if (identical(run_validation$status, "success")) "success" else "error",
      if (identical(tmp$temporary_result_type, genai_model_assessment_result_type())) "success" else "error",
      if (length(tmp$metrics %||% list()) >= 5L && is.numeric(tmp$metrics$rmse)) "success" else "error",
      if (all(vapply(tmp$tables, nrow, integer(1)) <= genai_registered_analysis_limits()$max_table_rows)) "success" else "error",
      if (length(tmp$plots %||% list()) <= 2L && all(vapply(tmp$plots, function(p) is.list(p) && !is.null(p$bounded_data), logical(1)))) "success" else "error",
      if (isFALSE(run_exec$value$artifact_created) && isFALSE(run_exec$value$report_created)) "success" else "error",
      if ("metrics" %in% names(run_exec$value$outputs) && "plot_descriptions" %in% names(run_exec$value$outputs)) "success" else "error",
      if (identical(persist_validation$status, "success")) "success" else "error",
      if (identical(persist_exec$status, "success") && isTRUE(persist_exec$value$persisted_result_created)) "success" else "error",
      if (nrow(listed) && persisted_id %in% listed$persisted_result_id && genai_model_assessment_result_type() %in% listed$result_type) "success" else "error",
      if (identical(bundle$status, "success") && length(bundle$value$metrics %||% list())) "success" else "error",
      if (identical(bundle$status, "success") && length(bundle$value$plots %||% list())) "success" else "error",
      if (identical(inspect_validation$status, "success")) "success" else "error",
      if (identical(inspect_exec$status, "success") && identical(ctx$selected_persisted_result_id, persisted_id)) "success" else "error",
      if (identical(reconcile$status, "success")) "success" else "error"
    ),
    message = c(
      "model_assessment is registered as the second GenAI executable module.",
      "Only dataset_profile and model_assessment are executable through GenAI.",
      "GenAI-supplied target/prediction arguments are rejected.",
      "Missing trusted target configuration blocks validation.",
      "Non-numeric trusted target blocks model assessment preflight.",
      "Trusted regression assessment preflight reaches an acceptable state.",
      "Module-specific preflight checks are present.",
      "analysis.run_registered validates for model_assessment.",
      "Temporary result type is model_assessment_regression.",
      "Core regression metrics are present.",
      "Tables obey row bounds.",
      "Plot specs are normalized and bounded.",
      "Temporary execution creates no artifacts or reports.",
      "Safe GenAI summary includes metrics and plot descriptions.",
      "result.persist validates for the new type.",
      "Persistence succeeds through the existing staged commit path.",
      "Persisted Results discovery lists the new type.",
      "Persisted bundle includes metrics sidecar.",
      "Persisted bundle includes plot spec sidecars.",
      "result.inspect validates for the new type.",
      "result.inspect opens the persisted result read-only.",
      "Audit reconciliation handles the persisted result."
    )
  )
}

qa_genai_binary_model_assessment <- function(output_dir = file.path(tempdir(), "genai_binary_model_assessment_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(11011)
  n <- 80L
  score <- seq(0.05, 0.95, length.out = n)
  actual <- ifelse(score + stats::rnorm(n, 0, 0.08) >= 0.5, "Yes", "No")
  qa_data <- data.frame(
    id = seq_len(n),
    actual = actual,
    probability = pmin(pmax(score, 0.001), 0.999),
    weight = rep(1, n),
    stringsAsFactors = FALSE
  )
  make_ctx <- function(data = qa_data, config = list(
    assessment_problem_type = "Binary Classification",
    actual_var = "actual",
    prediction_var = "probability",
    positive_class = "Yes",
    threshold = 0.5,
    prediction_scale = "probability"
  ), project_id = paste0("qa_binary_model_assessment_", sample.int(999999, 1L))) {
    provider <- storage_provider("configured_workspace", "configured_workspace", "Configured Workspace", file.path(output_dir, paste0("workspace_", project_id)), available = TRUE, capabilities = list(supports_external_projects = TRUE, can_choose_directory = FALSE))
    workspace <- validate_workspace_root(provider$root_path, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
    project <- create_project_in_workspace(workspace, "Binary Model Assessment QA", project_id = project_id)$value
    env <- new.env(parent = emptyenv())
    env$uploaded_data <- function() data
    env$project_data <- function() data
    env$project_data_info <- function() list(name = "Binary Scored QA Dataset", path = NULL)
    env$current_dataset_id <- function() "active_dataset"
    env$project_collector_project_id <- function() project$project_id
    env$current_workspace <- function() workspace
    env$current_project <- function() project
    env$genai_preflight_limits <- function() genai_preflight_limits()
    env$genai_preflight_state <- list(results = list())
    env$genai_analysis_run_state <- list(jobs = list(), results = list())
    env$genai_persistence_locks <- list()
    env$executed_proposal_ids <- character()
    env$selected_persisted_result_id <- NULL
    env$genai_registered_analysis_config <- function(module_id) {
      if (identical(normalize_module_id(module_id), "model_assessment")) config else genai_registered_analysis_default_config(module_id)
    }
    env$store_genai_preflight_result <- function(result) {
      env$genai_preflight_state$results[[result$preflight_result_id]] <- result
      result$preflight_result_id
    }
    env$store_genai_analysis_job <- function(job) {
      env$genai_analysis_run_state$jobs[[job$job_id]] <- job
      job$job_id
    }
    env$update_genai_analysis_job <- function(job_id, fields = list()) {
      job <- env$genai_analysis_run_state$jobs[[job_id]] %||% list(job_id = job_id)
      for (field in names(fields)) job[[field]] <- fields[[field]]
      env$genai_analysis_run_state$jobs[[job_id]] <- job
      job
    }
    env$store_genai_analysis_result <- function(result) {
      env$genai_analysis_run_state$results[[result$temporary_result_id]] <- result
      result$temporary_result_id
    }
    env$mark_genai_analysis_result_persisted <- function(temporary_result_id, persisted_result_id, persisted_project_id) {
      result <- env$genai_analysis_run_state$results[[temporary_result_id]]
      if (is.null(result)) return(FALSE)
      result$persisted <- TRUE
      result$persisted_result_id <- persisted_result_id
      result$persisted_project_id <- persisted_project_id
      env$genai_analysis_run_state$results[[temporary_result_id]] <- result
      TRUE
    }
    env$reset_genai_analysis_cancel <- function() TRUE
    env$genai_analysis_cancel_requested <- function() FALSE
    env$genai_action_proposal_executed <- function(proposal_id) proposal_id %in% env$executed_proposal_ids
    env$mark_genai_action_proposal_executed <- function(proposal_id) {
      env$executed_proposal_ids <- unique(c(env$executed_proposal_ids, proposal_id))
      TRUE
    }
    env$inspect_persisted_result <- function(persisted_result_id) {
      resolution <- genai_resolve_persisted_result(persisted_result_id, ctx = env)
      if (!identical(resolution$status, "success")) return(resolution)
      env$selected_persisted_result_id <- persisted_result_id
      service_result(status = "success", value = resolution$value)
    }
    env
  }
  make_proposal <- function(action_id, args, risk = "medium", persist = FALSE, mutation = list()) genai_action_proposal(
    action_id = action_id,
    action_version = "1.0",
    arguments = args,
    rationale = paste("QA proposal for", action_id),
    evidence_refs = "qa:evidence",
    expected_effects = "QA bounded effect",
    state_mutations = mutation,
    persistence_requested = persist,
    risk_tier = risk,
    confidence = 0.94
  )
  ctx <- make_ctx()
  missing_positive_ctx <- make_ctx(config = list(assessment_problem_type = "Binary Classification", actual_var = "actual", prediction_var = "probability", positive_class = "", threshold = 0.5, prediction_scale = "probability"), project_id = "qa_binary_missing_positive")
  invalid_scale_ctx <- make_ctx(config = list(assessment_problem_type = "Binary Classification", actual_var = "actual", prediction_var = "probability", positive_class = "Yes", threshold = 0.5, prediction_scale = "logit"), project_id = "qa_binary_invalid_scale")
  out_of_range_ctx <- make_ctx(data = transform(qa_data, probability = probability * 100), project_id = "qa_binary_percent_probability")
  single_class_ctx <- make_ctx(data = transform(qa_data, actual = "Yes"), project_id = "qa_binary_single_class")

  preflight <- make_proposal("analysis.preflight", list(module_id = "model_assessment", dataset_id = "active_dataset"))
  preflight_validation <- genai_validate_action_proposal(preflight, ctx = ctx)
  preflight_exec <- genai_execute_action_proposal(genai_approve_action_proposal(preflight, preflight_validation, "user")$value, ctx = ctx)
  run <- make_proposal("analysis.run_registered", list(module_id = "model_assessment", dataset_id = "active_dataset"))
  run_validation <- genai_validate_action_proposal(run, ctx = ctx)
  run_exec <- genai_execute_action_proposal(genai_approve_action_proposal(run, run_validation, "user")$value, ctx = ctx)
  tmp_id <- run_exec$value$temporary_result_id
  tmp <- ctx$genai_analysis_run_state$results[[tmp_id]]
  persist <- make_proposal("result.persist", list(temporary_result_id = tmp_id), risk = "high", persist = TRUE, mutation = "Create one persisted project result")
  persist_validation <- genai_validate_action_proposal(persist, ctx = ctx)
  persist_exec <- genai_execute_action_proposal(genai_approve_action_proposal(persist, persist_validation, "user")$value, ctx = ctx)
  persisted_id <- persist_exec$value$persisted_result_id
  listed <- list_project_persisted_results(ctx$current_project())
  bundle <- read_persisted_result_bundle(ctx$current_project(), persisted_id)
  inspect <- make_proposal("result.inspect", list(persisted_result_id = persisted_id), risk = "low")
  inspect_validation <- genai_validate_action_proposal(inspect, ctx = ctx)
  inspect_exec <- genai_execute_action_proposal(genai_approve_action_proposal(inspect, inspect_validation, "user")$value, ctx = ctx)
  reconcile <- genai_reconcile_persisted_results_audit(ctx$current_project())
  extra_arg <- make_proposal("analysis.run_registered", list(module_id = "model_assessment", dataset_id = "active_dataset", positive_class = "Yes"))
  missing_positive_validation <- genai_validate_action_proposal(run, ctx = missing_positive_ctx)
  invalid_scale_validation <- genai_validate_action_proposal(run, ctx = invalid_scale_ctx)
  out_of_range_validation <- genai_validate_action_proposal(preflight, ctx = out_of_range_ctx)
  out_of_range_exec <- if (identical(out_of_range_validation$status, "success")) {
    genai_execute_action_proposal(genai_approve_action_proposal(preflight, out_of_range_validation, "user")$value, ctx = out_of_range_ctx)
  } else {
    service_result(status = "error", errors = out_of_range_validation$errors %||% "validation_failed")
  }
  single_class_validation <- genai_validate_action_proposal(preflight, ctx = single_class_ctx)
  single_class_exec <- if (identical(single_class_validation$status, "success")) {
    genai_execute_action_proposal(genai_approve_action_proposal(preflight, single_class_validation, "user")$value, ctx = single_class_ctx)
  } else {
    service_result(status = "error", errors = single_class_validation$errors %||% "validation_failed")
  }
  metadata <- genai_executable_module_metadata()
  modes <- genai_model_assessment_supported_modes()
  mode_def <- genai_model_assessment_mode_definition("binary_classification")
  data.table::data.table(
    check = c(
      "binary_mode_enabled", "only_two_modes_enabled", "handler_metadata_hidden",
      "result_type_mapping", "binary_result_type_supported", "model_supplied_config_rejected",
      "missing_positive_blocks", "invalid_scale_blocks", "percent_probability_blocks",
      "single_class_blocks", "preflight_ready", "preflight_has_binary_checks",
      "run_validation_success", "temporary_result_type", "mode_id_recorded",
      "trusted_configuration_recorded", "threshold_metrics_present", "binary_metrics_present",
      "confusion_reconciles", "tables_bounded", "plot_specs_bounded",
      "no_artifacts_or_reports", "safe_summary_has_trusted_config", "persistence_validates",
      "persistence_succeeds", "bundle_discovered", "bundle_contains_threshold_metrics",
      "result_inspect_validates", "result_inspect_succeeds", "audit_reconciliation_runs"
    ),
    status = c(
      if ("binary_classification" %in% modes) "success" else "error",
      if (identical(sort(modes), sort(c("regression", "binary_classification")))) "success" else "error",
      if (!"execution_handler_id" %in% names(genai_executable_module_metadata())) "success" else "error",
      if (identical(genai_model_assessment_result_type_for_config(list(task_type = "binary_classification")), genai_model_assessment_binary_result_type())) "success" else "error",
      if (genai_model_assessment_binary_result_type() %in% genai_supported_temporary_result_types()) "success" else "error",
      if (identical(genai_validate_action_proposal(extra_arg, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(missing_positive_validation$status, "error")) "success" else "error",
      if (identical(invalid_scale_validation$status, "error")) "success" else "error",
      if (identical(out_of_range_exec$status, "success") && isTRUE((out_of_range_exec$value$outputs$readiness %||% "") %in% c("blocked", "failed"))) "success" else "error",
      if (identical(single_class_exec$status, "success") && isTRUE((single_class_exec$value$outputs$readiness %||% "") %in% c("blocked", "failed"))) "success" else "error",
      if (identical(preflight_validation$status, "success") && isTRUE((preflight_exec$value$outputs$readiness %||% "") %in% c("ready", "ready_with_warnings"))) "success" else "error",
      if (any(vapply(preflight_exec$value$outputs$checks %||% list(), function(x) identical(x$check_id, "probability_range"), logical(1)))) "success" else "error",
      if (identical(run_validation$status, "success")) "success" else "error",
      if (identical(tmp$temporary_result_type, genai_model_assessment_binary_result_type())) "success" else "error",
      if (identical(tmp$mode_id, "binary_classification")) "success" else "error",
      if (identical(tmp$configuration_values$positive_class, "Yes") && identical(tmp$configuration_values$prediction_scale, "probability")) "success" else "error",
      if (is.data.frame(tmp$threshold_metrics) && nrow(tmp$threshold_metrics) == 1L) "success" else "error",
      if (all(c("roc_auc", "brier_score", "log_loss", "threshold", "accuracy", "f1") %in% names(tmp$metrics))) "success" else "error",
      if (abs(sum(unlist(tmp$metrics[c("true_positives", "true_negatives", "false_positives", "false_negatives")])) - (tmp$metrics$weighted_complete_pairs %||% tmp$metrics$complete_pairs)) < 1e-6) "success" else "error",
      if (all(vapply(tmp$tables, nrow, integer(1)) <= genai_registered_analysis_limits()$max_table_rows)) "success" else "error",
      if (length(tmp$plots %||% list()) <= 5L && all(vapply(tmp$plots, function(p) is.list(p) && !is.null(p$bounded_data), logical(1)))) "success" else "error",
      if (isFALSE(run_exec$value$artifact_created) && isFALSE(run_exec$value$report_created)) "success" else "error",
      if ("trusted_configuration" %in% names(run_exec$value$outputs) && identical(run_exec$value$outputs$trusted_configuration$positive_class, "Yes")) "success" else "error",
      if (identical(persist_validation$status, "success")) "success" else "error",
      if (identical(persist_exec$status, "success") && isTRUE(persist_exec$value$persisted_result_created)) "success" else "error",
      if (nrow(listed) && persisted_id %in% listed$persisted_result_id && genai_model_assessment_binary_result_type() %in% listed$result_type) "success" else "error",
      if (identical(bundle$status, "success") && !is.null(bundle$value$threshold_metrics)) "success" else "error",
      if (identical(inspect_validation$status, "success")) "success" else "error",
      if (identical(inspect_exec$status, "success") && identical(ctx$selected_persisted_result_id, persisted_id)) "success" else "error",
      if (identical(reconcile$status, "success")) "success" else "error"
    ),
    message = c(
      "Binary classification mode is registered under model_assessment.",
      "Only regression and binary_classification modes are enabled.",
      "Executable handler metadata remains hidden from GenAI-facing module metadata.",
      "Trusted binary configuration maps to model_assessment_binary.",
      "model_assessment_binary is eligible for temporary-result persistence.",
      "GenAI-supplied positive_class is rejected.",
      "Missing trusted positive class blocks validation.",
      "Unsupported prediction scale blocks validation.",
      "Percent-style probabilities are rejected by binary preflight.",
      "Single-class target is rejected by binary preflight.",
      "Binary preflight reaches an acceptable state.",
      "Binary-specific probability range check is present.",
      "analysis.run_registered validates for binary model assessment.",
      "Temporary result type is model_assessment_binary.",
      "Temporary result records binary mode_id.",
      "Trusted class/scale configuration is recorded.",
      "Threshold metrics are present and bounded.",
      "Core binary metrics are present.",
      "Confusion counts reconcile with evaluated rows for unweighted QA fixture.",
      "Tables obey row bounds.",
      "Plot specs are normalized and bounded.",
      "Temporary execution creates no artifacts or reports.",
      "Safe GenAI summary exposes trusted config only.",
      "result.persist validates for binary results.",
      "Persistence succeeds through staged commit.",
      "Persisted discovery lists binary result type.",
      "Persisted bundle includes threshold_metrics.",
      "result.inspect validates for binary persisted result.",
      "Read-only inspection succeeds.",
      "Durable audit reconciliation runs for binary result."
    )
  )
}

qa_genai_result_persistence <- function(output_dir = file.path(tempdir(), "genai_result_persistence_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  qa_data <- data.frame(
    id = seq_len(80),
    value = c(seq_len(70), rep(NA, 10)),
    group = rep(c("A", "B"), length.out = 80),
    constant = "x",
    stringsAsFactors = FALSE
  )
  make_workspace_project <- function(provider = NULL, project_id = "qa_persist_project") {
    provider <- provider %||% storage_provider(
      provider_id = "configured_workspace",
      provider_type = "configured_workspace",
      display_name = "Configured Workspace",
      root_path = file.path(output_dir, "workspace"),
      available = TRUE,
      writable = NA,
      capabilities = list(supports_external_projects = TRUE, can_choose_directory = FALSE)
    )
    workspace <- validate_workspace_root(provider$root_path, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
    project <- create_project_in_workspace(workspace, "Persistence QA", project_id = project_id)$value
    list(workspace = workspace, project = project)
  }
  make_ctx <- function(provider = NULL, project_id = "qa_persist_project") {
    state <- make_workspace_project(provider, project_id)
    env <- new.env(parent = emptyenv())
    env$project_data <- function() qa_data
    env$uploaded_data <- function() qa_data
    env$project_data_info <- function() list(name = "QA Dataset", path = NULL)
    env$current_dataset_id <- function() "active_dataset"
    env$project_collector_project_id <- function() state$project$project_id
    env$current_workspace <- function() state$workspace
    env$current_project <- function() state$project
    env$genai_preflight_limits <- function() genai_preflight_limits()
    env$genai_registered_analysis_limits <- function() genai_registered_analysis_limits()
    env$genai_preflight_state <- list(results = list())
    env$genai_analysis_run_state <- list(jobs = list(), results = list())
    env$genai_persistence_locks <- list()
    env$executed_proposal_ids <- character()
    env$selected_persisted_result_id <- NULL
    env$store_genai_preflight_result <- function(result) {
      env$genai_preflight_state$results[[result$preflight_result_id]] <- result
      result$preflight_result_id
    }
    env$store_genai_analysis_job <- function(job) {
      env$genai_analysis_run_state$jobs[[job$job_id]] <- job
      job$job_id
    }
    env$update_genai_analysis_job <- function(job_id, fields = list()) {
      job <- env$genai_analysis_run_state$jobs[[job_id]] %||% list(job_id = job_id)
      for (field in names(fields)) job[[field]] <- fields[[field]]
      env$genai_analysis_run_state$jobs[[job_id]] <- job
      job
    }
    env$store_genai_analysis_result <- function(result) {
      env$genai_analysis_run_state$results[[result$temporary_result_id]] <- result
      result$temporary_result_id
    }
    env$mark_genai_analysis_result_persisted <- function(temporary_result_id, persisted_result_id, persisted_project_id) {
      result <- env$genai_analysis_run_state$results[[temporary_result_id]]
      if (is.null(result)) return(FALSE)
      result$persisted <- TRUE
      result$persisted_result_id <- persisted_result_id
      result$persisted_at <- Sys.time()
      result$persisted_project_id <- persisted_project_id
      env$genai_analysis_run_state$results[[temporary_result_id]] <- result
      TRUE
    }
    env$reset_genai_analysis_cancel <- function() TRUE
    env$genai_analysis_cancel_requested <- function() FALSE
    env$genai_action_proposal_executed <- function(proposal_id) proposal_id %in% env$executed_proposal_ids
    env$mark_genai_action_proposal_executed <- function(proposal_id) {
      env$executed_proposal_ids <- unique(c(env$executed_proposal_ids, proposal_id))
      TRUE
    }
    env$inspect_persisted_result <- function(persisted_result_id) {
      resolution <- genai_resolve_persisted_result(persisted_result_id, ctx = env)
      if (!identical(resolution$status, "success")) return(resolution)
      env$selected_persisted_result_id <- persisted_result_id
      service_result(status = "success", value = resolution$value)
    }
    env
  }
  make_run <- function() genai_action_proposal(
    action_id = "analysis.run_registered",
    action_version = "1.0",
    arguments = list(module_id = "dataset_profile", dataset_id = "active_dataset"),
    rationale = "Run the allowlisted temporary dataset profile.",
    evidence_refs = "dataset:active_dataset",
    expected_effects = "Create a temporary session-local result",
    risk_tier = "medium",
    confidence = 0.9
  )
  make_persist <- function(temporary_result_id, extra = list(), persistence_requested = TRUE, risk_tier = "high", state_mutations = "Create one persisted project result") {
    genai_action_proposal(
      action_id = "result.persist",
      action_version = "1.0",
      arguments = c(list(temporary_result_id = temporary_result_id), extra),
      rationale = "Retain the completed dataset profile as durable project evidence.",
      evidence_refs = paste0("temporary_result:", temporary_result_id),
      expected_effects = c("Persist the completed dataset profile under the active project", "Do not rerun the analysis or generate a report"),
      state_mutations = state_mutations,
      persistence_requested = persistence_requested,
      risk_tier = risk_tier,
      confidence = 0.96
    )
  }
  make_inspect <- function(persisted_result_id, extra = list()) {
    genai_action_proposal(
      action_id = "result.inspect",
      action_version = "1.0",
      arguments = c(list(persisted_result_id = persisted_result_id), extra),
      rationale = "Open the trusted persisted dataset profile for read-only inspection.",
      evidence_refs = paste0("persisted_result:", persisted_result_id),
      expected_effects = c("Open the Persisted Results browser", "Select the referenced persisted result", "Do not modify or regenerate the result"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "low",
      confidence = 0.96
    )
  }
  ctx <- make_ctx()
  run <- make_run()
  run_validation <- genai_validate_action_proposal(run, ctx = ctx)
  run_approval <- genai_approve_action_proposal(run, run_validation, "user")
  run_execution <- genai_execute_action_proposal(run_approval$value, ctx = ctx, approval_hash = run_approval$value$approval_hash)
  temporary_result_id <- run_execution$value$temporary_result_id
  persist <- make_persist(temporary_result_id)
  persist_validation <- genai_validate_action_proposal(persist, ctx = ctx)
  persist_approval <- genai_approve_action_proposal(persist, persist_validation, "user")
  persist_execution <- genai_execute_action_proposal(persist_approval$value, ctx = ctx, approval_hash = persist_approval$value$approval_hash)
  duplicate_validation <- genai_validate_action_proposal(make_persist(temporary_result_id), ctx = ctx)
  listed <- list_project_persisted_results(ctx$current_project())
  listed_with_invalid <- list_project_persisted_results(ctx$current_project(), include_invalid = TRUE)
  resolved <- if (identical(persist_execution$status, "success")) {
    resolve_project_persisted_result(ctx$current_project(), persist_execution$value$persisted_result_id)
  } else {
    service_result(status = "error", errors = "persistence failed")
  }
  inspect <- make_inspect(persist_execution$value$persisted_result_id %||% "")
  inspect_validation <- genai_validate_action_proposal(inspect, ctx = ctx)
  inspect_approval <- genai_approve_action_proposal(inspect, inspect_validation, "user")
  inspect_execution <- genai_execute_action_proposal(inspect_approval$value, ctx = ctx, approval_hash = inspect_approval$value$approval_hash)
  inspect_replay <- genai_execute_action_proposal(inspect_approval$value, ctx = ctx, approval_hash = inspect_approval$value$approval_hash)
  inspect_extra <- make_inspect(persist_execution$value$persisted_result_id %||% "", extra = list(path = "C:/tmp/result"))
  inspect_unknown <- make_inspect("missing_result")
  provider_changed_ctx <- ctx
  original_current_workspace <- ctx$current_workspace
  provider_changed_ctx$current_workspace <- function() {
    workspace <- original_current_workspace()
    workspace$provider$provider_id <- "changed_provider"
    workspace$provider_id <- "changed_provider"
    workspace
  }
  provider_changed_execution <- genai_execute_action_proposal(persist_approval$value, ctx = provider_changed_ctx, approval_hash = persist_approval$value$approval_hash)
  managed_provider <- storage_provider(
    provider_id = "managed_persist_qa",
    provider_type = "managed_workspace",
    display_name = "Managed Persist QA",
    root_path = file.path(output_dir, "managed_workspace"),
    available = TRUE,
    managed = TRUE,
    capabilities = list(workspace_is_managed = TRUE, supports_external_projects = FALSE, can_choose_directory = FALSE, can_browse_server_directories = FALSE, native_directory_picker = FALSE)
  )
  managed_ctx <- make_ctx(managed_provider, "managed_persist_project")
  managed_run <- make_run()
  managed_run_validation <- genai_validate_action_proposal(managed_run, ctx = managed_ctx)
  managed_run_execution <- genai_execute_action_proposal(genai_approve_action_proposal(managed_run, managed_run_validation, "user")$value, ctx = managed_ctx)
  managed_persist <- make_persist(managed_run_execution$value$temporary_result_id)
  managed_persist_validation <- genai_validate_action_proposal(managed_persist, ctx = managed_ctx)
  managed_persist_execution <- genai_execute_action_proposal(genai_approve_action_proposal(managed_persist, managed_persist_validation, "user")$value, ctx = managed_ctx)
  invalid_extra <- make_persist(temporary_result_id, extra = list(filename = "bad.json"))
  missing_id <- make_persist("")
  no_persistence_flag <- make_persist(temporary_result_id, persistence_requested = FALSE)
  low_risk <- make_persist(temporary_result_id, risk_tier = "medium")
  registry <- genai_action_registry()
  action <- genai_action_registry_get("result.persist", registry)
  public_action <- genai_action_registry_list(registry)[["result.persist"]]
  inspect_action <- genai_action_registry_get("result.inspect", registry)
  inspect_public_action <- genai_action_registry_list(registry)[["result.inspect"]]
  data.table::data.table(
    check = c(
      "registry_result_persist", "result_persist_high_risk", "result_persist_persistence_required",
      "temporary_result_created", "valid_persistence_proposal", "approval_fingerprint_bound",
      "persistence_execution_success", "execution_state_semantics", "manifest_exists",
      "bundle_discovery", "bundle_resolves", "temporary_result_marked_persisted",
      "duplicate_persistence_blocked", "provider_change_invalidates_approval",
      "managed_provider_no_selection_succeeds", "extra_arguments_rejected", "missing_id_rejected",
      "persistence_flag_required", "risk_tier_required", "proposal_handler_hidden",
      "registry_result_inspect", "result_inspect_low_risk", "result_inspect_not_persistent",
      "browser_discovers_healthy_result", "browser_invalid_inventory_available",
      "valid_result_inspect_proposal", "result_inspect_fingerprint_bound",
      "result_inspect_execution_success", "result_inspect_selected_expected_result",
      "result_inspect_state_semantics", "result_inspect_replay_blocked",
      "result_inspect_extra_path_rejected", "result_inspect_unknown_rejected",
      "result_inspect_handler_hidden"
    ),
    status = c(
      if (inherits(action, "aq_genai_action_definition")) "success" else "error",
      if (identical(action$risk_tier, "high")) "success" else "error",
      if (isTRUE(action$persistence_requested)) "success" else "error",
      if (identical(run_execution$status, "success") && nzchar(temporary_result_id %||% "")) "success" else "error",
      if (identical(persist_validation$status, "success")) "success" else "error",
      if (identical(persist_approval$value$approval_resource_fingerprint, persist_validation$value$resource_fingerprint)) "success" else "error",
      if (identical(persist_execution$status, "success") && isTRUE(persist_execution$value$persisted_result_created)) "success" else "error",
      if (isFALSE(persist_execution$value$computation_performed) && isTRUE(persist_execution$value$project_state_changed) && isTRUE(persist_execution$value$persistent_changes) && isFALSE(persist_execution$value$report_created)) "success" else "error",
      if (file.exists(file.path(ctx$current_project()$project_root, persist_execution$value$safe_relative_location, "manifest.json"))) "success" else "error",
      if (nrow(listed) == 1L) "success" else "error",
      if (identical(resolved$status, "success")) "success" else "error",
      if (isTRUE(ctx$genai_analysis_run_state$results[[temporary_result_id]]$persisted)) "success" else "error",
      if (identical(duplicate_validation$status, "error") && any(grepl("temporary_result_already_persisted", duplicate_validation$errors))) "success" else "error",
      if (identical(provider_changed_execution$status, "error")) "success" else "error",
      if (identical(managed_persist_validation$status, "success") && identical(managed_persist_execution$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(invalid_extra, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(missing_id, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(no_persistence_flag, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(low_risk, ctx = ctx)$status, "error")) "success" else "error",
      if (!"handler" %in% names(public_action)) "success" else "error",
      if (inherits(inspect_action, "aq_genai_action_definition")) "success" else "error",
      if (identical(inspect_action$risk_tier, "low")) "success" else "error",
      if (!isTRUE(inspect_action$persistence_requested %||% FALSE)) "success" else "error",
      if (nrow(listed) == 1L && identical(listed$health_status[[1]], "healthy")) "success" else "error",
      if (nrow(listed_with_invalid) >= nrow(listed) && "health_status" %in% names(listed_with_invalid)) "success" else "error",
      if (identical(inspect_validation$status, "success")) "success" else "error",
      if (identical(inspect_approval$value$approval_resource_fingerprint, inspect_validation$value$resource_fingerprint)) "success" else "error",
      if (identical(inspect_execution$status, "success") && identical(inspect_execution$value$status, "succeeded")) "success" else "error",
      if (identical(ctx$selected_persisted_result_id, persist_execution$value$persisted_result_id)) "success" else "error",
      if (isTRUE(inspect_execution$value$ui_state_changed) && isFALSE(inspect_execution$value$project_state_changed) && isFALSE(inspect_execution$value$persistent_changes) && isFALSE(inspect_execution$value$computation_performed) && isFALSE(inspect_execution$value$persisted_result_created)) "success" else "error",
      if (identical(inspect_replay$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(inspect_extra, ctx = ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(inspect_unknown, ctx = ctx)$status, "error")) "success" else "error",
      if (!"handler" %in% names(inspect_public_action)) "success" else "error"
    ),
    message = c(
      "result.persist is registered.", "result.persist is high risk.", "result.persist is marked persistent.",
      "Temporary dataset_profile result was created through analysis.run_registered.", "Valid result.persist proposal validates.",
      "Approval is bound to persistence fingerprint.", "Approved persistence executes.",
      "Persistence reports durable project mutation without rerunning computation.", "Completed bundle manifest exists.",
      "Completed bundle is discoverable after commit.", "Persisted result resolves and validates by manifest/hash.",
      "Temporary result is annotated as persisted, not deleted.", "Duplicate persistence into same project is blocked.",
      "Provider change after approval invalidates execution.", "Managed provider with no directory selection can persist.",
      "Model-supplied filename/extra arguments are rejected.", "Missing temporary_result_id is rejected.",
      "Persistence flag is required.", "High risk tier is required.", "Public registry metadata hides executable handler.",
      "result.inspect is registered.", "result.inspect is low risk.", "result.inspect is not persistent.",
      "Browser discovery lists the healthy persisted result.", "Browser discovery can include safe invalid-bundle statuses.",
      "Valid result.inspect proposal validates.", "Approval binds to persisted-result resource fingerprint.",
      "Approved result.inspect executes.", "Trusted app bridge selects the expected persisted result.",
      "result.inspect reports UI-only read-only state semantics.", "Completed result.inspect proposal replay is blocked.",
      "Model-supplied paths are rejected.", "Unknown persisted result ids are rejected.",
      "Public registry metadata hides result.inspect handler."
    )
  )
}

qa_genai_action_layer <- function() {
  registry <- genai_action_registry()
  module_action <- genai_action_registry_get("module.open", registry)
  artifact_action <- genai_action_registry_get("artifact.inspect", registry)
  report_action <- genai_action_registry_get("report.open", registry)
  duplicate_error <- tryCatch({
    reg <- genai_action_registry_create(list(module_action))
    genai_action_registry_register(reg, module_action)
    FALSE
  }, error = function(e) TRUE)

  qa_artifact <- create_artifact(
    artifact_id = "artifact_qa_plot_001",
    artifact_type = "plot",
    label = "QA Plot Artifact",
    source_module = "autoquant_eda",
    metadata = list(project_id = "qa_project", artifact_version = "v1")
  )
  qa_artifact_v2 <- qa_artifact
  qa_artifact_v2$metadata$artifact_version <- "v2"
  other_project_artifact <- qa_artifact
  other_project_artifact$metadata$project_id <- "other_project"
  deleted_artifact <- qa_artifact
  deleted_artifact$status <- "deleted"
  unavailable_artifact <- qa_artifact
  unavailable_artifact$status <- "needs_data"
  unsupported_artifact <- qa_artifact
  unsupported_artifact$artifact_type <- "unsupported_type"

  make_ctx <- function(artifacts = list(qa_artifact), project_id = "qa_project") {
    selected <- new.env(parent = emptyenv())
    selected$id <- NULL
    env <- new.env(parent = emptyenv())
    env$all_artifacts <- function() artifacts
    env$project_collector_project_id <- function() project_id
    env$inspect_artifact <- function(artifact_id) {
      selected$id <- artifact_id
      TRUE
    }
    env$selected <- selected
    env
  }
  artifact_ctx <- make_ctx()
  artifact_ctx_v2 <- make_ctx(list(qa_artifact_v2))
  other_project_ctx <- make_ctx(list(other_project_artifact), project_id = "qa_project")
  deleted_ctx <- make_ctx(list(deleted_artifact))
  unavailable_ctx <- make_ctx(list(unavailable_artifact))
  unsupported_ctx <- make_ctx(list(unsupported_artifact))

  qa_report <- create_report_plan(
    plan_id = "report_qa_diagnostics_001",
    label = "QA Diagnostics Report",
    source_module = "autoquant_eda",
    layout_type = "sections",
    sections = list(
      overview = create_report_plan_section("overview", "Overview", artifact_ids = "artifact_qa_plot_001")
    ),
    metadata = list(project_id = "qa_project", report_version = "v1", render_status = "preview_available"),
    status = "recommended"
  )
  qa_report_v2 <- qa_report
  qa_report_v2$metadata$report_version <- "v2"
  qa_report_failed <- qa_report
  qa_report_failed$metadata$render_status <- "render_failed"
  qa_report_archived <- qa_report
  qa_report_archived$status <- "archived"
  qa_report_deleted <- qa_report
  qa_report_deleted$status <- "deleted"
  qa_report_generating <- qa_report
  qa_report_generating$metadata$render_status <- "generating"
  qa_report_unsupported <- qa_report
  qa_report_unsupported$layout_type <- "unsupported"
  qa_report_other_project <- qa_report
  qa_report_other_project$metadata$project_id <- "other_project"

  make_report_ctx <- function(reports = list(qa_report), project_id = "qa_project") {
    selected <- new.env(parent = emptyenv())
    selected$id <- NULL
    env <- new.env(parent = emptyenv())
    env$report_plan_state <- list(plans = repair_report_plan_collection(reports))
    env$project_collector_project_id <- function() project_id
    env$open_report <- function(report_id) {
      selected$id <- report_id
      TRUE
    }
    env$selected <- selected
    env
  }
  report_ctx <- make_report_ctx()
  report_ctx_v2 <- make_report_ctx(list(qa_report_v2))
  report_other_project_ctx <- make_report_ctx(list(qa_report_other_project), project_id = "qa_project")
  report_deleted_ctx <- make_report_ctx(list(qa_report_deleted))
  report_failed_ctx <- make_report_ctx(list(qa_report_failed))
  report_archived_ctx <- make_report_ctx(list(qa_report_archived))
  report_generating_ctx <- make_report_ctx(list(qa_report_generating))
  report_unsupported_ctx <- make_report_ctx(list(qa_report_unsupported))

  qa_data <- data.table::data.table(
    id = 1:25,
    target = c(rep(1, 10), rep(0, 15)),
    constant = "same",
    mostly_missing = c(rep(NA_real_, 20), 1:5),
    category = paste0("segment_", 1:25),
    value = seq_len(25)
  )
  qa_data_v2 <- data.table::copy(qa_data)
  qa_data_v2$new_col <- 1
  qa_empty <- qa_data[0]
  qa_zero_col <- data.table::data.table()[seq_len(3)]
  make_preflight_ctx <- function(data = qa_data, module_mutator = NULL, project_id = "qa_project", cancel = FALSE, limits = genai_preflight_limits()) {
    selected <- new.env(parent = emptyenv())
    selected$stored <- list()
    env <- new.env(parent = emptyenv())
    env$uploaded_data <- function() data
    env$project_data <- function() data
    env$project_data_info <- function() list(name = "QA Dataset", path = NULL)
    env$current_dataset_id <- function() "active_dataset"
    env$project_collector_project_id <- function() project_id
    env$genai_preflight_limits <- function() limits
    env$genai_preflight_cancel_requested <- function() isTRUE(cancel)
    env$reset_genai_preflight_cancel <- function() TRUE
    env$store_genai_preflight_result <- function(result) {
      selected$stored[[result$preflight_result_id]] <- result
      result$preflight_result_id
    }
    env$report_plan_state <- list(plans = list())
    env$all_artifacts <- function() list()
    env$selected <- selected
    if (!is.null(module_mutator)) {
      env$module_mutator <- module_mutator
    }
    env
  }
  preflight_ctx <- make_preflight_ctx()
  preflight_ctx_v2 <- make_preflight_ctx(qa_data_v2)
  preflight_empty_ctx <- make_preflight_ctx(qa_empty)
  preflight_zero_col_ctx <- make_preflight_ctx(qa_zero_col)
  preflight_cancel_ctx <- make_preflight_ctx(cancel = TRUE)
  preflight_timeout_ctx <- make_preflight_ctx(limits = genai_preflight_limits(max_elapsed_ms = -1L))

  valid <- genai_action_proposal(
    action_id = "module.open",
    action_version = "1.0",
    arguments = list(module_id = "autoquant_eda"),
    rationale = "Open Explore Data so the analyst can inspect foundational evidence.",
    evidence_refs = "qa:evidence",
    expected_effects = "Open Explore Data",
    risk_tier = "low"
  )
  valid_validation <- genai_validate_action_proposal(valid)
  unknown_action <- valid
  unknown_action$action_id <- "unknown.action"
  unknown_action$proposal_hash <- genai_action_compute_hash(unknown_action)
  invalid_module <- valid
  invalid_module$arguments$module_id <- "not_a_module"
  invalid_module$proposal_hash <- genai_action_compute_hash(invalid_module)
  missing_arguments <- valid
  missing_arguments$arguments <- list()
  missing_arguments$proposal_hash <- genai_action_compute_hash(missing_arguments)
  extra_arguments <- valid
  extra_arguments$arguments$callback <- "danger"
  extra_arguments$proposal_hash <- genai_action_compute_hash(extra_arguments)
  risk_mismatch <- valid
  risk_mismatch$risk_tier <- "none"
  risk_mismatch$proposal_hash <- genai_action_compute_hash(risk_mismatch)
  persistence <- valid
  persistence$persistence_requested <- TRUE
  persistence$proposal_hash <- genai_action_compute_hash(persistence)
  mutation <- valid
  mutation$state_mutations <- list(project_data = "change")
  mutation$proposal_hash <- genai_action_compute_hash(mutation)
  expired <- valid
  expired$expires_at <- Sys.time() - 1
  expired$proposal_hash <- genai_action_compute_hash(expired)
  corrupted <- valid
  corrupted$proposal_hash <- "bad"
  unsupported_version <- valid
  unsupported_version$action_version <- "9.9"
  unsupported_version$proposal_hash <- genai_action_compute_hash(unsupported_version)
  approval <- genai_approve_action_proposal(valid, valid_validation, approval_source = "user")
  self_approval <- genai_approve_action_proposal(valid, valid_validation, approval_source = "genai")
  module_ctx <- new.env(parent = emptyenv())
  module_ctx$selected_module <- NULL
  module_ctx$select_analysis_module <- function(module_id) {
    module_ctx$selected_module <- module_id
    TRUE
  }
  module_ctx$navigate_to <- function(page) {
    module_ctx$selected_page <- page
    TRUE
  }
  modified_after_approval <- approval$value
  modified_after_approval$arguments$module_id <- "model_assessment"
  unapproved_execution <- genai_execute_action_proposal(valid)
  approved_execution <- genai_execute_action_proposal(approval$value, ctx = module_ctx)
  read_only_execution <- genai_execute_action_proposal(approval$value, policy = genai_action_policy("read_only"))

  artifact_valid <- genai_action_proposal(
    action_id = "artifact.inspect",
    action_version = "1.0",
    arguments = list(artifact_id = "artifact_qa_plot_001"),
    rationale = "Inspect the QA plot artifact.",
    evidence_refs = c("artifact:artifact_qa_plot_001"),
    expected_effects = c("Open Artifact Studio", "Select the referenced artifact"),
    risk_tier = "low"
  )
  artifact_validation <- genai_validate_action_proposal(artifact_valid, ctx = artifact_ctx)
  artifact_approval <- genai_approve_action_proposal(artifact_valid, artifact_validation, approval_source = "user")
  artifact_execution <- genai_execute_action_proposal(artifact_approval$value, ctx = artifact_ctx)
  artifact_unapproved <- genai_execute_action_proposal(artifact_valid, ctx = artifact_ctx)
  artifact_stale <- genai_execute_action_proposal(artifact_approval$value, ctx = artifact_ctx_v2)
  artifact_missing <- artifact_valid
  artifact_missing$arguments <- list()
  artifact_missing$proposal_hash <- genai_action_compute_hash(artifact_missing)
  artifact_empty <- artifact_valid
  artifact_empty$arguments$artifact_id <- ""
  artifact_empty$proposal_hash <- genai_action_compute_hash(artifact_empty)
  artifact_vector <- artifact_valid
  artifact_vector$arguments$artifact_id <- c("artifact_qa_plot_001", "artifact_qa_plot_002")
  artifact_vector$proposal_hash <- genai_action_compute_hash(artifact_vector)
  artifact_malformed <- artifact_valid
  artifact_malformed$arguments$artifact_id <- "../artifact_qa_plot_001"
  artifact_malformed$proposal_hash <- genai_action_compute_hash(artifact_malformed)
  artifact_path <- artifact_valid
  artifact_path$arguments$artifact_id <- "C:/tmp/artifact.png"
  artifact_path$proposal_hash <- genai_action_compute_hash(artifact_path)
  artifact_url <- artifact_valid
  artifact_url$arguments$artifact_id <- "https://example.com/artifact"
  artifact_url$proposal_hash <- genai_action_compute_hash(artifact_url)
  artifact_extra <- artifact_valid
  artifact_extra$arguments$project_id <- "qa_project"
  artifact_extra$proposal_hash <- genai_action_compute_hash(artifact_extra)
  artifact_function_arg <- artifact_valid
  artifact_function_arg$arguments$callback <- "run_this"
  artifact_function_arg$proposal_hash <- genai_action_compute_hash(artifact_function_arg)
  artifact_unknown <- artifact_valid
  artifact_unknown$arguments$artifact_id <- "artifact_missing_404"
  artifact_unknown$proposal_hash <- genai_action_compute_hash(artifact_unknown)
  artifact_rejected <- genai_reject_action_proposal(artifact_valid)$value
  artifact_cancelled <- genai_cancel_action_proposal(artifact_valid)$value
  artifact_completed <- artifact_approval$value
  artifact_completed$status <- "succeeded"
  artifact_deleted_validation <- genai_validate_action_proposal(artifact_valid, ctx = deleted_ctx)
  artifact_unavailable_validation <- genai_validate_action_proposal(artifact_valid, ctx = unavailable_ctx)
  artifact_unsupported_validation <- genai_validate_action_proposal(artifact_valid, ctx = unsupported_ctx)
  artifact_other_project_validation <- genai_validate_action_proposal(artifact_valid, ctx = other_project_ctx)

  report_valid <- genai_action_proposal(
    action_id = "report.open",
    action_version = "1.0",
    arguments = list(report_id = "report_qa_diagnostics_001"),
    rationale = "Open the QA diagnostics report plan for inspection.",
    evidence_refs = c("report:report_qa_diagnostics_001"),
    expected_effects = c("Open Layout Studio", "Select the referenced report plan"),
    risk_tier = "low"
  )
  report_validation <- genai_validate_action_proposal(report_valid, ctx = report_ctx)
  report_approval <- genai_approve_action_proposal(report_valid, report_validation, approval_source = "user")
  report_execution <- genai_execute_action_proposal(report_approval$value, ctx = report_ctx)
  report_unapproved <- genai_execute_action_proposal(report_valid, ctx = report_ctx)
  report_stale <- genai_execute_action_proposal(report_approval$value, ctx = report_ctx_v2)
  report_missing <- report_valid
  report_missing$arguments <- list()
  report_missing$proposal_hash <- genai_action_compute_hash(report_missing)
  report_empty <- report_valid
  report_empty$arguments$report_id <- ""
  report_empty$proposal_hash <- genai_action_compute_hash(report_empty)
  report_vector <- report_valid
  report_vector$arguments$report_id <- c("report_qa_diagnostics_001", "report_qa_diagnostics_002")
  report_vector$proposal_hash <- genai_action_compute_hash(report_vector)
  report_malformed <- report_valid
  report_malformed$arguments$report_id <- "../report_qa_diagnostics_001"
  report_malformed$proposal_hash <- genai_action_compute_hash(report_malformed)
  report_path <- report_valid
  report_path$arguments$report_id <- "C:/tmp/report.docx"
  report_path$proposal_hash <- genai_action_compute_hash(report_path)
  report_url <- report_valid
  report_url$arguments$report_id <- "https://example.com/report"
  report_url$proposal_hash <- genai_action_compute_hash(report_url)
  report_extra <- report_valid
  report_extra$arguments$render <- TRUE
  report_extra$proposal_hash <- genai_action_compute_hash(report_extra)
  report_callback_arg <- report_valid
  report_callback_arg$arguments$callback <- "run_this"
  report_callback_arg$proposal_hash <- genai_action_compute_hash(report_callback_arg)
  report_unknown <- report_valid
  report_unknown$arguments$report_id <- "report_missing_404"
  report_unknown$proposal_hash <- genai_action_compute_hash(report_unknown)
  report_rejected <- genai_reject_action_proposal(report_valid)$value
  report_cancelled <- genai_cancel_action_proposal(report_valid)$value
  report_completed <- report_approval$value
  report_completed$status <- "succeeded"
  report_deleted_validation <- genai_validate_action_proposal(report_valid, ctx = report_deleted_ctx)
  report_failed_validation <- genai_validate_action_proposal(report_valid, ctx = report_failed_ctx)
  report_archived_validation <- genai_validate_action_proposal(report_valid, ctx = report_archived_ctx)
  report_generating_validation <- genai_validate_action_proposal(report_valid, ctx = report_generating_ctx)
  report_unsupported_validation <- genai_validate_action_proposal(report_valid, ctx = report_unsupported_ctx)
  report_other_project_validation <- genai_validate_action_proposal(report_valid, ctx = report_other_project_ctx)

  preflight_valid <- genai_action_proposal(
    action_id = "analysis.preflight",
    action_version = "1.0",
    arguments = list(module_id = "autoquant_eda", dataset_id = "active_dataset"),
    rationale = "Check whether Explore Data can run against the active dataset.",
    evidence_refs = c("module:autoquant_eda", "dataset:active_dataset"),
    expected_effects = c("Run bounded readiness checks", "Create a temporary preflight result"),
    risk_tier = "medium"
  )
  preflight_validation <- genai_validate_action_proposal(preflight_valid, ctx = preflight_ctx)
  preflight_approval <- genai_approve_action_proposal(preflight_valid, preflight_validation, approval_source = "user")
  preflight_execution <- genai_execute_action_proposal(preflight_approval$value, ctx = preflight_ctx)
  preflight_unapproved <- genai_execute_action_proposal(preflight_valid, ctx = preflight_ctx)
  preflight_stale <- genai_execute_action_proposal(preflight_approval$value, ctx = preflight_ctx_v2)
  preflight_missing_module <- preflight_valid
  preflight_missing_module$arguments <- list(dataset_id = "active_dataset")
  preflight_missing_module$proposal_hash <- genai_action_compute_hash(preflight_missing_module)
  preflight_missing_dataset <- preflight_valid
  preflight_missing_dataset$arguments <- list(module_id = "autoquant_eda")
  preflight_missing_dataset$proposal_hash <- genai_action_compute_hash(preflight_missing_dataset)
  preflight_empty_ids <- preflight_valid
  preflight_empty_ids$arguments <- list(module_id = "", dataset_id = "")
  preflight_empty_ids$proposal_hash <- genai_action_compute_hash(preflight_empty_ids)
  preflight_vector_ids <- preflight_valid
  preflight_vector_ids$arguments <- list(module_id = c("autoquant_eda", "x"), dataset_id = "active_dataset")
  preflight_vector_ids$proposal_hash <- genai_action_compute_hash(preflight_vector_ids)
  preflight_path <- preflight_valid
  preflight_path$arguments$dataset_id <- "C:/tmp/data.csv"
  preflight_path$proposal_hash <- genai_action_compute_hash(preflight_path)
  preflight_url <- preflight_valid
  preflight_url$arguments$dataset_id <- "https://example.com/data.csv"
  preflight_url$proposal_hash <- genai_action_compute_hash(preflight_url)
  preflight_extra <- preflight_valid
  preflight_extra$arguments$target <- "target"
  preflight_extra$proposal_hash <- genai_action_compute_hash(preflight_extra)
  preflight_timeout_arg <- preflight_valid
  preflight_timeout_arg$arguments$timeout <- 999
  preflight_timeout_arg$proposal_hash <- genai_action_compute_hash(preflight_timeout_arg)
  preflight_code_arg <- preflight_valid
  preflight_code_arg$arguments$code <- "system('whoami')"
  preflight_code_arg$proposal_hash <- genai_action_compute_hash(preflight_code_arg)
  preflight_unknown_module <- preflight_valid
  preflight_unknown_module$arguments$module_id <- "missing_module"
  preflight_unknown_module$proposal_hash <- genai_action_compute_hash(preflight_unknown_module)
  preflight_unsupported_module <- preflight_valid
  preflight_unsupported_module$arguments$module_id <- "autoquant_multiclass_shap_analysis"
  preflight_unsupported_module$proposal_hash <- genai_action_compute_hash(preflight_unsupported_module)
  preflight_unknown_dataset <- preflight_valid
  preflight_unknown_dataset$arguments$dataset_id <- "dataset_missing"
  preflight_unknown_dataset$proposal_hash <- genai_action_compute_hash(preflight_unknown_dataset)
  preflight_empty_validation <- genai_validate_action_proposal(preflight_valid, ctx = preflight_empty_ctx)
  preflight_zero_col_validation <- genai_validate_action_proposal(preflight_valid, ctx = preflight_zero_col_ctx)
  preflight_cancel_execution <- genai_execute_action_proposal(preflight_approval$value, ctx = preflight_cancel_ctx)
  preflight_timeout_execution <- genai_execute_action_proposal(preflight_approval$value, ctx = preflight_timeout_ctx)
  preflight_rejected <- genai_reject_action_proposal(preflight_valid)$value
  preflight_cancelled <- genai_cancel_action_proposal(preflight_valid)$value
  preflight_completed <- preflight_approval$value
  preflight_completed$status <- "succeeded"

  artifact_parse <- genai_extract_action_proposal(paste0(
    "Inspect this:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "artifact.inspect",
      action_version = "1.0",
      arguments = list(artifact_id = "artifact_qa_plot_001"),
      rationale = "Inspect QA artifact.",
      evidence_refs = list("artifact:artifact_qa_plot_001"),
      expected_effects = list("Open Artifact Studio"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "low",
      confidence = 0.9
    ))),
    "\n```"
  ))
  invented_artifact_parse <- genai_extract_action_proposal(paste0(
    "Inspect this:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "artifact.inspect",
      action_version = "1.0",
      arguments = list(artifact_id = "artifact_invented"),
      rationale = "Inspect invented artifact.",
      evidence_refs = list("artifact:artifact_invented"),
      expected_effects = list("Open Artifact Studio"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "low",
      confidence = 0.9
    ))),
    "\n```"
  ))
  report_parse <- genai_extract_action_proposal(paste0(
    "Open this report:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "report.open",
      action_version = "1.0",
      arguments = list(report_id = "report_qa_diagnostics_001"),
      rationale = "Open QA report.",
      evidence_refs = list("report:report_qa_diagnostics_001"),
      expected_effects = list("Open Layout Studio"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "low",
      confidence = 0.9
    ))),
    "\n```"
  ))
  invented_report_parse <- genai_extract_action_proposal(paste0(
    "Open this report:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "report.open",
      action_version = "1.0",
      arguments = list(report_id = "report_invented"),
      rationale = "Open invented report.",
      evidence_refs = list("report:report_invented"),
      expected_effects = list("Open Layout Studio"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "low",
      confidence = 0.9
    ))),
    "\n```"
  ))
  preflight_parse <- genai_extract_action_proposal(paste0(
    "Preflight this:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "analysis.preflight",
      action_version = "1.0",
      arguments = list(module_id = "autoquant_eda", dataset_id = "active_dataset"),
      rationale = "Check readiness.",
      evidence_refs = list("module:autoquant_eda", "dataset:active_dataset"),
      expected_effects = list("Run bounded preflight"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "medium",
      confidence = 0.9
    ))),
    "\n```"
  ))
  invented_preflight_parse <- genai_extract_action_proposal(paste0(
    "Preflight this:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "analysis.preflight",
      action_version = "1.0",
      arguments = list(module_id = "autoquant_eda", dataset_id = "invented_dataset"),
      rationale = "Check readiness.",
      evidence_refs = list("module:autoquant_eda", "dataset:invented_dataset"),
      expected_effects = list("Run bounded preflight"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "medium",
      confidence = 0.9
    ))),
    "\n```"
  ))
  advisory_parse <- genai_extract_action_proposal("This is advice only.")
  proposal_parse <- genai_extract_action_proposal(paste0(
    "Open this:\n```json\n",
    .genai_action_json(list(action_proposal = list(
      proposal_version = "1.0",
      action_id = "module.open",
      action_version = "1.0",
      arguments = list(module_id = "autoquant_eda"),
      rationale = "Open Explore Data.",
      evidence_refs = list("qa"),
      expected_effects = list("Open Explore Data"),
      state_mutations = list(),
      persistence_requested = FALSE,
      risk_tier = "low",
      confidence = 0.9
    ))),
    "\n```"
  ))
  malformed_parse <- genai_extract_action_proposal("{ bad json")
  rows <- data.table::data.table(
    check = c(
      "valid_action_registration", "artifact_action_registration", "duplicate_action_rejection", "unknown_action_lookup", "listing_registered_actions",
      "metadata_excludes_handlers", "artifact_action_version",
      "valid_proposal", "unknown_action", "invalid_module_id", "missing_arguments", "extra_prohibited_arguments",
      "risk_tier_mismatch", "persistence_rejection", "state_mutation_rejection", "expiration", "corrupted_hash",
      "unsupported_action_version", "valid_approval", "rejection", "approval_blocked_for_invalid", "modified_invalidates_approval",
      "expired_cannot_execute", "model_cannot_self_approve", "approved_proposal_executes", "unapproved_cannot_execute",
      "read_only_cannot_execute", "audit_record_written", "no_persistent_project_mutation", "module_open_ui_state_semantics",
      "artifact_valid_id", "artifact_missing_id", "artifact_empty_id", "artifact_vector_id", "artifact_malformed_id",
      "artifact_path_rejected", "artifact_url_rejected", "artifact_project_arg_rejected", "artifact_callback_arg_rejected",
      "artifact_resolves_current_project", "artifact_unknown_rejected", "artifact_cross_project_rejected",
      "artifact_deleted_rejected", "artifact_unavailable_rejected", "artifact_unsupported_rejected",
      "artifact_fingerprint_bound", "artifact_changed_invalidates_approval", "artifact_rejected_cannot_execute",
      "artifact_cancelled_cannot_execute", "artifact_completed_cannot_execute_twice", "artifact_approved_executes",
      "artifact_selected_expected_id", "artifact_unapproved_cannot_execute", "artifact_audit_record_written",
      "artifact_contents_unchanged", "artifact_no_project_mutation", "artifact_no_persistent_change",
      "artifact_ui_state_semantics", "advisory_without_proposal",
      "valid_proposal_response", "valid_artifact_proposal_response", "invented_artifact_rejected_by_validation",
      "malformed_proposal_response", "unknown_action_proposal"
    ),
    status = c(
      if (inherits(module_action, "aq_genai_action_definition")) "success" else "error",
      if (inherits(artifact_action, "aq_genai_action_definition")) "success" else "error",
      if (duplicate_error) "success" else "error",
      if (is.null(genai_action_registry_get("missing.action", registry))) "success" else "error",
      if (all(c("module.open", "artifact.inspect") %in% names(genai_action_registry_list(registry)))) "success" else "error",
      if (!"handler" %in% names(genai_action_registry_list(registry)[["artifact.inspect"]])) "success" else "error",
      if (identical(artifact_action$action_version, "1.0")) "success" else "error",
      if (identical(valid_validation$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(unknown_action)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(invalid_module)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(missing_arguments)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(extra_arguments)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(risk_mismatch)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(persistence)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(mutation)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(expired)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(corrupted)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(unsupported_version)$status, "error")) "success" else "error",
      if (identical(approval$status, "success") && identical(approval$value$status, "approved")) "success" else "error",
      if (identical(genai_reject_action_proposal(valid)$value$status, "rejected")) "success" else "error",
      if (identical(genai_approve_action_proposal(invalid_module, genai_validate_action_proposal(invalid_module))$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(modified_after_approval)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(expired)$status, "error")) "success" else "error",
      if (identical(self_approval$status, "error")) "success" else "error",
      if (identical(approved_execution$status, "success")) "success" else "error",
      if (identical(unapproved_execution$status, "error")) "success" else "error",
      if (identical(read_only_execution$status, "error")) "success" else "error",
      if (data.table::is.data.table(approved_execution$metadata$audit_event) && nrow(approved_execution$metadata$audit_event) == 1L) "success" else "error",
      if (isFALSE(approved_execution$value$persistent_changes)) "success" else "error",
      if (isTRUE(approved_execution$value$ui_state_changed) && isFALSE(approved_execution$value$project_state_changed)) "success" else "error",
      if (identical(artifact_validation$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_missing, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_empty, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_vector, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_malformed, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_path, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_url, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_extra, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_function_arg, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (isTRUE(artifact_validation$value$resource_resolution$current_project_match)) "success" else "error",
      if (identical(genai_validate_action_proposal(artifact_unknown, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(artifact_other_project_validation$status, "error")) "success" else "error",
      if (identical(artifact_deleted_validation$status, "error")) "success" else "error",
      if (identical(artifact_unavailable_validation$status, "error")) "success" else "error",
      if (identical(artifact_unsupported_validation$status, "error")) "success" else "error",
      if (identical(artifact_approval$value$approval_resource_fingerprint, artifact_validation$value$resource_fingerprint)) "success" else "error",
      if (identical(artifact_stale$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(artifact_rejected, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(artifact_cancelled, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(artifact_completed, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (identical(artifact_execution$status, "success")) "success" else "error",
      if (identical(artifact_ctx$selected$id, "artifact_qa_plot_001")) "success" else "error",
      if (identical(artifact_unapproved$status, "error")) "success" else "error",
      if (data.table::is.data.table(artifact_execution$metadata$audit_event) && all(c("artifact_id", "resource_fingerprint", "ui_state_changed") %in% names(artifact_execution$metadata$audit_event))) "success" else "error",
      if (identical(qa_artifact$metadata$artifact_version, "v1")) "success" else "error",
      if (isFALSE(artifact_execution$value$project_state_changed)) "success" else "error",
      if (isFALSE(artifact_execution$value$persistent_changes)) "success" else "error",
      if (isTRUE(artifact_execution$value$ui_state_changed) && isFALSE(artifact_execution$value$project_state_changed)) "success" else "error",
      if (identical(advisory_parse$status, "needs_input")) "success" else "error",
      if (identical(proposal_parse$status, "success")) "success" else "error",
      if (identical(artifact_parse$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(invented_artifact_parse$value, ctx = artifact_ctx)$status, "error")) "success" else "error",
      if (!identical(malformed_parse$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(unknown_action)$status, "error")) "success" else "error"
    ),
    message = c(
      "module.open is registered.", "artifact.inspect is registered.", "Duplicate ids are rejected.", "Unknown lookup returns NULL.", "Registered actions can be listed.",
      "Action metadata listing excludes executable handlers.", "artifact.inspect reports action_version 1.0.",
      "A well-formed proposal validates.", "Unknown action proposal fails.", "Unknown module fails.", "Missing arguments fail.",
      "Extra arguments fail.", "Risk understatement fails.", "Persistence requests fail.", "State mutation requests fail.",
      "Expired proposals fail.", "Corrupted hashes fail.", "Unsupported versions fail.", "Valid proposal can be approved.",
      "Proposal can be rejected.", "Invalid proposal cannot be approved.", "Modified approved proposal cannot execute.",
      "Expired proposal cannot execute.", "GenAI cannot self-approve.", "Approved module.open executes deterministically.",
      "Unapproved proposal cannot execute.", "Read-only mode cannot execute.", "Audit event is written.", "module.open records no persistent mutation.",
      "module.open reports UI state change without project mutation.", "Valid artifact id validates.", "Missing artifact_id fails.",
      "Empty artifact_id fails.", "Vector artifact_id fails.", "Malformed artifact_id fails.", "Path-like artifact_id fails.",
      "URL artifact_id fails.", "Model-supplied project id fails.", "Model-supplied callback/function argument fails.",
      "Artifact resolves in current project.", "Unknown artifact id fails.", "Cross-project artifact fails.",
      "Deleted artifact fails.", "Unavailable artifact fails.", "Unsupported artifact type fails.",
      "Approval is bound to resolved resource fingerprint.", "Changed artifact invalidates approval.",
      "Rejected proposal cannot execute.", "Cancelled proposal cannot execute.", "Completed proposal cannot execute twice.",
      "Approved artifact.inspect executes deterministically.", "Artifact Studio selection targets the expected id.",
      "Unapproved artifact.inspect cannot execute.", "Resource-scoped audit event is written.",
      "Artifact contents remain unchanged.", "artifact.inspect reports no project mutation.",
      "artifact.inspect reports no persistent change.", "artifact.inspect reports UI state change without project mutation.",
      "Advisory text without proposal remains safe.", "module.open proposal JSON is parsed.",
      "artifact.inspect proposal JSON is parsed.", "Invented artifact id is rejected by trusted validation.",
      "Malformed proposal is ignored safely.", "Unknown proposal is rejected by validation."
    )
  )
  report_rows <- data.table::data.table(
    check = c(
      "report_action_registration", "report_action_version", "listing_report_action",
      "report_valid_id", "report_missing_id", "report_empty_id", "report_vector_id", "report_malformed_id",
      "report_path_rejected", "report_url_rejected", "report_render_arg_rejected", "report_callback_arg_rejected",
      "report_resolves_current_project", "report_unknown_rejected", "report_cross_project_rejected",
      "report_deleted_rejected", "report_failed_rejected", "report_archived_rejected", "report_generating_rejected",
      "report_unsupported_rejected", "report_fingerprint_bound", "report_changed_invalidates_approval",
      "report_rejected_cannot_execute", "report_cancelled_cannot_execute", "report_completed_cannot_execute_twice",
      "report_approved_executes", "report_selected_expected_id", "report_unapproved_cannot_execute",
      "report_audit_record_written", "report_no_project_mutation", "report_no_persistent_change",
      "report_ui_state_semantics", "valid_report_proposal_response", "invented_report_rejected_by_validation",
      "module_state_semantics_regression", "artifact_state_semantics_regression", "report_state_semantics"
    ),
    status = c(
      if (inherits(report_action, "aq_genai_action_definition")) "success" else "error",
      if (identical(report_action$action_version, "1.0")) "success" else "error",
      if ("report.open" %in% names(genai_action_registry_list(registry))) "success" else "error",
      if (identical(report_validation$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_missing, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_empty, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_vector, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_malformed, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_path, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_url, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_extra, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(report_callback_arg, ctx = report_ctx)$status, "error")) "success" else "error",
      if (isTRUE(report_validation$value$resource_resolution$current_project_match)) "success" else "error",
      if (identical(genai_validate_action_proposal(report_unknown, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(report_other_project_validation$status, "error")) "success" else "error",
      if (identical(report_deleted_validation$status, "error")) "success" else "error",
      if (identical(report_failed_validation$status, "error")) "success" else "error",
      if (identical(report_archived_validation$status, "error")) "success" else "error",
      if (identical(report_generating_validation$status, "error")) "success" else "error",
      if (identical(report_unsupported_validation$status, "error")) "success" else "error",
      if (identical(report_approval$value$approval_resource_fingerprint, report_validation$value$resource_fingerprint)) "success" else "error",
      if (identical(report_stale$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(report_rejected, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(report_cancelled, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(report_completed, ctx = report_ctx)$status, "error")) "success" else "error",
      if (identical(report_execution$status, "success")) "success" else "error",
      if (identical(report_ctx$selected$id, "report_qa_diagnostics_001")) "success" else "error",
      if (identical(report_unapproved$status, "error")) "success" else "error",
      if (data.table::is.data.table(report_execution$metadata$audit_event) && all(c("report_id", "report_status", "render_status", "resource_fingerprint") %in% names(report_execution$metadata$audit_event))) "success" else "error",
      if (isFALSE(report_execution$value$project_state_changed)) "success" else "error",
      if (isFALSE(report_execution$value$persistent_changes)) "success" else "error",
      if (isTRUE(report_execution$value$ui_state_changed) && isFALSE(report_execution$value$project_state_changed)) "success" else "error",
      if (identical(report_parse$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(invented_report_parse$value, ctx = report_ctx)$status, "error")) "success" else "error",
      if (isTRUE(approved_execution$value$ui_state_changed) && isFALSE(approved_execution$value$project_state_changed) && isFALSE(approved_execution$value$persistent_changes)) "success" else "error",
      if (isTRUE(artifact_execution$value$ui_state_changed) && isFALSE(artifact_execution$value$project_state_changed) && isFALSE(artifact_execution$value$persistent_changes)) "success" else "error",
      if (isTRUE(report_execution$value$ui_state_changed) && isFALSE(report_execution$value$project_state_changed) && isFALSE(report_execution$value$persistent_changes)) "success" else "error"
    ),
    message = c(
      "report.open is registered.", "report.open reports action_version 1.0.", "Registered actions include report.open.",
      "Valid report id validates.", "Missing report_id fails.", "Empty report_id fails.", "Vector report_id fails.", "Malformed report_id fails.",
      "Path-like report_id fails.", "URL report_id fails.", "Rendering parameters fail.", "Callback/function arguments fail.",
      "Report resolves in current project.", "Unknown report id fails.", "Cross-project report fails.",
      "Deleted report fails.", "Failed rendered report fails.", "Archived report fails.", "Generating report fails.",
      "Unsupported report type fails.", "Approval is bound to resolved report fingerprint.", "Changed report invalidates approval.",
      "Rejected report proposal cannot execute.", "Cancelled report proposal cannot execute.", "Completed report proposal cannot execute twice.",
      "Approved report.open executes deterministically.", "Layout Studio selection targets the expected report id.", "Unapproved report.open cannot execute.",
      "Report-scoped audit event is written.", "report.open reports no project mutation.", "report.open reports no persistent change.",
      "report.open reports UI state change without project mutation.", "report.open proposal JSON is parsed.", "Invented report id is rejected by trusted validation.",
      "module.open state semantics remain UI-only.", "artifact.inspect state semantics remain UI-only.", "report.open state semantics are UI-only."
    )
  )
  preflight_rows <- data.table::data.table(
    check = c(
      "preflight_action_registration", "preflight_action_risk_medium", "preflight_metadata_excludes_handler",
      "preflight_valid_args", "preflight_missing_module_id", "preflight_missing_dataset_id", "preflight_empty_ids",
      "preflight_vector_ids", "preflight_path_rejected", "preflight_url_rejected", "preflight_extra_arg_rejected",
      "preflight_timeout_arg_rejected", "preflight_code_arg_rejected", "preflight_unknown_module_rejected",
      "preflight_unsupported_module_rejected", "preflight_unknown_dataset_rejected", "preflight_module_resolves",
      "preflight_dataset_resolves", "preflight_fingerprint_bound", "preflight_changed_schema_invalidates_approval",
      "preflight_unapproved_cannot_execute", "preflight_rejected_cannot_execute", "preflight_cancelled_cannot_execute",
      "preflight_completed_cannot_execute_twice", "preflight_approved_executes", "preflight_temporary_result_created",
      "preflight_no_project_mutation", "preflight_no_persistent_change", "preflight_computation_semantics",
      "preflight_empty_dataset_blocks", "preflight_zero_column_dataset_blocks", "preflight_constant_detected",
      "preflight_high_cardinality_detected", "preflight_missingness_detected", "preflight_identifier_detected",
      "preflight_limits_enforced", "preflight_cancel_returns_cancelled", "preflight_timeout_returns_timed_out",
      "preflight_audit_record_written", "preflight_result_no_raw_rows", "preflight_valid_proposal_response",
      "preflight_invented_dataset_rejected_by_validation"
    ),
    status = c(
      if (inherits(genai_action_registry_get("analysis.preflight", registry), "aq_genai_action_definition")) "success" else "error",
      if (identical(genai_action_registry_get("analysis.preflight", registry)$risk_tier, "medium")) "success" else "error",
      if (!"handler" %in% names(genai_action_registry_list(registry)[["analysis.preflight"]])) "success" else "error",
      if (identical(preflight_validation$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_missing_module, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_missing_dataset, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_empty_ids, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_vector_ids, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_path, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_url, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_extra, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_timeout_arg, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_code_arg, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_unknown_module, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_unsupported_module, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_validate_action_proposal(preflight_unknown_dataset, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(preflight_validation$value$resource_resolution$module_id, "autoquant_eda")) "success" else "error",
      if (identical(preflight_validation$value$resource_resolution$dataset_id, "active_dataset")) "success" else "error",
      if (identical(preflight_approval$value$approval_resource_fingerprint, preflight_validation$value$resource_fingerprint)) "success" else "error",
      if (identical(preflight_stale$status, "error")) "success" else "error",
      if (identical(preflight_unapproved$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(preflight_rejected, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(preflight_cancelled, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(genai_execute_action_proposal(preflight_completed, ctx = preflight_ctx)$status, "error")) "success" else "error",
      if (identical(preflight_execution$status, "success") && identical(preflight_execution$value$status, "succeeded")) "success" else "error",
      if (isTRUE(preflight_execution$value$temporary_result_created) && length(preflight_ctx$selected$stored) == 1L) "success" else "error",
      if (isFALSE(preflight_execution$value$project_state_changed)) "success" else "error",
      if (isFALSE(preflight_execution$value$persistent_changes)) "success" else "error",
      if (isTRUE(preflight_execution$value$computation_performed) && isTRUE(preflight_execution$value$temporary_result_created)) "success" else "error",
      if (identical(genai_execute_action_proposal(genai_approve_action_proposal(preflight_valid, preflight_empty_validation, "user")$value, ctx = preflight_empty_ctx)$value$outputs$readiness, "blocked")) "success" else "error",
      if (identical(genai_execute_action_proposal(genai_approve_action_proposal(preflight_valid, preflight_zero_col_validation, "user")$value, ctx = preflight_zero_col_ctx)$value$outputs$readiness, "blocked")) "success" else "error",
      if (any(vapply(preflight_execution$value$outputs$checks, function(x) identical(x$check_id, "constant_columns") && identical(x$status, "warning"), logical(1)))) "success" else "error",
      if (any(vapply(preflight_execution$value$outputs$checks, function(x) identical(x$check_id, "high_cardinality_fields") && identical(x$status, "warning"), logical(1)))) "success" else "error",
      if (any(vapply(preflight_execution$value$outputs$checks, function(x) identical(x$check_id, "missing_value_severity") && identical(x$status, "warning"), logical(1)))) "success" else "error",
      if (any(vapply(preflight_execution$value$outputs$checks, function(x) identical(x$check_id, "identifier_like_fields") && identical(x$status, "warning"), logical(1)))) "success" else "error",
      if (preflight_execution$value$rows_considered <= genai_preflight_limits()$max_rows_inspected && preflight_execution$value$columns_considered <= genai_preflight_limits()$max_columns_inspected) "success" else "error",
      if (identical(preflight_cancel_execution$value$status, "cancelled")) "success" else "error",
      if (identical(preflight_timeout_execution$value$status, "timed_out")) "success" else "error",
      if (data.table::is.data.table(preflight_execution$metadata$audit_event) && all(c("module_id", "dataset_id", "readiness", "preflight_result_id", "computation_performed") %in% names(preflight_execution$metadata$audit_event))) "success" else "error",
      if (!"full_table" %in% names(preflight_execution$value$outputs) && !"rows" %in% names(preflight_execution$value$outputs)) "success" else "error",
      if (identical(preflight_parse$status, "success")) "success" else "error",
      if (identical(genai_validate_action_proposal(invented_preflight_parse$value, ctx = preflight_ctx)$status, "error")) "success" else "error"
    ),
    message = c(
      "analysis.preflight is registered.", "analysis.preflight is medium risk.", "Action metadata hides executable handlers.",
      "Valid module and dataset ids validate.", "Missing module_id fails.", "Missing dataset_id fails.", "Empty ids fail.",
      "Vector ids fail.", "Path ids fail.", "URL ids fail.", "Extra arguments fail.",
      "Model-supplied timeout fails.", "Model-supplied code fails.", "Unknown module fails.",
      "Unsupported/deferred module fails.", "Unknown dataset fails.", "Module resolves through trusted registry.",
      "Dataset resolves through trusted active dataset.", "Approval is bound to composite resource fingerprint.", "Changed schema invalidates approval.",
      "Unapproved preflight cannot execute.", "Rejected preflight cannot execute.", "Cancelled preflight cannot execute.",
      "Completed preflight cannot execute twice.", "Approved preflight executes.", "Temporary result is created.",
      "No project mutation is reported.", "No persistent change is reported.", "Computation semantics are reported.",
      "Empty dataset blocks readiness.", "Zero-column dataset blocks readiness.", "Constant columns are detected.",
      "High-cardinality fields are detected.", "Missingness severity is detected.", "Identifier-like fields are detected.",
      "Trusted row/column limits are enforced.", "Cancellation returns cancelled.", "Timeout returns timed_out.",
      "Preflight audit event is written.", "Preflight result excludes raw rows.", "analysis.preflight proposal JSON is parsed.",
      "Invented dataset id is rejected by trusted validation."
    )
  )
  run_registered_rows <- qa_genai_registered_analysis_action()
  second_module_rows <- qa_genai_second_registered_analysis_module()
  binary_model_assessment_rows <- qa_genai_binary_model_assessment()
  isolated_execution_rows <- if (exists("qa_genai_isolated_execution", mode = "function")) qa_genai_isolated_execution() else data.table::data.table(check = "qa_genai_isolated_execution_available", status = "error", message = "qa_genai_isolated_execution() is not available.")
  result_persistence_rows <- qa_genai_result_persistence()
  rows <- data.table::rbindlist(list(rows, report_rows, preflight_rows, run_registered_rows, second_module_rows, binary_model_assessment_rows, isolated_execution_rows, result_persistence_rows), use.names = TRUE, fill = TRUE)
  rows
}
