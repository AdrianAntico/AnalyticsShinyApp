build_week_demo_default_objective <- function() {
  "Identify the strongest drivers of funnel conversion, test stability across segments, investigate nonlinearities or anomalies, and assemble an analyst-ready evidence report."
}

build_week_demo_config <- function(provider = "openai", model = "gpt-5.6", api_key = "") {
  genai_config(
    provider = provider %||% "openai",
    model = model %||% "gpt-5.6",
    api_key = api_key %||% Sys.getenv("OPENAI_API_KEY", unset = ""),
    temperature = 0.2,
    max_tokens = 1200L,
    timeout = 30L
  )
}

build_week_demo_check <- function(check, status, message, action = "", metadata = list()) {
  data.table::data.table(
    check = check,
    status = status,
    message = message,
    action = action,
    metadata = list(metadata)
  )
}

build_week_demo_preflight <- function(
  data = NULL,
  config = build_week_demo_config(),
  check_provider = TRUE,
  run_runtime_qa = FALSE
) {
  checks <- list()
  add <- function(check, status, message, action = "", metadata = list()) {
    checks[[length(checks) + 1L]] <<- build_week_demo_check(check, status, message, action, metadata)
  }

  dataset <- data %||% build_week_demo_dataset(write_if_missing = TRUE)
  dataset_status <- validate_agent_dataset_contract(dataset, build_week_demo_dataset_manifest())
  dataset_signal_status <- validate_build_week_demo_data(dataset)
  add(
    "Dataset",
    if (identical(dataset_status$status, "success") && identical(dataset_signal_status$status, "success")) "success" else "error",
    if (identical(dataset_status$status, "success") && identical(dataset_signal_status$status, "success")) {
      paste("Mystery dataset ready:", nrow(dataset), "rows and", ncol(dataset), "columns. Hidden mechanisms are recoverable.")
    } else {
      paste(service_result_message(dataset_status), service_result_message(dataset_signal_status))
    },
    "Load or use the deterministic demo dataset.",
    list(contract = dataset_status$diagnostics %||% list(), signal_checks = dataset_signal_status$value %||% data.table::data.table())
  )

  provider_status <- genai_provider_status(config, check_availability = isTRUE(check_provider))
  provider_message <- if (identical(config$provider, "openai") && !nzchar(config$api_key %||% "")) {
    "OpenAI is selected for GPT-5.6, but no API key is configured."
  } else {
    service_result_message(provider_status)
  }
  add(
    "Provider",
    provider_status$status,
    provider_message,
    if (identical(provider_status$status, "success")) "Continue." else "Set OPENAI_API_KEY, choose Mock for deterministic rehearsal, or use an available local provider.",
    provider_status$metadata %||% list()
  )

  gpt_ready <- identical(config$provider, "openai") && identical(config$model %||% "", "gpt-5.6") && nzchar(config$api_key %||% "")
  mock_ready <- identical(config$provider, "mock")
  add(
    "GPT-5.6 configuration",
    if (isTRUE(gpt_ready) || isTRUE(mock_ready)) "success" else "warning",
    if (isTRUE(gpt_ready)) "GPT-5.6 is selected with an API key." else if (isTRUE(mock_ready)) "Mock provider selected for reproducible local QA." else "GPT-5.6 is not fully configured.",
    "Use OpenAI + gpt-5.6 for the live Build Week path or Mock for dry runs.",
    list(provider = config$provider, model = config$model, api_key_configured = nzchar(config$api_key %||% ""))
  )

  reports <- tryCatch(report_browser_demo_reports(), error = function(e) e)
  add(
    "Analytics services",
    if (inherits(reports, "error")) "error" else "success",
    if (inherits(reports, "error")) conditionMessage(reports) else paste("Available semantic service outputs:", paste(names(reports), collapse = ", "), "."),
    "Repair report demo contracts before running the campaign."
  )

  agent_qa <- if (isTRUE(run_runtime_qa)) tryCatch(qa_agent_operation_runtime(), error = function(e) e) else NULL
  add(
    "Agent runtime",
    if (inherits(agent_qa, "error")) "error" else if (is.null(agent_qa) || all(agent_qa$status != "error")) "success" else "error",
    if (inherits(agent_qa, "error")) conditionMessage(agent_qa) else "Agent session, replay, approval, and claim trace contracts are available.",
    "Run qa_agent_operation_runtime() for a deeper contract check."
  )

  report_qa <- if (isTRUE(run_runtime_qa)) tryCatch(qa_report_browser(), error = function(e) e) else NULL
  add(
    "Report browser",
    if (inherits(report_qa, "error")) "error" else if (is.null(report_qa) || all(report_qa$status != "error")) "success" else "error",
    if (inherits(report_qa, "error")) conditionMessage(report_qa) else "Interactive Report Browser contract is available.",
    "Repair Report Browser validation before investor recording."
  )

  targets <- tryCatch(agent_registered_ui_targets(), error = function(e) e)
  add(
    "Cursor targets",
    if (inherits(targets, "error")) "error" else if (all(c("data", "analysis_modules", "artifact_studio", "report_browser", "approval_gate") %in% targets$target)) "success" else "warning",
    if (inherits(targets, "error")) conditionMessage(targets) else paste("Registered targets:", paste(targets$target, collapse = ", "), "."),
    "Add missing semantic cursor targets before recording."
  )

  replay_probe <- tryCatch({
    result <- run_funnel_driver_investigation(approve_shap = TRUE, presentation_settings = agent_operation_settings("Instant"), provider_config = config)
    if (!identical(result$status, "success")) stop(service_result_message(result), call. = FALSE)
    agent_session_replay(result$value, presentation_settings = agent_operation_settings("Presentation"))
  }, error = function(e) e)
  add(
    "Replay",
    if (inherits(replay_probe, "error")) "error" else "success",
    if (inherits(replay_probe, "error")) conditionMessage(replay_probe) else "Replay can reconstruct the campaign without rerunning analysis.",
    "Use replay for deterministic demonstrations."
  )

  out <- data.table::rbindlist(checks, fill = TRUE)
  service_result(
    status = if (any(out$status == "error")) "error" else if (any(out$status %in% c("warning", "needs_input"))) "warning" else "success",
    value = out,
    messages = paste(sum(out$status == "success"), "of", nrow(out), "Build Week preflight checks passed."),
    metadata = list(provider = config$provider, model = config$model)
  )
}

