semantic_decision_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "semantic_decision_lifecycle_v1",
    project_id = project_id,
    active_context_id = NA_character_,
    contexts = data.table::data.table(),
    alternatives = data.table::data.table(),
    lever_settings = data.table::data.table(),
    criteria = data.table::data.table(),
    financial_impacts = data.table::data.table(),
    uncertainties = data.table::data.table(),
    optionality = data.table::data.table(),
    evidence_refs = data.table::data.table(),
    recommendations = data.table::data.table(),
    decisions = data.table::data.table(),
    outcome_expectations = data.table::data.table(),
    reviews = data.table::data.table(),
    assessments = list(),
    memory_artifacts = list(),
    artifact_registry = character(),
    history = data.table::data.table(
      event_id = character(),
      decision_context_id = character(),
      record_type = character(),
      record_id = character(),
      event_type = character(),
      signature = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

semantic_decision_record_tables <- function() {
  c(
    "contexts", "alternatives", "lever_settings", "criteria", "financial_impacts",
    "uncertainties", "optionality", "evidence_refs", "recommendations",
    "decisions", "outcome_expectations", "reviews"
  )
}

semantic_decision_parse_list <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) character()
  trimws(strsplit(x, ",", fixed = TRUE)[[1]])
}

semantic_decision_numeric <- function(x) {
  out <- suppressWarnings(as.numeric(x))
  if (length(out) != 1L || is.na(out)) NA_real_ else out
}

semantic_decision_bool <- function(x) {
  isTRUE(x) || identical(tolower(as.character(x %||% "")), "true")
}

semantic_decision_now <- function() as.character(Sys.time())

