page_product_experience_ui <- function(id) {
  ns <- NS(id)
  worlds <- product_experience_world_registry()
  scenarios <- product_experience_scenario_registry()
  relationship_states <- relationship_state_registry()

  tabPanel(
    "Product Experience",
    value = "product_experience",
    ui_page(
      title = "Product Experience Lab",
      subtitle = "Deterministic worlds, scenarios, review artifacts, and workflow evidence for improving the workstation experience.",
      eyebrow = "Developer",
      actions = ui_action_row(
        actionButton(ns("run_golden"), "Run Golden Workflow", class = "btn-primary"),
        actionButton(ns("run_prototype_replays"), "Run Prototype Replays", class = "btn-primary"),
        actionButton(ns("run_phase3_browser_trial"), "Run Phase 3 Browser Trial", class = "btn-primary"),
        actionButton(ns("run_browser_replay"), "Run Browser Replay", class = "btn-primary"),
        actionButton(ns("run_fixture"), "Run Fixture Scenario", class = "btn-primary"),
        actionButton(ns("refresh"), "Refresh")
      ),
      ui_workspace_grid(
        columns = "main-sidebar",
        tagList(
          tags$div(`data-testid` = "product-experience-world"),
          ui_card(
            title = "Architecture Decision",
            subtitle = "Phase 1 selects one browser automation path and keeps fixture validation honest.",
            uiOutput(ns("architecture_decision"))
          ),
          ui_card(
            title = "Golden Workflow",
            subtitle = "The canonical product benchmark: business question to persisted governed draft.",
            uiOutput(ns("golden_workflow")),
            uiOutput(ns("golden_steps"))
          ),
          ui_card(
            title = "UX Iteration Passes",
            subtitle = "The recording loop drives focused improvements instead of whole-app cosmetic wandering.",
            uiOutput(ns("ux_iteration_passes"))
          ),
          ui_card(
            title = "Golden Workflow Review",
            subtitle = "Step-by-step understanding, action, friction, cognitive load, and campaign mapping.",
            uiOutput(ns("workflow_review"))
          ),
          ui_card(
            title = "Golden Replay",
            subtitle = "Replay package, recorder state, screenshot chapters, video, trace, and regression status.",
            uiOutput(ns("golden_replay")),
            uiOutput(ns("golden_regression")),
            uiOutput(ns("replay_metrics")),
            uiOutput(ns("replay_comparison"))
          ),
          ui_card(
            title = "Browser Runtime",
            subtitle = "Repo-local Node, npm, Playwright, Chromium, validation screenshot, and generated recordings.",
            uiOutput(ns("browser_runtime")),
            uiOutput(ns("browser_replay_status"))
          ),
          ui_card(
            title = "External Media Governance",
            subtitle = "Bulky recordings are generated outside the source repository by default.",
            uiOutput(ns("media_governance"))
          ),
          ui_card(
            title = "Investor Showcase Candidate",
            subtitle = "The flagship world is chosen for visible evidence progression rather than marketing gloss.",
            uiOutput(ns("showcase_candidate")),
            uiOutput(ns("showcase_evidence"))
          ),
          ui_card(
            title = "Canonical Worlds",
            subtitle = "App-facing worlds. Hidden truth is intentionally excluded from this table.",
            uiOutput(ns("worlds"))
          ),
          ui_card(
            title = "Scenario Contract",
            subtitle = "Select a workflow scenario and inspect the deterministic contract.",
            selectInput(
              ns("scenario_id"),
              "Scenario",
              choices = stats::setNames(scenarios$scenario_id, scenarios$title),
              selected = scenarios$scenario_id[[1]]
            ),
            uiOutput(ns("scenario_contract"))
          ),
          tags$div(`data-testid` = "product-experience-scenario"),
          ui_card(
            title = "Latest Fixture Run",
            subtitle = "Fixture mode validates the contract without fabricating screenshots, video, or trace.",
            uiOutput(ns("latest_run")),
            uiOutput(ns("metrics"))
          ),
          tags$div(`data-testid` = "product-experience-run"),
          ui_card(
            title = "Review Artifact",
            subtitle = "Human review findings become structured product evidence and campaign seeds.",
            uiOutput(ns("review_summary")),
            uiOutput(ns("campaign_seeds"))
          ),
          ui_card(
            title = "Founder Review Findings",
            subtitle = "Founder observations become structured evidence for UX campaigns.",
            uiOutput(ns("founder_review"))
          ),
          ui_card(
            title = "UX Campaign Priority",
            subtitle = "Campaigns are ranked by user, commercial, scientific, effort, risk, and expected UX improvement.",
            uiOutput(ns("ux_campaign_priority"))
          ),
          ui_card(
            title = "Research Mode",
            subtitle = "Phase 6 treats the current Golden Workflow as a benchmark, not a conclusion.",
            uiOutput(ns("research_mode_principles"))
          ),
          ui_card(
            title = "Experience Hypotheses",
            subtitle = "Competing information architectures to test before converging.",
            uiOutput(ns("experience_hypotheses"))
          ),
          ui_card(
            title = "Prototype Comparison",
            subtitle = "Intent-first and business-question-first are next research candidates.",
            uiOutput(ns("prototype_comparison"))
          ),
          ui_card(
            title = "Experience Runtime",
            subtitle = "Compiles user intent into prototype-specific entry, routing, visibility, and AI behavior.",
            uiOutput(ns("experience_runtime"))
          ),
          ui_card(
            title = "Compiled Experience",
            subtitle = "The selected philosophy changes presentation only; architecture and workflow remain constant.",
            selectInput(
              ns("experience_prototype_id"),
              "Prototype",
              choices = stats::setNames(experience_prototype_registry()$prototype_id, experience_prototype_registry()$prototype_name),
              selected = "prototype_a_intent_first"
            ),
            selectInput(
              ns("experience_intent_id"),
              "Intent",
              choices = stats::setNames(experience_intent_registry()$intent_id, experience_intent_registry()$label),
              selected = "decide"
            ),
            uiOutput(ns("compiled_experience"))
          ),
          ui_card(
            title = "Relationship Runtime",
            subtitle = "Phase 4 determines how the product begins for different user relationships without replacing production.",
            selectInput(
              ns("relationship_state"),
              "Relationship State",
              choices = stats::setNames(relationship_states$relationship_state, relationship_states$label),
              selected = "new_user"
            ),
            uiOutput(ns("relationship_runtime_preview"))
          ),
          ui_card(
            title = "Progressive Experience Shell",
            subtitle = "Only immediate information appears first; deeper surfaces unlock as intent, evidence, and decision context emerge.",
            uiOutput(ns("relationship_shell_preview"))
          ),
          ui_card(
            title = "Working Context Preview",
            subtitle = "Phase 5 shifts meaningful work from modules into the Evidence Review / Decision Evaluation context.",
            uiOutput(ns("working_context_preview"))
          ),
          ui_card(
            title = "Progressive Workspace Depth",
            subtitle = "Question, evidence, reasoning, diagnostics, and architecture unfold as the work deepens.",
            uiOutput(ns("working_context_depth"))
          ),
          ui_card(
            title = "Prototype Entry Experience",
            subtitle = "Phase 2 compares the first interaction while holding workflow, evidence, decision, and artifacts constant.",
            uiOutput(ns("prototype_entry_experience"))
          ),
          ui_card(
            title = "Prototype Replay Package",
            subtitle = "Current, Intent-first, and Business-question-first replay packages share one Golden Workflow.",
            uiOutput(ns("prototype_replay_package"))
          ),
          ui_card(
            title = "Phase 3 Browser Trial",
            subtitle = "Browser-recorded Current, Intent-first, and Business Question first experiences.",
            uiOutput(ns("phase3_browser_trial"))
          ),
          ui_card(
            title = "Founder Experience Review",
            subtitle = "Reviewer prompts preserve strengths, weaknesses, delight, confusion, trust, recommendation, and open questions.",
            uiOutput(ns("founder_experience_review"))
          ),
          ui_card(
            title = "Visible Element Inventory",
            subtitle = "Classifies what should show, summarize, collapse, or disappear.",
            uiOutput(ns("visible_element_inventory"))
          )
        ),
        tagList(
          tags$div(`data-testid` = "product-experience-review"),
          ui_card(
            title = "Mode Disclosure",
            subtitle = "Fixture, live, and replay AI are separate modes and must be labeled.",
            uiOutput(ns("ai_modes"))
          ),
          ui_card(
            title = "Showcase Ranking",
            subtitle = "Candidate worlds are scored for story clarity, evidence richness, governance visibility, and demo value.",
            uiOutput(ns("candidate_ranking"))
          ),
          ui_card(
            title = "Investor Promotion Gate",
            subtitle = "No video is investor_candidate until the unedited workflow passes every gate.",
            uiOutput(ns("promotion_gate"))
          ),
          ui_card(
            title = "Final Assessment",
            subtitle = "Current classification of the canonical workflow.",
            uiOutput(ns("final_assessment"))
          ),
          ui_card(
            title = "Information Exposure",
            subtitle = "Essential, helpful, contextual, advanced, architectural, and developer surfaces.",
            uiOutput(ns("information_exposure"))
          ),
          ui_card(
            title = "Progressive Disclosure",
            subtitle = "The proposed visibility ladder from orientation to architecture.",
            uiOutput(ns("progressive_disclosure"))
          ),
          ui_card(
            title = "AI Role Assessment",
            subtitle = "Where AI should add reasoning and where deterministic UX should replace it.",
            uiOutput(ns("ai_role_assessment"))
          ),
          ui_card(
            title = "Research Campaigns",
            subtitle = "Next lightweight prototypes to compare against the Golden Workflow benchmark.",
            uiOutput(ns("research_campaigns"))
          ),
          ui_card(
            title = "Runtime Comparison",
            subtitle = "Baseline, intent-first, and business-question-first compiled through one runtime contract.",
            uiOutput(ns("runtime_comparison"))
          ),
          ui_card(
            title = "Relationship Comparison",
            subtitle = "Compares first-hour behavior across new, returning, current-project, resume, explore, and learn states.",
            uiOutput(ns("relationship_comparison"))
          ),
          ui_card(
            title = "Relationship Founder Review",
            subtitle = "First-hour review dimensions: impression, trust, momentum, curiosity, confidence, overwhelm, understanding, and desired next action.",
            uiOutput(ns("relationship_founder_review"))
          ),
          ui_card(
            title = "Relationship Campaigns",
            subtitle = "Campaigns target relationship quality rather than module polish.",
            uiOutput(ns("relationship_campaigns"))
          ),
          ui_card(
            title = "Working Context Capability Map",
            subtitle = "Primary and adjacent capabilities appear first; contextual, advanced, architectural, and developer surfaces stay quiet.",
            uiOutput(ns("working_context_capability_map"))
          ),
          ui_card(
            title = "Working Context Review",
            subtitle = "Founder review asks whether the workspace preserves focus, priority, location, and next-action clarity.",
            uiOutput(ns("working_context_review"))
          ),
          ui_card(
            title = "Working Context Campaigns",
            subtitle = "Campaigns target flow-breaking exposure, transitions, hierarchy, and navigation.",
            uiOutput(ns("working_context_campaigns"))
          ),
          ui_card(
            title = "Prototype Replay Comparison",
            subtitle = "Compares Current, A, and B using the same synthetic world and Golden Workflow.",
            uiOutput(ns("prototype_replay_comparison_phase2"))
          ),
          ui_card(
            title = "Phase 3 Experience Comparison",
            subtitle = "Browser-trial comparison across philosophy, cognitive load, trust, AI, and workflow preparation.",
            uiOutput(ns("phase3_experience_comparison"))
          ),
          ui_card(
            title = "Runtime Campaigns",
            subtitle = "Campaigns are scoped to prototypes rather than broad polishing.",
            uiOutput(ns("runtime_campaigns"))
          ),
          ui_card(
            title = "Phase 2 Recommendation",
            subtitle = "Conservative product guidance: compare before selecting a final experience.",
            uiOutput(ns("phase2_recommendation"))
          ),
          ui_card(
            title = "Phase 3 Final Assessment",
            subtitle = "Direct answers remain evidence-bound and avoid premature product-philosophy selection.",
            uiOutput(ns("phase3_final_assessment"))
          ),
          ui_card(
            title = "Open UX Questions",
            subtitle = "Current answers, uncertainty, and next experiments.",
            uiOutput(ns("research_open_questions"))
          ),
          ui_card(
            title = "Stable Selectors",
            subtitle = "Automation should use semantic data-testid contracts rather than brittle CSS selectors.",
            uiOutput(ns("selectors"))
          ),
          ui_card(
            title = "Recorder Status",
            subtitle = "Playwright is the selected recorder path. Phase 1 reports availability instead of hiding gaps.",
            uiOutput(ns("recorder_status"))
          )
        )
      )
    )
  )
}

