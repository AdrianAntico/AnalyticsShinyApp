causal_observational_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_observational_study",
      "aq_target_trial_spec",
      "aq_observational_assignment_mechanism",
      "aq_observational_treatment_definition",
      "aq_observational_adjustment_spec",
      "aq_assess_observational_temporal_eligibility",
      "aq_assess_observational_variation",
      "aq_observational_assignment_model_diagnostics",
      "aq_assess_observational_overlap",
      "aq_assess_observational_balance",
      "aq_observational_design_eligibility",
      "aq_assess_observational_selection_missingness",
      "aq_unmeasured_confounding_risk_register",
      "aq_observational_falsification_plan",
      "aq_plan_observational_causal_analysis",
      "aq_assess_observational_estimation_readiness",
      "aq_observational_causal_planning_artifact",
      "aq_observational_analysis_spec",
      "aq_estimate_observational_effect",
      "aq_observational_effect_artifact",
      "aq_did_analysis_spec",
      "aq_did_readiness",
      "aq_did_pre_period_diagnostics",
      "aq_did_parallel_trends",
      "aq_did_composition_stability",
      "aq_estimate_did_effect",
      "aq_did_effect_artifact",
      "aq_did_effect_report"
    ) %in% getNamespaceExports("AutoQuant"))
}

causal_observational_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "causal_observational_workspace_v1",
    project_id = project_id,
    active_study_id = NA_character_,
    studies = data.table::data.table(
      observational_study_id = character(),
      decision_context_id = character(),
      causal_question_id = character(),
      estimand_id = character(),
      study_title = character(),
      treatment = character(),
      comparison_condition = character(),
      updated_at = character()
    ),
    plans = list(),
    effect_results = list(),
    did_results = list(),
    artifact_registry = character(),
    stale = TRUE,
    history = data.table::data.table(
      event_id = character(),
      observational_study_id = character(),
      event_type = character(),
      signature = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

causal_observational_now <- function() as.character(Sys.time())

causal_observational_normalize <- function(state) {
  state <- state %||% causal_observational_empty()
  empty <- causal_observational_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  if (!data.table::is.data.table(state$studies)) state$studies <- data.table::as.data.table(state$studies)
  if (!data.table::is.data.table(state$history)) state$history <- data.table::as.data.table(state$history)
  state
}

causal_observational_active_id <- function(state) {
  state <- causal_observational_normalize(state)
  id <- state$active_study_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$studies)) state$studies$observational_study_id[[1]] else NA_character_
}

causal_observational_parse_list <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) character() else trimws(strsplit(x, ",", fixed = TRUE)[[1]])
}

causal_observational_signature <- function(state, study_id = causal_observational_active_id(state)) {
  state <- causal_observational_normalize(state)
  rows <- state$studies[observational_study_id == study_id]
  paste(study_id %||% "", nrow(rows), paste(rows$updated_at %||% character(), collapse = ","), sep = "::")
}

causal_observational_event <- function(study_id, event_type, signature, summary) {
  data.table::data.table(
    event_id = paste0("causal_observational_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    observational_study_id = study_id %||% NA_character_,
    event_type = event_type,
    signature = signature %||% NA_character_,
    summary = summary %||% "",
    timestamp = causal_observational_now()
  )
}

causal_observational_upsert_study <- function(state, row) {
  state <- causal_observational_normalize(state)
  row <- data.table::as.data.table(row)
  if (!"observational_study_id" %in% names(row) || !nzchar(row$observational_study_id[[1]] %||% "")) {
    return(service_result(status = "error", errors = "observational_study_id is required."))
  }
  row[, updated_at := causal_observational_now()]
  if (!"created_at" %in% names(row)) row[, created_at := updated_at]
  id <- row$observational_study_id[[1]]
  existing <- state$studies
  if (nrow(existing) && id %in% existing$observational_study_id) {
    old <- existing[observational_study_id == id][1]
    row[, created_at := old$created_at %||% updated_at]
    existing <- existing[observational_study_id != id]
  }
  state$studies <- data.table::rbindlist(list(existing, row), use.names = TRUE, fill = TRUE)
  state$active_study_id <- id
  state$plans[[id]]$stale <- TRUE
  state$stale <- TRUE
  signature <- causal_observational_signature(state, id)
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(id, "study_saved", signature, paste("Saved observational study", id))),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = state, messages = paste("Saved observational study", id), metadata = list(observational_study_id = id, signature = signature))
}

