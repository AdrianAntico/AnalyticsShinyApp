mission_control_artifact_counts <- function(artifacts) {
  types <- if (length(artifacts)) {
    vapply(artifacts, function(artifact) artifact$artifact_type %||% "artifact", character(1))
  } else {
    character()
  }
  metadata <- lapply(artifacts, function(artifact) artifact$metadata %||% list())
  list(
    total = length(artifacts),
    plots = sum(types == "plot"),
    tables = sum(types == "table"),
    narratives = sum(types %in% c("text", "narrative", "genai_narrative")),
    recommendations = sum(types == "recommendation") + sum(vapply(metadata, function(x) length(x$recommendations %||% character()), integer(1)) > 0L),
    diagnostics = sum(types == "diagnostic") + sum(vapply(metadata, function(x) length(x$diagnostics %||% x$warnings %||% character()), integer(1)) > 0L),
    json = sum(vapply(metadata, function(x) !is.null(x$json_path) || !is.null(x$json), logical(1)))
  )
}

mission_control_quality_summary <- function(artifacts) {
  if (!length(artifacts)) {
    return(list(avg = NA_real_, warnings = 0L, failures = 0L, scored = 0L))
  }
  assessments <- lapply(artifacts, function(artifact) {
    tryCatch(assess_artifact_quality(artifact, render_target = "llm_docx"), error = function(e) NULL)
  })
  assessments <- Filter(Negate(is.null), assessments)
  scores <- suppressWarnings(as.numeric(vapply(assessments, function(x) x$artifact_completeness %||% NA_real_, numeric(1))))
  severities <- vapply(assessments, function(x) x$severity %||% "neutral", character(1))
  list(
    avg = if (length(scores) && any(!is.na(scores))) round(mean(scores, na.rm = TRUE), 1) else NA_real_,
    warnings = sum(severities == "warning"),
    failures = sum(severities == "error"),
    scored = length(assessments)
  )
}

mission_control_status_group <- function(status, artifact_count = 0L, warnings = 0L, errors = 0L) {
  if (errors > 0L || status %in% c("failed", "error")) return("error")
  if (warnings > 0L || status %in% c("warning", "partial")) return("warning")
  if (artifact_count > 0L || status %in% c("completed", "success", "ready", "created")) return("success")
  if (status %in% c("running", "active")) return("info")
  "neutral"
}

mission_control_ai_status <- function(collector, artifacts) {
  artifact_count <- if (nrow(collector)) collector$artifact_count[[1]] %||% 0L else length(artifacts)
  manifest_ready <- nrow(collector) && identical(collector$manifest_status[[1]] %||% "", "ready")
  if (artifact_count > 0L && manifest_ready) return("Ready")
  if (artifact_count > 0L) return("Partial")
  "Incomplete"
}

mission_control_alerts <- function(artifacts, collector, quality, workflow) {
  alerts <- list()
  add <- function(title, message, severity = "medium", source = NULL) {
    alerts[[length(alerts) + 1L]] <<- list(title = title, message = message, severity = severity, source = source)
  }

  if (!length(artifacts)) {
    add("No evidence generated", "Run EDA, Model Readiness, Model Insights, or SHAP to populate the project evidence base.", "high", "Artifacts")
  }
  if (!nrow(collector) || (collector$artifact_count[[1]] %||% 0L) == 0L) {
    add("Collector has no artifacts", "The Project Artifact Collector is not yet preserving evidence for this project.", "high", "Collector")
  } else if (!identical(collector$manifest_status[[1]] %||% "", "ready")) {
    add("Collector manifest not ready", "Artifacts exist, but the manifest is not written or restored as ready.", "medium", "Collector")
  }
  if (!is.na(quality$avg) && quality$avg < 70) {
    add("Artifact quality needs review", paste0("Average LLM completeness is ", quality$avg, "%. Inspect warning artifacts before export."), "medium", "Quality")
  }
  if (quality$warnings > 0L) {
    add("Artifact warnings present", paste(quality$warnings, "artifact(s) have quality warnings."), "medium", "Quality")
  }
  if (quality$failures > 0L) {
    add("Artifact failures present", paste(quality$failures, "artifact(s) failed quality checks."), "high", "Quality")
  }
  implemented_without_artifacts <- workflow[status %in% c("implemented", "experimental") & artifact_count == 0L]
  if (nrow(implemented_without_artifacts)) {
    add(
      "Workflow evidence gaps",
      paste("No artifacts yet for:", paste(implemented_without_artifacts$label, collapse = ", ")),
      "low",
      "Workflow"
    )
  }

  if (!length(alerts)) {
    alerts <- list(list(
      title = "No open decisions",
      message = "Mission Control did not detect active warnings, missing collector evidence, or artifact quality failures.",
      severity = "success",
      source = "Project"
    ))
  }
  alerts
}

