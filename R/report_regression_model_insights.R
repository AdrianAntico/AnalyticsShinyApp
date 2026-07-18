regression_model_insights_report_type <- "regression_model_insights"

.rmi_report_artifacts <- function(input, artifacts = NULL) {
  if (!is.null(artifacts)) {
    return(artifacts)
  }
  if (is.list(input) && !is.null(input$artifacts)) {
    return(input$artifacts)
  }
  list()
}

.rmi_report_metadata <- function(input) {
  if (is.list(input) && !is.null(input$metadata)) {
    return(input$metadata)
  }
  list()
}

.rmi_report_value <- function(input) {
  if (is.list(input) && !is.null(input$value)) {
    return(input$value)
  }
  input
}

.rmi_report_artifact_id <- function(artifact, fallback = "artifact") {
  artifact$artifact_id %||% artifact$id %||% fallback
}

.rmi_report_artifact_label <- function(artifact, fallback = "Artifact") {
  artifact$label %||% artifact$title %||% .rmi_report_artifact_id(artifact, fallback)
}

.rmi_report_artifact_section <- function(artifact) {
  artifact$section %||% (artifact$metadata %||% list())$normalized_section %||% "Appendix"
}

.rmi_report_text_value <- function(value, fallback = "") {
  text <- trimws(paste(as.character(value %||% ""), collapse = " "))
  if (!nzchar(text) || identical(text, "NA")) {
    return(fallback)
  }
  text
}

.rmi_report_slug <- function(value) {
  report_safe_id("rmi", value)
}

.rmi_report_artifact_index <- function(artifacts) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(data.table::data.table())
  }
  artifact_names <- names(artifacts)
  if (is.null(artifact_names)) {
    artifact_names <- rep("", length(artifacts))
  }
  rows <- lapply(seq_along(artifacts), function(index) {
    artifact <- artifacts[[index]]
    metadata <- artifact$metadata %||% list()
    fallback_id <- if (nzchar(artifact_names[[index]])) artifact_names[[index]] else paste0("artifact_", index)
    data.table::data.table(
      artifact_id = .rmi_report_artifact_id(artifact, fallback_id),
      label = .rmi_report_artifact_label(artifact),
      artifact_type = artifact$artifact_type %||% "unknown",
      section = .rmi_report_artifact_section(artifact),
      source_module = artifact$source_module %||% "unknown",
      order = suppressWarnings(as.integer(artifact$order %||% index)),
      importance = metadata$artifact_importance %||% "recommended",
      intent = metadata$analytical_intent %||% metadata$intent %||% infer_artifact_intent(artifact$artifact_type %||% "unknown", artifact$label %||% ""),
      status = artifact$status %||% "ready"
    )
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

.rmi_report_section_order <- function() {
  c(
    "Model Overview",
    "Prediction Diagnostics",
    "Residual Diagnostics",
    "Global Importance",
    "Feature Effects",
    "Feature Diagnostics",
    "Appendix"
  )
}

.rmi_report_order_sections <- function(sections) {
  section_names <- names(sections)
  order <- match(section_names, .rmi_report_section_order())
  order[is.na(order)] <- length(.rmi_report_section_order()) + seq_len(sum(is.na(order)))
  sections[order(order, section_names)]
}

.rmi_report_evidence_links <- function(artifact_index) {
  if (!nrow(artifact_index)) {
    return(list())
  }
  lapply(seq_len(nrow(artifact_index)), function(index) {
    row <- artifact_index[index]
    list(
      artifact_id = row$artifact_id[[1]],
      role = row$intent[[1]],
      relationship = "supports",
      label = row$label[[1]],
      source_module = row$source_module[[1]]
    )
  })
}

.rmi_report_table_contract <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  table_architecture <- metadata$table_architecture %||% list()
  list(
    table_id = .rmi_report_artifact_id(artifact),
    title = .rmi_report_artifact_label(artifact),
    purpose = metadata$purpose %||% metadata$recommended_caption %||% "Structured regression model insight table.",
    source_artifact_id = .rmi_report_artifact_id(artifact),
    density = "adaptive",
    row_height = "automatic",
    pinned_columns = table_architecture$pinned_columns %||% character(),
    grouped_rows = table_architecture$grouped_rows %||% FALSE,
    expandable_rows = TRUE,
    default_sort = table_architecture$default_sort %||% metadata$default_sort %||% NULL,
    alternate_views = table_architecture$preview_views %||% metadata$preview_views %||% list(),
    static_fallback = "render_preview_table"
  )
}

.rmi_report_visual_spec <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  list(
    purpose = metadata$purpose %||% metadata$recommended_caption %||% paste("Inspect", .rmi_report_artifact_label(artifact)),
    source_object = .rmi_report_artifact_id(artifact),
    source_artifact_id = .rmi_report_artifact_id(artifact),
    interaction_capability = c("interactive", "drilldown"),
    presentation_hints = list(
      density = "balanced",
      preferred_size = "large",
      caption = metadata$recommended_caption %||% .rmi_report_artifact_label(artifact)
    ),
    export_fallback = list(
      strategy = "static_image_or_caption",
      reason = "Renderer-specific plot capture is outside the ReportContract adapter."
    )
  )
}

