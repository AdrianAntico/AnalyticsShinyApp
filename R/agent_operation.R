agent_session_version <- "0.1.0"

agent_session_states <- c(
  "created",
  "planning",
  "awaiting_approval",
  "running",
  "paused",
  "completed",
  "failed",
  "cancelled",
  "replaying"
)

agent_terminal_states <- c("completed", "failed", "cancelled")
agent_resumable_states <- c("paused", "awaiting_approval")
agent_approval_required_states <- c("awaiting_approval")

agent_lifecycle_transitions <- function() {
  list(
    created = c("planning", "cancelled", "failed", "replaying"),
    planning = c("awaiting_approval", "running", "paused", "failed", "cancelled"),
    awaiting_approval = c("running", "paused", "failed", "cancelled"),
    running = c("awaiting_approval", "paused", "completed", "failed", "cancelled"),
    paused = c("running", "cancelled", "failed", "replaying"),
    completed = c("replaying"),
    failed = c("replaying"),
    cancelled = c("replaying"),
    replaying = c("completed", "paused", "cancelled", "failed")
  )
}

agent_action_types <- c(
  "inspect_project",
  "inspect_dataset",
  "navigate",
  "configure_service",
  "run_service",
  "review_result",
  "record_observation",
  "record_decision",
  "request_approval",
  "receive_approval",
  "create_artifact",
  "build_report",
  "validate_report",
  "open_report",
  "pause",
  "resume",
  "complete",
  "fail"
)

agent_action_statuses <- c(
  "pending",
  "running",
  "completed",
  "failed",
  "skipped",
  "cancelled",
  "awaiting_approval"
)

agent_inquiry_stages <- c(
  "observation",
  "important_uncertainty",
  "competing_explanations",
  "candidate_investigations",
  "selected_investigation",
  "evidence_collected",
  "belief_update",
  "decision_impact",
  "remaining_uncertainty",
  "stopping_rule"
)

agent_explanation_statuses <- c("proposed", "supported", "weakened", "rejected", "unresolved")
agent_ordinal_confidence <- c("low", "moderate", "high", "unresolved", "not_assessed")
agent_ordinal_value <- c("low", "moderate", "high")
agent_stopping_outcomes <- c("decision_ready", "needs_additional_analysis", "needs_new_data", "needs_human_judgment", "budget_exhausted", "scope_complete")

agent_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3%z")
}

agent_id <- function(prefix) {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sprintf("%04d", sample.int(9999L, 1L)))
}

agent_action_registry <- function() {
  data.table::data.table(
    action_type = agent_action_types,
    label = ui_display_label(agent_action_types),
    execution_class = c(
      "read", "read", "ui", "configuration", "service", "read",
      "record", "record", "governance", "governance", "artifact",
      "report", "validation", "ui", "control", "control", "terminal", "terminal"
    ),
    requires_approval = agent_action_types %in% c("run_service", "create_artifact", "build_report", "open_report"),
    mutates_project = agent_action_types %in% c("create_artifact", "build_report")
  )
}

create_agent_dataset_manifest <- function(
  dataset_id = "funnel_driver_dataset_contract",
  display_name = "Funnel Driver Investigation Dataset",
  required_fields = c("event_date", "channel", "impressions", "clicks", "conversions", "spend"),
  target_candidates = c("conversion_rate", "cvr", "conversions"),
  segment_fields = c("channel", "region", "customer_segment"),
  time_field = "event_date",
  notes = "Contract accepts existing funnel marketing data or a deterministic synthetic dataset supplied later."
) {
  structure(
    list(
      dataset_id = dataset_id,
      display_name = display_name,
      required_fields = as.character(required_fields),
      target_candidates = as.character(target_candidates),
      segment_fields = as.character(segment_fields),
      time_field = time_field,
      notes = notes,
      created_at = agent_now()
    ),
    class = c("agent_dataset_manifest", "list")
  )
}

validate_agent_dataset_contract <- function(data, manifest = create_agent_dataset_manifest()) {
  errors <- character()
  warnings <- character()
  diagnostics <- list()

  if (is.null(data) || !is.data.frame(data)) {
    errors <- c(errors, "Dataset is missing or is not a data frame.")
  } else {
    fields <- names(data)
    missing_required <- setdiff(manifest$required_fields %||% character(), fields)
    if (length(missing_required)) {
      errors <- c(errors, paste("Dataset is missing required fields:", paste(missing_required, collapse = ", ")))
    }
    target_matches <- intersect(manifest$target_candidates %||% character(), fields)
    if (!length(target_matches)) {
      errors <- c(errors, paste("Dataset does not contain a usable target candidate:", paste(manifest$target_candidates, collapse = ", ")))
    }
    missing_segments <- setdiff(manifest$segment_fields %||% character(), fields)
    if (length(missing_segments)) {
      warnings <- c(warnings, paste("Optional segment fields missing:", paste(missing_segments, collapse = ", ")))
    }
    target_field <- if (length(target_matches)) target_matches[[1]] else NA_character_
    diagnostics <- list(
      rows = nrow(data),
      columns = ncol(data),
      fields = fields,
      target_field = target_field,
      segment_fields_available = intersect(manifest$segment_fields %||% character(), fields)
    )
  }

  service_result(
    status = if (length(errors)) "error" else if (length(warnings)) "warning" else "success",
    value = list(valid = !length(errors), manifest = manifest, diagnostics = diagnostics),
    warnings = warnings,
    errors = errors,
    diagnostics = diagnostics
  )
}

agent_operation_setting_schema <- function() {
  list(
    cursor_enabled = "logical",
    cursor_travel_duration = "numeric",
    pause_before_action = "numeric",
    pause_after_action = "numeric",
    minimum_page_dwell = "numeric",
    minimum_result_dwell = "numeric",
    show_navigation = "logical",
    show_observations = "logical",
    show_decisions = "logical",
    show_evidence = "logical",
    show_confidence = "logical",
    show_rejected_alternatives = "logical",
    show_raw_events = "logical",
    auto_scroll = "logical",
    require_approval_at_gates = "logical"
  )
}

agent_operation_presets <- function() {
  list(
    Instant = list(
      cursor_enabled = FALSE,
      cursor_travel_duration = 0,
      pause_before_action = 0,
      pause_after_action = 0,
      minimum_page_dwell = 0,
      minimum_result_dwell = 0,
      show_navigation = TRUE,
      show_observations = TRUE,
      show_decisions = TRUE,
      show_evidence = TRUE,
      show_confidence = TRUE,
      show_rejected_alternatives = FALSE,
      show_raw_events = FALSE,
      auto_scroll = FALSE,
      require_approval_at_gates = FALSE
    ),
    `Follow Along` = list(
      cursor_enabled = TRUE,
      cursor_travel_duration = 450,
      pause_before_action = 250,
      pause_after_action = 450,
      minimum_page_dwell = 800,
      minimum_result_dwell = 1200,
      show_navigation = TRUE,
      show_observations = TRUE,
      show_decisions = TRUE,
      show_evidence = TRUE,
      show_confidence = TRUE,
      show_rejected_alternatives = TRUE,
      show_raw_events = FALSE,
      auto_scroll = TRUE,
      require_approval_at_gates = TRUE
    ),
    Presentation = list(
      cursor_enabled = TRUE,
      cursor_travel_duration = 800,
      pause_before_action = 600,
      pause_after_action = 900,
      minimum_page_dwell = 1400,
      minimum_result_dwell = 2200,
      show_navigation = TRUE,
      show_observations = TRUE,
      show_decisions = TRUE,
      show_evidence = TRUE,
      show_confidence = TRUE,
      show_rejected_alternatives = TRUE,
      show_raw_events = FALSE,
      auto_scroll = TRUE,
      require_approval_at_gates = TRUE
    ),
    `Step-by-step` = list(
      cursor_enabled = TRUE,
      cursor_travel_duration = 600,
      pause_before_action = 0,
      pause_after_action = 0,
      minimum_page_dwell = 0,
      minimum_result_dwell = 0,
      show_navigation = TRUE,
      show_observations = TRUE,
      show_decisions = TRUE,
      show_evidence = TRUE,
      show_confidence = TRUE,
      show_rejected_alternatives = TRUE,
      show_raw_events = TRUE,
      auto_scroll = FALSE,
      require_approval_at_gates = TRUE
    )
  )
}

agent_operation_settings <- function(preset = "Follow Along", overrides = list()) {
  presets <- agent_operation_presets()
  if (!preset %in% names(presets)) {
    preset <- "Follow Along"
  }
  settings <- presets[[preset]]
  if (length(overrides)) {
    for (name in names(overrides)) {
      settings[[name]] <- overrides[[name]]
    }
  }
  settings$preset <- preset
  settings
}

validate_agent_operation_settings <- function(settings) {
  schema <- agent_operation_setting_schema()
  errors <- character()
  missing <- setdiff(names(schema), names(settings %||% list()))
  if (length(missing)) {
    errors <- c(errors, paste("Agent operation settings missing:", paste(missing, collapse = ", ")))
  }
  for (name in intersect(names(schema), names(settings %||% list()))) {
    expected <- schema[[name]]
    value <- settings[[name]]
    ok <- switch(expected,
      logical = is.logical(value) && length(value) == 1L,
      numeric = is.numeric(value) && length(value) == 1L && is.finite(value) && value >= 0,
      TRUE
    )
    if (!isTRUE(ok)) {
      errors <- c(errors, paste("Invalid setting:", name))
    }
  }
  service_result(status = if (length(errors)) "error" else "success", errors = errors, value = settings)
}

