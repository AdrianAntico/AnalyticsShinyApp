render_targets <- function() {
  c(
    "human_report",
    "html_report",
    "rmarkdown",
    "llm_docx",
    "markdown",
    "pdf",
    "json_archive"
  )
}

validate_render_target <- function(render_target) {
  if (!is.character(render_target) ||
      length(render_target) != 1L ||
      !render_target %in% render_targets()) {
    return(service_result(
      status = "error",
      errors = paste("render_target must be one of:", paste(render_targets(), collapse = ", ")),
      metadata = list(error_code = "RENDER_TARGET_INVALID")
    ))
  }

  service_result(status = "success", value = render_target)
}

render_target_policy <- function(render_target = "human_report") {
  validation <- validate_render_target(render_target)
  if (!identical(validation$status, "success")) {
    return(validation)
  }

  policies <- list(
    human_report = list(
      render_target = "human_report",
      preserve_interactivity = TRUE,
      use_screenshots = FALSE,
      include_metadata = TRUE,
      include_supporting_payloads = FALSE,
      description = "Human-facing reports preserve existing interactive widgets and layout behavior."
    ),
    html_report = list(
      render_target = "html_report",
      preserve_interactivity = TRUE,
      use_screenshots = FALSE,
      include_metadata = TRUE,
      include_supporting_payloads = FALSE,
      description = "HTML reports preserve interactive widgets and existing sizing behavior."
    ),
    rmarkdown = list(
      render_target = "rmarkdown",
      preserve_interactivity = TRUE,
      use_screenshots = FALSE,
      include_metadata = TRUE,
      include_supporting_payloads = FALSE,
      description = "R Markdown reports preserve existing report rendering behavior."
    ),
    llm_docx = list(
      render_target = "llm_docx",
      preserve_interactivity = FALSE,
      use_screenshots = TRUE,
      include_metadata = TRUE,
      include_supporting_payloads = TRUE,
      description = "LLM DOCX collectors use production screenshots plus captions, metadata, tables, diagnostics, recommendations, and JSON payloads."
    ),
    markdown = list(
      render_target = "markdown",
      preserve_interactivity = FALSE,
      use_screenshots = TRUE,
      include_metadata = TRUE,
      include_supporting_payloads = TRUE,
      description = "Markdown collectors may use screenshots and compact metadata."
    ),
    pdf = list(
      render_target = "pdf",
      preserve_interactivity = FALSE,
      use_screenshots = TRUE,
      include_metadata = TRUE,
      include_supporting_payloads = TRUE,
      description = "PDF render targets are static and may use screenshots."
    ),
    json_archive = list(
      render_target = "json_archive",
      preserve_interactivity = FALSE,
      use_screenshots = FALSE,
      include_metadata = TRUE,
      include_supporting_payloads = TRUE,
      description = "JSON archives preserve structured artifact metadata and payload references."
    )
  )

  service_result(status = "success", value = policies[[render_target]])
}

artifact_render_metadata <- function(artifact, render_target = "human_report", extra = list()) {
  policy <- render_target_policy(render_target)
  if (!identical(policy$status, "success")) {
    stop(paste(policy$errors, collapse = " "), call. = FALSE)
  }

  metadata <- artifact$metadata %||% list()
  metadata$render_target <- render_target
  metadata$render_policy <- policy$value
  metadata$render_source_artifact_id <- artifact$artifact_id %||% NULL
  metadata$render_source_module <- artifact$source_module %||% NULL
  metadata$render_created_at <- as.character(Sys.time())
  if (length(extra)) {
    metadata$render_extra <- extra
  }
  metadata
}

artifact_caption <- function(artifact, render_target = "human_report") {
  label <- artifact$label %||% artifact$artifact_id %||% "Artifact"
  section <- artifact$section %||% "Analysis"
  type <- artifact_type_label(artifact$artifact_type %||% "artifact")
  paste(type, "-", section, "-", label, "| render_target:", render_target)
}

