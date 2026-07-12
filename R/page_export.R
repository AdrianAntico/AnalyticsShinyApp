page_export_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Export",
    ui_page(
      title = "Export",
      subtitle = "Write human-facing report outputs and reproducible R code from the current project state.",
      eyebrow = "Reports",
      tags$div(
        class = "aq-export-layout",
        ui_card(
          title = "Export Settings",
          class = "aq-export-settings",
          tags$div(
            class = "aq-wide-input",
            textInput(ns("export_dir"), "Export Directory", value = "")
          ),
          textInput(ns("export_name"), "File Name", value = "autoplots_report"),
          ui_action_row(
            actionButton(ns("export_html"), "Export HTML", class = "btn-primary"),
            actionButton(ns("export_code"), "Export R Code", class = "btn-secondary"),
            actionButton(ns("export_all"), "Export All", class = "btn-success")
          )
        ),
        ui_card(
          title = "Export Status",
          class = "aq-export-status",
          uiOutput(ns("export_message"))
        )
      )
    )
  )
}

page_export_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ctx$export_name_value <- function() {
      name <- selected_value(input$export_name)
      if (is.null(name)) {
        return(NULL)
      }

      tools::file_path_sans_ext(basename(name))
    }

    ctx$get_export_dir <- function() {
      selected_value(input$export_dir)
    }

    ctx$get_export_name <- function() {
      input$export_name
    }

    ctx$set_export_settings <- function(export_dir = NULL, export_name = NULL) {
      if (!is.null(export_dir)) {
        updateTextInput(session, "export_dir", value = export_dir)
      }
      if (!is.null(export_name)) {
        updateTextInput(session, "export_name", value = export_name)
      }
    }

    observe({
      if (isTRUE(ctx$project_ready())) {
        project <- ctx$current_project()
        export_dir <- project_report_path(project, create_dir = TRUE)
        if (!identical(input$export_dir, export_dir)) {
          updateTextInput(session, "export_dir", value = export_dir)
        }
      }
    })

    validate_export_gate <- function(export_dir) {
      if (!isTRUE(ctx$project_ready())) {
        return(storage_error_result(
          "project_required",
          "No project is open. Exports are persistent outputs and require a ready project.",
          workspace_state = ctx$workspace_state(),
          project_state = ctx$project_state_status(),
          requested_resource_type = "report_export"
        ))
      }
      persistent_write_gate(
        workspace = ctx$current_workspace(),
        project = ctx$current_project(),
        target = file.path(export_dir, paste0(.export_clean_name(input$export_name) %||% "report", ".html")),
        requested_resource_type = "report_export"
      )
    }

    observeEvent(input$export_html, {
      ctx$export_message("")
      gate <- validate_export_gate(input$export_dir)
      if (!identical(gate$status, "success")) {
        ctx$export_message(service_result_message(gate))
        return(invisible(NULL))
      }

      result <- export_html_service(
        report = tryCatch(ctx$current_report(), error = function(e) NULL),
        export_dir = input$export_dir,
        export_name = input$export_name
      )
      ctx$export_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$export_code, {
      ctx$export_message("")
      gate <- validate_export_gate(input$export_dir)
      if (!identical(gate$status, "success")) {
        ctx$export_message(service_result_message(gate))
        return(invisible(NULL))
      }

      code <- tryCatch(ctx$current_report_code(), error = function(e) NULL)
      result <- export_code_service(
        code = code,
        export_dir = input$export_dir,
        export_name = input$export_name
      )
      ctx$export_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$export_all, {
      ctx$export_message("")
      gate <- validate_export_gate(input$export_dir)
      if (!identical(gate$status, "success")) {
        ctx$export_message(service_result_message(gate))
        return(invisible(NULL))
      }

      result <- export_all_service(
        report = tryCatch(ctx$current_report(), error = function(e) NULL),
        code = tryCatch(ctx$current_report_code(), error = function(e) NULL),
        export_dir = input$export_dir,
        export_name = input$export_name
      )
      ctx$export_message(service_result_message(result))
    }, ignoreInit = TRUE)

    output$export_message <- renderUI({
      message <- ctx$export_message()
      if (is.null(message) || !nzchar(message)) {
        return(ui_empty_state("No export has been run yet."))
      }

      tags$p(class = "aq-export-message", message)
    })
  })
}