create_agent_action <- function(
  action_type,
  target = NULL,
  status = "pending",
  label = NULL,
  rationale = NULL,
  evidence_inputs = character(),
  outputs = list(),
  ui_hints = list(),
  error = NULL,
  action_id = NULL
) {
  if (!action_type %in% agent_action_types) {
    stop("Unsupported agent action type: ", action_type, call. = FALSE)
  }
  if (!status %in% agent_action_statuses) {
    stop("Unsupported agent action status: ", status, call. = FALSE)
  }
  structure(
    list(
      action_id = action_id %||% agent_id("action"),
      action_type = action_type,
      target = target,
      status = status,
      started_at = agent_now(),
      ended_at = if (status %in% c("completed", "failed", "skipped", "cancelled")) agent_now() else NULL,
      label = label %||% ui_display_label(action_type),
      rationale = rationale,
      evidence_inputs = as.character(evidence_inputs %||% character()),
      outputs = outputs,
      ui_hints = ui_hints,
      error = error
    ),
    class = c("agent_action", "list")
  )
}

create_inquiry_timeline_event <- function(stage, title, statement, evidence_ids = character(), metadata = list(), event_id = NULL) {
  if (!stage %in% agent_inquiry_stages) {
    stop("Unsupported inquiry stage: ", stage, call. = FALSE)
  }
  list(
    event_id = event_id %||% agent_id("inquiry_event"),
    stage = stage,
    title = title,
    statement = statement,
    evidence_ids = as.character(evidence_ids %||% character()),
    metadata = metadata %||% list(),
    timestamp = agent_now()
  )
}

create_inquiry_explanation <- function(
  explanation_id,
  description,
  status = "proposed",
  supporting_evidence = character(),
  contradicting_evidence = character(),
  confidence = "not_assessed",
  remaining_uncertainty = NULL
) {
  if (!status %in% agent_explanation_statuses) {
    stop("Unsupported explanation status: ", status, call. = FALSE)
  }
  if (!confidence %in% agent_ordinal_confidence) {
    stop("Unsupported explanation confidence: ", confidence, call. = FALSE)
  }
  list(
    explanation_id = explanation_id,
    description = description,
    status = status,
    supporting_evidence = as.character(supporting_evidence %||% character()),
    contradicting_evidence = as.character(contradicting_evidence %||% character()),
    confidence = confidence,
    remaining_uncertainty = remaining_uncertainty %||% "Evidence is not sufficient to close this explanation."
  )
}

create_candidate_investigation <- function(
  investigation_id,
  investigation,
  question_answered,
  expected_decision_impact = "moderate",
  expected_learning_value = "moderate",
  execution_cost = "moderate",
  interpretation_risk = "moderate",
  approval_requirement = "none",
  selected = FALSE,
  selection_rationale = NULL
) {
  for (value in c(expected_decision_impact, expected_learning_value, execution_cost, interpretation_risk)) {
    if (!value %in% agent_ordinal_value) {
      stop("Unsupported investigation ordinal value: ", value, call. = FALSE)
    }
  }
  list(
    investigation_id = investigation_id,
    investigation = investigation,
    question_answered = question_answered,
    expected_decision_impact = expected_decision_impact,
    expected_learning_value = expected_learning_value,
    execution_cost = execution_cost,
    interpretation_risk = interpretation_risk,
    approval_requirement = approval_requirement,
    selected = isTRUE(selected),
    selection_rationale = selection_rationale
  )
}

create_belief_revision <- function(
  revision_id,
  initial_belief,
  evidence_discovered,
  updated_belief,
  decision_impact,
  confidence = "moderate",
  evidence_ids = character()
) {
  if (!confidence %in% agent_ordinal_confidence) {
    stop("Unsupported belief confidence: ", confidence, call. = FALSE)
  }
  list(
    revision_id = revision_id,
    initial_belief = initial_belief,
    evidence_discovered = evidence_discovered,
    updated_belief = updated_belief,
    decision_impact = decision_impact,
    confidence = confidence,
    evidence_ids = as.character(evidence_ids %||% character()),
    timestamp = agent_now()
  )
}

create_recommendation_revision <- function(
  recommendation_version,
  previous_recommendation,
  current_recommendation,
  reason_changed,
  supporting_evidence_ids = character()
) {
  list(
    recommendation_version = recommendation_version,
    previous_recommendation = previous_recommendation,
    current_recommendation = current_recommendation,
    reason_changed = reason_changed,
    supporting_evidence_ids = as.character(supporting_evidence_ids %||% character()),
    timestamp = agent_now()
  )
}

create_inquiry_state <- function(objective) {
  list(
    objective = objective,
    current_belief = "No evidence has been reviewed yet.",
    important_uncertainty = "Which explanation best accounts for the observed funnel performance?",
    explanations = list(),
    candidate_investigations = list(),
    selected_investigation_id = NULL,
    belief_revisions = list(),
    recommendation_revisions = list(),
    remaining_uncertainty = character(),
    integrity_review = NULL,
    stopping_rule = list(outcome = "scope_complete", rationale = "The bounded campaign scope is complete.", next_action = "Human review should inspect linked evidence."),
    timeline = list()
  )
}

agent_session_add_inquiry_event <- function(session, stage, title, statement, evidence_ids = character(), metadata = list()) {
  session$inquiry$timeline <- c(session$inquiry$timeline %||% list(), list(create_inquiry_timeline_event(stage, title, statement, evidence_ids, metadata)))
  session$timestamps$updated_at <- agent_now()
  session
}

agent_session_set_explanations <- function(session, explanations) {
  session$inquiry$explanations <- explanations %||% list()
  session
}

agent_session_set_candidate_investigations <- function(session, candidates, selected_id = NULL) {
  session$inquiry$candidate_investigations <- candidates %||% list()
  session$inquiry$selected_investigation_id <- selected_id
  session
}

agent_session_add_belief_revision <- function(session, revision) {
  session$inquiry$belief_revisions <- c(session$inquiry$belief_revisions %||% list(), list(revision))
  session$inquiry$current_belief <- revision$updated_belief %||% session$inquiry$current_belief
  session
}

agent_session_add_recommendation_revision <- function(session, revision) {
  session$inquiry$recommendation_revisions <- c(session$inquiry$recommendation_revisions %||% list(), list(revision))
  session
}

agent_session_set_remaining_uncertainty <- function(session, remaining_uncertainty, stopping_rule) {
  session$inquiry$remaining_uncertainty <- as.character(remaining_uncertainty %||% character())
  session$inquiry$stopping_rule <- stopping_rule %||% session$inquiry$stopping_rule
  session
}

agent_session_set_integrity_review <- function(session, integrity_review) {
  session$inquiry$integrity_review <- integrity_review
  session$timestamps$updated_at <- agent_now()
  session
}

validate_inquiry_state <- function(inquiry, require_complete = FALSE) {
  errors <- character()
  if (!is.list(inquiry)) errors <- c(errors, "Inquiry state is missing.")
  stages <- vapply(inquiry$timeline %||% list(), function(event) event$stage %||% "", character(1))
  missing_stages <- setdiff(c("observation", "competing_explanations", "selected_investigation", "belief_update", "decision_impact", "remaining_uncertainty", "stopping_rule"), stages)
  if (isTRUE(require_complete) && length(missing_stages)) {
    errors <- c(errors, paste("Inquiry timeline missing stages:", paste(missing_stages, collapse = ", ")))
  }
  explanation_statuses <- vapply(inquiry$explanations %||% list(), function(item) item$status %||% "", character(1))
  if (length(explanation_statuses) && any(!explanation_statuses %in% agent_explanation_statuses)) {
    errors <- c(errors, "Inquiry contains unsupported explanation status.")
  }
  if (length(inquiry$candidate_investigations %||% list()) && !nzchar(inquiry$selected_investigation_id %||% "")) {
    errors <- c(errors, "Inquiry candidates exist but no selected investigation is recorded.")
  }
  stopping <- inquiry$stopping_rule$outcome %||% ""
  if (nzchar(stopping) && !stopping %in% agent_stopping_outcomes) {
    errors <- c(errors, "Inquiry stopping rule has unsupported outcome.")
  }
  service_result(status = if (length(errors)) "error" else "success", errors = errors, value = inquiry)
}

validate_agent_action <- function(action) {
  errors <- character()
  if (!inherits(action, "agent_action")) errors <- c(errors, "Action is missing agent_action class.")
  if (!action$action_type %in% agent_action_types) errors <- c(errors, "Action has unsupported type.")
  if (!action$status %in% agent_action_statuses) errors <- c(errors, "Action has unsupported status.")
  if (is.null(action$action_id) || !nzchar(action$action_id)) errors <- c(errors, "Action is missing action_id.")
  service_result(status = if (length(errors)) "error" else "success", errors = errors, value = action)
}

create_decision_trace <- function(
  goal,
  observation,
  decision,
  basis,
  evidence_ids = character(),
  confidence = "not_assessed",
  alternatives_considered = character(),
  next_action = NULL,
  trace_id = NULL
) {
  structure(
    list(
      trace_id = trace_id %||% agent_id("decision"),
      goal = goal,
      observation = observation,
      decision = decision,
      basis = basis,
      evidence_ids = as.character(evidence_ids %||% character()),
      confidence = confidence,
      alternatives_considered = as.character(alternatives_considered %||% character()),
      next_action = next_action,
      created_at = agent_now()
    ),
    class = c("decision_trace", "list")
  )
}

