build_week_stage_sequence <- function() {
  list(
    list(id = "objective", label = "Objective", detail = "Start with the question worth answering.", stages = character()),
    list(id = "observation", label = "Observation", detail = "Find the first signal in the data.", stages = "observation"),
    list(id = "uncertainty", label = "Uncertainty", detail = "Name what remains unresolved.", stages = "important_uncertainty"),
    list(id = "explanations", label = "Explanations", detail = "Compare plausible causes.", stages = "competing_explanations"),
    list(id = "investigation", label = "Investigation", detail = "Choose the evidence path.", stages = c("candidate_investigations", "selected_investigation")),
    list(id = "evidence", label = "Evidence", detail = "Collect governed evidence.", stages = "evidence_collected"),
    list(id = "belief", label = "Belief", detail = "Revise the working belief.", stages = "belief_update"),
    list(id = "recommendation", label = "Recommendation", detail = "Update the guidance.", stages = "decision_impact"),
    list(id = "verification", label = "Integrity", detail = "Challenge the recommendation before action.", stages = c("remaining_uncertainty", "stopping_rule"))
  )
}

build_week_visible_events <- function(session_state) {
  inquiry <- session_state$inquiry %||% NULL
  events <- inquiry$timeline %||% list()
  if (isTRUE(session_state$presentation_state$replay) && length(events)) {
    visible_count <- max(1L, min(length(events), as.integer(session_state$presentation_state$step_index %||% 1L)))
    events <- events[seq_len(visible_count)]
  }
  events
}

build_week_stage_status <- function(session_state = NULL) {
  sequence <- build_week_stage_sequence()
  if (is.null(session_state)) {
    sequence[[1L]]$status <- "active"
    for (i in seq_along(sequence)[-1L]) sequence[[i]]$status <- "pending"
    return(sequence)
  }
  events <- build_week_visible_events(session_state)
  event_stages <- vapply(events, function(event) event$stage %||% "", character(1))
  active_stage <- if (length(event_stages)) tail(event_stages, 1L) else ""
  for (i in seq_along(sequence)) {
    stage <- sequence[[i]]
    has_stage <- length(intersect(stage$stages, event_stages)) > 0L
    is_active <- length(intersect(stage$stages, active_stage)) > 0L
    if (identical(stage$id, "objective")) {
      stage$status <- if (length(events)) "complete" else "active"
    } else if (is_active) {
      stage$status <- "active"
    } else if (has_stage) {
      stage$status <- "complete"
    } else {
      stage$status <- "pending"
    }
    sequence[[i]] <- stage
  }
  sequence
}

ui_build_week_progress <- function(session_state = NULL) {
  stages <- build_week_stage_status(session_state)
  tags$div(
    class = "aq-build-week-progress",
    tags$div(
      class = "aq-build-week-progress-header",
      tags$div(
        tags$p(class = "aq-report-browser-eyebrow", "Investigation Path"),
        tags$h4("Objective -> evidence -> integrity review -> decision readiness")
      ),
      tags$p("What changed, why it changed, and why the final claim is credible.")
    ),
    tags$div(
      class = "aq-build-week-steps",
      lapply(seq_along(stages), function(i) {
        stage <- stages[[i]]
        tags$div(
          class = paste("aq-build-week-step", paste0("aq-build-week-step-", stage$status)),
          tags$span(class = "aq-build-week-step-index", i),
          tags$strong(stage$label),
          tags$small(stage$detail)
        )
      })
    )
  )
}

ui_build_week_empty <- function(title, detail) {
  tags$div(
    class = "aq-build-week-empty",
    tags$strong(title),
    tags$p(detail)
  )
}

