genai_audit_schema_version <- function() {
  "genai_action_audit_v1"
}

genai_audit_event_types <- function() {
  c(
    "proposal_created", "proposal_validated", "proposal_rejected",
    "approval_granted", "approval_rejected",
    "execution_started", "execution_succeeded", "execution_failed",
    "execution_cancelled", "execution_timed_out",
    "persistence_committed", "persistence_recovered",
    "inspection_opened", "policy_blocked", "resource_stale",
    "delegation_granted", "delegation_used", "delegation_denied",
    "delegation_revoked", "delegation_expired", "delegation_exhausted",
    genai_job_event_types()
  )
}

genai_audit_terminal_event_types <- function() {
  c(
    "execution_succeeded", "execution_failed", "execution_cancelled", "execution_timed_out",
    "persistence_committed", "persistence_recovered",
    "job_succeeded", "job_failed", "job_cancelled", "job_timed_out", "job_orphaned", "job_recovered"
  )
}

genai_audit_ledger_dir <- function(project, create_dir = FALSE) {
  project_log_path(project, "genai_actions", create_dir = create_dir)
}

genai_audit_ledger_path <- function(project, create_dir = FALSE) {
  dir <- genai_audit_ledger_dir(project, create_dir = create_dir)
  file.path(dir, "events.ndjson")
}

genai_audit_checkpoint_path <- function(project, create_dir = FALSE) {
  dir <- project_log_path(project, "genai_actions", "checkpoints", create_dir = create_dir)
  file.path(dir, "checkpoint.json")
}

genai_audit_safe_scalar <- function(value, max_chars = 300L) {
  if (is.null(value) || length(value) < 1L) return(NA_character_)
  value <- value[[1]]
  if (is.na(value)) return(NA_character_)
  value <- as.character(value)
  value <- gsub("[\r\n\t]+", " ", value)
  value <- trimws(value)
  if (nchar(value, type = "chars") > max_chars) {
    value <- paste0(substr(value, 1L, max_chars), "...")
  }
  value
}

genai_audit_safe_log_messages <- function(values, max_items = 8L, max_chars = 240L) {
  values <- as.character(values %||% character())
  values <- values[nzchar(values)]
  values <- utils::head(values, max_items)
  unname(vapply(values, genai_audit_safe_scalar, character(1), max_chars = max_chars))
}

genai_audit_contains_absolute_path <- function(value) {
  if (is.null(value)) return(FALSE)
  text <- paste(as.character(value), collapse = " ")
  grepl("[A-Za-z]:[\\\\/]", text) || grepl("(^|\\s)/(Users|home|tmp|var|etc|mnt|Volumes)/", text)
}

genai_audit_prohibited_names <- function() {
  c(
    "prompt", "raw_prompt", "full_prompt", "messages", "full_response", "raw_response",
    "raw_rows", "raw_data", "data", "payload", "result_payload", "temporary_result",
    "persisted_result_payload", "credentials", "api_key", "token", "secret",
    "password", "project_root", "workspace_root", "path", "absolute_path",
    "callback", "handler", "env", "environment", "connection", "stack_trace", "traceback"
  )
}

genai_audit_sanitize_event <- function(event) {
  if (!is.list(event)) {
    return(service_result(status = "error", errors = "Audit event must be a list."))
  }
  prohibited <- intersect(tolower(names(event)), genai_audit_prohibited_names())
  if (length(prohibited)) {
    return(service_result(status = "error", errors = paste("Audit event contains prohibited fields:", paste(prohibited, collapse = ", "))))
  }
  unsafe_values <- vapply(event, genai_audit_contains_absolute_path, logical(1))
  unsafe_fields <- names(event)[unsafe_values]
  allowed_path_fields <- c("safe_relative_location")
  unsafe_fields <- setdiff(unsafe_fields, allowed_path_fields)
  if (length(unsafe_fields)) {
    return(service_result(status = "error", errors = paste("Audit event contains unsafe path-like values:", paste(unsafe_fields, collapse = ", "))))
  }
  simple <- list()
  for (name in names(event)) {
    value <- event[[name]]
    if (is.function(value) || is.environment(value) || inherits(value, "connection") || typeof(value) == "externalptr") {
      return(service_result(status = "error", errors = paste("Audit event contains unsafe object:", name)))
    }
    if (is.null(value)) {
      simple[[name]] <- NULL
    } else if (is.logical(value)) {
      simple[[name]] <- isTRUE(value)
    } else if (is.numeric(value) || is.integer(value)) {
      simple[[name]] <- if (length(value)) value[[1]] else NA_real_
    } else if (is.character(value)) {
      simple[[name]] <- genai_audit_safe_scalar(value)
    } else if (is.list(value) && name %in% c("warnings", "errors")) {
      simple[[name]] <- genai_audit_safe_log_messages(value)
    } else {
      simple[[name]] <- genai_audit_safe_scalar(paste(as.character(value), collapse = ", "))
    }
  }
  service_result(status = "success", value = simple)
}