validate_decision_trace <- function(trace) {
  errors <- character()
  required <- c("trace_id", "goal", "observation", "decision", "basis")
  for (field in required) {
    if (is.null(trace[[field]]) || !nzchar(as.character(trace[[field]]))) {
      errors <- c(errors, paste("DecisionTrace missing:", field))
    }
  }
  service_result(status = if (length(errors)) "error" else "success", errors = errors, value = trace)
}

create_agent_session <- function(
  objective,
  dataset_manifest = create_agent_dataset_manifest(),
  campaign_type = "funnel_driver_investigation",
  presentation_settings = agent_operation_settings("Follow Along"),
  session_id = NULL,
  provider_config = NULL
) {
  structure(
    list(
      session_version = agent_session_version,
      session_id = session_id %||% agent_id("agent_session"),
      objective = objective,
      dataset_manifest = dataset_manifest,
      campaign_type = campaign_type,
      status = "created",
      plan = list(),
      actions = list(),
      observations = list(),
      decision_traces = list(),
      evidence_references = list(),
      approvals = list(),
      service_runs = list(),
      inquiry = create_inquiry_state(objective),
      warnings = character(),
      errors = character(),
      report_id = NULL,
      report_contract = NULL,
      timestamps = list(created_at = agent_now(), updated_at = agent_now(), completed_at = NULL),
      presentation_settings = presentation_settings,
      presentation_state = list(step_index = 0L, current_target = NULL, replay = FALSE),
      provenance = list(
        created_by = "Analytics Workstation",
        deterministic = TRUE,
        replay_of = NULL,
        provider = provider_config$provider %||% NA_character_,
        model = provider_config$model %||% NA_character_
      )
    ),
    class = c("agent_session", "list")
  )
}

validate_agent_session <- function(session) {
  errors <- character()
  warnings <- character()
  if (!inherits(session, "agent_session")) errors <- c(errors, "Session is missing agent_session class.")
  if (!identical(session$session_version %||% "", agent_session_version)) warnings <- c(warnings, "AgentSession version differs from runtime.")
  if (!session$status %in% agent_session_states) errors <- c(errors, "Session has invalid status.")
  settings_validation <- validate_agent_operation_settings(session$presentation_settings %||% list())
  errors <- c(errors, settings_validation$errors)
  action_errors <- unlist(lapply(session$actions %||% list(), function(action) validate_agent_action(action)$errors), use.names = FALSE)
  errors <- c(errors, action_errors)
  trace_errors <- unlist(lapply(session$decision_traces %||% list(), function(trace) validate_decision_trace(trace)$errors), use.names = FALSE)
  errors <- c(errors, trace_errors)
  inquiry_validation <- validate_inquiry_state(session$inquiry %||% create_inquiry_state(session$objective %||% "Untitled inquiry"), require_complete = session$status %in% c("completed", "replaying"))
  errors <- c(errors, inquiry_validation$errors)
  service_result(
    status = if (length(errors)) "error" else if (length(warnings)) "warning" else "success",
    errors = errors,
    warnings = warnings,
    value = session,
    diagnostics = list(actions = length(session$actions %||% list()), decisions = length(session$decision_traces %||% list()), inquiry_events = length(session$inquiry$timeline %||% list()))
  )
}

agent_session_transition <- function(session, to_state, reason = NULL) {
  if (!to_state %in% agent_session_states) {
    stop("Unsupported AgentSession state: ", to_state, call. = FALSE)
  }
  from_state <- session$status %||% "created"
  allowed <- agent_lifecycle_transitions()[[from_state]] %||% character()
  if (!to_state %in% allowed && !identical(from_state, to_state)) {
    stop("Illegal AgentSession transition: ", from_state, " -> ", to_state, call. = FALSE)
  }
  session$status <- to_state
  session$timestamps$updated_at <- agent_now()
  if (to_state %in% agent_terminal_states) {
    session$timestamps$completed_at <- session$timestamps$completed_at %||% agent_now()
  }
  if (!is.null(reason)) {
    session$observations <- c(session$observations %||% list(), list(list(timestamp = agent_now(), message = reason, state = to_state)))
  }
  session
}

agent_session_add_action <- function(session, action) {
  session$actions <- c(session$actions %||% list(), list(action))
  session$presentation_state$current_target <- action$target
  session$timestamps$updated_at <- agent_now()
  session
}

agent_session_record_action <- function(session, action_type, target = NULL, label = NULL, rationale = NULL, evidence_inputs = character(), outputs = list(), ui_hints = list(), status = "completed", error = NULL) {
  action <- create_agent_action(action_type, target = target, status = status, label = label, rationale = rationale, evidence_inputs = evidence_inputs, outputs = outputs, ui_hints = ui_hints, error = error)
  agent_session_add_action(session, action)
}

agent_session_add_decision <- function(session, trace) {
  session$decision_traces <- c(session$decision_traces %||% list(), list(trace))
  session$timestamps$updated_at <- agent_now()
  session
}

agent_session_add_evidence <- function(session, evidence_id, title, evidence_type, source = NULL, metadata = list()) {
  session$evidence_references <- c(session$evidence_references %||% list(), list(list(
    evidence_id = evidence_id,
    title = title,
    evidence_type = evidence_type,
    source = source,
    metadata = metadata,
    recorded_at = agent_now()
  )))
  session
}

agent_session_add_service_run <- function(session, service_id, status, report = NULL, diagnostics = list()) {
  run <- list(
    service_run_id = agent_id("service_run"),
    service_id = service_id,
    status = status,
    report_id = report$report_id %||% NULL,
    component_count = length(report$components %||% list()),
    finding_count = length(report$findings %||% list()),
    evidence_count = length(report$evidence_links %||% list()),
    diagnostics = diagnostics,
    timestamp = agent_now()
  )
  session$service_runs <- c(session$service_runs %||% list(), list(run))
  session
}

agent_session_pause <- function(session) {
  agent_session_transition(agent_session_record_action(session, "pause", target = "control_bar", label = "Pause campaign"), "paused", "Campaign paused by operator.")
}

agent_session_resume <- function(session) {
  agent_session_transition(agent_session_record_action(session, "resume", target = "control_bar", label = "Resume campaign"), "running", "Campaign resumed by operator.")
}

agent_session_cancel <- function(session) {
  agent_session_transition(agent_session_record_action(session, "pause", target = "control_bar", label = "Stop campaign", status = "cancelled"), "cancelled", "Campaign cancelled by operator.")
}

agent_session_step <- function(session) {
  session$presentation_state$step_index <- as.integer(session$presentation_state$step_index %||% 0L) + 1L
  session$timestamps$updated_at <- agent_now()
  session
}

agent_session_to_list <- function(session) {
  unclass(session)
}

restore_agent_session_classes <- function(value) {
  if (is.list(value)) {
    if (!is.null(value$actions)) {
      value$actions <- lapply(value$actions, function(action) structure(action, class = c("agent_action", "list")))
    }
    if (!is.null(value$decision_traces)) {
      value$decision_traces <- lapply(value$decision_traces, function(trace) structure(trace, class = c("decision_trace", "list")))
    }
    if (!is.null(value$dataset_manifest)) {
      value$dataset_manifest <- structure(value$dataset_manifest, class = c("agent_dataset_manifest", "list"))
    }
    if (!is.null(value$report_contract)) {
      value$report_contract <- restore_report_classes(value$report_contract)
    }
    structure(value, class = c("agent_session", "list"))
  } else {
    value
  }
}

serialize_agent_session <- function(session, pretty = TRUE) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for AgentSession serialization.", call. = FALSE)
  }
  jsonlite::toJSON(agent_session_to_list(session), auto_unbox = TRUE, null = "null", pretty = pretty, digits = NA)
}

deserialize_agent_session <- function(json) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for AgentSession deserialization.", call. = FALSE)
  }
  restore_agent_session_classes(jsonlite::fromJSON(json, simplifyVector = FALSE))
}

agent_session_replay <- function(session, presentation_settings = NULL) {
  replay <- session
  replay$status <- "replaying"
  replay$presentation_settings <- presentation_settings %||% session$presentation_settings
  replay$presentation_state$replay <- TRUE
  replay$presentation_state$step_index <- 1L
  replay$provenance$replay_of <- session$session_id
  replay$timestamps$updated_at <- agent_now()
  replay
}

