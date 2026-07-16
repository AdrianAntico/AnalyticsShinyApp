decision_management_state <- function(project_id = NA_character_) {
  list(
    schema_version = "decision_management_context_state_v1",
    project_id = project_id,
    workflow_stage = "decision_review",
    selected_alternative_id = NA_character_,
    selected_action_id = "revise_recommendation",
    draft_id = NA_character_,
    updated_at = Sys.time()
  )
}

decision_management_active_context <- function(semantic_state) {
  semantic_state <- semantic_decision_normalize(semantic_state)
  context_id <- semantic_decision_active_context_id(semantic_state)
  contexts <- semantic_decision_rows(semantic_state, "contexts", context_id)
  if (!nrow(contexts)) {
    return(data.table::data.table(
      decision_context_id = NA_character_,
      title = "No decision authored yet",
      decision_question = "What should we do?",
      status = "missing",
      authority_id = NA_character_,
      coverage_id = NA_character_
    ))
  }
  contexts[1]
}

decision_management_summary <- function(
  semantic_state = semantic_decision_empty(),
  valuation_state = decision_valuation_empty(),
  workflow_state = decision_workflow_empty(),
  evidence_state = evidence_review_context_state()
) {
  first_value <- function(dt, column, default = NA_character_) {
    if (!is.data.frame(dt) || !nrow(dt) || !(column %in% names(dt))) return(default)
    dt[[column]][[1]] %||% default
  }
  semantic_state <- semantic_decision_normalize(semantic_state)
  context <- decision_management_active_context(semantic_state)
  context_id <- context$decision_context_id[[1]] %||% NA_character_
  alternatives <- semantic_decision_rows(semantic_state, "alternatives", context_id)
  recommendations <- semantic_decision_rows(semantic_state, "recommendations", context_id)
  decisions <- semantic_decision_rows(semantic_state, "decisions", context_id)
  evidence_refs <- semantic_decision_rows(semantic_state, "evidence_refs", context_id)
  uncertainties <- semantic_decision_rows(semantic_state, "uncertainties", context_id)
  optionality <- semantic_decision_rows(semantic_state, "optionality", context_id)
  financial <- semantic_decision_rows(semantic_state, "financial_impacts", context_id)
  valuation <- decision_valuation_summary(valuation_state)
  workflow <- decision_workflow_summary(workflow_state)
  preferred_id <- first_value(recommendations, "preferred_alternative_id", first_value(decisions, "selected_alternative_id", NA_character_))
  preferred <- if (nrow(alternatives) && nzchar(preferred_id %||% "")) {
    alternatives[alternative_id == preferred_id]
  } else if (nrow(alternatives) && "baseline" %in% names(alternatives)) {
    alternatives[!vapply(baseline, semantic_decision_bool, logical(1))][1]
  } else {
    alternatives[1]
  }
  if (!nrow(preferred) && nrow(alternatives)) preferred <- alternatives[1]
  stage <- if (nrow(decisions)) {
    first_value(decisions, "decision", "decision_recorded")
  } else if (nrow(recommendations)) {
    "draft_recommendation"
  } else if (nrow(alternatives)) {
    "alternatives_available"
  } else {
    "no_recommendation"
  }
  list(
    context = context,
    context_id = context_id,
    alternatives = alternatives,
    recommendations = recommendations,
    decisions = decisions,
    evidence_refs = evidence_refs,
    uncertainties = uncertainties,
    optionality = optionality,
    financial = financial,
    valuation_summary = valuation,
    workflow_summary = workflow,
    preferred = preferred,
    preferred_id = first_value(preferred, "alternative_id", preferred_id),
    stage = stage,
    evidence_stage = evidence_state$workflow_stage %||% "evidence_review"
  )
}