.rmi_report_recommendations <- function(artifacts) {
  recommendations <- list()
  for (artifact in artifacts %||% list()) {
    metadata <- artifact$metadata %||% list()
    candidates <- metadata$recommendations %||% list()
    content <- .rmi_report_text_value(artifact$content)
    if (identical(artifact$artifact_type, "recommendation") && nzchar(content)) {
      candidates <- c(candidates, content)
    }
    if (!length(candidates)) {
      next
    }
    for (candidate in candidates) {
      text <- paste(as.character(candidate), collapse = " ")
      if (!nzchar(text)) {
        next
      }
      recommendation_id <- report_safe_id("recommendation", paste(.rmi_report_artifact_id(artifact), length(recommendations) + 1L))
      recommendations[[recommendation_id]] <- list(
        recommendation_id = recommendation_id,
        action = text,
        evidence_ids = .rmi_report_artifact_id(artifact),
        metadata = list(source = "regression_model_insights_artifact")
      )
    }
  }
  recommendations
}

.rmi_report_text_findings <- function(artifacts) {
  findings <- list()
  for (artifact in artifacts %||% list()) {
    metadata <- artifact$metadata %||% list()
    candidates <- c(metadata$key_finding %||% character(), metadata$findings %||% character())
    content <- .rmi_report_text_value(artifact$content)
    if (identical(artifact$artifact_type, "text") && nzchar(content)) {
      candidates <- c(candidates, content)
    }
    for (candidate in candidates) {
      statement <- trimws(paste(as.character(candidate), collapse = " "))
      if (!nzchar(statement)) {
        next
      }
      finding_id <- report_safe_id("finding", paste(.rmi_report_artifact_id(artifact), length(findings) + 1L))
      findings[[finding_id]] <- create_report_finding(
        finding_id = finding_id,
        title = .rmi_report_artifact_label(artifact),
        statement = statement,
        confidence = metadata$confidence %||% "source_supplied",
        importance = metadata$artifact_importance %||% "recommended",
        evidence_ids = .rmi_report_artifact_id(artifact),
        quality_status = metadata$quality_status %||% artifact$status %||% "ready",
        metadata = list(source = "regression_model_insights_artifact")
      )
    }
  }
  findings
}

.rmi_report_inventory_findings <- function(index) {
  if (!nrow(index)) {
    return(list(create_report_finding(
      finding_id = "finding_no_evidence",
      title = "No Regression Evidence",
      statement = "No regression model insight artifacts were supplied to the report adapter.",
      confidence = "deterministic",
      importance = "critical",
      quality_status = "missing_evidence"
    )))
  }
  findings <- list()
  section_counts <- index[, .N, by = section][order(section)]
  findings[["finding_evidence_inventory"]] <- create_report_finding(
    finding_id = "finding_evidence_inventory",
    title = "Regression Evidence Inventory",
    statement = paste0(
      "Regression Model Insights supplied ", nrow(index), " artifact(s) across ",
      nrow(section_counts), " report section(s)."
    ),
    confidence = "deterministic",
    importance = "recommended",
    evidence_ids = index$artifact_id,
    quality_status = "ready",
    metadata = list(section_counts = section_counts)
  )
  diagnostic_ids <- index[grepl("diagnostic|residual|prediction", tolower(section)), artifact_id]
  if (length(diagnostic_ids)) {
    findings[["finding_diagnostics_available"]] <- create_report_finding(
      finding_id = "finding_diagnostics_available",
      title = "Diagnostic Evidence Available",
      statement = "Regression diagnostic evidence is available for report interpretation.",
      confidence = "deterministic",
      importance = "critical",
      evidence_ids = diagnostic_ids,
      quality_status = "ready"
    )
  }
  findings
}

