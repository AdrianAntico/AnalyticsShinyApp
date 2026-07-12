improvement_item_schema_version <- function() "improvement_item_v1"
improvement_event_schema_version <- function() "improvement_event_v1"
improvement_finding_schema_version <- function() "improvement_finding_v1"
improvement_remediation_schema_version <- function() "improvement_remediation_v1"
improvement_attempt_schema_version <- function() "improvement_attempt_v1"
improvement_re_evaluation_schema_version <- function() "improvement_re_evaluation_v1"
improvement_checkpoint_schema_version <- function() "improvement_ledger_checkpoint_v1"

improvement_item_types <- function() {
  c(
    "execution_failure", "validation_failure", "worker_failure", "resource_stale",
    "data_quality_issue", "analysis_quality_issue", "model_quality_issue",
    "configuration_gap", "project_storage_issue", "provider_issue", "audit_issue",
    "result_integrity_issue", "ux_problem", "documentation_gap", "architecture_debt",
    "compatibility_issue", "enhancement_opportunity", "low_confidence_concern",
    "user_requested_change", "accepted_limitation", "policy_block"
  )
}

improvement_source_types <- function() {
  c(
    "deterministic_check", "genai_assessment", "user", "mission_control", "qa",
    "audit_reconciliation", "action_execution", "worker_runtime",
    "persisted_result_validation", "technical_debt_register", "project_load",
    "storage_validation", "manual_import"
  )
}

improvement_statuses <- function() {
  c(
    "detected", "triage_required", "accepted", "planned", "in_progress",
    "awaiting_user_input", "awaiting_approval", "remediation_proposed",
    "remediation_running", "re_evaluation_required", "resolved",
    "partially_resolved", "unresolved", "deferred", "accepted_limitation",
    "rejected", "duplicate", "superseded"
  )
}

improvement_terminal_statuses <- function() {
  c("resolved", "partially_resolved", "unresolved", "deferred", "accepted_limitation", "rejected", "duplicate", "superseded")
}

improvement_severities <- function() c("informational", "low", "medium", "high", "critical")
improvement_priorities <- function() c("backlog", "normal", "high", "urgent")
improvement_confidences <- function() c("high", "medium", "low", "unknown")
improvement_confidence_bases <- function() {
  c(
    "deterministic_failure", "threshold_breach", "multiple_evidence_sources",
    "single_evidence_source", "genai_inference", "user_assertion", "heuristic"
  )
}

improvement_evidence_types <- function() {
  c(
    "mission_control_alert", "preflight_result", "temporary_result", "persisted_result",
    "audit_event", "worker_job", "qa_check", "technical_debt_item",
    "project_resource", "artifact", "report_plan", "module_configuration",
    "user_feedback", "storage_validation", "result_validation"
  )
}

improvement_evidence_relationships <- function() {
  c("supports", "contradicts", "triggered_by", "resolved_by", "introduced_by", "re_evaluated_by")
}

improvement_relationship_types <- function() {
  c("duplicate_of", "blocked_by", "blocks", "caused_by", "related_to", "supersedes", "parent_of", "child_of", "regression_of")
}

improvement_event_types <- function() {
  c(
    "item_detected", "item_created", "item_updated", "item_triaged",
    "item_accepted", "item_rejected", "item_deferred", "item_assigned",
    "priority_changed", "severity_changed", "user_feedback_added",
    "remediation_proposed", "remediation_approved", "remediation_rejected",
    "remediation_started", "remediation_succeeded", "remediation_failed",
    "re_evaluation_started", "re_evaluation_completed", "item_resolved",
    "item_partially_resolved", "item_reopened", "item_marked_duplicate",
    "item_marked_accepted_limitation"
  )
}

improvement_remediation_types <- function() {
  c(
    "rerun_preflight", "rerun_analysis", "inspect_result", "inspect_artifact",
    "open_module", "update_configuration_manually", "change_project_setting",
    "repair_result_manually", "review_data_quality", "create_technical_debt_item",
    "defer", "accept_limitation", "request_user_input"
  )
}

improvement_registered_action_map <- function() {
  list(
    rerun_preflight = "analysis.preflight",
    rerun_analysis = "analysis.run_registered",
    inspect_result = "result.inspect",
    inspect_artifact = "artifact.inspect",
    open_module = "module.open",
    create_technical_debt_item = NA_character_,
    update_configuration_manually = NA_character_,
    change_project_setting = NA_character_,
    repair_result_manually = NA_character_,
    review_data_quality = NA_character_,
    defer = NA_character_,
    accept_limitation = NA_character_,
    request_user_input = NA_character_
  )
}

improvement_status_transition_map <- function() {
  list(
    detected = c("triage_required", "accepted", "rejected", "deferred", "accepted_limitation", "duplicate", "superseded"),
    triage_required = c("accepted", "rejected", "deferred", "accepted_limitation", "awaiting_user_input", "duplicate", "superseded"),
    accepted = c("planned", "in_progress", "remediation_proposed", "awaiting_approval", "re_evaluation_required", "deferred", "accepted_limitation", "rejected"),
    planned = c("in_progress", "remediation_proposed", "awaiting_approval", "deferred", "accepted_limitation"),
    in_progress = c("remediation_running", "re_evaluation_required", "partially_resolved", "unresolved", "deferred"),
    awaiting_user_input = c("triage_required", "accepted", "rejected", "deferred", "accepted_limitation"),
    awaiting_approval = c("remediation_proposed", "remediation_running", "accepted", "rejected", "deferred"),
    remediation_proposed = c("awaiting_approval", "remediation_running", "planned", "rejected", "deferred"),
    remediation_running = c("re_evaluation_required", "partially_resolved", "unresolved", "deferred"),
    re_evaluation_required = c("resolved", "partially_resolved", "unresolved", "accepted_limitation", "deferred"),
    resolved = c("triage_required", "accepted", "re_evaluation_required"),
    partially_resolved = c("planned", "in_progress", "re_evaluation_required", "resolved", "deferred", "accepted_limitation"),
    unresolved = c("planned", "in_progress", "deferred", "accepted_limitation"),
    deferred = c("triage_required", "accepted", "planned"),
    accepted_limitation = c("triage_required", "accepted"),
    rejected = c("triage_required", "accepted"),
    duplicate = c("triage_required", "accepted"),
    superseded = c("triage_required", "accepted")
  )
}

improvement_ledger_dir <- function(project, create_dir = FALSE) {
  project_path(project, "governance", "improvement_ledger", create_dir = create_dir)
}

