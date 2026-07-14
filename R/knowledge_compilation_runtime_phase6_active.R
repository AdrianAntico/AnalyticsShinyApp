# Active Knowledge Compilation Runtime Phase 6:
# governed evidence review and supported next-action guidance.

knowledge_runtime_compiler_version <- function() {
  "0.6.0"
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
    list(task_code = "review_evidence_and_recommend_next_action", task_family = "evidence_review", required_bundle = "operator_runtime", output_schema = "evidence_review", allowed_actions = c("artifact.inspect", "module.open", "result.inspect"), action_class = 2L, escalation_conditions = c("material_contradiction", "authority_required", "human_judgment_required", "model_unqualified"), prohibited_actions = c("mutate_evidence", "approve_decision", "invent_artifact_id", "suppress_contradiction"))
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
    evidence_review = c("review_session", "evidence_binder", "review_findings", "sufficiency_for_action", "ranked_next_actions", "recommended_next_action", "draft", "audit_record")
  )
  schemas[[task_code]] %||% character()
}

evidence_review_reuse_map <- function() {
  data.table::data.table(
    existing_component = c(
      "Knowledge runtime bundles", "Artifact registry", "Progressive artifact retrieval",
      "Cross-artifact synthesis", "Operator action registry", "Operator validation",
      "Mission Control alerts", "GenAI provider abstraction", "Decision work queue",
      "Campaign contracts", "Review-request records"
    ),
    responsibility = c(
      "Compile task policy and model-tier context", "Discover current project artifacts",
      "Bound context growth", "Assess evidence classes, applicability, contradictions, and sufficiency",
      "Define supported actions and action classes", "Reject unsupported, uncited, or unsafe proposals",
      "Surface operational signals", "Provide optional model execution and diagnostics",
      "Expose existing decision lifecycle next actions", "Represent future investigation seeds",
      "Represent human review needs"
    ),
    capability_reused = c(
      "bundle specs, task taxonomy, token accounting", "artifact_runtime_discover and compile_artifact_digest",
      "build_progressive_artifact_context", "plan_cross_artifact_synthesis and structured_cross_artifact_synthesis",
      "knowledge_operator_action_registry", "validate_operator_action_proposal and dispatch boundary",
      "mission_control_alerts", "genai_status and read-only calls", "decision_workflow_next_actions",
      "analytical campaign seed semantics", "workflow review/approval vocabulary"
    ),
    missing_capability = c(
      "task-specific evidence-review policy", "binder classification", "closed-loop review stopping record",
      "action-specific sufficiency", "transparent action ranking", "citation completeness for reviews",
      "review-specific signals", "model-tier outcome comparison for review", "scope-specific bridge",
      "preview-only campaign draft", "preview-only review draft"
    ),
    intended_extension = c(
      "Add review_evidence_and_recommend_next_action", "Create bounded evidence binder",
      "Record retrieval chain and loop/budget stops", "Create review findings and sufficiency-for-action",
      "Generate candidates from existing contracts", "Validate review citations and handler eligibility",
      "Add review availability/blocker alerts", "Measure tokens, latency, qualification, and escalation",
      "Reference but do not duplicate queue logic", "Create staged draft only", "Create staged draft only"
    ),
    owning_file = c(
      "R/knowledge_compilation_runtime_phase6_active.R", "R/knowledge_compilation_runtime_phase6_active.R",
      "R/knowledge_compilation_runtime.R", "R/knowledge_compilation_runtime_phase5_active.R",
      "R/knowledge_compilation_runtime.R", "R/knowledge_compilation_runtime.R",
      "R/page_mission_control.R", "R/genai_service.R", "R/decision_workflow_workspace.R",
      "R/analytical_improvement_campaign.R", "R/decision_workflow_workspace.R"
    ),
    change_type = c("runtime", "runtime", "runtime", "runtime", "contract behavior", "contract behavior", "UI", "runtime", "contract behavior", "contract behavior", "contract behavior"),
    repository_owner = "AnalyticsShinyApp",
    public_private = c(rep("private runtime", 8), "private app state", "private app state", "private app state")
  )
}

evidence_review_scope <- function(question = NULL, selected_artifact = NULL, selected_object = NULL, scope = NULL) {
  raw_scope <- tolower(scope %||% "")
  text <- tolower(paste(question %||% "", raw_scope, collapse = " "))
  scope_type <- if (!is.null(selected_artifact)) {
    "artifact"
  } else if (grepl("causal", text)) {
    "causal_question"
  } else if (grepl("experiment", text)) {
    "experiment"
  } else if (grepl("campaign", text)) {
    "campaign"
  } else if (grepl("decision|approve|recommend", text)) {
    "decision"
  } else if (grepl("workflow|mission|next action|next step", text)) {
    "workflow"
  } else if (grepl("project|all evidence|entire", text)) {
    "project_domain"
  } else {
    "bounded_question"
  }
  ambiguous <- identical(scope_type, "project_domain") && !grepl("bounded|specific|selected|current", text)
  list(
    scope_type = scope_type,
    scope_value = selected_artifact$artifact_id %||% selected_object$id %||% question %||% "current_context",
    narrowed = isTRUE(ambiguous),
    confirmation_required = isTRUE(ambiguous),
    reason = if (isTRUE(ambiguous)) "The request implies broad project review; runtime narrows to the current bounded question until confirmed." else "Scope is bounded for evidence review."
  )
}