ui_inquiry_record <- function(session_state) {
  inquiry <- session_state$inquiry %||% NULL
  if (is.null(inquiry)) {
    return(tagList(
      ui_build_week_progress(NULL),
      ui_build_week_empty("No investigation started.", "Run preflight, then launch the governed investigation to create the inquiry timeline.")
    ))
  }
  events <- build_week_visible_events(session_state)
  explanations <- inquiry$explanations %||% list()
  candidates <- inquiry$candidate_investigations %||% list()
  revisions <- inquiry$belief_revisions %||% list()
  recommendations <- inquiry$recommendation_revisions %||% list()
  tagList(
    ui_build_week_progress(session_state),
    tags$div(
      class = "aq-inquiry-strip",
      lapply(events, function(event) {
        is_active <- identical(event$event_id %||% "", tail(events, 1L)[[1L]]$event_id %||% "")
        tags$div(
          class = paste("aq-inquiry-event", if (isTRUE(is_active) && isTRUE(session_state$presentation_state$replay)) "aq-inquiry-event-active" else ""),
          tags$span(class = "aq-inquiry-stage", ui_display_label(event$stage %||% "")),
          tags$strong(event$title %||% ""),
          tags$p(event$statement %||% ""),
          tags$small(paste("Evidence:", length(event$evidence_ids %||% character())))
        )
      })
    ),
    tags$div(
      class = "aq-inquiry-grid",
      tags$div(
        class = "aq-inquiry-panel",
        tags$h4("Competing Explanations"),
        if (!length(explanations)) {
          ui_build_week_empty("No competing explanations yet.", "The demo has not reached the explanation step.")
        } else {
          lapply(explanations, function(item) {
            tags$div(
              class = paste("aq-inquiry-explanation aq-inquiry-status-", item$status %||% "proposed"),
              tags$strong(item$description %||% item$explanation_id %||% ""),
              tags$p(paste(ui_display_label(item$status %||% "proposed"), "-", ui_display_label(item$confidence %||% "not_assessed"))),
              tags$small(item$remaining_uncertainty %||% "")
            )
          })
        }
      ),
      tags$div(
        class = "aq-inquiry-panel",
        tags$h4("Selected Investigation"),
        if (!length(candidates)) {
          ui_build_week_empty("No investigation selected yet.", "Candidate paths appear here once the system ranks the next evidence step.")
        } else {
          lapply(candidates, function(item) {
            tags$div(
              class = paste("aq-inquiry-candidate", if (isTRUE(item$selected)) "aq-inquiry-selected" else ""),
              if (isTRUE(item$selected)) tags$span(class = "aq-inquiry-stage", "Selected"),
              tags$strong(item$investigation %||% item$investigation_id %||% ""),
              tags$p(item$question_answered %||% ""),
              tags$small(paste(
                "Decision impact", ui_display_label(item$expected_decision_impact %||% "moderate"),
                "| Learning", ui_display_label(item$expected_learning_value %||% "moderate"),
                "| Cost", ui_display_label(item$execution_cost %||% "moderate")
              ))
            )
          })
        }
      ),
      tags$div(
        class = "aq-inquiry-panel aq-inquiry-wide",
        tags$h4("Belief Revision"),
        if (!length(revisions)) {
          ui_build_week_empty("No belief revision yet.", "Evidence has not been interpreted into a changed belief.")
        } else {
          lapply(revisions, function(item) {
            tags$div(
              class = "aq-belief-revision",
              tags$span(class = "aq-inquiry-stage", item$revision_id %||% ""),
              tags$p(tags$strong("Initial: "), item$initial_belief %||% ""),
              tags$p(tags$strong("Evidence: "), item$evidence_discovered %||% ""),
              tags$p(tags$strong("Updated: "), item$updated_belief %||% ""),
              tags$p(tags$strong("Decision impact: "), item$decision_impact %||% "")
            )
          })
        },
        if (length(recommendations)) {
          tags$div(
            class = "aq-belief-revision aq-inquiry-recommendation",
            tags$h4("Recommendation Evolution"),
            tags$p(tail(recommendations, 1L)[[1L]]$current_recommendation %||% "")
          )
        } else {
          ui_build_week_empty("No recommendation update yet.", "The recommendation will update after evidence changes the decision context.")
        },
        tags$div(
          class = "aq-belief-revision",
          tags$h4("Remaining Uncertainty and Stopping Rule"),
          tags$p(tags$strong(ui_display_label(inquiry$stopping_rule$outcome %||% "scope_complete"))),
          tags$p(inquiry$stopping_rule$rationale %||% ""),
          tags$small(inquiry$stopping_rule$next_action %||% "")
        )
      )
    )
  )
}