improvement_items_dir <- function(project, create_dir = FALSE) {
  dir <- file.path(improvement_ledger_dir(project, create_dir = create_dir), "items")
  if (isTRUE(create_dir) && !dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

improvement_event_log_path <- function(project, create_dir = FALSE) {
  file.path(improvement_ledger_dir(project, create_dir = create_dir), "events.ndjson")
}

improvement_checkpoint_path <- function(project, create_dir = FALSE) {
  dir <- file.path(improvement_ledger_dir(project, create_dir = create_dir), "checkpoints")
  if (isTRUE(create_dir) && !dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, "checkpoint.json")
}

improvement_item_path <- function(project, item_id, create_dir = FALSE) {
  if (!storage_resource_id_is_valid(item_id)) {
    stop("Improvement item id is malformed.", call. = FALSE)
  }
  file.path(improvement_items_dir(project, create_dir = create_dir), paste0(item_id, ".json"))
}

improvement_safe_scalar <- function(value, max_chars = 1000L) {
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

improvement_contains_absolute_path <- function(value) {
  if (is.null(value)) return(FALSE)
  text <- paste(as.character(value), collapse = " ")
  grepl("[A-Za-z]:[\\\\/]", text) || grepl("(^|\\s)/(Users|home|tmp|var|etc|mnt|Volumes)/", text)
}

improvement_contains_code <- function(value) {
  if (is.null(value)) return(FALSE)
  text <- paste(as.character(value), collapse = " ")
  grepl("(<script|function\\s*\\(|system\\s*\\(|shell\\s*\\(|eval\\s*\\(|source\\s*\\(|::|<-)", text, ignore.case = TRUE)
}

improvement_has_unsafe_object <- function(x) {
  if (is.function(x) || is.environment(x) || inherits(x, "connection") || typeof(x) == "externalptr") {
    return(TRUE)
  }
  if (is.list(x)) {
    return(any(vapply(x, improvement_has_unsafe_object, logical(1))))
  }
  FALSE
}

improvement_normalize_signature <- function(...) {
  parts <- unlist(list(...), use.names = FALSE)
  parts <- as.character(parts[!is.na(parts) & nzchar(as.character(parts))])
  text <- tolower(paste(parts, collapse = ":"))
  text <- gsub("[^a-z0-9_.:-]+", "_", text)
  text <- gsub("_+", "_", text)
  gsub("^_+|_+$", "", text)
}

improvement_item_id_from_signature <- function(project_id, signature) {
  paste0("imp_", substr(storage_hash_value(paste(project_id %||% "", signature %||% "", sep = "|")), 1L, 16L))
}

improvement_evidence_ref <- function(evidence_type, evidence_id, relationship = "supports", captured_at = storage_now(), summary = NULL) {
  list(
    evidence_type = as.character(evidence_type %||% NA_character_),
    evidence_id = as.character(evidence_id %||% NA_character_),
    relationship = as.character(relationship %||% "supports"),
    captured_at = as.character(captured_at %||% storage_now()),
    summary = improvement_safe_scalar(summary, max_chars = 300L)
  )
}

improvement_validate_evidence_ref <- function(ref, valid_evidence_ids = NULL) {
  errors <- character()
  if (!is.list(ref)) return(service_result(status = "error", errors = "Evidence reference must be a list."))
  if (!(ref$evidence_type %||% "") %in% improvement_evidence_types()) errors <- c(errors, paste("Invalid evidence type:", ref$evidence_type %||% "missing"))
  if (!storage_resource_id_is_valid(ref$evidence_id %||% "")) errors <- c(errors, paste("Invalid evidence id:", ref$evidence_id %||% "missing"))
  if (!(ref$relationship %||% "") %in% improvement_evidence_relationships()) errors <- c(errors, paste("Invalid evidence relationship:", ref$relationship %||% "missing"))
  if (!is.null(valid_evidence_ids) && !(ref$evidence_id %||% "") %in% valid_evidence_ids) errors <- c(errors, paste("Evidence id is not trusted:", ref$evidence_id %||% "missing"))
  if (improvement_contains_absolute_path(ref) || improvement_contains_code(ref)) errors <- c(errors, "Evidence reference contains unsafe content.")
  if (length(errors)) service_result(status = "error", errors = errors) else service_result(status = "success", value = ref)
}

improvement_finding <- function(
  finding_type,
  title,
  summary,
  severity = "medium",
  confidence = "unknown",
  evidence_refs = list(),
  affected_resource = list(resource_type = NA_character_, resource_id = NA_character_),
  recommended_remediation_types = character(),
  source_result_id = NA_character_
) {
  list(
    finding_id = paste0("finding_", substr(storage_hash_value(list(finding_type, title, summary, source_result_id)), 1L, 16L)),
    finding_schema_version = improvement_finding_schema_version(),
    finding_type = finding_type,
    title = improvement_safe_scalar(title, 160L),
    summary = improvement_safe_scalar(summary, 1000L),
    severity = severity,
    confidence = confidence,
    evidence_refs = evidence_refs,
    affected_resource = affected_resource,
    recommended_remediation_types = recommended_remediation_types,
    created_at = storage_now(),
    source_result_id = source_result_id
  )
}

improvement_remediation <- function(
  remediation_type,
  title,
  description = NULL,
  risk_tier = "low",
  expected_effect = NULL,
  required_actions = character(),
  required_user_input = character(),
  approval_required = TRUE,
  delegation_eligible = FALSE,
  estimated_effort = "unknown",
  confidence = "unknown",
  evidence_refs = list(),
  status = "proposed"
) {
  remediation_type <- as.character(remediation_type %||% "")
  action_map <- improvement_registered_action_map()
  mapped_action <- action_map[[remediation_type]] %||% NA_character_
  if (!is.na(mapped_action)) {
    required_actions <- unique(c(required_actions, mapped_action))
  }
  list(
    remediation_id = paste0("rem_", substr(storage_hash_value(list(remediation_type, title, Sys.time())), 1L, 16L)),
    remediation_schema_version = improvement_remediation_schema_version(),
    remediation_type = remediation_type,
    title = improvement_safe_scalar(title, 160L),
    description = improvement_safe_scalar(description %||% "", 1000L),
    risk_tier = risk_tier,
    expected_effect = improvement_safe_scalar(expected_effect %||% "", 500L),
    required_actions = as.character(required_actions %||% character()),
    required_user_input = as.character(required_user_input %||% character()),
    approval_required = isTRUE(approval_required),
    delegation_eligible = isTRUE(delegation_eligible),
    estimated_effort = improvement_safe_scalar(estimated_effort, 80L),
    confidence = confidence,
    evidence_refs = evidence_refs,
    status = status,
    created_at = storage_now()
  )
}

improvement_validate_remediation <- function(remediation) {
  errors <- character()
  if (!is.list(remediation)) return(service_result(status = "error", errors = "Remediation must be a list."))
  if (!identical(remediation$remediation_schema_version %||% "", improvement_remediation_schema_version())) errors <- c(errors, "Unsupported remediation schema.")
  if (!(remediation$remediation_type %||% "") %in% improvement_remediation_types()) errors <- c(errors, paste("Unsupported remediation type:", remediation$remediation_type %||% "missing"))
  if (!(remediation$confidence %||% "unknown") %in% improvement_confidences()) errors <- c(errors, "Invalid remediation confidence.")
  if (improvement_contains_absolute_path(remediation) || improvement_contains_code(remediation)) errors <- c(errors, "Remediation contains unsafe path or executable content.")
  actions <- as.character(remediation$required_actions %||% character())
  if (length(actions)) {
    invalid <- actions[!vapply(actions, function(action) {
      exists("genai_action_registry_exists", mode = "function") && isTRUE(genai_action_registry_exists(action))
    }, logical(1))]
    if (length(invalid)) errors <- c(errors, paste("Unsupported remediation action:", paste(invalid, collapse = ", ")))
  }
  if (length(errors)) service_result(status = "error", errors = errors) else service_result(status = "success", value = remediation)
}

improvement_new_item <- function(
  project,
  item_type,
  title,
  description,
  source_type,
  source_id = NA_character_,
  status = NULL,
  severity = "medium",
  priority = "normal",
  confidence = "unknown",
  confidence_basis = "heuristic",
  affected_component = NA_character_,
  affected_resource_type = NA_character_,
  affected_resource_id = NA_character_,
  evidence_refs = list(),
  finding_refs = character(),
  audit_refs = character(),
  technical_debt_refs = character(),
  related_item_ids = character(),
  recommended_remediations = list(),
  resolution_criteria = character(),
  current_assessment = NULL,
  tags = character(),
  intentional_for_now = FALSE,
  normalized_issue_signature = NULL
) {
  if (is.null(status)) {
    status <- if (identical(source_type, "genai_assessment")) "triage_required" else "detected"
  }
  signature <- normalized_issue_signature %||% improvement_normalize_signature(
    item_type, affected_resource_type, affected_resource_id, title
  )
  item_id <- improvement_item_id_from_signature(project$project_id, signature)
  list(
    item_id = item_id,
    item_schema_version = improvement_item_schema_version(),
    project_id = project$project_id %||% NA_character_,
    item_type = item_type,
    title = improvement_safe_scalar(title, 160L),
    description = improvement_safe_scalar(description, 2000L),
    status = status,
    severity = severity,
    priority = priority,
    confidence = confidence,
    confidence_basis = confidence_basis,
    source_type = source_type,
    source_id = as.character(source_id %||% NA_character_),
    detected_at = storage_now(),
    created_at = storage_now(),
    updated_at = storage_now(),
    last_detected_at = storage_now(),
    occurrence_count = 1L,
    affected_component = improvement_safe_scalar(affected_component, 120L),
    affected_resource_type = improvement_safe_scalar(affected_resource_type, 120L),
    affected_resource_id = improvement_safe_scalar(affected_resource_id, 160L),
    normalized_issue_signature = signature,
    evidence_refs = evidence_refs,
    finding_refs = as.character(finding_refs %||% character()),
    audit_refs = as.character(audit_refs %||% character()),
    technical_debt_refs = as.character(technical_debt_refs %||% character()),
    related_item_ids = as.character(related_item_ids %||% character()),
    recommended_remediations = recommended_remediations,
    resolution_criteria = as.character(resolution_criteria %||% character()),
    current_assessment = improvement_safe_scalar(current_assessment %||% "", 1000L),
    user_feedback = list(),
    attempt_history = list(),
    re_evaluation_history = list(),
    decision_history = list(),
    assigned_to = NA_character_,
    tags = as.character(tags %||% character()),
    intentional_for_now = isTRUE(intentional_for_now)
  )
}

improvement_required_item_fields <- function() {
  c(
    "item_id", "item_schema_version", "project_id", "item_type", "title",
    "description", "status", "severity", "priority", "confidence",
    "confidence_basis", "source_type", "source_id", "created_at", "updated_at",
    "affected_component", "affected_resource_type", "affected_resource_id",
    "evidence_refs", "recommended_remediations", "resolution_criteria",
    "user_feedback", "attempt_history", "re_evaluation_history", "decision_history",
    "normalized_issue_signature", "occurrence_count", "intentional_for_now"
  )
}

improvement_validate_item <- function(item, project = NULL) {
  errors <- character()
  if (!is.list(item)) return(service_result(status = "error", errors = "Improvement item must be a list."))
  missing <- setdiff(improvement_required_item_fields(), names(item))
  if (length(missing)) errors <- c(errors, paste("Missing required item fields:", paste(missing, collapse = ", ")))
  if (!identical(item$item_schema_version %||% "", improvement_item_schema_version())) errors <- c(errors, "Unsupported improvement item schema.")
  if (!storage_resource_id_is_valid(item$item_id %||% "")) errors <- c(errors, "Invalid item_id.")
  if (!(item$item_type %||% "") %in% improvement_item_types()) errors <- c(errors, paste("Invalid item_type:", item$item_type %||% "missing"))
  if (!(item$status %||% "") %in% improvement_statuses()) errors <- c(errors, paste("Invalid status:", item$status %||% "missing"))
  if (!(item$severity %||% "") %in% improvement_severities()) errors <- c(errors, paste("Invalid severity:", item$severity %||% "missing"))
  if (!(item$priority %||% "") %in% improvement_priorities()) errors <- c(errors, paste("Invalid priority:", item$priority %||% "missing"))
  if (!(item$confidence %||% "") %in% improvement_confidences()) errors <- c(errors, paste("Invalid confidence:", item$confidence %||% "missing"))
  if (!(item$confidence_basis %||% "") %in% improvement_confidence_bases()) errors <- c(errors, paste("Invalid confidence_basis:", item$confidence_basis %||% "missing"))
  if (!(item$source_type %||% "") %in% improvement_source_types()) errors <- c(errors, paste("Invalid source_type:", item$source_type %||% "missing"))
  if (!is.null(project) && !identical(item$project_id %||% "", project$project_id %||% "")) errors <- c(errors, "Item project_id does not match active project.")
  if (nchar(item$title %||% "", type = "chars") > 180L) errors <- c(errors, "Title is oversized.")
  if (nchar(item$description %||% "", type = "chars") > 2200L) errors <- c(errors, "Description is oversized.")
  if (improvement_has_unsafe_object(item)) errors <- c(errors, "Item contains unsafe executable object.")
  path_check <- item
  path_check$safe_relative_location <- NULL
  if (improvement_contains_absolute_path(path_check)) errors <- c(errors, "Item contains an absolute path.")
  if (improvement_contains_code(item$title) || improvement_contains_code(item$description)) errors <- c(errors, "Item title or description contains executable-looking content.")
  evidence_results <- lapply(item$evidence_refs %||% list(), improvement_validate_evidence_ref)
  evidence_errors <- unlist(lapply(evidence_results, function(x) x$errors %||% character()), use.names = FALSE)
  if (length(evidence_errors)) errors <- c(errors, evidence_errors)
  remediation_results <- lapply(item$recommended_remediations %||% list(), improvement_validate_remediation)
  remediation_errors <- unlist(lapply(remediation_results, function(x) x$errors %||% character()), use.names = FALSE)
  if (length(remediation_errors)) errors <- c(errors, remediation_errors)
  if (length(errors)) service_result(status = "error", errors = unique(errors)) else service_result(status = "success", value = item)
}

improvement_item_safe_transition <- function(item, to_status, rationale = NULL) {
  from <- item$status %||% "detected"
  to_status <- as.character(to_status %||% "")
  if (!to_status %in% improvement_statuses()) {
    return(service_result(status = "error", errors = paste("Invalid target status:", to_status)))
  }
  allowed <- improvement_status_transition_map()[[from]] %||% character()
  if (to_status == from || to_status %in% allowed) {
    item$status <- to_status
    item$updated_at <- storage_now()
    item$decision_history <- c(item$decision_history %||% list(), list(list(
      decision_at = storage_now(),
      from_status = from,
      to_status = to_status,
      rationale = improvement_safe_scalar(rationale %||% "", 500L)
    )))
    return(service_result(status = "success", value = item))
  }
  service_result(status = "error", errors = paste("Invalid status transition:", from, "->", to_status))
}

improvement_event_hash <- function(event, previous_event_hash = "") {
  hash_event <- event
  hash_event$event_hash <- NULL
  hash_event$previous_event_hash <- previous_event_hash %||% ""
  storage_hash_value(hash_event)
}

improvement_new_event_id <- function(now = Sys.time()) {
  paste0("impevt_", format(now, "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L))
}

improvement_event <- function(event_type, item, summary = NULL, actor = "application", idempotency_key = NULL, metadata = list()) {
  list(
    improvement_event_id = improvement_new_event_id(),
    improvement_event_schema_version = improvement_event_schema_version(),
    event_type = event_type,
    event_timestamp = storage_now(),
    item_id = item$item_id %||% NA_character_,
    project_id = item$project_id %||% NA_character_,
    actor = improvement_safe_scalar(actor, 80L),
    summary = improvement_safe_scalar(summary %||% item$title %||% event_type, 500L),
    idempotency_key = idempotency_key %||% paste(event_type, item$item_id %||% "", item$updated_at %||% "", sep = "|"),
    status = item$status %||% NA_character_,
    severity = item$severity %||% NA_character_,
    priority = item$priority %||% NA_character_,
    source_type = item$source_type %||% NA_character_,
    source_id = item$source_id %||% NA_character_,
    metadata = metadata
  )
}

improvement_validate_event <- function(event) {
  errors <- character()
  required <- c("improvement_event_id", "improvement_event_schema_version", "event_type", "event_timestamp", "item_id", "project_id", "idempotency_key")
  missing <- setdiff(required, names(event))
  if (length(missing)) errors <- c(errors, paste("Missing event fields:", paste(missing, collapse = ", ")))
  if (!identical(event$improvement_event_schema_version %||% "", improvement_event_schema_version())) errors <- c(errors, "Unsupported improvement event schema.")
  if (!(event$event_type %||% "") %in% improvement_event_types()) errors <- c(errors, paste("Unsupported improvement event type:", event$event_type %||% "missing"))
  if (!storage_resource_id_is_valid(event$item_id %||% "")) errors <- c(errors, "Invalid event item_id.")
  if (improvement_contains_absolute_path(event) || improvement_contains_code(event)) errors <- c(errors, "Improvement event contains unsafe content.")
  if (improvement_has_unsafe_object(event)) errors <- c(errors, "Improvement event contains unsafe object.")
  if (length(errors)) service_result(status = "error", errors = unique(errors)) else service_result(status = "success", value = event)
}

improvement_read_events <- function(project, validate_hash_chain = TRUE) {
  path <- tryCatch(improvement_event_log_path(project, create_dir = FALSE), error = function(e) NULL)
  if (is.null(path) || !file.exists(path)) {
    return(service_result(status = "success", value = list(events = data.table::data.table(), ledger_health = "missing", malformed_count = 0L)))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (!length(lines)) {
    return(service_result(status = "success", value = list(events = data.table::data.table(), ledger_health = "healthy", malformed_count = 0L)))
  }
  parsed <- list()
  malformed <- 0L
  health <- "healthy"
  previous_hash <- ""
  for (i in seq_along(lines)) {
    line <- trimws(lines[[i]])
    if (!nzchar(line)) next
    event <- tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE), error = function(e) structure(list(error = conditionMessage(e)), class = "improvement_event_parse_error"))
    if (inherits(event, "improvement_event_parse_error")) {
      malformed <- malformed + 1L
      health <- if (i == length(lines)) "partial" else "malformed"
      next
    }
    if (!identical(event$improvement_event_schema_version %||% "", improvement_event_schema_version())) {
      health <- "unsupported_schema"
    }
    if (isTRUE(validate_hash_chain) && health %in% c("healthy", "unsupported_schema")) {
      expected <- improvement_event_hash(event, previous_hash)
      if (!identical(event$previous_event_hash %||% "", previous_hash) || !identical(event$event_hash %||% "", expected)) {
        health <- "event_history_mismatch"
      }
      previous_hash <- event$event_hash %||% previous_hash
    } else {
      previous_hash <- event$event_hash %||% previous_hash
    }
    parsed[[length(parsed) + 1L]] <- event
  }
  normalize <- function(x) {
    out <- lapply(x, function(value) {
      if (is.null(value) || length(value) == 0L) {
        NA_character_
      } else if (is.list(value)) {
        paste(vapply(value, improvement_safe_scalar, character(1), max_chars = 120L), collapse = "; ")
      } else if (length(value) > 1L) {
        paste(as.character(value), collapse = "; ")
      } else {
        value
      }
    })
    as.data.frame(out, stringsAsFactors = FALSE)
  }
  events <- if (length(parsed)) data.table::rbindlist(lapply(parsed, normalize), fill = TRUE) else data.table::data.table()
  service_result(status = "success", value = list(events = events, ledger_health = health, malformed_count = malformed))
}

improvement_write_checkpoint <- function(project, events, event) {
  path <- improvement_checkpoint_path(project, create_dir = TRUE)
  checkpoint <- list(
    checkpoint_schema_version = improvement_checkpoint_schema_version(),
    item_schema_version = improvement_item_schema_version(),
    event_schema_version = improvement_event_schema_version(),
    event_count = nrow(events) + 1L,
    last_event_id = event$improvement_event_id,
    last_event_timestamp = event$event_timestamp,
    last_event_hash = event$event_hash,
    updated_at = storage_now()
  )
  atomic_save_json(checkpoint, path, pretty = TRUE)
}

improvement_append_event <- function(project, workspace, event) {
  path <- tryCatch(improvement_event_log_path(project, create_dir = TRUE), error = function(e) NULL)
  if (is.null(path)) return(service_result(status = "error", errors = "Improvement event path could not be resolved."))
  gate <- persistent_write_gate(workspace, project, path, "improvement_ledger")
  if (!identical(gate$status, "success")) return(service_result(status = "error", errors = gate$errors, metadata = list(write_gate = gate)))
  validation <- improvement_validate_event(event)
  if (!identical(validation$status, "success")) return(validation)
  event <- validation$value
  existing <- improvement_read_events(project)
  if (!identical(existing$status, "success")) return(existing)
  events <- existing$value$events
  if (nrow(events) && "idempotency_key" %in% names(events) && event$idempotency_key %in% events$idempotency_key) {
    matched <- events[events$idempotency_key == event$idempotency_key][1]
    return(service_result(status = "success", value = list(event_id = matched$improvement_event_id[[1]], already_recorded = TRUE)))
  }
  previous_hash <- if (nrow(events) && "event_hash" %in% names(events)) tail(events$event_hash, 1L) else ""
  event$previous_event_hash <- previous_hash %||% ""
  event$event_hash <- improvement_event_hash(event, event$previous_event_hash)
  line <- jsonlite::toJSON(event, auto_unbox = TRUE, null = "null", digits = NA)
  tryCatch({
    con <- file(path, open = "ab")
    on.exit(close(con), add = TRUE)
    writeBin(charToRaw(paste0(line, "\n")), con)
    improvement_write_checkpoint(project, events, event)
    service_result(status = "success", value = list(event_id = event$improvement_event_id, already_recorded = FALSE))
  }, error = function(e) {
    service_result(status = "error", errors = paste("Improvement event append failed:", conditionMessage(e)))
  })
}

improvement_save_item <- function(project, workspace, item, event_type = "item_updated", event_summary = NULL, actor = "application") {
  validation <- improvement_validate_item(item, project = project)
  if (!identical(validation$status, "success")) return(validation)
  path <- improvement_item_path(project, item$item_id, create_dir = TRUE)
  gate <- persistent_write_gate(workspace, project, path, "improvement_item")
  if (!identical(gate$status, "success")) return(service_result(status = "error", errors = gate$errors, metadata = list(write_gate = gate)))
  item$updated_at <- storage_now()
  tryCatch({
    atomic_save_json(item, path, pretty = TRUE)
    ev <- improvement_event(event_type, item, summary = event_summary, actor = actor)
    append <- improvement_append_event(project, workspace, ev)
    if (!identical(append$status, "success")) return(append)
    service_result(status = "success", value = item, metadata = list(item_path = "governance/improvement_ledger/items", event = append$value))
  }, error = function(e) {
    service_result(status = "error", errors = paste("Improvement item write failed:", conditionMessage(e)))
  })
}

improvement_load_item <- function(project, item_id) {
  path <- improvement_item_path(project, item_id, create_dir = FALSE)
  if (!file.exists(path)) return(service_result(status = "error", errors = paste("Improvement item not found:", item_id)))
  item <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) e)
  if (inherits(item, "error")) return(service_result(status = "error", errors = conditionMessage(item)))
  validation <- improvement_validate_item(item, project = project)
  if (!identical(validation$status, "success")) return(validation)
  service_result(status = "success", value = item)
}

improvement_load_items <- function(project, include_invalid = FALSE) {
  dir <- tryCatch(improvement_items_dir(project, create_dir = FALSE), error = function(e) NULL)
  if (is.null(dir) || !dir.exists(dir)) {
    return(service_result(status = "success", value = list(items = list(), ledger_health = "missing", invalid_items = list())))
  }
  paths <- list.files(dir, pattern = "\\.json$", full.names = TRUE)
  items <- list()
  invalid <- list()
  health <- "healthy"
  for (path in paths) {
    item <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) e)
    if (inherits(item, "error")) {
      invalid[[basename(path)]] <- conditionMessage(item)
      health <- "malformed"
      next
    }
    validation <- improvement_validate_item(item, project = project)
    if (!identical(validation$status, "success")) {
      invalid[[item$item_id %||% basename(path)]] <- validation$errors
      health <- if (grepl("Unsupported", paste(validation$errors, collapse = " "))) "unsupported_schema" else "malformed"
      if (isTRUE(include_invalid)) items[[length(items) + 1L]] <- item
      next
    }
    items[[length(items) + 1L]] <- item
  }
  events <- improvement_read_events(project)
  event_health <- events$value$ledger_health %||% "missing"
  if (identical(health, "healthy") && event_health %in% c("malformed", "partial", "unsupported_schema", "event_history_mismatch")) {
    health <- event_health
  }
  service_result(status = "success", value = list(items = items, ledger_health = health, invalid_items = invalid, events = events$value))
}

