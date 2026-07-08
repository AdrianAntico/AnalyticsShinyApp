plot_sizing_gallery_specs <- function() {
  c(
    .plot_sizing_bar_specs(),
    .plot_sizing_variable_importance_specs(),
    .plot_sizing_heatmap_specs(),
    .plot_sizing_corr_specs(),
    .plot_sizing_scatter_specs(),
    .plot_sizing_box_specs(),
    .plot_sizing_line_area_specs(),
    .plot_sizing_shap_specs()
  )
}

.plot_sizing_case <- function(
  case_id,
  title,
  plot_type,
  data,
  widget_args,
  renderer_function = NULL,
  categories = NA_integer_,
  requested_width = 760L,
  requested_height = 440L,
  notes = NULL,
  unsupported_reason = NULL
) {
  labels <- .plot_sizing_labels(data)
  renderer_function <- renderer_function %||% paste0("AutoPlots::", plot_type)
  list(
    case_id = case_id,
    title = title,
    plot_type = plot_type,
    data = data,
    widget_args = widget_args,
    renderer_function = renderer_function,
    unsupported_reason = unsupported_reason,
    metadata = list(
      plot_type = plot_type,
      rows = nrow(data),
      columns = ncol(data),
      categories = as.integer(categories %||% length(unique(labels))),
      max_label_length = if (length(labels)) max(nchar(as.character(labels))) else 0L,
      x_axis_label_rotate = widget_args[["xAxis.axisLabel.rotate"]] %||% NA_integer_,
      x_axis_label_font_size = widget_args[["xAxis.axisLabel.fontSize"]] %||% NA_integer_,
      y_axis_label_font_size = widget_args[["yAxis.axisLabel.fontSize"]] %||% NA_integer_,
      requested_width = as.integer(requested_width),
      requested_height = as.integer(requested_height),
      aspect_ratio = round(as.numeric(requested_width) / as.numeric(requested_height), 3)
    ),
    notes = notes
  )
}

.plot_sizing_labels <- function(data) {
  label_cols <- intersect(c("category", "Feature", "feature", "x_cat", "y_cat", "group"), names(data))
  unique(unlist(data[, label_cols, with = FALSE], use.names = FALSE))
}

.plot_sizing_category_data <- function(n, long_labels = FALSE) {
  labels <- if (long_labels) {
    paste("Long category label", seq_len(n), "with extra descriptive text")
  } else {
    paste0("Cat ", seq_len(n))
  }
  data.table::data.table(
    category = factor(labels, levels = labels),
    value = round(100 + 35 * sin(seq_len(n) / 3) + seq_len(n) * 1.7, 1)
  )
}

.plot_sizing_bar_x_rotation <- function(n, max_label_length) {
  label_pressure <- n * max(1L, max_label_length)
  if (n >= 30L || max_label_length >= 20L || label_pressure >= 150L) {
    90L
  } else if (n >= 10L || max_label_length >= 8L || label_pressure >= 60L) {
    45L
  } else {
    0L
  }
}

.plot_sizing_x_label_font_size <- function(n, max_label_length) {
  label_pressure <- n * max(1L, max_label_length)
  if (n >= 60L || label_pressure >= 300L) {
    9L
  } else if (n >= 30L || label_pressure >= 150L) {
    10L
  } else if (n >= 15L || label_pressure >= 90L) {
    12L
  } else {
    14L
  }
}

.plot_sizing_y_label_font_size <- function(n, max_label_length) {
  label_pressure <- n * max(1L, max_label_length)
  if (n >= 60L || max_label_length >= 30L || label_pressure >= 1500L) {
    8L
  } else if (n >= 30L || max_label_length >= 20L || label_pressure >= 600L) {
    9L
  } else if (n >= 15L || max_label_length >= 12L || label_pressure >= 250L) {
    10L
  } else {
    12L
  }
}

.plot_sizing_vertical_bar_height <- function(n) {
  if (n >= 60L) {
    700L
  } else if (n >= 30L) {
    640L
  } else if (n >= 15L) {
    500L
  } else {
    420L
  }
}

.plot_sizing_flipped_bar_height <- function(n) {
  if (n >= 60L) {
    1100L
  } else if (n >= 30L) {
    820L
  } else if (n >= 15L) {
    620L
  } else {
    500L
  }
}

