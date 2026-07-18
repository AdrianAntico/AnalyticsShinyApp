shap_analysis_report_type <- "shap_analysis"

shap_analysis_to_canonical_result <- function(module_result) {
  metadata <- report_adapter_metadata(module_result)
  configured_inputs <- metadata$configured_inputs %||% list()
  problem_type <- configured_inputs$problem_type %||% metadata$problem_type %||% "regression"
  create_canonical_analysis_result(
    result_id = metadata$module_run_id %||% paste("shap_analysis_result", problem_type, sep = "_"),
    analysis_id = "shap_analysis",
    module_id = metadata$module_id %||% "autoquant_regression_shap_analysis",
    run_id = metadata$module_run_id %||% NULL,
    inputs = configured_inputs,
    configuration = configured_inputs,
    outputs = list(raw_result = report_adapter_value(module_result)),
    diagnostics = list(messages = module_result$messages %||% character(), warnings = module_result$warnings %||% character()),
    metadata = metadata,
    provenance = list(source_function = metadata$source_function %||% "generate_regression_shap_analysis_artifacts")
  )
}

.shap_report_domain_findings <- function(index) {
  findings <- report_adapter_inventory_findings(
    index = index,
    finding_id = "finding_shap_evidence_inventory",
    title = "SHAP Evidence Inventory",
    domain_label = "SHAP Analysis",
    no_evidence_statement = "No SHAP artifacts were supplied to the report adapter."
  )
  if (!nrow(index)) {
    return(findings)
  }
  importance_ids <- index[grepl("importance", tolower(section)) | grepl("importance", tolower(label)), artifact_id]
  dependence_ids <- index[grepl("dependence|effect", tolower(section)) | grepl("dependence|effect", tolower(label)), artifact_id]
  interaction_ids <- index[grepl("interaction", tolower(section)) | grepl("interaction", tolower(label)), artifact_id]

  if (length(importance_ids)) {
    findings[["finding_shap_importance_available"]] <- create_report_finding(
      finding_id = "finding_shap_importance_available",
      title = "Global Importance Evidence Available",
      statement = "The SHAP output includes global feature-contribution evidence.",
      confidence = "deterministic",
      importance = "critical",
      evidence_ids = importance_ids,
      quality_status = "ready"
    )
  }
  if (length(dependence_ids)) {
    findings[["finding_shap_dependence_available"]] <- create_report_finding(
      finding_id = "finding_shap_dependence_available",
      title = "Feature Effect Evidence Available",
      statement = "The SHAP output includes feature-level dependence or marginal effect evidence.",
      confidence = "deterministic",
      importance = "recommended",
      evidence_ids = dependence_ids,
      quality_status = "ready"
    )
  }
  if (length(interaction_ids)) {
    findings[["finding_shap_interactions_available"]] <- create_report_finding(
      finding_id = "finding_shap_interactions_available",
      title = "Interaction Evidence Available",
      statement = "The SHAP output includes interaction-oriented evidence.",
      confidence = "deterministic",
      importance = "recommended",
      evidence_ids = interaction_ids,
      quality_status = "ready"
    )
  }
  findings
}

