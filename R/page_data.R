page_data_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Data",
    ui_page(
      title = "Data Workspace",
      subtitle = "Load the project dataset and inspect the working preview before running modules.",
      eyebrow = "Data",
      ui_workspace_grid(
        columns = "two",
        class = "aq-data-loader-grid",
        ui_card(
          title = "Dataset Source",
          subtitle = "Upload CSV, Excel, Parquet, or use project-loaded data.",
          fileInput(ns("csv_file"), "Dataset File", accept = supported_data_accept_types()),
          ui_callout(
            "Supported formats",
            "CSV, XLSX, XLSM, and Parquet. Excel workbooks load the first worksheet.",
            status = "info"
          )
        ),
        ui_card(
          title = "Dataset Status",
          textOutput(ns("data_summary")),
          ui_callout(
            "Next",
            "After data loads, use Workflow or Analysis Modules to generate artifacts.",
            status = "info",
            actions = ui_action_row(
              actionButton(ns("open_analysis_modules"), "Open Analysis Modules", class = "btn-primary btn-sm"),
              actionButton(ns("open_workflow"), "Open Workflow", class = "btn-secondary btn-sm")
            )
          )
        )
      ),
      ui_card(
        title = "Data Preview",
        class = "aq-data-preview-card",
        uiOutput(ns("data_preview"))
      )
    )
  )
}

page_data_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ctx$uploaded_data <- reactive({
      project_info <- ctx$project_data_info()
      if (identical(project_info$source, "prepared_artifact")) {
        data <- ctx$project_data()
        if (!is.null(data)) {
          return(data)
        }
      }

      if (is.null(input$csv_file)) {
        data <- ctx$project_data()
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

      read_dataset_file(input$csv_file$datapath, name = input$csv_file$name)
    })

    ctx$current_data_path <- function() {
      project_info <- ctx$project_data_info()
      if (identical(project_info$source, "prepared_artifact")) {
        return(project_info$path)
      }

      if (!is.null(input$csv_file$datapath)) {
        return(input$csv_file$datapath)
      }

      project_info$path
    }

    ctx$current_data_name <- function() {
      project_info <- ctx$project_data_info()
      if (identical(project_info$source, "prepared_artifact")) {
        return(project_info$name)
      }

      if (!is.null(input$csv_file$name)) {
        return(input$csv_file$name)
      }

      project_info$name
    }

    ctx$has_upload_or_project_data <- function() {
      !is.null(input$csv_file) || !is.null(ctx$project_data())
    }

    observeEvent(input$csv_file, {
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      if (!is.null(data) && length(ctx$saved_plots$configs)) {
        failures <- ctx$rebuild_saved_plots(data)
        if (length(failures)) {
          ctx$project_message(paste(
            "Data uploaded, but some saved plots could not be rebuilt:",
            paste(failures, collapse = " | ")
          ))
        } else {
          ctx$project_message("Data uploaded and saved plots rebuilt.")
        }
      }
    }, ignoreInit = TRUE)

    observeEvent(input$open_analysis_modules, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Analysis Modules")
    }, ignoreInit = TRUE)

    observeEvent(input$open_workflow, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Workflow")
    }, ignoreInit = TRUE)

    output$data_summary <- renderText({
      tryCatch({
        data <- ctx$uploaded_data()
        if (is.null(input$csv_file)) {
          return(sprintf(
            "%s - loaded from project - %s rows x %s columns",
            default_value(ctx$current_data_name(), "(project data)"),
            format(nrow(data), big.mark = ",", scientific = FALSE),
            format(ncol(data), big.mark = ",", scientific = FALSE)
          ))
        }

        sprintf(
          "%s (%s) - %s MB - %s rows x %s columns",
          input$csv_file$name,
          toupper(default_value(data_loader_extension(input$csv_file$name), "file")),
          file_size_mb(input$csv_file$size),
          format(nrow(data), big.mark = ",", scientific = FALSE),
          format(ncol(data), big.mark = ",", scientific = FALSE)
        )
      }, error = function(e) {
        conditionMessage(e)
      })
    })

    output$data_preview <- renderUI({
      data <- tryCatch(
        head(ctx$uploaded_data(), 25),
        error = function(e) data.table::data.table(Message = conditionMessage(e))
      )
      render_table(data, engine = "html", searchable = FALSE, sortable = FALSE)
    })
  })
}
