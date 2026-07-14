# Active Knowledge Compilation Runtime Phase 4 overrides.
# The main runtime file preserves prior phase chronology; this file owns the
# current active runtime version and diagnostics shape.

knowledge_runtime_compiler_version <- function() {
  "0.4.0"
}

knowledge_operator_runtime_diagnostics <- function(package, proposal = NULL, validation = NULL, model_tier = NULL, cache_hit = FALSE, fallback = NULL, escalation = NULL) {
  model <- ai_runtime_model_catalog()[tier == (model_tier %||% package$model_tier %||% "local_free_model")][1]
  if (!nrow(model)) model <- ai_runtime_model_catalog()[1]
  scores <- if (!is.null(proposal)) ai_runtime_evaluate_response(proposal, package) else NULL
  qualification <- if (!is.null(scores)) ai_runtime_qualification_from_scores(scores, model, package) else NULL
  list(
    runtime_version = knowledge_runtime_compiler_version(),
    schema_version = knowledge_runtime_schema_version(),
    task_code = package$task_code %||% NA_character_,
    bundle_id = package$bundle_id %||% NA_character_,
    bundle_version = package$bundle_version %||% NA_character_,
    model_tier = model_tier %||% package$model_tier %||% NA_character_,
    token_usage = package$token_accounting %||% list(),
    validation_status = validation$status %||% NA_character_,
    validation_errors = validation$errors %||% character(),
    qualification_status = qualification$qualification_status %||% "unknown",
    qualification_confidence = qualification$confidence %||% 0,
    reason_for_qualification = paste(qualification$required_validation %||% "deterministic validation", collapse = ", "),
    reason_for_rejection = paste(unique(c(validation$errors %||% character(), qualification$weaknesses %||% character())), collapse = "; "),
    retrieval_diagnostics = package$retrieval_diagnostics %||% list(),
    context_sufficiency = package$context_sufficiency$state %||% "unknown",
    retrieved_artifacts = vapply(package$artifact_digests %||% list(), function(x) x$artifact_id %||% "", character(1)),
    benchmark_reference = if (!is.null(qualification)) kc_hash_value(list(qualification = qualification, context = package$context_hash)) else NA_character_,
    fallback = fallback %||% NA_character_,
    escalation = escalation %||% package$escalation_conditions %||% character(),
    cache_hit = isTRUE(cache_hit) || isTRUE(package$cache$bundle_cache_hit),
    context_hash = package$context_hash %||% NA_character_,
    action_proposal = proposal
  )
}

knowledge_runtime_developer_snapshot <- function(ctx = NULL, user_request = "What should I do next?", model_tier = "local_free_model") {
  proposal <- knowledge_operator_propose(ctx = ctx, user_request = user_request, model_tier = model_tier)
  value <- proposal$value %||% list()
  list(
    status = proposal$status,
    task = value$context_package$task_code %||% NA_character_,
    bundle = value$context_package$bundle_id %||% NA_character_,
    context_hash = value$context_package$context_hash %||% NA_character_,
    model_tier = model_tier,
    validation = value$validation$status %||% proposal$status,
    qualification = value$diagnostics$qualification_status %||% "unknown",
    tokens = value$context_package$token_accounting %||% list(),
    proposal = value$proposal %||% list(),
    diagnostics = value$diagnostics %||% list()
  )
}
