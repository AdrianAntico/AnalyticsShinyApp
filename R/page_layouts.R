page_layouts_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Layout",
    ui_page(
      title = "Layout Studio",
      subtitle = "Compose artifacts, text blocks, table blocks, and report plans into reusable report structures.",
      eyebrow = "Reports",
      ui_split_panel(
        side = "left",
        side_content = tagList(
          ui_card(
            title = "Layout Controls",
            selectInput(ns("layout_type"), "Layout", choices = c("Grid", "Sections"), selected = "Grid"),
            numericInput(ns("layout_cols"), "Columns", value = 2, min = 1, max = 4, step = 1),
            textInput(ns("section_name"), "Section Name", value = "Analysis"),
            ui_action_row(
              actionButton(ns("assign_section"), "Assign All Saved Plots to Section", class = "btn-primary")
            )
          ),
          ui_disclosure(
            "Add Text Block",
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
            textOutput(ns("text_artifact_message")),
            level = "common"
          ),
          ui_disclosure(
            "Add Table Block",
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
            textOutput(ns("table_artifact_message")),
            level = "artifact"
          ),
          ui_disclosure(
            "Report Plans",
            uiOutput(ns("report_plan_summary")),
            selectInput(ns("selected_report_plan"), "Plan", choices = character()),
            uiOutput(ns("selected_report_plan_status")),
            uiOutput(ns("active_report_plan_indicator")),
            ui_action_row(
              actionButton(ns("preview_report_plan"), "Preview Plan", class = "btn-secondary"),
              actionButton(ns("apply_report_plan"), "Apply Plan", class = "btn-primary")
            ),
            textOutput(ns("report_plan_message")),
            level = "artifact",
            open = TRUE
          ),
          ui_disclosure(
            "Plan Editor",
            uiOutput(ns("report_plan_editor")),
            level = "advanced"
          )
        ),
        main = tagList(
          ui_workspace_grid(
            columns = "two",
            ui_preview_panel(
              title = "Text Artifact Preview",
              uiOutput(ns("text_artifact_preview"))
            ),
            ui_preview_panel(
              title = "Table Artifact Preview",
              uiOutput(ns("table_artifact_preview"))
            )
          ),
          ui_card(
            title = "Artifact Summary",
            uiOutput(ns("artifact_summary"))
          ),
          ui_preview_panel(
            title = "Report Plan Preview",
            uiOutput(ns("report_plan_preview"))
          ),
          ui_preview_panel(
            title = "Saved Layout Preview",
            uiOutput(ns("saved_layout_preview"))
          ),
          ui_workspace_grid(
            columns = "two",
            ui_code_panel(
              "Layout Code",
              verbatimTextOutput(ns("layout_code")),
              collapsed = FALSE
            ),
            ui_code_panel(
              "Report Code",
              verbatimTextOutput(ns("report_code"))
            )
          )
        )
      )
    )
  )
}

