causal_itt_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_randomized_itt_spec",
      "aq_validate_randomized_itt_readiness",
      "aq_estimate_randomized_itt",
      "aq_randomized_itt_effect_artifact",
      "aq_review_randomized_itt_result",
      "aq_randomized_itt_campaign_seeds"
    ) %in% getNamespaceExports("AutoQuant"))
}

causal_randomized_depth_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_randomized_design_analysis_spec",
      "aq_analyze_randomized_design_depth",
      "aq_randomized_causal_effect_report"
    ) %in% getNamespaceExports("AutoQuant"))
}

causal_itt_parse_csv <- function(x) {
  x <- x %||% character()
  x <- unlist(strsplit(paste(x, collapse = ","), ",", fixed = TRUE), use.names = FALSE)
  unique(trimws(x[nzchar(trimws(x))]))
}

causal_itt_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "causal_itt_workspace_v1",
    project_id = project_id,
    active_analysis_id = NA_character_,
    specs = data.table::data.table(
      analysis_id = character(),
      completed_experiment_id = character(),
      treatment_arm = character(),
      comparison_arm = character(),
      outcome = character(),
      outcome_type = character(),
      baseline_covariates = character(),
      cluster_variable = character(),
      standard_error_method = character(),
      minimum_meaningful_effect = numeric(),
      design_type = character(),
      analysis_modes = character(),
      block_fields = character(),
      stratum_fields = character(),
      period_field = character(),
      cluster_unit = character(),
      pre_period_fields = character(),
      factorial_terms = character(),
      material_benefit = numeric(),
      material_harm = numeric(),
      updated_at = character()
    ),
    results = list(),
    artifact_registry = character(),
    history = data.table::data.table(
      event_id = character(),
      analysis_id = character(),
      event_type = character(),
      signature = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

causal_itt_now <- function() as.character(Sys.time())

causal_itt_normalize <- function(state) {
  state <- state %||% causal_itt_empty()
  empty <- causal_itt_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (name in c("specs", "history")) {
    if (!data.table::is.data.table(state[[name]])) state[[name]] <- data.table::as.data.table(state[[name]])
  }
  state
}

causal_itt_active_id <- function(state) {
  state <- causal_itt_normalize(state)
  id <- state$active_analysis_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$specs)) state$specs$analysis_id[[1]] else NA_character_
}

causal_itt_signature <- function(state, completed_state = NULL, analysis_id = causal_itt_active_id(state)) {
  state <- causal_itt_normalize(state)
  spec <- state$specs[state$specs$analysis_id == analysis_id]
  completed_signature <- if (!is.null(completed_state)) {
    tryCatch(causal_completed_experiment_signature(completed_state), error = function(e) "")
  } else ""
  paste(
    analysis_id %||% "",
    nrow(spec),
    paste(spec$updated_at %||% character(), collapse = ","),
    completed_signature,
    sep = "::"
  )
}

