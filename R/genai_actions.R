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
      reversible = isTRUE(reversible),
      approval_required = isTRUE(approval_required),
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
    source_name = info$name %||% NA_character_
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
  preflight <- tryCatch(
    genai_run_generic_preflight(
      module_resolution = resolution$value,
      dataset_resolution = list(
      dataset_id = resolution$value$dataset_id,
      display_name = resolution$value$dataset_display_name,
      active_project_id = resolution$value$active_project_id,
      available = identical(resolution$value$dataset_availability, "available"),
      availability = resolution$value$dataset_availability,
      row_count = resolution$value$row_count,
      column_count = resolution$value$column_count
    ),
      data = data,
      limits = limits,
      cancel_requested = cancel_fun
    ),
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
    configuration_requirements = list(required_roles = resolution$value$required_roles %||% character()),
    data_summary = list(row_count = resolution$value$row_count, column_count = resolution$value$column_count)
  )
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
      reversible = isTRUE(action$reversible),
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

  if (isTRUE(proposal$persistence_requested)) {
    errors <- c(errors, "Persistence is not allowed for Phase 1 GenAI actions.")
  }
  if (length(proposal$state_mutations %||% list())) {
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
    cancel_requested = isTRUE(execution$cancel_requested),
    timed_out = isTRUE(execution$timed_out),
    computation_performed = isTRUE(execution$computation_performed),
    temporary_result_created = isTRUE(execution$temporary_result_created),
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
  action <- genai_action_registry_get(proposal$action_id, registry)
  handler_result <- tryCatch(
    action$handler(proposal$arguments, ctx = ctx),
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
    cancel_requested = isTRUE(handler_result$metadata$cancel_requested %||% FALSE),
    timed_out = isTRUE(handler_result$metadata$timed_out %||% FALSE),
    computation_performed = isTRUE(handler_result$metadata$computation_performed %||% FALSE),
    temporary_result_created = isTRUE(handler_result$metadata$temporary_result_created %||% FALSE),
    resource_fingerprint = handler_result$metadata$resource_fingerprint %||% validation$value$resource_fingerprint %||% NA_character_
  )
  proposal$status <- execution$status
  service_result(
    status = handler_result$status,
    value = execution,
    messages = execution$message,
    warnings = execution$warnings,
    errors = execution$errors,
    metadata = list(audit_event = genai_action_audit_event(proposal, execution, validation), validation = validation)
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
  } else if (identical(proposal$action_id %||% "", "analysis.preflight")) {
    paste(resource$display_name %||% proposal$arguments$module_id %||% "Unknown module", "->", resource$dataset_display_name %||% proposal$arguments$dataset_id %||% "Unknown dataset")
  } else {
    module$label %||% module_id %||% "Unknown"
  }
  target_kind <- if (identical(proposal$action_id %||% "", "artifact.inspect")) {
    "Target artifact"
  } else if (identical(proposal$action_id %||% "", "report.open")) {
    "Target report"
  } else if (identical(proposal$action_id %||% "", "analysis.preflight")) {
    "Preflight target"
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
      tags$dt("Rationale"), tags$dd(proposal$rationale %||% "No rationale supplied."),
      tags$dt("Expected effect"), tags$dd(paste(proposal$expected_effects %||% "Open selected module", collapse = "; ")),
      tags$dt("Evidence"), tags$dd(paste(proposal$evidence_refs %||% "Not supplied", collapse = "; ")),
      tags$dt("Risk"), tags$dd(proposal$risk_tier %||% "unknown"),
      tags$dt("Persistence"), tags$dd(if (isTRUE(proposal$persistence_requested)) "Requested" else "Not requested"),
      tags$dt("UI state change"), tags$dd("Yes, after approval"),
      tags$dt("Project mutation"), tags$dd("No"),
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
    tags$div(
      class = "aq-genai-proposal-actions",
      actionButton(ns("approve_proposal"), "Approve", class = "btn-primary btn-sm", disabled = if (!valid) "disabled" else NULL),
      actionButton(ns("reject_proposal"), "Reject", class = "btn-secondary btn-sm"),
      actionButton(ns("cancel_proposal"), "Cancel", class = "btn-secondary btn-sm")
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
  rows <- data.table::rbindlist(list(rows, report_rows, preflight_rows), use.names = TRUE, fill = TRUE)
  rows
}