regression_model_insights_to_canonical_result <- function(module_result) {
  metadata <- .rmi_report_metadata(module_result)
  configured_inputs <- metadata$configured_inputs %||% list()
  create_canonical_analysis_result(
    result_id = metadata$module_run_id %||% "regression_model_insights_result",
    analysis_id = "regression_model_insights",
    module_id = "autoquant_regression_model_insights",
    run_id = metadata$module_run_id %||% NULL,
    inputs = configured_inputs,
    configuration = configured_inputs,
    outputs = list(raw_result = .rmi_report_value(module_result)),
    diagnostics = list(messages = module_result$messages %||% character(), warnings = module_result$warnings %||% character()),
    metadata = metadata,
    provenance = list(source_function = metadata$source_function %||% "generate_regression_model_insights_artifacts")
  )
}

build_regression_model_insights_report <- function(
  analysis_result,
  artifacts = NULL,
  report_id = NULL,
  audience = list(primary = "analyst", secondary = c("decision_reviewer"), technical_depth = "standard"),
  purpose = "diagnostic_review",
  presentation_profile = create_presentation_profile(profile_id = "regression_model_insights_workstation", density = "balanced", theme = "inherit")
) {
  artifacts <- .rmi_report_artifacts(analysis_result, artifacts)
  metadata <- .rmi_report_metadata(analysis_result)
  canonical <- if (inherits(analysis_result, "canonical_analysis_result")) {
    analysis_result
  } else {
    regression_model_insights_to_canonical_result(analysis_result)
  }
  index <- .rmi_report_artifact_index(artifacts)
  evidence_links <- .rmi_report_evidence_links(index)
  recommendations <- .rmi_report_recommendations(artifacts)
  findings <- c(.rmi_report_text_findings(artifacts), .rmi_report_inventory_findings(index))

  report <- create_report_contract(
    report_id = report_id %||% report_safe_id("report", paste("regression_model_insights", canonical$run_id %||% Sys.Date())),
    title = "Regression Model Insights",
    report_type = regression_model_insights_report_type,
    analysis_ids = canonical$analysis_id,
    source_result_ids = canonical$result_id,
    metadata = list(
      source_module = "autoquant_regression_model_insights",
      source_run_id = canonical$run_id,
      source_function = canonical$provenance$source_function %||% NA_character_,
      generated_from = "Regression Model Insights module output"
    ),
    audience = audience,
    purpose = purpose,
    presentation_profile = presentation_profile,
    sections = list(),
    components = list(),
    findings = findings,
    recommendations = recommendations,
    evidence_links = evidence_links,
    capabilities = c("interactive", "filtering", "drilldown", "evidence_trace", "export_html", "export_pdf", "ai_summary"),
    provenance = list(
      canonical_result_id = canonical$result_id,
      adapter = "build_regression_model_insights_report",
      adapter_version = report_contract_version
    )
  )

  section_components <- list()
  add_to_section <- function(section_id, component) {
    report <<- add_component(report, component, section_id = section_id)
    section_components[[section_id]] <<- c(section_components[[section_id]] %||% character(), component$component_id)
  }

  add_to_section("model_overview", report_component_title("Regression Model Insights", subtitle = "Semantic report contract generated from regression model insight artifacts."))
  add_to_section("model_overview", report_component_orientation(
    question = "What evidence explains the regression model's performance, errors, diagnostics, and feature behavior?",
    scope = "This contract translates existing Regression Model Insights outputs into human-report semantics without rendering or recomputation.",
    audience = audience$primary %||% "analyst"
  ))
  add_to_section("model_overview", report_component_executive_summary(
    summary = paste0("The adapter found ", nrow(index), " regression evidence artifact(s). The report contract organizes them into overview, diagnostic, feature, and appendix sections."),
    confidence = "deterministic_inventory",
    next_action = "Renderers may now decide how to present this validated contract."
  ))
  add_to_section("model_overview", report_component_metric_summary(
    metrics = list(
      artifact_count = nrow(index),
      table_count = if (nrow(index)) sum(index$artifact_type == "table") else 0L,
      visualization_count = if (nrow(index)) sum(index$artifact_type == "plot") else 0L,
      text_count = if (nrow(index)) sum(index$artifact_type %in% c("text", "narrative")) else 0L,
      finding_count = length(findings),
      recommendation_count = length(recommendations)
    ),
    component_id = "regression_model_insights_metric_summary",
    title = "Evidence Inventory"
  ))

  for (artifact in artifacts %||% list()) {
    artifact_id <- .rmi_report_artifact_id(artifact)
    section_id <- .rmi_report_slug(.rmi_report_artifact_section(artifact))
    if (identical(artifact$artifact_type, "plot")) {
      add_to_section(section_id, report_component_visualization(
        plot_ref = artifact_id,
        specification = .rmi_report_visual_spec(artifact),
        caption = (artifact$metadata %||% list())$recommended_caption %||% .rmi_report_artifact_label(artifact),
        visual = artifact$object %||% (artifact$metadata %||% list())$visual,
        component_id = paste0("visual_", artifact_id),
        title = .rmi_report_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    } else if (identical(artifact$artifact_type, "table")) {
      add_to_section(section_id, report_component_table(
        table_ref = artifact_id,
        data = if (is.data.frame(artifact$content)) artifact$content else if (is.data.frame(artifact$object)) artifact$object else NULL,
        table_contract = .rmi_report_table_contract(artifact),
        component_id = paste0("table_", artifact_id),
        title = .rmi_report_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    } else if (artifact$artifact_type %in% c("text", "narrative")) {
      add_to_section(section_id, report_component_narrative(
        text = .rmi_report_text_value(artifact$content, .rmi_report_artifact_label(artifact)),
        component_id = paste0("narrative_", artifact_id),
        title = .rmi_report_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    } else if (identical(artifact$artifact_type, "diagnostic")) {
      add_to_section(section_id, report_component_diagnostic(
        status = artifact$status %||% "ready",
        messages = artifact$content %||% .rmi_report_artifact_label(artifact),
        component_id = paste0("diagnostic_", artifact_id),
        title = .rmi_report_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    }
  }

  if (!any(index$artifact_type == "plot")) {
    add_to_section("diagnostics", report_component_diagnostic(
      status = "missing",
      messages = "No visualization artifacts were supplied by the regression module output.",
      severity = "warning",
      component_id = "missing_regression_visualizations",
      title = "Visualization Evidence Missing"
    ))
  }
  if (!any(index$artifact_type == "table")) {
    add_to_section("diagnostics", report_component_diagnostic(
      status = "missing",
      messages = "No table artifacts were supplied by the regression module output.",
      severity = "warning",
      component_id = "missing_regression_tables",
      title = "Table Evidence Missing"
    ))
  }
  if (!length(recommendations)) {
    add_to_section("recommendations", report_component_diagnostic(
      status = "not_supplied",
      messages = "No explicit recommendations were supplied by the regression module output.",
      severity = "info",
      component_id = "missing_regression_recommendations",
      title = "Recommendations Not Supplied"
    ))
  } else {
    for (recommendation in recommendations) {
      add_to_section("recommendations", report_component_recommendation(
        action = recommendation$action,
        rationale = "Recommendation supplied by existing regression insight artifacts.",
        component_id = paste0("component_", recommendation$recommendation_id),
        metadata = list(evidence_ids = recommendation$evidence_ids)
      ))
    }
  }
  add_to_section("methodology", report_component_methodology(
    method = "Regression Model Insights adapter translated existing module output into a semantic ReportContract.",
    assumptions = c("No model analysis was recomputed.", "Artifacts are referenced as evidence rather than duplicated."),
    limitations = c("Renderer-specific behavior is intentionally absent.", "Missing artifact lineage is reported rather than fabricated.")
  ))
  add_to_section("technical_appendix", report_component_technical_appendix(
    content = list(
      source_module = "autoquant_regression_model_insights",
      source_run_id = canonical$run_id,
      artifact_ids = if (nrow(index)) index$artifact_id else character(),
      report_plan_ids = names(metadata$report_plans %||% list())
    )
  ))

  evidence_component_limit <- min(length(evidence_links), 25L)
  if (evidence_component_limit > 0L) {
    for (i in seq_len(evidence_component_limit)) {
      link <- evidence_links[[i]]
      add_to_section("evidence_links", report_component_evidence_link(
        artifact_id = link$artifact_id,
        relationship = link$relationship,
        role = link$role,
        component_id = paste0("evidence_", link$artifact_id),
        metadata = list(label = link$label, source_module = link$source_module)
      ))
    }
  }

  section_titles <- c(
    model_overview = "Model Overview",
    prediction_diagnostics = "Prediction Diagnostics",
    residual_diagnostics = "Residual Diagnostics",
    global_importance = "Global Importance",
    feature_effects = "Feature Effects",
    feature_diagnostics = "Feature Diagnostics",
    appendix = "Appendix",
    diagnostics = "Contract Diagnostics",
    recommendations = "Recommendations",
    methodology = "Methodology",
    technical_appendix = "Technical Appendix",
    evidence_links = "Evidence Links"
  )
  report$sections <- lapply(names(section_components), function(section_id) {
    create_report_section(
      section_id = section_id,
      title = section_titles[[section_id]] %||% tools::toTitleCase(gsub("_", " ", section_id)),
      purpose = paste("Communicate", section_titles[[section_id]] %||% section_id),
      priority = if (section_id %in% c("model_overview", "prediction_diagnostics", "residual_diagnostics")) "critical" else "recommended",
      components = section_components[[section_id]]
    )
  })
  names(report$sections) <- names(section_components)

  validation <- validate_report(report)
  report$validation <- list(
    status = validation$status,
    warnings = validation$warnings,
    errors = validation$errors,
    diagnostics = validation$diagnostics
  )
  report
}

qa_regression_model_insights_report_contract <- function() {
  checks <- list()
  add <- function(check, status, message) {
    checks[[length(checks) + 1L]] <<- data.table::data.table(check = check, status = status, message = message)
  }

  artifact_table <- create_artifact(
    artifact_id = "rmi_metrics_table",
    artifact_type = "table",
    label = "Model Metrics",
    source_module = "autoquant_regression_model_insights",
    object = data.table::data.table(metric = c("RMSE", "MAE"), value = c(1.2, 0.9)),
    metadata = list(created_by_module = TRUE, module_id = "autoquant_regression_model_insights", recommended_caption = "Model Metrics"),
    section = "Prediction Diagnostics"
  )
  artifact_plot <- create_artifact(
    artifact_id = "rmi_residual_plot",
    artifact_type = "plot",
    label = "Residual Plot",
    source_module = "autoquant_regression_model_insights",
    metadata = list(created_by_module = TRUE, module_id = "autoquant_regression_model_insights", recommended_caption = "Residual Plot"),
    section = "Residual Diagnostics"
  )
  artifact_text <- create_artifact(
    artifact_id = "rmi_summary_text",
    artifact_type = "text",
    label = "Model Summary Narrative",
    source_module = "autoquant_regression_model_insights",
    content = "Regression diagnostics were generated from existing model predictions.",
    metadata = list(created_by_module = TRUE, module_id = "autoquant_regression_model_insights", key_finding = "Regression diagnostics are available for review."),
    section = "Model Overview"
  )
  result <- service_result(
    status = "success",
    value = list(source = "fixture"),
    artifacts = list(artifact_table, artifact_plot, artifact_text),
    metadata = list(module_run_id = "rmi_fixture_run", source_function = "fixture", configured_inputs = list(target_column = "y", prediction_column = "pred"))
  )

  report <- build_regression_model_insights_report(result)
  validation <- validate_report(report)
  add("adapter_constructs", if (inherits(report, "report_contract")) "success" else "error", "Adapter returns a ReportContract.")
  add("adapter_validates", if (identical(validation$status, "success")) "success" else "error", paste(c(validation$errors, validation$warnings, "Regression report validates."), collapse = " "))
  add("component_counts", if (length(report$components) >= 8L) "success" else "error", paste("components =", length(report$components)))
  add("findings_present", if (length(report$findings) >= 2L) "success" else "error", paste("findings =", length(report$findings)))
  add("evidence_links_present", if (length(report$evidence_links) >= 3L) "success" else "error", paste("evidence_links =", length(report$evidence_links)))
  json <- serialize_report(report)
  restored <- deserialize_report(json)
  add("serialization_round_trip", if (identical(validate_report(restored)$status, "success")) "success" else "error", "Report serializes and deserializes.")

  missing_visual_result <- result
  missing_visual_result$artifacts <- list(artifact_table)
  missing_visual_report <- build_regression_model_insights_report(missing_visual_result)
  missing_visual_component <- any(vapply(missing_visual_report$components, function(component) identical(component$component_id, "missing_regression_visualizations"), logical(1)))
  add("missing_visuals_recorded", if (missing_visual_component && identical(validate_report(missing_visual_report)$status, "success")) "success" else "error", "Missing visualization evidence is recorded as a diagnostic component.")

  malformed <- tryCatch(build_regression_model_insights_report(list(value = NULL, artifacts = list(), metadata = list())), error = function(e) e)
  malformed_ok <- inherits(malformed, "report_contract") && identical(validate_report(malformed)$status, "success")
  add("malformed_input_degrades", if (malformed_ok) "success" else "error", "Malformed or empty input produces a valid diagnostic contract.")

  data.table::rbindlist(checks)
}
