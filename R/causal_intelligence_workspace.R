causal_intelligence_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_causal_question",
      "aq_estimand",
      "aq_causal_variable_roles",
      "aq_causal_relationships",
      "aq_causal_context",
      "aq_plan_causal_investigation",
      "aq_causal_planning_artifact"
    ) %in% getNamespaceExports("AutoQuant"))
}

causal_intelligence_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "causal_intelligence_workspace_v1",
    project_id = project_id,
    active_question_id = NA_character_,
    questions = data.table::data.table(),
    roles = data.table::data.table(),
    relationships = data.table::data.table(),
    assessments = list(),
    artifact_registry = character(),
    history = data.table::data.table(
      event_id = character(),
      causal_question_id = character(),
      record_type = character(),
      record_id = character(),
      event_type = character(),
      signature = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

causal_intelligence_record_tables <- function() c("questions", "roles", "relationships")

causal_intelligence_now <- function() as.character(Sys.time())

causal_intelligence_event <- function(causal_question_id, record_type, record_id, event_type, signature, summary) {
  data.table::data.table(
    event_id = paste0("causal_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    causal_question_id = causal_question_id %||% NA_character_,
    record_type = record_type,
    record_id = record_id %||% NA_character_,
    event_type = event_type,
    signature = signature %||% NA_character_,
    summary = summary %||% "",
    timestamp = causal_intelligence_now()
  )
}

causal_intelligence_normalize <- function(state) {
  state <- state %||% causal_intelligence_empty()
  empty <- causal_intelligence_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (table_name in causal_intelligence_record_tables()) {
    if (!data.table::is.data.table(state[[table_name]])) state[[table_name]] <- data.table::as.data.table(state[[table_name]])
  }
  if (!data.table::is.data.table(state$history)) state$history <- data.table::as.data.table(state$history)
  state
}

causal_intelligence_active_question_id <- function(state) {
  state <- causal_intelligence_normalize(state)
  id <- state$active_question_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$questions)) state$questions$causal_question_id[[1]] else NA_character_
}

causal_intelligence_rows <- function(state, table_name, causal_question_id = NULL) {
  state <- causal_intelligence_normalize(state)
  rows <- state[[table_name]]
  if (!nrow(rows) || is.null(causal_question_id) || !nzchar(causal_question_id %||% "")) return(rows)
  target_id <- causal_question_id
  if ("causal_question_id" %in% names(rows)) rows[causal_question_id == target_id] else rows
}

causal_intelligence_signature <- function(state, causal_question_id = causal_intelligence_active_question_id(state)) {
  state <- causal_intelligence_normalize(state)
  pieces <- lapply(causal_intelligence_record_tables(), function(table_name) {
    rows <- causal_intelligence_rows(state, table_name, causal_question_id)
    paste(table_name, nrow(rows), paste(rows$updated_at %||% character(), collapse = ","), sep = ":")
  })
  paste(causal_question_id %||% "", paste(pieces, collapse = "|"), sep = "::")
}

causal_intelligence_upsert_row <- function(state, table_name, id_col, row, causal_question_id = row$causal_question_id %||% NA_character_, event_type = NULL) {
  state <- causal_intelligence_normalize(state)
  if (!table_name %in% causal_intelligence_record_tables()) {
    return(service_result(status = "error", errors = paste("Unsupported causal table:", table_name)))
  }
  row <- data.table::as.data.table(row)
  if (!id_col %in% names(row) || !nzchar(row[[id_col]][[1]] %||% "")) {
    return(service_result(status = "error", errors = paste(id_col, "is required.")))
  }
  row[, updated_at := causal_intelligence_now()]
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
  if (identical(table_name, "questions")) state$active_question_id <- record_id
  signature <- causal_intelligence_signature(state, causal_question_id)
  state$history <- data.table::rbindlist(
    list(state$history, causal_intelligence_event(causal_question_id, table_name, record_id, event_type %||% if (was_existing) "modified" else "created", signature, paste(if (was_existing) "Modified" else "Created", table_name, record_id))),
    use.names = TRUE,
    fill = TRUE
  )
  state$assessments[[causal_question_id]]$stale <- TRUE
  service_result(status = "success", value = state, messages = paste("Saved", table_name, record_id), metadata = list(record_id = record_id, causal_question_id = causal_question_id, signature = signature))
}