page_product_experience_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    latest_run <- reactiveVal(NULL)
    latest_golden <- reactiveVal(NULL)
    latest_browser <- reactiveVal(NULL)
    latest_review <- reactiveVal(NULL)
    latest_prototype_replays <- reactiveVal(NULL)
    latest_phase3_trial <- reactiveVal(NULL)

    output$architecture_decision <- renderUI({
      decision <- product_experience_architecture_decision()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Decision"), tags$span(decision$decision)),
        tags$div(class = "aq-status-item", tags$strong("Recorder"), tags$span(decision$selected_automation)),
        tags$div(class = "aq-status-item", tags$strong("Fixture Runner"), tags$span(decision$fixture_runner)),
        tags$div(class = "aq-status-item", tags$strong("Limitation"), tags$span(decision$limitation))
      )
    })

    output$golden_workflow <- renderUI({
      workflow <- product_experience_golden_workflow()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Question"), tags$span(workflow$guiding_question)),
        tags$div(class = "aq-status-item", tags$strong("Story"), tags$span(workflow$product_story)),
        tags$div(class = "aq-status-item", tags$strong("Success"), tags$span(workflow$success_statement))
      )
    })

    output$golden_steps <- renderUI({
      render_table(
        product_experience_golden_workflow()$steps[, c("step_id", "chapter", "expected_page", "expected_validation", "deterministic_replacement_candidate"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$ux_iteration_passes <- renderUI({
      passes <- product_experience_ux_iteration_passes()
      render_table(
        passes[, c("pass_name", "purpose", "primary_question", "scope_rule"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$workflow_review <- renderUI({
      review <- product_experience_golden_workflow_review()
      render_table(
        review[, c("step", "expected_understanding", "expected_action", "current_friction", "cognitive_load", "severity", "campaign_id"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    observeEvent(input$run_golden, {
      result <- product_experience_run_golden_workflow(automation = "fixture", ai_mode = "fixture")
      latest_golden(result$value)
      if (!is.null(result$value)) {
        latest_review(product_experience_review_artifact(
          list(
            scenario_id = result$value$scenario_id,
            screenshots = result$value$chapters,
            ai_mode = result$value$ai_mode,
            automation = result$value$automation
          ),
          reviewer = "golden_fixture_reviewer",
          findings = product_experience_golden_review_findings()
        ))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$run_browser_replay, {
      result <- product_experience_regenerate_golden_workflow(port = 6989, ai_mode = "fixture")
      latest_browser(result)
      if (identical(result$status, "success")) {
        latest_golden(result$value)
        latest_review(product_experience_review_artifact(
          list(
            scenario_id = result$value$scenario_id,
            screenshots = result$value$chapters,
            ai_mode = result$value$ai_mode,
            automation = result$value$automation
          ),
          reviewer = "golden_browser_reviewer",
          findings = product_experience_golden_review_findings()
        ))
      }
    }, ignoreInit = TRUE)

    observeEvent(input$run_prototype_replays, {
      result <- experience_run_all_prototype_replays(write_files = TRUE)
      latest_prototype_replays(result$value)
    }, ignoreInit = TRUE)

    observeEvent(input$run_phase3_browser_trial, {
      result <- experience_run_phase3_browser_trial(port = 6993, ai_mode = "fixture", pacing_profile = "investor")
      latest_phase3_trial(result$value)
    }, ignoreInit = TRUE)

    output$golden_replay <- renderUI({
      run <- latest_golden()
      if (is.null(run)) {
        return(ui_empty_state("No Golden Workflow replay yet.", "Run the Golden Workflow to generate a deterministic replay package."))
      }
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Run"), tags$span(run$run_id)),
        tags$div(class = "aq-status-item", tags$strong("Recorder"), tags$span(run$recorder_status)),
        tags$div(class = "aq-status-item", tags$strong("Manifest"), tags$span(run$manifest_path)),
        tags$div(class = "aq-status-item", tags$strong("Review Package"), tags$span(run$review_package_path)),
        tags$div(class = "aq-status-item", tags$strong("Video"), tags$span(run$video_path %||% "not captured")),
        tags$div(class = "aq-status-item", tags$strong("Trace"), tags$span(run$trace_path %||% "not captured"))
      )
    })

    output$golden_regression <- renderUI({
      run <- latest_golden()
      if (is.null(run)) {
        return(NULL)
      }
      render_table(product_experience_compare_regression(run), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$replay_metrics <- renderUI({
      run <- latest_golden()
      if (is.null(run)) {
        return(ui_empty_state("No replay metrics yet.", "Run the Golden Workflow or Browser Replay to populate UX metrics."))
      }
      render_table(product_experience_replay_metrics_summary(run), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$replay_comparison <- renderUI({
      run <- latest_golden()
      if (is.null(run)) {
        return(NULL)
      }
      render_table(product_experience_compare_replay_runs(run), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$browser_runtime <- renderUI({
      discovery <- product_experience_runtime_discovery()
      render_table(discovery, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$browser_replay_status <- renderUI({
      result <- latest_browser()
      if (is.null(result)) {
        return(ui_empty_state("No browser replay has been run in this session.", "Run Browser Replay to provision/validate the runtime and record the Golden Workflow."))
      }
      if (!identical(result$status, "success")) {
        return(tags$div(
          class = "aq-status-list",
          tags$div(class = "aq-status-item", tags$strong("Status"), tags$span(result$status)),
          tags$div(class = "aq-status-item", tags$strong("Classification"), tags$span(paste(result$errors, collapse = "; "))),
          tags$div(class = "aq-status-item", tags$strong("Run Directory"), tags$span(result$metadata$run_dir %||% "not written")),
          tags$div(class = "aq-status-item", tags$strong("Report"), tags$span(result$metadata$report_path %||% "not written"))
        ))
      }
      run <- result$value
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Status"), tags$span("Golden Workflow completed")),
        tags$div(class = "aq-status-item", tags$strong("Screenshots"), tags$span(nrow(run$chapters))),
        tags$div(class = "aq-status-item", tags$strong("Verification"), tags$span(run$verification$status %||% "unknown")),
        tags$div(class = "aq-status-item", tags$strong("Video"), tags$a(href = product_experience_file_url(run$video_path), target = "_blank", "Open GoldenWorkflow.webm")),
        tags$div(class = "aq-status-item", tags$strong("Trace"), tags$a(href = product_experience_file_url(run$trace_path), target = "_blank", "Open trace.zip")),
        tags$div(class = "aq-status-item", tags$strong("Screenshots"), tags$a(href = product_experience_file_url(dirname(run$chapters$screenshot_path[[1]])), target = "_blank", "Open screenshot folder")),
        tags$div(class = "aq-status-item", tags$strong("Report"), tags$a(href = product_experience_file_url(run$manifest_path), target = "_blank", "Open execution report")),
        tags$div(class = "aq-status-item", tags$strong("Review Package"), tags$a(href = product_experience_file_url(run$review_package_path), target = "_blank", "Open review package"))
      )
    })

    output$media_governance <- renderUI({
      validation <- product_experience_media_root_validation()
      dirs <- product_experience_media_dirs(create = TRUE)
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Media Root"), tags$span(dirs$media_root)),
        tags$div(class = "aq-status-item", tags$strong("Runs"), tags$span(dirs$runs)),
        tags$div(class = "aq-status-item", tags$strong("Lifecycle"), tags$span(paste(product_experience_media_lifecycle_states()$lifecycle_state, collapse = " -> "))),
        render_table(validation, engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$showcase_candidate <- renderUI({
      world <- product_experience_flagship_world()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("World"), tags$span(world$title)),
        tags$div(class = "aq-status-item", tags$strong("Business Question"), tags$span(world$business_question)),
        tags$div(class = "aq-status-item", tags$strong("Objective"), tags$span(world$public_objective)),
        tags$div(class = "aq-status-item", tags$strong("Hidden Truth Policy"), tags$span(world$hidden_truth_policy))
      )
    })

    output$showcase_evidence <- renderUI({
      evidence <- product_experience_flagship_evidence_package()
      visible <- evidence$visible_evidence
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Descriptive Evidence"), tags$span(visible$descriptive)),
        tags$div(class = "aq-status-item", tags$strong("Guardrail"), tags$span(visible$guardrail)),
        tags$div(class = "aq-status-item", tags$strong("Governed Next Action"), tags$span(visible$governed_next_action)),
        tags$div(class = "aq-callout aq-callout-info", tags$strong("Limitations"), tags$ul(lapply(evidence$limitations, tags$li)))
      )
    })

    output$worlds <- renderUI({
      worlds <- product_experience_world_registry()
      render_table(worlds[, c("world_id", "title", "workflow_variant", "public_objective"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$scenario_contract <- renderUI({
      scenarios <- product_experience_scenario_registry()
      scenario <- scenarios[scenarios$scenario_id == input$scenario_id, , drop = FALSE]
      if (nrow(scenario) == 0) {
        return(ui_empty_state("No scenario selected.", "Choose a scenario to inspect its contract."))
      }
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Audience"), tags$span(scenario$audience)),
        tags$div(class = "aq-status-item", tags$strong("Entry Point"), tags$span(scenario$entry_point)),
        tags$div(class = "aq-status-item", tags$strong("Duration"), tags$span(paste0(scenario$estimated_duration_min, " minutes"))),
        tags$div(class = "aq-status-item", tags$strong("Completion"), tags$span(scenario$expected_completion)),
        tags$div(
          class = "aq-callout aq-callout-info",
          tags$strong("Steps"),
          tags$ol(lapply(scenario$steps[[1]], tags$li))
        )
      )
    })

    observeEvent(input$run_fixture, {
      result <- product_experience_run_scenario(
        input$scenario_id %||% "scenario_world_01",
        automation = "fixture",
        ai_mode = "fixture"
      )
      if (identical(result$status, "success")) {
        latest_run(result$value)
        findings <- data.frame(
          issue_id = "px_review_placeholder",
          category = "friction",
          severity = "low",
          description = "Fixture run created a reviewable workflow trace. Human reviewer should replace this placeholder after visual review.",
          recommendation = "Review the recorded workflow and preserve real friction in the artifact.",
          screenshot_id = "status",
          video_timestamp = NA_character_,
          campaign_candidate = TRUE,
          stringsAsFactors = FALSE
        )
        latest_review(product_experience_review_artifact(result$value, reviewer = "fixture_reviewer", findings = findings))
      }
    }, ignoreInit = TRUE)

    output$latest_run <- renderUI({
      run <- latest_run()
      if (is.null(run)) {
        return(ui_empty_state("No fixture run yet.", "Run a fixture scenario to create deterministic workflow evidence."))
      }
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Run"), tags$span(run$run_id)),
        tags$div(class = "aq-status-item", tags$strong("Automation"), tags$span(run$automation)),
        tags$div(class = "aq-status-item", tags$strong("AI Mode"), tags$span(run$ai_mode)),
        tags$div(class = "aq-status-item", tags$strong("Video"), tags$span(run$video_status)),
        tags$div(class = "aq-status-item", tags$strong("Trace"), tags$span(run$trace_status))
      )
    })

    output$metrics <- renderUI({
      run <- latest_run()
      if (is.null(run)) {
        return(ui_empty_state("No metrics yet.", "Run a fixture scenario to populate workflow metrics."))
      }
      render_table(product_experience_metrics_summary(run), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$review_summary <- renderUI({
      review <- latest_review()
      if (is.null(review)) {
        return(ui_empty_state("No review artifact yet.", "Run a fixture scenario, then replace the placeholder review with real human findings."))
      }
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Artifact"), tags$span(review$artifact_id)),
        tags$div(class = "aq-status-item", tags$strong("Type"), tags$span(review$artifact_type)),
        tags$div(class = "aq-status-item", tags$strong("Reviewer"), tags$span(review$content$reviewer)),
        tags$div(class = "aq-status-item", tags$strong("Hidden Truth Included"), tags$span(as.character(review$metadata$hidden_truth_included)))
      )
    })

    output$campaign_seeds <- renderUI({
      review <- latest_review()
      if (is.null(review)) {
        return(ui_empty_state("No campaign seeds yet.", "Review findings marked as campaign candidates will appear here."))
      }
      seeds <- product_experience_campaign_seeds(review)
      if (!nrow(seeds)) {
        return(ui_empty_state("No campaign seeds.", "This review has no campaign candidates."))
      }
      render_table(seeds, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$founder_review <- renderUI({
      run <- latest_golden()
      findings <- product_experience_founder_review_template(run = run, reviewer = "founder")
      render_table(
        findings[, c("workflow_step", "category", "severity", "finding", "recommendation", "campaign_id", "status"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$ux_campaign_priority <- renderUI({
      campaigns <- product_experience_prioritize_ux_campaigns(product_experience_founder_review_template(run = latest_golden(), reviewer = "founder"))
      render_table(
        campaigns[, c("campaign_id", "category", "severity", "priority_score", "recommendation", "expected_ux_improvement", "dependencies"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$research_mode_principles <- renderUI({
      render_table(
        product_experience_research_mode_principles(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$experience_hypotheses <- renderUI({
      hypotheses <- product_experience_experience_hypotheses()
      render_table(
        hypotheses[, c("hypothesis", "opening_prompt", "flow", "current_recommendation", "primary_risk"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$prototype_comparison <- renderUI({
      comparison <- product_experience_prototype_comparison()
      render_table(
        comparison[, c("prototype_name", "entry_surface", "default_visible_level", "learning_score", "prototype_status", "success_metric"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$experience_runtime <- renderUI({
      registry <- experience_prototype_registry()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Runtime"), tags$span("Product Experience Runtime")),
        tags$div(class = "aq-status-item", tags$strong("Rule"), tags$span("One architecture, multiple compiled experiences.")),
        render_table(
          registry[, c("prototype_name", "philosophy", "entry_prompt", "mission_control_behavior", "ai_visibility", "prototype_status"), drop = FALSE],
          engine = "html",
          searchable = FALSE,
          sortable = FALSE
        )
      )
    })

    output$compiled_experience <- renderUI({
      compiled <- experience_compiler(input$experience_prototype_id %||% "prototype_a_intent_first", intent = input$experience_intent_id %||% "decide")
      summary <- data.frame(
        item = c("Prototype", "Intent", "Start Surface", "Workflow", "Architecture", "AI Entry Visibility"),
        value = c(
          compiled$prototype$prototype_name[[1]],
          compiled$intent$intent_label[[1]],
          compiled$intent$start_surface[[1]],
          compiled$workflow$workflow_id,
          if (isTRUE(compiled$controls$architecture_unchanged)) "unchanged" else "changed",
          compiled$ai_plan$visibility[[1]]
        ),
        stringsAsFactors = FALSE
      )
      tags$div(
        class = "aq-status-list",
        render_table(summary, engine = "html", searchable = FALSE, sortable = FALSE),
        ui_section_header("Visible Now", paste(compiled$information_plan$component[compiled$information_plan$visibility == "immediate"], collapse = ", ")),
        ui_section_header("Deferred / Hidden", paste(compiled$information_plan$component[compiled$information_plan$visibility != "immediate"], collapse = ", ")),
        render_table(compiled$navigation_plan, engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$relationship_runtime_preview <- renderUI({
      runtime <- relationship_runtime(input$relationship_state %||% "new_user")
      if (!identical(runtime$status, "success")) {
        return(ui_empty_state("Relationship Runtime unavailable.", paste(runtime$errors, collapse = "; ")))
      }
      value <- runtime$value
      summary <- data.frame(
        item = c("State", "Opening Question", "Production Replacement", "Mission Control", "AI"),
        value = c(
          value$relationship_state$label[[1]],
          value$relationship_state$first_question[[1]],
          as.character(value$production_replacement),
          value$mission_control_policy$answer[[1]],
          value$ai_policy$answer[[1]]
        ),
        stringsAsFactors = FALSE
      )
      tags$div(
        class = "aq-status-list",
        render_table(summary, engine = "html", searchable = FALSE, sortable = FALSE),
        ui_section_header("Immediate User Questions", paste(value$shell_preview$zone[value$shell_preview$visibility_class == "Immediate"], collapse = ", "))
      )
    })

    output$relationship_shell_preview <- renderUI({
      state <- input$relationship_state %||% "new_user"
      runtime <- relationship_runtime(state)$value
      tags$div(
        class = "aq-status-list",
        render_table(runtime$shell_preview, engine = "html", searchable = FALSE, sortable = FALSE),
        ui_section_header("Progression", paste(runtime$progressive_shell$stage, collapse = " -> ")),
        render_table(
          runtime$progressive_shell[, c("stage", "user_need", "initial_visibility", "shell_behavior"), drop = FALSE],
          engine = "html",
          searchable = FALSE,
          sortable = FALSE
        )
      )
    })

    output$working_context_preview <- renderUI({
      context <- working_context_build_evidence_review()
      summary <- data.frame(
        item = c("Context", "Business Question", "Evidence Sufficiency", "Supported Next Action", "Production Slice"),
        value = c(
          context$label,
          context$business_question,
          paste0(context$evidence_sufficiency$status[[1]], " (", context$evidence_sufficiency$score[[1]], "%)"),
          context$supported_next_action,
          as.character(working_context_registry()$production_slice[[1]])
        ),
        stringsAsFactors = FALSE
      )
      render_table(summary, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$working_context_depth <- renderUI({
      render_table(working_context_progressive_depth(), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$prototype_entry_experience <- renderUI({
      entry <- experience_prototype_entry_experience(input$experience_prototype_id %||% "prototype_a_intent_first")
      render_table(entry, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$prototype_replay_package <- renderUI({
      replays <- latest_prototype_replays()
      if (is.null(replays)) {
        preview <- experience_prototype_replay_package(input$experience_prototype_id %||% "prototype_a_intent_first", write_files = FALSE)$value
        summary <- data.frame(
          item = c("Prototype", "Recorder", "Workflow", "Manifest", "Review Package", "Replay Quality"),
          value = c(
            preview$prototype_name,
            preview$recorder_status,
            preview$workflow$workflow_id,
            "not written in preview",
            "not written in preview",
            preview$metrics$replay_quality[[1]]
          ),
          stringsAsFactors = FALSE
        )
        return(tags$div(
          class = "aq-status-list",
          ui_empty_state("Prototype replay preview.", "Click Run Prototype Replays to write Current, A, and B packages."),
          render_table(summary, engine = "html", searchable = FALSE, sortable = FALSE)
        ))
      }
      rows <- do.call(rbind, lapply(replays, function(x) {
        data.frame(
          prototype = x$prototype_name,
          run_id = x$run_id,
          recorder = x$recorder_status,
          manifest = x$manifest_path,
          review_package = x$review_package_path,
          stringsAsFactors = FALSE
        )
      }))
      render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$phase3_browser_trial <- renderUI({
      trial <- latest_phase3_trial()
      if (is.null(trial)) {
        prototypes <- experience_phase3_trial_prototypes()
        return(tags$div(
          class = "aq-status-list",
          ui_empty_state("No Phase 3 browser trial yet.", "Click Run Phase 3 Browser Trial to record Current, Intent-first, and Business Question first experiences."),
          render_table(prototypes[, c("replay_id", "prototype_label", "hypothesis", "allowed_difference"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
        ))
      }
      rows <- do.call(rbind, lapply(trial$results, function(result) {
        run <- result$value
        data.frame(
          replay = run$replay_id %||% run$prototype_id %||% "unknown",
          prototype = run$prototype_name %||% "unavailable",
          status = result$status,
          video = run$video_path %||% NA_character_,
          trace = run$trace_path %||% NA_character_,
          review_package = run$review_package_path %||% NA_character_,
          stringsAsFactors = FALSE
        )
      }))
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Trial"), tags$span(trial$trial_id)),
        tags$div(class = "aq-status-item", tags$strong("Summary"), tags$span(trial$summary_path %||% "")),
        render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$founder_experience_review <- renderUI({
      replays <- latest_prototype_replays()
      founder <- experience_founder_review_package(replays)
      render_table(
        founder[, c("prototype_name", "strengths", "weaknesses", "delight", "confusion", "trust", "recommendation", "open_questions"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$visible_element_inventory <- renderUI({
      render_table(
        product_experience_visible_element_inventory(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$ai_modes <- renderUI({
      render_table(product_experience_ai_modes()[, c("ai_mode", "label", "allowed_for_qa", "description"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$candidate_ranking <- renderUI({
      render_table(product_experience_showcase_candidate_ranking(), engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$promotion_gate <- renderUI({
      run <- latest_golden()
      gate <- product_experience_assess_investor_candidate(
        run = run,
        findings = if (!is.null(latest_review())) latest_review()$content$recommended_changes else NULL,
        founder_approved = FALSE,
        developer_content_visible = TRUE
      )
      state <- attr(gate, "promotion_state") %||% "awaiting_review"
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Promotion State"), tags$span(state)),
        tags$div(class = "aq-status-item", tags$strong("Rule"), tags$span("Founder approval and no blockers are required before investor_candidate.")),
        render_table(gate[, c("criterion", "status", "observed_value", "failure_action"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$final_assessment <- renderUI({
      assessment <- product_experience_final_assessment(
        run = latest_golden(),
        founder_approved = FALSE,
        developer_content_visible = TRUE
      )
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Classification"), tags$span(assessment$classification)),
        tags$div(class = "aq-status-item", tags$strong("Promotion State"), tags$span(assessment$promotion_state)),
        tags$div(class = "aq-status-item", tags$strong("Coherence"), tags$span(assessment$does_workflow_feel_more_coherent)),
        tags$div(class = "aq-status-item", tags$strong("Business Story"), tags$span(assessment$is_business_story_obvious)),
        tags$div(class = "aq-status-item", tags$strong("Largest Weakness"), tags$span(assessment$largest_ux_weakness))
      )
    })

    output$information_exposure <- renderUI({
      render_table(
        product_experience_information_exposure_taxonomy(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$progressive_disclosure <- renderUI({
      render_table(
        product_experience_progressive_disclosure_strategy(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$ai_role_assessment <- renderUI({
      render_table(
        product_experience_ai_role_assessment(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$research_campaigns <- renderUI({
      render_table(
        product_experience_research_campaigns(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$runtime_comparison <- renderUI({
      comparison <- experience_compare_compiled_prototypes()
      render_table(
        comparison[, c("prototype_name", "entry_prompt", "start_surface", "time_to_first_meaningful_action_sec", "estimated_clicks", "navigation_depth", "ai_interactions", "cognitive_load_estimate", "comparison_note"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$relationship_comparison <- renderUI({
      render_table(
        relationship_runtime_comparison(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$relationship_founder_review <- renderUI({
      render_table(
        relationship_founder_review_template(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$relationship_campaigns <- renderUI({
      tags$div(
        class = "aq-status-list",
        render_table(relationship_campaigns(), engine = "html", searchable = FALSE, sortable = FALSE),
        ui_section_header("Open Product Question", relationship_final_assessment()$answer[relationship_final_assessment()$question == "What is the largest unanswered product question?"][[1]])
      )
    })

    output$working_context_capability_map <- renderUI({
      render_table(
        working_context_capability_map()[, c("capability", "exposure", "initial_visibility", "reason"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$working_context_review <- renderUI({
      tags$div(
        class = "aq-status-list",
        render_table(working_context_founder_review_template(), engine = "html", searchable = FALSE, sortable = FALSE),
        ui_disclosure(
          "Replay Contract",
          render_table(working_context_replay_contract(), engine = "html", searchable = FALSE, sortable = FALSE),
          open = FALSE
        )
      )
    })

    output$working_context_campaigns <- renderUI({
      tags$div(
        class = "aq-status-list",
        render_table(working_context_campaigns(), engine = "html", searchable = FALSE, sortable = FALSE),
        ui_disclosure(
          "Final Assessment",
          render_table(working_context_final_assessment(), engine = "html", searchable = FALSE, sortable = FALSE),
          open = FALSE
        )
      )
    })

    output$prototype_replay_comparison_phase2 <- renderUI({
      comparison <- experience_compare_prototype_replays(latest_prototype_replays())
      render_table(
        comparison[, c("prototype_name", "entry_prompt", "time_to_first_action_sec", "time_to_first_evidence_sec", "time_to_first_understanding_sec", "clicks", "context_switches", "visible_concepts", "reading_burden", "strength_hypothesis", "risk_hypothesis"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$phase3_experience_comparison <- renderUI({
      trial <- latest_phase3_trial()
      comparison <- if (!is.null(trial) && nrow(trial$comparison)) {
        trial$comparison
      } else {
        fixture <- experience_run_all_prototype_replays(write_files = FALSE)$value
        phase2 <- experience_compare_prototype_replays(fixture)
        data.frame(
          prototype_id = phase2$prototype_id,
          prototype_name = phase2$prototype_name,
          time_to_first_action_sec = phase2$time_to_first_action_sec,
          time_to_first_evidence_sec = phase2$time_to_first_evidence_sec,
          time_to_first_insight_sec = phase2$time_to_first_understanding_sec,
          clicks = phase2$clicks,
          workflow_duration_sec = NA_integer_,
          navigation_depth = phase2$navigation_depth,
          context_switches = phase2$context_switches,
          visible_concepts = phase2$visible_concepts,
          ai_interactions = phase2$ai_interactions,
          cognitive_load_estimate = c("high", "medium", "low_medium"),
          product_identity_speed = c("Golden Workflow review", "intent choices", "business question prompt"),
          stringsAsFactors = FALSE
        )
      }
      render_table(
        comparison[, c("prototype_name", "time_to_first_action_sec", "time_to_first_evidence_sec", "time_to_first_insight_sec", "clicks", "context_switches", "visible_concepts", "ai_interactions", "cognitive_load_estimate", "product_identity_speed"), drop = FALSE],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$runtime_campaigns <- renderUI({
      render_table(
        experience_phase2_campaigns(experience_compare_prototype_replays(latest_prototype_replays())),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$phase2_recommendation <- renderUI({
      recommendation <- experience_phase2_recommendation(experience_compare_prototype_replays(latest_prototype_replays()))
      render_table(recommendation, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$phase3_final_assessment <- renderUI({
      trial <- latest_phase3_trial()
      comparison <- if (!is.null(trial) && nrow(trial$comparison)) {
        trial$comparison
      } else {
        fixture <- experience_run_all_prototype_replays(write_files = FALSE)$value
        experience_phase3_compare_browser_replays(lapply(fixture, function(x) {
          x$video_path <- NA_character_
          x$trace_path <- NA_character_
          x$recorder_status <- "fixture_contract_only"
          x
        }))
      }
      assessment <- experience_phase3_final_assessment(comparison)
      render_table(assessment, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$research_open_questions <- renderUI({
      render_table(
        product_experience_research_open_questions(),
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      )
    })

    output$selectors <- renderUI({
      render_table(product_experience_selector_registry()[, c("selector_id", "data_testid", "purpose"), drop = FALSE], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$recorder_status <- renderUI({
      available <- product_experience_playwright_available()
      tags$div(
        class = "aq-status-list",
        tags$div(class = "aq-status-item", tags$strong("Selected Recorder"), tags$span("Playwright")),
        tags$div(class = "aq-status-item", tags$strong("Runtime Available"), tags$span(if (available) "yes" else "no")),
        tags$div(class = "aq-status-item", tags$strong("Policy"), tags$span("If unavailable, do not fabricate video, trace, or screenshots."))
      )
    })
  })
}
