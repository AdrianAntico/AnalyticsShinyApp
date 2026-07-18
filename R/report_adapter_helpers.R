report_adapter_artifacts <- function(input, artifacts = NULL) {
  if (!is.null(artifacts)) {
    return(artifacts)
  }
  if (is.list(input) && !is.null(input$artifacts)) {
    return(input$artifacts)
  }
  list()
}

report_adapter_metadata <- function(input) {
  if (is.list(input) && !is.null(input$metadata)) {
    return(input$metadata)
  }
  list()
}

report_adapter_value <- function(input) {
  if (is.list(input) && !is.null(input$value)) {
    return(input$value)
  }
  input
}

report_adapter_artifact_id <- function(artifact, fallback = "artifact") {
  artifact$artifact_id %||% artifact$id %||% fallback
}

report_adapter_artifact_label <- function(artifact, fallback = "Artifact") {
  artifact$label %||% artifact$title %||% report_adapter_artifact_id(artifact, fallback)
}

report_adapter_artifact_section <- function(artifact) {
  artifact$section %||% (artifact$metadata %||% list())$normalized_section %||% "Appendix"
}

report_adapter_text_value <- function(value, fallback = "") {
  text <- trimws(paste(as.character(value %||% ""), collapse = " "))
  if (!nzchar(text) || identical(text, "NA")) {
    return(fallback)
  }
  text
}

report_adapter_slug <- function(prefix, value) {
  report_safe_id(prefix, paste(prefix, value))
}

report_adapter_artifact_index <- function(artifacts) {
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
      artifact_id = report_adapter_artifact_id(artifact, fallback_id),
      label = report_adapter_artifact_label(artifact),
      artifact_type = artifact$artifact_type %||% "unknown",
      section = report_adapter_artifact_section(artifact),
      source_module = artifact$source_module %||% metadata$source_module %||% "unknown",
      order = suppressWarnings(as.integer(artifact$order %||% index)),
      importance = metadata$artifact_importance %||% "recommended",
      intent = metadata$analytical_intent %||% metadata$intent %||%
        infer_artifact_intent(artifact$artifact_type %||% "unknown", artifact$label %||% ""),
      status = artifact$status %||% "ready"
    )
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