genai_audit_required_fields <- function() {
  c(
    "audit_event_id", "audit_schema_version", "event_type", "event_timestamp",
    "project_id", "action_id", "action_version", "risk_tier",
    "proposal_id", "proposal_hash", "approval_source", "policy_decision"
  )
}

genai_audit_validate_event <- function(event) {
  errors <- character()
  if (!is.list(event)) {
    return(service_result(status = "error", errors = "Audit event must be a list."))
  }
  missing <- setdiff(genai_audit_required_fields(), names(event))
  if (length(missing)) errors <- c(errors, paste("Missing required audit fields:", paste(missing, collapse = ", ")))
  if (!identical(event$audit_schema_version %||% "", genai_audit_schema_version())) errors <- c(errors, "Unsupported audit schema version.")
  if (!event$event_type %in% genai_audit_event_types()) errors <- c(errors, paste("Unsupported audit event type:", event$event_type %||% ""))
  if (!is.null(event$action_id) && !genai_action_registry_exists(event$action_id %||% "")) errors <- c(errors, paste("Unknown action_id:", event$action_id %||% ""))
  valid_statuses <- c(
    NA_character_, "approved", "running", "succeeded", "failed", "cancelled",
    "timed_out", "rejected", "blocked", "persisted", "recovered",
    "active", "revoked", "expired", "exhausted", "invalid", "denied"
  )
  if (!is.null(event$result_status) && !is.na(event$result_status) && !event$result_status %in% valid_statuses) errors <- c(errors, paste("Invalid result status:", event$result_status))
  timestamp <- tryCatch(as.POSIXct(event$event_timestamp), error = function(e) NA)
  if (is.na(timestamp)) errors <- c(errors, "Invalid audit event timestamp.")
  sanitized <- genai_audit_sanitize_event(event)
  if (!identical(sanitized$status, "success")) errors <- c(errors, sanitized$errors)
  if (length(errors)) {
    return(service_result(status = "error", errors = errors))
  }
  service_result(status = "success", value = sanitized$value)
}

genai_audit_idempotency_key <- function(event) {
  paste(
    event$event_type %||% "",
    event$project_id %||% "",
    event$action_id %||% "",
    event$proposal_id %||% "",
    event$execution_id %||% "",
    event$result_status %||% "",
    event$persisted_result_id %||% "",
    sep = "|"
  )
}

genai_audit_event_hash <- function(event, previous_event_hash = "") {
  hash_event <- event
  hash_event$event_hash <- NULL
  hash_event$previous_event_hash <- previous_event_hash %||% ""
  .genai_action_hash(hash_event)
}

