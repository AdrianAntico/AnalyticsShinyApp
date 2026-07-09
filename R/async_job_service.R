.async_job_state <- new.env(parent = emptyenv())
.async_job_state$jobs <- list()
.async_job_state$config <- NULL
.async_job_state$mirai_daemons_started <- FALSE

async_backend_config <- function(
  backend = "mirai",
  workers = 1L,
  timeout_ms = NULL,
  fallback = c("sync", "none"),
  result_dir = file.path(tempdir(), "analytics_async_jobs"),
  source_mode = c("app", "none"),
  app_file = "app.R",
  start_daemons = TRUE
) {
  fallback <- match.arg(fallback)
  source_mode <- match.arg(source_mode)
  list(
    backend = backend,
    workers = as.integer(workers %||% 1L),
    timeout_ms = timeout_ms,
    fallback = fallback,
    result_dir = normalizePath(result_dir, winslash = "/", mustWork = FALSE),
    source_mode = source_mode,
    app_file = app_file,
    start_daemons = isTRUE(start_daemons)
  )
}

async_job_registry_env <- function() {
  .async_job_state
}

async_backend_available <- function(config = async_backend_config()) {
  if (is.character(config) && length(config) == 1L) {
    config <- async_backend_config(backend = config, fallback = "none")
  }
  backend <- config$backend %||% "mirai"
  if (identical(backend, "sync")) {
    return(service_result(
      status = "success",
      value = TRUE,
      messages = "Synchronous fallback backend is available.",
      metadata = list(backend = "sync", available = TRUE)
    ))
  }
  if (!identical(backend, "mirai")) {
    return(service_result(
      status = "warning",
      value = FALSE,
      warnings = paste("Async backend is not implemented:", backend),
      metadata = list(backend = backend, available = FALSE, reason_code = "backend_not_implemented")
    ))
  }
  available <- requireNamespace("mirai", quietly = TRUE)
  if (!available) {
    return(service_result(
      status = "warning",
      value = FALSE,
      warnings = "mirai is not installed. Async jobs can use synchronous fallback if configured.",
      metadata = list(backend = "mirai", available = FALSE, reason_code = "backend_unavailable")
    ))
  }
  service_result(
    status = "success",
    value = TRUE,
    messages = "mirai async backend is available.",
    metadata = list(
      backend = "mirai",
      available = TRUE,
      version = as.character(utils::packageVersion("mirai"))
    )
  )
}

async_job_id <- function(prefix = "job") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sprintf("%04d", sample.int(9999L, 1L)))
}

async_compact_arguments <- function(args) {
  if (is.null(args) || !length(args)) return(character())
  vapply(names(args), function(name) {
    value <- args[[name]]
    size <- tryCatch(utils::object.size(value), error = function(e) NA)
    class_name <- paste(class(value), collapse = "/")
    length_value <- tryCatch(length(value), error = function(e) NA_integer_)
    paste0(name, "=", class_name, "[", length_value, "]", if (!is.na(size)) paste0(" ", format(size, units = "auto")) else "")
  }, character(1))
}

async_new_job <- function(
  job_id = async_job_id(),
  job_type = "generic",
  module_id = NA_character_,
  project_id = NA_character_,
  run_id = NA_character_,
  backend = "mirai",
  function_name = NA_character_,
  arguments_summary = character(),
  result_path = NA_character_
) {
  now <- Sys.time()
  structure(list(
    job_id = job_id,
    job_type = job_type,
    module_id = module_id,
    project_id = project_id,
    run_id = run_id,
    status = "queued",
    submitted_at = now,
    started_at = as.POSIXct(NA),
    completed_at = as.POSIXct(NA),
    elapsed_seconds = NA_real_,
    backend = backend,
    function_name = function_name,
    arguments_summary = arguments_summary,
    result_path = result_path,
    error = character(),
    warnings = character(),
    artifacts_created = 0L,
    collector_updated = FALSE,
    progress = 0,
    logs = character(),
    handle = NULL,
    result = NULL,
    metadata = list()
  ), class = c("async_job", "list"))
}

async_job_store <- function(job) {
  .async_job_state$jobs[[job$job_id]] <- job
  invisible(job)
}