.plot_sizing_bar_specs <- function() {
  counts <- c(5L, 15L, 30L, 60L)
  specs <- list()
  for (n in counts) {
    data <- .plot_sizing_category_data(n, long_labels = FALSE)
    max_label_length <- max(nchar(as.character(data$category)))
    rotation <- .plot_sizing_bar_x_rotation(n, max_label_length)
    font_size <- .plot_sizing_x_label_font_size(n, max_label_length)
    specs[[length(specs) + 1L]] <- .plot_sizing_case(
      case_id = paste0("bar_vertical_", n, "_short"),
      title = paste("Bar vertical", n, "short labels"),
      plot_type = "Bar",
      data = data,
      widget_args = list(XVar = "category", YVar = "value", title.text = paste("Vertical Bar", n), xAxis.axisLabel.rotate = rotation, xAxis.axisLabel.fontSize = font_size),
      renderer_function = "AutoPlots::Bar",
      categories = n,
      requested_width = 760L,
      requested_height = .plot_sizing_vertical_bar_height(n),
      notes = paste0(
        "xAxis.axisLabel.rotate = ", rotation,
        ", xAxis.axisLabel.fontSize = ", font_size,
        " based on categories = ", n,
        " and max_label_length = ", max_label_length,
        if (n >= 60L) ". High-cardinality vertical bars remain a stress case; compare against the flipped bar case with larger height." else "."
      )
    )
  }
  for (n in counts) {
    raw_data <- .plot_sizing_category_data(n, long_labels = TRUE)
    max_label_length <- max(nchar(as.character(raw_data$category)))
    data <- data.table::data.table(
      Feature = factor(as.character(raw_data$category), levels = rev(as.character(raw_data$category))),
      Importance = raw_data$value
    )
    specs[[length(specs) + 1L]] <- .plot_sizing_case(
      case_id = paste0("bar_flipped_", n, "_long"),
      title = paste("Bar coordinate flipped", n, "long labels"),
      plot_type = "BarFlipped",
      data = data,
      widget_args = list(XVar = "Importance", YVar = "Feature", title.text = paste("Flipped Bar", n)),
      renderer_function = "AutoPlots::VariableImportance",
      categories = n,
      requested_width = 820L,
      requested_height = .plot_sizing_flipped_bar_height(n),
      notes = paste0(
        "Coordinate-flipped high-label bar uses AutoPlots::VariableImportance, the canonical AutoPlots wrapper that produces horizontal bars from Bar(). Inputs: categories = ", n,
        " and max_label_length = ", max_label_length,
        if (n >= 30L) "; high-cardinality cases also use additional height for static Word-style output." else "."
      )
    )
  }
  specs
}

.plot_sizing_variable_importance_specs <- function() {
  lapply(c(10L, 25L, 50L), function(n) {
    data <- data.table::data.table(
      Feature = factor(paste0("Feature_", sprintf("%02d", seq_len(n))), levels = rev(paste0("Feature_", sprintf("%02d", seq_len(n))))),
      Importance = round(sort(stats::runif(n, 0.01, 1), decreasing = TRUE), 3)
    )
    .plot_sizing_case(
      case_id = paste0("variable_importance_top_", n),
      title = paste("Variable Importance Top", n),
      plot_type = "VariableImportance",
      data = data,
      widget_args = list(XVar = "Importance", YVar = "Feature", title.text = paste("Variable Importance Top", n)),
      renderer_function = "AutoPlots::VariableImportance",
      categories = n,
      requested_width = 760L,
      requested_height = if (n >= 50L) 780L else if (n >= 25L) 600L else 420L
    )
  })
}

.plot_sizing_heatmap_specs <- function() {
  dims <- list(small = c(6L, 6L), medium = c(15L, 12L), large = c(30L, 24L))
  lapply(names(dims), function(size) {
    nx <- dims[[size]][[1L]]
    ny <- dims[[size]][[2L]]
    data <- data.table::CJ(x_cat = paste0("X", seq_len(nx)), y_cat = paste0("Y", seq_len(ny)))
    data[, z := round(sin(as.integer(factor(x_cat)) / 2) + cos(as.integer(factor(y_cat)) / 3), 3)]
    .plot_sizing_case(
      case_id = paste0("heatmap_", size),
      title = paste("Heatmap", size),
      plot_type = "HeatMap",
      data = data,
      widget_args = list(XVar = "x_cat", YVar = "y_cat", ZVar = "z", title.text = paste("Heatmap", size), xAxis.axisLabel.rotate = if (nx >= 15L) 45 else 0),
      renderer_function = "AutoPlots::HeatMap",
      categories = max(nx, ny),
      requested_width = if (identical(size, "large")) 900L else 760L,
      requested_height = if (identical(size, "large")) 720L else 520L
    )
  })
}