decision_management_story <- function(summary, room_stage = NULL) {
  first_value <- function(dt, column, default = NA_character_) {
    if (!is.data.frame(dt) || !nrow(dt) || !(column %in% names(dt))) return(default)
    dt[[column]][[1]] %||% default
  }
  stage <- room_stage %||% summary$stage %||% "no_recommendation"
  has_context <- !is.na(summary$context_id) && nzchar(summary$context_id)
  alternative_count <- nrow(summary$alternatives)
  valuation_status <- first_value(summary$valuation_summary, "valuation_status", "not_run")
  workflow_status <- first_value(summary$workflow_summary, "workflow_status", "not_run")
  preferred_name <- first_value(summary$preferred, "name", first_value(summary$preferred, "alternative_id", "No preferred alternative yet"))
  if (!has_context) {
    return(list(
      state_id = "no_recommendation",
      label = "No Recommendation",
      confidence = "Unknown",
      status = "neutral",
      headline = "No decision has been authored yet.",
      body = "The room cannot answer what to do until a business question and alternatives exist.",
      why = "Decision Management begins after a question has at least one possible action.",
      tradeoff = "No benefits, costs, risks, or opportunity costs are available yet.",
      next_step = "Open Semantic Intelligence to author the decision context.",
      what = "There is no decision object to manage.",
      how = "Author a decision context and at least two alternatives.",
      technical = "The room reads semantic_decision_state and does not fabricate decision records."
    ))
  }
  if (identical(stage, "recommendation_preview")) {
    return(list(
      state_id = "draft_recommendation",
      label = "Draft Recommendation",
      confidence = "Guarded",
      status = "warning",
      headline = paste("The current recommendation is to", preferred_name, "."),
      body = "The recommendation is visible for inspection before review, approval, or implementation.",
      why = if (identical(valuation_status, "current")) "Valuation is available, but governance still controls commitment." else "The room can stage the recommendation, but economic valuation is not current.",
      tradeoff = "Benefits, costs, risks, unknowns, and opportunity cost should be reviewed before submission.",
      next_step = "Submit for review or revise the recommendation.",
      what = "A recommendation draft is visible but not yet governed.",
      how = "Review alternatives and tradeoffs before moving it forward.",
      technical = "Preview is local room state; durable decisions remain owned by Semantic Intelligence and Decision Workflow."
    ))
  }
  if (identical(stage, "under_review")) {
    return(list(
      state_id = "under_review",
      label = "Under Review",
      confidence = "Review Required",
      status = "warning",
      headline = "The recommendation is ready for governed review.",
      body = "The next question is no longer what the evidence says. It is whether the authority, risks, and tradeoffs justify action.",
      why = "Review protects the decision from moving faster than evidence, authority, or coverage allow.",
      tradeoff = "Approval should consider value, downside risk, reversibility, and missing evidence.",
      next_step = "Approve only if the blockers are acceptable.",
      what = "The decision is in governance, not analysis.",
      how = "Use review status and blockers to decide whether to approve, revise, or request evidence.",
      technical = "Review status is represented as room state until the full workflow workbench records a durable review."
    ))
  }
  if (identical(stage, "approved")) {
    return(list(
      state_id = "approved",
      label = "Approved",
      confidence = "Authorized",
      status = "success",
      headline = "The decision is approved for implementation.",
      body = "Approval means the recommendation has passed the current governance threshold, not that the outcome is guaranteed.",
      why = "Authority has accepted the current tradeoff under the visible uncertainty.",
      tradeoff = "Implementation should preserve the assumptions, limits, and monitoring plan.",
      next_step = "Implement and prepare outcome review.",
      what = "The decision has permission to become action.",
      how = "Move from approval to implementation while preserving lineage.",
      technical = "Approval remains bounded by the current decision context and can be superseded by later evidence."
    ))
  }
  if (identical(stage, "implemented") || identical(stage, "completed")) {
    return(list(
      state_id = "implemented",
      label = if (identical(stage, "completed")) "Completed" else "Implemented",
      confidence = "Outcome Pending",
      status = "success",
      headline = "The recommendation has moved into action.",
      body = "The decision is no longer only a recommendation. The next learning comes from monitoring and realized outcomes.",
      why = "Implemented decisions become future evidence for whether the strategy worked.",
      tradeoff = "Outcome review should compare expected value, realized value, assumptions, and side effects.",
      next_step = "Review the outcome when evidence arrives.",
      what = "The room has crossed from decision into learning.",
      how = "Capture realized outcomes and promote or revise the decision memory.",
      technical = "Outcome memory is intentionally separate from recommendation approval."
    ))
  }
  if (alternative_count > 0L && !nrow(summary$recommendations)) {
    return(list(
      state_id = "no_recommendation",
      label = "No Recommendation",
      confidence = "Preliminary",
      status = "warning",
      headline = "Alternatives exist, but no recommendation has been authored.",
      body = "The room can compare possible actions, but it should not pretend one is preferred until a recommendation exists.",
      why = paste(alternative_count, "alternative(s) are available for comparison."),
      tradeoff = "Tradeoffs are still exploratory until criteria, economics, and evidence are connected.",
      next_step = "Revise or author a recommendation.",
      what = "The room has options, not a chosen position.",
      how = "Identify the preferred alternative or request more evidence.",
      technical = "Alternatives are read from semantic_decision_state; recommendation is a distinct authored record."
    ))
  }
  list(
    state_id = "draft_recommendation",
    label = "Draft Recommendation",
    confidence = if (identical(valuation_status, "current") && identical(workflow_status, "current")) "Supported" else "Guarded",
    status = if (identical(valuation_status, "current")) "success" else "warning",
    headline = paste("The current recommendation is to", preferred_name, "."),
    body = "The room is now answering what to do, using alternatives, tradeoffs, valuation, and governance status.",
      why = first_value(summary$recommendations, "evidence_basis", "A preferred alternative exists in the decision package."),
    tradeoff = if (identical(valuation_status, "current")) "Economic valuation is available for review." else "Economic valuation is not current; keep the recommendation guarded.",
    next_step = if (identical(workflow_status, "current")) "Use workflow status to move through review or approval." else "Submit the recommendation for review.",
    what = "The room has a current position.",
    how = "Inspect tradeoffs, then decide whether to review, approve, revise, or implement.",
    technical = "The Current Decision composes semantic alternatives, valuation summary, and workflow summary without duplicating those systems."
  )
}

