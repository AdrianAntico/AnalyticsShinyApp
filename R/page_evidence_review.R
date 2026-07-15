page_evidence_review_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Evidence Review",
    value = "evidence_review",
    ui_page(
      title = "Evidence Review",
      subtitle = "Review the current question, evidence, sufficiency, valuation, workflow status, and next action in one working context.",
      eyebrow = "Working Context",
      actions = ui_action_row(
        actionButton(ns("open_artifacts"), "Open Artifact Studio", class = "btn-secondary"),
        actionButton(ns("open_decisions"), "Open Decision Workbench", class = "btn-secondary"),
        actionButton(ns("open_mission"), "Open Mission Control", class = "btn-secondary")
      ),
      ui_workspace_grid(
        columns = "main-sidebar",
        tagList(
          uiOutput(ns("context_overview")),
          ui_card(
            title = "Current Question",
            subtitle = "The work begins with the question under evaluation.",
            uiOutput(ns("current_question"))
          ),
          ui_card(
            title = "Current Evidence",
            subtitle = "Relevant artifacts and cross-artifact synthesis stay in the working set.",
            uiOutput(ns("current_evidence"))
          ),
          ui_card(
            title = "Reasoning",
            subtitle = "Evidence sufficiency, contradictions, valuation, and workflow status.",
            uiOutput(ns("reasoning"))
          ),
          ui_card(
            title = "Current Draft",
            subtitle = "The decision draft remains visible while evidence is reviewed.",
            uiOutput(ns("current_draft"))
          ),
          ui_card(
            title = "Progressive Depth",
            subtitle = "The workspace grows deeper as the work becomes deeper.",
            uiOutput(ns("progressive_depth"))
          )
        ),
        tagList(
          ui_card(
            title = "Supported Next Action",
            subtitle = "One next action, with related work nearby.",
            uiOutput(ns("next_action")),
            ui_action_row(
              actionButton(ns("open_valuation"), "Valuation", class = "btn-primary btn-sm"),
              actionButton(ns("open_workflow"), "Workflow", class = "btn-secondary btn-sm")
            )
          ),
          ui_card(
            title = "Mission Summary",
            subtitle = "Context-relevant status only. Full Mission Control remains one step away.",
            uiOutput(ns("mission_summary"))
          ),
          ui_card(
            title = "Related Tasks",
            subtitle = "Adjacent work, not the entire application.",
            uiOutput(ns("related_tasks"))
          ),
          ui_card(
            title = "Capability Exposure",
            subtitle = "Primary and adjacent capabilities appear first. Deeper capability is available later.",
            uiOutput(ns("capability_exposure"))
          )
        )
      )
    )
  )
}

page_evidence_review_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    context_state <- reactive({
      working_context_build_evidence_review(
        artifacts = tryCatch(ctx$all_artifacts(), error = function(e) list()),
        collector_summary = tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table()),
        semantic_decision_state = tryCatch(ctx$semantic_decision_state(), error = function(e) semantic_decision_empty()),
        semantic_workspace = tryCatch(ctx$semantic_workspace(), error = function(e) semantic_workspace_empty()),
        valuation_state = tryCatch(ctx$decision_valuation_state(), error = function(e) decision_valuation_empty()),
        workflow_state = tryCatch(ctx$decision_workflow_state(), error = function(e) decision_workflow_empty())
      )
    })

    observeEvent(input$open_artifacts, ctx$navigate_to("Artifact Studio"), ignoreInit = TRUE)
    observeEvent(input$open_decisions, ctx$navigate_to("Semantic Intelligence"), ignoreInit = TRUE)
    observeEvent(input$open_mission, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)
    observeEvent(input$open_valuation, ctx$navigate_to("Semantic Intelligence"), ignoreInit = TRUE)
    observeEvent(input$open_workflow, ctx$navigate_to("Semantic Intelligence"), ignoreInit = TRUE)

    output$context_overview <- renderUI({
      context <- context_state()
      suff <- context$evidence_sufficiency
      ui_stat_grid(
        ui_stat_tile("Working Context", context$label, status = "info", detail = "task-first workspace"),
        ui_stat_tile("Evidence", context$artifact_summary$artifact_count[[1]], status = if (context$artifact_summary$artifact_count[[1]] > 0L) "success" else "warning", detail = "artifact(s)"),
        ui_stat_tile("Sufficiency", ui_display_label(suff$status[[1]]), status = if (suff$status[[1]] == "reasonable") "success" else if (suff$status[[1]] == "preliminary") "warning" else "error", detail = paste0(suff$score[[1]], "%")),
        ui_stat_tile("Collector", ui_display_label(context$collector_status), status = if (context$collector_status %in% c("success", "created", "restored")) "success" else "neutral")
      )
    })

    output$current_question <- renderUI({
      context <- context_state()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Business Question"), tags$span(context$business_question)),
        tags$div(class = "aq-status-item", tags$strong("Decision Context"), tags$span(context$decision_context_id %||% "Not authored")),
        tags$div(class = "aq-status-item", tags$strong("Current Job"), tags$span("Evaluate whether evidence is sufficient to support the next decision."))
      )
    })

    output$current_evidence <- renderUI({
      context <- context_state()
      tags$div(
        class = "aq-status-list",
        render_table(context$artifact_summary, engine = "html", searchable = FALSE, sortable = FALSE),
        tags$div(class = "aq-callout aq-callout-info", tags$strong("Cross-Artifact Synthesis"), tags$p(context$cross_artifact_synthesis))
      )
    })

    output$reasoning <- renderUI({
      context <- context_state()
      tags$div(
        class = "aq-status-list",
        render_table(context$evidence_sufficiency, engine = "html", searchable = FALSE, sortable = FALSE),
        tags$div(class = "aq-callout aq-callout-warning", tags$strong("Contradictions / Caveats"), tags$p(context$contradictions)),
        ui_disclosure(
          "Valuation Summary",
          render_table(context$valuation_summary, engine = "html", searchable = FALSE, sortable = FALSE),
          open = FALSE
        ),
        ui_disclosure(
          "Workflow Status",
          render_table(context$workflow_summary, engine = "html", searchable = FALSE, sortable = FALSE),
          open = FALSE
        )
      )
    })

    output$current_draft <- renderUI({
      render_table(context_state()$current_draft, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$progressive_depth <- renderUI({
      render_table(context_state()$progressive_depth, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$next_action <- renderUI({
      context <- context_state()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Next Action"), tags$span(context$supported_next_action)),
        tags$div(class = "aq-status-item", tags$strong("Why"), tags$span("The context prioritizes the smallest next step that improves decision readiness."))
      )
    })

    output$mission_summary <- renderUI({
      render_table(context_state()$mission_summary, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$related_tasks <- renderUI({
      transitions <- context_state()$transitions
      render_table(transitions[, c("adjacent_task", "target_surface", "transition_type", "reason"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$capability_exposure <- renderUI({
      map <- context_state()$capability_map
      render_table(map[, c("capability", "exposure", "initial_visibility", "reason"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })
  })
}