improvement_item_table <- function(items) {
  if (!length(items)) return(data.table::data.table())
  data.table::rbindlist(lapply(items, function(item) {
    data.table::data.table(
      item_id = item$item_id %||% NA_character_,
      title = item$title %||% NA_character_,
      item_type = item$item_type %||% NA_character_,
      status = item$status %||% NA_character_,
      severity = item$severity %||% NA_character_,
      priority = item$priority %||% NA_character_,
      confidence = item$confidence %||% NA_character_,
      affected_component = item$affected_component %||% NA_character_,
      affected_resource_type = item$affected_resource_type %||% NA_character_,
      affected_resource_id = item$affected_resource_id %||% NA_character_,
      source_type = item$source_type %||% NA_character_,
      source_id = item$source_id %||% NA_character_,
      updated_at = item$updated_at %||% NA_character_,
      last_detected_at = item$last_detected_at %||% NA_character_,
      occurrence_count = as.integer(item$occurrence_count %||% 1L),
      recommended_remediation_count = length(item$recommended_remediations %||% list()),
      evidence_count = length(item$evidence_refs %||% list())
    )
  }), fill = TRUE)
}

improvement_find_existing <- function(items, candidate) {
  if (!length(items)) return(NULL)
  matches <- Filter(function(item) {
    identical(item$project_id %||% "", candidate$project_id %||% "") &&
      identical(item$item_type %||% "", candidate$item_type %||% "") &&
      identical(item$affected_resource_type %||% "", candidate$affected_resource_type %||% "") &&
      identical(item$affected_resource_id %||% "", candidate$affected_resource_id %||% "") &&
      identical(item$normalized_issue_signature %||% "", candidate$normalized_issue_signature %||% "")
  }, items)
  if (length(matches)) matches[[1L]] else NULL
}

