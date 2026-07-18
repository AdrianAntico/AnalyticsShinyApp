eda_report_type <- "exploratory_data_analysis"

eda_to_canonical_result <- function(module_result) {
  metadata <- report_adapter_metadata(module_result)
  configured_inputs <- metadata$configured_inputs %||% list()
  create_canonical_analysis_result(
    result_id = metadata$module_run_id %||% "eda_result",
    analysis_id = "exploratory_data_analysis",
    module_id = "autoquant_eda",
    run_id = metadata$module_run_id %||% NULL,
    inputs = configured_inputs,
    configuration = configured_inputs,
    outputs = list(raw_result = report_adapter_value(module_result)),
    diagnostics = list(messages = module_result$messages %||% character(), warnings = module_result$warnings %||% character()),
    metadata = metadata,
    provenance = list(source_function = metadata$source_function %||% "generate_eda_artifacts")
  )
}

.eda_report_domain_findings <- function(index) {
  findings <- report_adapter_inventory_findings(
    index = index,
    finding_id = "finding_eda_evidence_inventory",
    title = "EDA Evidence Inventory",
    domain_label = "Exploratory Data Analysis",
    no_evidence_statement = "No EDA artifacts were supplied to the report adapter."
  )
  if (!nrow(index)) {
    return(findings)
  }
  missingness_ids <- index[grepl("missing|null|na", tolower(section)) | grepl("missing|null|na", tolower(label)), artifact_id]
  distribution_ids <- index[grepl("univariate|distribution|box|categor", tolower(section)) | grepl("distribution|box|categor", tolower(label)), artifact_id]
  correlation_ids <- index[grepl("correlation|correlogram", tolower(section)) | grepl("correlation|correlogram", tolower(label)), artifact_id]
  trend_ids <- index[grepl("trend|time", tolower(section)) | grepl("trend|time", tolower(label)), artifact_id]

  if (length(missingness_ids)) {
    findings[["finding_eda_missingness_available"]] <- create_report_finding(
      finding_id = "finding_eda_missingness_available",
      title = "Missingness Evidence Available",
      statement = "EDA output includes missingness evidence for data-quality review.",
      confidence = "deterministic",
      importance = "critical",
      evidence_ids = missingness_ids,
      quality_status = "ready"
    )
  }
  if (length(distribution_ids)) {
    findings[["finding_eda_distributions_available"]] <- create_report_finding(
      finding_id = "finding_eda_distributions_available",
      title = "Distribution Evidence Available",
      statement = "EDA output includes univariate distribution evidence.",
      confidence = "deterministic",
      importance = "recommended",
      evidence_ids = distribution_ids,
      quality_status = "ready"
    )
  }
  if (length(correlation_ids)) {
    findings[["finding_eda_correlations_available"]] <- create_report_finding(
      finding_id = "finding_eda_correlations_available",
      title = "Correlation Evidence Available",
      statement = "EDA output includes correlation evidence for relationship screening.",
      confidence = "deterministic",
      importance = "recommended",
      evidence_ids = correlation_ids,
      quality_status = "ready"
    )
  }
  if (length(trend_ids)) {
    findings[["finding_eda_trends_available"]] <- create_report_finding(
      finding_id = "finding_eda_trends_available",
      title = "Trend Evidence Available",
      statement = "EDA output includes time or trend evidence.",
      confidence = "deterministic",
      importance = "recommended",
      evidence_ids = trend_ids,
      quality_status = "ready"
    )
  }
  findings
}

