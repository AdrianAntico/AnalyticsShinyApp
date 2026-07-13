causal_experiment_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_experiment_question",
      "aq_experiment_design_spec",
      "aq_assignment_plan",
      "aq_assess_assignment_balance",
      "aq_power_plan",
      "aq_experiment_timing_plan",
      "aq_measurement_plan",
      "aq_validity_threat_register",
      "aq_interference_plan",
      "aq_experiment_gate_assessment",
      "aq_experiment_information_value",
      "aq_experiment_plan_artifact"
    ) %in% getNamespaceExports("AutoQuant"))
}

causal_experiment_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "causal_experiment_workspace_v1",
    project_id = project_id,
    active_experiment_question_id = NA_character_,
    experiment_questions = data.table::data.table(),
    design_specs = data.table::data.table(),
    plans = list(),
    artifact_registry = character(),
    history = data.table::data.table(
      event_id = character(),
      experiment_question_id = character(),
      record_type = character(),
      record_id = character(),
      event_type = character(),
      signature = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

causal_experiment_tables <- function() c("experiment_questions", "design_specs")

causal_experiment_normalize <- function(state) {
  state <- state %||% causal_experiment_empty()
  empty <- causal_experiment_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (table_name in causal_experiment_tables()) {
    if (!data.table::is.data.table(state[[table_name]])) state[[table_name]] <- data.table::as.data.table(state[[table_name]])
  }
  if (!data.table::is.data.table(state$history)) state$history <- data.table::as.data.table(state$history)
  state
}

causal_experiment_active_id <- function(state) {
  state <- causal_experiment_normalize(state)
  id <- state$active_experiment_question_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$experiment_questions)) state$experiment_questions$experiment_question_id[[1]] else NA_character_
}

causal_experiment_now <- function() as.character(Sys.time())

causal_experiment_event <- function(experiment_question_id, record_type, record_id, event_type, signature, summary) {
  data.table::data.table(
    event_id = paste0("causal_experiment_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    experiment_question_id = experiment_question_id %||% NA_character_,
    record_type = record_type,
    record_id = record_id %||% NA_character_,
    event_type = event_type,
    signature = signature %||% NA_character_,
    summary = summary %||% "",
    timestamp = causal_experiment_now()
  )
}

causal_experiment_rows <- function(state, table_name, experiment_question_id = NULL) {
  state <- causal_experiment_normalize(state)
  rows <- state[[table_name]]
  if (!nrow(rows) || is.null(experiment_question_id) || !nzchar(experiment_question_id %||% "")) return(rows)
  target_id <- experiment_question_id
  if ("experiment_question_id" %in% names(rows)) rows[experiment_question_id == target_id] else rows
}

causal_experiment_signature <- function(state, experiment_question_id = causal_experiment_active_id(state)) {
  state <- causal_experiment_normalize(state)
  pieces <- lapply(causal_experiment_tables(), function(table_name) {
    rows <- causal_experiment_rows(state, table_name, experiment_question_id)
    paste(table_name, nrow(rows), paste(rows$updated_at %||% character(), collapse = ","), sep = ":")
  })
  paste(experiment_question_id %||% "", paste(pieces, collapse = "|"), sep = "::")
}

causal_experiment_upsert_row <- function(state, table_name, id_col, row, experiment_question_id = row$experiment_question_id %||% NA_character_, event_type = NULL) {
  state <- causal_experiment_normalize(state)
  if (!table_name %in% causal_experiment_tables()) return(service_result(status = "error", errors = paste("Unsupported experiment table:", table_name)))
  row <- data.table::as.data.table(row)
  if (!id_col %in% names(row) || !nzchar(row[[id_col]][[1]] %||% "")) return(service_result(status = "error", errors = paste(id_col, "is required.")))
  row[, updated_at := causal_experiment_now()]
  if (!"created_at" %in% names(row)) row[, created_at := updated_at]
  existing <- state[[table_name]]
  record_id <- row[[id_col]][[1]]
  was_existing <- nrow(existing) && record_id %in% existing[[id_col]]
  if (was_existing) {
    old <- existing[get(id_col) == record_id][1]
    row[, created_at := old$created_at %||% updated_at]
    existing <- existing[get(id_col) != record_id]
  }
  state[[table_name]] <- data.table::rbindlist(list(existing, row), use.names = TRUE, fill = TRUE)
  if (identical(table_name, "experiment_questions")) state$active_experiment_question_id <- record_id
  signature <- causal_experiment_signature(state, experiment_question_id)
  state$history <- data.table::rbindlist(list(state$history, causal_experiment_event(experiment_question_id, table_name, record_id, event_type %||% if (was_existing) "modified" else "created", signature, paste(if (was_existing) "Modified" else "Created", table_name, record_id))), use.names = TRUE, fill = TRUE)
  state$plans[[experiment_question_id]]$stale <- TRUE
  service_result(status = "success", value = state, messages = paste("Saved", table_name, record_id), metadata = list(experiment_question_id = experiment_question_id, signature = signature))
}

causal_experiment_parse_list <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) character()
  trimws(strsplit(x, ",", fixed = TRUE)[[1]])
}

