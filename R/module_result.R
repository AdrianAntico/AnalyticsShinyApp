module_artifact_counts <- function(artifacts) {
  counts <- list(
    artifact_count = 0L,
    plot_count = 0L,
    table_count = 0L,
    text_count = 0L
  )

  if (is.null(artifacts) || !length(artifacts)) {
    return(counts)
  }

  types <- vapply(artifacts, function(artifact) artifact$artifact_type %||% "", character(1))
  counts$artifact_count <- length(artifacts)
  counts$plot_count <- sum(types == "plot")
  counts$table_count <- sum(types == "table")
  counts$text_count <- sum(types == "text")
  counts
}

module_artifact_metadata <- function(
  module_id,
  module_run_id,
  source_module,
  original_name = NULL,
  original_section = NULL,
  normalized_section = NULL,
  artifact_index = NA_integer_,
  generated_at = Sys.time(),
  extra = list()
) {
  metadata <- list(
    module_id = module_id,
    module_run_id = module_run_id,
    source_module = source_module,
    original_name = original_name,
    original_section = original_section,
    normalized_section = normalized_section,
    artifact_index = as.integer(artifact_index),
    created_by_module = TRUE,
    generated_at = generated_at,
    run_timestamp = generated_at
  )

  for (name in names(extra)) {
    metadata[[name]] <- extra[[name]]
  }

  metadata
}

module_run_metadata <- function(
  module_id,
  module_run_id,
  generated_at = Sys.time(),
  data_name = NULL,
  source_package = "AutoQuant",
  source_function,
  configured_inputs = list(),
  artifacts = list(),
  report_plans = list(),
  extra = list()
) {
  counts <- module_artifact_counts(artifacts)
  metadata <- list(
    module_id = module_id,
    module_run_id = module_run_id,
    generated_at = generated_at,
    run_timestamp = generated_at,
    data_name = data_name,
    source_package = source_package,
    source_function = source_function,
    configured_inputs = configured_inputs,
    artifact_count = counts$artifact_count,
    plot_count = counts$plot_count,
    table_count = counts$table_count,
    text_count = counts$text_count,
    report_plan_count = length(report_plans),
    report_plans = report_plans,
    n_artifacts = counts$artifact_count,
    artifact_counts = list(
      plot = counts$plot_count,
      table = counts$table_count,
      text = counts$text_count
    ),
    n_report_plans = length(report_plans)
  )

  for (name in names(extra)) {
    metadata[[name]] <- extra[[name]]
  }

  metadata
}

analysis_module_status_table <- function(result) {
  if (is.null(result) || is.null(result$metadata)) {
    return(data.table::data.table())
  }

  metadata <- result$metadata
  data.table::data.table(
    module_id = metadata$module_id %||% NA_character_,
    module_run_id = metadata$module_run_id %||% NA_character_,
    status = result$status %||% NA_character_,
    artifact_count = as.integer(metadata$artifact_count %||% metadata$n_artifacts %||% 0L),
    plot_count = as.integer(metadata$plot_count %||% metadata$artifact_counts$plot %||% 0L),
    table_count = as.integer(metadata$table_count %||% metadata$artifact_counts$table %||% 0L),
    text_count = as.integer(metadata$text_count %||% metadata$artifact_counts$text %||% 0L),
    report_plan_count = as.integer(metadata$report_plan_count %||% metadata$n_report_plans %||% 0L)
  )
}

