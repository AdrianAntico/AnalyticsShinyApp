decision_workflow_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_decision_workflow",
      "aq_assess_decision_review_readiness",
      "aq_decision_evidence_package",
      "aq_decision_workflow_artifact"
    ) %in% getNamespaceExports("AutoQuant"))
}

decision_workflow_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "decision_workflow_workspace_v1",
    project_id = project_id,
    active_workflow_id = NA_character_,
    workflows = data.table::data.table(),
    review_requests = data.table::data.table(),
    reviews = data.table::data.table(),
    approvals = data.table::data.table(),
    conditions = data.table::data.table(),
    implementation_plans = data.table::data.table(),
    implementation_evidence = data.table::data.table(),
    monitoring = data.table::data.table(),
    realized_values = data.table::data.table(),
    results = list(),
    artifact_registry = character(),
    message = "Decision workflow has not been run.",
    history = data.table::data.table(
      event_id = character(),
      workflow_id = character(),
      event_type = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

decision_workflow_tables <- function() {
  c("workflows", "review_requests", "reviews", "approvals", "conditions", "implementation_plans", "implementation_evidence", "monitoring", "realized_values")
}

decision_workflow_now <- function() as.character(Sys.time())

decision_workflow_normalize <- function(state) {
  state <- state %||% decision_workflow_empty()
  empty <- decision_workflow_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (table_name in decision_workflow_tables()) {
    if (!data.table::is.data.table(state[[table_name]])) state[[table_name]] <- data.table::as.data.table(state[[table_name]])
  }
  if (!data.table::is.data.table(state$history)) state$history <- data.table::as.data.table(state$history)
  state
}

decision_workflow_event <- function(workflow_id, event_type, summary) {
  data.table::data.table(
    event_id = paste0("decision_workflow_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    workflow_id = workflow_id %||% NA_character_,
    event_type = event_type %||% "event",
    summary = summary %||% "",
    timestamp = decision_workflow_now()
  )
}

decision_workflow_upsert <- function(state, table_name, id_col, row, workflow_id = NULL, event_type = NULL) {
  state <- decision_workflow_normalize(state)
  if (!table_name %in% decision_workflow_tables()) {
    return(service_result(status = "error", errors = paste("Unsupported decision workflow table:", table_name)))
  }
  row <- data.table::as.data.table(row)
  if (!id_col %in% names(row) || !nzchar(row[[id_col]][[1]] %||% "")) {
    return(service_result(status = "error", errors = paste(id_col, "is required.")))
  }
  workflow_id <- workflow_id %||% row$workflow_id %||% state$active_workflow_id
  row[, updated_at := decision_workflow_now()]
  if (!"created_at" %in% names(row)) row[, created_at := updated_at]
  existing <- state[[table_name]]
  record_id <- row[[id_col]][[1]]
  was_existing <- nrow(existing) && id_col %in% names(existing) && record_id %in% existing[[id_col]]
  if (was_existing) {
    old <- existing[get(id_col) == record_id][1]
    row[, created_at := old$created_at %||% updated_at]
    existing <- existing[get(id_col) != record_id]
  }
  state[[table_name]] <- data.table::rbindlist(list(existing, row), use.names = TRUE, fill = TRUE)
  if (identical(table_name, "workflows")) state$active_workflow_id <- record_id
  state$history <- data.table::rbindlist(
    list(state$history, decision_workflow_event(workflow_id, event_type %||% if (was_existing) "modified" else "created", paste(if (was_existing) "Modified" else "Created", table_name, record_id))),
    use.names = TRUE,
    fill = TRUE
  )
  state$message <- paste("Saved", table_name, record_id)
  service_result(status = "success", value = state, messages = state$message, metadata = list(record_id = record_id, workflow_id = workflow_id))
}

decision_workflow_rows <- function(state, table_name, workflow_id = NULL) {
  state <- decision_workflow_normalize(state)
  rows <- state[[table_name]]
  if (!nrow(rows) || is.null(workflow_id) || !nzchar(workflow_id %||% "")) return(rows)
  target_workflow_id <- workflow_id
  if ("workflow_id" %in% names(rows)) rows[workflow_id == target_workflow_id] else rows
}

decision_workflow_active_id <- function(state) {
  state <- decision_workflow_normalize(state)
  id <- state$active_workflow_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$workflows)) state$workflows$workflow_id[[1]] else NA_character_
}

decision_workflow_build <- function(state, semantic_decision_state = semantic_decision_empty(), valuation_state = decision_valuation_empty()) {
  if (!decision_workflow_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant decision workflow API is unavailable."))
  }
  state <- decision_workflow_normalize(state)
  id <- decision_workflow_active_id(state)
  rows <- decision_workflow_rows(state, "workflows", id)
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  decision_id <- semantic_decision_active_context_id(decision_state)
  valuation_id <- decision_valuation_active_id(valuation_state)
  valuation_result <- decision_valuation_normalize(valuation_state)$results[[valuation_id]]
  valuation_artifact_id <- valuation_result$autoquant_artifact$id %||% paste0("decision_valuation_artifact_", valuation_id)
  recommendation <- valuation_result$recommendation %||% data.table::data.table()
  selected <- if (nrow(recommendation)) recommendation$alternative_id[[1]] else NA_character_
  row <- if (nrow(rows)) rows[1] else data.table::data.table()
  workflow <- AutoQuant::aq_decision_workflow(
    workflow_id = row$workflow_id %||% id %||% paste0("workflow_", decision_id),
    decision_context_id = row$decision_context_id %||% decision_id,
    decision_version = row$decision_version %||% NA_character_,
    valuation_artifact_id = row$valuation_artifact_id %||% valuation_artifact_id,
    recommendation_id = row$recommendation_id %||% "valuation_recommendation",
    selected_alternative = row$selected_alternative %||% selected,
    workflow_type = row$workflow_type %||% "manager_approval",
    risk_tier = row$risk_tier %||% "medium",
    authority_tier = row$authority_tier %||% "manager",
    current_stage = row$current_stage %||% "draft",
    stage_owners = semantic_decision_parse_list(row$stage_owners %||% ""),
    required_approvals = semantic_decision_parse_list(row$required_approvals %||% ""),
    review_deadline = row$review_deadline %||% "",
    evidence_cutoff = row$evidence_cutoff %||% ""
  )
  service_result(status = "success", value = workflow, messages = "Decision workflow built.")
}

