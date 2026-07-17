page_ai_runtime_ui <- function(id) {
  ns <- NS(id)
  task_ids <- as.character(stats::na.omit(unlist(knowledge_runtime_task_taxonomy()$task_code, use.names = FALSE)))
  tier_ids <- as.character(stats::na.omit(unlist(knowledge_model_tier_profiles()$model_tier, use.names = FALSE)))
  task_choices <- stats::setNames(task_ids, gsub("_", " ", tools::toTitleCase(task_ids)))
  tier_choices <- stats::setNames(tier_ids, gsub("_", " ", tools::toTitleCase(tier_ids)))
  tabPanel(
    "AI Runtime",
    value = "ai_runtime",
    tags$main(
      class = "aq-page aq-page-ai-runtime",
      ui_section_header(
        "AI Runtime",
        "Inspect compiled runtime bundles, task routing, model-tier context, validation, diagnostics, and proposed actions.",
        eyebrow = "DEVELOPER"
      ),
      ui_object_spine(
        object = "AI Operating Contract",
        intent = "Inspect what the AI is allowed to know, propose, persist, and route before any broader operation is trusted.",
        state = "Read-only runtime inspection with governed proposals.",
        next_action = "Choose a task and model tier, then refresh the runtime snapshot.",
        depth = "Diagnostics are intentionally developer-facing and remain below the operating contract."
      ),
      tags$div(
        class = "aq-workspace-grid aq-workspace-grid-main-sidebar",
        tags$section(
          class = "aq-workspace-main",
          ui_card(
            title = "Runtime Snapshot",
            subtitle = "Deterministic view of what the AI operator is allowed to know and propose.",
            uiOutput(ns("runtime_snapshot"))
          ),
          ui_card(
            title = "Action Proposal",
            subtitle = "Proposal generated from the compiled runtime package. This page does not execute it.",
            tags$pre(class = "aq-code-block", textOutput(ns("action_proposal"), container = span))
          ),
          ui_card(
            title = "Qualification",
            subtitle = "Task-scoped model qualification under the current runtime and bundle version.",
            uiOutput(ns("qualification_summary"))
          ),
          tags$section(
            class = "aq-ai-runtime-depth",
            ui_disclosure(
              "Diagnostics",
              ui_card(
                title = "Runtime Diagnostics",
                subtitle = "Bundle, task, token, cache, validation, fallback, and escalation metadata.",
                tags$pre(class = "aq-code-block", textOutput(ns("runtime_diagnostics"), container = span))
              ),
              level = "developer",
              open = FALSE
            ),
            ui_disclosure(
              "Context and Synthesis",
              ui_workspace_grid(
                columns = "two",
                ui_card(
                  title = "Progressive Retrieval",
                  subtitle = "Artifact-centered context growth, retrieval chain, cache, and sufficiency diagnostics.",
                  uiOutput(ns("retrieval_summary")),
                  tags$pre(class = "aq-code-block", textOutput(ns("retrieval_chain"), container = span))
                ),
                ui_card(
                  title = "Cross-Artifact Synthesis",
                  subtitle = "Evidence classes, contradictions, coverage, missing evidence, and cited synthesis plan.",
                  uiOutput(ns("synthesis_summary")),
                  tags$pre(class = "aq-code-block", textOutput(ns("synthesis_plan"), container = span))
                )
              ),
              level = "developer",
              open = FALSE
            ),
            ui_disclosure(
              "Governed Review and Persistence",
              ui_workspace_grid(
                columns = "two",
                ui_card(
                  title = "Governed Evidence Review",
                  subtitle = "Bounded review, evidence binder, sufficiency for action, ranked supported actions, and preview-only draft.",
                  uiOutput(ns("evidence_review_summary")),
                  uiOutput(ns("evidence_review_actions")),
                  tags$pre(class = "aq-code-block", textOutput(ns("evidence_review_draft"), container = span))
                ),
                ui_card(
                  title = "Evidence Review Audit",
                  subtitle = "Operational AI evidence record. This is reconstructable runtime telemetry, not project mutation.",
                  tags$pre(class = "aq-code-block", textOutput(ns("evidence_review_audit"), container = span))
                ),
                ui_card(
                  title = "Confirmed Draft Persistence",
                  subtitle = "Governed Class 3 lifecycle state for AI-generated drafts. Persistence requires explicit confirmation and existing app handlers.",
                  uiOutput(ns("draft_persistence_summary")),
                  uiOutput(ns("draft_lifecycle_table")),
                  tags$pre(class = "aq-code-block", textOutput(ns("draft_audit_timeline"), container = span))
                ),
                ui_card(
                  title = "Mutation Governance",
                  subtitle = "Canonical mutation classification, risk, governance, lifecycle, and audit state for future AI-operated workflows.",
                  uiOutput(ns("mutation_governance_summary")),
                  uiOutput(ns("mutation_lifecycle_table")),
                  tags$pre(class = "aq-code-block", textOutput(ns("mutation_audit_timeline"), container = span))
                )
              ),
              level = "developer",
              open = FALSE
            )
          )
        ),
        tags$aside(
          class = "aq-workspace-sidebar",
          ui_card(
            title = "Controls",
            selectInput(
              ns("task"),
              "Task",
              choices = task_choices,
              selected = "recommend_supported_next_action"
            ),
            selectInput(
              ns("model_tier"),
              "Model Tier",
              choices = tier_choices,
              selected = "local_free_model"
            ),
            textInput(ns("request"), "Request", value = "What should I do next?"),
            textInput(ns("review_scope"), "Review Scope", value = "current bounded question"),
            actionButton(ns("refresh"), "Refresh Runtime")
          ),
          ui_card(
            title = "Model-Tier Benchmark",
            subtitle = "Deterministic fitness-for-task and qualification fixtures.",
            uiOutput(ns("benchmark_summary"))
          )
        )
      )
    )
  )
}