.plot_sizing_corr_specs <- function() {
  counts <- c(small = 6L, medium = 15L, large = 30L)
  lapply(names(counts), function(size) {
    n <- counts[[size]]
    data <- data.table::as.data.table(matrix(stats::rnorm(120L * n), nrow = 120L, ncol = n))
    names(data) <- paste0("Feature_", seq_len(n))
    .plot_sizing_case(
      case_id = paste0("corr_matrix_", size),
      title = paste("Correlation Matrix", size),
      plot_type = "CorrMatrix",
      data = data,
      widget_args = list(CorrVars = names(data), PreAgg = FALSE, title.text = paste("Correlation Matrix", size), ShowLabels = n <= 15L),
      renderer_function = "AutoPlots::CorrMatrix",
      categories = n,
      requested_width = if (n >= 30L) 900L else 760L,
      requested_height = if (n >= 30L) 760L else 580L
    )
  })
}

.plot_sizing_scatter_specs <- function() {
  list(
    .plot_sizing_scatter_case("scatter_sparse", "Scatter sparse", 120L, FALSE),
    .plot_sizing_scatter_case("scatter_dense", "Scatter dense", 6000L, FALSE),
    .plot_sizing_scatter_case("scatter_dense_transparency", "Scatter dense with transparency", 6000L, TRUE)
  )
}

.plot_sizing_scatter_case <- function(case_id, title, n, transparency) {
  data <- data.table::data.table(
    x = stats::rnorm(n),
    y = 0.6 * stats::rnorm(n) + stats::rnorm(n),
    group = sample(c("Segment A", "Segment B", "Segment C"), n, replace = TRUE)
  )
  .plot_sizing_case(
    case_id = case_id,
    title = title,
    plot_type = "Scatter",
    data = data,
    widget_args = list(XVar = "x", YVar = "y", GroupVar = "group", title.text = title),
    renderer_function = "AutoPlots::Scatter",
    categories = length(unique(data$group)),
    requested_width = 760L,
    requested_height = 480L,
    notes = if (transparency) "Transparency case exercises the production AutoPlots scatter widget at dense row counts." else NULL
  )
}

.plot_sizing_box_specs <- function() {
  lapply(c(few = 4L, many = 30L), function(n) {
    labels <- paste0("Group_", seq_len(n))
    data <- data.table::data.table(
      group = factor(rep(labels, each = 40L), levels = labels),
      value = stats::rnorm(n * 40L, rep(seq_len(n) / 6, each = 40L), 1)
    )
    .plot_sizing_case(
      case_id = paste0("box_", if (n <= 4L) "few" else "many", "_groups"),
      title = paste("Box Plot", n, "groups"),
      plot_type = "Box",
      data = data,
      widget_args = list(XVar = "group", YVar = "value", title.text = paste("Box Plot", n, "groups"), xAxis.axisLabel.rotate = if (n > 10L) 45 else 0),
      renderer_function = "AutoPlots::Box",
      categories = n,
      requested_width = if (n > 10L) 880L else 760L,
      requested_height = if (n > 10L) 620L else 440L
    )
  })
}

