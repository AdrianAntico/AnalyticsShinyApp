artifact_quality_components <- function() {
  c(
    "screenshot",
    "caption",
    "narrative",
    "metadata",
    "diagnostics",
    "recommendations",
    "table",
    "table_preview",
    "sorting_policy",
    "backing_data",
    "json"
  )
}

artifact_quality_policy <- function(render_target = "llm_docx") {
  target_validation <- validate_render_target(render_target)
  if (!identical(target_validation$status, "success")) {
    return(target_validation)
  }

  list(
    render_target = render_target,
    required_metadata = c(
      "artifact_id",
      "artifact_type",
      "source_module",
      "render_target",
      "created_at",
      "caption",
      "screenshot_status",
      "table_status",
      "json_status"
    ),
    required_components = if (identical(render_target, "llm_docx")) c("caption", "metadata") else c("caption"),
    graphical_screenshot_required = identical(render_target, "llm_docx"),
    optional_components = c("narrative", "diagnostics", "recommendations", "table", "table_preview", "sorting_policy", "backing_data", "json"),
    table_preview_rows = 12L
  )
}

artifact_quality_table_status <- function(artifact, max_rows = 12L, table_backing = list()) {
  if (!artifact$artifact_type %in% c("table", "metric")) {
    return(list(
      status = "not_applicable",
      row_count = NA_integer_,
      truncated = FALSE,
      preview = "not_applicable",
      sorting_policy = "not_applicable",
      backing_data = "not_applicable",
      csv = "not_applicable",
      json = "not_applicable"
    ))
  }
  if (is.null(artifact$object)) {
    return(list(
      status = "missing",
      row_count = NA_integer_,
      truncated = FALSE,
      preview = "missing",
      sorting_policy = "missing",
      backing_data = "missing",
      csv = "not_supplied",
      json = "not_supplied"
    ))
  }
  table_quality <- if (exists("table_artifact_quality_status", mode = "function")) {
    table_artifact_quality_status(artifact, render_target = "llm_docx", backing = table_backing)
  } else {
    NULL
  }
  rows <- tryCatch(nrow(data.table::as.data.table(artifact$object)), error = function(e) NA_integer_)
  list(
    status = if (is.na(rows)) "unavailable" else "available",
    row_count = rows,
    truncated = !is.na(rows) && rows > max_rows,
    preview = table_quality$preview %||% if (is.na(rows)) "missing" else "available",
    sorting_policy = table_quality$sorting_policy %||% "available",
    backing_data = table_quality$backing_data %||% if (is.na(rows)) "missing" else "available",
    csv = table_quality$csv %||% if (isTRUE(table_backing$csv_available)) "available" else "not_supplied",
    json = table_quality$json %||% if (isTRUE(table_backing$json_available)) "available" else "not_supplied"
  )
}

artifact_quality_json_status <- function(artifact, table_backing = list()) {
  metadata <- artifact$metadata %||% list()
  has_json <- identical(artifact$artifact_type, "json") ||
    !is.null(metadata$json) ||
    !is.null(metadata$json_payload) ||
    !is.null(metadata$structured_payload) ||
    isTRUE(table_backing$json_available)
  if (has_json) "available" else "not_supplied"
}

artifact_quality_component_status <- function(
  artifact,
  render_target = "llm_docx",
  screenshot = NULL,
  table_backing = list(),
  diagnostics = NULL,
  recommendations = NULL
) {
  policy <- artifact_quality_policy(render_target)
  table_status <- artifact_quality_table_status(artifact, policy$table_preview_rows, table_backing)
  metadata <- artifact$metadata %||% list()
  content <- artifact$content %||% ""
  artifact_diagnostics <- diagnostics %||% metadata$diagnostics %||% metadata$warnings %||% list()
  artifact_recommendations <- recommendations %||% metadata$recommendations %||% list()

  screenshot_status <- "not_applicable"
  if (identical(artifact$artifact_type, "plot") && isTRUE(policy$graphical_screenshot_required)) {
    screenshot_status <- screenshot$status %||% "missing"
  }

  list(
    screenshot = screenshot_status,
    caption = if (nzchar(artifact_caption(artifact, render_target))) "available" else "missing",
    narrative = if (artifact$artifact_type %in% c("text", "genai_narrative", "narrative") && nzchar(content)) "available" else if (nzchar(metadata$narrative %||% "")) "available" else "not_supplied",
    metadata = if (length(metadata)) "available" else "minimal",
    diagnostics = if (length(artifact_diagnostics)) "available" else "not_supplied",
    recommendations = if (length(artifact_recommendations)) "available" else "not_supplied",
    table = table_status$status,
    table_preview = table_status$preview,
    sorting_policy = table_status$sorting_policy,
    backing_data = table_status$backing_data,
    json = artifact_quality_json_status(artifact, table_backing),
    table_row_count = table_status$row_count,
    table_truncated = table_status$truncated
  )
}

