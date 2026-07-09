# saved_plots is the current legacy plot-specific report state.
# aq_artifact objects are the future generalized report state for plots, text,
# tables, metrics, forecasts, and narratives. The adapters below allow a gradual
# migration without changing existing saved plot behavior.

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) {
    return(y)
  }

  x
}

artifact_types <- c(
  "plot", "table", "text", "metric", "section_header",
  "model_summary", "forecast_block", "genai_narrative",
  "diagnostic", "recommendation", "json", "narrative"
)

artifact_statuses <- c(
  "ready", "draft", "needs_data", "missing_columns",
  "rebuild_failed", "hidden"
)

artifact_importance_levels <- c("critical", "recommended", "supplementary")

artifact_intents <- c(
  "Ranking", "Comparison", "Relationship", "Distribution", "Diagnostic",
  "Forecast", "Optimization", "Segmentation", "Time Series", "Prediction",
  "Importance", "Interaction", "Narrative", "Recommendation", "Data"
)

.artifact_semantic_text <- function(...) {
  tolower(paste(vapply(list(...), function(value) {
    paste(as.character(value %||% ""), collapse = " ")
  }, character(1)), collapse = " "))
}

infer_artifact_intent <- function(artifact_type, label = NULL, section = NULL, original_name = NULL) {
  text <- .artifact_semantic_text(label, section, original_name)
  if (grepl("interaction", text)) return("Interaction")
  if (grepl("importance|shap", text)) return("Importance")
  if (grepl("correlation|relationship|dependence|association", text)) return("Relationship")
  if (grepl("distribution|histogram|box|missing|summary|describe", text)) return("Distribution")
  if (grepl("trend|time|date|drift", text)) return("Time Series")
  if (grepl("prediction|actual|residual|error|calibration|threshold|confusion|metric|lift|gain|risk|diagnostic|readiness", text)) return("Diagnostic")
  if (grepl("segment|group|by", text)) return("Segmentation")
  if (grepl("recommend", text)) return("Recommendation")
  if (artifact_type %in% c("text", "narrative", "genai_narrative")) return("Narrative")
  if (artifact_type %in% c("table", "metric")) return("Data")
  "Comparison"
}

infer_artifact_importance <- function(module_id, artifact_type, label = NULL, section = NULL, original_name = NULL) {
  text <- .artifact_semantic_text(module_id, artifact_type, label, section, original_name)
  if (grepl("overview|summary|metric|threshold|confusion|importance|shap|risk|readiness|diagnostic|collector|quality", text)) {
    return("critical")
  }
  if (grepl("appendix|qa|metadata|context|local|supplement", text)) {
    return("supplementary")
  }
  "recommended"
}

producer_artifact_semantics <- function(
  module_id,
  artifact_type,
  label = NULL,
  section = NULL,
  original_name = NULL,
  object = NULL,
  render_targets = c("human_report", "llm_docx")
) {
  intent <- infer_artifact_intent(artifact_type, label, section, original_name)
  importance <- infer_artifact_importance(module_id, artifact_type, label, section, original_name)
  purpose <- paste(intent, "artifact produced by", module_id)
  text <- .artifact_semantic_text(label, section, original_name)
  table_policy <- NULL
  policy_source <- "not_applicable"

  if (identical(artifact_type, "table") && exists("infer_table_artifact_policy", mode = "function")) {
    table_policy <- infer_table_artifact_policy(
      artifact_id = original_name %||% label %||% "table",
      label = label %||% "Table",
      source_module = module_id,
      object = object,
      metadata = list(original_name = original_name, normalized_section = section),
      section = section %||% "Analysis",
      render_target = "llm_docx"
    )
    policy_source <- if (grepl("shap|importance|risk|diagnostic|threshold|metric|performance|confusion|lift|gain|calibration|residual|error|interaction|correlation|missing|drift|group", text)) {
      "explicit"
    } else {
      "inferred"
    }
  }

  plot_policy <- if (identical(artifact_type, "plot")) {
    list(
      purpose = purpose,
      expected_interpretation = intent,
      recommended_caption = label %||% paste(intent, "Plot"),
      importance = importance,
      quality_expectations = "Use production rendering for LLM screenshots; preserve interactive widget for human reports.",
      render_targets = render_targets,
      future_interaction_capabilities = "Preserve source widget metadata for future interactive renderers."
    )
  } else {
    NULL
  }

  narrative_policy <- if (artifact_type %in% c("text", "narrative", "genai_narrative", "diagnostic", "recommendation")) {
    list(
      purpose = purpose,
      priority = importance,
      quality_level = if (identical(importance, "critical")) "high" else "standard",
      audience = "human_and_llm",
      render_targets = render_targets
    )
  } else {
    NULL
  }

  list(
    analytical_intent = intent,
    artifact_importance = importance,
    artifact_purpose = purpose,
    render_targets = render_targets,
    policy_source = "explicit_producer_metadata",
    table_policy = table_policy,
    table_policy_source = policy_source,
    plot_policy = plot_policy,
    narrative_policy = narrative_policy
  )
}

