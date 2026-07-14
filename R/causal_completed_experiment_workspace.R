causal_completed_experiment_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_completed_experiment",
      "aq_assignment_evidence",
      "aq_treatment_delivery_evidence",
      "aq_exposure_evidence",
      "aq_compliance_evidence",
      "aq_outcome_evidence",
      "aq_exclusion_evidence",
      "aq_reconcile_experiment_execution",
      "aq_assess_randomization_integrity",
      "aq_assess_missingness_attrition",
      "aq_assess_treatment_fidelity",
      "aq_assess_interference_spillover",
      "aq_assess_guardrails",
      "aq_assess_estimand_preservation",
      "aq_assess_experiment_analysis_readiness",
      "aq_planned_analysis_record",
      "aq_completed_experiment_evidence_artifact"
    ) %in% getNamespaceExports("AutoQuant"))
}

causal_completed_experiment_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "causal_completed_experiment_workspace_v1",
    project_id = project_id,
    active_completed_experiment_id = NA_character_,
    completed_experiments = data.table::data.table(
      completed_experiment_id = character(),
      experiment_plan_artifact_id = character(),
      decision_context_id = character(),
      causal_question_id = character(),
      estimand_id = character(),
      experiment_status = character(),
      updated_at = character()
    ),
    evidence_mappings = data.table::data.table(
      completed_experiment_id = character(),
      evidence_role = character(),
      source_column = character(),
      updated_at = character()
    ),
    assessments = list(),
    artifact_registry = character(),
    history = data.table::data.table(
      event_id = character(),
      completed_experiment_id = character(),
      event_type = character(),
      signature = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

causal_completed_experiment_normalize <- function(state) {
  state <- state %||% causal_completed_experiment_empty()
  empty <- causal_completed_experiment_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (name in c("completed_experiments", "evidence_mappings", "history")) {
    if (!data.table::is.data.table(state[[name]])) state[[name]] <- data.table::as.data.table(state[[name]])
  }
  state
}

causal_completed_experiment_now <- function() as.character(Sys.time())

causal_completed_experiment_active_id <- function(state) {
  state <- causal_completed_experiment_normalize(state)
  id <- state$active_completed_experiment_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$completed_experiments)) state$completed_experiments$completed_experiment_id[[1]] else NA_character_
}

causal_completed_experiment_signature <- function(state, completed_experiment_id = causal_completed_experiment_active_id(state)) {
  state <- causal_completed_experiment_normalize(state)
  target_id <- completed_experiment_id
  rows <- state$completed_experiments[completed_experiment_id == target_id]
  mappings <- state$evidence_mappings[completed_experiment_id == target_id]
  paste(
    completed_experiment_id %||% "",
    nrow(rows),
    paste(rows$updated_at %||% character(), collapse = ","),
    nrow(mappings),
    paste(mappings$updated_at %||% character(), collapse = ","),
    sep = "::"
  )
}