decision_workflow_run <- function(state, semantic_decision_state = semantic_decision_empty(), valuation_state = decision_valuation_empty()) {
  build <- decision_workflow_build(state, semantic_decision_state, valuation_state)
  if (!identical(build$status, "success")) return(build)
  workflow <- build$value
  state <- decision_workflow_normalize(state)
  id <- workflow$workflow_id
  valuation_id <- decision_valuation_active_id(valuation_state)
  valuation_result <- decision_valuation_normalize(valuation_state)$results[[valuation_id]]
  readiness <- AutoQuant::aq_assess_decision_review_readiness(workflow, valuation = valuation_result)
  evidence_package <- AutoQuant::aq_decision_evidence_package(
    workflow,
    valuation = valuation_result,
    evidence_refs = c(workflow$valuation_artifact_id, valuation_id)
  )
  review_requests <- AutoQuant::aq_decision_review_request(decision_workflow_rows(state, "review_requests", id))
  reviews <- AutoQuant::aq_decision_review(decision_workflow_rows(state, "reviews", id))
  approvals <- AutoQuant::aq_decision_approval(decision_workflow_rows(state, "approvals", id))
  approval_validation <- AutoQuant::aq_validate_decision_approval(approvals, workflow)
  conditions <- AutoQuant::aq_decision_condition(decision_workflow_rows(state, "conditions", id))
  plans <- AutoQuant::aq_decision_implementation_plan(decision_workflow_rows(state, "implementation_plans", id))
  actuals <- AutoQuant::aq_record_decision_implementation(decision_workflow_rows(state, "implementation_evidence", id))
  reconciliation <- AutoQuant::aq_reconcile_decision_implementation(plans, actuals)
  monitoring <- AutoQuant::aq_decision_monitoring_plan(decision_workflow_rows(state, "monitoring", id))
  realized <- decision_workflow_rows(state, "realized_values", id)
  realized_review <- if (nrow(realized)) {
    AutoQuant::aq_realized_value_review(
      workflow_id = id,
      expected_value = realized$expected_value[[1]] %||% NA_real_,
      realized_value = realized$realized_value[[1]] %||% NA_real_,
      expected_cost = realized$expected_cost[[1]] %||% NA_real_,
      realized_cost = realized$realized_cost[[1]] %||% NA_real_,
      maturation_status = realized$maturation_status[[1]] %||% "unknown",
      notes = realized$notes[[1]] %||% NA_character_
    )
  } else {
    data.table::data.table()
  }
  quality <- AutoQuant::aq_assess_decision_quality(workflow, readiness, reviews, approvals, reconciliation)
  followups <- AutoQuant::aq_decision_followup_candidates(workflow, quality, realized_review, reconciliation)
  seeds <- AutoQuant::aq_decision_workflow_campaign_seeds(readiness, reconciliation, realized_review, followups)
  artifact <- AutoQuant::aq_decision_workflow_artifact(workflow, readiness, reviews, approvals, plans, reconciliation, monitoring, quality, realized_review, followups)
  state$active_workflow_id <- id
  state$results[[id]] <- list(
    workflow = workflow,
    readiness = readiness,
    evidence_package = evidence_package,
    review_requests = review_requests,
    reviews = reviews,
    approvals = approvals,
    approval_validation = approval_validation,
    conditions = conditions,
    implementation_plans = plans,
    implementation_evidence = actuals,
    reconciliation = reconciliation,
    monitoring = monitoring,
    realized_value = realized_review,
    quality = quality,
    followups = followups,
    campaign_seeds = seeds,
    autoquant_artifact = artifact,
    run_at = decision_workflow_now()
  )
  state$message <- "Decision workflow assessment completed."
  state$history <- data.table::rbindlist(list(state$history, decision_workflow_event(id, "workflow_run", state$message)), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = state$message, metadata = list(workflow_id = id))
}

decision_workflow_summary <- function(state) {
  state <- decision_workflow_normalize(state)
  id <- decision_workflow_active_id(state)
  result <- state$results[[id]]
  readiness <- result$readiness %||% data.table::data.table()
  quality <- result$quality %||% data.table::data.table()
  reconciliation <- result$reconciliation %||% data.table::data.table()
  data.table::data.table(
    workflows = nrow(state$workflows),
    active_workflow_id = id %||% NA_character_,
    workflow_status = if (is.null(result)) "not_run" else "current",
    readiness_state = if (nrow(readiness)) readiness$readiness_state[[1]] else "not_assessed",
    reviews = nrow(state$reviews),
    approvals = nrow(state$approvals),
    open_conditions = if (nrow(state$conditions) && "status" %in% names(state$conditions)) sum(state$conditions$status %in% c("open", "breached", "expired"), na.rm = TRUE) else 0L,
    implementation_deviations = if (nrow(reconciliation) && "escalation_required" %in% names(reconciliation)) sum(reconciliation$escalation_required, na.rm = TRUE) else 0L,
    quality_state = if (nrow(quality)) quality$decision_quality_state[[1]] else "not_assessed",
    followup_candidates = if (!is.null(result)) nrow(result$followups %||% data.table::data.table()) else 0L,
    registered_artifacts = length(state$artifact_registry)
  )
}

decision_workflow_app_artifact <- function(result) {
  workflow <- result$workflow
  quality <- result$quality %||% data.table::data.table()
  artifact_id <- paste0("decision_workflow_", workflow$workflow_id)
  create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Decision Workflow",
    source_module = "semantic_intelligence",
    object = result$readiness,
    content = "Governed decision workflow readiness, review, approval, implementation, and follow-through evidence.",
    metadata = list(
      module_id = "semantic_intelligence",
      module_run_id = paste0("decision_workflow_", format(Sys.time(), "%Y%m%d%H%M%S")),
      source_module = "semantic_intelligence",
      original_name = "decision_workflow",
      original_section = "Decision Workflow",
      normalized_section = "Decision Workflow",
      artifact_index = 1L,
      created_by_module = TRUE,
      generated_at = Sys.time(),
      run_timestamp = Sys.time(),
      analytical_intent = "Decision",
      artifact_importance = "critical",
      caption = "Decision workflow readiness, approval, implementation, and follow-through evidence.",
      diagnostics = c("Generated from deterministic AutoQuant decision workflow contracts."),
      recommendations = result$followups$candidate_type %||% character(),
      workflow_id = workflow$workflow_id,
      decision_context_id = workflow$decision_context_id,
      current_stage = workflow$current_stage,
      readiness_state = result$readiness$readiness_state[[1]] %||% NA_character_,
      decision_quality_state = quality$decision_quality_state[[1]] %||% NA_character_,
      autoquant_artifact_id = result$autoquant_artifact$id %||% NA_character_,
      supported_actions = result$autoquant_artifact$artifact_envelope$supported_actions %||% character()
    ),
    section = "Decision Workflow",
    order = 1L
  )
}

decision_workflow_register_artifact <- function(ctx, state) {
  state <- decision_workflow_normalize(state)
  id <- decision_workflow_active_id(state)
  result <- state$results[[id]]
  if (is.null(result)) return(service_result(status = "warning", warnings = "Run decision workflow before registering an artifact.", value = state))
  artifact <- decision_workflow_app_artifact(result)
  service <- service_result(
    status = "success",
    value = result,
    artifacts = list(artifact),
    metadata = module_run_metadata(
      module_id = "semantic_intelligence",
      module_run_id = artifact$metadata$module_run_id,
      source_function = "decision_workflow_register_artifact",
      artifacts = list(artifact)
    )
  )
  append_result <- ctx$append_module_result_to_collector(service, "semantic_intelligence", record_skipped = FALSE)
  if (identical(append_result$status, "success")) {
    state$artifact_registry <- unique(c(state$artifact_registry, artifact$artifact_id))
    state$message <- "Decision workflow artifact registered to collector."
    state$history <- data.table::rbindlist(list(state$history, decision_workflow_event(id, "artifact_registered", state$message)), use.names = TRUE, fill = TRUE)
    return(service_result(status = "success", value = state, messages = state$message))
  }
  service_result(status = append_result$status, value = state, warnings = append_result$warnings, errors = append_result$errors)
}

decision_workflow_campaign_seeds <- function(state) {
  state <- decision_workflow_normalize(state)
  id <- decision_workflow_active_id(state)
  result <- state$results[[id]]
  if (is.null(result)) return(data.table::data.table())
  result$campaign_seeds %||% data.table::data.table()
}