create_artifact <- function(
  artifact_id,
  artifact_type,
  label,
  source_module,
  object = NULL,
  content = NULL,
  config = list(),
  code = NULL,
  metadata = list(),
  section = "Analysis",
  order = NA_integer_,
  visible = TRUE,
  status = "ready",
  created_at = Sys.time(),
  updated_at = Sys.time()
) {
  if (isTRUE((metadata %||% list())$created_by_module) &&
      exists("producer_artifact_semantics", mode = "function")) {
    semantics <- producer_artifact_semantics(
      module_id = metadata$module_id %||% source_module,
      artifact_type = artifact_type,
      label = label,
      section = section,
      original_name = metadata$original_name %||% artifact_id,
      object = object
    )
    for (name in names(semantics)) {
      if (is.null(metadata[[name]]) && !is.null(semantics[[name]])) {
        metadata[[name]] <- semantics[[name]]
      }
    }
  }

  if (identical(artifact_type, "table") &&
      exists("attach_table_artifact_policy", mode = "function")) {
    policy_payload <- attach_table_artifact_policy(
      artifact_id = artifact_id,
      label = label,
      source_module = source_module,
      object = object,
      config = config,
      metadata = metadata,
      section = section
    )
    config <- policy_payload$config
    metadata <- policy_payload$metadata
  }

  structure(
    list(
      artifact_id = artifact_id,
      artifact_type = artifact_type,
      label = label,
      source_module = source_module,
      object = object,
      content = content,
      config = config,
      code = code,
      metadata = metadata,
      section = section,
      order = order,
      visible = visible,
      status = status,
      created_at = created_at,
      updated_at = updated_at
    ),
    class = c("aq_artifact", "list")
  )
}

validate_artifact <- function(artifact) {
  errors <- character()

  if (!inherits(artifact, "aq_artifact")) {
    errors <- c(errors, "Artifact must inherit from aq_artifact.")
  }

  if (!is.character(artifact$artifact_id) ||
      length(artifact$artifact_id) != 1L ||
      !nzchar(artifact$artifact_id)) {
    errors <- c(errors, "artifact_id must be a non-empty character value.")
  }

  if (!is.character(artifact$artifact_type) ||
      length(artifact$artifact_type) != 1L ||
      !artifact$artifact_type %in% artifact_types) {
    errors <- c(
      errors,
      paste("artifact_type must be one of:", paste(artifact_types, collapse = ", "))
    )
  }

  if (!is.character(artifact$label) ||
      length(artifact$label) != 1L ||
      !nzchar(artifact$label)) {
    errors <- c(errors, "label must be a non-empty character value.")
  }

  if (!is.character(artifact$source_module) ||
      length(artifact$source_module) != 1L ||
      !nzchar(artifact$source_module)) {
    errors <- c(errors, "source_module must be a non-empty character value.")
  }

  if (!is.character(artifact$status) ||
      length(artifact$status) != 1L ||
      !artifact$status %in% artifact_statuses) {
    errors <- c(
      errors,
      paste("status must be one of:", paste(artifact_statuses, collapse = ", "))
    )
  }

  if (!is.character(artifact$section) ||
      length(artifact$section) != 1L ||
      !nzchar(artifact$section)) {
    errors <- c(errors, "section must be a non-empty character value.")
  }

  if (!is.logical(artifact$visible) ||
      length(artifact$visible) != 1L ||
      is.na(artifact$visible)) {
    errors <- c(errors, "visible must be TRUE or FALSE.")
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      metadata = list(error_code = "ARTIFACT_INVALID")
    ))
  }

  service_result(
    status = "success",
    value = artifact,
    messages = paste("Artifact is valid:", artifact$artifact_id)
  )
}

