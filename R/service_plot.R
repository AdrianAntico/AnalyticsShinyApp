build_plot_args <- function(
  plot_type,
  data,
  input,
  include_data = TRUE
) {
  args <- list()
  if (include_data) {
    args$dt <- data
  }

  for (mapping in active_mappings(plot_type)) {
    args[[mapping]] <- mapping_value(input, mapping)
  }

  for (option_name in plot_spec(plot_type)$options) {
    args <- add_option_arg(args, option_name, option_value(input, option_name))
  }

  args[!vapply(args, is.null, logical(1))]
}

build_autoplots_call <- function(plot_type, data, input) {
  plot_fun <- getExportedValue("AutoPlots", plot_type)
  args <- build_plot_args(plot_type, data, input)
  apply_autoplots_full_grid(do.call(plot_fun, args))
}

plot_service_output_id <- function(id, prefix = "plot") {
  paste0(prefix, "_", gsub("[^A-Za-z0-9_]", "_", id %||% "visual"))
}

render_plot_service_widget <- function(widget, output, session, output_id, height = "520px") {
  if (is.null(widget)) {
    return(NULL)
  }
  if (!inherits(widget, "htmlwidget")) {
    return(htmltools::tagList(widget))
  }
  if (is.null(output) || is.null(session)) {
    return(htmltools::tagList(widget))
  }
  if (!requireNamespace("echarts4r", quietly = TRUE)) {
    return(htmltools::tagList(widget))
  }

  local_widget <- widget
  output[[output_id]] <- echarts4r::renderEcharts4r({
    local_widget
  })
  echarts4r::echarts4rOutput(session$ns(output_id), width = "100%", height = height)
}

snapshot_plot_config <- function(plot_type, input, mapping_values = list()) {
  spec <- plot_spec(plot_type)

  mappings <- list()
  for (mapping in active_mappings(plot_type)) {
    value <- mapping_value(input, mapping)
    if (is_empty_arg(value)) {
      remembered_value <- mapping_values[[mapping]]
      if (!is_empty_arg(remembered_value)) {
        value <- remembered_value
      }
    }

    mappings[[mapping]] <- value
  }

  options <- list()
  for (option_name in spec$options) {
    options[[option_name]] <- option_value(input, option_name)
  }

  list(
    plot_type = plot_type,
    mappings = mappings,
    options = options
  )
}

build_plot_args_from_config <- function(config, data, include_data = TRUE) {
  args <- list()

  if (include_data) {
    args$dt <- data
  }

  for (name in names(config$mappings)) {
    args[[name]] <- config$mappings[[name]]
  }

  for (name in names(config$options)) {
    args <- add_option_arg(args, name, config$options[[name]])
  }

  args[!vapply(args, is_empty_arg, logical(1))]
}

build_autoplots_call_from_config <- function(config, data) {
  plot_fun <- getExportedValue("AutoPlots", config$plot_type)
  args <- build_plot_args_from_config(config, data = data, include_data = TRUE)
  apply_autoplots_full_grid(do.call(plot_fun, args))
}

apply_autoplots_full_grid <- function(widget) {
  if (is.null(widget) || !inherits(widget, "htmlwidget")) {
    return(widget)
  }
  if (!requireNamespace("AutoPlots", quietly = TRUE)) {
    stop("AutoPlots is required to apply full-pane plot grid sizing.", call. = FALSE)
  }
  if (!exists("e_grid_full", envir = asNamespace("AutoPlots"), inherits = FALSE)) {
    stop("AutoPlots::e_grid_full() is unavailable. Install the current GitHub version of AutoPlots.", call. = FALSE)
  }

  AutoPlots::e_grid_full(widget)
}

validate_plot_ready <- function(plot_type, data, input) {
  if (is.null(data)) {
    return("No data is available.")
  }

  spec <- plot_spec(plot_type)

  for (mapping in spec$mappings) {
    value <- mapping_value(input, mapping)

    if (is.null(value) || length(value) == 0L || any(value == "")) {
      return(paste0("Required mapping is missing: ", mapping))
    }

    if (identical(mapping, "CorrVars")) {
      missing_cols <- setdiff(value, names(data))
      if (length(missing_cols)) {
        return(paste0(
          "CorrVars contains columns not in data: ",
          paste(missing_cols, collapse = ", ")
        ))
      }
    } else if (!value %in% names(data)) {
      return(paste0(mapping, " column is not in data: ", value))
    }
  }

  TRUE
}