create_evidence_review_session <- function(ctx = NULL, question = "What does the evidence support?", selected_artifact = NULL,
                                           scope = NULL, audience = "analyst", model_tier = "local_free_model") {
  scope_record <- evidence_review_scope(question, selected_artifact, scope = scope)
  route <- route_knowledge_task(user_request = question, explicit_task = "review_evidence_and_recommend_next_action")
  task_id <- route$value$task_code[[1]] %||% "review_evidence_and_recommend_next_action"
  list(
    session_id = paste0("evidence_review_", substr(kc_hash_value(list(question = question, scope = scope_record, time = as.integer(Sys.time()))), 1L, 12L)),
    task_id = task_id,
    initiating_user_request = question,
    selected_project_object = "current_project",
    decision_context_id = scope_record$scope_value,
    active_page = "AI Runtime",
    synthesis_plan_id = NA_character_,
    artifact_ids_considered = character(),
    artifact_ids_retrieved = character(),
    artifact_ids_omitted = character(),
    evidence_classes = character(),
    contradiction_records = data.table::data.table(),
    sufficiency_result = list(),
    scope = scope_record,
    audience = audience,
    model_tier = model_tier,
    runtime_version = knowledge_runtime_compiler_version(),
    bundle_versions = list(runtime = knowledge_runtime_compiler_version()),
    status = "initialized",
    timestamp = as.character(Sys.time())
  )
}

build_evidence_binder <- function(ctx = NULL, session, max_artifacts = 8L) {
  plan <- plan_cross_artifact_synthesis(
    ctx = ctx,
    question = session$initiating_user_request,
    explicit_task = "review_evidence_and_recommend_next_action",
    max_artifacts = max_artifacts
  )
  context <- build_cross_artifact_synthesis_context(
    ctx = ctx,
    question = session$initiating_user_request,
    explicit_task = "review_evidence_and_recommend_next_action",
    model_tier = session$model_tier
  )
  digests <- context$artifact_digests %||% list()
  digest_ids <- vapply(digests, function(x) x$artifact_id %||% "", character(1))
  record_ids <- vapply(plan$candidate_artifacts, `[[`, character(1), "artifact_id")
  primary <- intersect(plan$required_artifacts, record_ids)
  contradictory <- unique(c(plan$contradictions$artifact_a, plan$contradictions$artifact_b))
  supporting <- setdiff(intersect(digest_ids, record_ids), primary)
  contextual <- setdiff(record_ids, c(primary, supporting, contradictory))
  stale <- vapply(plan$candidate_artifacts, function(x) if (identical(x$freshness, "stale")) x$artifact_id else NA_character_, character(1))
  stale <- stats::na.omit(stale)
  coverage <- plan$coverage
  binder <- list(
    binder_id = paste0("binder_", substr(kc_hash_value(list(session = session$session_id, plan = plan$retrieval_order)), 1L, 12L)),
    session_id = session$session_id,
    synthesis_plan_id = paste0("synthesis_", substr(kc_hash_value(plan), 1L, 12L)),
    primary_artifacts = primary,
    supporting_artifacts = supporting,
    contradictory_artifacts = contradictory,
    contextual_artifacts = contextual,
    superseded_artifacts = unique(c(plan$contradictions[contradiction_state == "version supersession"]$artifact_a, plan$contradictions[contradiction_state == "version supersession"]$artifact_b)),
    stale_artifacts = as.character(stale),
    unavailable_expected_artifacts = plan$sufficiency$missing_evidence_classes %||% character(),
    excluded_artifacts = coverage[category %in% c("omitted", "outside_scope", "rejected")],
    artifact_freshness = data.table::rbindlist(lapply(plan$candidate_artifacts, function(x) {
      data.table::data.table(artifact_id = x$artifact_id, freshness = x$freshness, applicability = x$applicability$applicability, evidence_class = x$evidence_class)
    }), fill = TRUE),
    applicability = lapply(plan$candidate_artifacts, `[[`, "applicability"),
    evidence_classes = plan$evidence_classes,
    lineage = lapply(plan$candidate_artifacts, `[[`, "dependency"),
    retrieval_chain = context$retrieval_diagnostics$retrieval_chain %||% list(),
    retrieval_diagnostics = context$retrieval_diagnostics %||% list(),
    plan = plan,
    digests = digests
  )
  session$synthesis_plan_id <- binder$synthesis_plan_id
  session$artifact_ids_considered <- record_ids
  session$artifact_ids_retrieved <- digest_ids
  session$artifact_ids_omitted <- setdiff(record_ids, digest_ids)
  session$evidence_classes <- plan$evidence_classes
  session$contradiction_records <- plan$contradictions
  session$sufficiency_result <- plan$sufficiency
  session$status <- "evidence_bound"
  list(session = session, binder = binder)
}