decision_workflow_friction_inventory <- function() {
  data.table::data.table(
    journey_step = c(
      "Business context",
      "Decision context",
      "Alternatives",
      "Evidence",
      "Valuation",
      "Workflow",
      "Review",
      "Approval",
      "Implementation",
      "Outcomes",
      "Persistence"
    ),
    observed_friction = c(
      "Users must know which objective, tactic, lever, KPI, authority, and coverage objects already exist.",
      "Decision authoring exposes canonical IDs before the user sees an operational decision summary.",
      "Baseline and competing alternatives require repeated context and lever references.",
      "Evidence can exist in artifacts, semantic refs, causal outputs, or valuation outputs without one bounded inbox.",
      "Valuation status is separate from lifecycle status, so stale or missing valuation may not feel actionable.",
      "Workflow assessment is contract-complete but can feel like a raw lifecycle form.",
      "Reviewer scope and evidence package version need first-class presentation before raw review fields.",
      "Approvers need to see what is being approved before recording approval fields.",
      "Approved-versus-realized comparison is available only after running the workflow assessment.",
      "Decision quality, implementation quality, and realized outcome are easy to conflate.",
      "Save/load persists state, but the user needs a concise continuation queue after reload."
    ),
    completed_fix = c(
      "Context reuse appears in guided summary and evidence-gap guidance.",
      "Decision summary card added before raw workflow fields.",
      "Next-action guidance now prioritizes baseline and alternative completion.",
      "Deterministic evidence inbox added from linked refs, artifacts, and semantic metadata.",
      "Next-action and gap guidance distinguish missing, stale, and current valuation.",
      "Guided operations panel added above the low-level contract fields.",
      "Review-ready queue explains scope and evidence package prerequisites.",
      "Approval queue now requires recommendation, authority, and approval-scope visibility.",
      "Implementation queue highlights missing plan, monitoring, and deviations.",
      "Outcome guidance separates decision quality, implementation quality, and realized value.",
      "Mission Control decision queue and project persistence QA cover continuation."
    ),
    deferred = c(
      "Bulk authoring import remains deferred.",
      "Full guided wizard remains deferred; current pass adds deterministic guided panels.",
      "Side-by-side editing is deferred; version comparison is summarized deterministically.",
      "No probabilistic evidence suggestion or semantic vector search.",
      "No valuation engine changes.",
      "No new workflow engine.",
      "No reviewer-only route yet.",
      "No electronic signature or identity-management layer.",
      "No external task system.",
      "No automated learning promotion.",
      "No external collaboration sync."
    )
  )
}

decision_workflow_complexity_profile <- function(semantic_decision_state = semantic_decision_empty(), valuation_state = decision_valuation_empty(), workflow_state = decision_workflow_empty()) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  valuation_state <- decision_valuation_normalize(valuation_state)
  workflow_state <- decision_workflow_normalize(workflow_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  workflow_id <- decision_workflow_active_id(workflow_state)
  workflows <- decision_workflow_rows(workflow_state, "workflows", workflow_id)
  alternatives <- semantic_decision_rows(decision_state, "alternatives", context_id)
  uncertainties <- semantic_decision_rows(decision_state, "uncertainties", context_id)
  financial <- semantic_decision_rows(decision_state, "financial_impacts", context_id)
  risk_tier <- if (nrow(workflows)) workflows$risk_tier[[1]] %||% "medium" else "medium"
  authority_tier <- if (nrow(workflows)) workflows$authority_tier[[1]] %||% "manager" else "manager"
  max_exposure <- if (nrow(financial)) {
    vals <- suppressWarnings(as.numeric(c(financial$initial_cost %||% NA_real_, financial$recurring_cost %||% NA_real_, financial$expected_benefit %||% NA_real_, financial$downside_estimate %||% NA_real_, financial$upside_estimate %||% NA_real_)))
    if (any(is.finite(vals))) max(abs(vals), na.rm = TRUE) else NA_real_
  } else {
    NA_real_
  }
  score <- 0L
  score <- score + if (risk_tier %in% c("critical", "high")) 3L else if (identical(risk_tier, "medium")) 1L else 0L
  score <- score + if (authority_tier %in% c("enterprise", "cross_functional", "functional_executive")) 3L else if (authority_tier %in% c("manager", "executive")) 1L else 0L
  score <- score + if (nrow(alternatives) >= 4L) 2L else if (nrow(alternatives) >= 2L) 1L else 0L
  score <- score + if (nrow(uncertainties) >= 3L) 2L else if (nrow(uncertainties) >= 1L) 1L else 0L
  score <- score + if (is.finite(max_exposure) && max_exposure >= 1000000) 3L else if (is.finite(max_exposure) && max_exposure >= 100000) 2L else if (is.finite(max_exposure) && max_exposure > 0) 1L else 0L
  level <- if (score >= 8L) "executive_escalation" else if (score >= 6L) "cross_functional_decision" else if (score >= 4L) "high_consequence_decision" else if (score >= 2L) "standard_decision" else "lightweight_advisory"
  data.table::data.table(
    complexity_level = level,
    complexity_score = score,
    risk_tier = risk_tier,
    authority_tier = authority_tier,
    alternatives = nrow(alternatives),
    uncertainty_items = nrow(uncertainties),
    max_exposure = max_exposure,
    recommended_reviews = switch(level,
      lightweight_advisory = "analyst review optional",
      standard_decision = "analytical review",
      high_consequence_decision = "analytical and financial review",
      cross_functional_decision = "analytical, financial, operational, and authority review",
      executive_escalation = "executive, risk, financial, and implementation review",
      "analytical review"
    ),
    monitoring_level = if (level %in% c("executive_escalation", "cross_functional_decision", "high_consequence_decision")) "formal monitoring required" else if (identical(level, "standard_decision")) "basic monitoring recommended" else "light monitoring acceptable"
  )
}

decision_workflow_summary_card <- function(semantic_decision_state = semantic_decision_empty(), valuation_state = decision_valuation_empty(), workflow_state = decision_workflow_empty()) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  valuation_state <- decision_valuation_normalize(valuation_state)
  workflow_state <- decision_workflow_normalize(workflow_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  context <- semantic_decision_rows(decision_state, "contexts", context_id)
  alternatives <- semantic_decision_rows(decision_state, "alternatives", context_id)
  valuation_id <- decision_valuation_active_id(valuation_state)
  valuation_result <- valuation_state$results[[valuation_id]]
  recommendation <- valuation_result$recommendation %||% data.table::data.table()
  workflow_summary <- decision_workflow_summary(workflow_state)
  complexity <- decision_workflow_complexity_profile(decision_state, valuation_state, workflow_state)
  baseline <- if (nrow(alternatives) && "baseline" %in% names(alternatives)) {
    base <- alternatives[vapply(baseline %||% FALSE, semantic_decision_bool, logical(1L))]
    if (nrow(base)) base$name[[1]] %||% base$alternative_id[[1]] else "Not identified"
  } else {
    "Not identified"
  }
  leading <- if (nrow(recommendation) && "alternative_id" %in% names(recommendation)) recommendation$alternative_id[[1]] else workflow_summary$active_workflow_id[[1]] %||% "Not selected"
  data.table::data.table(
    field = c("Decision question", "Objective", "Owner", "Current stage", "Baseline", "Leading alternative", "Recommendation", "Largest uncertainty", "Major risk", "Authority", "Complexity", "Next action"),
    value = c(
      if (nrow(context)) context$decision_question[[1]] %||% "Not authored" else "Not authored",
      if (nrow(context)) context$objective_ids[[1]] %||% "Not linked" else "Not linked",
      if (nrow(context)) context$owner[[1]] %||% "Not assigned" else "Not assigned",
      workflow_summary$readiness_state[[1]] %||% "not_assessed",
      baseline,
      leading,
      if (nrow(recommendation) && "recommendation" %in% names(recommendation)) recommendation$recommendation[[1]] else "Not generated",
      if (nrow(semantic_decision_rows(decision_state, "uncertainties", context_id))) semantic_decision_rows(decision_state, "uncertainties", context_id)$uncertainty_category[[1]] %||% "Unknown" else "No uncertainty authored",
      complexity$risk_tier[[1]],
      complexity$authority_tier[[1]],
      complexity$complexity_level[[1]],
      decision_workflow_next_actions(decision_state, valuation_state, workflow_state)[1, action]
    )
  )
}