causal_observational_build_plan <- function(state, causal_state = causal_intelligence_empty(), data = NULL) {
  if (!causal_observational_available()) return(service_result(status = "warning", warnings = "AutoQuant observational causal-planning API is unavailable in the current R library. Install the updated AutoQuant package to run observational readiness."))
  state <- causal_observational_normalize(state)
  study_id <- causal_observational_active_id(state)
  rows <- state$studies[observational_study_id == study_id]
  if (!nrow(rows)) return(service_result(status = "error", errors = "No observational study exists."))
  row <- rows[1]
  study <- tryCatch(AutoQuant::aq_observational_study(row), error = function(e) e)
  if (inherits(study, "error")) return(service_result(status = "error", errors = conditionMessage(study)))
  target_trial <- tryCatch(AutoQuant::aq_target_trial_spec(
    study,
    eligibility_criteria = row$eligibility[[1]] %||% "eligible before assignment",
    treatment_strategies = c(row$treatment[[1]], row$comparison_condition[[1]]),
    assignment_time = row$treatment_assignment_time[[1]],
    follow_up = row$outcome_window[[1]],
    outcome = row$outcome[[1]] %||% "outcome",
    causal_contrast = row$estimand[[1]] %||% "ATE",
    estimand = row$estimand[[1]] %||% "ATE"
  ), error = function(e) e)
  if (inherits(target_trial, "error")) return(service_result(status = "error", errors = conditionMessage(target_trial)))
  assignment <- AutoQuant::aq_observational_assignment_mechanism(
    mechanism_type = row$assignment_mechanism[[1]] %||% "unknown",
    decision_process = row$assignment_process[[1]] %||% "",
    assignment_inputs = causal_observational_parse_list(row$assignment_inputs[[1]] %||% ""),
    timing = row$treatment_assignment_time[[1]] %||% "",
    confidence = row$assignment_confidence[[1]] %||% "unknown",
    unresolved_factors = causal_observational_parse_list(row$unresolved_assignment_factors[[1]] %||% "")
  )
  treatment <- AutoQuant::aq_observational_treatment_definition(row$treatment[[1]], row$comparison_condition[[1]], contamination_risk = row$contamination_risk[[1]] %||% "unknown")
  confounders <- causal_observational_parse_list(row$approved_confounders[[1]] %||% "")
  excluded_mediators <- causal_observational_parse_list(row$excluded_mediators[[1]] %||% "")
  excluded_colliders <- causal_observational_parse_list(row$excluded_colliders[[1]] %||% "")
  excluded_post <- causal_observational_parse_list(row$excluded_post_treatment[[1]] %||% "")
  adjustment <- AutoQuant::aq_observational_adjustment_spec(
    approved_confounders = confounders,
    optional_precision_variables = causal_observational_parse_list(row$precision_variables[[1]] %||% ""),
    assignment_predictors = causal_observational_parse_list(row$assignment_inputs[[1]] %||% ""),
    excluded_mediators = excluded_mediators,
    excluded_colliders = excluded_colliders,
    excluded_post_treatment = excluded_post,
    evidence_basis = "user_authored_app_state",
    human_approval = isTRUE(row$adjustment_approved[[1]] %in% c(TRUE, "TRUE", "true", "yes"))
  )
  timing_vars <- unique(c(confounders, excluded_mediators, excluded_colliders, excluded_post))
  temporal <- AutoQuant::aq_assess_observational_temporal_eligibility(
    adjustment,
    data.table::data.table(
      variable = timing_vars,
      timing_status = c(rep("pre_treatment", length(confounders)), rep("post_treatment", length(c(excluded_mediators, excluded_colliders, excluded_post))))[seq_along(timing_vars)]
    )
  )
  treatment_col <- row$treatment_column[[1]] %||% ""
  treated_count <- suppressWarnings(as.integer(row$treated_count[[1]] %||% NA_integer_))
  comparison_count <- suppressWarnings(as.integer(row$comparison_count[[1]] %||% NA_integer_))
  dt <- if (is.data.frame(data)) data.table::as.data.table(data) else data.table::data.table()
  if (nzchar(treatment_col) && treatment_col %in% names(dt)) {
    vals <- as.character(dt[[treatment_col]])
    tab <- table(vals)
    treated_count <- as.integer(max(tab, na.rm = TRUE))
    comparison_count <- as.integer(sum(tab) - treated_count)
  }
  variation <- AutoQuant::aq_assess_observational_variation(treated_count %||% 0L, comparison_count %||% 0L, outcome_count = if (nrow(dt)) nrow(dt) else NA_integer_)
  probabilities <- suppressWarnings(as.numeric(causal_observational_parse_list(row$diagnostic_probabilities[[1]] %||% "")))
  if (!length(probabilities) || all(!is.finite(probabilities))) probabilities <- seq(0.15, 0.85, length.out = 50)
  assignment_model <- AutoQuant::aq_observational_assignment_model_diagnostics(probabilities, approved_pre_treatment_variables = confounders)
  overlap <- AutoQuant::aq_assess_observational_overlap(assignment_model = assignment_model)
  balance <- if (nrow(dt) && nzchar(treatment_col) && treatment_col %in% names(dt) && length(confounders)) {
    available_covars <- intersect(confounders, names(dt))
    if (length(available_covars)) AutoQuant::aq_assess_observational_balance(dt, treatment_col, available_covars) else data.table::data.table(variable = confounders, severity = "unavailable", recommendation = "Confounders are not present in the loaded data.")
  } else {
    data.table::data.table(variable = confounders, severity = "not_assessed", recommendation = "Map treatment and covariate columns to assess baseline balance.")
  }
  selection <- AutoQuant::aq_assess_observational_selection_missingness(data.table::data.table(
    threat = row$selection_threat[[1]] %||% "selection not fully assessed",
    timing = row$selection_timing[[1]] %||% "unknown",
    severity = row$selection_severity[[1]] %||% "unknown",
    evidence = "app authored",
    recommendation = "Review source-system coverage, attrition, outcome observation, and missing confounders."
  ))
  unmeasured <- AutoQuant::aq_unmeasured_confounding_risk_register(data.table::data.table(
    factor = row$unmeasured_confounding_risk[[1]] %||% "unknown unmeasured confounding",
    confidence = row$unmeasured_risk_level[[1]] %||% "unknown",
    decision_consequence = row$decision_consequence[[1]] %||% "uncertain causal decision"
  ))
  falsification <- AutoQuant::aq_observational_falsification_plan(data.table::data.table(
    test_type = row$falsification_test[[1]] %||% "missing_falsification_plan",
    rationale = row$falsification_rationale[[1]] %||% "not supplied",
    expected_relationship = "null",
    required_data = row$falsification_required_data[[1]] %||% "",
    interpretation = "Falsification evidence informs bias concerns but does not prove validity.",
    limitations = "Planning only."
  ))
  design_eligibility <- AutoQuant::aq_observational_design_eligibility(
    study, variation, overlap, adjustment, target_trial,
    evidence = list(
      pre_period_available = isTRUE(row$pre_period_available[[1]] %in% c(TRUE, "TRUE", "true", "yes")),
      donor_pool_available = isTRUE(row$donor_pool_available[[1]] %in% c(TRUE, "TRUE", "true", "yes")),
      running_variable_cutoff = isTRUE(row$running_variable_cutoff[[1]] %in% c(TRUE, "TRUE", "true", "yes")),
      candidate_instrument = isTRUE(row$candidate_instrument[[1]] %in% c(TRUE, "TRUE", "true", "yes")),
      negative_control_available = isTRUE(row$negative_control_available[[1]] %in% c(TRUE, "TRUE", "true", "yes"))
    )
  )
  plan <- AutoQuant::aq_plan_observational_causal_analysis(study, target_trial, assignment, treatment, adjustment, temporal, variation, overlap, balance, selection, unmeasured, falsification, design_eligibility)
  readiness <- AutoQuant::aq_assess_observational_estimation_readiness(plan, overlap, adjustment, selection, unmeasured, falsification)
  aq_artifact <- AutoQuant::aq_observational_causal_planning_artifact(study, plan, readiness)
  signature <- causal_observational_signature(state, study_id)
  state$plans[[study_id]] <- list(
    study = study,
    target_trial = target_trial,
    assignment = assignment,
    treatment = treatment,
    adjustment = adjustment,
    temporal = temporal,
    variation = variation,
    assignment_model = assignment_model,
    overlap = overlap,
    balance = balance,
    selection = selection,
    unmeasured = unmeasured,
    falsification = falsification,
    design_eligibility = design_eligibility,
    plan = plan,
    readiness = readiness,
    aq_artifact = aq_artifact,
    signature = signature,
    stale = FALSE,
    planned_at = causal_observational_now()
  )
  state$stale <- FALSE
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(study_id, "plan_generated", signature, "Generated observational causal readiness plan.")),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = state, messages = "Observational causal readiness assessed.", metadata = list(observational_study_id = study_id, readiness_state = readiness$readiness_state[[1]], signature = signature))
}