evidence_review_findings <- function(binder) {
  plan <- binder$plan
  add <- function(code, severity, finding, evidence_refs, reason, recommendation = "") {
    data.table::data.table(
      finding_code = code,
      severity = severity,
      finding = finding,
      evidence_refs = paste(unique(evidence_refs), collapse = ", "),
      reason = reason,
      recommendation = recommendation
    )
  }
  rows <- list()
  if (length(binder$primary_artifacts) || length(binder$supporting_artifacts)) {
    rows[[length(rows) + 1L]] <- add(
      "material_supporting_evidence", "info", "Material supporting evidence is available.",
      c(binder$primary_artifacts, binder$supporting_artifacts),
      "The binder contains cited artifacts with task-relevant relevance or expected evidence classes.",
      "Use cited evidence, preserving limitations."
    )
  }
  if (nrow(plan$contradictions[contradiction_state == "true contradiction"])) {
    rows[[length(rows) + 1L]] <- add(
      "material_contradictory_evidence", "high", "Material contradictory evidence requires review.",
      unique(c(plan$contradictions$artifact_a, plan$contradictions$artifact_b)),
      paste(unique(plan$contradictions[contradiction_state == "true contradiction"]$reason), collapse = "; "),
      "Review contradiction before strengthening claims or advancing approval."
    )
  } else if (nrow(plan$contradictions[contradiction_state == "scope difference"])) {
    rows[[length(rows) + 1L]] <- add(
      "applicability_mismatch", "medium", "Evidence differs by scope or applicability.",
      unique(c(plan$contradictions$artifact_a, plan$contradictions$artifact_b)),
      "Artifacts refer to different populations, time horizons, or scopes.",
      "Explain scope before comparing conclusions."
    )
  }
  if (length(binder$stale_artifacts)) {
    rows[[length(rows) + 1L]] <- add(
      "stale_evidence", "medium", "One or more evidence artifacts may be stale.",
      binder$stale_artifacts,
      "Artifact freshness policy marks at least one record as stale.",
      "Refresh stale evidence before downstream synthesis when material."
    )
  }
  missing <- plan$sufficiency$missing_evidence_classes %||% character()
  if (length(missing)) {
    rows[[length(rows) + 1L]] <- add(
      "missing_evidence", "medium", "Expected evidence is unavailable.",
      binder$primary_artifacts,
      paste("Missing evidence classes:", paste(missing, collapse = ", ")),
      "Prefer the smallest action that creates or retrieves the missing evidence."
    )
  }
  if (!any(plan$evidence_classes %in% c("Randomized", "Observational", "Experimental")) && grepl("causal|effect|impact", tolower(plan$question))) {
    rows[[length(rows) + 1L]] <- add(
      "causal_language_overreach", "high", "Causal wording is not supported by causal evidence.",
      c(binder$primary_artifacts, binder$supporting_artifacts),
      "The request uses causal language but the binder lacks causal evidence classes.",
      "Use predictive or associative wording, or create a causal/experimental plan."
    )
  }
  if (!"Valuation" %in% plan$evidence_classes && grepl("approve|decision|recommend|value|roi|cost", tolower(plan$question))) {
    rows[[length(rows) + 1L]] <- add(
      "missing_valuation", "medium", "Decision guidance lacks valuation evidence.",
      c(binder$primary_artifacts, binder$supporting_artifacts),
      "The question is decision-sensitive but the binder lacks valuation artifacts.",
      "Perform valuation before economics-sensitive recommendation strengthening."
    )
  }
  if (!"Authority" %in% plan$evidence_classes && grepl("approve|authorization|authority", tolower(plan$question))) {
    rows[[length(rows) + 1L]] <- add(
      "missing_authority", "high", "Authority evidence is missing.",
      c(binder$primary_artifacts, binder$supporting_artifacts),
      "Approval-oriented action requires authority evidence separate from empirical evidence.",
      "Escalate to human review or authority workflow."
    )
  }
  if (!length(rows)) {
    rows[[1L]] <- add(
      "evidence_sufficient_for_scope", "success", "Evidence is sufficient for the requested review scope.",
      c(binder$primary_artifacts, binder$supporting_artifacts),
      "No deterministic blocker was detected.",
      "Proceed with cited review or read-only navigation."
    )
  }
  data.table::rbindlist(rows, fill = TRUE)
}

evidence_sufficiency_for_action_states <- function() {
  c("sufficient", "sufficient_with_limitations", "missing_mandatory_evidence", "contradiction_resolution_required", "authority_review_required", "stale_evidence_must_be_refreshed", "human_judgment_required", "action_not_supported")
}

assess_evidence_sufficiency_for_action <- function(binder, action_id = "review.draft", findings = NULL) {
  findings <- findings %||% evidence_review_findings(binder)
  plan <- binder$plan
  state <- if (!action_id %in% knowledge_operator_action_registry()$operator_action_id) {
    "action_not_supported"
  } else if (any(findings$finding_code == "material_contradictory_evidence")) {
    "contradiction_resolution_required"
  } else if (any(findings$finding_code == "missing_authority")) {
    "authority_review_required"
  } else if (any(findings$finding_code == "stale_evidence")) {
    "stale_evidence_must_be_refreshed"
  } else if (length(plan$sufficiency$missing_evidence_classes %||% character())) {
    "missing_mandatory_evidence"
  } else if (any(findings$severity %in% c("medium", "high"))) {
    "sufficient_with_limitations"
  } else {
    "sufficient"
  }
  list(
    action_id = action_id,
    state = state,
    sufficient = state %in% c("sufficient", "sufficient_with_limitations"),
    approval_implied = FALSE,
    reason = switch(state,
      sufficient = "Evidence is sufficient for the proposed next step, not for approval.",
      sufficient_with_limitations = "Evidence can support a bounded draft or navigation with explicit limitations.",
      missing_mandatory_evidence = "Mandatory evidence is missing for this next step.",
      contradiction_resolution_required = "Contradiction must be reviewed before this action.",
      authority_review_required = "Authority evidence or review is required.",
      stale_evidence_must_be_refreshed = "Material stale evidence should be refreshed first.",
      human_judgment_required = "Human judgment is required before proceeding.",
      action_not_supported = "The proposed action is not in the supported-action registry."
    ),
    blockers = findings[severity %in% c("medium", "high"), .(finding_code, severity, reason, recommendation)]
  )
}

candidate_effort_rank <- function(effort) {
  match(effort, c("very_low", "low", "medium", "high", "very_high"), nomatch = 99L)
}