causal_experiment_build_plan <- function(state, causal_state = causal_intelligence_empty(), eligible_units = NULL) {
  if (!causal_experiment_available()) return(service_result(status = "warning", warnings = "AutoQuant causal experiment-design API is unavailable in the current R library. Install the updated AutoQuant package to run experiment design planning."))
  state <- causal_experiment_normalize(state)
  experiment_question_id <- causal_experiment_active_id(state)
  eq_rows <- causal_experiment_rows(state, "experiment_questions", experiment_question_id)
  design_rows <- causal_experiment_rows(state, "design_specs", experiment_question_id)
  if (!nrow(eq_rows)) return(service_result(status = "error", errors = "No experiment question exists."))
  if (!nrow(design_rows)) return(service_result(status = "error", errors = "No experiment design specification exists."))
  causal_context <- NULL
  context_result <- tryCatch(causal_intelligence_build_autoquant(causal_state), error = function(e) NULL)
  if (is.list(context_result) && identical(context_result$status, "success")) causal_context <- context_result$value
  eq_row <- eq_rows[1]
  design_row <- design_rows[1]
  experiment_question <- tryCatch(AutoQuant::aq_experiment_question(eq_row, causal_context = causal_context), error = function(e) e)
  if (inherits(experiment_question, "error")) return(service_result(status = "error", errors = conditionMessage(experiment_question)))
  design <- tryCatch(AutoQuant::aq_experiment_design_spec(
    experiment_question,
    design_type = design_row$design_type[[1]],
    assignment_unit = design_row$assignment_unit[[1]],
    analysis_unit = design_row$analysis_unit[[1]],
    treatment_delivery_unit = design_row$treatment_delivery_unit[[1]],
    cluster_unit = design_row$cluster_unit[[1]],
    blocking_variables = causal_experiment_parse_list(design_row$blocking_variables[[1]]),
    stratification_variables = causal_experiment_parse_list(design_row$stratification_variables[[1]]),
    number_of_arms = as.integer(design_row$number_of_arms[[1]] %||% 2L),
    pre_period = design_row$pre_period[[1]],
    treatment_period = design_row$treatment_period[[1]],
    follow_up_period = design_row$follow_up_period[[1]],
    washout_period = design_row$washout_period[[1]],
    contamination_risks = causal_experiment_parse_list(design_row$contamination_risks[[1]]),
    interference_assumptions = design_row$interference_assumptions[[1]] %||% "not yet assessed"
  ), error = function(e) e)
  if (inherits(design, "error")) return(service_result(status = "error", errors = conditionMessage(design)))

  units <- if (is.null(eligible_units)) {
    data.table::data.table(unit_id = character())
  } else {
    units_dt <- data.table::as.data.table(eligible_units)
    if (!"unit_id" %in% names(units_dt)) units_dt[, unit_id := paste0("row_", seq_len(.N))]
    units_dt
  }
  assignment <- AutoQuant::aq_assignment_plan(design, units)
  balance <- AutoQuant::aq_assess_assignment_balance(assignment, units)
  power <- AutoQuant::aq_power_plan(outcome_type = "continuous", baseline_sd = suppressWarnings(as.numeric(eq_row$baseline_sd[[1]])), minimum_detectable_effect = suppressWarnings(as.numeric(eq_row$minimum_detectable_effect[[1]])))
  timing <- AutoQuant::aq_experiment_timing_plan(treatment_duration_days = suppressWarnings(as.integer(eq_row$treatment_duration_days[[1]] %||% NA_integer_)), outcome_maturation_days = suppressWarnings(as.integer(eq_row$outcome_maturation_days[[1]] %||% 0L)), reporting_delay_days = suppressWarnings(as.integer(eq_row$reporting_delay_days[[1]] %||% 0L)))
  measurement <- AutoQuant::aq_measurement_plan(eq_row$primary_outcome[[1]], guardrails = causal_experiment_parse_list(eq_row$guardrails[[1]]), exposure_verification = eq_row$exposure_verification[[1]], compliance_measure = eq_row$compliance_measure[[1]], treatment_receipt = eq_row$treatment_receipt[[1]], data_source = eq_row$data_source[[1]], owner = eq_row$owner[[1]])
  threats <- AutoQuant::aq_validity_threat_register(design_spec = design, measurement_plan = measurement)
  interference <- AutoQuant::aq_interference_plan(eq_row$interference_mode[[1]] %||% "no_interference_assumed", design)
  info <- AutoQuant::aq_experiment_information_value(eq_row$decision_sensitivity[[1]] %||% "unknown", eq_row$lever_importance[[1]] %||% "unknown", experiment_cost = suppressWarnings(as.numeric(eq_row$experiment_cost[[1]])), duration_days = suppressWarnings(as.integer(eq_row$duration_days[[1]])), reversibility = isTRUE(eq_row$reversibility[[1]] %in% c(TRUE, "TRUE", "true", "yes")))
  gate <- AutoQuant::aq_experiment_gate_assessment(experiment_question, design, assignment, power, measurement, threats, authority_approved = isTRUE(eq_row$authority_approved[[1]] %in% c(TRUE, "TRUE", "true", "yes")), coverage_approved = isTRUE(eq_row$coverage_approved[[1]] %in% c(TRUE, "TRUE", "true", "yes")), information_value = info)
  artifact <- AutoQuant::aq_experiment_plan_artifact(experiment_question, design, assignment, power, timing, measurement, threats, interference, gate, info)
  plan <- list(experiment_question = experiment_question, design = design, assignment = assignment, balance = balance, power = power, timing = timing, measurement = measurement, threats = threats, interference = interference, information_value = info, gate = gate, aq_artifact = artifact)
  signature <- causal_experiment_signature(state, experiment_question_id)
  state$plans[[experiment_question_id]] <- c(plan, list(signature = signature, stale = FALSE, planned_at = causal_experiment_now()))
  state$history <- data.table::rbindlist(list(state$history, causal_experiment_event(experiment_question_id, "plan", experiment_question_id, "planned", signature, "Generated governed experiment design plan with AutoQuant")), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = "Experiment design plan generated.", metadata = list(experiment_question_id = experiment_question_id, gate_status = gate$gate_status[[1]], execution_ready = FALSE))
}