decision_workflow_evidence_inbox <- function(artifacts = list(), semantic_decision_state = semantic_decision_empty(), workflow_state = decision_workflow_empty()) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  refs <- semantic_decision_rows(decision_state, "evidence_refs", context_id)
  rows <- list()
  add <- function(source_id, title, evidence_type, source, applicability, linkage_status, confidence = "unknown", limitations = "") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(
      source_id = source_id %||% NA_character_,
      title = title %||% source_id %||% "Evidence",
      evidence_type = evidence_type %||% "artifact",
      source = source %||% "project",
      applicability = applicability %||% "candidate",
      relationship = "contextualizes",
      confidence = confidence %||% "unknown",
      limitations = limitations %||% "",
      linkage_status = linkage_status %||% "suggested"
    )
  }
  if (nrow(refs)) {
    for (i in seq_len(nrow(refs))) {
      ref <- refs[i]
      add(ref$evidence_id %||% ref$evidence_ref %||% paste0("evidence_", i), ref$title %||% ref$evidence_ref %||% "Linked evidence", ref$evidence_type %||% "linked_evidence", "decision_refs", "explicitly linked to decision", "attached", ref$confidence %||% "declared", ref$limitations %||% "")
    }
  }
  if (length(artifacts)) {
    for (artifact in artifacts) {
      meta <- artifact$metadata %||% list()
      intent <- meta$analytical_intent %||% artifact$artifact_type %||% "artifact"
      module <- artifact$source_module %||% meta$source_module %||% "artifact"
      applicable <- if (tolower(intent) %in% c("decision", "diagnostic", "importance", "relationship", "prediction") || module %in% c("semantic_intelligence", "causal_intelligence", "autoquant_eda", "autoquant_shap")) {
        "candidate evidence from artifact metadata"
      } else {
        "low-confidence contextual artifact"
      }
      linked <- if (nrow(refs) && artifact$artifact_id %in% (refs$evidence_ref %||% refs$evidence_id %||% character())) "attached" else "suggested"
      add(artifact$artifact_id, artifact$label %||% meta$caption %||% artifact$artifact_id, intent, module, applicable, linked, meta$quality_score %||% meta$artifact_completeness %||% "metadata", paste(meta$warnings %||% meta$diagnostics %||% character(), collapse = "; "))
    }
  }
  if (!length(rows)) {
    return(data.table::data.table(source_id = character(), title = character(), evidence_type = character(), source = character(), applicability = character(), relationship = character(), confidence = character(), limitations = character(), linkage_status = character()))
  }
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

decision_workflow_gap_guidance <- function(semantic_decision_state = semantic_decision_empty(), semantic_workspace = semantic_workspace_empty(), valuation_state = decision_valuation_empty(), workflow_state = decision_workflow_empty()) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  valuation_state <- decision_valuation_normalize(valuation_state)
  workflow_state <- decision_workflow_normalize(workflow_state)
  validation <- semantic_decision_validate(decision_state, semantic_workspace)
  valuation_summary <- decision_valuation_summary(valuation_state)
  workflow_summary <- decision_workflow_summary(workflow_state)
  rows <- list()
  add <- function(gap, severity, why, action, convert_to = "decision task") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(gap, severity, why, action, convert_to)
  }
  if (nrow(validation)) {
    for (i in seq_len(nrow(validation[status %in% c("error", "warning")]))) {
      row <- validation[status %in% c("error", "warning")][i]
      add(row$check, if (identical(row$status, "error")) "blocked" else "warning", row$issue, row$recommendation, if (grepl("evidence|financial|valuation", row$check, ignore.case = TRUE)) "evidence request" else "authoring task")
    }
  }
  if ((valuation_summary$contexts[[1]] %||% 0L) == 0L) add("valuation_context_missing", "warning", "The decision has no valuation context.", "Create or run a valuation context before review.", "valuation task")
  if (identical(valuation_summary$valuation_status[[1]] %||% "", "not_run")) add("valuation_not_run", "warning", "Economics and recommendation have not been generated.", "Run decision valuation.", "valuation task")
  if ((valuation_summary$registered_artifacts[[1]] %||% 0L) == 0L && identical(valuation_summary$valuation_status[[1]] %||% "", "current")) add("valuation_artifact_not_registered", "warning", "Valuation evidence is not preserved in the collector.", "Register the valuation artifact.", "artifact task")
  if ((workflow_summary$workflows[[1]] %||% 0L) == 0L) add("workflow_missing", "warning", "No governed workflow exists.", "Create a proportional workflow for the decision.", "workflow task")
  if ((workflow_summary$workflows[[1]] %||% 0L) > 0L && identical(workflow_summary$workflow_status[[1]] %||% "", "not_run")) add("workflow_not_assessed", "warning", "Review readiness and implementation follow-through have not been assessed.", "Run workflow assessment.", "workflow task")
  if ((workflow_summary$open_conditions[[1]] %||% 0L) > 0L) add("open_conditions", "blocked", "Approval or review conditions remain open.", "Resolve or explicitly carry forward conditions.", "review question")
  if ((workflow_summary$implementation_deviations[[1]] %||% 0L) > 0L) add("implementation_deviation", "blocked", "Realized implementation differs from approved intent.", "Review deviation and decide whether escalation is required.", "follow-up decision")
  if (!length(rows)) add("no_blocking_gaps", "valid", "No blocking decision-workflow gaps were detected.", "Continue to the next governed step.", "not applicable")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

