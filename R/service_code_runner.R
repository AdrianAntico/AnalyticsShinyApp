.code_runner_blocked_functions <- function(code, blocked_functions) {
  code <- paste(code, collapse = "\n")
  blocked_functions <- blocked_functions[nzchar(blocked_functions)]
  blocked_functions[vapply(blocked_functions, function(fn) {
    grepl(paste0(fn, "("), code, fixed = TRUE) ||
      grepl(paste0(fn, " ("), code, fixed = TRUE)
  }, logical(1))]
}

.code_runner_value_summary <- function(value) {
  if (is.null(value)) {
    return("NULL")
  }

  paste(utils::capture.output(utils::str(value, max.level = 2, give.attr = FALSE)), collapse = "\n")
}

.code_runner_context_env <- function(data_context, artifact_context, envir = NULL) {
  if (is.null(envir)) {
    envir <- new.env(parent = baseenv())
  }

  if (!is.null(data_context$data)) {
    assign("data", data_context$data, envir = envir)
  }
  if (!is.null(artifact_context$artifacts)) {
    assign("artifacts", artifact_context$artifacts, envir = envir)
  }

  assign("data.table", data.table::data.table, envir = envir)
  assign("as.data.table", data.table::as.data.table, envir = envir)
  assign("AutoPlots", asNamespace("AutoPlots"), envir = envir)
  if (requireNamespace("AutoQuant", quietly = TRUE)) {
    assign("AutoQuant", asNamespace("AutoQuant"), envir = envir)
  }

  envir
}

run_code_local_trusted <- function(
  request,
  data_context = list(),
  artifact_context = list(),
  policy = create_code_execution_policy(),
  envir = NULL
) {
  policy_validation <- validate_code_execution_policy(policy)
  if (!identical(policy_validation$status, "success")) {
    return(service_result(
      status = "error",
      errors = policy_validation$errors,
      metadata = list(error_code = "CODE_EXECUTION_POLICY_INVALID")
    ))
  }

  request$status <- "running"
  request$execution_mode <- policy$execution_mode
  request_validation <- validate_code_run_request(request, policy)
  if (!identical(request_validation$status, "success")) {
    return(service_result(
      status = "error",
      value = create_code_run_result(
        run_id = request$run_id %||% NA_character_,
        status = "error",
        errors = request_validation$errors
      ),
      errors = request_validation$errors,
      metadata = list(error_code = "CODE_RUN_REQUEST_INVALID")
    ))
  }

  errors <- character()
  if (!isTRUE(policy$code_execution_enabled)) {
    errors <- c(errors, "Code execution is disabled by policy.")
  }
  if (!identical(policy$execution_mode, "local_trusted")) {
    errors <- c(errors, "Only local_trusted execution is implemented.")
  }
  if (identical(request$source, "genai")) {
    errors <- c(errors, "GenAI code execution is not implemented.")
  }
  if (request$source %in% c("manual", "rerun") && !isTRUE(policy$allow_manual_code)) {
    errors <- c(errors, "Manual code execution is disabled by policy.")
  }

  blocked <- .code_runner_blocked_functions(request$code, policy$blocked_functions %||% character())
  if (length(blocked)) {
    errors <- c(errors, paste("Code contains blocked function:", blocked[[1]]))
  }

  if (length(errors)) {
    result <- create_code_run_result(
      run_id = request$run_id,
      status = "error",
      errors = errors,
      diagnostics = list(blocked_functions = blocked),
      metadata = list(execution_mode = policy$execution_mode)
    )
    return(service_result(
      status = "error",
      value = result,
      errors = errors,
      metadata = list(error_code = "CODE_RUN_BLOCKED", run_id = request$run_id)
    ))
  }

  # Trusted local execution only. This is not a sandbox; the policy checks above
  # are guardrails for the app workflow, not a security boundary.
  run_env <- .code_runner_context_env(data_context, artifact_context, envir)
  warnings <- character()
  printed <- character()
  value <- NULL
  started_at <- Sys.time()
  ended_at <- NULL
  runtime_seconds <- NA_real_

  execution <- tryCatch(
    {
      printed <- utils::capture.output({
        value <- withCallingHandlers(
          {
            expressions <- parse(text = paste(request$code, collapse = "\n"))
            last_value <- NULL
            for (expr in expressions) {
              last_value <- eval(expr, envir = run_env)
            }
            last_value
          },
          warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
          }
        )
      }, type = "output")
      list(status = "success", error = NULL)
    },
    error = function(e) {
      list(status = "error", error = e)
    }
  )

  ended_at <- Sys.time()
  runtime_seconds <- as.numeric(difftime(ended_at, started_at, units = "secs"))

  if (identical(execution$status, "error")) {
    result <- create_code_run_result(
      run_id = request$run_id,
      status = "error",
      value = NULL,
      outputs = list(printed = printed),
      logs = printed,
      warnings = warnings,
      errors = conditionMessage(execution$error),
      diagnostics = list(
        call = if (!is.null(execution$error$call)) paste(deparse(execution$error$call), collapse = "\n") else NULL
      ),
      started_at = started_at,
      ended_at = ended_at,
      runtime_seconds = runtime_seconds,
      metadata = list(
        execution_mode = "local_trusted",
        trusted_local_execution = TRUE,
        value_summary = "Execution failed before returning a value."
      )
    )
    return(service_result(
      status = "error",
      value = result,
      errors = result$errors,
      warnings = warnings,
      diagnostics = result$diagnostics,
      metadata = list(run_id = request$run_id)
    ))
  }

  result_status <- if (length(warnings)) "warning" else "success"
  result <- create_code_run_result(
    run_id = request$run_id,
    status = result_status,
    value = value,
    outputs = list(printed = printed),
    logs = printed,
    warnings = warnings,
    errors = character(),
    started_at = started_at,
    ended_at = ended_at,
    runtime_seconds = runtime_seconds,
    metadata = list(
      execution_mode = "local_trusted",
      trusted_local_execution = TRUE,
      value_summary = .code_runner_value_summary(value)
    )
  )

  service_result(
    status = if (identical(result_status, "success")) "success" else "warning",
    value = result,
    messages = paste("Code run completed with status:", result_status),
    warnings = warnings,
    metadata = list(run_id = request$run_id)
  )
}