validate_plot_config_ready <- function(config, data) {
  if (is.null(data)) {
    return("No data is available.")
  }

  spec <- plot_spec(config$plot_type)

  for (mapping in spec$mappings) {
    value <- config$mappings[[mapping]]

    if (is.null(value) || length(value) == 0L || any(value == "")) {
      return(paste0("Required mapping is missing: ", mapping))
    }

    if (identical(mapping, "CorrVars")) {
      missing_cols <- setdiff(value, names(data))
      if (length(missing_cols)) {
        return(paste0(
          "CorrVars contains columns not in data: ",
          paste(missing_cols, collapse = ", ")
        ))
      }
    } else if (!value %in% names(data)) {
      return(paste0(mapping, " column is not in data: ", value))
    }
  }

  TRUE
}

arg_to_code <- function(name, value) {
  if (is.logical(value) || is.numeric(value)) {
    return(paste0(name, " = ", deparse(value, width.cutoff = 500L)))
  }

  paste0(name, " = ", r_string(value))
}

build_autoplots_code <- function(plot_type, input) {
  args <- build_plot_args(plot_type, data = NULL, input = input, include_data = FALSE)
  arg_lines <- c(
    "dt = data",
    unlist(Map(arg_to_code, names(args), args), use.names = FALSE)
  )

  paste0(
    "library(AutoPlots)\n\n",
    "data <- data.table::fread(\"path/to/data.csv\")\n\n",
    "p1 <- AutoPlots::", plot_type, "(\n",
    "  ", paste(arg_lines, collapse = ",\n  "), "\n",
    ") |>\n",
    "  AutoPlots::e_grid_full()\n\n",
    "p1"
  )
}

build_autoplots_assignment_code <- function(name, config) {
  args <- build_plot_args_from_config(config, data = NULL, include_data = FALSE)
  arg_lines <- c(
    "dt = data",
    unlist(Map(arg_to_code, names(args), args), use.names = FALSE)
  )

  paste0(
    name, " <- AutoPlots::", config$plot_type, "(\n",
    "  ", paste(arg_lines, collapse = ",\n  "), "\n",
    ") |>\n",
    "  AutoPlots::e_grid_full()"
  )
}

next_plot_name <- function(plot_names) {
  if (!length(plot_names)) {
    return("p1")
  }

  plot_ids <- suppressWarnings(as.integer(sub("^p", "", plot_names)))
  plot_ids <- plot_ids[!is.na(plot_ids)]
  if (!length(plot_ids)) {
    return("p1")
  }

  paste0("p", max(plot_ids) + 1L)
}

next_sort_order <- function(metadata) {
  if (!length(metadata)) {
    return(1L)
  }

  orders <- vapply(metadata, function(item) {
    if (is.null(item$sort_order)) {
      return(NA_integer_)
    }

    as.integer(item$sort_order)
  }, integer(1))
  orders <- orders[!is.na(orders)]
  if (!length(orders)) {
    return(1L)
  }

  max(orders) + 1L
}

plot_metadata <- function(plot_name, config, section_name = "Analysis", sort_order = 1L) {
  list(
    plot_name = plot_name,
    plot_type = config$plot_type,
    section_name = section_name,
    sort_order = as.integer(sort_order)
  )
}

ordered_plot_names_from_metadata <- function(metadata) {
  plot_names <- names(metadata)
  if (!length(plot_names)) {
    return(character())
  }

  orders <- vapply(metadata, function(item) {
    if (is.null(item$sort_order)) {
      return(NA_integer_)
    }

    as.integer(item$sort_order)
  }, integer(1))
  orders[is.na(orders)] <- seq_along(orders)[is.na(orders)]
  plot_names[order(orders, plot_names)]
}

section_plot_names_from_metadata <- function(metadata) {
  plot_names <- ordered_plot_names_from_metadata(metadata)
  sections <- list()

  for (plot_name in plot_names) {
    section_name <- metadata[[plot_name]]$section_name
    if (is.null(section_name) || !nzchar(section_name)) {
      section_name <- "Analysis"
    }

    sections[[section_name]] <- c(sections[[section_name]], plot_name)
  }

  sections
}

ordered_list_by_names <- function(items, item_names) {
  item_names <- item_names[item_names %in% names(items)]
  items[item_names]
}