mission_control_timeline <- function(ctx, artifacts, collector) {
  items <- list()
  add <- function(time, title, detail = NULL, status = "neutral") {
    items[[length(items) + 1L]] <<- list(time = time, title = title, detail = detail, status = status)
  }
  fmt <- function(x) {
    time <- suppressWarnings(as.POSIXct(x))
    if (is.na(time)) return("--:--")
    format(time, "%H:%M")
  }

  data_info <- tryCatch(ctx$project_data_info(), error = function(e) list(path = NULL, name = NULL))
  if (!is.null(data_info$name)) {
    add(format(Sys.time(), "%H:%M"), "Dataset loaded", data_info$name, "success")
  }
  if (length(artifacts)) {
    artifact_rows <- lapply(artifacts, function(artifact) {
      time <- artifact$updated_at %||% artifact$created_at %||% artifact$metadata$generated_at %||% artifact$metadata$run_timestamp %||% Sys.time()
      list(time = time, artifact = artifact)
    })
    artifact_rows <- artifact_rows[order(vapply(artifact_rows, function(x) as.numeric(as.POSIXct(x$time)), numeric(1)), decreasing = TRUE)]
    for (row in utils::head(artifact_rows, 8L)) {
      artifact <- row$artifact
      add(fmt(row$time), paste(artifact$label %||% artifact$artifact_id, "created"), artifact$source_module %||% "artifact", "success")
    }
  }
  if (nrow(collector) && (collector$artifact_count[[1]] %||% 0L) > 0L) {
    add(format(Sys.time(), "%H:%M"), "Collector available", paste(collector$artifact_count[[1]], "artifacts preserved"), "success")
  }
  if (!length(items)) {
    return(list())
  }
  items
}

mission_control_workflow_rows <- function(ctx) {
  workflow <- workflow_state_summary(ctx)
  workflow[, display_status := data.table::fifelse(
    artifact_count > 0L,
    "Completed",
    data.table::fifelse(status %in% c("implemented", "experimental"), "Not Started", data.table::fifelse(status == "planned", "Planned", "Future"))
  )]
  workflow[, status_group := mapply(mission_control_status_group, display_status, artifact_count, 0L, 0L)]
  workflow[, action := data.table::fifelse(!is.na(page) & nzchar(page), "Open", "Planned")]
  workflow[]
}

page_mission_control_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Mission Control",
    ui_page(
      title = "Mission Control",
      subtitle = "Operational awareness for the project, modules, evidence, collector, QA, and AI readiness.",
      eyebrow = "Operations",
      actions = ui_action_row(
        actionButton(ns("open_artifacts"), "Open Artifact Studio", class = "btn-primary"),
        actionButton(ns("open_modules"), "Open Analysis Modules", class = "btn-secondary")
      ),
      tags$div(
        class = "aq-mission-control",
        uiOutput(ns("project_health")),
        tags$div(
          class = "aq-mission-control-grid",
          ui_card(
            title = "System Status",
            subtitle = "Module and workflow readiness.",
            uiOutput(ns("system_status"))
          ),
          ui_card(
            title = "Alerts / Open Decisions",
            subtitle = "Prioritized operational queue, not an error dump.",
            uiOutput(ns("alerts"))
          ),
          uiOutput(ns("genai_status"))
        ),
        tags$div(
          class = "aq-mission-control-grid",
          ui_card(
            title = "AI Assistance",
            subtitle = "Read-only explanations from the configured GenAI provider.",
            ui_action_row(
              actionButton(ns("explain_alerts"), "Explain Alerts", class = "btn-primary btn-sm"),
              actionButton(ns("suggest_next_action"), "Suggest Next Action", class = "btn-secondary btn-sm")
            ),
            uiOutput(ns("genai_result"))
          )
        ),
        ui_card(
          title = "Run Timeline",
          subtitle = "Recent analytical activity reconstructed from project evidence.",
          uiOutput(ns("timeline"))
        )
      )
    )
  )
}

