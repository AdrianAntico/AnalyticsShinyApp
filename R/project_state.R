normalize_project_path <- function(path) {
  path <- selected_value(path)
  if (is.null(path)) {
    stop("Project file path is required.", call. = FALSE)
  }

  path <- trimws(as.character(path[[1]]))
  path <- gsub("^[\"']+|[\"']+$", "", path)
  path <- trimws(path)
  if (!nzchar(path)) {
    stop("Project file path is required.", call. = FALSE)
  }

  path <- path.expand(chartr("\\", "/", path))
  if (!grepl("\\.rds$", path, ignore.case = TRUE)) {
    path <- paste0(path, ".rds")
  }

  suppressWarnings(normalizePath(path, winslash = "/", mustWork = FALSE))
}

normalize_project_load_path <- function(path) {
  path <- normalize_project_path(path)
  if (file.exists(path)) {
    return(normalizePath(path, winslash = "/", mustWork = TRUE))
  }

  path
}

qa_project_load_paths <- function(output_dir = file.path(tempdir(), "project_load_path_qa")) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  project_path <- normalizePath(file.path(output_dir, "qa_project.rds"), winslash = "/", mustWork = FALSE)
  saveRDS(list(app_version = APP_VERSION, saved_at = Sys.time(), plot_configs = list(), plot_code = list(), plot_metadata = list(), layout_type = "Grid", layout_cols = 2L, export_dir = output_dir, export_name = "qa"), project_path)
  existing_path <- normalizePath(project_path, winslash = "/", mustWork = TRUE)
  backslash_path <- chartr("/", "\\", existing_path)
  quoted_backslash_path <- paste0("\"", backslash_path, "\"")
  quoted_forward_path <- paste0("\"", existing_path, "\"")
  nonexistent_path <- file.path(output_dir, "missing_project.rds")

  checks <- list(
    backslash_path = list(
      path = backslash_path,
      expected_exists = TRUE,
      recommendation = "Backslash Windows paths should normalize to a readable RDS path."
    ),
    forward_slash_path = list(
      path = existing_path,
      expected_exists = TRUE,
      recommendation = "Forward slash paths should continue to load."
    ),
    quoted_backslash_path = list(
      path = quoted_backslash_path,
      expected_exists = TRUE,
      recommendation = "Quoted Windows paths should strip quotes before file checks."
    ),
    quoted_forward_slash_path = list(
      path = quoted_forward_path,
      expected_exists = TRUE,
      recommendation = "Quoted forward slash paths should strip quotes before file checks."
    ),
    nonexistent_path = list(
      path = nonexistent_path,
      expected_exists = FALSE,
      recommendation = "Missing project files should report a clear missing-file condition."
    )
  )

  rows <- lapply(names(checks), function(check_name) {
    spec <- checks[[check_name]]
    normalized <- tryCatch(
      normalize_project_load_path(spec$path),
      error = function(e) structure(NA_character_, error = conditionMessage(e))
    )
    error <- attr(normalized, "error") %||% ""
    exists <- is.character(normalized) && length(normalized) == 1L && !is.na(normalized) && file.exists(normalized)
    readable <- if (exists) {
      tryCatch(is.list(readRDS(normalized)), error = function(e) FALSE)
    } else {
      FALSE
    }
    status <- if (nzchar(error)) {
      "error"
    } else if (isTRUE(spec$expected_exists) && exists && readable) {
      "success"
    } else if (!isTRUE(spec$expected_exists) && !exists && grepl("missing_project\\.rds$", normalized)) {
      "success"
    } else {
      "error"
    }

    data.table::data.table(
      check = check_name,
      status = status,
      message = if (identical(status, "success")) {
        paste("Normalized path:", normalized)
      } else if (nzchar(error)) {
        error
      } else {
        paste("Path normalization did not meet expectation. Normalized path:", normalized)
      },
      recommendation = spec$recommendation
    )
  })

  empty_project <- list(
    app_version = APP_VERSION,
    saved_at = Sys.time(),
    plot_configs = list(),
    plot_code = list(),
    plot_metadata = list(),
    layout_type = "Grid",
    layout_cols = 2L,
    export_dir = output_dir,
    export_name = "empty_artifact_project"
  )
  empty_validation <- validate_project_state(empty_project)
  empty_row <- data.table::data.table(
    check = "empty_plot_collections",
    status = if (isTRUE(empty_validation$valid)) "success" else "error",
    message = if (isTRUE(empty_validation$valid)) {
      "Project states with no saved Plot Builder plots can still load artifact/module evidence."
    } else {
      paste(empty_validation$errors, collapse = " | ")
    },
    recommendation = "Empty plot collections should not block loading collector/artifact-first projects."
  )

  data.table::rbindlist(c(rows, list(empty_row)), use.names = TRUE, fill = TRUE)
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
    "active_modeling_context", "source_data_info", "feature_experiment_state", "analytical_campaign_state", "decision_memory_state", "semantic_workspace", "semantic_decision_state", "decision_valuation_state", "decision_workflow_state", "causal_intelligence_state", "causal_experiment_state", "causal_completed_experiment_state", "causal_itt_state", "causal_observational_state", "ai_draft_store", "ai_mutation_store", "artifact_relationship_drafts",
    "current_mappings", "current_options", "section_names", "selected_theme",
    "project_metadata", "workspace_root",
    "module_artifacts", "text_artifacts", "table_artifacts", "report_plans", "active_plan_id",
    "project_collector",
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

  if (!is.list(repaired$plot_configs) || (length(repaired$plot_configs) > 0L && is.null(names(repaired$plot_configs)))) {
    result$valid <- FALSE
    result$errors <- c(result$errors, "plot_configs must be a named list.")
    result$repaired_state <- repaired
    return(result)
  }

  plot_names <- names(repaired$plot_configs) %||% character()
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

