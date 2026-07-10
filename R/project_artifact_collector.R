project_collector_statuses <- c(
  "success", "warning", "error", "skipped", "not_requested", "empty"
)

project_artifact_bundle <- function(
  project_id,
  project_name = project_id,
  run_id,
  module_id,
  module_label = module_id,
  artifacts = list(),
  status = "success",
  warnings = character(),
  errors = character(),
  diagnostics = list(),
  metadata = list(),
  created_at = Sys.time()
) {
  if (!status %in% project_collector_statuses) {
    stop("Bundle status is not valid.", call. = FALSE)
  }

  structure(
    list(
      bundle_id = paste(project_id, run_id, module_id, sep = "::"),
      project_id = project_id,
      project_name = project_name,
      run_id = run_id,
      module_id = module_id,
      module_label = module_label,
      status = status,
      artifacts = artifacts %||% list(),
      warnings = warnings %||% character(),
      errors = errors %||% character(),
      diagnostics = diagnostics %||% list(),
      metadata = metadata %||% list(),
      created_at = created_at
    ),
    class = c("project_artifact_bundle", "list")
  )
}

project_artifact_bundle_from_result <- function(
  result,
  project_id,
  project_name = project_id,
  run_id = NULL,
  module_id = NULL,
  module_label = NULL
) {
  metadata <- result$metadata %||% list()
  module_id <- module_id %||% metadata$module_id %||% "unknown_module"
  run_id <- run_id %||% metadata$module_run_id %||% paste0(module_id, "_", format(Sys.time(), "%Y%m%d%H%M%S"))
  module_label <- module_label %||% module_id

  artifacts <- result$artifacts %||% list()
  if (exists("ensure_table_artifact_policy", mode = "function") && length(artifacts)) {
    artifacts <- lapply(artifacts, ensure_table_artifact_policy, render_target = "llm_docx")
  }
  status <- result$status %||% "error"
  if (identical(status, "needs_input")) {
    status <- "skipped"
  }
  if (identical(status, "success") && !length(artifacts)) {
    status <- "empty"
  }

  project_artifact_bundle(
    project_id = project_id,
    project_name = project_name,
    run_id = run_id,
    module_id = module_id,
    module_label = module_label,
    artifacts = artifacts,
    status = status,
    warnings = result$warnings %||% character(),
    errors = result$errors %||% character(),
    diagnostics = result$diagnostics %||% list(),
    metadata = metadata
  )
}

validate_project_artifact_bundle <- function(bundle) {
  errors <- character()

  if (!inherits(bundle, "project_artifact_bundle")) {
    errors <- c(errors, "Bundle must inherit from project_artifact_bundle.")
  }

  required <- c("project_id", "project_name", "run_id", "module_id", "status", "artifacts")
  missing <- setdiff(required, names(bundle))
  if (length(missing)) {
    errors <- c(errors, paste("Bundle is missing required fields:", paste(missing, collapse = ", ")))
  }

  if (!is.character(bundle$project_id) || !nzchar(bundle$project_id %||% "")) {
    errors <- c(errors, "project_id must be a non-empty character value.")
  }
  if (!is.character(bundle$run_id) || !nzchar(bundle$run_id %||% "")) {
    errors <- c(errors, "run_id must be a non-empty character value.")
  }
  if (!is.character(bundle$module_id) || !nzchar(bundle$module_id %||% "")) {
    errors <- c(errors, "module_id must be a non-empty character value.")
  }
  if (!is.character(bundle$status) ||
      length(bundle$status) != 1L ||
      !bundle$status %in% project_collector_statuses) {
    errors <- c(errors, "status is not valid.")
  }
  if (!is.list(bundle$artifacts)) {
    errors <- c(errors, "artifacts must be a list.")
  }

  if (length(bundle$artifacts)) {
    artifact_errors <- unlist(lapply(bundle$artifacts, function(artifact) {
      validation <- validate_artifact(artifact)
      validation$errors %||% character()
    }), use.names = FALSE)
    if (length(artifact_errors)) {
      errors <- c(errors, paste("One or more artifacts are invalid:", paste(artifact_errors, collapse = " | ")))
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      metadata = list(error_code = "PROJECT_ARTIFACT_BUNDLE_INVALID")
    ))
  }

  service_result(status = "success", value = bundle)
}

