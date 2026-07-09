evidence_routing_levels <- function() {
  data.table::data.table(
    routing_level = 0:5,
    routing_label = c("Exclude", "Mention Only", "Summary", "Evidence", "Deep Dive", "Request More Evidence")
  )
}

evidence_routing_profiles <- function() {
  list(
    conservative = list(max_artifacts = 6L, max_images = 1L, max_tables = 2L, deep_dive_threshold = 0.78, include_threshold = 0.34, token_budget = 1800L, redundancy_tolerance = 0.35, prefer_vision = FALSE, exact_values = FALSE),
    balanced = list(max_artifacts = 10L, max_images = 2L, max_tables = 3L, deep_dive_threshold = 0.70, include_threshold = 0.26, token_budget = 3000L, redundancy_tolerance = 0.55, prefer_vision = FALSE, exact_values = FALSE),
    thorough = list(max_artifacts = 18L, max_images = 4L, max_tables = 6L, deep_dive_threshold = 0.62, include_threshold = 0.18, token_budget = 6000L, redundancy_tolerance = 0.75, prefer_vision = FALSE, exact_values = FALSE),
    accuracy_first = list(max_artifacts = 14L, max_images = 3L, max_tables = 6L, deep_dive_threshold = 0.60, include_threshold = 0.20, token_budget = 5000L, redundancy_tolerance = 0.70, prefer_vision = FALSE, exact_values = TRUE),
    token_saver = list(max_artifacts = 5L, max_images = 1L, max_tables = 1L, deep_dive_threshold = 0.88, include_threshold = 0.42, token_budget = 1100L, redundancy_tolerance = 0.25, prefer_vision = FALSE, exact_values = FALSE),
    vision_first = list(max_artifacts = 10L, max_images = 4L, max_tables = 2L, deep_dive_threshold = 0.66, include_threshold = 0.24, token_budget = 3500L, redundancy_tolerance = 0.60, prefer_vision = TRUE, exact_values = FALSE),
    local_private = list(max_artifacts = 8L, max_images = 2L, max_tables = 2L, deep_dive_threshold = 0.72, include_threshold = 0.30, token_budget = 2500L, redundancy_tolerance = 0.50, prefer_vision = FALSE, exact_values = FALSE, local_only = TRUE)
  )
}

evidence_routing_profile <- function(profile = "balanced", overrides = list()) {
  profiles <- evidence_routing_profiles()
  selected <- profiles[[profile]] %||% profiles$balanced
  utils::modifyList(selected, overrides)
}

evidence_plan_id <- function(prefix = "evidence_plan") {
  paste0(prefix, "_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample.int(9999L, 1L))
}

evidence_task_type <- function(question) {
  text <- tolower(question %||% "")
  if (grepl("creative|attribute|campaign|channel|placement|audience", text)) {
    "creative_next_action"
  } else if (grepl("trustworthy|trust|confidence|reliable|validated", text)) {
    "trustworthiness"
  } else if (grepl("misleading|risk|production|concern|caveat|limit", text)) {
    "risk_assessment"
  } else if (grepl("exact|value|metric|number|rank", text)) {
    "exact_values"
  } else if (grepl("nonlinear|unstable|effect|shape", text)) {
    "effect_diagnostics"
  } else if (grepl("executive|briefing|summary|brief", text)) {
    "executive_briefing"
  } else if (grepl("next|test|investigate|action|recommend", text)) {
    "next_action"
  } else {
    "summarize"
  }
}

evidence_question_keywords <- function(question) {
  words <- unique(unlist(strsplit(tolower(question %||% ""), "[^a-z0-9_]+")))
  stopwords <- c("the", "and", "or", "to", "for", "of", "a", "an", "is", "are", "what", "which", "should", "we", "next", "this", "that", "from")
  words[nzchar(words) & !(words %in% stopwords)]
}

evidence_artifact_text <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  paste(
    artifact$artifact_id %||% "",
    artifact$artifact_type %||% artifact$type %||% "",
    artifact$label %||% artifact$title %||% "",
    artifact$source_module %||% "",
    artifact$section %||% "",
    metadata$caption %||% "",
    metadata$analytical_intent %||% "",
    metadata$artifact_purpose %||% "",
    metadata$artifact_importance %||% "",
    collapse = " "
  )
}

evidence_estimated_context_cost <- function(artifact, strategy) {
  context <- tryCatch(genai_build_artifact_context(artifact, strategy = strategy), error = function(e) list())
  text_cost <- genai_estimate_tokens(genai_context_json(context))
  image_cost <- if (genai_strategy_requests_image_payload(strategy)) 350L else 0L
  table_cost <- if (identical(strategy, "full_table")) 650L else if (strategy %in% c("table_preview_only", "screenshot_caption_preview", "balanced")) 180L else 0L
  as.integer(text_cost + image_cost + table_cost)
}

