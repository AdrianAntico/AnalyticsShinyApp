.genai_job_state <- new.env(parent = emptyenv())
.genai_job_state$jobs <- list()
.genai_job_state$processes <- list()

genai_job_backend_available <- function(backend = genai_isolated_worker_backend()) {
  if (!identical(backend, "callr")) {
    return(service_result(status = "error", value = FALSE, errors = paste("Unsupported GenAI worker backend:", backend)))
  }
  ok <- requireNamespace("callr", quietly = TRUE) && requireNamespace("ps", quietly = TRUE)
  service_result(
    status = if (ok) "success" else "warning",
    value = ok,
    warnings = if (!ok) "callr and ps are required for isolated GenAI execution." else character(),
    metadata = list(backend = backend, callr = requireNamespace("callr", quietly = TRUE), ps = requireNamespace("ps", quietly = TRUE))
  )
}

genai_job_runtime_dir <- function(project, job_id = NULL, create_dir = FALSE) {
  if (is.null(job_id)) {
    return(project_path(project, "runtime", "genai_jobs", create_dir = create_dir))
  }
  project_path(project, "runtime", "genai_jobs", safe_path_component(job_id, "job"), create_dir = create_dir)
}

genai_job_record_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "job.json")
genai_job_progress_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "progress.ndjson")
genai_job_request_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "request.rds")
genai_job_result_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "result", "handoff.rds")
genai_job_error_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "error.json")
genai_job_complete_marker_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "complete.marker")
genai_job_snapshot_path <- function(project, job_id, create_dir = FALSE) file.path(genai_job_runtime_dir(project, job_id, create_dir), "snapshot", "dataset.rds")

genai_job_safe_relative <- function(project, path) {
  root <- storage_normalize_path(project$project_root, must_work = TRUE)
  path <- storage_normalize_path(path, must_work = FALSE)
  if (!path_within_root(path, root)) return(NA_character_)
  sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", root), "/?"), "", path)
}

genai_job_write_json <- function(object, path) {
  atomic_save_json(object, path, pretty = TRUE)
}