create_project_artifact_collector <- function(
  project_id,
  project_name = project_id,
  output_dir = file.path("docs", "project_artifact_collector"),
  collector_docx = "Project_Artifact_Collector.docx",
  artifact_directory = "artifacts",
  render_target = "llm_docx"
) {
  render_target_validation <- validate_render_target(render_target)
  if (!identical(render_target_validation$status, "success")) {
    stop(paste(render_target_validation$errors, collapse = " "), call. = FALSE)
  }
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = FALSE)
  artifact_dir <- file.path(output_dir, artifact_directory)
  screenshot_dir <- file.path(artifact_dir, "screenshots")
  table_dir <- file.path(artifact_dir, "tables")

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(screenshot_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

  structure(
    list(
      project_id = project_id,
      project_name = project_name,
      output_dir = output_dir,
      artifact_directory = artifact_dir,
      screenshot_directory = screenshot_dir,
      table_directory = table_dir,
      collector_docx = file.path(output_dir, collector_docx),
      manifest_file = file.path(output_dir, "Project_Artifact_Collector_manifest.csv"),
      render_target = render_target,
      bundles = list(),
      appended_bundle_ids = character(),
      created_at = Sys.time(),
      updated_at = Sys.time()
    ),
    class = c("project_artifact_collector", "list")
  )
}

.project_collector_slug <- function(value) {
  slug <- tolower(as.character(value %||% "artifact"))
  slug <- gsub("[^a-z0-9]+", "_", slug)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) "artifact" else slug
}

.project_collector_screenshot_helper <- function() {
  "AutoQuant::ObjectToPNG"
}

.project_collector_close_screenshot_browser <- function() {
  if (!requireNamespace("chromote", quietly = TRUE)) {
    return(invisible(FALSE))
  }
  has_default <- get("has_default_chromote_object", envir = asNamespace("chromote"))
  if (!isTRUE(tryCatch(has_default(), error = function(e) FALSE))) {
    return(invisible(FALSE))
  }
  browser <- tryCatch(chromote::default_chromote_object(), error = function(e) NULL)
  if (is.null(browser)) {
    return(invisible(FALSE))
  }
  tryCatch(browser$close(wait = 2), error = function(e) NULL)
  invisible(TRUE)
}

.project_collector_capture_plot <- function(artifact, output_file, width = 1400, height = 900) {
  if (!requireNamespace("AutoQuant", quietly = TRUE) ||
      !"ObjectToPNG" %in% getNamespaceExports("AutoQuant")) {
    stop("Production screenshot helper AutoQuant::ObjectToPNG is not available.", call. = FALSE)
  }
  if (is.null(artifact$object)) {
    stop("Plot artifact has no object to screenshot.", call. = FALSE)
  }
  if (file.exists(output_file)) {
    unlink(output_file)
  }
  result <- AutoQuant::ObjectToPNG(
    object = artifact$object,
    file = output_file,
    width = width,
    height = height,
    dpi = 150,
    background = "white",
    overwrite = TRUE,
    delay = 0.2
  )
  if (!file.exists(output_file) || file.info(output_file)$size <= 0) {
    stop("Production screenshot helper did not create a PNG file.", call. = FALSE)
  }
  screenshot <- normalizePath(output_file, winslash = "/", mustWork = TRUE)
  attr(screenshot, "html_path") <- attr(result, "html_path") %||% NA_character_
  attr(screenshot, "selfcontained") <- attr(result, "selfcontained") %||% NA
  screenshot
}

.project_collector_table_text <- function(data, max_rows = 12L, max_cols = 8L) {
  if (is.null(data)) {
    return("No table data.")
  }
  data <- data.table::as.data.table(data)
  shown <- utils::head(data[, seq_len(min(ncol(data), max_cols)), with = FALSE], max_rows)
  paste(capture.output(print(shown)), collapse = "\n")
}

