custom_code_hook_stages <- function() {
  c(
    "data",
    "eda",
    "feature_engineering",
    "feature_engineering_model_prep",
    "model_prep",
    "model_readiness",
    "plot_builder",
    "artifact_library",
    "layouts",
    "analysis_modules",
    "catboost_builder",
    "model_assessment",
    "model_insights",
    "shap_analysis",
    "shap_insights",
    "code_runner",
    "export",
    "report_export",
    "project",
    "settings"
  )
}

custom_code_hook_timings <- function() {
  c("pre_stage", "post_stage", "standalone")
}

custom_code_hook_output_types <- function() {
  c("dataset", "plot", "table", "text", "metric", "handoff_notes")
}

normalize_custom_code_hook_stage <- function(stage) {
  stage <- selected_value(stage)
  if (is.null(stage) || !nzchar(stage)) {
    return(NULL)
  }

  stage <- gsub("-", "_", tolower(stage), fixed = TRUE)
  stage <- gsub(" ", "_", stage, fixed = TRUE)
  stage
}

normalize_custom_code_hook_timing <- function(timing) {
  timing <- selected_value(timing)
  if (is.null(timing) || !nzchar(timing)) {
    return(NULL)
  }

  timing <- gsub("-", "_", tolower(timing), fixed = TRUE)
  timing <- gsub(" ", "_", timing, fixed = TRUE)
  timing
}

create_custom_code_hook_request <- function(
  run_id,
  stage,
  timing = c("pre_stage", "post_stage", "standalone"),
  label = NULL,
  code = "",
  requested_outputs = custom_code_hook_output_types(),
  data_name = NULL,
  context = list(),
  status = "draft",
  execution_mode = "disabled",
  created_at = Sys.time()
) {
  stage <- normalize_custom_code_hook_stage(stage)
  timing <- normalize_custom_code_hook_timing(timing)

  hook_context <- context %||% list()
  hook_context$custom_code_hook <- TRUE
  hook_context$workflow_stage <- stage
  hook_context$hook_timing <- timing
  hook_context$data_name <- data_name %||% hook_context$data_name
  hook_context$auto_run <- FALSE

  request <- create_code_run_request(
    run_id = run_id,
    label = label %||% paste("Custom code", timing, "for", stage),
    code = code,
    source = "manual",
    execution_mode = execution_mode,
    requested_outputs = intersect(requested_outputs, custom_code_hook_output_types()),
    context = hook_context,
    requires_approval = FALSE,
    status = status,
    created_at = created_at,
    updated_at = created_at
  )
  request$metadata <- hook_context
  request
}

validate_custom_code_hook_request <- function(request, policy = NULL) {
  validation <- validate_code_run_request(request, policy = NULL)
  if (!identical(validation$status, "success")) {
    return(validation)
  }

  errors <- character()
  warnings <- character()
  context <- request$context %||% list()
  stage <- normalize_custom_code_hook_stage(context$workflow_stage)
  timing <- normalize_custom_code_hook_timing(context$hook_timing)

  if (!isTRUE(context$custom_code_hook)) {
    errors <- c(errors, "Custom code hook requests must include context$custom_code_hook = TRUE.")
  }
  if (is.null(stage) || !stage %in% custom_code_hook_stages()) {
    errors <- c(errors, paste("workflow_stage must be one of:", paste(custom_code_hook_stages(), collapse = ", ")))
  }
  if (is.null(timing) || !timing %in% custom_code_hook_timings()) {
    errors <- c(errors, paste("hook_timing must be one of:", paste(custom_code_hook_timings(), collapse = ", ")))
  }
  if (!identical(request$source, "manual")) {
    errors <- c(errors, "Custom code hooks must use Code Runner manual execution so trusted/local controls apply.")
  }
  if (isTRUE(context$auto_run)) {
    errors <- c(errors, "Custom code hooks must not auto-run.")
  }
  if (identical(request$status, "running")) {
    errors <- c(errors, "Custom code hook requests must be created as drafts or approvals, not running jobs.")
  }
  if (!is.null(policy) && request$status %in% executable_code_run_statuses()) {
    policy_validation <- validate_code_run_request(request, policy)
    if (!identical(policy_validation$status, "success")) {
      warnings <- c(warnings, policy_validation$errors)
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      value = request,
      warnings = warnings,
      errors = errors,
      metadata = list(error_code = "CUSTOM_CODE_HOOK_INVALID")
    ))
  }

  service_result(
    status = if (length(warnings)) "warning" else "success",
    value = request,
    messages = "Custom code hook request is valid.",
    warnings = warnings,
    metadata = list(
      run_id = request$run_id,
      workflow_stage = stage,
      hook_timing = timing,
      auto_run = FALSE
    )
  )
}

custom_code_hook_summary <- function(records) {
  summary <- code_tracker_summary(records)
  if (!nrow(summary)) {
    summary[, `:=`(
      workflow_stage = character(),
      hook_timing = character(),
      is_custom_code_hook = logical()
    )]
    return(summary)
  }

  rows <- lapply(records, function(record) {
    metadata <- record$metadata %||% list()
    data.table::data.table(
      run_id = record$run_id %||% NA_character_,
      workflow_stage = metadata$workflow_stage %||% metadata$context$workflow_stage %||% NA_character_,
      hook_timing = metadata$hook_timing %||% metadata$context$hook_timing %||% NA_character_,
      is_custom_code_hook = isTRUE(metadata$custom_code_hook) || isTRUE(metadata$context$custom_code_hook)
    )
  })

  hook_info <- data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
  hook_info[summary, on = "run_id"]
}

qa_custom_code_hooks <- function() {
  request <- create_custom_code_hook_request(
    run_id = "qa_custom_code_hook_001",
    stage = "catboost_builder",
    timing = "post_stage",
    label = "Inspect CatBoost scored output",
    code = "data.table::data.table(note = 'handoff review')",
    requested_outputs = c("table", "handoff_notes"),
    data_name = "qa_data"
  )
  validation <- validate_custom_code_hook_request(request)

  policy <- create_code_execution_policy(
    code_execution_enabled = TRUE,
    execution_mode = "local_trusted",
    allow_manual_code = TRUE
  )
  execution_validation <- validate_custom_code_hook_request(
    within(request, {
      status <- "approved"
      execution_mode <- "local_trusted"
    }),
    policy = policy
  )

  invalid_auto_run <- validate_custom_code_hook_request(
    within(request, {
      context$auto_run <- TRUE
    })
  )

  data.table::data.table(
    check = c("draft_valid", "approved_uses_policy", "auto_run_blocked", "source_manual"),
    passed = c(
      identical(validation$status, "success"),
      execution_validation$status %in% c("success", "warning"),
      identical(invalid_auto_run$status, "error"),
      identical(request$source, "manual")
    ),
    detail = c(
      validation$messages %||% "",
      paste(execution_validation$warnings %||% character(), collapse = " | "),
      paste(invalid_auto_run$errors %||% character(), collapse = " | "),
      "Custom hooks reuse manual Code Runner execution."
    )
  )
}