build_investigation_integrity_review <- function(session) {
  inquiry <- session$inquiry %||% create_inquiry_state(session$objective %||% "Campaign inquiry")
  explanations <- inquiry$explanations %||% list()
  evidence_ids <- vapply(session$evidence_references %||% list(), function(item) item$evidence_id %||% "", character(1))
  belief_revisions <- inquiry$belief_revisions %||% list()
  recommendation_revisions <- inquiry$recommendation_revisions %||% list()
  latest_recommendation <- if (length(recommendation_revisions)) {
    tail(recommendation_revisions, 1L)[[1L]]$current_recommendation
  } else {
    "Review linked evidence before decision use."
  }
  confidence_values <- vapply(explanations, function(item) item$confidence %||% "not_assessed", character(1))
  high_count <- sum(confidence_values == "high")
  supported_count <- sum(vapply(explanations, function(item) (item$status %||% "") %in% "supported", logical(1)))
  has_shap <- any(grepl("shap", evidence_ids, ignore.case = TRUE))
  evidence_strength <- if (has_shap && high_count >= 2L && length(belief_revisions) >= 2L) {
    "Strong directional evidence"
  } else if (length(evidence_ids) >= 2L && supported_count >= 2L) {
    "Moderate directional evidence"
  } else {
    "Preliminary evidence"
  }
  alternative_review <- lapply(explanations, function(item) {
    status <- item$status %||% "not_assessed"
    list(
      explanation = item$description %||% item$explanation_id %||% "Unnamed explanation",
      supporting_evidence = item$supporting_evidence %||% character(),
      weakening_evidence = item$contradicting_evidence %||% character(),
      status = status,
      reason = switch(
        status,
        supported = paste("Supported by", length(item$supporting_evidence %||% character()), "evidence reference(s), with remaining uncertainty:", item$remaining_uncertainty %||% "none recorded"),
        weakened = paste("Weakened by contradictory evidence; remaining uncertainty:", item$remaining_uncertainty %||% "none recorded"),
        rejected = paste("Rejected because supporting evidence did not survive review; remaining uncertainty:", item$remaining_uncertainty %||% "none recorded"),
        unresolved = paste("Still unresolved:", item$remaining_uncertainty %||% "additional evidence required"),
        paste("Not fully assessed:", item$remaining_uncertainty %||% "additional evidence required")
      )
    )
  })
  coverage <- list(
    list(question = "Is the dataset suitable for investigation?", status = "well_investigated", evidence = "EDA and schema checks are available."),
    list(question = "Which baseline drivers are directionally important?", status = if (length(evidence_ids) >= 2L) "well_investigated" else "partially_investigated", evidence = "Baseline report evidence is available."),
    list(question = "Do nonlinear explanations support the recommendation?", status = if (has_shap) "well_investigated" else "partially_investigated", evidence = if (has_shap) "Governed SHAP evidence was collected." else "SHAP evidence was not approved or not available."),
    list(question = "Are findings stable across regions and audiences?", status = "partially_investigated", evidence = "Segment signals are visible, but follow-up stability review remains prudent."),
    list(question = "Is the recommendation causally identified?", status = "not_investigated", evidence = "The demo is observational and does not claim randomized causal proof."),
    list(question = "Will the intervention work after implementation?", status = "not_investigated", evidence = "Post-implementation monitoring has not occurred yet.")
  )
  contradictory <- c(
    "Regional and audience exceptions may complicate broad rollout.",
    "Competitor promotion pressure explains some context but does not directly prescribe a marketing action.",
    "Search saturation evidence argues for marginal tuning, not a blanket Search cut.",
    "Social response appears audience-dependent rather than universally strong."
  )
  assumptions <- c(
    "Operational delays are measured accurately enough to support a throughput recommendation.",
    "Competitor promotion indicators are representative of meaningful market pressure.",
    "Creative age reflects true refresh timing rather than a logging artifact.",
    "Enrollment reporting is complete enough for directional comparison.",
    "The synthetic mystery dataset is suitable for demonstrating the governed investigation path."
  )
  sensitivity_level <- if (has_shap) "Moderately sensitive" else "Highly sensitive"
  additional_analysis_change <- if (has_shap) "Possible" else "Likely"
  decision_readiness <- if (has_shap) "Requires human judgment" else "Needs additional evidence"
  list(
    generated_at = agent_now(),
    executive_summary = paste(
      "The recommendation is credible as directional guidance because multiple evidence sources shifted the investigation away from a broad channel cut and toward operational throughput, creative refresh, and targeted allocation.",
      "It is not causal proof, and it should be used with human judgment plus monitoring."
    ),
    strength_of_evidence = list(
      rating = evidence_strength,
      rationale = paste("The campaign linked", length(evidence_ids), "evidence reference(s), recorded", length(belief_revisions), "belief revision(s), and preserved", length(explanations), "competing explanation(s).")
    ),
    alternative_explanations = alternative_review,
    contradictory_evidence = contradictory,
    evidence_coverage = coverage,
    assumptions = assumptions,
    sensitivity = list(
      rating = sensitivity_level,
      rationale = if (has_shap) {
        "The recommendation survived baseline and explanation evidence, but rollout details remain sensitive to segment and regional context."
      } else {
        "The recommendation remains sensitive because the explanation step was not approved."
      }
    ),
    recommendation_robustness = list(
      current_recommendation = latest_recommendation,
      supporting_evidence = evidence_ids,
      remaining_uncertainty = inquiry$remaining_uncertainty %||% character(),
      confidence = if (has_shap) "High directional confidence" else "Moderate preliminary confidence",
      would_additional_analysis_change_recommendation = additional_analysis_change
    ),
    decision_readiness = list(
      status = decision_readiness,
      rationale = if (has_shap) {
        "The evidence is sufficient for an informed human decision, but not for automatic implementation."
      } else {
        "The strongest explanation step was not completed, so the investigation should not drive action without additional evidence."
      }
    )
  )
}

agent_registered_ui_targets <- function() {
  data.table::data.table(
    target = c("project", "data", "analysis_modules", "artifact_studio", "report_browser", "approval_gate", "control_bar"),
    selector = c(".aq-page-project", ".aq-page-data", ".aq-page-analysis-modules", ".aq-page-artifact-studio", ".aq-page-report-browser", ".aq-agent-approval-gate", ".aq-agent-control-bar"),
    label = c("Project", "Data Workspace", "Analysis Modules", "Artifact Studio", "Report Browser", "Approval Gate", "Control Bar")
  )
}

resolve_agent_cursor_target <- function(target, registered_targets = agent_registered_ui_targets()) {
  if (is.null(target) || !nzchar(as.character(target))) {
    return(service_result(status = "warning", warnings = "No cursor target supplied.", value = list(target = NULL, selector = NULL, fallback = TRUE)))
  }
  index <- match(target, registered_targets$target)
  if (is.na(index)) {
    return(service_result(status = "warning", warnings = paste("Cursor target not registered:", target), value = list(target = target, selector = ".aq-page", fallback = TRUE)))
  }
  service_result(status = "success", value = as.list(registered_targets[index]))
}

agent_funnel_contract_fixture <- function(n = 80L) {
  set.seed(42)
  data.frame(
    event_date = seq.Date(Sys.Date() - n + 1L, Sys.Date(), by = "day"),
    channel = sample(c("Search", "Social", "Email", "Direct"), n, replace = TRUE),
    region = sample(c("West", "Midwest", "South", "Northeast"), n, replace = TRUE),
    customer_segment = sample(c("Budget", "Standard", "Premium", "Enterprise"), n, replace = TRUE),
    impressions = sample(2500:20000, n, replace = TRUE),
    clicks = sample(50:900, n, replace = TRUE),
    spend = round(runif(n, 40, 900), 2),
    conversions = sample(1:140, n, replace = TRUE),
    revenue = round(runif(n, 200, 45000), 2)
  )
}

agent_count_report <- function(report, service_id) {
  validation <- validate_report(report)
  list(
    service_id = service_id,
    report_id = report$report_id,
    title = report$title,
    validation_status = validation$status,
    components = length(report$components %||% list()),
    findings = length(report$findings %||% list()),
    evidence_links = length(report$evidence_links %||% list())
  )
}

agent_inquiry_timeline_table <- function(inquiry) {
  events <- inquiry$timeline %||% list()
  if (!length(events)) return(data.frame(stage = character(), event = character(), statement = character(), evidence = character()))
  data.frame(
    stage = vapply(events, function(x) ui_display_label(x$stage %||% ""), character(1)),
    event = vapply(events, function(x) x$title %||% "", character(1)),
    statement = vapply(events, function(x) x$statement %||% "", character(1)),
    evidence = vapply(events, function(x) paste(x$evidence_ids %||% character(), collapse = ", "), character(1)),
    stringsAsFactors = FALSE
  )
}

agent_inquiry_explanation_table <- function(inquiry) {
  explanations <- inquiry$explanations %||% list()
  if (!length(explanations)) return(data.frame(explanation = character(), status = character(), confidence = character(), evidence = character()))
  data.frame(
    explanation = vapply(explanations, function(x) x$description %||% x$explanation_id %||% "", character(1)),
    status = vapply(explanations, function(x) ui_display_label(x$status %||% ""), character(1)),
    confidence = vapply(explanations, function(x) ui_display_label(x$confidence %||% ""), character(1)),
    evidence = vapply(explanations, function(x) paste(x$supporting_evidence %||% character(), collapse = ", "), character(1)),
    stringsAsFactors = FALSE
  )
}

agent_inquiry_candidate_table <- function(inquiry) {
  candidates <- inquiry$candidate_investigations %||% list()
  if (!length(candidates)) return(data.frame(investigation = character(), selected = character(), decision_impact = character(), learning_value = character(), cost = character()))
  data.frame(
    investigation = vapply(candidates, function(x) x$investigation %||% x$investigation_id %||% "", character(1)),
    selected = vapply(candidates, function(x) if (isTRUE(x$selected)) "selected" else "not selected", character(1)),
    decision_impact = vapply(candidates, function(x) ui_display_label(x$expected_decision_impact %||% ""), character(1)),
    learning_value = vapply(candidates, function(x) ui_display_label(x$expected_learning_value %||% ""), character(1)),
    cost = vapply(candidates, function(x) ui_display_label(x$execution_cost %||% ""), character(1)),
    stringsAsFactors = FALSE
  )
}

agent_inquiry_belief_table <- function(inquiry) {
  revisions <- inquiry$belief_revisions %||% list()
  if (!length(revisions)) return(data.frame(revision = character(), initial_belief = character(), evidence = character(), updated_belief = character(), decision_impact = character()))
  data.frame(
    revision = vapply(revisions, function(x) x$revision_id %||% "", character(1)),
    initial_belief = vapply(revisions, function(x) x$initial_belief %||% "", character(1)),
    evidence = vapply(revisions, function(x) x$evidence_discovered %||% "", character(1)),
    updated_belief = vapply(revisions, function(x) x$updated_belief %||% "", character(1)),
    decision_impact = vapply(revisions, function(x) x$decision_impact %||% "", character(1)),
    stringsAsFactors = FALSE
  )
}

