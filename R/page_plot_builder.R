mapping_control <- function(mapping, data, required = TRUE, selected = NULL, ns = identity) {
  choices <- column_choices(data, include_none = !required)
  if (identical(mapping, "CorrVars")) {
    all_choices <- column_choices(data)
    if (is.null(selected)) {
      selected <- names(data)
    }

    selected <- selected[selected %in% all_choices]
    if (!length(selected)) {
      selected <- all_choices
    }

    return(selectInput(
      ns(mapping_input_id(mapping)),
      mapping_label(mapping),
      choices = all_choices,
      selected = selected,
      multiple = TRUE
    ))
  }

  if (is.null(selected) || !selected %in% choices) {
    if (!required && "" %in% choices) {
      selected <- ""
    } else {
      selected <- choices[1L]
    }
  }

  selectInput(
    ns(mapping_input_id(mapping)),
    mapping_label(mapping),
    choices = choices,
    selected = selected
  )
}

page_plot_builder_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Plots",
    ui_page(
      title = "Plot Builder",
      subtitle = "Create production AutoPlots widgets, save them as artifacts, and assign them to report sections.",
      eyebrow = "Artifacts",
      ui_split_panel(
        side = "left",
        side_content = ui_card(
          title = "Plot Controls",
          selectInput(ns("plot_type"), "Plot Type", choices = plot_type_choices()),
          ui_control_group(
            "Mappings",
            tags$div(
              class = "aq-plot-mapping-controls",
              uiOutput(ns("mapping_inputs"))
            )
          ),
          tags$div(
            class = "aq-plot-builder-primary-actions",
            actionButton(ns("build_plot"), "Build / Refresh Plot", class = "btn-primary"),
            actionButton(ns("add_plot"), "Add Plot", class = "btn-success"),
            actionButton(ns("remove_last_plot"), "Remove Last Plot", class = "btn-secondary")
          ),
          ui_disclosure(
            "Plot Options",
            uiOutput(ns("option_inputs")),
            level = "advanced",
            open = TRUE
          ),
          ui_callout(
            "Preview cadence",
            "Plot preview updates only when Build / Refresh Plot is clicked.",
            status = "info"
          )
        ),
        main = tagList(
          ui_preview_panel(
            title = "Current Plot Preview",
            uiOutput(ns("preview_plot")),
            textOutput(ns("plot_list_message"))
          ),
          ui_workspace_grid(
            columns = "two",
            ui_card(
              title = "Saved Plots",
              selectInput(ns("selected_saved_plot"), "Saved Plot", choices = character()),
              ui_action_row(
                actionButton(ns("load_saved_plot"), "Load Plot for Editing", class = "btn-secondary"),
                actionButton(ns("update_saved_plot"), "Update Saved Plot", class = "btn-primary"),
                actionButton(ns("duplicate_saved_plot"), "Duplicate Plot", class = "btn-secondary")
              ),
              selectInput(ns("section_for_plot"), "Section", choices = character()),
              textInput(ns("new_section_name"), "New Section", value = ""),
              ui_action_row(
                actionButton(ns("assign_plot_section"), "Assign Plot to Section", class = "btn-primary"),
                actionButton(ns("move_plot_up"), "Move Up", class = "btn-secondary"),
                actionButton(ns("move_plot_down"), "Move Down", class = "btn-secondary")
              ),
              uiOutput(ns("saved_plot_list"))
            ),
            tagList(
              ui_code_panel(
                "Current Plot Code",
                verbatimTextOutput(ns("generated_code")),
                collapsed = FALSE
              ),
              ui_code_panel(
                "All Saved Plots Code",
                verbatimTextOutput(ns("saved_plots_code"))
              )
            )
          )
        )
      )
    )
  )
}