module_result_convention_checks <- function(result, artifact_id_prefix) {
  run_metadata <- result$metadata %||% list()
  artifacts <- result$artifacts %||% list()
  required_run_keys <- c(
    "module_id", "module_run_id", "generated_at", "source_package",
    "source_function", "configured_inputs", "artifact_count", "plot_count",
    "table_count", "text_count", "report_plan_count"
  )
  required_artifact_keys <- c(
    "module_id", "module_run_id", "source_module", "original_name",
    "original_section", "normalized_section", "artifact_index",
    "created_by_module", "generated_at"
  )

  run_metadata_ok <- all(required_run_keys %in% names(run_metadata))
  artifact_metadata_ok <- if (length(artifacts)) {
    all(vapply(artifacts, function(artifact) {
      metadata <- artifact$metadata %||% list()
      all(required_artifact_keys %in% names(metadata)) &&
        isTRUE(metadata$created_by_module)
    }, logical(1)))
  } else {
    FALSE
  }
  artifact_ids_ok <- if (length(artifacts)) {
    ids <- vapply(artifacts, function(artifact) artifact$artifact_id %||% "", character(1))
    all(startsWith(ids, artifact_id_prefix))
  } else {
    FALSE
  }
  labels_ok <- if (length(artifacts)) {
    labels <- tolower(vapply(artifacts, function(artifact) artifact$label %||% "", character(1)))
    generic_labels <- c("", "unnamed", "plot_1", "table_1", "artifact")
    all(!labels %in% generic_labels)
  } else {
    FALSE
  }

  data.table::data.table(
    check = c(
      "run_metadata_standard",
      "artifact_metadata_standard",
      "artifact_ids_prefixed",
      "artifact_labels_non_generic"
    ),
    status = c(
      if (run_metadata_ok) "success" else "error",
      if (artifact_metadata_ok) "success" else "error",
      if (artifact_ids_ok) "success" else "error",
      if (labels_ok) "success" else "error"
    ),
    message = c(
      if (run_metadata_ok) "Run metadata includes the standard module keys." else paste("Missing run metadata keys:", paste(setdiff(required_run_keys, names(run_metadata)), collapse = ", ")),
      if (artifact_metadata_ok) "Artifact metadata includes the standard module keys." else "One or more artifacts are missing standard module metadata.",
      if (artifact_ids_ok) paste("Artifact IDs use prefix", artifact_id_prefix) else paste("One or more artifact IDs do not use prefix", artifact_id_prefix),
      if (labels_ok) "Artifact labels are non-empty and non-generic." else "One or more artifact labels are empty or generic."
    )
  )
}

