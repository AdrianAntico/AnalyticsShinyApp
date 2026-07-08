.code_output_artifact_id <- function(run_id, artifact_type) {
  paste("code", run_id, artifact_type, format(Sys.time(), "%Y%m%d%H%M%S"), sep = "_")
}

.code_metric_table <- function(value) {
  if (is.numeric(value) && is.atomic(value)) {
    return(data.table::data.table(name = names(value) %||% paste0("value_", seq_along(value)), value = as.numeric(value)))
  }

  if (is.list(value) && length(value) && all(vapply(value, function(item) {
    is.numeric(item) && length(item) == 1L
  }, logical(1)))) {
    return(data.table::data.table(
      name = names(value) %||% paste0("value_", seq_along(value)),
      value = as.numeric(unlist(value, use.names = FALSE))
    ))
  }

  NULL
}

code_output_to_artifact_candidates <- function(
  value,
  run_record,
  label_prefix = NULL
) {
  if (is.null(value) || is.null(run_record)) {
    return(list())
  }

  label_prefix <- label_prefix %||% run_record$label %||% "Code Output"
  run_id <- run_record$run_id %||% "code_run"
  metadata <- list(
    module_id = "code_runner",
    module_run_id = run_id,
    source_module = "code_runner",
    original_name = label_prefix,
    original_section = "Code Runner",
    normalized_section = "Code Runner",
    artifact_index = NA_integer_,
    created_by_module = TRUE,
    run_id = run_id,
    code_hash = run_record$code_hash %||% NA_character_,
    source = run_record$source %||% "manual",
    created_by_code_runner = TRUE
  )

  if (data.table::is.data.table(value) || is.data.frame(value)) {
    artifact <- create_artifact(
      artifact_id = .code_output_artifact_id(run_id, "table"),
      artifact_type = "table",
      label = paste(label_prefix, "Table"),
      source_module = "code_runner",
      object = data.table::as.data.table(value),
      config = list(engine = "reactable", page_size = 10, theme = "auto"),
      metadata = metadata,
      section = "Code Runner",
      order = NA_integer_,
      status = "ready"
    )
    return(stats::setNames(list(artifact), artifact$artifact_id))
  }

  if (inherits(value, "htmlwidget")) {
    artifact <- create_artifact(
      artifact_id = .code_output_artifact_id(run_id, "plot"),
      artifact_type = "plot",
      label = paste(label_prefix, "Plot"),
      source_module = "code_runner",
      object = value,
      metadata = metadata,
      section = "Code Runner",
      order = NA_integer_,
      status = "ready"
    )
    return(stats::setNames(list(artifact), artifact$artifact_id))
  }

  if (is.character(value)) {
    artifact <- create_artifact(
      artifact_id = .code_output_artifact_id(run_id, "text"),
      artifact_type = "text",
      label = paste(label_prefix, "Text"),
      source_module = "code_runner",
      content = paste(value, collapse = "\n"),
      config = list(format = "markdown"),
      metadata = metadata,
      section = "Code Runner",
      order = NA_integer_,
      status = "ready"
    )
    return(stats::setNames(list(artifact), artifact$artifact_id))
  }

  metric_table <- .code_metric_table(value)
  if (!is.null(metric_table)) {
    artifact <- create_artifact(
      artifact_id = .code_output_artifact_id(run_id, "metric"),
      artifact_type = "metric",
      label = paste(label_prefix, "Metric"),
      source_module = "code_runner",
      object = metric_table,
      metadata = metadata,
      section = "Code Runner",
      order = NA_integer_,
      status = "ready"
    )
    return(stats::setNames(list(artifact), artifact$artifact_id))
  }

  list()
}