async_job_get <- function(job_id) {
  .async_job_state$jobs[[job_id]]
}

async_job_registry <- function(refresh = TRUE) {
  if (isTRUE(refresh)) {
    invisible(lapply(names(.async_job_state$jobs), async_job_status))
  }
  .async_job_state$jobs
}

async_job_registry_reset <- function(stop_daemons = FALSE) {
  .async_job_state$jobs <- list()
  .async_job_state$config <- NULL
  if (isTRUE(stop_daemons) && requireNamespace("mirai", quietly = TRUE)) {
    try(mirai::daemons(0), silent = TRUE)
    .async_job_state$mirai_daemons_started <- FALSE
  }
  invisible(TRUE)
}

async_job_result_path <- function(job_id, result_dir) {
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
  file.path(result_dir, paste0(job_id, "_result.rds"))
}

async_worker_call <- function(function_name, args, working_dir, source_mode = "app", app_file = "app.R") {
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(working_dir)
  if (identical(source_mode, "app")) {
    source_env <- new.env(parent = globalenv())
    source(app_file, local = source_env)
    if (exists("app_env", envir = source_env, inherits = FALSE) &&
        exists(function_name, envir = get("app_env", envir = source_env), inherits = FALSE)) {
      fn <- get(function_name, envir = get("app_env", envir = source_env), inherits = FALSE)
    } else {
      fn <- get(function_name, envir = source_env, inherits = TRUE)
    }
  } else {
    fn <- get(function_name, envir = globalenv(), inherits = TRUE)
  }

  warnings <- character()
  logs <- character()
  started_at <- Sys.time()
  value <- withCallingHandlers(
    tryCatch(
      do.call(fn, args),
      error = function(e) {
        structure(list(error = conditionMessage(e)), class = "async_worker_error")
      }
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      logs <<- c(logs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  completed_at <- Sys.time()
  list(
    value = value,
    warnings = warnings,
    logs = logs,
    started_at = started_at,
    completed_at = completed_at,
    elapsed_seconds = as.numeric(difftime(completed_at, started_at, units = "secs"))
  )
}

async_worker_summarize <- function(worker_result) {
  value <- worker_result$value
  if (inherits(value, "async_worker_error")) {
    return(list(status = "failed", error = value$error %||% "Worker failed.", warnings = worker_result$warnings %||% character()))
  }
  if (is.list(value) && !is.null(value$status) && identical(value$status, "error")) {
    return(list(
      status = "failed",
      error = paste(value$errors %||% "Worker returned error service_result.", collapse = " | "),
      warnings = c(worker_result$warnings %||% character(), value$warnings %||% character())
    ))
  }
  list(
    status = "completed",
    error = character(),
    warnings = c(worker_result$warnings %||% character(), if (is.list(value)) value$warnings %||% character() else character())
  )
}

async_job_finalize <- function(job, worker_result) {
  summary <- async_worker_summarize(worker_result)
  job$status <- summary$status
  job$started_at <- worker_result$started_at %||% job$started_at
  job$completed_at <- worker_result$completed_at %||% Sys.time()
  job$elapsed_seconds <- worker_result$elapsed_seconds %||% as.numeric(difftime(job$completed_at, job$submitted_at, units = "secs"))
  job$error <- summary$error
  job$warnings <- summary$warnings
  job$logs <- c(job$logs %||% character(), worker_result$logs %||% character())
  job$progress <- if (identical(job$status, "completed")) 1 else job$progress
  job$result <- worker_result$value
  if (is.list(worker_result$value)) {
    metadata <- worker_result$value$metadata %||% list()
    value <- worker_result$value$value %||% list()
    job$artifacts_created <- metadata$artifact_count %||% length(value$artifacts %||% list())
    job$collector_updated <- !is.null(metadata$collector_docx) || !is.null(value$collector)
  }
  if (nzchar(job$result_path %||% "")) {
    saveRDS(worker_result$value, job$result_path)
  }
  async_job_store(job)
  job
}

async_start_mirai_daemons <- function(config) {
  if (!isTRUE(config$start_daemons)) return(invisible(FALSE))
  if (!requireNamespace("mirai", quietly = TRUE)) return(invisible(FALSE))
  if (isTRUE(.async_job_state$mirai_daemons_started)) return(invisible(TRUE))
  workers <- max(1L, as.integer(config$workers %||% 1L))
  mirai::daemons(workers)
  .async_job_state$mirai_daemons_started <- TRUE
  invisible(TRUE)
}

async_job_submit <- function(
  function_name,
  args = list(),
  job_type = "generic",
  module_id = NA_character_,
  project_id = NA_character_,
  run_id = NA_character_,
  config = async_backend_config(),
  job_id = async_job_id(job_type),
  working_dir = getwd()
) {
  dir.create(config$result_dir, recursive = TRUE, showWarnings = FALSE)
  result_path <- async_job_result_path(job_id, config$result_dir)
  availability <- async_backend_available(config)
  backend <- config$backend %||% "mirai"
  if (!identical(availability$status, "success")) {
    if (!identical(config$fallback, "sync")) {
      job <- async_new_job(
        job_id = job_id,
        job_type = job_type,
        module_id = module_id,
        project_id = project_id,
        run_id = run_id,
        backend = backend,
        function_name = function_name,
        arguments_summary = async_compact_arguments(args),
        result_path = result_path
      )
      job$status <- "unavailable"
      job$completed_at <- Sys.time()
      job$error <- availability$warnings %||% availability$errors %||% "Async backend unavailable."
      async_job_store(job)
      return(service_result(status = "warning", value = job, warnings = job$error, metadata = list(job_id = job_id, backend = backend)))
    }
    backend <- "sync"
  }

  job <- async_new_job(
    job_id = job_id,
    job_type = job_type,
    module_id = module_id,
    project_id = project_id,
    run_id = run_id,
    backend = backend,
    function_name = function_name,
    arguments_summary = async_compact_arguments(args),
    result_path = result_path
  )
  job$status <- "running"
  job$started_at <- Sys.time()
  job$progress <- 0.1
  async_job_store(job)

  if (identical(backend, "sync")) {
    worker_result <- async_worker_call(
      function_name = function_name,
      args = args,
      working_dir = working_dir,
      source_mode = config$source_mode %||% "app",
      app_file = config$app_file %||% "app.R"
    )
    job <- async_job_finalize(job, worker_result)
    return(service_result(status = "success", value = job, messages = paste("Synchronous fallback job completed:", job_id), metadata = list(job_id = job_id, backend = "sync")))
  }

  tryCatch({
    async_start_mirai_daemons(config)
    handle <- mirai::mirai(
      async_worker_call(
        function_name = .function_name,
        args = .args,
        working_dir = .working_dir,
        source_mode = .source_mode,
        app_file = .app_file
      ),
      .args = list(
        async_worker_call = async_worker_call,
        .function_name = function_name,
        .args = args,
        .working_dir = normalizePath(working_dir, winslash = "/", mustWork = TRUE),
        .source_mode = config$source_mode %||% "app",
        .app_file = config$app_file %||% "app.R"
      ),
      .timeout = config$timeout_ms
    )
    job$handle <- handle
    job$metadata$mirai_id <- attr(handle, "id")
    async_job_store(job)
    service_result(status = "success", value = job, messages = paste("Async job submitted:", job_id), metadata = list(job_id = job_id, backend = "mirai"))
  }, error = function(e) {
    if (identical(config$fallback, "sync")) {
      worker_result <- async_worker_call(
        function_name = function_name,
        args = args,
        working_dir = working_dir,
        source_mode = config$source_mode %||% "app",
        app_file = config$app_file %||% "app.R"
      )
      job$backend <- "sync"
      job$warnings <- paste("mirai submit failed; used synchronous fallback:", conditionMessage(e))
      job <- async_job_finalize(job, worker_result)
      return(service_result(status = "warning", value = job, warnings = job$warnings, metadata = list(job_id = job_id, backend = "sync")))
    }
    job$status <- "failed"
    job$completed_at <- Sys.time()
    job$error <- conditionMessage(e)
    async_job_store(job)
    service_result(status = "error", value = job, errors = conditionMessage(e), metadata = list(job_id = job_id, backend = "mirai"))
  })
}

async_job_status <- function(job_id) {
  job <- async_job_get(job_id)
  if (is.null(job)) {
    return(service_result(status = "warning", warnings = paste("Unknown async job:", job_id), metadata = list(job_id = job_id)))
  }
  if (identical(job$backend, "mirai") && !is.null(job$handle) && job$status %in% c("queued", "running")) {
    unresolved <- tryCatch(mirai::unresolved(job$handle), error = function(e) FALSE)
    if (isTRUE(unresolved)) {
      job$status <- "running"
      job$elapsed_seconds <- as.numeric(difftime(Sys.time(), job$started_at, units = "secs"))
      job$progress <- max(job$progress %||% 0.1, 0.2)
      async_job_store(job)
    } else {
      worker_result <- job$handle$data
      if (inherits(worker_result, "miraiError") || inherits(worker_result, "errorValue")) {
        job$status <- "failed"
        job$completed_at <- Sys.time()
        job$elapsed_seconds <- as.numeric(difftime(job$completed_at, job$started_at, units = "secs"))
        job$error <- as.character(worker_result)
        async_job_store(job)
      } else {
        job <- async_job_finalize(job, worker_result)
      }
    }
  }
  service_result(status = "success", value = job, metadata = list(job_id = job_id, job_status = job$status))
}

async_job_result <- function(job_id) {
  status <- async_job_status(job_id)
  if (!identical(status$status, "success")) return(status)
  job <- status$value
  if (!job$status %in% c("completed", "failed", "cancelled", "timed_out")) {
    return(service_result(status = "warning", value = NULL, warnings = paste("Job is not complete:", job$status), metadata = list(job_id = job_id, job_status = job$status)))
  }
  value <- if (!is.null(job$result)) {
    job$result
  } else if (file.exists(job$result_path %||% "")) {
    readRDS(job$result_path)
  } else {
    NULL
  }
  service_result(
    status = if (identical(job$status, "completed")) "success" else "warning",
    value = value,
    warnings = if (!identical(job$status, "completed")) job$error else character(),
    metadata = list(job_id = job_id, job_status = job$status, result_path = job$result_path)
  )
}

async_job_cancel <- function(job_id) {
  job <- async_job_get(job_id)
  if (is.null(job)) {
    return(service_result(status = "warning", warnings = paste("Unknown async job:", job_id), metadata = list(job_id = job_id)))
  }
  if (identical(job$backend, "mirai") && !is.null(job$handle) && requireNamespace("mirai", quietly = TRUE)) {
    try(mirai::stop_mirai(job$handle), silent = TRUE)
  }
  job$status <- "cancelled"
  job$completed_at <- Sys.time()
  job$elapsed_seconds <- as.numeric(difftime(job$completed_at, job$started_at %||% job$submitted_at, units = "secs"))
  job$progress <- 0
  async_job_store(job)
  service_result(status = "success", value = job, messages = paste("Cancelled async job:", job_id), metadata = list(job_id = job_id))
}

async_job_log <- function(job_id) {
  status <- async_job_status(job_id)
  if (!identical(status$status, "success")) return(status)
  job <- status$value
  service_result(status = "success", value = job$logs %||% character(), metadata = list(job_id = job_id, job_status = job$status))
}

async_job_summary <- function(refresh = TRUE) {
  jobs <- async_job_registry(refresh = refresh)
  if (!length(jobs)) {
    return(data.table::data.table())
  }
  data.table::rbindlist(lapply(jobs, function(job) {
    data.table::data.table(
      job_id = job$job_id %||% NA_character_,
      job_type = job$job_type %||% NA_character_,
      module_id = job$module_id %||% NA_character_,
      project_id = job$project_id %||% NA_character_,
      run_id = job$run_id %||% NA_character_,
      status = job$status %||% NA_character_,
      submitted_at = job$submitted_at %||% as.POSIXct(NA),
      started_at = job$started_at %||% as.POSIXct(NA),
      completed_at = job$completed_at %||% as.POSIXct(NA),
      elapsed_seconds = suppressWarnings(as.numeric(job$elapsed_seconds %||% NA_real_)),
      backend = job$backend %||% NA_character_,
      function_name = job$function_name %||% NA_character_,
      result_path = job$result_path %||% NA_character_,
      has_error = length(job$error %||% character()) > 0L,
      warning_count = length(job$warnings %||% character()),
      artifacts_created = as.integer(job$artifacts_created %||% 0L),
      collector_updated = isTRUE(job$collector_updated),
      progress = suppressWarnings(as.numeric(job$progress %||% 0))
    )
  }), fill = TRUE)
}

async_job_status_counts <- function(refresh = TRUE) {
  summary <- async_job_summary(refresh = refresh)
  if (!nrow(summary)) {
    return(list(total = 0L, running = 0L, completed = 0L, failed = 0L, latest_status = "none", latest_job_id = NA_character_))
  }
  latest <- summary[order(submitted_at, decreasing = TRUE)][1]
  list(
    total = nrow(summary),
    running = sum(summary$status %in% c("queued", "running")),
    completed = sum(summary$status == "completed"),
    failed = sum(summary$status %in% c("failed", "timed_out", "cancelled", "unavailable")),
    latest_status = latest$status[[1]],
    latest_job_id = latest$job_id[[1]]
  )
}

async_run_artifact_studio_demo_seed <- function(
  output_dir = file.path("exports", "artifact_studio_demo_async"),
  config = async_backend_config(),
  seed = 42L,
  n = 120L,
  max_artifacts_per_module = 8L
) {
  async_job_submit(
    function_name = "create_artifact_studio_demo_project",
    args = list(
      output_dir = output_dir,
      seed = seed,
      n = n,
      max_artifacts_per_module = max_artifacts_per_module,
      write_collector = TRUE
    ),
    job_type = "artifact_studio_demo_seed",
    module_id = "artifact_studio",
    project_id = "artifact_studio_demo_async",
    run_id = paste0("async_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    config = config,
    working_dir = getwd()
  )
}

async_qa_worker_success <- function(value = 42L, delay = 0.05) {
  Sys.sleep(delay)
  service_result(
    status = "success",
    value = list(value = value),
    messages = "Async QA worker completed.",
    metadata = list(artifact_count = 0L)
  )
}

async_qa_worker_failure <- function() {
  stop("Intentional async QA failure.", call. = FALSE)
}

async_worker_environment_check <- function(env_vars = c("R_LIBS", "R_LIBS_USER", "PATH")) {
  package_available <- function(package) requireNamespace(package, quietly = TRUE)
  functions_available <- c(
    async_job_submit = exists("async_job_submit", mode = "function"),
    create_artifact_studio_demo_project = exists("create_artifact_studio_demo_project", mode = "function"),
    service_result = exists("service_result", mode = "function")
  )
  service_result(
    status = "success",
    value = list(
      r_version = R.version.string,
      r_home = R.home(),
      platform = R.version$platform,
      working_directory = getwd(),
      lib_paths = .libPaths(),
      packages = list(
        mirai = package_available("mirai"),
        AutoQuant = package_available("AutoQuant"),
        AutoPlots = package_available("AutoPlots"),
        shiny = package_available("shiny"),
        data.table = package_available("data.table")
      ),
      functions_available = functions_available,
      env_vars = stats::setNames(as.list(Sys.getenv(env_vars, unset = NA_character_)), env_vars)
    ),
    messages = "Async worker environment check completed."
  )
}

qa_async_job_service <- function(output_dir = file.path(tempdir(), "async_job_service_qa")) {
  async_job_registry_reset(stop_daemons = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  config_mirai <- async_backend_config(result_dir = file.path(output_dir, "mirai"), fallback = "sync", timeout_ms = 30000L)
  config_sync <- async_backend_config(backend = "sync", result_dir = file.path(output_dir, "sync"), source_mode = "app")
  unavailable_config <- async_backend_config(backend = "not_a_backend", fallback = "none", result_dir = file.path(output_dir, "unavailable"))

  backend_check <- async_backend_available(config_mirai)
  unavailable_submit <- async_job_submit(
    "async_qa_worker_success",
    args = list(value = 1L),
    job_type = "qa_unavailable",
    config = unavailable_config
  )

  sync_submit <- async_job_submit(
    "async_qa_worker_success",
    args = list(value = 7L, delay = 0),
    job_type = "qa_sync_success",
    config = config_sync
  )
  sync_job <- sync_submit$value
  sync_result <- async_job_result(sync_job$job_id)

  fail_submit <- async_job_submit(
    "async_qa_worker_failure",
    args = list(),
    job_type = "qa_sync_failure",
    config = config_sync
  )
  fail_job <- fail_submit$value
  fail_status <- async_job_status(fail_job$job_id)

  mirai_submit <- async_job_submit(
    "async_qa_worker_success",
    args = list(value = 9L, delay = 0.05),
    job_type = "qa_async_success",
    config = config_mirai
  )
  mirai_job <- mirai_submit$value
  deadline <- Sys.time() + 20
  repeat {
    status <- async_job_status(mirai_job$job_id)
    if (!status$value$status %in% c("queued", "running")) break
    if (Sys.time() > deadline) break
    Sys.sleep(0.05)
  }
  mirai_status <- async_job_status(mirai_job$job_id)
  mirai_result <- async_job_result(mirai_job$job_id)
  registry <- async_job_summary(refresh = TRUE)
  counts <- async_job_status_counts(refresh = FALSE)

  app_source <- tryCatch({
    env <- new.env(parent = globalenv())
    source("app.R", local = env)
    TRUE
  }, error = function(e) e)

  rows <- list(
    data.table::data.table(
      check = "backend_config_exists",
      status = if (is.list(config_mirai) && identical(config_mirai$backend, "mirai")) "success" else "error",
      message = "Backend config object can be created."
    ),
    data.table::data.table(
      check = "mirai_availability_check",
      status = if (backend_check$status %in% c("success", "warning") && !is.null(backend_check$metadata$available)) "success" else "error",
      message = paste(c(backend_check$messages, backend_check$warnings), collapse = " ")
    ),
    data.table::data.table(
      check = "unavailable_backend_degrades",
      status = if (identical(unavailable_submit$value$status, "unavailable")) "success" else "error",
      message = paste(unavailable_submit$warnings %||% unavailable_submit$messages %||% character(), collapse = " ")
    ),
    data.table::data.table(
      check = "sync_fallback_completes",
      status = if (identical(sync_job$status, "completed") && identical(sync_result$status, "success")) "success" else "error",
      message = paste("Sync status:", sync_job$status)
    ),
    data.table::data.table(
      check = "failed_job_captured",
      status = if (identical(fail_status$value$status, "failed") && length(fail_status$value$error)) "success" else "error",
      message = paste(fail_status$value$error, collapse = " ")
    ),
    data.table::data.table(
      check = "mirai_or_fallback_submit",
      status = if (mirai_submit$status %in% c("success", "warning") && !is.null(mirai_job$job_id)) "success" else "error",
      message = paste("Backend used:", mirai_job$backend)
    ),
    data.table::data.table(
      check = "async_job_completes",
      status = if (mirai_status$value$status == "completed") "success" else "error",
      message = paste("Final status:", mirai_status$value$status)
    ),
    data.table::data.table(
      check = "result_retrievable",
      status = if (identical(mirai_result$status, "success") && !is.null(mirai_result$value)) "success" else "error",
      message = paste("Result path:", mirai_status$value$result_path)
    ),
    data.table::data.table(
      check = "registry_records_status",
      status = if (nrow(registry) >= 3L && all(c("job_id", "status", "backend", "result_path") %in% names(registry))) "success" else "error",
      message = paste("Jobs:", nrow(registry), "running:", counts$running)
    ),
    data.table::data.table(
      check = "result_path_written",
      status = if (file.exists(mirai_status$value$result_path %||% "")) "success" else "error",
      message = mirai_status$value$result_path %||% "missing"
    ),
    data.table::data.table(
      check = "app_source_passes",
      status = if (isTRUE(app_source)) "success" else "error",
      message = if (isTRUE(app_source)) "app.R sourced." else conditionMessage(app_source)
    )
  )

  data.table::rbindlist(rows, fill = TRUE)
}