ui_claim_path_node <- function(label, body, detail = NULL, status = "neutral") {
  tags$div(
    class = paste("aq-claim-path-node", paste0("aq-claim-path-node-", status)),
    tags$span(class = "aq-inquiry-stage", label),
    tags$p(body %||% "Not recorded."),
    if (!is.null(detail) && nzchar(detail)) tags$small(detail)
  )
}

ui_integrity_status <- function(value) {
  tags$span(class = "aq-integrity-status", ui_display_label(value %||% "not_assessed"))
}

ui_integrity_review <- function(review) {
  if (is.null(review)) {
    return(ui_build_week_empty("Integrity review not available.", "Complete the investigation before reviewing decision readiness."))
  }
  coverage <- review$evidence_coverage %||% list()
  alternatives <- review$alternative_explanations %||% list()
  tags$div(
    class = "aq-integrity-review",
    tags$div(
      class = "aq-integrity-review-header",
      tags$p(class = "aq-report-browser-eyebrow", "Investigation Integrity Review"),
      tags$h3("The workstation challenged its own recommendation."),
      tags$p(review$executive_summary %||% "No integrity summary recorded.")
    ),
    tags$div(
      class = "aq-integrity-summary-grid",
      tags$div(class = "aq-integrity-summary-tile", tags$span("Evidence strength"), tags$strong(review$strength_of_evidence$rating %||% "Not assessed"), tags$p(review$strength_of_evidence$rationale %||% "")),
      tags$div(class = "aq-integrity-summary-tile", tags$span("Sensitivity"), tags$strong(review$sensitivity$rating %||% "Not assessed"), tags$p(review$sensitivity$rationale %||% "")),
      tags$div(class = "aq-integrity-summary-tile", tags$span("Decision readiness"), tags$strong(review$decision_readiness$status %||% "Not assessed"), tags$p(review$decision_readiness$rationale %||% "")),
      tags$div(class = "aq-integrity-summary-tile", tags$span("Could more analysis change it?"), tags$strong(review$recommendation_robustness$would_additional_analysis_change_recommendation %||% "Unknown"), tags$p(review$recommendation_robustness$confidence %||% ""))
    ),
    tags$details(
      class = "aq-integrity-section",
      open = "open",
      tags$summary("Alternative explanations reviewed"),
      if (!length(alternatives)) {
        ui_build_week_empty("No alternative explanations recorded.", "The investigation did not preserve competing explanations.")
      } else {
        tags$div(
          class = "aq-integrity-alt-list",
          lapply(alternatives, function(item) {
            tags$div(
              class = "aq-integrity-alt",
              tags$div(
                tags$strong(item$explanation %||% "Unnamed explanation"),
                ui_integrity_status(item$status)
              ),
              tags$p(item$reason %||% ""),
              tags$small(paste("Supports:", paste(item$supporting_evidence %||% "none", collapse = ", "))),
              tags$small(paste("Weakens:", paste(item$weakening_evidence %||% "none", collapse = ", ")))
            )
          })
        )
      }
    ),
    tags$details(
      class = "aq-integrity-section",
      open = "open",
      tags$summary("Contradictory evidence and gaps"),
      tags$div(
        class = "aq-integrity-two-col",
        tags$div(tags$h4("Contradictory evidence"), report_browser_list(review$contradictory_evidence %||% character(), empty = "No contradictory evidence recorded.")),
        tags$div(tags$h4("Evidence gaps"), report_browser_list(vapply(coverage, function(item) paste(ui_display_label(item$status %||% "not_investigated"), "-", item$question %||% ""), character(1)), empty = "No coverage gaps recorded."))
      )
    ),
    tags$details(
      class = "aq-integrity-section",
      tags$summary("Assumptions and robustness"),
      tags$div(
        class = "aq-integrity-two-col",
        tags$div(tags$h4("Assumptions"), report_browser_list(review$assumptions %||% character(), empty = "No assumptions recorded.")),
        tags$div(
          tags$h4("Recommendation robustness"),
          tags$p(review$recommendation_robustness$current_recommendation %||% "No recommendation recorded."),
          tags$p(tags$strong("Remaining uncertainty:")),
          report_browser_list(review$recommendation_robustness$remaining_uncertainty %||% character(), empty = "No remaining uncertainty recorded.")
        )
      )
    )
  )
}