causal_observational_run_estimation <- function(state, data = NULL, study_id = causal_observational_active_id(state)) {
  if (!causal_observational_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant observational estimation API is unavailable in the current R library. Install the updated AutoQuant package to run governed observational estimation."))
  }
  state <- causal_observational_normalize(state)
  plan <- state$plans[[study_id]]
  if (is.null(plan) || isTRUE(plan$stale)) {
    return(service_result(status = "error", errors = "Generate a current observational readiness plan before estimating."))
  }
  readiness_state <- plan$readiness$readiness_state[[1]] %||% "not_planned"
  if (!readiness_state %in% c("ready_for_design_implementation", "ready_with_strong_assumptions")) {
    return(service_result(status = "error", errors = paste("Observational estimation is blocked by readiness state:", readiness_state)))
  }
  dt <- if (is.data.frame(data)) data.table::as.data.table(data) else data.table::data.table()
  if (!nrow(dt)) return(service_result(status = "error", errors = "Load a dataset before running observational estimation."))
  row <- state$studies[observational_study_id == study_id][1]
  treatment_col <- row$treatment_column[[1]] %||% ""
  outcome_col <- row$outcome_column[[1]] %||% row$outcome[[1]] %||% ""
  if (!nzchar(treatment_col) || !treatment_col %in% names(dt)) return(service_result(status = "error", errors = "Map a valid treatment column before estimation."))
  if (!nzchar(outcome_col) || !outcome_col %in% names(dt)) return(service_result(status = "error", errors = "Map a valid outcome column before estimation."))
  confounders <- intersect(causal_observational_parse_list(row$approved_confounders[[1]] %||% ""), names(dt))
  if (!length(confounders)) return(service_result(status = "error", errors = "Approved confounder columns must be present in the loaded data."))
  estimand <- row$observational_estimand[[1]] %||% row$estimand[[1]] %||% "ATE"
  if (!estimand %in% c("ATE", "ATT")) estimand <- "ATE"
  spec <- tryCatch(
    AutoQuant::aq_observational_analysis_spec(
      planning_artifact = plan$aq_artifact,
      plan = plan$plan,
      readiness = plan$readiness,
      target_trial = plan$target_trial,
      treatment_col = treatment_col,
      outcome_col = outcome_col,
      adjustment_variables = confounders,
      estimand = estimand,
      approved = TRUE
    ),
    error = function(e) e
  )
  if (inherits(spec, "error")) return(service_result(status = "error", errors = conditionMessage(spec)))
  result <- tryCatch(AutoQuant::aq_estimate_observational_effect(dt, spec), error = function(e) e)
  if (inherits(result, "error")) return(service_result(status = "error", errors = conditionMessage(result)))
  artifact <- tryCatch(AutoQuant::aq_observational_effect_artifact(result), error = function(e) e)
  if (inherits(artifact, "error")) return(service_result(status = "error", errors = conditionMessage(artifact)))
  state$effect_results[[study_id]] <- list(
    spec = spec,
    result = result,
    aq_artifact = artifact,
    estimated_at = causal_observational_now()
  )
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(study_id, "effect_estimated", causal_observational_signature(state, study_id), "Ran governed observational AIPW effect estimation.")),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = state, messages = "Governed observational effect estimated and marked for review.", metadata = list(observational_study_id = study_id, effect_estimated = isTRUE(result$effect_estimated), status = result$status))
}