page_ai_runtime_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    snapshot <- reactive({
      input$refresh
      isolate(knowledge_runtime_developer_snapshot(
        ctx = ctx,
        user_request = input$request %||% "What should I do next?",
        model_tier = input$model_tier %||% "local_free_model"
      ))
    })

    routed_snapshot <- reactive({
      task <- input$task %||% "recommend_supported_next_action"
      model_tier <- input$model_tier %||% "local_free_model"
      result <- knowledge_operator_propose(
        ctx = ctx,
        user_request = input$request %||% "What should I do next?",
        explicit_task = task,
        model_tier = model_tier
      )
      result$value %||% list()
    })

    retrieval_snapshot <- reactive({
      task <- input$task %||% "recommend_supported_next_action"
      request <- artifact_retrieval_request(
        retrieval_type = "need_findings",
        artifact_id = NULL,
        reason = "AI Runtime page preview requests the smallest available finding or artifact digest.",
        task_code = task
      )
      build_progressive_artifact_context(
        ctx = ctx,
        user_request = input$request %||% "What should I do next?",
        explicit_task = task,
        retrieval_requests = list(request),
        model_tier = input$model_tier %||% "local_free_model"
      )$value %||% list()
    })

    synthesis_snapshot <- reactive({
      structured_cross_artifact_synthesis(
        ctx = ctx,
        question = input$request %||% "What should I do next?",
        explicit_task = input$task %||% "recommend_supported_next_action",
        model_tier = input$model_tier %||% "local_free_model"
      )
    })

    evidence_review_snapshot <- reactive({
      input$refresh
      isolate(run_ai_operated_evidence_review(
        ctx = ctx,
        question = input$request %||% "What should I do next?",
        scope = input$review_scope %||% "current bounded question",
        model_tier = input$model_tier %||% "local_free_model"
      )$value %||% list())
    })

    draft_store_snapshot <- reactive({
      store <- tryCatch(ctx$ai_draft_state$store, error = function(e) ai_draft_store_empty())
      list(ai_draft_store = ai_draft_store_normalize(store))
    })

    mutation_store_snapshot <- reactive({
      store <- tryCatch(ctx$ai_mutation_state$store, error = function(e) mutation_store_empty())
      list(ai_mutation_store = mutation_store_normalize(store))
    })

    output$runtime_snapshot <- renderUI({
      value <- routed_snapshot()
      package <- value$context_package %||% list()
      validation <- value$validation %||% list(status = "unknown")
      ui_stat_grid(
        ui_stat_tile("Task", ui_display_label(package$task_code %||% "unknown"), status = "info"),
        ui_stat_tile("Bundle", package$bundle_id %||% "unknown", detail = package$bundle_version %||% ""),
        ui_stat_tile("Model Tier", ui_display_label(package$model_tier %||% "unknown")),
        ui_stat_tile("Validation", ui_display_label(validation$status %||% "unknown"), status = if (identical(validation$status %||% "", "success")) "success" else "warning"),
        ui_stat_tile("Tokens", package$token_accounting$total_estimated_tokens %||% 0L, detail = paste("budget", package$token_accounting$tier_budget %||% "-")),
        ui_stat_tile("Cache", if (isTRUE(package$cache$bundle_cache_hit)) "Hit" else "Miss")
      )
    })

    output$qualification_summary <- renderUI({
      value <- routed_snapshot()
      diagnostics <- value$diagnostics %||% list()
      ui_stat_grid(
        ui_stat_tile("Qualification", ui_display_label(diagnostics$qualification_status %||% "unknown"), status = if ((diagnostics$qualification_status %||% "") %in% c("qualified", "qualified_with_validation", "navigation_only")) "success" else "warning"),
        ui_stat_tile("Confidence", round(100 * (diagnostics$qualification_confidence %||% 0), 1), detail = "percent"),
        ui_stat_tile("Runtime", diagnostics$runtime_version %||% "unknown"),
        ui_stat_tile("Benchmark", diagnostics$benchmark_reference %||% "not available")
      )
    })

    output$retrieval_summary <- renderUI({
      value <- retrieval_snapshot()
      diagnostics <- value$retrieval_diagnostics %||% list()
      ui_stat_grid(
        ui_stat_tile("Artifacts", nrow(value$artifact_inventory %||% data.table::data.table()), detail = "discoverable"),
        ui_stat_tile("Retrieved", diagnostics$retrieval_granted %||% 0L, detail = paste("denied", diagnostics$retrieval_denied %||% 0L)),
        ui_stat_tile("Token Growth", diagnostics$token_increase %||% 0L, detail = paste("final", diagnostics$final_context_tokens %||% 0L)),
        ui_stat_tile("Sufficiency", ui_display_label(diagnostics$context_sufficiency %||% "unknown"), status = if ((diagnostics$context_sufficiency %||% "") %in% c("sufficient", "probably_sufficient")) "success" else "warning")
      )
    })

    output$retrieval_chain <- renderText({
      value <- retrieval_snapshot()
      jsonlite::toJSON(value$retrieval_diagnostics %||% list(), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$synthesis_summary <- renderUI({
      synthesis <- synthesis_snapshot()
      plan <- synthesis$synthesis_plan %||% list()
      ui_stat_grid(
        ui_stat_tile("Evidence", length(synthesis$evidence_considered %||% character()), detail = "artifacts considered"),
        ui_stat_tile("Classes", length(synthesis$evidence_classes %||% character()), detail = paste(synthesis$evidence_classes %||% character(), collapse = ", ")),
        ui_stat_tile("Contradictions", nrow(synthesis$contradictions %||% data.table::data.table()), status = if (nrow(synthesis$contradictions %||% data.table::data.table()) > 0L) "warning" else "success"),
        ui_stat_tile("Sufficiency", ui_display_label(plan$sufficiency$state %||% "unknown"), status = if ((plan$sufficiency$state %||% "") %in% c("sufficient", "probably sufficient")) "success" else "warning")
      )
    })

    output$synthesis_plan <- renderText({
      synthesis <- synthesis_snapshot()
      jsonlite::toJSON(list(
        evidence_considered = synthesis$evidence_considered,
        evidence_omitted = synthesis$evidence_omitted,
        evidence_classes = synthesis$evidence_classes,
        contradictions = synthesis$contradictions,
        remaining_uncertainty = synthesis$remaining_uncertainty,
        citations = synthesis$citations,
        prohibited_claims = synthesis$prohibited_claims
      ), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$evidence_review_summary <- renderUI({
      review <- evidence_review_snapshot()
      sufficiency <- review$sufficiency %||% list()
      routing <- review$model_routing %||% list()
      ui_stat_grid(
        ui_stat_tile("Session", review$session$session_id %||% "unknown", status = "info"),
        ui_stat_tile("Reviewed", length(unique(c(review$binder$primary_artifacts, review$binder$supporting_artifacts, review$binder$contradictory_artifacts))), detail = "artifacts"),
        ui_stat_tile("Sufficiency", ui_display_label(sufficiency$state %||% "unknown"), status = if (isTRUE(sufficiency$sufficient)) "success" else "warning"),
        ui_stat_tile("Contradictions", nrow(review$synthesis_summary$contradictions %||% data.table::data.table()), status = if (nrow(review$synthesis_summary$contradictions %||% data.table::data.table())) "warning" else "success"),
        ui_stat_tile("Route", ui_display_label(routing$model_tier %||% "unknown"), detail = routing$escalation %||% "none"),
        ui_stat_tile("Citation Check", ui_display_label(review$citation_validation$status %||% "unknown"), status = if (identical(review$citation_validation$status %||% "", "success")) "success" else "error")
      )
    })

    output$evidence_review_actions <- renderUI({
      review <- evidence_review_snapshot()
      actions <- review$ranked_actions %||% data.table::data.table()
      if (!nrow(actions)) return(ui_empty_state("No supported action.", "The review did not find a supported action for this scope."))
      render_table(
        actions[, .(rank, action_id, action_class, purpose, evidence_gap_addressed, expected_information_gain, effort_category, authority_requirement, user_confirmation_required, current_eligibility, ranking_reason)],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$evidence_review_draft <- renderText({
      review <- evidence_review_snapshot()
      jsonlite::toJSON(list(
        draft = review$draft,
        campaign_draft = review$campaign_draft,
        findings = review$findings[, .(finding_code, severity, finding, evidence_refs, recommendation)]
      ), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$evidence_review_audit <- renderText({
      review <- evidence_review_snapshot()
      jsonlite::toJSON(review$audit_record %||% list(), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$draft_persistence_summary <- renderUI({
      diagnostics <- ai_draft_mutation_diagnostics(draft_store_snapshot())
      ui_stat_grid(
        ui_stat_tile("Generated", diagnostics$drafts_generated[[1]], detail = "AI drafts"),
        ui_stat_tile("Confirmed", diagnostics$drafts_confirmed[[1]], status = if (diagnostics$drafts_confirmed[[1]] > 0L) "warning" else "neutral"),
        ui_stat_tile("Persisted", diagnostics$drafts_persisted[[1]], status = if (diagnostics$drafts_persisted[[1]] > 0L) "success" else "neutral"),
        ui_stat_tile("Rejected", diagnostics$drafts_rejected[[1]], status = if (diagnostics$drafts_rejected[[1]] > 0L) "warning" else "neutral"),
        ui_stat_tile("Undo", diagnostics$undo_available[[1]], detail = "available"),
        ui_stat_tile("Validation", diagnostics$validation_failures[[1]], detail = "failure(s)", status = if (diagnostics$validation_failures[[1]] > 0L) "error" else "success")
      )
    })

    output$draft_lifecycle_table <- renderUI({
      rows <- ai_draft_lifecycle_table(draft_store_snapshot())
      if (!nrow(rows)) {
        return(ui_empty_state("No AI drafts have been persisted.", "Confirmed draft persistence will appear here after a governed Class 3 operation."))
      }
      render_table(
        rows[, .(draft_id, draft_type, status, confirmation_status, validation_status, citations, undo_available, archive_available, updated_at)],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$draft_audit_timeline <- renderText({
      store <- draft_store_snapshot()$ai_draft_store
      jsonlite::toJSON(store$lifecycle %||% data.table::data.table(), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$mutation_governance_summary <- renderUI({
      diagnostics <- mutation_governance_diagnostics(mutation_store_snapshot())
      ui_stat_grid(
        ui_stat_tile("Mutations", diagnostics$mutations[[1]], detail = "governed"),
        ui_stat_tile("Pending", diagnostics$pending[[1]], status = if (diagnostics$pending[[1]] > 0L) "warning" else "neutral"),
        ui_stat_tile("Persisted", diagnostics$persisted[[1]], status = if (diagnostics$persisted[[1]] > 0L) "success" else "neutral"),
        ui_stat_tile("High Risk", diagnostics$high_or_critical[[1]], status = if (diagnostics$high_or_critical[[1]] > 0L) "warning" else "success"),
        ui_stat_tile("Undo", diagnostics$undo_available[[1]], detail = "available"),
        ui_stat_tile("Validation", diagnostics$validation_failures[[1]], detail = "failure(s)", status = if (diagnostics$validation_failures[[1]] > 0L) "error" else "success")
      )
    })

    output$mutation_lifecycle_table <- renderUI({
      rows <- mutation_lifecycle_table(mutation_store_snapshot())
      if (!nrow(rows)) {
        return(ui_empty_state("No governed mutations have been persisted.", "Future review requests and evidence-link drafts will appear here after confirmation."))
      }
      render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$mutation_audit_timeline <- renderText({
      store <- mutation_store_snapshot()$ai_mutation_store
      jsonlite::toJSON(store$lifecycle %||% data.table::data.table(), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$action_proposal <- renderText({
      jsonlite::toJSON(routed_snapshot()$proposal %||% list(), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$runtime_diagnostics <- renderText({
      jsonlite::toJSON(routed_snapshot()$diagnostics %||% list(), auto_unbox = TRUE, pretty = TRUE, null = "null")
    })

    output$benchmark_summary <- renderUI({
      benchmark <- run_ai_runtime_qualification_benchmark(ctx)
      render_table(
        benchmark[, .(task_family, model_tier, task_code, qualification_status, confidence, evidence_fidelity, estimated_input_tokens)],
        engine = "html"
      )
    })
  })
}

qa_ai_runtime_page <- function() {
  ui <- page_ai_runtime_ui("qa_ai_runtime")
  taxonomy <- knowledge_runtime_task_taxonomy()
  snapshot <- knowledge_runtime_developer_snapshot(user_request = "What should I do next?")
  ui_text <- paste(capture.output(print(ui)), collapse = "\n")
  has <- function(text, patterns) all(vapply(patterns, grepl, logical(1), x = text, fixed = TRUE))
  data.table::data.table(
    check = c("page_ui", "task_choices", "developer_snapshot", "benchmark_available", "qualification_visible", "retrieval_visible", "synthesis_visible", "evidence_review_visible", "draft_persistence_visible", "mutation_governance_visible"),
    status = c(
      if (inherits(ui, "shiny.tag")) "success" else "error",
      if (all(c("recommend_supported_next_action", "open_artifact", "create_review_draft", "review_evidence_and_recommend_next_action") %in% taxonomy$task_code)) "success" else "error",
      if (length(snapshot$diagnostics %||% list()) && nzchar(snapshot$context_hash %||% "")) "success" else "error",
      if (nrow(run_ai_runtime_qualification_benchmark()) >= 10L) "success" else "error",
      if (nzchar(snapshot$qualification %||% "")) "success" else "error",
      if (identical(qa_artifact_progressive_retrieval()[check == "progressive_expansion"]$status[[1]], "success")) "success" else "error",
      if (identical(qa_cross_artifact_synthesis()[check == "structured_synthesis"]$status[[1]], "success")) "success" else "error",
      if (identical(qa_ai_operated_evidence_review()[check == "ai_runtime_integration_data"]$status[[1]], "success")) "success" else "error",
      if (has(ui_text, c("Confirmed Draft Persistence", "draft_persistence_summary", "draft_lifecycle_table"))) "success" else "error",
      if (has(ui_text, c("Mutation Governance", "mutation_governance_summary", "mutation_lifecycle_table"))) "success" else "error"
    ),
    message = c(
      "AI Runtime page UI renders.",
      "Developer page task controls include Phase 2 tasks.",
      "Developer snapshot exposes diagnostics and context hash.",
      "Qualification benchmark fixtures are available for display.",
      "Developer snapshot exposes current qualification status.",
      "AI Runtime page can display progressive retrieval diagnostics.",
      "AI Runtime page can display cross-artifact synthesis diagnostics.",
      "AI Runtime page can display governed evidence-review diagnostics.",
      "AI Runtime page exposes confirmed draft lifecycle, undo/archive availability, and audit timeline.",
      "AI Runtime page exposes mutation classification, risk, governance, lifecycle, and audit state."
    )
  )
}
