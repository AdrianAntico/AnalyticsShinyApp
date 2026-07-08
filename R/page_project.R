page_project_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Project",
    ui_page(
      title = "Project Workspace",
      subtitle = "Mission control for data, modules, artifacts, reports, collector output, and AI-ready evidence.",
      eyebrow = "Project",
      actions = ui_action_row(
        actionButton(ns("save_project"), "Save Project", class = "btn-primary"),
        actionButton(ns("load_project"), "Load Project", class = "btn-secondary")
      ),
      uiOutput(ns("workspace_overview")),
      uiOutput(ns("workspace_progress")),
      ui_workspace_grid(
        columns = "main-sidebar",
        tagList(
          ui_card(
            title = "Workspace Status",
            subtitle = "A compact readout of the current analytical run.",
            uiOutput(ns("project_message_panel")),
            uiOutput(ns("workspace_status")),
            ui_disclosure(
              "Recent Activity",
              uiOutput(ns("recent_activity")),
              level = "common",
              open = TRUE
            )
          ),
          uiOutput(ns("ai_readiness_panel")),
          uiOutput(ns("collector_panel"))
        ),
        ui_card(
          title = "Project Files",
          subtitle = "Save or reload the project state and portable bundle.",
          textInput(
            ns("project_path"),
            "Project File",
            value = file.path(getwd(), "autoplots_project.rds")
          ),
          ui_action_row(
            actionButton(ns("save_project_secondary"), "Save", class = "btn-primary btn-sm"),
            actionButton(ns("load_project_secondary"), "Load", class = "btn-secondary btn-sm")
          ),
          ui_disclosure(
            "Bundle Options",
            textInput(
              ns("bundle_dir"),
              "Project Bundle Directory",
              value = file.path(getwd(), "autoplots_project")
            ),
            ui_action_row(
              actionButton(ns("save_bundle"), "Save Bundle", class = "btn-primary btn-sm"),
              actionButton(ns("load_bundle"), "Load Bundle", class = "btn-secondary btn-sm")
            ),
            level = "advanced"
          )
        )
      )
    )
  )
}