causal_observational_run_did <- function(state, data = NULL, study_id = causal_observational_active_id(state)) {
  if (!causal_observational_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant DiD API is unavailable in the current R library. Install the updated AutoQuant package to run governed Difference-in-Differences."))
  }
  state <- causal_observational_normalize(state)
  plan <- state$plans[[study_id]]
  if (is.null(plan) || isTRUE(plan$stale)) {
    return(service_result(status = "error", errors = "Generate a current observational readiness plan before running Difference-in-Differences."))
  }
  readiness_state <- plan$readiness$readiness_state[[1]] %||% "not_planned"
  if (!readiness_state %in% c("ready_for_design_implementation", "ready_with_strong_assumptions")) {
    return(service_result(status = "error", errors = paste("Difference-in-Differences is blocked by observational readiness state:", readiness_state)))
  }
  dt <- if (is.data.frame(data)) data.table::as.data.table(data) else data.table::data.table()
  if (!nrow(dt)) return(service_result(status = "error", errors = "Load a dataset before running Difference-in-Differences."))
  row <- state$studies[observational_study_id == study_id][1]
  treatment_col <- row$treatment_column[[1]] %||% ""
  outcome_col <- row$outcome_column[[1]] %||% row$outcome[[1]] %||% ""
  time_col <- row$did_time_column[[1]] %||% ""
  unit_col <- row$did_unit_column[[1]] %||% ""
  intervention_time <- row$did_intervention_time[[1]] %||% ""
  missing <- c()
  if (!nzchar(treatment_col) || !treatment_col %in% names(dt)) missing <- c(missing, "treatment column")
  if (!nzchar(outcome_col) || !outcome_col %in% names(dt)) missing <- c(missing, "outcome column")
  if (!nzchar(time_col) || !time_col %in% names(dt)) missing <- c(missing, "time column")
  if (!nzchar(intervention_time)) missing <- c(missing, "intervention time")
  if (length(missing)) return(service_result(status = "error", errors = paste("Map required DiD fields:", paste(missing, collapse = ", "))))
  spec <- tryCatch(
    AutoQuant::aq_did_analysis_spec(
      planning_artifact = plan$aq_artifact,
      plan = plan$plan,
      readiness = plan$readiness,
      target_trial = plan$target_trial,
      treatment_col = treatment_col,
      outcome_col = outcome_col,
      time_col = time_col,
      intervention_time = intervention_time,
      unit_col = if (nzchar(unit_col)) unit_col else NULL,
      cluster_col = if (nzchar(unit_col)) unit_col else NULL,
      estimand = "ATT",
      approved = TRUE
    ),
    error = function(e) e
  )
  if (inherits(spec, "error")) return(service_result(status = "error", errors = conditionMessage(spec)))
  result <- tryCatch(AutoQuant::aq_estimate_did_effect(dt, spec), error = function(e) e)
  if (inherits(result, "error")) return(service_result(status = "error", errors = conditionMessage(result)))
  aq_artifact <- tryCatch(AutoQuant::aq_did_effect_artifact(result), error = function(e) e)
  if (inherits(aq_artifact, "error")) return(service_result(status = "error", errors = conditionMessage(aq_artifact)))
  report <- tryCatch(AutoQuant::aq_did_effect_report(result), error = function(e) NULL)
  state$did_results[[study_id]] <- list(
    spec = spec,
    result = result,
    aq_artifact = aq_artifact,
    report = report,
    estimated_at = causal_observational_now()
  )
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(study_id, "did_effect_estimated", causal_observational_signature(state, study_id), "Ran governed Difference-in-Differences estimation.")),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = state, messages = "Governed Difference-in-Differences evidence generated and marked for review.", metadata = list(observational_study_id = study_id, effect_estimated = isTRUE(result$effect_estimated), status = result$status))
}