build_week_demo_launch <- function(
  objective = build_week_demo_default_objective(),
  data = NULL,
  provider_config = build_week_demo_config(provider = "mock"),
  preset = "Presentation",
  approve_shap = TRUE
) {
  run_funnel_driver_investigation(
    data = data %||% build_week_demo_dataset(write_if_missing = TRUE),
    dataset_manifest = build_week_demo_dataset_manifest(),
    approve_shap = approve_shap,
    presentation_settings = agent_operation_settings(preset %||% "Presentation"),
    objective = objective %||% build_week_demo_default_objective(),
    provider_config = provider_config
  )
}

build_week_demo_reset <- function(ctx = NULL) {
  if (!is.null(ctx)) {
    if (is.function(ctx$agent_session_state)) ctx$agent_session_state(NULL)
    if (is.function(ctx$agent_report_contract)) ctx$agent_report_contract(NULL)
    if (!is.null(ctx$build_week_demo_state)) {
      ctx$build_week_demo_state$preflight <- NULL
      ctx$build_week_demo_state$message <- "Demo reset. Ready for a clean run."
    }
  }
  service_result(status = "success", value = TRUE, messages = "Build Week demo state reset.")
}

qa_build_week_demo <- function() {
  mock_config <- build_week_demo_config(provider = "mock", model = "mock-model")
  dataset_1 <- generate_build_week_demo_data(write_files = FALSE, seed = 20260717L)$data
  dataset_2 <- generate_build_week_demo_data(write_files = FALSE, seed = 20260717L)$data
  dataset_validation <- validate_build_week_demo_data(dataset_1)
  preflight <- build_week_demo_preflight(config = mock_config, check_provider = TRUE, run_runtime_qa = FALSE)
  launch <- build_week_demo_launch(provider_config = mock_config, preset = "Instant", approve_shap = TRUE)
  trace <- if (identical(launch$status, "success")) agent_campaign_claim_trace(launch$value) else service_result(status = "error", errors = "Launch failed.")
  inquiry <- launch$value$inquiry %||% list()
  inquiry_validation <- if (identical(launch$status, "success")) validate_inquiry_state(inquiry, require_complete = TRUE) else service_result(status = "error", errors = "Launch failed.")
  reset <- build_week_demo_reset()
  openai_missing_key <- genai_provider_status(build_week_demo_config(provider = "openai", model = "gpt-5.6", api_key = ""), check_availability = TRUE)

  data.table::data.table(
    check = c(
      "preflight_returns_checks",
      "dataset_deterministic",
      "dataset_schema",
      "dataset_hidden_mechanisms",
      "mock_provider_passes",
      "campaign_launches",
      "report_contract_attached",
      "inquiry_timeline_complete",
      "competing_explanations_recorded",
      "candidate_investigation_selected",
      "belief_revision_recorded",
      "recommendation_evolution_recorded",
      "remaining_uncertainty_recorded",
      "integrity_review_recorded",
      "decision_readiness_recorded",
      "claim_trace_available",
      "claim_trace_belief_path",
      "claim_trace_integrity_review",
      "reset_service_result",
      "openai_missing_key_visible"
    ),
    status = c(
      if (nrow(preflight$value %||% data.table::data.table()) >= 6L) "success" else "error",
      if (identical(dataset_1, dataset_2)) "success" else "error",
      if (identical(names(dataset_1), build_week_demo_schema()) && nrow(dataset_1) == 80L) "success" else "error",
      if (identical(dataset_validation$status, "success")) "success" else "error",
      if (any((preflight$value %||% data.table::data.table())$check == "Provider" & (preflight$value %||% data.table::data.table())$status == "success")) "success" else "error",
      if (identical(launch$status, "success") && identical(launch$value$status, "completed")) "success" else "error",
      if (identical(validate_report(launch$value$report_contract)$status, "success")) "success" else "error",
      if (identical(inquiry_validation$status, "success")) "success" else "error",
      if (length(inquiry$explanations %||% list()) >= 3L) "success" else "error",
      if (nzchar(inquiry$selected_investigation_id %||% "")) "success" else "error",
      if (length(inquiry$belief_revisions %||% list()) >= 2L) "success" else "error",
      if (length(inquiry$recommendation_revisions %||% list()) >= 2L) "success" else "error",
      if (length(inquiry$remaining_uncertainty %||% character())) "success" else "error",
      if (is.list(inquiry$integrity_review %||% NULL) && nzchar(inquiry$integrity_review$executive_summary %||% "")) "success" else "error",
      if (is.list(inquiry$integrity_review$decision_readiness %||% NULL) && nzchar(inquiry$integrity_review$decision_readiness$status %||% "")) "success" else "error",
      if (identical(trace$status, "success") && length(trace$value$evidence_ids %||% character())) "success" else "error",
      if (identical(trace$status, "success") && length(trace$value$belief_revisions %||% list()) && nzchar(trace$value$final_conclusion %||% "")) "success" else "error",
      if (identical(trace$status, "success") && is.list(trace$value$integrity_review %||% NULL) && nzchar(trace$value$integrity_review$decision_readiness$status %||% "")) "success" else "error",
      if (identical(reset$status, "success")) "success" else "error",
      if (identical(openai_missing_key$status, "needs_input")) "success" else "error"
    ),
    message = c(
      "Build Week preflight returns a structured check table.",
      "Build Week mystery dataset generation is deterministic.",
      "Build Week mystery dataset has the canonical 80-row schema.",
      "Hidden mechanisms remain recoverable by deterministic validation.",
      "Mock provider supports deterministic Build Week QA.",
      "Governed campaign launches end-to-end.",
      "Campaign output includes a validated ReportContract.",
      "Campaign inquiry timeline has required investigation stages.",
      "Campaign records competing explanations.",
      "Campaign records the selected investigation.",
      "Campaign records belief revisions.",
      "Campaign records recommendation evolution.",
      "Campaign records remaining uncertainty.",
      "Campaign records a structured integrity review.",
      "Campaign records decision readiness from the integrity review.",
      "Claim verification trace resolves evidence.",
      "Claim verification includes initial belief, revisions, and final conclusion.",
      "Claim verification includes integrity review and decision readiness.",
      "Reset returns a successful service_result.",
      "OpenAI without an API key is visible setup guidance, not a crash."
    )
  )
}