build_agent_campaign_report <- function(session, service_summaries = list(), shap_status = "not_requested") {
  report <- create_report_contract(
    report_id = paste0("agent_campaign_report_", session$session_id),
    title = "Funnel Driver Investigation Campaign",
    report_type = "agent_campaign_report",
    purpose = "evidence_review",
    capabilities = c("interactive", "evidence_trace", "ai_summary"),
    presentation_profile = create_presentation_profile(profile_id = "campaign_review", density = "balanced"),
    sections = list(
      create_report_section("orientation", "Orientation", priority = "critical"),
      create_report_section("executive_summary", "Executive Summary", priority = "critical"),
      create_report_section("data_readiness", "Data Readiness"),
      create_report_section("inquiry_timeline", "Inquiry Timeline", priority = "critical"),
      create_report_section("key_findings", "Key Findings", priority = "critical"),
      create_report_section("belief_revision", "Belief Revision", priority = "critical"),
      create_report_section("baseline_model", "Baseline Model"),
      create_report_section("driver_analysis", "Driver Analysis"),
      create_report_section("shap_analysis", "SHAP Analysis"),
      create_report_section("stability_segment_review", "Stability / Segment Review"),
      create_report_section("limitations", "Limitations"),
      create_report_section("recommendations", "Recommendations"),
      create_report_section("methodology", "Methodology"),
      create_report_section("evidence_links", "Evidence Links"),
      create_report_section("technical_appendix", "Technical Appendix")
    ),
    provenance = list(agent_session_id = session$session_id, generated_at = agent_now(), deterministic = TRUE)
  )

  report <- add_component(report, report_component_title("Funnel Driver Investigation Campaign", "A governed agent session assembled this semantic report from deterministic service outputs."), "orientation")
  report <- add_component(report, report_component_orientation(session$objective, scope = "Funnel driver investigation", audience = "analyst"), "orientation")
  report <- add_component(report, report_component_executive_summary(
    summary = paste0("The campaign validated the dataset contract, ran ", length(service_summaries), " deterministic service report step(s), and assembled evidence references without fabricating business conclusions."),
    confidence = "process_confidence_only",
    next_action = "Open linked evidence and verify each analytical claim before decision use."
  ), "executive_summary")
  report <- add_component(report, report_component_metric_summary(
    list(
      service_reports = length(service_summaries),
      actions_recorded = length(session$actions %||% list()),
      decision_traces = length(session$decision_traces %||% list()),
      evidence_references = length(session$evidence_references %||% list())
    ),
    component_id = "campaign_summary_metrics",
    title = "Campaign Summary"
  ), "executive_summary")

  data_validation <- session$observations$dataset_validation %||% NULL
  report <- add_component(report, report_component_diagnostic(
    status = data_validation$status %||% "not_recorded",
    messages = c(data_validation$message %||% "Dataset readiness was recorded by the AgentSession."),
    title = "Dataset Readiness"
  ), "data_readiness")

  report <- add_component(report, report_component_table(
    data = agent_inquiry_timeline_table(session$inquiry %||% create_inquiry_state(session$objective)),
    title = "Inquiry Timeline",
    component_id = "campaign_inquiry_timeline"
  ), "inquiry_timeline")
  report <- add_component(report, report_component_table(
    data = agent_inquiry_explanation_table(session$inquiry %||% create_inquiry_state(session$objective)),
    title = "Competing Explanations",
    component_id = "campaign_competing_explanations"
  ), "inquiry_timeline")
  report <- add_component(report, report_component_table(
    data = agent_inquiry_candidate_table(session$inquiry %||% create_inquiry_state(session$objective)),
    title = "Candidate Investigations",
    component_id = "campaign_candidate_investigations"
  ), "inquiry_timeline")

  report <- add_component(report, report_component_finding(
    statement = "The campaign has produced traceable process evidence, not a final business recommendation.",
    support = "Service runs, approval events, report validation, and evidence references are recorded in the AgentSession.",
    caveat = "Substantive driver conclusions must be read from the linked analytical artifacts and reviewed by a human.",
    confidence = "high_process_confidence",
    component_id = "finding_traceable_process_evidence",
    metadata = list(evidence_ids = vapply(session$evidence_references %||% list(), function(x) x$evidence_id %||% "", character(1)))
  ), "key_findings")
  report <- add_finding(
    report,
    "The campaign produced a validated evidence trail rather than an ungrounded answer.",
    support = "All service runs and report sections are represented as deterministic AgentSession state.",
    caveat = "Analytical truth depends on the underlying service outputs and dataset quality.",
    confidence = "high_process_confidence",
    finding_id = "finding_traceable_process_evidence",
    metadata = list(
      title = "Traceable process evidence",
      evidence_ids = vapply(session$evidence_references %||% list(), function(x) x$evidence_id %||% "", character(1)),
      quality_status = "validated_process"
    )
  )

  if (length(session$inquiry$belief_revisions %||% list())) {
    latest_belief <- tail(session$inquiry$belief_revisions, 1L)[[1]]
    report <- add_finding(
      report,
      "The campaign revised its recommendation as evidence accumulated.",
      support = latest_belief$evidence_discovered %||% "Belief revisions are recorded in the AgentSession.",
      caveat = paste(session$inquiry$remaining_uncertainty %||% "Remaining uncertainty requires human review.", collapse = " "),
      confidence = latest_belief$confidence %||% "moderate",
      finding_id = "finding_inquiry_belief_revision",
      metadata = list(
        title = "Belief revision",
        evidence_ids = latest_belief$evidence_ids %||% character(),
        quality_status = "traceable_belief_update"
      )
    )
  }

  report <- add_component(report, report_component_table(
    data = agent_inquiry_belief_table(session$inquiry %||% create_inquiry_state(session$objective)),
    title = "Belief Revisions",
    component_id = "campaign_belief_revisions"
  ), "belief_revision")
  if (length(session$inquiry$recommendation_revisions %||% list())) {
    recommendation_table <- data.frame(
      version = vapply(session$inquiry$recommendation_revisions, function(x) as.character(x$recommendation_version %||% ""), character(1)),
      previous = vapply(session$inquiry$recommendation_revisions, function(x) x$previous_recommendation %||% "", character(1)),
      current = vapply(session$inquiry$recommendation_revisions, function(x) x$current_recommendation %||% "", character(1)),
      reason = vapply(session$inquiry$recommendation_revisions, function(x) x$reason_changed %||% "", character(1)),
      stringsAsFactors = FALSE
    )
    report <- add_component(report, report_component_table(data = recommendation_table, title = "Recommendation Evolution", component_id = "campaign_recommendation_evolution"), "belief_revision")
  }

  if (length(service_summaries)) {
    service_table <- data.frame(
      service = vapply(service_summaries, function(x) x$service_id %||% "", character(1)),
      report_id = vapply(service_summaries, function(x) x$report_id %||% "", character(1)),
      validation_status = vapply(service_summaries, function(x) x$validation_status %||% "", character(1)),
      components = vapply(service_summaries, function(x) x$components %||% 0L, integer(1)),
      findings = vapply(service_summaries, function(x) x$findings %||% 0L, integer(1)),
      evidence_links = vapply(service_summaries, function(x) x$evidence_links %||% 0L, integer(1))
    )
    report <- add_component(report, report_component_table(data = service_table, title = "Service Report Inventory", component_id = "service_report_inventory"), "driver_analysis")
  }

  report <- add_component(report, report_component_narrative(
    paste("SHAP gate status:", ui_display_label(shap_status), "The campaign records approval or rejection before SHAP is included."),
    component_id = "shap_gate_status",
    title = "SHAP Gate"
  ), "shap_analysis")
  report <- add_component(report, report_component_narrative(
    "Segment and stability review is represented as a campaign section so later service outputs can be linked without changing the report model.",
    component_id = "segment_review_placeholder",
    title = "Segment Review"
  ), "stability_segment_review")
  report <- add_component(report, report_component_diagnostic(
    status = "requires_human_review",
    messages = c("Campaign observations are bounded to deterministic service outputs.", "No business conclusion is fabricated when source analyses are unavailable."),
    title = "Limitations"
  ), "limitations")
  report <- add_component(report, report_component_recommendation(
    action = "Review the campaign evidence trail and linked analytical artifacts before using findings in a decision.",
    rationale = "The agent can assemble, route, and explain evidence, but human review remains required for business adoption.",
    risk = "Skipping evidence review may convert process confidence into unsupported business confidence.",
    component_id = "recommend_review_evidence"
  ), "recommendations")
  report$recommendations <- list(list(
    recommendation_id = "recommend_review_evidence",
    action = "Review linked evidence before decision use.",
    rationale = "Process traceability is not the same as substantive truth."
  ))
  report <- add_component(report, report_component_methodology(
    method = "Governed agent operation using deterministic service execution, AgentSession event recording, approval gates, and semantic ReportContract assembly.",
    assumptions = c("Underlying service outputs remain authoritative.", "Replay does not rerun analysis."),
    limitations = c("This campaign is bounded and does not execute autonomous free-form actions.")
  ), "methodology")

  for (evidence in session$evidence_references %||% list()) {
    report <- add_component(report, report_component_evidence_link(
      artifact_id = evidence$evidence_id,
      role = evidence$evidence_type %||% "evidence",
      component_id = paste0("evidence_", report_safe_id("id", evidence$evidence_id)),
      metadata = list(title = evidence$title %||% evidence$evidence_id, source = evidence$source %||% NA_character_)
    ), "evidence_links")
  }
  report <- add_component(report, report_component_technical_appendix(
    content = paste("AgentSession:", session$session_id, "Actions:", length(session$actions %||% list()), "Replayable:", TRUE),
    component_id = "campaign_technical_appendix"
  ), "technical_appendix")
  validation <- validate_report(report)
  report$validation <- list(status = validation$status, errors = validation$errors, warnings = validation$warnings)
  report
}