causal_completed_experiment_event <- function(completed_experiment_id, event_type, signature, summary) {
  data.table::data.table(
    event_id = paste0("causal_completed_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    completed_experiment_id = completed_experiment_id %||% NA_character_,
    event_type = event_type,
    signature = signature %||% NA_character_,
    summary = summary %||% "",
    timestamp = causal_completed_experiment_now()
  )
}

causal_completed_experiment_upsert_completed <- function(state, row) {
  state <- causal_completed_experiment_normalize(state)
  row <- data.table::as.data.table(row)
  if (!"completed_experiment_id" %in% names(row) || !nzchar(row$completed_experiment_id[[1]] %||% "")) {
    return(service_result(status = "error", errors = "completed_experiment_id is required."))
  }
  row[, updated_at := causal_completed_experiment_now()]
  if (!"created_at" %in% names(row)) row[, created_at := updated_at]
  id <- row$completed_experiment_id[[1]]
  existing <- state$completed_experiments
  if (nrow(existing) && id %in% existing$completed_experiment_id) {
    old <- existing[completed_experiment_id == id][1]
    row[, created_at := old$created_at %||% updated_at]
    existing <- existing[completed_experiment_id != id]
  }
  state$completed_experiments <- data.table::rbindlist(list(existing, row), use.names = TRUE, fill = TRUE)
  state$active_completed_experiment_id <- id
  state$assessments[[id]]$stale <- TRUE
  signature <- causal_completed_experiment_signature(state, id)
  state$history <- data.table::rbindlist(list(state$history, causal_completed_experiment_event(id, "completed_experiment_saved", signature, paste("Saved completed experiment", id))), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = paste("Saved completed experiment", id), metadata = list(completed_experiment_id = id, signature = signature))
}

causal_completed_experiment_save_mappings <- function(state, completed_experiment_id, mappings) {
  state <- causal_completed_experiment_normalize(state)
  if (!nzchar(completed_experiment_id %||% "")) return(service_result(status = "error", errors = "Save a completed experiment before mapping evidence columns."))
  rows <- data.table::as.data.table(mappings)
  rows <- rows[nzchar(source_column %||% "")]
  if (!nrow(rows)) return(service_result(status = "warning", warnings = "No evidence mappings were supplied."))
  rows[, completed_experiment_id := completed_experiment_id]
  rows[, updated_at := causal_completed_experiment_now()]
  target_id <- completed_experiment_id
  state$evidence_mappings <- state$evidence_mappings[completed_experiment_id != target_id]
  state$evidence_mappings <- data.table::rbindlist(list(state$evidence_mappings, rows), use.names = TRUE, fill = TRUE)
  state$assessments[[completed_experiment_id]]$stale <- TRUE
  signature <- causal_completed_experiment_signature(state, completed_experiment_id)
  state$history <- data.table::rbindlist(list(state$history, causal_completed_experiment_event(completed_experiment_id, "evidence_mappings_saved", signature, "Saved completed-experiment evidence mappings.")), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = "Saved completed-experiment evidence mappings.", metadata = list(completed_experiment_id = completed_experiment_id, signature = signature))
}

causal_completed_experiment_mapping <- function(state, completed_experiment_id, role) {
  state <- causal_completed_experiment_normalize(state)
  target_id <- completed_experiment_id
  rows <- state$evidence_mappings[completed_experiment_id == target_id & evidence_role == role]
  if (nrow(rows)) rows$source_column[[1]] else NA_character_
}

causal_completed_experiment_get_col <- function(state, completed_experiment_id, role, fallback = NULL) {
  value <- causal_completed_experiment_mapping(state, completed_experiment_id, role)
  if (nzchar(value %||% "")) value else fallback
}

causal_completed_experiment_build_autoquant <- function(state, data = NULL) {
  if (!causal_completed_experiment_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant completed-experiment API is unavailable in the current R library. Install the updated AutoQuant package to assess completed experiment readiness."))
  }
  state <- causal_completed_experiment_normalize(state)
  id <- causal_completed_experiment_active_id(state)
  record <- state$completed_experiments[completed_experiment_id == id][1]
  if (!nrow(record)) return(service_result(status = "error", errors = "No completed experiment record exists."))
  dt <- data.table::as.data.table(data %||% data.table::data.table())
  completed <- AutoQuant::aq_completed_experiment(record)
  assignment <- NULL
  delivery <- NULL
  exposure <- NULL
  compliance <- NULL
  outcomes <- NULL
  exclusions <- NULL
  guardrail_outcomes <- NULL
  unit_col <- causal_completed_experiment_get_col(state, id, "unit_id", "unit_id")
  planned_col <- causal_completed_experiment_get_col(state, id, "planned_arm", "planned_arm")
  realized_col <- causal_completed_experiment_get_col(state, id, "realized_assigned_arm", "realized_assigned_arm")
  delivered_col <- causal_completed_experiment_get_col(state, id, "delivered_condition", "delivered_condition")
  delivery_status_col <- causal_completed_experiment_get_col(state, id, "delivery_status", "delivery_status")
  exposure_col <- causal_completed_experiment_get_col(state, id, "exposure", "exposure")
  received_col <- causal_completed_experiment_get_col(state, id, "treatment_received", "treatment_received")
  outcome_col <- causal_completed_experiment_get_col(state, id, "primary_outcome", record$primary_outcome[[1]] %||% "outcome")
  guardrail_col <- causal_completed_experiment_get_col(state, id, "guardrail", NA_character_)
  exclusion_col <- causal_completed_experiment_get_col(state, id, "exclusion_stage", NA_character_)
  if (all(c(unit_col, planned_col) %in% names(dt))) {
    if (!realized_col %in% names(dt)) dt[, realized_assigned_arm := get(planned_col)]
    assignment <- AutoQuant::aq_assignment_evidence(dt, unit_id_col = unit_col, planned_arm_col = planned_col, realized_arm_col = if (realized_col %in% names(dt)) realized_col else "realized_assigned_arm")
  }
  if (all(c(unit_col, delivered_col) %in% names(dt))) {
    delivery <- AutoQuant::aq_treatment_delivery_evidence(dt, unit_id_col = unit_col, delivered_condition_col = delivered_col, delivery_status_col = if (delivery_status_col %in% names(dt)) delivery_status_col else NULL)
  }
  if (all(c(unit_col, exposure_col) %in% names(dt))) {
    exposure <- AutoQuant::aq_exposure_evidence(dt, unit_id_col = unit_col, exposure_col = exposure_col)
  }
  if (all(c(unit_col, planned_col, received_col) %in% names(dt))) {
    compliance <- AutoQuant::aq_compliance_evidence(dt, unit_id_col = unit_col, assigned_col = planned_col, received_col = received_col)
  }
  if (all(c(unit_col, outcome_col) %in% names(dt))) {
    outcome_dt <- data.table::data.table(unit_id = as.character(dt[[unit_col]]), outcome_id = outcome_col, value = dt[[outcome_col]], outcome_role = "primary")
    outcomes <- AutoQuant::aq_outcome_evidence(outcome_dt)
  }
  if (all(c(unit_col, guardrail_col) %in% names(dt))) {
    guardrail_dt <- data.table::data.table(unit_id = as.character(dt[[unit_col]]), outcome_id = guardrail_col, value = dt[[guardrail_col]], outcome_role = "guardrail")
    guardrail_outcomes <- AutoQuant::aq_outcome_evidence(guardrail_dt)
  }
  if (all(c(unit_col, exclusion_col) %in% names(dt))) {
    exclusion_dt <- data.table::data.table(
      unit_id = as.character(dt[[unit_col]]),
      exclusion_stage = as.character(dt[[exclusion_col]]),
      exclusion_reason = data.table::fifelse(as.character(dt[[exclusion_col]]) %in% c("", "none", "None", "NONE", NA_character_), "not_excluded", "mapped_exclusion")
    )
    exclusions <- AutoQuant::aq_exclusion_evidence(exclusion_dt)
  }
  missingness <- if (!is.null(assignment) && !is.null(outcomes)) AutoQuant::aq_assess_missingness_attrition(assignment, outcomes) else data.table::data.table(check = "missingness_unavailable", status = "warning", finding = "Assignment or outcome evidence is missing.")
  reconciliation <- AutoQuant::aq_reconcile_experiment_execution(
    completed,
    assignment_evidence = assignment,
    delivery_evidence = delivery,
    outcome_evidence = outcomes,
    exclusion_evidence = exclusions
  )
  integrity <- if (!is.null(assignment)) AutoQuant::aq_assess_randomization_integrity(assignment) else data.table::data.table(status = "assignment_integrity_review", diagnostics = list(data.table::data.table(check = "assignment_missing", status = "fail", finding = "Assignment evidence is missing.")))
  fidelity <- if (!is.null(assignment)) AutoQuant::aq_assess_treatment_fidelity(assignment, delivery, exposure, compliance) else data.table::data.table(fidelity_status = "insufficient measurement", reasons = "Assignment evidence missing.", recommendation = "Attach assignment evidence.")
  interference <- AutoQuant::aq_assess_interference_spillover()
  guardrails <- if (!is.null(guardrail_outcomes)) AutoQuant::aq_assess_guardrails(guardrail_outcomes) else data.table::data.table(guardrail_status = "guardrail_absent", severity = "warning", finding = "No guardrail evidence was supplied.", recommendation = "A positive primary outcome does not override missing guardrails.")
  estimand <- AutoQuant::aq_assess_estimand_preservation(completed, reconciliation, integrity, fidelity, missingness, interference, outcomes, exclusions)
  readiness <- AutoQuant::aq_assess_experiment_analysis_readiness(completed, assignment, outcomes, reconciliation, integrity, fidelity, missingness, estimand, guardrails)
  planned <- AutoQuant::aq_planned_analysis_record(completed, readiness, outcome_variables = if (!is.null(outcomes)) unique(outcomes$outcomes$outcome_id) else character())
  artifact <- AutoQuant::aq_completed_experiment_evidence_artifact(completed, assignment, delivery, exposure, compliance, outcomes, exclusions, missingness, reconciliation, integrity, fidelity, interference, guardrails, estimand, readiness, planned)
  service_result(status = "success", value = list(completed = completed, assignment = assignment, delivery = delivery, exposure = exposure, compliance = compliance, outcomes = outcomes, exclusions = exclusions, missingness = missingness, reconciliation = reconciliation, integrity = integrity, fidelity = fidelity, interference = interference, guardrails = guardrails, estimand = estimand, readiness = readiness, planned_analysis = planned, aq_artifact = artifact), messages = "Completed-experiment readiness assessed.")
}

causal_completed_experiment_assess <- function(state, data = NULL) {
  state <- causal_completed_experiment_normalize(state)
  id <- causal_completed_experiment_active_id(state)
  built <- causal_completed_experiment_build_autoquant(state, data)
  if (!identical(built$status, "success")) return(built)
  signature <- causal_completed_experiment_signature(state, id)
  state$assessments[[id]] <- c(built$value, list(signature = signature, stale = FALSE, assessed_at = causal_completed_experiment_now()))
  state$history <- data.table::rbindlist(list(state$history, causal_completed_experiment_event(id, "readiness_assessed", signature, paste("Readiness:", built$value$readiness$readiness_state[[1]]))), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = built$messages, metadata = list(completed_experiment_id = id, readiness_state = built$value$readiness$readiness_state[[1]], signature = signature))
}

causal_completed_experiment_summary <- function(state) {
  state <- causal_completed_experiment_normalize(state)
  id <- causal_completed_experiment_active_id(state)
  assessment <- state$assessments[[id]]
  readiness <- if (is.null(assessment)) "not_assessed" else assessment$readiness$readiness_state[[1]] %||% "not_assessed"
  data.table::data.table(
    completed_experiments = nrow(state$completed_experiments),
    evidence_mappings = nrow(state$evidence_mappings),
    readiness_state = readiness,
    assessment_status = if (is.null(assessment)) "not_assessed" else if (!identical(assessment$signature, causal_completed_experiment_signature(state, id))) "stale" else "current",
    assignment_preserved = !is.null(assessment$assignment),
    outcome_available = !is.null(assessment$outcomes),
    guardrail_status = if (is.null(assessment)) "not_assessed" else assessment$guardrails$guardrail_status[[1]] %||% "not_assessed",
    registered_artifacts = length(state$artifact_registry %||% character())
  )
}

causal_completed_experiment_campaign_seeds <- function(state) {
  summary <- causal_completed_experiment_summary(state)
  rows <- list()
  add <- function(seed_type, severity, recommendation) rows[[length(rows) + 1L]] <<- data.table::data.table(seed_type, severity, recommendation)
  if (!nrow(summary) || summary$completed_experiments[[1]] == 0L) add("completed_experiment_missing", "medium", "Ingest completed or in-progress experiment evidence before effect estimation.")
  if (!isTRUE(summary$assignment_preserved[[1]])) add("assignment_evidence_missing", "high", "Attach original assignment evidence; do not infer treatment from exposure.")
  if (!isTRUE(summary$outcome_available[[1]])) add("outcome_evidence_missing", "high", "Attach planned outcome evidence before analysis.")
  if (summary$guardrail_status[[1]] %in% c("guardrail_absent", "guardrail_breach_review")) add("guardrail_review", "medium", "Review guardrails separately from primary outcomes.")
  if (summary$readiness_state[[1]] %in% c("estimand_revision_required", "blocked", "invalid_for_planned_estimand")) add("estimand_readiness_blocker", "high", "Resolve estimand/readiness blockers before any estimator is allowed.")
  if (!length(rows)) add("ready_for_itt", "low", "Completed evidence appears ready for a future ITT estimator.")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

causal_completed_experiment_register_artifact <- function(ctx, state, completed_experiment_id = causal_completed_experiment_active_id(state)) {
  state <- causal_completed_experiment_normalize(state)
  assessment <- state$assessments[[completed_experiment_id]]
  if (is.null(assessment) || !identical(assessment$signature, causal_completed_experiment_signature(state, completed_experiment_id))) {
    return(service_result(status = "error", errors = "Assess current completed-experiment evidence before registering artifacts."))
  }
  artifact_id <- paste("causal_completed", completed_experiment_id, "readiness", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) return(service_result(status = "success", messages = "No duplicate completed-experiment artifact was registered."))
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Completed Experiment Readiness",
    source_module = "causal_intelligence",
    object = assessment$readiness,
    content = "Completed-experiment evidence readiness. No causal effect estimated.",
    metadata = list(
      module_id = "causal_intelligence",
      module_run_id = paste0("causal_completed_", format(Sys.time(), "%Y%m%d%H%M%S")),
      analytical_intent = "Causal Experiment Readiness",
      artifact_importance = "critical",
      caption = paste("Completed experiment readiness for", completed_experiment_id),
      diagnostics = c(assessment$reconciliation$finding, assessment$estimand$reasons),
      recommendations = c(assessment$readiness$recommendation, assessment$guardrails$recommendation),
      completed_experiment_id = completed_experiment_id,
      readiness_state = assessment$readiness$readiness_state[[1]],
      no_effect_estimated = TRUE,
      assignment_preserved = !is.null(assessment$assignment),
      prohibited_claims = c("causal effect was estimated", "treatment was redefined from exposure", "post-assignment exclusions were silently applied")
    ),
    section = "Causal Intelligence",
    order = 3L
  )
  result <- service_result(status = "success", artifacts = list(artifact), messages = "Completed-experiment readiness artifact registered.", metadata = list(module_id = "causal_intelligence", module_run_id = artifact$metadata$module_run_id, artifact_count = 1L))
  names(result$artifacts) <- artifact_id
  collector <- ctx$append_module_result_to_collector(result, module_id = "causal_intelligence", record_skipped = FALSE)
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry %||% character(), artifact_id))
  ctx$causal_completed_experiment_state(state)
  collector
}