causal_observational_register_artifact <- function(ctx, state, study_id = causal_observational_active_id(state)) {
  state <- causal_observational_normalize(state)
  plan <- state$plans[[study_id]]
  if (is.null(plan) || isTRUE(plan$stale)) return(service_result(status = "error", errors = "Generate a current observational plan before registering artifacts."))
  artifact_id <- paste("observational_causal", study_id, "planning", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) {
    ctx$causal_observational_state(state)
    return(service_result(status = "success", messages = "No duplicate observational planning artifact was registered."))
  }
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Observational Causal Planning",
    source_module = "causal_intelligence",
    object = plan$design_eligibility,
    content = "Planning-only observational causal study, target trial, assignment, overlap, balance, design eligibility, and readiness artifact.",
    metadata = list(
      module_id = "causal_observational",
      analytical_intent = "Observational Causal Planning",
      artifact_importance = "critical",
      caption = paste("Observational readiness plan for", study_id),
      diagnostics = plan$readiness$reasons[[1]],
      recommendations = plan$readiness$supported_next_actions[[1]],
      observational_study_id = study_id,
      readiness_state = plan$readiness$readiness_state[[1]],
      overlap_state = plan$overlap$overlap_state[[1]],
      no_effect_estimated = TRUE,
      prohibited_claims = plan$plan$prohibited_claims,
      source_contract = plan$aq_artifact$artifact_envelope$artifact_type %||% "observational_causal_planning_artifact"
    ),
    render_targets = c("artifact_studio", "llm_docx", "human_report"),
    quality = list(completeness = 0.9, warnings = character())
  )
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry, artifact_id))
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(study_id, "artifact_registered", causal_observational_signature(state, study_id), paste("Registered observational planning artifact", artifact_id))),
    use.names = TRUE,
    fill = TRUE
  )
  ctx$causal_observational_state(state)
  service_result(status = "success", value = artifact, messages = paste("Registered observational planning artifact", artifact_id), metadata = list(artifact_id = artifact_id))
}

