page_project_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Project",
    ui_page(
      title = "Project Workspace",
      subtitle = "Create, load, save, and inspect the active analytical project.",
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
            title = "Workspace",
            subtitle = "Where projects and runtime data may live. This is stored outside the source repository.",
            selectInput(
              ns("workspace_provider"),
              "Storage Provider",
              choices = c(
                "Configured Workspace" = "configured_workspace",
                "Local / Server Directory" = "local_server_directory",
                "Managed Workspace" = "managed_workspace",
                "Native Host Directory" = "native_host_directory"
              ),
              selected = "configured_workspace"
            ),
            textInput(ns("workspace_root"), "Workspace Directory", value = ""),
            ui_action_row(
              actionButton(ns("configure_workspace"), "Use Workspace", class = "btn-primary btn-sm")
            ),
            uiOutput(ns("workspace_provider_details")),
            uiOutput(ns("workspace_guard"))
          ),
          ui_card(
            title = "Project",
            subtitle = "The active analytical workspace that owns persistent artifacts, reports, layouts, and results.",
            textInput(ns("project_name"), "New Project Name", value = "Analytics Project"),
            ui_action_row(
              actionButton(ns("create_project"), "Create Project", class = "btn-primary btn-sm"),
              actionButton(ns("close_project"), "Close Project", class = "btn-secondary btn-sm")
            ),
            uiOutput(ns("project_guard"))
          ),
          ui_card(
            title = "Workspace Status",
            subtitle = "A compact readout of the current analytical run.",
            uiOutput(ns("project_message_panel")),
            uiOutput(ns("workspace_status")),
            uiOutput(ns("modeling_context_panel")),
            ui_disclosure(
              "Recent Activity",
              uiOutput(ns("recent_activity")),
              level = "common",
              open = TRUE
            )
          ),
          uiOutput(ns("ai_readiness_panel")),
          uiOutput(ns("genai_provider_panel")),
          uiOutput(ns("collector_panel"))
        ),
        ui_card(
          title = "Project Files",
          subtitle = "Save or reload the project state and portable bundle.",
          textInput(
            ns("project_path"),
            "Project File",
            value = ""
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
              value = ""
            ),
            ui_action_row(
              actionButton(ns("save_bundle"), "Save Bundle", class = "btn-primary btn-sm"),
              actionButton(ns("load_bundle"), "Load Bundle", class = "btn-secondary btn-sm")
            ),
            level = "advanced"
          )
        )
      ),
      uiOutput(ns("persisted_results_browser")),
      uiOutput(ns("feature_experiment_browser")),
      uiOutput(ns("genai_job_monitor")),
      uiOutput(ns("improvement_ledger_browser")),
      uiOutput(ns("remediation_plan_browser")),
      uiOutput(ns("genai_audit_ledger_browser"))
    )
  )
}

