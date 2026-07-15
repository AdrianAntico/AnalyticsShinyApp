# Active Knowledge Compilation Runtime Phase 8:
# mutation governance and the reusable governed Class 3 framework.

knowledge_runtime_compiler_version <- function() {
  "0.8.0"
}

knowledge_runtime_task_taxonomy <- function() {
  base <- kc_dt(list(
    list(task_code = "explain_workflow_state", task_family = "workflow", required_bundle = "decision_workflow_guidance", output_schema = "workflow_explanation", allowed_actions = c("module.open", "result.inspect"), action_class = 0L, escalation_conditions = c("authority_missing", "decision_blocked"), prohibited_actions = c("approve_decision", "mutate_project")),
    list(task_code = "recommend_supported_next_action", task_family = "workflow", required_bundle = "decision_workflow_guidance", output_schema = "next_action_guidance", allowed_actions = c("module.open", "analysis.preflight", "report.open"), action_class = 1L, escalation_conditions = c("unsupported_action", "authority_required"), prohibited_actions = c("invent_action", "direct_execution")),
    list(task_code = "summarize_observational_plan", task_family = "causal", required_bundle = "observational_causal_synthesis", output_schema = "observational_summary", allowed_actions = c("result.inspect"), action_class = 0L, escalation_conditions = c("effect_claim_requested", "identification_weak"), prohibited_actions = c("claim_effect_estimated")),
    list(task_code = "extract_supported_claims", task_family = "claim", required_bundle = "claim_runtime", output_schema = "claim_assessment", allowed_actions = c("result.inspect"), action_class = 0L, escalation_conditions = c("contradiction", "evidence_missing"), prohibited_actions = c("causal_overclaim", "unsupported_claim")),
    list(task_code = "explain_epistemic_finding", task_family = "epistemic", required_bundle = "epistemic_runtime", output_schema = "epistemic_explanation", allowed_actions = c("result.inspect"), action_class = 0L, escalation_conditions = c("actor_sensitive", "authority_sensitive"), prohibited_actions = c("motive_diagnosis")),
    list(task_code = "navigate_page", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_action", allowed_actions = c("module.open"), action_class = 1L, escalation_conditions = c("unknown_target"), prohibited_actions = c("hidden_navigation")),
    list(task_code = "open_artifact", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_action", allowed_actions = c("artifact.inspect"), action_class = 1L, escalation_conditions = c("unknown_artifact"), prohibited_actions = c("invent_artifact_id")),
    list(task_code = "run_deterministic_validation", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_action", allowed_actions = c("analysis.preflight"), action_class = 2L, escalation_conditions = c("dataset_missing", "module_unavailable"), prohibited_actions = c("autonomous_analysis_change")),
    list(task_code = "generate_workflow_summary", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_draft", allowed_actions = c("result.inspect"), action_class = 2L, escalation_conditions = c("authority_missing"), prohibited_actions = c("submit_review")),
    list(task_code = "generate_observational_summary", task_family = "operator", required_bundle = "observational_causal_synthesis", output_schema = "operator_draft", allowed_actions = c("result.inspect"), action_class = 2L, escalation_conditions = c("effect_claim_requested"), prohibited_actions = c("estimate_effect")),
    list(task_code = "create_review_draft", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_draft", allowed_actions = c("result.inspect"), action_class = 2L, escalation_conditions = c("human_review_required"), prohibited_actions = c("approve_or_submit_review")),
    list(task_code = "create_campaign_draft", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_draft", allowed_actions = c("result.inspect"), action_class = 2L, escalation_conditions = c("unbounded_scope"), prohibited_actions = c("start_campaign")),
    list(task_code = "attach_existing_artifact_reference", task_family = "operator", required_bundle = "artifact_runtime", output_schema = "operator_action", allowed_actions = c("artifact.inspect"), action_class = 2L, escalation_conditions = c("unknown_artifact"), prohibited_actions = c("automatic_attachment")),
    list(task_code = "open_mission_control_item", task_family = "operator", required_bundle = "operator_runtime", output_schema = "operator_action", allowed_actions = c("module.open"), action_class = 1L, escalation_conditions = c("unknown_target"), prohibited_actions = c("hidden_navigation")),
    list(task_code = "benchmark_model_tier", task_family = "model_routing", required_bundle = "operator_runtime", output_schema = "benchmark_summary", allowed_actions = c("result.inspect"), action_class = 0L, escalation_conditions = c("qualification_expired"), prohibited_actions = c("declare_unqualified_model_optimal")),
    list(task_code = "review_evidence_and_recommend_next_action", task_family = "evidence_review", required_bundle = "operator_runtime", output_schema = "evidence_review", allowed_actions = c("artifact.inspect", "module.open", "result.inspect"), action_class = 2L, escalation_conditions = c("material_contradiction", "authority_required", "human_judgment_required", "model_unqualified"), prohibited_actions = c("mutate_evidence", "approve_decision", "invent_artifact_id", "suppress_contradiction")),
    list(task_code = "persist_confirmed_draft", task_family = "operator", required_bundle = "operator_runtime", output_schema = "persistable_ai_draft", allowed_actions = c("result.persist"), action_class = 3L, escalation_conditions = c("confirmation_missing", "stale_dependencies", "citation_invalid"), prohibited_actions = c("approval", "evidence_mutation", "campaign_execution", "review_submission")),
    list(task_code = "govern_project_mutation", task_family = "operator", required_bundle = "operator_runtime", output_schema = "governed_mutation", allowed_actions = c("result.persist"), action_class = 3L, escalation_conditions = c("governance_blocked", "confirmation_missing", "review_required"), prohibited_actions = c("skip_governance", "unsupported_mutation", "autonomous_execution"))
  ))
  unique(base, by = "task_code")
}

knowledge_output_schema <- function(task_code) {
  schemas <- list(
    explain_workflow_state = c("current_state", "explanation", "blocker", "next_supported_action", "prerequisite", "authority_required", "evidence_references"),
    recommend_supported_next_action = c("current_state", "recommended_action", "reason", "expected_benefit", "prerequisite", "alternatives", "evidence_references"),
    summarize_observational_plan = c("question", "estimand", "assignment_mechanism", "major_threats", "readiness", "permitted_claims", "prohibited_claims", "evidence_gaps", "next_actions"),
    extract_supported_claims = c("candidate_claim", "support_status", "supporting_evidence", "contradictory_evidence", "applicability", "uncertainty", "permitted_wording", "prohibited_wording", "review_requirement"),
    explain_epistemic_finding = c("finding_code", "observable_evidence", "reasoning_vulnerability", "materiality", "uncertainty", "possible_alternative_explanation", "required_review", "recommended_response", "non_diagnostic_wording"),
    operator_action = c("action_id", "action_class", "arguments", "rationale", "evidence_refs", "expected_effects", "requires_confirmation", "context_hash", "bundle_version"),
    operator_draft = c("draft_type", "title", "summary", "evidence_refs", "limitations", "recommended_review", "context_hash", "bundle_version"),
    benchmark_summary = c("model_tier", "task_code", "structured_validity", "estimated_tokens", "expected_latency_ms", "escalation_required", "fitness_for_task"),
    evidence_review = c("review_session", "evidence_binder", "review_findings", "sufficiency_for_action", "ranked_next_actions", "recommended_next_action", "draft", "audit_record"),
    persistable_ai_draft = c("draft_id", "draft_type", "originating_review_session", "validation_status", "confirmation_status", "handler", "project_target", "audit_id", "undo_id", "archive_id"),
    governed_mutation = c("mutation_id", "mutation_type", "classification", "risk", "governance", "validation_status", "confirmation_status", "handler", "audit_id", "lifecycle_status")
  )
  schemas[[task_code]] %||% character()
}

knowledge_operator_action_registry <- function() {
  kc_dt(list(
    list(operator_action_id = "navigate.page", genai_action_id = "module.open", action_class = 1L, display_name = "Navigate Page", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "navigate_page"),
    list(operator_action_id = "artifact.open", genai_action_id = "artifact.inspect", action_class = 1L, display_name = "Open Artifact", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "open_artifact"),
    list(operator_action_id = "validation.run", genai_action_id = "analysis.preflight", action_class = 2L, display_name = "Run Deterministic Validation", mutates_state = FALSE, requires_confirmation = TRUE, supported_task = "run_deterministic_validation"),
    list(operator_action_id = "workflow.summary", genai_action_id = NA_character_, action_class = 2L, display_name = "Generate Workflow Summary Draft", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "generate_workflow_summary"),
    list(operator_action_id = "observational.summary", genai_action_id = NA_character_, action_class = 2L, display_name = "Generate Observational Summary Draft", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "generate_observational_summary"),
    list(operator_action_id = "review.draft", genai_action_id = NA_character_, action_class = 2L, display_name = "Create Review Draft", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "create_review_draft"),
    list(operator_action_id = "campaign.draft", genai_action_id = NA_character_, action_class = 2L, display_name = "Create Campaign Draft", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "create_campaign_draft"),
    list(operator_action_id = "artifact.reference.attach", genai_action_id = "artifact.inspect", action_class = 2L, display_name = "Attach Existing Artifact Reference Draft", mutates_state = FALSE, requires_confirmation = TRUE, supported_task = "attach_existing_artifact_reference"),
    list(operator_action_id = "mission.item.open", genai_action_id = "module.open", action_class = 1L, display_name = "Open Mission Control Item", mutates_state = FALSE, requires_confirmation = FALSE, supported_task = "open_mission_control_item"),
    list(operator_action_id = "ai.review_draft.persist", genai_action_id = "result.persist", action_class = 3L, display_name = "Persist Confirmed Evidence Review Draft", mutates_state = TRUE, requires_confirmation = TRUE, supported_task = "persist_confirmed_draft"),
    list(operator_action_id = "ai.campaign_draft.persist", genai_action_id = "result.persist", action_class = 3L, display_name = "Persist Confirmed Campaign Draft", mutates_state = TRUE, requires_confirmation = TRUE, supported_task = "persist_confirmed_draft"),
    list(operator_action_id = "ai.review_request.persist", genai_action_id = "result.persist", action_class = 3L, display_name = "Persist Confirmed Review Request Draft", mutates_state = TRUE, requires_confirmation = TRUE, supported_task = "govern_project_mutation"),
    list(operator_action_id = "ai.evidence_link.persist", genai_action_id = "result.persist", action_class = 3L, display_name = "Persist Confirmed Evidence-Link Draft", mutates_state = TRUE, requires_confirmation = TRUE, supported_task = "govern_project_mutation")
  ))
}

mutation_taxonomy <- function() {
  data.table::data.table(
    mutation_type = c(
      "read_only", "navigation", "draft_creation", "draft_persistence",
      "relationship_staging", "relationship_persistence", "metadata_update",
      "workflow_update", "evidence_attachment", "evidence_removal",
      "recommendation_change", "decision_change", "authority_change",
      "analytical_specification", "execution", "deletion", "unknown"
    ),
    canonical = TRUE,
    mutates_project = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    default_reversibility = c("reversible", "reversible", "reversible", "undoable", "undoable", "undoable", "undoable", "conditional", "conditional", "difficult", "conditional", "difficult", "blocked", "conditional", "blocked", "difficult", "blocked"),
    default_governance = c("no_confirmation", "no_confirmation", "user_confirmation", "user_confirmation", "user_confirmation", "reviewer_acknowledgement", "user_confirmation", "reviewer_acknowledgement", "reviewer_acknowledgement", "independent_review", "reviewer_acknowledgement", "approval_required", "authority_escalation", "independent_review", "blocked", "approval_required", "unsupported")
  )
}

mutation_lifecycle_states <- function() {
  c("proposed", "validated", "previewed", "confirmed", "persisted", "rejected", "archived", "undone", "restored", "expired", "superseded")
}

mutation_store_empty <- function() {
  list(
    schema_version = "mutation_store_v1",
    mutations = list(),
    lifecycle = data.table::data.table(
      event_id = character(), mutation_id = character(), event_type = character(),
      previous_status = character(), new_status = character(), timestamp = character(),
      actor = character(), reason = character(), audit_id = character()
    ),
    audits = list(),
    diagnostics = list()
  )
}

mutation_store_normalize <- function(store = NULL) {
  store <- store %||% mutation_store_empty()
  store$schema_version <- store$schema_version %||% "mutation_store_v1"
  store$mutations <- store$mutations %||% list()
  store$lifecycle <- data.table::as.data.table(store$lifecycle %||% mutation_store_empty()$lifecycle)
  store$audits <- store$audits %||% list()
  store$diagnostics <- store$diagnostics %||% list()
  store
}

mutation_event <- function(mutation_id, event_type, previous_status, new_status, actor = "user", reason = "", audit_id = NA_character_) {
  data.table::data.table(
    event_id = paste0("mutation_event_", substr(kc_hash_value(list(mutation_id, event_type, previous_status, new_status, actor, reason, Sys.time())), 1L, 12L)),
    mutation_id = mutation_id,
    event_type = event_type,
    previous_status = previous_status %||% "",
    new_status = new_status %||% "",
    timestamp = as.character(Sys.time()),
    actor = actor %||% "user",
    reason = reason %||% "",
    audit_id = audit_id %||% NA_character_
  )
}

mutation_store_add_event <- function(store, mutation, event_type, previous_status, new_status, actor = "user", reason = "") {
  store <- mutation_store_normalize(store)
  event <- mutation_event(mutation$mutation_id, event_type, previous_status, new_status, actor, reason, mutation$audit_id %||% NA_character_)
  store$lifecycle <- data.table::rbindlist(list(store$lifecycle, event), fill = TRUE)
  store$mutations[[mutation$mutation_id]] <- mutation
  store
}

mutation_risk_assessment <- function(classification) {
  score <- 0L
  if (!identical(classification$reversibility %||% "", "reversible")) score <- score + 1L
  if ((classification$affected_authority %||% "none") != "none") score <- score + 3L
  if ((classification$affected_evidence %||% "none") != "none") score <- score + 2L
  if ((classification$affected_workflow %||% "none") != "none") score <- score + 2L
  if ((classification$project_impact %||% "none") %in% c("material", "persistent")) score <- score + 2L
  if ((classification$epistemic_impact %||% "none") %in% c("material", "claim_affecting")) score <- score + 2L
  if ((classification$organizational_impact %||% "none") %in% c("material", "authority_sensitive")) score <- score + 2L
  risk <- if (score <= 0L) "negligible" else if (score <= 2L) "low" else if (score <= 5L) "moderate" else if (score <= 8L) "high" else "critical"
  list(risk_level = risk, risk_score = score)
}

mutation_governance_policy <- function(classification, risk = NULL) {
  risk <- risk %||% mutation_risk_assessment(classification)
  taxonomy <- mutation_taxonomy()
  row <- taxonomy[mutation_type == classification$mutation_type]
  governance <- if (nrow(row)) row$default_governance[[1]] else "unsupported"
  if (risk$risk_level %in% c("high", "critical") && governance %in% c("no_confirmation", "user_confirmation")) {
    governance <- "independent_review"
  }
  if (classification$mutation_type %in% c("authority_change", "execution", "unknown")) governance <- "blocked"
  list(
    governance_requirement = governance,
    confirmation_required = governance %in% c("user_confirmation", "reviewer_acknowledgement", "independent_review", "approval_required", "authority_escalation"),
    review_required = governance %in% c("reviewer_acknowledgement", "independent_review", "approval_required", "authority_escalation"),
    approval_required = governance %in% c("approval_required", "authority_escalation"),
    blocked = governance %in% c("blocked", "unsupported"),
    reason = paste("Deterministic governance for", classification$mutation_type, "at", risk$risk_level, "risk.")
  )
}

mutation_classification <- function(proposal = list()) {
  mutation_type <- proposal$mutation_type %||% "unknown"
  taxonomy <- mutation_taxonomy()
  if (!mutation_type %in% taxonomy$mutation_type) mutation_type <- "unknown"
  row <- taxonomy[mutation_type == mutation_type][1]
  affected_artifacts <- unique(proposal$affected_artifacts %||% proposal$citations %||% character())
  classification <- list(
    mutation_id = proposal$mutation_id %||% paste0("mutation_", substr(kc_hash_value(list(proposal, Sys.time())), 1L, 12L)),
    mutation_type = mutation_type,
    affected_objects = unique(proposal$affected_objects %||% character()),
    affected_artifacts = affected_artifacts,
    affected_workflow = proposal$affected_workflow %||% "none",
    affected_authority = proposal$affected_authority %||% "none",
    affected_evidence = proposal$affected_evidence %||% if (length(affected_artifacts)) "references" else "none",
    reversibility = proposal$reversibility %||% row$default_reversibility[[1]] %||% "unknown",
    project_impact = proposal$project_impact %||% if (isTRUE(row$mutates_project[[1]])) "persistent" else "none",
    epistemic_impact = proposal$epistemic_impact %||% "contextual",
    organizational_impact = proposal$organizational_impact %||% "none",
    confirmation_requirement = NA_character_,
    review_requirement = NA_character_,
    allowed_handler = proposal$handler %||% NA_character_
  )
  risk <- mutation_risk_assessment(classification)
  governance <- mutation_governance_policy(classification, risk)
  classification$risk_level <- risk$risk_level
  classification$risk_score <- risk$risk_score
  classification$confirmation_requirement <- if (isTRUE(governance$confirmation_required)) "required" else "not_required"
  classification$review_requirement <- if (isTRUE(governance$review_required)) "required" else "not_required"
  classification$governance_requirement <- governance$governance_requirement
  classification
}

governed_mutation_content_hash <- function(payload, citations, classification, runtime_version) {
  stable_classification <- classification
  stable_classification$mutation_id <- NA_character_
  kc_hash_value(list(payload = payload, citations = citations, classification = stable_classification, runtime = runtime_version))
}

artifact_ids_from_project <- function(project_state = list(), review_result = NULL) {
  ids <- names(project_state$module_artifacts %||% list())
  ids <- unique(c(ids, if (!is.null(review_result)) {
    review <- review_result$value %||% review_result
    c(review$binder$primary_artifacts, review$binder$supporting_artifacts, review$binder$contradictory_artifacts, review$binder$contextual_artifacts)
  } else character()))
  ids[nzchar(ids)]
}

create_governed_mutation <- function(mutation_type, payload, citations = character(),
                                     originating_review_session = NA_character_,
                                     handler = NA_character_,
                                     user = "local_user",
                                     review_result = NULL) {
  proposal <- list(
    mutation_type = mutation_type,
    affected_objects = payload$affected_objects %||% character(),
    affected_artifacts = citations,
    citations = citations,
    affected_workflow = payload$affected_workflow %||% "none",
    affected_authority = payload$affected_authority %||% "none",
    affected_evidence = payload$affected_evidence %||% "references",
    reversibility = payload$reversibility %||% "undoable",
    project_impact = payload$project_impact %||% "persistent",
    epistemic_impact = payload$epistemic_impact %||% "contextual",
    organizational_impact = payload$organizational_impact %||% "none",
    handler = handler
  )
  classification <- mutation_classification(proposal)
  risk <- list(risk_level = classification$risk_level, risk_score = classification$risk_score)
  governance <- mutation_governance_policy(classification, risk)
  mutation_hash <- governed_mutation_content_hash(payload, citations, classification, knowledge_runtime_compiler_version())
  mutation_id <- paste0("mutation_", mutation_type, "_", substr(mutation_hash, 1L, 12L))
  classification$mutation_id <- mutation_id
  list(
    contract_type = "governed_mutation",
    mutation_id = mutation_id,
    mutation_type = mutation_type,
    lifecycle_status = "proposed",
    originating_review_session = originating_review_session,
    runtime_version = knowledge_runtime_compiler_version(),
    bundle_versions = (review_result$value %||% review_result)$session$bundle_versions %||% list(operator_runtime = knowledge_runtime_compiler_version()),
    classification = classification,
    risk = risk,
    governance = governance,
    validation_status = "not_validated",
    confirmation_status = "not_confirmed",
    handler = handler,
    payload = payload,
    citations = citations,
    created_time = as.character(Sys.time()),
    confirmed_time = NA_character_,
    user = user,
    ai_model = (review_result$value %||% review_result)$model_routing$model_tier %||% NA_character_,
    qualification = (review_result$value %||% review_result)$model_routing$escalation %||% "none",
    audit_id = paste0("mutation_audit_", substr(kc_hash_value(list(mutation_id, "audit")), 1L, 12L)),
    undo_id = paste0("undo_", substr(kc_hash_value(list(mutation_id, "undo")), 1L, 12L)),
    archive_id = paste0("archive_", substr(kc_hash_value(list(mutation_id, "archive")), 1L, 12L)),
    stale_dependencies = character(),
    generated = TRUE,
    mutation_hash = mutation_hash
  )
}

create_review_request_mutation <- function(review_result, title = "AI Review Request", requested_review_type = "epistemic_review", user = "local_user") {
  review <- review_result$value %||% review_result
  citations <- unique(c(review$binder$primary_artifacts, review$binder$supporting_artifacts, review$binder$contradictory_artifacts))
  payload <- list(
    draft_type = "review_request",
    title = title,
    requested_review_type = requested_review_type,
    question = review$session$question %||% "",
    reason = "AI evidence review identified a bounded review request. Persistence does not submit the review.",
    affected_objects = c(review$session$session_id %||% ""),
    affected_evidence = "review_request_reference",
    project_impact = "persistent",
    epistemic_impact = "review_readiness",
    reversibility = "undoable",
    citations = citations,
    submitted = FALSE
  )
  create_governed_mutation("draft_persistence", payload, citations, review$session$session_id, "project_state_review_request_handler", user, review_result)
}

create_evidence_link_mutation <- function(source_artifact_id, target_artifact_id, relationship_type = "supports",
                                          reason = "AI proposed evidence relationship.", review_result = NULL,
                                          user = "local_user") {
  payload <- list(
    draft_type = "evidence_link",
    source_artifact_id = source_artifact_id,
    target_artifact_id = target_artifact_id,
    relationship_type = relationship_type,
    relationship_status = "proposed",
    reason = reason,
    affected_objects = c(source_artifact_id, target_artifact_id),
    affected_evidence = "relationship_reference",
    project_impact = "persistent",
    epistemic_impact = "contextual",
    reversibility = "undoable",
    citations = unique(c(source_artifact_id, target_artifact_id)),
    accepted_as_evidence = FALSE
  )
  session_id <- (review_result$value %||% review_result)$session$session_id %||% NA_character_
  create_governed_mutation("relationship_staging", payload, unique(c(source_artifact_id, target_artifact_id)), session_id, "project_state_evidence_link_draft_handler", user, review_result)
}

confirm_governed_mutation <- function(mutation, user = "local_user") {
  mutation$lifecycle_status <- "confirmed"
  mutation$confirmation_status <- "confirmed"
  mutation$confirmed_time <- as.character(Sys.time())
  mutation$user <- user
  mutation
}

validate_governed_mutation <- function(mutation, project_state = list(), review_result = NULL, require_confirmation = TRUE) {
  errors <- character()
  warnings <- character()
  if (!identical(mutation$contract_type %||% "", "governed_mutation")) errors <- c(errors, "Mutation does not use the governed_mutation contract.")
  if (!mutation$mutation_type %in% mutation_taxonomy()$mutation_type) errors <- c(errors, "Mutation type is not canonical.")
  if (!identical(mutation$runtime_version %||% "", knowledge_runtime_compiler_version())) errors <- c(errors, "Mutation runtime version is not current.")
  if (isTRUE(require_confirmation) && !identical(mutation$confirmation_status %||% "", "confirmed")) errors <- c(errors, "Mutation confirmation is required before persistence.")
  if (isTRUE(mutation$governance$blocked)) errors <- c(errors, paste("Mutation governance is blocked:", mutation$governance$governance_requirement))
  if (!nzchar(mutation$handler %||% "")) errors <- c(errors, "Mutation has no allowed handler.")
  if (length(mutation$stale_dependencies %||% character())) errors <- c(errors, "Mutation has stale dependencies and must be regenerated.")
  if (!identical(mutation$mutation_hash, governed_mutation_content_hash(mutation$payload, mutation$citations, mutation$classification, mutation$runtime_version))) {
    errors <- c(errors, "Mutation content hash changed after creation.")
  }
  known_ids <- artifact_ids_from_project(project_state, review_result)
  if (length(mutation$citations %||% character()) && length(setdiff(mutation$citations, known_ids))) {
    errors <- c(errors, paste("Mutation citations reference unknown artifacts:", paste(setdiff(mutation$citations, known_ids), collapse = ", ")))
  }
  if (identical(mutation$payload$draft_type %||% "", "evidence_link")) {
    allowed_relationships <- c("supports", "contradicts", "contextualizes", "narrows", "supersedes", "derived_from", "tests", "requires")
    if (!mutation$payload$relationship_type %in% allowed_relationships) errors <- c(errors, "Evidence-link relationship type is prohibited or unsupported.")
    if (identical(mutation$payload$source_artifact_id, mutation$payload$target_artifact_id)) errors <- c(errors, "Evidence-link source and target must be different artifacts.")
    links <- project_state$artifact_relationship_drafts %||% list()
    duplicate <- any(vapply(links, function(link) {
      identical(link$source_artifact_id %||% "", mutation$payload$source_artifact_id %||% "") &&
        identical(link$target_artifact_id %||% "", mutation$payload$target_artifact_id %||% "") &&
        identical(link$relationship_type %||% "", mutation$payload$relationship_type %||% "") &&
        !identical(link$status %||% "", "undone")
    }, logical(1)))
    if (duplicate) errors <- c(errors, "Duplicate evidence-link draft already exists.")
  }
  action_id <- switch(
    mutation$handler,
    project_state_review_request_handler = "ai.review_request.persist",
    project_state_evidence_link_draft_handler = "ai.evidence_link.persist",
    NA_character_
  )
  action <- knowledge_operator_action_registry()[operator_action_id == action_id]
  if (!nrow(action) || !identical(action$action_class[[1]], 3L) || !isTRUE(action$requires_confirmation[[1]])) {
    errors <- c(errors, "Supported Class 3 mutation action is not registered correctly.")
  }
  status <- if (length(errors)) "error" else "success"
  mutation$validation_status <- status
  if (identical(status, "success")) mutation$lifecycle_status <- if (identical(mutation$lifecycle_status, "confirmed")) "confirmed" else "validated"
  service_result(status, value = list(valid = !length(errors), mutation = mutation, classification = mutation$classification, risk = mutation$risk, governance = mutation$governance), errors = errors, warnings = warnings)
}

mutation_audit_record <- function(mutation, validation, objects_changed = character(), artifacts_changed = character()) {
  list(
    audit_id = mutation$audit_id,
    mutation_id = mutation$mutation_id,
    mutation_type = mutation$mutation_type,
    classification = mutation$classification,
    risk = mutation$risk,
    governance = mutation$governance,
    validation_status = validation$status,
    confirmation_status = mutation$confirmation_status,
    handler = mutation$handler,
    objects_changed = objects_changed,
    artifacts_changed = artifacts_changed,
    workflow_changed = mutation$classification$affected_workflow,
    authority = mutation$classification$affected_authority,
    undo_id = mutation$undo_id,
    archive_id = mutation$archive_id,
    runtime_version = mutation$runtime_version,
    bundle_versions = mutation$bundle_versions,
    model = mutation$ai_model,
    qualification = mutation$qualification,
    tokens = NA_integer_,
    latency_ms = NA_real_,
    timestamp = as.character(Sys.time())
  )
}

mutation_to_artifact <- function(mutation) {
  create_artifact(
    artifact_id = paste0("ai_", mutation$mutation_id),
    artifact_type = if (identical(mutation$payload$draft_type, "evidence_link")) "diagnostic" else "genai_narrative",
    label = if (identical(mutation$payload$draft_type, "evidence_link")) "AI Evidence-Link Draft" else "AI Review Request Draft",
    source_module = "ai_runtime",
    content = jsonlite::toJSON(mutation, auto_unbox = TRUE, pretty = TRUE, null = "null"),
    metadata = list(
      module_id = "ai_runtime",
      mutation_id = mutation$mutation_id,
      mutation_type = mutation$mutation_type,
      risk_level = mutation$risk$risk_level,
      governance_requirement = mutation$governance$governance_requirement,
      citations = mutation$citations,
      generated = TRUE,
      analytical_intent = "Governance",
      artifact_importance = "recommended",
      render_targets = c("artifact_studio", "llm_docx")
    ),
    section = "AI Mutation Governance"
  )
}

persist_confirmed_governed_mutation <- function(project_state = list(), mutation, review_result = NULL, write_collector = FALSE) {
  validation <- validate_governed_mutation(mutation, project_state, review_result, require_confirmation = TRUE)
  if (!identical(validation$status, "success")) return(validation)
  mutation <- validation$value$mutation
  previous_status <- mutation$lifecycle_status
  mutation$lifecycle_status <- "persisted"
  mutation$persisted_time <- as.character(Sys.time())
  mutation$validation_status <- "success"
  artifact <- mutation_to_artifact(mutation)
  store <- mutation_store_normalize(project_state$ai_mutation_store %||% NULL)
  store <- mutation_store_add_event(store, mutation, "persisted", previous_status, "persisted", actor = mutation$user, reason = "Confirmed governed mutation persisted through existing app handler.")
  project_state$ai_mutation_store <- store
  objects_changed <- character()
  if (identical(mutation$handler, "project_state_review_request_handler")) {
    project_state$decision_memory_state <- project_state$decision_memory_state %||% list()
    requests <- project_state$decision_memory_state$review_requests %||% list()
    requests[[mutation$mutation_id]] <- list(
      review_request_id = mutation$mutation_id,
      status = "draft",
      source = "ai_runtime",
      payload = mutation$payload,
      citations = mutation$citations,
      audit_id = mutation$audit_id,
      submitted = FALSE
    )
    project_state$decision_memory_state$review_requests <- requests
    objects_changed <- c(objects_changed, mutation$mutation_id)
  } else if (identical(mutation$handler, "project_state_evidence_link_draft_handler")) {
    links <- project_state$artifact_relationship_drafts %||% list()
    links[[mutation$mutation_id]] <- list(
      relationship_id = mutation$mutation_id,
      source_artifact_id = mutation$payload$source_artifact_id,
      target_artifact_id = mutation$payload$target_artifact_id,
      relationship_type = mutation$payload$relationship_type,
      status = "proposed",
      accepted_as_evidence = FALSE,
      audit_id = mutation$audit_id,
      reason = mutation$payload$reason
    )
    project_state$artifact_relationship_drafts <- links
    objects_changed <- c(objects_changed, mutation$mutation_id)
  }
  project_state$module_artifacts <- project_state$module_artifacts %||% list()
  project_state$module_artifacts[[artifact$artifact_id]] <- artifact
  collector_result <- NULL
  if (inherits(project_state$project_collector, "project_artifact_collector")) {
    bundle <- project_artifact_bundle(
      project_id = project_state$project_collector$project_id,
      project_name = project_state$project_collector$project_name,
      run_id = paste0("ai_mutation_", substr(mutation$mutation_id, 1L, 24L), "_", format(Sys.time(), "%Y%m%d%H%M%S")),
      module_id = "ai_runtime",
      module_label = "AI Runtime",
      artifacts = list(artifact),
      status = "success",
      metadata = list(mutation_id = mutation$mutation_id, audit_id = mutation$audit_id, class_3 = TRUE)
    )
    collector_result <- project_collector_append_bundle(project_state$project_collector, bundle, write = isTRUE(write_collector))
    if (identical(collector_result$status, "success")) project_state$project_collector <- collector_result$value
  }
  audit <- mutation_audit_record(mutation, validation, objects_changed, artifact$artifact_id)
  store <- mutation_store_normalize(project_state$ai_mutation_store)
  store$audits[[audit$audit_id]] <- audit
  project_state$ai_mutation_store <- store
  service_result("success", value = list(project_state = project_state, mutation = mutation, artifact = artifact, audit = audit, collector_result = collector_result))
}

mutation_update_status <- function(project_state, mutation_id, new_status, reason = "") {
  store <- mutation_store_normalize(project_state$ai_mutation_store %||% NULL)
  mutation <- store$mutations[[mutation_id]]
  if (is.null(mutation)) return(service_result("error", errors = paste("Unknown mutation:", mutation_id)))
  allowed <- list(
    proposed = c("validated", "previewed", "confirmed", "rejected", "expired"),
    validated = c("previewed", "confirmed", "rejected", "expired"),
    previewed = c("confirmed", "rejected", "expired"),
    confirmed = c("persisted", "rejected", "expired"),
    persisted = c("archived", "undone", "superseded"),
    archived = c("restored"),
    undone = c("restored"),
    restored = c("archived", "undone", "superseded"),
    rejected = character(),
    expired = character(),
    superseded = character()
  )
  previous <- mutation$lifecycle_status %||% "proposed"
  if (!new_status %in% (allowed[[previous]] %||% character())) {
    return(service_result("error", errors = paste("Illegal mutation transition:", previous, "->", new_status)))
  }
  mutation$lifecycle_status <- new_status
  store <- mutation_store_add_event(store, mutation, new_status, previous, new_status, actor = mutation$user %||% "user", reason = reason)
  project_state$ai_mutation_store <- store
  service_result("success", value = list(project_state = project_state, mutation = mutation))
}

undo_governed_mutation <- function(project_state, mutation_id, reason = "User undid mutation persistence.") mutation_update_status(project_state, mutation_id, "undone", reason)
archive_governed_mutation <- function(project_state, mutation_id, reason = "User archived mutation.") mutation_update_status(project_state, mutation_id, "archived", reason)
restore_governed_mutation <- function(project_state, mutation_id, reason = "User restored mutation.") mutation_update_status(project_state, mutation_id, "restored", reason)
supersede_governed_mutation <- function(project_state, mutation_id, reason = "Mutation superseded.") mutation_update_status(project_state, mutation_id, "superseded", reason)
reject_governed_mutation <- function(project_state, mutation_id, reason = "User rejected mutation.") mutation_update_status(project_state, mutation_id, "rejected", reason)

mutation_governance_diagnostics <- function(project_state = list()) {
  store <- mutation_store_normalize(project_state$ai_mutation_store %||% NULL)
  mutations <- store$mutations
  statuses <- vapply(mutations, function(x) x$lifecycle_status %||% "unknown", character(1))
  risks <- vapply(mutations, function(x) x$risk$risk_level %||% "unknown", character(1))
  data.table::data.table(
    mutations = length(mutations),
    pending = sum(statuses %in% c("proposed", "validated", "previewed", "confirmed")),
    persisted = sum(statuses %in% c("persisted", "restored")),
    rejected = sum(statuses == "rejected"),
    archived = sum(statuses == "archived"),
    undone = sum(statuses == "undone"),
    expired = sum(statuses == "expired"),
    superseded = sum(statuses == "superseded"),
    high_or_critical = sum(risks %in% c("high", "critical")),
    validation_failures = sum((store$lifecycle$event_type %||% character()) == "validation_failed"),
    undo_available = sum(statuses %in% c("persisted", "restored")),
    archive_available = sum(statuses %in% c("persisted", "restored"))
  )
}

mutation_lifecycle_table <- function(project_state = list()) {
  store <- mutation_store_normalize(project_state$ai_mutation_store %||% NULL)
  if (!length(store$mutations)) {
    return(data.table::data.table(mutation_id = character(), mutation_type = character(), lifecycle_status = character(), risk_level = character(), governance = character(), handler = character(), citations = integer()))
  }
  data.table::rbindlist(lapply(store$mutations, function(mutation) {
    data.table::data.table(
      mutation_id = mutation$mutation_id,
      mutation_type = mutation$mutation_type,
      lifecycle_status = mutation$lifecycle_status,
      risk_level = mutation$risk$risk_level,
      governance = mutation$governance$governance_requirement,
      handler = mutation$handler,
      citations = length(mutation$citations %||% character())
    )
  }), fill = TRUE)
}

qa_mutation_governance <- function(output_dir = file.path(tempdir(), "mutation_governance_qa")) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  artifacts <- list(
    create_artifact("qa_artifact_a", "diagnostic", "Artifact A", "qa", content = "A", metadata = list(artifact_completeness = 90)),
    create_artifact("qa_artifact_b", "diagnostic", "Artifact B", "qa", content = "B", metadata = list(artifact_completeness = 90))
  )
  ctx <- list(artifacts = artifacts)
  review <- run_ai_operated_evidence_review(ctx, "What evidence should be reviewed?", model_tier = "local_free_model")
  review_mutation <- create_review_request_mutation(review, user = "qa_user")
  link_mutation <- create_evidence_link_mutation("qa_artifact_a", "qa_artifact_b", "supports", review_result = review, user = "qa_user")
  project <- list(
    app_version = APP_VERSION,
    saved_at = Sys.time(),
    plot_configs = list(),
    plot_code = list(),
    plot_metadata = list(),
    layout_type = "Grid",
    layout_cols = 2L,
    export_dir = output_dir,
    export_name = "qa_mutation",
    decision_memory_state = list(reviews = list(), review_requests = list()),
    module_artifacts = artifacts,
    artifact_relationship_drafts = list(),
    ai_mutation_store = mutation_store_empty(),
    project_collector = create_project_artifact_collector("qa_mutation_project", "QA Mutation Project", output_dir = output_dir)
  )
  unconfirmed <- validate_governed_mutation(review_mutation, project, review, require_confirmation = TRUE)
  confirmed_review <- confirm_governed_mutation(review_mutation, "qa_user")
  confirmed_link <- confirm_governed_mutation(link_mutation, "qa_user")
  validated_review <- validate_governed_mutation(confirmed_review, project, review, require_confirmation = TRUE)
  validated_link <- validate_governed_mutation(confirmed_link, project, review, require_confirmation = TRUE)
  persisted_review <- persist_confirmed_governed_mutation(project, confirmed_review, review, write_collector = FALSE)
  project2 <- persisted_review$value$project_state
  persisted_link <- persist_confirmed_governed_mutation(project2, confirmed_link, review, write_collector = FALSE)
  project3 <- persisted_link$value$project_state
  duplicate_link <- validate_governed_mutation(confirmed_link, project3, review, require_confirmation = TRUE)
  hallucinated <- create_evidence_link_mutation("qa_artifact_a", "invented_artifact", "supports", review_result = review, user = "qa_user")
  hallucinated <- confirm_governed_mutation(hallucinated, "qa_user")
  hallucinated_validation <- validate_governed_mutation(hallucinated, project, review, require_confirmation = TRUE)
  prohibited <- create_evidence_link_mutation("qa_artifact_a", "qa_artifact_b", "accepts_as_truth", review_result = review, user = "qa_user")
  prohibited <- confirm_governed_mutation(prohibited, "qa_user")
  prohibited_validation <- validate_governed_mutation(prohibited, project, review, require_confirmation = TRUE)
  undo <- undo_governed_mutation(project3, confirmed_link$mutation_id)
  archive <- archive_governed_mutation(project3, confirmed_review$mutation_id)
  restore <- restore_governed_mutation(archive$value$project_state, confirmed_review$mutation_id)
  supersede <- supersede_governed_mutation(restore$value$project_state, confirmed_review$mutation_id)
  diagnostics <- mutation_governance_diagnostics(project3)
  lifecycle <- mutation_lifecycle_table(project3)
  class3 <- knowledge_operator_action_registry()[action_class == 3L]
  data.table::data.table(
    check = c(
      "taxonomy", "classification", "risk", "governance", "review_request_draft",
      "evidence_link_draft", "unconfirmed_rejected", "review_validation",
      "link_validation", "review_persistence", "link_persistence",
      "hallucinated_relationship_rejected", "prohibited_relationship_rejected",
      "duplicate_relationship_rejected", "undo", "archive", "restore",
      "supersede", "audit", "runtime", "mission_control_data",
      "ai_runtime_data", "collector", "no_review_submission",
      "no_evidence_attachment", "no_unsupported_class3"
    ),
    status = c(
      if (nrow(mutation_taxonomy()) >= 17L && all(mutation_taxonomy()[, .N, by = mutation_type]$N == 1L)) "success" else "error",
      if (identical(mutation_classification(list(mutation_type = "draft_persistence"))$mutation_type, "draft_persistence")) "success" else "error",
      if (mutation_risk_assessment(list(mutation_type = "draft_persistence", reversibility = "undoable", affected_evidence = "references", project_impact = "persistent", epistemic_impact = "contextual", affected_authority = "none", affected_workflow = "none", organizational_impact = "none"))$risk_level %in% c("low", "moderate", "high")) "success" else "error",
      if (!isTRUE(mutation_governance_policy(mutation_classification(list(mutation_type = "execution")))$blocked)) "error" else "success",
      if (identical(review_mutation$payload$draft_type, "review_request")) "success" else "error",
      if (identical(link_mutation$payload$draft_type, "evidence_link")) "success" else "error",
      if (identical(unconfirmed$status, "error")) "success" else "error",
      if (identical(validated_review$status, "success")) "success" else "error",
      if (identical(validated_link$status, "success")) "success" else "error",
      if (identical(persisted_review$status, "success") && !is.null(persisted_review$value$project_state$decision_memory_state$review_requests[[confirmed_review$mutation_id]])) "success" else "error",
      if (identical(persisted_link$status, "success") && !is.null(project3$artifact_relationship_drafts[[confirmed_link$mutation_id]])) "success" else "error",
      if (identical(hallucinated_validation$status, "error")) "success" else "error",
      if (identical(prohibited_validation$status, "error")) "success" else "error",
      if (identical(duplicate_link$status, "error")) "success" else "error",
      if (identical(undo$status, "success")) "success" else "error",
      if (identical(archive$status, "success")) "success" else "error",
      if (identical(restore$status, "success")) "success" else "error",
      if (identical(supersede$status, "success")) "success" else "error",
      if (length(project3$ai_mutation_store$audits) >= 2L) "success" else "error",
      if (identical(knowledge_runtime_compiler_version(), "0.8.0")) "success" else "error",
      if (nrow(diagnostics) == 1L && diagnostics$persisted[[1]] >= 2L) "success" else "error",
      if (nrow(lifecycle) >= 2L) "success" else "error",
      if (inherits(project3$project_collector, "project_artifact_collector") && length(project3$project_collector$bundles) >= 2L) "success" else "error",
      if (!isTRUE(project3$decision_memory_state$review_requests[[confirmed_review$mutation_id]]$submitted)) "success" else "error",
      if (!isTRUE(project3$artifact_relationship_drafts[[confirmed_link$mutation_id]]$accepted_as_evidence)) "success" else "error",
      if (all(class3$operator_action_id %in% c("ai.review_draft.persist", "ai.campaign_draft.persist", "ai.review_request.persist", "ai.evidence_link.persist"))) "success" else "error"
    ),
    message = c(
      "Every mutation belongs to one canonical mutation type.",
      "Mutation classification returns the canonical type.",
      "Risk assessment is deterministic from project, evidence, authority, and reversibility factors.",
      "Governance policy blocks execution-class mutations.",
      "Review request draft mutation can be generated.",
      "Evidence-link draft mutation can be generated.",
      "Unconfirmed mutations cannot persist.",
      "Review request validates before persistence.",
      "Evidence-link validates before persistence.",
      "Confirmed review request draft persists as an unsubmitted review request object.",
      "Confirmed evidence-link draft persists as a proposed relationship, not accepted evidence.",
      "Hallucinated artifact relationships are rejected.",
      "Prohibited relationship types are rejected.",
      "Duplicate evidence-link drafts are rejected.",
      "Undo lifecycle transition succeeds.",
      "Archive lifecycle transition succeeds.",
      "Restore lifecycle transition succeeds.",
      "Supersede lifecycle transition succeeds.",
      "Mutation audit records are retained.",
      "Runtime bundle version advanced to Phase 8.",
      "Mission Control can consume mutation diagnostics.",
      "AI Runtime can consume mutation lifecycle rows.",
      "Project Artifact Collector receives governed mutation artifacts.",
      "Review request persistence does not submit a review.",
      "Evidence-link persistence does not accept or attach evidence.",
      "No unsupported Class 3 mutation actions are registered."
    )
  )
}

qa_knowledge_compilation_runtime_phase8 <- function() {
  data.table::rbindlist(list(
    qa_knowledge_compilation_runtime_phase7(),
    qa_mutation_governance()
  ), fill = TRUE)
}