decision_workflow_next_actions <- function(semantic_decision_state = semantic_decision_empty(), valuation_state = decision_valuation_empty(), workflow_state = decision_workflow_empty()) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  valuation_state <- decision_valuation_normalize(valuation_state)
  workflow_state <- decision_workflow_normalize(workflow_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  summary <- semantic_decision_summary(decision_state)
  valuation_summary <- decision_valuation_summary(valuation_state)
  workflow_summary <- decision_workflow_summary(workflow_state)
  result <- workflow_state$results[[decision_workflow_active_id(workflow_state)]]
  rows <- list()
  add <- function(rank, stage, action, why, required = TRUE, authority_required = FALSE, target = "Semantic Intelligence") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(rank = as.integer(rank), stage, action, why, required = isTRUE(required), authority_required = isTRUE(authority_required), target)
  }
  if ((summary$contexts[[1]] %||% 0L) == 0L) add(1L, "authoring", "Create decision context", "A business decision question is required before alternatives, evidence, valuation, or review can be governed.")
  if ((summary$alternatives[[1]] %||% 0L) == 0L) add(2L, "authoring", "Add baseline and competing alternative", "A decision needs a current-policy baseline and at least one meaningful alternative.")
  if ((summary$alternatives[[1]] %||% 0L) == 1L) add(3L, "authoring", "Add competing alternative", "A single baseline does not create a decision tradeoff.")
  if ((summary$criteria[[1]] %||% 0L) == 0L) add(4L, "authoring", "Add decision criteria", "Criteria make tradeoffs reviewable without collapsing everything into one score.", required = FALSE)
  if ((summary$financial_impacts[[1]] %||% 0L) == 0L) add(5L, "valuation", "Add financial or utility evidence", "Valuation needs costs, benefits, impacts, or explicit unknowns.")
  if (identical(summary$assessment_status[[1]] %||% "", "not_assessed") && (summary$contexts[[1]] %||% 0L) > 0L) add(6L, "validation", "Assess authored decision", "Run deterministic validation before relying on recommendations.")
  if (identical(summary$assessment_status[[1]] %||% "", "stale")) add(7L, "staleness", "Reassess authored decision", "Decision inputs changed after the prior assessment.")
  if ((valuation_summary$contexts[[1]] %||% 0L) == 0L) add(8L, "valuation", "Create valuation context", "The valuation layer reuses alternatives and business references but needs its own bounded context.")
  if ((valuation_summary$contexts[[1]] %||% 0L) > 0L && !identical(valuation_summary$valuation_status[[1]] %||% "", "current")) add(9L, "valuation", "Run decision valuation", "Economics, thresholds, uncertainty, and recommendation must be current before review.")
  if ((valuation_summary$registered_artifacts[[1]] %||% 0L) == 0L && identical(valuation_summary$valuation_status[[1]] %||% "", "current")) add(10L, "evidence", "Register valuation artifact", "Reviewed decisions should point to frozen, collector-visible evidence.")
  if ((workflow_summary$workflows[[1]] %||% 0L) == 0L) add(11L, "workflow", "Create proportional workflow", "Review and approval requirements should match consequence, risk, and authority.")
  if ((workflow_summary$workflows[[1]] %||% 0L) > 0L && identical(workflow_summary$workflow_status[[1]] %||% "", "not_run")) add(12L, "workflow", "Run workflow assessment", "Assess readiness, approval validity, implementation, monitoring, and follow-up candidates.")
  if (!is.null(result) && !identical(workflow_summary$readiness_state[[1]] %||% "", "ready_for_review")) add(13L, "evidence", "Resolve readiness blockers", paste("Readiness is", ui_display_label(workflow_summary$readiness_state[[1]] %||% "unknown")), TRUE)
  if (!is.null(result) && (workflow_summary$reviews[[1]] %||% 0L) == 0L) add(14L, "review", "Request or record scoped review", "Reviewers should see the exact evidence package and scope, not raw authoring panels.", TRUE)
  if (!is.null(result) && (workflow_summary$approvals[[1]] %||% 0L) == 0L) add(15L, "approval", "Record explicit approval decision", "Approval must preserve what was approved, authority basis, conditions, and expiration.", TRUE, TRUE)
  if (!is.null(result) && !nrow(decision_workflow_rows(workflow_state, "implementation_plans", decision_workflow_active_id(workflow_state)))) add(16L, "implementation", "Create implementation plan", "Approved intent should be translated into owner, milestones, rollback, and monitoring.", FALSE)
  if (!is.null(result) && !nrow(decision_workflow_rows(workflow_state, "realized_values", decision_workflow_active_id(workflow_state)))) add(17L, "outcomes", "Attach realized outcome evidence", "Outcome review separates decision quality, implementation quality, and realized value.", FALSE)
  if (!is.null(result) && (workflow_summary$registered_artifacts[[1]] %||% 0L) == 0L) add(18L, "collector", "Register workflow artifact", "The collector should preserve workflow evidence as project memory.", FALSE)
  if (!length(rows)) add(99L, "complete", "Review learning and close or create follow-up", "No deterministic blockers remain; preserve learning and decide whether a follow-up candidate matters.", FALSE)
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)[order(rank)]
}

decision_workflow_staleness_explanation <- function(semantic_decision_state = semantic_decision_empty(), valuation_state = decision_valuation_empty(), workflow_state = decision_workflow_empty()) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  assessment <- decision_state$assessments[[context_id]]
  current_signature <- semantic_decision_signature(decision_state, context_id)
  stale <- !is.null(assessment) && !identical(assessment$signature %||% "", current_signature)
  changed <- decision_state$history[decision_context_id == context_id][order(timestamp, decreasing = TRUE)][1:min(.N, 5L)]
  data.table::data.table(
    stale = stale,
    changed_event = if (nrow(changed)) changed$summary else "No recent decision edits detected.",
    changed_at = if (nrow(changed)) changed$timestamp else NA_character_,
    affected = if (stale) "decision assessment, valuation, recommendation, workflow readiness, review package, approval" else "none",
    not_affected = if (stale) "historical evidence package remains viewable but should not be treated as current" else "current evidence remains usable",
    recovery = if (stale) "Reassess authored decision, rerun valuation, rerun workflow assessment, then refresh review or approval package." else "No stale-state recovery is required."
  )
}