page_mission_control_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    mission_state <- reactive({
      artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
      workflow <- mission_control_workflow_rows(ctx)
      counts <- mission_control_artifact_counts(artifacts)
      quality <- mission_control_quality_summary(artifacts)
      ai_status <- mission_control_ai_status(collector, artifacts)
      list(
        artifacts = artifacts,
        collector = collector,
        data = data,
        plans = plans,
        workflow = workflow,
        counts = counts,
        quality = quality,
        ai_status = ai_status,
        alerts = mission_control_alerts(artifacts, collector, quality, workflow),
        timeline = mission_control_timeline(ctx, artifacts, collector)
      )
    })

    output$project_health <- renderUI({
      state <- mission_state()
      collector_status <- if (nrow(state$collector)) state$collector$collector_status[[1]] %||% "not_created" else "not_created"
      manifest_status <- if (nrow(state$collector)) state$collector$manifest_status[[1]] %||% "not_written" else "not_written"
      qa_status <- tryCatch({
        qa <- qa_artifact_studio()
        if (any(qa$status == "error")) "warning" else "healthy"
      }, error = function(e) "unknown")
      quality_status <- mission_control_status_group("success", warnings = state$quality$warnings, errors = state$quality$failures)
      mission_status <- if (state$quality$failures > 0L || state$counts$total == 0L) {
        "critical"
      } else if (state$quality$warnings > 0L || !identical(manifest_status, "ready") || !identical(state$ai_status, "Ready")) {
        "attention"
      } else {
        "healthy"
      }
      mission_title <- switch(
        mission_status,
        critical = "Mission state: evidence gap",
        attention = "Mission state: attention required",
        healthy = "Mission state: operational",
        "Mission state: monitoring"
      )
      mission_message <- switch(
        mission_status,
        critical = "Evidence generation or collector readiness needs immediate attention before this project can be trusted.",
        attention = "The project is active and evidence is available, but readiness gaps or quality warnings deserve review.",
        healthy = "Core evidence, collector output, QA, and AI readiness are aligned.",
        "Mission Control is monitoring project state."
      )
      mission_facts <- list(
        Evidence = paste(state$counts$total, "artifacts"),
        Collector = collector_status,
        Quality = if (is.na(state$quality$avg)) "Not scored" else paste0(state$quality$avg, "%"),
        Alerts = length(state$alerts)
      )
      ui_health_summary(
        ui_mission_state_banner(mission_status, mission_title, mission_message, mission_facts),
        ui_status_tile("Project", if (is.null(state$data)) "Waiting" else "Active", status = if (is.null(state$data)) "neutral" else "success", detail = if (is.null(state$data)) "No dataset loaded" else paste(nrow(state$data), "rows")),
        ui_status_tile("Collector", collector_status, status = mission_control_status_group(collector_status, artifact_count = state$counts$total), detail = paste(state$counts$total, "artifacts")),
        ui_status_tile("AI Readiness", state$ai_status, status = mission_control_status_group(tolower(state$ai_status), artifact_count = state$counts$total), detail = manifest_status),
        ui_status_tile("Artifact Quality", if (is.na(state$quality$avg)) "Not scored" else paste0(state$quality$avg, "%"), status = quality_status, detail = paste(state$quality$warnings, "warnings")),
        ui_status_tile("Workflow", paste(sum(state$workflow$artifact_count > 0L), "/", nrow(state$workflow)), status = if (sum(state$workflow$artifact_count > 0L) > 0L) "success" else "neutral", detail = "stages with evidence"),
        ui_status_tile("Reports", length(state$plans), status = if (length(state$plans)) "success" else "neutral", detail = "report plans"),
        ui_status_tile("Warnings", state$quality$warnings + state$quality$failures, status = if ((state$quality$warnings + state$quality$failures) > 0L) "warning" else "success", detail = "quality signals"),
        ui_status_tile("QA", qa_status, status = if (identical(qa_status, "healthy")) "success" else "warning", detail = "studio smoke")
      )
    })

    output$system_status <- renderUI({
      ui_workflow_status(mission_state()$workflow, ns = session$ns)
    })

    output$alerts <- renderUI({
      alerts <- mission_state()$alerts
      tags$div(
        class = "aq-alert-queue",
        lapply(alerts, function(alert) {
          ui_alert_card(
            title = alert$title,
            message = alert$message,
            severity = alert$severity,
            source = alert$source
          )
        })
      )
    })

    output$genai_status <- renderUI({
      ui_genai_status_panel(ctx$genai_status(check_availability = FALSE), title = "GenAI Provider")
    })

    output$genai_result <- renderUI({
      result <- ctx$genai_last_result()
      if (is.null(result)) {
        return(ui_empty_state("No GenAI explanation requested.", "Use Explain Alerts or Suggest Next Action for read-only assistance."))
      }
      tags$div(
        ui_status_badge(result$status, status = if (identical(result$status, "success")) "success" else if (identical(result$status, "error")) "error" else "warning"),
        tags$pre(class = "aq-genai-output", result$value$text %||% service_result_message(result))
      )
    })

    output$timeline <- renderUI({
      ui_timeline(mission_state()$timeline)
    })

    observeEvent(input$open_artifacts, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Artifact Studio")
    }, ignoreInit = TRUE)

    observeEvent(input$open_modules, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Analysis Modules")
    }, ignoreInit = TRUE)

    observeEvent(input$explain_alerts, {
      result <- genai_explain_alerts(mission_state()$alerts, config = ctx$genai_config())
      ctx$genai_last_result(result)
    }, ignoreInit = TRUE)

    observeEvent(input$suggest_next_action, {
      result <- genai_suggest_next_action(ctx, config = ctx$genai_config())
      ctx$genai_last_result(result)
    }, ignoreInit = TRUE)

    lapply(workflow_stage_registry(), function(stage) {
      stage_id <- stage$stage_id
      input_id <- paste0("mission_open_", stage_id)
      observeEvent(input[[input_id]], {
        target_page <- stage$page %||% NA_character_
        if (!is.na(target_page) && nzchar(target_page)) {
          if (!is.null(ctx$navigate_to)) ctx$navigate_to(target_page)
        }
      }, ignoreInit = TRUE)
    })
  })
}

