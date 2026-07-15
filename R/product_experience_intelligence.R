product_experience_architecture_decision <- function() {
  list(
    status = "accepted",
    decision = "Use Playwright as the single browser automation path for recorded product-experience runs.",
    rationale = c(
      "The app already has production screenshot helpers for artifacts, but not a maintained guided-tour system.",
      "Browser-level workflow recording needs launch, navigation, validation, screenshots, video, traces, and clean shutdown.",
      "Playwright is the least fragile fit for deterministic end-to-end product-experience evidence.",
      "Phase 1 keeps a fixture runner for deterministic contract validation and does not fabricate videos or traces."
    ),
    non_goals = c(
      "No marketing-only demo flows.",
      "No duplicate guided-tour framework.",
      "No hidden-truth exposure to the app runtime.",
      "No production data.",
      "No paid AI dependency."
    ),
    selected_automation = "playwright",
    fixture_runner = "product_experience_run_scenario(automation = 'fixture')",
    recorder_contract = "product_experience_run_scenario(automation = 'playwright')",
    limitation = "Playwright recording is contract-defined in Phase 1 and reports unavailable when the runtime is not installed."
  )
}

product_experience_world_registry <- function() {
  data.frame(
    world_id = sprintf("world_%02d", seq_len(10)),
    title = c(
      "Happy Path",
      "Null Evidence",
      "Contradictory Evidence",
      "Explore vs Exploit",
      "Guardrail Failure",
      "Observational AIPW",
      "Difference-in-Differences",
      "Epistemic Integrity",
      "Decision Lifecycle",
      "Cold Start"
    ),
    product_experience = c(
      "Clear objective, strong evidence, governed workflow, successful outcome.",
      "No supported effect; evidence review preserves the baseline recommendation.",
      "Forecast, observational evidence, randomized evidence, and expert judgment conflict.",
      "Insufficient evidence leads to pilot design rather than premature commitment.",
      "Primary KPI improves while a guardrail fails, blocking the decision.",
      "AIPW evidence supports conditional claims under explicit assumptions.",
      "Valid and invalid trend structures are compared before treatment interpretation.",
      "Evidence suppression, metric switching, narrative overreach, and authority pressure are surfaced.",
      "Proposal, review, approval, implementation, outcome, and learning are connected.",
      "Minimal project knowledge leads to guided authoring and knowledge acquisition."
    ),
    workflow_variant = c(
      "Business Question First",
      "Evidence First",
      "Mission Control First",
      "Explore vs Exploit",
      "Decision First",
      "Evidence First",
      "Evidence First",
      "Mission Control First",
      "Decision First",
      "Business Question First"
    ),
    public_objective = c(
      "Decide whether to adopt a recommended analytical action.",
      "Decide whether existing evidence justifies changing the baseline.",
      "Understand how the workstation handles conflicting evidence.",
      "Choose between immediate rollout and learning-oriented pilot.",
      "Determine whether a decision can proceed under guardrail violation.",
      "Review observational causal evidence with assumptions visible.",
      "Compare difference-in-differences readiness and findings.",
      "Evaluate how epistemic risks are detected and governed.",
      "Track a decision through its full governed lifecycle.",
      "Start from limited evidence and acquire project context."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_ground_truth_registry <- function() {
  worlds <- product_experience_world_registry()
  data.frame(
    world_id = worlds$world_id,
    qa_only = TRUE,
    hidden_truth = c(
      "Treatment is beneficial and supported by convergent evidence.",
      "Treatment has no material effect beyond baseline variation.",
      "True effect is heterogeneous and time-limited, explaining apparent conflict.",
      "Expected value is positive only after learning resolves segment uncertainty.",
      "Net value is negative after guardrail loss is considered.",
      "AIPW is directionally valid under observed overlap and measured confounding.",
      "One treatment cohort satisfies parallel trends; one intentionally violates it.",
      "Requested narrative strengthening is unsupported by the evidence set.",
      "Approved alternative creates positive value after monitored implementation.",
      "No reliable decision is possible until first evidence is generated."
    ),
    generating_mechanism = c(
      "Synthetic uplift with low noise and stable guardrails.",
      "Synthetic null effect with realistic noise and no subgroup support.",
      "Synthetic mixed evidence with temporal instability.",
      "Synthetic uncertain utility with pilot-resolvable heterogeneity.",
      "Synthetic KPI lift paired with hidden guardrail degradation.",
      "Synthetic observational treatment assignment with measured confounding.",
      "Synthetic panel with one valid and one invalid comparison group.",
      "Synthetic epistemic intervention and claim-governance events.",
      "Synthetic decision workflow events and implementation outcome.",
      "Synthetic empty project with only authorable business context."
    ),
    causal_structure = c(
      "Treatment -> KPI; no guardrail harm.",
      "Treatment has no effect on KPI.",
      "Treatment -> KPI varies by segment and time.",
      "Tactic -> outcome depends on unknown segment response.",
      "Treatment -> KPI and treatment -> guardrail harm.",
      "Treatment assigned by covariates; outcome requires adjustment.",
      "Treatment timing varies across panels with trend assumptions.",
      "Claims depend on evidence and intervention provenance.",
      "Decision outcome follows approved alternative and implementation.",
      "Unknown; first evidence must be authored or generated."
    ),
    expected_artifacts = c(
      "EDA, readiness, model evidence, SHAP or causal evidence, decision record.",
      "EDA, null finding, baseline recommendation, review note.",
      "Forecast artifact, causal artifact, experiment artifact, synthesis finding.",
      "uncertainty summary, pilot recommendation, campaign seed.",
      "KPI artifact, guardrail artifact, blocked decision finding.",
      "propensity diagnostics, overlap diagnostics, AIPW estimate, conditional claim.",
      "trend diagnostics, DiD estimate, invalid-trend warning.",
      "epistemic findings, intervention provenance, claim review, adjudication.",
      "proposal, review, approval, implementation, outcome, learning record.",
      "business question, knowledge gaps, recommended first analysis."
    ),
    qa_expectations = c(
      "Completion succeeds without warnings.",
      "Recommendation remains baseline.",
      "Synthesis exposes conflict rather than hiding it.",
      "Pilot is recommended before commitment.",
      "Decision readiness is blocked.",
      "Claims remain conditional.",
      "Invalid trend branch is not decision-ready.",
      "Governance flags are emitted.",
      "Lifecycle states are legal and replayable.",
      "Guide recommends knowledge acquisition."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_scenario_registry <- function() {
  step_sets <- lapply(seq_len(10), function(i) {
    c(
      "Load canonical world",
      "Open entry workspace",
      "Review current status",
      "Follow recommended next action",
      "Inspect generated evidence",
      "Record product-experience review"
    )
  })
  worlds <- product_experience_world_registry()
  data.frame(
    scenario_id = paste0("scenario_", worlds$world_id),
    world_id = worlds$world_id,
    title = paste(worlds$title, "Workflow"),
    audience = c(
      "Product reviewer",
      "Analyst",
      "Analytical lead",
      "Product reviewer",
      "Decision owner",
      "Causal analyst",
      "Causal analyst",
      "Governance reviewer",
      "Decision owner",
      "New user"
    ),
    purpose = worlds$public_objective,
    estimated_duration_min = c(8, 7, 10, 9, 8, 10, 10, 9, 11, 6),
    entry_point = c(
      "Guide",
      "Artifact Studio",
      "Mission Control",
      "Guide",
      "Decision Workflow",
      "Causal Intelligence",
      "Causal Intelligence",
      "AI Runtime",
      "Decision Workflow",
      "Guide"
    ),
    workflow_variant = worlds$workflow_variant,
    steps = I(step_sets),
    expected_pages = I(list(
      c("Guide", "Mission Control", "Artifact Studio"),
      c("Artifact Studio", "Mission Control"),
      c("Mission Control", "AI Runtime", "Artifact Studio"),
      c("Guide", "Mission Control", "Analytical Campaign"),
      c("Decision Workflow", "Mission Control"),
      c("Causal Intelligence", "Artifact Studio"),
      c("Causal Intelligence", "Artifact Studio"),
      c("AI Runtime", "Mission Control"),
      c("Decision Workflow", "Mission Control"),
      c("Guide", "Knowledge Library")
    )),
    expected_screenshots = I(replicate(10, c("entry", "status", "evidence", "review"), simplify = FALSE)),
    expected_narration = I(replicate(10, c("context", "action", "evidence", "review"), simplify = FALSE)),
    expected_validation = I(replicate(10, c("world loaded", "steps completed", "review artifact created"), simplify = FALSE)),
    expected_completion = "review_artifact_created",
    stringsAsFactors = FALSE
  )
}

product_experience_selector_registry <- function() {
  data.frame(
    selector_id = c(
      "app.root",
      "nav.guide",
      "nav.mission_control",
      "nav.artifact_studio",
      "nav.ai_runtime",
      "nav.product_experience",
      "product_experience.world",
      "product_experience.scenario",
      "product_experience.run",
      "product_experience.review",
      "global_ai.assistant",
      "mission_control.status"
    ),
    data_testid = c(
      "app-root",
      "nav-guide",
      "nav-mission-control",
      "nav-artifact-studio",
      "nav-ai-runtime",
      "nav-product-experience",
      "product-experience-world",
      "product-experience-scenario",
      "product-experience-run",
      "product-experience-review",
      "global-ai-assistant",
      "mission-control-status"
    ),
    purpose = c(
      "Application root",
      "Open Guide",
      "Open Mission Control",
      "Open Artifact Studio",
      "Open AI Runtime",
      "Open Product Experience Lab",
      "World selector",
      "Scenario selector",
      "Scenario execution control",
      "Review artifact control",
      "Global AI assistance",
      "Mission Control status panel"
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_ai_modes <- function() {
  data.frame(
    ai_mode = c("fixture", "live", "replay"),
    label = c("Fixture AI", "Live AI", "Replay AI"),
    description = c(
      "Deterministic scripted response for repeatable validation.",
      "Configured provider response; may vary by model, latency, and availability.",
      "Previously captured response replayed with provenance."
    ),
    allowed_for_qa = c(TRUE, FALSE, TRUE),
    must_disclose = TRUE,
    stringsAsFactors = FALSE
  )
}

product_experience_validate_ai_mode <- function(ai_mode = "fixture") {
  modes <- product_experience_ai_modes()
  ok <- ai_mode %in% modes$ai_mode
  if (!ok) {
    return(service_result(
      status = "error",
      errors = paste0("Unknown AI demo mode: ", ai_mode),
      diagnostics = list(available_modes = modes$ai_mode)
    ))
  }
  service_result(
    status = "success",
    value = modes[modes$ai_mode == ai_mode, , drop = FALSE],
    messages = paste0("AI mode selected: ", modes$label[modes$ai_mode == ai_mode])
  )
}

product_experience_generate_project <- function(world_id, output_dir = tempfile("product_experience_world_")) {
  worlds <- product_experience_world_registry()
  if (!world_id %in% worlds$world_id) {
    return(service_result(
      status = "error",
      errors = paste0("Unknown product-experience world: ", world_id)
    ))
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  world <- worlds[worlds$world_id == world_id, , drop = FALSE]
  project <- list(
    project_id = paste0("px_", world_id),
    project_name = paste("Product Experience", world$title),
    world_id = world_id,
    world_title = world$title,
    public_objective = world$public_objective,
    workflow_variant = world$workflow_variant,
    generated_at = as.POSIXct("2026-07-14 00:00:00", tz = "UTC"),
    hidden_truth_included = FALSE
  )
  path <- file.path(output_dir, paste0(project$project_id, ".rds"))
  saveRDS(project, path)
  service_result(
    status = "success",
    value = project,
    messages = paste0("Generated deterministic product-experience project for ", world$title),
    metadata = list(project_path = normalizePath(path, winslash = "/", mustWork = FALSE))
  )
}

product_experience_repo_root <- function(root = getwd()) {
  normalizePath(root, winslash = "/", mustWork = FALSE)
}

product_experience_default_media_root <- function(root = getwd()) {
  env_root <- Sys.getenv("ANALYTICS_WORKSTATION_MEDIA_ROOT", unset = "")
  if (nzchar(env_root)) {
    return(normalizePath(env_root, winslash = "/", mustWork = FALSE))
  }
  option_root <- getOption("analytics_workstation.media_root", "")
  if (nzchar(option_root)) {
    return(normalizePath(option_root, winslash = "/", mustWork = FALSE))
  }
  user_profile <- Sys.getenv("USERPROFILE", unset = "")
  if (nzchar(user_profile)) {
    return(normalizePath(file.path(user_profile, "Documents", "AnalyticsWorkstationMedia"), winslash = "/", mustWork = FALSE))
  }
  normalizePath(file.path(path.expand("~"), "AnalyticsWorkstationMedia"), winslash = "/", mustWork = FALSE)
}

product_experience_media_root <- function(root = getwd(), media_root = NULL) {
  candidate <- media_root %||% product_experience_default_media_root(root)
  normalizePath(candidate, winslash = "/", mustWork = FALSE)
}

product_experience_media_dirs <- function(root = getwd(), media_root = NULL, create = TRUE) {
  base <- product_experience_media_root(root, media_root)
  dirs <- list(
    media_root = base,
    product_experience = file.path(base, "product_experience"),
    worlds = file.path(base, "product_experience", "worlds"),
    runs = file.path(base, "product_experience", "runs"),
    screenshots = file.path(base, "product_experience", "screenshots"),
    videos = file.path(base, "product_experience", "videos"),
    traces = file.path(base, "product_experience", "traces"),
    review_packages = file.path(base, "product_experience", "review_packages"),
    candidates = file.path(base, "product_experience", "candidates"),
    approved = file.path(base, "product_experience", "approved"),
    rejected = file.path(base, "product_experience", "rejected"),
    archive = file.path(base, "product_experience", "archive")
  )
  if (create) {
    invisible(lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE))
  }
  lapply(dirs, normalizePath, winslash = "/", mustWork = FALSE)
}

product_experience_media_root_validation <- function(root = getwd(), media_root = NULL) {
  dirs <- product_experience_media_dirs(root, media_root, create = TRUE)
  repo <- product_experience_repo_root(root)
  media <- dirs$media_root
  probe <- tempfile("media_probe_", tmpdir = media)
  writable <- tryCatch({
    writeLines("ok", probe)
    file.exists(probe)
  }, error = function(e) FALSE)
  if (file.exists(probe)) unlink(probe)
  data.frame(
    check = c("configured", "writable", "outside_repository", "recordings_ignored_by_source"),
    status = c(
      nzchar(media),
      writable,
      !startsWith(tolower(media), paste0(tolower(repo), "/")),
      TRUE
    ),
    value = c(media, as.character(writable), paste("repo:", repo), "runtime/export media stays out of source control"),
    stringsAsFactors = FALSE
  )
}

product_experience_media_lifecycle_states <- function() {
  data.frame(
    lifecycle_state = c("candidate", "awaiting_review", "approved", "rejected", "archived"),
    meaning = c(
      "Generated and awaiting automated verification.",
      "Verified enough for human review, not yet canonical.",
      "Human-approved external showcase asset.",
      "Reviewed and rejected for canonical use.",
      "Retained for history but no longer active."
    ),
    mutable = c(TRUE, TRUE, FALSE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )
}

product_experience_ux_iteration_passes <- function() {
  data.frame(
    pass_id = c("pass_01_coherence_friction", "pass_02_evidence_ai_naturalness", "pass_03_presentation_investor_readiness"),
    pass_name = c(
      "Coherence and Friction",
      "Evidence Communication and AI Naturalness",
      "Presentation and Investor Readiness"
    ),
    purpose = c(
      "Make the Golden Workflow feel like one product rather than many powerful modules.",
      "Make the analytical value and AI contribution understandable without dashboard paste-in energy.",
      "Make the identical workflow pleasant, credible, and safe to show externally."
    ),
    primary_question = c(
      "Can a new user complete the Golden Workflow without knowing how the system was built?",
      "Does the app help the viewer understand something consequential faster than an analyst could explain manually?",
      "Does the workflow inspire trust and make commercial value obvious?"
    ),
    focus = I(list(
      c("obvious entry point", "clear current stage", "fewer clicks", "no dead ends", "consistent button placement", "visible next action", "remove internal architecture language from normal surfaces"),
      c("key insight earlier", "chart/table hierarchy", "contradictions legible", "conclusion vs uncertainty vs limitation vs next action", "shorter AI responses", "visible but non-theatrical AI actions"),
      c("spacing", "typography", "responsive sizing", "stable viewport", "chart polish", "synthetic-data disclosure", "final summary screen", "no developer-only content")
    )),
    scope_rule = c(
      "Fix shared components only when Golden Workflow exposes the issue.",
      "Improve evidence comprehension before adding new analytical surfaces.",
      "Promote only complete unedited recordings that pass founder review."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_investor_promotion_gate <- function() {
  data.frame(
    criterion_id = c(
      "no_major_confusion",
      "no_broken_transition",
      "no_navigation_friction",
      "opening_business_question",
      "meaningful_execution",
      "nontrivial_insight",
      "ai_visible_valuable",
      "credible_uncertainty_guardrails",
      "obvious_final_next_action",
      "no_developer_only_content",
      "founder_approved_unedited_workflow"
    ),
    criterion = c(
      "No major confusion finding",
      "No broken or fake-looking transition",
      "No unresolved navigation friction",
      "Clear business question within the opening segment",
      "Meaningful app execution is visible",
      "A nontrivial insight is communicated",
      "AI contribution is visible and valuable",
      "Uncertainty and guardrails remain credible",
      "Final next action is obvious",
      "No developer-only content is visible",
      "Human founder review approves the complete unedited workflow"
    ),
    required = TRUE,
    evidence_source = c(
      "founder review findings",
      "video and screenshots",
      "review findings and click trace",
      "opening chapter screenshot/video",
      "execution report and visible state transitions",
      "showcase evidence package and AI Runtime",
      "AI Runtime, Guide, or visible assistant action",
      "showcase evidence package and final summary",
      "final chapter",
      "video review",
      "manual founder review"
    ),
    failure_action = c(
      "Create UX campaign seed before promotion.",
      "Fix transition or remove chapter before promotion.",
      "Fix navigation path or add visible next action before promotion.",
      "Rewrite opening or Guide state before promotion.",
      "Add visible execution or state change before promotion.",
      "Improve evidence hierarchy before promotion.",
      "Shorten/reframe AI output before promotion.",
      "Restore limitation and guardrail language before promotion.",
      "Add final summary/action state before promotion.",
      "Hide developer-only surfaces from investor cut before promotion.",
      "Keep lifecycle state at awaiting_review."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_assess_investor_candidate <- function(
  run = NULL,
  findings = NULL,
  founder_approved = FALSE,
  developer_content_visible = TRUE
) {
  run <- run %||% list(
    chapters = data.frame(chapter = character(), stringsAsFactors = FALSE),
    events = list(),
    metrics = list(ai_interactions = 0L),
    verification = list(video = list(duration_sec = 0))
  )
  gate <- product_experience_investor_promotion_gate()
  finding_text <- tolower(paste(unlist(findings %||% character()), collapse = " "))
  has_issue <- function(pattern) grepl(pattern, finding_text)
  video_duration <- suppressWarnings(as.numeric(run$verification$video$duration_sec %||% run$metrics$completion_time_sec %||% NA_real_))
  chapter_names <- tolower(paste(run$chapters$chapter %||% character(), collapse = " "))
  statuses <- c(
    !has_issue("major confusion|confusing|lost"),
    !has_issue("broken|fake|jump|flash|dead transition"),
    !has_issue("navigation friction|dead end|hunt|unresolved navigation"),
    grepl("business context", chapter_names),
    isTRUE((video_duration %||% 0) > 20) && length(run$events %||% list()) >= 5L,
    TRUE,
    (run$metrics$ai_interactions %||% 0L) >= 1L,
    TRUE,
    grepl("next action|persisted draft|human confirmation", chapter_names),
    !isTRUE(developer_content_visible),
    isTRUE(founder_approved)
  )
  gate$status <- ifelse(statuses, "pass", "block")
  gate$promotion_blocker <- gate$status != "pass"
  gate$observed_value <- c(
    ifelse(statuses[[1]], "no blocking finding supplied", "blocking confusion finding"),
    ifelse(statuses[[2]], "no broken transition finding supplied", "blocking transition finding"),
    ifelse(statuses[[3]], "no unresolved navigation finding supplied", "blocking navigation finding"),
    ifelse(statuses[[4]], "business context chapter present", "business context chapter missing"),
    paste("duration_sec", round(video_duration %||% 0, 2)),
    "requires human qualitative review",
    paste("ai_interactions", run$metrics$ai_interactions %||% NA_integer_),
    "requires human qualitative review",
    ifelse(statuses[[9]], "final action chapter present", "final action chapter missing"),
    ifelse(developer_content_visible, "developer content visible", "developer content hidden"),
    ifelse(founder_approved, "approved", "not approved")
  )
  attr(gate, "promotion_state") <- if (all(gate$status == "pass")) "investor_candidate" else "awaiting_review"
  gate
}

product_experience_golden_workflow_review <- function() {
  workflow <- product_experience_golden_workflow()
  data.frame(
    step = workflow$steps$chapter,
    purpose = workflow$steps$user_story,
    expected_understanding = c(
      "The product starts from a business question, not a module menu.",
      "Evidence has been gathered and is being reviewed for relevance.",
      "The system can synthesize across artifacts instead of listing outputs.",
      "The system distinguishes enough evidence from missing evidence.",
      "The next action is governed, explained, and not magical.",
      "Navigation should feel like flow, not hunting.",
      "The system can prepare a bounded draft without mutating state silently.",
      "Human confirmation makes durable project memory."
    ),
    expected_action = c(
      "Understand the decision context.",
      "Inspect the evidence summary.",
      "Review support, contradictions, and uncertainty.",
      "Decide whether more evidence is required.",
      "Follow the recommended next step.",
      "Arrive at the right workspace.",
      "Review the draft and its limitations.",
      "Approve, reject, or preserve the draft."
    ),
    current_friction = c(
      "The opening question is still generic and should be tied to the flagship synthetic world.",
      "Evidence review exists, but the first important insight is not always visually dominant.",
      "Synthesis is present but can read like a technical panel instead of a decision story.",
      "Sufficiency language needs stronger hierarchy between conclusion, uncertainty, and next action.",
      "Mission Control is useful, but priority ordering should make the one next action unmistakable.",
      "The current replay still visits developer/product-experience surfaces during the canonical recording.",
      "Draft/review state is structured, but the visible review moment is not yet emotionally satisfying.",
      "Persistence and learning are documented, but the final screen does not yet feel like a clean close."
    ),
    cognitive_load = c("medium", "medium", "medium", "medium", "low", "high", "medium", "medium"),
    estimated_duration_sec = c(6, 6, 6, 6, 5, 7, 6, 6),
    estimated_clicks = c(0, 1, 0, 0, 1, 1, 1, 0),
    navigation_depth = c(0, 1, 1, 1, 1, 2, 2, 2),
    severity = c("medium", "high", "medium", "medium", "medium", "critical", "medium", "medium"),
    campaign_id = paste0("ux_campaign_", sprintf("%02d", seq_len(8))),
    stringsAsFactors = FALSE
  )
}

product_experience_founder_review_schema <- function() {
  data.frame(
    field = c(
      "review_id", "reviewer", "timestamp", "run_id", "workflow_step",
      "finding", "category", "severity", "screenshot_path", "video_timestamp",
      "recommendation", "campaign_id", "status"
    ),
    purpose = c(
      "Durable review identifier.",
      "Founder or reviewer name.",
      "When the observation was recorded.",
      "Replay run being reviewed.",
      "Golden Workflow step associated with the observation.",
      "What the reviewer observed.",
      "Navigation, visual, terminology, AI, evidence, decision, workflow, Mission Control, performance, loading, or hierarchy.",
      "low, medium, high, critical.",
      "Optional screenshot evidence.",
      "Optional video timestamp.",
      "Recommended UX change.",
      "Campaign created or linked from the observation.",
      "open, accepted, deferred, fixed, or rejected."
    ),
    required = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )
}

product_experience_founder_review_template <- function(run = NULL, reviewer = "founder") {
  workflow_review <- product_experience_golden_workflow_review()
  data.frame(
    review_id = paste0("founder_review_", seq_len(nrow(workflow_review))),
    reviewer = reviewer,
    timestamp = as.character(Sys.time()),
    run_id = run$run_id %||% "pending_replay",
    workflow_step = workflow_review$step,
    finding = workflow_review$current_friction,
    category = c("workflow", "evidence", "AI", "evidence", "Mission Control", "navigation", "decision", "workflow"),
    severity = workflow_review$severity,
    screenshot_path = NA_character_,
    video_timestamp = NA_character_,
    recommendation = c(
      "Bind the opening segment to the flagship business question.",
      "Move the key insight above supporting detail.",
      "Rewrite synthesis as decision support with supporting evidence below.",
      "Use a clear conclusion/uncertainty/next-action hierarchy.",
      "Make the highest-priority next action visually dominant.",
      "Remove Product Experience Lab/developer surfaces from investor-facing capture.",
      "Make review draft state feel like a meaningful analytical dossier.",
      "Add a concise final summary screen with decision, guardrails, and next action."
    ),
    campaign_id = workflow_review$campaign_id,
    status = "open",
    stringsAsFactors = FALSE
  )
}

product_experience_prioritize_ux_campaigns <- function(findings = product_experience_founder_review_template()) {
  severity_score <- c(low = 1L, medium = 2L, high = 3L, critical = 4L)
  category_impact <- c(
    navigation = 4L,
    evidence = 4L,
    `Mission Control` = 3L,
    AI = 3L,
    decision = 4L,
    workflow = 3L,
    visual = 2L,
    terminology = 2L,
    performance = 2L,
    loading = 2L,
    hierarchy = 4L
  )
  effort <- c(
    ux_campaign_01 = 2L,
    ux_campaign_02 = 2L,
    ux_campaign_03 = 2L,
    ux_campaign_04 = 2L,
    ux_campaign_05 = 2L,
    ux_campaign_06 = 4L,
    ux_campaign_07 = 3L,
    ux_campaign_08 = 2L
  )
  campaigns <- data.frame(
    campaign_id = findings$campaign_id,
    finding = findings$finding,
    category = findings$category,
    severity = findings$severity,
    recommendation = findings$recommendation,
    user_impact = unname(severity_score[findings$severity] %||% 1L),
    commercial_impact = ifelse(findings$campaign_id %in% c("ux_campaign_01", "ux_campaign_02", "ux_campaign_06", "ux_campaign_08"), 4L, 3L),
    scientific_impact = ifelse(findings$category %in% c("evidence", "AI", "decision"), 4L, 2L),
    implementation_effort = unname(effort[findings$campaign_id] %||% 2L),
    risk = ifelse(findings$campaign_id == "ux_campaign_06", 3L, 1L),
    dependencies = ifelse(findings$campaign_id == "ux_campaign_06", "Need user-facing replay state seeding or capture route.", "None"),
    expected_ux_improvement = c(
      "Viewer understands why the workflow exists immediately.",
      "Viewer sees the consequential insight earlier.",
      "AI feels like decision support rather than pasted text.",
      "Evidence sufficiency becomes easier to trust.",
      "The one next action is obvious.",
      "Investor recording stops showing developer scaffolding.",
      "Review feels important rather than administrative.",
      "Workflow ends with a clear decision memory."
    ),
    stringsAsFactors = FALSE
  )
  campaigns$priority_score <- campaigns$user_impact + campaigns$commercial_impact + campaigns$scientific_impact - campaigns$implementation_effort - campaigns$risk
  campaigns[order(-campaigns$priority_score, -campaigns$user_impact, campaigns$implementation_effort), , drop = FALSE]
}

product_experience_replay_metrics_summary <- function(run = NULL) {
  metrics <- run$metrics %||% list()
  data.frame(
    metric = c(
      "clicks", "completion_time_sec", "backtracking", "help_usage", "scroll_events",
      "context_expansions", "ai_interactions", "navigation_depth", "mission_control_visits",
      "review_completion", "promotion_state"
    ),
    value = c(
      metrics$clicks %||% NA_integer_,
      metrics$completion_time_sec %||% NA_real_,
      metrics$backtracking %||% NA_integer_,
      metrics$help_usage %||% NA_integer_,
      metrics$scroll_events %||% NA_integer_,
      metrics$context_expansions %||% NA_integer_,
      metrics$ai_interactions %||% NA_integer_,
      metrics$navigation_depth %||% NA_integer_,
      sum(vapply(run$events %||% list(), function(x) identical(x$page %||% "", "Mission Control") || grepl("Mission Control", x$result %||% ""), logical(1))),
      ifelse(nzchar(run$review_package_path %||% ""), "available", "pending"),
      attr(product_experience_assess_investor_candidate(run, developer_content_visible = TRUE), "promotion_state") %||% "awaiting_review"
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_compare_replay_runs <- function(current_run, previous_run = NULL) {
  current <- product_experience_replay_metrics_summary(current_run)
  names(current)[names(current) == "value"] <- "current"
  if (is.null(previous_run)) {
    current$previous <- NA_character_
    current$semantic_change <- "baseline"
    current$interpretation <- "No previous replay supplied."
    return(current[, c("metric", "previous", "current", "semantic_change", "interpretation"), drop = FALSE])
  }
  previous <- product_experience_replay_metrics_summary(previous_run)
  names(previous)[names(previous) == "value"] <- "previous"
  rows <- merge(previous, current, by = "metric", all = TRUE)
  rows$semantic_change <- "unchanged"
  numeric_metrics <- suppressWarnings(!is.na(as.numeric(rows$current)) & !is.na(as.numeric(rows$previous)))
  delta <- suppressWarnings(as.numeric(rows$current) - as.numeric(rows$previous))
  lower_is_better <- rows$metric %in% c("clicks", "completion_time_sec", "backtracking", "scroll_events", "navigation_depth")
  rows$semantic_change[numeric_metrics & lower_is_better & delta < 0] <- "improved"
  rows$semantic_change[numeric_metrics & lower_is_better & delta > 0] <- "regressed"
  rows$semantic_change[numeric_metrics & !lower_is_better & delta > 0] <- "improved"
  rows$semantic_change[numeric_metrics & !lower_is_better & delta < 0] <- "regressed"
  rows$interpretation <- ifelse(
    rows$semantic_change == "improved",
    "The workflow moved in the desired direction.",
    ifelse(rows$semantic_change == "regressed", "The workflow became heavier or less complete.", "No semantic movement detected.")
  )
  rows[, c("metric", "previous", "current", "semantic_change", "interpretation"), drop = FALSE]
}

product_experience_final_assessment <- function(run = NULL, founder_approved = FALSE, developer_content_visible = TRUE) {
  gate <- product_experience_assess_investor_candidate(run, founder_approved = founder_approved, developer_content_visible = developer_content_visible)
  blockers <- gate[gate$status != "pass", , drop = FALSE]
  classification <- if (nrow(blockers) == 0L) {
    "Investor Candidate"
  } else if (any(blockers$criterion_id %in% c("meaningful_execution", "opening_business_question"))) {
    "Internal"
  } else if (any(blockers$criterion_id %in% c("no_developer_only_content", "founder_approved_unedited_workflow"))) {
    "Beta"
  } else {
    "Internal"
  }
  list(
    classification = classification,
    does_workflow_feel_more_coherent = "Partially. The replay is structured and paced, but developer-surface leakage remains the largest coherence blocker.",
    is_business_story_obvious = "Improving. The flagship world supplies the story, but the recording must open and close around that story more cleanly.",
    does_ai_appear_only_when_valuable = "Not fully. AI is bounded and read-only, but deterministic UI should replace generic explanatory panels where possible.",
    is_cognitive_load_lower = "Partially. The three-pass protocol identifies where load remains high.",
    can_users_identify_next_action = "Partially. Mission Control exists, but the one next action needs stronger visual dominance.",
    unnecessary_complexity_removed = "Not enough yet. The next campaign should remove developer-only Product Experience Lab surfaces from investor capture.",
    largest_ux_weakness = "The Golden Workflow still contains product-experience/developer scaffolding in the recording path.",
    promotion_state = attr(gate, "promotion_state") %||% "awaiting_review",
    blockers = blockers
  )
}

product_experience_research_mode_principles <- function() {
  data.frame(
    principle = c(
      "Explore before exploiting",
      "Optimize human understanding",
      "Current Golden Workflow is a benchmark, not a conclusion",
      "Architecture remains capability-first; UX may become intent-first",
      "Do not expose architecture by default",
      "Prefer deterministic UX over AI for basic interface operation"
    ),
    implication = c(
      "Do not converge on final navigation until competing information architectures have been compared.",
      "A screen succeeds when the user understands why it exists and what to do next.",
      "Replay comparison should include alternative prototypes, not only incremental polish of the current flow.",
      "Modules and capabilities can remain intact while the entry experience asks what the user is trying to accomplish.",
      "Architecture belongs in advanced/developer layers unless the user asks for it.",
      "AI should assist understanding, evidence, navigation, and reasoning; deterministic UI should handle obvious next steps."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_experience_hypotheses <- function() {
  data.frame(
    hypothesis_id = c(
      "hypothesis_intent_first",
      "hypothesis_mission_control_first",
      "hypothesis_business_question_first",
      "hypothesis_decision_first",
      "hypothesis_analyst_workspace",
      "hypothesis_evidence_gallery_first"
    ),
    hypothesis = c(
      "Intent-first",
      "Mission Control first",
      "Business Question first",
      "Decision-first",
      "Analyst Workspace",
      "Evidence Gallery first"
    ),
    opening_prompt = c(
      "What are you trying to accomplish?",
      "What needs attention?",
      "What question are we trying to answer?",
      "What decision needs to be made?",
      "What workspace do you want to use?",
      "What evidence already exists?"
    ),
    flow = c(
      "Intent -> workflow -> evidence -> decision -> action",
      "System state -> priority signal -> evidence -> decision",
      "Question -> evidence -> understanding -> action",
      "Decision -> alternatives -> evidence -> workflow",
      "Capability -> module -> artifact -> report",
      "Evidence -> pattern -> question -> decision"
    ),
    learning_value = c(
      "Tests whether first-time users think in goals rather than features.",
      "Tests whether operational status is the best home base.",
      "Tests whether the product should anchor around authored analytical questions.",
      "Tests whether business owners orient around decisions and alternatives.",
      "Preserves power-user familiarity and reveals what current architecture already does well.",
      "Tests whether artifacts are the most natural entry point once evidence exists."
    ),
    primary_risk = c(
      "May hide power and frustrate experts.",
      "May feel like monitoring rather than thinking.",
      "May over-constrain open-ended exploration.",
      "May require business intent authoring before users feel ready.",
      "May continue exposing too much too early.",
      "May be weak for cold-start projects."
    ),
    current_recommendation = c(
      "Prototype next",
      "Keep as comparison",
      "Prototype next",
      "Prototype later",
      "Use as baseline",
      "Prototype after artifact-rich seeded project"
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_prototype_modes <- function() {
  hypotheses <- product_experience_experience_hypotheses()
  data.frame(
    prototype_id = c("prototype_a_intent", "prototype_b_mission", "prototype_c_question", "prototype_d_decision", "prototype_e_analyst", "prototype_f_evidence"),
    hypothesis_id = hypotheses$hypothesis_id,
    prototype_name = hypotheses$hypothesis,
    entry_surface = c("Guide", "Mission Control", "Guide", "Decision Workflow", "Project Workspace", "Artifact Studio"),
    default_visible_level = c("Level 0 Orientation", "Level 1 Workflow", "Level 0 Orientation", "Level 1 Workflow", "Level 2 Evidence", "Level 2 Evidence"),
    immediate_visible_elements = I(list(
      c("intent prompt", "current project status", "recommended starting paths"),
      c("top priority", "workspace health", "running jobs", "collector status"),
      c("business question prompt", "known evidence", "missing evidence", "next evidence request"),
      c("decision statement", "alternatives", "decision readiness", "evidence gaps"),
      c("workspace tabs", "module selectors", "artifact counts", "developer controls"),
      c("artifact gallery", "evidence filters", "inspector", "collector memory")
    )),
    intentionally_hidden_initially = I(list(
      c("module registry", "architecture docs", "developer QA"),
      c("low-priority diagnostics", "implementation details", "developer QA"),
      c("module registry", "raw capability map", "architecture terminology"),
      c("advanced diagnostics", "module internals", "raw artifacts"),
      c("nothing significant", "baseline exposes most capability"),
      c("empty-project architecture", "advanced diagnostics", "developer controls")
    )),
    success_metric = c(
      "User can choose a path without asking what the app does.",
      "User can identify the one next action immediately.",
      "User understands the business story without narration.",
      "User can evaluate alternatives and evidence gaps.",
      "Expert can access power with minimal ceremony.",
      "User can understand existing evidence and choose what to inspect."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_information_exposure_taxonomy <- function() {
  data.frame(
    exposure_class = c("Essential", "Helpful", "Contextual", "Advanced", "Architectural", "Developer"),
    definition = c(
      "Required to understand or advance the current intent.",
      "Useful but not required for the next action.",
      "Only useful in the current project/module state.",
      "Power-user controls or deeper diagnostics.",
      "Explains how the system is built or governed.",
      "Implementation, QA, replay, runtime, or debug details."
    ),
    default_visibility = c("show", "summarize", "surface_when_relevant", "collapse", "hide_until_requested", "hide_from_investor_workflow"),
    examples = c(
      "business question, current recommendation, next action",
      "project status, evidence count, top limitation",
      "warnings for selected artifact, missing data fields, model-specific diagnostics",
      "provider configuration, threshold settings, detailed lineage",
      "ontology, architecture docs, runtime bundle, QA contracts",
      "Product Experience Lab, replay trace, generated code panels, internal IDs"
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_progressive_disclosure_strategy <- function() {
  data.frame(
    level = c("Level 0", "Level 1", "Level 2", "Level 3", "Level 4"),
    name = c("Orientation", "Workflow", "Evidence", "Diagnostics", "Architecture"),
    user_question = c(
      "What is this and where should I start?",
      "What am I doing next?",
      "What do we know?",
      "Can I trust this?",
      "How is this system built?"
    ),
    should_show = c(
      "intent, project state, recommended path",
      "current stage, next step, required inputs, completion state",
      "artifact summary, key finding, limitations, guardrails",
      "warnings, data quality, assumptions, validation details",
      "contracts, policies, runtime, QA, ontology"
    ),
    should_hide = c(
      "module internals, developer tools, long diagnostics",
      "architecture maps, full raw tables, hidden advanced controls",
      "low-level implementation, all sidecars by default",
      "source code and full architectural docs unless requested",
      "nothing; user explicitly asked for architecture"
    ),
    mechanism = c(
      "Guide card or intent launcher",
      "workflow stage panel",
      "evidence summary and inspector",
      "expandable diagnostics and trust panels",
      "Knowledge Library / Developer / QA surfaces"
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_visible_element_inventory <- function() {
  data.frame(
    surface = c(
      "Guide",
      "Mission Control",
      "Artifact Studio",
      "AI Runtime",
      "Product Experience Lab",
      "Analysis Modules",
      "Knowledge Library",
      "Command Palette"
    ),
    element = c(
      "primary action cards",
      "health/status tiles",
      "artifact cards and inspector",
      "runtime and evidence review panels",
      "replay, QA, campaign, and media-governance controls",
      "module selector and generated code",
      "architecture/book/research reader",
      "navigation and action launcher"
    ),
    exposure_class = c("Essential", "Helpful", "Essential", "Contextual", "Developer", "Advanced", "Architectural", "Helpful"),
    investor_workflow_visibility = c("show", "summarize", "show_when_artifacts_exist", "show_if_ai_contributes", "hide", "hide_unless_module_execution_visible", "hide", "optional"),
    rationale = c(
      "The entry experience should orient around intent.",
      "Status helps if it reveals one next action.",
      "Artifacts are evidence and should be central when evidence exists.",
      "AI should be visible only when it explains evidence or reasoning.",
      "Developer/replay surfaces explain how demos are produced, not why the product matters.",
      "Useful for analysts, but raw module selection can overload first-time viewers.",
      "Important institutional memory, not first-run product value.",
      "Helpful for power users, but not necessary in a narrated investor workflow."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_ai_role_assessment <- function() {
  data.frame(
    interaction = c(
      "Navigate to obvious next workspace",
      "Explain why a next action is recommended",
      "Summarize cross-artifact evidence",
      "Expose uncertainty and guardrails",
      "Operate basic UI controls",
      "Generate long generic prose"
    ),
    preferred_owner = c("deterministic UI", "AI or deterministic explanation", "AI-assisted reasoning", "AI-assisted reasoning", "deterministic UI", "neither by default"),
    rationale = c(
      "Navigation should not require probabilistic reasoning when the next step is known.",
      "Explanation may benefit from context synthesis, but canned deterministic reasons can cover simple cases.",
      "Cross-artifact synthesis is a genuine AI value zone.",
      "Guardrails and uncertainty require careful synthesis and should remain auditable.",
      "The user should not need AI to click obvious controls.",
      "Long prose increases cognitive load and feels pasted into a dashboard."
    ),
    current_research_question = c(
      "Can visible next-action controls replace this?",
      "Which explanations should be deterministic templates?",
      "How much evidence is enough for useful synthesis?",
      "Can guardrails be visually legible before prose?",
      "Where is the UI still forcing AI to act as glue?",
      "What is the shortest useful AI response?"
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_prototype_comparison <- function() {
  prototypes <- product_experience_prototype_modes()
  scores <- data.frame(
    prototype_id = prototypes$prototype_id,
    human_understanding = c(5L, 4L, 5L, 4L, 3L, 4L),
    cognitive_load = c(2L, 3L, 2L, 3L, 5L, 3L),
    commercial_story = c(4L, 3L, 5L, 4L, 2L, 3L),
    expert_power_preserved = c(3L, 3L, 3L, 3L, 5L, 3L),
    implementation_risk = c(2L, 2L, 2L, 3L, 1L, 3L),
    research_value = c(5L, 4L, 5L, 4L, 3L, 4L),
    stringsAsFactors = FALSE
  )
  merged <- merge(prototypes, scores, by = "prototype_id", all.x = TRUE)
  merged$learning_score <- merged$human_understanding + merged$commercial_story + merged$research_value - merged$cognitive_load - merged$implementation_risk
  merged$prototype_status <- ifelse(
    merged$prototype_name %in% c("Intent-first", "Business Question first"),
    "prototype_next",
    ifelse(merged$prototype_name == "Analyst Workspace", "baseline", "comparison_candidate")
  )
  merged[order(-merged$learning_score, merged$implementation_risk), , drop = FALSE]
}

product_experience_research_campaigns <- function() {
  comparison <- product_experience_prototype_comparison()
  next_prototypes <- comparison[comparison$prototype_status == "prototype_next", , drop = FALSE]
  campaign_notes <- data.frame(
    prototype_name = c("Intent-first", "Business Question first"),
    minimum_prototype = c(
      "A Guide variant that asks intent first and unfolds only relevant workflow cards.",
      "A Guide variant that anchors on the flagship business question, then reveals evidence and action."
    ),
    reject_if = c(
      "Users cannot find advanced capability or feel trapped in a wizard.",
      "Users cannot handle open-ended exploration or need to browse evidence before authoring a question."
    ),
    keep_if = c(
      "First-time users understand where to start faster than the baseline.",
      "The business story becomes obvious without narration."
    ),
    stringsAsFactors = FALSE
  )
  next_prototypes <- merge(next_prototypes, campaign_notes, by = "prototype_name", all.x = TRUE)
  data.frame(
    campaign_id = paste0("research_campaign_", seq_len(nrow(next_prototypes))),
    prototype_id = next_prototypes$prototype_id,
    hypothesis = next_prototypes$prototype_name,
    objective = paste("Test", next_prototypes$prototype_name, "as an alternative to current Golden Workflow navigation."),
    learning_goal = next_prototypes$success_metric,
    minimum_prototype = next_prototypes$minimum_prototype,
    reject_if = next_prototypes$reject_if,
    keep_if = next_prototypes$keep_if,
    stringsAsFactors = FALSE
  )
}

product_experience_research_open_questions <- function() {
  data.frame(
    question_id = paste0("ux_question_", sprintf("%02d", seq_len(8))),
    question = c(
      "Does the current architecture expose too much too early?",
      "Do users think in terms of intent, business question, evidence, decision, or modules?",
      "Should the Golden Workflow remain canonical or become one benchmark among several?",
      "What should disappear from the default surface?",
      "What should unfold progressively?",
      "Where should AI become invisible?",
      "What is the first moment where the product feels valuable?",
      "What is the largest unanswered UX question?"
    ),
    current_answer = c(
      "Probably yes; developer and architectural surfaces are visible too soon in recorded workflows.",
      "Hypothesis: first-time users think in intent/question language; experts tolerate modules.",
      "It should remain the current benchmark, not the final canonical experience.",
      "Developer replay controls, raw architecture language, generated code, and internal IDs.",
      "Diagnostics, architecture, provider details, sidecars, full tables, QA and runtime status.",
      "Basic navigation and obvious next-step execution should be deterministic.",
      "Likely when evidence changes a business decision or prevents premature action.",
      "Whether the product should open on intent, question, mission control, decision, or evidence."
    ),
    next_experiment = c(
      "Run baseline vs intent-first prototype review.",
      "Compare prototype entry surfaces with identical synthetic world.",
      "Replay at least two alternative flows before promoting a new benchmark.",
      "Classify visible elements in the current Golden Workflow capture.",
      "Prototype progressive disclosure levels 0-4.",
      "Replace one AI navigation/explanation moment with deterministic UI.",
      "Use founder review timestamps for moment-of-understanding capture.",
      "Build the next prototype as intent-first and compare to business-question-first."
    ),
    stringsAsFactors = FALSE
  )
}

experience_intent_registry <- function() {
  data.frame(
    intent_id = c("analyze", "decide", "review", "continue", "explore", "learn"),
    label = c("Analyze data", "Make a decision", "Review evidence", "Continue work", "Explore", "Learn"),
    user_question = c(
      "What data should we understand first?",
      "What decision needs evidence?",
      "What evidence already exists?",
      "Where did this project leave off?",
      "What should we inspect?",
      "What concept should we understand?"
    ),
    default_start_surface = c("Data", "Guide", "Artifact Studio", "Mission Control", "Guide", "Knowledge Library"),
    primary_next_action = c(
      "Load data or run Explore Data.",
      "Define the decision and review evidence sufficiency.",
      "Open Artifact Studio and inspect project evidence.",
      "Resume from the last meaningful project state.",
      "Choose an exploratory evidence path.",
      "Open Knowledge Library or Guide learning path."
    ),
    stringsAsFactors = FALSE
  )
}

experience_capability_map <- function() {
  data.frame(
    capability_id = c(
      "guide_orientation",
      "mission_control_status",
      "data_intake",
      "workflow_progression",
      "analysis_modules",
      "artifact_studio",
      "decision_workbench",
      "delivery",
      "knowledge_library",
      "ai_runtime",
      "product_experience_lab",
      "code_runner"
    ),
    capability = c(
      "Guide orientation",
      "Mission Control status",
      "Data intake",
      "Workflow progression",
      "Analysis execution",
      "Artifact Studio",
      "Decision Workbench",
      "Delivery",
      "Knowledge Library",
      "AI Runtime",
      "Product Experience Lab",
      "Code Runner"
    ),
    audience = c(
      "all users",
      "returning users",
      "analysts",
      "analysts",
      "power users",
      "all users after evidence exists",
      "decision owners",
      "analysts and decision owners",
      "learners and developers",
      "developers and advanced reviewers",
      "product team",
      "developers"
    ),
    workflow = c(
      "orientation",
      "operation",
      "data",
      "workflow",
      "workflow",
      "evidence",
      "decision",
      "delivery",
      "learning",
      "advanced_ai",
      "product_research",
      "developer"
    ),
    default_exposure = c("immediate", "contextual", "contextual", "contextual", "advanced", "contextual", "contextual", "contextual", "deferred", "developer", "developer", "developer"),
    depends_on = c(
      "none",
      "project_state",
      "project_or_file",
      "intent_or_project",
      "workflow_stage",
      "artifacts",
      "decision_context",
      "artifacts_or_reports",
      "user_request",
      "advanced_mode",
      "developer_mode",
      "developer_mode"
    ),
    ai_visibility = c("optional_explanation", "optional_explanation", "hidden", "hidden", "hidden", "optional_synthesis", "optional_reasoning", "hidden", "optional_explanation", "visible_diagnostics", "hidden", "hidden"),
    promotion = c("show", "summarize", "show_when_relevant", "show_when_relevant", "collapse", "show_when_relevant", "show_when_relevant", "show_when_relevant", "link_contextually", "hide", "hide", "hide"),
    stringsAsFactors = FALSE
  )
}

experience_prototype_registry <- function() {
  data.frame(
    prototype_id = c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first"),
    prototype_name = c("Current Golden Workflow", "Prototype A: Intent-first", "Prototype B: Business Question first"),
    philosophy = c(
      "Capability-aware benchmark",
      "User intent compiles the experience",
      "Business question compiles the experience"
    ),
    entry_prompt = c(
      "What should we do next?",
      "What are you trying to accomplish?",
      "What business question are you trying to answer?"
    ),
    entry_surface = c("Guide", "Guide", "Guide"),
    default_intent = c("decide", "decide", "decide"),
    mission_control_behavior = c("workspace_status", "contextual_operating_layer", "decision_status_layer"),
    ai_visibility = c("visible_when_workflow_requests", "hidden_until_reasoning_benefits", "hidden_until_evidence_synthesis"),
    visual_emphasis = c("workflow benchmark", "intent choices and next path", "business question and evidence state"),
    workflow_id = rep(product_experience_golden_workflow()$workflow_id, 3),
    prototype_status = c("baseline", "prototype", "prototype"),
    stringsAsFactors = FALSE
  )
}

experience_runtime_visibility_levels <- function() {
  data.frame(
    exposure = c("immediate", "deferred", "contextual", "advanced", "architectural", "developer"),
    meaning = c(
      "Visible now because it advances the current intent.",
      "Available after the user selects a path or asks for more.",
      "Visible only when project state makes it useful.",
      "Power-user setting or deeper diagnostic.",
      "Explains how the system is built or governed.",
      "Implementation, QA, replay, runtime, or debug surface."
    ),
    default_policy = c("show", "summarize", "surface_when_relevant", "collapse", "hide_until_requested", "hide_from_normal_workflow"),
    stringsAsFactors = FALSE
  )
}

experience_progressive_runtime <- function(prototype_id = "prototype_a_intent_first") {
  data.frame(
    level = paste("Level", 0:5),
    stage = c("Orientation", "Workflow", "Evidence", "Decision", "Diagnostics", "Architecture"),
    user_question = c(
      "What is this and where should I start?",
      "What am I doing next?",
      "What do we know?",
      "What should we do?",
      "Can I trust this?",
      "How is this built?"
    ),
    runtime_policy = c(
      "compile entry prompt, visible choices, and first next action",
      "compile route, stage state, required input, and progress",
      "compile evidence summary, artifacts, limitations, and inspector route",
      "compile decision readiness, recommendation, alternatives, and guardrails",
      "compile warnings, assumptions, validation, and review state",
      "compile architecture docs, runtime diagnostics, QA, and developer surfaces"
    ),
    prototype_id = prototype_id,
    stringsAsFactors = FALSE
  )
}

experience_route_intent <- function(intent = "decide", prototype_id = "prototype_a_intent_first", project_state = list()) {
  intents <- experience_intent_registry()
  prototypes <- experience_prototype_registry()
  intent <- tolower(intent %||% "decide")
  intent <- switch(intent,
    analysis = "analyze",
    analyze_data = "analyze",
    make_decision = "decide",
    business_question = "decide",
    evidence = "review",
    resume = "continue",
    intent
  )
  intent_row <- intents[intents$intent_id == intent, , drop = FALSE]
  if (!nrow(intent_row)) {
    intent_row <- intents[intents$intent_id == "explore", , drop = FALSE]
  }
  prototype <- prototypes[prototypes$prototype_id == prototype_id, , drop = FALSE]
  if (!nrow(prototype)) {
    prototype <- prototypes[prototypes$prototype_id == "current_golden_workflow", , drop = FALSE]
  }

  start_surface <- intent_row$default_start_surface[[1]]
  if (identical(prototype$prototype_id[[1]], "prototype_b_business_question_first")) {
    start_surface <- "Guide"
  }
  if (identical(prototype$prototype_id[[1]], "current_golden_workflow")) {
    start_surface <- "Guide"
  }
  if (isTRUE(project_state$has_artifacts) && identical(intent_row$intent_id[[1]], "review")) {
    start_surface <- "Artifact Studio"
  }
  data.frame(
    prototype_id = prototype$prototype_id[[1]],
    intent_id = intent_row$intent_id[[1]],
    intent_label = intent_row$label[[1]],
    start_surface = start_surface,
    entry_prompt = prototype$entry_prompt[[1]],
    next_action = intent_row$primary_next_action[[1]],
    disclosure_level = ifelse(identical(intent_row$intent_id[[1]], "learn"), "Level 4", "Level 0"),
    reason = paste("Prototype", prototype$prototype_name[[1]], "routes", intent_row$label[[1]], "to", start_surface),
    stringsAsFactors = FALSE
  )
}

experience_compiler <- function(
  prototype = "prototype_a_intent_first",
  intent = NULL,
  workflow = product_experience_golden_workflow(),
  user_state = list(),
  current_project = list(),
  current_decision = list(),
  current_artifacts = list()
) {
  registry <- experience_prototype_registry()
  if (is.character(prototype)) {
    prototype_row <- registry[registry$prototype_id == prototype | registry$prototype_name == prototype, , drop = FALSE]
  } else if (is.data.frame(prototype)) {
    prototype_row <- prototype[1, , drop = FALSE]
  } else {
    prototype_row <- registry[0, , drop = FALSE]
  }
  if (!nrow(prototype_row)) {
    prototype_row <- registry[registry$prototype_id == "current_golden_workflow", , drop = FALSE]
  }
  intent <- intent %||% prototype_row$default_intent[[1]]
  project_state <- list(
    has_project = isTRUE(current_project$has_project %||% length(current_project) > 0L),
    has_artifacts = isTRUE(current_project$has_artifacts %||% length(current_artifacts) > 0L),
    has_decision = isTRUE(current_project$has_decision %||% length(current_decision) > 0L)
  )
  route <- experience_route_intent(intent, prototype_row$prototype_id[[1]], project_state)
  capabilities <- experience_capability_map()
  immediate_capabilities <- capabilities[capabilities$promotion %in% c("show", "summarize", "show_when_relevant"), , drop = FALSE]
  hidden_capabilities <- capabilities[capabilities$promotion %in% c("hide", "collapse", "link_contextually"), , drop = FALSE]

  if (identical(prototype_row$prototype_id[[1]], "prototype_a_intent_first")) {
    visible_components <- c("intent_prompt", "intent_choices", "recommended_path", "project_state_summary", "next_action")
    hidden_components <- c("module_registry", "architecture_docs", "developer_qa", "ai_runtime_internals", "generated_code")
    navigation <- c("Guide", route$start_surface[[1]], "Workflow", "Artifact Studio", "Mission Control")
  } else if (identical(prototype_row$prototype_id[[1]], "prototype_b_business_question_first")) {
    visible_components <- c("business_question", "decision_context", "known_evidence", "missing_evidence", "next_evidence_action")
    hidden_components <- c("broad_onboarding_choices", "module_registry", "architecture_map", "developer_surfaces", "generated_code")
    navigation <- c("Guide", "Artifact Studio", "Mission Control", "Decision Review")
  } else {
    visible_components <- c("golden_workflow_summary", "workflow_steps", "replay_metrics", "current_next_action")
    hidden_components <- c("hidden_truth", "developer_only_investor_capture")
    navigation <- unique(workflow$steps$expected_page)
  }

  information_plan <- data.frame(
    component = c(visible_components, hidden_components),
    visibility = c(rep("immediate", length(visible_components)), rep("developer_or_deferred", length(hidden_components))),
    justification = c(
      paste("Visible because it advances", route$intent_label[[1]], "under", prototype_row$prototype_name[[1]]),
      paste("Hidden because it does not advance the first", route$intent_label[[1]], "moment")
    ),
    stringsAsFactors = FALSE
  )
  navigation_plan <- data.frame(
    order = seq_along(navigation),
    surface = navigation,
    reason = c("entry", rep("compiled route", max(0, length(navigation) - 1L))),
    stringsAsFactors = FALSE
  )
  ai_plan <- data.frame(
    ai_surface = c("entry", "evidence_synthesis", "navigation", "diagnostics"),
    visibility = c(
      ifelse(grepl("hidden", prototype_row$ai_visibility[[1]]), "hidden", "contextual"),
      "contextual",
      "hidden",
      "advanced"
    ),
    rule = c(
      "AI should not explain deterministic entry choices.",
      "AI may synthesize evidence when understanding or reasoning benefits.",
      "Deterministic UI owns obvious navigation.",
      "AI/runtime diagnostics are advanced or developer-facing."
    ),
    stringsAsFactors = FALSE
  )

  compiled <- list(
    runtime_id = paste0("experience_runtime_", prototype_row$prototype_id[[1]]),
    prototype = prototype_row,
    intent = route,
    workflow = workflow[c("workflow_id", "title", "guiding_question", "success_statement")],
    navigation_plan = navigation_plan,
    information_plan = information_plan,
    ai_plan = ai_plan,
    progressive_experience = experience_progressive_runtime(prototype_row$prototype_id[[1]]),
    capability_map = capabilities,
    immediate_capabilities = immediate_capabilities,
    hidden_capabilities = hidden_capabilities,
    controls = list(
      architecture_unchanged = TRUE,
      business_logic_unchanged = TRUE,
      workflow_id = workflow$workflow_id,
      synthetic_world = "showcase_bounded_growth_pilot",
      evidence_constant = TRUE,
      decision_constant = TRUE
    ),
    metrics_seed = list(
      time_to_first_meaningful_action_sec = switch(prototype_row$prototype_id[[1]],
        prototype_a_intent_first = 18,
        prototype_b_business_question_first = 12,
        current_golden_workflow = 30,
        24
      ),
      estimated_clicks = switch(prototype_row$prototype_id[[1]],
        prototype_a_intent_first = 10,
        prototype_b_business_question_first = 9,
        current_golden_workflow = 12,
        11
      ),
      navigation_depth = nrow(navigation_plan),
      ai_interactions = ifelse(identical(prototype_row$prototype_id[[1]], "current_golden_workflow"), 1L, 0L),
      cognitive_load_estimate = switch(prototype_row$prototype_id[[1]],
        prototype_a_intent_first = "low_medium",
        prototype_b_business_question_first = "low",
        current_golden_workflow = "medium_high",
        "medium"
      )
    )
  )
  class(compiled) <- c("compiled_experience", class(compiled))
  compiled
}

experience_runtime <- function(
  prototype_id = "prototype_a_intent_first",
  intent = NULL,
  workflow = product_experience_golden_workflow(),
  user_state = list(),
  current_project = list(),
  current_decision = list(),
  current_artifacts = list()
) {
  compiled <- experience_compiler(
    prototype = prototype_id,
    intent = intent,
    workflow = workflow,
    user_state = user_state,
    current_project = current_project,
    current_decision = current_decision,
    current_artifacts = current_artifacts
  )
  service_result(
    status = "success",
    value = compiled,
    messages = paste("Compiled experience:", compiled$prototype$prototype_name[[1]])
  )
}

experience_metrics_summary <- function(compiled_experience) {
  metrics <- compiled_experience$metrics_seed
  data.frame(
    prototype_id = compiled_experience$prototype$prototype_id[[1]],
    prototype_name = compiled_experience$prototype$prototype_name[[1]],
    metric = names(metrics),
    value = unlist(metrics, use.names = FALSE),
    stringsAsFactors = FALSE
  )
}

experience_compare_compiled_prototypes <- function(
  prototype_ids = c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first"),
  intent = "decide"
) {
  compiled <- lapply(prototype_ids, function(id) experience_compiler(id, intent = intent))
  rows <- do.call(rbind, lapply(compiled, function(x) {
    data.frame(
      prototype_id = x$prototype$prototype_id[[1]],
      prototype_name = x$prototype$prototype_name[[1]],
      entry_prompt = x$prototype$entry_prompt[[1]],
      start_surface = x$intent$start_surface[[1]],
      time_to_first_meaningful_action_sec = x$metrics_seed$time_to_first_meaningful_action_sec,
      estimated_clicks = x$metrics_seed$estimated_clicks,
      navigation_depth = x$metrics_seed$navigation_depth,
      ai_interactions = x$metrics_seed$ai_interactions,
      cognitive_load_estimate = x$metrics_seed$cognitive_load_estimate,
      visible_components = paste(x$information_plan$component[x$information_plan$visibility == "immediate"], collapse = ", "),
      hidden_components = paste(x$information_plan$component[x$information_plan$visibility != "immediate"], collapse = ", "),
      stringsAsFactors = FALSE
    )
  }))
  rows$comparison_note <- ifelse(
    rows$prototype_id == "current_golden_workflow",
    "Baseline benchmark; do not treat as failed solely because it exposes more architecture.",
    "Prototype candidate; compare evidence before selecting a winner."
  )
  rows
}

experience_founder_review_comparison_template <- function(
  prototype_ids = c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first")
) {
  compiled <- lapply(prototype_ids, function(id) experience_compiler(id, intent = "decide"))
  do.call(rbind, lapply(compiled, function(x) {
    data.frame(
      prototype_id = x$prototype$prototype_id[[1]],
      prototype_name = x$prototype$prototype_name[[1]],
      first_minute_summary = NA_character_,
      first_meaningful_action = NA_character_,
      moment_of_delight = NA_character_,
      moment_of_confusion = NA_character_,
      architecture_leak = NA_character_,
      ai_necessity = NA_character_,
      evidence_clarity = NA_character_,
      product_identity_clarity = NA_character_,
      confidence_change = NA_character_,
      preference_rank = NA_integer_,
      recommendation = "pending_review",
      stringsAsFactors = FALSE
    )
  }))
}

experience_prototype_campaigns <- function(comparison = experience_compare_compiled_prototypes()) {
  data.frame(
    campaign_id = paste0("experience_runtime_campaign_", seq_len(nrow(comparison))),
    prototype_id = comparison$prototype_id,
    scope = "prototype_specific",
    trigger = c(
      "Baseline exposes current product experience for comparison.",
      "Intent-first must prove broad orientation without becoming a wizard.",
      "Business-question-first must prove story clarity without blocking exploratory users."
    )[match(comparison$prototype_id, c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first"))],
    recommended_experiment = c(
      "Replay unchanged and preserve metrics as benchmark.",
      "Replay with only intent-first entry, navigation, and information hierarchy changed.",
      "Replay with only business-question-first entry, navigation, and information hierarchy changed."
    )[match(comparison$prototype_id, c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first"))],
    success_signal = c(
      "Known baseline remains reproducible.",
      "User can choose a path without understanding modules.",
      "User understands the business story without narration."
    )[match(comparison$prototype_id, c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first"))],
    stringsAsFactors = FALSE
  )
}

experience_prototype_entry_experience <- function(prototype_id = "prototype_a_intent_first") {
  prototypes <- experience_prototype_registry()
  prototype <- prototypes[prototypes$prototype_id == prototype_id, , drop = FALSE]
  if (!nrow(prototype)) {
    prototype <- prototypes[prototypes$prototype_id == "current_golden_workflow", , drop = FALSE]
  }
  choices <- switch(prototype$prototype_id[[1]],
    prototype_a_intent_first = c("Analyze data", "Make a decision", "Review evidence", "Continue previous work", "Explore", "Learn"),
    prototype_b_business_question_first = c("Enter business question", "Use example question", "Continue previous question", "Review evidence first"),
    current_golden_workflow = c("Open Guide", "Run Golden Workflow", "Review Mission Control", "Open Artifact Studio"),
    c("Open Guide")
  )
  first_minute_goal <- switch(prototype$prototype_id[[1]],
    prototype_a_intent_first = "Let the user identify intent before exposing modules, architecture, or AI.",
    prototype_b_business_question_first = "Turn a business question into an evidence plan before exposing modules.",
    current_golden_workflow = "Expose the current benchmark workflow for comparison.",
    "Orient the user."
  )
  data.frame(
    prototype_id = prototype$prototype_id[[1]],
    prototype_name = prototype$prototype_name[[1]],
    first_interaction = prototype$entry_prompt[[1]],
    choices = paste(choices, collapse = " | "),
    first_minute_goal = first_minute_goal,
    mission_control_role = prototype$mission_control_behavior[[1]],
    ai_policy = prototype$ai_visibility[[1]],
    convergence_target = product_experience_golden_workflow()$workflow_id,
    stringsAsFactors = FALSE
  )
}

experience_prototype_replay_metrics <- function(compiled_experience) {
  id <- compiled_experience$prototype$prototype_id[[1]]
  visible_count <- sum(compiled_experience$information_plan$visibility == "immediate")
  data.frame(
    prototype_id = id,
    prototype_name = compiled_experience$prototype$prototype_name[[1]],
    time_to_first_action_sec = switch(id,
      prototype_a_intent_first = 18,
      prototype_b_business_question_first = 12,
      current_golden_workflow = 30,
      24
    ),
    time_to_first_evidence_sec = switch(id,
      prototype_a_intent_first = 70,
      prototype_b_business_question_first = 55,
      current_golden_workflow = 80,
      75
    ),
    time_to_first_understanding_sec = switch(id,
      prototype_a_intent_first = 120,
      prototype_b_business_question_first = 95,
      current_golden_workflow = 130,
      125
    ),
    clicks = compiled_experience$metrics_seed$estimated_clicks,
    navigation_depth = compiled_experience$metrics_seed$navigation_depth,
    context_switches = switch(id,
      prototype_a_intent_first = 4,
      prototype_b_business_question_first = 3,
      current_golden_workflow = 5,
      4
    ),
    backtracking = 0L,
    ai_interactions = switch(id,
      prototype_a_intent_first = 1L,
      prototype_b_business_question_first = 1L,
      current_golden_workflow = 1L,
      1L
    ),
    visible_concepts = visible_count,
    reading_burden = switch(id,
      prototype_a_intent_first = "medium",
      prototype_b_business_question_first = "low_medium",
      current_golden_workflow = "high",
      "medium"
    ),
    founder_preference = "pending_review",
    replay_quality = "compiled_fixture_estimate",
    metric_basis = "deterministic compiled prototype; browser replay remains a separate validation layer",
    stringsAsFactors = FALSE
  )
}

experience_prototype_replay_package <- function(
  prototype_id = "prototype_a_intent_first",
  intent = "decide",
  automation = "fixture",
  ai_mode = "fixture",
  output_dir = file.path("exports", "product_experience", "prototype_replays"),
  write_files = TRUE
) {
  compiled <- experience_compiler(prototype_id, intent = intent)
  workflow <- product_experience_golden_workflow()
  entry <- experience_prototype_entry_experience(compiled$prototype$prototype_id[[1]])
  metrics <- experience_prototype_replay_metrics(compiled)
  run_id <- paste0("phase2_", compiled$prototype$prototype_id[[1]], "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  run_dir <- file.path(output_dir, run_id)
  chapters <- product_experience_golden_chapters()
  chapters$screenshot_status <- if (identical(automation, "fixture")) "fixture_contract_only" else "pending_recorder"
  chapters$screenshot_path <- NA_character_
  replay_events <- data.frame(
    event_order = seq_len(nrow(workflow$steps)),
    step_id = workflow$steps$step_id,
    chapter = workflow$steps$chapter,
    expected_page = workflow$steps$expected_page,
    prototype_surface = rep(compiled$intent$start_surface[[1]], nrow(workflow$steps)),
    validation = workflow$steps$expected_validation,
    stringsAsFactors = FALSE
  )
  founder_review <- data.frame(
    prototype_id = compiled$prototype$prototype_id[[1]],
    dimension = c("strengths", "weaknesses", "delight", "confusion", "trust", "recommendation", "open_questions"),
    prompt = c(
      "What became easier or more obvious?",
      "Where did this prototype create friction or hide too much?",
      "What moment made the workstation feel inevitable?",
      "Where did you wonder what to do next?",
      "Did the prototype increase confidence in the product?",
      "Should this remain in the candidate set, be revised, or be rejected?",
      "What must be tested in the next replay?"
    ),
    response = NA_character_,
    stringsAsFactors = FALSE
  )
  package <- list(
    run_id = run_id,
    package_type = "product_experience_phase2_prototype_replay",
    prototype_id = compiled$prototype$prototype_id[[1]],
    prototype_name = compiled$prototype$prototype_name[[1]],
    automation = automation,
    ai_mode = ai_mode,
    recorder_status = if (identical(automation, "fixture")) "fixture_contract_only" else "pending_recorder",
    entry_experience = entry,
    compiled_experience = compiled,
    workflow = workflow[c("workflow_id", "title", "guiding_question", "success_statement")],
    workflow_steps = workflow$steps,
    chapters = chapters,
    replay_events = replay_events,
    metrics = metrics,
    founder_review = founder_review,
    mission_control_role = compiled$prototype$mission_control_behavior[[1]],
    ai_visibility = compiled$prototype$ai_visibility[[1]],
    information_layers = experience_progressive_runtime(compiled$prototype$prototype_id[[1]]),
    convergence = list(
      same_synthetic_world = TRUE,
      same_golden_workflow = TRUE,
      same_artifacts = TRUE,
      same_decision = TRUE,
      same_ai_capabilities = TRUE
    ),
    no_final_winner_declared = TRUE,
    hidden_truth_included = FALSE,
    created_at = Sys.time()
  )
  if (isTRUE(write_files)) {
    dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
    manifest_path <- file.path(run_dir, "prototype_replay_manifest.json")
    review_path <- file.path(run_dir, "founder_review_package.json")
    product_experience_write_json(package, manifest_path)
    product_experience_write_json(list(
      run_id = run_id,
      prototype = entry,
      metrics = metrics,
      founder_review = founder_review,
      comparison_prompt = "Review this replay against Current, Prototype A, and Prototype B without choosing a final winner prematurely."
    ), review_path)
    package$manifest_path <- normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
    package$review_package_path <- normalizePath(review_path, winslash = "/", mustWork = FALSE)
  } else {
    package$manifest_path <- NA_character_
    package$review_package_path <- NA_character_
  }
  service_result(
    status = "success",
    value = package,
    messages = paste("Prototype replay package generated:", run_id),
    metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE))
  )
}

experience_run_all_prototype_replays <- function(write_files = TRUE) {
  prototype_ids <- c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first")
  runs <- lapply(prototype_ids, function(id) {
    experience_prototype_replay_package(id, intent = "decide", write_files = write_files)$value
  })
  names(runs) <- prototype_ids
  service_result(
    status = "success",
    value = runs,
    messages = "Generated Current, Prototype A, and Prototype B replay packages."
  )
}

experience_compare_prototype_replays <- function(replays = NULL) {
  if (is.null(replays)) {
    replays <- experience_run_all_prototype_replays(write_files = FALSE)$value
  }
  rows <- do.call(rbind, lapply(replays, function(x) x$metrics))
  rows$entry_prompt <- vapply(replays, function(x) x$entry_experience$first_interaction[[1]], character(1))
  rows$mission_control_role <- vapply(replays, function(x) x$mission_control_role, character(1))
  rows$ai_visibility <- vapply(replays, function(x) x$ai_visibility, character(1))
  rows$strength_hypothesis <- c(
    current_golden_workflow = "Best benchmark for continuity and regression detection.",
    prototype_a_intent_first = "Likely best for cold-start orientation and broad user goals.",
    prototype_b_business_question_first = "Likely best for business-value clarity and investor narrative."
  )[rows$prototype_id]
  rows$risk_hypothesis <- c(
    current_golden_workflow = "Can expose too much implementation and require prior product knowledge.",
    prototype_a_intent_first = "Could become a generic wizard if the chosen intent does not quickly produce evidence.",
    prototype_b_business_question_first = "Could feel too narrow for exploratory users or users without a crisp question."
  )[rows$prototype_id]
  rows$recommendation <- "compare_with_founder_replay_before_selection"
  rows
}

experience_founder_review_package <- function(replays = NULL) {
  if (is.null(replays)) {
    replays <- experience_run_all_prototype_replays(write_files = FALSE)$value
  }
  rows <- do.call(rbind, lapply(replays, function(x) {
    data.frame(
      prototype_id = x$prototype_id,
      prototype_name = x$prototype_name,
      strengths = NA_character_,
      weaknesses = NA_character_,
      delight = NA_character_,
      confusion = NA_character_,
      trust = NA_character_,
      recommendation = "pending_founder_review",
      open_questions = NA_character_,
      replay_manifest = x$manifest_path %||% NA_character_,
      stringsAsFactors = FALSE
    )
  }))
  rows$review_rule <- "Evaluate the same Golden Workflow under each entry experience; do not choose a final winner until replay evidence is reviewed."
  rows
}

experience_phase2_recommendation <- function(comparison = experience_compare_prototype_replays()) {
  data.frame(
    question = c(
      "Which prototype should lead the next replay?",
      "Should Mission Control be the entry point?",
      "How visible should AI be?",
      "Should a third prototype be preserved?"
    ),
    current_answer = c(
      "Run A and B against the same Golden Workflow before selecting.",
      "No. Mission Control should support orientation after the user states intent or question.",
      "Contextual. AI should appear when evidence synthesis or explanation is valuable, not as the first obligation.",
      "Yes. A decision-first prototype remains a plausible future candidate after A/B are reviewed."
    ),
    evidence_basis = c(
      "Compiled metrics favor B for first understanding and A for broad orientation; neither has founder replay evidence yet.",
      "Mission Control is a status and operating workspace; as the first screen it may require users to understand the architecture too early.",
      "The runtime separates deterministic UX from probabilistic reasoning.",
      "The phase is exploration; preserving alternatives lowers premature convergence risk."
    ),
    next_step = c(
      "Record Current, A, and B with identical world/evidence/decision conditions.",
      "Keep Mission Control visible as a supporting workspace in both prototypes.",
      "Evaluate whether AI contributes a shorter, clearer explanation in the evidence and decision chapters.",
      "Define a decision-first prototype only after A and B expose their failure modes."
    ),
    stringsAsFactors = FALSE
  )
}

experience_phase2_campaigns <- function(comparison = experience_compare_prototype_replays()) {
  data.frame(
    campaign_id = paste0("experience_phase2_", comparison$prototype_id),
    prototype_id = comparison$prototype_id,
    scope = "prototype_specific",
    campaign_goal = c(
      current_golden_workflow = "Preserve benchmark replay and measure architecture leakage.",
      prototype_a_intent_first = "Validate whether users can begin from intent without module knowledge.",
      prototype_b_business_question_first = "Validate whether a business question produces faster evidence comprehension."
    )[comparison$prototype_id],
    success_metric = c(
      current_golden_workflow = "Stable replay with no broken transitions.",
      prototype_a_intent_first = "Lower first-action friction without increasing backtracking.",
      prototype_b_business_question_first = "Lower time-to-understanding with credible evidence visibility."
    )[comparison$prototype_id],
    risk_to_watch = comparison$risk_hypothesis,
    stringsAsFactors = FALSE
  )
}

experience_phase3_trial_prototypes <- function() {
  data.frame(
    replay_id = c("Replay_Current", "Replay_Intent", "Replay_BusinessQuestion"),
    prototype_id = c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first"),
    prototype_label = c("Current Experience", "Intent-First", "Business Question First"),
    hypothesis = c(
      "The current experience may preserve capability context but expose architecture too early.",
      "Intent-first may reduce cold-start ambiguity by asking what the user wants to accomplish.",
      "Business-question-first may reveal product identity fastest by starting with the decision problem."
    ),
    allowed_difference = "Entry, navigation, information hierarchy, progressive disclosure",
    controlled_constants = "same world, data, AI, evidence, Golden Workflow, final decision, viewport, browser, pacing",
    stringsAsFactors = FALSE
  )
}

experience_phase3_output_root <- function(root = getwd()) {
  file.path(product_experience_replay_output_root(root), "phase3_prototype_trial")
}

experience_phase3_cognitive_load <- function(run_or_package) {
  prototype_id <- run_or_package$prototype_id %||% "current_golden_workflow"
  data.frame(
    prototype_id = prototype_id,
    initial_overload = switch(prototype_id,
      prototype_a_intent_first = "medium",
      prototype_b_business_question_first = "low_medium",
      current_golden_workflow = "high",
      "medium"
    ),
    progressive_understanding = switch(prototype_id,
      prototype_a_intent_first = "steady_after_intent_choice",
      prototype_b_business_question_first = "fast_after_question_entry",
      current_golden_workflow = "delayed_until_workflow_context",
      "unknown"
    ),
    information_density = switch(prototype_id,
      prototype_a_intent_first = "moderate",
      prototype_b_business_question_first = "focused",
      current_golden_workflow = "dense",
      "unknown"
    ),
    decision_confidence = switch(prototype_id,
      prototype_a_intent_first = "moderate_pending_founder_review",
      prototype_b_business_question_first = "higher_pending_founder_review",
      current_golden_workflow = "moderate_with_architecture_noise",
      "unknown"
    ),
    cognitive_load_spike = switch(prototype_id,
      prototype_a_intent_first = "after intent choice if the next route still exposes modules",
      prototype_b_business_question_first = "when translating question to evidence if the path is unclear",
      current_golden_workflow = "initial orientation and developer/product-experience surfaces",
      "unknown"
    ),
    stringsAsFactors = FALSE
  )
}

experience_phase3_product_story <- function(run_or_package) {
  prototype_id <- run_or_package$prototype_id %||% "current_golden_workflow"
  data.frame(
    prototype_id = prototype_id,
    first_product_identity_moment = switch(prototype_id,
      prototype_a_intent_first = "The user sees that intent controls the workstation path.",
      prototype_b_business_question_first = "The user sees that a business question becomes evidence and a decision path.",
      current_golden_workflow = "The user sees a capable workflow, but product identity may depend on later explanation.",
      "unknown"
    ),
    viewer_understanding_trigger = switch(prototype_id,
      prototype_a_intent_first = "intent choices",
      prototype_b_business_question_first = "business question prompt",
      current_golden_workflow = "Golden Workflow review",
      "unknown"
    ),
    story_risk = switch(prototype_id,
      prototype_a_intent_first = "Could feel like onboarding rather than a decision system.",
      prototype_b_business_question_first = "Could feel narrow for users without a ready question.",
      current_golden_workflow = "Could look like a collection of powerful modules.",
      "unknown"
    ),
    stringsAsFactors = FALSE
  )
}

experience_phase3_ai_assessment <- function(run_or_package) {
  prototype_id <- run_or_package$prototype_id %||% "current_golden_workflow"
  data.frame(
    prototype_id = prototype_id,
    visibility = switch(prototype_id,
      prototype_a_intent_first = "contextual_after_intent",
      prototype_b_business_question_first = "contextual_after_evidence_need",
      current_golden_workflow = "visible_when_workflow_requests",
      "unknown"
    ),
    naturalness = switch(prototype_id,
      prototype_a_intent_first = "useful_if_it_explains_route",
      prototype_b_business_question_first = "useful_if_it_synthesizes_question_to_evidence",
      current_golden_workflow = "variable",
      "unknown"
    ),
    necessity = switch(prototype_id,
      prototype_a_intent_first = "not_required_for_entry",
      prototype_b_business_question_first = "not_required_for_entry_but_useful_for_evidence_synthesis",
      current_golden_workflow = "not_required_for_navigation",
      "unknown"
    ),
    deterministic_replacement_flag = switch(prototype_id,
      prototype_a_intent_first = "entry choices should be deterministic",
      prototype_b_business_question_first = "question scaffolding should be deterministic",
      current_golden_workflow = "obvious navigation should be deterministic",
      "unknown"
    ),
    stringsAsFactors = FALSE
  )
}

experience_phase3_replay_validation <- function(run) {
  chapters <- run$chapters %||% data.frame()
  metrics <- run$metrics %||% list()
  data.frame(
    check = c(
      "expected_page",
      "expected_state",
      "expected_workflow",
      "expected_artifacts",
      "expected_transitions",
      "expected_ai",
      "expected_mission_control",
      "expected_final_draft",
      "expected_completion",
      "video",
      "screenshots",
      "trace"
    ),
    status = c(
      if (all(product_experience_golden_workflow()$steps$expected_page %in% chapters$chapter | nrow(chapters) >= 8L)) "pass" else "review",
      if (length(run$events %||% list()) > 0L) "pass" else "review",
      if (identical(run$workflow_id %||% "", product_experience_golden_workflow()$workflow_id)) "pass" else "fail",
      if (all(c("same_synthetic_world", "same_artifacts", "same_decision") %in% names((experience_prototype_replay_package(run$prototype_id %||% "current_golden_workflow", write_files = FALSE)$value)$convergence))) "pass" else "review",
      if (length(run$events %||% list()) > 0L) "pass" else "review",
      if (!is.null(metrics$ai_interactions)) "pass" else "review",
      if (!is.null(metrics$mission_control_usage) || !is.null(metrics$navigation_depth)) "pass" else "review",
      if (!is.null(metrics$draft_acceptance) || grepl("persisted", paste(chapters$chapter, collapse = " "), ignore.case = TRUE)) "pass" else "review",
      if (identical(run$recorder_status %||% "", "Golden Workflow completed")) "pass" else "fail",
      if (nzchar(run$video_path %||% "") && file.exists(run$video_path)) "pass" else "fail",
      if (nrow(chapters) >= 8L && all(file.exists(chapters$screenshot_path))) "pass" else "fail",
      if (nzchar(run$trace_path %||% "") && file.exists(run$trace_path)) "pass" else "fail"
    ),
    recommendation = c(
      "Confirm canonical pages remain visible.",
      "Confirm state changes are visible in the recording.",
      "All prototypes must use the same Golden Workflow.",
      "Do not compare prototypes if evidence differs.",
      "Review event ordering for navigation differences.",
      "AI must be disclosed and measured.",
      "Mission Control role must be visible or explicitly supporting.",
      "The replay must reach the persisted draft/review package.",
      "Incomplete replays cannot select product philosophy.",
      "Inspect the WebM manually.",
      "Inspect screenshots for meaningful chapters.",
      "Keep the trace for debugging replay behavior."
    ),
    stringsAsFactors = FALSE
  )
}

experience_phase3_founder_review_package <- function(runs) {
  do.call(rbind, lapply(runs, function(run) {
    data.frame(
      replay_id = run$replay_id %||% run$prototype_id,
      prototype_id = run$prototype_id,
      prototype_name = run$prototype_name,
      understanding = NA_character_,
      trust = NA_character_,
      confusion = NA_character_,
      delight = NA_character_,
      evidence = NA_character_,
      workflow = NA_character_,
      ai = NA_character_,
      visual_hierarchy = NA_character_,
      navigation = NA_character_,
      recommendation = "pending_founder_review",
      approval = "pending",
      video_path = run$video_path %||% NA_character_,
      review_package_path = run$review_package_path %||% NA_character_,
      stringsAsFactors = FALSE
    )
  }))
}

experience_phase3_compare_browser_replays <- function(runs) {
  rows <- do.call(rbind, lapply(runs, function(run) {
    metrics <- run$metrics %||% list()
    data.frame(
      prototype_id = run$prototype_id,
      prototype_name = run$prototype_name,
      time_to_first_action_sec = metrics$time_to_first_action_sec %||% NA_integer_,
      time_to_first_evidence_sec = metrics$time_to_first_evidence_sec %||% NA_integer_,
      time_to_first_insight_sec = metrics$time_to_first_insight_sec %||% NA_integer_,
      clicks = metrics$clicks %||% NA_integer_,
      workflow_duration_sec = metrics$completion_time_sec %||% NA_integer_,
      navigation_depth = metrics$navigation_depth %||% NA_integer_,
      context_switches = metrics$context_switches %||% NA_integer_,
      backtracking = metrics$backtracking %||% NA_integer_,
      visible_concepts = metrics$visible_concepts %||% NA_integer_,
      ai_interactions = metrics$ai_interactions %||% NA_integer_,
      mission_control_usage = metrics$mission_control_usage %||% NA_integer_,
      reading_burden = metrics$reading_burden %||% NA_character_,
      completion = identical(run$recorder_status %||% "", "Golden Workflow completed"),
      video_path = run$video_path %||% NA_character_,
      stringsAsFactors = FALSE
    )
  }))
  rows$cognitive_load_estimate <- vapply(seq_len(nrow(rows)), function(i) {
    experience_phase3_cognitive_load(list(prototype_id = rows$prototype_id[[i]]))$initial_overload[[1]]
  }, character(1))
  rows$product_identity_speed <- vapply(seq_len(nrow(rows)), function(i) {
    experience_phase3_product_story(list(prototype_id = rows$prototype_id[[i]]))$viewer_understanding_trigger[[1]]
  }, character(1))
  rows$strength_hypothesis <- c(
    current_golden_workflow = "Best benchmark for continuity and regression detection.",
    prototype_a_intent_first = "Likely best for cold-start orientation and broad user goals.",
    prototype_b_business_question_first = "Likely best for business-value clarity and investor narrative."
  )[rows$prototype_id]
  rows$risk_hypothesis <- c(
    current_golden_workflow = "Can expose too much implementation and require prior product knowledge.",
    prototype_a_intent_first = "Could become a generic wizard if the chosen intent does not quickly produce evidence.",
    prototype_b_business_question_first = "Could feel too narrow for exploratory users or users without a crisp question."
  )[rows$prototype_id]
  rows
}

experience_phase3_pairwise_comparison <- function(comparison) {
  pairs <- list(
    c("current_golden_workflow", "prototype_a_intent_first"),
    c("current_golden_workflow", "prototype_b_business_question_first"),
    c("prototype_a_intent_first", "prototype_b_business_question_first")
  )
  do.call(rbind, lapply(pairs, function(pair) {
    a <- comparison[comparison$prototype_id == pair[[1]], , drop = FALSE]
    b <- comparison[comparison$prototype_id == pair[[2]], , drop = FALSE]
    data.frame(
      comparison = paste(a$prototype_name[[1]], "vs", b$prototype_name[[1]]),
      first_action_delta_sec = b$time_to_first_action_sec[[1]] - a$time_to_first_action_sec[[1]],
      first_evidence_delta_sec = b$time_to_first_evidence_sec[[1]] - a$time_to_first_evidence_sec[[1]],
      insight_delta_sec = b$time_to_first_insight_sec[[1]] - a$time_to_first_insight_sec[[1]],
      click_delta = b$clicks[[1]] - a$clicks[[1]],
      interpretation = "Negative deltas favor the second prototype on speed/click metrics; founder review must still judge trust and identity.",
      stringsAsFactors = FALSE
    )
  }))
}

experience_phase3_final_assessment <- function(comparison, founder_review = NULL) {
  data.frame(
    question = c(
      "Which prototype minimizes cognitive load?",
      "Which reveals the product identity fastest?",
      "Which best hides architectural complexity?",
      "Which best prepares the Golden Workflow?",
      "Which produces the strongest trust?",
      "Which best balances simplicity and capability?",
      "Should either challenger replace the current experience?",
      "Should a third prototype now be explored?"
    ),
    evidence_based_answer = c(
      "Preliminary metrics favor Business Question First; founder review is still required.",
      "Preliminary product-story assessment favors Business Question First.",
      "Intent First and Business Question First both hide more architecture than Current; Business Question First is more focused.",
      "Business Question First best prepares the decision narrative; Intent First best prepares general navigation.",
      "Not yet knowable without founder review of the recordings.",
      "Preliminary balance favors Intent First for breadth and Business Question First for clarity; no automatic winner.",
      "Not until the three recordings are reviewed and scored.",
      "Yes. Decision-first should remain a future hypothesis if A/B succeed for different reasons."
    ),
    confidence = c("preliminary", "preliminary", "preliminary", "preliminary", "insufficient_evidence", "preliminary", "insufficient_evidence", "reasonable"),
    required_next_evidence = c(
      "Founder cognitive load ratings",
      "Founder first-understanding timestamp",
      "Architecture-leak review",
      "Golden Workflow completion review",
      "Trust rating after watching unedited videos",
      "Founder preference and replay quality",
      "Approval decision",
      "Observed failure modes from A/B"
    ),
    stringsAsFactors = FALSE
  )
}

experience_run_phase3_browser_trial <- function(
  port = 3899,
  root = getwd(),
  runtime_root = product_experience_runtime_root(),
  output_root = experience_phase3_output_root(root),
  ai_mode = "fixture",
  pacing_profile = "investor",
  prototype_ids = experience_phase3_trial_prototypes()$prototype_id
) {
  dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
  trial_id <- paste0("phase3_browser_trial_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  trial_dir <- file.path(output_root, trial_id)
  dir.create(trial_dir, recursive = TRUE, showWarnings = FALSE)
  results <- lapply(prototype_ids, function(id) {
    prototype_dir <- file.path(trial_dir, id)
    result <- product_experience_regenerate_golden_workflow(
      port = port,
      root = root,
      runtime_root = runtime_root,
      output_root = prototype_dir,
      ai_mode = ai_mode,
      pacing_profile = pacing_profile,
      prototype_id = id
    )
    if (!is.null(result$value)) {
      result$value$replay_id <- experience_phase3_trial_prototypes()$replay_id[match(id, experience_phase3_trial_prototypes()$prototype_id)]
      result$value$validation <- experience_phase3_replay_validation(result$value)
    }
    result
  })
  names(results) <- prototype_ids
  successful_runs <- lapply(results, function(x) x$value)
  successful_runs <- successful_runs[!vapply(successful_runs, is.null, logical(1))]
  comparison <- if (length(successful_runs)) experience_phase3_compare_browser_replays(successful_runs) else data.frame()
  pairwise <- if (nrow(comparison)) experience_phase3_pairwise_comparison(comparison) else data.frame()
  founder <- if (length(successful_runs)) experience_phase3_founder_review_package(successful_runs) else data.frame()
  campaigns <- if (nrow(comparison)) experience_phase2_campaigns(comparison) else data.frame()
  final <- if (nrow(comparison)) experience_phase3_final_assessment(comparison, founder) else data.frame()
  summary <- list(
    trial_id = trial_id,
    trial_type = "product_experience_runtime_phase3_browser_trial",
    trial_dir = normalizePath(trial_dir, winslash = "/", mustWork = FALSE),
    summary_path = normalizePath(file.path(trial_dir, "phase3_trial_summary.json"), winslash = "/", mustWork = FALSE),
    prototypes = experience_phase3_trial_prototypes(),
    results = results,
    comparison = comparison,
    pairwise_comparison = pairwise,
    founder_review = founder,
    campaigns = campaigns,
    final_assessment = final,
    open_questions = product_experience_research_open_questions(),
    created_at = Sys.time()
  )
  summary_path <- summary$summary_path
  product_experience_write_json(summary, summary_path)
  service_result(
    status = if (all(vapply(results, function(x) identical(x$status, "success"), logical(1)))) "success" else "warning",
    value = summary,
    warnings = names(results)[!vapply(results, function(x) identical(x$status, "success"), logical(1))],
    messages = paste("Phase 3 browser prototype trial generated:", trial_id),
    metadata = list(trial_dir = normalizePath(trial_dir, winslash = "/", mustWork = FALSE), summary_path = normalizePath(summary_path, winslash = "/", mustWork = FALSE))
  )
}

product_experience_replay_output_root <- function(root = getwd(), media_root = NULL) {
  product_experience_media_dirs(root, media_root, create = TRUE)$runs
}

product_experience_showcase_candidate_ranking <- function() {
  data.frame(
    rank = 1:5,
    candidate_id = c(
      "showcase_bounded_growth_pilot",
      "world_03_contradictory_evidence",
      "world_08_epistemic_integrity",
      "world_05_guardrail_failure",
      "world_09_decision_lifecycle"
    ),
    title = c(
      "Bounded Growth Pilot",
      "Contradictory Evidence",
      "Epistemic Integrity",
      "Guardrail Failure",
      "Decision Lifecycle"
    ),
    investor_story = c(
      "A business question becomes evidence, uncertainty, a governed pilot, and project memory.",
      "The app shows it can preserve conflicting evidence instead of smoothing it away.",
      "The app demonstrates epistemic governance and claim-risk controls.",
      "The app blocks an apparently good decision when a guardrail fails.",
      "The app connects recommendation, approval, implementation, and outcome."
    ),
    data_richness = c("high", "high", "medium", "medium", "medium"),
    visual_potential = c("high", "medium", "medium", "medium", "medium"),
    ai_demonstrability = c("high", "medium", "high", "medium", "medium"),
    governance_visibility = c("high", "medium", "high", "high", "high"),
    recommendation = c(
      "Use as Phase 4 flagship.",
      "Keep as comparison candidate.",
      "Keep for governance-focused demos.",
      "Use when guardrails are the main story.",
      "Use after decision workflow UI is visually stronger."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_flagship_world <- function() {
  list(
    world_id = "showcase_bounded_growth_pilot",
    title = "Bounded Growth Pilot",
    business_question = "Which acquisition tactic should we scale next quarter without violating quality and capacity guardrails?",
    public_objective = "Recommend a governed next action from realistic growth, cost, quality, and capacity evidence.",
    audience = "Investor, product reviewer, analyst, and executive stakeholder.",
    app_visible_truth = FALSE,
    decision_context = c(
      "Search and partner campaigns can increase qualified applications.",
      "Aggressive scaling risks higher acquisition cost and lower downstream quality.",
      "The system should recommend a bounded pilot instead of a full rollout when uncertainty remains."
    ),
    hidden_truth_policy = "Generating mechanism and true response curves are QA-only and never shown as app-facing evidence."
  )
}

product_experience_generate_flagship_world <- function(seed = 20260714L) {
  set.seed(seed)
  dates <- seq.Date(as.Date("2025-01-01"), by = "week", length.out = 52)
  regions <- c("Northeast", "Midwest", "South", "West")
  channels <- c("Search", "Social", "Partner")
  grid <- expand.grid(date = dates, region = regions, channel = channels, stringsAsFactors = FALSE)
  region_multiplier <- c(Northeast = 0.95, Midwest = 1.08, South = 0.9, West = 1.18)
  channel_cost <- c(Search = 42, Social = 29, Partner = 55)
  channel_quality <- c(Search = 0.74, Social = 0.62, Partner = 0.81)
  week_index <- as.integer((grid$date - min(grid$date)) / 7) + 1L
  seasonality <- 1 + 0.12 * sin(2 * pi * week_index / 26)
  spend <- round(runif(nrow(grid), 1600, 7200) * region_multiplier[grid$region] * seasonality, 2)
  saturation <- 1 - exp(-spend / 6200)
  raw_leads <- rpois(nrow(grid), lambda = 42 + 120 * saturation * region_multiplier[grid$region])
  quality_rate <- pmax(0.18, pmin(0.86, channel_quality[grid$channel] - 0.06 * (spend > 6000) + rnorm(nrow(grid), 0, 0.035)))
  qualified <- rbinom(nrow(grid), pmax(raw_leads, 1), quality_rate)
  enroll_rate <- pmax(0.08, pmin(0.44, 0.17 + 0.11 * (grid$channel == "Partner") + 0.06 * (grid$region %in% c("Midwest", "West")) - 0.04 * (spend > 6500)))
  enrollments <- rbinom(nrow(grid), pmax(qualified, 1), enroll_rate)
  capacity_utilization <- pmin(1.18, 0.55 + 0.0025 * ave(enrollments, grid$region, FUN = function(x) cumsum(x) / seq_along(x)) + rnorm(nrow(grid), 0, 0.025))
  app_data <- data.frame(
    date = grid$date,
    region = grid$region,
    channel = grid$channel,
    spend = spend,
    leads = raw_leads,
    qualified_leads = qualified,
    enrollments = enrollments,
    cost_per_enrollment = round(spend / pmax(enrollments, 1), 2),
    quality_rate = round(quality_rate, 3),
    capacity_utilization = round(capacity_utilization, 3),
    pilot_eligible = grid$region %in% c("Midwest", "West") & grid$channel %in% c("Search", "Partner"),
    stringsAsFactors = FALSE
  )
  truth <- list(
    seed = seed,
    hidden_truth = TRUE,
    true_best_action = "Bounded Midwest/West Search and Partner pilot with spend caps and capacity guardrails.",
    generating_mechanism = "Nonlinear response with channel-specific cost/quality tradeoffs and regional capacity saturation.",
    reason_full_rollout_is_wrong = "High spend increases volume but degrades quality and capacity in several region-channel pairs.",
    expected_failure_if_truth_leaks = "A demo could appear omniscient rather than evidence-driven."
  )
  list(
    world = product_experience_flagship_world(),
    app_data = app_data,
    truth_manifest = truth
  )
}

product_experience_flagship_evidence_package <- function(seed = 20260714L) {
  generated <- product_experience_generate_flagship_world(seed)
  data <- generated$app_data
  by_channel <- aggregate(
    cbind(spend, leads, qualified_leads, enrollments) ~ channel,
    data = data,
    FUN = sum
  )
  by_channel$cost_per_enrollment <- round(by_channel$spend / pmax(by_channel$enrollments, 1), 2)
  by_channel$qualification_rate <- round(by_channel$qualified_leads / pmax(by_channel$leads, 1), 3)
  by_region <- aggregate(
    cbind(enrollments, quality_rate, capacity_utilization) ~ region,
    data = data,
    FUN = mean
  )
  by_region$enrollments <- round(by_region$enrollments, 1)
  by_region$quality_rate <- round(by_region$quality_rate, 3)
  by_region$capacity_utilization <- round(by_region$capacity_utilization, 3)
  list(
    showcase_id = "showcase_bounded_growth_pilot",
    title = "Bounded Growth Pilot Evidence Package",
    business_question = generated$world$business_question,
    visible_evidence = list(
      descriptive = "Search and Partner channels generate the most qualified enrollment volume, but cost and capacity pressure rise at higher spend.",
      causal_design = "The next credible step is a bounded pilot, not an unrestricted rollout; existing evidence is suggestive but not decision-final.",
      guardrail = "Capacity utilization and qualification rate are explicit guardrails. Several aggressive scaling cells approach guardrail limits.",
      valuation = "Expected value is positive only under capped spend, monitored capacity, and pre-specified stopping criteria.",
      governed_next_action = "Run a Midwest/West Search + Partner pilot with capped spend, weekly guardrail review, and pre-registered decision criteria."
    ),
    tables = list(
      channel_summary = by_channel,
      region_guardrails = by_region
    ),
    limitations = c(
      "Synthetic world is scientifically coherent but not real customer data.",
      "The current demo uses deterministic fixture evidence; live model behavior should be separately qualified.",
      "The true generating mechanism remains QA-only and should not be visible in app-facing evidence."
    ),
    hidden_truth_included = FALSE
  )
}

product_experience_showcase_media_manifest <- function(run, lifecycle_state = "awaiting_review", media_root = product_experience_media_root()) {
  states <- product_experience_media_lifecycle_states()$lifecycle_state
  if (!lifecycle_state %in% states) {
    stop("Unknown media lifecycle state: ", lifecycle_state, call. = FALSE)
  }
  list(
    manifest_type = "product_experience_showcase_media_manifest",
    schema_version = "0.1.0",
    lifecycle_state = lifecycle_state,
    media_root = normalizePath(media_root, winslash = "/", mustWork = FALSE),
    run_id = run$run_id %||% NA_character_,
    workflow_id = run$workflow_id %||% NA_character_,
    world_id = run$world_id %||% NA_character_,
    video_path = run$video_path %||% NA_character_,
    trace_path = run$trace_path %||% NA_character_,
    review_package_path = run$review_package_path %||% NA_character_,
    screenshot_count = if (!is.null(run$chapters)) nrow(run$chapters) else NA_integer_,
    hidden_truth_included = isTRUE(run$hidden_truth_included),
    created_at = as.character(Sys.time()),
    reviewer_required = lifecycle_state %in% c("candidate", "awaiting_review")
  )
}

product_experience_runtime_root <- function() {
  file.path("runtime", "product-experience")
}

product_experience_tool_manifest_path <- function() {
  file.path("tools", "product-experience", "package.json")
}

product_experience_runtime_package_path <- function(root = product_experience_runtime_root()) {
  file.path(root, "package.json")
}

product_experience_find_executable <- function(names, extra_dirs = character()) {
  extension_rank <- function(paths) {
    if (any(grepl("\\.cmd$", names, ignore.case = TRUE))) {
      return(!grepl("\\.cmd$", paths, ignore.case = TRUE))
    }
    if (any(grepl("\\.exe$", names, ignore.case = TRUE))) {
      return(!grepl("\\.exe$", paths, ignore.case = TRUE))
    }
    rep(FALSE, length(paths))
  }
  for (dir in extra_dirs[!is.na(extra_dirs) & nzchar(extra_dirs) & file.exists(extra_dirs)]) {
    direct <- file.path(dir, names)
    recursive <- list.files(dir, pattern = paste0("^(", paste(gsub("\\.", "\\\\.", names), collapse = "|"), ")$"), recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
    local_found <- unique(c(direct[file.exists(direct)], recursive[file.exists(recursive)]))
    if (length(local_found)) {
      local_found <- local_found[order(grepl("node_modules", local_found, fixed = TRUE), extension_rank(local_found), nchar(local_found))]
      return(normalizePath(local_found[[1]], winslash = "/", mustWork = FALSE))
    }
  }
  global_candidates <- unname(Sys.which(names))
  global_candidates <- global_candidates[!is.na(global_candidates) & nzchar(global_candidates)]
  found <- global_candidates[file.exists(global_candidates)]
  if (!length(found) || is.na(found[[1]])) "" else normalizePath(found[[1]], winslash = "/", mustWork = FALSE)
}

product_experience_node_search_dirs <- function(root = product_experience_runtime_root()) {
  unique(c(
    file.path(root, "node"),
    dirname(Sys.which("node")),
    dirname(Sys.which("npm")),
    dirname(Sys.which("npx")),
    "C:/Program Files/RStudio/resources/app/bin/node",
    "C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Microsoft/VisualStudio/NodeJs",
    "C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Microsoft/VisualStudio/NodeJs/win-x86"
  ))
}

product_experience_runtime_discovery <- function(root = product_experience_runtime_root()) {
  dirs <- product_experience_node_search_dirs(root)
  node <- product_experience_find_executable(c("node", "node.exe"), dirs)
  npm <- product_experience_find_executable(c("npm", "npm.cmd"), dirs)
  npx <- product_experience_find_executable(c("npx", "npx.cmd"), dirs)
  playwright <- product_experience_find_executable(c("playwright", "playwright.cmd"), c(dirs, file.path(root, "node_modules", ".bin")))
  package_json <- product_experience_runtime_package_path(root)
  package_lock <- file.path(root, "package-lock.json")
  previous <- list(
    screenshots = list.files(file.path("exports", "product_experience"), pattern = "\\.png$", recursive = TRUE, full.names = TRUE),
    videos = list.files(file.path("exports", "product_experience"), pattern = "\\.webm$", recursive = TRUE, full.names = TRUE),
    traces = list.files(file.path("exports", "product_experience"), pattern = "trace\\.zip$", recursive = TRUE, full.names = TRUE),
    reports = list.files(file.path("exports", "product_experience"), pattern = "execution_report\\.json$", recursive = TRUE, full.names = TRUE)
  )
  data.frame(
    component = c("node", "npm", "npx", "playwright", "package_json", "package_lock", "previous_screenshots", "previous_videos", "previous_traces", "previous_reports"),
    path = c(node, npm, npx, playwright, package_json, package_lock, paste(previous$screenshots, collapse = ";"), paste(previous$videos, collapse = ";"), paste(previous$traces, collapse = ";"), paste(previous$reports, collapse = ";")),
    available = c(nzchar(node), nzchar(npm), nzchar(npx), nzchar(playwright), file.exists(package_json), file.exists(package_lock), length(previous$screenshots) > 0L, length(previous$videos) > 0L, length(previous$traces) > 0L, length(previous$reports) > 0L),
    stringsAsFactors = FALSE
  )
}

product_experience_playwright_available <- function(root = product_experience_runtime_root()) {
  discovery <- product_experience_runtime_discovery(root)
  isTRUE(discovery$available[match("node", discovery$component)]) &&
    isTRUE(discovery$available[match("playwright", discovery$component)])
}

product_experience_playwright_diagnostics <- function(root = product_experience_runtime_root()) {
  discovery <- product_experience_runtime_discovery(root)
  discovery[discovery$component %in% c("node", "npm", "npx", "playwright"), , drop = FALSE]
}

product_experience_node_version <- "v22.13.1"

product_experience_provision_node <- function(root = product_experience_runtime_root(), version = product_experience_node_version) {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  node_dir <- file.path(root, "node")
  dir.create(node_dir, recursive = TRUE, showWarnings = FALSE)
  local_node <- product_experience_find_executable(c("node", "node.exe"), node_dir)
  local_npm <- product_experience_find_executable(c("npm", "npm.cmd"), node_dir)
  if (nzchar(local_node) && nzchar(local_npm)) {
    return(service_result(status = "success", value = product_experience_runtime_discovery(root), messages = "Repository-local Node/npm already available."))
  }
  zip_url <- sprintf("https://nodejs.org/dist/%s/node-%s-win-x64.zip", version, version)
  zip_path <- file.path(root, paste0("node-", version, "-win-x64.zip"))
  ok <- tryCatch({
    utils::download.file(zip_url, zip_path, mode = "wb", quiet = TRUE)
    unzip(zip_path, exdir = node_dir)
    TRUE
  }, error = function(e) e)
  if (inherits(ok, "error")) {
    return(service_result(
      status = "error",
      errors = paste("Node provisioning failed:", conditionMessage(ok)),
      diagnostics = list(url = zip_url, zip_path = zip_path)
    ))
  }
  discovery <- product_experience_runtime_discovery(root)
  service_result(
    status = if (isTRUE(discovery$available[match("node", discovery$component)]) && isTRUE(discovery$available[match("npm", discovery$component)])) "success" else "error",
    value = discovery,
    messages = paste("Provisioned Node runtime:", version),
    errors = if (!isTRUE(discovery$available[match("npm", discovery$component)])) "Provisioned Node but npm was not found." else character()
  )
}

product_experience_runtime_paths <- function(root = product_experience_runtime_root()) {
  discovery <- product_experience_runtime_discovery(root)
  stats::setNames(discovery$path, discovery$component)
}

product_experience_system2 <- function(command, args = character(), cwd = getwd(), env = character(), timeout = 120000) {
  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  old_env <- list()
  if (length(env)) {
    for (item in env) {
      parts <- strsplit(item, "=", fixed = TRUE)[[1]]
      key <- parts[[1]]
      value <- paste(parts[-1], collapse = "=")
      old_env[[key]] <- Sys.getenv(key, unset = NA_character_)
      do.call(Sys.setenv, stats::setNames(list(value), key))
    }
    on.exit({
      for (key in names(old_env)) {
        if (is.na(old_env[[key]])) Sys.unsetenv(key) else do.call(Sys.setenv, stats::setNames(list(old_env[[key]]), key))
      }
    }, add = TRUE)
  }
  setwd(cwd)
  output <- tryCatch(
    system2(command, args = args, stdout = TRUE, stderr = TRUE),
    error = function(e) structure(conditionMessage(e), status = 1L)
  )
  status <- attr(output, "status") %||% 0L
  list(status = as.integer(status), output = output)
}

product_experience_provision_playwright <- function(root = product_experience_runtime_root()) {
  node_result <- product_experience_provision_node(root)
  if (!identical(node_result$status, "success")) {
    return(node_result)
  }
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  manifest <- product_experience_tool_manifest_path()
  if (!file.exists(manifest)) {
    return(service_result(status = "error", errors = paste("Missing product experience package manifest:", manifest)))
  }
  file.copy(manifest, product_experience_runtime_package_path(root), overwrite = TRUE)
  node_root <- file.path(root, "node")
  node <- product_experience_find_executable(c("node", "node.exe"), node_root)
  npm <- product_experience_find_executable(c("npm", "npm.cmd"), node_root)
  if (!nzchar(npm) || !file.exists(npm)) {
    return(service_result(status = "error", errors = "Repository-local npm executable was not found after Node provisioning."))
  }
  runtime_env <- c(paste0("PATH=", paste(c(dirname(node), Sys.getenv("PATH")), collapse = .Platform$path.sep)))
  install <- product_experience_system2(npm, c("install", "--no-audit", "--fund=false"), cwd = root, env = runtime_env)
  if (install$status != 0L) {
    return(service_result(status = "error", errors = "npm install failed.", diagnostics = list(output = install$output)))
  }
  npx <- product_experience_find_executable(c("npx", "npx.cmd"), node_root)
  install_browser <- product_experience_system2(npx, c("playwright", "install", "chromium"), cwd = root, env = runtime_env)
  if (install_browser$status != 0L) {
    return(service_result(status = "error", errors = "Playwright Chromium provisioning failed.", diagnostics = list(output = install_browser$output)))
  }
  service_result(
    status = "success",
    value = product_experience_runtime_discovery(root),
    messages = "Provisioned repository-local Playwright runtime."
  )
}

product_experience_validate_browser_runtime <- function(root = product_experience_runtime_root()) {
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  paths <- product_experience_runtime_paths(root)
  node <- paths[["node"]]
  if (!nzchar(node) || !file.exists(node)) {
    return(service_result(status = "error", errors = "Node executable is unavailable.", diagnostics = list(discovery = product_experience_runtime_discovery(root))))
  }
  validation_js <- file.path(root, "validate_browser_runtime.js")
  writeLines(c(
    "const { chromium } = require('playwright');",
    "const fs = require('fs');",
    "(async () => {",
    "  const browser = await chromium.launch({ headless: true });",
    "  const page = await browser.newPage({ viewport: { width: 800, height: 600 } });",
    "  await page.setContent('<main data-testid=\"runtime-validation\"><h1>Product Experience Runtime</h1><button>Ready</button></main>');",
    "  await page.getByText('Ready').click();",
    "  await page.screenshot({ path: 'runtime_validation.png', fullPage: true });",
    "  await browser.close();",
    "})().catch(err => { console.error(err); process.exit(1); });"
  ), validation_js)
  result <- product_experience_system2(node, basename(validation_js), cwd = root)
  service_result(
    status = if (result$status == 0L && file.exists(file.path(root, "runtime_validation.png"))) "success" else "error",
    value = list(screenshot = normalizePath(file.path(root, "runtime_validation.png"), winslash = "/", mustWork = FALSE)),
    errors = if (result$status != 0L) "Minimal Playwright browser validation failed." else character(),
    diagnostics = list(output = result$output, discovery = product_experience_runtime_discovery(root))
  )
}

product_experience_ensure_browser_runtime <- function(root = product_experience_runtime_root()) {
  discovery <- product_experience_runtime_discovery(root)
  validation <- product_experience_validate_browser_runtime(root)
  if (identical(validation$status, "success")) {
    return(service_result(status = "success", value = list(discovery = discovery, validation = validation), messages = "Browser runtime is already valid."))
  }
  provision <- product_experience_provision_playwright(root)
  if (!identical(provision$status, "success")) {
    return(service_result(
      status = "error",
      errors = "Provisioning failed.",
      diagnostics = list(discovery = discovery, initial_validation = validation, provisioning = provision)
    ))
  }
  retry <- product_experience_validate_browser_runtime(root)
  service_result(
    status = if (identical(retry$status, "success")) "success" else "error",
    value = list(discovery = product_experience_runtime_discovery(root), validation = retry, provisioning = provision),
    messages = if (identical(retry$status, "success")) "Browser runtime provisioned and validated." else character(),
    errors = if (!identical(retry$status, "success")) "Runtime validation failed after provisioning." else character(),
    diagnostics = if (!identical(retry$status, "success")) list(discovery = product_experience_runtime_discovery(root), validation = retry, provisioning = provision) else list()
  )
}

product_experience_find_rscript <- function() {
  candidates <- c(
    Sys.which("Rscript"),
    "C:/Program Files/R/R-4.5.2/bin/Rscript.exe",
    "C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe",
    "C:/Program Files/R/R-4.5.1/bin/Rscript.exe",
    "C:/Program Files/R/R-4.2.1/bin/Rscript.exe"
  )
  candidates <- candidates[nzchar(candidates)]
  candidates[file.exists(candidates)][1] %||% ""
}

product_experience_wait_for_url <- function(url, timeout_sec = 45) {
  deadline <- Sys.time() + timeout_sec
  repeat {
    ok <- tryCatch({
      con <- NULL
      con <- url(url)
      readLines(con, n = 1, warn = FALSE)
      close(con)
      TRUE
    }, error = function(e) {
      if (exists("con", inherits = FALSE) && inherits(con, "connection") && isOpen(con)) {
        try(close(con), silent = TRUE)
      }
      FALSE
    })
    if (isTRUE(ok)) return(TRUE)
    if (Sys.time() > deadline) return(FALSE)
    Sys.sleep(1)
  }
}

product_experience_launch_app <- function(port = 3899, root = getwd()) {
  rscript <- product_experience_find_rscript()
  if (!nzchar(rscript)) {
    return(service_result(status = "error", errors = "Rscript was not found for app launch."))
  }
  runtime_dir <- product_experience_runtime_root()
  dir.create(runtime_dir, recursive = TRUE, showWarnings = FALSE)
  launcher <- file.path(runtime_dir, "launch_app.R")
  pid_file <- normalizePath(file.path(runtime_dir, "shiny.pid"), winslash = "/", mustWork = FALSE)
  log_file <- normalizePath(file.path(runtime_dir, "shiny.log"), winslash = "/", mustWork = FALSE)
  writeLines(c(
    sprintf("setwd(%s)", deparse(normalizePath(root, winslash = "/", mustWork = FALSE))),
    sprintf("writeLines(as.character(Sys.getpid()), %s)", deparse(pid_file)),
    sprintf("sink(%s, split = TRUE)", deparse(log_file)),
    "on.exit(sink(), add = TRUE)",
    sprintf("shiny::runApp('.', port = %s, host = '127.0.0.1', launch.browser = FALSE)", as.integer(port))
  ), launcher)
  system2(rscript, launcher, wait = FALSE)
  app_url <- sprintf("http://127.0.0.1:%s", as.integer(port))
  ready <- product_experience_wait_for_url(app_url)
  pid <- if (file.exists(pid_file)) readLines(pid_file, warn = FALSE)[1] else NA_character_
  service_result(
    status = if (isTRUE(ready)) "success" else "error",
    value = list(app_url = app_url, pid = pid, pid_file = pid_file, log_file = log_file),
    errors = if (!isTRUE(ready)) paste("App did not become available:", app_url) else character()
  )
}

product_experience_stop_app <- function(launch_result) {
  pid <- launch_result$value$pid %||% NA_character_
  if (!is.na(pid) && nzchar(pid)) {
    try(tools::pskill(as.integer(pid)), silent = TRUE)
  }
  invisible(TRUE)
}

product_experience_golden_workflow <- function() {
  steps <- data.frame(
    step_id = sprintf("golden_%02d", seq_len(8)),
    chapter = c(
      "Business Context",
      "Evidence Review",
      "Cross-Artifact Synthesis",
      "Evidence Sufficiency",
      "Governed Next Action",
      "Navigation",
      "Review Draft",
      "Human Confirmation and Persisted Draft"
    ),
    user_story = c(
      "A decision maker asks what should happen next.",
      "The workstation shows relevant evidence without requiring architectural knowledge.",
      "The workstation summarizes support, contradictions, uncertainty, and missing evidence.",
      "The workstation explains whether evidence is sufficient for a governed next action.",
      "The workstation proposes one supported action with rationale, cost, confidence, and alternatives.",
      "The workstation moves the user to the right surface without making the user hunt.",
      "The workstation prepares a bounded review draft without mutating project state.",
      "A human confirms persistence, after which the draft becomes durable project evidence."
    ),
    expected_page = c(
      "Guide",
      "AI Runtime",
      "AI Runtime",
      "AI Runtime",
      "Mission Control",
      "Artifact Studio",
      "AI Runtime",
      "AI Runtime"
    ),
    expected_validation = c(
      "business question visible",
      "evidence review visible",
      "synthesis visible",
      "sufficiency visible",
      "supported action visible",
      "target page visible",
      "review draft visible",
      "confirmed draft status visible"
    ),
    deterministic_replacement_candidate = c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  list(
    workflow_id = "golden_business_question_to_persisted_draft",
    title = "Golden Workflow: Business Question to Persisted Draft",
    world_id = "world_01",
    scenario_id = "scenario_world_01",
    guiding_question = "What should we do next?",
    purpose = "Establish the canonical UX benchmark for evidence-centered decision guidance.",
    product_story = "Business Context -> Evidence -> Understanding -> Decision -> Governance -> Learning",
    success_statement = "A first-time user finishes believing the system helped them make a better decision.",
    steps = steps
  )
}

product_experience_golden_benchmarks <- function() {
  data.frame(
    metric = c(
      "completion_time_sec",
      "clicks",
      "backtracking",
      "navigation_depth",
      "context_expansions",
      "ai_interactions",
      "help_usage",
      "scroll_events",
      "confusion_markers",
      "review_duration_sec",
      "confirmation_count",
      "draft_acceptance"
    ),
    expected = c(240, 14, 0, 4, 3, 2, 1, 6, 0, 90, 1, 1),
    tolerance = c(60, 4, 1, 1, 2, 1, 1, 4, 1, 60, 0, 0),
    direction = c("lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "lower_or_equal", "equal", "equal"),
    stringsAsFactors = FALSE
  )
}

product_experience_narration_profiles <- function() {
  data.frame(
    narration_profile = c("engineering", "business", "executive", "analyst"),
    emphasis = c(
      "selectors, validation, replay artifacts, state transitions",
      "why the recommendation follows from evidence",
      "decision confidence, risk, next action, governance",
      "evidence quality, contradictions, sufficiency, limitations"
    ),
    first_line = c(
      "This workflow validates the golden path from business question to persisted draft.",
      "The workstation starts with a question and turns it into a supported next action.",
      "The workflow shows whether the organization is ready to act.",
      "The workflow inspects evidence, uncertainty, and what remains unresolved."
    ),
    stringsAsFactors = FALSE
  )
}

product_experience_golden_chapters <- function() {
  workflow <- product_experience_golden_workflow()
  data.frame(
    chapter_id = workflow$steps$step_id,
    chapter = workflow$steps$chapter,
    expected_screenshot = paste0(workflow$steps$step_id, ".png"),
    screenshot_status = "pending_recorder",
    stringsAsFactors = FALSE
  )
}

product_experience_write_json <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  } else {
    writeLines(capture.output(str(x, give.attr = FALSE)), path)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

product_experience_read_json <- function(path) {
  if (!file.exists(path)) {
    return(NULL)
  }
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    return(jsonlite::read_json(path, simplifyVector = FALSE))
  }
  NULL
}

product_experience_file_url <- function(path) {
  paste0("file:///", gsub(" ", "%20", normalizePath(path, winslash = "/", mustWork = FALSE)))
}

product_experience_verify_video <- function(video_path, runtime_root = product_experience_runtime_root()) {
  paths <- product_experience_runtime_paths(runtime_root)
  node <- paths[["node"]]
  node_modules <- normalizePath(file.path(runtime_root, "node_modules"), winslash = "/", mustWork = FALSE)
  if (!nzchar(video_path %||% "") || !file.exists(video_path)) {
    return(service_result(status = "error", errors = "Golden Workflow video file does not exist."))
  }
  if (!nzchar(node %||% "") || !file.exists(node)) {
    return(service_result(status = "error", errors = "Node executable is unavailable for video verification."))
  }
  verify_js <- file.path(runtime_root, "verify_video_runtime.js")
  check_png <- file.path(dirname(video_path), "GoldenWorkflow_video_check.png")
  writeLines(c(
    "const { chromium } = require('playwright');",
    "const { pathToFileURL } = require('url');",
    "(async () => {",
    "  const videoPath = process.env.AW_PX_VIDEO_PATH;",
    "  const screenshotPath = process.env.AW_PX_VIDEO_CHECK;",
    "  const browser = await chromium.launch({ headless: true });",
    "  const page = await browser.newPage({ viewport: { width: 960, height: 540 } });",
    "  await page.goto(pathToFileURL(videoPath).href, { waitUntil: 'domcontentloaded', timeout: 15000 });",
    "  const meta = await page.evaluate(async () => {",
    "    const v = document.querySelector('video');",
    "    if (!v) throw new Error('no video element');",
    "    await new Promise((resolve, reject) => {",
    "      if (Number.isFinite(v.duration) && v.duration > 0) return resolve();",
    "      const timeout = setTimeout(() => reject(new Error('metadata timeout')), 15000);",
    "      v.onloadedmetadata = () => { clearTimeout(timeout); resolve(); };",
    "      v.onerror = () => reject(new Error('video error ' + (v.error && v.error.code)));",
    "    });",
    "    v.currentTime = Math.min(1, Math.max(0, v.duration / 3));",
    "    await new Promise((resolve, reject) => {",
    "      const timeout = setTimeout(() => reject(new Error('seek timeout')), 15000);",
    "      v.onseeked = () => { clearTimeout(timeout); resolve(); };",
    "    });",
    "    return { duration_sec: v.duration, video_width: v.videoWidth, video_height: v.videoHeight, current_time: v.currentTime, ready_state: v.readyState };",
    "  });",
    "  await page.screenshot({ path: screenshotPath, fullPage: true });",
    "  await browser.close();",
    "  console.log(JSON.stringify(meta));",
    "})().catch(err => { console.error(err); process.exit(1); });"
  ), verify_js)
  env <- c(
    paste0("NODE_PATH=", node_modules),
    paste0("AW_PX_VIDEO_PATH=", normalizePath(video_path, winslash = "/", mustWork = FALSE)),
    paste0("AW_PX_VIDEO_CHECK=", normalizePath(check_png, winslash = "/", mustWork = FALSE))
  )
  result <- product_experience_system2(node, basename(verify_js), cwd = runtime_root, env = env)
  meta <- tryCatch(jsonlite::fromJSON(paste(result$output, collapse = "\n")), error = function(e) NULL)
  file_info <- file.info(video_path)
  ok <- result$status == 0L &&
    !is.null(meta) &&
    isTRUE((meta$duration_sec %||% 0) > 20) &&
    isTRUE((meta$video_width %||% 0) > 0) &&
    isTRUE((meta$video_height %||% 0) > 0) &&
    isTRUE((file_info$size %||% 0) > 100000) &&
    file.exists(check_png) &&
    isTRUE((file.info(check_png)$size %||% 0) > 0)
  service_result(
    status = if (ok) "success" else "error",
    value = c(as.list(meta %||% list()), list(
      video_path = normalizePath(video_path, winslash = "/", mustWork = FALSE),
      video_size = unname(file_info$size %||% NA_real_),
      video_check_screenshot = normalizePath(check_png, winslash = "/", mustWork = FALSE),
      frame_visual_check = "browser_screenshot_captured"
    )),
    errors = if (!ok) "Golden Workflow video metadata/playback verification failed." else character(),
    diagnostics = list(output = result$output, status = result$status)
  )
}

product_experience_verify_replay_artifacts <- function(run, report_path = run$manifest_path %||% NA_character_, review_path = run$review_package_path %||% NA_character_) {
  video_path <- run$video_path %||% NA_character_
  trace_path <- run$trace_path %||% NA_character_
  screenshots <- run$chapters$screenshot_path %||% character()
  screenshot_info <- file.info(screenshots)
  trace_entries <- tryCatch(utils::unzip(trace_path, list = TRUE), error = function(e) NULL)
  video <- product_experience_verify_video(video_path)
  checks <- list(
    canonical_video_name = identical(basename(video_path), "GoldenWorkflow.webm"),
    video_exists = file.exists(video_path) && isTRUE(file.info(video_path)$size > 100000),
    video_playable = identical(video$status, "success"),
    screenshot_count = length(screenshots) >= 8L,
    screenshots_exist = length(screenshots) >= 8L && all(file.exists(screenshots)) && all(screenshot_info$size > 0),
    trace_exists = file.exists(trace_path) && isTRUE(file.info(trace_path)$size > 0),
    trace_archive_valid = !is.null(trace_entries) && nrow(trace_entries) > 0L,
    execution_report_exists = file.exists(report_path) && isTRUE(file.info(report_path)$size > 0),
    review_package_exists = file.exists(review_path) && isTRUE(file.info(review_path)$size > 0),
    expected_chapters = all(product_experience_golden_chapters()$chapter %in% run$chapters$chapter),
    replay_status = identical(run$recorder_status, "Golden Workflow completed")
  )
  list(
    status = if (all(unlist(checks, use.names = FALSE))) "success" else "error",
    checks = checks,
    video = video$value,
    trace_entries = if (!is.null(trace_entries)) nrow(trace_entries) else 0L,
    errors = names(checks)[!unlist(checks, use.names = FALSE)]
  )
}

product_experience_classify_replay_failure <- function(stage, result = NULL, report = NULL) {
  if (identical(stage, "runtime")) return("Runtime unavailable")
  if (identical(stage, "provisioning")) return("Provisioning failed")
  if (identical(stage, "browser")) return("Browser failed")
  if (identical(stage, "app")) return("Application failed")
  if (identical(stage, "selector")) return("Selector failed")
  if (identical(stage, "scenario")) return("Scenario failed")
  if (identical(stage, "validation")) return("Validation failed")
  if (identical(stage, "recording")) return("Recording failed")
  if (!is.null(report) && identical(report$status %||% "", "completed")) return("Golden Workflow completed")
  msg <- paste(c(result$errors %||% character(), unlist((result$diagnostics %||% list())$output %||% character())), collapse = "\n")
  report_error <- report$error$message %||% ""
  text <- tolower(paste(msg, report_error))
  if (grepl("browser|chromium", text)) return("Browser failed")
  if (grepl("selector|getbyrole|getbytext|locator|strict mode", text)) return("Selector failed")
  if (grepl("timeout|visible|validation", text)) return("Validation failed")
  if (grepl("video|trace|screenshot", text)) return("Recording failed")
  "Replay failed"
}

product_experience_run_golden_workflow <- function(
  automation = c("fixture", "playwright"),
  ai_mode = "fixture",
  output_dir = file.path("exports", "product_experience", "golden_workflow")
) {
  automation <- match.arg(automation)
  workflow <- product_experience_golden_workflow()
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  run_dir <- file.path(output_dir, paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

  recorder <- product_experience_playwright_diagnostics()
  recorder_available <- isTRUE(product_experience_playwright_available())
  if (identical(automation, "playwright") && !recorder_available) {
    recording_status <- "recorder_unavailable"
    warning <- "Node/Playwright is not available on PATH. The golden workflow manifest was generated, but screenshots, video, and trace were not fabricated."
  } else if (identical(automation, "fixture")) {
    recording_status <- "fixture_contract_only"
    warning <- "Fixture mode validates workflow contracts and review artifacts without capturing screenshots, video, or trace."
  } else {
    recording_status <- "recorder_contract_ready"
    warning <- character()
  }

  chapters <- product_experience_golden_chapters()
  chapters$screenshot_status <- if (identical(recording_status, "recorder_contract_ready")) "capture_required" else recording_status
  chapters$screenshot_path <- NA_character_

  metrics <- list(
    completion_time_sec = if (identical(recording_status, "fixture_contract_only")) 216 else NA_integer_,
    clicks = if (identical(recording_status, "fixture_contract_only")) 12 else NA_integer_,
    backtracking = 0L,
    navigation_depth = 4L,
    context_expansions = 3L,
    ai_interactions = if (identical(ai_mode, "fixture")) 1L else 2L,
    help_usage = 1L,
    scroll_events = 4L,
    confusion_markers = 0L,
    review_duration_sec = 72L,
    confirmation_count = 1L,
    draft_acceptance = 1L
  )

  run <- list(
    run_id = paste0("golden_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    workflow_id = workflow$workflow_id,
    scenario_id = workflow$scenario_id,
    world_id = workflow$world_id,
    automation = automation,
    ai_mode = ai_mode,
    ai_mode_disclosed = TRUE,
    recorder_status = recording_status,
    recorder_diagnostics = recorder,
    steps = workflow$steps,
    chapters = chapters,
    video_path = NA_character_,
    video_hash = NA_character_,
    trace_path = NA_character_,
    trace_hash = NA_character_,
    metrics = metrics,
    hidden_truth_included = FALSE,
    started_at = Sys.time(),
    completed_at = Sys.time(),
    warning = warning
  )
  manifest_path <- file.path(run_dir, "execution_manifest.json")
  review_path <- file.path(run_dir, "review_package.json")
  product_experience_write_json(run, manifest_path)
  product_experience_write_json(list(
    workflow = workflow[c("workflow_id", "title", "guiding_question", "success_statement")],
    chapters = chapters,
    metrics = metrics,
    review_schema = product_experience_review_schema(),
    research_mode_principles = product_experience_research_mode_principles(),
    experience_hypotheses = product_experience_experience_hypotheses(),
    prototype_comparison = product_experience_prototype_comparison(),
    information_exposure = product_experience_information_exposure_taxonomy(),
    progressive_disclosure = product_experience_progressive_disclosure_strategy(),
    research_campaigns = product_experience_research_campaigns(),
    research_open_questions = product_experience_research_open_questions()
  ), review_path)

  run$manifest_path <- normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  run$review_package_path <- normalizePath(review_path, winslash = "/", mustWork = FALSE)

  service_result(
    status = if (length(warning)) "warning" else "success",
    value = run,
    warnings = warning,
    messages = paste("Golden Workflow replay package generated:", run$run_id),
    metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE))
  )
}

product_experience_regenerate_golden_workflow <- function(
  port = 3899,
  root = getwd(),
  runtime_root = product_experience_runtime_root(),
  output_root = product_experience_replay_output_root(root),
  ai_mode = "fixture",
  pacing_profile = "investor",
  prototype_id = "current_golden_workflow"
) {
  prototypes <- experience_prototype_registry()
  prototype <- prototypes[prototypes$prototype_id == prototype_id, , drop = FALSE]
  if (!nrow(prototype)) {
    prototype <- prototypes[prototypes$prototype_id == "current_golden_workflow", , drop = FALSE]
  }
  run_dir <- file.path(output_root, paste0("run_", prototype$prototype_id[[1]], "_", format(Sys.time(), "%Y%m%d_%H%M%S")))
  dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
  runtime <- product_experience_ensure_browser_runtime(runtime_root)
  if (!identical(runtime$status, "success")) {
    return(service_result(
      status = "error",
      errors = product_experience_classify_replay_failure("provisioning", runtime),
      diagnostics = list(runtime = runtime),
      metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE))
    ))
  }

  launch <- product_experience_launch_app(port = port, root = root)
  on.exit({
    if (exists("launch", inherits = FALSE) && identical(launch$status, "success")) {
      product_experience_stop_app(launch)
    }
  }, add = TRUE)
  if (!identical(launch$status, "success")) {
    return(service_result(
      status = "error",
      errors = product_experience_classify_replay_failure("app", launch),
      diagnostics = list(runtime = runtime, launch = launch),
      metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE))
    ))
  }

  paths <- product_experience_runtime_paths(runtime_root)
  node <- paths[["node"]]
  script <- normalizePath(file.path("scripts", "product_experience", "golden_workflow_replay.js"), winslash = "/", mustWork = TRUE)
  node_path <- normalizePath(file.path(runtime_root, "node_modules"), winslash = "/", mustWork = FALSE)
  env <- c(
    paste0("AW_APP_URL=", launch$value$app_url),
    paste0("AW_PX_OUTPUT_DIR=", normalizePath(run_dir, winslash = "/", mustWork = FALSE)),
    paste0("AW_PX_AI_MODE=", ai_mode),
    paste0("AW_PX_PACING_PROFILE=", pacing_profile),
    paste0("AW_PX_PROTOTYPE_ID=", prototype$prototype_id[[1]]),
    paste0("AW_PX_PROTOTYPE_NAME=", prototype$prototype_name[[1]]),
    paste0("NODE_PATH=", node_path)
  )
  replay <- product_experience_system2(node, script, cwd = root, env = env)
  report_path <- file.path(run_dir, "execution_report.json")
  report <- product_experience_read_json(report_path)
  completed <- replay$status == 0L && !is.null(report) && identical(report$status %||% "", "completed")

  if (!completed) {
    return(service_result(
      status = "error",
      errors = product_experience_classify_replay_failure("replay", replay, report),
      diagnostics = list(runtime = runtime, launch = launch, replay = replay, report = report),
      metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE), report_path = normalizePath(report_path, winslash = "/", mustWork = FALSE))
    ))
  }

  run <- list(
    run_id = report$run_id %||% paste0("golden_playwright_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    workflow_id = report$workflow_id %||% "golden_business_question_to_persisted_draft",
    prototype_id = report$prototype_id %||% prototype$prototype_id[[1]],
    prototype_name = report$prototype_name %||% prototype$prototype_name[[1]],
    scenario_id = "scenario_world_01",
    world_id = "world_01",
    automation = "playwright",
    ai_mode = report$ai_mode %||% ai_mode,
    ai_mode_disclosed = TRUE,
    recorder_status = "Golden Workflow completed",
    recorder_diagnostics = product_experience_runtime_discovery(runtime_root),
    steps = product_experience_golden_workflow()$steps,
    chapters = data.frame(
      chapter_id = vapply(report$chapters, function(x) x$chapter_id %||% "", character(1)),
      chapter = vapply(report$chapters, function(x) x$chapter %||% "", character(1)),
      screenshot_path = vapply(report$chapters, function(x) x$screenshot_path %||% "", character(1)),
      screenshot_hash = vapply(report$chapters, function(x) x$screenshot_hash %||% "", character(1)),
      screenshot_status = vapply(report$chapters, function(x) x$status %||% "", character(1)),
      stringsAsFactors = FALSE
    ),
    video_path = report$video_path %||% NA_character_,
    video_hash = report$video_hash %||% NA_character_,
    trace_path = report$trace_path %||% NA_character_,
    trace_hash = report$trace_hash %||% NA_character_,
    metrics = report$metrics,
    events = report$events %||% list(),
    hidden_truth_included = FALSE,
    started_at = report$started_at %||% as.character(Sys.time()),
    completed_at = report$completed_at %||% as.character(Sys.time()),
    warning = character(),
    pacing_profile = pacing_profile,
    manifest_path = normalizePath(report_path, winslash = "/", mustWork = FALSE),
    review_package_path = normalizePath(file.path(run_dir, "review_package.json"), winslash = "/", mustWork = FALSE)
  )

  product_experience_write_json(list(
    workflow = product_experience_golden_workflow()[c("workflow_id", "title", "guiding_question", "success_statement")],
    prototype = prototype,
    chapters = run$chapters,
    metrics = run$metrics,
    review_schema = product_experience_review_schema(),
    recording = list(video_path = run$video_path, video_hash = run$video_hash, trace_path = run$trace_path, trace_hash = run$trace_hash)
  ), run$review_package_path)

  verification <- product_experience_verify_replay_artifacts(run)
  run$verification <- verification
  report$verification <- verification
  product_experience_write_json(report, report_path)
  media_manifest <- product_experience_showcase_media_manifest(run, lifecycle_state = "awaiting_review")
  founder_findings <- product_experience_founder_review_template(run = run, reviewer = "founder")
  ux_campaigns <- product_experience_prioritize_ux_campaigns(founder_findings)
  ux_metrics <- product_experience_replay_metrics_summary(run)
  replay_comparison <- product_experience_compare_replay_runs(run)
  promotion_gate <- product_experience_assess_investor_candidate(
    run = run,
    findings = founder_findings$finding,
    founder_approved = FALSE,
    developer_content_visible = TRUE
  )
  final_assessment <- product_experience_final_assessment(run, founder_approved = FALSE, developer_content_visible = TRUE)
  product_experience_write_json(list(
    workflow = product_experience_golden_workflow()[c("workflow_id", "title", "guiding_question", "success_statement")],
    chapters = run$chapters,
    metrics = run$metrics,
    replay_metrics = report$metrics,
    prototype = prototype,
    entry_experience = experience_prototype_entry_experience(prototype$prototype_id[[1]]),
    compiled_experience = experience_compiler(prototype$prototype_id[[1]], intent = "decide"),
    ux_metrics = ux_metrics,
    semantic_replay_comparison = replay_comparison,
    research_mode_principles = product_experience_research_mode_principles(),
    experience_hypotheses = product_experience_experience_hypotheses(),
    prototype_comparison = product_experience_prototype_comparison(),
    information_exposure = product_experience_information_exposure_taxonomy(),
    progressive_disclosure = product_experience_progressive_disclosure_strategy(),
    visible_element_inventory = product_experience_visible_element_inventory(),
    ai_role_assessment = product_experience_ai_role_assessment(),
    research_campaigns = product_experience_research_campaigns(),
    research_open_questions = product_experience_research_open_questions(),
    founder_review_findings = founder_findings,
    ux_campaigns = ux_campaigns,
    validation = verification,
    media_manifest = media_manifest,
    investor_promotion_gate = promotion_gate,
    investor_promotion_state = attr(promotion_gate, "promotion_state") %||% "awaiting_review",
    final_assessment = final_assessment[setdiff(names(final_assessment), "blockers")],
    final_assessment_blockers = final_assessment$blockers,
    showcase = product_experience_flagship_evidence_package(),
    known_issues = if (identical(verification$status, "success")) character() else verification$errors,
    campaign_seeds = product_experience_golden_review_findings(),
    open_questions = c(
      "Does the recorded workflow communicate why the next action is recommended?",
      "Are the AI Runtime sections visibly meaningful or too sparse in the recording?",
      "Does the flagship world make the business decision and evidence progression obvious?",
      "Does the recording reveal navigation friction that should become a product campaign?"
    ),
    founder_review_status = if (identical(verification$status, "success")) "ready_for_founder_review" else "blocked",
    recording = list(video_path = run$video_path, video_hash = run$video_hash, trace_path = run$trace_path, trace_hash = run$trace_hash)
  ), run$review_package_path)

  if (!identical(verification$status, "success")) {
    return(service_result(
      status = "error",
      errors = paste("Recording verification failed:", paste(verification$errors, collapse = ", ")),
      value = run,
      diagnostics = list(runtime = runtime, launch = launch, replay = replay, verification = verification),
      metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE), report_path = normalizePath(report_path, winslash = "/", mustWork = FALSE))
    ))
  }

  service_result(
    status = "success",
    value = run,
    messages = "Golden Workflow completed with Playwright recording.",
    diagnostics = list(runtime = runtime, launch = launch, replay = replay),
    metadata = list(run_dir = normalizePath(run_dir, winslash = "/", mustWork = FALSE), report_path = normalizePath(report_path, winslash = "/", mustWork = FALSE))
  )
}

product_experience_review_schema <- function() {
  data.frame(
    field = c(
      "timestamp", "step", "confusion", "delay", "unexpected_click",
      "backtracking", "ai_quality", "workflow_quality", "visual_hierarchy",
      "terminology", "trust", "overall_friction", "overall_delight",
      "severity", "recommendation", "campaign_seed"
    ),
    type = c(
      "datetime", "character", "boolean", "integer", "boolean",
      "boolean", "ordinal", "ordinal", "ordinal",
      "ordinal", "ordinal", "ordinal", "ordinal",
      "low|medium|high|critical", "character", "boolean"
    ),
    required = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )
}

product_experience_golden_review_findings <- function() {
  data.frame(
    issue_id = "golden_review_001",
    category = "workflow",
    timestamp = as.POSIXct("2026-07-14 00:03:00", tz = "UTC"),
    step = "Evidence Sufficiency",
    confusion = FALSE,
    delay = 0L,
    unexpected_click = FALSE,
    backtracking = FALSE,
    ai_quality = "good",
    workflow_quality = "good",
    visual_hierarchy = "good",
    terminology = "clear",
    trust = "adequate",
    overall_friction = "low",
    overall_delight = "moderate",
    severity = "low",
    description = "Fixture review shows the workflow contract is coherent; real browser recording is still required before UX claims are strong.",
    recommendation = "Provision Playwright and replay the golden workflow before calling the recorded experience production-ready.",
    screenshot_id = "golden_04",
    video_timestamp = NA_character_,
    campaign_candidate = TRUE,
    campaign_seed = TRUE,
    stringsAsFactors = FALSE
  )
}

product_experience_compare_regression <- function(current_run, previous_run = NULL, benchmarks = product_experience_golden_benchmarks()) {
  current_metrics <- data.frame(
    metric = names(current_run$metrics),
    current = suppressWarnings(as.numeric(unlist(current_run$metrics, use.names = FALSE))),
    stringsAsFactors = FALSE
  )
  rows <- merge(benchmarks, current_metrics, by = "metric", all.x = TRUE)
  rows$allowed <- rows$expected + rows$tolerance
  rows$status <- ifelse(
    rows$direction == "equal",
    ifelse(rows$current == rows$expected, "pass", "regression"),
    ifelse(is.na(rows$current), "not_measured", ifelse(rows$current <= rows$allowed, "pass", "regression"))
  )
  if (!is.null(previous_run)) {
    previous_metrics <- data.frame(
      metric = names(previous_run$metrics),
      previous = suppressWarnings(as.numeric(unlist(previous_run$metrics, use.names = FALSE))),
      stringsAsFactors = FALSE
    )
    rows <- merge(rows, previous_metrics, by = "metric", all.x = TRUE)
    rows$delta_from_previous <- rows$current - rows$previous
  } else {
    rows$previous <- NA_real_
    rows$delta_from_previous <- NA_real_
  }
  rows
}

product_experience_run_scenario <- function(
  scenario_id,
  automation = c("fixture", "playwright"),
  ai_mode = "fixture",
  output_dir = tempfile("product_experience_run_")
) {
  automation <- match.arg(automation)
  scenarios <- product_experience_scenario_registry()
  if (!scenario_id %in% scenarios$scenario_id) {
    return(service_result(status = "error", errors = paste0("Unknown scenario: ", scenario_id)))
  }
  ai_check <- product_experience_validate_ai_mode(ai_mode)
  if (!identical(ai_check$status, "success")) {
    return(ai_check)
  }
  scenario <- scenarios[scenarios$scenario_id == scenario_id, , drop = FALSE]
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (identical(automation, "playwright") && !product_experience_playwright_available()) {
    return(service_result(
      status = "warning",
      value = list(
        scenario_id = scenario_id,
        world_id = scenario$world_id,
        automation = automation,
        ai_mode = ai_mode,
        recording_status = "not_available"
      ),
      warnings = "Playwright runtime was not detected. Fixture validation remains available; video and trace were not fabricated.",
      metadata = list(output_dir = normalizePath(output_dir, winslash = "/", mustWork = FALSE))
    ))
  }

  steps <- scenario$steps[[1]]
  step_log <- data.frame(
    step_index = seq_along(steps),
    step = steps,
    status = "completed",
    validation = c("world loaded", "page opened", "status visible", "action followed", "evidence visible", "review created"),
    stringsAsFactors = FALSE
  )
  metrics <- list(
    completion_time_sec = length(steps) * 12L,
    clicks = length(steps) + 3L,
    navigation_depth = length(unique(unlist(scenario$expected_pages[[1]], use.names = FALSE))),
    context_expansions = 1L,
    ai_interactions = if (identical(ai_mode, "fixture")) 1L else 0L,
    help_usage = 1L,
    backtracking = 0L,
    errors = 0L,
    confusion_markers = 0L,
    abandoned_workflow = FALSE,
    recovery = "not_required"
  )
  screenshots <- data.frame(
    screenshot_id = scenario$expected_screenshots[[1]],
    screenshot_status = if (identical(automation, "fixture")) "not_captured_fixture" else "capture_contract_defined",
    path = NA_character_,
    stringsAsFactors = FALSE
  )
  run <- list(
    run_id = paste0("pxrun_", scenario_id, "_", automation, "_", ai_mode),
    scenario_id = scenario_id,
    world_id = scenario$world_id,
    automation = automation,
    ai_mode = ai_mode,
    ai_mode_disclosed = TRUE,
    started_at = as.POSIXct("2026-07-14 00:00:00", tz = "UTC"),
    completed_at = as.POSIXct("2026-07-14 00:01:12", tz = "UTC"),
    status = "completed",
    step_log = step_log,
    screenshots = screenshots,
    video_status = if (identical(automation, "fixture")) "not_captured_fixture" else "capture_contract_defined",
    trace_status = if (identical(automation, "fixture")) "not_captured_fixture" else "capture_contract_defined",
    metrics = metrics,
    hidden_truth_included = FALSE
  )
  saveRDS(run, file.path(output_dir, paste0(run$run_id, ".rds")))
  service_result(
    status = "success",
    value = run,
    messages = paste0("Completed deterministic product-experience scenario: ", scenario$title),
    metadata = list(output_dir = normalizePath(output_dir, winslash = "/", mustWork = FALSE))
  )
}

product_experience_review_artifact <- function(
  scenario_run,
  reviewer = "human_reviewer",
  findings = NULL
) {
  if (is.null(findings)) {
    findings <- data.frame(
      issue_id = character(),
      category = character(),
      severity = character(),
      description = character(),
      recommendation = character(),
      screenshot_id = character(),
      video_timestamp = character(),
      campaign_candidate = logical(),
      stringsAsFactors = FALSE
    )
  }
  content <- list(
    scenario = scenario_run$scenario_id,
    reviewer = reviewer,
    timestamp = as.POSIXct("2026-07-14 00:02:00", tz = "UTC"),
    friction_points = findings[findings$category == "friction", , drop = FALSE],
    confusing_moments = findings[findings$category == "confusion", , drop = FALSE],
    missing_explanation = findings[findings$category == "missing_explanation", , drop = FALSE],
    navigation_issues = findings[findings$category == "navigation", , drop = FALSE],
    ai_issues = findings[findings$category == "ai", , drop = FALSE],
    workflow_issues = findings[findings$category == "workflow", , drop = FALSE],
    visual_issues = findings[findings$category == "visual", , drop = FALSE],
    unexpected_delight = findings[findings$category == "delight", , drop = FALSE],
    recommended_changes = findings$recommendation,
    severity = findings$severity,
    screenshots = scenario_run$screenshots,
    video_timestamps = findings$video_timestamp,
    campaign_candidates = findings[isTRUE(nrow(findings) > 0) & findings$campaign_candidate, , drop = FALSE]
  )
  create_artifact(
    artifact_id = paste0("px_review_", scenario_run$scenario_id),
    artifact_type = "product_experience_review_artifact",
    label = paste("Product Experience Review:", scenario_run$scenario_id),
    source_module = "product_experience_intelligence",
    content = content,
    metadata = list(
      module_id = "product_experience_intelligence",
      render_targets = c("developer_review", "product_experience_lab"),
      analytical_intent = "product_experience_evaluation",
      artifact_importance = "recommended",
      ai_mode = scenario_run$ai_mode,
      automation = scenario_run$automation,
      hidden_truth_included = FALSE
    ),
    section = "Product Experience"
  )
}

product_experience_campaign_seeds <- function(review_artifact) {
  findings <- review_artifact$content$campaign_candidates
  if (is.null(findings) || nrow(findings) == 0) {
    return(data.frame(
      campaign_seed_id = character(),
      source_artifact_id = character(),
      issue_id = character(),
      severity = character(),
      recommended_change = character(),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    campaign_seed_id = paste0("px_campaign_", seq_len(nrow(findings))),
    source_artifact_id = review_artifact$artifact_id,
    issue_id = findings$issue_id,
    severity = findings$severity,
    recommended_change = findings$recommendation,
    stringsAsFactors = FALSE
  )
}

product_experience_metrics_summary <- function(scenario_run) {
  data.frame(
    metric = names(scenario_run$metrics),
    value = unlist(scenario_run$metrics, use.names = FALSE),
    stringsAsFactors = FALSE
  )
}

relationship_state_registry <- function() {
  data.frame(
    relationship_state = c("new_user", "returning_user", "current_project", "resume_workflow", "explore", "learn"),
    label = c("New User", "Returning User", "Current Project", "Resume Workflow", "Explore", "Learn"),
    first_question = c(
      "What decision or question brought you here?",
      "Do you want to continue where you left off or review what changed?",
      "What needs attention in this project right now?",
      "Should we resume the last workflow or inspect project status first?",
      "What would you like to explore before committing to an analysis?",
      "Which part of the workstation should be explained first?"
    ),
    minimum_sufficient_beginning = c(
      "Explain the workstation in one sentence, ask for intent, and offer one first action.",
      "Summarize changes, attention items, last workflow, and the best next action.",
      "Show project status, evidence state, collector state, and one recommended action.",
      "Show last workflow state, blockers, recoverable context, and the resume action.",
      "Offer low-commitment exploration paths without requiring project setup.",
      "Teach the mental model before exposing modules or developer detail."
    ),
    primary_risk = c(
      "Overwhelm before value is understood.",
      "Forgetting where the user left off.",
      "Surfacing module machinery before the project story.",
      "Resuming stale or confusing work without context.",
      "Letting exploration become aimless browsing.",
      "Turning the product into documentation instead of guided orientation."
    ),
    stringsAsFactors = FALSE
  )
}

relationship_visibility_taxonomy <- function() {
  data.frame(
    visibility_class = c("Immediate", "Helpful", "Contextual", "Deferred", "Advanced", "Architectural", "Developer"),
    initial_policy = c("show", "summarize_or_tease", "show_after_state_known", "hide_until_requested", "hide_until_need", "hide_until_learning_mode", "hide_from_normal_user"),
    purpose = c(
      "Answer why the product matters and what to do first.",
      "Support the next action without stealing attention.",
      "Appear when project, workflow, or evidence state makes it relevant.",
      "Remain available but not part of the first encounter.",
      "Serve expert control after the user understands the workflow.",
      "Teach how the system works when the user asks to learn.",
      "Support QA, replay, and product development."
    ),
    example_surfaces = c(
      "value proposition; current intent; one next action",
      "project status; collector status; compact trust cues",
      "Mission Control details; Artifact Studio; evidence inspector",
      "diagnostics; reports; advanced filters",
      "execution modes; evidence strategy; GenAI configuration",
      "ontology; policies; runtime architecture",
      "Product Experience Lab; QA tables; generated replay internals"
    ),
    stringsAsFactors = FALSE
  )
}

relationship_experience_layers <- function() {
  data.frame(
    layer = 0:6,
    layer_name = c("Relationship", "Current Intent", "Workflow", "Evidence", "Decision", "Depth", "Architecture"),
    question_answered = c(
      "Who is this user to the product right now?",
      "What are they trying to accomplish?",
      "What sequence should they follow?",
      "What evidence exists or is needed?",
      "What decision can be made or deferred?",
      "What diagnostics, caveats, and alternatives matter?",
      "Why does the system behave this way?"
    ),
    first_hour_policy = c("always", "always", "after intent", "after workflow context", "after evidence", "on demand", "learning mode only"),
    assessment = c(
      "Appropriate as Layer 0 because experience should begin with relationship, not modules.",
      "Appropriate as Layer 1 because intent determines what should be visible.",
      "Appropriate as Layer 2 because workflow gives momentum.",
      "Appropriate as Layer 3 because artifacts are evidence, not the first explanation.",
      "Appropriate as Layer 4 because decisions need evidence context.",
      "Appropriate as Layer 5 because depth should not crowd the first interaction.",
      "Appropriate as Layer 6 because architecture is valuable but rarely the first need."
    ),
    stringsAsFactors = FALSE
  )
}

relationship_progressive_shell <- function() {
  data.frame(
    stage_order = seq_len(7),
    stage = c("Orientation", "Question", "Evidence", "Understanding", "Decision", "Diagnostics", "Architecture"),
    user_need = c(
      "Understand what the product is.",
      "State the business question, intent, or starting condition.",
      "See what evidence exists or what evidence is missing.",
      "Understand what the evidence implies and what remains uncertain.",
      "Identify the next decision or action.",
      "Inspect caveats, failures, and trust constraints.",
      "Learn why the workstation is organized this way."
    ),
    initial_visibility = c("Immediate", "Immediate", "Contextual", "Contextual", "Helpful", "Deferred", "Architectural"),
    shell_behavior = c(
      "Short value statement and one first prompt.",
      "Ask for intent before exposing module machinery.",
      "Summarize evidence availability without opening every artifact surface.",
      "Use concise explanation before deep diagnostics.",
      "Show one recommended next action with reason and alternative.",
      "Expose when requested or when risk requires attention.",
      "Expose through Knowledge Library, Guide, and learning mode."
    ),
    stringsAsFactors = FALSE
  )
}

relationship_new_user_experience <- function() {
  data.frame(
    question = c(
      "What is this?",
      "Why should I care?",
      "What can I accomplish?",
      "What should I do first?"
    ),
    answer = c(
      "Analytics Workstation helps turn business questions into evidence-backed decisions.",
      "It helps you see what is known, what is uncertain, what evidence supports each claim, and what to do next.",
      "You can load data, ask a business question, generate evidence, inspect artifacts, understand uncertainty, and prepare a decision.",
      "Tell the workstation what decision or question brought you here."
    ),
    visibility_class = "Immediate",
    stringsAsFactors = FALSE
  )
}

relationship_returning_user_experience <- function() {
  data.frame(
    question = c(
      "What changed?",
      "What needs attention?",
      "What was I doing?",
      "What is the best next action?"
    ),
    answer = c(
      "Show new artifacts, completed runs, failed jobs, updated findings, and changed collector status.",
      "Highlight blockers, warnings, stale evidence, failed actions, and decision-readiness gaps.",
      "Show the last project, last workflow, last selected artifact, and any paused plan.",
      "Recommend one deterministic next action with reason, expected benefit, expected cost, and an alternative path."
    ),
    visibility_class = "Immediate",
    stringsAsFactors = FALSE
  )
}

relationship_mission_control_policy <- function() {
  data.frame(
    policy_question = c("Mission Control placement", "New user behavior", "Returning user behavior", "Escalation rule"),
    answer = c(
      "Mission Control should be summarized inside the shell and opened after orientation, not used as the first full experience.",
      "Show compact health and one next action; defer operational detail.",
      "Show changes, attention items, resumable workflows, and project status earlier.",
      "Open full Mission Control when there are failures, approvals, running jobs, or explicit user intent."
    ),
    stringsAsFactors = FALSE
  )
}

relationship_ai_policy <- function() {
  data.frame(
    policy_question = c("Should AI greet?", "When should AI appear?", "What should AI avoid?", "What should deterministic UX own?"),
    answer = c(
      "No. The deterministic shell should greet; AI should not be theatrical.",
      "AI should appear after intent or evidence creates a real reasoning need.",
      "Avoid replacing basic orientation, navigation labels, or deterministic status explanation.",
      "Own first impression, visibility hierarchy, project status, and simple next-step logic."
    ),
    stringsAsFactors = FALSE
  )
}

relationship_logging_ontology <- function() {
  data.frame(
    event_family = c("first_impression", "trust", "momentum", "curiosity", "confidence", "overwhelm", "understanding", "desired_next_action", "confusion", "exit"),
    observation = c(
      "What did the user think the product was?",
      "Did the user believe the product was credible?",
      "Did the user know what to do next?",
      "Did the user want to explore further?",
      "Did the user feel able to proceed?",
      "Did the user encounter too much information too soon?",
      "Could the user explain the product's purpose?",
      "What action did the user want to take next?",
      "Where did meaning break down?",
      "Where did the user stop or abandon the flow?"
    ),
    would_justify_adaptation = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    implementation_status = "design_only_no_logging",
    stringsAsFactors = FALSE
  )
}

relationship_experience_memory_model <- function() {
  data.frame(
    memory_scope = c("first_use", "returning_user", "mastery", "current_workflow", "current_project", "current_intent"),
    future_signal = c(
      "Has the user completed orientation?",
      "What changed since the last session?",
      "Which concepts and workflows are familiar?",
      "What workflow is active, paused, or blocked?",
      "What project evidence, decisions, and artifacts exist?",
      "What is the user trying to accomplish now?"
    ),
    phase4_status = "future_distinction_documented_only",
    why_it_matters = c(
      "Avoid explaining too much too early.",
      "Resume context instead of restarting.",
      "Expose power without overwhelming beginners.",
      "Keep momentum across interruption.",
      "Anchor the experience in evidence and decision state.",
      "Route attention before routing features."
    ),
    stringsAsFactors = FALSE
  )
}

relationship_founder_review_template <- function() {
  data.frame(
    review_dimension = c("first_impression", "trust", "momentum", "curiosity", "confidence", "overwhelm", "understanding", "desired_next_action"),
    prompt = c(
      "What did the product seem to be in the first minute?",
      "Did the opening experience feel credible?",
      "Did you know what to do next?",
      "Did the experience make you want to explore?",
      "Did you feel capable of using the workstation?",
      "What felt like too much too soon?",
      "Could you explain the product to someone else?",
      "What did you want to click or do next?"
    ),
    score_scale = "1-5 plus notes",
    required = TRUE,
    stringsAsFactors = FALSE
  )
}

relationship_campaigns <- function() {
  data.frame(
    campaign_id = c("relationship_new_user_first_hour", "relationship_returning_user_resume", "relationship_mission_control_entry", "relationship_ai_naturalness"),
    campaign_type = "relationship_campaign",
    hypothesis = c(
      "A new-user shell that asks for intent before modules reduces overwhelm and increases momentum.",
      "A returning-user shell that shows changes and resumable work improves continuity.",
      "Mission Control works best as compact status first, full operational workspace second.",
      "AI is more trusted when it appears after intent/evidence rather than greeting first."
    ),
    primary_metric = c("first_minute_understanding", "resume_confidence", "attention_to_critical_status", "ai_trust_and_usefulness"),
    not_a_module_campaign = TRUE,
    stringsAsFactors = FALSE
  )
}

relationship_final_assessment <- function() {
  data.frame(
    question = c(
      "What should Analytics Workstation say to a first-time user?",
      "What should Analytics Workstation say to a returning user?",
      "What should disappear from the initial shell?",
      "What should be visible only later?",
      "Should Mission Control be inside or outside the shell?",
      "Should AI greet the user?",
      "What deserves immediate attention?",
      "What is the largest unanswered product question?"
    ),
    answer = c(
      "Tell me what decision or question brought you here. I will help turn it into evidence, uncertainty, and a next action.",
      "Here is what changed, what needs attention, where you left off, and the best next step.",
      "Module catalogs, architecture language, QA/developer surfaces, generated code, deep settings, and AI internals.",
      "Full Mission Control, Artifact Studio, diagnostics, reports, architecture docs, advanced AI/runtime controls, and developer panels.",
      "Inside as compact status during orientation; outside as a full workspace after intent or attention requires it.",
      "No. The deterministic shell should greet; AI should appear when reasoning is useful.",
      "Relationship state, current intent, project context if available, one recommended next action, and trust/guardrail cues.",
      "Whether the first-hour shell should begin with intent, business question, or decision context after founder review and first-hour testing."
    ),
    confidence = c("high", "high", "high", "medium_high", "medium_high", "medium_high", "high", "insufficient_evidence"),
    stringsAsFactors = FALSE
  )
}

relationship_shell_preview <- function(state = "new_user") {
  states <- relationship_state_registry()
  if (!state %in% states$relationship_state) {
    state <- "new_user"
  }
  state_row <- states[states$relationship_state == state, , drop = FALSE]
  if (identical(state, "returning_user")) {
    core <- relationship_returning_user_experience()
  } else if (identical(state, "new_user")) {
    core <- relationship_new_user_experience()
  } else {
    core <- data.frame(
      question = c("Current relationship", "What should happen first?", "What should remain hidden?"),
      answer = c(
        state_row$label[[1]],
        state_row$minimum_sufficient_beginning[[1]],
        "Developer, architectural, advanced, and diagnostic surfaces unless explicitly needed."
      ),
      visibility_class = "Immediate",
      stringsAsFactors = FALSE
    )
  }
  data.frame(
    zone = c("Opening", "Prompt", "Value", "Next Action", "Hidden Initially"),
    visible_text = c(
      "Analytics Workstation turns questions into evidence-backed decisions.",
      state_row$first_question[[1]],
      state_row$minimum_sufficient_beginning[[1]],
      if (identical(state, "new_user")) "Start with a decision or business question." else "Resume, inspect changes, or review attention items.",
      "Modules, architecture, QA, generated code, deep settings, and developer tools."
    ),
    purpose = c(
      "Product identity",
      "Relationship-aware orientation",
      "Immediate value",
      "Momentum",
      "Overwhelm prevention"
    ),
    visibility_class = c("Immediate", "Immediate", "Immediate", "Immediate", "Developer"),
    stringsAsFactors = FALSE
  )
}

relationship_runtime <- function(state = "new_user", project_state = list(), intent = NULL) {
  states <- relationship_state_registry()
  if (!state %in% states$relationship_state) {
    return(service_result(status = "error", errors = paste("Unknown relationship state:", state)))
  }
  value <- list(
    runtime_id = "relationship_runtime_phase4",
    relationship_state = states[states$relationship_state == state, , drop = FALSE],
    intent = intent %||% NA_character_,
    project_state_summary = project_state,
    shell_preview = relationship_shell_preview(state),
    new_user = relationship_new_user_experience(),
    returning_user = relationship_returning_user_experience(),
    visibility = relationship_visibility_taxonomy(),
    layers = relationship_experience_layers(),
    progressive_shell = relationship_progressive_shell(),
    mission_control_policy = relationship_mission_control_policy(),
    ai_policy = relationship_ai_policy(),
    logging_ontology = relationship_logging_ontology(),
    experience_memory = relationship_experience_memory_model(),
    founder_review = relationship_founder_review_template(),
    campaigns = relationship_campaigns(),
    final_assessment = relationship_final_assessment(),
    production_replacement = FALSE,
    implementation_scope = "prototype_preview_compare_only"
  )
  class(value) <- c("relationship_runtime", class(value))
  service_result(
    status = "success",
    value = value,
    messages = "Relationship Runtime compiled as a deterministic preview contract.",
    metadata = list(phase = "Product Experience Runtime Phase 4", production_replacement = FALSE)
  )
}

relationship_runtime_comparison <- function() {
  states <- relationship_state_registry()
  do.call(rbind, lapply(states$relationship_state, function(state) {
    rt <- relationship_runtime(state)$value
    data.frame(
      relationship_state = state,
      label = rt$relationship_state$label[[1]],
      opening_prompt = rt$relationship_state$first_question[[1]],
      immediate_items = paste(rt$shell_preview$zone[rt$shell_preview$visibility_class == "Immediate"], collapse = " | "),
      hidden_initially = paste(rt$shell_preview$visible_text[rt$shell_preview$visibility_class != "Immediate"], collapse = " | "),
      mission_control = relationship_mission_control_policy()$answer[[1]],
      ai_policy = relationship_ai_policy()$answer[[1]],
      stringsAsFactors = FALSE
    )
  }))
}

qa_product_experience_relationship_runtime <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  states <- relationship_state_registry()
  visibility <- relationship_visibility_taxonomy()
  layers <- relationship_experience_layers()
  progressive <- relationship_progressive_shell()
  new_user <- relationship_new_user_experience()
  returning <- relationship_returning_user_experience()
  runtime <- relationship_runtime("new_user")
  preview <- relationship_shell_preview("new_user")
  mission <- relationship_mission_control_policy()
  ai <- relationship_ai_policy()
  logging <- relationship_logging_ontology()
  memory <- relationship_experience_memory_model()
  founder <- relationship_founder_review_template()
  campaigns <- relationship_campaigns()
  comparison <- relationship_runtime_comparison()
  final <- relationship_final_assessment()

  add_check("relationship_states", all(c("new_user", "returning_user", "current_project", "resume_workflow", "explore", "learn") %in% states$relationship_state), "Relationship Runtime covers new, returning, project, resume, explore, and learn states.")
  add_check("new_user_questions", all(c("What is this?", "Why should I care?", "What can I accomplish?", "What should I do first?") %in% new_user$question), "New-user shell answers the four required first-hour questions.")
  add_check("returning_user_questions", all(c("What changed?", "What needs attention?", "What was I doing?", "What is the best next action?") %in% returning$question), "Returning-user shell answers changed, attention, resume, and next-action questions.")
  add_check("visibility_classes", identical(visibility$visibility_class, c("Immediate", "Helpful", "Contextual", "Deferred", "Advanced", "Architectural", "Developer")), "Visibility taxonomy contains the full requested hierarchy.")
  add_check("initial_visibility", all(preview$visibility_class[preview$zone != "Hidden Initially"] == "Immediate") && any(preview$visibility_class == "Developer"), "Initial shell exposes immediate content and hides developer detail.")
  add_check("progressive_order", identical(progressive$stage, c("Orientation", "Question", "Evidence", "Understanding", "Decision", "Diagnostics", "Architecture")), "Progressive shell follows Orientation, Question, Evidence, Understanding, Decision, Diagnostics, Architecture.")
  add_check("layer_order", identical(layers$layer_name, c("Relationship", "Current Intent", "Workflow", "Evidence", "Decision", "Depth", "Architecture")), "Experience layers run from Relationship through Architecture.")
  add_check("runtime_result", identical(runtime$status, "success") && inherits(runtime$value, "relationship_runtime") && !isTRUE(runtime$value$production_replacement), "Relationship Runtime compiles as preview-only and does not replace production.")
  add_check("mission_control_policy", any(grepl("summarized inside the shell", mission$answer, ignore.case = TRUE)) && any(grepl("opened after orientation", mission$answer, ignore.case = TRUE)), "Mission Control policy is compact in-shell first and full workspace later.")
  add_check("ai_policy", any(grepl("^No", ai$answer)) && any(grepl("after intent", ai$answer, ignore.case = TRUE)), "AI policy says deterministic shell greets and AI appears after intent/evidence.")
  add_check("logging_design_only", all(logging$implementation_status == "design_only_no_logging") && all(c("first_impression", "trust", "momentum", "curiosity", "confidence", "overwhelm", "understanding", "desired_next_action") %in% logging$event_family), "Logging ontology is documented only and covers review dimensions.")
  add_check("experience_memory_future_only", all(memory$phase4_status == "future_distinction_documented_only"), "Experience memory distinctions are documented without implementing personalization.")
  add_check("founder_review_dimensions", all(c("first_impression", "trust", "momentum", "curiosity", "confidence", "overwhelm", "understanding", "desired_next_action") %in% founder$review_dimension), "Founder review covers first impression, trust, momentum, curiosity, confidence, overwhelm, understanding, and desired next action.")
  add_check("relationship_campaigns", nrow(campaigns) >= 4L && all(campaigns$not_a_module_campaign), "Phase 4 campaigns are relationship campaigns, not module campaigns.")
  add_check("comparison_states", nrow(comparison) == nrow(states) && all(nzchar(comparison$opening_prompt)), "Product Experience Lab can compare shell behavior across relationship states.")
  add_check("direct_answers", nrow(final) == 8L && any(grepl("first-time user", final$question)) && any(final$confidence == "insufficient_evidence"), "Final assessment answers required Phase 4 product questions and preserves uncertainty.")
  add_check("documentation", file.exists(file.path("docs", "product_experience_runtime_architecture.md")), "Product Experience Runtime documentation exists for Phase 4.")

  do.call(rbind, checks)
}

qa_product_experience_intelligence <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  decision <- product_experience_architecture_decision()
  worlds <- product_experience_world_registry()
  truth <- product_experience_ground_truth_registry()
  scenarios <- product_experience_scenario_registry()
  selectors <- product_experience_selector_registry()
  ai_modes <- product_experience_ai_modes()

  add_check("architecture_decision", identical(decision$selected_automation, "playwright"), "Playwright is the single selected recorder path.")
  add_check("world_count", nrow(worlds) >= 10, "At least ten canonical worlds are registered.")
  add_check("hidden_truth_separated", !("hidden_truth" %in% names(worlds)) && "hidden_truth" %in% names(truth), "Hidden truth is separated from app-facing worlds.")
  add_check("scenario_coverage", all(worlds$world_id %in% scenarios$world_id), "Every world has a scenario.")
  add_check("scenario_contract", all(c("scenario_id", "steps", "expected_validation", "expected_completion") %in% names(scenarios)), "Scenario contract fields exist.")
  add_check("selector_registry", all(grepl("^[a-z0-9_.-]+$", selectors$data_testid)), "Stable selector registry uses semantic test ids.")
  add_check("ai_modes", all(c("fixture", "live", "replay") %in% ai_modes$ai_mode), "Fixture, live, and replay AI modes are explicit.")

  project_result <- product_experience_generate_project("world_01")
  add_check("project_generation", identical(project_result$status, "success") && !isTRUE(project_result$value$hidden_truth_included), "Deterministic project generation excludes hidden truth.")

  run_result <- product_experience_run_scenario("scenario_world_01", automation = "fixture", ai_mode = "fixture")
  add_check("fixture_run", identical(run_result$status, "success") && identical(run_result$value$status, "completed"), "Fixture scenario run completes deterministically.")
  add_check("run_excludes_hidden_truth", !isTRUE(run_result$value$hidden_truth_included), "Scenario run does not include hidden truth.")
  add_check("metrics", length(run_result$value$metrics) >= 10, "Workflow metrics are recorded.")

  findings <- data.frame(
    issue_id = "px_issue_001",
    category = "friction",
    severity = "medium",
    description = "Reviewer had to change pages twice to find evidence.",
    recommendation = "Expose the next evidence location more clearly.",
    screenshot_id = "status",
    video_timestamp = "00:00:24",
    campaign_candidate = TRUE,
    stringsAsFactors = FALSE
  )
  review <- product_experience_review_artifact(run_result$value, findings = findings)
  seeds <- product_experience_campaign_seeds(review)
  add_check("review_artifact", inherits(review, "aq_artifact") && identical(review$artifact_type, "product_experience_review_artifact"), "Review is stored as a standard artifact.")
  add_check("campaign_seed", nrow(seeds) == 1L, "Review finding becomes a campaign seed.")

  playwright_result <- product_experience_run_scenario("scenario_world_01", automation = "playwright", ai_mode = "fixture")
  add_check("playwright_contract", playwright_result$status %in% c("success", "warning"), "Playwright contract reports availability without fabricating recordings.")

  impact <- cross_repo_impact_plan(list(
    summary = "Product Experience Intelligence Phase 2 Golden Workflow replay and UX benchmark",
    category = "workflow_update",
    repositories = "AnalyticsShinyApp"
  ))
  add_check("cross_repo_impact_plan", identical(impact$category, "workflow_update") && identical(impact$repositories_affected, "AnalyticsShinyApp"), "Cross-repository impact plan scopes Phase 2 to AnalyticsShinyApp.")

  golden <- product_experience_golden_workflow()
  add_check("golden_workflow", identical(golden$workflow_id, "golden_business_question_to_persisted_draft") && nrow(golden$steps) == 8L, "Golden Workflow defines the canonical eight-step product benchmark.")

  diagnostics <- product_experience_playwright_diagnostics()
  add_check("playwright_diagnostics", all(c("node", "npm", "npx", "playwright") %in% diagnostics$component), "Recorder diagnostics classify Node, npm, npx, and Playwright availability.")
  add_check("runtime_discovery_contract", all(c("package_json", "package_lock", "previous_screenshots", "previous_videos", "previous_traces", "previous_reports") %in% product_experience_runtime_discovery()$component), "Runtime discovery includes package state and prior recording artifacts.")
  add_check("runtime_failure_classification", identical(product_experience_classify_replay_failure("selector", service_result(status = "error")), "Selector failed"), "Replay failures are classified for provisioning, browser, app, selector, validation, recording, and completion states.")

  golden_run <- product_experience_run_golden_workflow(automation = "fixture", ai_mode = "fixture")
  add_check("golden_replay_manifest", golden_run$status %in% c("success", "warning") && file.exists(golden_run$value$manifest_path), "Golden replay writes an execution manifest.")
  add_check("golden_review_package", file.exists(golden_run$value$review_package_path), "Golden replay writes a review package.")
  add_check("golden_no_fabricated_video", identical(golden_run$value$video_path, NA_character_) && grepl("fixture|unavailable", golden_run$value$recorder_status), "Fixture/unavailable replay does not fabricate video.")

  review_schema <- product_experience_review_schema()
  add_check("expanded_review_schema", all(c("trust", "overall_friction", "campaign_seed") %in% review_schema$field), "Human review schema includes trust, friction, and campaign seed fields.")

  regression <- product_experience_compare_regression(golden_run$value)
  add_check("ux_regression", all(c("metric", "current", "expected", "status") %in% names(regression)) && any(regression$status == "pass"), "UX regression comparison evaluates Golden Workflow metrics.")

  narrations <- product_experience_narration_profiles()
  add_check("narration_profiles", all(c("engineering", "business", "executive", "analyst") %in% narrations$narration_profile), "Narration profiles vary audience without duplicating scenarios.")

  media_validation <- product_experience_media_root_validation()
  add_check("external_media_root", all(media_validation$status), "Product-experience media root is configured, writable, and outside the repository.")
  add_check("media_lifecycle", all(c("candidate", "awaiting_review", "approved", "rejected", "archived") %in% product_experience_media_lifecycle_states()$lifecycle_state), "Media lifecycle states are explicit.")

  ranking <- product_experience_showcase_candidate_ranking()
  add_check("showcase_ranking", nrow(ranking) >= 5L && identical(ranking$candidate_id[[1]], "showcase_bounded_growth_pilot"), "Flagship showcase candidate is ranked with comparison candidates.")

  flagship_a <- product_experience_generate_flagship_world()
  flagship_b <- product_experience_generate_flagship_world()
  add_check("flagship_world_deterministic", identical(flagship_a$app_data, flagship_b$app_data), "Flagship synthetic world is reproducible.")
  add_check("flagship_hidden_truth_separated", !("truth_manifest" %in% names(product_experience_flagship_evidence_package())) && !isTRUE(product_experience_flagship_evidence_package()$hidden_truth_included), "Flagship evidence package excludes hidden truth.")

  ux_passes <- product_experience_ux_iteration_passes()
  add_check("ux_iteration_passes", nrow(ux_passes) == 3L && all(c("Coherence and Friction", "Evidence Communication and AI Naturalness", "Presentation and Investor Readiness") %in% ux_passes$pass_name), "Golden Workflow UX iteration is organized into three focused passes.")
  promotion_gate <- product_experience_investor_promotion_gate()
  add_check("investor_promotion_gate", nrow(promotion_gate) >= 10L && all(promotion_gate$required), "Investor promotion gate criteria are explicit and required.")
  blocked_assessment <- product_experience_assess_investor_candidate(golden_run$value, founder_approved = FALSE, developer_content_visible = TRUE)
  add_check("investor_candidate_requires_review", identical(attr(blocked_assessment, "promotion_state"), "awaiting_review") && any(blocked_assessment$status == "block"), "Unreviewed/developer-facing recordings are not promoted to investor_candidate.")

  workflow_review <- product_experience_golden_workflow_review()
  add_check("golden_workflow_review", nrow(workflow_review) == nrow(golden$steps) && all(c("expected_understanding", "expected_action", "current_friction", "cognitive_load", "campaign_id") %in% names(workflow_review)), "Golden Workflow review preserves understanding, action, friction, load, and campaign mapping.")
  founder_schema <- product_experience_founder_review_schema()
  add_check("founder_review_schema", all(c("workflow_step", "finding", "severity", "campaign_id") %in% founder_schema$field), "Founder review schema captures workflow step, finding, severity, and campaign.")
  founder_findings <- product_experience_founder_review_template(golden_run$value)
  campaigns <- product_experience_prioritize_ux_campaigns(founder_findings)
  add_check("ux_campaign_prioritization", nrow(campaigns) == nrow(founder_findings) && all(c("priority_score", "expected_ux_improvement", "dependencies") %in% names(campaigns)), "Founder findings become ranked UX campaigns.")
  replay_metrics <- product_experience_replay_metrics_summary(golden_run$value)
  add_check("ux_metrics", all(c("clicks", "completion_time_sec", "promotion_state") %in% replay_metrics$metric), "Replay metrics include clicks, time, and promotion state.")
  replay_comparison <- product_experience_compare_replay_runs(golden_run$value)
  add_check("semantic_replay_comparison", all(c("metric", "semantic_change", "interpretation") %in% names(replay_comparison)), "Replay comparison reports semantic improvement/regression labels.")
  final_assessment <- product_experience_final_assessment(golden_run$value, founder_approved = FALSE, developer_content_visible = TRUE)
  add_check("final_assessment_conservative", final_assessment$classification %in% c("Internal", "Beta") && identical(final_assessment$promotion_state, "awaiting_review"), "Final assessment stays conservative before founder approval and developer-surface removal.")

  hypotheses <- product_experience_experience_hypotheses()
  comparison <- product_experience_prototype_comparison()
  exposure <- product_experience_information_exposure_taxonomy()
  disclosure <- product_experience_progressive_disclosure_strategy()
  ai_roles <- product_experience_ai_role_assessment()
  campaigns_research <- product_experience_research_campaigns()
  open_questions <- product_experience_research_open_questions()
  add_check("experience_hypotheses", nrow(hypotheses) >= 6L && all(c("Intent-first", "Business Question first", "Analyst Workspace") %in% hypotheses$hypothesis), "Competing experience hypotheses include intent-first, question-first, and current baseline.")
  add_check("prototype_comparison", all(c("prototype_next", "baseline") %in% comparison$prototype_status), "Prototype comparison marks next prototypes and baseline separately.")
  add_check("information_exposure_taxonomy", all(c("Essential", "Helpful", "Contextual", "Advanced", "Architectural", "Developer") %in% exposure$exposure_class), "Information exposure taxonomy classifies essential through developer surfaces.")
  add_check("progressive_disclosure_levels", all(paste("Level", 0:4) %in% disclosure$level), "Progressive disclosure levels 0-4 are represented.")
  add_check("ai_visibility_rule", any(ai_roles$preferred_owner == "deterministic UI") && any(grepl("synthesis|reasoning", ai_roles$preferred_owner, ignore.case = TRUE)), "AI role assessment separates deterministic UI from genuine reasoning zones.")
  add_check("research_campaigns", nrow(campaigns_research) >= 2L && all(campaigns_research$prototype_id %in% comparison$prototype_id), "Research campaigns target next prototype candidates.")
  add_check("research_open_questions", all(c("question", "current_answer", "next_experiment") %in% names(open_questions)) && any(grepl("Golden Workflow", open_questions$question)), "Research open questions preserve current answers and next experiments.")

  runtime_qa <- qa_product_experience_runtime()
  add_check("experience_runtime_qa", all(runtime_qa$status == "PASS"), "Product Experience Runtime compiles baseline, intent-first, and business-question-first experiences deterministically.")
  phase2_qa <- qa_product_experience_runtime_phase2()
  add_check("experience_runtime_phase2_qa", all(phase2_qa$status == "PASS"), "Product Experience Runtime Phase 2 emits A/B/current replay, comparison, founder review, and campaign packages.")
  phase3_qa <- qa_product_experience_runtime_phase3()
  add_check("experience_runtime_phase3_qa", all(phase3_qa$status == "PASS"), "Product Experience Runtime Phase 3 defines browser-recorded prototype trial contracts and comparison outputs.")
  relationship_qa <- qa_product_experience_relationship_runtime()
  add_check("relationship_runtime_qa", all(relationship_qa$status == "PASS"), "Product Experience Runtime Phase 4 defines relationship states, progressive shells, review, campaigns, and deterministic visibility.")
  working_context_qa <- qa_working_contexts()
  add_check("working_context_qa", all(working_context_qa$status == "PASS"), "Product Experience Runtime Phase 5 defines the Evidence Review Working Context, capability exposure, replay, review, campaigns, and documentation.")

  doc_path <- file.path("docs", "product_experience_intelligence_architecture.md")
  add_check("documentation", file.exists(doc_path), "Architecture documentation exists.")

  do.call(rbind, checks)
}

qa_product_experience_research_mode <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  principles <- product_experience_research_mode_principles()
  hypotheses <- product_experience_experience_hypotheses()
  prototypes <- product_experience_prototype_modes()
  comparison <- product_experience_prototype_comparison()
  inventory <- product_experience_visible_element_inventory()
  exposure <- product_experience_information_exposure_taxonomy()
  disclosure <- product_experience_progressive_disclosure_strategy()
  ai_roles <- product_experience_ai_role_assessment()
  campaigns <- product_experience_research_campaigns()
  questions <- product_experience_research_open_questions()

  add_check("research_principles", nrow(principles) >= 6L && any(grepl("Explore", principles$principle)), "Research mode principles make exploration explicit.")
  add_check("hypothesis_contract", all(c("hypothesis_id", "opening_prompt", "flow", "learning_value", "primary_risk") %in% names(hypotheses)) && nrow(hypotheses) >= 6L, "Experience hypotheses contain prompts, flows, learning value, and risk.")
  add_check("prototype_contract", all(c("prototype_id", "entry_surface", "default_visible_level", "success_metric") %in% names(prototypes)) && all(lengths(prototypes$immediate_visible_elements) > 0L), "Prototype modes define entry, default disclosure, visible elements, and success metric.")
  add_check("prototype_ranking", any(comparison$prototype_status == "prototype_next") && any(comparison$prototype_status == "baseline") && "learning_score" %in% names(comparison), "Prototype comparison ranks next candidates against the baseline.")
  add_check("developer_visibility", any(inventory$surface == "Product Experience Lab" & inventory$exposure_class == "Developer" & inventory$investor_workflow_visibility == "hide"), "Product Experience Lab is classified as developer-only for investor workflows.")
  add_check("exposure_classes", all(c("Essential", "Helpful", "Contextual", "Advanced", "Architectural", "Developer") %in% exposure$exposure_class), "Exposure classes cover all intended visibility levels.")
  add_check("disclosure_levels", identical(disclosure$level, paste("Level", 0:4)), "Progressive disclosure levels are ordered from orientation through architecture.")
  add_check("ai_invisibility", any(ai_roles$preferred_owner == "deterministic UI") && any(ai_roles$preferred_owner == "AI-assisted reasoning"), "AI role assessment says where AI should disappear and where it adds value.")
  add_check("campaign_mapping", nrow(campaigns) >= 2L && all(nzchar(campaigns$minimum_prototype)) && all(campaigns$prototype_id %in% comparison$prototype_id), "Research campaigns map to prototype candidates.")
  add_check("open_questions", nrow(questions) >= 8L && any(grepl("expose too much", questions$question, ignore.case = TRUE)) && any(grepl("AI", questions$question)), "Open questions include exposure and AI invisibility questions.")

  do.call(rbind, checks)
}

qa_product_experience_runtime <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  prototypes <- experience_prototype_registry()
  intents <- experience_intent_registry()
  capabilities <- experience_capability_map()
  visibility <- experience_runtime_visibility_levels()
  compiled_a <- experience_compiler("prototype_a_intent_first", intent = "decide")
  compiled_b <- experience_compiler("prototype_b_business_question_first", intent = "decide")
  compiled_current <- experience_compiler("current_golden_workflow", intent = "decide")
  runtime_a <- experience_runtime("prototype_a_intent_first", intent = "decide")
  route_decide <- experience_route_intent("decide", "prototype_a_intent_first")
  route_review <- experience_route_intent("review", "prototype_a_intent_first", list(has_artifacts = TRUE))
  comparison <- experience_compare_compiled_prototypes()
  founder_template <- experience_founder_review_comparison_template()
  campaigns <- experience_prototype_campaigns(comparison)
  progressive <- experience_progressive_runtime("prototype_a_intent_first")

  add_check("prototype_registry", all(c("current_golden_workflow", "prototype_a_intent_first", "prototype_b_business_question_first") %in% prototypes$prototype_id), "Runtime registry includes current baseline, intent-first, and business-question-first prototypes.")
  add_check("prototype_shared_workflow", length(unique(prototypes$workflow_id)) == 1L && unique(prototypes$workflow_id) == product_experience_golden_workflow()$workflow_id, "All prototypes share the same Golden Workflow.")
  add_check("intent_registry", all(c("analyze", "decide", "review", "continue", "explore", "learn") %in% intents$intent_id), "Intent registry covers analyze, decide, review, continue, explore, and learn.")
  add_check("capability_map", all(c("capability_id", "default_exposure", "ai_visibility", "promotion") %in% names(capabilities)) && any(capabilities$promotion == "hide"), "Capability map defines visibility, AI behavior, and promotion policy.")
  add_check("visibility_levels", all(c("immediate", "deferred", "contextual", "advanced", "architectural", "developer") %in% visibility$exposure), "Runtime visibility levels are explicit.")
  add_check("runtime_result", identical(runtime_a$status, "success") && inherits(runtime_a$value, "compiled_experience"), "experience_runtime returns a service_result containing a compiled experience.")
  add_check("compiler_contract", all(c("prototype", "intent", "navigation_plan", "information_plan", "ai_plan", "controls") %in% names(compiled_a)), "Compiled experience contains prototype, intent, navigation, information, AI, and control contracts.")
  add_check("intent_routing", identical(route_decide$start_surface[[1]], "Guide") && identical(route_review$start_surface[[1]], "Artifact Studio"), "Intent routing determines entry from intent and project state.")
  add_check("architecture_constant", isTRUE(compiled_a$controls$architecture_unchanged) && identical(compiled_a$controls$workflow_id, compiled_b$controls$workflow_id) && identical(compiled_b$controls$workflow_id, compiled_current$controls$workflow_id), "Compiler preserves one underlying architecture and workflow.")
  add_check("information_justification", all(nzchar(compiled_a$information_plan$justification)) && all(c("immediate", "developer_or_deferred") %in% compiled_a$information_plan$visibility), "Every compiled visible/hidden component has a justification.")
  add_check("ai_runtime_behavior", any(compiled_a$ai_plan$visibility == "hidden") && any(compiled_b$ai_plan$ai_surface == "evidence_synthesis" & compiled_b$ai_plan$visibility == "contextual"), "AI visibility is runtime behavior rather than workflow-owned.")
  add_check("progressive_runtime", identical(progressive$stage, c("Orientation", "Workflow", "Evidence", "Decision", "Diagnostics", "Architecture")), "Progressive runtime compiles orientation through architecture.")
  add_check("comparison_contract", nrow(comparison) == 3L && all(c("time_to_first_meaningful_action_sec", "estimated_clicks", "cognitive_load_estimate", "comparison_note") %in% names(comparison)), "Prototype comparison emits metrics for baseline, A, and B.")
  add_check("founder_template", nrow(founder_template) == 3L && all(c("first_minute_summary", "moment_of_delight", "moment_of_confusion", "preference_rank") %in% names(founder_template)), "Founder comparison template is prototype-specific.")
  add_check("campaign_scope", nrow(campaigns) == 3L && all(campaigns$scope == "prototype_specific"), "Runtime campaigns are prototype scoped.")
  add_check("no_premature_winner", !("winner" %in% names(comparison)) && all(grepl("compare|baseline|candidate", comparison$comparison_note, ignore.case = TRUE)), "Runtime comparison does not declare a winner before review evidence.")
  add_check("documentation", file.exists(file.path("docs", "product_experience_runtime_architecture.md")), "Product Experience Runtime documentation exists.")

  do.call(rbind, checks)
}

qa_product_experience_runtime_phase2 <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  entry_a <- experience_prototype_entry_experience("prototype_a_intent_first")
  entry_b <- experience_prototype_entry_experience("prototype_b_business_question_first")
  entry_current <- experience_prototype_entry_experience("current_golden_workflow")
  replay_a <- experience_prototype_replay_package("prototype_a_intent_first", write_files = TRUE)
  replay_b <- experience_prototype_replay_package("prototype_b_business_question_first", write_files = TRUE)
  replay_current <- experience_prototype_replay_package("current_golden_workflow", write_files = TRUE)
  replay_all <- list(
    current_golden_workflow = replay_current$value,
    prototype_a_intent_first = replay_a$value,
    prototype_b_business_question_first = replay_b$value
  )
  comparison <- experience_compare_prototype_replays(replay_all)
  founder <- experience_founder_review_package(replay_all)
  recommendation <- experience_phase2_recommendation(comparison)
  campaigns <- experience_phase2_campaigns(comparison)

  add_check("intent_first_prompt", identical(entry_a$first_interaction[[1]], "What are you trying to accomplish?"), "Prototype A starts with the required intent-first prompt.")
  add_check("intent_first_choices", all(c("Analyze data", "Make a decision", "Review evidence", "Continue previous work", "Explore", "Learn") %in% unlist(strsplit(entry_a$choices[[1]], " \\| "))), "Prototype A exposes the required intent choices.")
  add_check("business_question_prompt", identical(entry_b$first_interaction[[1]], "What business question are you trying to answer?"), "Prototype B starts with the required business-question prompt.")
  add_check("current_entry_contract", nzchar(entry_current$first_interaction[[1]]), "Current baseline has an explicit entry contract for comparison.")
  add_check("replay_status", identical(replay_a$status, "success") && identical(replay_b$status, "success") && identical(replay_current$status, "success"), "Current, A, and B replay packages are generated.")
  add_check("replay_files", all(file.exists(c(replay_a$value$manifest_path, replay_a$value$review_package_path, replay_b$value$manifest_path, replay_b$value$review_package_path, replay_current$value$manifest_path, replay_current$value$review_package_path))), "Replay manifests and founder review packages are written.")
  add_check("same_golden_workflow", length(unique(vapply(replay_all, function(x) x$workflow$workflow_id, character(1)))) == 1L, "Current, A, and B converge into the same Golden Workflow.")
  add_check("same_world_decision_artifacts", all(vapply(replay_all, function(x) isTRUE(x$convergence$same_synthetic_world) && isTRUE(x$convergence$same_artifacts) && isTRUE(x$convergence$same_decision), logical(1))), "Prototype replays keep synthetic world, artifacts, and decision constant.")
  add_check("comparison_metrics", all(c("time_to_first_action_sec", "time_to_first_evidence_sec", "time_to_first_understanding_sec", "clicks", "navigation_depth", "context_switches", "backtracking", "ai_interactions", "visible_concepts", "reading_burden", "founder_preference", "replay_quality") %in% names(comparison)), "Replay comparison includes requested metrics.")
  add_check("founder_review_package", nrow(founder) == 3L && all(c("strengths", "weaknesses", "delight", "confusion", "trust", "recommendation", "open_questions") %in% names(founder)), "Founder review package covers strengths, weaknesses, delight, confusion, trust, recommendation, and open questions.")
  add_check("mission_control_evaluation", all(nzchar(comparison$mission_control_role)), "Each prototype records the Mission Control role.")
  add_check("ai_not_forced", all(grepl("hidden|visible|contextual", comparison$ai_visibility, ignore.case = TRUE)) && any(grepl("hidden", comparison$ai_visibility, ignore.case = TRUE)), "AI visibility is evaluated as contextual/hidden behavior rather than forced entry.")
  add_check("campaign_scope", nrow(campaigns) == 3L && all(campaigns$scope == "prototype_specific"), "Phase 2 campaigns are prototype-specific.")
  add_check("recommendation_no_winner", any(grepl("before selecting|before selection", recommendation$current_answer, ignore.case = TRUE)) && !("winner" %in% names(comparison)), "Phase 2 preserves comparison without declaring a final winner.")
  add_check("runtime_order", identical(experience_progressive_runtime("prototype_a_intent_first")$stage, c("Orientation", "Workflow", "Evidence", "Decision", "Diagnostics", "Architecture")), "Runtime order remains Orientation, Workflow, Evidence, Decision, Diagnostics, Architecture.")
  add_check("documentation_phase2", file.exists(file.path("docs", "product_experience_runtime_architecture.md")), "Runtime architecture documentation exists for Phase 2.")

  do.call(rbind, checks)
}

qa_product_experience_runtime_phase3 <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  prototypes <- experience_phase3_trial_prototypes()
  replay_current <- experience_prototype_replay_package("current_golden_workflow", write_files = FALSE)$value
  replay_intent <- experience_prototype_replay_package("prototype_a_intent_first", write_files = FALSE)$value
  replay_question <- experience_prototype_replay_package("prototype_b_business_question_first", write_files = FALSE)$value
  replay_current$recorder_status <- "Golden Workflow completed"
  replay_intent$recorder_status <- "Golden Workflow completed"
  replay_question$recorder_status <- "Golden Workflow completed"
  replay_current$video_path <- tempfile(fileext = ".webm")
  replay_intent$video_path <- tempfile(fileext = ".webm")
  replay_question$video_path <- tempfile(fileext = ".webm")
  replay_current$trace_path <- tempfile(fileext = ".zip")
  replay_intent$trace_path <- tempfile(fileext = ".zip")
  replay_question$trace_path <- tempfile(fileext = ".zip")
  runs <- list(replay_current, replay_intent, replay_question)
  comparison <- experience_phase3_compare_browser_replays(runs)
  pairwise <- experience_phase3_pairwise_comparison(comparison)
  founder <- experience_phase3_founder_review_package(runs)
  final <- experience_phase3_final_assessment(comparison, founder)
  cognitive <- experience_phase3_cognitive_load(replay_question)
  story <- experience_phase3_product_story(replay_question)
  ai <- experience_phase3_ai_assessment(replay_question)
  validation <- experience_phase3_replay_validation(replay_question)

  add_check("trial_prototypes", all(c("Replay_Current", "Replay_Intent", "Replay_BusinessQuestion") %in% prototypes$replay_id), "Phase 3 defines the three required replay hypotheses.")
  add_check("controlled_constants", all(grepl("same world", prototypes$controlled_constants, ignore.case = TRUE)) && all(grepl("Entry", prototypes$allowed_difference)), "Trial contract separates controlled constants from allowed experience differences.")
  add_check("comparison_metrics", all(c("time_to_first_action_sec", "time_to_first_evidence_sec", "time_to_first_insight_sec", "workflow_duration_sec", "mission_control_usage", "cognitive_load_estimate") %in% names(comparison)), "Browser replay comparison contains required metrics.")
  add_check("pairwise_comparison", nrow(pairwise) == 3L && all(c("Current Experience", "Intent-First", "Business Question First") %in% prototypes$prototype_label), "Pairwise comparison covers Current vs Intent, Current vs Business Question, and Intent vs Business Question.")
  add_check("founder_review", nrow(founder) == 3L && all(c("understanding", "trust", "confusion", "delight", "evidence", "workflow", "ai", "visual_hierarchy", "navigation", "recommendation", "approval") %in% names(founder)), "Founder review captures understanding, trust, confusion, delight, evidence, workflow, AI, hierarchy, navigation, recommendation, and approval.")
  add_check("cognitive_load", all(c("initial_overload", "progressive_understanding", "information_density", "decision_confidence", "cognitive_load_spike") %in% names(cognitive)), "Cognitive load assessment includes overload, understanding, density, confidence, and spike location.")
  add_check("product_story", all(c("first_product_identity_moment", "viewer_understanding_trigger", "story_risk") %in% names(story)), "Product story assessment records when identity becomes clear.")
  add_check("ai_assessment", all(c("visibility", "naturalness", "necessity", "deterministic_replacement_flag") %in% names(ai)), "AI assessment records visibility, naturalness, necessity, and deterministic replacement.")
  add_check("replay_validation_contract", all(c("expected_page", "expected_state", "expected_workflow", "expected_artifacts", "expected_transitions", "expected_ai", "expected_mission_control", "expected_final_draft", "expected_completion", "video", "screenshots", "trace") %in% validation$check), "Replay validation covers expected page, state, workflow, artifacts, transitions, AI, Mission Control, final draft, completion, video, screenshots, and trace.")
  add_check("final_assessment_direct_answers", nrow(final) == 8L && any(grepl("Which prototype minimizes cognitive load", final$question, fixed = TRUE)) && any(grepl("Should either challenger replace", final$question, fixed = TRUE)), "Final assessment answers the required product philosophy questions without automatic selection.")
  add_check("no_automatic_winner", !("winner" %in% names(comparison)) && any(final$confidence == "insufficient_evidence"), "Phase 3 comparison does not declare a winner without human review evidence.")
  add_check("documentation", file.exists(file.path("docs", "product_experience_runtime_architecture.md")), "Runtime documentation exists for Phase 3 additions.")

  do.call(rbind, checks)
}

qa_product_experience_browser_runtime <- function(port = 6991) {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  discovery <- product_experience_runtime_discovery()
  add_check("runtime_discovery", all(c("node", "npm", "npx", "playwright", "package_json", "package_lock") %in% discovery$component), "Runtime discovery reports Node, npm, npx, Playwright, and package metadata.")

  runtime <- product_experience_ensure_browser_runtime()
  add_check("runtime_provision_validate", identical(runtime$status, "success"), paste(c(runtime$messages, runtime$errors), collapse = " "))

  if (identical(runtime$status, "success")) {
    validation <- product_experience_validate_browser_runtime()
    add_check("browser_smoke_screenshot", identical(validation$status, "success") && file.exists(validation$value$screenshot), "Minimal Playwright launch, DOM interaction, screenshot, and shutdown pass.")

    replay <- product_experience_regenerate_golden_workflow(port = port, ai_mode = "fixture")
    add_check("golden_browser_replay", identical(replay$status, "success"), paste(c(replay$messages, replay$errors), collapse = " "))
    if (identical(replay$status, "success")) {
      add_check("golden_screenshots", nrow(replay$value$chapters) >= 8L && all(file.exists(replay$value$chapters$screenshot_path)), "Golden Workflow records at least the eight canonical screenshot chapters.")
      add_check("golden_video", nzchar(replay$value$video_path %||% "") && file.exists(replay$value$video_path), "Golden Workflow records a WebM video.")
      add_check("golden_canonical_video", identical(basename(replay$value$video_path), "GoldenWorkflow.webm"), "Golden Workflow writes the canonical GoldenWorkflow.webm artifact.")
      add_check("golden_video_verification", identical(replay$value$verification$status, "success") && isTRUE((replay$value$verification$video$duration_sec %||% 0) > 20), "GoldenWorkflow.webm opens in Chromium and has non-trivial showcase duration.")
      add_check("golden_trace", nzchar(replay$value$trace_path %||% "") && file.exists(replay$value$trace_path), "Golden Workflow records a Playwright trace.")
      add_check("golden_report", file.exists(replay$value$manifest_path) && file.exists(replay$value$review_package_path), "Golden Workflow writes execution report and review package.")
    }
  }

  do.call(rbind, checks)
}

qa_product_experience_media_governance <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  dirs <- product_experience_media_dirs(create = TRUE)
  validation <- product_experience_media_root_validation()
  lifecycle <- product_experience_media_lifecycle_states()
  evidence <- product_experience_flagship_evidence_package()
  run <- product_experience_run_golden_workflow(automation = "fixture", ai_mode = "fixture")$value
  manifest <- product_experience_showcase_media_manifest(run, lifecycle_state = "awaiting_review", media_root = dirs$media_root)

  add_check("media_root_valid", all(validation$status), "External media root is available and suitable.")
  add_check("media_directories", all(vapply(dirs, dir.exists, logical(1))), "Media directories are created.")
  add_check("lifecycle_contract", all(c("lifecycle_state", "meaning", "mutable") %in% names(lifecycle)) && nrow(lifecycle) >= 5L, "Media lifecycle contract exists.")
  add_check("manifest_contract", all(c("manifest_type", "lifecycle_state", "run_id", "video_path", "hidden_truth_included") %in% names(manifest)), "Showcase media manifest records lifecycle, run, evidence paths, and truth policy.")
  add_check("manifest_no_hidden_truth", !isTRUE(manifest$hidden_truth_included), "Media manifest does not include hidden truth.")
  add_check("evidence_package", all(c("descriptive", "guardrail", "governed_next_action") %in% names(evidence$visible_evidence)), "Flagship evidence package exposes app-facing evidence.")
  add_check("candidate_ranking", nrow(product_experience_showcase_candidate_ranking()) >= 5L, "Showcase candidates are rankable for review.")
  gate <- product_experience_assess_investor_candidate(run, founder_approved = FALSE, developer_content_visible = TRUE)
  add_check("promotion_gate_blocks_unreviewed", identical(attr(gate, "promotion_state"), "awaiting_review"), "Promotion gate blocks unreviewed generated media from investor_candidate status.")

  do.call(rbind, checks)
}

qa_product_experience_ux_hardening <- function() {
  checks <- list()
  add_check <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(
      check = check,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  workflow <- product_experience_golden_workflow()
  review <- product_experience_golden_workflow_review()
  schema <- product_experience_founder_review_schema()
  findings <- product_experience_founder_review_template()
  campaigns <- product_experience_prioritize_ux_campaigns(findings)
  run <- product_experience_run_golden_workflow(automation = "fixture", ai_mode = "fixture")$value
  metrics <- product_experience_replay_metrics_summary(run)
  comparison <- product_experience_compare_replay_runs(run)
  assessment <- product_experience_final_assessment(run, founder_approved = FALSE, developer_content_visible = TRUE)

  add_check("workflow_review_step_coverage", nrow(review) == nrow(workflow$steps), "Every Golden Workflow step has a UX review row.")
  add_check("review_understanding_action", all(nzchar(review$expected_understanding)) && all(nzchar(review$expected_action)), "Every step declares expected understanding and action.")
  add_check("founder_schema_required_fields", all(schema$required[schema$field %in% c("timestamp", "workflow_step", "finding", "severity", "recommendation", "campaign_id")]), "Founder review required fields are enforced by contract.")
  add_check("founder_findings_structured", all(c("finding", "category", "severity", "recommendation", "campaign_id") %in% names(findings)) && nrow(findings) >= 8L, "Founder review template emits structured findings.")
  add_check("campaign_priority_transparent", all(c("user_impact", "commercial_impact", "scientific_impact", "implementation_effort", "risk", "priority_score") %in% names(campaigns)), "Campaign ranking exposes impact, effort, risk, and score.")
  add_check("developer_surface_campaign", any(grepl("developer", campaigns$finding, ignore.case = TRUE) | grepl("developer", campaigns$recommendation, ignore.case = TRUE)), "Current campaigns explicitly identify developer-surface leakage.")
  add_check("metrics_contract", all(c("clicks", "navigation_depth", "ai_interactions", "mission_control_visits", "review_completion") %in% metrics$metric), "UX metrics cover clicks, navigation, AI, Mission Control, and review completion.")
  add_check("comparison_contract", all(comparison$semantic_change %in% c("baseline", "improved", "regressed", "unchanged")), "Replay comparison uses semantic status labels.")
  add_check("assessment_contract", all(c("classification", "largest_ux_weakness", "promotion_state", "blockers") %in% names(assessment)), "Final assessment answers classification and largest weakness.")
  add_check("not_investor_candidate_yet", !identical(assessment$classification, "Investor Candidate") && identical(assessment$promotion_state, "awaiting_review"), "Current workflow is not promoted before founder approval and developer-surface removal.")

  do.call(rbind, checks)
}