code_run_result_summary <- function(result) {
  if (is.null(result)) {
    return(NULL)
  }

  create_code_run_result(
    run_id = result$run_id,
    status = result$status,
    value = NULL,
    outputs = result$outputs %||% list(),
    artifacts = list(),
    artifact_ids = result$artifact_ids %||% character(),
    logs = result$logs %||% character(),
    warnings = result$warnings %||% character(),
    errors = result$errors %||% character(),
    diagnostics = result$diagnostics %||% list(),
    started_at = result$started_at,
    ended_at = result$ended_at,
    runtime_seconds = result$runtime_seconds,
    metadata = result$metadata %||% list()
  )
}

qa_code_runner_local_trusted <- function() {
  policy <- create_code_execution_policy(
    code_execution_enabled = TRUE,
    execution_mode = "local_trusted",
    allow_manual_code = TRUE
  )

  success_request <- create_code_run_request(
    run_id = "qa_code_success",
    label = "Success",
    code = "x <- 1 + 1; x",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  success_result <- run_code_local_trusted(success_request, policy = policy)

  warning_request <- create_code_run_request(
    run_id = "qa_code_warning",
    label = "Warning",
    code = "warning('careful'); 3",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  warning_result <- run_code_local_trusted(warning_request, policy = policy)

  error_request <- create_code_run_request(
    run_id = "qa_code_error",
    label = "Error",
    code = "stop('boom')",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  error_result <- run_code_local_trusted(error_request, policy = policy)

  blocked_request <- create_code_run_request(
    run_id = "qa_code_blocked",
    label = "Blocked",
    code = "system('echo hi')",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  blocked_result <- run_code_local_trusted(blocked_request, policy = policy)

  table_request <- create_code_run_request(
    run_id = "qa_code_table",
    label = "Table",
    code = "data.table(a = 1:3)",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  table_result <- run_code_local_trusted(table_request, policy = policy)
  table_record <- create_code_tracker_record(
    run_id = table_request$run_id,
    label = table_request$label,
    code = table_request$code,
    source = table_request$source,
    status = table_result$value$status %||% "error"
  )
  candidates <- if (inherits(table_result$value, "aq_code_run_result")) {
    code_output_to_artifact_candidates(table_result$value$value, table_record)
  } else {
    list()
  }

  data.table::data.table(
    check = c(
      "success_value",
      "warning_captured",
      "error_captured",
      "blocked_function",
      "table_artifact_candidate"
    ),
    status = c(
      if (identical(success_result$status, "success") && identical(success_result$value$value, 2)) "success" else "error",
      if (identical(warning_result$status, "warning") && length(warning_result$value$warnings)) "success" else "error",
      if (identical(error_result$status, "error") && length(error_result$value$errors)) "success" else "error",
      if (identical(blocked_result$status, "error") && grepl("blocked function", paste(blocked_result$errors, collapse = " "), ignore.case = TRUE)) "success" else "error",
      if (length(candidates) == 1L && identical(candidates[[1]]$artifact_type, "table")) "success" else "error"
    ),
    message = c(
      paste("Value:", success_result$value$value %||% NA),
      paste(warning_result$value$warnings %||% character(), collapse = " "),
      paste(error_result$value$errors %||% character(), collapse = " "),
      paste(blocked_result$errors %||% character(), collapse = " "),
      paste("Candidates:", length(candidates))
    )
  )
}

qa_code_runner_history_workflow <- function() {
  policy <- create_code_execution_policy(
    code_execution_enabled = TRUE,
    execution_mode = "local_trusted",
    allow_manual_code = TRUE
  )

  original_request <- create_code_run_request(
    run_id = "qa_history_original",
    label = "History Original",
    code = "1 + 1",
    source = "manual",
    execution_mode = "local_trusted",
    status = "running"
  )
  original_result <- run_code_local_trusted(original_request, policy = policy)
  original_record <- create_code_tracker_record(
    run_id = original_request$run_id,
    label = original_request$label,
    code = original_request$code,
    source = original_request$source,
    status = original_result$value$status,
    started_at = original_result$value$started_at,
    ended_at = original_result$value$ended_at,
    runtime_seconds = original_result$value$runtime_seconds
  )
  original_snapshot <- original_record

  duplicate_request <- duplicate_code_run_request(
    request = original_request,
    run_id = "qa_history_duplicate",
    parent_run_id = original_request$run_id
  )
  duplicate_record <- create_code_tracker_record(
    run_id = duplicate_request$run_id,
    label = duplicate_request$label,
    code = duplicate_request$code,
    source = duplicate_request$source,
    status = duplicate_request$status,
    metadata = list(parent_run_id = original_request$run_id)
  )
  duplicate_record <- update_code_tracker_record_metadata(
    duplicate_record,
    notes = "Duplicated for QA."
  )

  rerun_request <- duplicate_code_run_request(
    request = original_request,
    run_id = "qa_history_rerun",
    label = "History Original Rerun",
    source = "rerun",
    status = "running",
    parent_run_id = original_request$run_id
  )
  rerun_result <- run_code_local_trusted(rerun_request, policy = policy)
  rerun_record <- create_code_tracker_record(
    run_id = rerun_request$run_id,
    label = rerun_request$label,
    code = rerun_request$code,
    source = rerun_request$source,
    status = rerun_result$value$status,
    started_at = rerun_result$value$started_at,
    ended_at = rerun_result$value$ended_at,
    runtime_seconds = rerun_result$value$runtime_seconds,
    metadata = list(parent_run_id = original_request$run_id)
  )

  failed_rerun_request <- duplicate_code_run_request(
    request = original_request,
    run_id = "qa_history_failed_rerun",
    label = "History Original Failed Rerun",
    source = "rerun",
    status = "running",
    parent_run_id = original_request$run_id
  )
  failed_rerun_request$code <- "stop('rerun failed')"
  failed_rerun_result <- run_code_local_trusted(failed_rerun_request, policy = policy)
  failed_rerun_record <- create_code_tracker_record(
    run_id = failed_rerun_request$run_id,
    label = failed_rerun_request$label,
    code = failed_rerun_request$code,
    source = failed_rerun_request$source,
    status = failed_rerun_result$value$status,
    started_at = failed_rerun_result$value$started_at,
    ended_at = failed_rerun_result$value$ended_at,
    runtime_seconds = failed_rerun_result$value$runtime_seconds,
    errors_summary = failed_rerun_result$value$errors,
    metadata = list(parent_run_id = original_request$run_id)
  )

  records <- list(
    original = original_record,
    duplicate = duplicate_record,
    rerun = rerun_record,
    failed_rerun = failed_rerun_record
  )
  summary <- code_tracker_summary(records)

  data.table::data.table(
    check = c(
      "duplicate_created",
      "rerun_new_run_id",
      "parent_run_id",
      "original_unchanged",
      "summary_includes_runs",
      "notes_stored",
      "failed_rerun_preserved"
    ),
    status = c(
      if (identical(duplicate_request$status, "draft") && identical(duplicate_request$code, original_request$code)) "success" else "error",
      if (!identical(rerun_request$run_id, original_request$run_id) && identical(rerun_result$status, "success")) "success" else "error",
      if (identical(rerun_record$metadata$parent_run_id, original_request$run_id)) "success" else "error",
      if (identical(original_record$run_id, original_snapshot$run_id) && identical(original_record$status, original_snapshot$status)) "success" else "error",
      if (nrow(summary) == 4L) "success" else "error",
      if (identical(duplicate_record$metadata$notes, "Duplicated for QA.")) "success" else "error",
      if (identical(failed_rerun_record$status, "error") && length(failed_rerun_record$errors_summary)) "success" else "error"
    ),
    message = c(
      duplicate_request$run_id,
      rerun_request$run_id,
      rerun_record$metadata$parent_run_id,
      "Original record preserved.",
      paste("Summary rows:", nrow(summary)),
      duplicate_record$metadata$notes,
      paste(failed_rerun_record$errors_summary, collapse = " ")
    )
  )
}