report_adapter_evidence_links <- function(artifact_index) {
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

report_adapter_table_contract <- function(artifact, purpose = NULL) {
  metadata <- artifact$metadata %||% list()
  table_architecture <- metadata$table_architecture %||% list()
  list(
    table_id = report_adapter_artifact_id(artifact),
    title = report_adapter_artifact_label(artifact),
    purpose = purpose %||% metadata$purpose %||% metadata$recommended_caption %||% "Structured analytical evidence table.",
    source_artifact_id = report_adapter_artifact_id(artifact),
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

report_adapter_visual_spec <- function(artifact, purpose = NULL, interaction_capability = c("interactive", "drilldown")) {
  metadata <- artifact$metadata %||% list()
  list(
    purpose = purpose %||% metadata$purpose %||% metadata$recommended_caption %||% paste("Inspect", report_adapter_artifact_label(artifact)),
    source_object = report_adapter_artifact_id(artifact),
    source_artifact_id = report_adapter_artifact_id(artifact),
    interaction_capability = interaction_capability,
    presentation_hints = list(
      density = "balanced",
      preferred_size = "large",
      caption = metadata$recommended_caption %||% report_adapter_artifact_label(artifact)
    ),
    export_fallback = list(
      strategy = "static_image_or_caption",
      reason = "Renderer-specific plot capture is outside the ReportContract adapter."
    )
  )
}

report_adapter_text_findings <- function(artifacts, source_label, fallback_prefix = "finding") {
  findings <- list()
  for (artifact in artifacts %||% list()) {
    metadata <- artifact$metadata %||% list()
    candidates <- c(metadata$key_finding %||% character(), metadata$findings %||% character())
    content <- report_adapter_text_value(artifact$content)
    if (artifact$artifact_type %in% c("text", "narrative") && nzchar(content)) {
      candidates <- c(candidates, content)
    }
    for (candidate in candidates) {
      statement <- trimws(paste(as.character(candidate), collapse = " "))
      if (!nzchar(statement)) {
        next
      }
      finding_id <- report_safe_id(fallback_prefix, paste(report_adapter_artifact_id(artifact), length(findings) + 1L))
      findings[[finding_id]] <- create_report_finding(
        finding_id = finding_id,
        title = report_adapter_artifact_label(artifact),
        statement = statement,
        confidence = metadata$confidence %||% "source_supplied",
        importance = metadata$artifact_importance %||% "recommended",
        evidence_ids = report_adapter_artifact_id(artifact),
        quality_status = metadata$quality_status %||% artifact$status %||% "ready",
        metadata = list(source = source_label)
      )
    }
  }
  findings
}

report_adapter_recommendations <- function(artifacts, source_label) {
  recommendations <- list()
  for (artifact in artifacts %||% list()) {
    metadata <- artifact$metadata %||% list()
    candidates <- metadata$recommendations %||% list()
    content <- report_adapter_text_value(artifact$content)
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
      recommendation_id <- report_safe_id("recommendation", paste(report_adapter_artifact_id(artifact), length(recommendations) + 1L))
      recommendations[[recommendation_id]] <- list(
        recommendation_id = recommendation_id,
        action = text,
        evidence_ids = report_adapter_artifact_id(artifact),
        metadata = list(source = source_label)
      )
    }
  }
  recommendations
}

report_adapter_inventory_findings <- function(index, finding_id, title, domain_label, no_evidence_statement) {
  if (!nrow(index)) {
    return(list(create_report_finding(
      finding_id = paste0(finding_id, "_no_evidence"),
      title = paste("No", domain_label, "Evidence"),
      statement = no_evidence_statement,
      confidence = "deterministic",
      importance = "critical",
      quality_status = "missing_evidence"
    )))
  }
  section_counts <- index[, .N, by = section][order(section)]
  list(create_report_finding(
    finding_id = finding_id,
    title = title,
    statement = paste0(domain_label, " supplied ", nrow(index), " artifact(s) across ", nrow(section_counts), " report section(s)."),
    confidence = "deterministic",
    importance = "recommended",
    evidence_ids = index$artifact_id,
    quality_status = "ready",
    metadata = list(section_counts = section_counts)
  ))
}

report_adapter_add_standard_artifact_components <- function(report, artifacts, section_components, section_prefix = "section") {
  add_to_section <- function(section_id, component) {
    report <<- add_component(report, component, section_id = section_id)
    section_components[[section_id]] <<- c(section_components[[section_id]] %||% character(), component$component_id)
  }

  for (artifact in artifacts %||% list()) {
    artifact_id <- report_adapter_artifact_id(artifact)
    section_id <- report_adapter_slug(section_prefix, report_adapter_artifact_section(artifact))
    if (identical(artifact$artifact_type, "plot")) {
      add_to_section(section_id, report_component_visualization(
        plot_ref = artifact_id,
        specification = report_adapter_visual_spec(artifact),
        caption = (artifact$metadata %||% list())$recommended_caption %||% report_adapter_artifact_label(artifact),
        component_id = paste0("visual_", artifact_id),
        title = report_adapter_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    } else if (identical(artifact$artifact_type, "table")) {
      add_to_section(section_id, report_component_table(
        table_ref = artifact_id,
        data = if (is.data.frame(artifact$content)) artifact$content else NULL,
        table_contract = report_adapter_table_contract(artifact),
        component_id = paste0("table_", artifact_id),
        title = report_adapter_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    } else if (artifact$artifact_type %in% c("text", "narrative")) {
      add_to_section(section_id, report_component_narrative(
        text = report_adapter_text_value(artifact$content, report_adapter_artifact_label(artifact)),
        component_id = paste0("narrative_", artifact_id),
        title = report_adapter_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    } else if (identical(artifact$artifact_type, "diagnostic")) {
      add_to_section(section_id, report_component_diagnostic(
        status = artifact$status %||% "ready",
        messages = artifact$content %||% report_adapter_artifact_label(artifact),
        component_id = paste0("diagnostic_", artifact_id),
        title = report_adapter_artifact_label(artifact),
        metadata = list(source_artifact_id = artifact_id)
      ))
    }
  }
  list(report = report, section_components = section_components)
}

report_adapter_finalize_sections <- function(report, section_components, section_titles = c(), critical_sections = character()) {
  report$sections <- lapply(names(section_components), function(section_id) {
    section_title <- unname(section_titles[section_id])
    if (is.na(section_title) || !nzchar(section_title)) {
      section_title <- tools::toTitleCase(gsub("_", " ", section_id))
    }
    create_report_section(
      section_id = section_id,
      title = section_title,
      purpose = paste("Communicate", section_title),
      priority = if (section_id %in% critical_sections) "critical" else "recommended",
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

qa_report_contract_adapters <- function() {
  adapter_qas <- list(
    regression_model_insights = qa_regression_model_insights_report_contract(),
    shap_analysis = qa_shap_analysis_report_contract(),
    exploratory_data_analysis = qa_eda_report_contract()
  )
  data.table::rbindlist(lapply(names(adapter_qas), function(adapter) {
    result <- data.table::as.data.table(adapter_qas[[adapter]])
    result[, adapter := adapter]
    data.table::setcolorder(result, c("adapter", setdiff(names(result), "adapter")))
    result
  }), use.names = TRUE, fill = TRUE)
}
