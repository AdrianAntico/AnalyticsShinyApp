code_run_sources <- function() {
  c("manual", "genai", "module", "rerun")
}

code_run_statuses <- function() {
  c("draft", "pending_approval", "approved", "rejected", "running", "success", "warning", "error", "cancelled")
}

code_run_result_statuses <- function() {
  c("pending", "approved", "running", "success", "warning", "error", "cancelled")
}

executable_code_run_statuses <- function() {
  c("pending_approval", "approved", "running", "success", "warning", "error")
}

create_code_run_request <- function(
  run_id,
  label,
  code,
  source = "manual",
  execution_mode = "disabled",
  requested_outputs = character(),
  context = list(),
  requires_approval = FALSE,
  status = "draft",
  created_at = Sys.time(),
  updated_at = Sys.time()
) {
  structure(
    list(
      run_id = run_id,
      label = label,
      code = code,
      source = source,
      execution_mode = execution_mode,
      requested_outputs = requested_outputs,
      context = context,
      requires_approval = requires_approval,
      status = status,
      created_at = created_at,
      updated_at = updated_at
    ),
    class = c("aq_code_run_request", "list")
  )
}

validate_code_run_request <- function(request, policy = NULL) {
  errors <- character()

  if (!inherits(request, "aq_code_run_request") && !is.list(request)) {
    errors <- c(errors, "Code run request must be a list.")
  } else {
    if (!is.character(request$run_id) || length(request$run_id) != 1L || !nzchar(request$run_id)) {
      errors <- c(errors, "run_id must be a non-empty character value.")
    }
    if (!is.character(request$label) || length(request$label) != 1L || !nzchar(request$label)) {
      errors <- c(errors, "label must be a non-empty character value.")
    }
    if (!is.character(request$code) || length(request$code) < 1L || !nzchar(paste(request$code, collapse = "\n"))) {
      errors <- c(errors, "code must be non-empty.")
    }
    if (!request$source %in% code_run_sources()) {
      errors <- c(errors, paste("source must be one of:", paste(code_run_sources(), collapse = ", ")))
    }
    if (!request$execution_mode %in% code_execution_modes()) {
      errors <- c(errors, paste("execution_mode must be one of:", paste(code_execution_modes(), collapse = ", ")))
    }
    if (!request$status %in% code_run_statuses()) {
      errors <- c(errors, paste("status must be one of:", paste(code_run_statuses(), collapse = ", ")))
    }
    if (!is.logical(request$requires_approval) || length(request$requires_approval) != 1L || is.na(request$requires_approval)) {
      errors <- c(errors, "requires_approval must be TRUE or FALSE.")
    }

    if (!is.null(policy)) {
      policy_validation <- validate_code_execution_policy(policy)
      if (!identical(policy_validation$status, "success")) {
        errors <- c(errors, policy_validation$errors)
      } else if (request$status %in% executable_code_run_statuses()) {
        if (!isTRUE(policy$code_execution_enabled) || identical(policy$execution_mode, "disabled")) {
          errors <- c(errors, "Code execution is disabled by policy.")
        }
        if (identical(request$source, "manual") && !isTRUE(policy$allow_manual_code)) {
          errors <- c(errors, "Manual code execution is disabled by policy.")
        }
        if (identical(request$source, "genai") && !isTRUE(policy$allow_genai_code)) {
          errors <- c(errors, "GenAI code execution is disabled by policy.")
        }
      }
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      value = request,
      errors = errors,
      metadata = list(error_code = "CODE_RUN_REQUEST_INVALID")
    ))
  }

  service_result(
    status = "success",
    value = request,
    messages = "Code run request is valid.",
    metadata = list(
      run_id = request$run_id,
      source = request$source,
      execution_mode = request$execution_mode,
      request_status = request$status
    )
  )
}

create_code_run_result <- function(
  run_id,
  status = "pending",
  value = NULL,
  outputs = list(),
  artifacts = list(),
  artifact_ids = character(),
  logs = character(),
  warnings = character(),
  errors = character(),
  diagnostics = list(),
  started_at = NULL,
  ended_at = NULL,
  runtime_seconds = NA_real_,
  metadata = list()
) {
  structure(
    list(
      run_id = run_id,
      status = status,
      value = value,
      outputs = outputs,
      artifacts = artifacts,
      artifact_ids = artifact_ids,
      logs = logs,
      warnings = warnings,
      errors = errors,
      diagnostics = diagnostics,
      started_at = started_at,
      ended_at = ended_at,
      runtime_seconds = runtime_seconds,
      metadata = metadata
    ),
    class = c("aq_code_run_result", "list")
  )
}

code_hash_value <- function(code) {
  code_text <- paste(code, collapse = "\n")
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(code_text, algo = "sha256"))
  }

  ints <- utf8ToInt(code_text)
  if (!length(ints)) {
    return(NA_character_)
  }

  value <- sum(as.numeric(ints) * seq_along(ints)) %% 2147483647
  sprintf("fallback_%08x", as.integer(value))
}