causal_experiment_summary <- function(state) {
  state <- causal_experiment_normalize(state)
  experiment_question_id <- causal_experiment_active_id(state)
  plan <- state$plans[[experiment_question_id]]
  data.table::data.table(
    experiment_questions = nrow(state$experiment_questions),
    design_specs = nrow(state$design_specs),
    plan_status = if (is.null(plan)) "not_planned" else if (!identical(plan$signature, causal_experiment_signature(state, experiment_question_id))) "stale" else "current",
    gate_status = if (is.null(plan)) "not_planned" else plan$gate$gate_status[[1]] %||% "unknown",
    execution_ready = FALSE,
    registered_artifacts = length(state$artifact_registry %||% character())
  )
}

causal_experiment_register_artifact <- function(ctx, state, experiment_question_id = causal_experiment_active_id(state)) {
  state <- causal_experiment_normalize(state)
  plan <- state$plans[[experiment_question_id]]
  if (is.null(plan) || isTRUE(plan$stale) || !identical(plan$signature, causal_experiment_signature(state, experiment_question_id))) return(service_result(status = "error", errors = "Generate a current experiment design plan before registering artifacts."))
  artifact_id <- paste("causal_experiment", experiment_question_id, "plan", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) return(service_result(status = "success", messages = "No duplicate experiment plan artifact was registered."))
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Governed Experiment Plan",
      source_module = "causal_intelligence",
    object = plan$gate,
    content = "Governed experiment design plan. No treatment executed and no effect estimated.",
    metadata = list(
      module_id = "causal_intelligence",
      module_run_id = paste0("causal_experiment_", format(Sys.time(), "%Y%m%d%H%M%S")),
      analytical_intent = "Experiment Design Planning",
      artifact_importance = "critical",
      caption = paste("Governed experiment plan for", experiment_question_id),
      diagnostics = c(plan$threats$threat, plan$gate$warnings),
      recommendations = c(plan$gate$recommendation, plan$information_value$recommendation),
      experiment_question_id = experiment_question_id,
      design_type = plan$design$design_type,
      gate_status = plan$gate$gate_status[[1]],
      no_treatment_executed = TRUE,
      no_effect_estimated = TRUE,
      prohibited_claims = plan$aq_artifact$metadata$prohibited_claims %||% character(),
      signature = plan$signature
    ),
    section = "Causal Intelligence",
    order = 2L
  )
  result <- service_result(status = "success", artifacts = list(artifact), messages = "Experiment design artifact registered.", metadata = list(module_id = "causal_intelligence", module_run_id = artifact$metadata$module_run_id, artifact_count = 1L))
  names(result$artifacts) <- artifact_id
  collector <- ctx$append_module_result_to_collector(result, module_id = "causal_intelligence", record_skipped = FALSE)
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry %||% character(), artifact_id))
  ctx$causal_experiment_state(state)
  collector
}