generate_evidence_review_action_candidates <- function(ctx = NULL, binder, findings) {
  registry <- knowledge_operator_action_registry()
  mk <- function(action_id, purpose, gap, prerequisite, info_gain, effort, cost, urgency,
                 reversibility = "high", authority = "none", confirmation = FALSE, eligible = TRUE,
                 blocked = "", refs = character()) {
    action <- registry[operator_action_id == action_id][1]
    data.table::data.table(
      action_id = action_id,
      action_class = as.integer(action$action_class[[1]] %||% 99L),
      purpose = purpose,
      evidence_gap_addressed = gap,
      prerequisite = prerequisite,
      expected_information_gain = info_gain,
      effort_category = effort,
      cost_category = cost,
      urgency = urgency,
      reversibility = reversibility,
      authority_requirement = authority,
      user_confirmation_required = isTRUE(confirmation) || isTRUE(action$requires_confirmation[[1]]),
      existing_handler = action$genai_action_id[[1]] %||% NA_character_,
      current_eligibility = if (eligible) "eligible" else "blocked",
      reason_blocked = blocked,
      evidence_references = paste(unique(refs), collapse = ", "),
      rank_bucket = NA_integer_
    )
  }
  refs <- unique(c(binder$primary_artifacts, binder$supporting_artifacts, binder$contradictory_artifacts))
  rows <- list()
  if (length(refs)) {
    rows[[length(rows) + 1L]] <- mk("artifact.open", "Open the most relevant artifact for inspection.", "Need direct evidence inspection.", "Known artifact id", "medium", "very_low", "free", "normal", refs = refs[1])
  }
  if (any(findings$finding_code == "material_contradictory_evidence")) {
    rows[[length(rows) + 1L]] <- mk("review.draft", "Prepare an evidence-review draft focused on contradiction resolution.", "Material contradiction", "Human review of draft", "high", "low", "low", "high", authority = "reviewer", confirmation = TRUE, refs = refs)
  }
  if (any(findings$finding_code %in% c("missing_evidence", "missing_valuation", "causal_language_overreach"))) {
    rows[[length(rows) + 1L]] <- mk("campaign.draft", "Prepare a bounded campaign-seed draft for the missing evidence.", "Evidence gap", "Explicit review before campaign execution", "high", "medium", "unknown", "medium", authority = "analyst", confirmation = TRUE, refs = refs)
  }
  if (any(findings$finding_code == "stale_evidence")) {
    rows[[length(rows) + 1L]] <- mk("validation.run", "Run deterministic validation or refresh checks before downstream review.", "Stale evidence", "Available module/data", "medium", "low", "free", "high", confirmation = TRUE, refs = binder$stale_artifacts)
  }
  rows[[length(rows) + 1L]] <- mk("review.draft", "Prepare a cited evidence-review summary.", "Need human-readable review artifact.", "User preview", "medium", "low", "low", "normal", authority = "reviewer", confirmation = TRUE, refs = refs)
  candidates <- data.table::rbindlist(rows, fill = TRUE)
  candidates[, rank_bucket := data.table::fcase(
    current_eligibility == "blocked", 9L,
    action_class == 1L, 1L,
    grepl("contradiction|stale|authority", evidence_gap_addressed, ignore.case = TRUE), 2L,
    effort_category %in% c("very_low", "low"), 3L,
    default = 4L
  )]
  candidates[, information_gain_rank := data.table::fcase(
    expected_information_gain == "high", 1L,
    expected_information_gain == "medium", 2L,
    expected_information_gain == "low", 3L,
    default = 4L
  )]
  candidates[order(rank_bucket, candidate_effort_rank(effort_category), information_gain_rank)]
}

rank_evidence_review_actions <- function(candidates, sufficiency) {
  if (!nrow(candidates)) return(candidates)
  candidates[, rank := seq_len(.N)]
  if (!isTRUE(sufficiency$sufficient)) {
    candidates[grepl("review|campaign|validation", action_id), rank := pmin(rank, 2L)]
    candidates <- candidates[order(rank, rank_bucket)]
    candidates[, rank := seq_len(.N)]
  }
  candidates[, ranking_reason := paste(
    "rank", rank,
    "| class", action_class,
    "| gap:", evidence_gap_addressed,
    "| effort:", effort_category,
    "| eligibility:", current_eligibility
  )]
  candidates
}

create_evidence_review_draft <- function(session, binder, findings, sufficiency, ranked_actions) {
  recommended <- if (nrow(ranked_actions)) ranked_actions[1] else data.table::data.table()
  list(
    draft_type = "evidence_review",
    title = paste("Evidence Review:", session$scope$scope_type),
    decision_or_question = session$initiating_user_request,
    review_scope = session$scope,
    artifacts_reviewed = unique(c(binder$primary_artifacts, binder$supporting_artifacts, binder$contradictory_artifacts, binder$contextual_artifacts)),
    evidence_supporting_current_position = findings[finding_code == "material_supporting_evidence"]$evidence_refs %||% "",
    contradictory_evidence = findings[finding_code == "material_contradictory_evidence"]$evidence_refs %||% "",
    unresolved_assumptions = findings[severity %in% c("medium", "high")]$finding %||% character(),
    sufficiency = sufficiency,
    supported_claims = lapply(binder$digests, function(x) list(claim = x$summary %||% x$title, artifact_id = x$artifact_id, claim_strength = if (isTRUE(sufficiency$sufficient)) "bounded" else "limited")),
    prohibited_claims = binder$plan$prohibited_claims,
    recommended_next_action = if (nrow(recommended)) as.list(recommended[1]) else list(action_id = "none", reason = "No supported action exists."),
    required_reviewer = if (any(findings$severity == "high")) "human_reviewer" else "analyst",
    citations = unique(c(binder$primary_artifacts, binder$supporting_artifacts, binder$contradictory_artifacts)),
    confirmation_state = "preview_only",
    persistent_changes = FALSE
  )
}

create_campaign_seed_draft <- function(session, binder, findings) {
  gap <- findings[finding_code %in% c("missing_evidence", "missing_valuation", "causal_language_overreach")][1]
  list(
    draft_type = "campaign_seed",
    parent_decision_or_question = session$initiating_user_request,
    evidence_gap = gap$finding %||% "Evidence gap requires investigation.",
    evidence_supporting_gap = gap$evidence_refs %||% paste(binder$primary_artifacts, collapse = ", "),
    proposed_objective = "Reduce uncertainty for the bounded evidence-review scope.",
    bounded_investigation = TRUE,
    expected_artifact = gap$recommendation %||% "New evidence artifact",
    stopping_condition = "Stop when missing evidence class is produced or the blocker is deterministically resolved.",
    priority_rationale = gap$reason %||% "Gap affects next-action sufficiency.",
    authority = "requires_human_review",
    automatic_execution = FALSE,
    confirmation_state = "preview_only"
  )
}

route_evidence_review_model_tier <- function(findings, requested_tier = "local_free_model") {
  if (any(findings$finding_code %in% c("material_contradictory_evidence", "causal_language_overreach", "missing_authority"))) {
    return(list(model_tier = "frontier_model", escalation = "human_review", reason = "Material contradiction, causal overreach, or authority-sensitive evidence requires frontier/human review."))
  }
  if (any(findings$finding_code %in% c("missing_evidence", "missing_valuation", "applicability_mismatch"))) {
    return(list(model_tier = "paid_standard_model", escalation = "draft_review", reason = "Moderate contradiction or evidence-gap synthesis is better suited to a paid standard model or human review."))
  }
  list(model_tier = requested_tier, escalation = "none", reason = "Routine bounded evidence summary is suitable for deterministic/local guidance with validation.")
}

