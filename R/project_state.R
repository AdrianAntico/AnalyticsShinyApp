normalize_project_path <- function(path) {
  path <- selected_value(path)
  if (is.null(path)) {
    stop("Project file path is required.", call. = FALSE)
  }

  if (!grepl("\\.rds$", path, ignore.case = TRUE)) {
    path <- paste0(path, ".rds")
  }

  path
}

plot_config_column_status <- function(config, data = NULL) {
  if (is.null(data)) {
    return(list(status = "Needs data", message = "Source data is not available."))
  }

  if (is.null(config$plot_type) || !config$plot_type %in% plot_types) {
    return(list(status = "Rebuild failed", message = "Plot type is not supported by this app."))
  }

  spec <- plot_spec(config$plot_type)
  mappings <- default_value(config$mappings, list())

  missing_required <- character()
  for (mapping in spec$mappings) {
    value <- mappings[[mapping]]
    if (is.null(value) || length(value) == 0L || any(value == "")) {
      missing_required <- c(missing_required, mapping)
    } else if (identical(mapping, "CorrVars")) {
      missing_required <- c(missing_required, setdiff(value, names(data)))
    } else if (!value %in% names(data)) {
      missing_required <- c(missing_required, value)
    }
  }

  if (length(missing_required)) {
    return(list(
      status = "Missing columns",
      message = paste("Missing required columns:", paste(unique(missing_required), collapse = ", "))
    ))
  }

  missing_optional <- character()
  for (mapping in spec$optional_mappings) {
    value <- mappings[[mapping]]
    if (!is.null(value) && length(value) > 0L && !any(value == "")) {
      missing_optional <- c(missing_optional, setdiff(value, names(data)))
    }
  }

  if (length(missing_optional)) {
    return(list(
      status = "Ready",
      message = paste("Missing optional columns:", paste(unique(missing_optional), collapse = ", "))
    ))
  }

  list(status = "Ready", message = "")
}