decision_management_alternative_cards <- function(summary) {
  alternatives <- summary$alternatives
  if (!nrow(alternatives)) {
    return(tags$div(
      class = "aq-narrative-empty aq-decision-empty-alternatives",
      tags$p(class = "aq-section-eyebrow", "No Alternatives Yet"),
      tags$h4("A decision needs real options."),
      tags$p("Alternatives make the decision explicit: continue, defer, collect evidence, pilot, expand, abandon, or choose another governed action.")
    ))
  }
  preferred_id <- summary$preferred_id %||% NA_character_
  tags$div(
    class = "aq-decision-alternative-list",
    lapply(seq_len(nrow(alternatives)), function(i) {
      alt <- alternatives[i]
      baseline <- if ("baseline" %in% names(alt)) semantic_decision_bool(alt$baseline[[1]] %||% FALSE) else FALSE
      authority_compatible <- if ("authority_compatible" %in% names(alt)) semantic_decision_bool(alt$authority_compatible[[1]] %||% TRUE) else TRUE
      state <- if (identical(alt$alternative_id[[1]], preferred_id)) "preferred" else if (isTRUE(baseline)) "baseline" else "available"
      tags$article(
        class = paste("aq-decision-alternative", paste0("aq-decision-alternative-", state)),
        tags$span(class = "aq-section-eyebrow", ui_display_label(state)),
        tags$strong(alt$name[[1]] %||% alt$alternative_id[[1]]),
        tags$p(alt$alternative_type[[1]] %||% "Alternative"),
        tags$small(paste("Authority:", if (isTRUE(authority_compatible)) "compatible" else "needs review"))
      )
    })
  )
}

decision_management_tradeoff_summary <- function(summary) {
  financial <- summary$financial
  uncertainties <- summary$uncertainties
  optionality <- summary$optionality
  numeric_col <- function(dt, column) {
    if (!is.data.frame(dt) || !nrow(dt) || !(column %in% names(dt))) return(0)
    suppressWarnings(as.numeric(dt[[column]]))
  }
  text_col <- function(dt, column, default = "unspecified") {
    if (!is.data.frame(dt) || !nrow(dt) || !(column %in% names(dt))) return(default)
    dt[[column]] %||% default
  }
  data.table::data.table(
    dimension = c("Benefits", "Costs", "Risks", "Unknowns", "Opportunity Cost", "Optionality"),
    current_read = c(
      if (nrow(financial) && "expected_benefit" %in% names(financial)) paste(sum(numeric_col(financial, "expected_benefit"), na.rm = TRUE), "total expected benefit across authored impacts") else "No benefit evidence authored.",
      if (nrow(financial) && any(c("initial_cost", "recurring_cost") %in% names(financial))) paste(sum(c(numeric_col(financial, "initial_cost"), numeric_col(financial, "recurring_cost")), na.rm = TRUE), "total authored cost signal") else "No cost evidence authored.",
      if (nrow(uncertainties)) paste(nrow(uncertainties), "uncertainty record(s) require attention.") else "No explicit uncertainty record.",
      if (nrow(uncertainties)) paste(unique(text_col(uncertainties, "uncertainty_category")), collapse = ", ") else "Unknowns are not yet structured.",
      if (nrow(financial) && "opportunity_cost" %in% names(financial)) paste(sum(numeric_col(financial, "opportunity_cost"), na.rm = TRUE), "authored opportunity-cost signal") else "Opportunity cost is not explicit.",
      if (nrow(optionality)) paste(nrow(optionality), "optionality claim(s) may preserve future choices.") else "No optionality claim authored."
    )
  )
}

