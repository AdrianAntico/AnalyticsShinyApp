context_optimization_layers <- function() {
  data.table::data.table(
    layer_id = 1:5,
    layer_key = c(
      "deterministic_knowledge",
      "evidence_routing",
      "probabilistic_routing",
      "probabilistic_reasoning",
      "learning_observability"
    ),
    layer_name = c(
      "Deterministic Knowledge",
      "Evidence Routing",
      "Probabilistic Routing",
      "Probabilistic Reasoning",
      "Learning and Observability"
    ),
    execution_type = c("deterministic", "deterministic", "optional_probabilistic", "probabilistic", "observational"),
    genai_allowed = c(FALSE, FALSE, TRUE, TRUE, FALSE),
    paid_genai_required = c(FALSE, FALSE, FALSE, FALSE, FALSE),
    mutates_policy = c(FALSE, FALSE, FALSE, FALSE, FALSE),
    purpose = c(
      "Use artifact metadata, quality, provider capabilities, safety limits, and cost estimates before model calls.",
      "Build explainable evidence plans from deterministic utility, profile, and strategy rules.",
      "Optionally use a model only when deterministic routing is uncertain.",
      "Reason over the optimized evidence bundle after routing has reduced context.",
      "Record outcomes, feedback, costs, latency, and manual scores without automatic production mutation."
    )
  )
}

context_optimization_profiles <- function() {
  data.table::data.table(
    optimization_profile = c(
      "conservative",
      "balanced",
      "accuracy_first",
      "token_saver",
      "vision_first",
      "local_private",
      "critical_decision"
    ),
    routing_profile = c(
      "conservative",
      "balanced",
      "accuracy_first",
      "token_saver",
      "vision_first",
      "local_private",
      "thorough"
    ),
    optimization_goal = c(
      "Prefer compact, high-confidence evidence.",
      "Balance utility, cost, and coverage.",
      "Prefer richer diagnostic support when cost is acceptable.",
      "Minimize unnecessary context while preserving key evidence.",
      "Prefer image-capable strategies when provider capabilities allow it.",
      "Prefer local and privacy-preserving providers and sidecar references.",
      "Broaden evidence coverage for high-stakes interpretation."
    )
  )
}

context_optimization_profile <- function(profile = "balanced") {
  profiles <- context_optimization_profiles()
  selected <- profiles[optimization_profile == profile]
  if (!nrow(selected)) selected <- profiles[optimization_profile == "balanced"]
  as.list(selected[1])
}

context_deterministic_knowledge <- function(project, question, provider = "none", model = NULL, routing_profile = "balanced") {
  config <- genai_config(provider = provider, model = model %||% "", vision_enabled = identical(routing_profile, "vision_first"))
  provider_contract <- genai_provider(provider)
  capabilities <- provider_contract$capabilities %||% genai_capabilities()
  loaded_project <- genai_load_experiment_project(project)
  artifacts <- genai_project_artifacts(loaded_project)
  prepared <- lapply(artifacts, genai_prepare_experiment_artifact)
  rows <- lapply(prepared, function(artifact) {
    family <- genai_infer_artifact_family(artifact)$artifact_family
    metadata <- artifact$metadata %||% list()
    data.table::data.table(
      artifact_id = artifact$artifact_id %||% artifact$id %||% NA_character_,
      artifact_title = artifact$label %||% artifact$title %||% artifact$caption %||% NA_character_,
      artifact_type = artifact$artifact_type %||% artifact$type %||% NA_character_,
      artifact_family = family,
      artifact_importance = metadata$artifact_importance %||% NA_character_,
      analytical_intent = metadata$analytical_intent %||% NA_character_,
      quality_score = suppressWarnings(as.numeric(metadata$artifact_completeness %||% metadata$quality_score %||% NA_real_)),
      screenshot_available = nzchar(artifact$screenshot_path %||% ""),
      table_sidecar_available = nzchar(artifact$table_path %||% artifact$csv_path %||% ""),
      json_sidecar_available = nzchar(artifact$json_path %||% "")
    )
  })
  data.table::data.table(
    question = question,
    provider = provider,
    model = model %||% config$model %||% NA_character_,
      provider_local = isTRUE(capabilities[["local"]]),
      provider_paid = isTRUE(capabilities[["paid"]]),
      provider_vision = isTRUE(capabilities[["vision"]]),
    artifact_count = length(prepared),
    image_capability = genai_model_looks_vision_capable(config),
    estimated_context_available = length(prepared) > 0L,
    deterministic_rows = list(data.table::rbindlist(rows, fill = TRUE))
  )
}