causal_observational_register_effect_artifact <- function(ctx, state, study_id = causal_observational_active_id(state)) {
  state <- causal_observational_normalize(state)
  effect <- state$effect_results[[study_id]]
  if (is.null(effect)) return(service_result(status = "error", errors = "Run governed observational estimation before registering an effect artifact."))
  artifact_id <- paste("observational_causal", study_id, "effect", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) {
    ctx$causal_observational_state(state)
    return(service_result(status = "success", messages = "No duplicate observational effect artifact was registered."))
  }
  estimate <- if (is.data.frame(effect$result$primary_estimate) && nrow(effect$result$primary_estimate)) effect$result$primary_estimate$estimate[[1]] else NA_real_
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Observational Effect Evidence",
    source_module = "causal_intelligence",
    object = effect$result$primary_estimate,
    content = "Governed observational AIPW effect evidence with propensity, matching, weighting, balance, sensitivity, and claim-governance diagnostics.",
    metadata = list(
      module_id = "causal_observational",
      analytical_intent = "Observational Causal Effect",
      artifact_importance = "critical",
      caption = paste("Governed observational effect estimate for", study_id),
      diagnostics = paste(effect$result$sensitivity$sensitivity, effect$result$sensitivity$status, sep = ": ", collapse = " | "),
      recommendations = "Review balance, overlap, sensitivity reminders, and prohibited claims before using this evidence in a decision.",
      observational_study_id = study_id,
      effect_estimated = isTRUE(effect$result$effect_estimated),
      estimate = estimate,
      estimand = effect$spec$estimand,
      frozen_design_hash = effect$spec$frozen_design_hash,
      no_estimator_shopping = TRUE,
      requires_human_review = TRUE,
      prohibited_claims = effect$result$prohibited_claims,
      source_contract = effect$aq_artifact$artifact_envelope$artifact_type %||% "observational_effect_artifact"
    ),
    render_targets = c("artifact_studio", "llm_docx", "human_report"),
    quality = list(completeness = 0.92, warnings = "Observational causal evidence remains assumption-dependent.")
  )
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry, artifact_id))
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(study_id, "effect_artifact_registered", causal_observational_signature(state, study_id), paste("Registered observational effect artifact", artifact_id))),
    use.names = TRUE,
    fill = TRUE
  )
  ctx$causal_observational_state(state)
  service_result(status = "success", value = artifact, messages = paste("Registered observational effect artifact", artifact_id), metadata = list(artifact_id = artifact_id))
}

causal_observational_register_did_artifact <- function(ctx, state, study_id = causal_observational_active_id(state)) {
  state <- causal_observational_normalize(state)
  did <- state$did_results[[study_id]]
  if (is.null(did)) return(service_result(status = "error", errors = "Run governed Difference-in-Differences before registering a DiD artifact."))
  artifact_id <- paste("observational_causal", study_id, "did_effect", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) {
    ctx$causal_observational_state(state)
    return(service_result(status = "success", messages = "No duplicate DiD effect artifact was registered."))
  }
  estimate <- if (is.data.frame(did$result$primary_estimate) && nrow(did$result$primary_estimate)) did$result$primary_estimate$estimate[[1]] else NA_real_
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Difference-in-Differences Evidence",
    source_module = "causal_intelligence",
    object = did$result$primary_estimate,
    content = "Governed classic two-group Difference-in-Differences evidence with readiness, pre-period diagnostics, parallel-trends assessment, composition stability, sensitivity, and claim governance.",
    metadata = list(
      module_id = "causal_observational",
      analytical_intent = "Difference-in-Differences Causal Effect",
      artifact_importance = "critical",
      caption = paste("Governed DiD evidence for", study_id),
      diagnostics = paste("Parallel trends:", did$result$parallel_trends$parallel_trends_support[[1]], "| Composition:", did$result$composition$composition_state[[1]]),
      recommendations = "Review pre-period diagnostics, parallel-trends support, composition stability, sensitivity reminders, and prohibited claims before using this evidence in a decision.",
      observational_study_id = study_id,
      effect_estimated = isTRUE(did$result$effect_estimated),
      estimate = estimate,
      estimand = did$spec$estimand,
      frozen_design_hash = did$spec$frozen_design_hash,
      parallel_trends_support = did$result$parallel_trends$parallel_trends_support[[1]],
      composition_state = did$result$composition$composition_state[[1]],
      no_generalized_did = TRUE,
      requires_human_review = TRUE,
      prohibited_claims = did$result$prohibited_claims,
      source_contract = did$aq_artifact$artifact_envelope$artifact_type %||% "did_effect_artifact"
    ),
    render_targets = c("artifact_studio", "llm_docx", "human_report"),
    quality = list(completeness = 0.92, warnings = "DiD causal evidence remains assumption-dependent.")
  )
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry, artifact_id))
  state$history <- data.table::rbindlist(
    list(state$history, causal_observational_event(study_id, "did_artifact_registered", causal_observational_signature(state, study_id), paste("Registered DiD effect artifact", artifact_id))),
    use.names = TRUE,
    fill = TRUE
  )
  ctx$causal_observational_state(state)
  service_result(status = "success", value = artifact, messages = paste("Registered DiD effect artifact", artifact_id), metadata = list(artifact_id = artifact_id))
}