decision_management_actions <- function(story) {
  data.table::data.table(
    action_id = c("request_evidence", "revise_recommendation", "preview_recommendation", "submit_review", "approve", "implement", "review_outcome"),
    action = c("Request evidence", "Revise recommendation", "Preview recommendation", "Submit for review", "Approve", "Implement", "Review outcome"),
    reason = c(
      "Use when uncertainty or evidence gaps block confidence.",
      "Use when alternatives or tradeoffs change the position.",
      "Use before governance so the recommendation is visible.",
      "Use when the recommendation is ready for authority review.",
      "Use only when governance status supports action.",
      "Use after approval to move from decision into action.",
      "Use after implementation to learn whether the decision held."
    ),
    stage = c("any", "no_recommendation", "draft", "draft", "under_review", "approved", "implemented")
  )
}

page_decision_management_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Decision Management",
    value = "decision_management",
    ui_page(
      title = "Decision Management",
      subtitle = "Move from evidence-backed understanding to a governed decision.",
      eyebrow = "Decision Room",
      actions = ui_action_row(
        actionButton(ns("open_evidence_review"), "Review Evidence", class = "btn-secondary"),
        actionButton(ns("open_semantic"), "Edit Decision", class = "btn-secondary"),
        actionButton(ns("open_mission"), "Project Health", class = "btn-secondary")
      ),
      tags$section(
        class = "aq-evidence-room aq-decision-room",
        `data-testid` = "decision-management-production-candidate",
        uiOutput(ns("decision_header")),
        tags$div(
          class = "aq-evidence-action-dock aq-decision-action-dock",
          tags$div(class = "aq-evidence-action-summary", uiOutput(ns("next_decision_action")), uiOutput(ns("decision_readiness"))),
          uiOutput(ns("decision_actions"))
        ),
        uiOutput(ns("decision_feedback")),
        uiOutput(ns("decision_continuation")),
        tags$div(
          class = "aq-evidence-studio aq-decision-studio",
          tags$aside(
            class = "aq-evidence-rail aq-decision-rail",
            ui_section_header("Alternatives", "The real options under consideration."),
            uiOutput(ns("alternative_summary")),
            uiOutput(ns("alternative_cards"))
          ),
          tags$main(
            class = "aq-evidence-canvas aq-decision-canvas",
            tags$div(
              class = "aq-evidence-canvas-header",
              tags$div(
                tags$p(class = "aq-section-eyebrow", "Current Decision"),
                tags$h3("Current Decision"),
                tags$p("What the evidence, alternatives, and governance currently justify.")
              ),
              ui_action_row(
                actionButton(ns("preview_recommendation"), "Preview Recommendation", class = "btn-primary"),
                actionButton(ns("submit_review"), "Request Review", class = "btn-secondary aq-evidence-secondary-action"),
                actionButton(ns("approve_decision"), "Approve", class = "btn-secondary aq-evidence-secondary-action")
              )
            ),
            tags$div(
              class = "aq-evidence-canvas-body",
              tags$section(class = "aq-evidence-understanding-brief aq-decision-current", uiOutput(ns("current_decision"))),
              uiOutput(ns("decision_teaching")),
              tags$section(
                class = "aq-evidence-panel aq-evidence-panel-primary",
                ui_section_header("Tradeoffs", "Benefits, costs, risks, unknowns, opportunity cost, and optionality."),
                uiOutput(ns("tradeoff_view"))
              ),
              tags$section(
                class = "aq-evidence-panel aq-evidence-split",
                tags$div(ui_section_header("Economics", "Decision value in context."), uiOutput(ns("economics_view"))),
                tags$div(ui_section_header("Governance", "Review, authority, blockers, and workflow stage."), uiOutput(ns("governance_view")))
              )
            )
          ),
          tags$aside(
            class = "aq-evidence-inspector aq-decision-inspector",
            ui_section_header("Decision Detail", "Open only when a recommendation needs provenance."),
            uiOutput(ns("decision_detail")),
            tags$div(class = "aq-evidence-guide", uiOutput(ns("decision_mentor")))
          )
        ),
        tags$section(
          class = "aq-evidence-depth aq-decision-depth",
          ui_disclosure("Decision Reasoning", tagList(uiOutput(ns("action_table")), uiOutput(ns("recommendation_history"))), open = TRUE, level = "common"),
          ui_disclosure("Evidence and Economics", tagList(uiOutput(ns("evidence_refs")), uiOutput(ns("valuation_raw"))), open = FALSE, level = "artifact"),
          ui_disclosure("How This Was Determined", tagList(uiOutput(ns("workflow_raw")), uiOutput(ns("cross_context_comparison"))), open = FALSE, level = "advanced")
        )
      )
    )
  )
}