build_shap_analysis_report <- function(
  analysis_result,
  artifacts = NULL,
  report_id = NULL,
  audience = list(primary = "analyst", secondary = c("model_reviewer"), technical_depth = "standard"),
  purpose = "model_explainability",
  presentation_profile = create_presentation_profile(profile_id = "shap_analysis_workstation", density = "balanced", theme = "inherit")
) {
  artifacts <- report_adapter_artifacts(analysis_result, artifacts)
  metadata <- report_adapter_metadata(analysis_result)
  canonical <- if (inherits(analysis_result, "canonical_analysis_result")) {
    analysis_result
  } else {
    shap_analysis_to_canonical_result(analysis_result)
  }
  configured_inputs <- canonical$configuration %||% list()
  problem_type <- configured_inputs$problem_type %||% metadata$problem_type %||% "regression"
  index <- report_adapter_artifact_index(artifacts)
  evidence_links <- report_adapter_evidence_links(index)
  recommendations <- report_adapter_recommendations(artifacts, "shap_analysis_artifact")
  findings <- c(
    report_adapter_text_findings(artifacts, "shap_analysis_artifact", "shap_finding"),
    .shap_report_domain_findings(index)
  )

  report <- create_report_contract(
    report_id = report_id %||% report_safe_id("report", paste("shap_analysis", canonical$run_id %||% Sys.Date())),
    title = "SHAP Analysis",
    report_type = shap_analysis_report_type,
    analysis_ids = canonical$analysis_id,
    source_result_ids = canonical$result_id,
    metadata = list(
      source_module = canonical$module_id,
      source_run_id = canonical$run_id,
      source_function = canonical$provenance$source_function %||% NA_character_,
      problem_type = problem_type,
      generated_from = "SHAP analysis module output"
    ),
    audience = audience,
    purpose = purpose,
    presentation_profile = presentation_profile,
    sections = list(),
    components = list(),
    findings = findings,
    recommendations = recommendations,
    evidence_links = evidence_links,
    capabilities = c("interactive", "filtering", "linked_views", "drilldown", "evidence_trace", "export_html", "export_pdf", "ai_summary"),
    provenance = list(
      canonical_result_id = canonical$result_id,
      adapter = "build_shap_analysis_report",
      adapter_version = report_contract_version
    )
  )

  section_components <- list()
  add_to_section <- function(section_id, component) {
    report <<- add_component(report, component, section_id = section_id)
    section_components[[section_id]] <<- c(section_components[[section_id]] %||% character(), component$component_id)
  }

  add_to_section("shap_overview", report_component_title("SHAP Analysis", subtitle = "Semantic model-explainability report contract."))
  add_to_section("shap_overview", report_component_orientation(
    question = "Which features explain model predictions, and how do their effects vary globally, locally, and across context?",
    scope = "This contract translates existing SHAP artifacts into semantic report components without computing SHAP values or rendering plots.",
    audience = audience$primary %||% "analyst"
  ))
  add_to_section("shap_overview", report_component_executive_summary(
    summary = paste0("The adapter found ", nrow(index), " SHAP evidence artifact(s) for ", problem_type, " explainability."),
    confidence = "deterministic_inventory",
    next_action = "Use the evidence links to inspect importance, dependence, interaction, segment, time, or local explanation artifacts."
  ))
  add_to_section("shap_overview", report_component_metric_summary(
    metrics = list(
      artifact_count = nrow(index),
      table_count = if (nrow(index)) sum(index$artifact_type == "table") else 0L,
      visualization_count = if (nrow(index)) sum(index$artifact_type == "plot") else 0L,
      finding_count = length(findings),
      recommendation_count = length(recommendations),
      problem_type = problem_type
    ),
    component_id = "shap_analysis_metric_summary",
    title = "Explainability Evidence Inventory"
  ))

  added <- report_adapter_add_standard_artifact_components(report, artifacts, section_components, section_prefix = "shap")
  report <- added$report
  section_components <- added$section_components

  if (!any(index$artifact_type == "plot")) {
    add_to_section("diagnostics", report_component_diagnostic(
      status = "missing",
      messages = "No SHAP visualization artifacts were supplied.",
      severity = "warning",
      component_id = "missing_shap_visualizations",
      title = "SHAP Visualization Evidence Missing"
    ))
  }
  if (!any(index$artifact_type == "table")) {
    add_to_section("diagnostics", report_component_diagnostic(
      status = "missing",
      messages = "No SHAP table artifacts were supplied.",
      severity = "warning",
      component_id = "missing_shap_tables",
      title = "SHAP Table Evidence Missing"
    ))
  }
  if (!length(recommendations)) {
    add_to_section("recommendations", report_component_diagnostic(
      status = "not_supplied",
      messages = "No explicit SHAP recommendations were supplied.",
      severity = "info",
      component_id = "missing_shap_recommendations",
      title = "Recommendations Not Supplied"
    ))
  } else {
    for (recommendation in recommendations) {
      add_to_section("recommendations", report_component_recommendation(
        action = recommendation$action,
        rationale = "Recommendation supplied by existing SHAP artifacts.",
        component_id = paste0("component_", recommendation$recommendation_id),
        metadata = list(evidence_ids = recommendation$evidence_ids)
      ))
    }
  }
  add_to_section("methodology", report_component_methodology(
    method = "SHAP Analysis adapter translated existing explainability artifacts into a semantic ReportContract.",
    assumptions = c("SHAP values were computed upstream.", "The adapter does not recompute explanations."),
    limitations = c("Renderer behavior is intentionally absent.", "Exact SHAP interaction availability depends on upstream artifacts.")
  ))
  add_to_section("technical_appendix", report_component_technical_appendix(
    content = list(
      source_module = canonical$module_id,
      source_run_id = canonical$run_id,
      problem_type = problem_type,
      artifact_ids = if (nrow(index)) index$artifact_id else character(),
      configured_inputs = configured_inputs
    )
  ))
  for (i in seq_len(min(length(evidence_links), 25L))) {
    link <- evidence_links[[i]]
    add_to_section("evidence_links", report_component_evidence_link(
      artifact_id = link$artifact_id,
      relationship = link$relationship,
      role = link$role,
      component_id = paste0("evidence_", link$artifact_id),
      metadata = list(label = link$label, source_module = link$source_module)
    ))
  }

  report_adapter_finalize_sections(
    report,
    section_components,
    section_titles = c(
      shap_overview = "SHAP Overview",
      shap_global_importance = "Global Importance",
      shap_interaction_importance = "Interaction Importance",
      shap_single_feature_effects = "Single Feature Effects",
      shap_shap_dependence = "SHAP Dependence",
      shap_marginal_value_effect_curves = "Marginal Value / Effect Curves",
      shap_segment_effects = "Segment Effects",
      shap_time_effects = "Time Effects",
      shap_local_explanations = "Local Explanations",
      shap_appendix = "Appendix",
      diagnostics = "Contract Diagnostics",
      recommendations = "Recommendations",
      methodology = "Methodology",
      technical_appendix = "Technical Appendix",
      evidence_links = "Evidence Links"
    ),
    critical_sections = c("shap_overview", "shap_global_importance", "shap_shap_dependence")
  )
}

