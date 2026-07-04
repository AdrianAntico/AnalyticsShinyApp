server <- function(input, output, session) {
  ctx <- new.env(parent = environment())

  ctx$mapping_state <- reactiveValues(values = list())
  ctx$saved_plots <- reactiveValues(
    plots = list(),
    configs = list(),
    code = list(),
    metadata = list(),
    status = list()
  )
  ctx$saved_sections <- reactiveValues(sections = list())
  ctx$saved_text_artifacts <- reactiveValues(artifacts = list())
  ctx$saved_table_artifacts <- reactiveValues(artifacts = list())

  ctx$plot_result <- reactiveVal(NULL)
  ctx$plot_error <- reactiveVal(NULL)
  ctx$plot_config <- reactiveVal(NULL)
  ctx$plot_list_message <- reactiveVal("")
  ctx$text_artifact_message <- reactiveVal("")
  ctx$text_artifact_preview <- reactiveVal(NULL)
  ctx$table_artifact_message <- reactiveVal("")
  ctx$table_artifact_preview <- reactiveVal(NULL)
  ctx$artifact_library_message <- reactiveVal("")
  ctx$export_message <- reactiveVal("")
  ctx$project_message <- reactiveVal("")
  ctx$project_data <- reactiveVal(NULL)
  ctx$project_data_info <- reactiveVal(list(path = NULL, name = NULL))

  ctx$uploaded_data <- reactive({
    data <- ctx$project_data()
    if (!is.null(data)) {
      return(data)
    }
    req(FALSE)
  })
  ctx$current_data_path <- function() ctx$project_data_info()$path
  ctx$current_data_name <- function() ctx$project_data_info()$name
  ctx$has_upload_or_project_data <- function() !is.null(ctx$project_data())
  ctx$layout_cols_value <- function() 2L
  ctx$get_layout_type <- function() "Grid"
  ctx$set_layout_settings <- function(layout_type = NULL, layout_cols = NULL) invisible(NULL)
  ctx$get_export_dir <- function() getwd()
  ctx$get_export_name <- function() "autoplots_report"
  ctx$export_name_value <- function() "autoplots_report"
  ctx$set_export_settings <- function(export_dir = NULL, export_name = NULL) invisible(NULL)
  ctx$get_current_plot_type <- function() NULL
  ctx$current_plot_options <- function() list()
  ctx$load_config_into_builder <- function(config) invisible(NULL)

  ctx$ordered_plot_names <- function() {
    ordered_plot_names_from_metadata(ctx$saved_plots$metadata)
  }

  ctx$ready_plot_names <- function() {
    plot_names <- ctx$ordered_plot_names()
    plot_names[vapply(plot_names, function(plot_name) {
      identical(ctx$saved_plots$status[[plot_name]]$status, "Ready")
    }, logical(1))]
  }

  ctx$ordered_saved_plots <- function() {
    ordered_list_by_names(ctx$saved_plots$plots, ctx$ready_plot_names())
  }

  ctx$section_plot_names <- function(ready_only = FALSE) {
    metadata <- ctx$saved_plots$metadata
    if (isTRUE(ready_only)) {
      metadata <- ordered_list_by_names(metadata, ctx$ready_plot_names())
    }

    section_plot_names_from_metadata(metadata)
  }

  ctx$section_plot_objects <- function() {
    sections <- ctx$section_plot_names(ready_only = TRUE)
    lapply(sections, function(plot_names) {
      ordered_list_by_names(ctx$saved_plots$plots, plot_names)
    })
  }

  ctx$plot_artifacts <- function() {
    saved_plots_to_artifacts(
      saved_plots = ctx$saved_plots$plots,
      configs = ctx$saved_plots$configs,
      code = ctx$saved_plots$code,
      metadata = ctx$saved_plots$metadata
    )
  }

  ctx$text_artifacts <- function() {
    ctx$saved_text_artifacts$artifacts
  }

  ctx$table_artifacts <- function() {
    ctx$saved_table_artifacts$artifacts
  }

  ctx$all_artifacts <- function() {
    c(ctx$plot_artifacts(), ctx$text_artifacts(), ctx$table_artifacts())
  }

  ctx$artifact_order_value <- function(value, fallback = NA_integer_) {
    order <- suppressWarnings(as.integer(value))
    if (is.na(order)) {
      return(fallback)
    }

    order
  }

  ctx$update_plot_artifact_metadata <- function(artifact_id, label, section, order, visible) {
    metadata <- ctx$saved_plots$metadata[[artifact_id]] %||% list()
    metadata$label <- label
    metadata$section_name <- section
    metadata$sort_order <- order
    metadata$visible <- visible
    ctx$saved_plots$metadata[[artifact_id]] <- metadata
  }

  ctx$update_artifact_metadata <- function(artifact_id, label, section, order, visible) {
    if (artifact_id %in% names(ctx$saved_plots$configs)) {
      ctx$update_plot_artifact_metadata(artifact_id, label, section, order, visible)
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_text_artifacts$artifacts)) {
      artifact <- ctx$saved_text_artifacts$artifacts[[artifact_id]]
      artifact$label <- label
      artifact$section <- section
      artifact$order <- order
      artifact$visible <- visible
      artifact$updated_at <- Sys.time()
      ctx$saved_text_artifacts$artifacts[[artifact_id]] <- artifact
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_table_artifacts$artifacts)) {
      artifact <- ctx$saved_table_artifacts$artifacts[[artifact_id]]
      artifact$label <- label
      artifact$section <- section
      artifact$order <- order
      artifact$visible <- visible
      artifact$updated_at <- Sys.time()
      ctx$saved_table_artifacts$artifacts[[artifact_id]] <- artifact
      return(TRUE)
    }

    FALSE
  }

  ctx$remove_artifact_by_id <- function(artifact_id) {
    if (artifact_id %in% names(ctx$saved_plots$plots)) {
      ctx$saved_plots$plots[[artifact_id]] <- NULL
      ctx$saved_plots$configs[[artifact_id]] <- NULL
      ctx$saved_plots$code[[artifact_id]] <- NULL
      ctx$saved_plots$metadata[[artifact_id]] <- NULL
      ctx$saved_plots$status[[artifact_id]] <- NULL
      sections <- ctx$saved_sections$sections
      for (section_name in names(sections)) {
        sections[[section_name]][[artifact_id]] <- NULL
        if (!length(sections[[section_name]])) {
          sections[[section_name]] <- NULL
        }
      }
      ctx$saved_sections$sections <- sections
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_text_artifacts$artifacts)) {
      ctx$saved_text_artifacts$artifacts[[artifact_id]] <- NULL
      return(TRUE)
    }

    if (artifact_id %in% names(ctx$saved_table_artifacts$artifacts)) {
      ctx$saved_table_artifacts$artifacts[[artifact_id]] <- NULL
      return(TRUE)
    }

    FALSE
  }

  ctx$all_report_artifacts <- function() {
    artifacts <- ctx$all_artifacts()
    artifacts <- artifacts[vapply(artifacts, function(artifact) {
      isTRUE(artifact$visible) && identical(artifact$status, "ready")
    }, logical(1))]

    if (!length(artifacts)) {
      return(list())
    }

    summary <- artifact_summary(artifacts)
    ordered_ids <- summary$artifact_id[order(summary$order, summary$artifact_id)]
    ordered_list_by_names(artifacts, ordered_ids)
  }

  ctx$mixed_report_preview <- function() {
    artifacts <- ctx$all_report_artifacts()
    if (!length(artifacts)) {
      return(NULL)
    }

    cols <- ctx$layout_cols_value()
    if (identical(ctx$get_layout_type(), "Sections")) {
      summary <- artifact_summary(artifacts)
      section_names <- unique(summary$section)
      return(tags$div(
        class = "aq-report-sections",
        lapply(section_names, function(section_name) {
          section_ids <- summary$artifact_id[summary$section == section_name]
          tags$section(
            class = "aq-report-section",
            tags$h3(class = "aq-report-section-title", section_name),
            tags$div(
              class = "aq-report-grid",
              style = paste0("grid-template-columns: repeat(", cols, ", minmax(0, 1fr));"),
              lapply(ordered_list_by_names(artifacts, section_ids), render_artifact)
            )
          )
        })
      ))
    }

    tags$div(
      class = "aq-report-grid",
      style = paste0("grid-template-columns: repeat(", cols, ", minmax(0, 1fr));"),
      lapply(artifacts, render_artifact)
    )
  }

  ctx$next_text_artifact_id <- function() {
    existing <- names(ctx$saved_text_artifacts$artifacts)
    index <- 1L
    repeat {
      artifact_id <- paste0("t", index)
      if (!artifact_id %in% existing) {
        return(artifact_id)
      }
      index <- index + 1L
    }
  }

  ctx$next_table_artifact_id <- function() {
    existing <- names(ctx$saved_table_artifacts$artifacts)
    index <- 1L
    repeat {
      artifact_id <- paste0("tbl", index)
      if (!artifact_id %in% existing) {
        return(artifact_id)
      }
      index <- index + 1L
    }
  }

  ctx$next_artifact_order <- function() {
    summary <- combined_artifact_summary(ctx$plot_artifacts(), ctx$text_artifacts(), ctx$table_artifacts())
    if (!nrow(summary) || all(is.na(summary$order))) {
      return(1L)
    }

    max(summary$order, na.rm = TRUE) + 1L
  }

  ctx$current_report_code <- function() {
    ready_names <- ctx$ready_plot_names()
    if (!length(ready_names)) {
      stop("No ready saved plots are available. Rebuild or repair saved plots before exporting R code.", call. = FALSE)
    }

    build_report_code(
      saved_code = ordered_list_by_names(ctx$saved_plots$code, ready_names),
      section_plot_names = ctx$section_plot_names(ready_only = TRUE),
      layout_type = ctx$get_layout_type(),
      cols = ctx$layout_cols_value(),
      export_dir = default_value(selected_value(ctx$get_export_dir()), "path/to/output"),
      export_name = default_value(ctx$export_name_value(), "autoplots_report"),
      data_path = default_value(ctx$current_data_path(), "path/to/data.csv")
    )
  }

  ctx$current_report <- reactive({
    if (!length(names(ctx$saved_plots$plots))) {
      return(NULL)
    }

    cols <- ctx$layout_cols_value()

    if (identical(ctx$get_layout_type(), "Sections")) {
      sections <- ctx$section_plot_objects()
      if (!length(names(sections))) {
        return(NULL)
      }

      return(AutoPlots::display_plots_sections(
        sections = sections,
        cols = cols
      ))
    }

    AutoPlots::display_plots_grid(
      plots = ctx$ordered_saved_plots(),
      cols = cols
    )
  })

  ctx$current_project_state <- function() {
    data_path <- ctx$current_data_path()
    list(
      app_version = APP_VERSION,
      saved_at = Sys.time(),
      data_path = data_path,
      data_name = ctx$current_data_name(),
      original_data_path = data_path,
      plot_configs = ctx$saved_plots$configs,
      plot_code = ctx$saved_plots$code,
      plot_metadata = ctx$saved_plots$metadata,
      text_artifacts = ctx$saved_text_artifacts$artifacts,
      table_artifacts = ctx$saved_table_artifacts$artifacts,
      layout_type = ctx$get_layout_type(),
      layout_cols = ctx$layout_cols_value(),
      export_dir = selected_value(ctx$get_export_dir()),
      export_name = ctx$export_name_value(),
      current_plot_type = ctx$get_current_plot_type(),
      current_mappings = ctx$mapping_state$values,
      current_options = ctx$current_plot_options(),
      section_names = names(ctx$section_plot_names()),
      selected_theme = NULL
    )
  }

  ctx$rebuild_saved_plots <- function(data) {
    plots <- list()
    failures <- character()

    for (plot_name in names(ctx$saved_plots$configs)) {
      config <- ctx$saved_plots$configs[[plot_name]]
      compatibility <- plot_config_column_status(config, data = data)
      if (!identical(compatibility$status, "Ready")) {
        ctx$saved_plots$status[[plot_name]] <- compatibility
        failures <- c(failures, paste0(plot_name, ": ", compatibility$message))
        next
      }

      plot <- tryCatch(
        build_autoplots_call_from_config(config, data),
        error = function(e) {
          ctx$saved_plots$status[[plot_name]] <- list(
            status = "Rebuild failed",
            message = conditionMessage(e)
          )
          failures <<- c(failures, paste0(plot_name, ": ", conditionMessage(e)))
          NULL
        }
      )

      if (!is.null(plot)) {
        plots[[plot_name]] <- plot
        ctx$saved_plots$status[[plot_name]] <- list(
          status = "Ready",
          message = compatibility$message
        )
      }
    }

    ctx$saved_plots$plots <- plots
    failures
  }

  ctx$load_project_state <- function(project_state, preferred_data_path = NULL, export_dir_override = NULL) {
    validation <- validate_project_state(project_state)
    if (!isTRUE(validation$valid)) {
      stop(paste(validation$errors, collapse = " "), call. = FALSE)
    }

    project_state <- validation$repaired_state
    messages <- validation$warnings

    if (!is.null(preferred_data_path) && file.exists(preferred_data_path)) {
      project_state$data_path <- preferred_data_path
      project_state$data_name <- basename(preferred_data_path)
    }

    if (!is.null(export_dir_override)) {
      project_state$export_dir <- export_dir_override
    }

    ctx$saved_plots$configs <- project_state$plot_configs
    ctx$saved_plots$code <- project_state$plot_code
    ctx$saved_plots$metadata <- project_state$plot_metadata
    ctx$saved_plots$status <- list()
    ctx$saved_text_artifacts$artifacts <- project_state$text_artifacts %||% list()
    ctx$saved_table_artifacts$artifacts <- project_state$table_artifacts %||% list()

    for (plot_name in names(ctx$saved_plots$configs)) {
      ctx$saved_plots$status[[plot_name]] <- list(
        status = "Needs data",
        message = "Source data is not available."
      )
    }

    ctx$saved_plots$plots <- list()
    ctx$project_data(NULL)
    ctx$project_data_info(list(
      path = project_state$data_path,
      name = project_state$data_name
    ))

    if (!is.null(project_state$data_path) && file.exists(project_state$data_path)) {
      data <- tryCatch(
        data.table::fread(project_state$data_path),
        error = function(e) {
          stop("Failed to reload project data: ", conditionMessage(e), call. = FALSE)
        }
      )
      data_validation <- validate_project_state(project_state, data = data)
      project_state <- data_validation$repaired_state
      ctx$saved_plots$configs <- project_state$plot_configs
      ctx$saved_plots$code <- project_state$plot_code
      ctx$saved_plots$metadata <- project_state$plot_metadata
      messages <- c(messages, data_validation$warnings)
      ctx$project_data(data)
      failures <- ctx$rebuild_saved_plots(data)
      if (length(failures)) {
        messages <- c(
          messages,
          paste(
            "Project loaded, but some plots could not be rebuilt:",
            paste(failures, collapse = " | ")
          )
        )
      } else {
        messages <- c(messages, "Project loaded and saved plots rebuilt.")
      }
    } else {
      messages <- c(
        messages,
        "Project loaded, but source data file was not found. Re-upload the data to rebuild plots."
      )
    }

    ctx$set_layout_settings(
      layout_type = project_state$layout_type,
      layout_cols = project_state$layout_cols
    )
    ctx$set_export_settings(
      export_dir = project_state$export_dir,
      export_name = project_state$export_name
    )

    if (!is.null(project_state$current_plot_type) &&
        project_state$current_plot_type %in% plot_types) {
      current_config <- list(
        plot_type = project_state$current_plot_type,
        mappings = default_value(project_state$current_mappings, list()),
        options = default_value(project_state$current_options, list())
      )
      ctx$load_config_into_builder(current_config)
    }

    list(state = project_state, messages = unique(messages[nzchar(messages)]))
  }

  page_data_server("data", ctx)
  page_plot_builder_server("plot_builder", ctx)
  page_layouts_server("layouts", ctx)
  page_export_server("export", ctx)
  page_artifact_library_server("artifact_library", ctx)
  page_project_server("project", ctx)
}
