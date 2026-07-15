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
  pacing_profile = "investor"
) {
  run_dir <- file.path(output_root, paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S")))
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