causal_intelligence_parse_list <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) character()
  trimws(strsplit(x, ",", fixed = TRUE)[[1]])
}

causal_intelligence_build_autoquant <- function(state, semantic_decision_state = semantic_decision_empty(), semantic_workspace = semantic_workspace_empty()) {
  if (!causal_intelligence_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant causal-intelligence API is unavailable in the current R library. Source or install the updated AutoQuant package to run causal planning."))
  }
  state <- causal_intelligence_normalize(state)
  question_id <- causal_intelligence_active_question_id(state)
  questions <- causal_intelligence_rows(state, "questions", question_id)
  if (!nrow(questions)) return(service_result(status = "error", errors = "No causal question exists."))
  question_row <- questions[1]
  decision_context <- NULL
  decision_result <- semantic_decision_build_autoquant(semantic_decision_state, semantic_workspace)
  if (identical(decision_result$status, "success")) decision_context <- decision_result$value
  question <- tryCatch(
    AutoQuant::aq_causal_question(question = question_row, decision_context = decision_context),
    error = function(e) e
  )
  if (inherits(question, "error")) return(service_result(status = "error", errors = conditionMessage(question)))
  roles <- causal_intelligence_rows(state, "roles", question_id)
  relationships <- causal_intelligence_rows(state, "relationships", question_id)
  assumptions <- causal_intelligence_parse_list(question_row$assumptions %||% "")
  context <- tryCatch(
    AutoQuant::aq_causal_context(
      causal_question = question,
      roles = if (nrow(roles)) roles else NULL,
      relationships = if (nrow(relationships)) relationships else NULL,
      variable_semantics = NULL,
      assumptions = assumptions,
      selection_mechanism = question_row$selection_mechanism %||% NA_character_,
      measurement_mechanism = question_row$measurement_mechanism %||% NA_character_
    ),
    error = function(e) e
  )
  if (inherits(context, "error")) return(service_result(status = "error", errors = conditionMessage(context)))
  service_result(status = "success", value = context)
}

causal_intelligence_assess <- function(state, semantic_decision_state = semantic_decision_empty(), semantic_workspace = semantic_workspace_empty()) {
  state <- causal_intelligence_normalize(state)
  question_id <- causal_intelligence_active_question_id(state)
  context_result <- causal_intelligence_build_autoquant(state, semantic_decision_state, semantic_workspace)
  if (!identical(context_result$status, "success")) return(context_result)
  plan <- tryCatch(AutoQuant::aq_plan_causal_investigation(context_result$value), error = function(e) e)
  if (inherits(plan, "error")) return(service_result(status = "error", errors = conditionMessage(plan)))
  signature <- causal_intelligence_signature(state, question_id)
  state$assessments[[question_id]] <- list(
    context = context_result$value,
    plan = plan,
    signature = signature,
    stale = FALSE,
    assessed_at = causal_intelligence_now()
  )
  state$history <- data.table::rbindlist(
    list(state$history, causal_intelligence_event(question_id, "assessment", question_id, "assessed", signature, "Assessed causal identification plan with AutoQuant")),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = state, messages = "Causal identification plan assessed.", metadata = list(causal_question_id = question_id, signature = signature))
}