ui_campaign_claim_trace <- function(value) {
  evidence <- value$linked_evidence %||% list()
  revisions <- value$belief_revisions %||% list()
  tags$div(
    class = "aq-demo-claim-trace",
    tags$div(
      class = "aq-claim-dossier-header",
      tags$p(class = "aq-report-browser-eyebrow", "Why should I believe this?"),
      tags$h3(value$claim %||% "No claim selected."),
      tags$p("A traceable answer should show the original belief, the evidence that changed it, the recommendation that survived, and the limitations that remain.")
    ),
    tags$div(
      class = "aq-claim-path",
      ui_claim_path_node("Initial Belief", value$initial_belief %||% "No initial belief recorded.", status = "warning"),
      ui_claim_path_node(
        "Evidence Discovered",
        paste(value$evidence_discovered %||% "No evidence discovery recorded.", collapse = " "),
        paste("Evidence references:", paste(value$evidence_ids %||% character(), collapse = ", ")),
        status = "info"
      ),
      ui_claim_path_node(
        "Belief Updates",
        if (length(revisions)) paste(vapply(revisions, function(item) item$updated_belief %||% "", character(1)), collapse = " ") else "No belief revisions recorded.",
        status = if (length(revisions)) "success" else "warning"
      ),
      ui_claim_path_node("Final Recommendation", value$final_conclusion %||% value$final_recommendation %||% "Review linked evidence.", status = "success")
    ),
    tags$div(
      class = "aq-claim-detail-grid",
      tags$div(
        class = "aq-claim-detail-card",
        tags$h4("Diagnostics"),
        report_browser_list(value$diagnostics %||% value$diagnostic %||% character(), empty = "No diagnostics recorded.")
      ),
      tags$div(
        class = "aq-claim-detail-card",
        tags$h4("Methodology"),
        tags$p(value$method %||% "No methodology recorded.")
      ),
      tags$div(
        class = "aq-claim-detail-card",
        tags$h4("Limitations"),
        report_browser_list(value$limitations %||% character(), empty = "No limitations recorded.")
      ),
      tags$div(
        class = "aq-claim-detail-card aq-claim-detail-card-wide",
        ui_integrity_review(value$integrity_review)
      ),
      tags$div(
        class = "aq-claim-detail-card",
        tags$h4("Remaining Uncertainty"),
        report_browser_list(value$remaining_uncertainty %||% character(), empty = "No remaining uncertainty recorded.")
      ),
      tags$div(
        class = "aq-claim-detail-card aq-claim-detail-card-wide",
        tags$h4("Evidence Path"),
        tags$ol(
          tags$li("The main finding was selected from the validated campaign report."),
          tags$li(paste("Linked artifacts:", paste(vapply(evidence, function(item) item$title %||% item$evidence_id %||% "", character(1)), collapse = ", "))),
          tags$li("Diagnostics, methods, and limitations remain visible instead of being hidden in chat.")
        )
      )
    ),
    tags$div(
      class = "aq-claim-next-action",
      tags$strong("Next action"),
      tags$p(value$stopping_rule$next_action %||% value$final_recommendation %||% "Review linked evidence.")
    )
  )
}

