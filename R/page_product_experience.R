page_product_experience_ui <- function(id) {
  ns <- NS(id)
  worlds <- product_experience_world_registry()
  scenarios <- product_experience_scenario_registry()

  tabPanel(
    "Product Experience",
    value = "product_experience",
    ui_page(
      title = "Product Experience Lab",
      subtitle = "Deterministic worlds, scenarios, review artifacts, and workflow evidence for improving the workstation experience.",
      eyebrow = "Developer",
      actions = ui_action_row(
        actionButton(ns("run_golden"), "Run Golden Workflow", class = "btn-primary"),
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
            title = "Golden Replay",
            subtitle = "Replay package, recorder state, screenshot chapters, video, trace, and regression status.",
            uiOutput(ns("golden_replay")),
            uiOutput(ns("golden_regression"))
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