causal_itt_event <- function(analysis_id, event_type, signature, summary) {
  data.table::data.table(
    event_id = paste0("causal_itt_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    analysis_id = analysis_id %||% NA_character_,
    event_type = event_type,
    signature = signature %||% NA_character_,
    summary = summary %||% "",
    timestamp = causal_itt_now()
  )
}

causal_itt_upsert_spec <- function(state, row) {
  state <- causal_itt_normalize(state)
  row <- data.table::as.data.table(row)
  if (!"analysis_id" %in% names(row) || !nzchar(row$analysis_id[[1]] %||% "")) {
    row[, analysis_id := paste0("itt_analysis_", format(Sys.time(), "%Y%m%d%H%M%S"))]
  }
  for (field in c("completed_experiment_id", "treatment_arm", "comparison_arm", "outcome", "outcome_type")) {
    if (!field %in% names(row) || !nzchar(row[[field]][[1]] %||% "")) return(service_result(status = "error", errors = paste(field, "is required.")))
  }
  row[, updated_at := causal_itt_now()]
  id <- row$analysis_id[[1]]
  state$specs <- state$specs[analysis_id != id]
  state$specs <- data.table::rbindlist(list(state$specs, row), use.names = TRUE, fill = TRUE)
  state$active_analysis_id <- id
  existing_result <- state$results[[id]] %||% list()
  existing_result$stale <- TRUE
  state$results[[id]] <- existing_result
  signature <- causal_itt_signature(state, analysis_id = id)
  state$history <- data.table::rbindlist(list(state$history, causal_itt_event(id, "itt_spec_saved", signature, paste("Saved ITT spec", id))), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = paste("Saved ITT analysis spec", id), metadata = list(analysis_id = id, signature = signature))
}

causal_itt_baseline_data <- function(data, completed_state, spec_row) {
  dt <- data.table::as.data.table(data %||% data.table::data.table())
  if (!nrow(dt)) return(data.table::data.table())
  completed_id <- causal_completed_experiment_active_id(completed_state)
  unit_col <- causal_completed_experiment_get_col(completed_state, completed_id, "unit_id", "unit_id")
  covars <- causal_itt_parse_csv(spec_row$baseline_covariates[[1]] %||% "")
  cluster <- spec_row$cluster_variable[[1]] %||% ""
  keep <- unique(c(unit_col, covars, cluster))
  keep <- keep[nzchar(keep) & keep %in% names(dt)]
  if (!length(keep) || !unit_col %in% keep) return(data.table::data.table())
  out <- data.table::copy(dt[, keep, with = FALSE])
  if (!identical(unit_col, "unit_id")) data.table::setnames(out, unit_col, "unit_id")
  out
}

causal_itt_build_autoquant <- function(state, completed_state, data = NULL) {
  if (!causal_itt_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant randomized ITT API is unavailable in the current R library. Install the updated AutoQuant package to run Phase 4 estimation."))
  }
  state <- causal_itt_normalize(state)
  completed_state <- causal_completed_experiment_normalize(completed_state)
  analysis_id <- causal_itt_active_id(state)
  spec_row <- state$specs[state$specs$analysis_id == analysis_id][1]
  if (!nrow(spec_row)) return(service_result(status = "error", errors = "No ITT analysis spec exists."))
  completed_id <- causal_completed_experiment_active_id(completed_state)
  assessment <- completed_state$assessments[[completed_id]]
  if (is.null(assessment) || !identical(assessment$signature, causal_completed_experiment_signature(completed_state, completed_id))) {
    return(service_result(status = "error", errors = "Assess current completed-experiment readiness before running ITT estimation."))
  }
  baseline_data <- causal_itt_baseline_data(data, completed_state, spec_row)
  planned <- assessment$planned_analysis
  if (!is.null(planned) && nzchar(spec_row$baseline_covariates[[1]] %||% "")) {
    planned$baseline_covariates <- spec_row$baseline_covariates[[1]]
  }
  completed_record <- data.table::as.data.table(assessment$completed$record %||% data.table::data.table())
  spec <- AutoQuant::aq_randomized_itt_spec(
    analysis_id = analysis_id,
    completed_experiment_id = spec_row$completed_experiment_id[[1]],
    experiment_plan_artifact_id = completed_record$experiment_plan_artifact_id[[1]] %||% "",
    causal_question_id = completed_record$causal_question_id[[1]] %||% "",
    estimand_id = completed_record$estimand_id[[1]] %||% "",
    treatment_arm = spec_row$treatment_arm[[1]],
    comparison_arm = spec_row$comparison_arm[[1]],
    outcome = spec_row$outcome[[1]],
    outcome_type = spec_row$outcome_type[[1]],
    baseline_covariates = causal_itt_parse_csv(spec_row$baseline_covariates[[1]] %||% ""),
    cluster_variable = spec_row$cluster_variable[[1]] %||% NA_character_,
    standard_error_method = spec_row$standard_error_method[[1]] %||% "welch",
    minimum_meaningful_effect = suppressWarnings(as.numeric(spec_row$minimum_meaningful_effect[[1]]))
  )
  result <- AutoQuant::aq_estimate_randomized_itt(
    spec,
    completed_evidence = assessment,
    baseline_data = baseline_data,
    planned_analysis = planned
  )
  depth <- NULL
  report <- NULL
  depth_message <- "Phase 5 randomized design-depth API is unavailable."
  if (isTRUE(result$effect_estimated) && causal_randomized_depth_available()) {
    design_type <- spec_row$design_type[[1]] %||% "completely_randomized"
    if (is.na(design_type) || !nzchar(design_type)) design_type <- "completely_randomized"
    modes_value <- spec_row$analysis_modes[[1]] %||% "unadjusted,ancova"
    if (is.na(modes_value) || !nzchar(modes_value)) modes_value <- "unadjusted,ancova"
    modes <- causal_itt_parse_csv(modes_value)
    cluster_unit <- spec_row$cluster_unit[[1]] %||% spec_row$cluster_variable[[1]] %||% NA_character_
    if (is.na(cluster_unit) || !nzchar(cluster_unit)) cluster_unit <- NA_character_
    period_field <- spec_row$period_field[[1]] %||% NA_character_
    if (is.na(period_field) || !nzchar(period_field)) period_field <- NA_character_
    design_spec <- AutoQuant::aq_randomized_design_analysis_spec(
      itt_analysis_id = analysis_id,
      design_type = design_type,
      analysis_modes = modes,
      block_fields = causal_itt_parse_csv(spec_row$block_fields[[1]] %||% ""),
      stratum_fields = causal_itt_parse_csv(spec_row$stratum_fields[[1]] %||% ""),
      period_field = period_field,
      cluster_unit = cluster_unit,
      pre_period_fields = causal_itt_parse_csv(spec_row$pre_period_fields[[1]] %||% ""),
      factorial_terms = causal_itt_parse_csv(spec_row$factorial_terms[[1]] %||% ""),
      material_benefit = suppressWarnings(as.numeric(spec_row$material_benefit[[1]] %||% spec_row$minimum_meaningful_effect[[1]])),
      material_harm = suppressWarnings(as.numeric(spec_row$material_harm[[1]] %||% -abs(as.numeric(spec_row$minimum_meaningful_effect[[1]] %||% NA_real_))))
    )
    depth <- AutoQuant::aq_analyze_randomized_design_depth(result, design_spec, source_data = data)
    report <- AutoQuant::aq_randomized_causal_effect_report(result, depth)
    depth_message <- "Randomized design-depth evidence and causal report contract generated."
  }
  service_result(status = "success", value = list(spec = spec, result = result, design_depth = depth, causal_report = report, baseline_data = baseline_data, planned_analysis = planned), messages = paste("Randomized ITT analysis evaluated.", depth_message), metadata = list(analysis_id = analysis_id, effect_estimated = isTRUE(result$effect_estimated), design_depth = !is.null(depth), causal_report = !is.null(report)))
}

causal_itt_run <- function(state, completed_state, data = NULL) {
  state <- causal_itt_normalize(state)
  built <- causal_itt_build_autoquant(state, completed_state, data)
  if (!identical(built$status, "success")) return(built)
  analysis_id <- causal_itt_active_id(state)
  signature <- causal_itt_signature(state, completed_state, analysis_id)
  state$results[[analysis_id]] <- c(built$value, list(signature = signature, stale = FALSE, reviewed = FALSE, review_status = "review_required", run_at = causal_itt_now()))
  state$history <- data.table::rbindlist(list(state$history, causal_itt_event(analysis_id, "itt_analysis_run", signature, if (isTRUE(built$value$result$effect_estimated)) "ITT effect estimated." else "ITT analysis blocked by readiness gate.")), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = built$messages, metadata = c(built$metadata, list(signature = signature)))
}

causal_itt_review <- function(state, approve = TRUE, reviewer = "user") {
  if (!causal_itt_available()) return(service_result(status = "warning", warnings = "AutoQuant randomized ITT API is unavailable."))
  state <- causal_itt_normalize(state)
  analysis_id <- causal_itt_active_id(state)
  record <- state$results[[analysis_id]]
  if (is.null(record) || is.null(record$result) || !isTRUE(record$result$effect_estimated)) {
    return(service_result(status = "error", errors = "Run a successful ITT analysis before review."))
  }
  reviewed <- AutoQuant::aq_review_randomized_itt_result(record$result, reviewer = reviewer, approve = approve)
  record$review <- reviewed
  record$reviewed <- TRUE
  record$review_status <- reviewed$status %||% if (isTRUE(approve)) "approved_evidence" else "rejected"
  state$results[[analysis_id]] <- record
  state$history <- data.table::rbindlist(list(state$history, causal_itt_event(analysis_id, "itt_result_reviewed", record$signature, paste("Review:", record$review_status))), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = paste("ITT result review recorded:", record$review_status), metadata = list(analysis_id = analysis_id, review_status = record$review_status))
}

causal_itt_summary <- function(state) {
  state <- causal_itt_normalize(state)
  analysis_id <- causal_itt_active_id(state)
  record <- state$results[[analysis_id]]
  result <- record$result %||% NULL
  primary <- result$primary_estimate %||% data.table::data.table()
  materiality <- result$materiality %||% data.table::data.table()
  data.table::data.table(
    specs = nrow(state$specs),
    active_analysis_id = analysis_id %||% NA_character_,
    analysis_status = if (is.null(result)) "not_run" else result$status %||% "unknown",
    effect_estimated = isTRUE(result$effect_estimated),
    review_status = record$review_status %||% "not_reviewed",
    estimate = if (nrow(primary)) primary$estimate[[1]] else NA_real_,
    conf_low = if (nrow(primary)) primary$conf_low[[1]] else NA_real_,
    conf_high = if (nrow(primary)) primary$conf_high[[1]] else NA_real_,
    materiality_state = if (nrow(materiality)) materiality$materiality_state[[1]] else "not_assessed",
    registered_artifacts = length(state$artifact_registry %||% character()),
    design_depth_status = if (is.null(record$design_depth)) "not_available" else record$design_depth$status %||% "unknown",
    causal_report_status = if (is.null(record$causal_report)) "not_available" else "available",
    robustness_rows = nrow(record$design_depth$robustness_matrix %||% data.table::data.table())
  )
}

causal_itt_campaign_seeds <- function(state) {
  state <- causal_itt_normalize(state)
  analysis_id <- causal_itt_active_id(state)
  record <- state$results[[analysis_id]]
  if (!causal_itt_available()) return(data.table::data.table(seed_type = "itt_api_unavailable", severity = "medium", recommendation = "Install the updated AutoQuant package to use randomized ITT campaign seeds."))
  if (is.null(record) || is.null(record$result)) return(data.table::data.table(seed_type = "itt_analysis_missing", severity = "medium", recommendation = "Run ITT estimation after completed-experiment readiness is current."))
  if (!isTRUE(record$result$effect_estimated)) return(data.table::data.table(seed_type = "itt_blocked", severity = "high", recommendation = "Resolve readiness blockers before treating the experiment as decision evidence."))
  AutoQuant::aq_randomized_itt_campaign_seeds(record$result)
}

causal_itt_register_artifact <- function(ctx, state) {
  if (!causal_itt_available()) return(service_result(status = "warning", warnings = "AutoQuant randomized ITT API is unavailable."))
  state <- causal_itt_normalize(state)
  analysis_id <- causal_itt_active_id(state)
  record <- state$results[[analysis_id]]
  if (is.null(record) || is.null(record$result) || !isTRUE(record$result$effect_estimated)) return(service_result(status = "error", errors = "Run a successful ITT analysis before registering an effect artifact."))
  artifact_id <- paste("causal_itt", analysis_id, "effect", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) return(service_result(status = "success", messages = "No duplicate ITT effect artifact was registered."))
  aq_artifact <- AutoQuant::aq_randomized_itt_effect_artifact(record$result)
  primary <- record$result$primary_estimate
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Randomized ITT Effect",
    source_module = "causal_intelligence",
    object = primary,
    content = "Governed randomized intent-to-treat effect evidence.",
    metadata = list(
      module_id = "causal_intelligence",
      module_run_id = paste0("causal_itt_", format(Sys.time(), "%Y%m%d%H%M%S")),
      analytical_intent = "Causal ITT Effect",
      artifact_importance = "critical",
      caption = paste("Randomized ITT effect for", record$result$spec$outcome),
      diagnostics = c(record$result$gate$reason, record$result$guardrails$finding),
      recommendations = c(record$result$materiality$recommendation, record$result$guardrails$recommendation),
      analysis_id = analysis_id,
      completed_experiment_id = record$result$spec$completed_experiment_id,
      effect_scale = primary$effect_scale[[1]] %||% NA_character_,
      estimate = primary$estimate[[1]] %||% NA_real_,
      conf_low = primary$conf_low[[1]] %||% NA_real_,
      conf_high = primary$conf_high[[1]] %||% NA_real_,
      materiality_state = record$result$materiality$materiality_state[[1]] %||% NA_character_,
      review_status = record$review_status %||% "not_reviewed",
      aq_artifact_schema = aq_artifact$schema_version %||% NA_character_,
      prohibited_claims = record$result$prohibited_claims
    ),
    section = "Causal Intelligence",
    order = 4L
  )
  result <- service_result(status = "success", artifacts = list(artifact), messages = "Randomized ITT effect artifact registered.", metadata = list(module_id = "causal_intelligence", module_run_id = artifact$metadata$module_run_id, artifact_count = 1L))
  names(result$artifacts) <- artifact_id
  collector <- ctx$append_module_result_to_collector(result, module_id = "causal_intelligence", record_skipped = FALSE)
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry %||% character(), artifact_id))
  ctx$causal_itt_state(state)
  collector
}

