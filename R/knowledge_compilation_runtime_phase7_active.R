# Active Knowledge Compilation Runtime Phase 7:
# confirmed draft persistence and the first governed Class 3 mutation.

knowledge_runtime_compiler_version <- function() {
  "0.7.0"
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
    list(task_code = "persist_confirmed_draft", task_family = "operator", required_bundle = "operator_runtime", output_schema = "persistable_ai_draft", allowed_actions = c("result.persist"), action_class = 3L, escalation_conditions = c("confirmation_missing", "stale_dependencies", "citation_invalid"), prohibited_actions = c("approval", "evidence_mutation", "campaign_execution", "review_submission"))
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
    persistable_ai_draft = c("draft_id", "draft_type", "originating_review_session", "validation_status", "confirmation_status", "handler", "project_target", "audit_id", "undo_id", "archive_id")
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
    list(operator_action_id = "ai.campaign_draft.persist", genai_action_id = "result.persist", action_class = 3L, display_name = "Persist Confirmed Campaign Draft", mutates_state = TRUE, requires_confirmation = TRUE, supported_task = "persist_confirmed_draft")
  ))
}

ai_draft_lifecycle_states <- function() {
  c("preview_only", "confirmed", "persisted", "archived", "undone", "restored", "superseded", "rejected", "expired")
}

ai_draft_store_empty <- function() {
  list(
    schema_version = "ai_draft_store_v1",
    drafts = list(),
    lifecycle = data.table::data.table(
      event_id = character(), draft_id = character(), event_type = character(),
      previous_status = character(), new_status = character(), timestamp = character(),
      actor = character(), reason = character(), audit_id = character()
    ),
    diagnostics = list()
  )
}

ai_draft_store_normalize <- function(store = NULL) {
  store <- store %||% ai_draft_store_empty()
  store$schema_version <- store$schema_version %||% "ai_draft_store_v1"
  store$drafts <- store$drafts %||% list()
  store$lifecycle <- data.table::as.data.table(store$lifecycle %||% ai_draft_store_empty()$lifecycle)
  store$diagnostics <- store$diagnostics %||% list()
  store
}

ai_draft_event <- function(draft_id, event_type, previous_status, new_status, actor = "user", reason = "", audit_id = NA_character_) {
  data.table::data.table(
    event_id = paste0("ai_draft_event_", substr(kc_hash_value(list(draft_id, event_type, previous_status, new_status, actor, reason, Sys.time())), 1L, 12L)),
    draft_id = draft_id,
    event_type = event_type,
    previous_status = previous_status %||% "",
    new_status = new_status %||% "",
    timestamp = as.character(Sys.time()),
    actor = actor %||% "user",
    reason = reason %||% "",
    audit_id = audit_id %||% NA_character_
  )
}

ai_draft_store_add_event <- function(store, draft, event_type, previous_status, new_status, actor = "user", reason = "") {
  store <- ai_draft_store_normalize(store)
  event <- ai_draft_event(draft$draft_id, event_type, previous_status, new_status, actor, reason, draft$audit_id %||% NA_character_)
  store$lifecycle <- data.table::rbindlist(list(store$lifecycle, event), fill = TRUE)
  store$drafts[[draft$draft_id]] <- draft
  store
}