build_saved_plots_code <- function(saved_code) {
  plot_names <- names(saved_code)
  if (!length(plot_names)) {
    return(paste0(
      "library(AutoPlots)\n\n",
      "data <- data.table::fread(\"path/to/data.csv\")\n\n",
      "list()"
    ))
  }

  paste0(
    "library(AutoPlots)\n\n",
    "data <- data.table::fread(\"path/to/data.csv\")\n\n",
    paste(unlist(saved_code, use.names = FALSE), collapse = "\n\n"),
    "\n\n",
    "list(", paste(plot_names, collapse = ", "), ")"
  )
}

plot_list_code <- function(plot_names) {
  if (!length(plot_names)) {
    return("list()")
  }

  paste0("list(", paste(plot_names, collapse = ", "), ")")
}

section_list_code <- function(section_plot_names) {
  section_names <- names(section_plot_names)
  if (!length(section_names)) {
    return("list()")
  }

  section_lines <- unlist(lapply(section_names, function(section_name) {
    paste0(
      "  ", r_string(section_name), " = ",
      plot_list_code(section_plot_names[[section_name]])
    )
  }), use.names = FALSE)

  paste0(
    "list(\n",
    paste(section_lines, collapse = ",\n"),
    "\n)"
  )
}

build_layout_code <- function(plot_names, section_plot_names = list(), layout_type = "Grid", cols = 2) {
  if (identical(layout_type, "Sections")) {
    return(paste0(
      "sections <- ", section_list_code(section_plot_names), "\n\n",
      "report <- AutoPlots::display_plots_sections(\n",
      "  sections = sections,\n",
      "  cols = ", cols, "\n",
      ")\n\n",
      "report"
    ))
  }

  paste0(
    "plots <- ", plot_list_code(plot_names), "\n\n",
    "report <- AutoPlots::display_plots_grid(\n",
    "  plots = plots,\n",
    "  cols = ", cols, "\n",
    ")\n\n",
    "report"
  )
}

build_export_code <- function(export_dir = "path/to/output", export_name = "autoplots_report") {
  paste0(
    "html_path <- file.path(", r_string(export_dir), ", ", r_string(paste0(tools::file_path_sans_ext(basename(export_name)), ".html")), ")\n",
    "if (inherits(report, \"htmlwidget\")) {\n",
    "  htmlwidgets::saveWidget(\n",
    "    widget = report,\n",
    "    file = html_path,\n",
    "    selfcontained = TRUE\n",
    "  )\n",
    "} else {\n",
    "  htmltools::save_html(\n",
    "    htmltools::browsable(report),\n",
    "    file = html_path,\n",
    "    libdir = paste0(", r_string(tools::file_path_sans_ext(basename(export_name))), ", \"_files\")\n",
    "  )\n",
    "}"
  )
}

build_report_code <- function(
  saved_code,
  section_plot_names = list(),
  layout_type = "Grid",
  cols = 2,
  export_dir = "path/to/output",
  export_name = "autoplots_report",
  data_path = "path/to/data.csv"
) {
  plot_names <- names(saved_code)
  assignment_code <- if (length(plot_names)) {
    paste(unlist(saved_code, use.names = FALSE), collapse = "\n\n")
  } else {
    ""
  }

  layout_code <- build_layout_code(
    plot_names = plot_names,
    section_plot_names = section_plot_names,
    layout_type = layout_type,
    cols = cols
  )

  paste0(
    "library(AutoPlots)\n\n",
    "data <- data.table::fread(", r_string(data_path), ")\n\n",
    if (nzchar(assignment_code)) paste0(assignment_code, "\n\n") else "",
    layout_code,
    "\n\n",
    build_export_code(export_dir = export_dir, export_name = export_name)
  )
}

write_report_code <- function(code, path, name) {
  export_dir <- selected_value(path)
  if (is.null(export_dir)) {
    stop("Export directory is required.", call. = FALSE)
  }

  export_name <- selected_value(name)
  if (is.null(export_name)) {
    stop("File name is required.", call. = FALSE)
  }

  if (!dir.exists(export_dir)) {
    dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!dir.exists(export_dir)) {
    stop("Export directory could not be created.", call. = FALSE)
  }
  if (exists("storage_repo_root", mode = "function") &&
      exists("path_within_root", mode = "function") &&
      path_within_root(export_dir, storage_repo_root())) {
    stop("Export directory is inside the application repository and was blocked.", call. = FALSE)
  }

  output_path <- file.path(
    normalizePath(export_dir, winslash = "/", mustWork = TRUE),
    paste0(tools::file_path_sans_ext(basename(export_name)), ".R")
  )

  writeLines(code, con = output_path, useBytes = TRUE)
  normalizePath(output_path, winslash = "/", mustWork = TRUE)
}