run_funnel_driver_investigation <- function(
  data = NULL,
  dataset_manifest = build_week_demo_dataset_manifest(),
  approve_shap = TRUE,
  presentation_settings = agent_operation_settings("Presentation"),
  objective = NULL,
  provider_config = NULL
) {
  session <- create_agent_session(
    objective = objective %||% "Identify the strongest drivers of funnel conversion, test stability across segments, investigate nonlinearities or anomalies, and assemble an analyst-ready report.",
    dataset_manifest = dataset_manifest,
    presentation_settings = presentation_settings,
    provider_config = provider_config
  )
  service_summaries <- list()
  session <- agent_session_transition(session, "planning", "Campaign plan created.")
  session$plan <- list(
    steps = c("Validate dataset contract", "Run EDA", "Run Regression Model Insights baseline", "Request SHAP approval", "Run SHAP if approved", "Assemble ReportContract", "Open Report Browser"),
    approval_gates = c("SHAP Analysis")
  )
  data <- data %||% build_week_demo_dataset(write_if_missing = TRUE)
  session <- agent_session_record_action(session, "inspect_dataset", target = "data", label = "Inspect dataset contract", rationale = "The campaign must verify schema readiness before running analysis.")
  validation <- validate_agent_dataset_contract(data, dataset_manifest)
  session$observations$dataset_validation <- list(status = validation$status, message = paste(c(validation$errors, validation$warnings, "Dataset contract inspected."), collapse = " "))
  if (identical(validation$status, "error")) {
    session$errors <- c(session$errors, validation$errors)
    session <- agent_session_record_action(session, "fail", target = "data", label = "Fail campaign", status = "failed", error = paste(validation$errors, collapse = "; "))
    return(service_result(status = "error", value = agent_session_transition(session, "failed", "Dataset contract failed."), errors = validation$errors))
  }
  if (length(validation$warnings)) {
    session$warnings <- c(session$warnings, validation$warnings)
  }

  mystery_signals <- tryCatch(build_week_demo_signal_summary(data), error = function(e) NULL)
  if (!is.null(mystery_signals)) {
    observation_statement <- paste0(
      "Enrollment performance appears weaker than expected in selected weeks even though spend remains substantial. ",
      "Search looks inefficient at first glance, but the campaign has not yet separated saturation, audience response, operating delays, creative fatigue, competitor pressure, or region baselines."
    )
  } else {
    observation_statement <- paste0("The dataset passed schema validation with ", nrow(data), " rows. Mechanism-level drivers remain unknown.")
  }
  session <- agent_session_add_inquiry_event(session, "observation", "Initial funnel signal", observation_statement)
  session <- agent_session_add_inquiry_event(session, "important_uncertainty", "Main uncertainty", session$inquiry$important_uncertainty)
  initial_explanations <- list(
    create_inquiry_explanation("search_saturation", "Search may be underperforming because high spend has reached diminishing returns.", status = "proposed", confidence = "not_assessed"),
    create_inquiry_explanation("creative_fatigue", "Aging creative may be reducing response after several weeks in market.", status = "proposed", confidence = "not_assessed"),
    create_inquiry_explanation("operational_delay", "Processing delays may suppress enrollments once the operation exceeds a service threshold.", status = "proposed", confidence = "not_assessed"),
    create_inquiry_explanation("competitor_pressure", "Competitor promotions may explain selected regional declines.", status = "proposed", confidence = "not_assessed"),
    create_inquiry_explanation("audience_mix", "Audience mix may explain why Social appears strong in some segments and weak in others.", status = "proposed", confidence = "not_assessed")
  )
  session <- agent_session_set_explanations(session, initial_explanations)
  session <- agent_session_add_inquiry_event(session, "competing_explanations", "Competing explanations recorded", "The campaign will compare Search saturation, creative fatigue, operational delay, competitor pressure, and audience mix before recommending a decision path.")
  candidates <- list(
    create_candidate_investigation("eda_profile", "Explore data quality and distribution evidence", "Is the dataset suitable for a governed funnel investigation?", expected_decision_impact = "moderate", expected_learning_value = "moderate", execution_cost = "low", interpretation_risk = "low"),
    create_candidate_investigation("regression_baseline", "Run baseline Regression Model Insights", "Which directional drivers appear in a deterministic baseline model?", expected_decision_impact = "moderate", expected_learning_value = "moderate", execution_cost = "low", interpretation_risk = "moderate"),
    create_candidate_investigation("shap_driver_review", "Run governed SHAP driver review", "Do model explanations strengthen, weaken, or complicate the baseline driver story?", expected_decision_impact = "high", expected_learning_value = "high", execution_cost = "moderate", interpretation_risk = "moderate", approval_requirement = "approval_required", selected = isTRUE(approve_shap), selection_rationale = if (isTRUE(approve_shap)) "Highest expected learning value for distinguishing operational thresholds and interaction effects from simple spend explanations." else NULL),
    create_candidate_investigation("segment_stability_review", "Review audience and regional stability evidence", "Are findings stable enough across audiences and regions for business use?", expected_decision_impact = "high", expected_learning_value = "high", execution_cost = "moderate", interpretation_risk = "moderate")
  )
  session <- agent_session_set_candidate_investigations(session, candidates, selected_id = if (isTRUE(approve_shap)) "shap_driver_review" else "regression_baseline")
  session <- agent_session_add_inquiry_event(session, "candidate_investigations", "Candidate investigations ranked", "The campaign recorded low-cost readiness checks, a baseline model, governed SHAP, and future segment stability review as competing ways to reduce uncertainty.")

  demo_reports <- report_browser_demo_reports()
  service_map <- list(
    eda = demo_reports$eda,
    regression_model_insights = demo_reports$regression,
    shap_analysis = demo_reports$shap
  )

  for (service_id in c("eda", "regression_model_insights")) {
    session <- agent_session_record_action(session, "run_service", target = "analysis_modules", label = paste("Run", ui_display_label(service_id)), rationale = "Execute a deterministic analytics service before reviewing evidence.")
    report <- service_map[[service_id]]
    summary <- agent_count_report(report, service_id)
    service_summaries <- c(service_summaries, list(summary))
    session <- agent_session_add_service_run(session, service_id, summary$validation_status, report = report, diagnostics = summary)
    evidence_id <- paste0(service_id, "_report_", report$report_id)
    session <- agent_session_add_evidence(session, evidence_id, report$title, "report_contract", source = service_id, metadata = summary)
    session <- agent_session_add_inquiry_event(session, "evidence_collected", paste("Collected", ui_display_label(service_id)), paste("The", ui_display_label(service_id), "ReportContract validated with", summary$components, "component(s) and", summary$findings, "finding(s)."), evidence_ids = evidence_id)
    if (identical(service_id, "eda")) {
      session <- agent_session_add_belief_revision(session, create_belief_revision(
        revision_id = "belief_after_eda",
        initial_belief = "Search spend appears questionable because enrollments are weaker than expected in selected weeks.",
        evidence_discovered = "EDA produced a validated ReportContract and showed the mystery is not reducible to one channel or one region.",
        updated_belief = "The dataset is suitable for a governed baseline investigation, but the driver mechanism remains uncertain.",
        decision_impact = "Proceed to Regression Model Insights before making any recommendation.",
        confidence = "moderate",
        evidence_ids = evidence_id
      ))
      session <- agent_session_add_recommendation_revision(session, create_recommendation_revision(
        recommendation_version = 1L,
        previous_recommendation = "No recommendation before evidence review.",
        current_recommendation = "Do not cut Search yet; establish baseline driver evidence before touching budget.",
        reason_changed = "EDA established readiness but not mechanism.",
        supporting_evidence_ids = evidence_id
      ))
    }
    if (identical(service_id, "regression_model_insights")) {
      regression_explanations <- list(
        create_inquiry_explanation("search_saturation", "Search may be underperforming because high spend has reached diminishing returns.", status = "supported", supporting_evidence = evidence_id, confidence = "moderate", remaining_uncertainty = "Regression is directional and still needs nonlinear explanation evidence."),
        create_inquiry_explanation("creative_fatigue", "Aging creative may be reducing response after several weeks in market.", status = "supported", supporting_evidence = evidence_id, confidence = "moderate", remaining_uncertainty = "Creative evidence should be checked against audience and region."),
        create_inquiry_explanation("operational_delay", "Processing delays may suppress enrollments once the operation exceeds a service threshold.", status = "supported", supporting_evidence = evidence_id, confidence = "moderate", remaining_uncertainty = "The operational threshold shape still needs explanation evidence."),
        create_inquiry_explanation("competitor_pressure", "Competitor promotions may explain selected regional declines.", status = "supported", supporting_evidence = evidence_id, confidence = "moderate", remaining_uncertainty = "Competitor effects remain observational."),
        create_inquiry_explanation("audience_mix", "Audience mix may explain why Social appears strong in some segments and weak in others.", status = "unresolved", supporting_evidence = character(), confidence = "unresolved", remaining_uncertainty = "Audience interaction still needs stronger evidence.")
      )
      session <- agent_session_set_explanations(session, regression_explanations)
      session <- agent_session_add_belief_revision(session, create_belief_revision(
        revision_id = "belief_after_regression",
        initial_belief = session$inquiry$current_belief %||% "Baseline driver evidence is not yet available.",
        evidence_discovered = "Regression Model Insights produced a validated baseline report that elevated operational delay, creative age, competitor pressure, and diminishing Search returns.",
        updated_belief = "The story is no longer simply weak Search. Operations and creative are plausible action levers, while Social may depend on audience.",
        decision_impact = "Request governed SHAP approval if the operator wants stronger explanation evidence.",
        confidence = "moderate",
        evidence_ids = evidence_id
      ))
      session <- agent_session_add_recommendation_revision(session, create_recommendation_revision(
        recommendation_version = 2L,
        previous_recommendation = "Do not cut Search yet; establish baseline driver evidence before touching budget.",
        current_recommendation = if (isTRUE(approve_shap)) "Run governed SHAP to test whether delay threshold, creative fatigue, Search saturation, and Social-by-audience effects hold under explanation evidence." else "Treat operations and creative as preliminary priorities because SHAP was not approved.",
        reason_changed = "Baseline evidence moved the recommendation away from broad Search cuts and toward operations plus creative.",
        supporting_evidence_ids = evidence_id
      ))
    }
    session <- agent_session_record_action(session, "review_result", target = "artifact_studio", label = paste("Review", ui_display_label(service_id)), rationale = "Review the generated report contract before proceeding.", evidence_inputs = evidence_id)
    session <- agent_session_add_decision(session, create_decision_trace(
      goal = "Advance the campaign only when the preceding service output is traceable.",
      observation = paste(service_id, "returned a", summary$validation_status, "ReportContract with", summary$components, "component(s)."),
      decision = "Continue to the next campaign step.",
      basis = "ReportContract validation and evidence reference creation succeeded.",
      evidence_ids = evidence_id,
      confidence = "process_confidence_high",
      alternatives_considered = c("Stop and request manual review", "Continue without evidence reference"),
      next_action = "Proceed to the next deterministic service."
    ))
  }

  session <- agent_session_transition(session, "awaiting_approval", "SHAP approval gate reached.")
  session <- agent_session_record_action(session, "request_approval", target = "approval_gate", status = "awaiting_approval", label = "Request SHAP approval", rationale = "SHAP can be higher cost and should be governed before execution.")
  approval <- list(
    approval_id = agent_id("approval"),
    gate = "shap_analysis",
    status = if (isTRUE(approve_shap)) "approved" else "rejected",
    rationale = if (isTRUE(approve_shap)) "Operator approved SHAP for driver explanation." else "Operator rejected SHAP; campaign will produce reduced report.",
    timestamp = agent_now()
  )
  session$approvals <- c(session$approvals %||% list(), list(approval))
  session <- agent_session_record_action(session, "receive_approval", target = "approval_gate", label = paste("SHAP", ui_display_label(approval$status)), rationale = approval$rationale)
  session <- agent_session_add_inquiry_event(session, "selected_investigation", "Investigation selected", if (isTRUE(approve_shap)) "Governed SHAP was selected because it has high expected information value for distinguishing baseline and nonlinear explanations." else "Regression baseline was selected as the stopping point because the governed SHAP step was not approved.")

  shap_status <- approval$status
  if (isTRUE(approve_shap)) {
    session <- agent_session_transition(session, "running", "SHAP approved; campaign resumed.")
    session <- agent_session_record_action(session, "run_service", target = "analysis_modules", label = "Run SHAP Analysis", rationale = "Operator approved the governed SHAP step.")
    report <- service_map$shap_analysis
    summary <- agent_count_report(report, "shap_analysis")
    service_summaries <- c(service_summaries, list(summary))
    session <- agent_session_add_service_run(session, "shap_analysis", summary$validation_status, report = report, diagnostics = summary)
    evidence_id <- paste0("shap_analysis_report_", report$report_id)
    session <- agent_session_add_evidence(session, evidence_id, report$title, "report_contract", source = "shap_analysis", metadata = summary)
    session <- agent_session_add_inquiry_event(session, "evidence_collected", "Collected SHAP explanation evidence", paste("SHAP Analysis validated with", summary$components, "component(s) and now anchors the explanation step."), evidence_ids = evidence_id)
    all_evidence_ids <- vapply(session$evidence_references %||% list(), function(x) x$evidence_id %||% "", character(1))
    shap_explanations <- list(
      create_inquiry_explanation("search_saturation", "Search may be underperforming because high spend has reached diminishing returns.", status = "supported", supporting_evidence = all_evidence_ids, confidence = "high", remaining_uncertainty = "Saturation evidence guides marginal allocation, not a blanket channel cut."),
      create_inquiry_explanation("creative_fatigue", "Aging creative may be reducing response after several weeks in market.", status = "supported", supporting_evidence = all_evidence_ids, confidence = "moderate", remaining_uncertainty = "Creative refresh should be monitored after implementation."),
      create_inquiry_explanation("operational_delay", "Processing delays may suppress enrollments once the operation exceeds a service threshold.", status = "supported", supporting_evidence = all_evidence_ids, confidence = "high", remaining_uncertainty = "The delay intervention is actionable but not randomized causal proof."),
      create_inquiry_explanation("competitor_pressure", "Competitor promotions may explain selected regional declines.", status = "supported", supporting_evidence = all_evidence_ids, confidence = "moderate", remaining_uncertainty = "Competitor pressure should be handled as a regional context, not as channel failure."),
      create_inquiry_explanation("audience_mix", "Audience mix may explain why Social appears strong in some segments and weak in others.", status = "supported", supporting_evidence = all_evidence_ids, confidence = "moderate", remaining_uncertainty = "Social targeting needs audience-level monitoring.")
    )
    session <- agent_session_set_explanations(session, shap_explanations)
    session <- agent_session_add_belief_revision(session, create_belief_revision(
      revision_id = "belief_after_shap",
      initial_belief = session$inquiry$current_belief %||% "Nonlinear explanation evidence is unresolved.",
      evidence_discovered = "SHAP evidence strengthened the operational-delay threshold, Search saturation, creative fatigue, and audience-specific Social explanations.",
      updated_belief = "The best evidence-backed conclusion is that the business should not broadly reduce Search. The highest-value action is operational throughput, followed by creative refresh and audience-targeted Social allocation.",
      decision_impact = "Move from generic budget skepticism to a prioritized operational and targeting recommendation.",
      confidence = "high",
      evidence_ids = all_evidence_ids
    ))
    session <- agent_session_add_recommendation_revision(session, create_recommendation_revision(
      recommendation_version = 3L,
      previous_recommendation = "Run governed SHAP to test whether delay threshold, creative fatigue, Search saturation, and Social-by-audience effects hold under explanation evidence.",
      current_recommendation = "Improve processing throughput first, refresh aging creative, target Social toward Career Changers, tune Search at the saturated margin instead of broadly cutting it, and treat competitor pressure separately from channel quality.",
      reason_changed = "Explanation evidence changed the recommendation from broad channel skepticism to a prioritized intervention path.",
      supporting_evidence_ids = all_evidence_ids
    ))
    session <- agent_session_record_action(session, "review_result", target = "artifact_studio", label = "Review SHAP evidence", rationale = "Review driver explanation artifacts after governed approval.", evidence_inputs = evidence_id)
  } else {
    session <- agent_session_transition(session, "running", "SHAP rejected; reduced campaign report will be assembled.")
    session <- agent_session_add_decision(session, create_decision_trace(
      goal = "Respect approval boundaries while preserving campaign usefulness.",
      observation = "The SHAP approval gate was rejected.",
      decision = "Build a reduced report without SHAP outputs.",
      basis = "Governance rejects the optional higher-cost step while allowing prior deterministic evidence to be reported.",
      evidence_ids = character(),
      confidence = "governance_confidence_high",
      alternatives_considered = c("Run SHAP anyway", "Cancel the full campaign"),
      next_action = "Assemble reduced ReportContract."
    ))
    session <- agent_session_add_belief_revision(session, create_belief_revision(
      revision_id = "belief_without_shap",
      initial_belief = session$inquiry$current_belief %||% "Baseline evidence exists, explanation evidence is unresolved.",
      evidence_discovered = "The governed SHAP investigation was not approved.",
      updated_belief = "The campaign remains preliminary: operations and creative look important, but the system cannot confidently resolve the interaction and saturation story without explanation evidence.",
      decision_impact = "Assemble a reduced report and request human review before action.",
      confidence = "moderate",
      evidence_ids = vapply(session$evidence_references %||% list(), function(x) x$evidence_id %||% "", character(1))
    ))
  }

  session <- agent_session_add_inquiry_event(session, "belief_update", "Belief updated", session$inquiry$current_belief, evidence_ids = vapply(session$evidence_references %||% list(), function(x) x$evidence_id %||% "", character(1)))
  latest_recommendation <- tail(session$inquiry$recommendation_revisions %||% list(list(current_recommendation = "Review linked evidence before decision use.")), 1L)[[1]]
  session <- agent_session_add_inquiry_event(session, "decision_impact", "Recommendation updated", latest_recommendation$current_recommendation %||% "Review linked evidence before decision use.", evidence_ids = latest_recommendation$supporting_evidence_ids %||% character())
  remaining_uncertainty <- c(
    "The campaign does not establish randomized causal identification.",
    "The operational-delay intervention should be monitored after implementation.",
    "Social targeting and creative refresh should be reviewed by audience and region before broad rollout.",
    "Competitor-promo effects explain context but do not prescribe a direct marketing action by themselves."
  )
  session <- agent_session_set_remaining_uncertainty(session, remaining_uncertainty, list(
    outcome = if (isTRUE(approve_shap)) "needs_human_judgment" else "needs_additional_analysis",
    rationale = if (isTRUE(approve_shap)) "The bounded inquiry collected enough evidence for human review, but business adoption still requires judgment." else "The highest-value explanation step was not approved, so the inquiry remains preliminary.",
    next_action = if (isTRUE(approve_shap)) "Verify the campaign claim and inspect the Report Browser." else "Approve or replace the explanation investigation before using the report for decisions."
  ))
  session <- agent_session_set_integrity_review(session, build_investigation_integrity_review(session))
  session <- agent_session_add_inquiry_event(session, "remaining_uncertainty", "Remaining uncertainty recorded", paste(remaining_uncertainty, collapse = " "))
  session <- agent_session_add_inquiry_event(session, "stopping_rule", "Integrity review and decision readiness recorded", paste(session$inquiry$integrity_review$decision_readiness$rationale %||% session$inquiry$stopping_rule$rationale %||% "", "Next:", session$inquiry$stopping_rule$next_action %||% ""))

  session <- agent_session_record_action(session, "build_report", target = "report_browser", label = "Build campaign ReportContract", rationale = "Translate campaign state into a semantic report without rendering logic.")
  report <- build_agent_campaign_report(session, service_summaries, shap_status = shap_status)
  report_validation <- validate_report(report)
  session <- agent_session_record_action(session, "validate_report", target = "report_browser", label = "Validate campaign report", rationale = "A report must validate before it can become a replayable campaign output.", outputs = list(validation_status = report_validation$status))
  session$report_id <- report$report_id
  session$report_contract <- report
  session <- agent_session_record_action(session, "open_report", target = "report_browser", label = "Open report browser", rationale = "The analyst should inspect the assembled report at human speed.")
  session <- agent_session_record_action(session, "complete", target = "control_bar", label = "Complete campaign", rationale = "All bounded steps have finished.")
  session <- agent_session_transition(session, "completed", "Campaign completed.")
  service_result(status = if (identical(report_validation$status, "error")) "error" else "success", value = session, warnings = c(validation$warnings, report_validation$warnings), errors = report_validation$errors)
}