genai_audit_new_event_id <- function(now = Sys.time()) {
  paste0("audit_", format(now, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
}

genai_audit_event_from_action <- function(event_type, proposal, execution = NULL, validation = NULL, ctx = NULL) {
  now <- Sys.time()
  project <- if (!is.null(ctx) && is.function(ctx$current_project)) tryCatch(ctx$current_project(), error = function(e) NULL) else NULL
  workspace <- if (!is.null(ctx) && is.function(ctx$current_workspace)) tryCatch(ctx$current_workspace(), error = function(e) NULL) else NULL
  resource_resolution <- validation$value$resource_resolution %||% validation$metadata$resource_resolution %||% list()
  list(
    audit_event_id = genai_audit_new_event_id(now),
    audit_schema_version = genai_audit_schema_version(),
    event_type = event_type,
    event_timestamp = storage_now(),
    project_id = project$project_id %||% execution$active_project_id %||% resource_resolution$active_project_id %||% NA_character_,
    workspace_provider_id = workspace$provider_id %||% execution$workspace_provider_id %||% NA_character_,
    workspace_provider_type = workspace$provider_type %||% execution$workspace_provider_type %||% NA_character_,
    action_id = proposal$action_id %||% execution$action_id %||% NA_character_,
    action_version = proposal$action_version %||% NA_character_,
    risk_tier = proposal$risk_tier %||% NA_character_,
    proposal_id = proposal$proposal_id %||% execution$proposal_id %||% NA_character_,
    proposal_hash = proposal$proposal_hash %||% NA_character_,
    execution_id = execution$execution_id %||% NA_character_,
    approval_source = proposal$approval_source %||% NA_character_,
    policy_decision = validation$value$policy_decision %||% NA_character_,
    result_status = execution$status %||% proposal$status %||% NA_character_,
    approved_at = as.character(proposal$approved_at %||% NA_character_),
    executed_at = as.character(execution$started_at %||% NA_character_),
    completed_at = as.character(execution$completed_at %||% NA_character_),
    resource_type = resource_resolution$resource_type %||% execution$result_type %||% execution$artifact_type %||% execution$report_type %||% NA_character_,
    resource_id = resource_resolution$resource_id %||% execution$persisted_result_id %||% execution$artifact_id %||% execution$report_id %||% NA_character_,
    resource_fingerprint = execution$resource_fingerprint %||% validation$value$resource_fingerprint %||% NA_character_,
    persistence_fingerprint = execution$persistence_fingerprint %||% resource_resolution$persistence_fingerprint %||% NA_character_,
    temporary_result_id = execution$temporary_result_id %||% execution$source_temporary_result_id %||% resource_resolution$temporary_result_id %||% NA_character_,
    persisted_result_id = execution$persisted_result_id %||% NA_character_,
    result_type = execution$result_type %||% execution$temporary_result_type %||% resource_resolution$temporary_result_type %||% resource_resolution$result_type %||% NA_character_,
    output_contract_version = execution$output_contract_version %||% resource_resolution$output_contract_version %||% NA_character_,
    configuration_snapshot_id = execution$configuration_snapshot_id %||% resource_resolution$configuration_snapshot_id %||% NA_character_,
    configuration_fingerprint = execution$configuration_fingerprint %||% resource_resolution$configuration_fingerprint %||% NA_character_,
    preflight_result_id = execution$preflight_result_id %||% resource_resolution$preflight_result_id %||% NA_character_,
    module_id = execution$module_id %||% resource_resolution$module_id %||% NA_character_,
    module_version = execution$module_version %||% resource_resolution$module_version %||% NA_character_,
    dataset_id = execution$dataset_id %||% resource_resolution$dataset_id %||% NA_character_,
    dataset_version = execution$dataset_version %||% resource_resolution$dataset_version %||% NA_character_,
    schema_version = execution$schema_version %||% resource_resolution$schema_version %||% NA_character_,
    job_id = execution$job_id %||% NA_character_,
    worker_backend = execution$worker_backend %||% NA_character_,
    worker_pid_hash_or_safe_id = execution$worker_pid_hash_or_safe_id %||% NA_character_,
    progress_stage = execution$progress_stage %||% NA_character_,
    last_heartbeat_at = execution$last_heartbeat_at %||% NA_character_,
    worker_terminated = isTRUE(execution$worker_terminated),
    timed_out = isTRUE(execution$timed_out),
    recovered = isTRUE(execution$recovered),
    result_fingerprint = execution$result_fingerprint %||% NA_character_,
    resource_usage = execution$resource_usage_status %||% NA_character_,
    error_code = execution$error_code %||% NA_character_,
    idempotency_key = execution$idempotency_key %||% genai_audit_idempotency_key(list(
      event_type = event_type,
      project_id = project$project_id %||% NA_character_,
      action_id = proposal$action_id %||% NA_character_,
      proposal_id = proposal$proposal_id %||% NA_character_,
      execution_id = execution$execution_id %||% NA_character_,
      result_status = execution$status %||% proposal$status %||% NA_character_,
      persisted_result_id = execution$persisted_result_id %||% NA_character_
    )),
    already_committed = isTRUE(execution$already_committed),
    ui_state_changed = isTRUE(execution$ui_state_changed),
    project_state_changed = isTRUE(execution$project_state_changed),
    persistent_changes = isTRUE(execution$persistent_changes),
    computation_performed = isTRUE(execution$computation_performed),
    temporary_result_created = isTRUE(execution$temporary_result_created),
    persisted_result_created = isTRUE(execution$persisted_result_created),
    artifact_created = isTRUE(execution$artifact_created),
    report_created = isTRUE(execution$report_created),
    safe_relative_location = execution$safe_relative_location %||% NA_character_,
    warnings = genai_audit_safe_log_messages(c(validation$warnings %||% character(), execution$warnings %||% character())),
    errors = genai_audit_safe_log_messages(c(validation$errors %||% character(), execution$errors %||% character()))
  )
}

genai_audit_project_ready <- function(project) {
  is.list(project) && identical(project$project_state %||% "", "project_ready") && nzchar(project$project_id %||% "")
}

genai_durable_audit_eligible <- function(proposal, ctx = NULL) {
  if (is.null(ctx) || !is.function(ctx$current_project)) return(FALSE)
  project <- tryCatch(ctx$current_project(), error = function(e) NULL)
  if (!genai_audit_project_ready(project)) return(FALSE)
  action_id <- proposal$action_id %||% ""
  action_id %in% c("module.open", "artifact.inspect", "report.open", "analysis.preflight", "analysis.run_registered", "result.persist", "result.inspect")
}

genai_audit_read_events <- function(project, validate_hash_chain = TRUE) {
  if (!genai_audit_project_ready(project)) {
    return(service_result(status = "error", errors = "No ready project is available for audit discovery."))
  }
  path <- tryCatch(genai_audit_ledger_path(project, create_dir = FALSE), error = function(e) NULL)
  if (is.null(path) || !file.exists(path)) {
    return(service_result(
      status = "success",
      value = list(events = data.table::data.table(), ledger_health = "missing", ledger_path = "logs/genai_actions/events.ndjson", malformed_count = 0L)
    ))
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    return(service_result(status = "error", errors = "jsonlite is required to read the GenAI action audit ledger."))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!length(lines)) {
    return(service_result(
      status = "success",
      value = list(events = data.table::data.table(), ledger_health = "healthy", ledger_path = "logs/genai_actions/events.ndjson", malformed_count = 0L)
    ))
  }
  parsed <- list()
  malformed <- 0L
  health <- "healthy"
  previous_hash <- ""
  for (i in seq_along(lines)) {
    line <- lines[[i]]
    if (!nzchar(trimws(line))) next
    item <- tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE), error = function(e) structure(list(error = conditionMessage(e)), class = "audit_parse_error"))
    if (inherits(item, "audit_parse_error")) {
      malformed <- malformed + 1L
      health <- if (i == length(lines)) "partial_tail" else "malformed"
      next
    }
    if (!identical(item$audit_schema_version %||% "", genai_audit_schema_version())) {
      health <- "unsupported_schema"
    }
    if (isTRUE(validate_hash_chain) && health %in% c("healthy", "unsupported_schema")) {
      expected_hash <- genai_audit_event_hash(item, previous_hash)
      if (!identical(item$previous_event_hash %||% "", previous_hash) || !identical(item$event_hash %||% "", expected_hash)) {
        health <- "hash_chain_mismatch"
      }
      previous_hash <- item$event_hash %||% previous_hash
    } else {
      previous_hash <- item$event_hash %||% previous_hash
    }
    parsed[[length(parsed) + 1L]] <- item
  }
  normalize_record <- function(x) {
    out <- lapply(x, function(value) {
      if (is.null(value) || length(value) == 0L) {
        NA_character_
      } else if (is.list(value)) {
        paste(vapply(value, genai_audit_safe_scalar, character(1)), collapse = "; ")
      } else if (length(value) > 1L) {
        paste(as.character(value), collapse = "; ")
      } else {
        value
      }
    })
    as.data.frame(out, stringsAsFactors = FALSE)
  }
  events <- if (length(parsed)) data.table::rbindlist(lapply(parsed, normalize_record), fill = TRUE) else data.table::data.table()
  service_result(
    status = "success",
    value = list(events = events, ledger_health = health, ledger_path = "logs/genai_actions/events.ndjson", malformed_count = malformed)
  )
}