page_build_week_demo_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Build Week Demo",
    value = "build_week_demo",
    ui_page(
      title = "Build Week Demo",
      subtitle = "Watch one governed investigation move from uncertainty to evidence-backed recommendation.",
      eyebrow = "Demo",
      actions = ui_action_row(
        actionButton(ns("run_preflight"), "Run Preflight", class = "btn-secondary"),
        actionButton(ns("launch_demo"), "Launch Demo", class = "btn-primary"),
        actionButton(ns("replay_demo"), "Replay", class = "btn-secondary"),
        actionButton(ns("step_replay"), "Step Replay", class = "btn-secondary"),
        actionButton(ns("reset_demo"), "Reset", class = "btn-secondary")
      ),
      tags$div(
        class = "aq-build-week-demo",
        ui_object_spine(
          object = "Governed Investigation",
          intent = "Show the workstation investigating a mystery dataset through bounded evidence.",
          state = "Preflight verifies readiness before the investigation begins.",
          next_action = "Launch the demo, approve SHAP, watch beliefs change, then ask why the final claim should be trusted.",
          depth = "The path is replayable and governed; it is not an unconstrained chat demo."
        ),
        ui_card(
          title = "Demo Control",
          subtitle = "One objective, one investigation path, replayable state.",
          tags$div(
            class = "aq-form-grid aq-form-grid-2",
            textAreaInput(
              ns("objective"),
              "User Objective",
              value = build_week_demo_default_objective(),
              width = "100%",
              height = "96px"
            ),
            tags$div(
              selectInput(ns("provider"), "Provider", choices = c("OpenAI GPT-5.6" = "openai", "Mock rehearsal" = "mock", "Ollama/local" = "ollama"), selected = "openai"),
              textInput(ns("model"), "Model", value = "gpt-5.6"),
              passwordInput(ns("api_key"), "OpenAI API Key", value = Sys.getenv("OPENAI_API_KEY", unset = "")),
              selectInput(ns("preset"), "Presentation Speed", choices = names(agent_operation_presets()), selected = "Presentation"),
              checkboxInput(ns("approve_shap"), "Approve governed SHAP step", value = TRUE)
            )
          )
        ),
        ui_card(
          title = "Preflight",
          subtitle = "Every requirement is checked or explained before the judged path begins.",
          uiOutput(ns("preflight_table"))
        ),
        ui_card(
          title = "Inquiry Record",
          subtitle = "Observation -> uncertainty -> explanations -> investigation -> evidence -> belief revision.",
          uiOutput(ns("inquiry_record"))
        ),
        tags$div(
          class = "aq-workspace-grid aq-workspace-grid-2",
          ui_card(
            title = "Campaign State",
            subtitle = "Current progress through the governed investigation.",
            uiOutput(ns("campaign_state"))
          ),
          ui_card(
            title = "Claim Verification",
            subtitle = "The demo ending: claim -> evidence -> diagnostics -> methodology -> limitations.",
            tagList(
              actionButton(ns("verify_claim"), "Why should I believe this?", class = "btn-primary"),
              uiOutput(ns("claim_trace"))
            )
          )
        )
      )
    )
  )
}

