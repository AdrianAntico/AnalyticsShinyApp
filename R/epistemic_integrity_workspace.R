epistemic_integrity_required_exports <- function() {
  c(
    "aq_epistemic_intervention_event",
    "aq_epistemic_claim_record",
    "aq_detect_epistemic_findings",
    "aq_assess_epistemic_claims",
    "aq_epistemic_quality_gates",
    "aq_epistemic_adjudication",
    "aq_epistemic_integrity_artifact",
    "aq_epistemic_risk_registry",
    "qa_epistemic_integrity_contracts"
  )
}

epistemic_integrity_provider_diagnostics <- function() {
  required <- epistemic_integrity_required_exports()
  installed <- requireNamespace("AutoQuant", quietly = TRUE)
  exports <- if (installed) getNamespaceExports("AutoQuant") else character()
  missing <- setdiff(required, exports)
  source_path <- normalizePath(file.path(getwd(), "..", "AutoQuant", "R", "epistemic_integrity.R"), winslash = "/", mustWork = FALSE)
  source_text <- if (file.exists(source_path)) paste(readLines(source_path, warn = FALSE), collapse = "\n") else ""
  source_has_exports <- nzchar(source_text) && all(vapply(missing, function(x) grepl(paste0(x, " <- function"), source_text, fixed = TRUE), logical(1L)))
  reason_code <- if (!installed) {
    "provider_package_unavailable"
  } else if (!length(missing)) {
    "available"
  } else if (source_has_exports) {
    "installed_provider_stale"
  } else {
    "required_export_missing"
  }
  list(
    provider = "AutoQuant",
    capability = "epistemic_integrity",
    required = TRUE,
    available = installed && !length(missing),
    status = if (installed && !length(missing)) "available" else "unavailable",
    reason_code = reason_code,
    installed = installed,
    installed_path = if (installed) find.package("AutoQuant") else NA_character_,
    required_exports = required,
    available_exports = intersect(required, exports),
    missing_exports = missing,
    source_path = source_path,
    source_has_missing_exports = source_has_exports,
    recommendation = switch(
      reason_code,
      provider_package_unavailable = "Install AutoQuant in the current R library path.",
      installed_provider_stale = "Refresh the installed AutoQuant package from the current source tree.",
      required_export_missing = "Implement or export the missing AutoQuant epistemic integrity functions.",
      available = "No action required.",
      "Inspect AutoQuant provider configuration."
    )
  )
}

epistemic_integrity_available <- function() {
  isTRUE(epistemic_integrity_provider_diagnostics()$available)
}

epistemic_integrity_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "epistemic_integrity_workspace_v1",
    project_id = project_id,
    events = data.table::data.table(),
    claims = data.table::data.table(),
    evidence = data.table::data.table(),
    review_requirements = data.table::data.table(),
    adjudications = data.table::data.table(),
    findings = data.table::data.table(),
    claim_assessment = data.table::data.table(),
    quality_gates = data.table::data.table(),
    artifact = NULL,
    last_run_at = NA_character_,
    status = "not_run"
  )
}

epistemic_integrity_normalize <- function(state) {
  state <- state %||% epistemic_integrity_empty()
  for (nm in c("events", "claims", "evidence", "review_requirements", "adjudications", "findings", "claim_assessment", "quality_gates")) {
    if (is.null(state[[nm]]) || !data.table::is.data.table(state[[nm]])) {
      state[[nm]] <- data.table::as.data.table(state[[nm]] %||% data.frame())
    }
  }
  state
}

epistemic_integrity_run <- function(state = epistemic_integrity_empty()) {
  availability <- epistemic_integrity_provider_diagnostics()
  if (!isTRUE(availability$available)) {
    return(service_result(
      status = "warning",
      warnings = paste("AutoQuant epistemic integrity API unavailable:", availability$reason_code),
      diagnostics = availability
    ))
  }
  state <- epistemic_integrity_normalize(state)
  state$events <- AutoQuant::aq_epistemic_intervention_event(state$events)
  state$claims <- AutoQuant::aq_epistemic_claim_record(state$claims)
  state$findings <- AutoQuant::aq_detect_epistemic_findings(state$events, state$claims, state$evidence, state$review_requirements)
  state$claim_assessment <- AutoQuant::aq_assess_epistemic_claims(state$claims, state$evidence, state$findings)
  state$quality_gates <- AutoQuant::aq_epistemic_quality_gates(state$findings, state$claim_assessment)
  state$adjudications <- AutoQuant::aq_epistemic_adjudication(state$adjudications)
  state$artifact <- AutoQuant::aq_epistemic_integrity_artifact(
    events = state$events,
    claims = state$claims,
    evidence = state$evidence,
    review_requirements = state$review_requirements,
    adjudications = state$adjudications
  )
  state$last_run_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  state$status <- if (nrow(state$quality_gates) && any(state$quality_gates$status == "block")) "blocked" else "current"
  service_result(
    status = "success",
    value = state,
    messages = "Epistemic integrity assessment completed.",
    metadata = list(
      finding_count = nrow(state$findings),
      blocking_gate_count = sum(state$quality_gates$status == "block")
    )
  )
}

