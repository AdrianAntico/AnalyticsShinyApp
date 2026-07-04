server <- function(input, output, session) {
  mapping_state <- reactiveValues(values = list())
  saved_plots <- reactiveValues(
    plots = list(),
    configs = list(),
    code = list(),
    metadata = list(),
    status = list()
  )
  saved_sections <- reactiveValues(
    sections = list()
  )
  plot_result <- reactiveVal(NULL)
  plot_error <- reactiveVal(NULL)
  plot_config <- reactiveVal(NULL)
  plot_list_message <- reactiveVal("")
  export_message <- reactiveVal("")
  project_message <- reactiveVal("")
  project_data <- reactiveVal(NULL)
  project_data_info <- reactiveVal(list(path = NULL, name = NULL))

  layout_cols_value <- function() {
    cols <- input$layout_cols
    if (is.null(cols) || is.na(cols)) {
      return(2)
    }

    as.integer(cols)
  }

  export_name_value <- function() {
    name <- selected_value(input$export_name)
    if (is.null(name)) {
      return(NULL)
    }

    tools::file_path_sans_ext(basename(name))
  }

  export_output_path <- function(export_dir, export_name) {
    file.path(export_dir, paste0(export_name, ".html"))
  }

  current_report_code <- function() {
    ready_names <- ready_plot_names()
    if (!length(ready_names)) {
      stop("No ready saved plots are available. Rebuild or repair saved plots before exporting R code.", call. = FALSE)
    }

    build_report_code(
      saved_code = ordered_list_by_names(saved_plots$code, ready_names),
      section_plot_names = section_plot_names(ready_only = TRUE),
      layout_type = input$layout_type,
      cols = layout_cols_value(),
      export_dir = default_value(selected_value(input$export_dir), "path/to/output"),
      export_name = default_value(export_name_value(), "autoplots_report"),
      data_path = default_value(current_data_path(), "path/to/data.csv")
    )
  }

  ordered_plot_names <- function() {
    ordered_plot_names_from_metadata(saved_plots$metadata)
  }

  ready_plot_names <- function() {
    plot_names <- ordered_plot_names()
    plot_names[vapply(plot_names, function(plot_name) {
      identical(saved_plots$status[[plot_name]]$status, "Ready")
    }, logical(1))]
  }

  ordered_saved_plots <- function() {
    ordered_list_by_names(saved_plots$plots, ready_plot_names())
  }

  section_plot_names <- function(ready_only = FALSE) {
    metadata <- saved_plots$metadata
    if (isTRUE(ready_only)) {
      metadata <- ordered_list_by_names(metadata, ready_plot_names())
    }

    section_plot_names_from_metadata(metadata)
  }

  section_plot_objects <- function() {
    sections <- section_plot_names(ready_only = TRUE)
    lapply(sections, function(plot_names) {
      ordered_list_by_names(saved_plots$plots, plot_names)
    })
  }

  current_data_path <- function() {
    if (!is.null(input$csv_file$datapath)) {
      return(input$csv_file$datapath)
    }

    project_data_info()$path
  }

  current_data_name <- function() {
    if (!is.null(input$csv_file$name)) {
      return(input$csv_file$name)
    }

    project_data_info()$name
  }

  current_project_state <- function() {
    data_path <- current_data_path()
    list(
      app_version = APP_VERSION,
      saved_at = Sys.time(),
      data_path = data_path,
      data_name = current_data_name(),
      original_data_path = data_path,
      plot_configs = saved_plots$configs,
      plot_code = saved_plots$code,
      plot_metadata = saved_plots$metadata,
      layout_type = input$layout_type,
      layout_cols = layout_cols_value(),
      export_dir = selected_value(input$export_dir),
      export_name = export_name_value(),
      current_plot_type = input$plot_type,
      current_mappings = mapping_state$values,
      current_options = if (!is.null(input$plot_type)) {
        config <- snapshot_plot_config(
          plot_type = input$plot_type,
          input = input,
          mapping_values = mapping_state$values
        )
        config$options
      } else {
        list()
      },
      section_names = names(section_plot_names()),
      selected_theme = input$theme
    )
  }

  rebuild_saved_plots <- function(data) {
    plots <- list()
    failures <- character()

    for (plot_name in names(saved_plots$configs)) {
      config <- saved_plots$configs[[plot_name]]
      compatibility <- plot_config_column_status(config, data = data)
      if (!identical(compatibility$status, "Ready")) {
        saved_plots$status[[plot_name]] <- compatibility
        failures <- c(failures, paste0(plot_name, ": ", compatibility$message))
        next
      }

      plot <- tryCatch(
        build_autoplots_call_from_config(config, data),
        error = function(e) {
          saved_plots$status[[plot_name]] <- list(
            status = "Rebuild failed",
            message = conditionMessage(e)
          )
          failures <<- c(failures, paste0(plot_name, ": ", conditionMessage(e)))
          NULL
        }
      )

      if (!is.null(plot)) {
        plots[[plot_name]] <- plot
        saved_plots$status[[plot_name]] <- list(
          status = "Ready",
          message = compatibility$message
        )
      }
    }

    saved_plots$plots <- plots
    failures
  }

  restore_project_settings <- function(project_state) {
    if (!is.null(project_state$layout_type)) {
      updateSelectInput(session, "layout_type", selected = project_state$layout_type)
    }
    if (!is.null(project_state$layout_cols)) {
      updateNumericInput(session, "layout_cols", value = project_state$layout_cols)
    }
    if (!is.null(project_state$export_dir)) {
      updateTextInput(session, "export_dir", value = project_state$export_dir)
    }
    if (!is.null(project_state$export_name)) {
      updateTextInput(session, "export_name", value = project_state$export_name)
    }
    if (!is.null(project_state$current_plot_type) &&
        project_state$current_plot_type %in% plot_types) {
      updateSelectInput(session, "plot_type", selected = project_state$current_plot_type)
    }
  }

  load_project_state <- function(project_state, preferred_data_path = NULL, export_dir_override = NULL) {
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

    saved_plots$configs <- project_state$plot_configs
    saved_plots$code <- project_state$plot_code
    saved_plots$metadata <- project_state$plot_metadata
    saved_plots$status <- list()

    for (plot_name in names(saved_plots$configs)) {
      saved_plots$status[[plot_name]] <- list(
        status = "Needs data",
        message = "Source data is not available."
      )
    }

    saved_plots$plots <- list()
    project_data(NULL)
    project_data_info(list(
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
      saved_plots$configs <- project_state$plot_configs
      saved_plots$code <- project_state$plot_code
      saved_plots$metadata <- project_state$plot_metadata
      messages <- c(messages, data_validation$warnings)
      project_data(data)
      failures <- rebuild_saved_plots(data)
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

    restore_project_settings(project_state)

    if (!is.null(project_state$current_plot_type) &&
        project_state$current_plot_type %in% plot_types) {
      current_config <- list(
        plot_type = project_state$current_plot_type,
        mappings = default_value(project_state$current_mappings, list()),
        options = default_value(project_state$current_options, list())
      )
      load_config_into_builder(current_config)
    }

    list(state = project_state, messages = unique(messages[nzchar(messages)]))
  }

  remember_mapping <- function(mapping) {
    force(mapping)
    observeEvent(input[[mapping_input_id(mapping)]], {
      mapping_state$values[[mapping]] <- input[[mapping_input_id(mapping)]]
    }, ignoreInit = TRUE)
  }

  lapply(c("XVar", "YVar", "ZVar", "GroupVar", "CorrVars"), remember_mapping)

  update_mapping_control <- function(mapping, value) {
    if (identical(mapping, "CorrVars")) {
      updateSelectInput(
        session = session,
        inputId = mapping_input_id(mapping),
        selected = if (is.null(value)) character() else value
      )
      return()
    }

    updateSelectInput(
      session = session,
      inputId = mapping_input_id(mapping),
      selected = if (is.null(value)) "" else value
    )
  }

  update_option_control <- function(option_name, value) {
    opt <- option_registry[[option_name]]
    if (is.null(opt)) {
      return()
    }

    if (is.null(value)) {
      value <- opt$default
    }

    switch(
      opt$type,
      select = updateSelectInput(session, opt$input_id, selected = value),
      text = updateTextInput(session, opt$input_id, value = if (is.null(value)) "" else value),
      checkbox = updateCheckboxInput(session, opt$input_id, value = isTRUE(value)),
      numeric = updateNumericInput(session, opt$input_id, value = value),
      NULL
    )
  }

  load_config_into_builder <- function(config) {
    for (mapping in c("XVar", "YVar", "ZVar", "GroupVar", "CorrVars")) {
      mapping_state$values[[mapping]] <- config$mappings[[mapping]]
    }

    updateSelectInput(session, "plot_type", selected = config$plot_type)

    session$onFlushed(function() {
      for (mapping in active_mappings(config$plot_type)) {
        update_mapping_control(mapping, config$mappings[[mapping]])
      }

      for (option_name in plot_spec(config$plot_type)$options) {
        update_option_control(option_name, config$options[[option_name]])
      }
    }, once = TRUE)
  }

  update_saved_plot_references <- function(plot_name, plot) {
    sections <- saved_sections$sections
    for (section_name in names(sections)) {
      if (plot_name %in% names(sections[[section_name]])) {
        sections[[section_name]][[plot_name]] <- plot
      }
    }

    saved_sections$sections <- sections
  }

  observe({
    plot_names <- ordered_plot_names()
    selected <- isolate(input$selected_saved_plot)
    if (!length(plot_names)) {
      selected <- character()
    } else if (is.null(selected) || !selected %in% plot_names) {
      selected <- plot_names[1L]
    }

    updateSelectInput(
      session = session,
      inputId = "selected_saved_plot",
      choices = plot_names,
      selected = selected
    )

    section_names <- unique(vapply(saved_plots$metadata, function(item) {
      section_name <- item$section_name
      if (is.null(section_name) || !nzchar(section_name)) {
        return("Analysis")
      }

      section_name
    }, character(1)))

    if (!length(section_names)) {
      section_names <- "Analysis"
    }

    selected_section <- isolate(input$section_for_plot)
    if (is.null(selected_section) || !selected_section %in% section_names) {
      selected_section <- section_names[1L]
    }

    updateSelectInput(
      session = session,
      inputId = "section_for_plot",
      choices = section_names,
      selected = selected_section
    )
  })

  uploaded_data <- reactive({
    if (is.null(input$csv_file)) {
      data <- project_data()
      if (!is.null(data)) {
        return(data)
      }

      req(input$csv_file)
    }

    if (!is.null(input$csv_file$size) &&
        input$csv_file$size > MAX_UPLOAD_MB * 1024^2) {
      stop(
        sprintf(
          "Uploaded file is too large. Limit is %s MB.",
          MAX_UPLOAD_MB
        ),
        call. = FALSE
      )
    }

    data.table::fread(input$csv_file$datapath)
  })

  observeEvent(input$csv_file, {
    data <- tryCatch(uploaded_data(), error = function(e) NULL)
    if (!is.null(data) && length(saved_plots$configs)) {
      failures <- rebuild_saved_plots(data)
      if (length(failures)) {
        project_message(paste(
          "Data uploaded, but some saved plots could not be rebuilt:",
          paste(failures, collapse = " | ")
        ))
      } else {
        project_message("Data uploaded and saved plots rebuilt.")
      }
    }
  }, ignoreInit = TRUE)

  output$mapping_inputs <- renderUI({
    req(input$plot_type)
    data <- tryCatch(uploaded_data(), error = function(e) NULL)
    spec <- plot_spec(input$plot_type)

    tagList(
      lapply(spec$mappings, function(mapping) {
        mapping_control(
          mapping = mapping,
          data = data,
          required = TRUE,
          selected = mapping_state$values[[mapping]]
        )
      }),
      lapply(spec$optional_mappings, function(mapping) {
        mapping_control(
          mapping = mapping,
          data = data,
          required = FALSE,
          selected = mapping_state$values[[mapping]]
        )
      })
    )
  })

  output$option_inputs <- renderUI({
    req(input$plot_type)
    spec <- plot_spec(input$plot_type)

    tagList(lapply(spec$options, option_control))
  })

  output$data_summary <- renderText({
    tryCatch({
      data <- uploaded_data()
      if (is.null(input$csv_file)) {
        return(sprintf(
          "%s - loaded from project - %s rows x %s columns",
          default_value(current_data_name(), "(project data)"),
          format(nrow(data), big.mark = ",", scientific = FALSE),
          format(ncol(data), big.mark = ",", scientific = FALSE)
        ))
      }

      sprintf(
        "%s - %s MB - %s rows x %s columns",
        input$csv_file$name,
        file_size_mb(input$csv_file$size),
        format(nrow(data), big.mark = ",", scientific = FALSE),
        format(ncol(data), big.mark = ",", scientific = FALSE)
      )
    }, error = function(e) {
      conditionMessage(e)
    })
  })

  output$data_preview <- renderTable({
    tryCatch(
      head(uploaded_data(), 25),
      error = function(e) {
        data.frame(Message = conditionMessage(e))
      }
    )
  })

  observeEvent(input$build_plot, {
    plot_result(NULL)
    plot_error(NULL)
    plot_config(NULL)

    tryCatch({
      config <- snapshot_plot_config(
        plot_type = input$plot_type,
        input = input,
        mapping_values = mapping_state$values
      )

      data <- uploaded_data()
      ready <- validate_plot_config_ready(config, data)
      if (!isTRUE(ready)) {
        stop(ready, call. = FALSE)
      }

      plot_result(build_autoplots_call_from_config(config, data))
      plot_config(config)
    }, error = function(e) {
      message <- conditionMessage(e)
      if (!nzchar(message)) {
        message <- "AutoPlots returned an error without a message."
      }
      plot_error(message)
    })
  }, ignoreInit = TRUE)

  observeEvent(input$add_plot, {
    if (is.null(plot_result()) || is.null(plot_config()) || !is.null(plot_error())) {
      plot_list_message("Build a plot successfully before adding it.")
      return()
    }

    plot_name <- next_plot_name(names(saved_plots$plots))
    config <- plot_config()

    saved_plots$plots[[plot_name]] <- plot_result()
    saved_plots$configs[[plot_name]] <- config
    saved_plots$code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
    saved_plots$metadata[[plot_name]] <- plot_metadata(
      plot_name = plot_name,
      config = config,
      section_name = "Analysis",
      sort_order = next_sort_order(saved_plots$metadata)
    )
    saved_plots$status[[plot_name]] <- list(status = "Ready", message = "")
    plot_list_message(paste("Added", plot_name))
  }, ignoreInit = TRUE)

  observeEvent(input$remove_last_plot, {
    plot_names <- names(saved_plots$plots)
    if (!length(plot_names)) {
      plot_list_message("No saved plots to remove.")
      return()
    }

    plot_name <- plot_names[length(plot_names)]
    saved_plots$plots[[plot_name]] <- NULL
    saved_plots$configs[[plot_name]] <- NULL
    saved_plots$code[[plot_name]] <- NULL
    saved_plots$metadata[[plot_name]] <- NULL
    saved_plots$status[[plot_name]] <- NULL
    sections <- saved_sections$sections
    for (section_name in names(sections)) {
      sections[[section_name]][[plot_name]] <- NULL
      if (!length(sections[[section_name]])) {
        sections[[section_name]] <- NULL
      }
    }
    saved_sections$sections <- sections
    plot_list_message(paste("Removed", plot_name))
  }, ignoreInit = TRUE)

  observeEvent(input$load_saved_plot, {
    plot_name <- selected_value(input$selected_saved_plot)
    if (is.null(plot_name) || !plot_name %in% names(saved_plots$configs)) {
      plot_list_message("Select a saved plot to load.")
      return()
    }

    config <- saved_plots$configs[[plot_name]]
    plot_result(NULL)
    plot_error(NULL)
    plot_config(NULL)
    load_config_into_builder(config)
    plot_list_message(paste0("Loaded ", plot_name, " for editing. Click Build / Refresh Plot."))
  }, ignoreInit = TRUE)

  observeEvent(input$update_saved_plot, {
    plot_name <- selected_value(input$selected_saved_plot)
    if (is.null(plot_name) || !plot_name %in% names(saved_plots$plots)) {
      plot_list_message("Select a saved plot to update.")
      return()
    }

    if (is.null(plot_result()) || is.null(plot_config()) || !is.null(plot_error())) {
      plot_list_message("Build the edited plot successfully before updating the saved plot.")
      return()
    }

    config <- plot_config()
    saved_plots$plots[[plot_name]] <- plot_result()
    saved_plots$configs[[plot_name]] <- config
    saved_plots$code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
    metadata <- saved_plots$metadata[[plot_name]]
    if (is.null(metadata)) {
      metadata <- plot_metadata(
        plot_name = plot_name,
        config = config,
        section_name = "Analysis",
        sort_order = next_sort_order(saved_plots$metadata)
      )
    }
    metadata$plot_type <- config$plot_type
    saved_plots$metadata[[plot_name]] <- metadata
    saved_plots$status[[plot_name]] <- list(status = "Ready", message = "")
    update_saved_plot_references(plot_name, plot_result())
    plot_list_message(paste("Updated", plot_name))
  }, ignoreInit = TRUE)

  observeEvent(input$duplicate_saved_plot, {
    plot_name <- selected_value(input$selected_saved_plot)
    if (is.null(plot_name) || !plot_name %in% names(saved_plots$plots)) {
      plot_list_message("Select a saved plot to duplicate.")
      return()
    }

    new_plot_name <- next_plot_name(names(saved_plots$plots))
    config <- saved_plots$configs[[plot_name]]
    metadata <- saved_plots$metadata[[plot_name]]
    section_name <- if (is.null(metadata$section_name)) "Analysis" else metadata$section_name
    saved_plots$plots[[new_plot_name]] <- saved_plots$plots[[plot_name]]
    saved_plots$configs[[new_plot_name]] <- config
    saved_plots$code[[new_plot_name]] <- build_autoplots_assignment_code(new_plot_name, config)
    saved_plots$metadata[[new_plot_name]] <- plot_metadata(
      plot_name = new_plot_name,
      config = config,
      section_name = section_name,
      sort_order = next_sort_order(saved_plots$metadata)
    )
    saved_plots$status[[new_plot_name]] <- saved_plots$status[[plot_name]]
    plot_list_message(paste("Duplicated", plot_name, "as", new_plot_name))
  }, ignoreInit = TRUE)

  observeEvent(input$assign_section, {
    plot_names <- names(saved_plots$configs)
    if (!length(plot_names)) {
      plot_list_message("Add at least one saved plot before assigning a section.")
      return()
    }

    section_name <- selected_value(input$section_name)
    if (is.null(section_name)) {
      section_name <- "Analysis"
    }

    sections <- saved_sections$sections
    sections[[section_name]] <- ordered_list_by_names(saved_plots$plots, plot_names)
    saved_sections$sections <- sections
    for (plot_name in plot_names) {
      metadata <- saved_plots$metadata[[plot_name]]
      if (is.null(metadata)) {
        metadata <- plot_metadata(
          plot_name = plot_name,
          config = saved_plots$configs[[plot_name]],
          sort_order = next_sort_order(saved_plots$metadata)
        )
      }
      metadata$section_name <- section_name
      saved_plots$metadata[[plot_name]] <- metadata
    }
    plot_list_message(paste("Assigned saved plots to", section_name))
  }, ignoreInit = TRUE)

  observeEvent(input$assign_plot_section, {
    plot_name <- selected_value(input$selected_saved_plot)
    if (is.null(plot_name) || !plot_name %in% names(saved_plots$plots)) {
      plot_list_message("Select a saved plot before assigning a section.")
      return()
    }

    section_name <- selected_value(input$new_section_name)
    if (is.null(section_name)) {
      section_name <- selected_value(input$section_for_plot)
    }
    if (is.null(section_name)) {
      section_name <- "Analysis"
    }

    metadata <- saved_plots$metadata[[plot_name]]
    if (is.null(metadata)) {
      metadata <- plot_metadata(
        plot_name = plot_name,
        config = saved_plots$configs[[plot_name]],
        sort_order = next_sort_order(saved_plots$metadata)
      )
    }

    metadata$section_name <- section_name
    saved_plots$metadata[[plot_name]] <- metadata
    plot_list_message(paste("Assigned", plot_name, "to", section_name))
  }, ignoreInit = TRUE)

  observeEvent(input$save_project, {
    project_message("")

    tryCatch({
      project_state <- current_project_state()
      output_path <- save_project_state(project_state, input$project_path)
      project_message(paste("Saved project to", output_path))
    }, error = function(e) {
      project_message(paste("Save project failed:", conditionMessage(e)))
    })
  }, ignoreInit = TRUE)

  observeEvent(input$load_project, {
    project_message("")

    tryCatch({
      project_path <- normalize_project_path(input$project_path)
      if (!file.exists(project_path)) {
        stop("Project file does not exist.", call. = FALSE)
      }

      project_state <- readRDS(project_path)
      loaded <- load_project_state(project_state)
      project_message(paste(loaded$messages, collapse = " "))
    }, error = function(e) {
      project_message(paste("Load project failed:", conditionMessage(e)))
    })
  }, ignoreInit = TRUE)

  observeEvent(input$save_bundle, {
    project_message("")

    tryCatch({
      bundle_dir <- normalize_bundle_dir(input$bundle_dir)
      bundle_paths <- ensure_bundle_dirs(bundle_dir)
      project_state <- current_project_state()
      source_data_path <- current_data_path()

      if (!is.null(source_data_path) && file.exists(source_data_path)) {
        file.copy(
          from = source_data_path,
          to = bundle_paths$data_path,
          overwrite = TRUE
        )
        project_state$original_data_path <- source_data_path
        project_state$data_path <- bundle_paths$data_path
        project_state$data_name <- "data.csv"
      } else if (!is.null(project_data())) {
        data.table::fwrite(project_data(), bundle_paths$data_path)
        project_state$data_path <- bundle_paths$data_path
        project_state$data_name <- "data.csv"
      } else {
        stop("No source data is available to bundle.", call. = FALSE)
      }

      project_state$export_dir <- bundle_paths$exports_dir
      saveRDS(project_state, bundle_paths$project_path)
      updateTextInput(session, "export_dir", value = bundle_paths$exports_dir)
      project_data_info(list(path = bundle_paths$data_path, name = "data.csv"))
      project_message(paste("Saved project bundle to", bundle_paths$bundle_dir))
    }, error = function(e) {
      project_message(paste("Save bundle failed:", conditionMessage(e)))
    })
  }, ignoreInit = TRUE)

  observeEvent(input$load_bundle, {
    project_message("")

    tryCatch({
      bundle_dir <- normalize_bundle_dir(input$bundle_dir)
      if (!dir.exists(bundle_dir)) {
        stop("Project bundle directory does not exist.", call. = FALSE)
      }

      bundle_dir <- normalizePath(bundle_dir, winslash = "/", mustWork = TRUE)
      project_path <- file.path(bundle_dir, "project.rds")
      data_path <- file.path(bundle_dir, "data.csv")
      exports_dir <- file.path(bundle_dir, "exports")

      if (!file.exists(project_path)) {
        stop("Project bundle is missing project.rds.", call. = FALSE)
      }
      if (!file.exists(data_path)) {
        stop("Project bundle is missing data.csv.", call. = FALSE)
      }
      if (!dir.exists(exports_dir)) {
        dir.create(exports_dir, recursive = TRUE, showWarnings = FALSE)
      }
      if (!dir.exists(exports_dir)) {
        stop("Project bundle exports directory could not be created.", call. = FALSE)
      }

      project_state <- readRDS(project_path)
      loaded <- load_project_state(
        project_state = project_state,
        preferred_data_path = normalizePath(data_path, winslash = "/", mustWork = TRUE),
        export_dir_override = normalizePath(exports_dir, winslash = "/", mustWork = TRUE)
      )
      project_message(paste(
        c("Loaded project bundle.", loaded$messages),
        collapse = " "
      ))
    }, error = function(e) {
      project_message(paste("Load bundle failed:", conditionMessage(e)))
    })
  }, ignoreInit = TRUE)

  move_saved_plot <- function(direction) {
    plot_name <- selected_value(input$selected_saved_plot)
    plot_names <- ordered_plot_names()
    if (is.null(plot_name) || !plot_name %in% plot_names) {
      plot_list_message("Select a saved plot to move.")
      return()
    }

    index <- match(plot_name, plot_names)
    swap_index <- index + direction
    if (swap_index < 1L || swap_index > length(plot_names)) {
      plot_list_message(paste(plot_name, "is already at that end of the order."))
      return()
    }

    swap_name <- plot_names[swap_index]
    current_order <- saved_plots$metadata[[plot_name]]$sort_order
    swap_order <- saved_plots$metadata[[swap_name]]$sort_order
    saved_plots$metadata[[plot_name]]$sort_order <- swap_order
    saved_plots$metadata[[swap_name]]$sort_order <- current_order
    plot_list_message(paste("Moved", plot_name))
  }

  observeEvent(input$move_plot_up, {
    move_saved_plot(-1L)
  }, ignoreInit = TRUE)

  observeEvent(input$move_plot_down, {
    move_saved_plot(1L)
  }, ignoreInit = TRUE)

  current_report <- reactive({
    if (!length(names(saved_plots$plots))) {
      return(NULL)
    }

    cols <- layout_cols_value()

    if (identical(input$layout_type, "Sections")) {
      sections <- section_plot_objects()
      if (!length(names(sections))) {
        return(NULL)
      }

      return(AutoPlots::display_plots_sections(
        sections = sections,
        cols = cols
      ))
    }

    AutoPlots::display_plots_grid(
      plots = ordered_saved_plots(),
      cols = cols
    )
  })

  observeEvent(input$export_html, {
    export_message("")

    result <- export_html_service(
      report = tryCatch(current_report(), error = function(e) NULL),
      export_dir = input$export_dir,
      export_name = input$export_name
    )
    export_message(service_result_message(result))
  }, ignoreInit = TRUE)

  observeEvent(input$export_code, {
    export_message("")

    code <- tryCatch(current_report_code(), error = function(e) NULL)
    result <- export_code_service(
      code = code,
      export_dir = input$export_dir,
      export_name = input$export_name
    )
    export_message(service_result_message(result))
  }, ignoreInit = TRUE)

  observeEvent(input$export_all, {
    export_message("")

    result <- export_all_service(
      report = tryCatch(current_report(), error = function(e) NULL),
      code = tryCatch(current_report_code(), error = function(e) NULL),
      export_dir = input$export_dir,
      export_name = input$export_name
    )
    export_message(service_result_message(result))
  }, ignoreInit = TRUE)

  output$preview_plot <- renderUI({
    if (is.null(input$build_plot) || input$build_plot == 0L) {
      return(tags$div(
        style = "padding: 16px; color: #6B7280;",
        "Configure the plot options, then click Build / Refresh Plot."
      ))
    }

    if (is.null(input$csv_file) && is.null(project_data())) {
      return(plot_error_message("No data is available."))
    }

    if (!is.null(input$csv_file$size) &&
        input$csv_file$size > MAX_UPLOAD_MB * 1024^2) {
      return(plot_error_message(sprintf(
        "Uploaded file is too large. Limit is %s MB.",
        MAX_UPLOAD_MB
      )))
    }

    if (!is.null(plot_error())) {
      return(plot_error_message(plot_error()))
    }

    if (is.null(plot_result())) {
      return(tags$div(
        style = "padding: 16px; color: #6B7280;",
        "Preparing plot preview..."
      ))
    }

    uiOutput("preview_plot_widget")
  })

  output$preview_plot_widget <- renderUI({
    req(plot_result())
    tags$div(
      style = "min-height: 600px;",
      htmltools::tagList(plot_result())
    )
  })

  output$generated_code <- renderText({
    req(input$plot_type)

    build_autoplots_code(
      plot_type = input$plot_type,
      input = input
    )
  })

  output$plot_list_message <- renderText({
    plot_list_message()
  })

  output$project_message <- renderText({
    project_message()
  })

  output$saved_plot_list <- renderTable({
    plot_names <- ordered_plot_names()
    if (!length(plot_names)) {
      return(data.frame(Message = "No saved plots yet."))
    }

    do.call(
      rbind,
      lapply(plot_names, function(plot_name) {
        plot_config_summary(
          name = plot_name,
          config = saved_plots$configs[[plot_name]],
          metadata = saved_plots$metadata[[plot_name]],
          status = saved_plots$status[[plot_name]]
        )
      })
    )
  })

  output$saved_plots_code <- renderText({
    build_saved_plots_code(ordered_list_by_names(saved_plots$code, ready_plot_names()))
  })

  output$saved_layout_preview <- renderUI({
    if (identical(input$layout_type, "Sections")) {
      if (!length(names(section_plot_names(ready_only = TRUE)))) {
        return(tags$div(
          style = "padding: 16px; color: #6B7280;",
          "Assign ready saved plots to a section to preview a section layout."
        ))
      }

      return(tryCatch(
        htmltools::tagList(current_report()),
        error = function(e) {
          layout_error_message(conditionMessage(e))
        }
      ))
    }

    if (!length(names(saved_plots$plots))) {
      return(tags$div(
        style = "padding: 16px; color: #6B7280;",
        "Add plots from the Plots tab to preview a layout."
      ))
    }

    tryCatch(
      htmltools::tagList(current_report()),
      error = function(e) {
        layout_error_message(conditionMessage(e))
      }
    )
  })

  output$layout_code <- renderText({
    build_layout_code(
      plot_names = ordered_plot_names(),
      section_plot_names = section_plot_names(),
      layout_type = input$layout_type,
      cols = layout_cols_value()
    )
  })

  output$report_code <- renderText({
    tryCatch(
      current_report_code(),
      error = function(e) {
        build_report_code(
          saved_code = ordered_list_by_names(saved_plots$code, ready_plot_names()),
          section_plot_names = section_plot_names(ready_only = TRUE),
          layout_type = input$layout_type,
          cols = layout_cols_value(),
          export_dir = default_value(selected_value(input$export_dir), "path/to/output"),
          export_name = default_value(export_name_value(), "autoplots_report"),
          data_path = default_value(current_data_path(), "path/to/data.csv")
        )
      }
    )
  })

  output$export_message <- renderText({
    export_message()
  })
}