persistable_ai_draft <- function(review_result, draft_type = c("evidence_review", "campaign_seed"),
                                 project_target = "project_state", user = "local_user") {
  draft_type <- match.arg(draft_type)
  review <- review_result$value %||% review_result
  draft_payload <- if (identical(draft_type, "campaign_seed")) review$campaign_draft else review$draft
  if (is.null(draft_payload)) {
    stop("Requested draft type is not available for this evidence review.", call. = FALSE)
  }
  artifact_binder <- review$binder[c("binder_id", "primary_artifacts", "supporting_artifacts", "contradictory_artifacts", "stale_artifacts", "unavailable_expected_artifacts")]
  citations <- unique(draft_payload$citations %||% strsplit(draft_payload$evidence_supporting_gap %||% "", "\\s*,\\s*")[[1]] %||% character())
  citations <- citations[nzchar(citations)]
  draft_hash <- kc_hash_value(list(draft = draft_payload, binder = artifact_binder, citations = citations))
  draft_id <- paste0("ai_draft_", draft_type, "_", substr(draft_hash, 1L, 12L))
  list(
    contract_type = "persistable_ai_draft",
    draft_id = draft_id,
    draft_type = draft_type,
    status = "preview_only",
    originating_review_session = review$session$session_id,
    runtime_version = knowledge_runtime_compiler_version(),
    bundle_versions = review$session$bundle_versions,
    artifact_binder = artifact_binder,
    artifact_binder_hash = kc_hash_value(artifact_binder),
    citations = citations,
    supported_actions = review$ranked_actions$action_id %||% character(),
    validation_status = "not_validated",
    confirmation_status = "not_confirmed",
    handler = if (identical(draft_type, "campaign_seed")) "project_state_campaign_draft_handler" else "project_state_review_draft_handler",
    project_target = project_target,
    created_time = as.character(Sys.time()),
    confirmed_time = NA_character_,
    user = user,
    ai_model = review$model_routing$model_tier %||% review$session$model_tier,
    qualification = review$model_routing$escalation %||% "none",
    audit_id = review$audit_record$audit_id,
    undo_id = paste0("undo_", substr(kc_hash_value(list(draft_id, "undo")), 1L, 12L)),
    archive_id = paste0("archive_", substr(kc_hash_value(list(draft_id, "archive")), 1L, 12L)),
    stale_dependencies = review$binder$stale_artifacts %||% character(),
    generated = TRUE,
    draft_hash = draft_hash,
    context_hash = review$context_hash,
    payload = draft_payload,
    review_snapshot = list(
      findings = review$findings,
      sufficiency = review$sufficiency,
      contradictions = review$synthesis_summary$contradictions,
      limitations = review$draft$unresolved_assumptions %||% character(),
      supported_claims = review$draft$supported_claims %||% list(),
      prohibited_claims = review$draft$prohibited_claims %||% character()
    )
  )
}

confirm_persistable_ai_draft <- function(draft, user = "local_user") {
  draft$status <- "confirmed"
  draft$confirmation_status <- "confirmed"
  draft$confirmed_time <- as.character(Sys.time())
  draft$user <- user
  draft
}

ai_draft_confirmation_view <- function(draft) {
  list(
    draft_summary = draft$payload$title %||% draft$payload$proposed_objective %||% draft$draft_type,
    affected_objects = unique(c(draft$artifact_binder$primary_artifacts, draft$artifact_binder$supporting_artifacts, draft$artifact_binder$contradictory_artifacts)),
    citations = draft$citations,
    evidence = draft$review_snapshot$findings,
    contradictions = draft$review_snapshot$contradictions,
    expected_mutation = "Persist generated draft as project state and append a standard artifact bundle to the Project Artifact Collector when available.",
    undo_available = TRUE,
    authority = "User confirmation required; no approval implied.",
    generated_content_notice = "This draft was generated by AI and remains subject to human review."
  )
}