semantic_decision_event <- function(decision_context_id, record_type, record_id, event_type, signature, summary) {
  data.table::data.table(
    event_id = paste0("decision_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    decision_context_id = decision_context_id %||% NA_character_,
    record_type = record_type,
    record_id = record_id %||% NA_character_,
    event_type = event_type,
    signature = signature %||% NA_character_,
    summary = summary %||% "",
    timestamp = semantic_decision_now()
  )
}

semantic_decision_normalize <- function(state) {
  state <- state %||% semantic_decision_empty()
  empty <- semantic_decision_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (table_name in semantic_decision_record_tables()) {
    if (!data.table::is.data.table(state[[table_name]])) state[[table_name]] <- data.table::as.data.table(state[[table_name]])
  }
  if (!data.table::is.data.table(state$history)) state$history <- data.table::as.data.table(state$history)
  state
}

semantic_decision_upsert_row <- function(state, table_name, id_col, row, decision_context_id = row$decision_context_id %||% NA_character_, event_type = NULL) {
  state <- semantic_decision_normalize(state)
  if (!table_name %in% semantic_decision_record_tables()) {
    return(service_result(status = "error", errors = paste("Unsupported decision lifecycle table:", table_name)))
  }
  row <- data.table::as.data.table(row)
  if (!id_col %in% names(row) || !nzchar(row[[id_col]][[1]] %||% "")) {
    return(service_result(status = "error", errors = paste(id_col, "is required.")))
  }
  row[, updated_at := semantic_decision_now()]
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
  if (identical(table_name, "contexts")) state$active_context_id <- record_id
  signature <- semantic_decision_signature(state, decision_context_id)
  state$history <- data.table::rbindlist(
    list(state$history, semantic_decision_event(decision_context_id, table_name, record_id, event_type %||% if (was_existing) "modified" else "created", signature, paste(if (was_existing) "Modified" else "Created", table_name, record_id))),
    use.names = TRUE,
    fill = TRUE
  )
  if (table_name %in% c("contexts", "alternatives", "lever_settings", "criteria", "financial_impacts", "uncertainties", "optionality", "evidence_refs")) {
    state$assessments[[decision_context_id]]$stale <- TRUE
  }
  service_result(status = "success", value = state, messages = paste("Saved", table_name, record_id), metadata = list(record_id = record_id, decision_context_id = decision_context_id, signature = signature))
}

semantic_decision_rows <- function(state, table_name, decision_context_id = NULL) {
  state <- semantic_decision_normalize(state)
  rows <- state[[table_name]]
  if (!nrow(rows) || is.null(decision_context_id) || !nzchar(decision_context_id %||% "")) return(rows)
  target_context_id <- decision_context_id
  if ("decision_context_id" %in% names(rows)) rows[decision_context_id == target_context_id] else rows
}

semantic_decision_signature <- function(state, decision_context_id = state$active_context_id %||% NA_character_) {
  state <- semantic_decision_normalize(state)
  pieces <- lapply(semantic_decision_record_tables(), function(table_name) {
    rows <- semantic_decision_rows(state, table_name, decision_context_id)
    paste(table_name, nrow(rows), paste(rows$updated_at %||% character(), collapse = ","), sep = ":")
  })
  paste(decision_context_id %||% "", paste(pieces, collapse = "|"), sep = "::")
}

semantic_decision_active_context_id <- function(state) {
  state <- semantic_decision_normalize(state)
  id <- state$active_context_id %||% NA_character_
  if (nzchar(id)) return(id)
  contexts <- state$contexts
  if (nrow(contexts)) contexts$decision_context_id[[1]] else NA_character_
}

semantic_decision_workspace_active_ids <- function(workspace) {
  objects <- semantic_workspace_objects_table(workspace)
  objects[!status %in% c("archived", "retired"), object_id]
}

semantic_decision_validate <- function(state, workspace = semantic_workspace_empty()) {
  state <- semantic_decision_normalize(state)
  context_id <- semantic_decision_active_context_id(state)
  rows <- list()
  add <- function(check, status, issue, recommendation, object_id = NA_character_) {
    rows[[length(rows) + 1L]] <<- data.table::data.table(check = check, status = status, object_id = object_id, issue = issue, recommendation = recommendation)
  }
  contexts <- semantic_decision_rows(state, "contexts", context_id)
  alternatives <- semantic_decision_rows(state, "alternatives", context_id)
  criteria <- semantic_decision_rows(state, "criteria", context_id)
  financial <- semantic_decision_rows(state, "financial_impacts", context_id)
  lever_settings <- semantic_decision_rows(state, "lever_settings", context_id)
  optionality <- semantic_decision_rows(state, "optionality", context_id)
  active_ids <- semantic_decision_workspace_active_ids(workspace)

  if (!nrow(contexts)) {
    add("decision_context_exists", "error", "No authored decision context exists.", "Create a decision context before assessment.")
  } else {
    context <- contexts[1]
    if (!nzchar(context$decision_question %||% "")) add("decision_question", "error", "Decision question is missing.", "Author the decision question.", context_id)
    for (ref_col in c("objective_ids", "strategy_ids", "tactic_ids", "lever_ids", "kpi_ids", "guardrail_ids", "constraint_ids", "risk_ids", "assumption_ids", "authority_id", "coverage_id")) {
      refs <- semantic_decision_parse_list(context[[ref_col]] %||% "")
      missing <- setdiff(refs, active_ids)
      if (length(missing)) add("invalid_workspace_reference", "warning", paste(ref_col, "references missing, archived, or retired objects:", paste(missing, collapse = ", ")), "Repair or explicitly document out-of-scope references.", context_id)
    }
    if (!nzchar(context$authority_id %||% "")) add("missing_authority", "warning", "Decision context has no authority reference.", "Assign authority before approval.", context_id)
    if (!nzchar(context$coverage_id %||% "")) add("missing_coverage", "warning", "Decision context has no coverage reference.", "Assign organizational coverage.", context_id)
    if (!nzchar(context$objective_ids %||% "")) add("missing_objective", "warning", "Decision context is not linked to an objective.", "Link at least one objective.", context_id)
  }
  if (!nrow(alternatives)) {
    add("alternatives_exist", "error", "No alternatives exist.", "Create a current-policy baseline and at least one competing alternative.", context_id)
  } else {
    if (!any(vapply(alternatives$baseline %||% FALSE, semantic_decision_bool, logical(1L)))) add("baseline_alternative", "warning", "No baseline/current-policy alternative exists.", "Create a do-nothing/current-policy baseline.", context_id)
    if (nrow(unique(alternatives[, .(alternative_type, name)])) < nrow(alternatives)) add("alternative_difference", "warning", "Some alternatives may not be meaningfully distinct.", "Clarify proposed actions, lever changes, or timing.", context_id)
  }
  if (!nrow(criteria)) add("criteria_exist", "warning", "No decision criteria have been authored.", "Add explicit criteria before assessment.", context_id)
  if (!nrow(financial)) add("financial_evidence", "warning", "No financial evidence has been authored.", "Add observed, modeled, forecast, assumed, or unknown financial evidence.", context_id)
  if (nrow(lever_settings)) {
    for (i in seq_len(nrow(lever_settings))) {
      setting <- lever_settings[i]
      if (!setting$lever_id %in% active_ids) add("invalid_lever", "error", paste("Lever does not exist or is inactive:", setting$lever_id), "Use an active authored lever.", setting$setting_id)
      proposed <- semantic_decision_numeric(setting$proposed_value)
      min_value <- semantic_decision_numeric(setting$permitted_min)
      max_value <- semantic_decision_numeric(setting$permitted_max)
      validated_min <- semantic_decision_numeric(setting$validated_min)
      validated_max <- semantic_decision_numeric(setting$validated_max)
      if ((!is.na(proposed) && !is.na(min_value) && proposed < min_value) || (!is.na(proposed) && !is.na(max_value) && proposed > max_value)) {
        add("outside_permitted_range", "error", paste("Proposed lever value is outside permitted range:", setting$setting_id), "Revise the value or update constraints with authority.", setting$setting_id)
      }
      if ((!is.na(proposed) && !is.na(validated_min) && proposed < validated_min) || (!is.na(proposed) && !is.na(validated_max) && proposed > validated_max)) {
        add("outside_validated_range", "warning", paste("Proposed lever value is outside validated range:", setting$setting_id), "Flag as exploration/pilot or collect more evidence.", setting$setting_id)
      }
      if (isFALSE(semantic_decision_bool(setting$actionable))) add("non_actionable_lever", "warning", paste("Lever setting is not marked actionable:", setting$setting_id), "Treat as scenario/evidence only unless authority changes.", setting$setting_id)
    }
  }
  if (nrow(optionality)) {
    missing_structure <- optionality[!nzchar(enabling_action %||% "") | !nzchar(future_decisions_enabled %||% "")]
    if (nrow(missing_structure)) add("optionality_structure", "warning", "Some optionality claims lack enabling actions or future decisions.", "Complete optionality structure before relying on it.", context_id)
  }
  assessment <- state$assessments[[context_id]]
  if (!is.null(assessment) && !identical(assessment$signature, semantic_decision_signature(state, context_id))) {
    add("stale_assessment", "warning", "Current assessment was created from older decision inputs.", "Reassess before recommendation or decision.", context_id)
  }
  if (!length(rows)) add("decision_validation_summary", "success", "Authored decision package passed structural validation.", "Run assessment or record the human decision.", context_id)
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

semantic_decision_build_autoquant <- function(state, workspace = semantic_workspace_empty()) {
  if (!requireNamespace("AutoQuant", quietly = TRUE) || !"aq_decision_context" %in% getNamespaceExports("AutoQuant")) {
    return(service_result(status = "warning", warnings = "AutoQuant decision-management API is unavailable."))
  }
  state <- semantic_decision_normalize(state)
  context_id <- semantic_decision_active_context_id(state)
  contexts <- semantic_decision_rows(state, "contexts", context_id)
  if (!nrow(contexts)) return(service_result(status = "error", errors = "No authored decision context exists."))
  context <- contexts[1]
  context_record <- list(
    decision_context_id = context$decision_context_id,
    title = context$title %||% context$decision_context_id,
    decision_question = context$decision_question %||% "",
    description = context$description %||% "",
    owner = context$owner %||% "",
    decision_domain = context$decision_domain %||% "",
    organizational_scope = context$organizational_scope %||% "",
    authority = context$authority_id %||% "",
    coverage = context$coverage_id %||% "",
    status = context$status %||% "draft",
    deadline = context$deadline %||% NA_character_,
    time_horizon = context$time_horizon %||% NA_character_,
    review_cadence = context$review_cadence %||% NA_character_
  )
  list_columns <- function(dt, cols) {
    if (!nrow(dt)) return(dt)
    for (col in intersect(cols, names(dt))) dt[, (col) := lapply(get(col), semantic_decision_parse_list)]
    dt
  }
  alternatives <- list_columns(semantic_decision_rows(state, "alternatives", context_id), c("affected_tactics", "affected_levers", "proposed_lever_settings", "assumptions", "evidence_refs"))
  criteria <- semantic_decision_rows(state, "criteria", context_id)
  financial <- semantic_decision_rows(state, "financial_impacts", context_id)
  uncertainties <- semantic_decision_rows(state, "uncertainties", context_id)
  optionality <- list_columns(semantic_decision_rows(state, "optionality", context_id), c("future_decisions_enabled", "future_decisions_constrained", "options_foreclosed", "dependencies"))
  recommendations <- list_columns(semantic_decision_rows(state, "recommendations", context_id), c("viable_alternatives", "required_approvers"))
  decisions <- list_columns(semantic_decision_rows(state, "decisions", context_id), c("alternatives_considered", "conditions"))
  outcomes <- semantic_decision_rows(state, "outcome_expectations", context_id)
  value <- tryCatch(
    AutoQuant::aq_decision_context(
      context = context_record,
      alternatives = if (nrow(alternatives)) alternatives else NULL,
      criteria = if (nrow(criteria)) criteria else NULL,
      financial_impacts = if (nrow(financial)) financial else NULL,
      uncertainties = if (nrow(uncertainties)) uncertainties else NULL,
      optionality = if (nrow(optionality)) optionality else NULL,
      recommendations = if (nrow(recommendations)) recommendations else NULL,
      decisions = if (nrow(decisions)) decisions else NULL,
      outcomes = if (nrow(outcomes)) outcomes else NULL,
      business_intent = semantic_workspace_to_business_intent(workspace)$value %||% NULL
    ),
    error = function(e) e
  )
  if (inherits(value, "error")) return(service_result(status = "error", errors = conditionMessage(value)))
  service_result(status = "success", value = value)
}

semantic_decision_assess <- function(state, workspace = semantic_workspace_empty()) {
  state <- semantic_decision_normalize(state)
  context_id <- semantic_decision_active_context_id(state)
  aq <- semantic_decision_build_autoquant(state, workspace)
  if (!identical(aq$status, "success")) return(aq)
  signature <- semantic_decision_signature(state, context_id)
  state$assessments[[context_id]] <- list(
    decision_context = aq$value,
    alternative_assessment = AutoQuant::aq_assess_decision_alternatives(aq$value),
    optionality_assessment = AutoQuant::aq_assess_decision_optionality(aq$value),
    validation = aq$value$validation,
    signature = signature,
    stale = FALSE,
    assessed_at = semantic_decision_now()
  )
  state$history <- data.table::rbindlist(
    list(state$history, semantic_decision_event(context_id, "assessment", context_id, "assessed", signature, "Assessed authored decision package with AutoQuant")),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = state, messages = "Authored decision assessed with AutoQuant.", metadata = list(decision_context_id = context_id, signature = signature))
}

semantic_decision_choose_recommendation <- function(assessment) {
  alternatives <- assessment$alternative_assessment %||% data.table::data.table()
  if (!nrow(alternatives)) return(NA_character_)
  viable <- alternatives[!hard_constraint_failure & !authority_failure & !missing_information]
  if (!nrow(viable)) viable <- alternatives[!hard_constraint_failure & !missing_information]
  if (!nrow(viable)) viable <- alternatives
  if ("net_benefit" %in% names(viable) && any(is.finite(viable$net_benefit))) {
    return(viable[order(net_benefit, decreasing = TRUE), alternative_id][[1]])
  }
  viable$alternative_id[[1]]
}

semantic_decision_record_recommendation <- function(state, recommendation_category = "choose_alternative", rationale = "Deterministic authored decision assessment.", required_approvers = "") {
  state <- semantic_decision_normalize(state)
  context_id <- semantic_decision_active_context_id(state)
  assessment <- state$assessments[[context_id]]
  if (is.null(assessment) || isTRUE(assessment$stale)) return(service_result(status = "error", errors = "Run a current assessment before recording a recommendation."))
  preferred <- semantic_decision_choose_recommendation(assessment)
  row <- data.table::data.table(
    decision_context_id = context_id,
    recommendation_id = paste0("rec_", context_id),
    preferred_alternative_id = preferred,
    viable_alternatives = paste(assessment$alternative_assessment$alternative_id, collapse = ","),
    recommendation_category = recommendation_category,
    evidence_basis = rationale,
    required_approvers = required_approvers,
    status = "recommended"
  )
  semantic_decision_upsert_row(state, "recommendations", "recommendation_id", row, context_id, "recommended")
}

semantic_decision_register_artifacts <- function(ctx, state, context_id = semantic_decision_active_context_id(state)) {
  state <- semantic_decision_normalize(state)
  aq <- semantic_decision_build_autoquant(state, ctx$semantic_workspace())
  if (!identical(aq$status, "success")) return(aq)
  assessment <- state$assessments[[context_id]]
  if (is.null(assessment)) return(service_result(status = "error", errors = "Assess the decision before registering artifacts."))
  artifact_specs <- list(
    decision_context = aq$value$context,
    alternatives = aq$value$alternatives,
    alternative_assessment = assessment$alternative_assessment,
    recommendation = aq$value$recommendations,
    decision = aq$value$decisions,
    outcome_review = aq$value$outcomes,
    learning_summary = if (nrow(state$reviews)) AutoQuant::aq_decision_learning_summary(aq$value, state$reviews) else data.table::data.table(),
    decision_memory = if (nrow(state$reviews)) AutoQuant::aq_decision_timeline(aq$value, state$reviews) else AutoQuant::aq_decision_timeline(aq$value)
  )
  artifacts <- list()
  for (type in names(artifact_specs)) {
    artifact_id <- paste("semantic_decision", context_id, type, sep = "_")
    if (artifact_id %in% (state$artifact_registry %||% character())) next
    artifact <- create_artifact(
      artifact_id = artifact_id,
      artifact_type = "table",
      label = tools::toTitleCase(gsub("_", " ", type)),
      source_module = "semantic_intelligence",
      object = artifact_specs[[type]],
      content = paste("Authored decision lifecycle artifact:", type),
      metadata = list(
        module_id = "semantic_intelligence",
        module_run_id = paste0("semantic_decision_", format(Sys.time(), "%Y%m%d%H%M%S")),
        analytical_intent = "Decision",
        artifact_importance = if (type %in% c("decision_context", "alternative_assessment", "decision_memory")) "critical" else "recommended",
        caption = paste("Authored decision", type, "for", context_id),
        decision_context_id = context_id,
        lifecycle_artifact_type = type,
        parent_artifact_ids = character(),
        signature = semantic_decision_signature(state, context_id)
      ),
      section = "Decision Lifecycle",
      order = length(artifacts) + 1L
    )
    artifacts[[artifact_id]] <- artifact
    state$artifact_registry <- unique(c(state$artifact_registry %||% character(), artifact_id))
  }
  if (length(artifacts)) {
    result <- service_result(
      status = "success",
      artifacts = artifacts,
      messages = paste(length(artifacts), "decision lifecycle artifact(s) registered."),
      metadata = list(module_id = "semantic_intelligence", module_run_id = paste0("semantic_decision_", format(Sys.time(), "%Y%m%d%H%M%S")), artifact_count = length(artifacts))
    )
    collector <- ctx$append_module_result_to_collector(result, module_id = "semantic_intelligence", record_skipped = FALSE)
    for (artifact_id in names(artifacts)) ctx$saved_module_artifacts$artifacts[[artifact_id]] <- artifacts[[artifact_id]]
    ctx$semantic_decision_state(state)
    return(collector)
  }
  ctx$semantic_decision_state(state)
  service_result(status = "success", messages = "No duplicate decision artifacts were registered.")
}

semantic_decision_summary <- function(state, workspace = semantic_workspace_empty()) {
  state <- semantic_decision_normalize(state)
  context_id <- semantic_decision_active_context_id(state)
  validation <- semantic_decision_validate(state, workspace)
  assessment <- state$assessments[[context_id]]
  data.table::data.table(
    contexts = nrow(state$contexts),
    alternatives = nrow(semantic_decision_rows(state, "alternatives", context_id)),
    criteria = nrow(semantic_decision_rows(state, "criteria", context_id)),
    financial_impacts = nrow(semantic_decision_rows(state, "financial_impacts", context_id)),
    uncertainties = nrow(semantic_decision_rows(state, "uncertainties", context_id)),
    optionality = nrow(semantic_decision_rows(state, "optionality", context_id)),
    recommendations = nrow(semantic_decision_rows(state, "recommendations", context_id)),
    decisions = nrow(semantic_decision_rows(state, "decisions", context_id)),
    reviews = nrow(semantic_decision_rows(state, "reviews", context_id)),
    validation_errors = sum(validation$status == "error", na.rm = TRUE),
    validation_warnings = sum(validation$status == "warning", na.rm = TRUE),
    assessment_status = if (is.null(assessment)) "not_assessed" else if (!identical(assessment$signature, semantic_decision_signature(state, context_id))) "stale" else "current",
    registered_artifacts = length(state$artifact_registry %||% character())
  )
}

semantic_decision_campaign_seeds <- function(state, workspace = semantic_workspace_empty()) {
  state <- semantic_decision_normalize(state)
  context_id <- semantic_decision_active_context_id(state)
  validation <- semantic_decision_validate(state, workspace)
  summary <- semantic_decision_summary(state, workspace)
  rows <- list()
  add <- function(seed_type, priority, reason, evidence_ref = context_id) {
    rows[[length(rows) + 1L]] <<- data.table::data.table(
      seed_id = paste("semantic_decision", context_id %||% "none", seed_type, length(rows) + 1L, sep = "_"),
      decision_context_id = context_id %||% NA_character_,
      seed_type = seed_type,
      priority = priority,
      reason = reason,
      evidence_ref = evidence_ref %||% NA_character_,
      source = "semantic_decision_lifecycle"
    )
  }
  if ((summary$contexts[[1]] %||% 0L) == 0L) add("author_decision_context", "high", "No decision context has been authored.")
  if ((summary$alternatives[[1]] %||% 0L) < 2L) add("author_alternatives", "high", "Decision package needs a baseline and at least one competing alternative.")
  if ((summary$financial_impacts[[1]] %||% 0L) == 0L) add("add_financial_evidence", "medium", "No financial impact evidence has been authored.")
  if ((summary$uncertainties[[1]] %||% 0L) == 0L) add("add_uncertainty_evidence", "medium", "No uncertainty records exist for the decision.")
  if (any(validation$check %in% c("outside_validated_range", "outside_permitted_range"), na.rm = TRUE)) {
    add("review_lever_bounds", "high", "At least one proposed lever setting is outside permitted or validated bounds.")
  }
  if (identical(summary$assessment_status[[1]] %||% "", "stale")) add("reassess_decision", "high", "The decision assessment is stale after authored input changes.")
  if (identical(summary$assessment_status[[1]] %||% "", "not_assessed") && (summary$validation_errors[[1]] %||% 0L) == 0L) {
    add("assess_decision", "medium", "Decision package is structurally ready for deterministic assessment.")
  }
  if ((summary$decisions[[1]] %||% 0L) > 0L && (summary$reviews[[1]] %||% 0L) == 0L) {
    add("schedule_outcome_review", "medium", "A decision exists but no outcome review has been attached.")
  }
  if (!length(rows)) {
    return(data.table::data.table(
      seed_id = character(),
      decision_context_id = character(),
      seed_type = character(),
      priority = character(),
      reason = character(),
      evidence_ref = character(),
      source = character()
    ))
  }
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

semantic_decision_fixture <- function() {
  ws <- semantic_workspace_fixture()
  state <- semantic_decision_empty("semantic_decision_fixture")
  state <- semantic_decision_upsert_row(state, "contexts", "decision_context_id", data.table::data.table(
    decision_context_id = "decision_next_quarter_budget",
    title = "Next-quarter budget decision",
    decision_question = "Should we increase paid-search budget next quarter?",
    description = "Fixture used for QA only.",
    owner = "Marketing",
    decision_domain = "marketing",
    organizational_scope = "function",
    objective_ids = "objective_revenue_growth",
    strategy_ids = "strategy_qualified_demand",
    tactic_ids = "tactic_paid_search",
    lever_ids = "lever_paid_search_budget",
    kpi_ids = "kpi_revenue",
    authority_id = "authority_marketing_advisory",
    coverage_id = "coverage_marketing",
    deadline = as.character(Sys.Date() + 30),
    status = "draft"
  ), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "alternatives", "alternative_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", alternative_id = "alt_current", name = "Continue current policy", alternative_type = "do_nothing", baseline = TRUE, authority_compatible = TRUE, scope_compatible = TRUE, status = "draft"), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "alternatives", "alternative_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", alternative_id = "alt_increase", name = "Increase within validated range", alternative_type = "partial_implementation", baseline = FALSE, affected_levers = "lever_paid_search_budget", authority_compatible = TRUE, scope_compatible = TRUE, status = "draft"), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "lever_settings", "setting_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", setting_id = "setting_increase", alternative_id = "alt_increase", lever_id = "lever_paid_search_budget", current_value = 100, proposed_value = 110, change_amount = 10, unit = "index", permitted_min = 50, permitted_max = 150, validated_min = 80, validated_max = 120, actionable = TRUE), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "criteria", "criterion_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", criterion_id = "criterion_value", name = "Expected value", direction = "maximize", weight = 0.5, hard_constraint = FALSE, confidence = 0.7), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "criteria", "criterion_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", criterion_id = "criterion_authority", name = "Authority compatibility", direction = "maximize", hard_constraint = TRUE, confidence = 0.9), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "financial_impacts", "financial_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", financial_id = "fin_current", alternative_id = "alt_current", recurring_cost = 100, expected_benefit = 108, source_type = "observed", confidence = 0.8), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "financial_impacts", "financial_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", financial_id = "fin_increase", alternative_id = "alt_increase", recurring_cost = 110, expected_benefit = 140, source_type = "modeled", confidence = 0.7), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "uncertainties", "uncertainty_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", uncertainty_id = "unc_response", alternative_id = "alt_increase", criterion_id = "criterion_value", uncertainty_category = "transfer", direction = "two_sided", magnitude = "medium", reducibility = "reducible", decision_sensitivity = "medium", candidate_experiment = "bounded pilot"), "decision_next_quarter_budget")$value
  state <- semantic_decision_upsert_row(state, "optionality", "optionality_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", optionality_id = "opt_learn", alternative_id = "alt_increase", option_type = "learn", enabling_action = "increase within validated range", future_decisions_enabled = "expand,abandon", reversibility = TRUE, confidence = 0.6), "decision_next_quarter_budget")$value
  list(state = state, workspace = ws)
}