genai_audit_write_checkpoint <- function(project, events, event) {
  path <- genai_audit_checkpoint_path(project, create_dir = TRUE)
  checkpoint <- list(
    schema_version = genai_audit_schema_version(),
    event_count = nrow(events) + 1L,
    last_event_id = event$audit_event_id,
    last_event_timestamp = event$event_timestamp,
    last_event_hash = event$event_hash,
    updated_at = storage_now()
  )
  atomic_save_json(checkpoint, path, pretty = TRUE)
}

genai_audit_append_event <- function(project, workspace, event) {
  if (!genai_audit_project_ready(project)) {
    return(service_result(status = "error", errors = "No ready project is available for durable audit writes."))
  }
  path <- tryCatch(genai_audit_ledger_path(project, create_dir = TRUE), error = function(e) NULL)
  if (is.null(path)) {
    return(service_result(status = "error", errors = "Audit ledger path could not be resolved."))
  }
  gate <- persistent_write_gate(workspace, project, path, "genai_action_audit")
  if (!identical(gate$status, "success")) {
    return(service_result(status = "error", errors = gate$errors, metadata = list(write_gate = gate)))
  }
  validation <- genai_audit_validate_event(event)
  if (!identical(validation$status, "success")) {
    return(service_result(status = "error", errors = validation$errors))
  }
  event <- validation$value
  existing <- genai_audit_read_events(project)
  if (!identical(existing$status, "success")) {
    return(existing)
  }
  events <- existing$value$events
  event$audit_idempotency_key <- genai_audit_idempotency_key(event)
  if (nrow(events) && "audit_idempotency_key" %in% names(events) && event$audit_idempotency_key %in% events$audit_idempotency_key) {
    matched <- events[events$audit_idempotency_key == event$audit_idempotency_key][1]
    return(service_result(
      status = "success",
      value = list(audit_event_id = matched$audit_event_id[[1]], already_recorded = TRUE, durable = TRUE, ledger_health = existing$value$ledger_health),
      messages = "Audit event already recorded."
    ))
  }
  previous_hash <- if (nrow(events) && "event_hash" %in% names(events)) tail(events$event_hash, 1L) else ""
  event$previous_event_hash <- previous_hash %||% ""
  event$event_hash <- genai_audit_event_hash(event, event$previous_event_hash)
  line <- jsonlite::toJSON(event, auto_unbox = TRUE, null = "null", digits = NA)
  tryCatch({
    con <- file(path, open = "ab")
    on.exit(close(con), add = TRUE)
    writeBin(charToRaw(paste0(line, "\n")), con)
    genai_audit_write_checkpoint(project, events, event)
    service_result(
      status = "success",
      value = list(audit_event_id = event$audit_event_id, already_recorded = FALSE, durable = TRUE, ledger_health = existing$value$ledger_health),
      messages = "Audit event written."
    )
  }, error = function(e) {
    service_result(status = "error", errors = paste("Audit append failed:", conditionMessage(e)))
  })
}