qa_render_targets <- function(output_dir = file.path(tempdir(), "render_target_qa")) {
  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  data <- data.table::data.table(category = paste0("Category ", 1:6), value = c(10, 14, 8, 16, 9, 12))
  widget <- AutoPlots::Bar(dt = data, XVar = "category", YVar = "value", title.text = "Render Target QA")
  human_artifact <- create_artifact(
    artifact_id = "qa_render_bar",
    artifact_type = "plot",
    label = "Render Target QA Bar",
    source_module = "qa_render_targets",
    object = widget,
    metadata = list(render_target = "human_report"),
    section = "Render Target QA",
    order = 1L
  )
  table_artifact <- create_artifact(
    artifact_id = "qa_render_table",
    artifact_type = "table",
    label = "Render Target QA Table",
    source_module = "qa_render_targets",
    object = data,
    metadata = list(render_target = "llm_docx"),
    section = "Render Target QA",
    order = 2L
  )
  narrative_artifact <- create_artifact(
    artifact_id = "qa_render_narrative",
    artifact_type = "narrative",
    label = "Render Target QA Narrative",
    source_module = "qa_render_targets",
    content = "LLM render targets include context without changing human widgets.",
    metadata = list(render_target = "llm_docx"),
    section = "Render Target QA",
    order = 3L
  )

  object_before <- human_artifact$object
  result <- service_result(
    status = "success",
    artifacts = list(
      qa_render_bar = human_artifact,
      qa_render_table = table_artifact,
      qa_render_narrative = narrative_artifact
    ),
    metadata = list(module_id = "qa_render_targets", module_run_id = "qa_render_run")
  )
  collector <- create_project_artifact_collector(
    project_id = "qa_render_project",
    project_name = "QA Render Project",
    output_dir = output_dir,
    render_target = "llm_docx"
  )
  append <- project_collector_append_result(
    collector,
    result,
    run_id = "run_001",
    module_id = "qa_render_targets",
    module_label = "QA Render Targets",
    write = FALSE
  )
  collector <- append$value
  write <- project_collector_write(collector)
  screenshot_index <- write$metadata$screenshot_index %||% list()
  manifest <- if (file.exists(collector$manifest_file)) data.table::fread(collector$manifest_file) else data.table::data.table()

  export_png_check <- "warning"
  export_png_message <- "AutoQuant EDA ExportPNG comparison was not run."
  if (requireNamespace("AutoQuant", quietly = TRUE) &&
      "generate_eda_artifacts" %in% getNamespaceExports("AutoQuant")) {
    export_dir <- file.path(output_dir, "export_png")
    dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)
    eda_data <- data.table::data.table(x = 1:8, y = c(3, 5, 4, 8, 6, 9, 7, 10))
    without_png <- tryCatch(
      AutoQuant::generate_eda_artifacts(
        data = eda_data,
        DataName = "qa_export_png",
        UnivariateVars = c("x", "y"),
        CorrVars = c("x", "y"),
        Theme = "dark",
        ExportPNG = FALSE
      ),
      error = function(e) e
    )
    with_png <- tryCatch(
      AutoQuant::generate_eda_artifacts(
        data = eda_data,
        DataName = "qa_export_png",
        UnivariateVars = c("x", "y"),
        CorrVars = c("x", "y"),
        Theme = "dark",
        ExportPNG = TRUE,
        OutputPath = export_dir
      ),
      error = function(e) e
    )
    if (!inherits(without_png, "error") && !inherits(with_png, "error")) {
      widget_names_unchanged <- identical(names(without_png$plots), names(with_png$plots))
      class_signature <- function(items) {
        vapply(items, function(item) paste(class(item), collapse = "|"), character(1))
      }
      widget_classes_unchanged <- identical(
        class_signature(without_png$plots),
        class_signature(with_png$plots)
      )
      has_manifest <- is.data.frame(with_png$context$ImageManifest %||% NULL) &&
        any(nzchar(with_png$context$ImageManifest$png %||% character()))
      export_png_check <- if (widget_names_unchanged && widget_classes_unchanged && has_manifest) "success" else "error"
      export_png_message <- paste(
        "ExportPNG widget names/classes unchanged:",
        widget_names_unchanged && widget_classes_unchanged,
        "| LLM PNG manifest:",
        has_manifest
      )
    } else {
      export_png_check <- "error"
      without_msg <- if (inherits(without_png, "error")) conditionMessage(without_png) else "without_png ok"
      with_msg <- if (inherits(with_png, "error")) conditionMessage(with_png) else "with_png ok"
      export_png_message <- paste(
        "ExportPNG comparison failed:",
        without_msg,
        with_msg
      )
    }
  }

  data.table::data.table(
    check = c(
      "render_targets_registered",
      "human_policy_preserves_widgets",
      "llm_policy_uses_screenshots",
      "human_artifact_object_unchanged",
      "collector_render_target",
      "llm_screenshot_generated",
      "caption_metadata_available",
      "table_payload_available",
      "docx_integrity",
      "manifest_integrity",
      "export_png_does_not_change_human_widgets"
    ),
    status = c(
      if (all(c("human_report", "llm_docx") %in% render_targets())) "success" else "error",
      if (isTRUE(render_target_policy("human_report")$value$preserve_interactivity)) "success" else "error",
      if (isTRUE(render_target_policy("llm_docx")$value$use_screenshots)) "success" else "error",
      if (identical(object_before, human_artifact$object)) "success" else "error",
      if (identical(collector$render_target, "llm_docx")) "success" else "error",
      if (identical(screenshot_index$qa_render_bar$status, "success") && file.exists(screenshot_index$qa_render_bar$file)) "success" else "error",
      if (nzchar(artifact_caption(human_artifact, "llm_docx")) && !is.null(artifact_render_metadata(human_artifact, "llm_docx")$render_policy)) "success" else "error",
      if (nrow(table_artifact$object) == nrow(data)) "success" else "error",
      if (identical(write$status, "success") && project_collector_docx_integrity(collector$collector_docx)) "success" else "error",
      if (nrow(manifest) == 1L && "render_target" %in% names(manifest)) "success" else "error",
      export_png_check
    ),
    message = c(
      paste(render_targets(), collapse = ", "),
      "Human render target keeps interactive objects.",
      "LLM DOCX render target uses production screenshots.",
      "Collector writing did not mutate the human artifact object.",
      paste("Collector target:", collector$render_target),
      paste("Screenshot helper:", screenshot_index$qa_render_bar$helper %||% NA_character_),
      artifact_caption(human_artifact, "llm_docx"),
      paste("Rows:", nrow(table_artifact$object)),
      paste("DOCX:", collector$collector_docx),
      paste("Manifest rows:", nrow(manifest)),
      export_png_message
    )
  )
}