artifact_summary <- function(artifacts) {
  if (inherits(artifacts, "aq_artifact")) {
    artifacts <- list(artifacts)
  }

  if (is.null(artifacts) || !length(artifacts)) {
    return(data.table::data.table(
      artifact_id = character(),
      artifact_type = character(),
      label = character(),
      source_module = character(),
      section = character(),
      order = integer(),
      visible = logical(),
      status = character()
    ))
  }

  rows <- lapply(artifacts, function(artifact) {
    data.table::data.table(
      artifact_id = artifact$artifact_id %||% NA_character_,
      artifact_type = artifact$artifact_type %||% NA_character_,
      label = artifact$label %||% NA_character_,
      source_module = artifact$source_module %||% NA_character_,
      section = artifact$section %||% NA_character_,
      order = suppressWarnings(as.integer(artifact$order %||% NA_integer_)),
      visible = isTRUE(artifact$visible),
      status = artifact$status %||% NA_character_
    )
  })

  data.table::rbindlist(rows, use.names = TRUE)
}

.plot_artifact_label <- function(plot_name, config, metadata) {
  metadata$label %||%
    metadata$title %||%
    config$options[["title.text"]] %||%
    plot_name
}

as_plot_artifact <- function(
  plot_name,
  plot_object,
  config,
  code,
  metadata = list()
) {
  create_artifact(
    artifact_id = plot_name,
    artifact_type = "plot",
    label = .plot_artifact_label(plot_name, config, metadata),
    source_module = "plot_builder",
    object = plot_object,
    config = config,
    code = code,
    metadata = metadata,
    section = metadata$section_name %||% "Analysis",
    order = metadata$sort_order %||% NA_integer_,
    visible = metadata$visible %||% TRUE,
    status = metadata$status %||% "ready"
  )
}

saved_plots_to_artifacts <- function(saved_plots, configs, code, metadata) {
  plot_names <- names(saved_plots)
  artifacts <- lapply(plot_names, function(plot_name) {
    as_plot_artifact(
      plot_name = plot_name,
      plot_object = saved_plots[[plot_name]],
      config = configs[[plot_name]] %||% list(),
      code = code[[plot_name]],
      metadata = metadata[[plot_name]] %||% list()
    )
  })

  stats::setNames(artifacts, plot_names)
}

combined_artifact_summary <- function(
  plot_artifacts = list(),
  text_artifacts = list(),
  table_artifacts = list(),
  module_artifacts = list()
) {
  artifacts <- c(
    plot_artifacts %||% list(),
    text_artifacts %||% list(),
    table_artifacts %||% list(),
    module_artifacts %||% list()
  )
  summary <- artifact_summary(artifacts)
  if (!nrow(summary)) {
    return(summary)
  }

  summary[order(summary$order, summary$section, summary$artifact_id)]
}

artifact_type_label <- function(artifact_type) {
  labels <- c(
    plot = "Plot",
    table = "Table",
    text = "Text",
    metric = "Metric",
    section_header = "Section",
    model_summary = "Model",
    forecast_block = "Forecast",
    genai_narrative = "Narrative",
    diagnostic = "Diagnostic",
    recommendation = "Recommendation",
    json = "JSON",
    narrative = "Narrative"
  )

  labels[[artifact_type]] %||% artifact_type
}

render_artifact_body <- function(artifact) {
  if (!inherits(artifact, "aq_artifact")) {
    return(htmltools::tags$div(
      class = "aq-artifact-placeholder",
      "This artifact type cannot be previewed."
    ))
  }

  if (identical(artifact$artifact_type, "plot")) {
    if (is.null(artifact$object)) {
      return(htmltools::tags$div(
        class = "aq-artifact-placeholder",
        "Plot artifact has no preview object available."
      ))
    }

    return(htmltools::tagList(artifact$object))
  }

  if (identical(artifact$artifact_type, "text")) {
    content <- artifact$content %||% ""
    paragraphs <- strsplit(content, "\\n\\s*\\n", perl = TRUE)[[1]]
    paragraphs <- paragraphs[nzchar(paragraphs)]
    if (!length(paragraphs)) {
      paragraphs <- "No text content."
    }

    return(htmltools::tags$article(
      class = "aq-text-artifact",
      lapply(paragraphs, function(paragraph) {
        htmltools::tags$p(htmltools::HTML(htmltools::htmlEscape(paragraph)))
      })
    ))
  }

  if (identical(artifact$artifact_type, "table")) {
    return(render_table(
      data = artifact$object,
      engine = artifact$config$engine %||% "reactable",
      title = NULL,
      page_size = artifact$config$page_size %||% 10,
      theme = artifact$config$theme %||% "auto"
    ))
  }

  if (identical(artifact$artifact_type, "metric")) {
    metric_data <- artifact$object
    if (is.null(metric_data)) {
      metric_data <- data.table::data.table(
        metric = artifact$label %||% artifact$artifact_id,
        value = artifact$content %||% ""
      )
    }
    return(render_table(
      data = metric_data,
      engine = "html",
      title = NULL,
      page_size = 10,
      theme = artifact$config$theme %||% "auto"
    ))
  }

  htmltools::tags$div(
    class = "aq-artifact-placeholder",
    paste("Preview is not available for artifact type:", artifact$artifact_type)
  )
}

