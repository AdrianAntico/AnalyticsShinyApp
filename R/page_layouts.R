page_layouts_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Layout",
    h4("Layout"),
    sidebarLayout(
      sidebarPanel(
        selectInput(ns("layout_type"), "Layout", choices = c("Grid", "Sections"), selected = "Grid"),
        numericInput(ns("layout_cols"), "Columns", value = 2, min = 1, max = 4, step = 1),
        textInput(ns("section_name"), "Section Name", value = "Analysis"),
        actionButton(ns("assign_section"), "Assign All Saved Plots to Section"),
        tags$hr(),
        ui_card(
          title = "Add Text Block",
          textInput(ns("text_artifact_label"), "Label", value = "Text Block"),
          textInput(ns("text_artifact_section"), "Section", value = "Analysis"),
          selectInput(
            ns("text_artifact_subtype"),
            "Subtype",
            choices = c("markdown", "note", "summary", "caveat", "methodology"),
            selected = "markdown"
          ),
          textAreaInput(
            ns("text_artifact_content"),
            "Content",
            value = "",
            rows = 6,
            width = "100%"
          ),
          ui_action_row(
            actionButton(ns("add_text_artifact"), "Add Text Artifact", class = "btn-primary"),
            actionButton(ns("preview_text_artifact"), "Preview Text Artifact", class = "btn-secondary")
          ),
          textOutput(ns("text_artifact_message"))
        ),
        tags$hr(),
        ui_card(
          title = "Add Table Block",
          textInput(ns("table_artifact_label"), "Label", value = "Table Block"),
          textInput(ns("table_artifact_section"), "Section", value = "Analysis"),
          selectInput(
            ns("table_artifact_type"),
            "Table Type",
            choices = c("Data Preview", "Summary Statistics", "Frequency Table"),
            selected = "Data Preview"
          ),
          uiOutput(ns("table_artifact_vars_ui")),
          numericInput(ns("table_artifact_max_rows"), "Max Rows", value = 25, min = 1, step = 1),
          numericInput(ns("table_artifact_page_size"), "Page Size", value = 10, min = 1, step = 1),
          selectInput(
            ns("table_artifact_theme"),
            "Theme",
            choices = c("auto", "light", "dark", "pimp"),
            selected = "auto"
          ),
          ui_action_row(
            actionButton(ns("preview_table_artifact"), "Preview Table", class = "btn-secondary"),
            actionButton(ns("add_table_artifact"), "Add Table Artifact", class = "btn-primary")
          ),
          tags$hr(),
          selectInput(ns("selected_table_artifact"), "Saved Table", choices = character()),
          ui_action_row(
            actionButton(ns("export_table_artifact_csv"), "Export CSV", class = "btn-secondary"),
            actionButton(ns("export_table_artifact_xlsx"), "Export XLSX", class = "btn-secondary"),
            actionButton(ns("export_all_tables_xlsx"), "Export All Tables XLSX", class = "btn-success")
          ),
          textOutput(ns("table_artifact_message"))
        )
      ),
      mainPanel(
        uiOutput(ns("text_artifact_preview")),
        uiOutput(ns("table_artifact_preview")),
        tags$hr(),
        h4("Artifact Summary"),
        tableOutput(ns("artifact_summary")),
        tags$hr(),
        uiOutput(ns("saved_layout_preview")),
        tags$hr(),
        h4("Layout Code"),
        verbatimTextOutput(ns("layout_code")),
        tags$hr(),
        h4("Report Code"),
        verbatimTextOutput(ns("report_code"))
      )
    )
  )
}

