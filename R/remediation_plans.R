remediation_plan_schema_version <- function() "remediation_plan_v1"
remediation_plan_step_schema_version <- function() "remediation_plan_step_v1"
remediation_manual_input_schema_version <- function() "remediation_manual_input_v1"
remediation_decision_gate_schema_version <- function() "remediation_decision_gate_v1"
remediation_plan_event_schema_version <- function() "remediation_plan_event_v1"
remediation_plan_template_schema_version <- function() "remediation_plan_template_v1"
remediation_plan_recovery_schema_version <- function() "remediation_plan_recovery_v1"
remediation_plan_checkpoint_schema_version <- function() "remediation_plan_checkpoint_v1"

remediation_plan_lifecycle <- function() {
  terminal <- c("succeeded", "partially_succeeded", "failed", "cancelled", "expired", "superseded")
  transition_map <- list(
    draft = c("awaiting_user_review", "validation_failed", "superseded"),
    validation_failed = c("draft", "superseded"),
    awaiting_user_review = c("approved", "cancelled", "superseded"),
    approved = c("queued", "running", "paused", "expired", "cancelled", "superseded"),
    queued = c("running", "paused", "cancelled", "expired"),
    running = c("paused", "awaiting_user_input", "awaiting_step_approval", "re_evaluation_required", "succeeded", "partially_succeeded", "failed", "cancelled", "expired"),
    paused = c("running", "cancelled", "expired", "superseded"),
    awaiting_user_input = c("running", "paused", "cancelled", "expired"),
    awaiting_step_approval = c("running", "paused", "cancelled", "expired"),
    re_evaluation_required = c("running", "succeeded", "partially_succeeded", "failed", "paused", "cancelled", "expired"),
    succeeded = character(),
    partially_succeeded = character(),
    failed = character(),
    cancelled = character(),
    expired = character(),
    superseded = character()
  )
  statuses <- names(transition_map)
  list(
    statuses = statuses,
    terminal = terminal,
    resumable = c("approved", "queued", "paused", "re_evaluation_required"),
    approval_required = c("awaiting_user_review", "awaiting_step_approval"),
    retryable = c("running", "paused", "re_evaluation_required"),
    waiting = c("awaiting_user_review", "awaiting_user_input", "awaiting_step_approval"),
    active = setdiff(statuses, terminal),
    transition_map = transition_map
  )
}

remediation_plan_event_types <- function() {
  c(
    "plan_created", "plan_validated", "plan_approved", "plan_rejected",
    "plan_step_started", "plan_step_completed", "plan_step_failed",
    "plan_user_input_requested", "plan_user_input_received",
    "plan_step_approval_requested", "plan_step_approved",
    "plan_re_evaluation_started", "plan_re_evaluation_completed",
    "plan_succeeded", "plan_failed", "plan_paused", "plan_cancelled",
    "plan_expired", "plan_superseded", "plan_revised"
  )
}

remediation_plan_statuses <- function() remediation_plan_lifecycle()$statuses

remediation_plan_terminal_statuses <- function() remediation_plan_lifecycle()$terminal

remediation_plan_resumable_statuses <- function() remediation_plan_lifecycle()$resumable

remediation_plan_approval_required_statuses <- function() remediation_plan_lifecycle()$approval_required

remediation_plan_retryable_statuses <- function() remediation_plan_lifecycle()$retryable

remediation_plan_step_types <- function() {
  c("registered_action", "manual_user_input", "deterministic_re_evaluation", "decision_gate", "informational")
}

remediation_plan_approval_policies <- function() {
  c("plan_structure_only", "plan_and_low_risk_steps")
}

remediation_plan_failure_policies <- function() {
  c("stop_plan", "pause_for_user", "continue_with_warning", "run_re_evaluation", "select_alternative_branch")
}

remediation_plan_pause_reasons <- function() {
  c("pause_for_user", "pause_for_approval", "pause_for_resource", "pause_for_policy", "manual_pause")
}

remediation_plan_manual_input_types <- function() {
  c("choice", "boolean", "short_text", "number", "resource_reference")
}

remediation_plan_transition_map <- function() {
  remediation_plan_lifecycle()$transition_map
}

remediation_plan_dir <- function(project, create_dir = FALSE) {
  project_path(project, "governance", "remediation_plans", create_dir = create_dir)
}