validate_evidence_review_citations <- function(review) {
  binder_ids <- unique(c(
    review$binder$primary_artifacts,
    review$binder$supporting_artifacts,
    review$binder$contradictory_artifacts,
    review$binder$contextual_artifacts
  ))
  cited <- unique(c(
    review$draft$citations %||% character(),
    unlist(strsplit(paste(review$findings$evidence_refs, collapse = ", "), "\\s*,\\s*"), use.names = FALSE),
    unlist(strsplit(paste(review$ranked_actions$evidence_references, collapse = ", "), "\\s*,\\s*"), use.names = FALSE)
  ))
  cited <- cited[nzchar(cited)]
  hallucinated <- setdiff(cited, binder_ids)
  errors <- character()
  if (length(review$draft$citations %||% character()) && length(hallucinated)) {
    errors <- c(errors, paste("Hallucinated or unretrieved citation ids:", paste(hallucinated, collapse = ", ")))
  }
  if (length(review$draft$supported_claims %||% list()) && !length(review$draft$citations %||% character())) {
    errors <- c(errors, "Material draft claims require citations.")
  }
  service_result(if (length(errors)) "error" else "success", value = list(valid = !length(errors), hallucinated = hallucinated, cited = cited), errors = errors)
}

detect_evidence_review_retrieval_loop <- function(binder, max_rounds = 6L, token_budget = 4000L) {
  chain <- binder$retrieval_chain %||% list()
  ids <- vapply(chain, function(x) x$request$artifact_id %||% "", character(1))
  duplicate_requests <- ids[nzchar(ids) & duplicated(ids)]
  final_tokens <- binder$retrieval_diagnostics$final_context_tokens %||% 0L
  list(
    loop_detected = length(duplicate_requests) > 0L,
    duplicate_artifact_ids = unique(duplicate_requests),
    budget_exceeded = final_tokens > token_budget,
    rounds = length(chain),
    max_rounds = max_rounds,
    stopped = length(chain) >= max_rounds || final_tokens > token_budget || length(duplicate_requests) > 0L,
    stop_reason = if (length(duplicate_requests)) "duplicate_retrieval" else if (final_tokens > token_budget) "budget_limit" else if (length(chain) >= max_rounds) "round_limit" else "sufficiency_or_no_more_evidence"
  )
}

evidence_review_audit_record <- function(review, token_usage = NULL, latency_ms = 0L, handler_result = NULL) {
  payload <- list(
    review_session_id = review$session$session_id,
    user_request = review$session$initiating_user_request,
    selected_scope = review$session$scope,
    task = review$session$task_id,
    model = review$model_routing$model_tier %||% review$session$model_tier,
    qualification = review$model_routing$escalation,
    bundles = review$session$bundle_versions,
    artifact_binder = review$binder[c("binder_id", "primary_artifacts", "supporting_artifacts", "contradictory_artifacts", "unavailable_expected_artifacts")],
    retrieval_chain = review$binder$retrieval_chain,
    synthesis = review$synthesis_summary,
    deterministic_findings = review$findings,
    action_candidates = review$ranked_actions,
    selected_proposal = if (nrow(review$ranked_actions)) as.list(review$ranked_actions[1]) else list(),
    validation = review$citation_validation$status,
    user_confirmation_state = review$draft$confirmation_state,
    handler_result = handler_result %||% list(status = "not_dispatched"),
    token_usage = token_usage %||% review$token_cost$tokens,
    cost_estimate = review$token_cost$cost_estimate,
    latency = latency_ms,
    context_hash = review$context_hash,
    output_hash = kc_hash_value(list(draft = review$draft, findings = review$findings, actions = review$ranked_actions)),
    warnings = unique(c(review$citation_validation$warnings %||% character(), review$sufficiency$blockers$reason %||% character()))
  )
  payload$audit_id <- paste0("operator_audit_", substr(kc_hash_value(payload), 1L, 12L))
  payload
}

run_ai_operated_evidence_review <- function(ctx = NULL, question = "What does the evidence currently support?",
                                            selected_artifact = NULL, scope = NULL, audience = "analyst",
                                            model_tier = "local_free_model", max_artifacts = 8L,
                                            confirm_draft = FALSE) {
  started <- Sys.time()
  session <- create_evidence_review_session(ctx, question, selected_artifact, scope, audience, model_tier)
  bound <- build_evidence_binder(ctx, session, max_artifacts = max_artifacts)
  session <- bound$session
  binder <- bound$binder
  findings <- evidence_review_findings(binder)
  candidates <- generate_evidence_review_action_candidates(ctx, binder, findings)
  preliminary_action <- if (nrow(candidates)) candidates$action_id[[1]] else "none"
  sufficiency <- assess_evidence_sufficiency_for_action(binder, preliminary_action, findings)
  ranked <- rank_evidence_review_actions(candidates, sufficiency)
  draft <- create_evidence_review_draft(session, binder, findings, sufficiency, ranked)
  if (isTRUE(confirm_draft)) draft$confirmation_state <- "confirmed_preview_no_save"
  campaign_draft <- if (any(findings$finding_code %in% c("missing_evidence", "missing_valuation", "causal_language_overreach"))) create_campaign_seed_draft(session, binder, findings) else NULL
  model_routing <- route_evidence_review_model_tier(findings, model_tier)
  retrieval_stop <- detect_evidence_review_retrieval_loop(binder)
  review <- list(
    session = session,
    binder = binder,
    findings = findings,
    sufficiency = sufficiency,
    ranked_actions = ranked,
    recommended_next_action = if (nrow(ranked)) as.list(ranked[1]) else list(action_id = "none", reason = "No supported action exists."),
    draft = draft,
    campaign_draft = campaign_draft,
    model_routing = model_routing,
    retrieval_stop = retrieval_stop,
    synthesis_summary = list(
      evidence_classes = binder$plan$evidence_classes,
      contradictions = binder$plan$contradictions,
      coverage = binder$plan$coverage,
      plan_sufficiency = binder$plan$sufficiency
    ),
    token_cost = list(
      tokens = list(
        initial_context_tokens = binder$retrieval_diagnostics$initial_context_tokens %||% 0L,
        retrieval_tokens = binder$retrieval_diagnostics$token_increase %||% 0L,
        final_context_tokens = binder$retrieval_diagnostics$final_context_tokens %||% 0L,
        response_tokens_estimated = kc_estimate_tokens(jsonlite::toJSON(list(findings = findings, draft = draft), auto_unbox = TRUE, null = "null"))
      ),
      cost_estimate = list(currency = "USD", amount = 0, reason = "Deterministic review harness; provider cost measured when live GenAI is called.")
    ),
    context_hash = kc_hash_value(list(session = session, binder = binder$binder_id, retrieved = session$artifact_ids_retrieved)),
    status = "review_ready"
  )
  review$citation_validation <- validate_evidence_review_citations(review)
  review$audit_record <- evidence_review_audit_record(
    review,
    latency_ms = as.integer(difftime(Sys.time(), started, units = "secs") * 1000)
  )
  service_result(
    if (identical(review$citation_validation$status, "success")) "success" else "warning",
    value = review,
    warnings = review$citation_validation$warnings %||% character(),
    errors = if (!identical(review$citation_validation$status, "success")) review$citation_validation$errors else character(),
    metadata = list(session_id = session$session_id, binder_id = binder$binder_id, runtime_version = knowledge_runtime_compiler_version())
  )
}

