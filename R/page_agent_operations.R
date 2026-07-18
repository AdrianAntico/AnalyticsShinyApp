page_agent_operations_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Agent Operations",
    value = "agent_operations",
    tags$main(
      class = "aq-page aq-page-agent-operations",
      ui_section_header(
        "Agent Operations",
        "Run a bounded, observable investigation at machine speed while showing the reasoning at human speed.",
        eyebrow = "AI OPERATIONS"
      ),
      ui_object_spine(
        object = "Governed Investigation",
        intent = "Convert an agent objective into deterministic app actions, service runs, evidence, decisions, and a semantic report.",
        state = "No autonomous free-form execution. Every step is registered, replayable, and inspectable.",
        next_action = "Choose a pace, run the funnel driver campaign, and inspect the resulting evidence trail.",
        depth = "Replay uses the recorded AgentSession without rerunning analysis."
      ),
      tags$section(
        class = "aq-agent-control-bar",
        tags$div(
          class = "aq-agent-control-main",
          tags$strong("Campaign"),
          tags$span(textOutput(ns("campaign_status"), inline = TRUE))
        ),
        tags$div(
          class = "aq-agent-control-actions",
          actionButton(ns("run_campaign"), "Run Demo Campaign"),
          actionButton(ns("pause"), "Pause"),
          actionButton(ns("step"), "Step"),
          actionButton(ns("resume"), "Resume"),
          actionButton(ns("skip_animation"), "Skip Animation"),
          actionButton(ns("stop"), "Stop"),
          actionButton(ns("replay"), "Replay")
        )
      ),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          title = "Operation Settings",
          subtitle = "Presentation speed changes the observable experience, not the deterministic campaign result.",
          selectInput(ns("preset"), "Preset", choices = names(agent_operation_presets()), selected = "Follow Along"),
          checkboxInput(ns("approve_shap"), "Approve SHAP gate when campaign reaches it", value = TRUE),
          tags$div(
            class = "aq-agent-settings-grid",
            checkboxInput(ns("cursor_enabled"), "Cursor", value = TRUE),
            checkboxInput(ns("show_observations"), "Observations", value = TRUE),
            checkboxInput(ns("show_decisions"), "Decisions", value = TRUE),
            checkboxInput(ns("show_evidence"), "Evidence", value = TRUE),
            checkboxInput(ns("show_raw_events"), "Raw events", value = FALSE)
          )
        ),
        ui_card(
          title = "Mock Agent Cursor",
          subtitle = "Semantic target visualization only. It does not drive the app by screen coordinates.",
          uiOutput(ns("cursor_stage"))
        )
      ),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          title = "Activity Timeline",
          subtitle = "Registered actions, status, target, and rationale.",
          uiOutput(ns("activity_timeline"))
        ),
        ui_card(
          title = "Decision Trace",
          subtitle = "Human-readable reasoning trace. No hidden chain of thought.",
          uiOutput(ns("decision_trace"))
        )
      ),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          title = "Evidence Accumulation",
          subtitle = "Evidence references produced by service runs and report assembly.",
          uiOutput(ns("evidence_accumulation"))
        ),
        ui_card(
          title = "Report Assembly",
          subtitle = "Validated campaign ReportContract and claim traceability.",
          uiOutput(ns("report_assembly")),
          tags$div(
            class = "aq-action-row",
            actionButton(ns("open_report"), "Open Report Browser"),
            actionButton(ns("why_believe"), "Why should I believe this?")
          ),
          uiOutput(ns("claim_trace"))
        )
      )
    )
  )
}