page_layouts_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ctx$layout_cols_value <- function() {
      cols <- input$layout_cols
      if (is.null(cols) || is.na(cols)) {
        return(2)
      }

      as.integer(cols)
    }

    ctx$get_layout_type <- function() {
      input$layout_type
    }

    ctx$set_layout_settings <- function(layout_type = NULL, layout_cols = NULL) {
      if (!is.null(layout_type)) {
        updateSelectInput(session, "layout_type", selected = layout_type)
      }
      if (!is.null(layout_cols)) {
        updateNumericInput(session, "layout_cols", value = layout_cols)
      }
    }

    text_artifact_from_input <- function(artifact_id = "text_preview", order = NA_integer_) {
      label <- selected_value(input$text_artifact_label) %||% artifact_id
      section <- selected_value(input$text_artifact_section) %||% "Analysis"
      subtype <- selected_value(input$text_artifact_subtype) %||% "markdown"

      create_artifact(
        artifact_id = artifact_id,
        artifact_type = "text",
        label = label,
        source_module = "manual_text",
        content = input$text_artifact_content %||% "",
        config = list(format = "markdown"),
        metadata = list(subtype = subtype),
        section = section,
        order = order,
        status = "ready"
      )
    }

    table_artifact_vars <- function() {
      vars <- input$table_artifact_vars
      if (is.null(vars) || !length(vars) || any(!nzchar(vars))) {
        return(NULL)
      }

      vars
    }

    table_artifact_type_value <- function() {
      selected_value(input$table_artifact_type) %||% "Data Preview"
    }

    table_artifact_max_rows_value <- function() {
      value <- suppressWarnings(as.integer(input$table_artifact_max_rows))
      if (is.na(value) || value < 1L) {
        return(25L)
      }

      value
    }

    table_artifact_page_size_value <- function() {
      value <- suppressWarnings(as.integer(input$table_artifact_page_size))
      if (is.na(value) || value < 1L) {
        return(10L)
      }

      value
    }

    build_table_artifact_data <- function(data, table_type, vars) {
      if (is.null(data)) {
        stop("Upload data before previewing or adding a table artifact.", call. = FALSE)
      }

      if (!is.null(vars)) {
        missing_vars <- setdiff(vars, names(data))
        if (length(missing_vars)) {
          stop("Selected columns are missing: ", paste(missing_vars, collapse = ", "), call. = FALSE)
        }
      }

      switch(
        table_type,
        "Summary Statistics" = build_summary_statistics_table(data, vars = vars),
        "Frequency Table" = build_frequency_table(data, vars = vars),
        build_data_preview_table(
          data,
          vars = vars,
          max_rows = table_artifact_max_rows_value()
        )
      )
    }

    table_artifact_code <- function(table_type, vars) {
      vars_code <- if (is.null(vars)) {
        "NULL"
      } else {
        paste0("c(", paste(vapply(vars, r_string, character(1)), collapse = ", "), ")")
      }

      switch(
        table_type,
        "Summary Statistics" = paste0("build_summary_statistics_table(data, vars = ", vars_code, ")"),
        "Frequency Table" = paste0("build_frequency_table(data, vars = ", vars_code, ")"),
        paste0(
          "build_data_preview_table(data, vars = ",
          vars_code,
          ", max_rows = ",
          table_artifact_max_rows_value(),
          ")"
        )
      )
    }

    table_artifact_from_input <- function(artifact_id = "table_preview", order = NA_integer_) {
      data <- tryCatch(ctx$uploaded_data(), error = function(e) {
        stop(conditionMessage(e), call. = FALSE)
      })
      table_type <- table_artifact_type_value()
      vars <- table_artifact_vars()
      table_data <- build_table_artifact_data(data, table_type, vars)
      label <- selected_value(input$table_artifact_label) %||% artifact_id
      section <- selected_value(input$table_artifact_section) %||% "Analysis"
      theme <- selected_value(input$table_artifact_theme) %||% "auto"
      page_size <- table_artifact_page_size_value()

      create_artifact(
        artifact_id = artifact_id,
        artifact_type = "table",
        label = label,
        source_module = "table_builder",
        object = table_data,
        config = list(
          table_type = table_type,
          vars = vars,
          max_rows = table_artifact_max_rows_value(),
          page_size = page_size,
          engine = "reactable",
          theme = theme
        ),
        code = table_artifact_code(table_type, vars),
        metadata = list(
          n_rows = nrow(table_data),
          n_cols = ncol(table_data)
        ),
        section = section,
        order = order,
        status = "ready"
      )
    }

    observeEvent(input$assign_section, {
      plot_names <- names(ctx$saved_plots$configs)
      if (!length(plot_names)) {
        ctx$plot_list_message("Add at least one saved plot before assigning a section.")
        return()
      }

      section_name <- selected_value(input$section_name)
      if (is.null(section_name)) {
        section_name <- "Analysis"
      }

      sections <- ctx$saved_sections$sections
      sections[[section_name]] <- ordered_list_by_names(ctx$saved_plots$plots, plot_names)
      ctx$saved_sections$sections <- sections
      for (plot_name in plot_names) {
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
      }
      ctx$plot_list_message(paste("Assigned saved plots to", section_name))
    }, ignoreInit = TRUE)

    observeEvent(input$preview_text_artifact, {
      artifact <- text_artifact_from_input(order = ctx$next_artifact_order())
      validation <- validate_artifact(artifact)
      if (!identical(validation$status, "success")) {
        ctx$text_artifact_preview(NULL)
        ctx$text_artifact_message(service_result_message(validation))
        return()
      }

      ctx$text_artifact_preview(artifact)
      ctx$text_artifact_message("Previewing text artifact.")
    }, ignoreInit = TRUE)

    observeEvent(input$add_text_artifact, {
      artifact_id <- ctx$next_text_artifact_id()
      artifact <- text_artifact_from_input(
        artifact_id = artifact_id,
        order = ctx$next_artifact_order()
      )
      validation <- validate_artifact(artifact)
      if (!identical(validation$status, "success")) {
        ctx$text_artifact_message(service_result_message(validation))
        return()
      }

      ctx$saved_text_artifacts$artifacts[[artifact_id]] <- artifact
      ctx$text_artifact_preview(artifact)
      ctx$text_artifact_message(paste("Added text artifact", artifact_id))
    }, ignoreInit = TRUE)

    output$table_artifact_vars_ui <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      choices <- if (is.null(data)) character() else names(data)

      selectInput(
        session$ns("table_artifact_vars"),
        "Columns",
        choices = choices,
        selected = choices,
        multiple = TRUE
      )
    })

    observeEvent(input$preview_table_artifact, {
      artifact <- tryCatch(
        table_artifact_from_input(order = ctx$next_artifact_order()),
        error = function(e) {
          ctx$table_artifact_preview(NULL)
          ctx$table_artifact_message(conditionMessage(e))
          NULL
        }
      )
      if (is.null(artifact)) {
        return()
      }

      validation <- validate_artifact(artifact)
      if (!identical(validation$status, "success")) {
        ctx$table_artifact_preview(NULL)
        ctx$table_artifact_message(service_result_message(validation))
        return()
      }

      ctx$table_artifact_preview(artifact)
      ctx$table_artifact_message("Previewing table artifact.")
    }, ignoreInit = TRUE)

    observeEvent(input$add_table_artifact, {
      artifact_id <- ctx$next_table_artifact_id()
      artifact <- tryCatch(
        table_artifact_from_input(
          artifact_id = artifact_id,
          order = ctx$next_artifact_order()
        ),
        error = function(e) {
          ctx$table_artifact_message(conditionMessage(e))
          NULL
        }
      )
      if (is.null(artifact)) {
        return()
      }

      validation <- validate_artifact(artifact)
      if (!identical(validation$status, "success")) {
        ctx$table_artifact_message(service_result_message(validation))
        return()
      }

      ctx$saved_table_artifacts$artifacts[[artifact_id]] <- artifact
      ctx$table_artifact_preview(artifact)
      ctx$table_artifact_message(paste("Added table artifact", artifact_id))
    }, ignoreInit = TRUE)

    observe({
      table_ids <- names(ctx$saved_table_artifacts$artifacts)
      selected <- isolate(input$selected_table_artifact)
      if (!length(table_ids)) {
        selected <- character()
      } else if (is.null(selected) || !selected %in% table_ids) {
        selected <- table_ids[1L]
      }

      updateSelectInput(
        session = session,
        inputId = "selected_table_artifact",
        choices = table_ids,
        selected = selected
      )
    })

    selected_table_artifact <- function() {
      artifact_id <- selected_value(input$selected_table_artifact)
      if (is.null(artifact_id) || !artifact_id %in% names(ctx$saved_table_artifacts$artifacts)) {
        stop("Select a saved table artifact first.", call. = FALSE)
      }

      ctx$saved_table_artifacts$artifacts[[artifact_id]]
    }

    observeEvent(input$export_table_artifact_csv, {
      result <- tryCatch(
        export_table_csv(
          artifact_or_data = selected_table_artifact(),
          path = ctx$get_export_dir(),
          name = selected_value(input$selected_table_artifact) %||% "table"
        ),
        error = function(e) {
          service_result(status = "error", errors = conditionMessage(e))
        }
      )

      ctx$table_artifact_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$export_table_artifact_xlsx, {
      result <- tryCatch(
        export_table_xlsx(
          artifacts_or_tables = selected_table_artifact(),
          path = ctx$get_export_dir(),
          name = selected_value(input$selected_table_artifact) %||% "table"
        ),
        error = function(e) {
          service_result(status = "error", errors = conditionMessage(e))
        }
      )

      ctx$table_artifact_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$export_all_tables_xlsx, {
      artifacts <- ctx$saved_table_artifacts$artifacts
      if (!length(artifacts)) {
        ctx$table_artifact_message("No table artifacts are available to export.")
        return()
      }

      table_names <- vapply(names(artifacts), function(artifact_id) {
        artifacts[[artifact_id]]$label %||% artifact_id
      }, character(1))
      names(artifacts) <- table_names

      result <- export_table_xlsx(
        artifacts_or_tables = artifacts,
        path = ctx$get_export_dir(),
        name = "table_artifacts"
      )

      ctx$table_artifact_message(service_result_message(result))
    }, ignoreInit = TRUE)

    output$text_artifact_message <- renderText({
      ctx$text_artifact_message()
    })

    output$text_artifact_preview <- renderUI({
      artifact <- ctx$text_artifact_preview()
      if (is.null(artifact)) {
        return(NULL)
      }

      render_artifact(artifact)
    })

    output$table_artifact_message <- renderText({
      ctx$table_artifact_message()
    })

    output$table_artifact_preview <- renderUI({
      artifact <- ctx$table_artifact_preview()
      if (is.null(artifact)) {
        return(NULL)
      }

      render_artifact(artifact)
    })

    output$artifact_summary <- renderTable({
      combined_artifact_summary(ctx$plot_artifacts(), ctx$text_artifacts(), ctx$table_artifacts())
    })

    output$saved_layout_preview <- renderUI({
      if (identical(input$layout_type, "Sections")) {
        if (!length(ctx$all_report_artifacts())) {
          return(tags$div(
            style = "padding: 16px; color: #6B7280;",
            "Add ready plots, text artifacts, or table artifacts to preview a section layout."
          ))
        }

        return(tryCatch(
          htmltools::tagList(ctx$mixed_report_preview()),
          error = function(e) {
            layout_error_message(conditionMessage(e))
          }
        ))
      }

      if (!length(ctx$all_report_artifacts())) {
        return(tags$div(
          style = "padding: 16px; color: #6B7280;",
          "Add plots from the Plots tab, text artifacts, or table artifacts to preview a layout."
        ))
      }

      tryCatch(
        htmltools::tagList(ctx$mixed_report_preview()),
        error = function(e) {
          layout_error_message(conditionMessage(e))
        }
      )
    })

    output$layout_code <- renderText({
      build_layout_code(
        plot_names = ctx$ordered_plot_names(),
        section_plot_names = ctx$section_plot_names(),
        layout_type = input$layout_type,
        cols = ctx$layout_cols_value()
      )
    })

    output$report_code <- renderText({
      code <- tryCatch(
        ctx$current_report_code(),
        error = function(e) {
          build_report_code(
            saved_code = ordered_list_by_names(ctx$saved_plots$code, ctx$ready_plot_names()),
            section_plot_names = ctx$section_plot_names(ready_only = TRUE),
            layout_type = input$layout_type,
            cols = ctx$layout_cols_value(),
            export_dir = default_value(selected_value(ctx$get_export_dir()), "path/to/output"),
            export_name = default_value(ctx$export_name_value(), "autoplots_report"),
            data_path = default_value(ctx$current_data_path(), "path/to/data.csv")
          )
        }
      )

      if (length(ctx$text_artifacts()) || length(ctx$table_artifacts())) {
        code <- paste(
          code,
          "# TODO: Mixed text/table artifact export/report code generation is not fully supported yet.",
          sep = "\n\n"
        )
      }

      code
    })
  })
}