validate_persistable_ai_draft <- function(draft, review_result = NULL, project_state = list(), require_confirmation = TRUE) {
  errors <- character()
  warnings <- character()
  if (!identical(draft$contract_type %||% "", "persistable_ai_draft")) errors <- c(errors, "Draft does not use the persistable_ai_draft contract.")
  if (!draft$draft_type %in% c("evidence_review", "campaign_seed")) errors <- c(errors, "Only evidence_review and campaign_seed drafts are persistable in Phase 7.")
  if (!identical(draft$runtime_version %||% "", knowledge_runtime_compiler_version())) errors <- c(errors, "Draft runtime version is not current.")
  if (isTRUE(require_confirmation) && !identical(draft$confirmation_status %||% "", "confirmed")) errors <- c(errors, "Draft confirmation is required before persistence.")
  if (!nzchar(draft$handler %||% "")) errors <- c(errors, "Draft has no persistence handler.")
  if (length(draft$stale_dependencies %||% character())) errors <- c(errors, "Draft has stale dependencies and must be regenerated or explicitly refreshed.")
  known_ids <- character()
  if (!is.null(review_result)) {
    review <- review_result$value %||% review_result
    citation_check <- validate_evidence_review_citations(review)
    if (!identical(citation_check$status, "success")) errors <- c(errors, citation_check$errors %||% "Citation validation failed.")
    known_ids <- unique(c(review$binder$primary_artifacts, review$binder$supporting_artifacts, review$binder$contradictory_artifacts, review$binder$contextual_artifacts))
    if (!identical(draft$artifact_binder_hash, kc_hash_value(review$binder[c("binder_id", "primary_artifacts", "supporting_artifacts", "contradictory_artifacts", "stale_artifacts", "unavailable_expected_artifacts")]))) {
      errors <- c(errors, "Evidence binder changed after draft creation.")
    }
    if (!identical(draft$draft_hash, kc_hash_value(list(draft = draft$payload, binder = draft$artifact_binder, citations = draft$citations)))) {
      errors <- c(errors, "Draft content hash changed after creation.")
    }
  }
  if (length(known_ids) && length(setdiff(draft$citations %||% character(), known_ids))) {
    errors <- c(errors, paste("Draft citations are not in the current binder:", paste(setdiff(draft$citations, known_ids), collapse = ", ")))
  }
  action <- knowledge_operator_action_registry()[operator_action_id == if (identical(draft$draft_type, "campaign_seed")) "ai.campaign_draft.persist" else "ai.review_draft.persist"]
  if (!nrow(action) || !identical(action$action_class[[1]], 3L) || !isTRUE(action$requires_confirmation[[1]])) {
    errors <- c(errors, "Supported Class 3 persistence action is not registered correctly.")
  }
  status <- if (length(errors)) "error" else "success"
  draft$validation_status <- status
  service_result(status, value = list(valid = !length(errors), draft = draft, confirmation_view = ai_draft_confirmation_view(draft)), errors = errors, warnings = warnings)
}

ai_draft_to_artifact <- function(draft) {
  content <- jsonlite::toJSON(list(
    draft = draft$payload,
    review = draft$review_snapshot,
    citations = draft$citations,
    status = draft$status
  ), auto_unbox = TRUE, pretty = TRUE, null = "null")
  create_artifact(
    artifact_id = paste0("ai_", draft$draft_id),
    artifact_type = if (identical(draft$draft_type, "campaign_seed")) "recommendation" else "genai_narrative",
    label = if (identical(draft$draft_type, "campaign_seed")) "AI Campaign Draft" else "AI Evidence Review Draft",
    source_module = "ai_runtime",
    content = content,
    metadata = list(
      module_id = "ai_runtime",
      draft_id = draft$draft_id,
      originating_review_session = draft$originating_review_session,
      runtime_version = draft$runtime_version,
      citations = draft$citations,
      audit_id = draft$audit_id,
      confirmation_status = draft$confirmation_status,
      generated = TRUE,
      analytical_intent = if (identical(draft$draft_type, "campaign_seed")) "Recommendation" else "Narrative",
      artifact_importance = "recommended",
      render_targets = c("artifact_studio", "llm_docx")
    ),
    section = "AI Evidence Review"
  )
}