decision_workflow_version_comparison <- function(before, after) {
  before <- before %||% list()
  after <- after %||% list()
  before_names <- names(before)
  after_names <- names(after)
  fields <- sort(unique(c(before_names, after_names)))
  rows <- lapply(fields, function(field) {
    old <- before[[field]]
    new <- after[[field]]
    status <- if (!field %in% before_names) "added" else if (!field %in% after_names) "removed" else if (identical(old, new)) "unchanged" else "changed"
    data.table::data.table(
      field = field,
      change = status,
      before = paste(old %||% "", collapse = ", "),
      after = paste(new %||% "", collapse = ", "),
      materiality = if (field %in% c("selected_alternative", "approved_budget", "authority_tier", "risk_tier", "current_stage", "decision_question")) "material" else if (identical(status, "unchanged")) "none" else "contextual",
      downstream_impact = if (field %in% c("selected_alternative", "approved_budget", "authority_tier", "risk_tier")) "valuation, review, approval, implementation" else if (identical(status, "unchanged")) "none" else "review acknowledgement may be required"
    )
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

decision_workflow_authoring_ui <- function(ns) {
  ui_card(
    "Decision Workflow",
    "Move a valued decision through governed review, approval, implementation tracking, monitoring, realized-value review, and follow-through.",
    uiOutput(ns("decision_workflow_summary")),
    ui_disclosure(
      "Guided Decision Operations",
      uiOutput(ns("decision_workflow_guided_summary")),
      uiOutput(ns("decision_workflow_complexity")),
      uiOutput(ns("decision_workflow_next_actions")),
      open = TRUE
    ),
    ui_disclosure(
      "Evidence Inbox And Gaps",
      uiOutput(ns("decision_workflow_evidence_inbox")),
      uiOutput(ns("decision_workflow_gap_guidance")),
      open = TRUE
    ),
    ui_disclosure(
      "Staleness And Version Awareness",
      uiOutput(ns("decision_workflow_staleness")),
      uiOutput(ns("decision_workflow_version_comparison")),
      open = FALSE
    ),
    ui_disclosure(
      "Workflow",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("workflow_id"), "Workflow ID", placeholder = "workflow_next_quarter_budget"),
        textInput(ns("workflow_decision_context_id"), "Decision ID", placeholder = "Uses active authored decision if blank"),
        textInput(ns("workflow_valuation_artifact_id"), "Valuation Artifact ID", placeholder = "Uses active valuation if blank"),
        textInput(ns("workflow_recommendation_id"), "Recommendation ID", placeholder = "valuation_recommendation"),
        textInput(ns("workflow_selected_alternative"), "Selected Alternative", placeholder = "pilot"),
        selectInput(ns("workflow_type"), "Workflow Type", choices = c("advisory_only", "analyst_review", "manager_approval", "functional_executive_approval", "cross_functional_approval", "enterprise_escalation", "pilot_approval", "emergency_expedited_review")),
        selectInput(ns("workflow_risk_tier"), "Risk Tier", choices = c("low", "medium", "high", "critical")),
        textInput(ns("workflow_authority_tier"), "Authority Tier", placeholder = "manager"),
        selectInput(ns("workflow_current_stage"), "Current Stage", choices = c("draft", "evidence_gathering", "ready_for_review", "under_review", "awaiting_approval", "approved", "conditionally_approved", "implementation_planned", "implementing", "implemented", "monitoring", "outcome_review_due", "outcome_reviewed", "closed")),
        textInput(ns("workflow_required_approvals"), "Required Approvals", placeholder = "finance_owner,budget_manager"),
        textInput(ns("workflow_review_deadline"), "Review Deadline", placeholder = as.character(Sys.Date() + 7)),
        textInput(ns("workflow_evidence_cutoff"), "Evidence Cutoff", placeholder = as.character(Sys.Date()))
      ),
      ui_action_row(actionButton(ns("save_decision_workflow"), "Save Workflow", class = "btn-primary btn-sm")),
      open = TRUE
    ),
    ui_disclosure(
      "Review And Approval",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("workflow_review_id"), "Review ID", placeholder = "review_finance"),
        textInput(ns("workflow_reviewer"), "Reviewer", placeholder = "Finance Owner"),
        selectInput(ns("workflow_review_role"), "Review Role", choices = c("analytical", "causal", "financial", "operational", "risk", "legal", "strategy", "executive", "implementation")),
        selectInput(ns("workflow_review_status"), "Review Status", choices = c("endorse", "endorse_with_conditions", "request_revision", "request_more_evidence", "object", "escalate", "abstain", "out_of_scope")),
        numericInput(ns("workflow_review_confidence"), "Review Confidence", value = NA)
      ),
      textAreaInput(ns("workflow_review_findings"), "Findings", rows = 2),
      textAreaInput(ns("workflow_review_conditions"), "Review Conditions", rows = 2),
      ui_action_row(actionButton(ns("save_workflow_review"), "Save Review", class = "btn-secondary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("workflow_approval_id"), "Approval ID", placeholder = "approval_budget"),
        textInput(ns("workflow_approver"), "Approver", placeholder = "Budget Manager"),
        textInput(ns("workflow_authority_basis"), "Authority Basis", placeholder = "marketing_budget_authority"),
        textInput(ns("workflow_approved_alternative"), "Approved Alternative", placeholder = "pilot"),
        numericInput(ns("workflow_approved_budget"), "Approved Budget", value = NA),
        numericInput(ns("workflow_authority_magnitude"), "Authority Magnitude", value = NA),
        selectInput(ns("workflow_approval_status"), "Approval Status", choices = c("approved", "conditionally_approved", "rejected", "deferred", "escalated", "expired", "revoked", "superseded")),
        textInput(ns("workflow_approval_expiration"), "Approval Expiration", placeholder = as.character(Sys.Date() + 30))
      ),
      textAreaInput(ns("workflow_approval_conditions"), "Approval Conditions", rows = 2),
      ui_action_row(actionButton(ns("save_workflow_approval"), "Save Approval", class = "btn-secondary btn-sm"))
    ),
    ui_disclosure(
      "Implementation And Monitoring",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("workflow_implementation_id"), "Implementation ID", placeholder = "impl_pilot"),
        textInput(ns("workflow_impl_alternative"), "Alternative", placeholder = "pilot"),
        textInput(ns("workflow_impl_levers"), "Levers", placeholder = "budget"),
        textInput(ns("workflow_impl_targets"), "Approved Target Values", placeholder = "budget=110"),
        numericInput(ns("workflow_impl_budget"), "Implementation Budget", value = NA),
        textInput(ns("workflow_impl_owner"), "Owner", placeholder = "Marketing Ops"),
        textInput(ns("workflow_impl_expected_completion"), "Expected Completion", placeholder = as.character(Sys.Date() + 14))
      ),
      textAreaInput(ns("workflow_impl_rollback"), "Rollback Plan", rows = 2),
      ui_action_row(actionButton(ns("save_workflow_plan"), "Save Plan", class = "btn-secondary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        numericInput(ns("workflow_actual_cost"), "Actual Cost", value = NA),
        textInput(ns("workflow_actual_levers"), "Actual Lever Settings", placeholder = "budget=110"),
        textInput(ns("workflow_actual_owner"), "Operational Owner", placeholder = "Marketing Ops"),
        textInput(ns("workflow_actual_quality"), "Evidence Quality", placeholder = "observed")
      ),
      textAreaInput(ns("workflow_deviations"), "Deviations", rows = 2),
      ui_action_row(actionButton(ns("save_workflow_actual"), "Save Realized Implementation", class = "btn-secondary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("workflow_monitor_metric"), "Monitoring Metric", placeholder = "revenue"),
        textInput(ns("workflow_monitor_cadence"), "Cadence", placeholder = "weekly"),
        numericInput(ns("workflow_monitor_threshold"), "Threshold", value = NA),
        textInput(ns("workflow_monitor_owner"), "Owner", placeholder = "Analyst")
      ),
      textInput(ns("workflow_monitor_escalation"), "Escalation Rule", placeholder = "Notify owner if guardrail fails"),
      ui_action_row(actionButton(ns("save_workflow_monitor"), "Save Monitoring", class = "btn-secondary btn-sm"))
    ),
    ui_disclosure(
      "Outcome, Value, And Evidence",
      tags$div(
        class = "aq-form-grid",
        numericInput(ns("workflow_expected_value"), "Expected Value", value = NA),
        numericInput(ns("workflow_realized_value"), "Realized Value", value = NA),
        numericInput(ns("workflow_expected_cost"), "Expected Cost", value = NA),
        numericInput(ns("workflow_realized_cost"), "Realized Cost", value = NA),
        selectInput(ns("workflow_maturation_status"), "Maturation Status", choices = c("not_mature", "preliminary", "mature", "unknown"))
      ),
      textAreaInput(ns("workflow_value_notes"), "Value Review Notes", rows = 2),
      ui_action_row(
        actionButton(ns("save_workflow_value"), "Save Realized Value", class = "btn-secondary btn-sm"),
        actionButton(ns("run_decision_workflow"), "Run Workflow Assessment", class = "btn-primary btn-sm"),
        actionButton(ns("register_decision_workflow_artifact"), "Register Artifact", class = "btn-secondary btn-sm")
      ),
      uiOutput(ns("decision_workflow_message")),
      uiOutput(ns("decision_workflow_readiness")),
      uiOutput(ns("decision_workflow_quality")),
      uiOutput(ns("decision_workflow_followups"))
    )
  )
}