.project_collector_table_backing_index <- function(collector) {
  table_entries <- list()
  rows <- list()
  warnings <- character()

  for (bundle in collector$bundles) {
    artifacts <- bundle$artifacts %||% list()
    for (artifact in artifacts) {
      if (!artifact$artifact_type %in% c("table", "metric")) {
        next
      }
      table_stem <- .project_collector_slug(paste(bundle$run_id, bundle$module_id, artifact$artifact_id, sep = "_"))
      backing <- tryCatch(
        table_artifact_persist_backing_data(
          artifact = artifact,
          output_dir = collector$table_directory %||% file.path(collector$artifact_directory, "tables"),
          render_target = collector$render_target %||% "llm_docx",
          file_stem = table_stem
        ),
        error = function(e) e
      )
      if (inherits(backing, "error")) {
        backing <- list(
          csv_available = FALSE,
          json_available = FALSE,
          csv_path = NA_character_,
          json_path = NA_character_,
          errors = paste("Table backing write failed:", conditionMessage(backing))
        )
      }
      if (length(backing$errors %||% character())) {
        warnings <- c(warnings, paste(artifact$artifact_id, paste(backing$errors, collapse = " | "), sep = ": "))
      }
      representation <- table_artifact_representation(
        artifact,
        render_target = collector$render_target %||% "llm_docx",
        backing = backing
      )
      table_entries[[artifact$artifact_id]] <- backing
      rows[[length(rows) + 1L]] <- data.table::data.table(
        project_id = collector$project_id,
        run_id = bundle$run_id,
        module_id = bundle$module_id,
        artifact_id = artifact$artifact_id,
        table_id = representation$metadata$table_id,
        table_type = representation$metadata$table_type,
        table_intent = representation$metadata$table_intent,
        rows = representation$metadata$rows,
        columns = representation$metadata$columns,
        default_sort = representation$metadata$default_sort$label,
        alternate_sorts = paste(vapply(representation$metadata$alternate_sorts, function(sort) sort$label, character(1)), collapse = " | "),
        preview_strategy = representation$metadata$preview_strategy,
        preview_row_count = representation$metadata$preview_row_count,
        truncated = representation$metadata$truncated,
        csv_available = representation$metadata$csv_available,
        json_available = representation$metadata$json_available,
        csv_path = representation$metadata$csv_path,
        json_path = representation$metadata$json_path,
        render_target = representation$metadata$render_target
      )
    }
  }

  table_index <- if (length(rows)) {
    data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
  } else {
    data.table::data.table(
      project_id = character(),
      run_id = character(),
      module_id = character(),
      artifact_id = character(),
      table_id = character(),
      table_type = character(),
      table_intent = character(),
      rows = integer(),
      columns = integer(),
      default_sort = character(),
      alternate_sorts = character(),
      preview_strategy = character(),
      preview_row_count = integer(),
      truncated = logical(),
      csv_available = logical(),
      json_available = logical(),
      csv_path = character(),
      json_path = character(),
      render_target = character()
    )
  }

  list(entries = table_entries, index = table_index, warnings = warnings)
}

.project_collector_table_docx_lines <- function(artifact, collector, table_backing = list()) {
  representation <- table_artifact_representation(
    artifact,
    render_target = collector$render_target %||% "llm_docx",
    backing = table_backing
  )
  metadata <- representation$metadata
  lines <- c(
    paste("table_summary:", representation$summary),
    paste("table_rows:", metadata$rows),
    paste("table_columns:", metadata$columns),
    paste("default_sort:", metadata$default_sort$label),
    paste("alternate_sorts:", paste(vapply(metadata$alternate_sorts, function(sort) sort$label, character(1)), collapse = " | ")),
    paste("preview_strategy:", metadata$preview_strategy),
    paste("preview_row_count:", metadata$preview_row_count),
    paste("truncated:", metadata$truncated),
    paste("csv_available:", metadata$csv_available),
    paste("csv_path:", metadata$csv_path),
    paste("json_available:", metadata$json_available),
    paste("json_path:", metadata$json_path)
  )
  preview_lines <- unlist(lapply(representation$previews, function(preview) {
    c(
      paste("preview:", preview$label),
      paste("preview_sort_status:", preview$sort_status),
      paste("preview_sort_reason:", preview$sort_reason),
      .project_collector_table_text(preview$data, max_rows = nrow(preview$data), max_cols = 8L)
    )
  }), use.names = FALSE)
  c(lines, preview_lines)
}