remediation_plan_plans_dir <- function(project, create_dir = FALSE) {
  dir <- file.path(remediation_plan_dir(project, create_dir = create_dir), "plans")
  if (isTRUE(create_dir) && !dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

remediation_plan_path <- function(project, plan_id, create_dir = FALSE) {
  if (!storage_resource_id_is_valid(plan_id)) stop("Remediation plan id is malformed.", call. = FALSE)
  file.path(remediation_plan_plans_dir(project, create_dir = create_dir), paste0(plan_id, ".json"))
}

remediation_plan_event_log_path <- function(project, create_dir = FALSE) {
  file.path(remediation_plan_dir(project, create_dir = create_dir), "events.ndjson")
}

remediation_plan_checkpoint_path <- function(project, create_dir = FALSE) {
  dir <- file.path(remediation_plan_dir(project, create_dir = create_dir), "checkpoints")
  if (isTRUE(create_dir) && !dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  file.path(dir, "checkpoint.json")
}

remediation_plan_safe_scalar <- function(value, max_chars = 1000L) {
  improvement_safe_scalar(value, max_chars = max_chars)
}

remediation_plan_contains_unsafe <- function(value) {
  improvement_contains_absolute_path(value) || improvement_contains_code(value) || improvement_has_unsafe_object(value)
}

remediation_plan_id <- function(project_id, source_item_id, title, revision = 1L) {
  paste0("plan_", substr(storage_hash_value(list(project_id, source_item_id, title, revision, Sys.time())), 1L, 16L))
}

remediation_step_id <- function(index, title = "step") {
  paste0("step_", sprintf("%03d", as.integer(index)), "_", safe_path_component(title, "step"))
}

remediation_plan_fingerprint <- function(plan) {
  x <- plan
  x$plan_fingerprint <- NULL
  x$updated_at <- NULL
  storage_hash_value(x)
}

remediation_manual_input_field <- function(field_id, label, input_type = "short_text", required = TRUE, allowed_values = character(), validation_rule = NA_character_, help_text = NULL) {
  list(
    manual_input_schema_version = remediation_manual_input_schema_version(),
    field_id = safe_path_component(field_id, "field"),
    label = remediation_plan_safe_scalar(label, 120L),
    input_type = input_type,
    required = isTRUE(required),
    allowed_values = as.character(allowed_values %||% character()),
    validation_rule = remediation_plan_safe_scalar(validation_rule %||% "", 160L),
    help_text = remediation_plan_safe_scalar(help_text %||% "", 300L)
  )
}

remediation_plan_step <- function(
  step_index,
  step_type,
  title,
  description = NULL,
  depends_on = character(),
  action_id = NA_character_,
  action_arguments = list(),
  manual_input_schema = list(),
  re_evaluation_spec = list(),
  expected_effect = NULL,
  risk_tier = "low",
  approval_requirement = "normal_policy",
  delegation_eligible = FALSE,
  maximum_attempts = 1L,
  failure_policy = "stop_plan",
  next_on_success = NA_character_,
  next_on_failure = NA_character_,
  stop_on_failure = TRUE
) {
  step <- list(
    step_id = remediation_step_id(step_index, title),
    step_schema_version = remediation_plan_step_schema_version(),
    step_index = as.integer(step_index),
    step_type = step_type,
    title = remediation_plan_safe_scalar(title, 160L),
    description = remediation_plan_safe_scalar(description %||% "", 1000L),
    depends_on = as.character(depends_on %||% character()),
    status = "pending",
    action_id = as.character(action_id %||% NA_character_),
    action_arguments = action_arguments %||% list(),
    manual_input_schema = manual_input_schema %||% list(),
    manual_input_values = list(),
    re_evaluation_spec = re_evaluation_spec %||% list(),
    expected_effect = remediation_plan_safe_scalar(expected_effect %||% "", 500L),
    risk_tier = risk_tier,
    approval_requirement = approval_requirement,
    delegation_eligible = isTRUE(delegation_eligible),
    maximum_attempts = as.integer(maximum_attempts),
    attempt_count = 0L,
    started_at = NA_character_,
    completed_at = NA_character_,
    result_refs = list(),
    evidence_refs = list(),
    failure_policy = failure_policy,
    next_on_success = as.character(next_on_success %||% NA_character_),
    next_on_failure = as.character(next_on_failure %||% NA_character_),
    stop_on_failure = isTRUE(stop_on_failure)
  )
  step$step_fingerprint <- storage_hash_value(step)
  step
}

remediation_plan_required_fields <- function() {
  c(
    "plan_id", "plan_schema_version", "project_id", "source_item_id",
    "source_item_version", "title", "objective", "status", "created_at",
    "updated_at", "created_by", "risk_tier", "execution_mode",
    "allowed_action_ids", "maximum_steps", "maximum_attempts",
    "maximum_runtime_seconds", "maximum_persistent_actions", "current_step_id",
    "steps", "success_criteria", "stop_conditions", "resource_budget",
    "approval_policy", "plan_fingerprint", "revision"
  )
}

remediation_plan_new <- function(
  project,
  source_item,
  title,
  objective,
  steps,
  success_criteria,
  stop_conditions = remediation_plan_default_stop_conditions(),
  risk_tier = "medium",
  execution_mode = "stepwise",
  approval_policy = "plan_structure_only",
  maximum_steps = 10L,
  maximum_attempts = 3L,
  maximum_runtime_seconds = 900L,
  maximum_persistent_actions = 1L,
  created_by = "application",
  revision = 1L,
  parent_plan_id = NA_character_,
  supersedes_plan_id = NA_character_
) {
  plan <- list(
    plan_id = remediation_plan_id(project$project_id, source_item$item_id, title, revision),
    plan_schema_version = remediation_plan_schema_version(),
    project_id = project$project_id,
    source_item_id = source_item$item_id,
    source_item_version = paste(source_item$item_schema_version %||% "", source_item$updated_at %||% "", sep = "@"),
    title = remediation_plan_safe_scalar(title, 160L),
    objective = remediation_plan_safe_scalar(objective, 1200L),
    status = "draft",
    created_at = storage_now(),
    updated_at = storage_now(),
    created_by = created_by,
    approved_at = NA_character_,
    approved_by = NA_character_,
    started_at = NA_character_,
    completed_at = NA_character_,
    paused_at = NA_character_,
    cancelled_at = NA_character_,
    expires_at = format(Sys.time() + 7 * 24 * 3600, "%Y-%m-%dT%H:%M:%S%z"),
    risk_tier = risk_tier,
    execution_mode = execution_mode,
    allowed_action_ids = c("module.open", "artifact.inspect", "report.open", "analysis.preflight", "analysis.run_registered", "result.persist", "result.inspect"),
    maximum_steps = as.integer(maximum_steps),
    maximum_attempts = as.integer(maximum_attempts),
    maximum_runtime_seconds = as.integer(maximum_runtime_seconds),
    maximum_persistent_actions = as.integer(maximum_persistent_actions),
    current_step_id = NA_character_,
    steps = steps,
    success_criteria = as.character(success_criteria %||% character()),
    stop_conditions = as.character(stop_conditions %||% character()),
    resource_budget = list(maximum_steps = as.integer(maximum_steps), maximum_attempts = as.integer(maximum_attempts), maximum_runtime_seconds = as.integer(maximum_runtime_seconds), maximum_persistent_actions = as.integer(maximum_persistent_actions)),
    approval_policy = approval_policy,
    revision = as.integer(revision),
    parent_plan_id = as.character(parent_plan_id %||% NA_character_),
    supersedes_plan_id = as.character(supersedes_plan_id %||% NA_character_),
    event_refs = list(),
    audit_refs = list(),
    attempt_refs = list(),
    recovery_status = "not_recovered"
  )
  plan$plan_fingerprint <- remediation_plan_fingerprint(plan)
  plan
}

remediation_plan_default_stop_conditions <- function() {
  c(
    "maximum step count reached", "maximum runtime reached", "maximum retries reached",
    "critical failure", "project changed", "provider changed", "source item invalidated",
    "resolution criteria met", "user cancelled", "required approval denied",
    "unsupported state encountered"
  )
}

remediation_plan_validate_manual_input_schema <- function(schema) {
  errors <- character()
  if (!is.list(schema)) return(service_result(status = "error", errors = "Manual input schema must be a list."))
  for (field in schema) {
    if (!is.list(field)) {
      errors <- c(errors, "Manual input field must be a list.")
      next
    }
    if (!identical(field$manual_input_schema_version %||% "", remediation_manual_input_schema_version())) errors <- c(errors, "Unsupported manual input schema.")
    if (!storage_resource_id_is_valid(field$field_id %||% "")) errors <- c(errors, "Manual input field_id is invalid.")
    if (!(field$input_type %||% "") %in% remediation_plan_manual_input_types()) errors <- c(errors, paste("Unsupported manual input type:", field$input_type %||% "missing"))
    if (remediation_plan_contains_unsafe(field)) errors <- c(errors, "Manual input schema contains unsafe content.")
  }
  if (length(errors)) service_result(status = "error", errors = unique(errors)) else service_result(status = "success", value = schema)
}

remediation_plan_validate_step <- function(step, allowed_action_ids = NULL, registry = genai_action_registry()) {
  errors <- character()
  if (!is.list(step)) return(service_result(status = "error", errors = "Step must be a list."))
  required <- c("step_id", "step_schema_version", "step_index", "step_type", "title", "depends_on", "status", "maximum_attempts", "attempt_count", "failure_policy", "step_fingerprint")
  missing <- setdiff(required, names(step))
  if (length(missing)) errors <- c(errors, paste("Missing step fields:", paste(missing, collapse = ", ")))
  if (!identical(step$step_schema_version %||% "", remediation_plan_step_schema_version())) errors <- c(errors, "Unsupported step schema.")
  if (!storage_resource_id_is_valid(step$step_id %||% "")) errors <- c(errors, "Invalid step_id.")
  if (!(step$step_type %||% "") %in% remediation_plan_step_types()) errors <- c(errors, paste("Unsupported step_type:", step$step_type %||% "missing"))
  if (!step$failure_policy %in% remediation_plan_failure_policies()) errors <- c(errors, paste("Unsupported failure_policy:", step$failure_policy %||% "missing"))
  if ((step$maximum_attempts %||% 0L) < 1L || (step$maximum_attempts %||% 0L) > 3L) errors <- c(errors, "Step maximum_attempts must be between 1 and 3.")
  if (remediation_plan_contains_unsafe(step$title) || remediation_plan_contains_unsafe(step$description) || remediation_plan_contains_unsafe(step$action_arguments)) errors <- c(errors, "Step contains unsafe path, executable content, or object.")
  if (identical(step$step_type, "registered_action")) {
    if (!(step$action_id %||% "") %in% (allowed_action_ids %||% names(genai_action_registry_list(registry)))) errors <- c(errors, paste("Action is not allowed in this plan:", step$action_id %||% "missing"))
    action <- genai_action_registry_get(step$action_id %||% "", registry)
    if (is.null(action)) {
      errors <- c(errors, paste("Unknown registered action:", step$action_id %||% "missing"))
    } else {
      args <- step$action_arguments %||% list()
      extra <- switch(step$action_id %||% "",
        "module.open" = setdiff(names(args), "module_id"),
        "artifact.inspect" = setdiff(names(args), "artifact_id"),
        "report.open" = setdiff(names(args), "report_id"),
        "analysis.preflight" = setdiff(names(args), c("module_id", "dataset_id")),
        "analysis.run_registered" = setdiff(names(args), c("module_id", "dataset_id", "configuration")),
        "result.persist" = setdiff(names(args), "temporary_result_id"),
        "result.inspect" = setdiff(names(args), "result_id"),
        character()
      )
      if (length(extra)) errors <- c(errors, paste("Action step has unsupported arguments:", paste(extra, collapse = ", ")))
      if (step$action_id %in% c("module.open", "analysis.preflight", "analysis.run_registered") && !nzchar(args$module_id %||% "")) errors <- c(errors, paste(step$action_id, "requires module_id."))
      if (identical(step$action_id, "artifact.inspect") && !nzchar(args$artifact_id %||% "")) errors <- c(errors, "artifact.inspect requires artifact_id.")
      if (identical(step$action_id, "report.open") && !nzchar(args$report_id %||% "")) errors <- c(errors, "report.open requires report_id.")
      if (identical(step$action_id, "result.persist") && !nzchar(args$temporary_result_id %||% "")) errors <- c(errors, "result.persist requires temporary_result_id.")
      if (identical(step$action_id, "result.inspect") && !nzchar(args$result_id %||% "")) errors <- c(errors, "result.inspect requires result_id.")
      if (!identical(max_risk_tier(step$risk_tier %||% "low", action$risk_tier %||% "low"), step$risk_tier %||% "low")) errors <- c(errors, "Step risk_tier must not understate registered action risk.")
    }
  }
  if (identical(step$step_type, "manual_user_input")) {
    schema_validation <- remediation_plan_validate_manual_input_schema(step$manual_input_schema %||% list())
    if (!identical(schema_validation$status, "success")) errors <- c(errors, schema_validation$errors)
    if (!length(step$manual_input_schema %||% list())) errors <- c(errors, "Manual input step requires a manual_input_schema.")
  }
  if (identical(step$step_type, "deterministic_re_evaluation")) {
    spec <- step$re_evaluation_spec %||% list()
    required_spec <- c("evaluation_id", "source_item_id", "pass_condition")
    missing_spec <- setdiff(required_spec, names(spec))
    if (length(missing_spec)) errors <- c(errors, paste("Missing re-evaluation fields:", paste(missing_spec, collapse = ", ")))
    if (remediation_plan_contains_unsafe(spec)) errors <- c(errors, "Re-evaluation spec contains unsafe content.")
  }
  if (identical(step$step_type, "decision_gate")) {
    spec <- step$re_evaluation_spec %||% list()
    if (!identical(spec$decision_gate_schema_version %||% "", remediation_decision_gate_schema_version())) errors <- c(errors, "Decision gate requires supported decision gate schema.")
    allowed_next <- as.character(spec$allowed_next_step_ids %||% character())
    if (!length(allowed_next)) errors <- c(errors, "Decision gate requires allowed next step ids.")
  }
  if (length(errors)) service_result(status = "error", errors = unique(errors)) else service_result(status = "success", value = step)
}

max_risk_tier <- function(a, b) {
  levels <- c(none = 0L, low = 1L, medium = 2L, high = 3L, critical = 4L)
  rank <- function(x) {
    value <- unname(levels[as.character(x %||% "low")])
    if (is.na(value)) unname(levels[["low"]]) else value
  }
  max_rank <- max(rank(a), rank(b))
  names(levels)[match(max_rank, unname(levels))]
}

remediation_plan_dependency_errors <- function(steps) {
  ids <- vapply(steps, function(step) step$step_id %||% "", character(1))
  errors <- character()
  if (anyDuplicated(ids) || any(!nzchar(ids))) errors <- c(errors, "Step IDs must be unique and nonempty.")
  deps <- lapply(steps, function(step) as.character(step$depends_on %||% character()))
  names(deps) <- ids
  unknown <- unique(unlist(lapply(deps, setdiff, ids), use.names = FALSE))
  if (length(unknown)) errors <- c(errors, paste("Unknown step dependencies:", paste(unknown, collapse = ", ")))
  visiting <- character()
  visited <- character()
  has_cycle <- FALSE
  visit <- function(id) {
    if (id %in% visiting) {
      has_cycle <<- TRUE
      return()
    }
    if (id %in% visited) return()
    visiting <<- c(visiting, id)
    for (dep in deps[[id]] %||% character()) visit(dep)
    visiting <<- setdiff(visiting, id)
    visited <<- c(visited, id)
  }
  for (id in ids) visit(id)
  if (has_cycle) errors <- c(errors, "Step dependencies contain a cycle.")
  errors
}

remediation_plan_transition_allowed <- function(from_status, to_status) {
  if (!from_status %in% remediation_plan_statuses() || !to_status %in% remediation_plan_statuses()) return(FALSE)
  identical(from_status, to_status) || to_status %in% (remediation_plan_transition_map()[[from_status]] %||% character())
}

remediation_plan_lifecycle_diagnostics <- function() {
  lifecycle <- remediation_plan_lifecycle()
  map <- lifecycle$transition_map
  statuses <- lifecycle$statuses
  referenced <- unique(unlist(map, use.names = FALSE))
  list(
    missing_status_keys = setdiff(statuses, names(map)),
    unknown_referenced_statuses = setdiff(referenced, statuses),
    terminal_with_outgoing_transitions = names(map)[names(map) %in% lifecycle$terminal & vapply(map, length, integer(1)) > 0L],
    resumable_terminal_overlap = intersect(lifecycle$resumable, lifecycle$terminal),
    approval_terminal_overlap = intersect(lifecycle$approval_required, lifecycle$terminal),
    retryable_terminal_overlap = intersect(lifecycle$retryable, lifecycle$terminal)
  )
}

remediation_plan_validate <- function(plan, project = NULL, source_item = NULL, registry = genai_action_registry()) {
  errors <- character()
  warnings <- character()
  if (!is.list(plan)) return(service_result(status = "error", errors = "Plan must be a list."))
  missing <- setdiff(remediation_plan_required_fields(), names(plan))
  if (length(missing)) errors <- c(errors, paste("Missing plan fields:", paste(missing, collapse = ", ")))
  if (!identical(plan$plan_schema_version %||% "", remediation_plan_schema_version())) errors <- c(errors, "Unsupported remediation plan schema.")
  if (!storage_resource_id_is_valid(plan$plan_id %||% "")) errors <- c(errors, "Invalid plan_id.")
  if (!(plan$status %||% "") %in% remediation_plan_statuses()) errors <- c(errors, paste("Invalid plan status:", plan$status %||% "missing"))
  if (!(plan$approval_policy %||% "") %in% remediation_plan_approval_policies()) errors <- c(errors, paste("Invalid approval policy:", plan$approval_policy %||% "missing"))
  if (!is.null(project) && !identical(plan$project_id %||% "", project$project_id %||% "")) errors <- c(errors, "Plan project_id does not match active project.")
  if (is.null(source_item)) {
    if (!is.null(project) && storage_resource_id_is_valid(plan$source_item_id %||% "")) {
      loaded <- improvement_load_item(project, plan$source_item_id)
      if (identical(loaded$status, "success")) source_item <- loaded$value
    }
  }
  if (is.null(source_item)) {
    errors <- c(errors, "Source improvement item does not exist.")
  } else {
    if (!identical(source_item$project_id %||% "", plan$project_id %||% "")) errors <- c(errors, "Source item belongs to a different project.")
    if (!(plan$status %||% "") %in% remediation_plan_terminal_statuses() &&
        (source_item$status %||% "") %in% c("resolved", "rejected", "duplicate", "superseded")) {
      errors <- c(errors, "Source item status does not permit remediation.")
    }
  }
  steps <- plan$steps %||% list()
  if (!length(steps)) errors <- c(errors, "Plan requires at least one step.")
  if (length(steps) > (plan$maximum_steps %||% 0L) || length(steps) > 20L) errors <- c(errors, "Plan has excessive steps.")
  if ((plan$maximum_steps %||% 0L) < 1L || (plan$maximum_steps %||% 0L) > 20L) errors <- c(errors, "maximum_steps must be between 1 and 20.")
  if ((plan$maximum_attempts %||% 0L) < 1L || (plan$maximum_attempts %||% 0L) > 20L) errors <- c(errors, "maximum_attempts must be between 1 and 20.")
  if ((plan$maximum_runtime_seconds %||% 0L) < 1L || (plan$maximum_runtime_seconds %||% 0L) > 86400L) errors <- c(errors, "maximum_runtime_seconds must be bounded.")
  if ((plan$maximum_persistent_actions %||% -1L) < 0L || (plan$maximum_persistent_actions %||% -1L) > 3L) errors <- c(errors, "maximum_persistent_actions must be between 0 and 3.")
  if (!length(plan$success_criteria %||% character())) errors <- c(errors, "Plan requires success criteria.")
  if (!length(plan$stop_conditions %||% character())) errors <- c(errors, "Plan requires stop conditions.")
  if (remediation_plan_contains_unsafe(plan$title) || remediation_plan_contains_unsafe(plan$objective) || remediation_plan_contains_unsafe(plan$success_criteria) || remediation_plan_contains_unsafe(plan$stop_conditions)) errors <- c(errors, "Plan contains unsafe path, code, or object.")
  step_results <- lapply(steps, remediation_plan_validate_step, allowed_action_ids = plan$allowed_action_ids %||% character(), registry = registry)
  step_errors <- unlist(lapply(step_results, function(x) x$errors %||% character()), use.names = FALSE)
  if (length(step_errors)) errors <- c(errors, step_errors)
  errors <- c(errors, remediation_plan_dependency_errors(steps))
  action_ids <- vapply(steps, function(step) step$action_id %||% NA_character_, character(1))
  persistent_count <- sum(action_ids == "result.persist", na.rm = TRUE)
  if (persistent_count > (plan$maximum_persistent_actions %||% 0L)) errors <- c(errors, "Plan exceeds maximum persistent action count.")
  if (any(action_ids %in% c("code.run", "code_runner", "arbitrary_code"), na.rm = TRUE)) errors <- c(errors, "Arbitrary code actions are not supported.")
  if (length(errors)) service_result(status = "error", errors = unique(errors), warnings = warnings) else service_result(status = "success", value = plan, warnings = warnings)
}

remediation_plan_safe_transition <- function(plan, to_status, reason = NULL) {
  from <- plan$status %||% "draft"
  if (!to_status %in% remediation_plan_statuses()) return(service_result(status = "error", errors = paste("Invalid plan status:", to_status)))
  if (remediation_plan_transition_allowed(from, to_status)) {
    plan$status <- to_status
    plan$updated_at <- storage_now()
    if (identical(to_status, "approved")) plan$approved_at <- plan$updated_at
    if (identical(to_status, "running") && !nzchar(plan$started_at %||% "")) plan$started_at <- plan$updated_at
    if (to_status %in% remediation_plan_terminal_statuses()) plan$completed_at <- plan$updated_at
    if (identical(to_status, "paused")) plan$paused_at <- plan$updated_at
    if (identical(to_status, "cancelled")) plan$cancelled_at <- plan$updated_at
    plan$plan_fingerprint <- remediation_plan_fingerprint(plan)
    return(service_result(status = "success", value = plan))
  }
  service_result(status = "error", errors = paste("Invalid plan transition:", from, "->", to_status))
}

remediation_plan_event_hash <- function(event, previous_event_hash = "") {
  x <- event
  x$event_hash <- NULL
  x$previous_event_hash <- previous_event_hash %||% ""
  normalize <- function(value) {
    if (is.null(value)) return(NA_character_)
    if (is.list(value)) {
      nms <- sort(names(value) %||% character())
      if (length(nms)) return(stats::setNames(lapply(nms, function(name) normalize(value[[name]])), nms))
      return(lapply(value, normalize))
    }
    if (length(value) > 1L) return(vapply(value, as.character, character(1)))
    as.character(value)
  }
  storage_hash_value(normalize(x))
}

remediation_plan_event <- function(event_type, plan, step = NULL, summary = NULL, idempotency_key = NULL) {
  list(
    plan_event_id = paste0("planevt_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    plan_event_schema_version = remediation_plan_event_schema_version(),
    event_type = event_type,
    event_timestamp = storage_now(),
    plan_id = plan$plan_id %||% NA_character_,
    plan_revision = plan$revision %||% 1L,
    source_item_id = plan$source_item_id %||% NA_character_,
    project_id = plan$project_id %||% NA_character_,
    step_id = step$step_id %||% NA_character_,
    step_type = step$step_type %||% NA_character_,
    action_id = step$action_id %||% NA_character_,
    status = plan$status %||% NA_character_,
    step_status = step$status %||% NA_character_,
    summary = remediation_plan_safe_scalar(summary %||% event_type, 500L),
    idempotency_key = idempotency_key %||% paste(event_type, plan$plan_id %||% "", step$step_id %||% "", plan$updated_at %||% "", sep = "|")
  )
}

remediation_plan_validate_event <- function(event) {
  errors <- character()
  required <- c("plan_event_id", "plan_event_schema_version", "event_type", "event_timestamp", "plan_id", "project_id", "idempotency_key")
  missing <- setdiff(required, names(event))
  if (length(missing)) errors <- c(errors, paste("Missing plan event fields:", paste(missing, collapse = ", ")))
  if (!identical(event$plan_event_schema_version %||% "", remediation_plan_event_schema_version())) errors <- c(errors, "Unsupported plan event schema.")
  allowed <- c(
    "plan_created", "plan_validated", "plan_rejected", "plan_approved",
    "plan_started", "plan_paused", "plan_resumed", "plan_step_started",
    "plan_step_completed", "plan_step_failed", "plan_step_cancelled",
    "plan_step_approval_requested", "plan_step_approved", "plan_step_rejected",
    "plan_user_input_requested", "plan_user_input_received",
    "plan_re_evaluation_started", "plan_re_evaluation_completed",
    "plan_revised", "plan_succeeded", "plan_partially_succeeded",
    "plan_failed", "plan_cancelled", "plan_expired"
  )
  if (!(event$event_type %||% "") %in% allowed) errors <- c(errors, paste("Unsupported plan event type:", event$event_type %||% "missing"))
  if (remediation_plan_contains_unsafe(event)) errors <- c(errors, "Plan event contains unsafe content.")
  if (length(errors)) service_result(status = "error", errors = unique(errors)) else service_result(status = "success", value = event)
}

remediation_plan_read_events <- function(project, validate_hash_chain = TRUE) {
  path <- tryCatch(remediation_plan_event_log_path(project), error = function(e) NULL)
  if (is.null(path) || !file.exists(path)) return(service_result(status = "success", value = list(events = data.table::data.table(), ledger_health = "missing", malformed_count = 0L)))
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  parsed <- list()
  malformed <- 0L
  health <- "healthy"
  previous_hash <- ""
  for (i in seq_along(lines)) {
    line <- trimws(lines[[i]])
    if (!nzchar(line)) next
    event <- tryCatch(jsonlite::fromJSON(line, simplifyVector = FALSE), error = function(e) structure(list(error = conditionMessage(e)), class = "remediation_plan_parse_error"))
    if (inherits(event, "remediation_plan_parse_error")) {
      malformed <- malformed + 1L
      health <- if (i == length(lines)) "partial" else "malformed"
      next
    }
    if (!identical(event$plan_event_schema_version %||% "", remediation_plan_event_schema_version())) health <- "unsupported_schema"
    if (isTRUE(validate_hash_chain) && health %in% c("healthy", "unsupported_schema")) {
      expected <- remediation_plan_event_hash(event, previous_hash)
      if (!identical(event$previous_event_hash %||% "", previous_hash) || !identical(event$event_hash %||% "", expected)) health <- "event_history_mismatch"
      previous_hash <- event$event_hash %||% previous_hash
    } else {
      previous_hash <- event$event_hash %||% previous_hash
    }
    parsed[[length(parsed) + 1L]] <- event
  }
  normalize <- function(x) {
    out <- lapply(x, function(value) {
      if (is.null(value) || length(value) == 0L) NA_character_ else if (is.list(value)) paste(vapply(value, remediation_plan_safe_scalar, character(1), max_chars = 120L), collapse = "; ") else if (length(value) > 1L) paste(as.character(value), collapse = "; ") else value
    })
    as.data.frame(out, stringsAsFactors = FALSE)
  }
  events <- if (length(parsed)) data.table::rbindlist(lapply(parsed, normalize), fill = TRUE) else data.table::data.table()
  service_result(status = "success", value = list(events = events, ledger_health = health, malformed_count = malformed))
}

remediation_plan_append_event <- function(project, workspace, event) {
  path <- remediation_plan_event_log_path(project, create_dir = TRUE)
  gate <- persistent_write_gate(workspace, project, path, "remediation_plan_event")
  if (!identical(gate$status, "success")) return(service_result(status = "error", errors = gate$errors))
  validation <- remediation_plan_validate_event(event)
  if (!identical(validation$status, "success")) return(validation)
  event <- validation$value
  existing <- remediation_plan_read_events(project)
  if (!identical(existing$status, "success")) return(existing)
  if (!identical(existing$value$ledger_health %||% "missing", "healthy") && !identical(existing$value$ledger_health %||% "missing", "missing")) {
    return(service_result(status = "error", errors = paste("Remediation event ledger is unhealthy:", existing$value$ledger_health %||% "unknown")))
  }
  events <- existing$value$events
  if (nrow(events) && "idempotency_key" %in% names(events) && event$idempotency_key %in% events$idempotency_key) {
    return(service_result(status = "success", value = list(already_recorded = TRUE)))
  }
  previous_hash <- if (nrow(events) && "event_hash" %in% names(events)) tail(events$event_hash, 1L) else ""
  event$previous_event_hash <- previous_hash %||% ""
  event$event_hash <- remediation_plan_event_hash(event, event$previous_event_hash)
  line <- jsonlite::toJSON(event, auto_unbox = TRUE, null = "null", digits = NA)
  tryCatch({
    con <- file(path, open = "ab")
    on.exit(close(con), add = TRUE)
    writeBin(charToRaw(paste0(line, "\n")), con)
    checkpoint <- list(
      plan_checkpoint_schema_version = remediation_plan_checkpoint_schema_version(),
      plan_schema_version = remediation_plan_schema_version(),
      event_schema_version = remediation_plan_event_schema_version(),
      event_count = nrow(events) + 1L,
      last_event_id = event$plan_event_id,
      last_event_hash = event$event_hash,
      updated_at = storage_now()
    )
    atomic_save_json(checkpoint, remediation_plan_checkpoint_path(project, create_dir = TRUE), pretty = TRUE)
    service_result(status = "success", value = list(already_recorded = FALSE, event_id = event$plan_event_id))
  }, error = function(e) service_result(status = "error", errors = conditionMessage(e)))
}

remediation_plan_save <- function(project, workspace, plan, event_type = "plan_created", summary = NULL, source_item = NULL) {
  validation <- remediation_plan_validate(plan, project = project, source_item = source_item)
  if (!identical(validation$status, "success") && !identical(plan$status, "validation_failed")) return(validation)
  path <- remediation_plan_path(project, plan$plan_id, create_dir = TRUE)
  gate <- persistent_write_gate(workspace, project, path, "remediation_plan")
  if (!identical(gate$status, "success")) return(service_result(status = "error", errors = gate$errors))
  plan$updated_at <- storage_now()
  plan$plan_fingerprint <- remediation_plan_fingerprint(plan)
  tryCatch({
    atomic_save_json(plan, path, pretty = TRUE)
    ev <- remediation_plan_event(event_type, plan, summary = summary)
    append <- remediation_plan_append_event(project, workspace, ev)
    if (!identical(append$status, "success")) return(append)
    service_result(status = "success", value = plan, metadata = list(event = append$value))
  }, error = function(e) service_result(status = "error", errors = conditionMessage(e)))
}

remediation_plan_load <- function(project, plan_id) {
  path <- remediation_plan_path(project, plan_id)
  if (!file.exists(path)) return(service_result(status = "error", errors = paste("Remediation plan not found:", plan_id)))
  plan <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) e)
  if (inherits(plan, "error")) return(service_result(status = "error", errors = conditionMessage(plan)))
  validation <- remediation_plan_validate(plan, project = project)
  if (!identical(validation$status, "success")) return(validation)
  service_result(status = "success", value = plan)
}

remediation_plan_load_all <- function(project, include_invalid = FALSE) {
  dir <- tryCatch(remediation_plan_plans_dir(project), error = function(e) NULL)
  if (is.null(dir) || !dir.exists(dir)) return(service_result(status = "success", value = list(plans = list(), ledger_health = "missing", invalid_plans = list())))
  paths <- list.files(dir, pattern = "\\.json$", full.names = TRUE)
  plans <- list()
  invalid <- list()
  health <- "healthy"
  for (path in paths) {
    plan <- tryCatch(jsonlite::fromJSON(path, simplifyVector = FALSE), error = function(e) e)
    if (inherits(plan, "error")) {
      invalid[[basename(path)]] <- conditionMessage(plan)
      health <- "malformed"
      next
    }
    validation <- remediation_plan_validate(plan, project = project)
    if (!identical(validation$status, "success")) {
      invalid[[plan$plan_id %||% basename(path)]] <- validation$errors
      health <- if (grepl("Unsupported", paste(validation$errors, collapse = " "))) "unsupported_schema" else "malformed"
      if (isTRUE(include_invalid)) plans[[length(plans) + 1L]] <- plan
      next
    }
    plans[[length(plans) + 1L]] <- plan
  }
  events <- remediation_plan_read_events(project)
  event_health <- events$value$ledger_health %||% "missing"
  if (identical(health, "healthy") && event_health %in% c("malformed", "partial", "unsupported_schema", "event_history_mismatch")) health <- event_health
  service_result(status = "success", value = list(plans = plans, ledger_health = health, invalid_plans = invalid, events = events$value))
}

remediation_plan_table <- function(plans) {
  if (!length(plans)) return(data.table::data.table())
  data.table::rbindlist(lapply(plans, function(plan) {
    completed <- sum(vapply(plan$steps %||% list(), function(step) step$status %in% c("succeeded", "completed", "skipped"), logical(1)))
    data.table::data.table(
      plan_id = plan$plan_id %||% NA_character_,
      source_item_id = plan$source_item_id %||% NA_character_,
      title = plan$title %||% NA_character_,
      status = plan$status %||% NA_character_,
      risk_tier = plan$risk_tier %||% NA_character_,
      current_step_id = plan$current_step_id %||% NA_character_,
      completed_steps = completed,
      total_steps = length(plan$steps %||% list()),
      created_at = plan$created_at %||% NA_character_,
      updated_at = plan$updated_at %||% NA_character_,
      next_required_action = remediation_plan_next_required_action(plan)
    )
  }), fill = TRUE)
}

remediation_plan_next_required_action <- function(plan) {
  if ((plan$status %||% "") %in% c("awaiting_user_input")) return("Provide input")
  if ((plan$status %||% "") %in% c("awaiting_step_approval", "awaiting_user_review")) return("Review / approve")
  if ((plan$status %||% "") %in% c("paused")) return("Resume or revise")
  if ((plan$status %||% "") %in% remediation_plan_terminal_statuses()) return("Complete")
  next_step <- remediation_plan_next_step(plan)
  if (is.null(next_step)) return("Re-evaluate or complete")
  switch(next_step$step_type,
    registered_action = paste("Run", next_step$action_id),
    manual_user_input = "Provide input",
    deterministic_re_evaluation = "Run re-evaluation",
    decision_gate = "Evaluate gate",
    informational = "Acknowledge",
    "Continue"
  )
}

remediation_plan_create_from_template <- function(project, source_item, template_id = NULL) {
  template_id <- template_id %||% remediation_plan_select_template(source_item)
  template <- remediation_plan_template_registry()[[template_id]]
  if (is.null(template)) return(service_result(status = "error", errors = "remediation_not_currently_executable"))
  if (!(source_item$item_type %||% "") %in% template$item_types) return(service_result(status = "error", errors = "Template does not support this item type."))
  steps <- template$build_steps(source_item)
  plan <- remediation_plan_new(
    project = project,
    source_item = source_item,
    title = template$title,
    objective = template$objective(source_item),
    steps = steps,
    success_criteria = template$success_criteria(source_item),
    stop_conditions = template$stop_conditions %||% remediation_plan_default_stop_conditions(),
    risk_tier = template$risk_tier,
    approval_policy = "plan_structure_only",
    maximum_steps = length(steps) + 2L,
    maximum_persistent_actions = template$maximum_persistent_actions %||% 0L
  )
  validation <- remediation_plan_validate(plan, project = project, source_item = source_item)
  if (!identical(validation$status, "success")) {
    plan$status <- "validation_failed"
    return(service_result(status = "error", value = plan, errors = validation$errors))
  }
  transition <- remediation_plan_safe_transition(plan, "awaiting_user_review", "Template plan constructed.")
  service_result(status = "success", value = transition$value)
}

remediation_plan_select_template <- function(source_item) {
  type <- source_item$item_type %||% ""
  if (type %in% c("configuration_gap", "validation_failure", "policy_block")) return("configuration_gap_registered_analysis")
  if (type %in% c("worker_failure", "execution_failure")) return("worker_failure_registered_analysis")
  if (type %in% c("result_integrity_issue", "resource_stale")) return("temporary_result_retention")
  if (type %in% c("user_requested_change", "enhancement_opportunity", "ux_problem")) return("manual_review_only")
  NA_character_
}

remediation_plan_resolve_module_id <- function(value, fallback = "dataset_profile") {
  candidate <- as.character(value %||% fallback)
  if (nzchar(candidate) && !is.null(get_module_definition(candidate))) return(candidate)
  fallback
}

remediation_plan_template_registry <- function() {
  list(
    configuration_gap_registered_analysis = list(
      template_schema_version = remediation_plan_template_schema_version(),
      template_id = "configuration_gap_registered_analysis",
      title = "Resolve registered-analysis configuration gap",
      item_types = c("configuration_gap", "validation_failure", "policy_block"),
      risk_tier = "medium",
      maximum_persistent_actions = 0L,
      objective = function(item) paste("Resolve:", item$title),
      success_criteria = function(item) item$resolution_criteria %||% c("preflight passes", "configuration is valid"),
      stop_conditions = remediation_plan_default_stop_conditions(),
      build_steps = function(item) {
        module_id <- remediation_plan_resolve_module_id(item$affected_resource_id %||% item$affected_component, "dataset_profile")
        list(
          remediation_plan_step(1, "registered_action", "Open affected module", action_id = "module.open", action_arguments = list(module_id = module_id), expected_effect = "Open the affected module for configuration review.", risk_tier = "low", delegation_eligible = TRUE, failure_policy = "pause_for_user"),
          remediation_plan_step(2, "manual_user_input", "Confirm configuration", depends_on = "step_001_Open_affected_module", manual_input_schema = list(remediation_manual_input_field("configuration_confirmed", "Configuration has been reviewed", "boolean", TRUE)), expected_effect = "User confirms required fields are configured.", failure_policy = "pause_for_user"),
          remediation_plan_step(3, "registered_action", "Run preflight", depends_on = "step_002_Confirm_configuration", action_id = "analysis.preflight", action_arguments = list(module_id = module_id, dataset_id = "active_dataset"), expected_effect = "Verify configuration readiness.", risk_tier = "medium", approval_requirement = "explicit_step_approval", failure_policy = "pause_for_user"),
          remediation_plan_step(4, "deterministic_re_evaluation", "Evaluate resolution criteria", depends_on = "step_003_Run_preflight", re_evaluation_spec = list(evaluation_id = "preflight_resolution", source_item_id = item$item_id, pass_condition = "preflight_ready"), expected_effect = "Determine whether the configuration gap is resolved.", risk_tier = "low", failure_policy = "stop_plan")
        )
      }
    ),
    worker_failure_registered_analysis = list(
      template_schema_version = remediation_plan_template_schema_version(),
      template_id = "worker_failure_registered_analysis",
      title = "Re-evaluate worker failure through bounded registered analysis",
      item_types = c("worker_failure", "execution_failure"),
      risk_tier = "medium",
      maximum_persistent_actions = 0L,
      objective = function(item) paste("Reproduce or clear worker failure:", item$title),
      success_criteria = function(item) item$resolution_criteria %||% c("worker completes within timeout"),
      stop_conditions = remediation_plan_default_stop_conditions(),
      build_steps = function(item) {
        module_id <- remediation_plan_resolve_module_id(item$affected_resource_id %||% item$affected_component, "dataset_profile")
        list(
          remediation_plan_step(1, "registered_action", "Run preflight", action_id = "analysis.preflight", action_arguments = list(module_id = module_id, dataset_id = "active_dataset"), risk_tier = "medium", approval_requirement = "explicit_step_approval", failure_policy = "stop_plan"),
          remediation_plan_step(2, "registered_action", "Run registered analysis", depends_on = "step_001_Run_preflight", action_id = "analysis.run_registered", action_arguments = list(module_id = module_id, dataset_id = "active_dataset"), risk_tier = "medium", approval_requirement = "explicit_step_approval", failure_policy = "stop_plan"),
          remediation_plan_step(3, "deterministic_re_evaluation", "Evaluate worker completion", depends_on = "step_002_Run_registered_analysis", re_evaluation_spec = list(evaluation_id = "worker_completion", source_item_id = item$item_id, pass_condition = "worker_succeeded"), risk_tier = "low")
        )
      }
    ),
    temporary_result_retention = list(
      template_schema_version = remediation_plan_template_schema_version(),
      template_id = "temporary_result_retention",
      title = "Inspect and validate result integrity",
      item_types = c("result_integrity_issue", "resource_stale"),
      risk_tier = "high",
      maximum_persistent_actions = 1L,
      objective = function(item) paste("Validate result integrity:", item$title),
      success_criteria = function(item) item$resolution_criteria %||% c("persisted result hashes validate", "audit reconciliation matched"),
      stop_conditions = remediation_plan_default_stop_conditions(),
      build_steps = function(item) {
        result_id <- item$affected_resource_id %||% "persisted_result"
        list(
          remediation_plan_step(1, "registered_action", "Inspect result", action_id = "result.inspect", action_arguments = list(persisted_result_id = result_id), risk_tier = "low", delegation_eligible = TRUE, failure_policy = "pause_for_user"),
          remediation_plan_step(2, "deterministic_re_evaluation", "Validate result integrity", depends_on = "step_001_Inspect_result", re_evaluation_spec = list(evaluation_id = "result_integrity", source_item_id = item$item_id, pass_condition = "hashes_validate"), risk_tier = "low")
        )
      }
    ),
    manual_review_only = list(
      template_schema_version = remediation_plan_template_schema_version(),
      template_id = "manual_review_only",
      title = "Manual review and acceptance plan",
      item_types = c("user_requested_change", "enhancement_opportunity", "ux_problem"),
      risk_tier = "low",
      maximum_persistent_actions = 0L,
      objective = function(item) paste("Review user-requested improvement:", item$title),
      success_criteria = function(item) item$resolution_criteria %||% c("user confirms outcome"),
      stop_conditions = remediation_plan_default_stop_conditions(),
      build_steps = function(item) {
        list(
          remediation_plan_step(1, "manual_user_input", "Collect user decision", manual_input_schema = list(remediation_manual_input_field("user_decision", "Decision", "choice", TRUE, c("accept", "defer", "reject", "needs_revision"))), expected_effect = "Capture user decision.", risk_tier = "low", failure_policy = "pause_for_user"),
          remediation_plan_step(2, "deterministic_re_evaluation", "Evaluate user decision", depends_on = "step_001_Collect_user_decision", re_evaluation_spec = list(evaluation_id = "user_acceptance", source_item_id = item$item_id, pass_condition = "user_accepts"), risk_tier = "low")
        )
      }
    )
  )
}

remediation_plan_approve <- function(project, workspace, plan_id, approved_by = "user", approval_policy = NULL) {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  if (!is.null(approval_policy)) plan$approval_policy <- approval_policy
  transition <- remediation_plan_safe_transition(plan, "approved", "Plan approved.")
  if (!identical(transition$status, "success")) return(transition)
  plan <- transition$value
  plan$approved_by <- approved_by
  saved <- remediation_plan_save(project, workspace, plan, "plan_approved", "Plan approved.")
  item <- improvement_load_item(project, plan$source_item_id)
  if (identical(item$status, "success")) {
    updated <- improvement_item_safe_transition(item$value, "planned", "Remediation plan approved.")
    if (identical(updated$status, "success")) improvement_save_item(project, workspace, updated$value, event_type = "item_updated", event_summary = "Remediation plan approved.", actor = "application")
  }
  saved
}

remediation_plan_reject <- function(project, workspace, plan_id, reason = "Plan rejected.") {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  transition <- remediation_plan_safe_transition(plan, "cancelled", reason)
  if (!identical(transition$status, "success")) return(transition)
  remediation_plan_save(project, workspace, transition$value, "plan_rejected", reason)
}

remediation_plan_next_step <- function(plan) {
  steps <- plan$steps %||% list()
  if (!length(steps)) return(NULL)
  completed <- vapply(steps, function(step) step$status %in% c("succeeded", "completed", "skipped"), logical(1))
  ids <- vapply(steps, function(step) step$step_id %||% "", character(1))
  for (i in seq_along(steps)) {
    step <- steps[[i]]
    if (!identical(step$status %||% "pending", "pending")) next
    deps <- step$depends_on %||% character()
    if (!length(deps) || all(deps %in% ids[completed])) return(step)
  }
  NULL
}

remediation_plan_update_step <- function(plan, step) {
  ids <- vapply(plan$steps %||% list(), function(x) x$step_id %||% "", character(1))
  idx <- match(step$step_id, ids)
  if (!is.na(idx)) plan$steps[[idx]] <- step
  plan$current_step_id <- step$step_id
  plan$updated_at <- storage_now()
  plan$plan_fingerprint <- remediation_plan_fingerprint(plan)
  plan
}

remediation_plan_step_requires_approval <- function(plan, step, action = NULL) {
  if (!identical(step$step_type, "registered_action")) return(FALSE)
  action <- action %||% genai_action_registry_get(step$action_id %||% "")
  if (is.null(action)) return(TRUE)
  if (identical(plan$approval_policy %||% "", "plan_and_low_risk_steps") &&
      identical(action$risk_tier %||% "", "low") &&
      isTRUE(step$delegation_eligible)) {
    return(FALSE)
  }
  isTRUE(action$approval_required) || !(action$risk_tier %||% "low") %in% c("low")
}

remediation_plan_start_or_resume <- function(plan) {
  if ((plan$status %||% "") %in% c("approved", "queued", "paused")) {
    remediation_plan_safe_transition(plan, "running", "Plan resumed.")
  } else {
    service_result(status = "success", value = plan)
  }
}

remediation_plan_execute_next_step <- function(project, workspace, plan_id, ctx = NULL, approval_hash = NULL) {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  if ((plan$status %||% "") %in% remediation_plan_terminal_statuses()) return(service_result(status = "error", errors = "Terminal plan cannot resume."))
  if (as.POSIXct(plan$expires_at) < Sys.time()) {
    expired <- remediation_plan_safe_transition(plan, "expired", "Plan expired.")
    if (identical(expired$status, "success")) remediation_plan_save(project, workspace, expired$value, "plan_expired", "Plan expired.")
    return(service_result(status = "error", errors = "Plan expired."))
  }
  validation <- remediation_plan_validate(plan, project = project)
  if (!identical(validation$status, "success")) return(validation)
  started <- remediation_plan_start_or_resume(plan)
  if (!identical(started$status, "success")) return(started)
  plan <- started$value
  step <- remediation_plan_next_step(plan)
  if (is.null(step)) {
    transition <- remediation_plan_safe_transition(plan, "re_evaluation_required", "No pending executable steps remain.")
    if (!identical(transition$status, "success")) return(transition)
    saved <- remediation_plan_save(project, workspace, transition$value, "plan_re_evaluation_started", "No pending steps remain.")
    return(service_result(status = "success", value = saved$value, messages = "Plan requires re-evaluation."))
  }
  step$status <- "running"
  step$started_at <- storage_now()
  step$attempt_count <- as.integer(step$attempt_count %||% 0L) + 1L
  if (step$attempt_count > (step$maximum_attempts %||% 1L)) {
    step$status <- "failed"
    plan <- remediation_plan_update_step(plan, step)
    failed <- remediation_plan_safe_transition(plan, "failed", "Step maximum attempts exceeded.")
    if (identical(failed$status, "success")) remediation_plan_save(project, workspace, failed$value, "plan_failed", "Step maximum attempts exceeded.")
    return(service_result(status = "error", errors = "Step maximum attempts exceeded."))
  }
  plan <- remediation_plan_update_step(plan, step)
  remediation_plan_append_event(project, workspace, remediation_plan_event("plan_step_started", plan, step, paste("Started step:", step$title)))
  if (identical(step$step_type, "manual_user_input")) {
    step$status <- "waiting_input"
    plan <- remediation_plan_update_step(plan, step)
    paused <- remediation_plan_safe_transition(plan, "awaiting_user_input", "Manual input required.")
    saved <- remediation_plan_save(project, workspace, paused$value, "plan_user_input_requested", "Manual input required.")
    item <- improvement_load_item(project, plan$source_item_id)
    if (identical(item$status, "success")) {
      updated <- improvement_item_safe_transition(item$value, "awaiting_user_input", "Remediation plan requested user input.")
      if (identical(updated$status, "success")) improvement_save_item(project, workspace, updated$value, event_type = "item_updated", event_summary = "Remediation plan awaiting user input.", actor = "application")
    }
    return(service_result(status = "needs_input", value = saved$value, messages = "Manual input required."))
  }
  if (identical(step$step_type, "registered_action")) {
    action <- genai_action_registry_get(step$action_id)
    if (is.null(action)) return(service_result(status = "error", errors = paste("Unknown action:", step$action_id)))
    proposal <- genai_action_proposal(
      action_id = step$action_id,
      action_version = action$action_version,
      arguments = step$action_arguments %||% list(),
      rationale = paste("Remediation plan", plan$plan_id, "step", step$step_id),
      expected_effects = step$expected_effect %||% action$description,
      risk_tier = max_risk_tier(step$risk_tier, action$risk_tier),
      confidence = "medium"
    )
    if (remediation_plan_step_requires_approval(plan, step, action) && is.null(approval_hash)) {
      step$status <- "waiting_approval"
      step$result_refs <- c(step$result_refs, list(list(result_type = "proposal", proposal_id = proposal$proposal_id, action_id = proposal$action_id, risk_tier = proposal$risk_tier)))
      plan <- remediation_plan_update_step(plan, step)
      paused <- remediation_plan_safe_transition(plan, "awaiting_step_approval", "Step approval required.")
      saved <- remediation_plan_save(project, workspace, paused$value, "plan_step_approval_requested", "Step approval required.")
      return(service_result(status = "needs_input", value = saved$value, metadata = list(proposal = proposal), messages = "Step approval required."))
    }
    validation <- genai_validate_action_proposal(proposal, ctx = ctx)
    if (!identical(validation$status, "success")) {
      step$status <- "failed"
      step$completed_at <- storage_now()
      step$result_refs <- c(step$result_refs, list(list(result_type = "proposal_validation", status = "error", errors = validation$errors)))
      plan <- remediation_plan_update_step(plan, step)
      improvement_record_attempt(project, workspace, plan$source_item_id, remediation_id = plan$plan_id, action_id = step$action_id, proposal_id = proposal$proposal_id, status = "failed", outcome_summary = paste(validation$errors, collapse = "; "))
      if (isTRUE(step$stop_on_failure)) {
        failed <- remediation_plan_safe_transition(plan, "failed", "Action proposal validation failed.")
        remediation_plan_save(project, workspace, failed$value, "plan_step_failed", "Action proposal validation failed.")
        return(service_result(status = "error", value = failed$value, errors = validation$errors))
      }
    }
    approved <- genai_approve_action_proposal(proposal, validation, approval_source = if (is.null(approval_hash)) "plan_low_risk" else "user")
    if (!identical(approved$status, "success")) return(approved)
    execution <- genai_execute_action_proposal(approved$value, ctx = ctx, approval_hash = approved$value$approval_hash)
    step$completed_at <- storage_now()
    step$status <- if (identical(execution$status, "success")) "succeeded" else "failed"
    step$result_refs <- c(step$result_refs, list(list(result_type = "action_execution", proposal_id = proposal$proposal_id, execution_id = execution$value$execution_id %||% execution$metadata$execution_id %||% NA_character_, status = execution$status, action_id = step$action_id)))
    plan <- remediation_plan_update_step(plan, step)
    improvement_record_attempt(project, workspace, plan$source_item_id, remediation_id = plan$plan_id, action_id = step$action_id, proposal_id = proposal$proposal_id, execution_id = execution$value$execution_id %||% execution$metadata$execution_id %||% NA_character_, status = if (identical(execution$status, "success")) "succeeded" else "failed", outcome_summary = paste(execution$messages %||% execution$errors %||% step$title, collapse = "; "))
    if (!identical(execution$status, "success") && isTRUE(step$stop_on_failure)) {
      failed <- remediation_plan_safe_transition(plan, "failed", "Action step failed.")
      saved <- remediation_plan_save(project, workspace, failed$value, "plan_step_failed", "Action step failed.")
      return(service_result(status = "error", value = saved$value, errors = execution$errors %||% "Action step failed."))
    }
    saved <- remediation_plan_save(project, workspace, plan, "plan_step_completed", paste("Completed step:", step$title))
    return(service_result(status = "success", value = saved$value, metadata = list(execution = execution), messages = paste("Completed step:", step$title)))
  }
  if (identical(step$step_type, "deterministic_re_evaluation")) {
    spec <- step$re_evaluation_spec %||% list()
    criteria_met <- identical(spec$pass_condition %||% "", "always_pass")
    remaining <- if (criteria_met) "" else "Resolution criteria require user or deterministic confirmation."
    item_before_eval <- improvement_load_item(project, plan$source_item_id)
    if (identical(item_before_eval$status, "success") && !(item_before_eval$value$status %||% "") %in% c("re_evaluation_required", "partially_resolved", "unresolved")) {
      item_for_eval <- item_before_eval$value
      transition_map <- improvement_status_transition_map()
      transition_queue <- list(list(status = item_for_eval$status %||% "", path = character()))
      visited <- character()
      transition_path <- NULL
      while (length(transition_queue) && is.null(transition_path)) {
        current <- transition_queue[[1L]]
        transition_queue <- transition_queue[-1L]
        if (current$status %in% visited) next
        visited <- c(visited, current$status)
        for (next_status in transition_map[[current$status]] %||% character()) {
          next_path <- c(current$path, next_status)
          if (identical(next_status, "re_evaluation_required")) {
            transition_path <- next_path
            break
          }
          transition_queue[[length(transition_queue) + 1L]] <- list(status = next_status, path = next_path)
        }
      }
      ready_for_eval <- service_result(status = "success", value = item_for_eval)
      for (next_status in transition_path %||% character()) {
        ready_for_eval <- improvement_item_safe_transition(ready_for_eval$value, next_status, "Remediation plan reached deterministic re-evaluation.")
        if (!identical(ready_for_eval$status, "success")) break
      }
      if (identical(ready_for_eval$status, "success") && identical(ready_for_eval$value$status %||% "", "re_evaluation_required")) {
        improvement_save_item(project, workspace, ready_for_eval$value, event_type = "item_updated", event_summary = "Remediation plan reached deterministic re-evaluation.", actor = "application")
      }
    }
    reevaluation <- improvement_record_re_evaluation(project, workspace, plan$source_item_id, "before remediation plan", "after remediation plan", step$expected_effect %||% step$title, criteria_met = criteria_met, remaining_gaps = remaining, user_confirmation_required = !criteria_met)
    step$status <- if (identical(reevaluation$status, "success")) "succeeded" else "failed"
    step$completed_at <- storage_now()
    step$result_refs <- c(step$result_refs, list(list(result_type = "re_evaluation", status = reevaluation$status, item_status = reevaluation$value$status %||% NA_character_)))
    plan <- remediation_plan_update_step(plan, step)
    target <- if (identical(reevaluation$status, "success") && identical(reevaluation$value$status, "resolved")) "succeeded" else if (identical(reevaluation$status, "success") && identical(reevaluation$value$status, "partially_resolved")) "partially_succeeded" else "re_evaluation_required"
    transition <- remediation_plan_safe_transition(plan, target, "Deterministic re-evaluation completed.")
    saved <- remediation_plan_save(project, workspace, transition$value, if (target == "succeeded") "plan_succeeded" else "plan_re_evaluation_completed", "Deterministic re-evaluation completed.")
    return(service_result(status = "success", value = saved$value, metadata = list(re_evaluation = reevaluation)))
  }
  step$status <- "succeeded"
  step$completed_at <- storage_now()
  plan <- remediation_plan_update_step(plan, step)
  remediation_plan_save(project, workspace, plan, "plan_step_completed", paste("Completed step:", step$title))
}

remediation_plan_apply_manual_input <- function(project, workspace, plan_id, step_id, values, submission_id = NULL) {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  ids <- vapply(plan$steps, function(step) step$step_id %||% "", character(1))
  idx <- match(step_id, ids)
  if (is.na(idx)) return(service_result(status = "error", errors = "Step not found."))
  step <- plan$steps[[idx]]
  if (!identical(step$step_type, "manual_user_input")) return(service_result(status = "error", errors = "Step is not a manual input checkpoint."))
  errors <- character()
  for (field in step$manual_input_schema %||% list()) {
    value <- values[[field$field_id]]
    if (isTRUE(field$required) && (is.null(value) || !nzchar(as.character(value)))) errors <- c(errors, paste("Required input missing:", field$field_id))
    if ((field$input_type %||% "") == "choice" && length(field$allowed_values %||% character()) && !as.character(value) %in% field$allowed_values) errors <- c(errors, paste("Invalid choice:", field$field_id))
    if ((field$input_type %||% "") == "boolean" && !is.logical(value)) errors <- c(errors, paste("Boolean input required:", field$field_id))
    if ((field$input_type %||% "") == "number" && !is.finite(suppressWarnings(as.numeric(value)))) errors <- c(errors, paste("Numeric input required:", field$field_id))
    if (remediation_plan_contains_unsafe(value)) errors <- c(errors, paste("Unsafe manual input:", field$field_id))
  }
  if (length(errors)) return(service_result(status = "error", errors = errors))
  if (!is.null(step$manual_input_submission_id) && identical(step$manual_input_submission_id, submission_id %||% "")) {
    return(service_result(status = "success", value = plan, messages = "Manual input already applied."))
  }
  step$manual_input_values <- values
  step$manual_input_submission_id <- submission_id %||% paste0("input_", substr(storage_hash_value(list(step_id, values)), 1L, 16L))
  step$status <- "succeeded"
  step$completed_at <- storage_now()
  plan <- remediation_plan_update_step(plan, step)
  transition <- remediation_plan_safe_transition(plan, "running", "Manual input received.")
  if (identical(transition$status, "success")) plan <- transition$value
  saved <- remediation_plan_save(project, workspace, plan, "plan_user_input_received", "Manual input received.")
  saved
}

remediation_plan_pause <- function(project, workspace, plan_id, reason = "manual_pause") {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  transition <- remediation_plan_safe_transition(plan, "paused", reason)
  if (!identical(transition$status, "success")) return(transition)
  remediation_plan_save(project, workspace, transition$value, "plan_paused", reason)
}

remediation_plan_cancel <- function(project, workspace, plan_id, reason = "user_cancelled") {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  transition <- remediation_plan_safe_transition(plan, "cancelled", reason)
  if (!identical(transition$status, "success")) return(transition)
  remediation_plan_save(project, workspace, transition$value, "plan_cancelled", reason)
}

remediation_plan_approve_step <- function(project, workspace, plan_id, step_id = NULL, approval_note = "Step approved by user.") {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  plan <- loaded$value
  ids <- vapply(plan$steps %||% list(), function(step) step$step_id %||% "", character(1))
  statuses <- vapply(plan$steps %||% list(), function(step) step$status %||% "pending", character(1))
  if (is.null(step_id) || !nzchar(step_id)) {
    candidates <- which(statuses == "waiting_approval")
    if (!length(candidates)) return(service_result(status = "error", errors = "No step is waiting for approval."))
    idx <- candidates[[1]]
  } else {
    idx <- match(step_id, ids)
    if (is.na(idx)) return(service_result(status = "error", errors = "Step not found."))
    if (!identical(statuses[[idx]], "waiting_approval")) return(service_result(status = "error", errors = "Step is not waiting for approval."))
  }
  step <- plan$steps[[idx]]
  step$status <- "pending"
  step$approval_note <- approval_note
  step$approved_at <- storage_now()
  step$approval_hash <- storage_hash_value(list(plan_id = plan$plan_id, step_id = step$step_id, approved_at = step$approved_at, note = approval_note))
  plan <- remediation_plan_update_step(plan, step)
  transition <- remediation_plan_safe_transition(plan, "running", approval_note)
  if (identical(transition$status, "success")) plan <- transition$value
  remediation_plan_save(project, workspace, plan, "plan_step_approved", approval_note)
}

remediation_plan_revise <- function(project, workspace, plan_id, reason = "Plan revision requested.") {
  loaded <- remediation_plan_load(project, plan_id)
  if (!identical(loaded$status, "success")) return(loaded)
  old <- loaded$value
  item <- improvement_load_item(project, old$source_item_id)
  if (!identical(item$status, "success")) return(item)
  created <- remediation_plan_create_from_template(project, item$value)
  if (!identical(created$status, "success")) return(created)
  new_plan <- created$value
  new_plan$revision <- as.integer(old$revision %||% 1L) + 1L
  new_plan$parent_plan_id <- old$plan_id
  new_plan$supersedes_plan_id <- old$plan_id
  new_plan$plan_id <- remediation_plan_id(project$project_id, item$value$item_id, new_plan$title, new_plan$revision)
  new_plan$plan_fingerprint <- remediation_plan_fingerprint(new_plan)
  old_transition <- remediation_plan_safe_transition(old, "superseded", reason)
  if (identical(old_transition$status, "success")) remediation_plan_save(project, workspace, old_transition$value, "plan_revised", reason)
  remediation_plan_save(project, workspace, new_plan, "plan_created", reason, source_item = item$value)
}

remediation_plan_recovery_summary <- function(project) {
  loaded <- remediation_plan_load_all(project, include_invalid = TRUE)
  if (!identical(loaded$status, "success")) return(data.table::data.table(recovery_status = "unavailable", plan_count = 0L))
  plans <- loaded$value$plans
  if (!length(plans)) return(data.table::data.table(recovery_status = "none", plan_count = 0L))
  statuses <- vapply(plans, function(plan) plan$status %||% "invalid_plan", character(1))
  recovery <- ifelse(statuses %in% c("paused"), "recoverable_paused",
    ifelse(statuses %in% c("awaiting_step_approval"), "recoverable_waiting_approval",
      ifelse(statuses %in% c("awaiting_user_input"), "recoverable_waiting_input",
        ifelse(statuses %in% c("running", "queued"), "step_execution_uncertain",
          ifelse(statuses %in% remediation_plan_terminal_statuses(), "terminal", "recoverable_paused")))))
  data.table::data.table(recovery_status = recovery, plan_count = 1L)[, .(plan_count = sum(plan_count)), by = recovery_status]
}

remediation_plan_summary <- function(project) {
  loaded <- remediation_plan_load_all(project)
  if (!identical(loaded$status, "success")) return(data.table::data.table(ledger_health = "unavailable", total_plans = 0L, active_plans = 0L, awaiting_input = 0L, awaiting_approval = 0L, failed_plans = 0L))
  table <- remediation_plan_table(loaded$value$plans)
  if (!nrow(table)) return(data.table::data.table(ledger_health = loaded$value$ledger_health, total_plans = 0L, active_plans = 0L, awaiting_input = 0L, awaiting_approval = 0L, failed_plans = 0L))
  data.table::data.table(
    ledger_health = loaded$value$ledger_health,
    total_plans = nrow(table),
    active_plans = sum(!table$status %in% remediation_plan_terminal_statuses()),
    awaiting_input = sum(table$status == "awaiting_user_input"),
    awaiting_approval = sum(table$status %in% c("awaiting_user_review", "awaiting_step_approval")),
    failed_plans = sum(table$status %in% c("failed", "expired"))
  )
}

genai_remediation_plan_context_summary <- function(project, max_plans = 8L) {
  loaded <- remediation_plan_load_all(project)
  if (!identical(loaded$status, "success")) return(service_result(status = "warning", warnings = loaded$errors %||% "Remediation plans unavailable."))
  table <- remediation_plan_table(loaded$value$plans)
  if (!nrow(table)) return(service_result(status = "success", value = list(plans = list(), counts = list()), messages = "No remediation plans registered."))
  active <- table[!status %in% remediation_plan_terminal_statuses()]
  visible <- active[order(updated_at, decreasing = TRUE)][seq_len(min(.N, as.integer(max_plans)))]
  service_result(
    status = "success",
    value = list(
      plans = lapply(seq_len(nrow(visible)), function(i) {
        list(
          plan_id = visible$plan_id[[i]],
          source_item_id = visible$source_item_id[[i]],
          status = visible$status[[i]],
          current_step = visible$current_step_id[[i]],
          next_required_action = visible$next_required_action[[i]],
          completed_steps = visible$completed_steps[[i]],
          total_steps = visible$total_steps[[i]]
        )
      }),
      counts = remediation_plan_summary(project)
    ),
    messages = "Bounded remediation plan summary prepared for GenAI context."
  )
}

ui_remediation_plan_table <- function(table) {
  if (!nrow(table)) return(ui_empty_state("No remediation plans yet.", "Accepted improvement items can produce bounded stepwise remediation plans."))
  table <- table[order(updated_at, decreasing = TRUE)][seq_len(min(.N, 20L))]
  tags$div(
    class = "aq-table-scroll aq-remediation-plan-table",
    tags$table(
      class = "aq-table aq-table-compact",
      tags$thead(tags$tr(tags$th("Plan"), tags$th("Source Item"), tags$th("Status"), tags$th("Risk"), tags$th("Progress"), tags$th("Next"))),
      tags$tbody(lapply(seq_len(nrow(table)), function(i) {
        row <- table[i]
        tags$tr(
          tags$td(tags$strong(row$title[[1]]), tags$div(class = "aq-muted", row$plan_id[[1]])),
          tags$td(row$source_item_id[[1]]),
          tags$td(row$status[[1]]),
          tags$td(row$risk_tier[[1]]),
          tags$td(paste0(row$completed_steps[[1]], "/", row$total_steps[[1]])),
          tags$td(row$next_required_action[[1]])
        )
      }))
    )
  )
}

ui_remediation_plan_detail <- function(plan) {
  if (is.null(plan)) return(ui_empty_state("No remediation plan selected.", "Select a plan to inspect steps, gates, and current required action."))
  steps <- plan$steps %||% list()
  step_rows <- if (length(steps)) {
    data.table::rbindlist(lapply(steps, function(step) {
      data.table::data.table(
        step = step$title %||% step$step_id %||% "",
        type = step$step_type %||% "",
        status = step$status %||% "pending",
        action = step$action_id %||% "",
        risk = step$risk_tier %||% "",
        attempts = step$attempt_count %||% 0L,
        depends_on = paste(step$depends_on %||% character(), collapse = ", ")
      )
    }), fill = TRUE)
  } else {
    data.table::data.table()
  }
  tags$div(
    class = "aq-remediation-plan-detail",
    ui_stat_grid(
      ui_stat_tile("Status", plan$status %||% "unknown", status = if ((plan$status %||% "") %in% c("failed", "expired")) "error" else if ((plan$status %||% "") %in% c("awaiting_user_input", "awaiting_step_approval", "awaiting_user_review")) "warning" else "info", detail = remediation_plan_next_required_action(plan)),
      ui_stat_tile("Risk", plan$risk_tier %||% "unknown", status = if ((plan$risk_tier %||% "") %in% c("high", "critical")) "warning" else "info", detail = plan$approval_policy %||% ""),
      ui_stat_tile("Steps", length(steps), status = "neutral", detail = paste(sum(vapply(steps, function(step) (step$status %||% "") %in% c("succeeded", "completed", "skipped"), logical(1))), "complete"))
    ),
    ui_callout(plan$title %||% "Remediation Plan", plan$objective %||% "No objective recorded.", status = "info"),
    if (nrow(step_rows)) render_table(step_rows, engine = "html", searchable = FALSE, sortable = FALSE) else ui_empty_state("No plan steps.", "This plan has no executable steps."),
    ui_disclosure(
      "Success Criteria / Stop Conditions",
      tagList(
        tags$strong("Success Criteria"),
        tags$ul(lapply(plan$success_criteria %||% character(), tags$li)),
        tags$strong("Stop Conditions"),
        tags$ul(lapply(plan$stop_conditions %||% character(), tags$li))
      ),
      level = "advanced",
      open = FALSE
    )
  )
}

qa_remediation_plans <- function(output_dir = file.path(tempdir(), "remediation_plans_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(check, status, message, file = "R/remediation_plans.R", severity = "error") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, severity = severity, file = file, message = message)
  }
  provider <- storage_provider("remediation_qa_provider", "local_server_directory", "Remediation QA Provider", output_dir, TRUE, TRUE, FALSE, TRUE, list(supports_external_projects = TRUE, can_choose_directory = TRUE))
  workspace <- validate_workspace_root(output_dir, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
  project <- create_project_in_workspace(workspace, "Remediation QA", project_id = "remediation_qa_project")$value
  item_result <- improvement_create_user_item(project, workspace, "Configure dataset profile", "Dataset profile needs to be run.", item_type = "configuration_gap", priority = "high", affected_component = "Analysis", desired_outcome = "preflight passes")
  item <- item_result$value
  accepted <- improvement_item_safe_transition(item, "accepted", "Accepted for remediation.")
  improvement_save_item(project, workspace, accepted$value, event_type = "item_accepted", event_summary = "Accepted.", actor = "user")
  item <- improvement_load_item(project, item$item_id)$value
  plan_result <- remediation_plan_create_from_template(project, item)
  plan <- plan_result$value
  valid_plan <- remediation_plan_validate(plan, project = project, source_item = item)
  add("valid_plan_schema", if (identical(valid_plan$status, "success")) "success" else "error", paste(valid_plan$errors %||% "Valid plan accepted.", collapse = "; "))
  saved <- remediation_plan_save(project, workspace, plan, "plan_created", "QA plan created.", source_item = item)
  add("plan_persisted", if (identical(saved$status, "success") && file.exists(remediation_plan_path(project, plan$plan_id))) "success" else "error", "Plan persists under trusted project governance storage.")
  missing_source <- plan
  missing_source$source_item_id <- "missing_item"
  add("missing_source_item_rejected", if (identical(remediation_plan_validate(missing_source, project = project)$status, "error")) "success" else "error", "Missing source item is rejected.")
  invalid_status <- plan
  invalid_status$status <- "fixing"
  add("invalid_status_rejected", if (identical(remediation_plan_validate(invalid_status, project = project, source_item = item)$status, "error")) "success" else "error", "Invalid plan status is rejected.")
  duplicate_steps <- plan
  duplicate_steps$steps[[2]]$step_id <- duplicate_steps$steps[[1]]$step_id
  add("duplicate_step_ids_rejected", if (identical(remediation_plan_validate(duplicate_steps, project = project, source_item = item)$status, "error")) "success" else "error", "Duplicate step IDs are rejected.")
  cyclic <- plan
  cyclic$steps[[1]]$depends_on <- cyclic$steps[[4]]$step_id
  add("cyclic_dependencies_rejected", if (identical(remediation_plan_validate(cyclic, project = project, source_item = item)$status, "error")) "success" else "error", "Cyclic dependencies are rejected.")
  unknown_action <- plan
  unknown_action$steps[[1]]$action_id <- "not.action"
  add("unknown_action_rejected", if (identical(remediation_plan_validate(unknown_action, project = project, source_item = item)$status, "error")) "success" else "error", "Unknown actions are rejected.")
  invalid_args <- plan
  invalid_args$steps[[1]]$action_arguments <- list(module_id = "dataset_profile", output_path = "C:/tmp/x")
  add("invalid_action_arguments_rejected", if (identical(remediation_plan_validate(invalid_args, project = project, source_item = item)$status, "error")) "success" else "error", "Unsupported action arguments are rejected.")
  bad_manual <- plan
  bad_manual$steps[[2]]$manual_input_schema[[1]]$input_type <- "file_path"
  add("unsupported_manual_input_rejected", if (identical(remediation_plan_validate(bad_manual, project = project, source_item = item)$status, "error")) "success" else "error", "Unsupported manual input types are rejected.")
  no_stop <- plan
  no_stop$stop_conditions <- character()
  add("missing_stop_conditions_rejected", if (identical(remediation_plan_validate(no_stop, project = project, source_item = item)$status, "error")) "success" else "error", "Missing stop conditions are rejected.")
  no_success <- plan
  no_success$success_criteria <- character()
  add("missing_success_criteria_rejected", if (identical(remediation_plan_validate(no_success, project = project, source_item = item)$status, "error")) "success" else "error", "Missing success criteria are rejected.")
  too_many <- plan
  too_many$maximum_steps <- 100L
  add("excessive_steps_rejected", if (identical(remediation_plan_validate(too_many, project = project, source_item = item)$status, "error")) "success" else "error", "Excessive steps are rejected.")
  too_many_retries <- plan
  too_many_retries$steps[[1]]$maximum_attempts <- 99L
  add("excessive_retries_rejected", if (identical(remediation_plan_validate(too_many_retries, project = project, source_item = item)$status, "error")) "success" else "error", "Excessive retries are rejected.")
  too_long <- plan
  too_long$maximum_runtime_seconds <- 9999999L
  add("excessive_runtime_rejected", if (identical(remediation_plan_validate(too_long, project = project, source_item = item)$status, "error")) "success" else "error", "Excessive runtime is rejected.")
  too_persistent <- plan
  too_persistent$maximum_persistent_actions <- 0L
  too_persistent$steps[[1]]$action_id <- "result.persist"
  too_persistent$steps[[1]]$action_arguments <- list(temporary_result_id = "temp_001")
  add("excessive_persistence_rejected", if (identical(remediation_plan_validate(too_persistent, project = project, source_item = item)$status, "error")) "success" else "error", "Excessive persistence count is rejected.")
  code_plan <- plan
  code_plan$objective <- "Run system('bad')"
  add("arbitrary_code_rejected", if (identical(remediation_plan_validate(code_plan, project = project, source_item = item)$status, "error")) "success" else "error", "Executable-looking content is rejected.")
  path_plan <- plan
  path_plan$objective <- "Read C:/Users/Bizon/private.csv"
  add("arbitrary_path_rejected", if (identical(remediation_plan_validate(path_plan, project = project, source_item = item)$status, "error")) "success" else "error", "Absolute paths are rejected.")

  approve <- remediation_plan_approve(project, workspace, plan$plan_id, approval_policy = "plan_and_low_risk_steps")
  add("plan_approval_updates_status", if (identical(approve$status, "success") && identical(approve$value$status, "approved")) "success" else "error", "Plan approval updates plan status.")
  item_after_approve <- improvement_load_item(project, item$item_id)$value
  add("item_status_planned_after_approval", if (identical(item_after_approve$status, "planned")) "success" else "error", "Source item moves to planned after plan approval.")

  ctx <- new.env(parent = emptyenv())
  ctx$selected_module <- NULL
  ctx$select_analysis_module <- function(module_id) { ctx$selected_module <- module_id; TRUE }
  ctx$navigate_to <- function(page) { ctx$page <- page; TRUE }
  ctx$genai_action_proposal_executed <- function(proposal_id) FALSE
  ctx$mark_genai_action_proposal_executed <- function(proposal_id) TRUE
  step1 <- remediation_plan_execute_next_step(project, workspace, plan$plan_id, ctx = ctx)
  add("low_risk_step_executes_one_at_a_time", if (identical(step1$status, "success") && identical(ctx$selected_module, "dataset_profile")) "success" else "error", "Low-risk delegated step executes one at a time.")
  loaded_after_step1 <- remediation_plan_load(project, plan$plan_id)$value
  add("step_result_attached", if (length(loaded_after_step1$steps[[1]]$result_refs) >= 1L) "success" else "error", "Step result reference is attached.")
  step2 <- remediation_plan_execute_next_step(project, workspace, plan$plan_id, ctx = ctx)
  add("manual_input_pauses_plan", if (identical(step2$status, "needs_input") && identical(step2$value$status, "awaiting_user_input")) "success" else "error", "Manual input checkpoint pauses safely.")
  bad_input <- remediation_plan_apply_manual_input(project, workspace, plan$plan_id, loaded_after_step1$steps[[2]]$step_id, list(configuration_confirmed = "C:/tmp/bad"), submission_id = "input_bad")
  add("invalid_manual_input_rejected", if (identical(bad_input$status, "error")) "success" else "error", "Invalid manual input is rejected.")
  input <- remediation_plan_apply_manual_input(project, workspace, plan$plan_id, loaded_after_step1$steps[[2]]$step_id, list(configuration_confirmed = TRUE), submission_id = "input_001")
  input_again <- remediation_plan_apply_manual_input(project, workspace, plan$plan_id, loaded_after_step1$steps[[2]]$step_id, list(configuration_confirmed = TRUE), submission_id = "input_001")
  add("manual_input_applied_once", if (identical(input$status, "success") && identical(input_again$status, "success")) "success" else "error", "Manual input is idempotent.")
  step3 <- remediation_plan_execute_next_step(project, workspace, plan$plan_id, ctx = ctx)
  add("analytical_step_requires_approval", if (identical(step3$status, "needs_input") && identical(step3$value$status, "awaiting_step_approval")) "success" else "error", "Analytical step still requires explicit approval.")
  pause <- remediation_plan_pause(project, workspace, plan$plan_id)
  add("plan_pause_supported", if (identical(pause$status, "success") && identical(pause$value$status, "paused")) "success" else "error", "Plan can pause.")
  cancel <- remediation_plan_cancel(project, workspace, plan$plan_id)
  add("plan_cancel_supported", if (identical(cancel$status, "success") && identical(cancel$value$status, "cancelled")) "success" else "error", "Plan can cancel.")
  terminal_resume <- remediation_plan_execute_next_step(project, workspace, plan$plan_id, ctx = ctx)
  add("terminal_plan_cannot_resume", if (identical(terminal_resume$status, "error")) "success" else "error", "Terminal plan cannot resume.")

  revision_source <- remediation_plan_create_from_template(project, item)
  remediation_plan_save(project, workspace, revision_source$value, "plan_created", "Revision source.", source_item = item)
  revision <- remediation_plan_revise(project, workspace, revision_source$value$plan_id)
  add("plan_revision_created", if (identical(revision$status, "success") && revision$value$revision > revision_source$value$revision) "success" else "error", "Plan revision creates a new plan and retains history.")

  events <- remediation_plan_read_events(project)
  add("plan_events_recorded", if (identical(events$status, "success") && nrow(events$value$events) >= 5L) "success" else "error", "Plan event history is append-only.")
  add("plan_event_hash_chain_healthy", if (events$value$ledger_health %in% c("healthy", "missing")) "success" else "error", paste("Plan ledger health:", events$value$ledger_health))
  recovery <- remediation_plan_recovery_summary(project)
  add("recovery_summary_available", if (nrow(recovery) >= 1L) "success" else "error", "Recovery summary classifies plans.")
  summary <- remediation_plan_summary(project)
  context <- genai_remediation_plan_context_summary(project, max_plans = 2L)
  add("plan_summary_available", if (nrow(summary) == 1L) "success" else "error", "Plan summary is available.")
  add("bounded_genai_plan_context", if (identical(context$status, "success") && length(context$value$plans) <= 2L) "success" else "error", "Bounded GenAI plan context is available.")
  add("improvement_attempt_history_linked", if (length(improvement_load_item(project, item$item_id)$value$attempt_history %||% list()) >= 1L) "success" else "error", "Plan execution links to improvement attempt history.")

  page_text <- if (file.exists("R/page_project.R")) paste(readLines("R/page_project.R", warn = FALSE), collapse = "\n") else ""
  mission_text <- if (file.exists("R/page_mission_control.R")) paste(readLines("R/page_mission_control.R", warn = FALSE), collapse = "\n") else ""
  add("project_ui_surface_present", if (grepl("remediation_plan_browser", page_text, fixed = TRUE)) "success" else "error", "Project page exposes Remediation Plans.", file = "R/page_project.R")
  add("mission_control_plan_integration_present", if (grepl("remediation_plan_summary", mission_text, fixed = TRUE)) "success" else "error", "Mission Control reads remediation plan summary.", file = "R/page_mission_control.R")
  add("schema_inventory_updated", if (file.exists("docs/architecture/schema_version_inventory.md") && grepl("remediation plan schema", paste(readLines("docs/architecture/schema_version_inventory.md", warn = FALSE), collapse = "\n"), fixed = TRUE)) "success" else "error", "Schema inventory includes remediation schemas.", file = "docs/architecture/schema_version_inventory.md")
  add("architecture_doc_present", if (file.exists("docs/architecture/remediation_plans.md")) "success" else "error", "Remediation plan architecture doc exists.", file = "docs/architecture/remediation_plans.md")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

qa_remediation_plan_hardening <- function(output_dir = file.path(tempdir(), "remediation_plan_hardening_qa")) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(check, status, message, file = "R/remediation_plans.R", severity = "error") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, severity = severity, file = file, message = message)
  }
  make_project <- function(name) {
    root <- file.path(output_dir, safe_path_component(name, "project"))
    dir.create(root, recursive = TRUE, showWarnings = FALSE)
    provider <- storage_provider(paste0(name, "_provider"), "local_server_directory", paste(name, "Provider"), root, TRUE, TRUE, FALSE, TRUE, list(supports_external_projects = TRUE, can_choose_directory = TRUE))
    workspace <- validate_workspace_root(root, create = TRUE, provider = provider, repo_root = storage_repo_root())$value
    project <- create_project_in_workspace(workspace, paste(name, "Project"), project_id = safe_path_component(paste0(name, "_project"), "project"))$value
    item <- improvement_create_user_item(project, workspace, paste(name, "item"), "Hardening QA item.", item_type = "configuration_gap", priority = "high", affected_component = "Analysis", desired_outcome = "criteria met")$value
    accepted <- improvement_item_safe_transition(item, "accepted", "Accepted for hardening QA.")
    improvement_save_item(project, workspace, accepted$value, event_type = "item_accepted", event_summary = "Accepted.", actor = "qa")
    list(workspace = workspace, project = project, item = improvement_load_item(project, item$item_id)$value)
  }
  make_plan <- function(fixture, title = "Hardening plan", pass_condition = "always_pass", remaining_gaps = "") {
    steps <- list(
      remediation_plan_step(1, "informational", "Review state", expected_effect = "Record current state.", failure_policy = "continue_with_warning", stop_on_failure = FALSE),
      remediation_plan_step(
        2,
        "deterministic_re_evaluation",
        "Evaluate outcome",
        depends_on = "step_001_Review_state",
        re_evaluation_spec = list(evaluation_id = "eval_outcome", source_item_id = fixture$item$item_id, pass_condition = pass_condition),
        expected_effect = if (nzchar(remaining_gaps)) remaining_gaps else "Resolution criteria met.",
        failure_policy = "stop_plan"
      )
    )
    remediation_plan_new(
      project = fixture$project,
      source_item = fixture$item,
      title = title,
      objective = paste("QA objective:", title),
      steps = steps,
      success_criteria = c("criteria evaluated"),
      stop_conditions = remediation_plan_default_stop_conditions(),
      risk_tier = "low",
      approval_policy = "plan_and_low_risk_steps",
      maximum_steps = 5L,
      maximum_persistent_actions = 0L
    ) |>
      remediation_plan_safe_transition("awaiting_user_review", "Hardening QA plan ready for review.") |>
      (\(x) x$value)()
  }

  diagnostics <- remediation_plan_lifecycle_diagnostics()
  add("lifecycle_has_all_status_keys", if (!length(diagnostics$missing_status_keys)) "success" else "error", paste("Missing lifecycle keys:", paste(diagnostics$missing_status_keys, collapse = ", ")))
  add("lifecycle_references_known_statuses", if (!length(diagnostics$unknown_referenced_statuses)) "success" else "error", paste("Unknown references:", paste(diagnostics$unknown_referenced_statuses, collapse = ", ")))
  add("terminal_states_have_no_outgoing_transitions", if (!length(diagnostics$terminal_with_outgoing_transitions)) "success" else "error", paste("Terminal states with transitions:", paste(diagnostics$terminal_with_outgoing_transitions, collapse = ", ")))
  add("resumable_states_are_not_terminal", if (!length(diagnostics$resumable_terminal_overlap)) "success" else "error", "Resumable states do not overlap terminal states.")
  illegal_count <- 0L
  legal_count <- 0L
  for (from in remediation_plan_statuses()) {
    for (to in remediation_plan_statuses()) {
      allowed <- remediation_plan_transition_allowed(from, to)
      expected <- identical(from, to) || to %in% (remediation_plan_transition_map()[[from]] %||% character())
      if (!identical(allowed, expected)) illegal_count <- illegal_count + 1L
      if (allowed) legal_count <- legal_count + 1L
    }
  }
  add("transition_matrix_matches_single_source", if (illegal_count == 0L && legal_count > 0L) "success" else "error", paste("Transition mismatches:", illegal_count))

  success_fx <- make_project("success")
  success_plan <- make_plan(success_fx, "Successful remediation")
  remediation_plan_save(success_fx$project, success_fx$workspace, success_plan, "plan_created", "Success plan.", source_item = success_fx$item)
  remediation_plan_approve(success_fx$project, success_fx$workspace, success_plan$plan_id, approval_policy = "plan_and_low_risk_steps")
  remediation_plan_execute_next_step(success_fx$project, success_fx$workspace, success_plan$plan_id)
  success_result <- remediation_plan_execute_next_step(success_fx$project, success_fx$workspace, success_plan$plan_id)
  success_loaded <- remediation_plan_load(success_fx$project, success_plan$plan_id)$value
  item_success <- improvement_load_item(success_fx$project, success_fx$item$item_id)$value
  replay_result <- remediation_plan_execute_next_step(success_fx$project, success_fx$workspace, success_plan$plan_id)
  item_after_replay <- improvement_load_item(success_fx$project, success_fx$item$item_id)$value
  add("successful_plan_reaches_terminal_success", if (identical(success_result$status, "success") && identical(success_loaded$status, "succeeded")) "success" else "error", "Successful informational + re-evaluation plan reaches succeeded.")
  add("successful_plan_writes_one_outcome", if (length(item_success$re_evaluation_history %||% list()) == 1L) "success" else "error", "Successful plan writes exactly one re-evaluation outcome.")
  add("terminal_replay_does_not_duplicate_outcome", if (identical(replay_result$status, "error") && length(item_after_replay$re_evaluation_history %||% list()) == 1L) "success" else "error", "Terminal replay cannot duplicate re-evaluation outcomes.")

  partial_fx <- make_project("partial")
  partial_plan <- make_plan(partial_fx, "Partial remediation", pass_condition = "manual_confirmation_required", remaining_gaps = "Manual confirmation still required.")
  remediation_plan_save(partial_fx$project, partial_fx$workspace, partial_plan, "plan_created", "Partial plan.", source_item = partial_fx$item)
  remediation_plan_approve(partial_fx$project, partial_fx$workspace, partial_plan$plan_id, approval_policy = "plan_and_low_risk_steps")
  remediation_plan_execute_next_step(partial_fx$project, partial_fx$workspace, partial_plan$plan_id)
  remediation_plan_execute_next_step(partial_fx$project, partial_fx$workspace, partial_plan$plan_id)
  partial_loaded <- remediation_plan_load(partial_fx$project, partial_plan$plan_id)$value
  item_partial <- improvement_load_item(partial_fx$project, partial_fx$item$item_id)$value
  add("partial_plan_reaches_partial_success", if (identical(partial_loaded$status, "partially_succeeded") && identical(item_partial$status, "partially_resolved")) "success" else "error", "Partial success is represented distinctly.")

  failure_fx <- make_project("failure")
  failure_plan <- make_plan(failure_fx, "Failure remediation")
  failure_plan$steps[[1]]$attempt_count <- 1L
  remediation_plan_save(failure_fx$project, failure_fx$workspace, failure_plan, "plan_created", "Failure plan.", source_item = failure_fx$item)
  remediation_plan_approve(failure_fx$project, failure_fx$workspace, failure_plan$plan_id, approval_policy = "plan_and_low_risk_steps")
  failure_result <- remediation_plan_execute_next_step(failure_fx$project, failure_fx$workspace, failure_plan$plan_id)
  failure_loaded <- remediation_plan_load(failure_fx$project, failure_plan$plan_id)$value
  add("failure_plan_stops_on_exhausted_attempts", if (identical(failure_result$status, "error") && identical(failure_loaded$status, "failed")) "success" else "error", "Exhausted attempts fail the plan without executing later steps.")

  pause_fx <- make_project("pause_resume")
  pause_plan <- make_plan(pause_fx, "Pause resume remediation")
  remediation_plan_save(pause_fx$project, pause_fx$workspace, pause_plan, "plan_created", "Pause plan.", source_item = pause_fx$item)
  remediation_plan_approve(pause_fx$project, pause_fx$workspace, pause_plan$plan_id, approval_policy = "plan_and_low_risk_steps")
  remediation_plan_pause(pause_fx$project, pause_fx$workspace, pause_plan$plan_id)
  resumed <- remediation_plan_execute_next_step(pause_fx$project, pause_fx$workspace, pause_plan$plan_id)
  add("paused_plan_resumes_execution", if (identical(resumed$status, "success")) "success" else "error", "Paused plans resume through the transition map.")

  expire_fx <- make_project("expiration")
  expired_plan <- make_plan(expire_fx, "Expired remediation")
  expired_plan$expires_at <- format(Sys.time() - 60, "%Y-%m-%dT%H:%M:%S%z")
  remediation_plan_save(expire_fx$project, expire_fx$workspace, expired_plan, "plan_created", "Expired plan.", source_item = expire_fx$item)
  remediation_plan_approve(expire_fx$project, expire_fx$workspace, expired_plan$plan_id, approval_policy = "plan_and_low_risk_steps")
  expired <- remediation_plan_execute_next_step(expire_fx$project, expire_fx$workspace, expired_plan$plan_id)
  add("expired_plan_fails_closed", if (identical(expired$status, "error") && identical(remediation_plan_load(expire_fx$project, expired_plan$plan_id)$value$status, "expired")) "success" else "error", "Expired plans fail closed and persist expired state.")

  duplicate_fx <- make_project("duplicate_events")
  event <- remediation_plan_event("plan_created", make_plan(duplicate_fx, "Duplicate event plan"), summary = "duplicate event", idempotency_key = "same_event")
  first_append <- remediation_plan_append_event(duplicate_fx$project, duplicate_fx$workspace, event)
  second_append <- remediation_plan_append_event(duplicate_fx$project, duplicate_fx$workspace, event)
  duplicate_events <- remediation_plan_read_events(duplicate_fx$project)
  add("duplicate_event_idempotency", if (identical(first_append$status, "success") && identical(second_append$status, "success") && nrow(duplicate_events$value$events) == 1L) "success" else "error", "Duplicate plan events are idempotent.")

  corrupt_fx <- make_project("corrupt_storage")
  corrupt_plan <- make_plan(corrupt_fx, "Corrupt plan")
  remediation_plan_save(corrupt_fx$project, corrupt_fx$workspace, corrupt_plan, "plan_created", "Corrupt setup.", source_item = corrupt_fx$item)
  writeLines("{not json", remediation_plan_path(corrupt_fx$project, "broken_plan", create_dir = TRUE), useBytes = TRUE)
  corrupt_load <- remediation_plan_load_all(corrupt_fx$project, include_invalid = TRUE)
  add("corrupted_plan_classified", if (identical(corrupt_load$status, "success") && length(corrupt_load$value$invalid_plans) >= 1L) "success" else "error", "Corrupted persisted plans are classified, not repaired.")
  cat("{bad event}\n", file = remediation_plan_event_log_path(corrupt_fx$project, create_dir = TRUE), append = TRUE)
  corrupt_events <- remediation_plan_read_events(corrupt_fx$project)
  blocked_append <- remediation_plan_append_event(corrupt_fx$project, corrupt_fx$workspace, remediation_plan_event("plan_paused", corrupt_plan, summary = "blocked append", idempotency_key = "blocked_after_corruption"))
  add("corrupted_event_history_detected", if (corrupt_events$value$ledger_health %in% c("partial", "malformed", "event_history_mismatch")) "success" else "error", paste("Ledger health:", corrupt_events$value$ledger_health))
  add("unhealthy_event_history_blocks_append", if (identical(blocked_append$status, "error")) "success" else "error", "Unhealthy plan event ledgers reject further appends.")
  writeLines("{bad checkpoint}", remediation_plan_checkpoint_path(success_fx$project, create_dir = TRUE), useBytes = TRUE)
  checkpoint_tolerated <- remediation_plan_load_all(success_fx$project)
  add("invalid_checkpoint_does_not_block_event_replay", if (identical(checkpoint_tolerated$status, "success") && identical(checkpoint_tolerated$value$ledger_health, "healthy")) "success" else "error", "Event history remains authoritative when checkpoint is invalid.")

  replay_a <- remediation_plan_load_all(success_fx$project)
  replay_b <- remediation_plan_load_all(success_fx$project)
  table_a <- remediation_plan_table(replay_a$value$plans)
  table_b <- remediation_plan_table(replay_b$value$plans)
  replay_cols <- c("plan_id", "status", "completed_steps", "total_steps")
  replay_comparable <- all(replay_cols %in% names(table_a)) && all(replay_cols %in% names(table_b))
  replay_identical <- replay_comparable && identical(as.data.frame(table_a[, ..replay_cols]), as.data.frame(table_b[, ..replay_cols]))
  add("persisted_replay_is_deterministic", if (replay_identical) "success" else "error", "Repeated persisted replay produces stable plan state.")

  performance_start <- Sys.time()
  perf_context <- genai_remediation_plan_context_summary(success_fx$project, max_plans = 5L)
  perf_elapsed <- as.numeric(difftime(Sys.time(), performance_start, units = "secs"))
  add("bounded_context_generation_fast", if (identical(perf_context$status, "success") && is.finite(perf_elapsed) && perf_elapsed < 2) "success" else "error", paste("Context generation elapsed seconds:", round(perf_elapsed, 3)))

  docs <- if (file.exists("docs/architecture/remediation_plans.md")) paste(readLines("docs/architecture/remediation_plans.md", warn = FALSE), collapse = "\n") else ""
  add("architecture_invariants_documented", if (grepl("Boundaries", docs, fixed = TRUE) && grepl("Terminal plans cannot resume", docs, fixed = TRUE)) "success" else "error", "Remediation architecture documents lifecycle boundaries.", file = "docs/architecture/remediation_plans.md")

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