.plot_sizing_line_area_specs <- function() {
  short_dates <- seq.Date(as.Date("2026-01-01"), by = "day", length.out = 30L)
  long_dates <- seq.Date(as.Date("2023-01-01"), by = "week", length.out = 156L)
  grouped <- data.table::rbindlist(lapply(c("North", "South", "West"), function(group) {
    data.table::data.table(date = long_dates, value = cumsum(stats::rnorm(length(long_dates))) + match(group, c("North", "South", "West")) * 10, group = group)
  }))
  list(
    .plot_sizing_case("line_short_ungrouped", "Line short time span ungrouped", "Line", data.table::data.table(date = short_dates, value = cumsum(stats::rnorm(length(short_dates)))), list(XVar = "date", YVar = "value", title.text = "Line Short Time Span"), "AutoPlots::Line", NA_integer_, 760L, 430L),
    .plot_sizing_case("line_long_grouped", "Line long time span grouped", "Line", grouped, list(XVar = "date", YVar = "value", GroupVar = "group", title.text = "Line Long Grouped"), "AutoPlots::Line", 3L, 840L, 500L),
    .plot_sizing_case("area_short_ungrouped", "Area short time span ungrouped", "Area", data.table::data.table(date = short_dates, value = abs(cumsum(stats::rnorm(length(short_dates))))), list(XVar = "date", YVar = "value", title.text = "Area Short Time Span"), "AutoPlots::Area", NA_integer_, 760L, 430L),
    .plot_sizing_case("area_long_grouped", "Area long time span grouped", "Area", grouped[, .(date, value = abs(value), group)], list(XVar = "date", YVar = "value", GroupVar = "group", title.text = "Area Long Grouped"), "AutoPlots::Area", 3L, 840L, 500L)
  )
}

.plot_sizing_shap_specs <- function() {
  n <- 500L
  dependence <- data.table::data.table(feature_value = stats::rnorm(n), shap_value = stats::rnorm(n), segment = sample(c("Low", "Medium", "High"), n, TRUE))
  interaction <- data.table::CJ(feature_a_bin = paste0("A", 1:12), feature_b_bin = paste0("B", 1:10))
  interaction[, shap_interaction := round(stats::rnorm(.N), 3)]
  importance <- data.table::data.table(Feature = paste0("SHAP_Feature_", 1:25), Importance = sort(stats::runif(25), decreasing = TRUE))
  list(
    .plot_sizing_case("shap_dependence", "SHAP-style dependence", "Scatter", dependence, list(XVar = "feature_value", YVar = "shap_value", GroupVar = "segment", title.text = "SHAP Dependence"), "AutoPlots::Scatter", 3L, 760L, 480L),
    .plot_sizing_case("shap_interaction", "SHAP-style interaction", "HeatMap", interaction, list(XVar = "feature_a_bin", YVar = "feature_b_bin", ZVar = "shap_interaction", title.text = "SHAP Interaction"), "AutoPlots::HeatMap", 12L, 800L, 560L),
    .plot_sizing_case("shap_importance", "SHAP-style importance", "ShapImportance", importance, list(YVar = "Feature", title.text = "SHAP Importance"), "AutoPlots::ShapImportance", 25L, 760L, 600L)
  )
}

.plot_sizing_build_widget <- function(spec) {
  if (!is.null(spec$unsupported_reason)) {
    stop(spec$unsupported_reason, call. = FALSE)
  }
  args <- c(list(dt = spec$data, Height = spec$metadata$requested_height, Width = spec$metadata$requested_width), spec$widget_args)
  plot_fun <- getExportedValue("AutoPlots", sub("^AutoPlots::", "", spec$renderer_function))
  allowed_args <- names(formals(plot_fun))
  if (!"..." %in% allowed_args) {
    args <- args[names(args) %in% allowed_args]
  }
  do.call(plot_fun, args)
}

.plot_sizing_screenshot_function <- function() {
  "AutoQuant::ObjectToPNG"
}

.plot_sizing_capture_widget <- function(widget, png_path, width, height) {
  if (!requireNamespace("AutoQuant", quietly = TRUE) ||
      !"ObjectToPNG" %in% getNamespaceExports("AutoQuant")) {
    stop("Production screenshot helper AutoQuant::ObjectToPNG is not available.", call. = FALSE)
  }
  if (file.exists(png_path)) {
    unlink(png_path)
  }
  result <- AutoQuant::ObjectToPNG(
    object = widget,
    file = png_path,
    width = width,
    height = height,
    dpi = 150,
    background = "white",
    overwrite = TRUE,
    delay = 0.2
  )
  if (!file.exists(png_path) || file.info(png_path)$size <= 0) {
    stop("Production screenshot helper did not create a PNG file.", call. = FALSE)
  }
  png_file <- normalizePath(png_path, winslash = "/", mustWork = TRUE)
  attr(png_file, "html_path") <- attr(result, "html_path") %||% NA_character_
  attr(png_file, "selfcontained") <- attr(result, "selfcontained") %||% FALSE
  attr(png_file, "viewport_width") <- as.integer(width)
  attr(png_file, "viewport_height") <- as.integer(height)
  png_file
}