page_decision_management_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    room_state <- reactiveVal(decision_management_state())
    decision_message <- reactiveVal("Start by reviewing the current decision, alternatives, and tradeoffs.")
    mentor_result <- reactiveVal(NULL)

    summary_reactive <- reactive({
      decision_management_summary(
        semantic_state = tryCatch(ctx$semantic_decision_state(), error = function(e) semantic_decision_empty()),
        valuation_state = tryCatch(ctx$decision_valuation_state(), error = function(e) decision_valuation_empty()),
        workflow_state = tryCatch(ctx$decision_workflow_state(), error = function(e) decision_workflow_empty()),
        evidence_state = tryCatch(ctx$evidence_review_context_state(), error = function(e) evidence_review_context_state())
      )
    })

    story_reactive <- reactive({
      decision_management_story(summary_reactive(), room_state()$workflow_stage)
    })

    set_stage <- function(stage, message) {
      state <- room_state()
      state$workflow_stage <- stage
      state$updated_at <- Sys.time()
      room_state(state)
      decision_message(message)
    }

    observeEvent(input$open_evidence_review, ctx$navigate_to("Evidence Review"), ignoreInit = TRUE)
    observeEvent(input$open_semantic, ctx$navigate_to("Semantic Intelligence"), ignoreInit = TRUE)
    observeEvent(input$open_mission, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)

    observeEvent(input$preview_recommendation, {
      set_stage("recommendation_preview", "Recommendation preview created. The decision position is visible before review or approval.")
    }, ignoreInit = TRUE)
    observeEvent(input$submit_review, {
      set_stage("under_review", "Recommendation submitted for review. Governance is now protecting authority, risk, and tradeoff quality.")
    }, ignoreInit = TRUE)
    observeEvent(input$approve_decision, {
      set_stage("approved", "Decision approved in this room. Implementation should preserve assumptions and monitoring needs.")
    }, ignoreInit = TRUE)
    observeEvent(input$implement_decision, {
      set_stage("implemented", "Decision marked implemented in this room. Future value now depends on outcome review.")
    }, ignoreInit = TRUE)
    observeEvent(input$request_evidence, {
      decision_message("Evidence request noted. The room is keeping the recommendation bounded until uncertainty is reduced.")
    }, ignoreInit = TRUE)
    observeEvent(input$explain_decision, {
      story <- story_reactive()
      prompt <- paste(
        "Explain this decision recommendation in concise language.",
        "Do not invent evidence. Explain tradeoffs, uncertainty, governance, and next action.",
        paste(c(story$headline, story$body, story$why, story$tradeoff, story$next_step), collapse = "\n"),
        sep = "\n\n"
      )
      result <- genai_chat_with_telemetry(
        list(list(role = "user", content = prompt)),
        config = ctx$genai_config(),
        context_strategy = "structured_json_summary",
        included_components = c("metadata", "diagnostics", "recommendations")
      )
      mentor_result(result)
      decision_message("Mentor explanation returned. Use it to clarify the decision, not to replace governance.")
    }, ignoreInit = TRUE)

    output$decision_header <- renderUI({
      summary <- summary_reactive()
      story <- story_reactive()
      context <- summary$context
      tags$header(
        class = "aq-evidence-room-header aq-decision-room-header",
        tags$div(
          class = "aq-evidence-room-kicker",
          tags$span("Decision under management"),
          ui_status_badge(story$label, status = story$status)
        ),
        tags$div(
          class = "aq-evidence-room-title-row",
          tags$div(
            tags$p(class = "aq-section-eyebrow", "Decision Frame"),
            tags$h2(context$decision_question[[1]] %||% "What should we do?"),
            tags$p(class = "aq-evidence-room-subtitle", context$title[[1]] %||% context$decision_context_id[[1]] %||% "No decision context")
          ),
          tags$div(
            class = "aq-evidence-room-next",
            tags$span("Current recommendation"),
            tags$strong(story$label),
            tags$small(story$next_step)
          )
        ),
        tags$div(
          class = "aq-evidence-room-facts",
          tags$div(class = paste("aq-evidence-room-fact", paste0("aq-evidence-room-fact-", story$status)), tags$span("Decision"), tags$strong(story$label), tags$small(story$confidence)),
          tags$div(class = "aq-evidence-room-fact", tags$span("Alternatives"), tags$strong(nrow(summary$alternatives))),
          tags$div(class = "aq-evidence-room-fact", tags$span("Governance"), tags$strong(summary$workflow_summary$readiness_state[[1]] %||% "not assessed"), tags$small(summary$workflow_summary$workflow_status[[1]] %||% "not run"))
        )
      )
    })

    output$current_decision <- renderUI({
      summary <- summary_reactive()
      story <- story_reactive()
      tags$div(
        class = paste("aq-current-answer-story", paste0("aq-current-answer-story-", story$state_id)),
        tags$div(
          class = "aq-evidence-brief-copy",
          tags$div(class = "aq-current-answer-header", tags$p(class = "aq-section-eyebrow", "Current Decision"), ui_status_badge(story$label, status = story$status)),
          tags$h3(story$headline),
          tags$p(story$body),
          tags$div(class = "aq-current-answer-ribbon", tags$span("Confidence"), tags$strong(story$confidence), tags$span("Alternatives"), tags$strong(nrow(summary$alternatives)), tags$span("Evidence refs"), tags$strong(nrow(summary$evidence_refs)))
        ),
        tags$div(
          class = "aq-evidence-brief-grid",
          tags$div(class = "aq-evidence-brief-item", tags$span("Why this position"), tags$strong(story$why)),
          tags$div(class = "aq-evidence-brief-item", tags$span("Tradeoff"), tags$strong(story$tradeoff)),
          tags$div(class = "aq-evidence-brief-item", tags$span("What happens next"), tags$strong(story$next_step))
        )
      )
    })

    output$decision_teaching <- renderUI({
      story <- story_reactive()
      tags$section(
        class = paste("aq-evidence-teaching-strip aq-decision-teaching-strip", paste0("aq-decision-teaching-strip-", story$state_id)),
        tags$div(class = "aq-teaching-step", tags$span("What"), tags$strong(story$what)),
        tags$div(class = "aq-teaching-step", tags$span("Why it matters"), tags$strong(story$why)),
        tags$div(class = "aq-teaching-step", tags$span("How to move"), tags$strong(story$how)),
        ui_disclosure("Technical reason", tags$p(story$technical), open = FALSE, level = "advanced")
      )
    })

    output$next_decision_action <- renderUI({
      story <- story_reactive()
      tags$div(class = "aq-next-move-static", tags$span("Next useful move"), tags$strong(story$next_step), tags$small("Decision Management is using the current recommendation maturity."))
    })
    output$decision_readiness <- renderUI({
      story <- story_reactive()
      tags$div(class = "aq-evidence-primary-action-summary", tags$span("Decision readiness"), tags$strong(story$confidence), tags$small("Readiness reflects recommendation maturity, uncertainty, and governance."))
    })
    output$decision_actions <- renderUI({
      stage <- room_state()$workflow_stage
      if (identical(stage, "approved")) {
        return(ui_action_row(actionButton(session$ns("implement_decision"), "Implement", class = "btn-primary"), tags$span(class = "aq-evidence-action-hint", "Outcome review comes after implementation.")))
      }
      if (identical(stage, "under_review")) {
        return(ui_action_row(actionButton(session$ns("approve_decision"), "Approve", class = "btn-primary"), actionButton(session$ns("request_evidence"), "Request Evidence", class = "btn-secondary")))
      }
      ui_action_row(actionButton(session$ns("preview_recommendation"), "Preview Recommendation", class = "btn-primary"), tags$span(class = "aq-evidence-action-hint", "Submit review after preview."))
    })
    output$decision_feedback <- renderUI({
      stage <- room_state()$workflow_stage
      tags$div(class = paste("aq-evidence-feedback", paste0("aq-evidence-feedback-", stage)), tags$span(class = "aq-evidence-feedback-dot"), tags$strong(ui_display_label(stage)), tags$span(decision_message()))
    })
    output$decision_continuation <- renderUI({
      story <- story_reactive()
      continuation <- if (story$state_id %in% c("approved")) {
        list(
          label = "Continue the reasoning",
          next_step = "Move from approval to implementation.",
          why = "The decision has permission to become action; preserve assumptions and monitoring needs.",
          action = "Implement"
        )
      } else if (story$state_id %in% c("implemented")) {
        list(
          label = "Continue the reasoning",
          next_step = "Move from implementation to outcome learning.",
          why = "The next thought is whether the realized outcome confirms, revises, or supersedes the decision.",
          action = "Review Outcome"
        )
      } else if (story$state_id %in% c("under_review")) {
        list(
          label = "Continue the reasoning",
          next_step = "Resolve review before action.",
          why = "The recommendation is no longer only analytical; authority and risk now determine the next move.",
          action = "Approve or Request Evidence"
        )
      } else {
        list(
          label = "Continue the reasoning",
          next_step = "Make the recommendation inspectable.",
          why = "The current decision should become visible before review, approval, or implementation.",
          action = "Preview Recommendation"
        )
      }
      tags$section(
        class = "aq-semantic-continuation aq-decision-continuation",
        tags$div(
          tags$p(class = "aq-section-eyebrow", continuation$label),
          tags$strong(continuation$next_step),
          tags$span(continuation$why)
        ),
        tags$span(class = "aq-semantic-continuation-action", continuation$action)
      )
    })
    output$alternative_summary <- renderUI({
      summary <- summary_reactive()
      ui_stat_grid(
        ui_stat_tile("Alternatives", nrow(summary$alternatives), status = if (nrow(summary$alternatives)) "success" else "warning"),
        ui_stat_tile("Recommended", if (nrow(summary$recommendations)) 1 else 0, status = if (nrow(summary$recommendations)) "success" else "warning"),
        ui_stat_tile("Deferred", sum((summary$alternatives$alternative_type %||% character()) %in% c("defer", "collect_more_evidence")), status = "neutral")
      )
    })
    output$alternative_cards <- renderUI(decision_management_alternative_cards(summary_reactive()))
    output$tradeoff_view <- renderUI({
      summary <- summary_reactive()
      tradeoffs <- decision_management_tradeoff_summary(summary)
      tags$div(
        class = "aq-decision-tradeoff-list",
        lapply(seq_len(nrow(tradeoffs)), function(i) {
          row <- tradeoffs[i]
          tags$article(class = "aq-decision-tradeoff", tags$span(row$dimension), tags$strong(row$current_read))
        })
      )
    })
    output$economics_view <- renderUI(render_table(summary_reactive()$valuation_summary, engine = "html", searchable = FALSE, sortable = FALSE))
    output$governance_view <- renderUI(render_table(summary_reactive()$workflow_summary, engine = "html", searchable = FALSE, sortable = FALSE))
    output$decision_detail <- renderUI({
      story <- story_reactive()
      summary <- summary_reactive()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-callout aq-callout-info", tags$strong("Decision provenance"), tags$p("This room reads semantic decision, valuation, workflow, and evidence review state. It does not duplicate those records.")),
        render_table(data.table::data.table(
          field = c("Decision context", "Preferred alternative", "Evidence review stage", "Valuation", "Workflow"),
          value = c(summary$context_id, summary$preferred_id %||% "not selected", summary$evidence_stage, summary$valuation_summary$valuation_status[[1]] %||% "not run", summary$workflow_summary$workflow_status[[1]] %||% "not run")
        ), engine = "html", searchable = FALSE, sortable = FALSE),
        tags$div(class = "aq-callout aq-callout-info", tags$strong("Current teaching"), tags$p(story$technical))
      )
    })
    output$decision_mentor <- renderUI({
      result <- mentor_result()
      result_text <- NULL
      if (!is.null(result)) result_text <- if (identical(result$status, "success")) (result$value %||% list())$text %||% result$value %||% "AI response returned without text." else paste(c(result$errors, result$messages), collapse = " ")
      ui_disclosure(
        "Ask the mentor",
        tags$div(
          tags$div(class = "aq-evidence-mentor", tags$p(class = "aq-section-eyebrow", "Contextual Mentor"), tags$strong("Ask only when tradeoffs are unclear."), tags$p("Use this for recommendation, tradeoffs, uncertainty, optionality, or governance. The room should teach first; the mentor only clarifies.")),
          ui_action_row(actionButton(session$ns("explain_decision"), "Explain Decision", class = "btn-primary btn-sm")),
          if (!is.null(result_text)) tags$div(class = if (identical(result$status, "success")) "aq-callout aq-callout-success" else "aq-callout aq-callout-warning", tags$pre(result_text))
        ),
        open = !is.null(result_text),
        level = "advanced"
      )
    })
    output$action_table <- renderUI(render_table(decision_management_actions(story_reactive()), engine = "html", searchable = FALSE, sortable = FALSE))
    output$recommendation_history <- renderUI(render_table(summary_reactive()$recommendations, engine = "html", searchable = FALSE, sortable = FALSE))
    output$evidence_refs <- renderUI(render_table(summary_reactive()$evidence_refs, engine = "html", searchable = FALSE, sortable = FALSE))
    output$valuation_raw <- renderUI(render_table(summary_reactive()$financial, engine = "html", searchable = FALSE, sortable = FALSE))
    output$workflow_raw <- renderUI(render_table(summary_reactive()$workflow_summary, engine = "html", searchable = FALSE, sortable = FALSE))
    output$cross_context_comparison <- renderUI(render_table(working_context_cross_context_comparison(), engine = "html", searchable = FALSE, sortable = FALSE))
  })
}