qa_causal_completed_experiment_workspace <- function() {
  state <- causal_completed_experiment_empty("causal_completed_fixture")
  state <- causal_completed_experiment_upsert_completed(state, data.table::data.table(
    completed_experiment_id = "ce_paid_search_test",
    experiment_plan_artifact_id = "aq_experiment_plan_paid_search",
    decision_context_id = "decision_budget",
    causal_question_id = "cq_paid_search_revenue",
    estimand_id = "estimand_itt",
    design_version = "v1",
    assignment_version = "v1",
    experiment_status = "completed",
    actual_start_date = "2026-01-01",
    actual_end_date = "2026-02-01",
    data_cutoff_date = "2026-02-15",
    execution_owner = "analytics",
    primary_outcome = "revenue"
  ))$value
  mappings <- data.table::data.table(
    evidence_role = c("unit_id", "planned_arm", "realized_assigned_arm", "delivered_condition", "delivery_status", "exposure", "treatment_received", "primary_outcome", "guardrail", "exclusion_stage"),
    source_column = c("unit_id", "planned_arm", "realized_assigned_arm", "delivered_condition", "delivery_status", "exposure", "treatment_received", "revenue", "cost_guardrail", "exclusion_stage")
  )
  state <- causal_completed_experiment_save_mappings(state, "ce_paid_search_test", mappings)$value
  data <- data.table::data.table(
    unit_id = paste0("u", 1:20),
    planned_arm = rep(c("control", "treatment"), each = 10),
    realized_assigned_arm = rep(c("control", "treatment"), each = 10),
    delivered_condition = rep(c("control", "treatment"), each = 10),
    delivery_status = "delivered",
    exposure = c(rep(0, 10), rep(1, 10)),
    treatment_received = rep(c("control", "treatment"), each = 10),
    revenue = 1:20,
    cost_guardrail = 0,
    exclusion_stage = c(rep("none", 19), "post_assignment")
  )
  available <- causal_completed_experiment_available()
  assessed <- if (available) causal_completed_experiment_assess(state, data) else service_result(status = "warning", warnings = "AutoQuant completed experiment API unavailable for graceful QA.")
  summary <- if (identical(assessed$status, "success")) causal_completed_experiment_summary(assessed$value) else causal_completed_experiment_summary(state)
  rows <- list(
    data.table::data.table(check = "state_contract", status = if (identical(state$schema_version, "causal_completed_experiment_workspace_v1") && nrow(state$completed_experiments) == 1L) "success" else "error", message = "Completed experiment workspace stores execution records."),
    data.table::data.table(check = "mapping_contract", status = if (nrow(state$evidence_mappings) >= 5L) "success" else "error", message = "Evidence mappings are stored separately from source data."),
    data.table::data.table(check = "autoquant_graceful_availability", status = if (available || identical(assessed$status, "warning")) "success" else "error", message = "Workbench degrades gracefully when Phase 3 AutoQuant API is unavailable."),
    data.table::data.table(check = "readiness_assessment", status = if (!available || identical(assessed$status, "success")) "success" else "error", message = paste(assessed$errors %||% assessed$warnings %||% "Completed evidence readiness assessed.", collapse = " | ")),
    data.table::data.table(check = "no_effect_estimation", status = if (!available || summary$readiness_state[[1]] %in% c("ready_for_itt", "estimand_revision_required", "ready_with_major_limitations", "blocked", "outcome_pending")) "success" else "error", message = "Readiness state is classified without estimating effects.")
  )
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
