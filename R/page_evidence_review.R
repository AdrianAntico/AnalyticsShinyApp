page_evidence_review_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Evidence Review",
    value = "evidence_review",
    ui_page(
      title = "Evidence Review",
      subtitle = "Review what is known, what is missing, and which action the evidence can justify.",
      eyebrow = "Evidence Room",
      actions = ui_action_row(
        actionButton(ns("open_mission"), "Project Health", class = "btn-secondary"),
        actionButton(ns("open_artifacts"), "Artifact Studio", class = "btn-secondary"),
        actionButton(ns("open_decisions"), "Continue to Decision", class = "btn-secondary")
      ),
      tags$section(
        class = "aq-evidence-room",
        `data-testid` = "evidence-review-production-candidate",
        uiOutput(ns("context_header")),
        tags$div(
          class = "aq-evidence-action-dock",
          tags$div(
            class = "aq-evidence-action-summary",
            uiOutput(ns("action_selector")),
            uiOutput(ns("primary_action_summary"))
          ),
          uiOutput(ns("workflow_actions"))
        ),
        uiOutput(ns("room_feedback")),
        uiOutput(ns("semantic_continuation")),
        tags$div(
          class = "aq-evidence-studio",
          tags$aside(
            class = "aq-evidence-rail",
            ui_section_header("Evidence", "What the answer can cite."),
            uiOutput(ns("binder_summary")),
            uiOutput(ns("artifact_selector")),
            ui_action_row(
              actionButton(ns("inspect_artifact"), "Inspect", class = "btn-primary"),
              actionButton(ns("refresh_binder"), "Refresh", class = "btn-secondary aq-evidence-secondary-action")
            )
          ),
          tags$main(
            class = "aq-evidence-canvas",
            tags$div(
              class = "aq-evidence-canvas-header",
              tags$div(
                tags$p(class = "aq-section-eyebrow", "Current Answer"),
                tags$h3("Current Answer"),
                tags$p("The evolving story of what the evidence can safely support.")
              ),
              ui_action_row(
                actionButton(ns("compile_synthesis"), "Compile Answer", class = "btn-primary"),
                actionButton(ns("mark_contradiction_reviewed"), "Mark Reviewed", class = "btn-secondary aq-evidence-secondary-action"),
                actionButton(ns("request_more_evidence"), "Request Evidence", class = "btn-secondary aq-evidence-secondary-action")
              )
            ),
            tags$div(
              class = "aq-evidence-canvas-body",
              tags$section(
                class = "aq-evidence-understanding-brief",
                uiOutput(ns("understanding_brief"))
              ),
              uiOutput(ns("contextual_teaching")),
              tags$section(
                class = "aq-evidence-panel aq-evidence-panel-primary",
                ui_section_header("Supporting Evidence", "Claims the room can cite, gaps it must admit, and claims it refuses to make."),
                uiOutput(ns("synthesis_view"))
              ),
              tags$section(
                class = "aq-evidence-panel",
                ui_section_header("Contradictions", "Visible until reviewed, scoped, or resolved."),
                uiOutput(ns("contradiction_workspace"))
              ),
              tags$section(
                class = "aq-evidence-panel aq-evidence-split",
                tags$div(
                  ui_section_header("Evidence Sufficiency", "Specific to the proposed action."),
                  uiOutput(ns("sufficiency_view"))
                ),
                tags$div(
                  ui_section_header("Valuation", "Economic relevance in context."),
                  uiOutput(ns("valuation_view"))
                )
              )
            )
          ),
          tags$aside(
            class = "aq-evidence-inspector",
            ui_section_header("Detail", "Open only when a claim needs provenance."),
            uiOutput(ns("artifact_inspector")),
            tags$div(class = "aq-evidence-guide", uiOutput(ns("contextual_ai")))
          )
        ),
        tags$section(
          class = "aq-evidence-depth",
          ui_disclosure(
            "Recommendation Reasoning",
            tagList(
              uiOutput(ns("ranked_actions")),
              uiOutput(ns("draft_flow"))
            ),
            open = TRUE,
            level = "common"
          ),
          ui_disclosure(
            "Project Signals",
            uiOutput(ns("mission_summary")),
            open = FALSE,
            level = "artifact"
          ),
          ui_disclosure(
            "Technical Detail",
            tagList(
              uiOutput(ns("progressive_depth")),
              uiOutput(ns("context_state"))
            ),
            open = FALSE,
            level = "advanced"
          ),
          ui_disclosure(
            "Backstage and Return Paths",
            uiOutput(ns("related_tasks")),
            open = FALSE,
            level = "developer"
          )
        )
      )
    )
  )
}