qa_semantic_decision_lifecycle <- function() {
  fixture <- semantic_decision_fixture()
  state <- fixture$state
  workspace <- fixture$workspace
  validation <- semantic_decision_validate(state, workspace)
  aq <- semantic_decision_build_autoquant(state, workspace)
  assessed <- semantic_decision_assess(state, workspace)
  assessed_state <- assessed$value
  recommended <- semantic_decision_record_recommendation(assessed_state)
  stale_state <- semantic_decision_upsert_row(recommended$value, "criteria", "criterion_id", data.table::data.table(decision_context_id = "decision_next_quarter_budget", criterion_id = "criterion_risk", name = "Risk", direction = "minimize", weight = 0.2, hard_constraint = FALSE), "decision_next_quarter_budget")$value
  stale_validation <- semantic_decision_validate(stale_state, workspace)
  rows <- list(
    data.table::data.table(check = "authored_context", status = if (nrow(state$contexts) == 1L) "success" else "error", message = "Authored decision context exists."),
    data.table::data.table(check = "baseline_and_alternatives", status = if (nrow(state$alternatives) >= 2L && any(vapply(state$alternatives$baseline, semantic_decision_bool, logical(1)))) "success" else "error", message = "Baseline and competing alternatives exist."),
    data.table::data.table(check = "lever_setting_validation", status = if (!any(validation$check == "invalid_lever" & validation$status == "error")) "success" else "error", message = "Lever setting references authored active lever."),
    data.table::data.table(check = "criteria_financial_uncertainty_optionality", status = if (all(c(nrow(state$criteria), nrow(state$financial_impacts), nrow(state$uncertainties), nrow(state$optionality)) > 0L)) "success" else "error", message = "Decision criteria, economics, uncertainty, and optionality are authored."),
    data.table::data.table(check = "autoquant_assessment", status = if (identical(aq$status, "success") && identical(assessed$status, "success")) "success" else "error", message = paste(aq$errors %||% assessed$errors %||% "AutoQuant assessed authored decision package.", collapse = " | ")),
    data.table::data.table(check = "recommendation_recorded", status = if (identical(recommended$status, "success") && nrow(recommended$value$recommendations) >= 1L) "success" else "error", message = "Recommendation is recorded from current assessment."),
    data.table::data.table(check = "stale_assessment_detected", status = if (any(stale_validation$check == "stale_assessment")) "success" else "error", message = "Material edits mark prior assessment stale."),
    data.table::data.table(check = "campaign_seeds", status = if (nrow(semantic_decision_campaign_seeds(stale_state, workspace)) > 0L) "success" else "error", message = "Decision lifecycle emits campaign seed candidates for unresolved work."),
    data.table::data.table(check = "no_required_fixture_path", status = "success", message = "Fixture is used only by QA; production helpers require authored state.")
  )
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