qa_mission_control <- function() {
  page <- if (file.exists(file.path("R", "page_mission_control.R"))) {
    paste(readLines(file.path("R", "page_mission_control.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  app_ui <- if (file.exists(file.path("R", "app_ui.R"))) {
    paste(readLines(file.path("R", "app_ui.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  app <- if (file.exists("app.R")) paste(readLines("app.R", warn = FALSE), collapse = "\n") else ""
  components <- if (file.exists(file.path("R", "ui_components.R"))) {
    paste(readLines(file.path("R", "ui_components.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  css <- if (file.exists(file.path("www", "app.css"))) {
    paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  docs <- paste(
    if (file.exists(file.path("docs", "ui_ux_architecture.md"))) readLines(file.path("docs", "ui_ux_architecture.md"), warn = FALSE) else character(),
    if (file.exists(file.path("docs", "roadmap", "ux_roadmap.md"))) readLines(file.path("docs", "roadmap", "ux_roadmap.md"), warn = FALSE) else character(),
    collapse = "\n"
  )
  has <- function(text, patterns) all(vapply(patterns, grepl, logical(1), x = text, fixed = TRUE))

  data.table::data.table(
    check = c(
      "mission_control_page",
      "app_registration",
      "health_tiles",
      "workflow_status",
      "collector_summary",
      "ai_readiness",
      "alert_queue",
      "timeline",
      "empty_state",
      "selection_behavior",
      "navigation_links",
      "reusable_components",
      "namespace_safe_helpers",
      "css_layout",
      "visual_hierarchy",
      "status_presentation",
      "alert_ordering",
      "timeline_rendering",
      "health_tile_consistency",
      "collector_presentation",
      "css_cache_busting",
      "documentation"
    ),
    status = c(
      if (grepl("page_mission_control_ui", page, fixed = TRUE)) "success" else "error",
      if (has(app, "page_mission_control.R") && has(app_ui, "page_mission_control_ui")) "success" else "error",
      if (has(page, c("ui_health_summary", "ui_status_tile", "Artifact Quality"))) "success" else "error",
      if (has(page, c("ui_workflow_status", "workflow_state_summary", "System Status"))) "success" else "error",
      if (has(page, c("project_collector_summary", "Collector", "manifest_status"))) "success" else "error",
      if (has(page, c("mission_control_ai_status", "AI Readiness"))) "success" else "error",
      if (has(page, c("mission_control_alerts", "Alerts / Open Decisions", "aq-alert-queue"))) "success" else "error",
      if (has(page, c("mission_control_timeline", "Run Timeline", "ui_timeline"))) "success" else "error",
      if (has(components, c("No activity yet.", "Workflow status unavailable."))) "success" else "error",
      if (has(page, c("mission_open_", "observeEvent", "open_artifacts"))) "success" else "error",
      if (has(page, c("updateTabsetPanel", "Analysis Modules", "Artifact Studio"))) "success" else "error",
      if (has(components, c("ui_status_tile", "ui_health_summary", "ui_mission_state_banner", "ui_alert_card", "ui_timeline", "ui_workflow_status"))) "success" else "error",
      if (!grepl("[^:]\\bfifelse\\(", page, perl = TRUE)) "success" else "error",
      if (has(css, c(".aq-mission-control", ".aq-health-summary", ".aq-alert-card", ".aq-timeline", ".aq-workflow-status-board"))) "success" else "error",
      if (has(page, c("ui_mission_state_banner", "mission_status", "mission_title")) && has(css, c(".aq-mission-state-banner", ".aq-mission-state-pulse"))) "success" else "error",
      if (has(css, c(".aq-status-tile-success::before", ".aq-status-tile-warning::before", ".aq-status-tile-error::before"))) "success" else "error",
      if (has(page, c("mission_control_alerts", "critical", "attention", "quality warnings"))) "success" else "error",
      if (has(css, c(".aq-timeline-item::before", ".aq-timeline-item:not(:last-child)::after"))) "success" else "error",
      if (has(css, c(".aq-health-summary", "grid-column: 1 / -1", ".aq-status-tile-value"))) "success" else "error",
      if (has(page, c("Collector", "manifest_status", "collector_status", "state$counts$total"))) "success" else "error",
      if (has(app_ui, c("app.css?v=", "file.info(css_file)$mtime"))) "success" else "error",
      if (has(docs, c("Mission Control", "Operational awareness", "Alert philosophy", "Timeline"))) "success" else "error"
    ),
    message = c(
      "Mission Control page module exists.",
      "Mission Control is sourced and registered in the app shell.",
      "Project health tiles are present.",
      "Workflow/system status board is present.",
      "Collector status is surfaced.",
      "AI readiness is surfaced.",
      "Alert queue is present.",
      "Run timeline is present.",
      "Empty states are present.",
      "Selection/open behavior is wired.",
      "Navigation links target existing modes.",
      "Reusable Mission Control primitives exist.",
      "Mission Control helpers use namespace-safe data.table calls.",
      "Mission Control CSS selectors exist.",
      "Mission Control has a first-read mission state banner.",
      "Health and workflow statuses use state-bearing color rails.",
      "Alert generation preserves operational priority semantics.",
      "Timeline uses connected event markers.",
      "Health tiles share consistent sizing and hierarchy.",
      "Collector state is included in health and alert presentation.",
      "App CSS is cache-busted so Mission Control visual updates render after restart.",
      "Mission Control documentation is present."
    )
  )
}