qa_decision_management_room <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }
  page_path <- file.path("R", "page_decision_management.R")
  ui_path <- file.path("R", "app_ui.R")
  server_path <- file.path("R", "app_server.R")
  doc_path <- file.path("docs", "decision_management_production_candidate.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  ui <- if (file.exists(ui_path)) paste(readLines(ui_path, warn = FALSE), collapse = "\n") else ""
  server <- if (file.exists(server_path)) paste(readLines(server_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  summary <- decision_management_summary(semantic_decision_empty(), decision_valuation_empty(), decision_workflow_empty())
  story <- decision_management_story(summary)

  add("production_candidate_marker", grepl("decision-management-production-candidate", page, fixed = TRUE), "Decision Management has an explicit production-candidate marker.")
  add("app_registration", has_all(c("page_decision_management_ui", "page_decision_management_server"), paste(ui, server)), "Decision Management is mounted in the app shell and server.")
  add("focal_object", has_all(c("Current Decision", "current_decision", "What the evidence, alternatives, and governance currently justify."), page), "The room centers Current Decision as the focal object.")
  add("decision_studio", has_all(c("aq-decision-studio", "aq-decision-rail", "aq-decision-canvas", "aq-decision-inspector"), page), "Decision Studio has rail, canvas, and inspector zones.")
  add("alternatives_first_class", has_all(c("decision_management_alternative_cards", "preferred", "baseline", "available"), page), "Alternatives render as first-class decision objects.")
  add("tradeoffs_narrative_first", has_all(c("Benefits", "Costs", "Risks", "Unknowns", "Opportunity Cost", "Optionality"), page), "Tradeoffs are summarized narratively before raw tables.")
  add("governance_supportive", has_all(c("Review", "Authority", "Governance", "Approve", "Implement"), page), "Governance is visible as decision support.")
  add("stage_aware_actions", has_all(c("recommendation_preview", "under_review", "approved", "implemented"), page), "Decision actions evolve by stage.")
  add("contextual_mentor", has_all(c("Explain Decision", "The room should teach first; the mentor only clarifies."), page), "Mentor remains contextual and non-mechanical.")
  add("documentation", file.exists(doc_path) && has_all(c("Decision Room", "Cross-Context Validation", "Founder Review", "Campaigns"), doc), "Decision Management production-candidate documentation exists.")
  add("empty_summary_safe", identical(story$state_id, "no_recommendation") && grepl("No decision has been authored", story$headline, fixed = TRUE), "Empty decision state degrades gracefully.")

  do.call(rbind, checks)
}