artifact_quality_standard_metadata <- function(
  artifact,
  render_target = "llm_docx",
  screenshot = NULL,
  table_backing = list(),
  diagnostics = NULL,
  recommendations = NULL
) {
  component_status <- artifact_quality_component_status(
    artifact = artifact,
    render_target = render_target,
    screenshot = screenshot,
    table_backing = table_backing,
    diagnostics = diagnostics,
    recommendations = recommendations
  )
  list(
    artifact_id = artifact$artifact_id %||% NA_character_,
    artifact_type = artifact$artifact_type %||% NA_character_,
    source_module = artifact$source_module %||% NA_character_,
    render_target = render_target,
    created_at = as.character(artifact$created_at %||% Sys.time()),
    caption = artifact_caption(artifact, render_target),
    screenshot_status = component_status$screenshot,
    table_status = component_status$table,
    json_status = component_status$json,
    table_row_count = component_status$table_row_count,
    table_truncated = component_status$table_truncated
  )
}

artifact_completeness_score <- function(component_status) {
  components <- artifact_quality_components()
  weights <- stats::setNames(rep(1 / length(components), length(components)), components)
  available <- vapply(components, function(component) {
    status <- component_status[[component]] %||% "missing"
    status %in% c("available", "success", "minimal", "not_applicable")
  }, logical(1))
  round(sum(weights[available]) * 100, 1)
}

assess_artifact_quality <- function(
  artifact,
  render_target = "llm_docx",
  screenshot = NULL,
  table_backing = list(),
  diagnostics = NULL,
  recommendations = NULL
) {
  policy <- artifact_quality_policy(render_target)
  if (!is.list(policy)) {
    return(policy)
  }

  standard_metadata <- artifact_quality_standard_metadata(
    artifact = artifact,
    render_target = render_target,
    screenshot = screenshot,
    table_backing = table_backing,
    diagnostics = diagnostics,
    recommendations = recommendations
  )
  component_status <- artifact_quality_component_status(
    artifact = artifact,
    render_target = render_target,
    screenshot = screenshot,
    table_backing = table_backing,
    diagnostics = diagnostics,
    recommendations = recommendations
  )
  missing_required_metadata <- names(standard_metadata)[
    vapply(standard_metadata, function(value) {
      is.null(value) || length(value) == 0L || all(is.na(value)) || all(!nzchar(as.character(value)))
    }, logical(1))
  ]
  missing_required_metadata <- intersect(policy$required_metadata, missing_required_metadata)
  missing_required_components <- policy$required_components[
    !vapply(policy$required_components, function(component) {
      component_status[[component]] %in% c("available", "minimal", "not_applicable")
    }, logical(1))
  ]

  if (identical(artifact$artifact_type, "plot") &&
      isTRUE(policy$graphical_screenshot_required) &&
      !component_status$screenshot %in% c("success", "available")) {
    missing_required_components <- unique(c(missing_required_components, "screenshot"))
  }

  severity <- if (length(missing_required_metadata)) {
    "error"
  } else if (length(missing_required_components)) {
    "warning"
  } else {
    "info"
  }

  result <- list(
    artifact_id = artifact$artifact_id %||% NA_character_,
    artifact_type = artifact$artifact_type %||% NA_character_,
    render_target = render_target,
    caption = standard_metadata$caption,
    components = component_status,
    standard_metadata = standard_metadata,
    missing_required_metadata = missing_required_metadata,
    missing_required_components = missing_required_components,
    artifact_completeness = artifact_completeness_score(component_status),
    severity = severity,
    recommendation = if (length(missing_required_components)) {
      paste("Add or repair:", paste(missing_required_components, collapse = ", "))
    } else {
      "Artifact meets the current quality policy."
    }
  )
  class(result) <- c("artifact_quality_assessment", "list")
  result
}