page_plot_builder_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ctx$get_current_plot_type <- function() {
      input$plot_type
    }

    ctx$current_plot_options <- function() {
      if (is.null(input$plot_type)) {
        return(list())
      }

      config <- snapshot_plot_config(
        plot_type = input$plot_type,
        input = input,
        mapping_values = ctx$mapping_state$values
      )
      config$options
    }

    remember_mapping <- function(mapping) {
      force(mapping)
      observeEvent(input[[mapping_input_id(mapping)]], {
        ctx$mapping_state$values[[mapping]] <- input[[mapping_input_id(mapping)]]
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

    ctx$load_config_into_builder <- function(config) {
      for (mapping in c("XVar", "YVar", "ZVar", "GroupVar", "CorrVars")) {
        ctx$mapping_state$values[[mapping]] <- config$mappings[[mapping]]
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
      sections <- ctx$saved_sections$sections
      for (section_name in names(sections)) {
        if (plot_name %in% names(sections[[section_name]])) {
          sections[[section_name]][[plot_name]] <- plot
        }
      }

      ctx$saved_sections$sections <- sections
    }

    observe({
      plot_names <- ctx$ordered_plot_names()
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

      section_names <- unique(vapply(ctx$saved_plots$metadata, function(item) {
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

    output$mapping_inputs <- renderUI({
      req(input$plot_type)
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      spec <- plot_spec(input$plot_type)

      tagList(
        lapply(spec$mappings, function(mapping) {
        mapping_control(
          mapping = mapping,
          data = data,
          required = TRUE,
          selected = ctx$mapping_state$values[[mapping]],
          ns = session$ns
        )
      }),
      lapply(spec$optional_mappings, function(mapping) {
        mapping_control(
          mapping = mapping,
          data = data,
          required = FALSE,
          selected = ctx$mapping_state$values[[mapping]],
          ns = session$ns
        )
      })
    )
  })

    output$option_inputs <- renderUI({
      req(input$plot_type)
      spec <- plot_spec(input$plot_type)

      tagList(lapply(spec$options, function(option_name) {
        option_control(option_name, ns = session$ns)
      }))
    })

    observeEvent(input$build_plot, {
      ctx$plot_result(NULL)
      ctx$plot_error(NULL)
      ctx$plot_config(NULL)

      tryCatch({
        config <- snapshot_plot_config(
          plot_type = input$plot_type,
          input = input,
          mapping_values = ctx$mapping_state$values
        )

        data <- ctx$uploaded_data()
        ready <- validate_plot_config_ready(config, data)
        if (!isTRUE(ready)) {
          stop(ready, call. = FALSE)
        }

        ctx$plot_result(build_autoplots_call_from_config(config, data))
        ctx$plot_config(config)
      }, error = function(e) {
        message <- conditionMessage(e)
        if (!nzchar(message)) {
          message <- "AutoPlots returned an error without a message."
        }
        ctx$plot_error(message)
      })
    }, ignoreInit = TRUE)

    observeEvent(input$add_plot, {
      if (is.null(ctx$plot_result()) || is.null(ctx$plot_config()) || !is.null(ctx$plot_error())) {
        ctx$plot_list_message("Build a plot successfully before adding it.")
        return()
      }

      plot_name <- next_plot_name(names(ctx$saved_plots$plots))
      config <- ctx$plot_config()

      ctx$saved_plots$plots[[plot_name]] <- ctx$plot_result()
      ctx$saved_plots$configs[[plot_name]] <- config
      ctx$saved_plots$code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
      ctx$saved_plots$metadata[[plot_name]] <- plot_metadata(
        plot_name = plot_name,
        config = config,
        section_name = "Analysis",
        sort_order = next_sort_order(ctx$saved_plots$metadata)
      )
      ctx$saved_plots$status[[plot_name]] <- list(status = "Ready", message = "")
      ctx$plot_list_message(paste("Added", plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$remove_last_plot, {
      plot_names <- names(ctx$saved_plots$plots)
      if (!length(plot_names)) {
        ctx$plot_list_message("No saved plots to remove.")
        return()
      }

      plot_name <- plot_names[length(plot_names)]
      ctx$remove_artifact_by_id(plot_name)
      ctx$plot_list_message(paste("Removed", plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$load_saved_plot, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$configs)) {
        ctx$plot_list_message("Select a saved plot to load.")
        return()
      }

      config <- ctx$saved_plots$configs[[plot_name]]
      ctx$plot_result(NULL)
      ctx$plot_error(NULL)
      ctx$plot_config(NULL)
      ctx$load_config_into_builder(config)
      ctx$plot_list_message(paste0("Loaded ", plot_name, " for editing. Click Build / Refresh Plot."))
    }, ignoreInit = TRUE)

    observeEvent(input$update_saved_plot, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$plots)) {
        ctx$plot_list_message("Select a saved plot to update.")
        return()
      }

      if (is.null(ctx$plot_result()) || is.null(ctx$plot_config()) || !is.null(ctx$plot_error())) {
        ctx$plot_list_message("Build the edited plot successfully before updating the saved plot.")
        return()
      }

      config <- ctx$plot_config()
      ctx$saved_plots$plots[[plot_name]] <- ctx$plot_result()
      ctx$saved_plots$configs[[plot_name]] <- config
      ctx$saved_plots$code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
      metadata <- ctx$saved_plots$metadata[[plot_name]]
      if (is.null(metadata)) {
        metadata <- plot_metadata(
          plot_name = plot_name,
          config = config,
          section_name = "Analysis",
          sort_order = next_sort_order(ctx$saved_plots$metadata)
        )
      }
      metadata$plot_type <- config$plot_type
      ctx$saved_plots$metadata[[plot_name]] <- metadata
      ctx$saved_plots$status[[plot_name]] <- list(status = "Ready", message = "")
      update_saved_plot_references(plot_name, ctx$plot_result())
      ctx$plot_list_message(paste("Updated", plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$duplicate_saved_plot, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$plots)) {
        ctx$plot_list_message("Select a saved plot to duplicate.")
        return()
      }

      new_plot_name <- next_plot_name(names(ctx$saved_plots$plots))
      config <- ctx$saved_plots$configs[[plot_name]]
      metadata <- ctx$saved_plots$metadata[[plot_name]]
      section_name <- if (is.null(metadata$section_name)) "Analysis" else metadata$section_name
      ctx$saved_plots$plots[[new_plot_name]] <- ctx$saved_plots$plots[[plot_name]]
      ctx$saved_plots$configs[[new_plot_name]] <- config
      ctx$saved_plots$code[[new_plot_name]] <- build_autoplots_assignment_code(new_plot_name, config)
      ctx$saved_plots$metadata[[new_plot_name]] <- plot_metadata(
        plot_name = new_plot_name,
        config = config,
        section_name = section_name,
        sort_order = next_sort_order(ctx$saved_plots$metadata)
      )
      ctx$saved_plots$status[[new_plot_name]] <- ctx$saved_plots$status[[plot_name]]
      ctx$plot_list_message(paste("Duplicated", plot_name, "as", new_plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$assign_plot_section, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$plots)) {
        ctx$plot_list_message("Select a saved plot before assigning a section.")
        return()
      }

      section_name <- selected_value(input$new_section_name)
      if (is.null(section_name)) {
        section_name <- selected_value(input$section_for_plot)
      }
      if (is.null(section_name)) {
        section_name <- "Analysis"
      }

      metadata <- ctx$saved_plots$metadata[[plot_name]]
      if (is.null(metadata)) {
        metadata <- plot_metadata(
          plot_name = plot_name,
          config = ctx$saved_plots$configs[[plot_name]],
          sort_order = next_sort_order(ctx$saved_plots$metadata)
        )
      }

      metadata$section_name <- section_name
      ctx$saved_plots$metadata[[plot_name]] <- metadata
      ctx$plot_list_message(paste("Assigned", plot_name, "to", section_name))
    }, ignoreInit = TRUE)

    move_saved_plot <- function(direction) {
      plot_name <- selected_value(input$selected_saved_plot)
      plot_names <- ctx$ordered_plot_names()
      if (is.null(plot_name) || !plot_name %in% plot_names) {
        ctx$plot_list_message("Select a saved plot to move.")
        return()
      }

      index <- match(plot_name, plot_names)
      swap_index <- index + direction
      if (swap_index < 1L || swap_index > length(plot_names)) {
        ctx$plot_list_message(paste(plot_name, "is already at that end of the order."))
        return()
      }

      swap_name <- plot_names[swap_index]
      current_order <- ctx$saved_plots$metadata[[plot_name]]$sort_order
      swap_order <- ctx$saved_plots$metadata[[swap_name]]$sort_order
      ctx$saved_plots$metadata[[plot_name]]$sort_order <- swap_order
      ctx$saved_plots$metadata[[swap_name]]$sort_order <- current_order
      ctx$plot_list_message(paste("Moved", plot_name))
    }

    observeEvent(input$move_plot_up, {
      move_saved_plot(-1L)
    }, ignoreInit = TRUE)

    observeEvent(input$move_plot_down, {
      move_saved_plot(1L)
    }, ignoreInit = TRUE)

    output$preview_plot <- renderUI({
      if (is.null(input$build_plot) || input$build_plot == 0L) {
        return(tags$div(
          style = "padding: 16px; color: #6B7280;",
          "Configure the plot options, then click Build / Refresh Plot."
        ))
      }

      if (!ctx$has_upload_or_project_data()) {
        return(plot_error_message("No data is available."))
      }

      if (!is.null(ctx$plot_error())) {
        return(plot_error_message(ctx$plot_error()))
      }

      if (is.null(ctx$plot_result())) {
        return(tags$div(
          style = "padding: 16px; color: #6B7280;",
          "Preparing plot preview..."
        ))
      }

      uiOutput(session$ns("preview_plot_widget"))
    })

    output$preview_plot_widget <- renderUI({
      req(ctx$plot_result())
      tags$div(
        style = "min-height: 600px;",
        htmltools::tagList(ctx$plot_result())
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
      ctx$plot_list_message()
    })

    output$saved_plot_list <- renderUI({
      plot_names <- ctx$ordered_plot_names()
      if (!length(plot_names)) {
        return(render_table(
          data.table::data.table(Message = "No saved plots yet."),
          engine = "html",
          searchable = FALSE,
          sortable = FALSE
        ))
      }

      data <- data.table::rbindlist(
        lapply(plot_names, function(plot_name) {
          plot_config_summary(
            name = plot_name,
            config = ctx$saved_plots$configs[[plot_name]],
            metadata = ctx$saved_plots$metadata[[plot_name]],
            status = ctx$saved_plots$status[[plot_name]]
          )
        }),
        use.names = TRUE
      )
      render_table(data, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$saved_plots_code <- renderText({
      build_saved_plots_code(ordered_list_by_names(ctx$saved_plots$code, ctx$ready_plot_names()))
    })
  })
}