build_context_optimization_plan <- function(
  project,
  question,
  optimization_profile = "balanced",
  evidence_strategy = NULL,
  evidence_strategy_overrides = list(),
  provider = "none",
  model = NULL,
  probabilistic_routing = FALSE,
  allow_paid_genai = FALSE,
  output_dir = file.path("exports", "context_optimization"),
  write_outputs = FALSE
) {
  profile <- context_optimization_profile(optimization_profile)
  strategy_id <- evidence_strategy %||% if (optimization_profile %in% evidence_strategy_ids()) optimization_profile else "balanced"
  strategy_config <- evidence_strategy_config(strategy_id, evidence_strategy_overrides)
  routing_for_plan <- if (!is.null(evidence_strategy)) strategy_config$technical_config$routing_profile %||% profile$routing_profile else profile$routing_profile
  deterministic <- context_deterministic_knowledge(project, question, provider, model, routing_for_plan)
  evidence_plan <- build_evidence_plan(
    project = project,
    question = question,
    routing_profile = routing_for_plan,
    evidence_strategy = strategy_id,
    evidence_strategy_overrides = evidence_strategy_overrides,
    provider = provider,
    model = model,
    output_dir = output_dir,
    write_outputs = write_outputs
  )
  config <- genai_config(provider = provider, model = model %||% "", vision_enabled = identical(routing_for_plan, "vision_first"))
  provider_contract <- genai_provider(provider)
  capabilities <- provider_contract$capabilities %||% genai_capabilities()
  availability <- genai_available(provider, config = config)
  probabilistic_status <- if (!isTRUE(probabilistic_routing)) {
    "skipped_not_requested"
  } else if (isTRUE(capabilities[["paid"]]) && !isTRUE(allow_paid_genai)) {
    "skipped_paid_provider_not_allowed"
  } else if (!identical(availability$status, "success")) {
    "skipped_provider_unavailable"
  } else {
    "eligible_not_executed"
  }
  layer_trace <- context_optimization_layers()
  layer_trace[, status := c(
    "completed",
    "completed",
    probabilistic_status,
    "deferred_until_evidence_selected",
    "completed"
  )]
  layer_trace[, provider := provider]
  layer_trace[, model := model %||% config$model %||% NA_character_]
  layer_trace[, paid_genai_used := FALSE]
  result <- list(
    policy_id = paste0("context_optimization_", format(Sys.time(), "%Y%m%d_%H%M%S")),
    question = question,
    optimization_profile = optimization_profile,
    routing_profile = routing_for_plan,
    optimization_goal = profile$optimization_goal,
    deterministic_knowledge = deterministic,
    evidence_plan = evidence_plan,
    probabilistic_routing_status = probabilistic_status,
    probabilistic_routing_used = FALSE,
    paid_genai_used = FALSE,
    layer_trace = layer_trace,
    explainability = evidence_plan$routing[, .(artifact_id, artifact_title, routing_label, context_strategy, expected_utility, estimated_context_cost, routing_reason)]
  )
  service_result(
    status = "success",
    value = result,
    messages = "Context optimization plan built without autonomous action or policy mutation.",
    metadata = list(
      optimization_profile = optimization_profile,
      routing_profile = routing_for_plan,
      probabilistic_routing_status = probabilistic_status
    )
  )
}