page_agent_operations_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    settings <- reactive({
      preset_settings <- agent_operation_settings(input$preset %||% "Follow Along")
      agent_operation_settings(
        input$preset %||% "Follow Along",
        overrides = list(
          cursor_enabled = isTRUE(input$cursor_enabled),
          show_observations = isTRUE(input$show_observations),
          show_decisions = isTRUE(input$show_decisions),
          show_evidence = isTRUE(input$show_evidence),
          show_raw_events = isTRUE(input$show_raw_events),
          require_approval_at_gates = TRUE,
          cursor_travel_duration = preset_settings$cursor_travel_duration,
          pause_before_action = preset_settings$pause_before_action,
          pause_after_action = preset_settings$pause_after_action,
          minimum_page_dwell = preset_settings$minimum_page_dwell,
          minimum_result_dwell = preset_settings$minimum_result_dwell,
          show_navigation = preset_settings$show_navigation,
          show_confidence = preset_settings$show_confidence,
          show_rejected_alternatives = preset_settings$show_rejected_alternatives,
          auto_scroll = preset_settings$auto_scroll
        )
      )
    })

    observeEvent(input$preset, {
      preset <- agent_operation_settings(input$preset %||% "Follow Along")
      updateCheckboxInput(session, "cursor_enabled", value = isTRUE(preset$cursor_enabled))
      updateCheckboxInput(session, "show_observations", value = isTRUE(preset$show_observations))
      updateCheckboxInput(session, "show_decisions", value = isTRUE(preset$show_decisions))
      updateCheckboxInput(session, "show_evidence", value = isTRUE(preset$show_evidence))
      updateCheckboxInput(session, "show_raw_events", value = isTRUE(preset$show_raw_events))
    }, ignoreInit = TRUE)

    observeEvent(input$run_campaign, {
      result <- run_funnel_driver_investigation(
        data = ctx$project_data() %||% agent_funnel_contract_fixture(),
        approve_shap = isTRUE(input$approve_shap),
        presentation_settings = settings()
      )
      ctx$agent_session_state(result$value)
      ctx$agent_report_contract(result$value$report_contract %||% NULL)
    })

    observeEvent(input$pause, {
      current <- ctx$agent_session_state()
      if (inherits(current, "agent_session") && current$status %in% c("running", "awaiting_approval")) {
        ctx$agent_session_state(agent_session_pause(current))
      }
    })

    observeEvent(input$resume, {
      current <- ctx$agent_session_state()
      if (inherits(current, "agent_session") && identical(current$status, "paused")) {
        ctx$agent_session_state(agent_session_resume(current))
      }
    })

    observeEvent(input$step, {
      current <- ctx$agent_session_state()
      if (inherits(current, "agent_session")) {
        ctx$agent_session_state(agent_session_step(current))
      }
    })

    observeEvent(input$skip_animation, {
      current <- ctx$agent_session_state()
      if (inherits(current, "agent_session")) {
        current$presentation_settings <- agent_operation_settings("Instant")
        ctx$agent_session_state(current)
      }
    })

    observeEvent(input$stop, {
      current <- ctx$agent_session_state()
      if (inherits(current, "agent_session") && !current$status %in% agent_terminal_states) {
        ctx$agent_session_state(agent_session_cancel(current))
      }
    })

    observeEvent(input$replay, {
      current <- ctx$agent_session_state()
      if (inherits(current, "agent_session")) {
        ctx$agent_session_state(agent_session_replay(current, presentation_settings = settings()))
      }
    })

    observeEvent(input$open_report, {
      if (!is.null(ctx$agent_report_contract())) {
        session$sendCustomMessage("aq-switch-tab", "Report Browser")
      }
    })

    output$campaign_status <- renderText({
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session")) {
        return("No campaign has been run.")
      }
      paste(ui_display_label(current$status), "| actions:", length(current$actions %||% list()), "| report:", current$report_id %||% "not built")
    })

    output$cursor_stage <- renderUI({
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session")) {
        return(ui_empty_state("Cursor standing by", "Run the campaign to see semantic targets highlighted."))
      }
      target <- current$presentation_state$current_target %||% "control_bar"
      resolved <- resolve_agent_cursor_target(target)
      settings_value <- current$presentation_settings %||% list()
      tags$div(
        class = .aq_class("aq-agent-cursor-stage", if (isTRUE(settings_value$cursor_enabled)) "aq-agent-cursor-enabled" else "aq-agent-cursor-disabled"),
        tags$div(class = "aq-agent-cursor-target", tags$span("Target"), tags$strong(resolved$value$label %||% target)),
        tags$div(class = "aq-agent-cursor-path"),
        tags$div(class = "aq-agent-cursor", "?"),
        tags$p(class = "aq-muted", if (identical(resolved$status, "warning")) paste(resolved$warnings, collapse = " ") else "Cursor target resolved through the semantic target registry.")
      )
    })

    output$activity_timeline <- renderUI({
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session") || !length(current$actions %||% list())) {
        return(ui_empty_state("No actions recorded", "Run the campaign to create an observable event stream."))
      }
      actions <- current$actions %||% list()
      if (!isTRUE((current$presentation_settings %||% list())$show_raw_events)) {
        actions <- tail(actions, 12L)
      }
      tags$ol(
        class = "aq-agent-timeline",
        lapply(actions, function(action) {
          tags$li(
            class = paste("aq-agent-event", paste0("aq-agent-event-", action$status %||% "pending")),
            tags$div(
              tags$strong(action$label %||% ui_display_label(action$action_type)),
              tags$span(class = "aq-agent-event-meta", paste(ui_display_label(action$action_type), "|", ui_display_label(action$status), "|", action$target %||% "no target"))
            ),
            if (!is.null(action$rationale)) tags$p(action$rationale)
          )
        })
      )
    })

    output$decision_trace <- renderUI({
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session") || !length(current$decision_traces %||% list())) {
        return(ui_empty_state("No decisions recorded", "Decision traces appear when the campaign reviews service outputs or gates."))
      }
      traces <- current$decision_traces %||% list()
      tags$div(
        class = "aq-agent-decision-stack",
        lapply(tail(traces, 4L), function(trace) {
          tags$article(
            class = "aq-agent-decision",
            tags$p(class = "aq-agent-label", trace$goal),
            tags$h4(trace$decision),
            tags$p(trace$basis),
            tags$div(
              class = "aq-agent-evidence-strip",
              tags$span("Evidence"),
              if (length(trace$evidence_ids %||% character())) {
                lapply(trace$evidence_ids, function(id) tags$code(id))
              } else {
                tags$em("No evidence required for this governance decision.")
              }
            )
          )
        })
      )
    })

    output$evidence_accumulation <- renderUI({
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session") || !length(current$evidence_references %||% list())) {
        return(ui_empty_state("No evidence yet", "Service reports and artifacts are recorded here as the campaign runs."))
      }
      tags$div(
        class = "aq-agent-evidence-grid",
        lapply(current$evidence_references %||% list(), function(evidence) {
          tags$article(
            class = "aq-agent-evidence-card",
            tags$p(class = "aq-agent-label", ui_display_label(evidence$evidence_type %||% "evidence")),
            tags$h4(evidence$title %||% evidence$evidence_id),
            tags$code(evidence$evidence_id),
            tags$p(class = "aq-muted", evidence$source %||% "Recorded by AgentSession")
          )
        })
      )
    })

    output$report_assembly <- renderUI({
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session") || is.null(current$report_contract)) {
        return(ui_empty_state("No campaign report", "Run the campaign to assemble a semantic ReportContract."))
      }
      validation <- validate_report(current$report_contract)
      ui_stat_grid(
        ui_stat_tile("Report", current$report_contract$title, detail = current$report_contract$report_id),
        ui_stat_tile("Validation", ui_display_label(validation$status), status = if (identical(validation$status, "success")) "success" else "warning"),
        ui_stat_tile("Sections", length(current$report_contract$sections %||% list())),
        ui_stat_tile("Components", length(current$report_contract$components %||% list())),
        ui_stat_tile("Evidence", length(current$evidence_references %||% list()))
      )
    })

    output$claim_trace <- renderUI({
      input$why_believe
      current <- ctx$agent_session_state()
      if (!inherits(current, "agent_session") || is.null(current$report_contract) || input$why_believe < 1L) {
        return(NULL)
      }
      trace <- agent_campaign_claim_trace(current)
      if (!identical(trace$status, "success")) {
        return(ui_empty_state("Trace unavailable", paste(trace$errors, collapse = " ")))
      }
      value <- trace$value
      tags$article(
        class = "aq-agent-claim-trace",
        tags$p(class = "aq-agent-label", "Why should I believe this?"),
        tags$h4(value$claim),
        tags$p(tags$strong("Method: "), value$method),
        tags$p(tags$strong("Diagnostic: "), ui_display_label(value$diagnostic)),
        tags$div(
          class = "aq-agent-evidence-strip",
          tags$span("Evidence IDs"),
          lapply(value$evidence_ids, function(id) tags$code(id))
        ),
        report_browser_list(value$limitations, empty = "No limitations recorded.")
      )
    })
  })
}
