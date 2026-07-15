working_context_registry <- function() {
  data.frame(
    context_id = "evidence_review_decision_evaluation",
    label = "Evidence Review",
    purpose = "Review evidence, assess sufficiency, evaluate decision readiness, and decide the next action without leaving one workspace.",
    relationship_layer = "Current Working Context",
    production_slice = TRUE,
    template_for_future_contexts = TRUE,
    stringsAsFactors = FALSE
  )
}

working_context_progressive_depth <- function() {
  data.frame(
    depth_level = 1:5,
    label = c("Current Question", "Current Evidence", "Reasoning", "Diagnostics", "Architecture"),
    exposes = c(
      "Business question, decision context, current draft, supported next action.",
      "Relevant artifacts, cross-artifact synthesis, contradictions, sufficiency.",
      "Decision logic, valuation summary, uncertainty, alternatives, workflow status.",
      "Warnings, missing evidence, provider gaps, quality issues, implementation blockers.",
      "Policies, contracts, runtime architecture, QA, developer surfaces."
    ),
    default_visibility = c("primary", "primary", "adjacent", "contextual", "deferred"),
    stringsAsFactors = FALSE
  )
}

working_context_capability_map <- function(context_id = "evidence_review_decision_evaluation") {
  data.frame(
    capability = c(
      "Business Question",
      "Decision Context",
      "Relevant Artifacts",
      "Cross-Artifact Synthesis",
      "Contradictions",
      "Evidence Sufficiency",
      "Valuation Summary",
      "Supported Next Action",
      "Workflow Status",
      "Current Draft",
      "Mission Summary",
      "Artifact Studio",
      "Decision Valuation",
      "Decision Workflow",
      "Mission Control",
      "Knowledge Library",
      "Code Runner",
      "AI Runtime",
      "QA and Product Experience Lab",
      "Architecture Docs"
    ),
    exposure = c(
      "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary",
      "Adjacent", "Adjacent", "Adjacent", "Contextual", "Contextual", "Advanced", "Advanced", "Developer", "Architectural"
    ),
    reason = c(
      "Frames the work.",
      "Defines the decision under review.",
      "Evidence is the working material.",
      "The context exists to synthesize across artifacts.",
      "Conflicts affect trust and next action.",
      "Determines whether a decision can be made.",
      "Connects evidence to economics.",
      "Maintains momentum.",
      "Shows whether review, approval, or implementation is blocked.",
      "Keeps the decision artifact visible.",
      "Shows only relevant operational health.",
      "Deeper artifact inspection is related work.",
      "Economic analysis is the next natural adjacent task.",
      "Review and approval are adjacent tasks.",
      "Full operations are only needed when status demands it.",
      "Learning is useful but not part of the core work.",
      "Code execution is not part of evidence review.",
      "Provider/runtime controls are not the current job.",
      "Developer surfaces must not interrupt working flow.",
      "Architecture explains the system after the work is understood."
    ),
    initial_visibility = c(rep(TRUE, 11), rep(TRUE, 3), rep(FALSE, 6)),
    stringsAsFactors = FALSE
  )
}