artifact_quality_summary <- function(artifacts, render_target = "llm_docx", screenshot_index = list(), table_index = list()) {
  if (inherits(artifacts, "aq_artifact")) {
    artifacts <- list(artifacts)
  }
  if (is.null(artifacts) || !length(artifacts)) {
    return(data.table::data.table(
      artifact_id = character(),
      artifact_type = character(),
      render_target = character(),
      artifact_completeness = numeric(),
      severity = character(),
      missing_required_metadata = character(),
      missing_required_components = character(),
      caption = character()
    ))
  }

  rows <- lapply(artifacts, function(artifact) {
    assessment <- assess_artifact_quality(
      artifact = artifact,
      render_target = render_target,
      screenshot = screenshot_index[[artifact$artifact_id]],
      table_backing = table_index[[artifact$artifact_id]] %||% list()
    )
    data.table::data.table(
      artifact_id = assessment$artifact_id,
      artifact_type = assessment$artifact_type,
      render_target = assessment$render_target,
      artifact_completeness = assessment$artifact_completeness,
      severity = assessment$severity,
      missing_required_metadata = paste(assessment$missing_required_metadata, collapse = ", "),
      missing_required_components = paste(assessment$missing_required_components, collapse = ", "),
      caption = assessment$caption
    )
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

qa_artifact_quality_policy <- function(output_dir = file.path(tempdir(), "artifact_quality_policy_qa")) {
  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  dt <- data.table::data.table(category = paste0("Cat ", 1:20), value = seq_len(20))
  plot <- AutoPlots::Bar(dt = dt, XVar = "category", YVar = "value", title.text = "Quality Policy QA")
  plot_artifact <- create_artifact(
    artifact_id = "qa_quality_plot",
    artifact_type = "plot",
    label = "Quality Policy Plot",
    source_module = "qa_artifact_quality_policy",
    object = plot,
    metadata = list(narrative = "Synthetic bar chart for policy QA."),
    section = "Quality Policy",
    order = 1L
  )
  table_artifact <- create_artifact(
    artifact_id = "qa_quality_table",
    artifact_type = "table",
    label = "Quality Policy Table",
    source_module = "qa_artifact_quality_policy",
    object = dt,
    metadata = list(recommendations = "Review long category lists."),
    section = "Quality Policy",
    order = 2L
  )
  text_artifact <- create_artifact(
    artifact_id = "qa_quality_text",
    artifact_type = "narrative",
    label = "Quality Policy Narrative",
    source_module = "qa_artifact_quality_policy",
    content = "This artifact supplies narrative context.",
    metadata = list(diagnostics = "Narrative supplied."),
    section = "Quality Policy",
    order = 3L
  )

  missing_screenshot <- assess_artifact_quality(plot_artifact, render_target = "llm_docx")
  text_quality <- assess_artifact_quality(text_artifact, render_target = "llm_docx")
  bad_artifact <- plot_artifact
  bad_artifact$artifact_id <- NA_character_
  bad_quality <- assess_artifact_quality(bad_artifact, render_target = "llm_docx")

  collector <- create_project_artifact_collector(
    project_id = "qa_quality_project",
    project_name = "QA Quality Project",
    output_dir = output_dir
  )
  result <- service_result(
    status = "success",
    artifacts = list(
      qa_quality_plot = plot_artifact,
      qa_quality_table = table_artifact,
      qa_quality_text = text_artifact
    ),
    metadata = list(module_id = "qa_artifact_quality_policy", module_run_id = "run_quality")
  )
  append <- project_collector_append_result(
    collector,
    result,
    run_id = "run_001",
    module_id = "qa_artifact_quality_policy",
    module_label = "QA Artifact Quality Policy",
    write = FALSE
  )
  collector <- append$value
  write <- project_collector_write(collector)
  quality_index <- write$metadata$quality_index %||% data.table::data.table()

  data.table::data.table(
    check = c(
      "required_metadata_reported",
      "captions_available",
      "render_target_recorded",
      "graceful_degradation",
      "completeness_scoring",
      "collector_behavior",
      "missing_component_handling",
      "table_truncation_status",
      "quality_index_available"
    ),
    status = c(
      if ("artifact_id" %in% bad_quality$missing_required_metadata) "success" else "error",
      if (nzchar(text_quality$caption)) "success" else "error",
      if (identical(text_quality$render_target, "llm_docx")) "success" else "error",
      if (identical(missing_screenshot$severity, "warning") && "screenshot" %in% missing_screenshot$missing_required_components) "success" else "error",
      if (is.numeric(text_quality$artifact_completeness) && text_quality$artifact_completeness >= 0 && text_quality$artifact_completeness <= 100) "success" else "error",
      if (identical(write$status, "success") && project_collector_docx_integrity(collector$collector_docx)) "success" else "error",
      if (identical(artifact_quality_json_status(text_artifact), "not_supplied")) "success" else "error",
      if (isTRUE(artifact_quality_table_status(table_artifact)$truncated)) "success" else "error",
      if (nrow(quality_index) == 3L && "artifact_completeness" %in% names(quality_index)) "success" else "error"
    ),
    message = c(
      paste("Missing metadata:", paste(bad_quality$missing_required_metadata, collapse = ", ")),
      text_quality$caption,
      text_quality$render_target,
      paste("Missing components:", paste(missing_screenshot$missing_required_components, collapse = ", ")),
      paste("Completeness:", text_quality$artifact_completeness),
      paste("Collector status:", write$status),
      "JSON absence is recorded without failure.",
      paste("Rows:", artifact_quality_table_status(table_artifact)$row_count),
      paste("Quality rows:", nrow(quality_index))
    )
  )
}