page_build_week_demo_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    preflight_result <- reactiveVal(NULL)
    claim_result <- reactiveVal(NULL)

    current_config <- reactive({
      provider <- input$provider %||% "openai"
      model <- input$model %||% if (identical(provider, "openai")) "gpt-5.6" else ""
      build_week_demo_config(provider = provider, model = model, api_key = input$api_key %||% "")
    })

    observeEvent(input$provider, {
      if (identical(input$provider, "openai") && !identical(input$model, "gpt-5.6")) {
        updateTextInput(session, "model", value = "gpt-5.6")
      }
      if (identical(input$provider, "mock")) {
        updateTextInput(session, "model", value = "mock-model")
      }
      if (identical(input$provider, "ollama") && identical(input$model, "mock-model")) {
        updateTextInput(session, "model", value = "llama3.1")
      }
    })

    observeEvent(input$run_preflight, {
      result <- build_week_demo_preflight(config = current_config(), check_provider = TRUE, run_runtime_qa = FALSE)
      preflight_result(result)
      ctx$build_week_demo_state$preflight <- result
      ctx$build_week_demo_state$message <- service_result_message(result)
      ctx$genai_config(current_config())
    })

    observeEvent(input$launch_demo, {
      config <- current_config()
      ctx$genai_config(config)
      result <- build_week_demo_launch(
        objective = input$objective %||% build_week_demo_default_objective(),
        provider_config = config,
        preset = input$preset %||% "Presentation",
        approve_shap = isTRUE(input$approve_shap)
      )
      if (identical(result$status, "success")) {
        ctx$agent_session_state(result$value)
        ctx$agent_report_contract(result$value$report_contract)
        claim_result(NULL)
      }
      ctx$build_week_demo_state$message <- service_result_message(result)
    })

    observeEvent(input$replay_demo, {
      session_state <- ctx$agent_session_state()
      if (!is.null(session_state)) {
        replay <- agent_session_replay(session_state, presentation_settings = agent_operation_settings(input$preset %||% "Presentation"))
        ctx$agent_session_state(replay)
        ctx$build_week_demo_state$message <- "Replay mode is active. The recorded campaign state is being inspected without rerunning analysis."
      }
    })

    observeEvent(input$step_replay, {
      session_state <- ctx$agent_session_state()
      if (!is.null(session_state)) {
        if (!isTRUE(session_state$presentation_state$replay)) {
          session_state <- agent_session_replay(session_state, presentation_settings = agent_operation_settings(input$preset %||% "Presentation"))
        } else {
          session_state <- agent_session_step(session_state)
        }
        ctx$agent_session_state(session_state)
        ctx$build_week_demo_state$message <- paste("Replay step", session_state$presentation_state$step_index %||% 1L, "is active.")
      }
    })

    observeEvent(input$reset_demo, {
      result <- build_week_demo_reset(ctx)
      preflight_result(NULL)
      claim_result(NULL)
      ctx$build_week_demo_state$message <- service_result_message(result)
    })

    observeEvent(input$verify_claim, {
      session_state <- ctx$agent_session_state()
      if (is.null(session_state)) {
        claim_result(service_result(status = "needs_input", warnings = "Launch the demo before verifying a claim."))
      } else {
        claim_result(agent_campaign_claim_trace(session_state))
      }
    })

    output$preflight_table <- renderUI({
      result <- preflight_result() %||% ctx$build_week_demo_state$preflight
      if (is.null(result)) {
        return(ui_build_week_empty("Preflight has not run yet.", "Run preflight before launching the judged path."))
      }
      checks <- result$value %||% data.table::data.table()
      rows <- lapply(seq_len(nrow(checks)), function(i) {
        status <- checks$status[[i]]
        tags$div(
          class = paste("aq-demo-check aq-demo-check-", status),
          tags$div(tags$strong(checks$check[[i]]), ui_status_badge(ui_display_label(status), status = if (status %in% c("success", "error", "warning")) status else "warning")),
          tags$p(checks$message[[i]]),
          if (nzchar(checks$action[[i]] %||% "")) tags$small(checks$action[[i]])
        )
      })
      tags$div(class = "aq-demo-preflight-grid", rows)
    })

    output$campaign_state <- renderUI({
      session_state <- ctx$agent_session_state()
      message <- ctx$build_week_demo_state$message %||% "No Build Week campaign has run yet."
      if (is.null(session_state)) {
        return(ui_build_week_empty("No investigation state yet.", message))
      }
      actions <- session_state$actions %||% list()
      completed <- sum(vapply(actions, function(action) identical(action$status %||% "", "completed"), logical(1)))
      ui_stat_grid(
        ui_stat_tile("Status", ui_display_label(session_state$status)),
        ui_stat_tile("Actions", length(actions)),
        ui_stat_tile("Completed", completed),
        ui_stat_tile("Evidence", length(session_state$evidence_references %||% list())),
        ui_stat_tile("Report", session_state$report_id %||% "not built"),
        ui_stat_tile("Mode", if (isTRUE(session_state$presentation_state$replay)) "Replay" else "Live run")
      )
    })

    output$inquiry_record <- renderUI({
      session_state <- ctx$agent_session_state()
      if (is.null(session_state)) {
        return(ui_inquiry_record(list(inquiry = NULL, presentation_state = list())))
      }
      ui_inquiry_record(session_state)
    })

    output$claim_trace <- renderUI({
      result <- claim_result()
      if (is.null(result)) {
        return(ui_build_week_empty("No claim selected yet.", "Launch the campaign, then ask why the main finding should be believed."))
      }
      if (!identical(result$status, "success")) {
        return(ui_build_week_empty("Claim trace is not available.", service_result_message(result)))
      }
      value <- result$value
      tags$div(
        ui_campaign_claim_trace(value),
        ui_shell_route("Open Report Browser", "Report Browser", class = "btn-primary")
      )
    })
  })
}
