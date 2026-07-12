genai_worker_read_rds <- function(path) {
  if (!nzchar(path %||% "") || !file.exists(path)) {
    stop("Worker input file does not exist.", call. = FALSE)
  }
  readRDS(path)
}

genai_worker_write_json <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(object, path, auto_unbox = TRUE, null = "null", pretty = TRUE)
  path
}

genai_worker_append_progress <- function(path, event) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  line <- jsonlite::toJSON(event, auto_unbox = TRUE, null = "null", digits = NA)
  con <- file(path, open = "ab")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(paste0(line, "\n")), con)
  invisible(path)
}

genai_worker_progress_writer <- function(request) {
  sequence <- 0L
  force(request)
  function(stage, message, fraction = NA_real_) {
    sequence <<- sequence + 1L
    event <- genai_progress_event(
      job_id = request$job_id,
      sequence = sequence,
      stage_id = stage,
      message = message,
      fraction = fraction,
      heartbeat = TRUE
    )
    genai_worker_append_progress(request$progress_path, event)
    NULL
  }
}

genai_worker_verify_snapshot <- function(request) {
  snapshot <- request$dataset_snapshot %||% list()
  metadata <- request$dataset_snapshot_metadata %||% list()
  path <- snapshot$path %||% metadata$path %||% ""
  if (!nzchar(path) || !file.exists(path)) {
    return(service_result(status = "error", errors = "dataset_snapshot_missing"))
  }
  expected <- metadata$content_hash %||% snapshot$content_hash %||% NA_character_
  actual <- unname(tools::md5sum(path))
  if (nzchar(expected %||% "") && !identical(actual, expected)) {
    return(service_result(status = "error", errors = "dataset_snapshot_hash_mismatch"))
  }
  data <- readRDS(path)
  service_result(status = "success", value = data, metadata = list(content_hash = actual))
}

genai_worker_execute_request <- function(request) {
  validation <- genai_worker_request_validate(request)
  if (!identical(validation$status, "success")) {
    return(service_result(status = "error", errors = validation$errors))
  }
  if (nzchar(request$runtime_dir %||% "")) {
    old <- getwd()
    on.exit(setwd(old), add = TRUE)
    setwd(request$runtime_dir)
  }
  progress <- genai_worker_progress_writer(request)
  progress("worker_start", "Worker validated request and is loading the bounded dataset snapshot.", 0.05)
  snapshot <- genai_worker_verify_snapshot(request)
  if (!identical(snapshot$status, "success")) {
    return(snapshot)
  }
  data <- snapshot$value
  progress("handler_resolve", "Resolving trusted registered handler.", 0.1)
  handler <- switch(
    request$handler_id,
    dataset_profile = genai_dataset_profile_execute,
    model_assessment_regression = genai_model_assessment_execute,
    model_assessment_binary = genai_model_assessment_execute,
    NULL
  )
  if (is.null(handler)) {
    return(service_result(status = "error", errors = "worker_handler_not_enabled"))
  }
  set.seed(as.integer(request$execution_seed %||% 104729L))
  progress("compute", "Running trusted bounded analysis in isolated worker.", NA_real_)
  output <- tryCatch(
    handler(
      data = data,
      module_resolution = request$module_resolution,
      dataset_resolution = request$dataset_resolution,
      configuration_snapshot = request$configuration_snapshot,
      limits = request$resource_limits,
      cancel_requested = function() FALSE,
      progress = progress
    ),
    error = function(e) list(
      status = "failed",
      summary = conditionMessage(e),
      tables = list(),
      diagnostics = list(),
      warnings = character(),
      errors = conditionMessage(e),
      resource_usage = list(),
      execution_stages = character()
    )
  )
  result_type <- request$result_type %||% "dataset_profile"
  progress("validate_output", "Validating worker output contract.", 0.9)
  contract <- genai_validate_registered_analysis_output(output, request$resource_limits, result_type = result_type)
  if (!identical(contract$status, "success")) {
    return(service_result(status = "error", errors = c("worker_output_contract_invalid", contract$errors), value = output))
  }
  handoff <- list(
    worker_result_schema_version = genai_worker_result_schema_version(),
    job_id = request$job_id,
    status = "succeeded",
    module_id = request$module_id,
    mode_id = request$mode_id %||% NA_character_,
    result_type = result_type,
    started_at = NA_character_,
    completed_at = storage_now(),
    summary = output$summary,
    metrics = output$metrics %||% list(),
    threshold_metrics = output$threshold_metrics %||% NULL,
    diagnostics = output$diagnostics %||% list(),
    tables = output$tables %||% list(),
    plot_specs = output$plots %||% list(),
    warnings = output$warnings %||% character(),
    resource_usage = output$resource_usage %||% list(),
    execution_stages = output$execution_stages %||% character(),
    output_contract_version = genai_result_output_contract_version(result_type),
    execution_fingerprint = request$execution_fingerprint,
    result_fingerprint = .genai_action_hash(list(
      summary = output$summary,
      metrics = output$metrics %||% list(),
      threshold_metrics = output$threshold_metrics %||% NULL,
      tables = output$tables %||% list(),
      plots = output$plots %||% list(),
      diagnostics = output$diagnostics %||% list(),
      resource_usage = output$resource_usage %||% list()
    ))
  )
  dir.create(dirname(request$result_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(handoff, request$result_path)
  progress("complete", "Worker wrote validated result handoff.", 1)
  service_result(status = "success", value = handoff, messages = "Worker handoff written.")
}

genai_worker_run_request <- function(request_path) {
  request <- genai_worker_read_rds(request_path)
  result <- tryCatch(
    genai_worker_execute_request(request),
    error = function(e) service_result(status = "error", errors = conditionMessage(e))
  )
  if (!identical(result$status, "success")) {
    error_path <- request$error_path %||% file.path(dirname(request_path), "error.json")
    genai_worker_write_json(list(
      worker_result_schema_version = genai_worker_result_schema_version(),
      job_id = request$job_id %||% NA_character_,
      status = "failed",
      error_code = "worker_execution_failed",
      error_message = paste(result$errors %||% result$warnings %||% "Worker execution failed.", collapse = " | "),
      completed_at = storage_now()
    ), error_path)
  }
  result
}