page_project_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    project_actions <- reactiveVal(character())

    add_activity <- function(message) {
      existing <- project_actions()
      project_actions(utils::head(c(paste(format(Sys.time(), "%H:%M:%S"), message), existing), 6L))
    }

    output$project_message_panel <- renderUI({
      message <- ctx$project_message()
      if (is.null(message) || !nzchar(message)) {
        return(ui_empty_state("No project messages.", "Save, load, or run modules to see project activity here."))
      }
      tags$p(class = "aq-export-message", message)
    })

    output$workspace_overview <- renderUI({
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
      plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      collector_status <- if (nrow(collector)) collector$collector_status[[1]] else "not_created"
      collector_badge <- if (collector_status %in% c("success", "created")) "success" else if (collector_status %in% c("error")) "error" else "neutral"
      ui_stat_grid(
        ui_stat_tile("Dataset", if (is.null(data)) "None" else paste(nrow(data), "rows"), status = if (is.null(data)) "neutral" else "success", detail = if (is.null(data)) "Upload data to begin" else paste(ncol(data), "columns")),
        ui_stat_tile("Artifacts", length(artifacts), status = if (length(artifacts)) "success" else "neutral", detail = "plots, tables, text"),
        ui_stat_tile("Report Plans", length(plans), status = if (length(plans)) "success" else "neutral", detail = "curated outputs"),
        ui_stat_tile("Collector", collector_status, status = collector_badge, detail = if (nrow(collector)) paste(collector$artifact_count[[1]], "artifacts") else "not created")
      )
    })

    output$workspace_progress <- renderUI({
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
      plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      collector_ready <- nrow(collector) && (collector$artifact_count[[1]] %||% 0L) > 0L
      completed <- character()
      if (!is.null(data)) completed <- c(completed, "data")
      if (length(artifacts)) completed <- c(completed, "analysis", "artifacts")
      if (length(plans)) completed <- c(completed, "reports")
      if (collector_ready) completed <- c(completed, "collector", "ai")
      active <- if (is.null(data)) {
        "data"
      } else if (!length(artifacts)) {
        "analysis"
      } else if (!collector_ready) {
        "collector"
      } else {
        "ai"
      }

      ui_card(
        title = "Workspace Progress",
        subtitle = "Project -> data -> artifacts -> collector -> AI-ready evidence.",
        ui_progress_steps(
          steps = c(
            project = "Project",
            data = "Data",
            analysis = "Analysis",
            artifacts = "Artifacts",
            reports = "Reports",
            collector = "Collector",
            ai = "AI Ready"
          ),
          active = active,
          completed = completed
        )
      )
    })

    output$ai_readiness_panel <- renderUI({
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      artifact_count <- if (nrow(collector)) collector$artifact_count[[1]] %||% 0L else 0L
      render_target <- if (nrow(collector)) collector$render_target[[1]] %||% "llm_docx" else "llm_docx"
      status <- if (artifact_count > 0L) "ready" else "pending"
      details <- if (artifact_count > 0L) {
        "The collector has evidence available for LLM-oriented review."
      } else {
        "Run an analysis module to generate standardized artifacts for the collector."
      }
      ui_ai_readiness_panel(
        status = status,
        details = details,
        artifacts = artifact_count,
        render_target = render_target
      )
    })

    output$workspace_status <- renderUI({
      data_info <- tryCatch(ctx$project_data_info(), error = function(e) list(path = NULL, name = NULL))
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      rows <- data.table::data.table(
        item = c("Current dataset", "Dataset path", "Render target", "Collector DOCX", "Manifest", "Current run"),
        value = c(
          data_info$name %||% "No dataset loaded",
          data_info$path %||% "No source path",
          if (nrow(collector)) collector$render_target[[1]] %||% "llm_docx" else "llm_docx",
          if (nrow(collector)) collector$collector_docx[[1]] else "Collector not created",
          if (nrow(collector)) collector$manifest_status[[1]] else "not_written",
          if (nrow(collector)) collector$current_run_id[[1]] else "No run yet"
        )
      )
      render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$collector_panel <- renderUI({
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      ui_collector_status_panel(collector)
    })

    output$recent_activity <- renderUI({
      ui_activity_list(project_actions())
    })

    save_project_action <- function() {
      ctx$project_message("")

      tryCatch({
        project_state <- ctx$current_project_state()
        output_path <- save_project_state(project_state, input$project_path)
        ctx$project_message(paste("Saved project to", output_path))
        add_activity(paste("Saved project to", output_path))
      }, error = function(e) {
        ctx$project_message(paste("Save project failed:", conditionMessage(e)))
        add_activity(paste("Save project failed:", conditionMessage(e)))
      })
    }

    load_project_action <- function() {
      ctx$project_message("")

      tryCatch({
        project_path <- normalize_project_load_path(input$project_path)
        if (!file.exists(project_path)) {
          stop(paste("Project file does not exist:", project_path), call. = FALSE)
        }

        project_state <- readRDS(project_path)
        loaded <- ctx$load_project_state(project_state)
        ctx$project_message(paste(loaded$messages, collapse = " "))
        add_activity(paste("Loaded project from", project_path))
      }, error = function(e) {
        ctx$project_message(paste("Load project failed:", conditionMessage(e)))
        add_activity(paste("Load project failed:", conditionMessage(e)))
      })
    }

    observeEvent(input$save_project, save_project_action(), ignoreInit = TRUE)
    observeEvent(input$save_project_secondary, save_project_action(), ignoreInit = TRUE)
    observeEvent(input$load_project, load_project_action(), ignoreInit = TRUE)
    observeEvent(input$load_project_secondary, load_project_action(), ignoreInit = TRUE)

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
        add_activity(paste("Saved project bundle to", bundle_paths$bundle_dir))
      }, error = function(e) {
        ctx$project_message(paste("Save bundle failed:", conditionMessage(e)))
        add_activity(paste("Save bundle failed:", conditionMessage(e)))
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
        add_activity(paste("Loaded project bundle from", bundle_dir))
      }, error = function(e) {
        ctx$project_message(paste("Load bundle failed:", conditionMessage(e)))
        add_activity(paste("Load bundle failed:", conditionMessage(e)))
      })
    }, ignoreInit = TRUE)
  })
}