create_code_tracker_record <- function(
  run_id,
  label,
  code,
  source = "manual",
  status = "draft",
  artifact_ids = character(),
  dataset_id = NULL,
  data_name = NULL,
  project_id = NULL,
  proposal_id = NULL,
  package_versions = list(),
  created_at = Sys.time(),
  started_at = NULL,
  ended_at = NULL,
  runtime_seconds = NA_real_,
  warnings_summary = character(),
  errors_summary = character(),
  metadata = list()
) {
  structure(
    list(
      run_id = run_id,
      label = label,
      code_hash = code_hash_value(code),
      code = code,
      source = source,
      status = status,
      artifact_ids = artifact_ids,
      dataset_id = dataset_id,
      data_name = data_name,
      project_id = project_id,
      proposal_id = proposal_id,
      package_versions = package_versions,
      created_at = created_at,
      started_at = started_at,
      ended_at = ended_at,
      runtime_seconds = runtime_seconds,
      warnings_summary = warnings_summary,
      errors_summary = errors_summary,
      metadata = metadata
    ),
    class = c("aq_code_tracker_record", "list")
  )
}

code_tracker_summary <- function(records) {
  if (is.null(records) || !length(records)) {
    return(data.table::data.table(
      run_id = character(),
      label = character(),
      source = character(),
      status = character(),
      data_name = character(),
      n_artifacts = integer(),
      created_at = as.POSIXct(character()),
      runtime_seconds = numeric(),
      has_warnings = logical(),
      has_errors = logical()
    ))
  }

  if (inherits(records, "aq_code_tracker_record")) {
    records <- list(records)
  }

  rows <- lapply(records, function(record) {
    data.table::data.table(
      run_id = record$run_id %||% NA_character_,
      label = record$label %||% NA_character_,
      source = record$source %||% NA_character_,
      status = record$status %||% NA_character_,
      data_name = record$data_name %||% NA_character_,
      n_artifacts = length(record$artifact_ids %||% character()),
      created_at = record$created_at %||% as.POSIXct(NA),
      runtime_seconds = as.numeric(record$runtime_seconds %||% NA_real_),
      has_warnings = length(record$warnings_summary %||% character()) > 0L,
      has_errors = length(record$errors_summary %||% character()) > 0L
    )
  })

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

duplicate_code_run_request <- function(
  request,
  run_id,
  label = NULL,
  source = "rerun",
  status = "draft",
  parent_run_id = NULL,
  created_at = Sys.time()
) {
  context <- request$context %||% list()
  context$parent_run_id <- parent_run_id %||% request$run_id %||% NULL

  create_code_run_request(
    run_id = run_id,
    label = label %||% paste0(request$label %||% request$run_id, " Copy"),
    code = request$code %||% "",
    source = source,
    execution_mode = request$execution_mode %||% "disabled",
    requested_outputs = request$requested_outputs %||% character(),
    context = context,
    requires_approval = request$requires_approval %||% FALSE,
    status = status,
    created_at = created_at,
    updated_at = created_at
  )
}

update_code_tracker_record_metadata <- function(record, label = NULL, notes = NULL, metadata = list()) {
  record$label <- label %||% record$label
  record$metadata <- record$metadata %||% list()
  if (!is.null(notes)) {
    record$metadata$notes <- notes
  }
  for (name in names(metadata)) {
    record$metadata[[name]] <- metadata[[name]]
  }
  record
}

qa_code_runner_model <- function() {
  disabled_policy <- create_code_execution_policy()
  disabled_validation <- validate_code_execution_policy(disabled_policy)

  trusted_policy <- create_code_execution_policy(
    code_execution_enabled = TRUE,
    execution_mode = "local_trusted",
    allow_manual_code = TRUE,
    allow_file_read = TRUE,
    max_runtime_seconds = 60,
    max_memory_mb = 2048,
    allowed_packages = c("data.table", "AutoPlots")
  )
  trusted_validation <- validate_code_execution_policy(trusted_policy)

  request <- create_code_run_request(
    run_id = "code_run_qa_001",
    label = "QA Code Run",
    code = "summary(data)",
    source = "manual",
    execution_mode = "local_trusted",
    requested_outputs = "summary",
    context = list(data_name = "qa_data"),
    status = "approved"
  )
  request_validation <- validate_code_run_request(request, trusted_policy)

  result <- create_code_run_result(
    run_id = request$run_id,
    status = "success",
    outputs = list(summary = "not executed in foundation QA"),
    artifact_ids = "qa_artifact_1",
    logs = "Foundation object construction only.",
    started_at = Sys.time(),
    ended_at = Sys.time(),
    runtime_seconds = 0
  )

  record <- create_code_tracker_record(
    run_id = request$run_id,
    label = request$label,
    code = request$code,
    source = request$source,
    status = result$status,
    artifact_ids = result$artifact_ids,
    data_name = request$context$data_name,
    started_at = result$started_at,
    ended_at = result$ended_at,
    runtime_seconds = result$runtime_seconds
  )

  summary <- code_tracker_summary(list(record))
  summary[, policy_valid := identical(disabled_validation$status, "success") && identical(trusted_validation$status, "success")]
  summary[, request_valid := identical(request_validation$status, "success")]
  summary
}