causal_intelligence_register_artifact <- function(ctx, state, question_id = causal_intelligence_active_question_id(state)) {
  state <- causal_intelligence_normalize(state)
  assessment <- state$assessments[[question_id]]
  if (is.null(assessment) || isTRUE(assessment$stale)) return(service_result(status = "error", errors = "Run a current causal assessment before registering artifacts."))
  aq_artifact <- tryCatch(AutoQuant::aq_causal_planning_artifact(assessment$context, assessment$plan), error = function(e) e)
  if (inherits(aq_artifact, "error")) return(service_result(status = "error", errors = conditionMessage(aq_artifact)))
  artifact_id <- paste("causal_intelligence", question_id, "planning", sep = "_")
  if (artifact_id %in% (state$artifact_registry %||% character())) {
    ctx$causal_intelligence_state(state)
    return(service_result(status = "success", messages = "No duplicate causal planning artifact was registered."))
  }
  artifact <- create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Causal Identification Plan",
    source_module = "causal_intelligence",
    object = assessment$context$identification,
    content = "Planning-only causal question, estimand, role, graph, identification, and design-eligibility artifact.",
    metadata = list(
      module_id = "causal_intelligence",
      module_run_id = paste0("causal_intelligence_", format(Sys.time(), "%Y%m%d%H%M%S")),
      analytical_intent = "Causal Planning",
      artifact_importance = "critical",
      caption = paste("Causal identification plan for", question_id),
      diagnostics = assessment$context$graph_diagnostics$message,
      recommendations = assessment$plan$recommended_next_actions$reason %||% character(),
      causal_question_id = question_id,
      estimand_id = assessment$context$estimand$estimand_id %||% NA_character_,
      identification_status = assessment$context$identification$identification_status[[1]] %||% NA_character_,
      no_effect_estimated = TRUE,
      supported_actions = aq_artifact$metadata$supported_actions %||% character(),
      prohibited_claims = assessment$plan$prohibited_claims %||% character(),
      signature = causal_intelligence_signature(state, question_id)
    ),
    section = "Causal Intelligence",
    order = 1L
  )
  result <- service_result(
    status = "success",
    artifacts = list(artifact),
    messages = "Causal planning artifact registered.",
    metadata = list(module_id = "causal_intelligence", module_run_id = artifact$metadata$module_run_id, artifact_count = 1L)
  )
  names(result$artifacts) <- artifact_id
  collector <- ctx$append_module_result_to_collector(result, module_id = "causal_intelligence", record_skipped = FALSE)
  ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry %||% character(), artifact_id))
  ctx$causal_intelligence_state(state)
  collector
}

causal_intelligence_summary <- function(state) {
  state <- causal_intelligence_normalize(state)
  question_id <- causal_intelligence_active_question_id(state)
  assessment <- state$assessments[[question_id]]
  identification_status <- if (is.null(assessment)) "not_assessed" else assessment$context$identification$identification_status[[1]] %||% "unknown"
  data.table::data.table(
    questions = nrow(state$questions),
    roles = nrow(causal_intelligence_rows(state, "roles", question_id)),
    relationships = nrow(causal_intelligence_rows(state, "relationships", question_id)),
    assessment_status = if (is.null(assessment)) "not_assessed" else if (!identical(assessment$signature, causal_intelligence_signature(state, question_id))) "stale" else "current",
    identification_status = identification_status,
    registered_artifacts = length(state$artifact_registry %||% character())
  )
}

