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
  "model_summary", "forecast_block", "genai_narrative"
)

artifact_statuses <- c(
  "ready", "draft", "needs_data", "missing_columns",
  "rebuild_failed", "hidden"
)

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
    genai_narrative = "Narrative"
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
          htmltools::tags$p(class = "aq-report-artifact-source", artifact$source_module)
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