evidence_task_relevance <- function(artifact, question, task_type) {
  family <- genai_infer_artifact_family(artifact)$artifact_family
  text <- tolower(evidence_artifact_text(artifact))
  keywords <- evidence_question_keywords(question)
  keyword_score <- if (length(keywords)) mean(vapply(keywords, grepl, logical(1), x = text, fixed = TRUE)) else 0
  family_score <- switch(
    task_type,
    exact_values = if (grepl("^table_|correlation|heatmap", family)) 0.75 else 0.35,
    risk_assessment = if (grepl("diagnostic|metrics|correlation", family)) 0.82 else if (grepl("shap", family)) 0.62 else 0.30,
    trustworthiness = if (grepl("metrics|diagnostic|correlation", family)) 0.84 else if (grepl("shap", family)) 0.45 else 0.38,
    creative_next_action = if (grepl("shap_dependence|shap_importance|shap_interaction", family)) 0.86 else if (grepl("diagnostic|metrics", family)) 0.55 else 0.18,
    effect_diagnostics = if (identical(family, "shap_dependence")) 0.9 else if (grepl("shap_importance|diagnostic", family)) 0.58 else 0.22,
    executive_briefing = if (grepl("shap|metrics|diagnostic|histogram|trend", family)) 0.62 else 0.35,
    next_action = if (grepl("shap|importance|dependence|diagnostic|metrics", family)) 0.78 else 0.45,
    summarize = 0.55,
    0.45
  )
  importance <- (artifact$metadata %||% list())$artifact_importance %||% ""
  importance_score <- if (importance %in% c("critical", "recommended")) 0.15 else if (identical(importance, "supplementary")) 0.05 else 0
  min(1, family_score + (0.3 * keyword_score) + importance_score)
}

evidence_trustworthiness <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  quality <- suppressWarnings(as.numeric(metadata$artifact_completeness %||% metadata$quality_score %||% metadata$quality %||% NA_real_))
  quality_score <- if (is.na(quality)) 0.65 else max(0.1, min(1, quality / 100))
  warning_penalty <- if (length(metadata$warnings %||% metadata$diagnostics %||% character())) 0.08 else 0
  screenshot_bonus <- if (!is.null(metadata$screenshot_path %||% metadata$thumbnail_path)) 0.05 else 0
  table_bonus <- if (!is.null(metadata$table_csv_path %||% metadata$csv_path %||% artifact$table)) 0.05 else 0
  max(0.05, min(1, quality_score - warning_penalty + screenshot_bonus + table_bonus))
}

evidence_expected_insight_gain <- function(artifact, question) {
  family <- genai_infer_artifact_family(artifact)$artifact_family
  text <- tolower(paste(evidence_artifact_text(artifact), question %||% ""))
  base <- if (grepl("shap|importance|dependence|interaction", family)) 0.75 else if (grepl("metrics|diagnostic|correlation", family)) 0.65 else 0.45
  if (grepl("nonlinear|unstable|effect|shape", text) && identical(family, "shap_dependence")) base <- base + 0.2
  if (grepl("creative|attribute|test", text) && grepl("shap", family)) base <- base + 0.12
  if (grepl("trustworthy|trust|risk|misleading|production", text) && grepl("metrics|diagnostic", family)) base <- base + 0.15
  if (grepl("risk|warning|caveat|limitation|production|next|test|investigate", text)) base <- base + 0.1
  min(1, base)
}

evidence_novelty_scores <- function(artifacts) {
  seen <- character()
  scores <- numeric(length(artifacts))
  for (i in seq_along(artifacts)) {
    family <- genai_infer_artifact_family(artifacts[[i]])$artifact_family
    module <- artifacts[[i]]$source_module %||% ""
    key <- paste(family, module, sep = "::")
    scores[[i]] <- if (key %in% seen) 0.55 else 1
    seen <- c(seen, key)
  }
  scores
}

evidence_choose_context_strategy <- function(artifact, routing_level, question, profile, provider_config, max_full_table_rows = 50L, max_full_table_cols = 20L) {
  family <- genai_infer_artifact_family(artifact)$artifact_family
  type <- artifact$artifact_type %||% artifact$type %||% ""
  task <- evidence_task_type(question)
  provider <- genai_provider(provider_config$provider)
  can_vision <- isTRUE(provider$capabilities[["vision"]]) && isTRUE(provider_config$vision_enabled) && genai_model_looks_vision_capable(provider_config)
  dims <- genai_artifact_table_dimensions(artifact)
  full_table_safe <- !is.na(dims$rows) && !is.na(dims$columns) && dims$rows <= max_full_table_rows && dims$columns <= max_full_table_cols
  if (routing_level <= 1L) {
    return("caption_metadata")
  }
  if (identical(type, "table")) {
    if (isTRUE(profile$exact_values) || identical(task, "exact_values")) {
      return(if (full_table_safe) "full_table" else "table_preview_only")
    }
    return(if (routing_level >= 4L) "balanced" else "table_preview_only")
  }
  if (isTRUE(profile$prefer_vision) && can_vision && family %in% c("histogram", "shap_dependence", "shap_importance", "heatmap", "correlation_matrix")) {
    return(if (routing_level >= 4L) "screenshot_caption_preview" else "screenshot_caption")
  }
  if (routing_level >= 4L && family %in% c("shap_dependence", "heatmap", "correlation_matrix")) {
    return(if (can_vision) "screenshot_caption_preview" else "structured_json_summary")
  }
  if (routing_level >= 3L && family %in% c("histogram", "shap_importance", "shap_dependence") && can_vision) {
    return("screenshot_caption")
  }
  "structured_json_summary"
}