build_eda_report <- function(
  analysis_result,
  artifacts = NULL,
  report_id = NULL,
  audience = list(primary = "analyst", secondary = c("data_reviewer"), technical_depth = "standard"),
  purpose = "data_understanding",
  presentation_profile = create_presentation_profile(profile_id = "eda_workstation", density = "balanced", theme = "inherit")
) {
  artifacts <- report_adapter_artifacts(analysis_result, artifacts)
  metadata <- report_adapter_metadata(analysis_result)
  canonical <- if (inherits(analysis_result, "canonical_analysis_result")) {
    analysis_result
  } else {
    eda_to_canonical_result(analysis_result)
  }
  configured_inputs <- canonical$configuration %||% list()
  index <- report_adapter_artifact_index(artifacts)
  evidence_links <- report_adapter_evidence_links(index)
  recommendations <- report_adapter_recommendations(artifacts, "eda_artifact")
  findings <- c(
    report_adapter_text_findings(artifacts, "eda_artifact", "eda_finding"),
    .eda_report_domain_findings(index)
  )

  report <- create_report_contract(
    report_id = report_id %||% report_safe_id("report", paste("eda", canonical$run_id %||% Sys.Date())),
    title = "Exploratory Data Analysis",
    report_type = eda_report_type,
    analysis_ids = canonical$analysis_id,
    source_result_ids = canonical$result_id,
    metadata = list(
      source_module = "autoquant_eda",
      source_run_id = canonical$run_id,
      source_function = canonical$provenance$source_function %||% NA_character_,
      generated_from = "EDA module output"
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
      adapter = "build_eda_report",
      adapter_version = report_contract_version
    )
  )

  section_components <- list()
  add_to_section <- function(section_id, component) {
    report <<- add_component(report, component, section_id = section_id)
    section_components[[section_id]] <<- c(section_components[[section_id]] %||% character(), component$component_id)
  }

  add_to_section("data_overview", report_component_title("Exploratory Data Analysis", subtitle = "Semantic data-understanding report contract."))
  add_to_section("data_overview", report_component_orientation(
    question = "What does the dataset contain, where is it incomplete, and which distribution, relationship, trend, or risk signals deserve attention?",
    scope = "This contract translates existing EDA artifacts into semantic report components without profiling data or rendering outputs.",
    audience = audience$primary %||% "analyst"
  ))
  add_to_section("data_overview", report_component_executive_summary(
    summary = paste0("The adapter found ", nrow(index), " EDA evidence artifact(s) covering data overview, missingness, distributions, correlations, trends, and appendix material where available."),
    confidence = "deterministic_inventory",
    next_action = "Inspect the referenced evidence before model readiness or feature preparation."
  ))
  add_to_section("data_overview", report_component_metric_summary(
    metrics = list(
      artifact_count = nrow(index),
      table_count = if (nrow(index)) sum(index$artifact_type == "table") else 0L,
      visualization_count = if (nrow(index)) sum(index$artifact_type == "plot") else 0L,
      finding_count = length(findings),
      recommendation_count = length(recommendations),
      selected_variables = configured_inputs$selected_variables %||% list()
    ),
    component_id = "eda_metric_summary",
    title = "Exploratory Evidence Inventory"
  ))

  added <- report_adapter_add_standard_artifact_components(report, artifacts, section_components, section_prefix = "eda")
  report <- added$report
  section_components <- added$section_components

  if (!any(index$artifact_type == "plot")) {
    add_to_section("diagnostics", report_component_diagnostic(
      status = "missing",
      messages = "No EDA visualization artifacts were supplied.",
      severity = "warning",
      component_id = "missing_eda_visualizations",
      title = "EDA Visualization Evidence Missing"
    ))
  }
  if (!any(index$artifact_type == "table")) {
    add_to_section("diagnostics", report_component_diagnostic(
      status = "missing",
      messages = "No EDA table artifacts were supplied.",
      severity = "warning",
      component_id = "missing_eda_tables",
      title = "EDA Table Evidence Missing"
    ))
  }
  if (!length(recommendations)) {
    add_to_section("recommendations", report_component_diagnostic(
      status = "not_supplied",
      messages = "No explicit EDA recommendations were supplied.",
      severity = "info",
      component_id = "missing_eda_recommendations",
      title = "Recommendations Not Supplied"
    ))
  } else {
    for (recommendation in recommendations) {
      add_to_section("recommendations", report_component_recommendation(
        action = recommendation$action,
        rationale = "Recommendation supplied by existing EDA artifacts.",
        component_id = paste0("component_", recommendation$recommendation_id),
        metadata = list(evidence_ids = recommendation$evidence_ids)
      ))
    }
  }
  add_to_section("methodology", report_component_methodology(
    method = "EDA adapter translated existing exploratory artifacts into a semantic ReportContract.",
    assumptions = c("EDA computations were performed upstream.", "Artifacts are referenced as evidence rather than duplicated."),
    limitations = c("Renderer-specific behavior is intentionally absent.", "Statistical findings are not invented by the adapter.")
  ))
  add_to_section("technical_appendix", report_component_technical_appendix(
    content = list(
      source_module = "autoquant_eda",
      source_run_id = canonical$run_id,
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
      data_overview = "Data Overview",
      eda_data_overview = "Data Overview",
      eda_missingness = "Missingness",
      eda_univariate_analysis = "Univariate Analysis",
      eda_correlation_diagnostics = "Correlation Diagnostics",
      eda_trend_analysis = "Trend Analysis",
      eda_target_analysis = "Target Analysis",
      eda_drift_diagnostics = "Drift Diagnostics",
      eda_risk_leakage_flags = "Risk / Leakage Flags",
      eda_appendix = "Appendix",
      diagnostics = "Contract Diagnostics",
      recommendations = "Recommendations",
      methodology = "Methodology",
      technical_appendix = "Technical Appendix",
      evidence_links = "Evidence Links"
    ),
    critical_sections = c("data_overview", "eda_data_overview", "eda_missingness")
  )
}

qa_eda_report_contract <- function() {
  checks <- list()
  add <- function(check, status, message) {
    checks[[length(checks) + 1L]] <<- data.table::data.table(check = check, status = status, message = message)
  }

  config <- list(
    DataName = "qa_eda_fixture",
    selected_variables = list(
      univariate = c("revenue", "channel"),
      correlation = c("spend", "revenue"),
      trend = "revenue"
    )
  )
  artifact_table <- create_artifact(
    artifact_id = "eda_missingness_table",
    artifact_type = "table",
    label = "Missingness Summary",
    source_module = "autoquant_eda",
    object = data.table::data.table(variable = c("revenue", "spend"), missing_rate = c(0.01, 0.03)),
    metadata = list(created_by_module = TRUE, module_id = "autoquant_eda", recommended_caption = "Missingness Summary"),
    section = "Missingness"
  )
  artifact_plot <- create_artifact(
    artifact_id = "eda_distribution_plot",
    artifact_type = "plot",
    label = "Revenue Distribution",
    source_module = "autoquant_eda",
    metadata = list(created_by_module = TRUE, module_id = "autoquant_eda", recommended_caption = "Revenue Distribution"),
    section = "Univariate Analysis"
  )
  artifact_text <- create_artifact(
    artifact_id = "eda_overview_text",
    artifact_type = "text",
    label = "EDA Overview",
    source_module = "autoquant_eda",
    content = "EDA artifacts are available for data understanding.",
    metadata = list(created_by_module = TRUE, module_id = "autoquant_eda", key_finding = "EDA evidence is ready for review."),
    section = "Data Overview"
  )
  result <- service_result(
    status = "success",
    value = list(source = "fixture"),
    artifacts = list(artifact_table, artifact_plot, artifact_text),
    metadata = list(module_run_id = "eda_fixture_run", source_function = "fixture", configured_inputs = config)
  )

  report <- build_eda_report(result)
  validation <- validate_report(report)
  add("adapter_constructs", if (inherits(report, "report_contract")) "success" else "error", "Adapter returns a ReportContract.")
  add("adapter_validates", if (identical(validation$status, "success")) "success" else "error", paste(c(validation$errors, validation$warnings, "EDA report validates."), collapse = " "))
  add("component_counts", if (length(report$components) >= 8L) "success" else "error", paste("components =", length(report$components)))
  add("findings_present", if (length(report$findings) >= 2L) "success" else "error", paste("findings =", length(report$findings)))
  add("evidence_links_present", if (length(report$evidence_links) >= 3L) "success" else "error", paste("evidence_links =", length(report$evidence_links)))
  restored <- deserialize_report(serialize_report(report))
  add("serialization_round_trip", if (identical(validate_report(restored)$status, "success")) "success" else "error", "Report serializes and deserializes.")

  missing_report <- build_eda_report(service_result(status = "warning", artifacts = list(), metadata = list(module_run_id = "missing_eda_fixture", configured_inputs = config)))
  add("missing_evidence_degrades", if (identical(validate_report(missing_report)$status, "success")) "success" else "error", "Missing EDA evidence produces a valid diagnostic contract.")

  data.table::rbindlist(checks)
}
