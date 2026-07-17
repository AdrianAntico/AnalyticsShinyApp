page_project_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Project",
    ui_page(
      title = "Project Workspace",
      subtitle = "Create, open, save, and understand the active analytical project.",
      eyebrow = "Project",
      div(
        class = "aq-project-reference aq-project-object",
        uiOutput(ns("project_persistent_context")),
        ui_choice_explainer(
          ns("project_chapter"),
          "Project Chapters",
          choices = list(
            list(value = "lifecycle", title = "Lifecycle", description = "Create, open, save, close, and choose where this project lives.", recommended = TRUE),
            list(value = "current", title = "Current Project", description = "Inspect what the open project currently contains."),
            list(value = "activity", title = "Activity", description = "Review what changed and where work should resume."),
            list(value = "administration", title = "Administration", description = "Open advanced project systems only when needed.")
          ),
          selected = "lifecycle"
        ),
        uiOutput(ns("project_chapter_surface"))
      )
    )
  )
}

page_project_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    project_actions <- reactiveVal(character())
    project_lifecycle_busy <- reactiveVal(FALSE)
    project_location_confirmed <- reactiveVal(NULL)
    genai_project_busy <- reactiveVal(FALSE)
    genai_project_action <- reactiveVal(NULL)
    genai_last_request <- reactiveVal(list(action = NULL, completed_at = as.POSIXct(NA)))

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

    output$feature_experiment_browser <- renderUI({
      state <- tryCatch(list(
        proposals = ctx$feature_experiment_state$proposals,
        executions = ctx$feature_experiment_state$executions,
        experiments = ctx$feature_experiment_state$experiments,
        adoptions = ctx$feature_experiment_state$adoptions
      ), error = function(e) list())
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      project_id <- if (is.list(project)) project$project_id %||% NULL else NULL
      summary <- tryCatch(feature_experiment_state_summary(state), error = function(e) data.table::data.table())
      history <- tryCatch(feature_experiment_history_table(state), error = function(e) data.table::data.table())
      recovery <- tryCatch(feature_experiment_recovery_summary(state, project_id = project_id), error = function(e) service_result(status = "error", errors = conditionMessage(e)))
      issues <- recovery$value$issues %||% data.table::data.table()
      recommendations <- recovery$value$recommendations %||% data.table::data.table()
      if (!nrow(summary)) {
        summary <- data.table::data.table(total_proposals = 0L, awaiting_review = 0L, approved_proposals = 0L, unsupported_or_blocked = 0L, executions = 0L, failed_executions = 0L, experiments = 0L, accepted = 0L, rejected = 0L, inconclusive = 0L, adoptions = 0L)
      }
      ui_card(
        title = "Feature Experiments",
        subtitle = "Governed proposal, Rodeo execution, challenger comparison, and adoption history.",
        ui_stat_grid(
          ui_stat_tile("Proposals", summary$total_proposals[[1]] %||% 0L, status = if ((summary$awaiting_review[[1]] %||% 0L) > 0L) "warning" else "neutral", detail = paste(summary$awaiting_review[[1]] %||% 0L, "awaiting review")),
          ui_stat_tile("Executions", summary$executions[[1]] %||% 0L, status = if ((summary$failed_executions[[1]] %||% 0L) > 0L) "error" else "info", detail = paste(summary$failed_executions[[1]] %||% 0L, "failed")),
          ui_stat_tile("Experiments", summary$experiments[[1]] %||% 0L, status = if ((summary$accepted[[1]] %||% 0L) > 0L) "success" else if ((summary$rejected[[1]] %||% 0L) > 0L) "info" else "neutral", detail = paste(summary$accepted[[1]] %||% 0L, "accepted")),
          ui_stat_tile("Adoptions", summary$adoptions[[1]] %||% 0L, status = if ((summary$adoptions[[1]] %||% 0L) > 0L) "success" else "neutral", detail = "explicit approvals")
        ),
        if (nrow(history)) {
          ui_disclosure(
            "Feature Experiment History",
            render_table(utils::tail(history, 25L), engine = "html", searchable = FALSE, sortable = FALSE),
            level = "common",
            open = TRUE
          )
        } else {
          ui_empty_state("No feature experiments yet.", "Run Model Readiness, prepare features, train a baseline, then generate governed feature proposals.")
        },
        ui_disclosure(
          "Recovery and Continuity",
          tagList(
            if (nrow(issues)) render_table(issues, engine = "html", searchable = FALSE, sortable = FALSE) else ui_callout("Feature experiment references reconcile", "No recovery action is currently required.", status = "success"),
            if (nrow(recommendations)) render_table(recommendations, engine = "html", searchable = FALSE, sortable = FALSE) else NULL
          ),
          level = "common",
          open = FALSE
        )
      )
    })

    observe({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (is.list(project) && identical(project$project_state %||% "", "project_ready")) {
        project_file <- project_path(project, "project.rds")
        bundle_dir <- project$project_root
        if (!identical(input$project_path, project_file)) {
          updateTextInput(session, "project_path", value = project_file)
        }
        if (!identical(input$bundle_dir, bundle_dir)) {
          updateTextInput(session, "bundle_dir", value = bundle_dir)
        }
      }
    })

    output$workspace_guard <- renderUI({
      result <- tryCatch(ctx$workspace_status_result(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) list())
      if (identical(result$status %||% "", "success")) {
        return(ui_callout("Project Location ready", workspace$workspace_root %||% "", status = "success"))
      }
      ui_callout(
        "Project Location required",
        paste(result$errors %||% "Choose a Project Location before saving artifacts, reports, layouts, or project results.", collapse = " "),
        status = "warning"
      )
    })

    output$workspace_provider_details <- renderUI({
      providers <- storage_provider_registry()
      provider <- providers[[lifecycle_provider_selection()]] %||% providers$local_server_directory
      caps <- provider$capabilities %||% list()
      cap_text <- paste(names(caps)[vapply(caps, isTRUE, logical(1))], collapse = ", ")
      if (!nzchar(cap_text)) cap_text <- "No interactive selection capabilities."
      ui_callout(
        paste("Selected option:", provider$display_name),
        paste(
          if (lifecycle_provider_available(provider)) "Available." else lifecycle_provider_unavailable_reason(provider),
          if (isTRUE(provider$managed)) "The app controls this location." else "You control this location.",
          if (!is.null(provider$root_path) && nzchar(provider$root_path %||% "")) {
            paste("Location:", provider$root_path)
          } else {
            "No real location value has been provided."
          },
          "Capabilities:", cap_text
        ),
        status = if (lifecycle_provider_available(provider)) "info" else "warning"
      )
    })

    output$project_guard <- renderUI({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (is.list(project) && identical(project$project_state %||% "", "project_ready")) {
        return(ui_callout(
          "Project ready",
          paste(project$project_name, "is saving project work in", project$project_root),
          status = "success"
        ))
      }
      ui_callout(
        "No project open",
        "Current analytical results are temporary and cannot be saved until a project is created or opened.",
        status = "warning"
      )
    })

    project_readout <- reactive({
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      data_info <- tryCatch(ctx$project_data_info(), error = function(e) list())
      artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
      plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) list())
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      project_ready <- is.list(project) && identical(project$project_state %||% "", "project_ready")
      collector_count <- if (nrow(collector)) collector$artifact_count[[1]] %||% 0L else 0L
      list(
        data = data,
        data_info = data_info,
        artifacts = artifacts,
        plans = plans,
        collector = collector,
        collector_count = collector_count,
        workspace = workspace,
        project = project,
        project_ready = project_ready,
        project_name = if (project_ready) project$project_name %||% "Open Project" else "No Project Open",
        project_root = if (project_ready) project$project_root %||% "" else "",
        dataset_label = if (is.null(data)) "No dataset loaded" else paste(data_info$name %||% "Loaded Data", "-", format(nrow(data), big.mark = ","), "rows"),
        evidence_label = paste(length(artifacts), "artifact(s),", length(plans), "report plan(s),", collector_count, "collector artifact(s)")
      )
    })

    project_next_step <- reactive({
      info <- project_readout()
      if (!isTRUE(info$project_ready)) {
        return(list(title = "Create or open a project", message = "Project work is temporary until a project is created or opened.", status = "warning"))
      }
      if (is.null(info$data)) {
        return(list(title = "Load data", message = "A project is open, but no dataset is loaded yet.", status = "info"))
      }
      if (!length(info$artifacts)) {
        return(list(title = "Run the first analysis", message = "Generate foundational evidence with Explore Data or Model Readiness.", status = "info"))
      }
      if ((info$collector_count %||% 0L) < 1L) {
        return(list(title = "Write evidence memory", message = "Artifacts exist; make sure the project evidence memory is updated.", status = "warning"))
      }
      list(title = "Review evidence", message = "Evidence is available. Artifact Studio or AI Assistance can help inspect the project.", status = "success")
    })

    lifecycle_location_input <- reactive({
      provider_id <- lifecycle_provider_selection()
      provider <- lifecycle_provider(provider_id)
      raw <- input$workspace_root %||% ""
      source <- "manual_entry"
      if (!is.null(provider$root_path) && nzchar(provider$root_path %||% "")) {
        raw <- provider$root_path
        source <- "provider_root"
      }
      if (!nzchar(trimws(raw)) && !is.null(project_location_confirmed())) {
        raw <- project_location_confirmed()
        source <- "confirmed_location"
      }
      normalized <- storage_normalize_path(raw, must_work = FALSE)
      list(provider_id = provider_id, raw = raw, normalized = normalized, source = source)
    })

    lifecycle_provider_registry <- reactive({
      storage_provider_registry()
    })

    lifecycle_provider <- function(provider_id = NULL) {
      providers <- lifecycle_provider_registry()
      providers[[provider_id %||% "local_server_directory"]] %||% providers$local_server_directory
    }

    lifecycle_provider_available <- function(provider) {
      isTRUE(provider$available) && (
        identical(provider$provider_id, "local_server_directory") ||
          isTRUE(provider$selection_supported) ||
          (!is.null(provider$root_path) && nzchar(provider$root_path %||% ""))
      )
    }

    lifecycle_provider_unavailable_reason <- function(provider) {
      switch(
        provider$provider_id %||% "",
        configured_workspace = "No saved Project Location exists yet. Use Local Folder first, then save or create a project.",
        managed_workspace = "No app-managed location is available in this environment.",
        native_host_directory = "The host folder picker is not available in this environment.",
        "This location type is unavailable in the current runtime."
      )
    }

    lifecycle_provider_selection <- reactive({
      providers <- lifecycle_provider_registry()
      selected <- input$workspace_provider %||% "local_server_directory"
      provider <- providers[[selected]]
      if (is.null(provider) || !lifecycle_provider_available(provider)) {
        "local_server_directory"
      } else {
        selected
      }
    })

    lifecycle_location_choices <- reactive({
      providers <- lifecycle_provider_registry()
      provider_choice <- function(provider_id, title, description, recommended = FALSE) {
        provider <- providers[[provider_id]]
        enabled <- !is.null(provider) && lifecycle_provider_available(provider)
        list(
          value = provider_id,
          title = title,
          description = description,
          recommended = isTRUE(recommended),
          enabled = enabled,
          unavailable_reason = if (enabled) "" else lifecycle_provider_unavailable_reason(provider %||% list(provider_id = provider_id))
        )
      }
      list(
        provider_choice("local_server_directory", "Local Folder", "Paste a Windows folder path. Best default for local desktop work.", recommended = TRUE),
        provider_choice("configured_workspace", "Saved Location", "Reuse the project location already saved for this app."),
        provider_choice("managed_workspace", "App-Managed Location", "Use a deployment-provided managed location."),
        provider_choice("native_host_directory", "Choose Location", "Use the host folder picker when available.")
      )
    })

    lifecycle_location_value <- reactive({
      provider <- lifecycle_provider(lifecycle_provider_selection())
      if (!is.null(provider$root_path) && nzchar(provider$root_path %||% "")) {
        return(provider$root_path)
      }
      current_location_value <- input$workspace_root %||% ""
      if (nzchar(trimws(current_location_value))) current_location_value else project_location_confirmed() %||% ""
    })

    lifecycle_location_is_confirmed <- reactive({
      location <- lifecycle_location_input()
      if (is.null(location$normalized)) {
        return(FALSE)
      }
      identical(location$source, "provider_root") ||
        identical(project_location_confirmed(), location$normalized)
    })

    lifecycle_project_name <- reactive({
      trimws(input$project_name %||% "")
    })

    lifecycle_create_state <- reactive({
      location <- lifecycle_location_input()
      project_name <- lifecycle_project_name()
      project_id <- if (nzchar(project_name)) safe_path_component(project_name, "project") else ""
      destination <- if (!is.null(location$normalized) && nzchar(project_id)) {
        storage_normalize_path(file.path(location$normalized, project_id), must_work = FALSE)
      } else {
        NULL
      }
      missing <- character()
      warnings <- character()
      ready <- TRUE

      if (is.null(location$normalized)) {
        ready <- FALSE
        missing <- c(missing, "Enter or choose a Project Location.")
      }
      if (!nzchar(project_name)) {
        ready <- FALSE
        missing <- c(missing, "Enter a Project Name.")
      }
      if (!is.null(location$normalized) && file.exists(location$normalized) && !dir.exists(location$normalized)) {
        ready <- FALSE
        missing <- c(missing, "Project Location must be a folder, not a file.")
      }
      if (!is.null(location$normalized) && !isTRUE(lifecycle_location_is_confirmed())) {
        ready <- FALSE
        missing <- c(missing, "Confirm the Project Location.")
      }
      if (!is.null(destination) && file.exists(destination)) {
        if (dir.exists(destination) && length(list.files(destination, all.files = TRUE, no.. = TRUE))) {
          ready <- FALSE
          missing <- c(missing, "A non-empty project destination already exists.")
        } else if (!dir.exists(destination)) {
          ready <- FALSE
          missing <- c(missing, "The derived project destination points to a file.")
        }
      }
      if (!is.null(location$normalized) && !dir.exists(location$normalized)) {
        warnings <- c(warnings, "Project Location folder will be created.")
      }
      if (!is.null(destination) && !file.exists(destination)) {
        warnings <- c(warnings, "Project destination will be created.")
      }

      list(
        ready = isTRUE(ready),
        location = location,
        project_name = project_name,
        project_id = project_id,
        destination = destination,
        missing = missing,
        warnings = warnings
      )
    })

    lifecycle_open_state <- reactive({
      location <- lifecycle_location_input()
      normalized <- location$normalized
      candidate <- NULL
      status <- "warning"
      message <- "Choose an existing project location."
      ready <- FALSE

      if (!is.null(normalized)) {
        if (file.exists(normalized) && !dir.exists(normalized) && grepl("\\.rds$", normalized, ignore.case = TRUE)) {
          candidate <- normalized
        } else if (dir.exists(normalized)) {
          candidate <- file.path(normalized, "project.rds")
        }
        if (!is.null(candidate) && file.exists(candidate)) {
          ready <- TRUE
          status <- "success"
          message <- paste("Existing project detected:", candidate)
        } else if (!is.null(normalized) && dir.exists(normalized)) {
          status <- "warning"
          message <- "This folder does not contain a saved project yet."
        } else {
          status <- "warning"
          message <- "Project location does not exist yet."
        }
      }

      list(
        ready = ready,
        location = location,
        project_file = candidate,
        status = status,
        message = message
      )
    })

    lifecycle_create_feedback <- function(state) {
      if (isTRUE(state$ready)) {
        return(ui_callout(
          "Destination is ready",
          paste("New project will be created at:", state$destination),
          status = "success"
        ))
      }
      ui_callout(
        "Create Project is waiting",
        paste(c(state$missing, state$warnings), collapse = " "),
        status = "warning"
      )
    }

    lifecycle_location_status_callout <- function(intent = "create") {
      requested <- input$workspace_provider %||% lifecycle_provider_selection()
      selected <- lifecycle_provider_selection()
      provider <- lifecycle_provider(selected)
      location <- lifecycle_location_input()
      fallback <- !identical(requested, selected)
      available <- lifecycle_provider_available(provider)
      has_real_location <- !is.null(location$normalized)
      confirmed <- isTRUE(lifecycle_location_is_confirmed())
      title <- if (!available) {
        paste(provider$display_name %||% "Project Location", "unavailable")
      } else if (!has_real_location) {
        "No project location selected yet"
      } else if (confirmed) {
        "Project location confirmed"
      } else {
        "Location entered"
      }
      next_action <- if (fallback) {
        paste("The requested location type is unavailable, so Local Folder is selected instead.")
      } else if (!available) {
        lifecycle_provider_unavailable_reason(provider)
      } else if (!has_real_location) {
        "Paste a folder path or choose an available location option."
      } else if (confirmed && identical(intent, "open")) {
        "Open becomes available when project.rds is detected."
      } else if (confirmed) {
        "Name the project to continue."
      } else if (identical(location$source, "manual_entry")) {
        "Confirm this location to continue."
      } else {
        "Review this location to continue."
      }
      ui_callout(
        title,
        paste(
          "Selected location type:", ui_display_label(selected),
          if (has_real_location) paste("Location:", location$normalized) else "No real location value has been provided.",
          "Next:", next_action
        ),
        status = if (fallback || !available) "warning" else if (confirmed) "success" else "info"
      )
    }

    output$project_persistent_context <- renderUI({
      info <- project_readout()
      next_step <- project_next_step()
      actions <- project_actions()
      message <- ctx$project_message()
      project_state <- if (isTRUE(info$project_ready)) "Project is open" else "No durable project yet"
      latest_activity <- if (length(actions)) actions[[1]] else if (!is.null(message) && nzchar(message)) message else "No project activity yet."

      ui_card(
        title = "The Project",
        subtitle = "The object remains visible. Chapters change the aspect of the project you are reading.",
        class = "aq-project-object-context",
        div(
          class = "aq-project-object-summary",
          div(
            class = "aq-project-object-title",
            tags$span(class = "aq-kicker", if (isTRUE(info$project_ready)) "ACTIVE PROJECT" else "PROJECT NOT YET SAVED"),
            tags$h2(info$project_name),
            tags$p(if (isTRUE(info$project_ready)) "Persistent owner of data, evidence, reports, and AI-ready context." else "Create or open a project to start durable project memory.")
          ),
          div(
            class = "aq-project-object-facts",
            ui_stat_tile("Status", project_state, status = if (isTRUE(info$project_ready)) "success" else "warning"),
            ui_stat_tile("Project Location", if (nzchar(info$project_root)) "Ready" else ui_display_label(info$workspace$provider_id %||% "local_server_directory"), status = if (isTRUE(info$project_ready)) "success" else "warning", detail = if (nzchar(info$project_root)) info$project_root else "Choose a location"),
            ui_stat_tile("Dataset", info$dataset_label, status = if (is.null(info$data)) "neutral" else "success"),
            ui_stat_tile("Evidence", info$evidence_label, status = if (length(info$artifacts)) "success" else "neutral"),
            ui_stat_tile("Next Action", next_step$title, status = next_step$status, detail = next_step$message),
            ui_stat_tile("Recent Activity", latest_activity, status = if (length(actions) || nzchar(message %||% "")) "success" else "neutral")
          )
        )
      )
    })

    output$project_chapter_surface <- renderUI({
      chapter <- input$project_chapter %||% "lifecycle"
      info <- project_readout()
      next_step <- project_next_step()
      actions <- project_actions()
      message <- ctx$project_message()
      project_file_value <- input$project_path %||% if (isTRUE(info$project_ready)) project_path(info$project, "project.rds") else ""
      lifecycle_intent <- input$lifecycle_intent %||% "create"
      create_state <- lifecycle_create_state()
      open_state <- lifecycle_open_state()
      busy <- isTRUE(project_lifecycle_busy())
      lifecycle_button <- function(input_id, label, class = "btn-primary btn-sm", enabled = TRUE) {
        button <- actionButton(ns(input_id), label, class = class)
        if (!isTRUE(enabled)) {
          button <- htmltools::tagAppendAttributes(button, disabled = "disabled", `aria-disabled` = "true")
        }
        button
      }

      lifecycle <- function() {
        if (isTRUE(info$project_ready)) {
          return(ui_card(
            title = "Chapter 1: Lifecycle",
            subtitle = "Save, move, bundle, or close the active project.",
            class = "aq-project-chapter-surface",
            div(
              class = "aq-project-chapter-body",
              tags$section(
                class = "aq-project-chapter-section",
                div(
                  class = "aq-project-section-copy",
                  tags$h3("Project is open"),
                  tags$p("Lifecycle actions now operate on the active project. Creation and opening are available after closing or moving to advanced recovery.")
                ),
                div(
                  class = "aq-project-lifecycle-editorial",
                  tags$dl(
                    class = "aq-module-run-summary aq-project-summary-list",
                    tags$dt("Project Name"),
                    tags$dd(info$project_name),
                    tags$dt("Project Location"),
                    tags$dd(info$project_root),
                    tags$dt("Save State"),
                    tags$dd("Save is available for the active project.")
                  ),
                  ui_action_row(
                    lifecycle_button("save_project_secondary", if (busy) "Saving..." else "Save Project", class = "btn-success btn-sm", enabled = !busy),
                    lifecycle_button("close_project", "Close Project", class = "btn-secondary btn-sm", enabled = !busy)
                  ),
                  if (!is.null(message) && nzchar(message)) tags$p(class = "aq-export-message", message)
                )
              ),
              ui_disclosure(
                "Move / Save As",
                ui_callout("Planned lifecycle depth", "Move Project and Save As remain explicit future operations. They are not mixed into the creation sequence.", status = "info"),
                level = "advanced",
                open = FALSE
              ),
              ui_disclosure(
                "Portable Project Bundle",
                tagList(
                  tags$p(class = "aq-muted-note", "Use this when moving a complete project between environments."),
                  textInput(ns("bundle_dir"), "Bundle Location", value = input$bundle_dir %||% info$project_root),
                  ui_action_row(
                    actionButton(ns("save_bundle"), "Save Bundle", class = "btn-primary btn-sm"),
                    actionButton(ns("load_bundle"), "Load Bundle", class = "btn-secondary btn-sm")
                  )
                ),
                level = "advanced",
                open = FALSE
              )
            )
          ))
        }

        ui_card(
          title = "Chapter 1: Lifecycle",
          subtitle = "Choose where the project lives, then create or open it.",
          class = "aq-project-chapter-surface",
          div(
            class = "aq-project-chapter-body",
            tags$section(
              class = "aq-project-chapter-section",
              div(
                class = "aq-project-section-copy",
                tags$h3("1. Choose what you are doing"),
                tags$p("Lifecycle begins with intent. Creating and opening have different prerequisites, so the page only shows the flow that applies.")
              ),
              div(
                class = "aq-project-lifecycle-editorial",
                ui_choice_explainer(
                  ns("lifecycle_intent"),
                  "Lifecycle Intent",
                  choices = list(
                    list(value = "create", title = "Create New Project", description = "Choose a location, name the project, then create durable project memory.", recommended = TRUE),
                    list(value = "open", title = "Open Existing Project", description = "Choose an existing project location and let the app find the saved project file.")
                  ),
                  selected = lifecycle_intent
                )
              )
            ),
            tags$section(
              class = "aq-project-chapter-section",
              div(
                class = "aq-project-section-copy",
                tags$h3(if (identical(lifecycle_intent, "open")) "2. Choose existing project location" else "2. Choose or confirm project location"),
                tags$p(if (identical(lifecycle_intent, "open")) "Use the folder where the existing project lives. The app discovers the internal saved project file." else "This is the parent location where the new project will be created. One user-facing path; technical details stay behind disclosure.")
              ),
              div(
                class = "aq-project-location-editorial",
                ui_choice_explainer(
                  ns("workspace_provider"),
                  "Location Type",
                  choices = lifecycle_location_choices(),
                  selected = lifecycle_provider_selection()
                ),
                lifecycle_location_status_callout(lifecycle_intent),
                div(
                  class = "aq-project-location-path",
                  {
                    location_field <- textInput(
                      ns("workspace_root"),
                      "Project Location",
                      value = lifecycle_location_value(),
                      placeholder = "C:\\Users\\YourName\\Documents\\AnalyticsWorkstationProjects"
                    )
                    if (!identical(lifecycle_provider_selection(), "local_server_directory")) {
                      location_field <- htmltools::tagAppendAttributes(location_field, `data-provider-controlled` = "true")
                      if (length(location_field$children) >= 2L) {
                        location_field$children[[2]] <- htmltools::tagAppendAttributes(
                          location_field$children[[2]],
                          readonly = "readonly",
                          `aria-readonly` = "true"
                        )
                      }
                    }
                    location_field
                  },
                  if (identical(lifecycle_intent, "create")) {
                    location <- lifecycle_location_input()
                    lifecycle_button(
                      "confirm_project_location",
                      "Confirm Project Location",
                      class = "btn-secondary btn-sm",
                      enabled = identical(location$source, "manual_entry") &&
                        !is.null(location$normalized) &&
                        !busy
                    )
                  }
                ),
                if (identical(lifecycle_intent, "open")) {
                  ui_callout(if (isTRUE(open_state$ready)) "Existing project detected" else "Open Project is waiting", open_state$message, status = open_state$status)
                } else {
                  lifecycle_create_feedback(create_state)
                },
                ui_disclosure(
                  "Open project file directly",
                  tagList(
                    textInput(ns("project_path"), "Saved Project File", value = project_file_value),
                    tags$p(class = "aq-muted-note", "Advanced recovery only. The normal Open Existing Project flow discovers this file from Project Location.")
                  ),
                  level = "advanced",
                  open = FALSE
                ),
                ui_disclosure(
                  "Location Details",
                  tagList(
                    uiOutput(ns("workspace_location_summary")),
                    uiOutput(ns("workspace_provider_details"))
                  ),
                  level = "advanced",
                  open = FALSE
                )
              )
            ),
            if (identical(lifecycle_intent, "create")) {
              tags$section(
                class = "aq-project-chapter-section",
                div(
                  class = "aq-project-section-copy",
                  tags$h3("3. Name the project"),
                  tags$p("The project name determines the final project directory inside the selected Project Location.")
                ),
                div(
                  class = "aq-project-lifecycle-editorial",
                  textInput(ns("project_name"), "Project Name", value = input$project_name %||% ""),
                  ui_callout(
                    if (isTRUE(create_state$ready)) "Resolved destination" else "Destination preview",
                    if (!is.null(create_state$destination)) paste("New project will be created at:", create_state$destination) else "Enter a Project Location and Project Name to preview the destination.",
                    status = if (isTRUE(create_state$ready)) "success" else "info"
                  )
                )
              )
            },
            tags$section(
              class = "aq-project-chapter-section",
              div(
                class = "aq-project-section-copy",
                tags$h3(if (identical(lifecycle_intent, "open")) "3. Open the project" else "4. Create the project"),
                tags$p(if (identical(lifecycle_intent, "open")) "Open becomes available only after a saved project is detected." else "Create becomes available only after location and project name resolve to a valid destination.")
              ),
              div(
                class = "aq-project-lifecycle-editorial",
                if (identical(lifecycle_intent, "open")) {
                  ui_action_row(
                    lifecycle_button("load_project_secondary", if (busy) "Opening..." else "Open Project", class = "btn-primary btn-sm", enabled = isTRUE(open_state$ready) && !busy)
                  )
                } else {
                  ui_action_row(
                    lifecycle_button("create_project", if (busy) "Creating..." else "Create Project", class = "btn-primary btn-sm", enabled = isTRUE(create_state$ready) && !busy)
                  )
                },
                if (!is.null(message) && nzchar(message)) tags$p(class = "aq-export-message", message)
              )
            ),
            ui_disclosure(
              "Portable Project Bundle",
              tagList(
                tags$p(class = "aq-muted-note", "Portable bundles are lifecycle depth after a project exists or when restoring from a bundle."),
                textInput(ns("bundle_dir"), "Bundle Location", value = input$bundle_dir %||% ""),
                ui_action_row(actionButton(ns("load_bundle"), "Load Bundle", class = "btn-secondary btn-sm"))
              ),
              level = "advanced",
              open = FALSE
            )
          )
        )
      }

      current <- function() {
        ui_card(
          title = "Chapter 2: Current Project",
          subtitle = "What the open project currently contains.",
          class = "aq-project-chapter-surface",
          div(
            class = "aq-project-chapter-body",
            tags$dl(
              class = "aq-module-run-summary aq-project-summary-list",
              tags$dt("Project"),
              tags$dd(info$project_name),
              tags$dt("Project Location"),
              tags$dd(if (nzchar(info$project_root)) info$project_root else "No project location yet"),
              tags$dt("Data"),
              tags$dd(info$dataset_label),
              tags$dt("Evidence"),
              tags$dd(info$evidence_label)
            ),
            uiOutput(ns("workspace_progress")),
            ui_callout(next_step$title, next_step$message, status = next_step$status)
          )
        )
      }

      activity <- function() {
        activity_body <- if (length(actions)) {
          ui_activity_list(actions)
        } else {
          ui_empty_state(
            if (isTRUE(info$project_ready)) "Project is open." else "No project activity yet.",
            if (isTRUE(info$project_ready)) paste("Current next step:", next_step$title) else "Create or open a project to start the activity trail."
          )
        }
        ui_card(
          title = "Chapter 3: Activity",
          subtitle = "What changed and where work should resume.",
          class = "aq-project-chapter-surface",
          div(
            class = "aq-project-chapter-body",
            if (!is.null(message) && nzchar(message)) tags$p(class = "aq-export-message", message),
            activity_body,
            ui_callout("Resume point", next_step$message, status = next_step$status)
          )
        )
      }

      administration <- function() {
        ui_card(
          title = "Chapter 4: Administration",
          subtitle = "Advanced project systems. Open these only when the project needs operational depth.",
          class = "aq-project-chapter-surface",
          div(
            class = "aq-project-chapter-body aq-project-systems-editorial",
            uiOutput(ns("project_systems_summary")),
            selectInput(
              ns("project_system_detail"),
              "Project System",
              choices = c(
                "AI Assistance" = "ai_assistance",
                "Evidence Strategy" = "evidence_strategy",
                "Persisted Results" = "persisted_results",
                "Feature Experiments" = "feature_experiments",
                "GenAI Jobs" = "genai_jobs",
                "Improvement Ledger" = "improvement_ledger",
                "Remediation Plans" = "remediation_plans",
                "Action Audit" = "action_audit",
                "Technical Signals" = "technical_signals"
              ),
              selected = input$project_system_detail %||% "ai_assistance"
            ),
            uiOutput(ns("project_system_detail_panel"))
          )
        )
      }

      switch(
        chapter,
        lifecycle = lifecycle(),
        current = current(),
        activity = activity(),
        administration = administration(),
        lifecycle()
      )
    })

    output$project_systems_summary <- renderUI({
      uiOutput(ns("project_operations_summary"))
    })

    output$project_system_detail_panel <- renderUI({
      selected <- input$project_system_detail %||% "ai_assistance"
      switch(
        selected,
        ai_assistance = uiOutput(ns("project_intelligence_panel")),
        evidence_strategy = uiOutput(ns("evidence_strategy_panel")),
        persisted_results = uiOutput(ns("persisted_results_browser")),
        feature_experiments = uiOutput(ns("feature_experiment_browser")),
        genai_jobs = uiOutput(ns("genai_job_monitor")),
        improvement_ledger = uiOutput(ns("improvement_ledger_browser")),
        remediation_plans = uiOutput(ns("remediation_plan_browser")),
        action_audit = uiOutput(ns("genai_audit_ledger_browser")),
        technical_signals = ui_card(
          title = "Technical Signals",
          subtitle = "Storage, project state, modeling data, and collector details.",
          ui_disclosure("Project Signals", uiOutput(ns("workspace_status")), level = "advanced", open = TRUE),
          ui_disclosure("Modeling Data", uiOutput(ns("modeling_context_panel")), level = "advanced", open = FALSE),
          ui_disclosure("Collector", uiOutput(ns("collector_panel")), level = "advanced", open = FALSE)
        ),
        uiOutput(ns("project_intelligence_panel"))
      )
    })

    output$workspace_location_summary <- renderUI({
      provider_id <- lifecycle_provider_selection()
      provider <- lifecycle_provider(provider_id)
      location <- lifecycle_location_input()
      available <- lifecycle_provider_available(provider)
      has_real_location <- !is.null(location$normalized)
      confirmed <- isTRUE(lifecycle_location_is_confirmed())
      next_action <- if (!available) {
        lifecycle_provider_unavailable_reason(provider)
      } else if (!has_real_location) {
        "Paste a folder path or choose an available location option."
      } else if (confirmed) {
        "Location is ready for the current workflow."
      } else if (identical(location$source, "manual_entry")) {
        "Confirm this location to continue."
      } else {
        "Review this location to continue."
      }
      ui_callout(
        if (!available) paste(ui_display_label(provider_id), "unavailable") else if (!has_real_location) "No project location selected yet" else if (confirmed) "Project location confirmed" else "Location entered",
        paste(
          "Selected:", ui_display_label(provider_id),
          if (has_real_location) paste("Location:", location$normalized) else "No real location value has been provided.",
          "Next:", next_action
        ),
        status = if (!available) "warning" else if (confirmed) "success" else "info"
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
      next_message <- switch(
        active,
        data = "Load a dataset on the Data page or open an existing project.",
        analysis = "Run Explore Data from Analysis Modules to generate the first evidence layer.",
        collector = "Review generated artifacts and make sure collector output is written before reporting.",
        ai = "Inspect Artifact Studio or ask the Guide for a project brief.",
        "Review Mission Control for the next project action."
      )
      next_status <- if (identical(active, "ai")) "success" else "info"

      ui_card(
        title = "Workspace Progress",
        subtitle = "Project -> data -> analysis -> evidence memory -> AI-ready context.",
        ui_progress_steps(
          steps = c(
            project = "Project",
            data = "Data",
            analysis = "Analysis",
            artifacts = "Artifacts",
            reports = "Reports",
            collector = "Evidence Memory",
            ai = "AI Ready"
          ),
          active = active,
          completed = completed
        ),
        ui_callout("Next step", next_message, status = next_status)
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

    output$genai_provider_panel <- renderUI({
      strategy <- ctx$evidence_strategy_config()
      frontier <- evidence_strategy_frontier_summary(strategy)
      busy <- isTRUE(genai_project_busy())
      busy_action <- genai_project_action() %||% "AI request"
      tagList(
        ui_genai_status_panel(
          ctx$genai_status(check_availability = FALSE),
          title = "AI Assistance",
          actions = ui_action_row(
            actionButton(ns("brief_project"), if (busy) "Working..." else "Brief Project", class = "btn-primary btn-sm", disabled = if (busy) "disabled" else NULL),
            actionButton(ns("suggest_next_action"), if (busy) "Working..." else "Suggest Next Action", class = "btn-secondary btn-sm", disabled = if (busy) "disabled" else NULL)
          ),
          result = if (busy) {
            service_result(status = "warning", messages = paste(busy_action, "is running. Please wait before requesting another AI response."))
          } else {
            ctx$genai_last_result()
          }
        ),
        ui_card(
          title = "Evidence Strategy",
          subtitle = "Decision posture for future evidence routing.",
          div(
            class = "aw-evidence-strategy",
            selectInput(
              ns("evidence_strategy"),
              "Evidence Strategy",
              choices = stats::setNames(evidence_strategy_ids(), vapply(evidence_strategy_registry(), function(x) x$strategy_label, character(1))),
              selected = ctx$evidence_strategy()
            ),
            div(
              class = "aw-meta-grid",
              div(class = "aw-meta-item", span("Cost"), strong(frontier$estimated_token_cost[[1]])),
              div(class = "aw-meta-item", span("Completeness"), strong(frontier$estimated_evidence_completeness[[1]])),
              div(class = "aw-meta-item", span("Nuance Risk"), strong(frontier$risk_of_missing_nuance[[1]])),
              div(class = "aw-meta-item", span("Provider"), strong(frontier$provider_privacy_posture[[1]]))
            ),
            tags$p(class = "aw-muted", strategy$strategy_description)
          )
        )
      )
    })

    output$project_intelligence_panel <- renderUI({
      busy <- isTRUE(genai_project_busy())
      busy_action <- genai_project_action() %||% "AI request"
      ui_genai_status_panel(
        ctx$genai_status(check_availability = FALSE),
        title = "AI Assistance",
        actions = ui_action_row(
          actionButton(ns("brief_project"), if (busy) "Working..." else "Brief Project", class = "btn-primary btn-sm", disabled = if (busy) "disabled" else NULL),
          actionButton(ns("suggest_next_action"), if (busy) "Working..." else "Suggest Next Action", class = "btn-secondary btn-sm", disabled = if (busy) "disabled" else NULL)
        ),
        result = if (busy) {
          service_result(status = "warning", messages = paste(busy_action, "is running. Please wait before requesting another AI response."))
        } else {
          ctx$genai_last_result()
        }
      )
    })

    output$evidence_strategy_panel <- renderUI({
      strategy <- ctx$evidence_strategy_config()
      frontier <- evidence_strategy_frontier_summary(strategy)
      ui_card(
        title = "Evidence Strategy",
        subtitle = "How future evidence should balance cost, completeness, privacy, and nuance.",
        div(
          class = "aw-evidence-strategy",
          selectInput(
            ns("evidence_strategy"),
            "Strategy",
            choices = stats::setNames(evidence_strategy_ids(), vapply(evidence_strategy_registry(), function(x) x$strategy_label, character(1))),
            selected = ctx$evidence_strategy()
          ),
          div(
            class = "aw-meta-grid",
            div(class = "aw-meta-item", span("Cost"), strong(frontier$estimated_token_cost[[1]])),
            div(class = "aw-meta-item", span("Completeness"), strong(frontier$estimated_evidence_completeness[[1]])),
            div(class = "aw-meta-item", span("Nuance Risk"), strong(frontier$risk_of_missing_nuance[[1]])),
            div(class = "aw-meta-item", span("Provider"), strong(frontier$provider_privacy_posture[[1]]))
          ),
          tags$p(class = "aw-muted", strategy$strategy_description),
          ui_disclosure(
            "Technical Strategy Details",
            render_table(frontier, engine = "html", searchable = FALSE, sortable = FALSE),
            level = "advanced",
            open = FALSE
          )
        )
      )
    })

    output$project_operations_summary <- renderUI({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      project_ready <- is.list(project) && identical(project$project_state %||% "", "project_ready")
      persisted <- tryCatch(persisted_result_rows(), error = function(e) data.table::data.table())
      feature_state <- tryCatch(feature_experiment_state_summary(list(
        proposals = ctx$feature_experiment_state$proposals,
        executions = ctx$feature_experiment_state$executions,
        experiments = ctx$feature_experiment_state$experiments,
        adoptions = ctx$feature_experiment_state$adoptions
      )), error = function(e) data.table::data.table())
      jobs <- tryCatch(if (project_ready) genai_job_summary(project) else data.table::data.table(), error = function(e) data.table::data.table())
      improvements <- tryCatch(if (project_ready) improvement_ledger_summary(project) else data.table::data.table(), error = function(e) data.table::data.table())
      remediations <- tryCatch(remediation_plan_state()$table, error = function(e) data.table::data.table())
      audits <- tryCatch(audit_ledger_state()$events, error = function(e) data.table::data.table())
      feature_proposals <- if (nrow(feature_state)) feature_state$total_proposals[[1]] %||% 0L else 0L
      open_improvements <- if (nrow(improvements)) improvements$open_items[[1]] %||% 0L else 0L
      failed_jobs <- if (nrow(jobs) && "status" %in% names(jobs)) sum(jobs$status %in% c("failed", "error"), na.rm = TRUE) else 0L
      ui_card(
        title = "Project Operations",
        subtitle = "Operational systems stay secondary. Open one detail pane when needed.",
        ui_stat_grid(
          ui_stat_tile("Persisted Results", nrow(persisted), status = if (nrow(persisted)) "info" else "neutral"),
          ui_stat_tile("Feature Experiments", feature_proposals, status = if (feature_proposals > 0L) "info" else "neutral"),
          ui_stat_tile("GenAI Jobs", nrow(jobs), status = if (failed_jobs > 0L) "error" else if (nrow(jobs)) "info" else "neutral", detail = paste(failed_jobs, "failed")),
          ui_stat_tile("Improvements", open_improvements, status = if (open_improvements > 0L) "warning" else "neutral", detail = "open"),
          ui_stat_tile("Remediation Plans", nrow(remediations), status = if (nrow(remediations)) "info" else "neutral"),
          ui_stat_tile("Audit Events", nrow(audits), status = if (nrow(audits)) "info" else "neutral")
        )
      )
    })

    output$project_operation_detail_panel <- renderUI({
      selected <- input$project_operation_detail %||% "persisted_results"
      switch(
        selected,
        persisted_results = uiOutput(ns("persisted_results_browser")),
        feature_experiments = uiOutput(ns("feature_experiment_browser")),
        genai_jobs = uiOutput(ns("genai_job_monitor")),
        improvement_ledger = uiOutput(ns("improvement_ledger_browser")),
        remediation_plans = uiOutput(ns("remediation_plan_browser")),
        action_audit = uiOutput(ns("genai_audit_ledger_browser")),
        uiOutput(ns("persisted_results_browser"))
      )
    })

    output$workspace_status <- renderUI({
      data_info <- tryCatch(ctx$project_data_info(), error = function(e) list(path = NULL, name = NULL))
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      rows <- data.table::data.table(
        item = c("File Location", "Folder", "Project", "Project Folder", "Dataset", "Source File", "AI Context", "Evidence Document", "Evidence Index", "Latest Run"),
        value = c(
          ui_display_label(ctx$current_workspace()$provider_id %||% "No provider configured"),
          ctx$current_workspace()$workspace_root %||% "No workspace configured",
          ctx$current_project()$project_name %||% "No project open",
          ctx$current_project()$project_root %||% "No project root",
          data_info$name %||% "No dataset loaded",
          data_info$path %||% "No source path",
          if (nrow(collector)) ui_display_label(collector$render_target[[1]] %||% "llm_docx") else "LLM DOCX",
          if (nrow(collector)) collector$collector_docx[[1]] else "Evidence document not created",
          if (nrow(collector)) ui_status_label(collector$manifest_status[[1]]) else "Not Written",
          if (nrow(collector)) collector$current_run_id[[1]] else "No run yet"
        )
      )
      render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$modeling_context_panel <- renderUI({
      context <- ctx$current_modeling_context()
      validation <- ctx$validate_active_modeling_context()
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      data_info <- tryCatch(ctx$project_data_info(), error = function(e) list())
      artifact_id <- context$active_dataset_artifact_id %||% NA_character_
      ui_card(
        title = "Modeling Data",
        subtitle = "The dataset currently available to modeling and analysis steps.",
        class = "aq-compact-card",
        ui_action_row(
          ui_status_badge(
            ui_status_label(context$active_dataset_source %||% "source_dataset"),
            status = if (identical(validation$status, "success")) "success" else if (identical(validation$status, "warning")) "warning" else "error"
          ),
          if (!is.na(artifact_id) && nzchar(artifact_id)) {
            ui_status_badge("Prepared Data", status = "info")
          }
        ),
        tags$dl(
          class = "aq-module-run-summary",
          tags$dt("Dataset"),
          tags$dd(data_info$name %||% context$active_dataset_label %||% "Active Dataset"),
          tags$dt("Rows"),
          tags$dd(if (is.null(data)) "Not loaded" else format(nrow(data), big.mark = ",")),
          tags$dt("Columns"),
          tags$dd(if (is.null(data)) "Not loaded" else format(ncol(data), big.mark = ",")),
          tags$dt("Source"),
          tags$dd(if (!is.na(artifact_id) && nzchar(artifact_id)) "Prepared data artifact" else "Original or loaded dataset"),
          tags$dt("Source File"),
          tags$dd(data_info$path %||% "No source file recorded")
        ),
        if (!identical(validation$status, "success")) {
          ui_callout(
            "Context needs attention",
            paste(c(validation$errors, validation$warnings), collapse = " | "),
            status = if (identical(validation$status, "error")) "error" else "warning"
          )
        }
      )
    })

    output$collector_panel <- renderUI({
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      ui_collector_status_panel(collector)
    })

    persisted_result_rows <- reactive({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(data.table::data.table())
      }
      tryCatch(list_project_persisted_results(project, include_invalid = TRUE), error = function(e) {
        data.table::data.table(
          persisted_result_id = "unavailable",
          display_name = "Persisted results unavailable",
          result_type = NA_character_,
          module_id = NA_character_,
          dataset_id = NA_character_,
          persisted_at = NA_character_,
          health_status = "unavailable",
          manifest_status = "unavailable",
          hash_status = "not_validated",
          validation_errors = conditionMessage(e),
          safe_relative_location = "results/"
        )
      })
    })

    improvement_ledger_state <- reactive({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(list(project = project, result = NULL, items = list(), table = data.table::data.table(), health = "unavailable"))
      }
      result <- tryCatch(improvement_load_items(project), error = function(e) service_result(status = "error", errors = conditionMessage(e)))
      if (!identical(result$status, "success")) {
        return(list(project = project, result = result, items = list(), table = data.table::data.table(), health = "unavailable"))
      }
      list(project = project, result = result, items = result$value$items, table = improvement_item_table(result$value$items), health = result$value$ledger_health)
    })

    filtered_improvement_items <- reactive({
      table <- improvement_ledger_state()$table
      if (!nrow(table)) return(table)
      filters <- list(
        status = input$improvement_status_filter %||% "__open__",
        item_type = input$improvement_type_filter %||% "__all__",
        severity = input$improvement_severity_filter %||% "__all__",
        priority = input$improvement_priority_filter %||% "__all__",
        confidence = input$improvement_confidence_filter %||% "__all__"
      )
      if (identical(filters$status, "__open__")) {
        table <- table[!status %in% improvement_terminal_statuses()]
      } else if (!identical(filters$status, "__all__")) {
        table <- table[status == filters$status]
      }
      for (field in c("item_type", "severity", "priority", "confidence")) {
        value <- filters[[field]]
        if (!identical(value, "__all__") && field %in% names(table)) {
          table <- table[table[[field]] == value]
        }
      }
      table
    })

    remediation_plan_state <- reactive({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(list(project = project, result = NULL, plans = list(), table = data.table::data.table(), health = "unavailable"))
      }
      result <- tryCatch(remediation_plan_load_all(project, include_invalid = TRUE), error = function(e) service_result(status = "error", errors = conditionMessage(e)))
      if (!identical(result$status, "success")) {
        return(list(project = project, result = result, plans = list(), table = data.table::data.table(), health = "unavailable"))
      }
      list(project = project, result = result, plans = result$value$plans, table = remediation_plan_table(result$value$plans), health = result$value$ledger_health)
    })

    selected_remediation_plan <- reactive({
      state <- remediation_plan_state()
      table <- state$table
      selected <- selected_value(input$remediation_plan_id)
      if (!nrow(table)) return(NULL)
      if (!nzchar(selected %||% "") || !selected %in% table$plan_id) selected <- table$plan_id[[1]]
      matched <- Filter(function(plan) identical(plan$plan_id %||% "", selected), state$plans)
      if (length(matched)) matched[[1]] else NULL
    })

    observeEvent(input$create_improvement_item, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      title <- trimws(input$improvement_title %||% "")
      description <- trimws(input$improvement_description %||% "")
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        ctx$project_message("Open a project before creating an improvement item.")
        return(invisible(NULL))
      }
      if (!nzchar(title) || !nzchar(description)) {
        ctx$project_message("Improvement item title and description are required.")
        return(invisible(NULL))
      }
      result <- improvement_create_user_item(
        project = project,
        workspace = workspace,
        title = title,
        description = description,
        item_type = input$improvement_new_type %||% "user_requested_change",
        priority = input$improvement_new_priority %||% "normal",
        affected_component = input$improvement_component %||% "Project",
        desired_outcome = input$improvement_desired_outcome %||% ""
      )
      if (identical(result$status, "success")) {
        ctx$project_message(paste("Improvement item recorded:", result$value$title))
        updateTextInput(session, "improvement_title", value = "")
        updateTextAreaInput(session, "improvement_description", value = "")
        updateTextInput(session, "improvement_desired_outcome", value = "")
      } else {
        ctx$project_message(paste("Improvement item was not recorded:", paste(result$errors, collapse = " ")))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$add_improvement_feedback, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      item_id <- selected_value(input$improvement_item_id)
      feedback <- trimws(input$improvement_feedback %||% "")
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready") || !nzchar(item_id %||% "")) {
        ctx$project_message("Select an improvement item before adding feedback.")
        return(invisible(NULL))
      }
      if (!nzchar(feedback)) {
        ctx$project_message("Feedback text is required.")
        return(invisible(NULL))
      }
      status <- selected_value(input$improvement_feedback_status)
      if (identical(status, "__no_change__")) status <- NULL
      priority <- selected_value(input$improvement_feedback_priority)
      if (!nzchar(priority %||% "")) priority <- NULL
      severity <- selected_value(input$improvement_feedback_severity)
      if (!nzchar(severity %||% "")) severity <- NULL
      result <- improvement_add_user_feedback(
        project = project,
        workspace = workspace,
        item_id = item_id,
        feedback_type = input$improvement_feedback_type %||% "context",
        feedback = feedback,
        priority = priority,
        severity = severity,
        status = status
      )
      if (identical(result$status, "success")) {
        ctx$project_message(paste("Feedback added to", item_id))
        updateTextAreaInput(session, "improvement_feedback", value = "")
      } else {
        ctx$project_message(paste("Feedback was not recorded:", paste(result$errors, collapse = " ")))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$create_remediation_plan, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      item_id <- selected_value(input$remediation_source_item_id)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready") || !nzchar(item_id %||% "")) {
        ctx$project_message("Select an accepted improvement item before creating a remediation plan.")
        return(invisible(NULL))
      }
      item <- improvement_load_item(project, item_id)
      if (!identical(item$status, "success")) {
        ctx$project_message(paste("Improvement item could not be loaded:", paste(item$errors, collapse = " ")))
        return(invisible(NULL))
      }
      result <- remediation_plan_create_from_template(project, item$value)
      if (identical(result$status, "success")) {
        saved <- remediation_plan_save(project, workspace, result$value, "plan_created", "Plan created from Project workspace.", source_item = item$value)
        ctx$project_message(if (identical(saved$status, "success")) paste("Remediation plan created:", saved$value$title) else paste("Plan was not saved:", paste(saved$errors, collapse = " ")))
      } else {
        ctx$project_message(paste("No executable remediation plan was created:", paste(result$errors %||% "Template unavailable.", collapse = " ")))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$approve_remediation_plan, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      result <- remediation_plan_approve(project, workspace, selected_value(input$remediation_plan_id), approval_policy = input$remediation_approval_policy %||% "plan_structure_only")
      ctx$project_message(if (identical(result$status, "success")) paste("Remediation plan approved:", result$value$title) else paste("Plan approval failed:", paste(result$errors, collapse = " ")))
    }, ignoreInit = TRUE)

    observeEvent(input$approve_remediation_step, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      result <- remediation_plan_approve_step(project, workspace, selected_value(input$remediation_plan_id))
      ctx$project_message(if (identical(result$status, "success")) "Remediation step approved. Execute next step when ready." else paste("Step approval failed:", paste(result$errors, collapse = " ")))
    }, ignoreInit = TRUE)

    observeEvent(input$execute_next_remediation_step, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      result <- remediation_plan_execute_next_step(project, workspace, selected_value(input$remediation_plan_id), ctx = ctx)
      ctx$project_message(paste("Remediation step:", result$status, paste(result$messages %||% result$errors %||% "", collapse = " ")))
    }, ignoreInit = TRUE)

    observeEvent(input$pause_remediation_plan, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      result <- remediation_plan_pause(project, workspace, selected_value(input$remediation_plan_id))
      ctx$project_message(if (identical(result$status, "success")) "Remediation plan paused." else paste("Pause failed:", paste(result$errors, collapse = " ")))
    }, ignoreInit = TRUE)

    observeEvent(input$cancel_remediation_plan, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      result <- remediation_plan_cancel(project, workspace, selected_value(input$remediation_plan_id))
      ctx$project_message(if (identical(result$status, "success")) "Remediation plan cancelled." else paste("Cancel failed:", paste(result$errors, collapse = " ")))
    }, ignoreInit = TRUE)

    observeEvent(input$revise_remediation_plan, {
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) NULL)
      result <- remediation_plan_revise(project, workspace, selected_value(input$remediation_plan_id))
      ctx$project_message(if (identical(result$status, "success")) paste("Remediation plan revision created:", result$value$plan_id) else paste("Revision failed:", paste(result$errors, collapse = " ")))
    }, ignoreInit = TRUE)

    audit_ledger_state <- reactive({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(list(project = project, result = NULL, events = data.table::data.table(), health = "unavailable"))
      }
      result <- tryCatch(genai_audit_read_events(project), error = function(e) service_result(status = "error", errors = conditionMessage(e)))
      if (!identical(result$status, "success")) {
        return(list(project = project, result = result, events = data.table::data.table(), health = "unavailable"))
      }
      list(project = project, result = result, events = result$value$events, health = result$value$ledger_health)
    })

    output$genai_audit_ledger_browser <- renderUI({
      state <- audit_ledger_state()
      project <- state$project
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(ui_card(
          title = "GenAI Action Audit Ledger",
          subtitle = "Durable project-scoped action governance.",
          ui_empty_state("No project open.", "Create or load a project to inspect durable GenAI action events.")
        ))
      }
      if (!identical(state$result$status %||% "", "success")) {
        return(ui_card(
          title = "GenAI Action Audit Ledger",
          subtitle = "Durable project-scoped action governance.",
          ui_callout("Ledger unavailable", paste(state$result$errors %||% "Audit ledger could not be read.", collapse = " "), status = "error")
        ))
      }
      events <- state$events
      health <- state$health %||% "missing"
      if (!nrow(events)) {
        return(ui_card(
          title = "GenAI Action Audit Ledger",
          subtitle = paste("Ledger health:", health),
          ui_empty_state("No durable GenAI action events yet.", "Approved project-scoped actions and result persistence will write append-only audit events here.")
        ))
      }
      safe_choices <- function(values) {
        values <- sort(unique(as.character(values)))
        values <- values[!is.na(values) & nzchar(values)]
        c("All" = "__all__", stats::setNames(values, values))
      }
      action_choices <- safe_choices(events$action_id)
      event_choices <- safe_choices(events$event_type)
      status_choices <- safe_choices(events$result_status)
      risk_choices <- safe_choices(events$risk_tier)
      selected_event <- selected_value(input$audit_event_id)
      if (!nzchar(selected_event %||% "") || !selected_event %in% events$audit_event_id) {
        selected_event <- events$audit_event_id[[nrow(events)]]
      }
      event_select_choices <- stats::setNames(
        rev(events$audit_event_id),
        rev(paste(events$event_timestamp, events$event_type, events$action_id, sep = " | "))
      )
      reconciliation <- tryCatch(genai_reconcile_persisted_results_audit(project), error = function(e) service_result(status = "error", errors = conditionMessage(e)))
      reconciliation_rows <- if (identical(reconciliation$status, "success")) reconciliation$value else data.table::data.table()
      ui_card(
        title = "GenAI Action Audit Ledger",
        subtitle = paste("Append-only project action history. Ledger health:", health),
        ui_workspace_grid(
          columns = "main-sidebar",
          tagList(
            ui_stat_grid(
              ui_stat_tile("Events", nrow(events), status = if (identical(health, "healthy")) "success" else "warning", detail = "durable records"),
              ui_stat_tile("Health", health, status = if (identical(health, "healthy")) "success" else if (health %in% c("missing", "partial_tail")) "warning" else "error", detail = "restart discovery"),
              ui_stat_tile("Persistent Events", sum(events$event_type %in% c("persistence_committed", "persistence_recovered"), na.rm = TRUE), status = "info", detail = "result governance")
            ),
            ui_workspace_grid(
              columns = "two",
              selectInput(ns("audit_action_filter"), "Action", choices = action_choices, selected = input$audit_action_filter %||% "__all__"),
              selectInput(ns("audit_event_filter"), "Event Type", choices = event_choices, selected = input$audit_event_filter %||% "__all__"),
              selectInput(ns("audit_status_filter"), "Status", choices = status_choices, selected = input$audit_status_filter %||% "__all__"),
              selectInput(ns("audit_risk_filter"), "Risk", choices = risk_choices, selected = input$audit_risk_filter %||% "__all__")
            ),
            uiOutput(ns("audit_event_table")),
            ui_disclosure(
              "Persisted Result Reconciliation",
              if (nrow(reconciliation_rows)) {
                render_table(reconciliation_rows, engine = "html", searchable = FALSE, sortable = FALSE)
              } else {
                ui_empty_state("No persisted results to reconcile.", "Persistence events will be matched to result manifests once results exist.")
              },
              level = "common",
              open = FALSE
            )
          ),
          tagList(
            selectInput(ns("audit_event_id"), "Audit Event", choices = event_select_choices, selected = selected_event),
            uiOutput(ns("audit_event_detail"))
          )
        )
      )
    })

    output$improvement_ledger_browser <- renderUI({
      state <- improvement_ledger_state()
      project <- state$project
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(ui_card(
          title = "Improvement Ledger",
          subtitle = "Project-scoped findings, issues, UX friction, deferred work, and improvement requests.",
          ui_empty_state("No project open.", "Create or load a project to track durable improvement items.")
        ))
      }
      if (!identical(state$result$status %||% "", "success")) {
        return(ui_card(
          title = "Improvement Ledger",
          subtitle = "Project-scoped improvement governance.",
          ui_callout("Ledger unavailable", paste(state$result$errors %||% "Improvement ledger could not be read.", collapse = " "), status = "error")
        ))
      }
      table <- state$table
      summary <- improvement_ledger_summary(project)
      safe_choices <- function(values, all_label = "All") {
        values <- sort(unique(as.character(values)))
        values <- values[!is.na(values) & nzchar(values)]
        c(stats::setNames("__all__", all_label), stats::setNames(values, gsub("_", " ", values)))
      }
      status_choices <- c("Open" = "__open__", safe_choices(improvement_statuses(), "All"))
      type_choices <- safe_choices(improvement_item_types(), "All")
      severity_choices <- safe_choices(improvement_severities(), "All")
      priority_choices <- safe_choices(improvement_priorities(), "All")
      confidence_choices <- safe_choices(improvement_confidences(), "All")
      filtered <- filtered_improvement_items()
      selected <- selected_value(input$improvement_item_id)
      if (!nzchar(selected %||% "") || !selected %in% (table$item_id %||% character())) {
        selected <- if (nrow(filtered)) filtered$item_id[[1]] else if (nrow(table)) table$item_id[[1]] else ""
      }
      item_choices <- if (nrow(table)) stats::setNames(table$item_id, paste(table$title, table$status, sep = " - ")) else character()
      selected_item <- NULL
      if (nzchar(selected %||% "")) {
        matched <- Filter(function(item) identical(item$item_id %||% "", selected), state$items)
        if (length(matched)) selected_item <- matched[[1]]
      }
      ui_card(
        title = "Improvement Ledger",
        subtitle = paste("Governed improvement loop. Ledger health:", state$health %||% "missing"),
        ui_workspace_grid(
          columns = "main-sidebar",
          tagList(
            ui_stat_grid(
              ui_stat_tile("Open", summary$open_items[[1]] %||% 0L, status = if ((summary$open_items[[1]] %||% 0L) > 0L) "info" else "success", detail = "active items"),
              ui_stat_tile("Awaiting User", summary$awaiting_user[[1]] %||% 0L, status = if ((summary$awaiting_user[[1]] %||% 0L) > 0L) "warning" else "success", detail = "triage/input"),
              ui_stat_tile("Critical", summary$critical_open[[1]] %||% 0L, status = if ((summary$critical_open[[1]] %||% 0L) > 0L) "error" else "success", detail = "open critical"),
              ui_stat_tile("Resolved", summary$resolved_items[[1]] %||% 0L, status = "success", detail = "verified")
            ),
            ui_workspace_grid(
              columns = "three",
              selectInput(ns("improvement_status_filter"), "Status", choices = status_choices, selected = input$improvement_status_filter %||% "__open__"),
              selectInput(ns("improvement_type_filter"), "Type", choices = type_choices, selected = input$improvement_type_filter %||% "__all__"),
              selectInput(ns("improvement_severity_filter"), "Severity", choices = severity_choices, selected = input$improvement_severity_filter %||% "__all__"),
              selectInput(ns("improvement_priority_filter"), "Priority", choices = priority_choices, selected = input$improvement_priority_filter %||% "__all__"),
              selectInput(ns("improvement_confidence_filter"), "Confidence", choices = confidence_choices, selected = input$improvement_confidence_filter %||% "__all__")
            ),
            ui_improvement_ledger_table(filtered, ns = ns),
            ui_disclosure(
              "Create User Item",
              tagList(
                textInput(ns("improvement_title"), "Title", value = ""),
                textAreaInput(ns("improvement_description"), "Description", value = "", rows = 3),
                ui_workspace_grid(
                  columns = "two",
                  selectInput(ns("improvement_new_type"), "Type", choices = stats::setNames(improvement_item_types(), gsub("_", " ", improvement_item_types())), selected = "user_requested_change"),
                  selectInput(ns("improvement_new_priority"), "Priority", choices = improvement_priorities(), selected = "normal"),
                  textInput(ns("improvement_component"), "Affected Component", value = "Project"),
                  textInput(ns("improvement_desired_outcome"), "Desired Outcome / Criteria", value = "")
                ),
                actionButton(ns("create_improvement_item"), "Record Improvement Item", class = "btn-primary btn-sm")
              ),
              level = "common",
              open = FALSE
            )
          ),
          tagList(
            selectInput(ns("improvement_item_id"), "Improvement Item", choices = item_choices, selected = selected),
            ui_improvement_item_detail(selected_item),
            ui_disclosure(
              "Add Feedback / Triage",
              tagList(
                selectInput(ns("improvement_feedback_type"), "Feedback Type", choices = c("agree", "disagree", "context", "priority_change", "severity_change", "defer", "accept_limitation", "reopen"), selected = "context"),
                textAreaInput(ns("improvement_feedback"), "Feedback", value = "", rows = 3),
                ui_workspace_grid(
                  columns = "three",
                  selectInput(ns("improvement_feedback_priority"), "Priority", choices = c("No change" = "", improvement_priorities()), selected = ""),
                  selectInput(ns("improvement_feedback_severity"), "Severity", choices = c("No change" = "", improvement_severities()), selected = ""),
                  selectInput(ns("improvement_feedback_status"), "Status", choices = c("No change" = "__no_change__", stats::setNames(improvement_statuses(), gsub("_", " ", improvement_statuses()))), selected = "__no_change__")
                ),
                actionButton(ns("add_improvement_feedback"), "Add Feedback", class = "btn-secondary btn-sm")
              ),
              level = "common",
              open = FALSE
            )
          )
        )
      )
    })

    output$remediation_plan_browser <- renderUI({
      state <- remediation_plan_state()
      project <- state$project
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(ui_card(
          title = "Remediation Plans",
          subtitle = "Governed stepwise execution for accepted improvement items.",
          ui_empty_state("No project open.", "Create or load a project to plan bounded remediation work.")
        ))
      }
      if (!identical(state$result$status %||% "", "success")) {
        return(ui_card(
          title = "Remediation Plans",
          subtitle = "Governed stepwise execution.",
          ui_callout("Plans unavailable", paste(state$result$errors %||% "Remediation plans could not be read.", collapse = " "), status = "error")
        ))
      }
      summary <- remediation_plan_summary(project)
      table <- state$table
      open_items <- improvement_ledger_state()$table
      source_candidates <- open_items[status %in% c("accepted", "triaged", "awaiting_user_input", "planned")]
      source_choices <- if (nrow(source_candidates)) stats::setNames(source_candidates$item_id, paste(source_candidates$title, source_candidates$status, sep = " - ")) else character()
      selected_plan <- selected_remediation_plan()
      plan_choices <- if (nrow(table)) stats::setNames(table$plan_id, paste(table$title, table$status, sep = " - ")) else character()
      selected_plan_id <- selected_value(input$remediation_plan_id)
      if (!nzchar(selected_plan_id %||% "") && length(plan_choices)) selected_plan_id <- unname(plan_choices)[[1]]
      ui_card(
        title = "Remediation Plans",
        subtitle = paste("Governed, bounded remediation. Ledger health:", state$health %||% "missing"),
        ui_workspace_grid(
          columns = "main-sidebar",
          tagList(
            ui_stat_grid(
              ui_stat_tile("Plans", summary$total_plans[[1]] %||% 0L, status = if ((summary$total_plans[[1]] %||% 0L) > 0L) "info" else "neutral", detail = "total"),
              ui_stat_tile("Active", summary$active_plans[[1]] %||% 0L, status = if ((summary$active_plans[[1]] %||% 0L) > 0L) "warning" else "success", detail = "non-terminal"),
              ui_stat_tile("Awaiting Input", summary$awaiting_input[[1]] %||% 0L, status = if ((summary$awaiting_input[[1]] %||% 0L) > 0L) "warning" else "success", detail = "manual checkpoints"),
              ui_stat_tile("Awaiting Approval", summary$awaiting_approval[[1]] %||% 0L, status = if ((summary$awaiting_approval[[1]] %||% 0L) > 0L) "warning" else "success", detail = "review gates")
            ),
            ui_workspace_grid(
              columns = "two",
              selectInput(ns("remediation_source_item_id"), "Improvement Item", choices = source_choices),
              selectInput(ns("remediation_approval_policy"), "Approval Policy", choices = stats::setNames(remediation_plan_approval_policies(), gsub("_", " ", remediation_plan_approval_policies())), selected = "plan_structure_only")
            ),
            ui_action_row(
              actionButton(ns("create_remediation_plan"), "Create Plan", class = "btn-primary btn-sm"),
              actionButton(ns("approve_remediation_plan"), "Approve Plan", class = "btn-secondary btn-sm"),
              actionButton(ns("approve_remediation_step"), "Approve Step", class = "btn-secondary btn-sm"),
              actionButton(ns("execute_next_remediation_step"), "Execute Next Step", class = "btn-primary btn-sm")
            ),
            ui_action_row(
              actionButton(ns("pause_remediation_plan"), "Pause", class = "btn-secondary btn-sm"),
              actionButton(ns("revise_remediation_plan"), "Revise", class = "btn-secondary btn-sm"),
              actionButton(ns("cancel_remediation_plan"), "Cancel", class = "btn-secondary btn-sm")
            ),
            ui_remediation_plan_table(table)
          ),
          tagList(
            selectInput(ns("remediation_plan_id"), "Remediation Plan", choices = plan_choices, selected = selected_plan_id),
            ui_remediation_plan_detail(selected_plan)
          )
        )
      )
    })

    output$genai_job_monitor <- renderUI({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(ui_card(
          title = "GenAI Job Monitor",
          subtitle = "Isolated analytical worker jobs.",
          ui_empty_state("No project open.", "Open a project to inspect durable GenAI job records.")
        ))
      }
      jobs <- tryCatch(genai_job_summary(project), error = function(e) data.table::data.table(error = conditionMessage(e)))
      if (!nrow(jobs)) {
        return(ui_card(
          title = "GenAI Job Monitor",
          subtitle = "Isolated analytical worker jobs.",
          ui_empty_state("No GenAI jobs yet.", "Approved registered analyses will appear here with progress, recovery, and terminal status.")
        ))
      }
      cols <- intersect(c("job_id", "action_id", "module_id", "mode_id", "result_type", "status", "created_at", "started_at", "completed_at", "progress_stage", "recovery_status"), names(jobs))
      ui_card(
        title = "GenAI Job Monitor",
        subtitle = "Project-scoped isolated execution records.",
        render_table(jobs[, ..cols], engine = "html", searchable = FALSE, sortable = TRUE)
      )
    })

    filtered_audit_events <- reactive({
      events <- audit_ledger_state()$events
      if (!nrow(events)) return(events)
      filters <- list(
        action_id = input$audit_action_filter %||% "__all__",
        event_type = input$audit_event_filter %||% "__all__",
        result_status = input$audit_status_filter %||% "__all__",
        risk_tier = input$audit_risk_filter %||% "__all__"
      )
      for (field in names(filters)) {
        value <- filters[[field]]
        if (!identical(value, "__all__") && field %in% names(events)) {
          events <- events[events[[field]] == value]
        }
      }
      events
    })

    output$audit_event_table <- renderUI({
      events <- filtered_audit_events()
      if (!nrow(events)) {
        return(ui_empty_state("No matching audit events.", "Adjust the filters to inspect durable action history."))
      }
      cols <- intersect(c(
        "event_timestamp", "event_type", "action_id", "risk_tier", "proposal_id",
        "execution_id", "result_status", "approval_source", "persisted_result_id",
        "persistent_changes", "warnings", "errors"
      ), names(events))
      render_table(utils::tail(events[, cols, with = FALSE], 100L), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$audit_event_detail <- renderUI({
      events <- audit_ledger_state()$events
      selected <- selected_value(input$audit_event_id)
      if (!nrow(events) || !nzchar(selected %||% "")) {
        return(ui_empty_state("Select an audit event.", "Choose an event to inspect safe structured details."))
      }
      event <- events[events$audit_event_id == selected][1]
      if (!nrow(event)) {
        return(ui_empty_state("Audit event not found.", "Refresh the ledger browser and select an available event."))
      }
      safe_cols <- intersect(c(
        "audit_event_id", "audit_schema_version", "event_type", "event_timestamp",
        "project_id", "workspace_provider_id", "workspace_provider_type",
        "action_id", "action_version", "risk_tier", "proposal_id", "proposal_hash",
        "execution_id", "approval_source", "policy_decision", "result_status",
        "resource_type", "resource_id", "resource_fingerprint", "persistence_fingerprint",
        "temporary_result_id", "persisted_result_id", "module_id", "dataset_id",
        "idempotency_key", "already_committed", "project_state_changed", "persistent_changes",
        "safe_relative_location", "audit_idempotency_key", "previous_event_hash", "event_hash",
        "warnings", "errors"
      ), names(event))
      meta <- data.table::data.table(
        item = safe_cols,
        value = vapply(safe_cols, function(name) paste(as.character(event[[name]]), collapse = ", "), character(1))
      )
      tagList(
        ui_callout("Safe audit detail", "This view intentionally excludes prompts, raw rows, secrets, and sensitive absolute paths.", status = "info"),
        render_table(meta, engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$persisted_results_browser <- renderUI({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (!is.list(project) || !identical(project$project_state %||% "", "project_ready")) {
        return(ui_card(
          title = "Persisted Results",
          subtitle = "Project-scoped analytical results saved for later inspection.",
          ui_empty_state("No project open.", "Create or load a project to inspect persisted results.")
        ))
      }

      rows <- persisted_result_rows()
      if (!nrow(rows)) {
        return(ui_card(
          title = "Persisted Results",
          subtitle = "Project-scoped analytical results saved for later inspection.",
          ui_empty_state("No persisted results yet.", "Run an approved registered analysis and persist the temporary result to populate this browser.")
        ))
      }

      healthy <- rows[rows$health_status == "healthy"]
      invalid <- rows[rows$health_status != "healthy"]
      selected <- ctx$selected_persisted_result_id()
      if (!nrow(healthy)) selected <- NULL
      choices <- if (nrow(healthy)) {
        stats::setNames(healthy$persisted_result_id, paste(healthy$display_name, healthy$persisted_result_id, sep = " - "))
      } else {
        character()
      }

      ui_card(
        title = "Persisted Results",
        subtitle = "Read-only project memory. Healthy bundles validate manifest schema, project ownership, required files, and content hashes.",
        ui_workspace_grid(
          columns = "main-sidebar",
          tagList(
            if (nrow(healthy)) tagList(
              selectInput(ns("persisted_result_id"), "Healthy Result", choices = choices, selected = selected %||% healthy$persisted_result_id[[1]]),
              ui_action_row(
                actionButton(ns("open_persisted_result"), "Open Result", class = "btn-primary btn-sm"),
                actionButton(ns("refresh_persisted_results"), "Refresh", class = "btn-secondary btn-sm")
              ),
              render_table(
                healthy[, intersect(c(
                  "display_name", "persisted_result_id", "result_type", "module_id", "dataset_id",
                  "persisted_at", "warning_count", "diagnostic_count", "table_count",
                  "health_status", "safe_relative_location"
                ), names(healthy)), with = FALSE],
                engine = "html",
                searchable = FALSE,
                sortable = FALSE
              )
            ) else {
              ui_empty_state("No healthy persisted results.", "Invalid or unsupported bundles are listed separately and cannot be opened.")
            },
            if (nrow(invalid)) ui_disclosure(
              "Invalid or Unsupported Bundles",
              render_table(
                invalid[, intersect(c("persisted_result_id", "display_name", "health_status", "manifest_status", "hash_status", "validation_errors", "safe_relative_location"), names(invalid)), with = FALSE],
                engine = "html",
                searchable = FALSE,
                sortable = FALSE
              ),
              level = "advanced",
              open = TRUE
            )
          ),
          uiOutput(ns("persisted_result_detail"))
        )
      )
    })

    output$persisted_result_detail <- renderUI({
      selected <- ctx$selected_persisted_result_id() %||% selected_value(input$persisted_result_id)
      if (!nzchar(selected %||% "")) {
        return(ui_empty_state("Select a persisted result.", "Choose a healthy persisted result to inspect bounded metadata, summaries, diagnostics, warnings, and tables."))
      }
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      resolution <- genai_resolve_persisted_result(selected, ctx = ctx)
      if (!identical(resolution$status, "success")) {
        ctx$selected_persisted_result_id(NULL)
        return(ui_callout("Result unavailable", paste(resolution$errors %||% "The selected result is no longer healthy.", collapse = " "), status = "error"))
      }
      bundle <- read_persisted_result_bundle(project, selected, table_row_limit = 20L)
      if (!identical(bundle$status, "success")) {
        return(ui_callout("Result bundle failed validation", paste(bundle$errors %||% "Bundle content could not be read.", collapse = " "), status = "error"))
      }
      manifest <- bundle$value$manifest
      summary_text <- bundle$value$summary$summary %||% bundle$value$summary %||% "No summary was persisted."
      diagnostics <- bundle$value$diagnostics %||% list()
      warnings <- bundle$value$warnings %||% character()
      usage <- bundle$value$resource_usage %||% list()
      metrics <- bundle$value$metrics %||% list()
      threshold_metrics <- bundle$value$threshold_metrics %||% NULL
      plot_specs <- bundle$value$plots %||% list()
      meta <- data.table::data.table(
        item = c("Result ID", "Type", "Module", "Dataset", "Created", "Persisted", "Source Execution", "Project", "Index", "Hashes", "Location"),
        value = c(
          resolution$value$persisted_result_id,
          resolution$value$result_type,
          paste(resolution$value$module_id, resolution$value$module_version),
          paste(resolution$value$dataset_id, resolution$value$dataset_version),
          resolution$value$created_at,
          resolution$value$persisted_at,
          resolution$value$source_execution_id,
          resolution$value$active_project_name %||% resolution$value$active_project_id,
          resolution$value$manifest_status,
          resolution$value$hash_status,
          resolution$value$safe_relative_location
        )
      )
      diagnostic_rows <- data.table::data.table(
        item = names(diagnostics %||% list()),
        value = vapply(diagnostics %||% list(), function(x) paste(as.character(x), collapse = ", "), character(1))
      )
      metric_rows <- data.table::data.table(
        metric = names(metrics %||% list()),
        value = vapply(metrics %||% list(), function(x) paste(as.character(x), collapse = ", "), character(1))
      )
      threshold_rows <- if (is.data.frame(threshold_metrics) || data.table::is.data.table(threshold_metrics)) {
        data.table::as.data.table(threshold_metrics)
      } else {
        data.table::data.table()
      }
      warning_rows <- data.table::data.table(warning = as.character(warnings %||% character()))
      usage_rows <- data.table::data.table(
        item = names(usage %||% list()),
        value = vapply(usage %||% list(), function(x) paste(as.character(x), collapse = ", "), character(1))
      )
      table_ui <- lapply(bundle$value$tables %||% list(), function(table) {
        ui_disclosure(
          paste0("Table: ", table$table_id, " (", table$row_count, " rows x ", table$column_count, " columns", if (isTRUE(table$truncated)) ", preview truncated" else "", ")"),
          render_table(table$preview, engine = "html", searchable = FALSE, sortable = FALSE),
          level = "common",
          open = FALSE
        )
      })
      plot_ui <- lapply(plot_specs, function(plot) {
        plot_data <- plot$bounded_data %||% data.frame()
        plot_rows <- if (is.data.frame(plot_data) || data.table::is.data.table(plot_data)) nrow(plot_data) else 0L
        plot_meta <- data.table::data.table(
          item = c("Plot ID", "Type", "Title", "X Label", "Y Label", "Rows"),
          value = c(
            plot$plot_id %||% "",
            plot$plot_type %||% "",
            plot$title %||% "",
            plot$x_label %||% "",
            plot$y_label %||% "",
            as.character(plot_rows)
          )
        )
        ui_disclosure(
          paste0("Plot Spec: ", plot$title %||% plot$plot_id %||% "Bounded Plot"),
          tagList(
            render_table(plot_meta, engine = "html", searchable = FALSE, sortable = FALSE),
            if (is.data.frame(plot_data) || data.table::is.data.table(plot_data)) {
              render_table(utils::head(data.table::as.data.table(plot_data), 20L), engine = "html", searchable = FALSE, sortable = FALSE)
            } else {
              ui_empty_state("No bounded plot data.", "The persisted plot specification did not include tabular bounded data.")
            }
          ),
          level = "advanced",
          open = FALSE
        )
      })
      tagList(
        ui_callout("Persisted project state", "This result is opened read-only from trusted project storage. Content hashes validated before rendering.", status = "success"),
        ui_disclosure("Summary", tags$p(summary_text), level = "common", open = TRUE),
        ui_disclosure("Provenance", render_table(meta, engine = "html", searchable = FALSE, sortable = FALSE), level = "common", open = TRUE),
        ui_disclosure(
          "Metrics",
          if (nrow(metric_rows)) render_table(metric_rows, engine = "html", searchable = FALSE, sortable = FALSE) else ui_empty_state("No metrics.", "No metric payload was persisted for this result."),
          level = "common",
          open = TRUE
        ),
        ui_disclosure(
          "Threshold Metrics",
          if (nrow(threshold_rows)) render_table(threshold_rows, engine = "html", searchable = FALSE, sortable = FALSE) else ui_empty_state("No threshold metrics.", "No threshold-specific payload was persisted for this result."),
          level = "common",
          open = identical(manifest$result_type %||% "", "model_assessment_binary")
        ),
        ui_disclosure(
          "Diagnostics",
          if (nrow(diagnostic_rows)) render_table(diagnostic_rows, engine = "html", searchable = FALSE, sortable = FALSE) else ui_empty_state("No diagnostics.", "No diagnostic payload was persisted for this result."),
          level = "common",
          open = FALSE
        ),
        ui_disclosure(
          "Warnings",
          if (nrow(warning_rows)) render_table(warning_rows, engine = "html", searchable = FALSE, sortable = FALSE) else ui_empty_state("No warnings.", "No warning payload was persisted for this result."),
          level = "common",
          open = FALSE
        ),
        ui_disclosure(
          "Resource Usage",
          if (nrow(usage_rows)) render_table(usage_rows, engine = "html", searchable = FALSE, sortable = FALSE) else ui_empty_state("No resource usage.", "No resource usage payload was persisted for this result."),
          level = "advanced",
          open = FALSE
        ),
        if (length(table_ui)) tagList(table_ui) else ui_empty_state("No tables.", "No bounded table payloads were persisted for this result."),
        if (length(plot_ui)) tagList(plot_ui) else ui_empty_state("No plot specifications.", "No bounded plot specifications were persisted for this result.")
      )
    })

    output$recent_activity <- renderUI({
      ui_activity_list(project_actions())
    })

    observeEvent(input$go_intelligence, {
      updateSelectInput(session, "project_system_detail", selected = "ai_assistance")
    }, ignoreInit = TRUE)

    observeEvent(input$go_technical, {
      updateSelectInput(session, "project_system_detail", selected = "technical_signals")
    }, ignoreInit = TRUE)

    save_project_action <- function() {
      ctx$project_message("")

      tryCatch({
        if (!isTRUE(ctx$project_ready())) {
          stop("No project is open. Current analytical results are temporary and cannot be saved until a project is created or opened.", call. = FALSE)
        }
        ctx$persist_project_data_if_needed()
        project_state <- ctx$current_project_state()
        target_project_path <- input$project_path %||% ""
        if (!nzchar(target_project_path)) {
          target_project_path <- project_path(ctx$current_project(), "project.rds")
        }
        output_path <- save_project_state(
          project_state,
          target_project_path,
          workspace = ctx$current_workspace(),
          project = ctx$current_project(),
          resource_type = "project_state"
        )
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
        open_state <- lifecycle_open_state()
        project_path <- open_state$project_file %||% input$project_path
        project_path <- normalize_project_load_path(project_path)
        if (!file.exists(project_path)) {
          stop(paste("Project file does not exist:", project_path), call. = FALSE)
        }

        project_state <- readRDS(project_path)
        project_root <- dirname(project_path)
        root_validation <- validate_project_root(project_root, create = FALSE)
        if (!identical(root_validation$status, "success")) {
          stop(paste(root_validation$errors, collapse = " "), call. = FALSE)
        }
        active_project <- project_state$project_metadata %||% new_project_metadata(
          project_name = project_state$data_name %||% tools::file_path_sans_ext(basename(project_path)),
          project_root = root_validation$value,
          workspace_root = ctx$current_workspace()$workspace_root %||% NA_character_,
          project_id = safe_path_component(tools::file_path_sans_ext(basename(project_path)), "loaded_project")
        )
        active_project$project_root <- root_validation$value
        active_project$project_state <- "project_ready"
        ensure_project_structure(active_project$project_root)
        loaded <- ctx$load_project_state(project_state, active_project = active_project)
        project_location_confirmed(root_validation$value)
        updateTextInput(session, "workspace_root", value = root_validation$value)
        updateRadioButtons(
          session,
          "workspace_provider",
          selected = active_project$workspace_provider_id %||% "local_server_directory"
        )
        ctx$selected_persisted_result_id(NULL)
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
    observeEvent(input$load_project_secondary, {
      if (isTRUE(project_lifecycle_busy())) {
        ctx$project_message("Open Project is already running. Ignoring duplicate request.")
        return(invisible(NULL))
      }
      project_lifecycle_busy(TRUE)
      on.exit(project_lifecycle_busy(FALSE), add = TRUE)
      load_project_action()
    }, ignoreInit = TRUE)

    observeEvent(input$configure_workspace, {
      ctx$project_message("")
      result <- ctx$configure_workspace(input$workspace_root, provider_id = input$workspace_provider %||% "local_server_directory")
      ctx$project_message(service_result_message(result))
      add_activity(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$workspace_root, {
      current_location <- storage_normalize_path(input$workspace_root, must_work = FALSE)
      if (!identical(current_location, project_location_confirmed())) {
        project_location_confirmed(NULL)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$confirm_project_location, {
      ctx$project_message("")
      location <- lifecycle_location_input()
      if (is.null(location$normalized)) {
        message <- "Enter or choose a Project Location before confirming it."
        ctx$project_message(message)
        add_activity(message)
        return(invisible(NULL))
      }
      if (file.exists(location$normalized) && !dir.exists(location$normalized)) {
        message <- "Project Location must be a folder, not a file."
        ctx$project_message(message)
        add_activity(message)
        return(invisible(NULL))
      }
      project_location_confirmed(location$normalized)
      message <- paste("Project Location confirmed:", location$normalized)
      ctx$project_message(message)
      add_activity(message)
    }, ignoreInit = TRUE)

    observeEvent(input$create_project, {
      if (isTRUE(project_lifecycle_busy())) {
        ctx$project_message("Create Project is already running. Ignoring duplicate request.")
        add_activity("Create Project duplicate request ignored.")
        return(invisible(NULL))
      }
      ctx$project_message("")
      project_lifecycle_busy(TRUE)
      on.exit(project_lifecycle_busy(FALSE), add = TRUE)
      if (isTRUE(ctx$project_ready())) {
        message <- "Close the active project before creating another project."
        ctx$project_message(message)
        add_activity(message)
        return(invisible(NULL))
      }
      state <- lifecycle_create_state()
      if (!isTRUE(state$ready)) {
        message <- paste(c("Create Project is not ready.", state$missing), collapse = " ")
        ctx$project_message(message)
        add_activity(message)
        return(invisible(NULL))
      }
      workspace_result <- ctx$configure_workspace(state$location$normalized, provider_id = state$location$provider_id)
      if (!identical(workspace_result$status, "success")) {
        ctx$project_message(service_result_message(workspace_result))
        add_activity(service_result_message(workspace_result))
        return(invisible(NULL))
      }
      result <- ctx$create_project(state$project_name, project_id = state$project_id, project_root = state$destination)
      message <- service_result_message(result)
      ctx$project_message(message)
      add_activity(message)
    }, ignoreInit = TRUE)

    observeEvent(input$close_project, {
      ctx$close_project()
      add_activity("Closed active project.")
    }, ignoreInit = TRUE)

    run_project_genai_action <- function(action_id, label, fn) {
      last <- genai_last_request()
      recently_completed <- identical(last$action %||% "", action_id) &&
        !is.na(last$completed_at) &&
        as.numeric(difftime(Sys.time(), last$completed_at, units = "secs")) < 4
      if (isTRUE(genai_project_busy()) || isTRUE(recently_completed)) {
        message <- paste(label, "is already running or just completed. Ignoring duplicate request.")
        ctx$project_message(message)
        add_activity(message)
        return(invisible(NULL))
      }
      genai_project_busy(TRUE)
      genai_project_action(label)
      ctx$project_message(paste(label, "started. The response will appear in AI Assistance when ready."))
      add_activity(paste(label, "started."))
      on.exit({
        genai_project_busy(FALSE)
        genai_project_action(NULL)
        genai_last_request(list(action = action_id, completed_at = Sys.time()))
      }, add = TRUE)
      result <- tryCatch(
        fn(),
        error = function(e) service_result(status = "error", errors = conditionMessage(e))
      )
      if (is.list(result$value) && is.character(result$value$text %||% NULL)) {
        result$value$text <- gsub("\\\\([[:punct:]])", "\\1", result$value$text)
      } else if (is.character(result$value)) {
        result$value <- gsub("\\\\([[:punct:]])", "\\1", result$value)
      }
      ctx$genai_last_result(result)
      ctx$project_message(service_result_message(result))
      add_activity(paste(label, "finished:", service_result_message(result)))
      invisible(result)
    }

    observeEvent(input$brief_project, {
      run_project_genai_action(
        "brief_project",
        "Project brief",
        function() genai_brief_project(ctx, config = ctx$genai_config())
      )
    }, ignoreInit = TRUE)

    observeEvent(input$suggest_next_action, {
      run_project_genai_action(
        "suggest_next_action",
        "Next-action suggestion",
        function() genai_suggest_next_action(ctx, config = ctx$genai_config())
      )
    }, ignoreInit = TRUE)

    observeEvent(input$evidence_strategy, {
      strategy_id <- input$evidence_strategy %||% "balanced"
      strategy <- evidence_strategy_config(strategy_id)
      ctx$evidence_strategy(strategy_id)
      ctx$evidence_strategy_config(strategy)
      add_activity(paste("Selected evidence strategy:", strategy$strategy_label))
    }, ignoreInit = TRUE)

    observeEvent(input$open_persisted_result, {
      result_id <- input$persisted_result_id %||% ""
      result <- ctx$inspect_persisted_result(result_id)
      ctx$project_message(service_result_message(result))
      add_activity(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$refresh_persisted_results, {
      rows <- persisted_result_rows()
      healthy <- rows[rows$health_status == "healthy"]
      selected <- ctx$selected_persisted_result_id()
      if (!nrow(healthy) || !selected %in% healthy$persisted_result_id) {
        ctx$selected_persisted_result_id(NULL)
      }
      add_activity("Refreshed persisted results browser.")
    }, ignoreInit = TRUE)

    observeEvent(input$save_bundle, {
      ctx$project_message("")

      tryCatch({
        if (!isTRUE(ctx$project_ready())) {
          stop("No project is open. Project bundles are persistent outputs and require an active project.", call. = FALSE)
        }
        bundle_dir <- normalize_bundle_dir(input$bundle_dir)
        if (!path_within_root(bundle_dir, ctx$current_project()$project_root)) {
          stop("Project bundle directory must stay inside the active project root.", call. = FALSE)
        }
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
        gate <- persistent_write_gate(
          workspace = ctx$current_workspace(),
          project = ctx$current_project(),
          target = bundle_paths$project_path,
          requested_resource_type = "project_bundle"
        )
        if (!identical(gate$status, "success")) {
          stop(paste(gate$errors, collapse = " "), call. = FALSE)
        }
        atomic_save_rds(project_state, bundle_paths$project_path)
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
        root_validation <- validate_project_root(bundle_dir, create = FALSE)
        if (!identical(root_validation$status, "success")) {
          stop(paste(root_validation$errors, collapse = " "), call. = FALSE)
        }
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
        active_project <- project_state$project_metadata %||% new_project_metadata(
          project_name = project_state$data_name %||% basename(bundle_dir),
          project_root = bundle_dir,
          workspace_root = ctx$current_workspace()$workspace_root %||% NA_character_,
          project_id = safe_path_component(basename(bundle_dir), "loaded_bundle")
        )
        active_project$project_root <- bundle_dir
        active_project$project_state <- "project_ready"
        loaded <- ctx$load_project_state(
          project_state = project_state,
          preferred_data_path = normalizePath(data_path, winslash = "/", mustWork = TRUE),
          export_dir_override = normalizePath(exports_dir, winslash = "/", mustWork = TRUE),
          active_project = active_project
        )
        ctx$selected_persisted_result_id(NULL)
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