page_evidence_review_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    selected_artifact_id <- reactiveVal(NULL)
    inspection_result <- reactiveVal(NULL)
    synthesis_result <- reactiveVal(NULL)
    contradiction_message <- reactiveVal(NULL)
    draft_state <- reactiveVal(NULL)
    persisted_state <- reactiveVal(NULL)
    contextual_ai_result <- reactiveVal(NULL)
    interaction_message <- reactiveVal("Start by compiling the current answer, then inspect gaps before drafting.")

    story_stage_label <- function(stage) {
      labels <- c(
        evidence_review = "Evidence Review",
        synthesis_review = "Current Answer Compiled",
        draft_preview = "Preparing Recommendation",
        persisted_result = "Recommendation Saved"
      )
      label <- unname(labels[stage %||% "evidence_review"])
      if (length(label) && !is.na(label) && nzchar(label)) label else ui_display_label(stage)
    }

    story_teaching <- function(state_id, included_count = 0L, contradiction_count = 0L) {
      switch(
        state_id,
        no_answer_yet = list(
          what = "The room has evidence intake, but no compiled answer yet.",
          why = if (included_count > 0L) "Artifacts are available, but they have not been converted into cited claims, gaps, and limits." else "Without artifacts, the room has nothing defensible to cite.",
          how = if (included_count > 0L) "Compile the answer to turn available artifacts into a bounded interpretation." else "Generate or add evidence before asking for a recommendation.",
          technical = "Compilation is deterministic: it organizes included, omitted, stale, contradictory, and prohibited evidence before any draft can be saved."
        ),
        insufficient_evidence = list(
          what = "The safest answer is still 'not enough evidence.'",
          why = "The room blocks recommendation language when support, valuation, or action-specific sufficiency is missing.",
          how = "Use the missing-evidence message as the next work order, not as a failure.",
          technical = "Sufficiency is action-specific. The same evidence may support inspection while still blocking a decision draft."
        ),
        conflicting_evidence = list(
          what = "The evidence is informative but not clean enough for stronger commitment.",
          why = paste(contradiction_count, "visible conflict(s) could narrow, reverse, or delay the recommendation."),
          how = "Resolve the contradiction, scope it, or keep the recommendation weaker.",
          technical = "Contradictions stay visible because removing them would make the answer look more certain than the evidence allows."
        ),
        tentative_answer = list(
          what = "The evidence points somewhere, but the room is not ready to treat it as a decision.",
          why = "A tentative answer is useful for interpretation, but not yet durable enough for governed recommendation.",
          how = "Inspect the evidence gap, valuation, and review requirements before drafting.",
          technical = "Tentative answers preserve uncertainty so later evidence can strengthen, revise, or supersede the interpretation."
        ),
        supported_answer = list(
          what = "The evidence can support a bounded answer.",
          why = "The room has enough structure to move from interpretation toward a governed recommendation.",
          how = "Preview the recommendation to see exactly what would become durable before saving.",
          technical = "The recommendation remains governed: confirmation, guardrails, and audit records still matter."
        ),
        recommendation_ready = list(
          what = "A draft recommendation exists, but it has not become project evidence yet.",
          why = "Preview separates thinking from persistence so the user can inspect the claim before making it durable.",
          how = "Confirm only if the stated limits and evidence gap are acceptable.",
          technical = "Saving writes a recommendation artifact and audit record through the existing governed mutation path."
        ),
        decision_complete = list(
          what = "The current pass has produced durable project evidence.",
          why = "The saved recommendation can now be inspected, reused, audited, or superseded by future evidence.",
          how = "Review the saved artifact or move to the next decision step.",
          technical = "Persistence records the artifact, action id, confirmation, and evidence context for replay."
        ),
        list(
          what = "The room is explaining its current reasoning state.",
          why = "State-specific explanation helps the user understand what changed.",
          how = "Follow the next useful move.",
          technical = "Unknown states fall back to a safe explanatory frame."
        )
      )
    }

    base_context <- reactive({
      working_context_build_evidence_review(
        artifacts = tryCatch(ctx$all_artifacts(), error = function(e) list()),
        collector_summary = tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table()),
        semantic_decision_state = tryCatch(ctx$semantic_decision_state(), error = function(e) semantic_decision_empty()),
        semantic_workspace = tryCatch(ctx$semantic_workspace(), error = function(e) semantic_workspace_empty()),
        valuation_state = tryCatch(ctx$decision_valuation_state(), error = function(e) decision_valuation_empty()),
        workflow_state = tryCatch(ctx$decision_workflow_state(), error = function(e) decision_workflow_empty())
      )
    })

    artifacts_reactive <- reactive({
      tryCatch(ctx$all_artifacts(), error = function(e) list())
    })

    binder_reactive <- reactive({
      context <- base_context()
      context$evidence_binder
    })

    valuation_reactive <- reactive({
      base_context()$valuation_interpretation
    })

    sufficiency_reactive <- reactive({
      evidence_review_assess_sufficiency(
        binder_reactive(),
        synthesis = (synthesis_result() %||% list())$value %||% NULL,
        proposed_action = selected_value(input$next_action_id) %||% "prepare_decision_draft",
        valuation = valuation_reactive()
      )
    })

    ranked_actions_reactive <- reactive({
      evidence_review_rank_supported_actions(
        binder_reactive(),
        sufficiency = sufficiency_reactive(),
        valuation = valuation_reactive()
      )
    })

    current_answer_story <- reactive({
      binder <- binder_reactive()
      suff <- sufficiency_reactive()
      action <- ranked_actions_reactive()[rank == 1L]
      synthesis <- synthesis_result()
      draft <- draft_state()
      persisted <- persisted_state()
      included_count <- nrow(binder$included %||% data.table::data.table())
      contradiction_count <- nrow((binder$contradictory %||% data.table::data.table()))
      classification <- suff$sufficiency_classification[[1]] %||% "not_assessed"
      limitation <- suff$missing_evidence[[1]] %||% "No blocker detected."
      action_label <- action$action[[1]] %||% "Prepare next action"
      action_reason <- action$reason[[1]] %||% "Review the current evidence before committing a decision artifact."

      if (!is.null(persisted) && identical(persisted$status, "success")) {
        teaching <- story_teaching("decision_complete", included_count, contradiction_count)
        return(c(list(state_id = "decision_complete", label = "Decision Complete", confidence = "Durable", status = "success", headline = "The recommendation has been saved as project evidence.", body = "The current reasoning has a durable artifact and audit record. Review remains possible, but this pass has produced a governed result.", why = "A draft was previewed, confirmed, and persisted through the governed mutation path.", limits = "Future evidence can still supersede the saved recommendation.", next_step = "Review the saved recommendation or open the related project evidence."), teaching))
      }
      if (!is.null(draft)) {
        teaching <- story_teaching("recommendation_ready", included_count, contradiction_count)
        return(c(list(state_id = "recommendation_ready", label = "Recommendation Ready", confidence = "Guarded", status = "warning", headline = "A recommendation draft exists, but confirmation still matters.", body = "The room has enough structure to preview a governed recommendation. Confirm only if the stated evidence gap and guardrails are acceptable.", why = "The draft preserves the current answer, limits, and next action before persistence.", limits = limitation, next_step = "Confirm and save, or refresh the preview after changing the evidence."), teaching))
      }
      if (is.null(synthesis)) {
        teaching <- story_teaching("no_answer_yet", included_count, contradiction_count)
        return(c(list(state_id = "no_answer_yet", label = "No Answer Yet", confidence = "Unknown", status = "neutral", headline = "No current answer has been compiled yet.", body = if (included_count > 0L) "Evidence exists, but the room has not yet turned it into a bounded answer." else "No included evidence is available yet. The room cannot answer the question until artifacts enter the evidence set.", why = if (included_count > 0L) paste(included_count, "artifact(s) are available to inspect.") else "There are no cited artifacts in the current evidence set.", limits = if (included_count > 0L) "Understanding is still uncompiled." else "Evidence is missing.", next_step = if (included_count > 0L) "Compile the current answer." else "Generate or add evidence before drafting."), teaching))
      }
      if (included_count == 0L || identical(classification, "insufficient_or_blocked")) {
        teaching <- story_teaching("insufficient_evidence", included_count, contradiction_count)
        return(c(list(state_id = "insufficient_evidence", label = "Insufficient Evidence", confidence = "Blocked", status = "error", headline = "The evidence does not yet support an answer.", body = "The safest answer is that the question remains open. The next useful work is evidence collection, not recommendation writing.", why = "No supporting artifacts, valuation, or action-specific sufficiency is available.", limits = limitation, next_step = action_label), teaching))
      }
      if (contradiction_count > 0L) {
        teaching <- story_teaching("conflicting_evidence", included_count, contradiction_count)
        return(c(list(state_id = "conflicting_evidence", label = "Conflicting Evidence", confidence = "Conflicted", status = "warning", headline = "The evidence can be inspected, but contradictions limit commitment.", body = "The room can explain what the evidence says, but it should not strengthen the recommendation until the conflict is scoped or resolved.", why = paste(contradiction_count, "contradiction(s) are still visible in the evidence set."), limits = "Contradictory evidence may narrow, reverse, or delay the recommendation.", next_step = "Resolve or scope the contradiction before increasing commitment."), teaching))
      }
      if (classification %in% c("enough_to_draft", "enough_to_recommend", "enough_to_request_review")) {
        teaching <- story_teaching("supported_answer", included_count, contradiction_count)
        return(c(list(state_id = "supported_answer", label = "Supported Answer", confidence = "Supported", status = "success", headline = "The current evidence supports a bounded answer.", body = "The room can move from evidence interpretation toward a governed recommendation, while preserving limits and review requirements.", why = action_reason, limits = limitation, next_step = action_label), teaching))
      }
      teaching <- story_teaching("tentative_answer", included_count, contradiction_count)
      c(list(state_id = "tentative_answer", label = "Tentative Answer", confidence = "Tentative", status = "warning", headline = "The evidence suggests a direction, but it is not decision-ready.", body = "Use the current answer as an interpretation, not as a final recommendation.", why = action_reason, limits = limitation, next_step = action_label), teaching)
    })

    observe({
      binder <- binder_reactive()
      if (is.null(selected_artifact_id()) && nrow(binder$included %||% data.table::data.table())) {
        selected_artifact_id(binder$included$artifact_id[[1]])
      }
    })

    observeEvent(input$selected_artifact_id, {
      selected_artifact_id(selected_value(input$selected_artifact_id))
    }, ignoreInit = TRUE)

    observe({
      context <- base_context()
      state <- context$context_state
      state$selected_artifact_ids <- binder_reactive()$artifact_ids %||% character()
      state$evidence_binder_id <- binder_reactive()$binder_id
      state$sufficiency_state <- sufficiency_reactive()$sufficiency_classification[[1]] %||% "not_assessed"
      state$selected_next_action_id <- selected_value(input$next_action_id) %||% ranked_actions_reactive()$action_id[[1]] %||% NA_character_
      state$workflow_stage <- if (!is.null(persisted_state())) "persisted_result" else if (!is.null(draft_state())) "draft_preview" else if (!is.null(synthesis_result())) "synthesis_review" else "evidence_review"
      state$last_meaningful_action <- state$workflow_stage
      state$updated_at <- Sys.time()
      if (exists("evidence_review_context_state", where = ctx, inherits = FALSE)) {
        ctx$evidence_review_context_state(state)
      }
    })

    observeEvent(input$open_artifacts, {
      if (!is.null(selected_artifact_id()) && exists("inspect_artifact", where = ctx, inherits = FALSE)) {
        ctx$inspect_artifact(selected_artifact_id())
      }
      ctx$navigate_to("Artifact Studio")
    }, ignoreInit = TRUE)
    observeEvent(input$open_decisions, ctx$navigate_to("Decision Management"), ignoreInit = TRUE)
    observeEvent(input$open_mission, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)

    observeEvent(input$inspect_artifact, {
      result <- evidence_review_inspect_artifact(artifacts_reactive(), selected_artifact_id(), depth_level = 2L)
      inspection_result(result)
      interaction_message(if (identical(result$status, "success")) "Detail now shows the claim source, limits, diagnostics, and lineage for the selected evidence." else "Nothing opened because no evidence artifact is selected yet.")
    }, ignoreInit = TRUE)

    observeEvent(input$compile_synthesis, {
      synthesis_result(evidence_review_compile_synthesis(
        binder_reactive(),
        proposed_action = selected_value(input$next_action_id) %||% "prepare_decision_draft"
      ))
      story <- current_answer_story()
      interaction_message(paste("Current Answer moved to", story$label, "The room converted evidence into claims, gaps, limits, and a bounded next move."))
    }, ignoreInit = TRUE)

    observeEvent(input$refresh_binder, {
      synthesis_result(NULL)
      inspection_result(NULL)
      draft_state(NULL)
      persisted_state(NULL)
      contradiction_message("Evidence refreshed from current project artifacts.")
      interaction_message("Evidence changed, so the previous answer was cleared. Compile again before drafting.")
    }, ignoreInit = TRUE)

    observeEvent(input$mark_contradiction_reviewed, {
      contradiction_message("Contradiction marked reviewed in this context. The underlying evidence remains unchanged.")
      interaction_message("Contradiction review recorded. The conflict stays visible so the answer does not become falsely certain.")
    }, ignoreInit = TRUE)

    observeEvent(input$request_more_evidence, {
      contradiction_message("Additional evidence retrieval is recorded as a recommended follow-up; no artifact is fabricated.")
      interaction_message("Evidence request noted. The room is teaching that missing evidence is a work order, not permission to overclaim.")
    }, ignoreInit = TRUE)

    observeEvent(input$explain_sufficiency, {
      suff <- sufficiency_reactive()
      prompt <- paste(
        "Explain this Evidence Review sufficiency assessment in concise language.",
        "Do not invent evidence. Include the limitation and next action.",
        paste(capture.output(print(suff)), collapse = "\n"),
        sep = "\n\n"
      )
      result <- genai_chat_with_telemetry(
        list(list(role = "user", content = prompt)),
        config = ctx$genai_config(),
        context_strategy = "structured_json_summary",
        included_components = c("metadata", "diagnostics", "recommendations")
      )
      contextual_ai_result(result)
      interaction_message("Mentor explanation returned. Use it to clarify sufficiency, not to replace evidence.")
    }, ignoreInit = TRUE)

    observeEvent(input$summarize_binder, {
      binder <- binder_reactive()
      included <- binder$included %||% data.table::data.table()
      prompt <- paste(
        "Summarize this Evidence Review binder. Use only the supplied artifact metadata.",
        "Identify key evidence, limitations, contradictions, and a bounded next action.",
        paste(capture.output(print(included[, intersect(c("artifact_id", "title", "artifact_type", "key_finding", "limitations", "freshness", "contradiction_state"), names(included)), with = FALSE])), collapse = "\n"),
        sep = "\n\n"
      )
      result <- genai_chat_with_telemetry(
        list(list(role = "user", content = prompt)),
        config = ctx$genai_config(),
        context_strategy = "caption_metadata",
        included_components = c("caption", "metadata", "diagnostics")
      )
      contextual_ai_result(result)
      interaction_message("Mentor summary returned. Check it against the evidence set before relying on it.")
    }, ignoreInit = TRUE)

    observeEvent(input$preview_draft, {
      context <- base_context()
      draft <- evidence_review_create_draft(
        context,
        binder_reactive(),
        sufficiency_reactive(),
        selected_value(input$next_action_id) %||% "prepare_decision_draft"
      )
      draft_state(draft)
      persisted_state(NULL)
      interaction_message("Draft preview created. The proposed recommendation is visible before it becomes durable evidence.")
    }, ignoreInit = TRUE)

    observeEvent(input$persist_draft, {
      draft <- draft_state()
      if (is.null(draft)) {
        draft <- evidence_review_create_draft(
          base_context(),
          binder_reactive(),
          sufficiency_reactive(),
          selected_value(input$next_action_id) %||% "prepare_decision_draft"
        )
        draft_state(draft)
      }
      state <- tryCatch(ctx$evidence_review_context_state(), error = function(e) base_context()$context_state)
      result <- evidence_review_persist_draft(state, draft, confirmation = TRUE)
      if (identical(result$status, "success")) {
        persisted_state(result)
        artifact <- result$value$artifact
        ctx$saved_text_artifacts$artifacts[[artifact$artifact_id]] <- artifact
        if (data.table::is.data.table(ctx$genai_action_state$audit_log)) {
          ctx$genai_action_state$audit_log <- data.table::rbindlist(
            list(ctx$genai_action_state$audit_log, result$value$audit_record),
            use.names = TRUE,
            fill = TRUE
          )
        } else {
          ctx$genai_action_state$audit_log <- result$value$audit_record
        }
        ctx$artifact_library_message("Evidence Review draft persisted as a project artifact.")
        ctx$evidence_review_context_state(result$value$context_state)
        interaction_message("Draft persisted as evidence. The recommendation is now durable, traceable, and available for future review.")
      } else {
        persisted_state(NULL)
        interaction_message("Persistence did not complete. Review the validation message before trying again.")
      }
    }, ignoreInit = TRUE)

    output$context_header <- renderUI({
      context <- base_context()
      suff <- sufficiency_reactive()
      action <- ranked_actions_reactive()[rank == 1L]
      story <- current_answer_story()
      status <- suff$sufficiency_classification[[1]] %||% "not_assessed"
      status_kind <- if (grepl("enough", status)) "success" else if (grepl("inspect|reasonable|preliminary", status)) "warning" else "error"
      tags$header(
        class = "aq-evidence-room-header",
        tags$div(
          class = "aq-evidence-room-kicker",
          tags$span("Decision under review"),
          ui_status_badge(ui_display_label(status), status = status_kind)
        ),
          tags$div(
            class = "aq-evidence-room-title-row",
            tags$div(
            tags$p(class = "aq-section-eyebrow", "Decision Frame"),
            tags$h2(context$business_question),
            tags$p(class = "aq-evidence-room-subtitle", context$decision_context_id %||% "No decision context")
          ),
          tags$div(
            class = "aq-evidence-room-next",
            tags$span("Recommended next action"),
            tags$strong(action$action[[1]] %||% context$supported_next_action),
            tags$small(action$reason[[1]] %||% "Based on the current evidence binder.")
          )
        ),
        tags$div(
          class = "aq-evidence-room-facts",
          tags$div(
            class = paste("aq-evidence-room-fact", paste0("aq-evidence-room-fact-", status_kind)),
            tags$span("Evidence"),
            tags$strong(ui_display_label(status)),
            tags$small(if (nrow(context$evidence_binder$included %||% data.table::data.table())) "Citable material is present." else "No citable evidence yet.")
          ),
          tags$div(
            class = "aq-evidence-room-fact",
            tags$span("Limit"),
            tags$strong(suff$missing_evidence[[1]] %||% "None detected")
          ),
          tags$div(
            class = paste("aq-evidence-room-fact", paste0("aq-evidence-room-fact-", story$status)),
            tags$span("Answer"),
            tags$strong(story$label),
            tags$small(story$confidence)
          )
        )
      )
    })

    output$understanding_brief <- renderUI({
      binder <- binder_reactive()
      story <- current_answer_story()
      included_count <- nrow(binder$included %||% data.table::data.table())
      contradiction_count <- nrow(binder$contradictory %||% data.table::data.table())
      tags$div(
        class = paste("aq-current-answer-story", paste0("aq-current-answer-story-", story$state_id)),
        tags$div(
          class = "aq-evidence-brief-copy",
          tags$div(
            class = "aq-current-answer-header",
            tags$p(class = "aq-section-eyebrow", "Current Answer"),
            ui_status_badge(story$label, status = story$status)
          ),
          tags$h3(story$headline),
          tags$p(story$body),
          tags$div(
            class = "aq-current-answer-ribbon",
            tags$span("Confidence"),
            tags$strong(story$confidence),
            tags$span("Evidence"),
            tags$strong(paste(included_count, "artifact(s)")),
            tags$span("Contradictions"),
            tags$strong(contradiction_count)
          )
        ),
        tags$div(
          class = "aq-evidence-brief-grid",
          tags$div(
            class = "aq-evidence-brief-item",
            tags$span("Why we believe this"),
            tags$strong(story$why)
          ),
          tags$div(
            class = "aq-evidence-brief-item",
            tags$span("What limits it"),
            tags$strong(story$limits)
          ),
          tags$div(
            class = "aq-evidence-brief-item",
            tags$span("What happens next"),
            tags$strong(story$next_step)
          )
        )
      )
    })

    output$primary_action_summary <- renderUI({
      suff <- sufficiency_reactive()
      stage <- tryCatch(ctx$evidence_review_context_state()$workflow_stage, error = function(e) "evidence_review")
      readiness <- ui_display_label(suff$sufficiency_classification[[1]] %||% "not_assessed")
      tags$div(
        class = "aq-evidence-primary-action-summary",
        tags$span(if (identical(stage, "persisted_result")) "Saved for this pass." else if (identical(stage, "draft_preview")) "Ready for confirmation." else "Readiness"),
        tags$strong(readiness),
        tags$small(if (identical(stage, "draft_preview")) "Recommendation preview is ready to save." else if (identical(stage, "persisted_result")) "The recommendation has been recorded." else "Evidence sufficiency controls whether drafting is justified.")
      )
    })

    output$contextual_teaching <- renderUI({
      story <- current_answer_story()
      tags$section(
        class = paste("aq-evidence-teaching-strip", paste0("aq-evidence-teaching-strip-", story$state_id)),
        tags$div(
          class = "aq-teaching-step aq-teaching-step-what",
          tags$span("What"),
          tags$strong(story$what)
        ),
        tags$div(
          class = "aq-teaching-step aq-teaching-step-why",
          tags$span("Why it matters"),
          tags$strong(story$why)
        ),
        tags$div(
          class = "aq-teaching-step aq-teaching-step-how",
          tags$span("How to move"),
          tags$strong(story$how)
        ),
        ui_disclosure(
          "Technical reason",
          tags$p(story$technical),
          open = FALSE,
          level = "advanced"
        )
      )
    })

    output$workflow_actions <- renderUI({
      stage <- tryCatch(ctx$evidence_review_context_state()$workflow_stage, error = function(e) "evidence_review")
      if (is.null(synthesis_result()) && !identical(stage, "persisted_result")) {
        return(ui_action_row(
          actionButton(session$ns("preview_draft"), "Preview Recommendation", class = "btn-primary aq-hidden-action"),
          tags$span(class = "aq-evidence-action-hint", "Compile the answer before drafting.")
        ))
      }
      if (identical(stage, "persisted_result")) {
        return(ui_action_row(
          actionButton(session$ns("preview_draft"), "Review Draft", class = "btn-secondary"),
          tags$span(class = "aq-evidence-action-complete", "Recommendation Saved")
        ))
      }
      if (identical(stage, "draft_preview")) {
        return(ui_action_row(
          actionButton(session$ns("preview_draft"), "Refresh Preview", class = "btn-secondary"),
          actionButton(session$ns("persist_draft"), "Save Recommendation", class = "btn-primary")
        ))
      }
      ui_action_row(
        actionButton(session$ns("preview_draft"), "Preview Recommendation", class = "btn-primary"),
        tags$span(class = "aq-evidence-action-hint", "Saving appears after preview.")
      )
    })

    output$room_feedback <- renderUI({
      stage <- tryCatch(ctx$evidence_review_context_state()$workflow_stage, error = function(e) "evidence_review")
      tags$div(
        class = paste("aq-evidence-feedback", paste0("aq-evidence-feedback-", stage)),
        tags$span(class = "aq-evidence-feedback-dot"),
        tags$strong(story_stage_label(stage)),
        tags$span(interaction_message())
      )
    })

    output$binder_summary <- renderUI({
      binder <- binder_reactive()
      included <- binder$included %||% data.table::data.table()
      if (!nrow(included)) {
        return(tags$div(
          class = "aq-narrative-empty aq-narrative-empty-evidence",
          tags$p(class = "aq-section-eyebrow", "No Evidence Yet"),
          tags$h4("The room is waiting for evidence."),
          tags$p("This is blocked because there is nothing the answer can cite yet. Run analysis modules, add artifacts, or open Artifact Studio to bring evidence into this review."),
          tags$ul(
            tags$li("What we are waiting for: artifacts with claims, limits, diagnostics, and provenance."),
            tags$li("Why it matters: the Current Answer remains unknown until something can be cited."),
            tags$li("Next: generate evidence before drafting a recommendation.")
          )
        ))
      }
      tags$div(
        class = "aq-status-list",
        ui_stat_grid(
          ui_stat_tile("Included", nrow(binder$included %||% data.table::data.table()), status = "success", detail = "artifact(s)"),
          ui_stat_tile("Omitted", nrow(binder$omitted %||% data.table::data.table()), status = "neutral"),
          ui_stat_tile("Stale", nrow(binder$stale_or_superseded %||% data.table::data.table()), status = if (nrow(binder$stale_or_superseded %||% data.table::data.table())) "warning" else "success"),
          ui_stat_tile("Contradictions", nrow((binder$contradictory %||% data.table::data.table())), status = if (nrow(binder$contradictory %||% data.table::data.table())) "warning" else "success")
        ),
        ui_disclosure(
          "Included Artifacts",
          render_table((binder$included %||% data.table::data.table())[, intersect(c("artifact_id", "title", "artifact_type", "key_finding", "freshness", "contradiction_state"), names(binder$included)), with = FALSE], engine = "html", searchable = FALSE, sortable = FALSE),
          open = TRUE
        ),
        ui_disclosure(
          "Omitted / Stale Evidence",
          tagList(
            render_table(binder$omitted %||% data.table::data.table(), engine = "html", searchable = FALSE, sortable = FALSE),
            render_table(binder$stale_or_superseded %||% data.table::data.table(), engine = "html", searchable = FALSE, sortable = FALSE)
          ),
          open = FALSE
        )
      )
    })

    output$artifact_selector <- renderUI({
      binder <- binder_reactive()
      included <- binder$included %||% data.table::data.table()
      choices <- if (nrow(included)) stats::setNames(included$artifact_id, included$title) else character()
      if (!length(choices)) {
        return(tags$div(class = "aq-evidence-selector-empty", "Evidence selection appears after artifacts enter the room."))
      }
      selectInput(session$ns("selected_artifact_id"), "Evidence to inspect", choices = choices, selected = selected_artifact_id())
    })

    output$artifact_inspector <- renderUI({
      result <- inspection_result()
      if (is.null(result)) {
        return(tags$div(
          class = "aq-narrative-empty aq-narrative-empty-detail",
          tags$p(class = "aq-section-eyebrow", "No Detail Open"),
          tags$h4("Open evidence when you need to trust a claim."),
          tags$p("Detail stays quiet until provenance matters. Open an artifact when you need to understand where a claim came from, what limits it, and whether it belongs in the current answer.")
        ))
      }
      if (!identical(result$status, "success")) {
        return(tags$div(class = "aq-callout aq-callout-warning", paste(result$errors, collapse = " ")))
      }
      value <- result$value
      tags$div(
        render_table(value$summary, engine = "html", searchable = FALSE, sortable = FALSE),
        ui_disclosure("Claims", render_table(value$claims, engine = "html", searchable = FALSE, sortable = FALSE), open = TRUE),
        ui_disclosure("Diagnostics", render_table(value$diagnostics, engine = "html", searchable = FALSE, sortable = FALSE), open = FALSE),
        ui_disclosure("Lineage", render_table(value$lineage, engine = "html", searchable = FALSE, sortable = FALSE), open = FALSE),
        tags$div(class = "aq-callout aq-callout-info", tags$strong("Full Artifact Reference"), tags$p(value$full_artifact_ref))
      )
    })

    output$synthesis_view <- renderUI({
      result <- synthesis_result()
      if (is.null(result)) {
        return(tags$div(
          class = "aq-narrative-empty aq-narrative-empty-synthesis",
          tags$p(class = "aq-section-eyebrow", "No Synthesis Yet"),
          tags$h4("Understanding has not been compiled."),
          tags$p("Compilation is the moment the room asks, 'What can we safely say now?' It turns artifacts into cited claims, visible gaps, excluded evidence, and claims the room refuses to make.")
        ))
      }
      if (!identical(result$status, "success") && !identical(result$status, "warning")) {
        return(tags$div(class = "aq-callout aq-callout-warning", paste(result$errors, collapse = " ")))
      }
      value <- result$value
      tags$div(
        ui_disclosure("Cited Claims", render_table(value$cited_claims, engine = "html", searchable = FALSE, sortable = FALSE), open = TRUE),
        ui_disclosure("Evidence Gaps", render_table(value$gaps, engine = "html", searchable = FALSE, sortable = FALSE), open = TRUE),
        ui_disclosure("Excluded Evidence", render_table(value$excluded_evidence, engine = "html", searchable = FALSE, sortable = FALSE), open = FALSE),
        ui_disclosure("Prohibited Claims", render_table(value$prohibited_claims, engine = "html", searchable = FALSE, sortable = FALSE), open = FALSE)
      )
    })

    output$contradiction_workspace <- renderUI({
      contradictions <- evidence_review_contradiction_workspace(binder_reactive())
      message <- contradiction_message()
      if (!nrow(contradictions[status == "unresolved"])) {
        return(tags$div(
          if (!is.null(message)) tags$div(class = "aq-callout aq-callout-info", message),
          tags$div(
            class = "aq-narrative-empty aq-narrative-empty-contradiction",
            tags$p(class = "aq-section-eyebrow", "No Active Contradiction"),
            tags$h4("Nothing currently conflicts with the answer."),
            tags$p("This does not prove certainty. It means no deterministic conflict has been recorded. If contradictions appear later, they stay visible because they protect the answer from becoming too strong.")
          )
        ))
      }
      tags$div(
        if (!is.null(message)) tags$div(class = "aq-callout aq-callout-info", message),
        render_table(contradictions, engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$sufficiency_view <- renderUI({
      render_table(sufficiency_reactive(), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$valuation_view <- renderUI({
      render_table(valuation_reactive(), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$action_selector <- renderUI({
      actions <- ranked_actions_reactive()
      choices <- stats::setNames(actions$action_id, paste0(actions$rank, ". ", actions$action))
      tagList(
        tags$div(
          class = "aq-next-move-static",
          tags$span("Next useful move"),
          tags$strong(actions$action[[1]] %||% "Prepare next action"),
          tags$small(actions$reason[[1]] %||% "The room is using the highest ranked governed action.")
        ),
        if (nrow(actions) > 1L) {
          ui_disclosure(
            "Change next move",
            selectInput(session$ns("next_action_id"), NULL, choices = choices, selected = choices[[1]] %||% "inspect_artifact"),
            open = FALSE,
            level = "advanced"
          )
        } else {
          tags$div(
            class = "aq-hidden-control",
            selectInput(session$ns("next_action_id"), NULL, choices = choices, selected = choices[[1]] %||% "inspect_artifact")
          )
        }
      )
    })

    output$semantic_continuation <- renderUI({
      story <- current_answer_story()
      continuation <- if (story$state_id %in% c("supported_answer", "recommendation_ready", "decision_complete")) {
        list(
          label = "Continue the reasoning",
          next_step = "Move from Current Answer to Current Decision.",
          why = "The evidence can support a bounded next step, so the natural continuation is recommendation and tradeoff judgment.",
          action = "Continue to Decision"
        )
      } else if (story$state_id %in% c("insufficient_evidence", "no_answer_yet")) {
        list(
          label = "Continue the reasoning",
          next_step = "Generate evidence before deciding.",
          why = "The current answer is still unknown or blocked, so moving to a decision would spend judgment before evidence.",
          action = "Request Evidence"
        )
      } else {
        list(
          label = "Continue the reasoning",
          next_step = "Resolve what limits the Current Answer.",
          why = "The next thought is not a destination; it is reducing the uncertainty that still weakens the answer.",
          action = "Review Limits"
        )
      }
      tags$section(
        class = "aq-semantic-continuation",
        tags$div(
          tags$p(class = "aq-section-eyebrow", continuation$label),
          tags$strong(continuation$next_step),
          tags$span(continuation$why)
        ),
        tags$span(class = "aq-semantic-continuation-action", continuation$action)
      )
    })

    output$ranked_actions <- renderUI({
      actions <- ranked_actions_reactive()
      render_table(actions[, c("rank", "action", "reason", "consequence", "reversibility", "confirmation_required", "not_preferred_reason"), with = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$draft_flow <- renderUI({
      draft <- draft_state()
      persisted <- persisted_state()
      if (!is.null(persisted) && identical(persisted$status, "success")) {
        return(tags$div(
          class = "aq-status-list",
          tags$div(class = "aq-callout aq-callout-success", tags$strong("Recommendation Saved"), tags$p(persisted$messages)),
          render_table(persisted$value$audit_record, engine = "html", searchable = FALSE, sortable = FALSE)
        ))
      }
      if (is.null(draft)) {
        return(tags$div(
          class = "aq-narrative-empty aq-narrative-empty-draft",
          tags$p(class = "aq-section-eyebrow", "No Recommendation Preview Yet"),
          tags$h4("The room has not prepared a recommendation."),
          tags$p("Previewing converts the current answer, its limits, and the selected next move into a governed recommendation draft. Saving appears only after the user can inspect what would become durable.")
        ))
      }
      tags$div(
        render_table(draft$preview, engine = "html", searchable = FALSE, sortable = FALSE),
        ui_disclosure("Validation", render_table(draft$validation, engine = "html", searchable = FALSE, sortable = FALSE), open = TRUE)
      )
    })

    output$contextual_ai <- renderUI({
      result <- contextual_ai_result()
      result_text <- NULL
      if (!is.null(result)) {
        result_text <- if (identical(result$status, "success")) {
          (result$value %||% list())$text %||% result$value %||% "AI response returned without text."
        } else {
          paste(c(result$errors, result$messages), collapse = " ")
        }
      }
      ui_disclosure(
        "Ask the mentor",
        tags$div(
        tags$div(
          class = "aq-evidence-mentor",
          tags$p(class = "aq-section-eyebrow", "Contextual Mentor"),
          tags$strong("Ask only when understanding improves."),
          tags$p("Use this when a state feels unclear: sufficiency, contradiction, missing evidence, or bounded next action. The room should teach first; the mentor only clarifies.")
        ),
        ui_action_row(
          actionButton(session$ns("explain_sufficiency"), "Explain Sufficiency", class = "btn-primary btn-sm"),
          actionButton(session$ns("summarize_binder"), "Summarize Evidence", class = "btn-secondary btn-sm")
        ),
        if (!is.null(result_text)) {
          tags$div(
            class = if (identical(result$status, "success")) "aq-callout aq-callout-success" else "aq-callout aq-callout-warning",
            tags$pre(result_text)
          )
        },
        ui_disclosure(
          "Allowed Contextual AI Actions",
          render_table(evidence_review_contextual_ai_actions()[, c("ai_action", "reason", "must_use", "forbidden"), with = FALSE], engine = "html", searchable = FALSE, sortable = FALSE),
          open = FALSE
        )
        ),
        open = !is.null(result_text),
        level = "advanced"
      )
    })

    output$mission_summary <- renderUI({
      context <- base_context()
      mission <- context$mission_summary
      suff <- sufficiency_reactive()
      mission <- data.table::rbindlist(list(
        mission,
        data.table::data.table(signal = "Sufficiency", status = suff$sufficiency_classification[[1]] %||% "not_assessed"),
        data.table::data.table(signal = "Draft", status = if (!is.null(persisted_state())) "persisted" else if (!is.null(draft_state())) "awaiting_confirmation" else "not_started")
      ), use.names = TRUE, fill = TRUE)
      render_table(mission, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$progressive_depth <- renderUI({
      render_table(working_context_progressive_depth(), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$context_state <- renderUI({
      state <- tryCatch(ctx$evidence_review_context_state(), error = function(e) base_context()$context_state)
      render_table(evidence_review_context_state_summary(state), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$related_tasks <- renderUI({
      transitions <- working_context_transition_map()
      render_table(transitions[, c("adjacent_task", "target_surface", "transition_type", "reason"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })
  })
}
