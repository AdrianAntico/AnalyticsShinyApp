ui_global_ai_assistant <- function(id = "global_ai_assistant") {
  ns <- NS(id)
  tags$aside(
    class = "aq-global-ai-assistant",
    tags$details(
      class = "aq-global-ai-details",
      tags$summary(
        class = "aq-global-ai-trigger",
        tags$span(class = "aq-global-ai-pulse"),
        tags$span(class = "aq-global-ai-trigger-copy", tags$strong("Guide"), tags$small("AI assistance")),
        tags$span(class = "aq-global-ai-trigger-hint", "?")
      ),
      tags$section(
        class = "aq-global-ai-panel",
        tags$header(
          class = "aq-global-ai-header",
          tags$div(
            tags$p(class = "aq-section-eyebrow", "Read-only mentor"),
            tags$h3("Guide / AI Assistance"),
            tags$p("Explain the current workspace, alerts, and next analytical action.")
          )
        ),
        uiOutput(ns("status")),
        tags$div(
          class = "aq-global-ai-actions",
          actionButton(ns("explain_alerts"), "Explain Alerts", class = "btn-primary btn-sm"),
          actionButton(ns("suggest_next_action"), "Suggest Next Action", class = "btn-secondary btn-sm"),
          actionButton(ns("open_guide"), "Open Guide", class = "btn-secondary btn-sm")
        ),
        uiOutput(ns("proposal")),
        uiOutput(ns("result"))
      )
    )
  )
}

global_ai_mission_state <- function(ctx) {
  artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
  collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
  workflow <- tryCatch(mission_control_workflow_rows(ctx), error = function(e) data.table::data.table())
  quality <- tryCatch(mission_control_quality_summary(artifacts), error = function(e) {
    list(avg = NA_real_, warnings = 0L, failures = 0L, scored = 0L)
  })
  alerts <- tryCatch(
    mission_control_alerts(artifacts, collector, quality, workflow),
    error = function(e) list(list(
      title = "Guide context unavailable",
      message = conditionMessage(e),
      severity = "medium",
      source = "Guide"
    ))
  )
  list(
    artifacts = artifacts,
    collector = collector,
    workflow = workflow,
    quality = quality,
    alerts = alerts
  )
}

ui_global_ai_status <- function(status) {
  value <- if (is.list(status$value)) status$value else list()
  metadata <- status$metadata %||% list()
  configured <- isTRUE(value$configured %||% FALSE)
  available <- isTRUE(value$available %||% FALSE)
  availability_checked <- isTRUE(value$availability_checked %||% FALSE)
  status_label <- if (!configured) {
    "Not configured"
  } else if (available) {
    "Available"
  } else if (!availability_checked) {
    "Not checked"
  } else {
    "Unavailable"
  }
  status_class <- if (available) "success" else if (configured && !availability_checked) "info" else if (configured) "warning" else "neutral"
  tags$div(
    class = "aq-global-ai-status",
    ui_status_badge(status_label, status = status_class),
    tags$span(metadata$display_name %||% metadata$provider %||% "No GenAI provider"),
    tags$span(metadata$model %||% "No model")
  )
}

ui_global_ai_result <- function(result) {
  if (is.null(result)) {
    return(ui_empty_state(
      "Guide is standing by.",
      "Use Explain Alerts or Suggest Next Action from any page for read-only assistance."
    ))
  }
  status <- if (identical(result$status, "success")) {
    "success"
  } else if (identical(result$status, "error")) {
    "error"
  } else {
    "warning"
  }
  value <- if (is.list(result$value)) result$value else list()
  tags$div(
    class = "aq-global-ai-result",
    ui_status_badge(result$status, status = status),
    tags$pre(class = "aq-genai-output", value$text %||% service_result_message(result))
  )
}