improvement_merge_unique_refs <- function(a, b) {
  refs <- c(a %||% list(), b %||% list())
  if (!length(refs)) return(list())
  keys <- vapply(refs, function(ref) paste(ref$evidence_type %||% "", ref$evidence_id %||% "", ref$relationship %||% "", sep = "|"), character(1))
  refs[!duplicated(keys)]
}

improvement_create_or_update_item <- function(project, workspace, candidate, actor = "application") {
  loaded <- improvement_load_items(project)
  if (!identical(loaded$status, "success")) return(loaded)
  existing <- improvement_find_existing(loaded$value$items, candidate)
  if (is.null(existing)) {
    return(improvement_save_item(project, workspace, candidate, event_type = "item_created", event_summary = candidate$title, actor = actor))
  }
  existing$last_detected_at <- storage_now()
  existing$occurrence_count <- as.integer(existing$occurrence_count %||% 1L) + 1L
  existing$evidence_refs <- improvement_merge_unique_refs(existing$evidence_refs, candidate$evidence_refs)
  existing$finding_refs <- unique(c(existing$finding_refs %||% character(), candidate$finding_refs %||% character()))
  existing$audit_refs <- unique(c(existing$audit_refs %||% character(), candidate$audit_refs %||% character()))
  existing$technical_debt_refs <- unique(c(existing$technical_debt_refs %||% character(), candidate$technical_debt_refs %||% character()))
  existing$re_evaluation_history <- c(existing$re_evaluation_history %||% list(), list(list(
    re_evaluation_schema_version = improvement_re_evaluation_schema_version(),
    re_evaluation_id = paste0("reeval_", substr(storage_hash_value(list(existing$item_id, Sys.time())), 1L, 16L)),
    evaluated_at = storage_now(),
    before_state = existing$status %||% NA_character_,
    after_state = existing$status %||% NA_character_,
    comparison = "Duplicate detection updated occurrence count and evidence.",
    resolution_criteria_met = FALSE,
    remaining_gaps = "Issue detected again."
  )))
  if ((existing$status %||% "") %in% c("resolved", "partially_resolved")) {
    existing$status <- "re_evaluation_required"
  }
  improvement_save_item(project, workspace, existing, event_type = "item_updated", event_summary = "Existing improvement item updated by deduplication.", actor = actor)
}