render_artifact <- function(artifact, chrome = TRUE) {
  if (!isTRUE(chrome)) {
    return(render_artifact_body(artifact))
  }

  if (!inherits(artifact, "aq_artifact")) {
    return(htmltools::tags$article(
      class = "aq-report-artifact aq-report-artifact-unsupported",
      render_artifact_body(artifact)
    ))
  }

  htmltools::tags$article(
    class = paste(
      "aq-report-artifact",
      paste0("aq-report-artifact-", artifact$artifact_type)
    ),
    htmltools::tags$header(
      class = "aq-report-artifact-header",
      htmltools::tags$div(
        class = "aq-report-artifact-heading",
        htmltools::tags$h4(class = "aq-report-artifact-title", artifact$label %||% artifact$artifact_id),
        if (!is.null(artifact$source_module) && nzchar(artifact$source_module)) {
          htmltools::tags$p(class = "aq-report-artifact-source", module_display_label(artifact$source_module, artifact$source_module))
        }
      ),
      htmltools::tags$span(
        class = "aq-report-artifact-badge aq-status-badge aq-status-badge-neutral",
        artifact_type_label(artifact$artifact_type)
      )
    ),
    htmltools::tags$div(
      class = "aq-report-artifact-body",
      render_artifact_body(artifact)
    )
  )
}