qa_causal_experiment_design_workspace <- function() {
  fixture <- causal_intelligence_fixture()
  state <- causal_experiment_empty("causal_experiment_fixture")
  state <- causal_experiment_upsert_row(state, "experiment_questions", "experiment_question_id", data.table::data.table(
    experiment_question_id = "eq_paid_search_test",
    causal_question_id = "cq_paid_search_revenue",
    decision_context_id = "decision_next_quarter_budget",
    hypothesis = "Increasing eligible paid-search budget raises revenue.",
    null_claim = "No revenue lift.",
    alternative_claim = "Revenue lift is positive.",
    treatment = "approved paid-search budget increase",
    comparison = "current spend range",
    estimand = "ATE",
    assignment_population = "eligible customer segments",
    expected_mechanism = "More qualified traffic increases revenue.",
    primary_outcome = "revenue",
    guardrails = "cpa,customer_quality",
    decision_rule = "Roll out if lift exceeds cost and guardrails hold.",
    authority = "marketing_approval",
    coverage = "eligible_segments",
    exposure_verification = "spend delivery logs",
    compliance_measure = "budget adherence",
    treatment_receipt = "delivered spend",
    data_source = "project data",
    owner = "analytics",
    baseline_sd = 12,
    minimum_detectable_effect = 5,
    treatment_duration_days = 28,
    outcome_maturation_days = 14,
    reporting_delay_days = 7,
    decision_sensitivity = "high",
    lever_importance = "high",
    authority_approved = TRUE,
    coverage_approved = TRUE,
    interference_mode = "no_interference_assumed"
  ), "eq_paid_search_test")$value
  state <- causal_experiment_upsert_row(state, "design_specs", "design_id", data.table::data.table(
    experiment_question_id = "eq_paid_search_test",
    design_id = "design_paid_search",
    design_type = "stratified_randomized",
    assignment_unit = "segment",
    treatment_delivery_unit = "segment",
    analysis_unit = "segment-week",
    cluster_unit = "",
    stratification_variables = "customer_segment",
    blocking_variables = "",
    number_of_arms = 2L,
    pre_period = "eight weeks",
    treatment_period = "four weeks",
    follow_up_period = "two weeks",
    washout_period = "",
    contamination_risks = "",
    interference_assumptions = "no cross-segment spillover expected"
  ), "eq_paid_search_test")$value
  available <- causal_experiment_available()
  planned <- if (available) causal_experiment_build_plan(state, fixture$state, eligible_units = data.table::data.table(unit_id = paste0("unit_", seq_len(20L)))) else service_result(status = "warning", warnings = "AutoQuant experiment API unavailable for graceful QA.")
  summary <- if (identical(planned$status, "success")) causal_experiment_summary(planned$value) else causal_experiment_summary(state)
  rows <- list(
    data.table::data.table(check = "state_contract", status = if (identical(state$schema_version, "causal_experiment_workspace_v1") && nrow(state$experiment_questions) == 1L) "success" else "error", message = "Experiment design workspace stores authored questions."),
    data.table::data.table(check = "design_spec_records", status = if (nrow(state$design_specs) == 1L) "success" else "error", message = "Design specifications are persisted separately from causal questions."),
    data.table::data.table(check = "autoquant_graceful_availability", status = if (available || identical(planned$status, "warning")) "success" else "error", message = "Workbench degrades gracefully when the Phase 2 AutoQuant API is not installed."),
    data.table::data.table(check = "plan_generation", status = if (!available || identical(planned$status, "success")) "success" else "error", message = paste(planned$errors %||% planned$warnings %||% "Experiment design plan generated.", collapse = " | ")),
    data.table::data.table(check = "execution_boundary", status = if (identical(summary$execution_ready[[1]], FALSE)) "success" else "error", message = "Experiment design plans never appear treatment-execution ready.")
  )
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