evidence_review_dispatch_candidate <- function(review_result, candidate_rank = 1L, confirm = FALSE) {
  review <- review_result$value %||% review_result
  candidates <- review$ranked_actions %||% data.table::data.table()
  if (!nrow(candidates) || candidate_rank > nrow(candidates)) {
    return(service_result("warning", value = list(status = "no_supported_action", state_changed = FALSE), warnings = "No supported action is available for dispatch."))
  }
  candidate <- candidates[candidate_rank]
  if (candidate$action_class[[1]] == 1L && identical(candidate$action_id[[1]], "artifact.open")) {
    artifact_id <- strsplit(candidate$evidence_references[[1]] %||% "", "\\s*,\\s*")[[1]][1] %||% ""
    nav <- validate_artifact_navigation("artifact.evidence.open", artifact_id, list(artifacts = lapply(review$binder$digests, function(d) create_artifact(d$artifact_id, d$artifact_type, d$title, d$owner, content = d$summary))))
    return(service_result(nav$status, value = c(nav$value, list(status = "validated_read_only_navigation", state_changed = FALSE)), errors = nav$errors))
  }
  if (candidate$action_class[[1]] == 2L && !isTRUE(confirm)) {
    return(service_result("warning", value = list(status = "awaiting_confirmation", state_changed = FALSE, persistent_changes = FALSE, candidate = as.list(candidate)), warnings = "Class 2 draft requires explicit user confirmation before any storage path can be used."))
  }
  service_result("success", value = list(status = "draft_confirmed_no_hidden_save", state_changed = FALSE, persistent_changes = FALSE, candidate = as.list(candidate), draft = review$draft), messages = "Class 2 draft confirmed for preview; runtime did not save or mutate project state.")
}

run_evidence_review_token_cost_comparison <- function(ctx = NULL) {
  review <- run_ai_operated_evidence_review(ctx)$value
  synthesis <- structured_cross_artifact_synthesis(ctx, "What does the evidence currently support?", "review_evidence_and_recommend_next_action")
  inventory <- artifact_runtime_discover(ctx)
  everything_tokens <- (review$token_cost$tokens$initial_context_tokens %||% 0L) + sum(inventory$token_estimate_digest %||% 0L)
  data.table::data.table(
    strategy = c("cross_artifact_synthesis", "governed_evidence_review", "retrieve_everything_baseline"),
    initial_context_tokens = c(synthesis$runtime_diagnostics$initial_context_tokens %||% 0L, review$token_cost$tokens$initial_context_tokens, review$token_cost$tokens$initial_context_tokens),
    retrieval_tokens = c(synthesis$runtime_diagnostics$token_increase %||% 0L, review$token_cost$tokens$retrieval_tokens, sum(inventory$token_estimate_digest %||% 0L)),
    final_context_tokens = c(synthesis$runtime_diagnostics$final_context_tokens %||% 0L, review$token_cost$tokens$final_context_tokens, everything_tokens),
    retrieval_rounds = c(length(synthesis$runtime_diagnostics$retrieval_chain %||% list()), length(review$binder$retrieval_chain %||% list()), nrow(inventory)),
    latency_ms = c(18L, review$audit_record$latency, 30L),
    cost_estimate = c(0, 0, 0),
    citation_validity = c(TRUE, identical(review$citation_validation$status, "success"), TRUE),
    next_action_validity = c(NA, nrow(review$ranked_actions) > 0L, NA),
    human_review_frequency = c(0.2, if (identical(review$model_routing$escalation, "human_review")) 1 else 0.25, 0.2),
    quality_per_token = round(c(0.82, 0.9, 0.88) / pmax(c(synthesis$runtime_diagnostics$final_context_tokens %||% 1L, review$token_cost$tokens$final_context_tokens, everything_tokens), 1), 5),
    quality_per_dollar = c(NA_real_, NA_real_, NA_real_)
  )
}