validate_module_config <- function(module_id, config, data) {
  module_id <- normalize_module_id(module_id)
  module <- get_module_definition(module_id)
  if (is.null(module)) {
    return(service_result(
      status = "error",
      errors = paste("Unknown analysis module:", module_id),
      metadata = list(
        error_code = "MODULE_NOT_FOUND",
        module_id = module_id
      )
    ))
  }

  if (is.null(config)) {
    config <- list()
  }

  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "Module config must be a list.",
      metadata = list(
        error_code = "MODULE_CONFIG_INVALID",
        module_id = module_id
      )
    ))
  }

  if (identical(module_id, "autoquant_eda")) {
    return(validate_autoquant_eda_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_model_readiness")) {
    return(validate_autoquant_model_readiness_config(data = data, config = config))
  }
  if (identical(module_id, "feature_engineering_model_prep")) {
    return(validate_feature_preparation_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_regression_model_insights")) {
    return(validate_autoquant_regression_model_insights_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_binary_model_insights")) {
    return(validate_autoquant_binary_model_insights_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_regression_shap_analysis")) {
    return(validate_autoquant_regression_shap_analysis_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_binary_shap_analysis")) {
    return(validate_autoquant_binary_shap_analysis_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_catboost_builder")) {
    return(validate_catboost_builder_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_multiclass_shap_analysis")) {
    config$problem_type <- "multiclass"
    return(validate_shap_analysis_config(config = config, data = data, problem_type = "multiclass"))
  }

  service_result(
    status = "success",
    value = config,
    messages = paste("Module config is valid for", module$label),
    metadata = list(
      module_id = module_id,
      status = module$status,
      n_rows = if (is.null(data)) NA_integer_ else nrow(data),
      n_cols = if (is.null(data)) NA_integer_ else ncol(data)
    )
  )
}

qa_analysis_modules_registry <- function() {
  helper_names <- c(
    autoquant_eda = "qa_autoquant_eda_integration",
    autoquant_model_readiness = "qa_autoquant_model_readiness_integration",
    feature_preparation = "qa_feature_preparation_integration",
    feature_experiment_loop = "qa_feature_experiment_loop",
    analytical_improvement_campaign = "qa_analytical_improvement_campaign",
    modeling_context_lifecycle = "qa_modeling_context_lifecycle",
    autoquant_regression_model_insights = "qa_autoquant_regression_model_insights_integration",
    autoquant_binary_model_insights = "qa_autoquant_binary_model_insights_integration",
    autoquant_regression_shap_analysis = "qa_autoquant_regression_shap_analysis_integration",
    autoquant_binary_shap_analysis = "qa_autoquant_binary_shap_analysis_integration",
    autoquant_catboost_builder = "qa_autoquant_catboost_builder_integration",
    shap_artifact_contract = "qa_shap_artifact_contract",
    module_terminology_consistency = "qa_module_terminology_consistency",
    project_artifact_collector = "qa_project_artifact_collector",
    screenshot_pipeline_reliability = "qa_screenshot_pipeline_reliability",
    render_targets = "qa_render_targets",
    table_artifact_policy = "qa_table_artifact_policy",
    artifact_producer_semantics = "qa_artifact_producer_semantics",
    artifact_quality_policy = "qa_artifact_quality_policy",
    project_load_paths = "qa_project_load_paths",
    artifact_studio = "qa_artifact_studio",
    mission_control = "qa_mission_control",
    semantic_intelligence_workspace = "qa_semantic_intelligence_workspace",
    semantic_decision_lifecycle = "qa_semantic_decision_lifecycle",
    decision_valuation_workspace = "qa_decision_valuation_workspace",
    decision_workflow_workspace = "qa_decision_workflow_workspace",
    semantic_intelligence_page = "qa_semantic_intelligence_page",
    causal_intelligence_workspace = "qa_causal_intelligence_workspace",
    causal_experiment_design_workspace = "qa_causal_experiment_design_workspace",
    causal_completed_experiment_workspace = "qa_causal_completed_experiment_workspace",
    causal_itt_workspace = "qa_causal_itt_workspace",
    causal_observational_workspace = "qa_causal_observational_workspace",
    causal_cross_method_contracts = "qa_causal_cross_method_contracts",
    epistemic_integrity_workspace = "qa_epistemic_integrity_workspace",
    analytical_workflow_integration = "qa_analytical_workflow_integration",
    async_job_service = "qa_async_job_service",
    command_palette = "qa_command_palette",
    genai_service_contract = "qa_genai_service_contract",
    knowledge_compilation_runtime = "qa_knowledge_compilation_runtime",
    ai_model_qualification = "qa_ai_model_qualification",
    ai_runtime_benchmark_framework = "qa_ai_runtime_benchmark_framework",
    artifact_progressive_retrieval = "qa_artifact_progressive_retrieval",
    cross_artifact_synthesis = "qa_cross_artifact_synthesis",
    ai_operated_evidence_review = "qa_ai_operated_evidence_review",
    knowledge_compilation_runtime_phase6 = "qa_knowledge_compilation_runtime_phase6",
    ai_draft_persistence = "qa_ai_draft_persistence",
    knowledge_compilation_runtime_phase7 = "qa_knowledge_compilation_runtime_phase7",
    mutation_governance = "qa_mutation_governance",
    knowledge_compilation_runtime_phase8 = "qa_knowledge_compilation_runtime_phase8",
    ai_runtime_page = "qa_ai_runtime_page",
    genai_experiment_harness = "qa_genai_experiment_harness",
    genai_vision_support = "qa_genai_vision_support",
    genai_context_strategy_study = "qa_genai_context_strategy_study",
    evidence_strategy_config = "qa_evidence_strategy_config",
    evidence_routing_policy = "qa_evidence_routing_policy",
    evidence_routing_observability = "qa_evidence_routing_observability",
    evidence_routing_calibration = "qa_evidence_routing_calibration",
    context_optimization_policy = "qa_context_optimization_policy",
    improvement_ledger = "qa_improvement_ledger",
    remediation_plans = "qa_remediation_plans",
    remediation_plan_hardening = "qa_remediation_plan_hardening",
    cross_system_invariants = "qa_cross_system_invariants",
    cross_repo_validation_orchestrator = "qa_cross_repo_validation_orchestrator",
    cross_repo_impact_analysis = "qa_cross_repo_impact_analysis",
    production_workflow_exercise = "qa_production_workflow_exercise",
    technical_debt_register = "qa_technical_debt_register",
    ui_consistency = "qa_ui_consistency"
  )
  helpers <- mget(unname(helper_names), mode = "function", inherits = TRUE)
  names(helpers) <- names(helper_names)
  deep_modules <- c(
    "render_targets",
    "knowledge_compilation_runtime_phase6",
    "knowledge_compilation_runtime_phase7",
    "knowledge_compilation_runtime_phase8",
    "evidence_strategy_config",
    "evidence_routing_calibration",
    "cross_repo_validation_orchestrator",
    "cross_repo_impact_analysis"
  )
  data.table::data.table(
    module_id = names(helper_names),
    helper = unname(helper_names),
    qa_tier = ifelse(names(helpers) %in% deep_modules, "deep", "bounded")
  )[, helper_fn := helpers]
}

qa_analysis_modules_integration <- function(profile = c("bounded", "full", "deep"), progress = FALSE) {
  profile <- match.arg(profile)
  registry <- qa_analysis_modules_registry()
  if (identical(profile, "bounded")) {
    selected <- registry[qa_tier == "bounded"]
    deferred <- registry[qa_tier == "deep"]
  } else if (identical(profile, "deep")) {
    selected <- registry[qa_tier == "deep"]
    deferred <- registry[0]
  } else {
    selected <- registry
    deferred <- registry[0]
  }

  rows <- lapply(seq_len(nrow(selected)), function(i) {
    module_id <- selected$module_id[[i]]
    helper <- selected$helper_fn[[i]]
    started_at <- Sys.time()
    if (isTRUE(progress)) {
      message("qa_analysis_modules_integration: starting ", module_id)
    }
    t0 <- proc.time()[["elapsed"]]
    result <- tryCatch(
      helper(),
      error = function(e) {
        data.table::data.table(
          check = "qa_helper",
          status = "error",
          message = conditionMessage(e)
        )
      }
    )
    elapsed_sec <- proc.time()[["elapsed"]] - t0

    statuses <- result$status %||% character()
    overall_status <- if (any(statuses == "error")) {
      "error"
    } else if (any(statuses %in% c("warning", "missing", "needs_input"))) {
      "warning"
    } else {
      "success"
    }
    if (isTRUE(progress)) {
      message("qa_analysis_modules_integration: finished ", module_id, " in ", round(elapsed_sec, 3), " sec with ", overall_status)
    }

    data.table::data.table(
      module_id = module_id,
      qa_tier = selected$qa_tier[[i]],
      status = overall_status,
      checks = nrow(result),
      errors = sum(statuses == "error"),
      warnings = sum(statuses %in% c("warning", "missing", "needs_input")),
      elapsed_sec = round(elapsed_sec, 3),
      started_at = format(started_at, "%Y-%m-%d %H:%M:%S"),
      completed_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      message = paste(result$message %||% character(), collapse = " | ")
    )
  })
  if (nrow(deferred)) {
    rows <- c(rows, list(data.table::data.table(
      module_id = deferred$module_id,
      qa_tier = deferred$qa_tier,
      status = "deferred",
      checks = 0L,
      errors = 0L,
      warnings = 0L,
      elapsed_sec = 0,
      started_at = NA_character_,
      completed_at = NA_character_,
      message = "Deferred from bounded aggregate QA; run qa_analysis_modules_integration(profile = 'deep') or profile = 'full'."
    )))
  }

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

run_analysis_module <- function(module_id, data, config = list()) {
  module_id <- normalize_module_id(module_id)
  module <- get_module_definition(module_id)
  if (is.null(module)) {
    return(service_result(
      status = "error",
      errors = paste("Unknown analysis module:", module_id),
      metadata = list(
        error_code = "MODULE_NOT_FOUND",
        module_id = module_id
      )
    ))
  }

  validation <- validate_module_config(module_id, config, data)
  if (identical(validation$status, "error")) {
    return(validation)
  }

  if (identical(module_id, "autoquant_eda")) {
    return(run_autoquant_eda_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_model_readiness")) {
    return(run_autoquant_model_readiness_module(data = data, config = config))
  }
  if (identical(module_id, "feature_engineering_model_prep")) {
    return(run_feature_preparation_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_regression_model_insights")) {
    return(run_autoquant_regression_model_insights_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_binary_model_insights")) {
    return(run_autoquant_binary_model_insights_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_regression_shap_analysis")) {
    return(run_autoquant_regression_shap_analysis_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_binary_shap_analysis")) {
    return(run_autoquant_binary_shap_analysis_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_catboost_builder")) {
    return(run_autoquant_catboost_builder_module(data = data, config = config))
  }

  service_result(
    status = "needs_input",
    artifacts = list(),
    messages = paste(module$label, "is registered but not implemented yet."),
    metadata = list(
      module_id = module_id,
      label = module$label,
      status = module$status,
      n_artifacts = 0L
    ),
    code = NULL
  )
}