improvement_ingest_deterministic_signal <- function(project, workspace, signal) {
  signal <- signal %||% list()
  evidence <- signal$evidence_refs %||% list(improvement_evidence_ref(
    signal$evidence_type %||% "qa_check",
    signal$evidence_id %||% paste0("signal_", substr(storage_hash_value(signal), 1L, 16L)),
    relationship = "triggered_by",
    summary = signal$summary %||% signal$title %||% "Deterministic signal"
  ))
  candidate <- improvement_new_item(
    project = project,
    item_type = signal$item_type %||% "validation_failure",
    title = signal$title %||% "Deterministic validation failure",
    description = signal$description %||% signal$summary %||% "A deterministic check identified an actionable concern.",
    source_type = signal$source_type %||% "deterministic_check",
    source_id = signal$source_id %||% evidence[[1]]$evidence_id,
    status = signal$status %||% "detected",
    severity = signal$severity %||% "high",
    priority = signal$priority %||% if ((signal$severity %||% "") %in% c("critical", "high")) "high" else "normal",
    confidence = signal$confidence %||% "high",
    confidence_basis = signal$confidence_basis %||% "deterministic_failure",
    affected_component = signal$affected_component %||% NA_character_,
    affected_resource_type = signal$affected_resource_type %||% NA_character_,
    affected_resource_id = signal$affected_resource_id %||% NA_character_,
    evidence_refs = evidence,
    audit_refs = signal$audit_refs %||% character(),
    technical_debt_refs = signal$technical_debt_refs %||% character(),
    recommended_remediations = signal$recommended_remediations %||% list(),
    resolution_criteria = signal$resolution_criteria %||% character(),
    current_assessment = signal$current_assessment %||% signal$summary %||% "",
    normalized_issue_signature = signal$normalized_issue_signature %||% NULL
  )
  improvement_create_or_update_item(project, workspace, candidate, actor = "deterministic_check")
}

improvement_ingest_genai_concern <- function(project, workspace, concern, valid_evidence_ids = character()) {
  concern <- concern %||% list()
  allowed <- c(
    "item_type", "title", "description", "severity", "priority", "confidence",
    "confidence_basis", "affected_resource_type", "affected_resource_id",
    "affected_component", "evidence_refs", "recommended_remediation_types",
    "resolution_criteria", "source_id", "normalized_issue_signature"
  )
  unexpected <- setdiff(names(concern), allowed)
  if (length(unexpected)) {
    return(service_result(status = "error", errors = paste("GenAI concern contains unsupported fields:", paste(unexpected, collapse = ", "))))
  }
  if (improvement_contains_absolute_path(concern) || improvement_contains_code(concern) || improvement_has_unsafe_object(concern)) {
    return(service_result(status = "error", errors = "GenAI concern contains unsafe path, executable content, or object."))
  }
  evidence <- concern$evidence_refs %||% list()
  evidence_validation <- lapply(evidence, improvement_validate_evidence_ref, valid_evidence_ids = valid_evidence_ids)
  evidence_errors <- unlist(lapply(evidence_validation, function(x) x$errors %||% character()), use.names = FALSE)
  if (length(evidence_errors)) return(service_result(status = "error", errors = evidence_errors))
  remediations <- lapply(concern$recommended_remediation_types %||% character(), function(type) {
    improvement_remediation(type, title = paste("Consider", gsub("_", " ", type)), confidence = concern$confidence %||% "low")
  })
  remediation_validation <- lapply(remediations, improvement_validate_remediation)
  remediation_errors <- unlist(lapply(remediation_validation, function(x) x$errors %||% character()), use.names = FALSE)
  if (length(remediation_errors)) return(service_result(status = "error", errors = remediation_errors))
  severity <- concern$severity %||% "medium"
  if (identical(severity, "critical") && !identical(concern$confidence_basis %||% "", "deterministic_failure")) {
    severity <- "high"
  }
  candidate <- improvement_new_item(
    project = project,
    item_type = concern$item_type %||% "low_confidence_concern",
    title = concern$title %||% "GenAI concern requires triage",
    description = concern$description %||% "GenAI identified a concern from trusted context.",
    source_type = "genai_assessment",
    source_id = concern$source_id %||% "genai_concern",
    status = "triage_required",
    severity = severity,
    priority = concern$priority %||% "normal",
    confidence = concern$confidence %||% "low",
    confidence_basis = concern$confidence_basis %||% "genai_inference",
    affected_component = concern$affected_component %||% NA_character_,
    affected_resource_type = concern$affected_resource_type %||% NA_character_,
    affected_resource_id = concern$affected_resource_id %||% NA_character_,
    evidence_refs = evidence,
    recommended_remediations = remediations,
    resolution_criteria = concern$resolution_criteria %||% character(),
    current_assessment = "GenAI concern is not authoritative until triaged.",
    normalized_issue_signature = concern$normalized_issue_signature %||% NULL
  )
  improvement_create_or_update_item(project, workspace, candidate, actor = "genai_assessment")
}

improvement_create_user_item <- function(project, workspace, title, description, item_type = "user_requested_change", priority = "normal", affected_component = NA_character_, desired_outcome = NULL, evidence_refs = list()) {
  candidate <- improvement_new_item(
    project = project,
    item_type = item_type,
    title = title,
    description = description,
    source_type = "user",
    source_id = paste0("user_", format(Sys.time(), "%Y%m%d%H%M%S")),
    status = "triage_required",
    severity = "low",
    priority = priority,
    confidence = "high",
    confidence_basis = "user_assertion",
    affected_component = affected_component,
    affected_resource_type = "user_request",
    affected_resource_id = safe_path_component(title, "user_request"),
    evidence_refs = evidence_refs,
    resolution_criteria = if (nzchar(desired_outcome %||% "")) desired_outcome else character(),
    current_assessment = "User-created improvement item requires triage."
  )
  improvement_create_or_update_item(project, workspace, candidate, actor = "user")
}