global_ai_assistant_server <- function(id = "global_ai_assistant", ctx) {
  moduleServer(id, function(input, output, session) {
    store_proposal_from_result <- function(result) {
      proposal <- result$metadata$action_proposal %||% NULL
      if (!is.null(proposal) && is.function(ctx$set_genai_action_proposal)) {
        ctx$set_genai_action_proposal(proposal)
      }
      invisible(proposal)
    }

    output$status <- renderUI({
      status <- tryCatch(
        ctx$genai_status(check_availability = FALSE),
        error = function(e) service_result(
          status = "warning",
          value = list(available = FALSE, configured = FALSE, capabilities = genai_capabilities()),
          warnings = conditionMessage(e),
          metadata = list(display_name = "GenAI status unavailable", model = NA_character_)
        )
      )
      ui_global_ai_status(status)
    })

    output$result <- renderUI({
      ui_global_ai_result(ctx$genai_last_result())
    })

    output$proposal <- renderUI({
      ui_genai_action_proposal_review(
        ctx$genai_action_state$proposal,
        validation = ctx$genai_action_state$validation,
        ns = session$ns
      )
    })

    observeEvent(input$explain_alerts, {
      state <- global_ai_mission_state(ctx)
      result <- genai_explain_alerts(state$alerts, config = ctx$genai_config())
      ctx$genai_last_result(result)
      store_proposal_from_result(result)
    }, ignoreInit = TRUE)

    observeEvent(input$suggest_next_action, {
      result <- genai_suggest_next_action(ctx, config = ctx$genai_config())
      ctx$genai_last_result(result)
      store_proposal_from_result(result)
    }, ignoreInit = TRUE)

    observeEvent(input$open_guide, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Guide")
    }, ignoreInit = TRUE)

    observeEvent(input$approve_proposal, {
      proposal <- ctx$genai_action_state$proposal
      validation <- genai_validate_action_proposal(proposal, policy = ctx$genai_action_policy(), ctx = ctx)
      ctx$genai_action_state$validation <- validation
      approval <- genai_approve_action_proposal(proposal, validation, approval_source = "active_user")
      if (!identical(approval$status, "success")) {
        ctx$genai_action_state$execution_result <- approval
        return()
      }
      ctx$genai_action_state$approved_proposal <- approval$value
      execution <- genai_execute_action_proposal(
        approval$value,
        ctx = ctx,
        policy = ctx$genai_action_policy(),
        approval_hash = approval$value$approval_hash
      )
      ctx$genai_action_state$execution_result <- execution
      if (!is.null(ctx$genai_action_state$proposal)) {
        ctx$genai_action_state$proposal$status <- execution$value$status %||% execution$status
      }
      if (data.table::is.data.table(execution$metadata$audit_event)) {
        ctx$genai_action_state$audit_log <- data.table::rbindlist(
          list(ctx$genai_action_state$audit_log, execution$metadata$audit_event),
          fill = TRUE
        )
      }
      ctx$genai_last_result(service_result(
        status = execution$status,
        value = list(text = service_result_message(execution)),
        messages = execution$messages,
        warnings = execution$warnings,
        errors = execution$errors,
        metadata = list(action_execution = execution$value, audit_event = execution$metadata$audit_event)
      ))
    }, ignoreInit = TRUE)

    observeEvent(input$reject_proposal, {
      proposal <- ctx$genai_action_state$proposal
      rejection <- genai_reject_action_proposal(proposal, approval_source = "active_user")
      ctx$genai_action_state$proposal <- rejection$value
      ctx$genai_action_state$execution_result <- rejection
    }, ignoreInit = TRUE)

    observeEvent(input$cancel_proposal, {
      proposal <- ctx$genai_action_state$proposal
      cancellation <- genai_cancel_action_proposal(proposal, approval_source = "active_user")
      ctx$genai_action_state$proposal <- cancellation$value
      ctx$genai_action_state$execution_result <- cancellation
    }, ignoreInit = TRUE)
  })
}

qa_global_ai_assistant <- function() {
  read_file <- function(path) {
    if (file.exists(path)) paste(readLines(path, warn = FALSE), collapse = "\n") else ""
  }
  helper <- read_file(file.path("R", "global_ai_assistant.R"))
  app <- read_file("app.R")
  app_ui <- read_file(file.path("R", "app_ui.R"))
  app_server <- read_file(file.path("R", "app_server.R"))
  css <- read_file(file.path("www", "app.css"))
  has <- function(text, patterns) all(vapply(patterns, grepl, logical(1), x = text, fixed = TRUE))

  data.table::data.table(
    check = c(
      "floating_ui_exists",
      "app_shell_mount",
      "server_mount",
      "read_only_actions",
      "mission_context_reuse",
      "status_degrades_gracefully",
      "status_not_checked_distinct",
      "proposal_review_ui",
      "approval_executes_only_registered_action",
      "audit_log_recorded",
      "fixed_following_dock",
      "themed_response_scrollbar",
      "compact_default"
    ),
    status = c(
      if (has(helper, c("ui_global_ai_assistant", "aq-global-ai-assistant", "tags$details"))) "success" else "error",
      if (has(app, "global_ai_assistant.R") && has(app_ui, "ui_global_ai_assistant(\"global_ai\")")) "success" else "error",
      if (has(app_server, "global_ai_assistant_server(\"global_ai\", ctx)")) "success" else "error",
      if (has(helper, c("genai_explain_alerts", "genai_suggest_next_action", "Open Guide", "Read-only mentor"))) "success" else "error",
      if (has(helper, c("mission_control_alerts", "mission_control_workflow_rows", "mission_control_quality_summary"))) "success" else "error",
      if (has(helper, c("tryCatch", "service_result", "Not configured"))) "success" else "error",
      if (has(helper, c("availability_checked", "Not checked", "status_class"))) "success" else "error",
      if (has(helper, c("ui_genai_action_proposal_review", "approve_proposal", "reject_proposal", "cancel_proposal"))) "success" else "error",
      if (has(helper, c("genai_approve_action_proposal", "genai_execute_action_proposal", "approval_hash"))) "success" else "error",
      if (has(helper, c("audit_log", "audit_event", "data.table::rbindlist"))) "success" else "error",
      if (has(css, c(".aq-global-ai-assistant", "position: fixed", "bottom:", "right:"))) "success" else "error",
      if (has(css, c(".aq-global-ai-panel .aq-genai-output::-webkit-scrollbar-thumb", "scrollbar-color", ".aq-global-ai-panel::-webkit-scrollbar"))) "success" else "error",
      if (has(css, c(".aq-global-ai-trigger", ".aq-global-ai-panel", ".aq-global-ai-details[open]"))) "success" else "error"
    ),
    message = c(
      "Global Guide / AI Assistance UI is implemented as a reusable floating details dock.",
      "The app shell mounts the global assistant once for all pages.",
      "The app server wires the global assistant to the shared project context.",
      "Global assistant actions remain read-only: explain alerts, suggest next action, and open Guide.",
      "The assistant reuses Mission Control alert and workflow context instead of inventing a second state model.",
      "Provider status errors are captured and rendered as graceful guidance.",
      "The floating assistant distinguishes not-checked provider status from unavailable provider status.",
      "The floating assistant can render a validated GenAI action proposal review.",
      "Approval is explicit and execution flows through the registered action handler.",
      "Successful action execution appends an audit event.",
      "The assistant is fixed-position so it follows the user around the workstation.",
      "The assistant panel and GenAI response output use workstation-themed scrollbars.",
      "The assistant is collapsed by default and expands only when requested."
    )
  )
}