.plot_sizing_metadata_table <- function(metadata) {
  data.table::data.table(
    metric = names(metadata),
    value = vapply(metadata, as.character, character(1))
  )
}

.plot_sizing_metadata_html <- function(metadata) {
  rows <- lapply(names(metadata), function(name) {
    htmltools::tags$tr(htmltools::tags$th(name), htmltools::tags$td(as.character(metadata[[name]])))
  })
  do.call(htmltools::tags$table, c(list(class = "metadata"), rows))
}

.plot_sizing_write_html <- function(cases, output_path, asset_dir) {
  sections <- unname(lapply(cases, function(case) {
    widget_ui <- htmltools::tags$p(
      class = if (!is.null(case$widget)) "note" else "error",
      if (!is.null(case$widget)) "AutoPlots widget generation succeeded for this case." else paste("AutoPlots widget failed:", case$error %||% "unknown error")
    )
    htmltools::tags$section(
      class = "case",
      htmltools::tags$h2(case$title),
      htmltools::tags$p(class = "case-id", case$case_id),
      htmltools::tags$h3("Production AutoPlots build status"),
      widget_ui,
      htmltools::tags$h3("Production artifact screenshot"),
      if (!is.null(case$screenshot_file) && file.exists(case$screenshot_file)) {
        htmltools::tags$img(src = file.path(basename(asset_dir), basename(case$png_path)), style = "max-width: 100%; border: 1px solid #ddd;")
      } else {
        htmltools::tags$p(class = "error", paste("Production screenshot failed:", case$screenshot_error %||% "unknown error"))
      },
      htmltools::tags$h3("Metadata"),
      .plot_sizing_metadata_html(case$metadata),
      if (!is.null(case$notes)) htmltools::tags$p(class = "note", case$notes) else NULL
    )
  }))
  body_children <- c(list(
    htmltools::tags$h1("Plot Sizing QA Gallery"),
      htmltools::tags$p("Generated by qa_plot_sizing_gallery(). Every supported plot is built through its production AutoPlots function and captured through AutoQuant::ObjectToPNG, the same screenshot helper used by artifact generation."),
    htmltools::tags$div(
      class = "criteria",
      htmltools::tags$strong("Manual QA criteria"),
      htmltools::tags$ul(
        htmltools::tags$li("Are all axis labels visible?"),
        htmltools::tags$li("Are category labels truncated?"),
        htmltools::tags$li("Are legends clipped?"),
        htmltools::tags$li("Are titles readable?"),
        htmltools::tags$li("Are margins sufficient?"),
        htmltools::tags$li("Are heatmap cells distinguishable?"),
        htmltools::tags$li("Are tick labels overlapping?"),
        htmltools::tags$li("Does the aspect ratio feel appropriate?"),
        htmltools::tags$li("Are plots wasting excessive whitespace?")
      )
    )
  ), sections)
  body_children <- unname(body_children)
  page <- htmltools::tags$html(
    htmltools::tags$head(
      htmltools::tags$title("Plot Sizing QA Gallery"),
      htmltools::tags$style(htmltools::HTML("
        body { font-family: Segoe UI, Arial, sans-serif; margin: 32px; color: #222; }
        h1 { margin-bottom: 0; }
        .criteria { background: #f6f8fa; padding: 16px 20px; border-left: 4px solid #4C78A8; }
        .case { page-break-inside: avoid; border-top: 1px solid #ddd; padding-top: 24px; margin-top: 28px; }
        .case-id { color: #666; font-family: Consolas, monospace; }
        .metadata { border-collapse: collapse; margin-top: 8px; }
        .metadata th, .metadata td { border: 1px solid #ddd; padding: 4px 8px; text-align: left; }
        .metadata th { background: #f6f8fa; }
        .error { color: #a40000; white-space: pre-wrap; }
        .note { color: #555; font-style: italic; }
      "))
    ),
    do.call(htmltools::tags$body, body_children)
  )
  htmltools::save_html(page, file = output_path, libdir = paste0(tools::file_path_sans_ext(basename(output_path)), "_lib"))
  normalizePath(output_path, winslash = "/", mustWork = TRUE)
}

.plot_sizing_xml_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

.plot_sizing_docx_paragraph <- function(text, style = NULL) {
  style_xml <- if (is.null(style)) "" else paste0('<w:pPr><w:pStyle w:val="', style, '"/></w:pPr>')
  paste0("<w:p>", style_xml, "<w:r><w:t>", .plot_sizing_xml_escape(text), "</w:t></w:r></w:p>")
}

.plot_sizing_docx_image <- function(rel_id, width_px, height_px) {
  width_in <- round(width_px / 110, 2)
  height_in <- round(height_px / 110, 2)
  paste0(
    '<w:p><w:r><w:pict><v:shape type="#_x0000_t75" style="width:', width_in, 'in;height:', height_in, 'in">',
    '<v:imagedata r:id="', rel_id, '" o:title="plot"/>',
    "</v:shape></w:pict></w:r></w:p>"
  )
}

.plot_sizing_write_docx <- function(cases, output_path) {
  output_path <- file.path(normalizePath(dirname(output_path), winslash = "/", mustWork = TRUE), basename(output_path))
  docx_root <- tempfile("plot_sizing_docx_")
  dir.create(file.path(docx_root, "_rels"), recursive = TRUE)
  dir.create(file.path(docx_root, "word", "_rels"), recursive = TRUE)
  dir.create(file.path(docx_root, "word", "media"), recursive = TRUE)

  body <- c(
    .plot_sizing_docx_paragraph("Plot Sizing QA Gallery", "Title"),
    .plot_sizing_docx_paragraph("Generated by qa_plot_sizing_gallery(). PNG previews are screenshots produced through AutoQuant::ObjectToPNG, the production artifact screenshot helper."),
    .plot_sizing_docx_paragraph("LLM interpretation purpose", "Heading1"),
    .plot_sizing_docx_paragraph("This document is an artifact screenshot corpus, not a polished human report. Its purpose is to compress modeling context into dense visual evidence that an LLM can inspect with minimal raw-data/token burden."),
    .plot_sizing_docx_paragraph("Interpretation criteria: plots must not be blank; titles, plot type, axes, scales, legends, and primary visual patterns should be recoverable. Crowded or clipped labels are acceptable when the chart structure and enough category identity remain inferable."),
    .plot_sizing_docx_paragraph("Metadata contract: each artifact includes renderer, screenshot helper, row/column counts, category count, max label length, requested dimensions, aspect ratio, and axis-label sizing choices when applicable. These fields ground the visual image without dumping raw data."),
    .plot_sizing_docx_paragraph("Known stress cases: high category counts, long labels, dense heatmaps, large correlation matrices, and horizontal bars with long y-axis labels may be visually imperfect. These are retained because they reveal where static Word export sizing policy must improve.")
  )
  rels <- character()
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    if (is.null(case$screenshot_file) || !file.exists(case$screenshot_file)) {
      body <- c(
        body,
        .plot_sizing_docx_paragraph(case$title, "Heading1"),
        .plot_sizing_docx_paragraph(paste("Not Yet Supported:", case$unsupported_reason %||% case$screenshot_error %||% case$widget_error %||% "production screenshot unavailable"))
      )
      next
    }
    image_name <- paste0(case$case_id, ".png")
    file.copy(case$screenshot_file, file.path(docx_root, "word", "media", image_name), overwrite = TRUE)
    rel_id <- paste0("rId", i)
    rels <- c(rels, paste0('<Relationship Id="', rel_id, '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/', image_name, '"/>'))
    body <- c(
      body,
      .plot_sizing_docx_paragraph(case$title, "Heading1"),
      .plot_sizing_docx_image(rel_id, case$metadata$requested_width, case$metadata$requested_height),
      .plot_sizing_docx_paragraph(paste("renderer_function:", case$renderer_function)),
      .plot_sizing_docx_paragraph(paste("screenshot_function:", case$screenshot_function)),
      .plot_sizing_docx_paragraph(paste("plot_type:", case$metadata$plot_type)),
      .plot_sizing_docx_paragraph(paste("rows:", case$metadata$rows)),
      .plot_sizing_docx_paragraph(paste("columns:", case$metadata$columns)),
      .plot_sizing_docx_paragraph(paste("categories:", case$metadata$categories)),
      .plot_sizing_docx_paragraph(paste("max_label_length:", case$metadata$max_label_length)),
      .plot_sizing_docx_paragraph(paste("x_axis_label_rotate:", case$metadata$x_axis_label_rotate)),
      .plot_sizing_docx_paragraph(paste("x_axis_label_font_size:", case$metadata$x_axis_label_font_size)),
      .plot_sizing_docx_paragraph(paste("y_axis_label_font_size:", case$metadata$y_axis_label_font_size)),
      .plot_sizing_docx_paragraph(paste("requested_width:", case$metadata$requested_width)),
      .plot_sizing_docx_paragraph(paste("requested_height:", case$metadata$requested_height)),
      .plot_sizing_docx_paragraph(paste("aspect_ratio:", case$metadata$aspect_ratio)),
      if (!is.null(case$notes)) .plot_sizing_docx_paragraph(paste("notes:", case$notes)) else NULL
    )
  }

  writeLines('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>', file.path(docx_root, "[Content_Types].xml"), useBytes = TRUE)
  writeLines('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>', file.path(docx_root, "_rels", ".rels"), useBytes = TRUE)
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
      stop("Could not replace existing DOCX output file. Close the file and rerun qa_plot_sizing_gallery().", call. = FALSE)
    }
  }
  zip_result <- utils::zip(zipfile = output_path, files = list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE), flags = "-r9Xq")
  if (!identical(zip_result, 0L) || !file.exists(output_path)) {
    stop("DOCX gallery zip creation failed.", call. = FALSE)
  }
  normalizePath(output_path, winslash = "/", mustWork = TRUE)
}

qa_plot_sizing_gallery <- function(
  output_dir = file.path("docs"),
  html_file = "plot_sizing_gallery.html",
  docx_file = "plot_sizing_gallery.docx",
  seed = 42L
) {
  set.seed(seed)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  asset_dir <- file.path(output_dir, "plot_sizing_gallery_files")
  if (!dir.exists(asset_dir)) {
    dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)
  }
  old_widget_dir <- file.path(output_dir, "plot_sizing_gallery_widgets")
  if (dir.exists(old_widget_dir)) {
    unlink(old_widget_dir, recursive = TRUE, force = TRUE)
  }
  old_pngs <- list.files(asset_dir, pattern = "\\.png$", full.names = TRUE)
  if (length(old_pngs)) {
    unlink(old_pngs, force = TRUE)
  }

  specs <- plot_sizing_gallery_specs()
  cases <- lapply(specs, function(spec) {
    png_path <- file.path(asset_dir, paste0(spec$case_id, ".png"))
    widget <- tryCatch(.plot_sizing_build_widget(spec), error = function(e) {
      spec$error <<- conditionMessage(e)
      NULL
    })
    widget_error <- spec$error %||% NULL
    screenshot_error <- NULL
    screenshot_function <- .plot_sizing_screenshot_function()
    screenshot_selfcontained <- NA
    screenshot_html_path <- NA_character_
    screenshot_status <- "not_run"
    screenshot_file <- if (!is.null(widget)) {
      tryCatch(
        .plot_sizing_capture_widget(
          widget = widget,
          png_path = png_path,
          width = spec$metadata$requested_width,
          height = spec$metadata$requested_height
        ),
        error = function(e) {
          screenshot_error <<- conditionMessage(e)
          screenshot_status <<- "error"
          NULL
        }
      )
    } else {
      NULL
    }
    if (!is.null(screenshot_file)) {
      screenshot_selfcontained <- isTRUE(attr(screenshot_file, "selfcontained"))
      screenshot_html_path <- attr(screenshot_file, "html_path") %||% NA_character_
      screenshot_status <- "success"
    }
    spec$png_path <- png_path
    spec$widget <- widget
    spec$widget_error <- widget_error
    spec$screenshot_function <- screenshot_function
    spec$screenshot_selfcontained <- screenshot_selfcontained
    spec$screenshot_html_path <- screenshot_html_path
    spec$screenshot_status <- screenshot_status
    spec$screenshot_error <- screenshot_error
    spec$screenshot_file <- screenshot_file
    spec
  })

  html_path <- file.path(output_dir, html_file)
  docx_path <- file.path(output_dir, docx_file)
  html_result <- tryCatch(.plot_sizing_write_html(cases, html_path, asset_dir), error = function(e) e)
  docx_result <- tryCatch(.plot_sizing_write_docx(cases, docx_path), error = function(e) e)

  case_rows <- data.table::rbindlist(lapply(cases, function(case) {
    metadata <- case$metadata
    is_supported <- is.null(case$unsupported_reason)
    origin_ok <- is_supported && grepl("^AutoPlots::", case$renderer_function)
    canonical_renderer_ok <- is_supported && !grepl("^AutoPlots::Plot\\.", case$renderer_function)
    screenshot_helper_ok <- is_supported && identical(case$screenshot_function, .plot_sizing_screenshot_function())
    widget_ok <- !is.null(case$widget)
    screenshot_ok <- !is.null(case$screenshot_file) && file.exists(case$png_path)
    case_status <- if (!is_supported) {
      "warning"
    } else if (!origin_ok || !canonical_renderer_ok || !screenshot_helper_ok) {
      "error"
    } else if (widget_ok && screenshot_ok) {
      "success"
    } else {
      "error"
    }
    data.table::data.table(
      check = case$case_id,
      status = case_status,
      message = paste(c(
        if (is_supported) paste("Renderer:", case$renderer_function) else paste("Not Yet Supported:", case$unsupported_reason),
        if (origin_ok || !is_supported) "Production renderer validation passed." else "Renderer is not an AutoPlots function.",
        if (canonical_renderer_ok || !is_supported) "Canonical renderer validation passed." else "Renderer uses a Plot.* function; gallery requires canonical AutoPlots wrappers.",
        if (screenshot_helper_ok || !is_supported) paste("Screenshot helper:", case$screenshot_function) else paste("Screenshot helper is not production artifact helper:", case$screenshot_function %||% "unknown"),
        if (widget_ok) "AutoPlots widget generated." else paste("AutoPlots widget failed:", case$widget_error %||% case$error %||% "unknown error"),
        if (screenshot_ok) "Production artifact screenshot generated." else paste("Production screenshot failed:", case$screenshot_error %||% "unknown error")
      ), collapse = " "),
      plot_type = metadata$plot_type,
      renderer_function = case$renderer_function,
      screenshot_function = case$screenshot_function,
      screenshot_helper = case$screenshot_function,
      selfcontained = case$screenshot_selfcontained,
      html_path = case$screenshot_html_path,
      png_path = normalizePath(case$png_path, winslash = "/", mustWork = FALSE),
      viewport_width = metadata$requested_width,
      viewport_height = metadata$requested_height,
      screenshot_status = case$screenshot_status,
      rows = metadata$rows,
      columns = metadata$columns,
      categories = metadata$categories,
      max_label_length = metadata$max_label_length,
      x_axis_label_rotate = metadata$x_axis_label_rotate,
      x_axis_label_font_size = metadata$x_axis_label_font_size,
      y_axis_label_font_size = metadata$y_axis_label_font_size,
      requested_width = metadata$requested_width,
      requested_height = metadata$requested_height,
      aspect_ratio = metadata$aspect_ratio,
      file = normalizePath(case$png_path, winslash = "/", mustWork = FALSE)
    )
  }), use.names = TRUE, fill = TRUE)

  output_rows <- data.table::data.table(
    check = c("html_gallery", "docx_gallery"),
    status = c(
      if (inherits(html_result, "error")) "error" else "success",
      if (inherits(docx_result, "error")) "error" else "success"
    ),
    message = c(
      if (inherits(html_result, "error")) conditionMessage(html_result) else paste("Wrote", html_result),
      if (inherits(docx_result, "error")) conditionMessage(docx_result) else paste("Wrote", docx_result)
    ),
    plot_type = "gallery_output",
    renderer_function = "gallery_writer",
    screenshot_function = NA_character_,
    screenshot_helper = NA_character_,
    selfcontained = NA,
    html_path = NA_character_,
    png_path = NA_character_,
    viewport_width = NA_integer_,
    viewport_height = NA_integer_,
    screenshot_status = NA_character_,
    rows = length(cases),
    columns = NA_integer_,
    categories = NA_integer_,
    max_label_length = NA_integer_,
    x_axis_label_rotate = NA_integer_,
    x_axis_label_font_size = NA_integer_,
    y_axis_label_font_size = NA_integer_,
    requested_width = NA_integer_,
    requested_height = NA_integer_,
    aspect_ratio = NA_real_,
    file = c(
      normalizePath(html_path, winslash = "/", mustWork = FALSE),
      normalizePath(docx_path, winslash = "/", mustWork = FALSE)
    )
  )

  data.table::rbindlist(list(case_rows, output_rows), use.names = TRUE, fill = TRUE)
}