improvement_add_user_feedback <- function(project, workspace, item_id, feedback_type, feedback, priority = NULL, severity = NULL, status = NULL) {
  loaded <- improvement_load_item(project, item_id)
  if (!identical(loaded$status, "success")) return(loaded)
  item <- loaded$value
  if (!is.null(priority)) {
    if (!priority %in% improvement_priorities()) return(service_result(status = "error", errors = paste("Invalid priority:", priority)))
    item$priority <- priority
  }
  if (!is.null(severity)) {
    if (!severity %in% improvement_severities()) return(service_result(status = "error", errors = paste("Invalid severity:", severity)))
    item$severity <- severity
  }
  if (!is.null(status) && !identical(status, item$status)) {
    transition <- improvement_item_safe_transition(item, status, rationale = feedback)
    if (!identical(transition$status, "success")) return(transition)
    item <- transition$value
  }
  item$user_feedback <- c(item$user_feedback %||% list(), list(list(
    feedback_id = paste0("fb_", substr(storage_hash_value(list(item_id, feedback, Sys.time())), 1L, 16L)),
    feedback_type = improvement_safe_scalar(feedback_type, 80L),
    feedback = improvement_safe_scalar(feedback, 1000L),
    created_at = storage_now()
  )))
  improvement_save_item(project, workspace, item, event_type = "user_feedback_added", event_summary = "User feedback added.", actor = "user")
}

improvement_add_remediation <- function(project, workspace, item_id, remediation) {
  loaded <- improvement_load_item(project, item_id)
  if (!identical(loaded$status, "success")) return(loaded)
  validation <- improvement_validate_remediation(remediation)
  if (!identical(validation$status, "success")) return(validation)
  item <- loaded$value
  item$recommended_remediations <- c(item$recommended_remediations %||% list(), list(remediation))
  transition <- improvement_item_safe_transition(item, "remediation_proposed", rationale = remediation$title)
  if (identical(transition$status, "success")) item <- transition$value
  improvement_save_item(project, workspace, item, event_type = "remediation_proposed", event_summary = remediation$title, actor = "application")
}

improvement_record_attempt <- function(project, workspace, item_id, remediation_id = NA_character_, action_id = NA_character_, proposal_id = NA_character_, execution_id = NA_character_, status = "started", outcome_summary = NULL, evidence_refs = list()) {
  loaded <- improvement_load_item(project, item_id)
  if (!identical(loaded$status, "success")) return(loaded)
  item <- loaded$value
  attempt <- list(
    attempt_schema_version = improvement_attempt_schema_version(),
    attempt_id = paste0("attempt_", substr(storage_hash_value(list(item_id, remediation_id, action_id, Sys.time())), 1L, 16L)),
    item_id = item_id,
    remediation_id = remediation_id,
    action_id = action_id,
    proposal_id = proposal_id,
    execution_id = execution_id,
    started_at = storage_now(),
    completed_at = if (!identical(status, "started")) storage_now() else NA_character_,
    status = status,
    outcome_summary = improvement_safe_scalar(outcome_summary %||% "", 1000L),
    evidence_refs = evidence_refs,
    introduced_new_item_ids = character(),
    user_feedback = character()
  )
  item$attempt_history <- c(item$attempt_history %||% list(), list(attempt))
  target_status <- if (identical(status, "started")) "remediation_running" else "re_evaluation_required"
  transition <- improvement_item_safe_transition(item, target_status, rationale = outcome_summary)
  if (identical(transition$status, "success")) item <- transition$value
  event_type <- if (status %in% c("succeeded", "success")) "remediation_succeeded" else if (status %in% c("failed", "error", "cancelled", "timed_out")) "remediation_failed" else "remediation_started"
  improvement_save_item(project, workspace, item, event_type = event_type, event_summary = outcome_summary %||% status, actor = "application")
}

improvement_record_re_evaluation <- function(project, workspace, item_id, before_state, after_state, comparison, criteria_met = FALSE, remaining_gaps = NULL, user_confirmation_required = FALSE) {
  loaded <- improvement_load_item(project, item_id)
  if (!identical(loaded$status, "success")) return(loaded)
  item <- loaded$value
  re_eval <- list(
    re_evaluation_schema_version = improvement_re_evaluation_schema_version(),
    re_evaluation_id = paste0("reeval_", substr(storage_hash_value(list(item_id, comparison, Sys.time())), 1L, 16L)),
    evaluated_at = storage_now(),
    before_state = improvement_safe_scalar(before_state, 500L),
    after_state = improvement_safe_scalar(after_state, 500L),
    comparison = improvement_safe_scalar(comparison, 1000L),
    resolution_criteria_met = isTRUE(criteria_met),
    remaining_gaps = improvement_safe_scalar(remaining_gaps %||% "", 1000L),
    user_confirmation_required = isTRUE(user_confirmation_required)
  )
  item$re_evaluation_history <- c(item$re_evaluation_history %||% list(), list(re_eval))
  target_status <- if (isTRUE(criteria_met) && !isTRUE(user_confirmation_required)) {
    "resolved"
  } else if (nzchar(remaining_gaps %||% "")) {
    "partially_resolved"
  } else {
    "unresolved"
  }
  transition <- improvement_item_safe_transition(item, target_status, rationale = comparison)
  if (!identical(transition$status, "success")) return(transition)
  item <- transition$value
  event_type <- if (identical(target_status, "resolved")) "item_resolved" else if (identical(target_status, "partially_resolved")) "item_partially_resolved" else "re_evaluation_completed"
  improvement_save_item(project, workspace, item, event_type = event_type, event_summary = comparison, actor = "application")
}

improvement_ledger_summary <- function(project) {
  loaded <- improvement_load_items(project)
  if (!identical(loaded$status, "success")) {
    return(data.table::data.table(ledger_health = "unavailable", total_items = 0L, open_items = 0L, critical_open = 0L, awaiting_user = 0L, high_priority = 0L, resolved_items = 0L))
  }
  table <- improvement_item_table(loaded$value$items)
  if (!nrow(table)) {
    return(data.table::data.table(ledger_health = loaded$value$ledger_health, total_items = 0L, open_items = 0L, critical_open = 0L, awaiting_user = 0L, high_priority = 0L, resolved_items = 0L))
  }
  active <- !table$status %in% improvement_terminal_statuses()
  data.table::data.table(
    ledger_health = loaded$value$ledger_health,
    total_items = nrow(table),
    open_items = sum(active),
    critical_open = sum(active & table$severity == "critical"),
    awaiting_user = sum(table$status %in% c("awaiting_user_input", "awaiting_approval", "triage_required")),
    high_priority = sum(active & table$priority %in% c("high", "urgent")),
    resolved_items = sum(table$status == "resolved")
  )
}

genai_improvement_context_summary <- function(project, max_items = 12L) {
  loaded <- improvement_load_items(project)
  if (!identical(loaded$status, "success")) {
    return(service_result(status = "warning", warnings = loaded$errors %||% "Improvement ledger unavailable."))
  }
  table <- improvement_item_table(loaded$value$items)
  if (!nrow(table)) {
    return(service_result(status = "success", value = list(items = list(), counts = list()), messages = "No improvement items registered."))
  }
  active <- table[!status %in% improvement_terminal_statuses()]
  severity_rank <- c(critical = 1L, high = 2L, medium = 3L, low = 4L, informational = 5L)
  priority_rank <- c(urgent = 1L, high = 2L, normal = 3L, backlog = 4L)
  active[, severity_order := severity_rank[severity] %||% 99L]
  active[, priority_order := priority_rank[priority] %||% 99L]
  visible <- active[order(priority_order, severity_order, -occurrence_count)][seq_len(min(.N, as.integer(max_items)))]
  service_result(
    status = "success",
    value = list(
      ledger_health = loaded$value$ledger_health,
      items = lapply(seq_len(nrow(visible)), function(i) {
        list(
          item_id = visible$item_id[[i]],
          title = visible$title[[i]],
          item_type = visible$item_type[[i]],
          status = visible$status[[i]],
          severity = visible$severity[[i]],
          priority = visible$priority[[i]],
          confidence = visible$confidence[[i]],
          affected_component = visible$affected_component[[i]],
          evidence_count = visible$evidence_count[[i]],
          recommended_remediation_count = visible$recommended_remediation_count[[i]]
        )
      }),
      counts = improvement_ledger_summary(project)
    ),
    messages = "Bounded improvement ledger summary prepared for GenAI context."
  )
}

improvement_ledger_health <- function(project) {
  loaded <- improvement_load_items(project)
  if (!identical(loaded$status, "success")) return("unavailable")
  loaded$value$ledger_health %||% "healthy"
}