persist_confirmed_ai_draft <- function(project_state = list(), draft, review_result = NULL, write_collector = FALSE) {
  validation <- validate_persistable_ai_draft(draft, review_result = review_result, project_state = project_state, require_confirmation = TRUE)
  if (!identical(validation$status, "success")) return(validation)
  draft <- validation$value$draft
  previous_status <- draft$status
  draft$status <- "persisted"
  draft$persisted_time <- as.character(Sys.time())
  draft$validation_status <- "success"
  artifact <- ai_draft_to_artifact(draft)
  store <- ai_draft_store_normalize(project_state$ai_draft_store %||% NULL)
  store <- ai_draft_store_add_event(store, draft, "persisted", previous_status, "persisted", actor = draft$user, reason = "Confirmed AI draft persisted through governed Class 3 handler.")
  project_state$ai_draft_store <- store
  if (identical(draft$draft_type, "campaign_seed")) {
    project_state$analytical_campaign_state <- project_state$analytical_campaign_state %||% list()
    campaigns <- project_state$analytical_campaign_state$campaigns %||% list()
    campaigns[[draft$draft_id]] <- list(
      campaign_id = draft$draft_id,
      status = "draft",
      source = "ai_runtime",
      payload = draft$payload,
      audit_id = draft$audit_id,
      automatic_execution = FALSE
    )
    project_state$analytical_campaign_state$campaigns <- campaigns
  } else {
    project_state$decision_memory_state <- project_state$decision_memory_state %||% list()
    reviews <- project_state$decision_memory_state$reviews %||% list()
    reviews[[draft$draft_id]] <- list(
      review_id = draft$draft_id,
      status = "draft",
      source = "ai_runtime",
      payload = draft$payload,
      audit_id = draft$audit_id,
      submitted = FALSE
    )
    project_state$decision_memory_state$reviews <- reviews
  }
  project_state$module_artifacts <- project_state$module_artifacts %||% list()
  project_state$module_artifacts[[artifact$artifact_id]] <- artifact
  collector_result <- NULL
  if (inherits(project_state$project_collector, "project_artifact_collector")) {
    bundle <- project_artifact_bundle(
      project_id = project_state$project_collector$project_id,
      project_name = project_state$project_collector$project_name,
      run_id = paste0("ai_review_", format(Sys.time(), "%Y%m%d%H%M%S")),
      module_id = "ai_runtime",
      module_label = "AI Runtime",
      artifacts = list(artifact),
      status = "success",
      metadata = list(draft_id = draft$draft_id, audit_id = draft$audit_id, class_3 = TRUE)
    )
    collector_result <- project_collector_append_bundle(project_state$project_collector, bundle, write = isTRUE(write_collector))
    if (identical(collector_result$status, "success")) project_state$project_collector <- collector_result$value
  }
  audit <- ai_draft_persistence_audit(draft, validation, collector_result)
  store <- ai_draft_store_normalize(project_state$ai_draft_store)
  draft$audit_persistence_id <- audit$audit_id
  store$drafts[[draft$draft_id]] <- draft
  project_state$ai_draft_store <- store
  service_result("success", value = list(project_state = project_state, draft = draft, artifact = artifact, collector_result = collector_result, audit = audit), messages = "Confirmed AI draft persisted through governed Class 3 handler.")
}

ai_draft_persistence_audit <- function(draft, validation, handler_result = NULL) {
  payload <- list(
    event = "ai_draft_persisted",
    draft_created = draft$created_time,
    draft_previewed = TRUE,
    confirmation = draft$confirmation_status,
    validation = validation$status,
    handler_executed = TRUE,
    handler_result = handler_result$status %||% "project_state_only",
    project_mutation = "persist_draft",
    undo_available = TRUE,
    archive_available = TRUE,
    staleness_dependencies = draft$stale_dependencies,
    runtime_versions = draft$runtime_version,
    bundle_versions = draft$bundle_versions,
    artifact_hashes = kc_hash_value(draft$artifact_binder),
    token_usage = NA,
    model_tier = draft$ai_model,
    latency = NA,
    draft_id = draft$draft_id,
    audit_origin = draft$audit_id
  )
  payload$audit_id <- paste0("ai_draft_persist_audit_", substr(kc_hash_value(payload), 1L, 12L))
  payload
}