validate_project_state <- function(project_state, data = NULL) {
  result <- list(
    valid = TRUE,
    errors = character(),
    warnings = character(),
    repaired_state = project_state
  )

  if (!is.list(project_state)) {
    result$valid <- FALSE
    result$errors <- "Project file is not a valid project list."
    result$repaired_state <- list()
    return(result)
  }

  required_fields <- c(
    "app_version", "saved_at",
    "plot_configs", "plot_code", "plot_metadata",
    "layout_type", "layout_cols", "export_dir", "export_name"
  )
  missing_fields <- setdiff(required_fields, names(project_state))
  if (length(missing_fields)) {
    hard_missing <- setdiff(missing_fields, c("app_version", "plot_code", "plot_metadata"))
    if (length(hard_missing)) {
      result$valid <- FALSE
      result$errors <- c(
        result$errors,
        paste("Project file is missing required fields:", paste(hard_missing, collapse = ", "))
      )
    }
    repairable_missing <- intersect(missing_fields, c("plot_code", "plot_metadata"))
    if (length(repairable_missing)) {
      result$warnings <- c(
        result$warnings,
        paste("Project file was missing repairable fields:", paste(repairable_missing, collapse = ", "))
      )
    }
  }

  optional_fields <- c(
    "data_path", "data_name", "current_plot_type",
    "current_mappings", "current_options", "section_names", "selected_theme",
    "module_artifacts", "text_artifacts", "table_artifacts", "report_plans", "active_plan_id",
    "code_run_records", "code_run_requests", "code_run_results",
    "code_runner_policy", "code_execution_policy"
  )
  missing_optional <- setdiff(optional_fields, names(project_state))
  if (length(missing_optional)) {
    result$warnings <- c(
      result$warnings,
      paste("Project file is missing optional fields:", paste(missing_optional, collapse = ", "))
    )
  }

  if (is.null(project_state$app_version) ||
      !identical(project_state$app_version, APP_VERSION)) {
    result$warnings <- c(
      result$warnings,
      "Project file version differs from current app version. Attempting to load."
    )
  }

  if (!result$valid) {
    return(result)
  }

  repaired <- project_state

  if (!is.list(repaired$plot_configs) || is.null(names(repaired$plot_configs))) {
    result$valid <- FALSE
    result$errors <- c(result$errors, "plot_configs must be a named list.")
    result$repaired_state <- repaired
    return(result)
  }

  plot_names <- names(repaired$plot_configs)
  invalid_names <- plot_names[!grepl("^p[0-9]+$", plot_names)]
  if (length(invalid_names)) {
    result$warnings <- c(
      result$warnings,
      paste("Some plot names are unusual:", paste(invalid_names, collapse = ", "))
    )
  }

  if (!is.list(repaired$plot_code)) {
    repaired$plot_code <- list()
    result$warnings <- c(result$warnings, "plot_code was missing or invalid and was rebuilt where possible.")
  }

  if (!is.list(repaired$plot_metadata)) {
    repaired$plot_metadata <- list()
    result$warnings <- c(result$warnings, "plot_metadata was missing or invalid and default metadata was added.")
  }

  stale_metadata <- setdiff(names(repaired$plot_metadata), plot_names)
  if (length(stale_metadata)) {
    repaired$plot_metadata[stale_metadata] <- NULL
    result$warnings <- c(
      result$warnings,
      paste("Removed stale metadata for missing plots:", paste(stale_metadata, collapse = ", "))
    )
  }

  for (plot_name in plot_names) {
    config <- repaired$plot_configs[[plot_name]]

    if (is.null(repaired$plot_code[[plot_name]])) {
      repaired$plot_code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
      result$warnings <- c(result$warnings, paste("Rebuilt missing code for", plot_name))
    }

    metadata <- repaired$plot_metadata[[plot_name]]
    if (is.null(metadata) || !is.list(metadata)) {
      metadata <- plot_metadata(
        plot_name = plot_name,
        config = config,
        section_name = "Analysis",
        sort_order = NA_integer_
      )
      result$warnings <- c(result$warnings, paste("Added default metadata for", plot_name))
    }

    if (!identical(metadata$plot_name, plot_name)) {
      metadata$plot_name <- plot_name
      result$warnings <- c(result$warnings, paste("Repaired metadata plot name for", plot_name))
    }
    metadata$plot_type <- config$plot_type
    if (is.null(metadata$section_name) || !nzchar(metadata$section_name)) {
      metadata$section_name <- "Analysis"
      result$warnings <- c(result$warnings, paste("Defaulted section to Analysis for", plot_name))
    }
    metadata$sort_order <- suppressWarnings(as.integer(metadata$sort_order))
    repaired$plot_metadata[[plot_name]] <- metadata
  }

  ordered_names <- ordered_plot_names_from_metadata(repaired$plot_metadata)
  for (index in seq_along(ordered_names)) {
    repaired$plot_metadata[[ordered_names[index]]]$sort_order <- index
  }

  if (is.null(repaired$layout_type) || !repaired$layout_type %in% c("Grid", "Sections")) {
    repaired$layout_type <- "Grid"
    result$warnings <- c(result$warnings, "Invalid layout_type repaired to Grid.")
  }

  layout_cols <- suppressWarnings(as.integer(repaired$layout_cols))
  if (is.na(layout_cols)) {
    layout_cols <- 2L
    result$warnings <- c(result$warnings, "Invalid layout_cols repaired to 2.")
  }
  repaired$layout_cols <- max(1L, min(4L, layout_cols))
  if (!identical(repaired$layout_cols, layout_cols)) {
    result$warnings <- c(result$warnings, "layout_cols was clamped between 1 and 4.")
  }

  if (!is.null(repaired$sections) && is.list(repaired$sections)) {
    repaired$sections <- lapply(repaired$sections, function(section) {
      names(section)[names(section) %in% plot_names]
    })
    repaired$sections <- repaired$sections[vapply(repaired$sections, length, integer(1)) > 0L]
    result$warnings <- c(result$warnings, "Section state was repaired; sections are derived from plot metadata.")
  }

  for (plot_name in plot_names) {
    compatibility <- plot_config_column_status(repaired$plot_configs[[plot_name]], data = data)
    if (!identical(compatibility$status, "Ready") || nzchar(compatibility$message)) {
      result$warnings <- c(result$warnings, paste(plot_name, compatibility$status, compatibility$message))
    }
  }

  result$warnings <- unique(result$warnings[nzchar(result$warnings)])
  result$repaired_state <- repaired
  result
}