agent_campaign_claim_trace <- function(session, finding_id = "finding_traceable_process_evidence") {
  report <- session$report_contract
  finding <- NULL
  for (item in report$findings %||% list()) {
    if (identical(item$finding_id %||% "", finding_id)) {
      finding <- item
      break
    }
  }
  if (is.null(finding)) {
    return(service_result(status = "error", errors = paste("Finding not found:", finding_id)))
  }
  evidence_ids <- finding$evidence_ids %||% character()
  linked_evidence <- Filter(function(evidence) evidence$evidence_id %in% evidence_ids, session$evidence_references %||% list())
  inquiry <- session$inquiry %||% create_inquiry_state(session$objective %||% "Campaign inquiry")
  belief_revisions <- inquiry$belief_revisions %||% list()
  recommendation_revisions <- inquiry$recommendation_revisions %||% list()
  initial_belief <- if (length(belief_revisions)) belief_revisions[[1L]]$initial_belief else inquiry$current_belief %||% "No belief was recorded."
  final_belief <- if (length(belief_revisions)) tail(belief_revisions, 1L)[[1L]]$updated_belief else inquiry$current_belief %||% "No final belief was recorded."
  final_recommendation <- if (length(recommendation_revisions)) tail(recommendation_revisions, 1L)[[1L]]$current_recommendation else "Review linked evidence before decision use."
  service_result(
    status = "success",
    value = list(
      claim = finding$statement,
      initial_belief = initial_belief,
      evidence_discovered = vapply(belief_revisions, function(x) x$evidence_discovered %||% "", character(1)),
      belief_revisions = belief_revisions,
      final_conclusion = final_belief,
      recommendation_revisions = recommendation_revisions,
      final_recommendation = final_recommendation,
      integrity_review = inquiry$integrity_review %||% build_investigation_integrity_review(session),
      remaining_uncertainty = inquiry$remaining_uncertainty %||% character(),
      stopping_rule = inquiry$stopping_rule %||% list(),
      evidence_ids = evidence_ids,
      linked_evidence = linked_evidence,
      diagnostic = finding$quality_status %||% "not_assessed",
      diagnostics = c(finding$quality_status %||% "not_assessed", paste("Inquiry events:", length(inquiry$timeline %||% list()))),
      method = "Deterministic AgentSession replay plus ReportContract evidence references and recorded belief revisions.",
      limitations = c("This trace explains why the process claim is credible, not whether a business driver is causally true."),
      provenance = list(agent_session_id = session$session_id, report_id = report$report_id)
    )
  )
}