genai_record_durable_audit <- function(event_type, proposal, execution = NULL, validation = NULL, ctx = NULL) {
  if (!genai_durable_audit_eligible(proposal, ctx)) {
    return(service_result(status = "success", value = list(durable = FALSE, skipped = TRUE), messages = "Durable audit not eligible."))
  }
  project <- tryCatch(ctx$current_project(), error = function(e) NULL)
  workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
  event <- genai_audit_event_from_action(event_type, proposal, execution, validation, ctx)
  genai_audit_append_event(project, workspace, event)
}

genai_project_audit_summary <- function(project) {
  result <- genai_audit_read_events(project)
  if (!identical(result$status, "success")) {
    return(data.table::data.table(ledger_health = "unavailable", event_count = 0L, terminal_count = 0L, malformed_count = NA_integer_))
  }
  events <- result$value$events
  data.table::data.table(
    ledger_health = result$value$ledger_health,
    event_count = nrow(events),
    terminal_count = if (nrow(events) && "event_type" %in% names(events)) sum(events$event_type %in% genai_audit_terminal_event_types(), na.rm = TRUE) else 0L,
    malformed_count = result$value$malformed_count %||% 0L
  )
}

genai_reconcile_persisted_results_audit <- function(project) {
  results <- list_project_persisted_results(project, include_invalid = FALSE)
  audit <- genai_audit_read_events(project)
  if (!identical(audit$status, "success")) {
    return(service_result(status = "error", errors = audit$errors))
  }
  events <- audit$value$events
  if (!nrow(results)) {
    return(service_result(status = "success", value = data.table::data.table()))
  }
  rows <- lapply(seq_len(nrow(results)), function(i) {
    row <- results[i]
    matched <- if (nrow(events) && "persisted_result_id" %in% names(events)) {
      events[events$persisted_result_id == row$persisted_result_id & events$event_type %in% c("persistence_committed", "persistence_recovered", "execution_succeeded")]
    } else {
      data.table::data.table()
    }
    duplicate_terminal <- if (nrow(matched)) {
      sum(matched$event_type %in% c("persistence_committed", "persistence_recovered"), na.rm = TRUE) > 1L
    } else {
      FALSE
    }
    project_mismatch <- if (nrow(matched) && "project_id" %in% names(matched)) {
      any(!is.na(matched$project_id) & matched$project_id != project$project_id)
    } else {
      FALSE
    }
    status <- if (!nrow(matched)) {
      "missing_audit_event"
    } else if (isTRUE(project_mismatch)) {
      "project_mismatch"
    } else if (isTRUE(duplicate_terminal)) {
      "duplicate_terminal_event"
    } else {
      "matched"
    }
    data.table::data.table(
      persisted_result_id = row$persisted_result_id,
      display_name = row$display_name %||% row$persisted_result_id,
      result_type = row$result_type %||% NA_character_,
      reconciliation_status = status,
      matching_audit_events = nrow(matched),
      latest_audit_event = if (nrow(matched)) tail(matched$audit_event_id, 1L) else NA_character_
    )
  })
  service_result(status = "success", value = data.table::rbindlist(rows, fill = TRUE))
}