epistemic_integrity_summary <- function(state) {
  state <- epistemic_integrity_normalize(state)
  data.table::data.table(
    status = state$status %||% "not_run",
    events = nrow(state$events),
    claims = nrow(state$claims),
    findings = nrow(state$findings),
    blocking_gates = sum(state$quality_gates$status == "block"),
    high_or_critical_findings = sum(state$findings$severity %in% c("high", "critical")),
    review_required_claims = if (nrow(state$claim_assessment)) sum(vapply(state$claim_assessment$review_required, isTRUE, logical(1L))) else 0L,
    last_run_at = state$last_run_at %||% NA_character_
  )
}

epistemic_integrity_to_app_artifact <- function(state) {
  state <- epistemic_integrity_normalize(state)
  if (is.null(state$artifact)) return(NULL)
  create_artifact(
    artifact_id = state$artifact$artifact_envelope$artifact_id %||% state$artifact$id,
    artifact_type = "diagnostic",
    label = "Epistemic Integrity Assessment",
    source_module = "epistemic_integrity",
    object = list(
      findings = state$findings,
      claim_assessment = state$claim_assessment,
      quality_gates = state$quality_gates,
      autoquant_artifact = state$artifact
    ),
    metadata = list(
      analytical_intent = "Diagnostic",
      artifact_importance = "critical",
      caption = "Epistemic integrity findings, claim governance, quality gates, and adjudication state.",
      diagnostics = state$findings$reason %||% character(),
      recommendations = state$quality_gates$recommendation %||% character(),
      supported_actions = state$artifact$artifact_envelope$supported_actions %||% character(),
      render_targets = c("artifact_studio", "llm_docx", "human_report")
    ),
    section = "Epistemic Integrity",
    order = 1L
  )
}

qa_epistemic_integrity_workspace <- function() {
  rows <- list()
  add <- function(check, ok, message) rows[[length(rows) + 1L]] <<- data.table::data.table(suite = "epistemic_integrity_workspace", check = check, status = if (isTRUE(ok)) "success" else "error", message = message)
  availability <- epistemic_integrity_provider_diagnostics()
  add("autoquant_available", availability$available, paste("AutoQuant epistemic API availability:", availability$reason_code, "-", availability$recommendation))
  state <- epistemic_integrity_empty("qa_project")
  state$events <- data.table::data.table(
    intervention_id = "ev1",
    artifact_id = "artifact_1",
    actor_id = "owner_1",
    actor_role = "business_owner",
    event_type = "metric_change",
    requested_change = "Change outcome metric after seeing results",
    result_awareness = TRUE,
    authority_context = "decision_owner"
  )
  state$claims <- data.table::data.table(
    claim_id = "claim_1",
    artifact_id = "artifact_1",
    claim_text = "This proves the tactic will definitely increase revenue.",
    claim_strength = "decision_ready",
    evidence_strength = "associational",
    causal_language = TRUE,
    evidence_refs = "artifact_1"
  )
  state$evidence <- data.table::data.table(evidence_id = "contra_1", contradicts_claim_id = "claim_1", material = TRUE)
  state$review_requirements <- data.table::data.table(object_id = "claim_1", required_review = TRUE, completed_review = FALSE)
  run <- epistemic_integrity_run(state)
  add("run_success", identical(run$status, "success"), "Epistemic integrity run succeeds.")
  if (identical(run$status, "success")) {
    summary <- epistemic_integrity_summary(run$value)
    add("findings_created", summary$findings[[1]] >= 4L, "Observable epistemic findings are generated.")
    add("quality_gate_blocks", summary$blocking_gates[[1]] >= 1L, "Critical overclaim gates block unsupported claims.")
    add("claim_assessment", nrow(run$value$claim_assessment) == 1L && isTRUE(run$value$claim_assessment$overclaim[[1]]), "Claim-to-evidence assessment detects overclaiming.")
    artifact <- epistemic_integrity_to_app_artifact(run$value)
    add("app_artifact", !is.null(artifact) && identical(artifact$source_module, "epistemic_integrity"), "App artifact wraps the portable AutoQuant epistemic artifact.")
  }
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