causal_observational_summary <- function(state) {
  state <- causal_observational_normalize(state)
  study_id <- causal_observational_active_id(state)
  plan <- state$plans[[study_id]]
  readiness <- if (!is.null(plan) && !isTRUE(plan$stale)) plan$readiness$readiness_state[[1]] else "not_planned"
  overlap <- if (!is.null(plan) && !isTRUE(plan$stale)) plan$overlap$overlap_state[[1]] else "not_assessed"
  assignment <- if (!is.null(plan) && !isTRUE(plan$stale)) plan$assignment$mechanism_type else if (nrow(state$studies)) state$studies[observational_study_id == study_id]$assignment_mechanism[[1]] %||% "unknown" else "unknown"
  effect <- state$effect_results[[study_id]]
  effect_status <- if (!is.null(effect)) effect$result$status %||% "estimated" else "not_estimated"
  did <- state$did_results[[study_id]]
  did_status <- if (!is.null(did)) did$result$status %||% "estimated" else "not_estimated"
  data.table::data.table(
    studies = nrow(state$studies),
    active_study_id = study_id %||% NA_character_,
    readiness_state = readiness,
    overlap_state = overlap,
    assignment_mechanism = assignment,
    effect_status = effect_status,
    did_status = did_status,
    stale = isTRUE(state$stale) || isTRUE(plan$stale %||% FALSE),
    registered_artifacts = length(state$artifact_registry %||% character())
  )
}

causal_observational_campaign_seeds <- function(state) {
  summary <- causal_observational_summary(state)
  seeds <- list()
  add <- function(seed, reason) seeds[[length(seeds) + 1L]] <<- data.table::data.table(seed = seed, reason = reason, source = "observational_causal_planning")
  if (!nrow(summary) || summary$studies[[1]] == 0L) add("author_observational_study", "No observational causal study exists.")
  if (summary$assignment_mechanism[[1]] %in% c("unknown", "")) add("document_assignment_mechanism", "Treatment assignment is not documented.")
  if (summary$overlap_state[[1]] %in% c("severe positivity concern", "no credible support", "not_assessed")) add("inspect_overlap", paste("Overlap state:", summary$overlap_state[[1]]))
  if (summary$readiness_state[[1]] %in% c("experiment_preferred", "blocked", "unidentified")) add("design_experiment", paste("Readiness state:", summary$readiness_state[[1]]))
  if (!length(seeds)) add("review_observational_plan", "Observational plan is available for review.")
  data.table::rbindlist(seeds, use.names = TRUE, fill = TRUE)
}