page_project_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
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
      workspace <- tryCatch(ctx$current_workspace(), error = function(e) list())
      workspace_root <- workspace$workspace_root %||% ""
      if (nzchar(workspace_root) && !identical(input$workspace_root, workspace_root)) {
        updateTextInput(session, "workspace_root", value = workspace_root)
      }
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
        return(ui_callout("Workspace ready", workspace$workspace_root %||% "", status = "success"))
      }
      ui_callout(
        "Workspace required",
        paste(result$errors %||% "Choose a workspace directory before saving artifacts, reports, layouts, or project results.", collapse = " "),
        status = "warning"
      )
    })

    output$workspace_provider_details <- renderUI({
      providers <- storage_provider_registry()
      provider <- providers[[input$workspace_provider %||% "configured_workspace"]] %||% providers$configured_workspace
      caps <- provider$capabilities %||% list()
      cap_text <- paste(names(caps)[vapply(caps, isTRUE, logical(1))], collapse = ", ")
      if (!nzchar(cap_text)) cap_text <- "No interactive selection capabilities."
      ui_callout(
        paste("Provider:", provider$display_name),
        paste(
          "Type:", provider$provider_type,
          "| Available:", provider$available,
          "| Managed:", provider$managed,
          "| Capabilities:", cap_text
        ),
        status = if (isTRUE(provider$available)) "info" else "warning"
      )
    })

    output$project_guard <- renderUI({
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      if (is.list(project) && identical(project$project_state %||% "", "project_ready")) {
        return(ui_callout(
          "Project ready",
          paste(project$project_name, "owns persistent outputs at", project$project_root),
          status = "success"
        ))
      }
      ui_callout(
        "No project open",
        "Current analytical results are temporary and cannot be saved until a project is created or opened.",
        status = "warning"
      )
    })

    output$workspace_overview <- renderUI({
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
      plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      workspace_state <- tryCatch(ctx$workspace_state(), error = function(e) "workspace_unconfigured")
      project_state <- tryCatch(ctx$project_state_status(), error = function(e) "no_project")
      collector_status <- if (nrow(collector)) collector$collector_status[[1]] else "not_created"
      collector_badge <- if (collector_status %in% c("success", "created")) "success" else if (collector_status %in% c("error")) "error" else "neutral"
      ui_stat_grid(
        ui_stat_tile("Dataset", if (is.null(data)) "None" else paste(nrow(data), "rows"), status = if (is.null(data)) "neutral" else "success", detail = if (is.null(data)) "Upload data to begin" else paste(ncol(data), "columns")),
        ui_stat_tile("Workspace", ui_status_label(workspace_state), status = if (identical(workspace_state, "workspace_ready")) "success" else "warning", detail = ui_display_label(ctx$current_workspace()$provider_id %||% "no provider")),
        ui_stat_tile("Project", ui_status_label(project_state), status = if (identical(project_state, "project_ready")) "success" else "warning", detail = "persistent owner"),
        ui_stat_tile("Artifacts", length(artifacts), status = if (length(artifacts)) "success" else "neutral", detail = "plots, tables, text"),
        ui_stat_tile("Report Plans", length(plans), status = if (length(plans)) "success" else "neutral", detail = "curated outputs"),
        ui_stat_tile("Collector", ui_status_label(collector_status), status = collector_badge, detail = if (nrow(collector)) paste(collector$artifact_count[[1]], "artifacts") else "not created")
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
      tagList(
        ui_genai_status_panel(
          ctx$genai_status(check_availability = FALSE),
          title = "GenAI Readiness",
          actions = ui_action_row(
            actionButton(ns("brief_project"), "Brief Project", class = "btn-primary btn-sm"),
            actionButton(ns("suggest_next_action"), "Suggest Next Action", class = "btn-secondary btn-sm")
          ),
          result = ctx$genai_last_result()
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

    output$workspace_status <- renderUI({
      data_info <- tryCatch(ctx$project_data_info(), error = function(e) list(path = NULL, name = NULL))
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      rows <- data.table::data.table(
        item = c("Workspace provider", "Workspace", "Project", "Project root", "Current dataset", "Dataset path", "Render target", "Collector DOCX", "Manifest", "Current run"),
        value = c(
          ctx$current_workspace()$provider_id %||% "No provider configured",
          ctx$current_workspace()$workspace_root %||% "No workspace configured",
          ctx$current_project()$project_name %||% "No project open",
          ctx$current_project()$project_root %||% "No project root",
          data_info$name %||% "No dataset loaded",
          data_info$path %||% "No source path",
          if (nrow(collector)) ui_display_label(collector$render_target[[1]] %||% "llm_docx") else "LLM DOCX",
          if (nrow(collector)) collector$collector_docx[[1]] else "Collector not created",
          if (nrow(collector)) ui_status_label(collector$manifest_status[[1]]) else "Not Written",
          if (nrow(collector)) collector$current_run_id[[1]] else "No run yet"
        )
      )
      render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$modeling_context_panel <- renderUI({
      context <- ctx$current_modeling_context()
      validation <- ctx$validate_active_modeling_context()
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      artifact_id <- context$active_dataset_artifact_id %||% NA_character_
      ui_card(
        title = "Active Modeling Context",
        subtitle = "The dataset identity and lineage that downstream modeling will consume.",
        class = "aq-compact-card",
        ui_action_row(
          ui_status_badge(
            ui_status_label(context$active_dataset_source %||% "source_dataset"),
            status = if (identical(validation$status, "success")) "success" else if (identical(validation$status, "warning")) "warning" else "error"
          ),
          if (!is.na(artifact_id) && nzchar(artifact_id)) {
            ui_status_badge("Prepared Artifact", status = "info")
          }
        ),
        tags$dl(
          class = "aq-module-run-summary",
          tags$dt("Dataset"),
          tags$dd(context$active_dataset_label %||% "Active Dataset"),
          tags$dt("Rows"),
          tags$dd(if (is.null(data)) "Not loaded" else format(nrow(data), big.mark = ",")),
          tags$dt("Columns"),
          tags$dd(if (is.null(data)) "Not loaded" else format(ncol(data), big.mark = ",")),
          tags$dt("Prepared Artifact"),
          tags$dd(if (!is.na(artifact_id) && nzchar(artifact_id)) artifact_id else "None"),
          tags$dt("Lineage"),
          tags$dd(context$lineage_summary %||% "No lineage summary recorded.")
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
        item = c("Result ID", "Type", "Module", "Dataset", "Created", "Persisted", "Source Execution", "Project", "Manifest", "Hashes", "Location"),
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

    save_project_action <- function() {
      ctx$project_message("")

      tryCatch({
        if (!isTRUE(ctx$project_ready())) {
          stop("No project is open. Current analytical results are temporary and cannot be saved until a project is created or opened.", call. = FALSE)
        }
        ctx$persist_project_data_if_needed()
        project_state <- ctx$current_project_state()
        output_path <- save_project_state(
          project_state,
          input$project_path,
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
        project_path <- normalize_project_load_path(input$project_path)
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
    observeEvent(input$load_project_secondary, load_project_action(), ignoreInit = TRUE)

    observeEvent(input$configure_workspace, {
      ctx$project_message("")
      result <- ctx$configure_workspace(input$workspace_root, provider_id = input$workspace_provider %||% "configured_workspace")
      ctx$project_message(service_result_message(result))
      add_activity(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$create_project, {
      ctx$project_message("")
      result <- ctx$create_project(input$project_name)
      ctx$project_message(service_result_message(result))
      add_activity(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$close_project, {
      ctx$close_project()
      add_activity("Closed active project.")
    }, ignoreInit = TRUE)

    observeEvent(input$brief_project, {
      result <- genai_brief_project(ctx, config = ctx$genai_config())
      ctx$genai_last_result(result)
      ctx$project_message(service_result_message(result))
      add_activity("Requested read-only GenAI project brief.")
    }, ignoreInit = TRUE)

    observeEvent(input$suggest_next_action, {
      result <- genai_suggest_next_action(ctx, config = ctx$genai_config())
      ctx$genai_last_result(result)
      ctx$project_message(service_result_message(result))
      add_activity("Requested read-only GenAI next-action suggestion.")
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