ui_improvement_ledger_table <- function(table, ns = identity) {
  if (!nrow(table)) return(ui_empty_state("No improvement items yet.", "Failures, concerns, user requests, and deferred improvements will appear here once detected or created."))
  table <- table[order(!priority %in% c("urgent", "high"), !severity %in% c("critical", "high"), updated_at, decreasing = TRUE)]
  table <- table[seq_len(min(nrow(table), 20L))]
  tags$div(
    class = "aq-table-scroll aq-improvement-ledger-table",
    tags$table(
      class = "aq-table aq-table-compact",
      tags$thead(tags$tr(
        tags$th("Item"), tags$th("Type"), tags$th("Status"), tags$th("Severity"),
        tags$th("Priority"), tags$th("Confidence"), tags$th("Source"), tags$th("Updated")
      )),
      tags$tbody(lapply(seq_len(nrow(table)), function(i) {
        row <- table[i]
        tags$tr(
          tags$td(tags$strong(row$title[[1]]), tags$div(class = "aq-muted", row$item_id[[1]])),
          tags$td(gsub("_", " ", row$item_type[[1]])),
          tags$td(row$status[[1]]),
          tags$td(ui_status_badge(row$severity[[1]], status = if (row$severity[[1]] %in% c("critical", "high")) "error" else if (row$severity[[1]] == "medium") "warning" else "info")),
          tags$td(row$priority[[1]]),
          tags$td(row$confidence[[1]]),
          tags$td(row$source_type[[1]]),
          tags$td(substr(row$updated_at[[1]], 1L, 10L))
        )
      }))
    )
  )
}

ui_improvement_item_detail <- function(item) {
  if (is.null(item)) {
    return(ui_empty_state("Select an improvement item.", "Details, evidence, feedback, remediation, attempts, and re-evaluation history will appear here."))
  }
  tags$div(
    class = "aq-improvement-detail",
    ui_stat_grid(
      ui_stat_tile("Status", item$status, status = if (item$status %in% improvement_terminal_statuses()) "success" else "info"),
      ui_stat_tile("Severity", item$severity, status = if (item$severity %in% c("critical", "high")) "error" else "warning"),
      ui_stat_tile("Priority", item$priority, status = if (item$priority %in% c("urgent", "high")) "warning" else "neutral"),
      ui_stat_tile("Confidence", item$confidence, status = if (identical(item$confidence, "high")) "success" else "info")
    ),
    tags$p(item$description),
    tags$dl(
      class = "aq-metadata-grid",
      tags$dt("Affected"), tags$dd(paste(item$affected_component %||% "-", item$affected_resource_type %||% "-", item$affected_resource_id %||% "-")),
      tags$dt("Source"), tags$dd(paste(item$source_type %||% "-", item$source_id %||% "-")),
      tags$dt("Occurrences"), tags$dd(as.character(item$occurrence_count %||% 1L)),
      tags$dt("Resolution Criteria"), tags$dd(paste(item$resolution_criteria %||% "Not defined yet.", collapse = "; "))
    ),
    ui_disclosure("Evidence", tags$ul(lapply(item$evidence_refs %||% list(), function(ref) tags$li(paste(ref$relationship, ref$evidence_type, ref$evidence_id, sep = ": ")))), level = "common", open = TRUE),
    ui_disclosure("Recommended Remediations", tags$ul(lapply(item$recommended_remediations %||% list(), function(rem) tags$li(paste(rem$title, "-", rem$remediation_type)))), level = "common", open = TRUE),
    ui_disclosure("User Feedback", tags$ul(lapply(item$user_feedback %||% list(), function(fb) tags$li(paste(substr(fb$created_at %||% "", 1L, 10L), fb$feedback_type %||% "feedback", fb$feedback %||% "", sep = " - ")))), level = "advanced"),
    ui_disclosure("Attempts / Re-Evaluation", tags$div(
      tags$p(paste(length(item$attempt_history %||% list()), "attempt(s) recorded.")),
      tags$p(paste(length(item$re_evaluation_history %||% list()), "re-evaluation(s) recorded."))
    ), level = "advanced")
  )
}

