page_report_browser_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Report Browser",
    ui_page(
      title = "Report Browser",
      subtitle = "Read structured investigation reports as native workstation reports.",
      eyebrow = "Delivery",
      actions = ui_action_row(
        selectInput(
          ns("report_family"),
          "Report Contract",
          choices = c("Regression", "SHAP", "EDA", "Agent Campaign"),
          selected = "Regression",
          width = "220px"
        )
      ),
      ui_object_spine(
        object = "Interactive Report",
        intent = "Turn governed analytical evidence into a readable investigation record.",
        state = "Consumes validated report records only.",
        next_action = "Choose a report and inspect sections, findings, evidence, and components.",
        depth = "Exports, editing, and artifact inspection remain downstream phases."
      ),
      uiOutput(ns("campaign_claim_trace")),
      uiOutput(ns("report_browser"))
    )
  )
}

page_report_browser_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    available_reports <- reactive({
      reports <- report_browser_demo_reports()
      campaign <- tryCatch(ctx$agent_report_contract(), error = function(e) NULL)
      if (!is.null(campaign)) {
        reports[["Agent Campaign"]] <- campaign
      }
      reports
    })

    observe({
      reports <- available_reports()
      selected <- input$report_family
      if (is.null(selected) || !selected %in% names(reports)) selected <- names(reports)[[1]]
      updateSelectInput(session, "report_family", choices = names(reports), selected = selected)
    })

    output$campaign_claim_trace <- renderUI({
      selected <- input$report_family %||% "Regression"
      if (!identical(selected, "Agent Campaign")) {
        return(NULL)
      }
      session_state <- tryCatch(ctx$agent_session_state(), error = function(e) NULL)
      if (is.null(session_state)) {
        return(ui_card(
          title = "Claim Verification",
          subtitle = "Launch the Build Week demo to activate the campaign trace.",
          body = ui_empty_state("No campaign trace yet.", "The Report Browser will show finding-to-evidence provenance once the campaign report exists.")
        ))
      }
      trace <- agent_campaign_claim_trace(session_state)
      if (!identical(trace$status, "success")) {
        return(ui_card(
          title = "Claim Verification",
          subtitle = "The selected report does not expose a traceable campaign finding.",
          body = ui_empty_state("Trace unavailable.", service_result_message(trace))
        ))
      }
      ui_card(
        title = "Why should I believe this?",
        subtitle = "Initial belief -> evidence -> revisions -> final conclusion.",
        body = ui_campaign_claim_trace(trace$value)
      )
    })

    output$report_browser <- renderUI({
      reports <- available_reports()
      selected <- input$report_family %||% "Regression"
      report <- reports[[selected]] %||% reports[[1]]
      render_report_browser(report)
    })
  })
}