decision_workflow_bind_server <- function(input, output, session, ctx, decision_state, valuation_state, active_decision_id) {
  workflow_state <- reactive(decision_workflow_normalize(ctx$decision_workflow_state()))
  active_workflow_id <- reactive(decision_workflow_active_id(workflow_state()))

  output$decision_workflow_summary <- renderUI({
    summary <- decision_workflow_summary(workflow_state())
    ui_stat_grid(
      ui_stat_tile("Workflows", summary$workflows[[1]], status = if (summary$workflows[[1]] > 0L) "success" else "neutral"),
      ui_stat_tile("Readiness", ui_status_label(summary$readiness_state[[1]]), status = if (identical(summary$readiness_state[[1]], "ready_for_review")) "success" else "warning"),
      ui_stat_tile("Reviews", summary$reviews[[1]], status = if (summary$reviews[[1]] > 0L) "success" else "neutral"),
      ui_stat_tile("Approvals", summary$approvals[[1]], status = if (summary$approvals[[1]] > 0L) "success" else "neutral"),
      ui_stat_tile("Quality", ui_status_label(summary$quality_state[[1]]), status = if (summary$quality_state[[1]] %in% c("high_quality_process", "adequate_process")) "success" else "neutral"),
      ui_stat_tile("Artifacts", summary$registered_artifacts[[1]], status = if (summary$registered_artifacts[[1]] > 0L) "success" else "neutral")
    )
  })

  output$decision_workflow_message <- renderUI({
    ui_callout("Workflow status", workflow_state()$message %||% "Decision workflow has not been run.", status = "info")
  })

  output$decision_workflow_guided_summary <- renderUI({
    card <- decision_workflow_summary_card(decision_state(), valuation_state(), workflow_state())
    render_table(card, engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_workflow_complexity <- renderUI({
    profile <- decision_workflow_complexity_profile(decision_state(), valuation_state(), workflow_state())
    status <- if (profile$complexity_level[[1]] %in% c("executive_escalation", "cross_functional_decision", "high_consequence_decision")) "warning" else "info"
    tagList(
      ui_callout(
        "Proportional workflow",
        paste(
          "Recommended level:",
          ui_display_label(profile$complexity_level[[1]]),
          "-",
          profile$recommended_reviews[[1]],
          "-",
          profile$monitoring_level[[1]]
        ),
        status = status
      ),
      render_table(profile, engine = "html", searchable = FALSE, sortable = FALSE)
    )
  })

  output$decision_workflow_next_actions <- renderUI({
    actions <- decision_workflow_next_actions(decision_state(), valuation_state(), workflow_state())
    if (!nrow(actions)) return(ui_empty_state("No next action available.", "The decision workflow queue will appear after authoring begins."))
    first <- actions[1]
    tagList(
      ui_callout(
        paste("Next:", first$action[[1]]),
        paste(first$why[[1]], "Stage:", ui_display_label(first$stage[[1]]), "Required:", if (isTRUE(first$required[[1]])) "yes" else "no"),
        status = if (isTRUE(first$required[[1]])) "warning" else "info"
      ),
      render_table(actions[, .(rank, stage, action, why, required, authority_required)], engine = "html", searchable = FALSE, sortable = FALSE)
    )
  })

  output$decision_workflow_evidence_inbox <- renderUI({
    artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
    inbox <- decision_workflow_evidence_inbox(artifacts, decision_state(), workflow_state())
    if (!nrow(inbox)) return(ui_empty_state("No candidate evidence yet.", "Run analyses, register artifacts, or add explicit evidence references before review."))
    render_table(inbox[1:min(.N, 12L)], engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_workflow_gap_guidance <- renderUI({
    gaps <- decision_workflow_gap_guidance(decision_state(), tryCatch(ctx$semantic_workspace(), error = function(e) semantic_workspace_empty()), valuation_state(), workflow_state())
    render_table(gaps, engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_workflow_staleness <- renderUI({
    stale <- decision_workflow_staleness_explanation(decision_state(), valuation_state(), workflow_state())
    status <- if (any(stale$stale %||% FALSE)) "warning" else "success"
    tagList(
      ui_callout(
        if (any(stale$stale %||% FALSE)) "Stale-state recovery required" else "No stale-state recovery required",
        stale$recovery[[1]] %||% "",
        status = status
      ),
      render_table(stale, engine = "html", searchable = FALSE, sortable = FALSE)
    )
  })

  output$decision_workflow_version_comparison <- renderUI({
    id <- active_workflow_id()
    rows <- decision_workflow_rows(workflow_state(), "workflows", id)
    if (!nrow(rows)) return(ui_empty_state("No workflow version to compare.", "Save a workflow before inspecting material fields."))
    result <- workflow_state()$results[[id]]
    current <- as.list(rows[1])
    built <- if (!is.null(result$workflow)) result$workflow else current
    comparison <- decision_workflow_version_comparison(current, built)
    render_table(comparison[change != "unchanged"], engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_workflow_readiness <- renderUI({
    result <- workflow_state()$results[[active_workflow_id()]]
    if (is.null(result)) return(ui_empty_state("No review readiness yet.", "Run workflow assessment after saving a workflow."))
    render_table(result$readiness[, .(check, status, readiness_state, reason, required_action)], engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_workflow_quality <- renderUI({
    result <- workflow_state()$results[[active_workflow_id()]]
    if (is.null(result)) return(ui_empty_state("No decision quality assessment yet.", "Run workflow assessment to compare review, approval, implementation, and outcome evidence."))
    render_table(result$quality, engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_workflow_followups <- renderUI({
    result <- workflow_state()$results[[active_workflow_id()]]
    if (is.null(result) || !nrow(result$followups %||% data.table::data.table())) return(ui_empty_state("No follow-up candidates yet.", "Follow-up candidates appear after outcome or implementation evidence is available."))
    render_table(result$followups, engine = "html", searchable = FALSE, sortable = FALSE)
  })

  save_workflow_row <- function(result) {
    if (identical(result$status, "success")) ctx$decision_workflow_state(result$value)
    ctx$decision_workflow_message <- service_result_message(result)
  }

  observeEvent(input$save_decision_workflow, {
    decision_id <- input$workflow_decision_context_id
    if (!nzchar(decision_id %||% "")) decision_id <- active_decision_id()
    workflow_id <- input$workflow_id
    if (!nzchar(workflow_id %||% "")) workflow_id <- paste0("workflow_", decision_id)
    row <- data.table::data.table(
      workflow_id = workflow_id,
      decision_context_id = decision_id,
      valuation_artifact_id = input$workflow_valuation_artifact_id %||% "",
      recommendation_id = input$workflow_recommendation_id %||% "",
      selected_alternative = input$workflow_selected_alternative %||% "",
      workflow_type = input$workflow_type %||% "manager_approval",
      risk_tier = input$workflow_risk_tier %||% "medium",
      authority_tier = input$workflow_authority_tier %||% "manager",
      current_stage = input$workflow_current_stage %||% "draft",
      required_approvals = input$workflow_required_approvals %||% "",
      review_deadline = input$workflow_review_deadline %||% "",
      evidence_cutoff = input$workflow_evidence_cutoff %||% ""
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "workflows", "workflow_id", row, workflow_id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_workflow_review, {
    id <- active_workflow_id()
    row <- data.table::data.table(
      workflow_id = id,
      review_id = input$workflow_review_id %||% "",
      reviewer = input$workflow_reviewer %||% "",
      role = input$workflow_review_role %||% "analytical",
      status = input$workflow_review_status %||% "endorse",
      findings = input$workflow_review_findings %||% "",
      conditions = input$workflow_review_conditions %||% "",
      confidence = input$workflow_review_confidence
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "reviews", "review_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_workflow_approval, {
    id <- active_workflow_id()
    row <- data.table::data.table(
      workflow_id = id,
      approval_id = input$workflow_approval_id %||% "",
      approver = input$workflow_approver %||% "",
      authority_basis = input$workflow_authority_basis %||% "",
      approved_alternative = input$workflow_approved_alternative %||% "",
      approved_budget = input$workflow_approved_budget,
      authority_magnitude = input$workflow_authority_magnitude,
      status = input$workflow_approval_status %||% "approved",
      expiration = input$workflow_approval_expiration %||% "",
      conditions = input$workflow_approval_conditions %||% ""
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "approvals", "approval_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_workflow_plan, {
    id <- active_workflow_id()
    row <- data.table::data.table(
      workflow_id = id,
      implementation_id = input$workflow_implementation_id %||% "",
      selected_alternative = input$workflow_impl_alternative %||% "",
      levers = input$workflow_impl_levers %||% "",
      approved_target_values = input$workflow_impl_targets %||% "",
      budget = input$workflow_impl_budget,
      owners = input$workflow_impl_owner %||% "",
      expected_completion_date = input$workflow_impl_expected_completion %||% "",
      rollback_plan = input$workflow_impl_rollback %||% ""
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "implementation_plans", "implementation_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_workflow_actual, {
    id <- active_workflow_id()
    implementation_id <- input$workflow_implementation_id %||% ""
    row <- data.table::data.table(
      workflow_id = id,
      implementation_evidence_id = paste0("actual_", implementation_id),
      implementation_id = implementation_id,
      actual_cost = input$workflow_actual_cost,
      actual_lever_settings = input$workflow_actual_levers %||% "",
      deviations = input$workflow_deviations %||% "",
      operational_owner = input$workflow_actual_owner %||% "",
      evidence_quality = input$workflow_actual_quality %||% ""
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "implementation_evidence", "implementation_evidence_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_workflow_monitor, {
    id <- active_workflow_id()
    row <- data.table::data.table(
      workflow_id = id,
      monitoring_id = paste0("monitor_", input$workflow_monitor_metric %||% "metric"),
      metric = input$workflow_monitor_metric %||% "",
      cadence = input$workflow_monitor_cadence %||% "",
      threshold = input$workflow_monitor_threshold,
      owner = input$workflow_monitor_owner %||% "",
      escalation_rule = input$workflow_monitor_escalation %||% ""
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "monitoring", "monitoring_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_workflow_value, {
    id <- active_workflow_id()
    row <- data.table::data.table(
      workflow_id = id,
      realized_value_id = paste0("realized_value_", id),
      expected_value = input$workflow_expected_value,
      realized_value = input$workflow_realized_value,
      expected_cost = input$workflow_expected_cost,
      realized_cost = input$workflow_realized_cost,
      maturation_status = input$workflow_maturation_status %||% "unknown",
      notes = input$workflow_value_notes %||% ""
    )
    save_workflow_row(decision_workflow_upsert(workflow_state(), "realized_values", "realized_value_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$run_decision_workflow, {
    result <- decision_workflow_run(workflow_state(), decision_state(), valuation_state())
    save_workflow_row(result)
  }, ignoreInit = TRUE)

  observeEvent(input$register_decision_workflow_artifact, {
    result <- decision_workflow_register_artifact(ctx, workflow_state())
    save_workflow_row(result)
  }, ignoreInit = TRUE)
}

qa_decision_workflow_workspace <- function() {
  rows <- list()
  add <- function(check, ok, message) rows[[length(rows) + 1L]] <<- data.table::data.table(suite = "decision_workflow_workspace", check = check, status = if (isTRUE(ok)) "success" else "error", message)
  add("autoquant_available", decision_workflow_available(), "AutoQuant workflow API is available.")
  semantic <- semantic_decision_empty("qa_project")
  semantic <- semantic_decision_upsert_row(semantic, "contexts", "decision_context_id", data.table::data.table(decision_context_id = "decision_1", decision_question = "What should we do?", authority_id = "authority_1", coverage_id = "coverage_1"), "decision_1")$value
  semantic <- semantic_decision_upsert_row(semantic, "alternatives", "alternative_id", data.table::data.table(decision_context_id = "decision_1", alternative_id = "baseline", name = "Baseline", baseline = TRUE, alternative_type = "do_nothing"), "decision_1")$value
  semantic <- semantic_decision_upsert_row(semantic, "alternatives", "alternative_id", data.table::data.table(decision_context_id = "decision_1", alternative_id = "pilot", name = "Pilot", baseline = FALSE, alternative_type = "pilot"), "decision_1")$value
  valuation <- decision_valuation_empty("qa_project")
  valuation <- decision_valuation_upsert(valuation, "contexts", "valuation_context_id", data.table::data.table(valuation_context_id = "valuation_1", decision_context_id = "decision_1", alternatives_included = "baseline,pilot", baseline_alternative = "baseline", currency = "USD", discount_rate = 0, time_horizon_periods = 1, authority = "authority_1", coverage = "coverage_1"), "valuation_1")$value
  valuation <- decision_valuation_upsert(valuation, "impact_mappings", "mapping_id", data.table::data.table(valuation_context_id = "valuation_1", mapping_id = "impact_1", source_artifact_id = "itt_1", alternative_id = "pilot", evidence_type = "randomized_itt", effect_value = 0.1, affected_population = 1000, duration_periods = 1, unit_value = 5, source_type = "causally_estimated"), "valuation_1")$value
  valuation <- decision_valuation_run(valuation, semantic)$value
  state <- decision_workflow_empty("qa_project")
  state <- decision_workflow_upsert(state, "workflows", "workflow_id", data.table::data.table(workflow_id = "workflow_1", decision_context_id = "decision_1", selected_alternative = "pilot", workflow_type = "pilot_approval", authority_tier = "manager", review_deadline = as.character(Sys.Date() + 7)), "workflow_1")$value
  state <- decision_workflow_upsert(state, "reviews", "review_id", data.table::data.table(workflow_id = "workflow_1", review_id = "review_1", reviewer = "Finance", role = "financial", status = "endorse_with_conditions"), "workflow_1")$value
  state <- decision_workflow_upsert(state, "approvals", "approval_id", data.table::data.table(workflow_id = "workflow_1", approval_id = "approval_1", approver = "Manager", authority_basis = "authority_1", approved_alternative = "pilot", approved_budget = 100, authority_magnitude = 200, status = "conditionally_approved"), "workflow_1")$value
  run <- decision_workflow_run(state, semantic, valuation)
  add("run_success", identical(run$status, "success"), "Decision workflow assessment succeeds.")
  summary <- decision_workflow_summary(run$value)
  add("summary_reports_lifecycle", identical(summary$workflow_status[[1]], "current") && summary$reviews[[1]] == 1L && summary$approvals[[1]] == 1L, "Summary reports review and approval lifecycle.")
  result <- run$value$results[[decision_workflow_active_id(run$value)]]
  add("readiness_and_artifact", nrow(result$readiness) > 0L && identical(result$autoquant_artifact$artifact_envelope$artifact_type, "decision_workflow_artifact"), "Workflow result contains readiness and canonical artifact.")
  add("campaign_seed_table", data.table::is.data.table(decision_workflow_campaign_seeds(run$value)), "Workflow campaign seeds are available.")
  friction <- decision_workflow_friction_inventory()
  add("friction_inventory", nrow(friction) >= 10L && all(c("journey_step", "observed_friction", "completed_fix", "deferred") %in% names(friction)), "Phase 2 records a structured workflow-friction inventory.")
  complexity <- decision_workflow_complexity_profile(semantic, valuation, run$value)
  add("proportional_workflow", nrow(complexity) == 1L && complexity$complexity_level[[1]] %in% c("lightweight_advisory", "standard_decision", "high_consequence_decision", "cross_functional_decision", "executive_escalation"), "Decision complexity classification recommends proportional governance.")
  next_actions <- decision_workflow_next_actions(semantic, valuation, run$value)
  add("next_action_guidance", nrow(next_actions) > 0L && all(c("stage", "action", "why", "required", "authority_required") %in% names(next_actions)), "Deterministic next-action guidance is available.")
  inbox <- decision_workflow_evidence_inbox(list(list(artifact_id = "itt_1", label = "ITT Evidence", artifact_type = "table", source_module = "causal_itt", metadata = list(analytical_intent = "Decision"))), semantic, run$value)
  add("evidence_inbox", nrow(inbox) > 0L && "linkage_status" %in% names(inbox), "Decision evidence inbox suggests bounded candidate evidence without auto-attachment.")
  gaps <- decision_workflow_gap_guidance(semantic, semantic_workspace_empty("qa_project"), valuation, run$value)
  add("evidence_gap_guidance", nrow(gaps) > 0L && all(c("gap", "severity", "action") %in% names(gaps)), "Evidence gaps are represented as actionable guidance.")
  stale <- decision_workflow_staleness_explanation(semantic, valuation, run$value)
  add("staleness_explanation", nrow(stale) > 0L && all(c("affected", "recovery") %in% names(stale)), "Stale-state explanation reports affected objects and recovery sequence.")
  comparison <- decision_workflow_version_comparison(list(selected_alternative = "baseline", risk_tier = "low"), list(selected_alternative = "pilot", risk_tier = "high"))
  add("version_comparison", nrow(comparison[change == "changed"]) == 2L && all(c("materiality", "downstream_impact") %in% names(comparison)), "Version comparison reports material human-readable changes.")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