qa_context_optimization_policy <- function() {
  project_path <- file.path("exports", "artifact_studio_demo", "artifact_studio_demo_project.rds")
  if (!file.exists(project_path) && exists("create_artifact_studio_demo_project", mode = "function")) {
    create_artifact_studio_demo_project()
  }
  plan <- build_context_optimization_plan(
    project = project_path,
    question = "What evidence is missing before making a recommendation?",
    optimization_profile = "balanced",
    provider = "none",
    probabilistic_routing = FALSE,
    write_outputs = FALSE
  )$value
  token_plan <- build_context_optimization_plan(
    project = project_path,
    question = "What should I do next?",
    optimization_profile = "token_saver",
    provider = "none",
    write_outputs = FALSE
  )$value
  thorough_plan <- build_context_optimization_plan(
    project = project_path,
    question = "What should I do next?",
    optimization_profile = "critical_decision",
    provider = "none",
    write_outputs = FALSE
  )$value
  layers <- context_optimization_layers()
  trace <- plan$layer_trace
  log <- evidence_observability_log(plan$evidence_plan)
  required_log_fields <- c(
    "plan_id", "question", "routing_profile", "provider", "model", "artifact_id",
    "routing_level", "context_strategy", "expected_utility", "estimated_context_cost",
    "latency_ms", "user_rating", "answer_accepted", "manual_quality_score"
  )
  docs <- if (file.exists(file.path("docs", "context_optimization_policy.md"))) {
    paste(readLines(file.path("docs", "context_optimization_policy.md"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  data.table::data.table(
    check = c(
      "policy_document_exists",
      "deterministic_rules_execute_first",
      "evidence_routing_second",
      "probabilistic_routing_optional",
      "paid_genai_not_required_for_deterministic_reasoning",
      "routing_profiles_influence_optimization",
      "observability_fields_exist",
      "policy_ordering_respected",
      "evidence_plans_remain_explainable",
      "no_automatic_policy_mutation"
    ),
    status = c(
      if (nzchar(docs) && grepl("Never spend probabilistic intelligence on deterministic knowledge", docs, fixed = TRUE)) "success" else "error",
      if (trace[layer_key == "deterministic_knowledge", layer_id] == 1L && trace[layer_key == "deterministic_knowledge", genai_allowed] == FALSE) "success" else "error",
      if (trace[layer_key == "evidence_routing", layer_id] == 2L && trace[layer_key == "evidence_routing", execution_type] == "deterministic") "success" else "error",
      if (identical(plan$probabilistic_routing_status, "skipped_not_requested") && !isTRUE(plan$probabilistic_routing_used)) "success" else "error",
      if (identical(plan$deterministic_knowledge$provider, "none") && !any(trace$paid_genai_used)) "success" else "error",
      if (nrow(thorough_plan$evidence_plan$selected_artifacts) >= nrow(token_plan$evidence_plan$selected_artifacts)) "success" else "error",
      if (all(required_log_fields %in% names(log))) "success" else "error",
      if (identical(layers$layer_key, trace$layer_key) && all(diff(trace$layer_id) > 0)) "success" else "error",
      if (nrow(plan$explainability) > 0L && all(nzchar(plan$explainability$routing_reason))) "success" else "error",
      if (!any(trace$mutates_policy) && identical(update_evidence_routing_priors(log)$status, "success")) "success" else "error"
    ),
    message = c(
      "Context Optimization Policy documentation exists and states the core principle.",
      "Deterministic knowledge is layer 1 and does not allow GenAI.",
      "Evidence routing is layer 2 and remains deterministic.",
      "Probabilistic routing is optional and skipped when not requested.",
      "Deterministic reasoning works without paid GenAI or configured providers.",
      "Optimization profiles produce different evidence coverage.",
      "Evidence observability includes cost, latency, feedback, and manual scoring fields.",
      "Policy layer ordering is explicit and preserved.",
      "Evidence plans expose reasons, strategies, utility, and cost.",
      "Learning summaries do not mutate production routing behavior."
    )
  )
}