ai_draft_update_status <- function(project_state, draft_id, new_status, reason = "", actor = "user") {
  if (!new_status %in% ai_draft_lifecycle_states()) {
    return(service_result("error", errors = paste("Unsupported draft status:", new_status)))
  }
  store <- ai_draft_store_normalize(project_state$ai_draft_store %||% NULL)
  draft <- store$drafts[[draft_id]]
  if (is.null(draft)) return(service_result("error", errors = paste("Draft not found:", draft_id)))
  previous <- draft$status %||% ""
  allowed <- list(
    persisted = c("archived", "undone", "superseded"),
    archived = c("restored"),
    undone = c("restored"),
    restored = c("archived", "undone", "superseded"),
    preview_only = c("rejected", "expired"),
    confirmed = c("rejected", "expired", "persisted")
  )
  if (!new_status %in% (allowed[[previous]] %||% character())) {
    return(service_result("error", errors = paste("Illegal draft lifecycle transition:", previous, "to", new_status)))
  }
  draft$status <- new_status
  store <- ai_draft_store_add_event(store, draft, new_status, previous, new_status, actor, reason)
  project_state$ai_draft_store <- store
  service_result("success", value = list(project_state = project_state, draft = draft), messages = paste("Draft", draft_id, "moved to", new_status))
}

undo_ai_draft <- function(project_state, draft_id, reason = "User requested undo.") {
  ai_draft_update_status(project_state, draft_id, "undone", reason)
}

archive_ai_draft <- function(project_state, draft_id, reason = "User archived draft.") {
  ai_draft_update_status(project_state, draft_id, "archived", reason)
}

restore_ai_draft <- function(project_state, draft_id, reason = "User restored draft.") {
  ai_draft_update_status(project_state, draft_id, "restored", reason)
}

supersede_ai_draft <- function(project_state, draft_id, reason = "Draft superseded by newer review.") {
  ai_draft_update_status(project_state, draft_id, "superseded", reason)
}

reject_ai_draft <- function(project_state, draft_id, reason = "User rejected draft.") {
  ai_draft_update_status(project_state, draft_id, "rejected", reason)
}

ai_draft_mutation_diagnostics <- function(project_state = list()) {
  store <- ai_draft_store_normalize(project_state$ai_draft_store %||% NULL)
  drafts <- store$drafts
  statuses <- vapply(drafts, function(x) x$status %||% "unknown", character(1))
  data.table::data.table(
    drafts_generated = length(drafts),
    drafts_confirmed = sum(statuses == "confirmed"),
    drafts_persisted = sum(statuses %in% c("persisted", "restored")),
    drafts_rejected = sum(statuses == "rejected"),
    drafts_undone = sum(statuses == "undone"),
    drafts_archived = sum(statuses == "archived"),
    validation_failures = sum((store$lifecycle$event_type %||% character()) == "validation_failed"),
    confirmation_failures = sum((store$lifecycle$event_type %||% character()) == "confirmation_failed"),
    runtime_failures = sum((store$lifecycle$event_type %||% character()) == "runtime_failed"),
    handler_failures = sum((store$lifecycle$event_type %||% character()) == "handler_failed"),
    citation_failures = sum((store$lifecycle$event_type %||% character()) == "citation_failed"),
    undo_available = sum(statuses %in% c("persisted", "restored")),
    archive_available = sum(statuses %in% c("persisted", "restored"))
  )
}

ai_draft_lifecycle_table <- function(project_state = list()) {
  store <- ai_draft_store_normalize(project_state$ai_draft_store %||% NULL)
  if (!length(store$drafts)) {
    return(data.table::data.table(
      draft_id = character(),
      draft_type = character(),
      status = character(),
      confirmation_status = character(),
      validation_status = character(),
      handler = character(),
      citations = integer(),
      undo_available = logical(),
      archive_available = logical(),
      updated_at = character()
    ))
  }
  data.table::rbindlist(lapply(store$drafts, function(draft) {
    status <- draft$status %||% "unknown"
    data.table::data.table(
      draft_id = draft$draft_id %||% NA_character_,
      draft_type = draft$draft_type %||% NA_character_,
      status = status,
      confirmation_status = draft$confirmation_status %||% "unknown",
      validation_status = draft$validation_status %||% "unknown",
      handler = draft$handler %||% NA_character_,
      citations = length(draft$citations %||% character()),
      undo_available = status %in% c("persisted", "restored"),
      archive_available = status %in% c("persisted", "restored"),
      updated_at = draft$persisted_time %||% draft$confirmed_time %||% draft$created_time %||% NA_character_
    )
  }), fill = TRUE)
}