artifact_semantics_audit <- function(artifacts) {
  if (inherits(artifacts, "aq_artifact")) {
    artifacts <- list(artifacts)
  }
  if (is.null(artifacts) || !length(artifacts)) {
    return(data.table::data.table(
      module = character(),
      artifact_id = character(),
      artifact_type = character(),
      policy_source = character(),
      analytical_intent = character(),
      artifact_importance = character(),
      render_targets = character(),
      status = character(),
      recommendation = character()
    ))
  }

  rows <- lapply(artifacts, function(artifact) {
    metadata <- artifact$metadata %||% list()
    table_architecture <- metadata$table_architecture %||% list()
    policy_source <- metadata$policy_source %||%
      if (!is.null(metadata$table_policy) || !is.null(artifact$config$table_policy)) {
        paste0("table_policy_", table_architecture$policy_source %||% "unknown")
      } else {
        "missing"
      }
    intent <- metadata$analytical_intent %||% NA_character_
    importance <- metadata$artifact_importance %||% NA_character_
    render_targets <- metadata$render_targets %||% character()
    has_required <- nzchar(as.character(intent %||% "")) &&
      nzchar(as.character(importance %||% "")) &&
      length(render_targets)
    data.table::data.table(
      module = artifact$source_module %||% metadata$module_id %||% NA_character_,
      artifact_id = artifact$artifact_id %||% NA_character_,
      artifact_type = artifact$artifact_type %||% NA_character_,
      policy_source = policy_source,
      analytical_intent = intent,
      artifact_importance = importance,
      render_targets = paste(render_targets, collapse = ", "),
      status = if (has_required) {
        if (grepl("inferred", policy_source)) "Inferred" else "Explicit"
      } else {
        "Missing"
      },
      recommendation = if (has_required) {
        "No action required."
      } else {
        "Declare analytical_intent, artifact_importance, and render_targets at production time."
      }
    )
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

qa_artifact_producer_semantics <- function() {
  table_artifacts <- if (exists("table_artifact_module_audit_fixtures", mode = "function")) {
    table_artifact_module_audit_fixtures()
  } else {
    list()
  }
  plot_artifact <- create_artifact(
    artifact_id = "qa_semantics_plot",
    artifact_type = "plot",
    label = "Variable Importance Plot",
    source_module = "qa_artifact_producer_semantics",
    object = NULL,
    metadata = module_artifact_metadata(
      module_id = "qa_artifact_producer_semantics",
      module_run_id = "run_semantics",
      source_module = "qa_artifact_producer_semantics",
      original_name = "variable_importance_plot",
      original_section = "Global Importance",
      normalized_section = "Global Importance"
    ),
    section = "Global Importance"
  )
  narrative_artifact <- create_artifact(
    artifact_id = "qa_semantics_narrative",
    artifact_type = "narrative",
    label = "Model Readiness Narrative",
    source_module = "qa_artifact_producer_semantics",
    content = "Readiness summary.",
    metadata = module_artifact_metadata(
      module_id = "qa_artifact_producer_semantics",
      module_run_id = "run_semantics",
      source_module = "qa_artifact_producer_semantics",
      original_name = "model_readiness_narrative",
      original_section = "Model Overview",
      normalized_section = "Model Overview"
    ),
    section = "Model Overview"
  )
  artifacts <- c(table_artifacts, list(plot_artifact, narrative_artifact))
  audit <- artifact_semantics_audit(artifacts)
  missing_artifact <- plot_artifact
  missing_artifact$metadata$analytical_intent <- NULL
  missing_artifact$metadata$artifact_importance <- NULL
  missing_artifact$metadata$render_targets <- NULL
  missing_audit <- artifact_semantics_audit(list(missing_artifact))
  summary_by_module <- audit[, .N, by = .(module, artifact_type, status, analytical_intent, artifact_importance)]

  data.table::data.table(
    check = c(
      "artifact_semantics_available",
      "policy_source_reported",
      "intent_reported",
      "importance_reported",
      "render_targets_reported",
      "coverage_summary_available",
      "missing_semantics_reported"
    ),
    status = c(
      if (nrow(audit) == length(artifacts)) "success" else "error",
      if (all(nzchar(audit$policy_source))) "success" else "error",
      if (all(nzchar(audit$analytical_intent))) "success" else "error",
      if (all(audit$artifact_importance %in% artifact_importance_levels)) "success" else "error",
      if (all(nzchar(audit$render_targets))) "success" else "error",
      if (nrow(summary_by_module) > 0L) "success" else "error",
      if (identical(missing_audit$status[[1]], "Missing")) "success" else "error"
    ),
    message = c(
      paste("Artifacts audited:", nrow(audit)),
      paste("Policy sources:", paste(unique(audit$policy_source), collapse = ", ")),
      paste("Intents:", paste(unique(audit$analytical_intent), collapse = ", ")),
      paste("Importance:", paste(unique(audit$artifact_importance), collapse = ", ")),
      paste("Render targets:", paste(unique(audit$render_targets), collapse = " | ")),
      paste("Coverage rows:", nrow(summary_by_module)),
      paste("Missing audit status:", missing_audit$status[[1]])
    )
  )
}

qa_artifact_model <- function() {
  plot_artifact <- create_artifact(
    artifact_id = "p1",
    artifact_type = "plot",
    label = "Revenue by Date",
    source_module = "plot_builder",
    object = NULL,
    config = list(plot_type = "Line"),
    code = "p1 <- AutoPlots::Line(...)",
    metadata = list(section_name = "Analysis", sort_order = 1L),
    section = "Analysis",
    order = 1L
  )

  text_artifact <- create_artifact(
    artifact_id = "n1",
    artifact_type = "text",
    label = "Summary",
    source_module = "genai_narrative",
    content = "Revenue increased over the selected period.",
    section = "Narrative",
    order = 2L
  )

  table_artifact <- create_artifact(
    artifact_id = "t1",
    artifact_type = "table",
    label = "Metrics",
    source_module = "eda",
    object = data.table::data.table(a = 1:3),
    section = "Tables",
    order = 3L
  )

  artifacts <- list(
    p1 = plot_artifact,
    n1 = text_artifact,
    t1 = table_artifact
  )

  validations <- lapply(artifacts, validate_artifact)
  if (!all(vapply(validations, function(result) {
    identical(result$status, "success")
  }, logical(1)))) {
    stop("Artifact model QA failed validation.", call. = FALSE)
  }

  artifact_summary(artifacts)
}