genai_job_read_json <- function(path) {
  if (!file.exists(path)) return(NULL)
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

genai_job_register_session <- function(job, process = NULL) {
  .genai_job_state$jobs[[job$job_id]] <- job
  if (!is.null(process)) .genai_job_state$processes[[job$job_id]] <- process
  invisible(job)
}

genai_job_get_session <- function(job_id) .genai_job_state$jobs[[job_id]]
genai_job_get_process <- function(job_id) .genai_job_state$processes[[job_id]]

genai_job_persist_record <- function(project, job) {
  record <- job
  record$internal_paths <- NULL
  record$process <- NULL
  record$handle <- NULL
  path <- genai_job_record_path(project, job$job_id, create_dir = TRUE)
  genai_job_write_json(record, path)
  invisible(record)
}

genai_job_parse_time <- function(x) {
  if (inherits(x, "POSIXt")) return(x)
  if (!nzchar(x %||% "")) return(as.POSIXct(NA))
  suppressWarnings(as.POSIXct(as.character(x), format = "%Y-%m-%dT%H:%M:%S%z"))
}

genai_job_load_record <- function(project, job_id) {
  genai_job_read_json(genai_job_record_path(project, job_id, create_dir = FALSE))
}

genai_job_update <- function(project, job, fields = list()) {
  old_status <- job$status %||% "created"
  if ("status" %in% names(fields) && !identical(fields$status, old_status)) {
    transition <- genai_job_safe_status_transition(job, fields$status)
    if (!identical(transition$status, "success")) return(transition)
    job <- transition$value
    fields$status <- NULL
  }
  for (field in names(fields)) job[[field]] <- fields[[field]]
  job$updated_at <- storage_now()
  genai_job_persist_record(project, job)
  genai_job_register_session(job, genai_job_get_process(job$job_id))
  service_result(status = "success", value = job)
}

genai_job_create_snapshot <- function(project, job_id, data, limits, dataset_resolution) {
  max_rows <- as.integer(limits$max_sample_rows %||% limits$max_rows_inspected %||% 5000L)
  max_cols <- as.integer(limits$max_columns %||% 100L)
  rows_original <- nrow(data)
  cols_original <- ncol(data)
  bounded <- data
  sampling_mode <- "full"
  if (nrow(bounded) > max_rows) {
    bounded <- bounded[seq_len(max_rows), , drop = FALSE]
    sampling_mode <- "head_bounded"
  }
  if (ncol(bounded) > max_cols) {
    bounded <- bounded[, seq_len(max_cols), drop = FALSE]
    sampling_mode <- paste(sampling_mode, "column_bounded", sep = "+")
  }
  path <- genai_job_snapshot_path(project, job_id, create_dir = TRUE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(bounded, path)
  hash <- unname(tools::md5sum(path))
  metadata <- list(
    dataset_snapshot_schema_version = genai_dataset_snapshot_schema_version(),
    dataset_snapshot_id = paste0("snapshot_", safe_path_component(job_id, "job")),
    dataset_id = dataset_resolution$dataset_id %||% NA_character_,
    dataset_version = dataset_resolution$dataset_version %||% NA_character_,
    schema_version = dataset_resolution$schema_version %||% NA_character_,
    row_count_original = rows_original,
    row_count_transferred = nrow(bounded),
    column_count_original = cols_original,
    column_count_transferred = ncol(bounded),
    sampling_mode = sampling_mode,
    content_hash = hash,
    created_at = storage_now(),
    expires_at = format(Sys.time() + 3600, "%Y-%m-%dT%H:%M:%S%z"),
    safe_relative_location = genai_job_safe_relative(project, path)
  )
  list(path = path, metadata = metadata)
}

genai_job_create_record <- function(project, proposal, resolution, execution_id, limits, handler_id) {
  now <- storage_now()
  snapshot <- resolution$metadata$configuration_snapshot
  result_type <- snapshot$result_type %||% genai_module_result_type(resolution$value$module_id, snapshot$configuration_values)
  job_id <- genai_job_id()
  list(
    job_schema_version = genai_job_record_schema_version(),
    job_id = job_id,
    proposal_id = proposal$proposal_id %||% NA_character_,
    execution_id = execution_id,
    action_id = "analysis.run_registered",
    module_id = resolution$value$module_id,
    module_version = resolution$value$module_version,
    mode_id = snapshot$mode_id %||% NA_character_,
    result_type = result_type,
    dataset_id = resolution$value$dataset_id,
    dataset_version = resolution$value$dataset_version,
    schema_version = resolution$value$schema_version,
    active_project_id = project$project_id,
    configuration_snapshot_id = snapshot$configuration_snapshot_id,
    configuration_fingerprint = snapshot$configuration_fingerprint,
    preflight_result_id = resolution$value$preflight_result_id,
    preflight_fingerprint = resolution$value$preflight_fingerprint,
    resource_fingerprint = resolution$value$resource_fingerprint,
    execution_fingerprint = genai_registered_analysis_execution_fingerprint(resolution$value, limits),
    worker_backend = genai_isolated_worker_backend(),
    worker_pid = NA_character_,
    worker_pid_hash_or_safe_id = NA_character_,
    handler_id = handler_id,
    status = "created",
    created_at = now,
    queued_at = NA_character_,
    started_at = NA_character_,
    last_heartbeat_at = NA_character_,
    completed_at = NA_character_,
    cancel_requested_at = NA_character_,
    cancelled_at = NA_character_,
    timed_out_at = NA_character_,
    failed_at = NA_character_,
    progress_stage = "created",
    progress_message = "Job created.",
    progress_fraction = NA_real_,
    timeout_seconds = max(30, as.numeric((limits$max_elapsed_ms %||% 30000L) / 1000)),
    resource_profile_id = "registered_analysis_bounded_v1",
    result_handoff_path = NA_character_,
    error_code = NA_character_,
    error_message = NA_character_,
    recovery_status = "not_recovered",
    temporary_result_id = NA_character_,
    result_fingerprint = NA_character_,
    worker_isolated = TRUE,
    hard_cancellation_supported = TRUE
  )
}

genai_job_build_worker_request <- function(project, job, resolution, limits, snapshot_info) {
  snapshot <- resolution$metadata$configuration_snapshot
  result_type <- job$result_type
  request <- list(
    worker_request_schema_version = genai_worker_request_schema_version(),
    job_id = job$job_id,
    action_id = "analysis.run_registered",
    handler_id = job$handler_id,
    module_id = job$module_id,
    module_version = job$module_version,
    mode_id = job$mode_id,
    result_type = result_type,
    dataset_snapshot = list(path = snapshot_info$path, content_hash = snapshot_info$metadata$content_hash),
    dataset_snapshot_metadata = c(snapshot_info$metadata, list(path = snapshot_info$path)),
    module_resolution = resolution$value,
    dataset_resolution = list(
      dataset_id = resolution$value$dataset_id,
      display_name = resolution$value$dataset_display_name,
      dataset_version = resolution$value$dataset_version,
      schema_version = resolution$value$schema_version,
      active_project_id = resolution$value$active_project_id
    ),
    configuration_snapshot = snapshot,
    preflight_summary = list(
      preflight_result_id = resolution$value$preflight_result_id,
      preflight_fingerprint = resolution$value$preflight_fingerprint,
      readiness = resolution$value$preflight_readiness
    ),
    resource_limits = limits,
    execution_seed = 104729L,
    requested_outputs = c("summary", "metrics", "tables", "plots", "diagnostics"),
    execution_fingerprint = job$execution_fingerprint,
    output_contract_version = genai_result_output_contract_version(result_type),
    progress_path = genai_job_progress_path(project, job$job_id, create_dir = TRUE),
    result_path = genai_job_result_path(project, job$job_id, create_dir = TRUE),
    error_path = genai_job_error_path(project, job$job_id, create_dir = TRUE),
    runtime_dir = genai_job_runtime_dir(project, job$job_id, create_dir = TRUE)
  )
  validation <- genai_worker_request_validate(request)
  if (!identical(validation$status, "success")) return(validation)
  saveRDS(request, genai_job_request_path(project, job$job_id, create_dir = TRUE))
  service_result(status = "success", value = request)
}

genai_job_start <- function(project, job, request_path, repo_root = storage_repo_root()) {
  availability <- genai_job_backend_available()
  if (!identical(availability$status, "success")) return(availability)
  queued <- genai_job_update(project, job, list(status = "queued", queued_at = storage_now(), progress_stage = "queued", progress_message = "Queued for isolated worker."))
  if (!identical(queued$status, "success")) return(queued)
  job <- queued$value
  started <- genai_job_update(project, job, list(status = "starting", started_at = storage_now(), progress_stage = "starting", progress_message = "Starting isolated worker process."))
  if (!identical(started$status, "success")) return(started)
  job <- started$value
  proc <- callr::r_bg(
    func = function(.repo_root, .request_path) {
      setwd(.repo_root)
      source(file.path(.repo_root, "app.R"))
      app_env$genai_worker_run_request(.request_path)
    },
    args = list(
      .repo_root = storage_normalize_path(repo_root, must_work = TRUE),
      .request_path = storage_normalize_path(request_path, must_work = TRUE)
    ),
    supervise = TRUE,
    stdout = file.path(genai_job_runtime_dir(project, job$job_id, create_dir = TRUE), "stdout.log"),
    stderr = file.path(genai_job_runtime_dir(project, job$job_id, create_dir = TRUE), "stderr.log"),
    env = c(
      OPENAI_API_KEY = "",
      ANTHROPIC_API_KEY = "",
      GOOGLE_API_KEY = "",
      AZURE_OPENAI_API_KEY = "",
      OPENAI_BASE_URL = "",
      R_DEFAULT_INTERNET_TIMEOUT = "30"
    )
  )
  pid <- tryCatch(proc$get_pid(), error = function(e) NA_integer_)
  job$worker_pid <- as.character(pid %||% NA_integer_)
  job$worker_pid_hash_or_safe_id <- paste0("pid_hash:", storage_hash_value(as.character(pid %||% "")))
  job <- genai_job_update(project, job, list(
    status = "running",
    worker_pid = job$worker_pid,
    worker_pid_hash_or_safe_id = job$worker_pid_hash_or_safe_id,
    last_heartbeat_at = storage_now(),
    progress_stage = "running",
    progress_message = "Isolated worker process is running."
  ))$value
  genai_job_register_session(job, proc)
  service_result(status = "success", value = job, metadata = list(job_id = job$job_id, worker_pid = pid))
}

genai_job_read_progress <- function(project, job_id) {
  path <- genai_job_progress_path(project, job_id)
  if (!file.exists(path)) return(data.table::data.table())
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  rows <- lapply(lines[nzchar(trimws(lines))], function(line) {
    tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE), error = function(e) NULL)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (!length(rows)) return(data.table::data.table())
  data.table::rbindlist(lapply(rows, as.data.frame), fill = TRUE)
}

genai_job_poll <- function(project, job_id) {
  job <- genai_job_get_session(job_id) %||% genai_job_load_record(project, job_id)
  if (is.null(job)) return(service_result(status = "error", errors = "genai_job_not_found"))
  if (job$status %in% genai_job_terminal_statuses()) return(service_result(status = "success", value = job))
  progress <- genai_job_read_progress(project, job_id)
  if (nrow(progress)) {
    latest <- progress[order(progress_sequence)][.N]
    job <- genai_job_update(project, job, list(
      last_heartbeat_at = latest$timestamp[[1]] %||% storage_now(),
      progress_stage = latest$stage_id[[1]] %||% job$progress_stage,
      progress_message = latest$message[[1]] %||% job$progress_message,
      progress_fraction = suppressWarnings(as.numeric(latest$fraction[[1]] %||% NA_real_))
    ))$value
  }
  proc <- genai_job_get_process(job_id)
  if (is.null(proc)) {
    return(service_result(status = "warning", value = genai_job_update(project, job, list(status = "orphaned", error_code = "process_handle_missing", error_message = "No live process handle is available."))$value, warnings = "process_handle_missing"))
  }
  alive <- tryCatch(proc$is_alive(), error = function(e) FALSE)
  elapsed <- as.numeric(difftime(Sys.time(), genai_job_parse_time(job$started_at), units = "secs"))
  if (isTRUE(alive) && is.finite(elapsed) && elapsed > as.numeric(job$timeout_seconds %||% 30)) {
    return(genai_job_timeout(project, job_id))
  }
  if (isTRUE(alive)) return(service_result(status = "success", value = job))
  exit_status <- tryCatch(proc$get_exit_status(), error = function(e) NA_integer_)
  if (file.exists(genai_job_result_path(project, job_id))) {
    job <- genai_job_update(project, job, list(status = "succeeded", completed_at = storage_now(), progress_stage = "complete", progress_message = "Worker completed and handoff is available.", result_handoff_path = genai_job_safe_relative(project, genai_job_result_path(project, job_id))))$value
    writeLines(storage_now(), genai_job_complete_marker_path(project, job_id, create_dir = TRUE))
    return(service_result(status = "success", value = job))
  }
  error_message <- if (file.exists(genai_job_error_path(project, job_id))) {
    err <- genai_job_read_json(genai_job_error_path(project, job_id))
    err$error_message %||% "Worker failed."
  } else {
    paste("Worker exited without result handoff. Exit status:", exit_status)
  }
  job <- genai_job_update(project, job, list(status = "failed", failed_at = storage_now(), error_code = "worker_failed_no_handoff", error_message = error_message))$value
  service_result(status = "success", value = job)
}

genai_job_cancel <- function(project, job_id) {
  job <- genai_job_get_session(job_id) %||% genai_job_load_record(project, job_id)
  if (is.null(job)) return(service_result(status = "error", errors = "genai_job_not_found"))
  if (job$status %in% genai_job_terminal_statuses()) return(service_result(status = "success", value = job, messages = "Job is already terminal."))
  job <- genai_job_update(project, job, list(status = "cancel_requested", cancel_requested_at = storage_now(), progress_stage = "cancellation_requested", progress_message = "Cancellation requested."))$value
  proc <- genai_job_get_process(job_id)
  terminated <- FALSE
  if (!is.null(proc)) {
    try(proc$kill(), silent = TRUE)
    Sys.sleep(0.1)
    terminated <- !isTRUE(tryCatch(proc$is_alive(), error = function(e) FALSE))
  }
  if (file.exists(genai_job_result_path(project, job_id))) unlink(genai_job_result_path(project, job_id), force = TRUE)
  job <- genai_job_update(project, job, list(status = "cancelled", cancelled_at = storage_now(), completed_at = storage_now(), progress_stage = "cancelled", progress_message = "Worker terminated and incomplete output discarded.", error_code = "cancelled_by_user", worker_terminated = terminated))$value
  service_result(status = "success", value = job, metadata = list(worker_terminated = terminated))
}

genai_job_timeout <- function(project, job_id) {
  job <- genai_job_get_session(job_id) %||% genai_job_load_record(project, job_id)
  if (is.null(job)) return(service_result(status = "error", errors = "genai_job_not_found"))
  if (job$status %in% genai_job_terminal_statuses()) return(service_result(status = "success", value = job))
  proc <- genai_job_get_process(job_id)
  terminated <- FALSE
  if (!is.null(proc)) {
    try(proc$kill(), silent = TRUE)
    Sys.sleep(0.1)
    terminated <- !isTRUE(tryCatch(proc$is_alive(), error = function(e) FALSE))
  }
  if (file.exists(genai_job_result_path(project, job_id))) unlink(genai_job_result_path(project, job_id), force = TRUE)
  job <- genai_job_update(project, job, list(status = "timed_out", timed_out_at = storage_now(), completed_at = storage_now(), progress_stage = "timed_out", progress_message = "Timeout exceeded; worker terminated.", error_code = "worker_timeout", worker_terminated = terminated))$value
  service_result(status = "success", value = job, metadata = list(worker_terminated = terminated))
}

genai_job_collect_handoff <- function(project, job_id, expected_fingerprint = NULL, expected_result_type = NULL, limits = NULL) {
  poll <- genai_job_poll(project, job_id)
  if (!identical(poll$status, "success")) return(poll)
  job <- poll$value
  if (!identical(job$status, "succeeded")) {
    return(service_result(status = "warning", value = list(job = job), warnings = paste("Job is not collectable:", job$status)))
  }
  path <- genai_job_result_path(project, job_id)
  if (!file.exists(path)) return(service_result(status = "error", errors = "result_handoff_missing", value = list(job = job)))
  handoff <- readRDS(path)
  errors <- character()
  if (!identical(handoff$worker_result_schema_version %||% "", genai_worker_result_schema_version())) errors <- c(errors, "unsupported_worker_result_schema")
  if (!identical(handoff$job_id %||% "", job_id)) errors <- c(errors, "worker_result_job_id_mismatch")
  if (!is.null(expected_fingerprint) && !identical(handoff$execution_fingerprint %||% "", expected_fingerprint)) errors <- c(errors, "worker_result_execution_fingerprint_mismatch")
  if (!is.null(expected_result_type) && !identical(handoff$result_type %||% "", expected_result_type)) errors <- c(errors, "worker_result_type_mismatch")
  output <- list(
    status = handoff$status %||% "succeeded",
    summary = handoff$summary,
    metrics = handoff$metrics %||% list(),
    threshold_metrics = handoff$threshold_metrics %||% NULL,
    tables = handoff$tables %||% list(),
    plots = handoff$plot_specs %||% list(),
    diagnostics = handoff$diagnostics %||% list(),
    warnings = handoff$warnings %||% character(),
    resource_usage = handoff$resource_usage %||% list(),
    execution_stages = handoff$execution_stages %||% character()
  )
  validation <- genai_validate_registered_analysis_output(output, limits %||% genai_registered_analysis_limits(), result_type = expected_result_type %||% handoff$result_type)
  if (!identical(validation$status, "success")) errors <- c(errors, validation$errors)
  if (length(errors)) {
    genai_job_update(project, job, list(status = "failed", error_code = "result_handoff_rejected", error_message = paste(errors, collapse = "; ")))
    return(service_result(status = "error", errors = errors, value = list(job = job, handoff = handoff)))
  }
  service_result(status = "success", value = list(job = job, handoff = handoff, output = output, validation = validation))
}

genai_job_reconstruct_temporary_result <- function(project, job_id, ctx = NULL, limits = NULL) {
  collected <- genai_job_collect_handoff(project, job_id, limits = limits)
  if (!identical(collected$status, "success")) return(collected)
  job <- collected$value$job
  handoff <- collected$value$handoff
  output <- collected$value$output
  completed <- Sys.time()
  module_def <- tryCatch(get_module_definition(job$module_id), error = function(e) NULL)
  temporary_result <- list(
    temporary_result_id = paste0("tmp_recovered_", format(completed, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    temporary_result_type = handoff$result_type,
    mode_id = handoff$mode_id %||% job$mode_id %||% NA_character_,
    source_action_id = "analysis.run_registered",
    source_execution_id = job$execution_id,
    execution_id = job$execution_id,
    proposal_id = job$proposal_id,
    job_id = job$job_id,
    module_id = job$module_id,
    module_version = job$module_version,
    module_display_name = module_def$label %||% job$module_id,
    dataset_id = job$dataset_id,
    dataset_display_name = "Recovered project dataset",
    dataset_version = job$dataset_version,
    schema_version = job$schema_version,
    active_project_id = project$project_id,
    configuration_snapshot_id = job$configuration_snapshot_id,
    configuration_fingerprint = job$configuration_fingerprint,
    preflight_result_id = job$preflight_result_id,
    preflight_fingerprint = job$preflight_fingerprint,
    resource_fingerprint = job$resource_fingerprint,
    summary = output$summary,
    metrics = output$metrics %||% list(),
    threshold_metrics = output$threshold_metrics %||% NULL,
    tables = output$tables %||% list(),
    plots = output$plots %||% list(),
    diagnostics = output$diagnostics %||% list(),
    warnings = c(output$warnings %||% character(), "Temporary result reconstructed from a validated isolated worker handoff."),
    resource_usage = output$resource_usage %||% list(),
    execution_stages = output$execution_stages %||% character(),
    output_contract_version = genai_result_output_contract_version(handoff$result_type),
    result_fingerprint = handoff$result_fingerprint %||% .genai_action_hash(output),
    created_at = completed,
    expires_at = completed + 3600,
    persisted = FALSE,
    recovered = TRUE
  )
  if (!is.null(ctx) && is.function(ctx$store_genai_analysis_result)) {
    ctx$store_genai_analysis_result(temporary_result)
  }
  updated <- genai_job_update(project, job, list(
    status = "recovered",
    recovery_status = "temporary_result_reconstructed",
    temporary_result_id = temporary_result$temporary_result_id,
    result_fingerprint = temporary_result$result_fingerprint,
    progress_stage = "recovered",
    progress_message = "Validated handoff reconstructed as a session temporary result."
  ))
  service_result(
    status = "success",
    value = list(job = updated$value %||% job, temporary_result = temporary_result),
    messages = "Temporary result reconstructed from validated worker handoff.",
    metadata = list(job_id = job_id, temporary_result_id = temporary_result$temporary_result_id, recovered = TRUE)
  )
}

genai_job_recover_jobs <- function(project) {
  root <- genai_job_runtime_dir(project, create_dir = FALSE)
  if (!dir.exists(root)) return(service_result(status = "success", value = data.table::data.table()))
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  rows <- lapply(dirs, function(dir) {
    job_id <- basename(dir)
    record <- genai_job_load_record(project, job_id)
    status <- "invalid_job_record"
    if (is.list(record) && identical(record$job_schema_version %||% "", genai_job_record_schema_version())) {
      result_exists <- file.exists(genai_job_result_path(project, job_id))
      error_exists <- file.exists(genai_job_error_path(project, job_id))
      status <- if (record$status %in% c("succeeded", "recovered") && result_exists) {
        "completed_uncollected"
      } else if (record$status %in% genai_job_terminal_statuses()) {
        record$status
      } else if (result_exists) {
        "completed_uncollected"
      } else if (error_exists) {
        "failed_unfinalized"
      } else {
        "orphaned"
      }
    }
    data.table::data.table(job_id = job_id, recovery_classification = status, job_status = record$status %||% NA_character_)
  })
  service_result(status = "success", value = data.table::rbindlist(rows, fill = TRUE))
}

genai_job_cleanup <- function(project, job_id, remove_snapshot = TRUE) {
  if (isTRUE(remove_snapshot)) {
    snapshot_dir <- dirname(genai_job_snapshot_path(project, job_id))
    if (dir.exists(snapshot_dir)) unlink(snapshot_dir, recursive = TRUE, force = TRUE)
  }
  service_result(status = "success", messages = "GenAI job cleanup completed.", metadata = list(job_id = job_id))
}

genai_job_summary <- function(project = NULL) {
  if (is.null(project) || !identical(project$project_state %||% "", "project_ready")) {
    jobs <- .genai_job_state$jobs
    if (!length(jobs)) return(data.table::data.table())
    return(data.table::rbindlist(lapply(jobs, function(job) data.table::as.data.table(job[intersect(names(job), c("job_id", "action_id", "module_id", "mode_id", "result_type", "status", "created_at", "started_at", "completed_at", "progress_stage", "progress_message", "worker_backend"))])), fill = TRUE))
  }
  recovery <- genai_job_recover_jobs(project)
  if (!identical(recovery$status, "success") || !nrow(recovery$value)) return(data.table::data.table())
  rows <- lapply(recovery$value$job_id, function(job_id) {
    rec <- genai_job_load_record(project, job_id)
    if (!is.list(rec)) return(NULL)
    data.table::data.table(
      job_id = rec$job_id %||% job_id,
      action_id = rec$action_id %||% NA_character_,
      module_id = rec$module_id %||% NA_character_,
      mode_id = rec$mode_id %||% NA_character_,
      result_type = rec$result_type %||% NA_character_,
      status = rec$status %||% NA_character_,
      created_at = rec$created_at %||% NA_character_,
      started_at = rec$started_at %||% NA_character_,
      completed_at = rec$completed_at %||% NA_character_,
      progress_stage = rec$progress_stage %||% NA_character_,
      progress_message = rec$progress_message %||% NA_character_,
      worker_backend = rec$worker_backend %||% NA_character_,
      recovery_status = rec$recovery_status %||% NA_character_
    )
  })
  data.table::rbindlist(rows[!vapply(rows, is.null, logical(1))], fill = TRUE)
}

qa_genai_isolated_execution <- function(output_dir = file.path(tempdir(), "genai_isolated_execution_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(check, status, message) {
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, message = message)
  }

  make_state <- function(project_id, data, config = NULL) {
    provider <- storage_provider(
      "configured_workspace", "configured_workspace", "Configured Workspace",
      file.path(output_dir, paste0("workspace_", project_id)),
      available = TRUE,
      capabilities = list(supports_external_projects = TRUE, can_choose_directory = FALSE)
    )
    workspace <- validate_workspace_root(provider$root_path, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
    project <- create_project_in_workspace(workspace, "Isolated Execution QA", project_id = project_id)$value
    env <- new.env(parent = emptyenv())
    env$uploaded_data <- function() data
    env$project_data <- function() data
    env$project_data_info <- function() list(name = "Isolated QA Dataset", path = NULL)
    env$current_dataset_id <- function() "active_dataset"
    env$project_collector_project_id <- function() project$project_id
    env$current_workspace <- function() workspace
    env$current_project <- function() project
    env$genai_preflight_limits <- function() genai_preflight_limits()
    env$genai_registered_analysis_limits <- function() genai_registered_analysis_limits()
    env$genai_preflight_state <- list(results = list())
    env$genai_analysis_run_state <- list(jobs = list(), results = list())
    env$genai_persistence_locks <- list()
    env$executed_proposal_ids <- character()
    env$genai_registered_analysis_config <- function(module_id) {
      if (!is.null(config) && identical(normalize_module_id(module_id), "model_assessment")) config else genai_registered_analysis_default_config(module_id)
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
    env$genai_analysis_cancel_requested <- function() FALSE
    env$reset_genai_analysis_cancel <- function() TRUE
    env$genai_action_proposal_executed <- function(proposal_id) proposal_id %in% env$executed_proposal_ids
    env$mark_genai_action_proposal_executed <- function(proposal_id) {
      env$executed_proposal_ids <- unique(c(env$executed_proposal_ids, proposal_id))
      TRUE
    }
    list(workspace = workspace, project = project, ctx = env)
  }

  make_run <- function(ctx, module_id) {
    proposal <- genai_action_proposal(
      action_id = "analysis.run_registered",
      action_version = "1.0",
      arguments = list(module_id = module_id, dataset_id = "active_dataset"),
      rationale = "QA isolated execution proposal",
      evidence_refs = c("qa:isolated_execution"),
      expected_effects = c("Create a bounded temporary result through an isolated worker", "Do not persist project results"),
      risk_tier = "medium",
      confidence = 0.92
    )
    validation <- genai_validate_action_proposal(proposal, ctx = ctx)
    if (!identical(validation$status, "success")) return(list(validation = validation, execution = service_result(status = "error", errors = validation$errors)))
    approved <- genai_approve_action_proposal(proposal, validation, "qa")
    list(validation = validation, execution = genai_execute_action_proposal(approved$value, ctx = ctx, approval_hash = approved$value$approval_hash))
  }

  backend <- genai_job_backend_available()
  add("worker_backend_available", if (identical(backend$status, "success") && isTRUE(backend$value)) "success" else "error", "callr and ps are available for isolated execution.")
  add("supported_handlers_allowlist", if (identical(sort(genai_worker_supported_handlers()), sort(c("dataset_profile", "model_assessment_binary", "model_assessment_regression")))) "success" else "error", "Only the three Phase 12 handlers are enabled.")
  add("invalid_transition_rejected", if (identical(genai_job_safe_status_transition(list(status = "succeeded"), "running")$status, "error")) "success" else "error", "Terminal job states cannot transition back to running.")
  add("valid_transition_allowed", if (identical(genai_job_safe_status_transition(list(status = "created"), "queued")$status, "success")) "success" else "error", "Created jobs can transition to queued.")

  invalid_request <- list(worker_request_schema_version = genai_worker_request_schema_version(), job_id = "job", action_id = "analysis.run_registered", handler_id = "dataset_profile", module_id = "dataset_profile", result_type = "dataset_profile", dataset_snapshot = list(), dataset_snapshot_metadata = list(), configuration_snapshot = list(), resource_limits = list(), execution_fingerprint = "x", progress_path = "p", result_path = "r", runtime_dir = "d", callback = "not_allowed")
  add("request_extra_field_rejected", if (identical(genai_worker_request_validate(invalid_request)$status, "error")) "success" else "error", "Worker requests reject callback/code-like extra fields.")
  unsupported_request <- invalid_request
  unsupported_request$callback <- NULL
  unsupported_request$handler_id <- "unsupported"
  add("unsupported_handler_rejected", if (identical(genai_worker_request_validate(unsupported_request)$status, "error")) "success" else "error", "Unsupported handlers fail closed.")

  profile_data <- data.frame(id = seq_len(30), segment = rep(c("A", "B", "C"), 10), value = seq_len(30), stringsAsFactors = FALSE)
  profile_state <- make_state("qa_iso_dataset_profile", profile_data)
  profile_run <- make_run(profile_state$ctx, "dataset_profile")
  profile_tmp_id <- profile_run$execution$value$temporary_result_id %||% NA_character_
  profile_tmp <- profile_state$ctx$genai_analysis_run_state$results[[profile_tmp_id]]
  add("dataset_profile_isolated_success", if (identical(profile_run$execution$status, "success") && isTRUE(profile_run$execution$value$worker_isolated) && !is.null(profile_tmp)) "success" else "error", paste("Dataset Profile runs in an isolated worker and registers a temporary result.", paste(profile_run$execution$errors %||% profile_run$validation$errors %||% character(), collapse = "; ")))
  add("dataset_profile_job_record_durable", if (nrow(genai_job_summary(profile_state$project)) >= 1L) "success" else "error", "Dataset Profile job record is discoverable after execution.")

  regression_data <- data.frame(actual = seq(10, 69), predicted = seq(11, 70), segment = rep(c("A", "B"), length.out = 60), stringsAsFactors = FALSE)
  regression_state <- make_state("qa_iso_regression", regression_data, list(assessment_problem_type = "Regression", actual_var = "actual", prediction_var = "predicted", segment_var = "segment"))
  regression_run <- make_run(regression_state$ctx, "model_assessment")
  regression_tmp <- regression_state$ctx$genai_analysis_run_state$results[[regression_run$execution$value$temporary_result_id %||% ""]]
  add("regression_assessment_isolated_success", if (identical(regression_run$execution$status, "success") && identical(regression_tmp$temporary_result_type %||% "", "model_assessment_regression")) "success" else "error", paste("Regression Model Assessment runs in isolation.", paste(regression_run$execution$errors %||% regression_run$validation$errors %||% character(), collapse = "; ")))

  score <- seq(0.05, 0.95, length.out = 80)
  binary_data <- data.frame(actual = ifelse(score >= 0.5, "Yes", "No"), probability = score, stringsAsFactors = FALSE)
  binary_state <- make_state("qa_iso_binary", binary_data, list(assessment_problem_type = "Binary Classification", actual_var = "actual", prediction_var = "probability", positive_class = "Yes", threshold = 0.5, prediction_scale = "probability"))
  binary_run <- make_run(binary_state$ctx, "model_assessment")
  binary_tmp <- binary_state$ctx$genai_analysis_run_state$results[[binary_run$execution$value$temporary_result_id %||% ""]]
  add("binary_assessment_isolated_success", if (identical(binary_run$execution$status, "success") && identical(binary_tmp$temporary_result_type %||% "", "model_assessment_binary")) "success" else "error", paste("Binary Model Assessment runs in isolation.", paste(binary_run$execution$errors %||% binary_run$validation$errors %||% character(), collapse = "; ")))

  resolution <- genai_resolve_registered_analysis_resources("dataset_profile", "active_dataset", ctx = profile_state$ctx)
  job <- genai_job_create_record(profile_state$project, list(proposal_id = "qa_cancel"), resolution, "execution_cancel", genai_registered_analysis_limits(), "dataset_profile")
  snapshot <- genai_job_create_snapshot(profile_state$project, job$job_id, profile_data, genai_registered_analysis_limits(), resolution$value)
  request <- genai_job_build_worker_request(profile_state$project, job, resolution, genai_registered_analysis_limits(), snapshot)
  if (identical(request$status, "success")) {
    genai_job_persist_record(profile_state$project, job)
    started <- genai_job_start(profile_state$project, job, genai_job_request_path(profile_state$project, job$job_id))
    cancelled <- if (identical(started$status, "success")) genai_job_cancel(profile_state$project, started$value$job_id) else started
    add("hard_cancel_terminal", if (identical(cancelled$status, "success") && identical(cancelled$value$status, "cancelled") && !file.exists(genai_job_result_path(profile_state$project, job$job_id))) "success" else "error", "Hard cancellation terminates the worker and discards any handoff.")
    repeated <- genai_job_cancel(profile_state$project, job$job_id)
    add("hard_cancel_idempotent", if (identical(repeated$status, "success") && identical(repeated$value$status, "cancelled")) "success" else "error", "Repeated cancellation is idempotent.")
  } else {
    add("hard_cancel_terminal", "error", "Cancel setup failed.")
    add("hard_cancel_idempotent", "error", "Cancel setup failed.")
  }

  timeout_job <- genai_job_create_record(profile_state$project, list(proposal_id = "qa_timeout"), resolution, "execution_timeout", genai_registered_analysis_limits(), "dataset_profile")
  timeout_snapshot <- genai_job_create_snapshot(profile_state$project, timeout_job$job_id, profile_data, genai_registered_analysis_limits(), resolution$value)
  timeout_request <- genai_job_build_worker_request(profile_state$project, timeout_job, resolution, genai_registered_analysis_limits(), timeout_snapshot)
  if (identical(timeout_request$status, "success")) {
    genai_job_persist_record(profile_state$project, timeout_job)
    timeout_started <- genai_job_start(profile_state$project, timeout_job, genai_job_request_path(profile_state$project, timeout_job$job_id))
    timed_out <- if (identical(timeout_started$status, "success")) genai_job_timeout(profile_state$project, timeout_started$value$job_id) else timeout_started
    add("external_timeout_terminal", if (identical(timed_out$status, "success") && identical(timed_out$value$status, "timed_out") && !file.exists(genai_job_result_path(profile_state$project, timeout_job$job_id))) "success" else "error", "External timeout terminates the worker and discards any handoff.")
  } else {
    add("external_timeout_terminal", "error", "Timeout setup failed.")
  }

  tamper_job <- genai_job_create_record(profile_state$project, list(proposal_id = "qa_tamper"), resolution, "execution_tamper", genai_registered_analysis_limits(), "dataset_profile")
  tamper_snapshot <- genai_job_create_snapshot(profile_state$project, tamper_job$job_id, profile_data, genai_registered_analysis_limits(), resolution$value)
  saveRDS(profile_data[1, , drop = FALSE], tamper_snapshot$path)
  tamper_request <- list(dataset_snapshot = list(path = tamper_snapshot$path, content_hash = tamper_snapshot$metadata$content_hash), dataset_snapshot_metadata = c(tamper_snapshot$metadata, list(path = tamper_snapshot$path)))
  add("tampered_snapshot_rejected", if (identical(genai_worker_verify_snapshot(tamper_request)$status, "error")) "success" else "error", "Dataset snapshot hash mismatches are rejected.")

  progress <- genai_job_read_progress(profile_state$project, profile_run$execution$value$job_id)
  add("progress_monotonic", if (nrow(progress) && identical(progress$progress_sequence, sort(progress$progress_sequence))) "success" else "error", "Worker progress sequence is monotonic.")
  add("progress_bounded", if (nrow(progress) && all(nchar(as.character(progress$message)) <= 240L)) "success" else "error", "Worker progress messages are bounded.")

  recovery <- genai_job_recover_jobs(profile_state$project)
  add("recovery_classification_available", if (identical(recovery$status, "success") && nrow(recovery$value)) "success" else "error", "Durable job recovery classifies project jobs.")

  recovery_ctx <- new.env(parent = emptyenv())
  recovery_ctx$genai_analysis_run_state <- list(results = list())
  recovery_ctx$store_genai_analysis_result <- function(result) {
    recovery_ctx$genai_analysis_run_state$results[[result$temporary_result_id]] <- result
    result$temporary_result_id
  }
  reconstructed <- genai_job_reconstruct_temporary_result(profile_state$project, profile_run$execution$value$job_id, ctx = recovery_ctx)
  reconstructed_id <- reconstructed$value$temporary_result$temporary_result_id %||% NA_character_
  add("completed_job_reconstructs_temporary_result", if (identical(reconstructed$status, "success") && !is.null(recovery_ctx$genai_analysis_run_state$results[[reconstructed_id]]) && isTRUE(reconstructed$value$temporary_result$recovered) && isFALSE(reconstructed$value$temporary_result$persisted)) "success" else "error", "Completed validated jobs can reconstruct temporary session results without persistence.")

  record <- genai_job_load_record(profile_state$project, profile_run$execution$value$job_id)
  serialized <- paste(capture.output(str(record)), collapse = "\n")
  add("job_record_excludes_raw_rows", if (!grepl("segment_1|value =|raw_rows|dataset_snapshot = data", serialized)) "success" else "error", "Durable job record excludes raw rows and dataset payloads.")
  prohibited_record_fields <- intersect(names(record %||% list()), c("process", "handle", "internal_paths"))
  add("job_record_excludes_process_handle", if (!length(prohibited_record_fields)) "success" else "error", "Durable job record excludes process handles and internal absolute path bundle.")
  add("job_events_registered", if (all(c("job_created", "worker_started", "job_succeeded", "job_cancelled", "job_timed_out") %in% genai_audit_event_types())) "success" else "error", "Job lifecycle audit events are registered.")

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