page_layouts_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    report_plan_message <- reactiveVal("")
    report_plan_preview <- reactiveVal(NULL)

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

    output$artifact_summary <- renderUI({
      render_table(
        ctx$combined_artifact_summary(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    selected_report_plan <- function() {
      plan_id <- selected_value(input$selected_report_plan)
      if (is.null(plan_id) || length(plan_id) != 1L || !plan_id %in% names(ctx$report_plan_state$plans)) {
        return(NULL)
      }

      ctx$report_plan_state$plans[[plan_id]]
    }

    ordered_plan_sections <- function(plan) {
      sections <- plan$sections %||% list()
      if (!length(sections)) {
        return(list())
      }

      section_order <- vapply(sections, function(section) {
        suppressWarnings(as.integer(section$order %||% NA_integer_))
      }, integer(1))
      sections[order(section_order, names(sections), na.last = TRUE)]
    }

    refresh_plan_artifact_ids <- function(plan) {
      plan$sections <- ordered_plan_sections(plan)
      plan$artifact_ids <- unique(unlist(lapply(plan$sections, function(section) {
        section$artifact_ids %||% character()
      }), use.names = FALSE))
      plan$updated_at <- Sys.time()
      plan
    }

    save_report_plan <- function(plan, message) {
      plan <- refresh_plan_artifact_ids(plan)
      validation <- validate_report_plan(plan, ctx$all_artifacts())
      if (identical(validation$status, "error")) {
        report_plan_message(service_result_message(validation))
        return(FALSE)
      }

      plan <- validation$value
      ctx$report_plan_state$plans[[plan$plan_id]] <- plan
      report_plan_message(paste(c(message, validation$warnings), collapse = " "))
      report_plan_preview(render_report_plan_preview(plan))
      TRUE
    }

    selected_plan_section_id <- function() {
      selected_value(input$plan_section_edit)
    }

    selected_plan_artifact_id <- function() {
      selected_value(input$plan_artifact_edit)
    }

    observe({
      plan_ids <- names(ctx$report_plan_state$plans)
      selected <- ctx$selected_report_plan_id() %||% isolate(input$selected_report_plan)
      if (!length(plan_ids)) {
        selected <- character()
      } else if (is.null(selected) || !selected %in% plan_ids) {
        selected <- plan_ids[1L]
      }

      updateSelectInput(
        session,
        "selected_report_plan",
        choices = plan_ids,
        selected = selected
      )
    })

    observeEvent(input$selected_report_plan, {
      plan_id <- selected_value(input$selected_report_plan)
      if (!is.null(plan_id) && plan_id %in% names(ctx$report_plan_state$plans)) {
        ctx$selected_report_plan_id(plan_id)
      }
    }, ignoreInit = TRUE)

    output$report_plan_summary <- renderUI({
      summary <- ctx$report_plan_summary()
      if (!nrow(summary)) {
        return(render_table(
          data.table::data.table(Message = "No report plans have been created yet."),
          engine = "html",
          searchable = FALSE,
          sortable = FALSE
        ))
      }

      render_table(summary, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$selected_report_plan_status <- renderUI({
      plan <- selected_report_plan()
      if (is.null(plan)) {
        return(ui_empty_state("Select a plan to edit."))
      }

      validation <- validate_report_plan(plan, ctx$all_artifacts())
      label <- report_plan_validation_status(validation, plan)
      badge_status <- switch(
        label,
        "Applied" = "success",
        "Ready" = "success",
        "Has warnings" = "warning",
        "Invalid" = "error",
        "neutral"
      )
      tags$div(
        class = "aq-plan-status-row",
        ui_status_badge(label, status = badge_status),
        if (length(validation$warnings)) {
          tags$p(class = "aq-export-message", paste(validation$warnings, collapse = " "))
        },
        if (length(validation$errors)) {
          tags$p(class = "aq-export-message", paste(validation$errors, collapse = " "))
        }
      )
    })

    output$active_report_plan_indicator <- renderUI({
      plan_id <- ctx$report_plan_state$active_plan_id
      if (is.null(plan_id) || length(plan_id) != 1L || !plan_id %in% names(ctx$report_plan_state$plans)) {
        return(NULL)
      }
      plan <- ctx$report_plan_state$plans[[plan_id]]
      if (is.null(plan)) {
        return(NULL)
      }

      tags$div(
        class = "aq-plan-active-indicator",
        ui_status_badge("Applied", status = "success"),
        tags$p(
          class = "aq-export-message",
          paste("Active plan:", plan$label, "from", module_display_label(plan$source_module, plan$source_module))
        )
      )
    })

    observe({
      plan <- selected_report_plan()
      if (is.null(plan)) {
        return()
      }

      updateTextInput(session, "plan_label_edit", value = plan$label %||% "")
      updateSelectInput(session, "plan_layout_type_edit", selected = plan$layout_type %||% "sections")
      updateNumericInput(session, "plan_cols_edit", value = as.integer(plan$cols %||% 2L))
    })

    observe({
      plan <- selected_report_plan()
      if (is.null(plan)) {
        updateSelectInput(session, "plan_section_edit", choices = character(), selected = character())
        updateSelectInput(session, "plan_artifact_edit", choices = character(), selected = character())
        updateSelectInput(session, "plan_target_section", choices = character(), selected = character())
        updateSelectInput(session, "plan_add_section", choices = character(), selected = character())
        updateSelectInput(session, "plan_add_artifact", choices = character(), selected = character())
        return()
      }

      sections <- ordered_plan_sections(plan)
      section_ids <- names(sections)
      section_choices <- stats::setNames(section_ids, vapply(sections, function(section) {
        section$title %||% section$section_id
      }, character(1)))
      selected_section <- selected_value(input$plan_section_edit)
      if (is.null(selected_section) || !selected_section %in% section_ids) {
        selected_section <- if (length(section_ids)) section_ids[[1]] else character()
      }

      updateSelectInput(session, "plan_section_edit", choices = section_choices, selected = selected_section)
      updateSelectInput(session, "plan_target_section", choices = section_choices, selected = selected_section)
      updateSelectInput(session, "plan_add_section", choices = section_choices, selected = selected_section)

      if (!length(section_ids)) {
        updateSelectInput(session, "plan_artifact_edit", choices = character(), selected = character())
        updateSelectInput(session, "plan_add_artifact", choices = character(), selected = character())
        return()
      }

      selected_section_obj <- sections[[selected_section]]
      artifact_ids <- selected_section_obj$artifact_ids %||% character()
      artifacts <- ctx$all_artifacts()
      artifact_choices <- stats::setNames(artifact_ids, vapply(artifact_ids, function(artifact_id) {
        artifact <- artifacts[[artifact_id]]
        if (is.null(artifact)) {
          return(paste(artifact_id, "(missing)"))
        }
        paste0(artifact$label %||% artifact_id, " [", artifact_id, "]")
      }, character(1)))
      selected_artifact <- selected_value(input$plan_artifact_edit)
      if (is.null(selected_artifact) || !selected_artifact %in% artifact_ids) {
        selected_artifact <- if (length(artifact_ids)) artifact_ids[[1]] else character()
      }
      updateSelectInput(session, "plan_artifact_edit", choices = artifact_choices, selected = selected_artifact)

      available_ids <- setdiff(names(artifacts), plan$artifact_ids %||% character())
      available_choices <- stats::setNames(available_ids, vapply(available_ids, function(artifact_id) {
        artifact <- artifacts[[artifact_id]]
        paste0(artifact$label %||% artifact_id, " [", artifact_id, "]")
      }, character(1)))
      updateSelectInput(session, "plan_add_artifact", choices = available_choices)
    })

    render_report_plan_preview <- function(plan) {
      artifacts <- ctx$all_artifacts()
      validation <- validate_report_plan(plan, artifacts)
      plan <- validation$value
      tags$div(
        class = "aq-report-plan-preview",
        ui_section_header(
          plan$label,
          paste(
            c(
              paste("Source:", module_display_label(plan$source_module, plan$source_module)),
              paste("Layout:", plan$layout_type),
              paste("Sections:", length(plan$sections)),
              paste("Artifacts:", length(plan$artifact_ids)),
              plan$description
            ),
            collapse = " | "
          )
        ),
        if (length(validation$warnings)) {
          ui_empty_state("Plan has warnings.", paste(validation$warnings, collapse = " "))
        },
        if (length(validation$errors)) {
          ui_empty_state("Plan is invalid.", paste(validation$errors, collapse = " "))
        },
        lapply(plan$sections, function(section) {
          rows <- lapply(section$artifact_ids, function(artifact_id) {
            artifact <- artifacts[[artifact_id]]
            if (is.null(artifact)) {
              return(tags$li(
                tags$span(paste(artifact_id, "(missing)")),
                " ",
                ui_status_badge("Missing", status = "warning")
              ))
            }

            tags$li(
              tags$span(artifact$label %||% artifact_id),
              " ",
              ui_status_badge(artifact_type_label(artifact$artifact_type), status = "neutral"),
              if (!isTRUE(artifact$visible)) {
                tagList(" ", ui_status_badge("Hidden", status = "warning"))
              }
            )
          })

          ui_card(
            title = section$title,
            subtitle = section$description,
            if (length(rows)) {
              tags$ul(rows)
            } else {
              ui_empty_state("This section has no artifacts.")
            }
          )
        })
      )
    }

    output$report_plan_editor <- renderUI({
      plan <- selected_report_plan()
      if (!length(ctx$report_plan_state$plans)) {
        return(ui_empty_state("No report plans available."))
      }
      if (is.null(plan)) {
        return(ui_empty_state("Select a plan to edit."))
      }

      tagList(
        ui_control_group(
          "Plan Metadata",
          textInput(session$ns("plan_label_edit"), "Plan Label", value = plan$label %||% ""),
          selectInput(
            session$ns("plan_layout_type_edit"),
            "Layout Type",
            choices = c("sections", "grid", "carousel", "canvas"),
            selected = plan$layout_type %||% "sections"
          ),
          numericInput(session$ns("plan_cols_edit"), "Columns", value = as.integer(plan$cols %||% 2L), min = 1, step = 1),
          ui_action_row(
            actionButton(session$ns("update_plan_metadata"), "Update Plan Metadata", class = "btn-primary"),
            actionButton(session$ns("duplicate_plan"), "Duplicate Plan", class = "btn-secondary"),
            actionButton(session$ns("archive_plan"), "Archive Plan", class = "btn-danger")
          )
        ),
        ui_control_group(
          "Sections",
          selectInput(session$ns("plan_section_edit"), "Section", choices = character()),
          textInput(session$ns("plan_section_title_edit"), "Section Title", value = ""),
          ui_action_row(
            actionButton(session$ns("rename_plan_section"), "Rename Section", class = "btn-secondary"),
            actionButton(session$ns("move_plan_section_up"), "Move Section Up", class = "btn-secondary"),
            actionButton(session$ns("move_plan_section_down"), "Move Section Down", class = "btn-secondary"),
            actionButton(session$ns("remove_plan_section"), "Remove Section", class = "btn-danger")
          )
        ),
        ui_control_group(
          "Artifacts",
          selectInput(session$ns("plan_artifact_edit"), "Artifact", choices = character()),
          selectInput(session$ns("plan_target_section"), "Move To Section", choices = character()),
          ui_action_row(
            actionButton(session$ns("move_plan_artifact_up"), "Move Artifact Up", class = "btn-secondary"),
            actionButton(session$ns("move_plan_artifact_down"), "Move Artifact Down", class = "btn-secondary"),
            actionButton(session$ns("move_plan_artifact_section"), "Move To Section", class = "btn-secondary"),
            actionButton(session$ns("remove_plan_artifact"), "Remove From Plan", class = "btn-danger")
          ),
          tags$hr(),
          selectInput(session$ns("plan_add_artifact"), "Add Artifact", choices = character()),
          selectInput(session$ns("plan_add_section"), "Add To Section", choices = character()),
          ui_action_row(
            actionButton(session$ns("add_artifact_to_plan"), "Add Artifact to Plan", class = "btn-primary")
          )
        )
      )
    })

    observe({
      plan <- selected_report_plan()
      section_id <- selected_plan_section_id()
      if (is.null(plan) || is.null(section_id)) {
        return()
      }

      section <- plan$sections[[section_id]]
      updateTextInput(session, "plan_section_title_edit", value = section$title %||% "")
    })

    observeEvent(input$update_plan_metadata, {
      plan <- selected_report_plan()
      if (is.null(plan)) {
        report_plan_message("Select a plan to edit.")
        return()
      }

      plan$label <- selected_value(input$plan_label_edit) %||% plan$label
      plan$layout_type <- selected_value(input$plan_layout_type_edit) %||% plan$layout_type
      plan$cols <- as.integer(input$plan_cols_edit %||% plan$cols)
      save_report_plan(plan, paste("Updated plan metadata:", plan$label))
    }, ignoreInit = TRUE)

    observeEvent(input$duplicate_plan, {
      plan <- selected_report_plan()
      if (is.null(plan)) {
        report_plan_message("Select a plan to duplicate.")
        return()
      }

      base_id <- paste0(plan$plan_id, "_copy")
      new_id <- base_id
      index <- 1L
      while (new_id %in% names(ctx$report_plan_state$plans)) {
        index <- index + 1L
        new_id <- paste0(base_id, "_", index)
      }
      plan$plan_id <- new_id
      plan$label <- paste(plan$label, "Copy")
      plan$status <- "draft"
      plan$created_at <- Sys.time()
      plan$updated_at <- Sys.time()
      save_report_plan(plan, paste("Duplicated report plan:", plan$label))
      updateSelectInput(session, "selected_report_plan", selected = new_id)
    }, ignoreInit = TRUE)

    observeEvent(input$archive_plan, {
      plan <- selected_report_plan()
      if (is.null(plan)) {
        report_plan_message("Select a plan to archive.")
        return()
      }

      plan$status <- "archived"
      save_report_plan(plan, paste("Archived report plan:", plan$label))
    }, ignoreInit = TRUE)

    rename_selected_section <- function() {
      plan <- selected_report_plan()
      section_id <- selected_plan_section_id()
      if (is.null(plan) || is.null(section_id)) {
        report_plan_message("Select a section to rename.")
        return()
      }

      title <- selected_value(input$plan_section_title_edit)
      if (is.null(title)) {
        report_plan_message("Enter a section title.")
        return()
      }

      plan$sections[[section_id]]$title <- title
      save_report_plan(plan, paste("Renamed section:", title))
    }

    observeEvent(input$rename_plan_section, rename_selected_section(), ignoreInit = TRUE)

    move_section <- function(direction) {
      plan <- selected_report_plan()
      section_id <- selected_plan_section_id()
      if (is.null(plan) || is.null(section_id)) {
        report_plan_message("Select a section to move.")
        return()
      }

      sections <- ordered_plan_sections(plan)
      section_ids <- names(sections)
      index <- match(section_id, section_ids)
      swap_index <- index + direction
      if (is.na(index) || swap_index < 1L || swap_index > length(section_ids)) {
        report_plan_message("Section is already at that end of the plan.")
        return()
      }

      section_ids[c(index, swap_index)] <- section_ids[c(swap_index, index)]
      sections <- sections[section_ids]
      for (i in seq_along(sections)) {
        sections[[i]]$order <- i
      }
      plan$sections <- sections
      save_report_plan(plan, "Moved section.")
    }

    observeEvent(input$move_plan_section_up, move_section(-1L), ignoreInit = TRUE)
    observeEvent(input$move_plan_section_down, move_section(1L), ignoreInit = TRUE)

    observeEvent(input$remove_plan_section, {
      plan <- selected_report_plan()
      section_id <- selected_plan_section_id()
      if (is.null(plan) || is.null(section_id)) {
        report_plan_message("Select a section to remove.")
        return()
      }

      plan$sections[[section_id]] <- NULL
      save_report_plan(plan, "Removed section from plan. Artifacts remain in the Artifact Library.")
    }, ignoreInit = TRUE)

    move_artifact <- function(direction) {
      plan <- selected_report_plan()
      section_id <- selected_plan_section_id()
      artifact_id <- selected_plan_artifact_id()
      if (is.null(plan) || is.null(section_id) || is.null(artifact_id)) {
        report_plan_message("Select an artifact to move.")
        return()
      }

      artifact_ids <- plan$sections[[section_id]]$artifact_ids %||% character()
      index <- match(artifact_id, artifact_ids)
      swap_index <- index + direction
      if (is.na(index) || swap_index < 1L || swap_index > length(artifact_ids)) {
        report_plan_message("Artifact is already at that end of the section.")
        return()
      }

      artifact_ids[c(index, swap_index)] <- artifact_ids[c(swap_index, index)]
      plan$sections[[section_id]]$artifact_ids <- artifact_ids
      save_report_plan(plan, "Moved artifact.")
    }

    observeEvent(input$move_plan_artifact_up, move_artifact(-1L), ignoreInit = TRUE)
    observeEvent(input$move_plan_artifact_down, move_artifact(1L), ignoreInit = TRUE)

    observeEvent(input$remove_plan_artifact, {
      plan <- selected_report_plan()
      section_id <- selected_plan_section_id()
      artifact_id <- selected_plan_artifact_id()
      if (is.null(plan) || is.null(section_id) || is.null(artifact_id)) {
        report_plan_message("Select an artifact to remove from the plan.")
        return()
      }

      plan$sections[[section_id]]$artifact_ids <- setdiff(plan$sections[[section_id]]$artifact_ids %||% character(), artifact_id)
      save_report_plan(plan, "Removed artifact from plan. Artifact remains in the Artifact Library.")
    }, ignoreInit = TRUE)

    observeEvent(input$move_plan_artifact_section, {
      plan <- selected_report_plan()
      from_section <- selected_plan_section_id()
      to_section <- selected_value(input$plan_target_section)
      artifact_id <- selected_plan_artifact_id()
      if (is.null(plan) || is.null(from_section) || is.null(to_section) || is.null(artifact_id)) {
        report_plan_message("Select an artifact and target section.")
        return()
      }

      plan$sections[[from_section]]$artifact_ids <- setdiff(plan$sections[[from_section]]$artifact_ids %||% character(), artifact_id)
      plan$sections[[to_section]]$artifact_ids <- c(plan$sections[[to_section]]$artifact_ids %||% character(), artifact_id)
      save_report_plan(plan, "Moved artifact to another section.")
    }, ignoreInit = TRUE)

    observeEvent(input$add_artifact_to_plan, {
      plan <- selected_report_plan()
      section_id <- selected_value(input$plan_add_section)
      artifact_id <- selected_value(input$plan_add_artifact)
      if (is.null(plan) || is.null(section_id)) {
        report_plan_message("Select a plan section.")
        return()
      }
      if (is.null(artifact_id)) {
        report_plan_message("All artifacts are already included in this plan.")
        return()
      }

      plan$sections[[section_id]]$artifact_ids <- unique(c(plan$sections[[section_id]]$artifact_ids %||% character(), artifact_id))
      save_report_plan(plan, "Added artifact to plan.")
    }, ignoreInit = TRUE)

    observeEvent(input$preview_report_plan, {
      plan_id <- selected_value(input$selected_report_plan)
      if (is.null(plan_id) || length(plan_id) != 1L || !plan_id %in% names(ctx$report_plan_state$plans)) {
        report_plan_preview(NULL)
        report_plan_message("Select a report plan to preview.")
        return()
      }
      plan <- ctx$report_plan_state$plans[[plan_id]]
      if (is.null(plan)) {
        report_plan_preview(NULL)
        report_plan_message("Select a report plan to preview.")
        return()
      }

      report_plan_preview(render_report_plan_preview(plan))
      report_plan_message(paste("Previewing report plan:", plan$label))
    }, ignoreInit = TRUE)

    observeEvent(input$apply_report_plan, {
      plan_id <- selected_value(input$selected_report_plan)
      if (is.null(plan_id)) {
        report_plan_message("Select a report plan to apply.")
        return()
      }

      result <- ctx$apply_report_plan(plan_id)
      report_plan_message(service_result_message(result))
      if (!identical(result$status, "error")) {
        report_plan_preview(render_report_plan_preview(result$value))
      }
    }, ignoreInit = TRUE)

    output$report_plan_preview <- renderUI({
      report_plan_preview()
    })

    output$report_plan_message <- renderText({
      report_plan_message()
    })

    output$saved_layout_preview <- renderUI({
      if (identical(input$layout_type, "Sections")) {
        if (!length(ctx$all_report_artifacts())) {
          if (!length(ctx$all_artifacts())) {
            return(ui_empty_state(
              "No artifacts available.",
              "Create a plot, text block, or table artifact to preview a section layout."
            ))
          }

          return(ui_empty_state(
            "No visible artifacts selected for this layout.",
            "Use the Artifact Library to show artifacts in the report preview."
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
        if (!length(ctx$all_artifacts())) {
          return(ui_empty_state(
            "No artifacts available.",
            "Create a plot, text block, or table artifact to preview a grid layout."
          ))
        }

        return(ui_empty_state(
          "No visible artifacts selected for this layout.",
          "Use the Artifact Library to show artifacts in the report preview."
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
          "# Note: mixed text/table artifact export and report-plan code generation is intentionally omitted from this replay snippet.",
          sep = "\n\n"
        )
      }

      code
    })
  })
}