qa_causal_itt_workspace <- function() {
  set.seed(20260713)
  rows <- list()
  add <- function(check, status, message) rows[[length(rows) + 1L]] <<- data.table::data.table(check, status, message)
  state <- causal_itt_empty("causal_itt_fixture")
  completed <- causal_completed_experiment_empty("causal_itt_fixture")
  completed <- causal_completed_experiment_upsert_completed(completed, data.table::data.table(
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
  completed <- causal_completed_experiment_save_mappings(completed, "ce_paid_search_test", data.table::data.table(
    evidence_role = c("unit_id", "planned_arm", "realized_assigned_arm", "delivered_condition", "primary_outcome", "guardrail"),
    source_column = c("unit_id", "planned_arm", "realized_assigned_arm", "delivered_condition", "revenue", "cost_guardrail")
  ))$value
  data <- data.table::data.table(
    unit_id = paste0("u", 1:40),
    planned_arm = rep(c("control", "treatment"), each = 20),
    realized_assigned_arm = rep(c("control", "treatment"), each = 20),
    delivered_condition = rep(c("control", "treatment"), each = 20),
    revenue = c(seq(10, 29), seq(14, 33)),
    baseline_y = rnorm(40),
    cluster = rep(paste0("geo", 1:4), each = 10),
    cost_guardrail = 0
  )
  available <- causal_itt_available() && causal_completed_experiment_available()
  assessed <- if (available) causal_completed_experiment_assess(completed, data) else service_result(status = "warning", warnings = "AutoQuant causal ITT API unavailable for graceful QA.")
  completed <- if (identical(assessed$status, "success")) assessed$value else completed
  state <- causal_itt_upsert_spec(state, data.table::data.table(
    analysis_id = "itt_paid_search_revenue",
    completed_experiment_id = "ce_paid_search_test",
    treatment_arm = "treatment",
    comparison_arm = "control",
    outcome = "revenue",
    outcome_type = "continuous",
    baseline_covariates = "baseline_y",
    cluster_variable = "cluster",
    standard_error_method = "cluster",
    minimum_meaningful_effect = 1
  ))$value
  run <- if (available) causal_itt_run(state, completed, data) else service_result(status = "warning", warnings = "AutoQuant causal ITT API unavailable for graceful QA.")
  state <- if (identical(run$status, "success")) run$value else state
  summary <- causal_itt_summary(state)
  seeds <- causal_itt_campaign_seeds(state)
  add("state_contract", if (identical(state$schema_version, "causal_itt_workspace_v1") && nrow(state$specs) == 1L) "success" else "error", "ITT workspace stores estimator specs.")
  add("availability_graceful", if (available || identical(run$status, "warning")) "success" else "error", "Workbench degrades gracefully when AutoQuant Phase 4 API is unavailable.")
  add("readiness_gate", if (!available || identical(run$status, "success")) "success" else "error", paste(run$errors %||% run$warnings %||% "ITT readiness checked.", collapse = " | "))
  add("effect_result", if (!available || isTRUE(summary$effect_estimated[[1]])) "success" else "error", "ITT result is produced when Phase 3 readiness is compatible.")
  add("campaign_seeds", if (nrow(seeds) >= 1L) "success" else "error", "ITT campaign seeds are available for bounded follow-up.")
  add("design_depth_graceful", if (!available || !causal_randomized_depth_available() || !is.null(state$results[[causal_itt_active_id(state)]]$design_depth)) "success" else "error", "Phase 5 design-depth evidence is generated when the updated AutoQuant API is installed.")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