qa_improvement_ledger <- function(output_dir = file.path(tempdir(), "improvement_ledger_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(check, status, message, file = "R/improvement_ledger.R", severity = "error") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, severity = severity, file = file, message = message)
  }
  provider <- storage_provider(
    provider_id = "improvement_qa_provider",
    provider_type = "local_server_directory",
    display_name = "Improvement QA Provider",
    root_path = output_dir,
    available = TRUE,
    writable = TRUE,
    capabilities = list(supports_external_projects = TRUE, can_choose_directory = TRUE)
  )
  workspace <- validate_workspace_root(output_dir, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
  project <- create_project_in_workspace(workspace, "Improvement QA", project_id = "improvement_qa_project")$value

  evidence <- improvement_evidence_ref("preflight_result", "preflight_001", "triggered_by", summary = "Prediction column missing.")
  item <- improvement_new_item(
    project = project,
    item_type = "validation_failure",
    title = "Prediction column is missing",
    description = "Model Assessment cannot run because the prediction column is not configured.",
    source_type = "deterministic_check",
    source_id = "preflight_001",
    severity = "high",
    priority = "high",
    confidence = "high",
    confidence_basis = "deterministic_failure",
    affected_component = "Model Assessment",
    affected_resource_type = "module_configuration",
    affected_resource_id = "model_assessment",
    evidence_refs = list(evidence),
    recommended_remediations = list(improvement_remediation("open_module", "Open Model Assessment", required_actions = "module.open")),
    resolution_criteria = "prediction column is configured and valid"
  )
  valid_item <- improvement_validate_item(item, project)
  add("valid_item_schema", if (identical(valid_item$status, "success")) "success" else "error", paste(valid_item$errors %||% "Valid item accepted.", collapse = "; "))

  missing <- item
  missing$title <- NULL
  add("missing_required_field_detected", if (identical(improvement_validate_item(missing, project)$status, "error")) "success" else "error", "Missing required fields are rejected.")
  invalid_type <- item
  invalid_type$item_type <- "other"
  add("invalid_type_detected", if (identical(improvement_validate_item(invalid_type, project)$status, "error")) "success" else "error", "Invalid item type is rejected.")
  invalid_status <- item
  invalid_status$status <- "fixed"
  add("invalid_status_detected", if (identical(improvement_validate_item(invalid_status, project)$status, "error")) "success" else "error", "Invalid status is rejected.")
  invalid_severity <- item
  invalid_severity$severity <- "severe"
  add("invalid_severity_detected", if (identical(improvement_validate_item(invalid_severity, project)$status, "error")) "success" else "error", "Invalid severity is rejected.")
  invalid_priority <- item
  invalid_priority$priority <- "today"
  add("invalid_priority_detected", if (identical(improvement_validate_item(invalid_priority, project)$status, "error")) "success" else "error", "Invalid priority is rejected.")
  invalid_confidence <- item
  invalid_confidence$confidence <- "certain"
  add("invalid_confidence_detected", if (identical(improvement_validate_item(invalid_confidence, project)$status, "error")) "success" else "error", "Invalid confidence is rejected.")
  unsafe_path <- item
  unsafe_path$description <- "See C:\\Users\\Bizon\\secret.csv"
  add("unsafe_path_rejected", if (identical(improvement_validate_item(unsafe_path, project)$status, "error")) "success" else "error", "Absolute paths are rejected.")
  code_item <- item
  code_item$description <- "Run system('del x')"
  add("executable_text_rejected", if (identical(improvement_validate_item(code_item, project)$status, "error")) "success" else "error", "Executable-looking prose is rejected.")
  oversized <- item
  oversized$description <- paste(rep("x", 2300L), collapse = "")
  add("oversized_description_rejected", if (identical(improvement_validate_item(oversized, project)$status, "error")) "success" else "error", "Oversized descriptions are rejected.")
  bad_rem <- improvement_remediation("rerun_analysis", "Bad", required_actions = "not.registered")
  add("invalid_remediation_action_rejected", if (identical(improvement_validate_remediation(bad_rem)$status, "error")) "success" else "error", "Unsupported remediation actions are rejected.")

  created <- improvement_create_or_update_item(project, workspace, item)
  loaded <- improvement_load_items(project)
  add("durable_item_created", if (identical(created$status, "success") && length(loaded$value$items) == 1L) "success" else "error", "Item is written to durable project governance storage.")
  add("ledger_path_project_scoped", if (path_within_root(improvement_item_path(project, item$item_id), project$project_root)) "success" else "error", "Item path is beneath project root.")
  second <- improvement_ingest_deterministic_signal(project, workspace, list(
    item_type = "validation_failure",
    title = "Prediction column is missing",
    description = "Model Assessment cannot run because the prediction column is not configured.",
    source_id = "preflight_001",
    affected_component = "Model Assessment",
    affected_resource_type = "module_configuration",
    affected_resource_id = "model_assessment",
    normalized_issue_signature = item$normalized_issue_signature,
    evidence_refs = list(evidence)
  ))
  after_dedupe <- improvement_load_items(project)
  deduped_item <- after_dedupe$value$items[[1]]
  add("deduplication_updates_existing", if (identical(second$status, "success") && length(after_dedupe$value$items) == 1L && deduped_item$occurrence_count >= 2L) "success" else "error", "Repeated deterministic signal updates occurrence count instead of creating duplicates.")

  transition <- improvement_item_safe_transition(deduped_item, "accepted", "User accepted deterministic failure.")
  add("valid_transition_allowed", if (identical(transition$status, "success")) "success" else "error", "detected -> accepted transition is allowed.")
  invalid_transition <- improvement_item_safe_transition(transition$value, "resolved", "Skipping re-evaluation")
  add("invalid_transition_blocked", if (identical(invalid_transition$status, "error")) "success" else "error", "Invalid lifecycle transition is blocked.")

  feedback <- improvement_add_user_feedback(project, workspace, item$item_id, "agree", "This is a real issue.", priority = "urgent", severity = "high", status = "accepted")
  add("user_feedback_persisted", if (identical(feedback$status, "success") && length(feedback$value$user_feedback) >= 1L) "success" else "error", "User feedback is appended durably.")
  attempt <- improvement_record_attempt(project, workspace, item$item_id, remediation_id = "remediation_001", action_id = "module.open", proposal_id = "proposal_001", execution_id = "execution_001", status = "succeeded", outcome_summary = "Opened module.")
  add("attempt_history_persisted", if (identical(attempt$status, "success") && length(attempt$value$attempt_history) >= 1L) "success" else "error", "Attempt history is appended durably.")
  re_eval <- improvement_record_re_evaluation(project, workspace, item$item_id, "missing prediction", "prediction configured", "Resolution criteria met.", criteria_met = TRUE)
  add("re_evaluation_resolves_when_met", if (identical(re_eval$status, "success") && identical(re_eval$value$status, "resolved")) "success" else "error", "Re-evaluation can resolve item when criteria are met.")
  regression <- improvement_ingest_deterministic_signal(project, workspace, list(
    item_type = "validation_failure",
    title = "Prediction column is missing",
    description = "Model Assessment cannot run because the prediction column is not configured.",
    source_id = "preflight_002",
    affected_component = "Model Assessment",
    affected_resource_type = "module_configuration",
    affected_resource_id = "model_assessment",
    normalized_issue_signature = item$normalized_issue_signature,
    evidence_refs = list(improvement_evidence_ref("preflight_result", "preflight_002", "triggered_by"))
  ))
  reopened <- improvement_load_item(project, item$item_id)
  add("resolved_item_regression_reopens_for_re_evaluation", if (identical(regression$status, "success") && identical(reopened$value$status, "re_evaluation_required")) "success" else "error", "Resolved item detected again moves to re-evaluation.")

  genai_valid <- improvement_ingest_genai_concern(project, workspace, list(
    item_type = "low_confidence_concern",
    title = "Artifact summary may be incomplete",
    description = "The artifact appears to lack a recommendation.",
    severity = "critical",
    priority = "normal",
    confidence = "low",
    confidence_basis = "genai_inference",
    affected_component = "Artifact Studio",
    affected_resource_type = "artifact",
    affected_resource_id = "artifact_001",
    evidence_refs = list(improvement_evidence_ref("artifact", "artifact_001", "supports")),
    recommended_remediation_types = c("inspect_artifact"),
    normalized_issue_signature = "artifact_summary_incomplete:artifact_001"
  ), valid_evidence_ids = "artifact_001")
  genai_item <- improvement_load_item(project, genai_valid$value$item_id)
  add("genai_concern_enters_triage", if (identical(genai_valid$status, "success") && identical(genai_item$value$status, "triage_required") && genai_item$value$severity != "critical") "success" else "error", "GenAI concern is triage-required and critical severity is capped without deterministic evidence.")
  genai_invented <- improvement_ingest_genai_concern(project, workspace, list(
    item_type = "low_confidence_concern",
    title = "Invented evidence",
    description = "This should fail.",
    evidence_refs = list(improvement_evidence_ref("artifact", "made_up", "supports"))
  ), valid_evidence_ids = "artifact_001")
  add("invented_evidence_rejected", if (identical(genai_invented$status, "error")) "success" else "error", "GenAI concern with invented evidence is rejected.")
  genai_path <- improvement_ingest_genai_concern(project, workspace, list(
    item_type = "low_confidence_concern",
    title = "Bad path",
    description = "Read C:\\Users\\Bizon\\secret.csv"
  ), valid_evidence_ids = character())
  add("genai_path_rejected", if (identical(genai_path$status, "error")) "success" else "error", "GenAI-supplied paths are rejected.")

  user_item <- improvement_create_user_item(project, workspace, "Make table scrollbars prettier", "The current scrollbar looks native and out of theme.", priority = "high", affected_component = "UI")
  add("user_created_item_persisted", if (identical(user_item$status, "success") && identical(user_item$value$source_type, "user")) "success" else "error", "User-created items are project-bound and durable.")
  duplicate_user <- improvement_create_user_item(project, workspace, "Make table scrollbars prettier", "The current scrollbar looks native and out of theme.", priority = "high", affected_component = "UI")
  all_after_user <- improvement_load_items(project)
  add("duplicate_user_warning_or_update", if (identical(duplicate_user$status, "success") && sum(vapply(all_after_user$value$items, function(x) identical(x$title, "Make table scrollbars prettier"), logical(1))) == 1L) "success" else "error", "Repeated user submission updates the existing item.")

  summary <- improvement_ledger_summary(project)
  context <- genai_improvement_context_summary(project, max_items = 2L)
  add("summary_available", if (nrow(summary) == 1L && summary$total_items > 0L) "success" else "error", "Ledger summary is available.")
  add("bounded_genai_context", if (identical(context$status, "success") && length(context$value$items) <= 2L) "success" else "error", "Bounded GenAI context summary is available.")
  events <- improvement_read_events(project)
  add("event_history_append_only", if (identical(events$status, "success") && nrow(events$value$events) >= 5L) "success" else "error", "Event history records lifecycle events.")
  add("event_hash_chain_healthy", if (events$value$ledger_health %in% c("healthy", "missing")) "success" else "error", paste("Ledger health:", events$value$ledger_health))

  bad_path <- improvement_event_log_path(project)
  writeLines("{not-json", bad_path, sep = "\n", useBytes = TRUE)
  malformed <- improvement_read_events(project)
  add("malformed_event_history_classified", if (identical(malformed$value$ledger_health, "partial")) "success" else "error", "Malformed event tail is classified without repair.")

  no_project_error <- tryCatch(improvement_items_dir(list(project_state = "no_project")), error = function(e) e)
  add("no_getwd_fallback", if (inherits(no_project_error, "error")) "success" else "error", "Ledger helpers do not fall back to getwd for missing project.")

  page_text <- if (file.exists(file.path("R", "page_project.R"))) paste(readLines(file.path("R", "page_project.R"), warn = FALSE), collapse = "\n") else ""
  mission_text <- if (file.exists(file.path("R", "page_mission_control.R"))) paste(readLines(file.path("R", "page_mission_control.R"), warn = FALSE), collapse = "\n") else ""
  add("project_ui_surface_present", if (grepl("improvement_ledger_browser", page_text, fixed = TRUE)) "success" else "error", "Project page exposes the Improvement Ledger.", file = "R/page_project.R")
  add("mission_control_integration_present", if (grepl("improvement_ledger_summary", mission_text, fixed = TRUE)) "success" else "error", "Mission Control reads improvement ledger summary.", file = "R/page_mission_control.R")
  add("schema_inventory_updated", if (file.exists("docs/architecture/schema_version_inventory.md") && grepl("improvement item schema", paste(readLines("docs/architecture/schema_version_inventory.md", warn = FALSE), collapse = "\n"), fixed = TRUE)) "success" else "error", "Schema inventory includes improvement schemas.", file = "docs/architecture/schema_version_inventory.md")
  add("architecture_doc_present", if (file.exists("docs/architecture/improvement_ledger.md")) "success" else "error", "Improvement ledger architecture doc exists.", file = "docs/architecture/improvement_ledger.md")

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