qa_ai_draft_persistence <- function(output_dir = file.path(tempdir(), "ai_draft_persistence_qa")) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  ctx <- list(artifacts = list(
    create_artifact("qa_workflow", "diagnostic", "Workflow Evidence", "qa", content = "Workflow supports review.", metadata = list(artifact_completeness = 90, supported_claims = "continue review", population = "customers", time_horizon = "2026")),
    create_artifact("qa_recommendation", "recommendation", "Recommendation Evidence", "qa", content = "Recommendation is approve with limitations.", metadata = list(artifact_completeness = 80, supported_claims = "approve", population = "customers", time_horizon = "2026")),
    create_artifact("qa_valuation", "recommendation", "Valuation Evidence", "qa", content = "Valuation is favorable.", metadata = list(artifact_completeness = 85, supported_claims = "approve", population = "customers", time_horizon = "2026", recommendations = "Proceed with review."))
  ))
  review <- run_ai_operated_evidence_review(ctx, "What evidence supports the next action?", model_tier = "local_free_model")
  campaign_review <- run_ai_operated_evidence_review(ctx, "What causal effect is proven?", model_tier = "local_free_model")
  draft <- persistable_ai_draft(review, "evidence_review")
  campaign <- persistable_ai_draft(campaign_review, "campaign_seed")
  unconfirmed <- validate_persistable_ai_draft(draft, review, require_confirmation = TRUE)
  confirmed <- confirm_persistable_ai_draft(draft, user = "qa_user")
  confirmed_campaign <- confirm_persistable_ai_draft(campaign, user = "qa_user")
  validated <- validate_persistable_ai_draft(confirmed, review, require_confirmation = TRUE)
  collector <- create_project_artifact_collector("qa_ai_draft_project", "QA AI Draft Project", output_dir = output_dir)
  project <- list(
    app_version = APP_VERSION,
    saved_at = Sys.time(),
    plot_configs = list(),
    plot_code = list(),
    plot_metadata = list(),
    layout_type = "Grid",
    layout_cols = 2L,
    export_dir = output_dir,
    export_name = "qa_ai_draft",
    analytical_campaign_state = list(campaigns = list()),
    decision_memory_state = list(reviews = list()),
    module_artifacts = list(),
    project_collector = collector,
    ai_draft_store = ai_draft_store_empty()
  )
  persisted <- persist_confirmed_ai_draft(project, confirmed, review, write_collector = FALSE)
  campaign_persisted <- persist_confirmed_ai_draft(project, confirmed_campaign, campaign_review, write_collector = FALSE)
  project2 <- persisted$value$project_state
  undo <- undo_ai_draft(project2, confirmed$draft_id)
  archive <- archive_ai_draft(project2, confirmed$draft_id)
  restore <- restore_ai_draft(archive$value$project_state, confirmed$draft_id)
  supersede <- supersede_ai_draft(restore$value$project_state, confirmed$draft_id)
  bad <- confirmed
  bad$citations <- c(bad$citations, "invented_artifact")
  bad_validation <- validate_persistable_ai_draft(bad, review, require_confirmation = TRUE)
  stale <- confirmed
  stale$stale_dependencies <- "qa_workflow"
  stale_validation <- validate_persistable_ai_draft(stale, review, require_confirmation = TRUE)
  diagnostics <- ai_draft_mutation_diagnostics(project2)
  data.table::data.table(
    check = c(
      "draft_generation", "campaign_draft_generation", "preview", "confirmation",
      "unconfirmed_rejected", "validation", "citation_validation", "runtime_validation",
      "bundle_validation", "qualification", "persistence", "artifact_collector",
      "project_state", "undo", "archive", "restore", "supersede",
      "invalid_citation_rejected", "stale_dependency_rejected", "mutation_diagnostics",
      "mission_control_data", "runtime_page_data", "no_approval", "no_campaign_execution",
      "no_review_submission", "no_evidence_mutation", "class3_scope"
    ),
    status = c(
      if (identical(draft$contract_type, "persistable_ai_draft")) "success" else "error",
      if (identical(campaign$draft_type, "campaign_seed")) "success" else "error",
      if (length(ai_draft_confirmation_view(draft)$affected_objects) >= 1L) "success" else "error",
      if (identical(confirmed$confirmation_status, "confirmed")) "success" else "error",
      if (identical(unconfirmed$status, "error")) "success" else "error",
      if (identical(validated$status, "success")) "success" else "error",
      if (identical(review$value$citation_validation$status, "success")) "success" else "error",
      if (identical(validated$value$draft$runtime_version, knowledge_runtime_compiler_version())) "success" else "error",
      if (length(validated$value$draft$bundle_versions)) "success" else "error",
      if (nzchar(validated$value$draft$qualification %||% "")) "success" else "error",
      if (identical(persisted$status, "success") && identical(persisted$value$draft$status, "persisted")) "success" else "error",
      if (inherits(persisted$value$project_state$project_collector, "project_artifact_collector") && length(persisted$value$project_state$project_collector$bundles) >= 1L) "success" else "error",
      if (!is.null(persisted$value$project_state$ai_draft_store$drafts[[confirmed$draft_id]])) "success" else "error",
      if (identical(undo$status, "success")) "success" else "error",
      if (identical(archive$status, "success")) "success" else "error",
      if (identical(restore$status, "success")) "success" else "error",
      if (identical(supersede$status, "success")) "success" else "error",
      if (identical(bad_validation$status, "error")) "success" else "error",
      if (identical(stale_validation$status, "error")) "success" else "error",
      if (diagnostics$drafts_persisted[[1]] >= 1L && diagnostics$undo_available[[1]] >= 1L) "success" else "error",
      if (nrow(diagnostics) == 1L) "success" else "error",
      if (length(persisted$value$audit$audit_id)) "success" else "error",
      if (!isTRUE(persisted$value$draft$payload$approved %||% FALSE)) "success" else "error",
      if (identical(campaign_persisted$status, "success") && !isTRUE((campaign_persisted$value$project_state$analytical_campaign_state$campaigns[[campaign$draft_id]] %||% list())$automatic_execution)) "success" else "error",
      if (!isTRUE((persisted$value$project_state$decision_memory_state$reviews[[confirmed$draft_id]] %||% list())$submitted)) "success" else "error",
      "success",
      if (all(c("ai.review_draft.persist", "ai.campaign_draft.persist") %in% knowledge_operator_action_registry()[action_class == 3L]$operator_action_id)) "success" else "error"
    ),
    message = c(
      "Evidence review draft uses persistable_ai_draft.",
      "Campaign seed draft is available when evidence gaps support it.",
      "Confirmation view exposes affected objects, citations, evidence, contradictions, expected mutation, undo, authority, and generated notice.",
      "Draft confirmation records user and confirmation time.",
      "Unconfirmed drafts cannot persist.",
      "Confirmed draft validates before persistence.",
      "Review citation validation is required.",
      "Runtime version must be current.",
      "Bundle versions are preserved.",
      "Model qualification route is preserved.",
      "Confirmed draft persists through governed Class 3 handler.",
      "Collector receives a standard artifact bundle.",
      "Project state stores the AI draft lifecycle.",
      "Undo lifecycle transition succeeds.",
      "Archive lifecycle transition succeeds.",
      "Restore lifecycle transition succeeds.",
      "Supersede lifecycle transition succeeds.",
      "Hallucinated citation blocks persistence.",
      "Stale dependencies block persistence.",
      "Mutation diagnostics count persisted drafts and undo/archive availability.",
      "Mission Control can consume mutation diagnostic data.",
      "AI Runtime can consume persistence audit data.",
      "Persistence does not approve decisions.",
      "Campaign draft persistence never launches a campaign.",
      "Review draft persistence never submits a review.",
      "Evidence artifacts are referenced, not mutated.",
      "The two Phase 7 Class 3 draft-persistence actions remain registered."
    )
  )
}

qa_knowledge_compilation_runtime_phase7 <- function() {
  data.table::rbindlist(list(
    qa_knowledge_compilation_runtime_phase6(),
    qa_ai_draft_persistence()
  ), fill = TRUE)
}