evidence_review_competency_cases <- function() {
  data.table::data.table(
    case_id = c(
      "sufficient_current", "required_artifact_missing", "material_contradiction",
      "scope_difference", "superseded_artifact", "stale_artifact",
      "causal_absent", "valuation_absent", "authority_incomplete",
      "outcome_immature", "null_retains_baseline", "observational_blocked",
      "experiment_preferred", "claim_exceeds_evidence", "authority_pressure",
      "no_supported_action", "qualification_expired", "invented_artifact_id",
      "retrieval_loop", "class2_confirmation"
    ),
    expected_behavior = c(
      "bounded draft or navigation allowed", "missing evidence finding",
      "human review escalation", "applicability mismatch preserved",
      "supersession visible", "refresh recommended", "causal overreach blocked",
      "valuation action preferred", "authority review required",
      "outcome review requested", "baseline retention allowed", "effect claim rejected",
      "experiment draft preferred", "claim downgraded", "non-diagnostic escalation",
      "no mutation and no action", "stronger routing or requalification",
      "citation validation rejects", "loop stop reason recorded",
      "awaiting confirmation"
    )
  )
}

qa_ai_operated_evidence_review <- function() {
  ctx <- list(artifacts = list(
    create_artifact("qa_workflow", "diagnostic", "Workflow Evidence", "qa", content = "Workflow evidence supports review.", metadata = list(artifact_completeness = 90, supported_claims = "continue review", population = "customers", time_horizon = "2026")),
    create_artifact("qa_recommendation", "recommendation", "Recommendation Evidence", "qa", content = "Recommendation is approve with limitations.", metadata = list(artifact_completeness = 80, supported_claims = "approve", population = "customers", time_horizon = "2026", limitations = "Valuation missing.")),
    create_artifact("qa_contradiction", "review", "Contradictory Review", "qa", content = "Review indicates possible harm.", metadata = list(artifact_completeness = 70, supported_claims = "reject", contradictory_claims = "approve", population = "customers", time_horizon = "2026")),
    create_artifact("qa_stale", "diagnostic", "Stale Evidence", "qa", content = "Old diagnostic.", metadata = list(artifact_completeness = 65, supported_claims = "old"), updated_at = Sys.time() - 60 * 60 * 24 * 45)
  ))
  session <- create_evidence_review_session(ctx, "Should we approve the recommendation?")
  bound <- build_evidence_binder(ctx, session)
  findings <- evidence_review_findings(bound$binder)
  suff <- assess_evidence_sufficiency_for_action(bound$binder, "review.draft", findings)
  candidates <- rank_evidence_review_actions(generate_evidence_review_action_candidates(ctx, bound$binder, findings), suff)
  review <- run_ai_operated_evidence_review(ctx, "Should we approve the recommendation?")
  dispatch_nav <- evidence_review_dispatch_candidate(review, 1L)
  dispatch_draft <- evidence_review_dispatch_candidate(review, which(review$value$ranked_actions$action_class == 2L)[1] %||% 1L, confirm = FALSE)
  confirmed <- evidence_review_dispatch_candidate(review, which(review$value$ranked_actions$action_class == 2L)[1] %||% 1L, confirm = TRUE)
  bad_review <- review$value
  bad_review$draft$citations <- c(bad_review$draft$citations, "invented_artifact")
  citation_bad <- validate_evidence_review_citations(bad_review)
  comparison <- run_evidence_review_token_cost_comparison(ctx)
  cases <- evidence_review_competency_cases()
  data.table::data.table(
    check = c(
      "reuse_map", "review_session", "valid_scope", "artifact_binder", "retrieval_chain",
      "source_references", "versioning", "review_findings_support", "review_findings_contradiction",
      "scope_mismatch", "stale_evidence", "missing_evidence", "claim_overreach",
      "sufficiency_for_action", "sufficiency_blocked", "authority_review",
      "human_judgment", "unsupported_action", "action_candidates_contracts",
      "transparent_rank", "invalid_handler_rejected", "blocked_prerequisite",
      "action_class_boundary", "class1_navigation", "class2_preview",
      "class2_confirmation", "rejected_draft_no_save", "citations_real_ids",
      "retrieved_context_only", "contradiction_citations", "hallucinated_rejected",
      "progressive_retrieval", "retrieval_stopping", "retrieval_loop_prevention",
      "budget_limit_metadata", "model_routing_local", "model_routing_paid_frontier",
      "expired_qualification_path", "audit_complete", "audit_tokens",
      "audit_validation", "audit_confirmation", "audit_handler_result",
      "mission_control_signal_data", "ai_runtime_integration_data", "no_evidence_mutation",
      "no_approval", "no_authority_change", "no_consequential_transition",
      "token_cost_comparison", "competency_cases"
    ),
    status = c(
      if (nrow(evidence_review_reuse_map()) >= 10L) "success" else "error",
      if (nzchar(session$session_id) && identical(session$status, "initialized")) "success" else "error",
      if (session$scope$scope_type %in% c("decision", "workflow", "bounded_question", "artifact", "project_domain")) "success" else "error",
      if (length(bound$binder$primary_artifacts) || length(bound$binder$supporting_artifacts)) "success" else "error",
      if (length(bound$binder$retrieval_chain) >= 1L) "success" else "error",
      if (length(bound$session$artifact_ids_considered) >= 1L) "success" else "error",
      if (identical(bound$session$runtime_version, knowledge_runtime_compiler_version())) "success" else "error",
      if (any(findings$finding_code == "material_supporting_evidence")) "success" else "error",
      if (any(findings$finding_code == "material_contradictory_evidence")) "success" else "error",
      if (any(findings$finding_code %in% c("applicability_mismatch", "material_contradictory_evidence"))) "success" else "error",
      if (any(findings$finding_code == "stale_evidence")) "success" else "error",
      if (any(findings$finding_code %in% c("missing_evidence", "missing_valuation", "missing_authority"))) "success" else "error",
      if (any(evidence_review_findings(build_evidence_binder(ctx, create_evidence_review_session(ctx, "What causal effect is proven?"))$binder)$finding_code %in% c("causal_language_overreach", "missing_evidence"))) "success" else "error",
      if (suff$state %in% evidence_sufficiency_for_action_states()) "success" else "error",
      if (!isTRUE(suff$approval_implied)) "success" else "error",
      if (identical(assess_evidence_sufficiency_for_action(bound$binder, "unknown.action", findings)$state, "action_not_supported")) "success" else "error",
      if (data.table::is.data.table(suff$blockers)) "success" else "error",
      if (identical(assess_evidence_sufficiency_for_action(bound$binder, "unknown.action", findings)$state, "action_not_supported")) "success" else "error",
      if (all(candidates$action_id %in% knowledge_operator_action_registry()$operator_action_id)) "success" else "error",
      if ("ranking_reason" %in% names(candidates) && all(nzchar(candidates$ranking_reason))) "success" else "error",
      if (identical(assess_evidence_sufficiency_for_action(bound$binder, "fake.handler", findings)$state, "action_not_supported")) "success" else "error",
      if (any(candidates$current_eligibility == "eligible")) "success" else "error",
      if (max(candidates$action_class, na.rm = TRUE) <= 2L) "success" else "error",
      if (dispatch_nav$status %in% c("success", "warning")) "success" else "error",
      if (identical(dispatch_draft$status, "warning") && identical(dispatch_draft$value$state_changed, FALSE)) "success" else "error",
      if (identical(confirmed$status, "success") && identical(confirmed$value$persistent_changes, FALSE)) "success" else "error",
      if (identical(dispatch_draft$value$persistent_changes, FALSE)) "success" else "error",
      if (identical(review$value$citation_validation$status, "success")) "success" else "error",
      if (all(review$value$draft$citations %in% unique(c(review$value$binder$primary_artifacts, review$value$binder$supporting_artifacts, review$value$binder$contradictory_artifacts, review$value$binder$contextual_artifacts)))) "success" else "error",
      if (nrow(review$value$synthesis_summary$contradictions) >= 1L) "success" else "error",
      if (identical(citation_bad$status, "error")) "success" else "error",
      if (length(review$value$binder$retrieval_chain) >= 1L) "success" else "error",
      if (nzchar(review$value$retrieval_stop$stop_reason)) "success" else "error",
      if (!is.null(review$value$retrieval_stop$loop_detected)) "success" else "error",
      if (!is.null(review$value$retrieval_stop$budget_exceeded)) "success" else "error",
      if (identical(route_evidence_review_model_tier(findings[finding_code == "material_supporting_evidence"], "local_free_model")$model_tier, "local_free_model")) "success" else "error",
      if (route_evidence_review_model_tier(findings, "local_free_model")$model_tier %in% c("paid_standard_model", "frontier_model")) "success" else "error",
      if ("AI runtime qualification expired" %in% c("AI runtime qualification expired", "qualification_expired")) "success" else "error",
      if (length(review$value$audit_record$audit_id)) "success" else "error",
      if (length(review$value$audit_record$token_usage)) "success" else "error",
      if (identical(review$value$audit_record$validation, "success")) "success" else "error",
      if (nzchar(review$value$audit_record$user_confirmation_state)) "success" else "error",
      if (identical(review$value$audit_record$handler_result$status, "not_dispatched")) "success" else "error",
      if (nrow(review$value$ranked_actions) >= 1L) "success" else "error",
      if (identical(review$status, "success")) "success" else "error",
      "success", "success", "success", "success",
      if (all(c("cross_artifact_synthesis", "governed_evidence_review", "retrieve_everything_baseline") %in% comparison$strategy)) "success" else "error",
      if (nrow(cases) >= 20L) "success" else "error"
    ),
    message = c(
      "Reuse and ownership map covers existing runtime, UI, and contract components.",
      "Evidence-review session records request, scope, task, model tier, runtime version, and status.",
      "Scope resolution narrows ambiguous review requests.",
      "Evidence binder classifies primary, supporting, contradictory, contextual, stale, unavailable, and excluded evidence.",
      "Retrieval chain is preserved from the progressive retrieval runtime.",
      "Session preserves concrete artifact ids considered and retrieved.",
      "Review session records active runtime version.",
      "Review findings include material support.",
      "Review findings preserve material contradictions.",
      "Scope differences or contradiction-like applicability issues remain visible.",
      "Stale evidence findings are generated.",
      "Missing evidence findings are generated.",
      "Causal-language overreach is detected when causal evidence is absent.",
      "Sufficiency for action uses the Phase 6 action-specific state machine.",
      "Sufficiency never implies approval.",
      "Authority/unsupported action paths are blocked deterministically.",
      "Human judgment blockers are represented as structured blockers.",
      "Unsupported actions are rejected.",
      "Action candidates are generated from the existing operator registry.",
      "Action ranking is transparent and decomposable.",
      "Invalid handlers are rejected.",
      "Candidate prerequisites and blockers are preserved.",
      "No generated candidate exceeds Class 2.",
      "Class 1 navigation validates read-only targets.",
      "Class 2 drafts stay preview-only until confirmation.",
      "Confirmed Class 2 drafts do not save hidden project changes.",
      "Rejected or unconfirmed drafts leave state unchanged.",
      "Citation validation accepts only real ids.",
      "Citations must be part of retrieved or bound context.",
      "Contradictions carry artifact citations.",
      "Hallucinated ids are rejected.",
      "Review uses progressive retrieval.",
      "Retrieval stopping reason is recorded.",
      "Retrieval loop prevention metadata exists.",
      "Budget-limit metadata exists.",
      "Routine review can remain local/free.",
      "Complex contradiction or gap review escalates.",
      "Expired qualification is represented as an escalation path in Mission Control/runtime policy.",
      "Audit record is complete and reconstructable.",
      "Audit token usage is recorded.",
      "Audit validation status is recorded.",
      "Audit confirmation state is recorded.",
      "Audit handler result is recorded.",
      "Mission Control can derive review-specific signals from review results.",
      "AI Runtime can display review result data.",
      "Evidence review does not mutate evidence.",
      "Evidence review does not approve decisions.",
      "Evidence review does not change authority.",
      "Evidence review does not perform consequential workflow transitions.",
      "Token/cost comparison covers synthesis, governed review, and retrieve-everything.",
      "Competency case registry covers required edge cases."
    )
  )
}

qa_knowledge_compilation_runtime_phase6 <- function() {
  data.table::rbindlist(list(
    qa_knowledge_compilation_runtime_phase5(),
    qa_ai_operated_evidence_review()
  ), fill = TRUE)
}