qa_agent_operation_runtime <- function() {
  checks <- list()
  add <- function(check, status, message = "") {
    checks[[length(checks) + 1L]] <<- data.table::data.table(check = check, status = status, message = message)
  }

  session <- create_agent_session("QA campaign")
  add("session_construction", if (inherits(session, "agent_session")) "success" else "error", "AgentSession constructed.")
  add("settings_presets", if (identical(validate_agent_operation_settings(agent_operation_settings("Presentation"))$status, "success")) "success" else "error", "Presentation settings validate.")
  add("action_registry", if (setequal(agent_action_registry()$action_type, agent_action_types)) "success" else "error", "Action registry covers all supported types.")
  action <- create_agent_action("inspect_project")
  add("action_validation", if (identical(validate_agent_action(action)$status, "success")) "success" else "error", "Agent action validates.")
  trace <- create_decision_trace("Goal", "Observation", "Decision", "Basis")
  add("decision_trace", if (identical(validate_decision_trace(trace)$status, "success")) "success" else "error", "DecisionTrace validates.")
  transitioned <- tryCatch(agent_session_transition(session, "completed"), error = function(e) e)
  add("illegal_transition_rejected", if (inherits(transitioned, "error")) "success" else "error", "Illegal lifecycle transitions are rejected.")
  session2 <- agent_session_transition(session, "planning")
  session2 <- agent_session_transition(session2, "running")
  session2 <- agent_session_pause(session2)
  session2 <- agent_session_resume(session2)
  add("pause_resume", if (identical(session2$status, "running")) "success" else "error", "Pause/resume transitions work.")
  stepped <- agent_session_step(session2)
  add("step_control", if ((stepped$presentation_state$step_index %||% 0L) == 1L) "success" else "error", "Step increments presentation state.")
  cursor <- resolve_agent_cursor_target("missing_target")
  add("cursor_fallback", if (identical(cursor$status, "warning") && isTRUE(cursor$value$fallback)) "success" else "error", "Missing cursor target falls back safely.")
  approved <- run_funnel_driver_investigation(approve_shap = TRUE)
  add("campaign_approved_path", if (identical(approved$status, "success") && identical(approved$value$status, "completed")) "success" else "error", paste(c(approved$errors, "Approved campaign completes."), collapse = " "))
  add("inquiry_validation", if (identical(validate_inquiry_state(approved$value$inquiry, require_complete = TRUE)$status, "success")) "success" else "error", "Completed campaign has a valid inquiry record.")
  add("inquiry_explanations", if (length(approved$value$inquiry$explanations %||% list()) >= 3L) "success" else "error", "Campaign records competing explanations.")
  add("inquiry_belief_revisions", if (length(approved$value$inquiry$belief_revisions %||% list()) >= 2L) "success" else "error", "Campaign records belief revision over evidence.")
  rejected <- run_funnel_driver_investigation(approve_shap = FALSE)
  add("campaign_rejected_path", if (identical(rejected$status, "success") && identical(rejected$value$status, "completed")) "success" else "error", paste(c(rejected$errors, "Rejected SHAP campaign completes with reduced report."), collapse = " "))
  failed <- run_funnel_driver_investigation(data = data.frame(channel = "Search"), approve_shap = TRUE)
  add("campaign_failure_path", if (identical(failed$status, "error") && identical(failed$value$status, "failed")) "success" else "error", "Invalid dataset fails gracefully.")
  json <- serialize_agent_session(approved$value)
  restored <- deserialize_agent_session(json)
  add("serialization_roundtrip", if (identical(validate_agent_session(restored)$status, "success")) "success" else "error", "AgentSession serializes and restores.")
  replay <- agent_session_replay(restored)
  add("replay_without_rerun", if (identical(replay$status, "replaying") && length(replay$service_runs) == length(restored$service_runs)) "success" else "error", "Replay copies recorded service runs without execution.")
  replay_step <- agent_session_step(replay)
  add("inquiry_replay_steps", if (isTRUE(replay_step$presentation_state$replay) && (replay_step$presentation_state$step_index %||% 0L) > (replay$presentation_state$step_index %||% 0L)) "success" else "error", "Replay can step through recorded inquiry state.")
  trace_result <- agent_campaign_claim_trace(approved$value)
  add("claim_traceability", if (identical(trace_result$status, "success") && length(trace_result$value$evidence_ids)) "success" else "error", "Report finding traces to evidence.")
  add("claim_belief_path", if (identical(trace_result$status, "success") && length(trace_result$value$belief_revisions %||% list()) && nzchar(trace_result$value$final_conclusion %||% "")) "success" else "error", "Claim trace includes belief revision and final conclusion.")
  report_validation <- validate_report(approved$value$report_contract)
  add("report_completion", if (!identical(report_validation$status, "error")) "success" else "error", paste(c(report_validation$errors, "Campaign report validates."), collapse = " "))

  data.table::rbindlist(checks)
}