causal_intelligence_campaign_seeds <- function(state) {
  state <- causal_intelligence_normalize(state)
  summary <- causal_intelligence_summary(state)
  question_id <- causal_intelligence_active_question_id(state)
  rows <- list()
  add <- function(seed_type, priority, reason) {
    rows[[length(rows) + 1L]] <<- data.table::data.table(
      seed_id = paste("causal_intelligence", question_id %||% "none", seed_type, length(rows) + 1L, sep = "_"),
      causal_question_id = question_id %||% NA_character_,
      seed_type = seed_type,
      priority = priority,
      reason = reason,
      source = "causal_intelligence"
    )
  }
  if ((summary$questions[[1]] %||% 0L) == 0L) add("author_causal_question", "high", "No causal question has been authored.")
  if ((summary$roles[[1]] %||% 0L) < 2L) add("assign_causal_roles", "high", "Exposure, outcome, and candidate adjustment roles are incomplete.")
  if ((summary$relationships[[1]] %||% 0L) == 0L) add("author_causal_graph", "medium", "No directed causal assumptions have been authored.")
  if (!identical(summary$assessment_status[[1]] %||% "", "current") && (summary$questions[[1]] %||% 0L) > 0L) add("assess_identification", "medium", "Causal context has not been assessed or is stale.")
  if (identical(summary$identification_status[[1]] %||% "", "insufficient information")) add("collect_identification_evidence", "high", "Identification plan reports insufficient information.")
  if (!length(rows)) {
    return(data.table::data.table(seed_id = character(), causal_question_id = character(), seed_type = character(), priority = character(), reason = character(), source = character()))
  }
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

causal_intelligence_fixture <- function() {
  semantic <- semantic_decision_fixture()
  state <- causal_intelligence_empty("causal_fixture")
  state <- causal_intelligence_upsert_row(state, "questions", "causal_question_id", data.table::data.table(
    causal_question_id = "cq_paid_search_revenue",
    decision_context_id = "decision_next_quarter_budget",
    business_objective = "objective_revenue_growth",
    lever_id = "lever_paid_search_budget",
    exposure = "spend",
    outcome = "revenue",
    population = "eligible customer segments",
    unit_of_analysis = "segment-week",
    time_zero = "campaign start",
    treatment_window = "next quarter",
    outcome_window = "same quarter and four-week lag",
    comparison_condition = "current paid-search spend range",
    intervention_definition = "increase paid-search spend from current validated range to proposed segment-week range",
    estimand = "ATE",
    effect_scale = "incremental revenue difference",
    target_population = "eligible customer segments",
    assumptions = "observational treatment variation exists,historical pre-period is available,no random assignment is currently asserted",
    selection_mechanism = "budget-eligible segments selected by marketing policy",
    measurement_mechanism = "revenue and spend are observed in project data"
  ), "cq_paid_search_revenue")$value
  role_rows <- list(
    list(role_id = "role_spend", variable = "spend", role = "exposure", timing = "time_varying"),
    list(role_id = "role_revenue", variable = "revenue", role = "outcome", timing = "post_treatment"),
    list(role_id = "role_segment", variable = "customer_segment", role = "confounder_candidate", timing = "baseline"),
    list(role_id = "role_clicks", variable = "clicks", role = "mediator_candidate", timing = "post_treatment")
  )
  for (role in role_rows) {
    role$causal_question_id <- "cq_paid_search_revenue"
    state <- causal_intelligence_upsert_row(state, "roles", "role_id", data.table::as.data.table(role), "cq_paid_search_revenue")$value
  }
  edge_rows <- list(
    list(relationship_id = "edge_segment_spend", source_variable = "customer_segment", destination_variable = "spend", relationship_type = "causes"),
    list(relationship_id = "edge_segment_revenue", source_variable = "customer_segment", destination_variable = "revenue", relationship_type = "causes"),
    list(relationship_id = "edge_spend_revenue", source_variable = "spend", destination_variable = "revenue", relationship_type = "may_cause"),
    list(relationship_id = "edge_spend_clicks", source_variable = "spend", destination_variable = "clicks", relationship_type = "causes"),
    list(relationship_id = "edge_clicks_revenue", source_variable = "clicks", destination_variable = "revenue", relationship_type = "causes")
  )
  for (edge in edge_rows) {
    edge$causal_question_id <- "cq_paid_search_revenue"
    state <- causal_intelligence_upsert_row(state, "relationships", "relationship_id", data.table::as.data.table(edge), "cq_paid_search_revenue")$value
  }
  list(state = state, semantic_workspace = semantic$workspace, semantic_decision_state = semantic$state)
}

qa_causal_intelligence_workspace <- function() {
  fixture <- causal_intelligence_fixture()
  state <- fixture$state
  summary <- causal_intelligence_summary(state)
  seeds <- causal_intelligence_campaign_seeds(causal_intelligence_empty())
  availability <- causal_intelligence_available()
  assessed <- if (availability) causal_intelligence_assess(state, fixture$semantic_decision_state, fixture$semantic_workspace) else service_result(status = "warning", warnings = "AutoQuant causal API unavailable for source-level app QA.")
  rows <- list(
    data.table::data.table(check = "state_contract", status = if (identical(state$schema_version, "causal_intelligence_workspace_v1") && nrow(state$questions) == 1L) "success" else "error", message = "Causal workspace state stores authored questions."),
    data.table::data.table(check = "question_relative_roles", status = if (summary$roles[[1]] >= 4L) "success" else "error", message = "Causal roles are question-relative records."),
    data.table::data.table(check = "causal_graph_records", status = if (summary$relationships[[1]] >= 5L) "success" else "error", message = "Directed relationship records are stored without effect estimation."),
    data.table::data.table(check = "autoquant_graceful_availability", status = if (availability || identical(assessed$status, "warning")) "success" else "error", message = "Workbench degrades gracefully when the new AutoQuant causal API is not installed."),
    data.table::data.table(check = "causal_assessment", status = if (!availability || identical(assessed$status, "success")) "success" else "error", message = paste(assessed$errors %||% assessed$warnings %||% "AutoQuant causal assessment returns a planning context.", collapse = " | ")),
    data.table::data.table(check = "campaign_seeds", status = if (nrow(seeds) > 0L) "success" else "error", message = "Missing causal planning work emits campaign seed candidates.")
  )
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