working_context_transition_map <- function() {
  data.frame(
    from_context = "Evidence Review",
    adjacent_task = c("Inspect Artifact", "Run Valuation", "Request Decision Review", "Open Mission Control", "Open Knowledge Library"),
    target_surface = c("Artifact Studio", "Semantic Intelligence", "Semantic Intelligence", "Mission Control", "Knowledge Library"),
    transition_type = c("adjacent", "adjacent", "adjacent", "contextual", "contextual"),
    reason = c(
      "Inspect a specific evidence object in detail.",
      "Translate evidence into economic recommendation.",
      "Move from evidence sufficiency to governed review.",
      "Inspect operational signals only when attention is required.",
      "Learn the architecture or concept behind the work."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_founder_review_template <- function() {
  data.frame(
    review_dimension = c(
      "focus",
      "location_awareness",
      "information_priority",
      "next_action",
      "unnecessary_capability",
      "missing_capability",
      "transition_quality",
      "evidence_hierarchy"
    ),
    prompt = c(
      "Did I remain focused inside one coherent workspace?",
      "Did I know where I was and what job I was doing?",
      "Did the most important information appear before secondary detail?",
      "Did I know what came next?",
      "What unrelated capability appeared too early?",
      "What capability was needed but missing from the working set?",
      "Did adjacent-task transitions feel natural?",
      "Did evidence, uncertainty, and recommendation have a clear hierarchy?"
    ),
    score_scale = "1-5 plus notes",
    stringsAsFactors = FALSE
  )
}

working_context_campaigns <- function() {
  data.frame(
    campaign_id = c(
      "wc_too_many_adjacent_tasks",
      "wc_wrong_information_priority",
      "wc_excess_architecture",
      "wc_excess_navigation",
      "wc_poor_transitions",
      "wc_weak_evidence_hierarchy"
    ),
    campaign_type = "working_context_campaign",
    symptom = c(
      "The context begins to look like the full app.",
      "Secondary diagnostics appear before the decision question or evidence.",
      "Architecture language leaks into normal work.",
      "The user must repeatedly leave the context.",
      "Adjacent tasks feel like page jumps instead of natural work continuation.",
      "Artifacts, contradictions, sufficiency, and next action compete visually."
    ),
    expected_fix = c(
      "Reduce initial adjacent tasks to the minimum useful set.",
      "Reorder panels around question, evidence, reasoning, next action.",
      "Move architecture to progressive depth level 5.",
      "Bring relevant summaries into the context.",
      "Add clearer transition labels and return paths.",
      "Strengthen section hierarchy and evidence status cues."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_replay_contract <- function() {
  data.frame(
    replay_step = seq_len(7),
    action = c(
      "Open Evidence Review",
      "Read current question",
      "Review evidence sufficiency",
      "Inspect contradictions",
      "Read valuation and workflow summaries",
      "Choose supported next action",
      "Transition to one adjacent task"
    ),
    expected_observation = c(
      "User lands in one task-shaped workspace.",
      "Business question and decision context are visible immediately.",
      "Sufficiency is visible without opening Mission Control.",
      "Contradictions are surfaced as evidence concerns, not hidden diagnostics.",
      "Valuation and workflow are summarized in context.",
      "Next action is explicit and explained.",
      "Related task opens naturally without exposing the full app."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_summarize_artifacts <- function(artifacts = list()) {
  if (!length(artifacts)) {
    return(data.table::data.table(
      artifact_count = 0L,
      plot_count = 0L,
      table_count = 0L,
      diagnostic_count = 0L,
      recommendation_count = 0L,
      critical_count = 0L
    ))
  }
  types <- vapply(artifacts, function(x) x$artifact_type %||% "unknown", character(1))
  importance <- vapply(artifacts, function(x) (x$metadata %||% list())$artifact_importance %||% "unspecified", character(1))
  data.table::data.table(
    artifact_count = length(artifacts),
    plot_count = sum(types == "plot"),
    table_count = sum(types == "table"),
    diagnostic_count = sum(types %in% c("diagnostic", "diagnostics")),
    recommendation_count = sum(types %in% c("recommendation", "recommendations")),
    critical_count = sum(importance == "critical")
  )
}

working_context_build_evidence_review <- function(
  artifacts = list(),
  collector_summary = data.table::data.table(),
  semantic_decision_state = semantic_decision_empty(),
  semantic_workspace = semantic_workspace_empty(),
  valuation_state = decision_valuation_empty(),
  workflow_state = decision_workflow_empty()
) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  contexts <- semantic_decision_rows(decision_state, "contexts", context_id)
  decision_summary <- semantic_decision_summary(decision_state, semantic_workspace)
  valuation_summary <- decision_valuation_summary(valuation_state)
  workflow_summary <- decision_workflow_summary(workflow_state)
  artifact_summary <- working_context_summarize_artifacts(artifacts)
  collector_status <- if (nrow(collector_summary)) collector_summary$collector_status[[1]] %||% "not_created" else "not_created"
  artifact_count <- artifact_summary$artifact_count[[1]]
  has_decision <- nrow(contexts) > 0L
  has_valuation <- identical(valuation_summary$valuation_status[[1]] %||% "", "current")
  has_workflow <- (workflow_summary$workflows[[1]] %||% 0L) > 0L
  sufficiency_score <- min(100, (if (artifact_count > 0L) 30 else 0) + (if (has_decision) 25 else 0) + (if (has_valuation) 25 else 0) + (if (has_workflow) 20 else 0))
  sufficiency <- if (sufficiency_score >= 80) "reasonable" else if (sufficiency_score >= 45) "preliminary" else "insufficient"
  contradictions <- if (artifact_count >= 3 && !has_valuation) {
    "Evidence exists, but decision valuation has not connected it to alternatives."
  } else if (!artifact_count) {
    "No artifact evidence exists yet."
  } else {
    "No explicit contradiction has been registered in this context."
  }
  next_action <- if (!artifact_count) {
    "Generate evidence with Explore Data or Model Readiness."
  } else if (!has_decision) {
    "Create or select a decision context."
  } else if (!has_valuation) {
    "Run decision valuation."
  } else if (!has_workflow) {
    "Request decision review or prepare workflow."
  } else {
    "Review approval status and decide whether to proceed."
  }
  question <- if (has_decision && "decision_question" %in% names(contexts)) {
    contexts$decision_question[[1]] %||% "Decision question is authored but empty."
  } else {
    "What evidence-supported decision are we evaluating?"
  }
  list(
    context_id = "evidence_review_decision_evaluation",
    label = "Evidence Review",
    business_question = question,
    decision_context_id = context_id %||% NA_character_,
    decision_summary = decision_summary,
    artifact_summary = artifact_summary,
    collector_status = collector_status,
    valuation_summary = valuation_summary,
    workflow_summary = workflow_summary,
    cross_artifact_synthesis = if (artifact_count) paste("Review", artifact_count, "artifact(s) as the current evidence set.") else "No evidence artifacts are available yet.",
    contradictions = contradictions,
    evidence_sufficiency = data.table::data.table(score = sufficiency_score, status = sufficiency, rationale = "Score combines artifacts, authored decision context, valuation, and workflow state."),
    supported_next_action = next_action,
    mission_summary = data.table::data.table(
      signal = c("Artifacts", "Collector", "Decision", "Valuation", "Workflow"),
      status = c(
        if (artifact_count) "available" else "missing",
        collector_status,
        if (has_decision) "authored" else "missing",
        if (has_valuation) "current" else "not_run",
        if (has_workflow) "available" else "not_started"
      )
    ),
    current_draft = data.table::data.table(
      draft_item = c("Decision Context", "Recommendation", "Workflow"),
      status = c(if (has_decision) "draft_available" else "missing", valuation_summary$primary_recommendation[[1]] %||% "not_available", workflow_summary$workflow_status[[1]] %||% "not_started")
    ),
    capability_map = working_context_capability_map(),
    progressive_depth = working_context_progressive_depth(),
    transitions = working_context_transition_map()
  )
}

working_context_final_assessment <- function() {
  data.frame(
    question = c(
      "Can meaningful work now occur without excessive context switching?",
      "Does the Working Context reduce cognitive load?",
      "Does it preserve access to advanced capability?",
      "Does it expose only the current working set?",
      "Does it naturally lead into adjacent tasks?",
      "Does Mission Control now feel contextual?",
      "What remains the biggest UX weakness?",
      "What should the next Working Context be?"
    ),
    answer = c(
      "Partially yes: Evidence Review now composes evidence, sufficiency, valuation, workflow, and next action in one workspace.",
      "Directionally yes: primary and adjacent capabilities are separated from contextual, advanced, architectural, and developer surfaces.",
      "Yes: advanced capabilities remain reachable through adjacent/contextual transitions without occupying the initial working set.",
      "Mostly yes: the Evidence Review context initially exposes question, evidence, sufficiency, valuation, workflow, draft, mission summary, and next action.",
      "Yes: adjacent tasks are Artifact Studio, Decision Valuation, Decision Workflow, Mission Control, and Knowledge Library.",
      "More contextual: Mission Control is represented as mission summary first, full operations only when needed.",
      "The context is still a composed surface over existing modules; deeper inline execution remains limited.",
      "Decision Management should be next because it naturally follows Evidence Review and can validate whether contexts can span proposal, review, approval, implementation, and outcome."
    ),
    confidence = c("medium", "medium_high", "high", "medium_high", "high", "medium", "high", "medium"),
    stringsAsFactors = FALSE
  )
}

qa_working_contexts <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }
  registry <- working_context_registry()
  depth <- working_context_progressive_depth()
  map <- working_context_capability_map()
  transitions <- working_context_transition_map()
  review <- working_context_founder_review_template()
  campaigns <- working_context_campaigns()
  replay <- working_context_replay_contract()
  context <- working_context_build_evidence_review()
  final <- working_context_final_assessment()
  page_exists <- file.exists(file.path("R", "page_evidence_review.R"))
  docs_exists <- file.exists(file.path("docs", "working_context_architecture.md"))

  add("registry", nrow(registry) == 1L && isTRUE(registry$production_slice[[1]]), "Exactly one production Working Context is registered for Phase 5.")
  add("evidence_review_contract", identical(context$context_id, "evidence_review_decision_evaluation") && all(c("business_question", "evidence_sufficiency", "supported_next_action", "capability_map") %in% names(context)), "Evidence Review context composes question, sufficiency, next action, and capability map.")
  add("progressive_depth", identical(depth$label, c("Current Question", "Current Evidence", "Reasoning", "Diagnostics", "Architecture")), "Progressive depth runs from question through architecture.")
  add("capability_mapping", all(c("Primary", "Adjacent", "Contextual", "Advanced", "Architectural", "Developer") %in% map$exposure) && all(map$initial_visibility[map$exposure %in% c("Primary", "Adjacent")]), "Capability map separates primary/adjacent from deeper capability.")
  add("working_set_focus", !any(map$initial_visibility[map$exposure %in% c("Advanced", "Architectural", "Developer")]), "Advanced, architectural, and developer capability is hidden initially.")
  add("context_transitions", all(c("Artifact Studio", "Semantic Intelligence", "Mission Control", "Knowledge Library") %in% transitions$target_surface), "Context transitions lead to related tasks rather than the entire application.")
  add("founder_review", all(c("focus", "location_awareness", "information_priority", "next_action", "unnecessary_capability", "missing_capability") %in% review$review_dimension), "Founder review captures focus, location, priority, next action, unnecessary capability, and missing capability.")
  add("campaigns", nrow(campaigns) >= 6L && all(campaigns$campaign_type == "working_context_campaign"), "Working Context campaigns cover focus, priority, architecture, navigation, transitions, and hierarchy.")
  add("replay", nrow(replay) >= 7L && any(grepl("Open Evidence Review", replay$action)), "Replay contract starts inside Evidence Review and validates a full related-work path.")
  add("mission_contextual", any(map$capability == "Mission Summary" & map$exposure == "Primary") && any(map$capability == "Mission Control" & map$exposure == "Contextual"), "Mission Control is contextual while mission summary is primary.")
  add("final_assessment", nrow(final) == 8L && any(grepl("Decision Management", final$answer)), "Final assessment answers the required Phase 5 questions.")
  add("page_exists", page_exists, "Evidence Review production page exists.")
  add("documentation", docs_exists, "Working Context architecture documentation exists.")
  do.call(rbind, checks)
}