qa_shap_analysis_report_contract <- function() {
  checks <- list()
  add <- function(check, status, message) {
    checks[[length(checks) + 1L]] <<- data.table::data.table(check = check, status = status, message = message)
  }

  config <- create_shap_analysis_config(
    problem_type = "regression",
    target_col = "y",
    prediction_col = "pred",
    feature_cols = c("spend", "clicks"),
    shap_prefix = "Shap_"
  )
  artifact_table <- create_artifact(
    artifact_id = "shap_importance_table",
    artifact_type = "table",
    label = "Global SHAP Importance",
    source_module = "autoquant_regression_shap_analysis",
    object = data.table::data.table(feature = c("spend", "clicks"), mean_abs_shap = c(0.42, 0.25)),
    metadata = create_shap_artifact_metadata(config, lens = "global_importance", section = "Global Importance"),
    section = "Global Importance"
  )
  artifact_plot <- create_artifact(
    artifact_id = "shap_dependence_plot",
    artifact_type = "plot",
    label = "Spend SHAP Dependence",
    source_module = "autoquant_regression_shap_analysis",
    metadata = create_shap_artifact_metadata(config, lens = "shap_dependence", section = "SHAP Dependence"),
    section = "SHAP Dependence"
  )
  artifact_text <- create_artifact(
    artifact_id = "shap_summary_text",
    artifact_type = "text",
    label = "SHAP Summary",
    source_module = "autoquant_regression_shap_analysis",
    content = "SHAP importance and dependence evidence is available for model explanation.",
    metadata = c(create_shap_artifact_metadata(config, lens = "overview", section = "SHAP Overview"), list(key_finding = "Feature contribution evidence is ready for review.")),
    section = "SHAP Overview"
  )
  result <- service_result(
    status = "success",
    value = list(source = "fixture"),
    artifacts = list(artifact_table, artifact_plot, artifact_text),
    metadata = list(
      module_id = "autoquant_regression_shap_analysis",
      module_run_id = "shap_fixture_run",
      source_function = "fixture",
      configured_inputs = config
    )
  )

  report <- build_shap_analysis_report(result)
  validation <- validate_report(report)
  add("adapter_constructs", if (inherits(report, "report_contract")) "success" else "error", "Adapter returns a ReportContract.")
  add("adapter_validates", if (identical(validation$status, "success")) "success" else "error", paste(c(validation$errors, validation$warnings, "SHAP report validates."), collapse = " "))
  add("component_counts", if (length(report$components) >= 8L) "success" else "error", paste("components =", length(report$components)))
  add("findings_present", if (length(report$findings) >= 2L) "success" else "error", paste("findings =", length(report$findings)))
  add("evidence_links_present", if (length(report$evidence_links) >= 3L) "success" else "error", paste("evidence_links =", length(report$evidence_links)))
  restored <- deserialize_report(serialize_report(report))
  add("serialization_round_trip", if (identical(validate_report(restored)$status, "success")) "success" else "error", "Report serializes and deserializes.")

  missing_report <- build_shap_analysis_report(service_result(status = "warning", artifacts = list(), metadata = list(module_run_id = "missing_shap_fixture", configured_inputs = config)))
  add("missing_evidence_degrades", if (identical(validate_report(missing_report)$status, "success")) "success" else "error", "Missing SHAP evidence produces a valid diagnostic contract.")

  data.table::rbindlist(checks)
}