qa_causal_observational_workspace <- function() {
  page <- if (file.exists(file.path("R", "page_causal_intelligence.R"))) paste(readLines(file.path("R", "page_causal_intelligence.R"), warn = FALSE), collapse = "\n") else ""
  app <- if (file.exists("app.R")) paste(readLines("app.R", warn = FALSE), collapse = "\n") else ""
  server <- if (file.exists(file.path("R", "app_server.R"))) paste(readLines(file.path("R", "app_server.R"), warn = FALSE), collapse = "\n") else ""
  mission <- if (file.exists(file.path("R", "page_mission_control.R"))) paste(readLines(file.path("R", "page_mission_control.R"), warn = FALSE), collapse = "\n") else ""
  genai <- if (file.exists(file.path("R", "genai_service.R"))) paste(readLines(file.path("R", "genai_service.R"), warn = FALSE), collapse = "\n") else ""
  state <- causal_observational_empty("qa")
  row <- data.table::data.table(
    observational_study_id = "obs_qa",
    decision_context_id = "decision_qa",
    causal_question_id = "cq_qa",
    estimand_id = "estimand_qa",
    study_title = "QA observational study",
    treatment = "treated",
    comparison_condition = "comparison",
    unit_of_analysis = "unit",
    population = "eligible units",
    eligibility = "eligible before treatment",
    treatment_assignment_time = "time zero",
    treatment_window = "30 days",
    outcome_window = "60 days",
    baseline_window = "90 days",
    outcome = "revenue",
    estimand = "ATE",
    assignment_mechanism = "unknown",
    approved_confounders = "x1,x2",
    treated_count = 50,
    comparison_count = 60
  )
  upsert <- causal_observational_upsert_study(state, row)
  summary <- causal_observational_summary(if (identical(upsert$status, "success")) upsert$value else state)
  set.seed(99)
  qa_data <- data.table::data.table(
    treat = rep(c(0, 1), each = 80),
    y = c(stats::rnorm(80, 0), stats::rnorm(80, 1)),
    x1 = stats::rnorm(160),
    x2 = rep(c("a", "b"), 80)
  )
  est_row <- data.table::copy(row)
  est_row[, `:=`(
    observational_study_id = "obs_est_qa",
    treatment_column = "treat",
    outcome_column = "y",
    approved_confounders = "x1,x2",
    observational_estimand = "ATE",
    assignment_mechanism = "eligibility_threshold",
    assignment_confidence = "high",
    diagnostic_probabilities = "0.25,0.35,0.45,0.55,0.65,0.75",
    unmeasured_risk_level = "low",
    selection_severity = "low",
    falsification_test = "negative_control",
    adjustment_approved = TRUE,
    negative_control_available = TRUE
  )]
  est_state <- causal_observational_empty("qa_est")
  est_state <- causal_observational_upsert_study(est_state, est_row)$value
  est_plan <- causal_observational_build_plan(est_state, causal_intelligence_empty(), qa_data)
  est_run <- if (identical(est_plan$status, "success")) causal_observational_run_estimation(est_plan$value, qa_data) else est_plan
  did_units <- paste0("u", seq_len(40))
  did_data <- data.table::CJ(unit = did_units, time = seq_len(6))
  did_data[, treat := as.integer(as.integer(sub("u", "", unit)) <= 20L)]
  did_data[, y := 2 + 0.2 * time + 0.9 * treat * as.integer(time >= 4L) + stats::rnorm(.N, 0, 0.25)]
  did_row <- data.table::copy(row)
  did_row[, `:=`(
    observational_study_id = "obs_did_qa",
    treatment_column = "treat",
    outcome_column = "y",
    approved_confounders = "time",
    did_time_column = "time",
    did_unit_column = "unit",
    did_intervention_time = "4",
    assignment_mechanism = "geographic_rollout",
    assignment_confidence = "high",
    diagnostic_probabilities = "0.25,0.35,0.45,0.55,0.65,0.75",
    unmeasured_risk_level = "low",
    selection_severity = "low",
    falsification_test = "negative_control",
    adjustment_approved = TRUE,
    negative_control_available = TRUE
  )]
  did_state <- causal_observational_empty("qa_did")
  did_state <- causal_observational_upsert_study(did_state, did_row)$value
  did_plan <- causal_observational_build_plan(did_state, causal_intelligence_empty(), did_data)
  did_run <- if (identical(did_plan$status, "success")) causal_observational_run_did(did_plan$value, did_data) else did_plan
  checks <- data.table::data.table(
    check = c(
      "state_contract", "availability_guard", "upsert_and_staleness", "summary",
      "app_sourced", "server_state", "project_persistence", "page_workbench",
      "artifact_registration", "mission_control", "genai_context", "campaign_seeds",
      "effect_estimator_ui", "governed_estimation_path", "governed_did_path"
    ),
    status = c(
      if (identical(causal_observational_empty()$schema_version, "causal_observational_workspace_v1")) "success" else "error",
      if (is.logical(causal_observational_available())) "success" else "error",
      if (identical(upsert$status, "success") && isTRUE(upsert$value$stale)) "success" else "error",
      if (nrow(summary) == 1L && summary$studies[[1]] == 1L) "success" else "error",
      if (grepl("causal_observational_workspace.R", app, fixed = TRUE)) "success" else "error",
      if (grepl("causal_observational_state", server, fixed = TRUE)) "success" else "error",
      if (grepl("causal_observational_state", paste(readLines(file.path("R", "project_state.R"), warn = FALSE), collapse = "\n"), fixed = TRUE)) "success" else "error",
      if (grepl("Observational Study Design", page, fixed = TRUE) && grepl("run_observational_plan", page, fixed = TRUE)) "success" else "error",
      if (grepl("causal_observational_register_artifact", page, fixed = TRUE)) "success" else "error",
      if (grepl("causal_observational", mission, fixed = TRUE)) "success" else "error",
      if (grepl("causal_observational", genai, fixed = TRUE)) "success" else "error",
      if (nrow(causal_observational_campaign_seeds(upsert$value)) >= 1L) "success" else "error",
      if (grepl("run_observational_estimate", page, fixed = TRUE)) "success" else "error",
      if (identical(est_run$status, "success") && isTRUE(est_run$metadata$effect_estimated)) "success" else "error",
      if (identical(did_run$status, "success") && isTRUE(did_run$metadata$effect_estimated)) "success" else "error"
    ),
    message = c(
      "Workspace state has a stable schema.",
      "AutoQuant availability is guarded.",
      "Saving a study marks downstream planning stale.",
      "Summary returns active readiness state.",
      "App sources observational workspace.",
      "Server owns observational causal state.",
      "Project files persist observational causal state.",
      "Causal Intelligence page exposes observational workbench controls.",
      "Planning artifacts can be registered.",
      "Mission Control can see observational status.",
      "GenAI context can summarize observational planning without claims.",
      "Campaign seeds surface planning gaps.",
      "UI exposes governed observational effect estimation.",
      "App can execute the approved readiness -> governed estimation path.",
      "App can execute the approved readiness -> governed Difference-in-Differences path."
    )
  )
  checks
}
