page_project_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Project",
    sidebarLayout(
      sidebarPanel(
        textInput(
          ns("project_path"),
          "Project File",
          value = file.path(getwd(), "autoplots_project.rds")
        ),
        actionButton(ns("save_project"), "Save Project", class = "btn-primary"),
        actionButton(ns("load_project"), "Load Project", class = "btn-secondary"),
        tags$hr(),
        textInput(
          ns("bundle_dir"),
          "Project Bundle Directory",
          value = file.path(getwd(), "autoplots_project")
        ),
        actionButton(ns("save_bundle"), "Save Project Bundle", class = "btn-primary"),
        actionButton(ns("load_bundle"), "Load Project Bundle", class = "btn-secondary")
      ),
      mainPanel(
        textOutput(ns("project_message"))
      )
    )
  )
}

page_project_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    output$project_message <- renderText({
      ctx$project_message()
    })

    observeEvent(input$save_project, {
      ctx$project_message("")

      tryCatch({
        project_state <- ctx$current_project_state()
        output_path <- save_project_state(project_state, input$project_path)
        ctx$project_message(paste("Saved project to", output_path))
      }, error = function(e) {
        ctx$project_message(paste("Save project failed:", conditionMessage(e)))
      })
    }, ignoreInit = TRUE)

    observeEvent(input$load_project, {
      ctx$project_message("")

      tryCatch({
        project_path <- normalize_project_path(input$project_path)
        if (!file.exists(project_path)) {
          stop("Project file does not exist.", call. = FALSE)
        }

        project_state <- readRDS(project_path)
        loaded <- ctx$load_project_state(project_state)
        ctx$project_message(paste(loaded$messages, collapse = " "))
      }, error = function(e) {
        ctx$project_message(paste("Load project failed:", conditionMessage(e)))
      })
    }, ignoreInit = TRUE)

    observeEvent(input$save_bundle, {
      ctx$project_message("")

      tryCatch({
        bundle_dir <- normalize_bundle_dir(input$bundle_dir)
        bundle_paths <- ensure_bundle_dirs(bundle_dir)
        project_state <- ctx$current_project_state()
        source_data_path <- ctx$current_data_path()

        if (!is.null(source_data_path) && file.exists(source_data_path)) {
          file.copy(
            from = source_data_path,
            to = bundle_paths$data_path,
            overwrite = TRUE
          )
          project_state$original_data_path <- source_data_path
          project_state$data_path <- bundle_paths$data_path
          project_state$data_name <- "data.csv"
        } else if (!is.null(ctx$project_data())) {
          data.table::fwrite(ctx$project_data(), bundle_paths$data_path)
          project_state$data_path <- bundle_paths$data_path
          project_state$data_name <- "data.csv"
        } else {
          stop("No source data is available to bundle.", call. = FALSE)
        }

        project_state$export_dir <- bundle_paths$exports_dir
        saveRDS(project_state, bundle_paths$project_path)
        ctx$set_export_settings(export_dir = bundle_paths$exports_dir)
        ctx$project_data_info(list(path = bundle_paths$data_path, name = "data.csv"))
        ctx$project_message(paste("Saved project bundle to", bundle_paths$bundle_dir))
      }, error = function(e) {
        ctx$project_message(paste("Save bundle failed:", conditionMessage(e)))
      })
    }, ignoreInit = TRUE)

    observeEvent(input$load_bundle, {
      ctx$project_message("")

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
        loaded <- ctx$load_project_state(
          project_state = project_state,
          preferred_data_path = normalizePath(data_path, winslash = "/", mustWork = TRUE),
          export_dir_override = normalizePath(exports_dir, winslash = "/", mustWork = TRUE)
        )
        ctx$project_message(paste(
          c("Loaded project bundle.", loaded$messages),
          collapse = " "
        ))
      }, error = function(e) {
        ctx$project_message(paste("Load bundle failed:", conditionMessage(e)))
      })
    }, ignoreInit = TRUE)
  })
}