.project_collector_quality_index <- function(collector, screenshot_index = list(), table_entries = list()) {
  rows <- lapply(collector$bundles, function(bundle) {
    artifacts <- bundle$artifacts %||% list()
    if (!length(artifacts)) {
      return(NULL)
    }
    summary <- artifact_quality_summary(
      artifacts,
      render_target = collector$render_target %||% "llm_docx",
      screenshot_index = screenshot_index,
      table_index = table_entries
    )
    if (!nrow(summary)) {
      return(NULL)
    }
    summary[, `:=`(
      project_id = collector$project_id,
      run_id = bundle$run_id,
      module_id = bundle$module_id
    )]
    summary
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) {
    return(data.table::data.table(
      project_id = character(),
      run_id = character(),
      module_id = character(),
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
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

.project_collector_xml_escape <- function(x) {
  x <- as.character(x %||% "")
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

.project_collector_docx_paragraph <- function(text, style = NULL) {
  style_xml <- if (is.null(style)) "" else paste0('<w:pPr><w:pStyle w:val="', style, '"/></w:pPr>')
  paste0("<w:p>", style_xml, "<w:r><w:t xml:space=\"preserve\">", .project_collector_xml_escape(text), "</w:t></w:r></w:p>")
}

.project_collector_docx_image <- function(rel_id, width_px = 1400, height_px = 900) {
  width_in <- min(round(width_px / 180, 2), 6.8)
  height_in <- min(round(height_px / 180, 2), 8.8)
  paste0(
    '<w:p><w:r><w:pict><v:shape type="#_x0000_t75" style="width:', width_in, 'in;height:', height_in, 'in">',
    '<v:imagedata r:id="', rel_id, '" o:title="artifact"/>',
    "</v:shape></w:pict></w:r></w:p>"
  )
}

.project_collector_artifact_width <- function(artifact) {
  as.integer(artifact$metadata$requested_width %||% artifact$metadata$png_width %||% artifact$config$width %||% 1400L)
}

.project_collector_artifact_height <- function(artifact) {
  as.integer(artifact$metadata$requested_height %||% artifact$metadata$png_height %||% artifact$config$height %||% 900L)
}

project_collector_manifest <- function(collector) {
  rows <- lapply(collector$bundles, function(bundle) {
    statuses <- bundle$status %||% "error"
    data.table::data.table(
      project_id = bundle$project_id %||% collector$project_id,
      project_name = bundle$project_name %||% collector$project_name,
      run_id = bundle$run_id %||% NA_character_,
      timestamp = as.character(bundle$created_at %||% Sys.time()),
      module = bundle$module_id %||% NA_character_,
      status = statuses,
      artifacts_added = length(bundle$artifacts %||% list()),
      warnings = paste(bundle$warnings %||% character(), collapse = " | "),
      errors = paste(bundle$errors %||% character(), collapse = " | "),
      render_target = collector$render_target %||% "llm_docx",
      collector_docx = normalizePath(collector$collector_docx, winslash = "/", mustWork = FALSE),
      artifact_directory = normalizePath(collector$artifact_directory, winslash = "/", mustWork = FALSE)
    )
  })

  if (!length(rows)) {
    return(data.table::data.table(
      project_id = character(),
      project_name = character(),
      run_id = character(),
      timestamp = character(),
      module = character(),
      status = character(),
      artifacts_added = integer(),
      warnings = character(),
      errors = character(),
      render_target = character(),
      collector_docx = character(),
      artifact_directory = character()
    ))
  }

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

.project_collector_write_docx <- function(collector, screenshot_index, table_entries = list()) {
  output_path <- collector$collector_docx
  docx_root <- tempfile("project_collector_docx_")
  dir.create(file.path(docx_root, "_rels"), recursive = TRUE)
  dir.create(file.path(docx_root, "word", "_rels"), recursive = TRUE)
  dir.create(file.path(docx_root, "word", "media"), recursive = TRUE)

  body <- c(
    .project_collector_docx_paragraph("Project Artifact Collector", "Title"),
    .project_collector_docx_paragraph(paste("project_id:", collector$project_id)),
    .project_collector_docx_paragraph(paste("project_name:", collector$project_name)),
    .project_collector_docx_paragraph(paste("render_target:", collector$render_target %||% "llm_docx")),
    .project_collector_docx_paragraph("LLM interpretation purpose", "Heading1"),
    .project_collector_docx_paragraph("This document aggregates standardized project artifacts into a compact visual and metadata corpus. It is optimized for LLM interpretation of the modeling landscape without dumping raw data."),
    .project_collector_docx_paragraph("The collector preserves module boundaries, run IDs, artifact types, screenshots, table previews, narratives, diagnostics, recommendations, and metadata. Optional or skipped modules are expected and do not indicate collector failure."),
    .project_collector_docx_paragraph("Use screenshots as dense visual summaries and metadata as grounding context. Crowded labels are acceptable when the overall pattern remains recoverable.")
  )

  rels <- character()
  rel_index <- 1L
  runs <- unique(vapply(collector$bundles, function(bundle) bundle$run_id, character(1)))
  for (run_id in runs) {
    body <- c(body, .project_collector_docx_paragraph(paste("Run", run_id), "Heading1"))
    run_bundles <- collector$bundles[vapply(collector$bundles, function(bundle) identical(bundle$run_id, run_id), logical(1))]

    for (bundle in run_bundles) {
      body <- c(
        body,
        .project_collector_docx_paragraph(bundle$module_label %||% bundle$module_id, "Heading2"),
        .project_collector_docx_paragraph(paste("module_id:", bundle$module_id)),
        .project_collector_docx_paragraph(paste("module_status:", bundle$status)),
        .project_collector_docx_paragraph(paste("artifacts_added:", length(bundle$artifacts %||% list())))
      )

      if (bundle$status %in% c("skipped", "not_requested", "empty")) {
        body <- c(body, .project_collector_docx_paragraph(paste("Expected empty/skipped module:", bundle$status)))
        next
      }

      artifacts <- bundle$artifacts %||% list()
      if (!length(artifacts)) {
        body <- c(body, .project_collector_docx_paragraph("No artifacts generated."))
        next
      }

      artifact_order <- order(vapply(artifacts, function(artifact) artifact$order %||% Inf, numeric(1)), names(artifacts))
      for (artifact in artifacts[artifact_order]) {
        quality <- assess_artifact_quality(
          artifact = artifact,
          render_target = collector$render_target %||% "llm_docx",
          screenshot = screenshot_index[[artifact$artifact_id]]
        )
        body <- c(
          body,
          .project_collector_docx_paragraph(artifact$label %||% artifact$artifact_id, "Heading3"),
          .project_collector_docx_paragraph(paste("caption:", quality$caption)),
          .project_collector_docx_paragraph(paste("artifact_completeness:", paste0(quality$artifact_completeness, "%"))),
          .project_collector_docx_paragraph(paste("quality_severity:", quality$severity)),
          .project_collector_docx_paragraph(paste("missing_required_components:", paste(quality$missing_required_components, collapse = ", "))),
          .project_collector_docx_paragraph(paste("artifact_id:", artifact$artifact_id)),
          .project_collector_docx_paragraph(paste("artifact_type:", artifact$artifact_type)),
          .project_collector_docx_paragraph(paste("section:", artifact$section)),
          .project_collector_docx_paragraph(paste("source_module:", artifact$source_module)),
          .project_collector_docx_paragraph(paste("order:", artifact$order %||% NA_integer_))
        )

        if (identical(artifact$artifact_type, "plot")) {
          screenshot <- screenshot_index[[artifact$artifact_id]]
          if (is.null(screenshot) ||
              is.null(screenshot$file) ||
              !nzchar(as.character(screenshot$file)) ||
              !file.exists(screenshot$file)) {
            screenshot_status <- if (is.null(screenshot)) "missing" else screenshot$status %||% "missing"
            body <- c(body, .project_collector_docx_paragraph(paste("screenshot_status:", screenshot_status)))
          } else {
            image_name <- paste0(.project_collector_slug(artifact$artifact_id), ".png")
            file.copy(screenshot$file, file.path(docx_root, "word", "media", image_name), overwrite = TRUE)
            rel_id <- paste0("rId", rel_index)
            rel_index <- rel_index + 1L
            rels <- c(rels, paste0('<Relationship Id="', rel_id, '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/', image_name, '"/>'))
            body <- c(
              body,
              .project_collector_docx_image(rel_id, screenshot$width, screenshot$height),
              .project_collector_docx_paragraph(paste("screenshot_helper:", screenshot$helper)),
              .project_collector_docx_paragraph(paste("screenshot_status:", screenshot$status)),
              .project_collector_docx_paragraph(paste("screenshot_render_target:", screenshot$render_target)),
              .project_collector_docx_paragraph(paste("screenshot_file:", screenshot$file))
            )
          }
        } else if (artifact$artifact_type %in% c("table", "metric")) {
          table_lines <- .project_collector_table_docx_lines(
            artifact,
            collector,
            table_backing = table_entries[[artifact$artifact_id]] %||% list()
          )
          body <- c(body, vapply(table_lines, .project_collector_docx_paragraph, character(1)))
        } else if (artifact$artifact_type %in% c("text", "genai_narrative", "narrative", "diagnostic", "recommendation")) {
          body <- c(body, .project_collector_docx_paragraph(artifact$content %||% "No text content."))
        } else if (identical(artifact$artifact_type, "json")) {
          json_text <- if (is.null(artifact$content)) {
            paste(utils::capture.output(str(artifact$object %||% artifact$metadata %||% list())), collapse = "\n")
          } else {
            artifact$content
          }
          body <- c(body, .project_collector_docx_paragraph(json_text))
        } else {
          body <- c(body, .project_collector_docx_paragraph(paste("Payload retained as metadata for artifact type:", artifact$artifact_type)))
        }

        metadata_names <- names(artifact$metadata %||% list())
        if (length(metadata_names)) {
          compact_metadata <- paste(
            vapply(metadata_names, function(name) {
              value <- artifact$metadata[[name]]
              if (is.list(value)) {
                value <- paste(names(value), collapse = ",")
              }
              paste0(name, "=", paste(as.character(value), collapse = ","))
            }, character(1)),
            collapse = " | "
          )
          body <- c(body, .project_collector_docx_paragraph(paste("metadata:", compact_metadata)))
        }
      }
    }
  }

  writeLines('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>', file.path(docx_root, "[Content_Types].xml"), useBytes = TRUE)
  writeLines('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId0" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>', file.path(docx_root, "_rels", ".rels"), useBytes = TRUE)
  writeLines(paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">', paste(rels, collapse = ""), "</Relationships>"), file.path(docx_root, "word", "_rels", "document.xml.rels"), useBytes = TRUE)
  document_xml <- paste0(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"><w:body>',
    paste(body, collapse = ""),
    '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/></w:sectPr></w:body></w:document>'
  )
  writeLines(document_xml, file.path(docx_root, "word", "document.xml"), useBytes = TRUE)

  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(docx_root)
  if (file.exists(output_path)) {
    unlink(output_path)
    if (file.exists(output_path)) {
      stop("Could not replace existing collector DOCX. Close the file and rerun.", call. = FALSE)
    }
  }
  zip_result <- utils::zip(zipfile = output_path, files = list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE), flags = "-r9Xq")
  if (!identical(zip_result, 0L) || !file.exists(output_path)) {
    stop("Collector DOCX zip creation failed.", call. = FALSE)
  }
  normalizePath(output_path, winslash = "/", mustWork = TRUE)
}

project_collector_write <- function(collector) {
  if (!inherits(collector, "project_artifact_collector")) {
    return(service_result(status = "error", errors = "collector must inherit from project_artifact_collector."))
  }

  old_options <- options(
    chromote.headless = "new",
    webshot.quiet = TRUE,
    webshot.concurrent = 1L
  )
  on.exit(options(old_options), add = TRUE)
  on.exit(.project_collector_close_screenshot_browser(), add = TRUE)

  screenshot_index <- list()
  warnings <- character()
  errors <- character()

  for (bundle in collector$bundles) {
    artifacts <- bundle$artifacts %||% list()
    for (artifact in artifacts) {
      if (!identical(artifact$artifact_type, "plot")) {
        next
      }
      width <- .project_collector_artifact_width(artifact)
      height <- .project_collector_artifact_height(artifact)
      screenshot_stem <- .project_collector_slug(paste(bundle$run_id, bundle$module_id, artifact$artifact_id, sep = "_"))
      file <- file.path(collector$screenshot_directory, paste0(screenshot_stem, ".png"))
      capture <- tryCatch(
        .project_collector_capture_plot(artifact, file, width = width, height = height),
        error = function(e) e
      )
      if (inherits(capture, "error")) {
        warnings <- c(warnings, paste("Screenshot failed for", artifact$artifact_id, ":", conditionMessage(capture)))
        screenshot_index[[artifact$artifact_id]] <- list(
          status = "error",
          error = conditionMessage(capture),
          helper = .project_collector_screenshot_helper(),
          render_target = collector$render_target %||% "llm_docx",
          width = width,
          height = height
        )
      } else {
        screenshot_index[[artifact$artifact_id]] <- list(
          status = "success",
          file = capture,
          helper = .project_collector_screenshot_helper(),
          render_target = collector$render_target %||% "llm_docx",
          html_path = attr(capture, "html_path") %||% NA_character_,
          selfcontained = attr(capture, "selfcontained") %||% NA,
          width = width,
          height = height
        )
      }
    }
  }

  table_backing <- .project_collector_table_backing_index(collector)
  warnings <- c(warnings, table_backing$warnings)
  quality_index <- .project_collector_quality_index(collector, screenshot_index, table_backing$entries)
  docx_result <- tryCatch(.project_collector_write_docx(collector, screenshot_index, table_backing$entries), error = function(e) e)
  if (inherits(docx_result, "error")) {
    errors <- c(errors, paste("DOCX write failed:", conditionMessage(docx_result)))
  }

  manifest <- project_collector_manifest(collector)
  data.table::fwrite(manifest, collector$manifest_file)

  if (length(errors)) {
    return(service_result(
      status = "error",
      warnings = warnings,
      errors = errors,
      metadata = list(
        collector_docx = normalizePath(collector$collector_docx, winslash = "/", mustWork = FALSE),
        manifest_file = normalizePath(collector$manifest_file, winslash = "/", mustWork = FALSE),
        artifact_directory = normalizePath(collector$artifact_directory, winslash = "/", mustWork = FALSE),
        screenshot_index = screenshot_index,
        table_index = table_backing$index,
        quality_index = quality_index
      )
    ))
  }

  service_result(
    status = "success",
    messages = "Project Artifact Collector was written successfully.",
    warnings = warnings,
    metadata = list(
      collector_docx = normalizePath(collector$collector_docx, winslash = "/", mustWork = TRUE),
      manifest_file = normalizePath(collector$manifest_file, winslash = "/", mustWork = TRUE),
      artifact_directory = normalizePath(collector$artifact_directory, winslash = "/", mustWork = TRUE),
      screenshot_index = screenshot_index,
      table_index = table_backing$index,
      quality_index = quality_index
    )
  )
}

project_collector_append_bundle <- function(collector, bundle, write = TRUE) {
  if (!inherits(collector, "project_artifact_collector")) {
    return(service_result(status = "error", errors = "collector must inherit from project_artifact_collector."))
  }

  validation <- validate_project_artifact_bundle(bundle)
  if (identical(validation$status, "error")) {
    return(validation)
  }

  if (bundle$bundle_id %in% collector$appended_bundle_ids) {
    return(service_result(
      status = "warning",
      value = collector,
      warnings = paste("Bundle was already appended and was skipped:", bundle$bundle_id),
      metadata = list(duplicate_bundle_id = bundle$bundle_id)
    ))
  }

  collector$bundles[[bundle$bundle_id]] <- bundle
  collector$appended_bundle_ids <- c(collector$appended_bundle_ids, bundle$bundle_id)
  collector$updated_at <- Sys.time()

  if (!isTRUE(write)) {
    return(service_result(status = "success", value = collector, messages = paste("Appended bundle:", bundle$bundle_id)))
  }

  write_result <- project_collector_write(collector)
  write_result$value <- collector
  write_result
}

project_collector_append_result <- function(
  collector,
  result,
  project_id = collector$project_id,
  project_name = collector$project_name,
  run_id = NULL,
  module_id = NULL,
  module_label = NULL,
  write = TRUE
) {
  bundle <- project_artifact_bundle_from_result(
    result = result,
    project_id = project_id,
    project_name = project_name,
    run_id = run_id,
    module_id = module_id,
    module_label = module_label
  )
  project_collector_append_bundle(collector, bundle, write = write)
}

project_collector_docx_integrity <- function(path) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  tmp <- tempfile("collector_docx_check_")
  dir.create(tmp)
  on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)
  zip_path <- file.path(tmp, "collector.zip")
  file.copy(path, zip_path, overwrite = TRUE)
  ok <- tryCatch({
    utils::unzip(zip_path, exdir = tmp)
    file.exists(file.path(tmp, "word", "document.xml")) &&
      file.exists(file.path(tmp, "[Content_Types].xml"))
  }, error = function(e) FALSE)
  isTRUE(ok)
}

qa_project_artifact_collector <- function(output_dir = file.path(tempdir(), "project_artifact_collector_qa")) {
  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  collector <- create_project_artifact_collector(
    project_id = "qa_project",
    project_name = "QA Project",
    output_dir = output_dir
  )

  data <- data.table::data.table(category = paste0("Cat ", 1:5), value = c(4, 8, 6, 10, 9))
  plot <- AutoPlots::Bar(dt = data, XVar = "category", YVar = "value", title.text = "QA Bar")
  plot_artifact <- create_artifact(
    artifact_id = "qa_plot",
    artifact_type = "plot",
    label = "QA Bar Plot",
    source_module = "qa_module_a",
    object = plot,
    metadata = list(requested_width = 760L, requested_height = 480L),
    section = "QA Plots",
    order = 1L
  )
  table_artifact <- create_artifact(
    artifact_id = "qa_table",
    artifact_type = "table",
    label = "QA Table",
    source_module = "qa_module_a",
    object = data,
    section = "QA Tables",
    order = 2L
  )
  text_artifact <- create_artifact(
    artifact_id = "qa_text",
    artifact_type = "text",
    label = "QA Narrative",
    source_module = "qa_module_b",
    content = "The QA project artifact collector captured a narrative artifact.",
    section = "QA Narrative",
    order = 1L
  )

  bundle_a <- project_artifact_bundle(
    project_id = "qa_project",
    project_name = "QA Project",
    run_id = "run_001",
    module_id = "qa_module_a",
    module_label = "QA Module A",
    artifacts = list(qa_plot = plot_artifact, qa_table = table_artifact),
    status = "success"
  )
  bundle_b <- project_artifact_bundle(
    project_id = "qa_project",
    project_name = "QA Project",
    run_id = "run_001",
    module_id = "qa_module_b",
    module_label = "QA Module B",
    artifacts = list(qa_text = text_artifact),
    status = "success"
  )
  skipped_bundle <- project_artifact_bundle(
    project_id = "qa_project",
    project_name = "QA Project",
    run_id = "run_001",
    module_id = "qa_skipped",
    module_label = "QA Skipped Module",
    artifacts = list(),
    status = "skipped",
    warnings = "Module not requested."
  )
  failed_bundle <- project_artifact_bundle(
    project_id = "qa_project",
    project_name = "QA Project",
    run_id = "run_002",
    module_id = "qa_failed",
    module_label = "QA Failed Module",
    artifacts = list(),
    status = "error",
    errors = "Artifact generation failed upstream."
  )

  append_a <- project_collector_append_bundle(collector, bundle_a, write = FALSE)
  collector <- append_a$value
  append_b <- project_collector_append_bundle(collector, bundle_b, write = FALSE)
  collector <- append_b$value
  append_skipped <- project_collector_append_bundle(collector, skipped_bundle, write = FALSE)
  collector <- append_skipped$value
  append_failed <- project_collector_append_bundle(collector, failed_bundle, write = FALSE)
  collector <- append_failed$value
  workflow_result <- service_result(
    status = "success",
    artifacts = list(qa_text = text_artifact),
    metadata = list(
      module_id = "qa_workflow_module",
      module_run_id = "qa_workflow_run"
    )
  )
  append_workflow <- project_collector_append_result(
    collector,
    workflow_result,
    run_id = "run_003",
    module_id = "qa_workflow_module",
    module_label = "QA Workflow Module",
    write = FALSE
  )
  collector <- append_workflow$value
  duplicate <- project_collector_append_bundle(collector, bundle_a, write = FALSE)
  write_result <- project_collector_write(collector)
  manifest <- if (file.exists(collector$manifest_file)) data.table::fread(collector$manifest_file) else data.table::data.table()
  screenshot_index <- write_result$metadata$screenshot_index %||% list()
  screenshot_ok <- length(screenshot_index) &&
    identical(screenshot_index$qa_plot$status, "success") &&
    file.exists(screenshot_index$qa_plot$file)

  corrupted <- validate_project_artifact_bundle(list(project_id = "bad"))

  data.table::data.table(
    check = c(
      "collector_creation",
      "append_behavior",
      "multiple_module_appends",
      "skipped_module",
      "failed_module_recorded",
      "ordering",
      "manifest_generation",
      "duplicate_append_protection",
      "screenshot_validation",
      "docx_integrity",
      "backward_compatibility_aq_artifact",
      "corrupted_bundle_validation",
      "workflow_service_result_append",
      "persistent_project_runs"
    ),
    status = c(
      if (inherits(collector, "project_artifact_collector")) "success" else "error",
      append_a$status,
      if (length(collector$bundles) == 5L) "success" else "error",
      if ("qa_skipped" %in% manifest$module && manifest[module == "qa_skipped"]$status == "skipped") "success" else "error",
      if ("qa_failed" %in% manifest$module && manifest[module == "qa_failed"]$status == "error") "success" else "error",
      if (identical(names(collector$bundles), collector$appended_bundle_ids)) "success" else "error",
      if (nrow(manifest) == 5L && file.exists(collector$manifest_file)) "success" else "error",
      if (identical(duplicate$status, "warning")) "success" else "error",
      if (screenshot_ok && identical(screenshot_index$qa_plot$helper, "AutoQuant::ObjectToPNG")) "success" else "error",
      if (identical(write_result$status, "success") && project_collector_docx_integrity(collector$collector_docx)) "success" else "error",
      if (all(vapply(bundle_a$artifacts, function(artifact) inherits(artifact, "aq_artifact"), logical(1)))) "success" else "error",
      if (identical(corrupted$status, "error")) "success" else "error",
      if (identical(append_workflow$status, "success") && "qa_workflow_module" %in% manifest$module) "success" else "error",
      if (identical(sort(unique(manifest$run_id)), c("run_001", "run_002", "run_003"))) "success" else "error"
    ),
    message = c(
      paste("Collector:", collector$project_id),
      paste("Append result:", append_a$status),
      paste("Bundles:", length(collector$bundles)),
      "Skipped module is represented in manifest without collector failure.",
      "Failed module is represented in manifest for reconstruction.",
      "Bundle append order is retained.",
      paste("Manifest rows:", nrow(manifest)),
      paste("Duplicate result:", duplicate$status),
      paste("Screenshot helper:", screenshot_index$qa_plot$helper %||% NA_character_),
      paste("DOCX:", collector$collector_docx),
      "Existing aq_artifact objects are accepted as collector payloads.",
      "Invalid bundle is rejected.",
      "Module service_result objects append through the workflow-facing collector path.",
      paste("Runs:", paste(sort(unique(manifest$run_id)), collapse = ", "))
    )
  )
}