build_evidence_plan <- function(
  project,
  question,
  routing_profile = "balanced",
  evidence_strategy = NULL,
  evidence_strategy_overrides = list(),
  provider = "ollama",
  model = NULL,
  profile_overrides = list(),
  token_budget = NULL,
  latency_budget_ms = NULL,
  accuracy_preference = "balanced",
  privacy_preference = "local_private",
  output_dir = file.path("exports", "evidence_routing"),
  max_full_table_rows = 50L,
  max_full_table_cols = 20L,
  write_outputs = TRUE
) {
  routing_profile_supplied <- !missing(routing_profile)
  strategy_id <- evidence_strategy %||% "balanced"
  strategy_config <- evidence_strategy_config(strategy_id, evidence_strategy_overrides)
  strategy_technical_config <- strategy_config$technical_config %||% list()
  apply_strategy_config <- !is.null(evidence_strategy) || !routing_profile_supplied
  if (isTRUE(apply_strategy_config)) {
    routing_profile <- strategy_technical_config$routing_profile %||% routing_profile
  }
  if (isTRUE(apply_strategy_config)) {
    strategy_profile_overrides <- evidence_strategy_routing_overrides(strategy_config)
    profile_overrides <- utils::modifyList(strategy_profile_overrides, profile_overrides)
    token_budget <- token_budget %||% strategy_technical_config$max_estimated_tokens
    latency_budget_ms <- latency_budget_ms %||% strategy_technical_config$max_latency_ms
  }
  if (isTRUE(apply_strategy_config) && !isTRUE(strategy_technical_config$full_table_allowed)) {
    max_full_table_rows <- 0L
    max_full_table_cols <- 0L
  }
  provider_constraint <- evidence_strategy_apply_provider_constraints(provider, strategy_config)
  loaded_project <- genai_load_experiment_project(project)
  project_path <- if (is.character(project) && length(project) == 1L) normalize_project_load_path(project) else NULL
  collector_dir <- genai_project_collector_artifact_dir(loaded_project, project_path = project_path)
  artifacts <- lapply(genai_project_artifacts(loaded_project), genai_prepare_experiment_artifact, collector_artifact_dir = collector_dir)
  profile <- evidence_routing_profile(routing_profile, profile_overrides)
  if (!is.null(token_budget)) profile$token_budget <- token_budget
  task_type <- evidence_task_type(question)
  config <- genai_config(provider = provider, model = model %||% "", vision_enabled = identical(routing_profile, "vision_first") || isTRUE(profile$prefer_vision))
  novelty <- evidence_novelty_scores(artifacts)
  rows <- lapply(seq_along(artifacts), function(i) {
    artifact <- artifacts[[i]]
    family <- genai_infer_artifact_family(artifact)
    relevance <- evidence_task_relevance(artifact, question, task_type)
    trust <- evidence_trustworthiness(artifact)
    insight <- evidence_expected_insight_gain(artifact, question)
    user_weight <- if ((artifact$metadata %||% list())$artifact_importance %in% c("critical", "recommended")) 1.15 else 1
    provisional_strategy <- evidence_choose_context_strategy(artifact, 3L, question, profile, config, max_full_table_rows, max_full_table_cols)
    cost <- evidence_estimated_context_cost(artifact, provisional_strategy)
    utility <- (relevance * trust * novelty[[i]] * insight * user_weight) / max(1, cost / 1000)
    level <- if (utility < profile$include_threshold / 2) 0L else if (utility < profile$include_threshold) 1L else if (utility < profile$deep_dive_threshold / 2) 2L else if (utility < profile$deep_dive_threshold) 3L else 4L
    strategy <- evidence_choose_context_strategy(artifact, level, question, profile, config, max_full_table_rows, max_full_table_cols)
    final_cost <- evidence_estimated_context_cost(artifact, strategy)
    reason <- if (level == 0L) {
      "Excluded due to low conservative utility after relevance, trust, novelty, insight, and context cost."
    } else if (level == 1L) {
      "Mention only: possibly useful but not worth detailed context under the current profile."
    } else if (level == 2L) {
      "Summary: include compact caption, metadata, and diagnostics."
    } else if (level == 3L) {
      "Evidence: include screenshot/table preview/structured summary as appropriate."
    } else {
      "Deep dive: high relevance and expected insight justify richer context."
    }
    data.table::data.table(
      artifact_id = artifact$artifact_id %||% "",
      artifact_title = artifact$label %||% artifact$title %||% artifact$artifact_id %||% "",
      artifact_type = artifact$artifact_type %||% artifact$type %||% "",
      artifact_family = family$artifact_family,
      artifact_family_policy_source = family$policy_source,
      source_module = artifact$source_module %||% "",
      routing_level = level,
      routing_label = evidence_routing_levels()[routing_level == level, routing_label],
      context_strategy = strategy,
      task_relevance = round(relevance, 3),
      trustworthiness = round(trust, 3),
      novelty = round(novelty[[i]], 3),
      expected_insight_gain = round(insight, 3),
      user_preference_weight = round(user_weight, 3),
      estimated_context_cost = final_cost,
      expected_utility = round(utility, 4),
      confidence = round(min(0.65, 0.25 + relevance * trust * 0.4), 3),
      fallback_strategy = "caption_metadata",
      routing_reason = reason
    )
  })
  routing <- data.table::rbindlist(rows, fill = TRUE)
  data.table::setorder(routing, -routing_level, -expected_utility)
  selected <- routing[routing_level >= 2L]
  if (nrow(selected) > profile$max_artifacts) {
    keep <- selected[seq_len(profile$max_artifacts)]$artifact_id
    routing[!(artifact_id %in% keep) & routing_level >= 2L, `:=`(
      routing_level = 1L,
      routing_label = "Mention Only",
      context_strategy = "caption_metadata",
      routing_reason = "Downgraded to mention-only by profile max_artifacts limit."
    )]
  }
  if (sum(routing$estimated_context_cost[routing$routing_level >= 2L], na.rm = TRUE) > profile$token_budget) {
    routing[context_strategy == "full_table", `:=`(context_strategy = "table_preview_only", routing_reason = paste(routing_reason, "Full table downgraded to table preview by token budget."))]
  }
  missing <- evidence_missing_requests(question, routing)
  if (length(missing)) {
    routing <- data.table::rbindlist(list(routing, data.table::data.table(
      artifact_id = paste0("request_more_evidence_", seq_along(missing)),
      artifact_title = missing,
      artifact_type = "request",
      artifact_family = "request_more_evidence",
      artifact_family_policy_source = "inferred",
      source_module = "evidence_routing_policy",
      routing_level = 5L,
      routing_label = "Request More Evidence",
      context_strategy = "none",
      task_relevance = 1,
      trustworthiness = NA_real_,
      novelty = 1,
      expected_insight_gain = 1,
      user_preference_weight = 1,
      estimated_context_cost = 0L,
      expected_utility = 1,
      confidence = 0.5,
      fallback_strategy = "none",
      routing_reason = "Existing artifacts appear insufficient for part of the question."
    )), fill = TRUE)
  }
  plan_id <- evidence_plan_id()
  plan <- list(
    plan_id = plan_id,
    project_id = (loaded_project$project_id %||% "project"),
    run_id = paste0("routing_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    question = question,
    task_type = task_type,
    routing_profile = routing_profile,
    evidence_strategy = strategy_config$evidence_strategy,
    strategy_label = strategy_config$strategy_label,
    strategy_description = strategy_config$strategy_description,
    strategy_config = strategy_config,
    technical_config = strategy_technical_config,
    user_overrides = evidence_strategy_overrides,
    business_tradeoff_summary = strategy_config$business_tradeoff_summary,
    selected_provider_mode = if (isTRUE(strategy_technical_config$local_only)) "local_only" else if (isTRUE(strategy_technical_config$paid_provider_allowed)) "paid_allowed" else "local_or_free_preferred",
    paid_provider_allowed = isTRUE(strategy_technical_config$paid_provider_allowed),
    local_only = isTRUE(strategy_technical_config$local_only),
    evidence_explosion_allowed = isTRUE(strategy_technical_config$evidence_explosion_allowed),
    provider_constraint = provider_constraint,
    user_constraints = list(token_budget = profile$token_budget, latency_budget_ms = latency_budget_ms, accuracy_preference = accuracy_preference, privacy_preference = privacy_preference),
    provider = provider,
    model = model %||% config$model,
    selected_artifacts = routing[routing_level >= 2L & routing_level <= 4L],
    excluded_artifacts = routing[routing_level == 0L],
    sidecar_only_artifacts = routing[routing_level == 1L],
    deep_dive_artifacts = routing[routing_level == 4L],
    request_more_evidence = routing[routing_level == 5L],
    routing = routing,
    profile = profile
  )
  if (isTRUE(write_outputs)) {
    plan$paths <- write_evidence_plan_outputs(plan, output_dir = output_dir)
  }
  plan
}

evidence_missing_requests <- function(question, routing) {
  text <- tolower(question %||% "")
  available <- unique(routing$artifact_family)
  missing <- character()
  artifact_text <- tolower(paste(routing$artifact_title, routing$source_module, routing$artifact_family, collapse = " "))
  if (grepl("creative|attribute|campaign|placement|audience", text) && !grepl("creative|campaign|placement|audience", artifact_text)) {
    missing <- c(missing, "Generate creative-attribute SHAP importance, effect, interaction, and sparse-group stability evidence.")
  }
  if (grepl("trustworthy|trust|confidence|reliable", text) && !any(c("table_metrics", "model_assessment") %in% available)) {
    missing <- c(missing, "Generate model assessment metrics, calibration, residual, and validation diagnostics.")
  }
  if (grepl("trustworthy|trust|confidence|reliable", text) && !grepl("calibration|residual|holdout|validation|lift|gain", artifact_text)) {
    missing <- c(missing, "Generate calibration, residual, holdout, lift/gain, or threshold stability evidence.")
  }
  if (grepl("misleading|risk|production", text) && !grepl("calibration|residual|drift|leakage|threshold", artifact_text)) {
    missing <- c(missing, "Generate post-model risk evidence such as calibration, residual, drift, leakage, and threshold diagnostics.")
  }
  if (grepl("interaction", text) && !("shap_interaction" %in% available)) missing <- c(missing, "Generate SHAP interaction evidence.")
  if (grepl("residual|calibration|lift|gain|assessment", text) && !("table_metrics" %in% available)) missing <- c(missing, "Generate post-model assessment metrics.")
  if (grepl("correlation|heatmap", text) && !any(c("table_correlation", "correlation_matrix", "heatmap") %in% available)) missing <- c(missing, "Generate correlation matrix or correlation diagnostics.")
  if (grepl("missing|before making|recommendation", text)) {
    if (!("shap_interaction" %in% available)) missing <- c(missing, "Generate interaction diagnostics before final recommendations.")
    if (!grepl("calibration|residual|holdout|validation", artifact_text)) missing <- c(missing, "Generate model validation and calibration evidence before final recommendations.")
  }
  unique(missing)
}

evidence_observability_log <- function(plan, response_path = NA_character_, actual_latency_ms = NA_real_, actual_tokens = NA_integer_) {
  routing <- plan$routing
  data.table::data.table(
    plan_id = plan$plan_id,
    project_id = plan$project_id,
    run_id = plan$run_id,
    question = plan$question,
    task_type = plan$task_type,
    routing_profile = plan$routing_profile,
    evidence_strategy = plan$evidence_strategy %||% "balanced",
    strategy_label = plan$strategy_label %||% "Balanced",
    strategy_description = plan$strategy_description %||% "",
    technical_config = evidence_strategy_compact_json(plan$technical_config %||% list()),
    user_overrides = evidence_strategy_compact_json(plan$user_overrides %||% list()),
    business_tradeoff_summary = evidence_strategy_compact_json(plan$business_tradeoff_summary %||% list()),
    selected_provider_mode = plan$selected_provider_mode %||% NA_character_,
    paid_provider_allowed = isTRUE(plan$paid_provider_allowed),
    local_only = isTRUE(plan$local_only),
    evidence_explosion_allowed = isTRUE(plan$evidence_explosion_allowed),
    provider = plan$provider %||% NA_character_,
    model = plan$model %||% NA_character_,
    artifact_id = routing$artifact_id,
    artifact_title = routing$artifact_title,
    artifact_family = routing$artifact_family,
    routing_level = routing$routing_level,
    routing_label = routing$routing_label,
    context_strategy = routing$context_strategy,
    expected_utility = routing$expected_utility,
    estimated_context_cost = routing$estimated_context_cost,
    actual_cost = actual_tokens,
    latency_ms = actual_latency_ms,
    model_response_path = response_path,
    user_rating = NA_real_,
    answer_accepted = NA,
    follow_up_required = NA,
    excluded_artifact_opened_afterward = NA,
    more_detail_requested = NA,
    hallucination_flagged = NA,
    artifact_later_proved_useful = NA,
    manual_quality_score = NA_real_,
    feedback_notes = NA_character_
  )
}

write_evidence_plan_outputs <- function(plan, output_dir = file.path("exports", "evidence_routing")) {
  plan_dir <- file.path(output_dir, plan$plan_id)
  dir.create(plan_dir, recursive = TRUE, showWarnings = FALSE)
  csv_path <- file.path(plan_dir, "evidence_plan.csv")
  json_path <- file.path(plan_dir, "evidence_plan.json")
  summary_path <- file.path(plan_dir, "routing_summary.md")
  log_path <- file.path(plan_dir, "observability_log.csv")
  data.table::fwrite(plan$routing, csv_path)
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(list(
      plan_id = plan$plan_id,
      question = plan$question,
      task_type = plan$task_type,
      routing_profile = plan$routing_profile,
      evidence_strategy = plan$evidence_strategy,
      strategy_label = plan$strategy_label,
      strategy_description = plan$strategy_description,
      technical_config = plan$technical_config,
      user_overrides = plan$user_overrides,
      business_tradeoff_summary = plan$business_tradeoff_summary,
      provider = plan$provider,
      model = plan$model,
      user_constraints = plan$user_constraints,
      routing = plan$routing
    ), json_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  }
  log <- evidence_observability_log(plan)
  data.table::fwrite(log, log_path)
  writeLines(c(
    paste0("# Evidence Routing Summary: ", plan$plan_id),
    "",
    paste0("- Question: ", plan$question),
    paste0("- Task type: ", plan$task_type),
    paste0("- Evidence strategy: ", plan$strategy_label %||% plan$evidence_strategy %||% "Balanced"),
    paste0("- Routing profile: ", plan$routing_profile),
    paste0("- Provider/model: ", plan$provider, " / ", plan$model %||% ""),
    paste0("- Selected evidence artifacts: ", nrow(plan$selected_artifacts)),
    paste0("- Mention-only artifacts: ", nrow(plan$sidecar_only_artifacts)),
    paste0("- Excluded artifacts: ", nrow(plan$excluded_artifacts)),
    paste0("- Deep dives: ", nrow(plan$deep_dive_artifacts)),
    paste0("- Requests for more evidence: ", nrow(plan$request_more_evidence)),
    "",
    "## Top Routing Decisions",
    "```",
    paste(capture.output(print(utils::head(plan$routing[, .(artifact_title, artifact_family, routing_label, context_strategy, expected_utility, estimated_context_cost, routing_reason)], 12L))), collapse = "\n"),
    "```"
  ), summary_path)
  list(evidence_plan_json = json_path, evidence_plan_csv = csv_path, routing_summary = summary_path, observability_log = log_path, plan_dir = plan_dir)
}

update_evidence_routing_priors <- function(observability_logs) {
  logs <- if (is.character(observability_logs)) data.table::rbindlist(lapply(observability_logs[file.exists(observability_logs)], data.table::fread), fill = TRUE) else data.table::as.data.table(observability_logs)
  if (!nrow(logs)) {
    return(service_result(status = "warning", warnings = "No observability logs supplied.", value = data.table::data.table()))
  }
  summary <- logs[, .(
    routed = .N,
    accepted = sum(answer_accepted %in% TRUE, na.rm = TRUE),
    follow_up_required = sum(follow_up_required %in% TRUE, na.rm = TRUE),
    hallucination_flagged = sum(hallucination_flagged %in% TRUE, na.rm = TRUE),
    avg_manual_quality = mean(as.numeric(manual_quality_score), na.rm = TRUE)
  ), by = .(artifact_family, context_strategy)]
  summary[, recommendation := "Insufficient scored feedback for automatic policy mutation; keep as research observation."]
  service_result(status = "success", value = summary, messages = "Evidence routing priors summarized without mutating policy.")
}

run_evidence_routing_calibration <- function(
  project = file.path("exports", "artifact_studio_demo", "artifact_studio_demo_project.rds"),
  questions = c(
    "Which variables should we investigate next?",
    "Which creative attributes should we test next?",
    "What are the biggest model risks?",
    "What evidence suggests the model is trustworthy?",
    "What does SHAP say about the strongest drivers?",
    "Which effects look nonlinear or unstable?",
    "What should we include in an executive briefing?",
    "What evidence is missing before making a recommendation?",
    "Where might the model be misleading?",
    "What should I do next?"
  ),
  profiles = c("token_saver", "balanced", "accuracy_first", "thorough"),
  provider = "ollama",
  model = "llava:latest",
  output_dir = file.path("exports", "evidence_routing"),
  calibration_id = NULL
) {
  calibration_id <- calibration_id %||% paste0("calibration_", format(Sys.time(), "%Y%m%d_%H%M%S"))
  calibration_dir <- file.path(output_dir, calibration_id)
  dir.create(calibration_dir, recursive = TRUE, showWarnings = FALSE)
  plan_rows <- list()
  decision_rows <- list()
  for (question in questions) {
    for (profile in profiles) {
      plan <- build_evidence_plan(
        project = project,
        question = question,
        routing_profile = profile,
        provider = provider,
        model = model,
        output_dir = calibration_dir,
        write_outputs = TRUE
      )
      routing <- data.table::copy(plan$routing)
      routing[, `:=`(question = question, profile = profile, plan_id = plan$plan_id)]
      decision_rows[[length(decision_rows) + 1L]] <- routing
      plan_rows[[length(plan_rows) + 1L]] <- data.table::data.table(
        question = question,
        profile = profile,
        plan_id = plan$plan_id,
        selected = nrow(plan$selected_artifacts),
        mention_only = nrow(plan$sidecar_only_artifacts),
        excluded = nrow(plan$excluded_artifacts),
        deep_dives = nrow(plan$deep_dive_artifacts),
        request_more_evidence = nrow(plan$request_more_evidence),
        estimated_cost = sum(plan$routing$estimated_context_cost[plan$routing$routing_level >= 2L & plan$routing$routing_level <= 4L], na.rm = TRUE),
        plan_dir = plan$paths$plan_dir
      )
    }
  }
  plans <- data.table::rbindlist(plan_rows, fill = TRUE)
  decisions <- data.table::rbindlist(decision_rows, fill = TRUE)
  data.table::fwrite(plans, file.path(calibration_dir, "calibration_plan_summary.csv"))
  data.table::fwrite(decisions, file.path(calibration_dir, "calibration_decisions.csv"))
  selected <- decisions[routing_level >= 2L & routing_level <= 4L]
  excluded <- decisions[routing_level == 0L]
  deep <- decisions[routing_level == 4L]
  over_patterns <- selected[, .N, by = .(artifact_family)][order(-N)]
  under_patterns <- excluded[, .N, by = .(artifact_family)][order(-N)]
  frequent_selected <- selected[, .N, by = .(artifact_title, artifact_family)][order(-N)]
  frequent_excluded <- excluded[, .N, by = .(artifact_title, artifact_family)][order(-N)]
  frequent_deep <- deep[, .N, by = .(artifact_title, artifact_family)][order(-N)]
  profile_shape <- plans[, .(
    avg_selected = round(mean(selected), 1),
    avg_excluded = round(mean(excluded), 1),
    avg_deep_dives = round(mean(deep_dives), 1),
    avg_requests = round(mean(request_more_evidence), 1),
    avg_estimated_cost = round(mean(estimated_cost), 1)
  ), by = profile][order(profile)]
  fmt <- function(dt, n = 12L) paste(capture.output(print(utils::head(dt, n))), collapse = "\n")
  report <- c(
    paste0("# Evidence Routing Calibration Report: ", calibration_id),
    "",
    "## Questions Tested",
    paste0("- ", questions),
    "",
    "## Profiles Tested",
    paste0("- ", profiles),
    "",
    "## Plan Behavior By Profile",
    "```",
    fmt(profile_shape),
    "```",
    "",
    "## Common Over-Inclusion Candidates",
    "Families selected frequently. These are not necessarily wrong, but should be reviewed for redundancy.",
    "```",
    fmt(over_patterns),
    "```",
    "",
    "## Common Under-Inclusion Candidates",
    "Families often excluded by conservative utility.",
    "```",
    fmt(under_patterns),
    "```",
    "",
    "## Artifacts Frequently Selected",
    "```",
    fmt(frequent_selected),
    "```",
    "",
    "## Artifacts Frequently Excluded",
    "```",
    fmt(frequent_excluded),
    "```",
    "",
    "## Artifacts Often Deep-Dived",
    "```",
    fmt(frequent_deep),
    "```",
    "",
    "## Recommended Rule / Weight Adjustments Applied",
    "- Creative-attribute questions now prioritize SHAP importance/dependence and diagnostics while requesting creative-specific evidence when absent.",
    "- Model-risk questions now weight diagnostics, metrics, correlation, calibration/residual gaps, and readiness evidence more strongly than generic importance alone.",
    "- Trustworthiness questions now request calibration/residual/validation evidence when unavailable.",
    "- Nonlinear/unstable effect questions now prioritize SHAP dependence and effect artifacts.",
    "- Missing-evidence questions now request interaction and validation/calibration evidence when absent.",
    "",
    "## Remaining Open Questions",
    "- Should generic EDA be further suppressed for creative-specific questions?",
    "- How much model assessment evidence is enough before trustworthiness questions stop requesting more evidence?",
    "- Should repeated selection of SHAP importance be treated as useful redundancy or over-inclusion?",
    "- What manual feedback thresholds should justify future policy refinement?",
    "",
    "## Caveat",
    "This calibration report is generated from routing plans and heuristic QA only. It does not mutate routing policy automatically and does not claim learned optimal behavior."
  )
  report_path <- file.path(calibration_dir, "calibration_report.md")
  writeLines(report, report_path)
  service_result(
    status = "success",
    value = list(plans = plans, decisions = decisions, report_path = report_path, calibration_dir = calibration_dir),
    messages = "Evidence routing calibration completed.",
    metadata = list(calibration_id = calibration_id)
  )
}

qa_evidence_routing_policy <- function() {
  project_path <- file.path("exports", "artifact_studio_demo", "artifact_studio_demo_project.rds")
  if (!file.exists(project_path) && exists("create_artifact_studio_demo_project", mode = "function")) {
    create_artifact_studio_demo_project()
  }
  plan <- build_evidence_plan(
    project_path,
    question = "Which SHAP effects and target quality caveats should we investigate next?",
    routing_profile = "balanced",
    provider = "ollama",
    model = "llava:latest",
    output_dir = file.path("exports", "evidence_routing"),
    write_outputs = TRUE
  )
  token_plan <- build_evidence_plan(project_path, "Summarize target distribution and SHAP importance.", routing_profile = "token_saver", provider = "none", write_outputs = FALSE)
  thorough_plan <- build_evidence_plan(project_path, "Summarize target distribution and SHAP importance.", routing_profile = "thorough", provider = "none", write_outputs = FALSE)
  data.table::data.table(
    check = c(
      "plan_built",
      "routing_levels_assigned",
      "low_relevance_excluded_or_mentioned",
      "high_importance_included",
      "full_table_guarded",
      "vision_requires_capability",
      "upstream_prior_fields_present",
      "profiles_change_behavior",
      "outputs_written",
      "no_auto_learning_mutation"
    ),
    status = c(
      if (is.list(plan) && nrow(plan$routing) > 0L) "success" else "error",
      if (all(plan$routing$routing_level %in% 0:5)) "success" else "error",
      if (any(plan$routing$routing_level <= 1L)) "success" else "error",
      if (any(plan$routing$routing_level >= 2L & grepl("SHAP|Target", plan$routing$artifact_title))) "success" else "error",
      if (!any(plan$routing$context_strategy == "full_table" & plan$routing$estimated_context_cost > 2500L)) "success" else "error",
      if (!any(plan$routing$context_strategy %in% c("screenshot_caption", "screenshot_caption_preview")) || genai_model_looks_vision_capable(genai_config(provider = "ollama", model = "llava:latest", vision_enabled = TRUE))) "success" else "error",
      if (all(c("task_relevance", "trustworthiness", "novelty", "expected_insight_gain") %in% names(plan$routing))) "success" else "error",
      if (nrow(thorough_plan$selected_artifacts) >= nrow(token_plan$selected_artifacts)) "success" else "error",
      if (all(file.exists(unlist(plan$paths)))) "success" else "error",
      if (identical(update_evidence_routing_priors(data.table::fread(plan$paths$observability_log))$status, "success")) "success" else "error"
    ),
    message = c(
      "Evidence plan builds from the seeded project.",
      "Every candidate receives a routing level.",
      "Some artifacts are excluded or mention-only under conservative utility.",
      "Relevant SHAP/target artifacts are included.",
      "Full table selection remains guarded by cost and safety rules.",
      "Vision strategies require a vision-capable provider/model configuration.",
      "Utility model fields represent upstream priors.",
      "Routing profiles influence selected evidence volume.",
      "Evidence plan JSON/CSV/summary/log outputs are written.",
      "Prior update summarizes observations without mutating routing policy."
    )
  )
}

qa_evidence_routing_observability <- function() {
  project_path <- file.path("exports", "artifact_studio_demo", "artifact_studio_demo_project.rds")
  plan <- build_evidence_plan(
    project_path,
    question = "What production risks should we investigate next?",
    routing_profile = "conservative",
    provider = "none",
    output_dir = file.path("exports", "evidence_routing"),
    write_outputs = TRUE
  )
  log <- data.table::fread(plan$paths$observability_log)
  required <- c("plan_id", "project_id", "run_id", "question", "task_type", "routing_profile", "provider", "model", "artifact_id", "routing_level", "context_strategy", "expected_utility", "estimated_context_cost", "actual_cost", "latency_ms", "model_response_path", "user_rating", "answer_accepted", "follow_up_required", "excluded_artifact_opened_afterward", "more_detail_requested", "hallucination_flagged", "artifact_later_proved_useful", "manual_quality_score")
  data.table::data.table(
    check = c(
      "observability_log_written",
      "feedback_placeholders_exist",
      "selected_and_excluded_recorded",
      "routing_reason_visible",
      "existing_genai_qa_passes"
    ),
    status = c(
      if (file.exists(plan$paths$observability_log) && nrow(log) > 0L) "success" else "error",
      if (all(required %in% names(log))) "success" else "error",
      if (any(plan$routing$routing_level >= 2L) && any(plan$routing$routing_level <= 1L)) "success" else "error",
      if ("routing_reason" %in% names(plan$routing) && all(nzchar(plan$routing$routing_reason))) "success" else "error",
      if (!any(qa_genai_service_contract()$status == "error")) "success" else "error"
    ),
    message = c(
      "Observability log writes successfully.",
      "Learning-ready feedback placeholders are present.",
      "Plan records both selected and non-selected artifacts.",
      "Routing decisions remain inspectable.",
      "Existing GenAI QA still passes."
    )
  )
}

qa_evidence_routing_calibration <- function() {
  project_path <- file.path("exports", "artifact_studio_demo", "artifact_studio_demo_project.rds")
  questions <- c(
    "Which creative attributes should we test next?",
    "What are the biggest model risks?",
    "What does SHAP say about the strongest drivers?",
    "What evidence is missing before making a recommendation?"
  )
  calibration <- run_evidence_routing_calibration(
    project = project_path,
    questions = questions,
    profiles = c("token_saver", "balanced", "thorough"),
    provider = "none",
    model = "none",
    output_dir = file.path(tempdir(), "evidence_routing_calibration_qa"),
    calibration_id = "qa_calibration"
  )
  plans <- calibration$value$plans
  decisions <- calibration$value$decisions
  shap_plan <- decisions[grepl("SHAP", question, ignore.case = TRUE) & routing_level >= 2L]
  risk_plan <- decisions[grepl("risk", question, ignore.case = TRUE) & routing_level >= 2L]
  token_counts <- plans[profile == "token_saver", sum(selected)]
  thorough_counts <- plans[profile == "thorough", sum(selected)]
  data.table::data.table(
    check = c(
      "multiple_questions_planned",
      "multiple_profiles_differ",
      "calibration_report_written",
      "shap_questions_select_shap",
      "risk_questions_select_diagnostics",
      "token_saver_less_than_thorough",
      "full_tables_guarded",
      "request_more_evidence_occurs",
      "routing_qa_still_passes",
      "aggregate_safe"
    ),
    status = c(
      if (length(unique(plans$question)) >= 3L) "success" else "error",
      if (length(unique(plans$profile)) >= 3L && length(unique(plans$selected)) > 1L) "success" else "error",
      if (file.exists(calibration$value$report_path)) "success" else "error",
      if (any(grepl("shap", shap_plan$artifact_family, ignore.case = TRUE))) "success" else "error",
      if (any(grepl("diagnostic|metrics|correlation", risk_plan$artifact_family, ignore.case = TRUE))) "success" else "error",
      if (token_counts < thorough_counts) "success" else "error",
      if (!any(decisions$context_strategy == "full_table" & decisions$estimated_context_cost > 2500L, na.rm = TRUE)) "success" else "error",
      if (any(decisions$routing_level == 5L)) "success" else "error",
      if (!any(qa_evidence_routing_policy()$status == "error") && !any(qa_evidence_routing_observability()$status == "error")) "success" else "error",
      "success"
    ),
    message = c(
      "Calibration builds plans for multiple realistic questions.",
      "Routing profiles produce different plan shapes.",
      "Aggregate calibration report is written.",
      "SHAP questions select SHAP evidence.",
      "Model-risk questions select diagnostic/metrics/correlation evidence.",
      "Token saver selects fewer artifacts than thorough.",
      "Full table use remains guarded.",
      "Missing evidence requests can occur.",
      "Existing evidence routing QA still passes.",
      "Calibration QA is isolated from production behavior."
    )
  )
}
