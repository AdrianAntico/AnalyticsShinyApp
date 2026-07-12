genai_job_record_schema_version <- function() "genai_job_record_v1"
genai_worker_request_schema_version <- function() "genai_worker_request_v1"
genai_worker_result_schema_version <- function() "genai_worker_result_v1"
genai_progress_event_schema_version <- function() "genai_progress_event_v1"
genai_dataset_snapshot_schema_version <- function() "genai_dataset_snapshot_v1"
genai_recovery_state_schema_version <- function() "genai_recovery_state_v1"

genai_isolated_worker_backend <- function() "callr"

genai_job_statuses <- function() {
  c(
    "created", "queued", "starting", "running", "cancel_requested", "cancelling",
    "cancelled", "timed_out", "succeeded", "failed", "orphaned", "recoverable",
    "recovered", "discarded"
  )
}

genai_job_terminal_statuses <- function() {
  c("cancelled", "timed_out", "succeeded", "failed", "orphaned", "recovered", "discarded")
}

genai_job_transition_map <- function() {
  list(
    created = c("queued", "starting", "discarded", "failed"),
    queued = c("starting", "running", "cancel_requested", "cancelled", "timed_out", "failed", "orphaned"),
    starting = c("running", "cancel_requested", "cancelling", "cancelled", "timed_out", "failed", "orphaned"),
    running = c("cancel_requested", "cancelling", "cancelled", "timed_out", "succeeded", "failed", "orphaned", "recoverable"),
    cancel_requested = c("cancelling", "cancelled", "timed_out", "failed"),
    cancelling = c("cancelled", "timed_out", "failed"),
    recoverable = c("recovered", "failed", "discarded"),
    cancelled = character(),
    timed_out = character(),
    succeeded = c("recovered"),
    failed = character(),
    orphaned = character(),
    recovered = character(),
    discarded = character()
  )
}

genai_job_transition_valid <- function(from, to) {
  from <- as.character(from %||% "")
  to <- as.character(to %||% "")
  if (!from %in% genai_job_statuses() || !to %in% genai_job_statuses()) return(FALSE)
  to %in% (genai_job_transition_map()[[from]] %||% character())
}

genai_job_safe_status_transition <- function(job, status) {
  old <- job$status %||% "created"
  if (identical(old, status)) return(service_result(status = "success", value = job))
  if (!genai_job_transition_valid(old, status)) {
    return(service_result(
      status = "error",
      errors = paste("Invalid GenAI job transition:", old, "->", status),
      value = job,
      metadata = list(from = old, to = status)
    ))
  }
  job$status <- status
  service_result(status = "success", value = job)
}

genai_job_event_types <- function() {
  c(
    "job_created", "job_queued", "worker_started", "job_progress_checkpoint",
    "cancel_requested", "worker_terminated", "job_cancelled", "job_timed_out",
    "job_failed", "job_succeeded", "job_orphaned", "job_recovered",
    "result_handoff_rejected", "temporary_result_reconstructed"
  )
}

genai_worker_supported_handlers <- function() {
  c("dataset_profile", "model_assessment_regression", "model_assessment_binary")
}

genai_worker_handler_id <- function(module_id, mode_id = NA_character_, result_type = NULL) {
  result_type <- result_type %||% genai_module_result_type(module_id, list(task_type = mode_id))
  if (identical(module_id, "dataset_profile")) return("dataset_profile")
  if (identical(module_id, genai_registered_analysis_second_module_id()) && identical(mode_id, "regression")) return("model_assessment_regression")
  if (identical(module_id, genai_registered_analysis_second_module_id()) && identical(mode_id, "binary_classification")) return("model_assessment_binary")
  result_type %||% "unsupported"
}

genai_worker_handler_enabled <- function(handler_id) {
  handler_id %in% genai_worker_supported_handlers()
}

genai_job_id <- function(prefix = "genai_job") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sprintf("%06d", sample.int(999999L, 1L)))
}

genai_worker_request_allowed_fields <- function() {
  c(
    "worker_request_schema_version", "job_id", "action_id", "handler_id",
    "module_id", "module_version", "mode_id", "result_type", "dataset_snapshot",
    "dataset_snapshot_metadata", "module_resolution", "dataset_resolution",
    "configuration_snapshot", "preflight_summary", "resource_limits",
    "execution_seed", "requested_outputs", "execution_fingerprint",
    "output_contract_version", "progress_path", "result_path", "error_path",
    "runtime_dir"
  )
}

genai_worker_request_required_fields <- function() {
  c(
    "worker_request_schema_version", "job_id", "action_id", "handler_id",
    "module_id", "result_type", "dataset_snapshot", "dataset_snapshot_metadata",
    "configuration_snapshot", "resource_limits", "execution_fingerprint",
    "progress_path", "result_path", "runtime_dir"
  )
}

genai_worker_request_validate <- function(request) {
  errors <- character()
  if (!is.list(request)) return(service_result(status = "error", errors = "Worker request must be a list."))
  extra <- setdiff(names(request), genai_worker_request_allowed_fields())
  if (length(extra)) errors <- c(errors, paste("Worker request contains prohibited fields:", paste(extra, collapse = ", ")))
  missing <- setdiff(genai_worker_request_required_fields(), names(request))
  if (length(missing)) errors <- c(errors, paste("Worker request missing required fields:", paste(missing, collapse = ", ")))
  if (!identical(request$worker_request_schema_version %||% "", genai_worker_request_schema_version())) errors <- c(errors, "Unsupported worker request schema.")
  if (!genai_worker_handler_enabled(request$handler_id %||% "")) errors <- c(errors, "worker_handler_not_enabled")
  unsafe_names <- intersect(tolower(names(request)), c("callback", "function", "code", "expr", "prompt", "secret", "api_key", "token"))
  if (length(unsafe_names)) errors <- c(errors, paste("Worker request contains unsafe fields:", paste(unsafe_names, collapse = ", ")))
  if (is.function(request$dataset_snapshot) || is.environment(request$dataset_snapshot)) errors <- c(errors, "Worker request contains unsafe dataset snapshot object.")
  if (is.function(request$configuration_snapshot) || is.environment(request$configuration_snapshot)) errors <- c(errors, "Worker request contains unsafe configuration object.")
  if (length(errors)) return(service_result(status = "error", errors = errors))
  service_result(status = "success", value = request)
}

genai_progress_event <- function(job_id, sequence, stage_id, message, fraction = NA_real_, heartbeat = TRUE) {
  message <- paste(as.character(message %||% ""), collapse = " ")
  if (nchar(message, type = "chars") > 240L) message <- paste0(substr(message, 1L, 237L), "...")
  list(
    progress_event_schema_version = genai_progress_event_schema_version(),
    job_id = job_id,
    progress_sequence = as.integer(sequence %||% 0L),
    timestamp = storage_now(),
    stage_id = safe_path_component(stage_id %||% "stage", "stage"),
    stage_label = as.character(stage_id %||% "stage"),
    message = message,
    fraction = if (is.finite(fraction)) max(0, min(1, as.numeric(fraction))) else NA_real_,
    heartbeat = isTRUE(heartbeat)
  )
}
