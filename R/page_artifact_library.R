page_artifact_library_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Artifact Library",
    ui_page(
      title = "Artifact Library",
      tags$div(
        class = "aq-export-layout",
        ui_card(
          title = "Manage Artifacts",
          selectInput(
            ns("artifact_type_filter"),
            "Type",
            choices = c("All", "Plot", "Text", "Table"),
            selected = "All"
          ),
          selectInput(ns("selected_artifact_id"), "Artifact", choices = character()),
          textInput(ns("artifact_label_edit"), "Label", value = ""),
          textInput(ns("artifact_section_edit"), "Section", value = "Analysis"),
          numericInput(ns("artifact_order_edit"), "Order", value = NA, min = 1, step = 1),
          checkboxInput(ns("artifact_visible_edit"), "Visible in report", value = TRUE),
          ui_action_row(
            actionButton(ns("update_artifact_metadata"), "Update Artifact Metadata", class = "btn-primary"),
            actionButton(ns("toggle_artifact_visibility"), "Hide / Show Artifact", class = "btn-secondary"),
            actionButton(ns("remove_artifact"), "Remove Artifact", class = "btn-danger")
          ),
          tags$hr(),
          uiOutput(ns("artifact_library_table_exports")),
          textOutput(ns("artifact_library_message"))
        ),
        ui_card(
          title = "Artifact Preview",
          uiOutput(ns("selected_artifact_preview"))
        )
      ),
      ui_card(
        title = "Artifacts",
        tableOutput(ns("artifact_library_summary"))
      )
    )
  )
}

page_artifact_library_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    filtered_artifact_summary <- function() {
      summary <- ctx$combined_artifact_summary()
      filter <- selected_value(input$artifact_type_filter) %||% "All"
      if (identical(filter, "All") || !nrow(summary)) {
        return(summary)
      }

      summary[summary$artifact_type == tolower(filter)]
    }

    selected_artifact <- function() {
      artifact_id <- selected_value(input$selected_artifact_id)
      artifacts <- ctx$all_artifacts()
      if (is.null(artifact_id) || !artifact_id %in% names(artifacts)) {
        return(NULL)
      }

      artifacts[[artifact_id]]
    }

    observe({
      summary <- filtered_artifact_summary()
      choices <- summary$artifact_id
      selected <- isolate(input$selected_artifact_id)
      if (!length(choices)) {
        selected <- character()
      } else if (is.null(selected) || !selected %in% choices) {
        selected <- choices[1L]
      }

      updateSelectInput(
        session = session,
        inputId = "selected_artifact_id",
        choices = choices,
        selected = selected
      )
    })

    observe({
      artifact <- selected_artifact()
      if (is.null(artifact)) {
        updateTextInput(session, "artifact_label_edit", value = "")
        updateTextInput(session, "artifact_section_edit", value = "Analysis")
        updateNumericInput(session, "artifact_order_edit", value = NA)
        updateCheckboxInput(session, "artifact_visible_edit", value = TRUE)
        return()
      }

      updateTextInput(session, "artifact_label_edit", value = artifact$label %||% "")
      updateTextInput(session, "artifact_section_edit", value = artifact$section %||% "Analysis")
      updateNumericInput(
        session,
        "artifact_order_edit",
        value = ctx$artifact_order_value(artifact$order, NA_integer_)
      )
      updateCheckboxInput(session, "artifact_visible_edit", value = isTRUE(artifact$visible))
    })

    observeEvent(input$update_artifact_metadata, {
      artifact <- selected_artifact()
      if (is.null(artifact)) {
        ctx$artifact_library_message("Select an artifact before updating metadata.")
        return()
      }

      label <- selected_value(input$artifact_label_edit) %||% artifact$label
      section <- selected_value(input$artifact_section_edit) %||% artifact$section
      order <- ctx$artifact_order_value(input$artifact_order_edit, artifact$order)
      visible <- isTRUE(input$artifact_visible_edit)

      if (!ctx$update_artifact_metadata(artifact$artifact_id, label, section, order, visible)) {
        ctx$artifact_library_message(paste("Could not update artifact", artifact$artifact_id))
        return()
      }

      ctx$artifact_library_message(paste("Updated artifact", artifact$artifact_id))
    }, ignoreInit = TRUE)

    observeEvent(input$toggle_artifact_visibility, {
      artifact <- selected_artifact()
      if (is.null(artifact)) {
        ctx$artifact_library_message("Select an artifact before changing visibility.")
        return()
      }

      visible <- !isTRUE(artifact$visible)
      if (!ctx$update_artifact_metadata(
        artifact$artifact_id,
        artifact$label,
        artifact$section,
        artifact$order,
        visible
      )) {
        ctx$artifact_library_message(paste("Could not update artifact", artifact$artifact_id))
        return()
      }

      ctx$artifact_library_message(paste(
        if (visible) "Showing artifact" else "Hiding artifact",
        artifact$artifact_id
      ))
    }, ignoreInit = TRUE)

    observeEvent(input$remove_artifact, {
      artifact_id <- selected_value(input$selected_artifact_id)
      if (is.null(artifact_id)) {
        ctx$artifact_library_message("Select an artifact before removing it.")
        return()
      }

      if (!ctx$remove_artifact_by_id(artifact_id)) {
        ctx$artifact_library_message(paste("Could not remove artifact", artifact_id))
        return()
      }

      ctx$artifact_library_message(paste("Removed artifact", artifact_id))
    }, ignoreInit = TRUE)

    observeEvent(input$library_export_table_csv, {
      artifact <- selected_artifact()
      if (is.null(artifact) || !identical(artifact$artifact_type, "table")) {
        ctx$artifact_library_message("Select a table artifact before exporting CSV.")
        return()
      }

      result <- tryCatch(
        export_table_csv(
          artifact_or_data = artifact,
          path = ctx$get_export_dir(),
          name = artifact$artifact_id
        ),
        error = function(e) {
          service_result(status = "error", errors = conditionMessage(e))
        }
      )

      ctx$artifact_library_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$library_export_table_xlsx, {
      artifact <- selected_artifact()
      if (is.null(artifact) || !identical(artifact$artifact_type, "table")) {
        ctx$artifact_library_message("Select a table artifact before exporting XLSX.")
        return()
      }

      result <- tryCatch(
        export_table_xlsx(
          artifacts_or_tables = artifact,
          path = ctx$get_export_dir(),
          name = artifact$artifact_id
        ),
        error = function(e) {
          service_result(status = "error", errors = conditionMessage(e))
        }
      )

      ctx$artifact_library_message(service_result_message(result))
    }, ignoreInit = TRUE)

    output$artifact_library_message <- renderText({
      ctx$artifact_library_message()
    })

    output$artifact_library_summary <- renderTable({
      summary <- filtered_artifact_summary()
      if (!nrow(summary)) {
        return(data.table::data.table(Message = "No artifacts have been created yet."))
      }

      summary
    })

    output$selected_artifact_preview <- renderUI({
      artifact <- selected_artifact()
      if (is.null(artifact)) {
        return(ui_empty_state("Select an artifact to preview it."))
      }

      render_artifact(artifact)
    })

    output$artifact_library_table_exports <- renderUI({
      artifact <- selected_artifact()
      if (is.null(artifact) || !identical(artifact$artifact_type, "table")) {
        return(NULL)
      }

      ui_action_row(
        actionButton(session$ns("library_export_table_csv"), "Export Table CSV", class = "btn-secondary"),
        actionButton(session$ns("library_export_table_xlsx"), "Export Table XLSX", class = "btn-secondary")
      )
    })
  })
}