qa_genai_action_audit_ledger <- function(output_dir = file.path(tempdir(), "genai_action_audit_ledger_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  provider <- storage_provider(
    provider_id = "audit_qa_provider",
    provider_type = "local_server_directory",
    display_name = "Audit QA Provider",
    root_path = output_dir,
    available = TRUE,
    writable = TRUE,
    capabilities = list(supports_external_projects = TRUE, can_choose_directory = TRUE)
  )
  workspace <- validate_workspace_root(output_dir, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
  project <- create_project_in_workspace(workspace, "Audit QA", project_id = "audit_qa_project")$value
  ctx <- new.env(parent = emptyenv())
  ctx$current_workspace <- function() workspace
  ctx$current_project <- function() project
  ctx$selected_module <- NULL
  ctx$select_analysis_module <- function(module_id) {
    ctx$selected_module <- module_id
    TRUE
  }
  ctx$genai_action_proposal_executed <- function(proposal_id) FALSE
  ctx$mark_genai_action_proposal_executed <- function(proposal_id) TRUE
  proposal <- genai_action_proposal(
    action_id = "result.inspect",
    action_version = "1.0",
    arguments = list(persisted_result_id = "persisted_qa_result"),
    rationale = "Inspect a persisted result.",
    expected_effects = "Open persisted result",
    risk_tier = "low"
  )
  proposal$status <- "approved"
  proposal$approved_at <- Sys.time()
  proposal$approval_source <- "user"
  proposal$approval_hash <- proposal$proposal_hash
  validation <- service_result(status = "success", value = list(valid = TRUE, policy_decision = "approved", resource_fingerprint = "fingerprint_qa", resource_resolution = list(resource_id = "persisted_qa_result")))
  execution <- list(
    execution_id = "execution_qa_001",
    action_id = "result.inspect",
    proposal_id = proposal$proposal_id,
    status = "succeeded",
    started_at = Sys.time(),
    completed_at = Sys.time(),
    persisted_result_id = "persisted_qa_result",
    persistent_changes = FALSE,
    ui_state_changed = TRUE,
    project_state_changed = FALSE,
    computation_performed = FALSE
  )
  append_a <- genai_record_durable_audit("execution_succeeded", proposal, execution, validation, ctx)
  append_b <- genai_record_durable_audit("execution_succeeded", proposal, execution, validation, ctx)
  read_a <- genai_audit_read_events(project)
  module_proposal <- genai_action_proposal(
    action_id = "module.open",
    action_version = "1.0",
    arguments = list(module_id = "autoquant_eda"),
    rationale = "Open Explore Data.",
    expected_effects = "Open Explore Data",
    risk_tier = "low"
  )
  module_validation <- genai_validate_action_proposal(module_proposal, ctx = ctx)
  module_approval <- genai_approve_action_proposal(module_proposal, module_validation, "user")
  module_execution <- genai_execute_action_proposal(module_approval$value, ctx = ctx, approval_hash = module_approval$value$approval_hash)
  read_after_execution <- genai_audit_read_events(project)
  unsafe_event <- genai_audit_event_from_action("execution_succeeded", proposal, execution, validation, ctx)
  unsafe_event$raw_prompt <- "do a thing"
  unsafe_validation <- genai_audit_validate_event(unsafe_event)
  bad_line_path <- genai_audit_ledger_path(project)
  writeLines("{not-json", bad_line_path, sep = "\n", useBytes = TRUE)
  partial <- genai_audit_read_events(project)
  rows <- data.table::data.table(
    check = c(
      "ledger_path_project_scoped", "valid_event_appended", "duplicate_prevented",
      "restart_read_events", "hash_chain_healthy", "action_layer_emits_durable_events",
      "action_layer_keeps_session_audit", "prohibited_prompt_rejected",
      "malformed_tail_classified", "summary_available", "reconcile_empty_safe"
    ),
    status = c(
      if (path_within_root(genai_audit_ledger_path(project), project$project_root)) "success" else "error",
      if (identical(append_a$status, "success") && isFALSE(append_a$value$already_recorded)) "success" else "error",
      if (identical(append_b$status, "success") && isTRUE(append_b$value$already_recorded)) "success" else "error",
      if (identical(read_a$status, "success") && nrow(read_a$value$events) == 1L) "success" else "error",
      if (identical(read_a$value$ledger_health, "healthy")) "success" else "error",
      if (identical(module_execution$status, "success") && nrow(read_after_execution$value$events) >= 4L && all(c("approval_granted", "execution_started", "execution_succeeded") %in% read_after_execution$value$events$event_type)) "success" else "error",
      if (data.table::is.data.table(module_execution$metadata$audit_event)) "success" else "error",
      if (identical(unsafe_validation$status, "error")) "success" else "error",
      if (identical(partial$value$ledger_health, "partial_tail")) "success" else "error",
      if (nrow(genai_project_audit_summary(project)) == 1L) "success" else "error",
      if (identical(genai_reconcile_persisted_results_audit(project)$status, "success")) "success" else "error"
    ),
    message = c(
      "Ledger resolves beneath the project logs directory.",
      "A valid durable event appends to NDJSON.",
      "Retrying the same event returns already_recorded.",
      "Restart discovery reads the complete event.",
      "Hash chaining validates a clean ledger.",
      "Approved project-scoped action execution emits durable events.",
      "Existing session-local audit event remains available.",
      "Raw prompt fields are rejected.",
      "Malformed trailing content is classified without rewriting the ledger.",
      "Project audit summary is available.",
      "Reconciliation handles projects with no persisted results."
    )
  )
  rows
}
