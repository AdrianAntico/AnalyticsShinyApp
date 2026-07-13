page_causal_intelligence_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Causal Intelligence",
    value = "Causal Intelligence",
    ui_page(
      title = "Causal Intelligence",
      subtitle = "Author causal questions, estimands, variable roles, and identification plans before estimating anything.",
      eyebrow = "Causal Planning",
      tags$div(
        class = "aq-grid aq-grid-2-1",
        tags$div(
          ui_card(
            "Causal Question",
            "Define the intervention question in decision-relative terms. This is planning only.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("causal_question_id"), "Causal Question ID", value = "cq_project_lever_outcome"),
              uiOutput(ns("decision_context_selector")),
              textInput(ns("business_objective"), "Business Objective", placeholder = "objective_growth"),
              textInput(ns("lever_id"), "Lever / Intervention ID", placeholder = "lever_paid_search_budget"),
              textInput(ns("exposure"), "Exposure / Intervention Variable", placeholder = "spend"),
              textInput(ns("outcome"), "Outcome Variable", placeholder = "revenue"),
              textInput(ns("population"), "Population", placeholder = "eligible markets"),
              textInput(ns("unit_of_analysis"), "Unit of Analysis", placeholder = "market-week"),
              textInput(ns("time_zero"), "Time Zero", placeholder = "campaign start"),
              textInput(ns("treatment_window"), "Treatment Window", placeholder = "next quarter"),
              textInput(ns("outcome_window"), "Outcome Window", placeholder = "same quarter and four-week lag"),
              textInput(ns("comparison_condition"), "Comparison Condition", placeholder = "current policy / current spend range"),
              selectInput(ns("estimand"), "Estimand", choices = c("ATE", "ATT", "ATC", "CATE", "policy_effect", "intention_to_treat", "controlled_direct_effect", "dose_response", "incremental_effect")),
              textInput(ns("effect_scale"), "Effect Scale", placeholder = "incremental revenue difference"),
              textInput(ns("target_population"), "Target Population", placeholder = "eligible markets")
            ),
            textAreaInput(ns("intervention_definition"), "Intervention Definition", rows = 2, placeholder = "increase spend from current range to proposed validated range"),
            textAreaInput(ns("assumptions"), "Identification Assumptions", rows = 2, placeholder = "observational treatment variation exists,historical pre-period is available"),
            tags$div(
              class = "aq-form-grid",
              textInput(ns("selection_mechanism"), "Selection Mechanism", placeholder = "How units enter the study population"),
              textInput(ns("measurement_mechanism"), "Measurement Mechanism", placeholder = "How exposure/outcome are measured")
            ),
            ui_action_row(
              actionButton(ns("save_question"), "Save Causal Question", class = "btn-primary"),
              actionButton(ns("assess_causal_plan"), "Assess Identification Plan", class = "btn-secondary"),
              actionButton(ns("register_causal_artifact"), "Register Planning Artifact", class = "btn-secondary")
            )
          ),
          ui_card(
            "Variable Roles",
            "Roles are question-relative. A predictor is not automatically a confounder, mediator, or causal exposure.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("role_id"), "Role ID", placeholder = "role_spend"),
              textInput(ns("role_variable"), "Variable", placeholder = "spend"),
              selectInput(ns("role"), "Causal Role", choices = c("exposure", "outcome", "confounder_candidate", "mediator_candidate", "collider_candidate", "effect_modifier", "instrument_candidate", "selection_variable", "prognostic_precision_variable", "exposure_predictor", "proxy", "surrogate_outcome", "missingness_indicator", "censoring_variable", "compliance_uptake", "competing_exposure", "spillover_interference_variable", "state_variable", "constraint", "unknown")),
              selectInput(ns("timing"), "Timing", choices = c("baseline", "pre_treatment", "contemporaneous", "post_treatment", "time_varying", "lagged", "future_known", "future_unknown", "unknown")),
              numericInput(ns("role_confidence"), "Role Confidence", value = NA, min = 0, max = 1, step = 0.05),
              selectInput(ns("adjustment_eligibility"), "Adjustment Eligibility", choices = c("unknown", "candidate", "do_not_adjust", "design_only", "depends_on_estimand"))
            ),
            textAreaInput(ns("role_rationale"), "Rationale", rows = 2),
            ui_action_row(actionButton(ns("save_role"), "Save Role", class = "btn-primary")),
            uiOutput(ns("causal_roles_table"))
          ),
          ui_card(
            "Causal Graph Assumptions",
            "Author directed assumptions explicitly. This is not automatic DAG discovery.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("relationship_id"), "Relationship ID", placeholder = "edge_spend_revenue"),
              textInput(ns("source_variable"), "Source Variable", placeholder = "spend"),
              textInput(ns("destination_variable"), "Destination Variable", placeholder = "revenue"),
              selectInput(ns("relationship_type"), "Relationship Type", choices = c("causes", "may_cause", "mediates", "modifies_effect_of", "determines_treatment_assignment", "determines_selection", "measures", "proxies", "constrains", "enables", "creates_spillover_to")),
              selectInput(ns("direction"), "Direction", choices = c("directed", "undirected", "uncertain")),
              selectInput(ns("relationship_timing"), "Timing", choices = c("baseline", "pre_treatment", "contemporaneous", "post_treatment", "time_varying", "lagged", "unknown")),
              numericInput(ns("relationship_confidence"), "Confidence", value = NA, min = 0, max = 1, step = 0.05),
              selectInput(ns("relationship_status"), "Status", choices = c("active", "retired", "disputed"))
            ),
            textAreaInput(ns("human_rationale"), "Human Rationale", rows = 2),
            ui_action_row(actionButton(ns("save_relationship"), "Save Relationship", class = "btn-primary")),
            uiOutput(ns("causal_relationships_table"))
          )
        ),
        tags$div(
          ui_card(
            "Planning Status",
            "Causal Intelligence does not estimate effects in Phase 1.",
            uiOutput(ns("causal_summary_cards")),
            verbatimTextOutput(ns("causal_message"))
          ),
          ui_card(
            "Identification",
            "Deterministic planning output from the authored question, roles, graph, and assumptions.",
            uiOutput(ns("identification_table")),
            ui_disclosure("Graph Diagnostics", uiOutput(ns("graph_diagnostics_table"))),
            ui_disclosure("Adjustment Guidance", uiOutput(ns("adjustment_guidance_table"))),
            ui_disclosure("Design Eligibility", uiOutput(ns("design_eligibility_table")))
          ),
          ui_card(
            "Investigation Plan",
            "Next evidence actions, prohibited claims, and campaign seeds.",
            uiOutput(ns("recommended_actions_table")),
            uiOutput(ns("campaign_seeds_table"))
          ),
          ui_card(
            "Experiment Design",
            "Convert a causal question into a governed design artifact. This does not execute treatment or estimate effects.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("experiment_question_id"), "Experiment Question ID", value = "eq_project_test"),
              textInput(ns("experiment_hypothesis"), "Hypothesis", placeholder = "Increasing the lever improves the outcome."),
              textInput(ns("experiment_treatment"), "Treatment", placeholder = "approved intervention"),
              textInput(ns("experiment_comparison"), "Comparison", placeholder = "current policy"),
              textInput(ns("experiment_population"), "Assignment Population", placeholder = "eligible units"),
              textInput(ns("experiment_primary_outcome"), "Primary Outcome", placeholder = "revenue"),
              textInput(ns("experiment_guardrails"), "Guardrails", placeholder = "cost,quality")
            ),
            textAreaInput(ns("experiment_decision_rule"), "Decision Rule", rows = 2, placeholder = "Roll out if lift exceeds cost and guardrails hold."),
            tags$div(
              class = "aq-form-grid",
              selectInput(ns("experiment_design_type"), "Design Type", choices = c("individual_randomized_ab", "stratified_randomized", "blocked_randomized", "cluster_randomized", "geographic_randomized", "switchback", "stepped_wedge", "factorial", "randomized_encouragement")),
              textInput(ns("assignment_unit"), "Assignment Unit", value = "unit"),
              textInput(ns("treatment_delivery_unit"), "Treatment Delivery Unit", value = "unit"),
              textInput(ns("analysis_unit"), "Analysis Unit", value = "unit-period"),
              textInput(ns("cluster_unit"), "Cluster Unit", placeholder = "market"),
              textInput(ns("stratification_variables"), "Stratification Variables", placeholder = "region"),
              textInput(ns("blocking_variables"), "Blocking Variables", placeholder = "segment"),
              numericInput(ns("minimum_detectable_effect"), "Minimum Detectable Effect", value = NA, min = 0, step = 0.1),
              numericInput(ns("baseline_sd"), "Baseline SD", value = NA, min = 0, step = 0.1),
              numericInput(ns("treatment_duration_days"), "Treatment Days", value = 28, min = 0, step = 1),
              selectInput(ns("interference_mode"), "Interference Mode", choices = c("no_interference_assumed", "within_cluster_allowed", "cross_cluster_risk", "geographic_spillover", "network_spillover", "channel_contamination", "treatment_substitution", "competitive_response")),
              checkboxInput(ns("authority_approved"), "Authority Approved", value = FALSE),
              checkboxInput(ns("coverage_approved"), "Coverage Approved", value = FALSE)
            ),
            ui_action_row(
              actionButton(ns("save_experiment_question"), "Save Experiment Question", class = "btn-primary"),
              actionButton(ns("save_experiment_design"), "Save Design Spec", class = "btn-secondary"),
              actionButton(ns("generate_experiment_plan"), "Generate Plan", class = "btn-secondary"),
              actionButton(ns("register_experiment_artifact"), "Register Experiment Artifact", class = "btn-secondary")
            ),
            verbatimTextOutput(ns("experiment_message")),
            uiOutput(ns("experiment_summary_cards")),
            ui_disclosure("Experiment Gate", uiOutput(ns("experiment_gate_table"))),
            ui_disclosure("Power and Timing", uiOutput(ns("experiment_power_table"))),
            ui_disclosure("Validity Threats", uiOutput(ns("experiment_threats_table")))
          )
        )
      )
    )
  )
}

page_causal_intelligence_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    message <- reactiveVal("Causal planning is ready. Author a question, roles, and graph assumptions.")

    output$decision_context_selector <- renderUI({
      state <- semantic_decision_normalize(ctx$semantic_decision_state())
      choices <- if (nrow(state$contexts)) state$contexts$decision_context_id else character()
      selected <- causal_intelligence_active_question_id(ctx$causal_intelligence_state())
      selectInput(ns("decision_context_id"), "Authored Decision Context", choices = c("(none)" = "", choices), selected = "")
    })

    current_question_id <- reactive({
      id <- input$causal_question_id %||% causal_intelligence_active_question_id(ctx$causal_intelligence_state())
      if (nzchar(id %||% "")) id else NA_character_
    })

    observeEvent(input$save_question, {
      row <- data.table::data.table(
        causal_question_id = input$causal_question_id,
        decision_context_id = input$decision_context_id %||% "",
        business_objective = input$business_objective %||% "",
        lever_id = input$lever_id %||% "",
        exposure = input$exposure %||% "",
        outcome = input$outcome %||% "",
        population = input$population %||% "",
        unit_of_analysis = input$unit_of_analysis %||% "",
        time_zero = input$time_zero %||% "",
        treatment_window = input$treatment_window %||% "",
        outcome_window = input$outcome_window %||% "",
        comparison_condition = input$comparison_condition %||% "",
        intervention_definition = input$intervention_definition %||% "",
        estimand = input$estimand %||% "ATE",
        effect_scale = input$effect_scale %||% "",
        target_population = input$target_population %||% "",
        assumptions = input$assumptions %||% "",
        selection_mechanism = input$selection_mechanism %||% "",
        measurement_mechanism = input$measurement_mechanism %||% ""
      )
      result <- causal_intelligence_upsert_row(ctx$causal_intelligence_state(), "questions", "causal_question_id", row, row$causal_question_id[[1]], "question_authored")
      if (identical(result$status, "success")) ctx$causal_intelligence_state(result$value)
      message(paste(result$messages %||% result$errors, collapse = " | "))
    })

    observeEvent(input$save_role, {
      qid <- current_question_id()
      row <- data.table::data.table(
        causal_question_id = qid,
        role_id = input$role_id,
        variable = input$role_variable,
        role = input$role,
        timing = input$timing,
        role_confidence = input$role_confidence,
        evidence_basis = "human_authored",
        assigned_by = "user",
        rationale = input$role_rationale %||% "",
        adjustment_eligibility = input$adjustment_eligibility %||% "unknown"
      )
      result <- causal_intelligence_upsert_row(ctx$causal_intelligence_state(), "roles", "role_id", row, qid, "role_authored")
      if (identical(result$status, "success")) ctx$causal_intelligence_state(result$value)
      message(paste(result$messages %||% result$errors, collapse = " | "))
    })

    observeEvent(input$save_relationship, {
      qid <- current_question_id()
      row <- data.table::data.table(
        causal_question_id = qid,
        relationship_id = input$relationship_id,
        source_variable = input$source_variable,
        destination_variable = input$destination_variable,
        relationship_type = input$relationship_type,
        direction = input$direction,
        timing = input$relationship_timing,
        confidence = input$relationship_confidence,
        human_rationale = input$human_rationale %||% "",
        status = input$relationship_status %||% "active"
      )
      result <- causal_intelligence_upsert_row(ctx$causal_intelligence_state(), "relationships", "relationship_id", row, qid, "relationship_authored")
      if (identical(result$status, "success")) ctx$causal_intelligence_state(result$value)
      message(paste(result$messages %||% result$errors, collapse = " | "))
    })

    observeEvent(input$assess_causal_plan, {
      result <- causal_intelligence_assess(ctx$causal_intelligence_state(), ctx$semantic_decision_state(), ctx$semantic_workspace())
      if (identical(result$status, "success")) ctx$causal_intelligence_state(result$value)
      message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$register_causal_artifact, {
      result <- causal_intelligence_register_artifact(ctx, ctx$causal_intelligence_state())
      message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    experiment_message <- reactiveVal("Experiment design planning is ready. Save an experiment question and design spec, then generate a plan.")

    observeEvent(input$save_experiment_question, {
      qid <- current_question_id()
      row <- data.table::data.table(
        experiment_question_id = input$experiment_question_id,
        causal_question_id = qid,
        decision_context_id = input$decision_context_id %||% "",
        hypothesis = input$experiment_hypothesis %||% "",
        null_claim = paste("No effect of", input$experiment_treatment %||% "treatment"),
        alternative_claim = paste("Effect of", input$experiment_treatment %||% "treatment", "differs from comparison"),
        treatment = input$experiment_treatment %||% "",
        comparison = input$experiment_comparison %||% "",
        estimand = input$estimand %||% "ATE",
        assignment_population = input$experiment_population %||% "",
        expected_mechanism = input$intervention_definition %||% "",
        primary_outcome = input$experiment_primary_outcome %||% "",
        guardrails = input$experiment_guardrails %||% "",
        decision_rule = input$experiment_decision_rule %||% "",
        authority = input$business_objective %||% "approval_required",
        coverage = input$experiment_population %||% "",
        exposure_verification = "assignment and delivery logs required",
        compliance_measure = "compliance measure required",
        treatment_receipt = "treatment receipt required",
        data_source = "project data",
        owner = "analytics",
        baseline_sd = input$baseline_sd,
        minimum_detectable_effect = input$minimum_detectable_effect,
        treatment_duration_days = input$treatment_duration_days,
        outcome_maturation_days = 0L,
        reporting_delay_days = 0L,
        decision_sensitivity = "unknown",
        lever_importance = "unknown",
        authority_approved = input$authority_approved,
        coverage_approved = input$coverage_approved,
        interference_mode = input$interference_mode
      )
      result <- causal_experiment_upsert_row(ctx$causal_experiment_state(), "experiment_questions", "experiment_question_id", row, row$experiment_question_id[[1]], "experiment_question_authored")
      if (identical(result$status, "success")) ctx$causal_experiment_state(result$value)
      experiment_message(paste(result$messages %||% result$errors, collapse = " | "))
    })

    observeEvent(input$save_experiment_design, {
      eqid <- input$experiment_question_id %||% causal_experiment_active_id(ctx$causal_experiment_state())
      row <- data.table::data.table(
        experiment_question_id = eqid,
        design_id = paste0("design_", eqid),
        design_type = input$experiment_design_type,
        assignment_unit = input$assignment_unit,
        treatment_delivery_unit = input$treatment_delivery_unit,
        analysis_unit = input$analysis_unit,
        cluster_unit = input$cluster_unit %||% "",
        stratification_variables = input$stratification_variables %||% "",
        blocking_variables = input$blocking_variables %||% "",
        number_of_arms = 2L,
        pre_period = "",
        treatment_period = paste(input$treatment_duration_days %||% "", "days"),
        follow_up_period = "",
        washout_period = "",
        contamination_risks = "",
        interference_assumptions = input$interference_mode %||% "not yet assessed"
      )
      result <- causal_experiment_upsert_row(ctx$causal_experiment_state(), "design_specs", "design_id", row, eqid, "experiment_design_authored")
      if (identical(result$status, "success")) ctx$causal_experiment_state(result$value)
      experiment_message(paste(result$messages %||% result$errors, collapse = " | "))
    })

    observeEvent(input$generate_experiment_plan, {
      result <- causal_experiment_build_plan(ctx$causal_experiment_state(), ctx$causal_intelligence_state(), eligible_units = ctx$uploaded_data())
      if (identical(result$status, "success")) ctx$causal_experiment_state(result$value)
      experiment_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$register_experiment_artifact, {
      result <- causal_experiment_register_artifact(ctx, ctx$causal_experiment_state())
      experiment_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    assessment <- reactive({
      state <- causal_intelligence_normalize(ctx$causal_intelligence_state())
      state$assessments[[causal_intelligence_active_question_id(state)]]
    })

    output$causal_message <- renderText(message())
    output$experiment_message <- renderText(experiment_message())

    output$causal_summary_cards <- renderUI({
      summary <- causal_intelligence_summary(ctx$causal_intelligence_state())
      tags$div(
        class = "aq-metric-grid",
        ui_card("Questions", NULL, tags$strong(summary$questions[[1]]), tags$p("authored")),
        ui_card("Roles", NULL, tags$strong(summary$roles[[1]]), tags$p("question-relative")),
        ui_card("Graph Edges", NULL, tags$strong(summary$relationships[[1]]), tags$p("directed assumptions")),
        ui_card("Assessment", NULL, tags$strong(ui_display_label(summary$assessment_status[[1]])), tags$p(ui_display_label(summary$identification_status[[1]])))
      )
    })

    causal_render_table <- function(rows, title, message = "No records yet.") {
      rows <- data.table::as.data.table(rows)
      if (!nrow(rows)) return(ui_empty_state(title, message))
      render_table(rows, engine = "html", searchable = FALSE, sortable = FALSE)
    }

    output$causal_roles_table <- renderUI({
      rows <- causal_intelligence_rows(ctx$causal_intelligence_state(), "roles", current_question_id())
      causal_render_table(rows[, intersect(c("role_id", "variable", "role", "timing", "adjustment_eligibility"), names(rows)), with = FALSE], "No roles yet.", "Add exposure, outcome, and candidate adjustment roles.")
    })
    output$causal_relationships_table <- renderUI({
      rows <- causal_intelligence_rows(ctx$causal_intelligence_state(), "relationships", current_question_id())
      causal_render_table(rows[, intersect(c("relationship_id", "source_variable", "destination_variable", "relationship_type", "status"), names(rows)), with = FALSE], "No graph assumptions yet.", "Author directed relationships before identification planning.")
    })
    output$identification_table <- renderUI({
      a <- assessment()
      if (is.null(a)) return(ui_empty_state("No identification assessment.", "Run Assess Identification Plan."))
      causal_render_table(a$context$identification, "No identification assessment.")
    })
    output$graph_diagnostics_table <- renderUI({
      a <- assessment()
      if (is.null(a)) return(ui_empty_state("No graph diagnostics yet.", "Run Assess Identification Plan."))
      causal_render_table(a$context$graph_diagnostics, "No graph diagnostics yet.")
    })
    output$adjustment_guidance_table <- renderUI({
      a <- assessment()
      if (is.null(a)) return(ui_empty_state("No adjustment guidance yet.", "Run Assess Identification Plan."))
      causal_render_table(a$context$adjustment_guidance, "No adjustment guidance yet.")
    })
    output$design_eligibility_table <- renderUI({
      a <- assessment()
      if (is.null(a)) return(ui_empty_state("No design eligibility yet.", "Run Assess Identification Plan."))
      causal_render_table(utils::head(a$context$design_eligibility, 12L), "No design eligibility yet.")
    })
    output$recommended_actions_table <- renderUI({
      a <- assessment()
      if (is.null(a)) return(ui_empty_state("No investigation plan yet.", "Run Assess Identification Plan."))
      causal_render_table(a$plan$recommended_next_actions, "No recommended actions yet.")
    })
    output$campaign_seeds_table <- renderUI({
      causal_render_table(causal_intelligence_campaign_seeds(ctx$causal_intelligence_state()), "No campaign seeds.", "Causal planning is currently complete enough that no seed was emitted.")
    })
    experiment_plan <- reactive({
      state <- causal_experiment_normalize(ctx$causal_experiment_state())
      state$plans[[causal_experiment_active_id(state)]]
    })
    output$experiment_summary_cards <- renderUI({
      summary <- causal_experiment_summary(ctx$causal_experiment_state())
      tags$div(
        class = "aq-metric-grid",
        ui_card("Questions", NULL, tags$strong(summary$experiment_questions[[1]]), tags$p("experiment questions")),
        ui_card("Designs", NULL, tags$strong(summary$design_specs[[1]]), tags$p("design specs")),
        ui_card("Plan", NULL, tags$strong(ui_display_label(summary$plan_status[[1]])), tags$p(ui_display_label(summary$gate_status[[1]]))),
        ui_card("Execution", NULL, tags$strong("No"), tags$p("treatment execution out of scope"))
      )
    })
    output$experiment_gate_table <- renderUI({
      plan <- experiment_plan()
      if (is.null(plan)) return(ui_empty_state("No gate assessment.", "Generate an experiment design plan."))
      causal_render_table(plan$gate, "No gate assessment.")
    })
    output$experiment_power_table <- renderUI({
      plan <- experiment_plan()
      if (is.null(plan)) return(ui_empty_state("No power or timing plan.", "Generate an experiment design plan."))
      causal_render_table(data.table::rbindlist(list(data.table::as.data.table(plan$power), data.table::as.data.table(plan$timing)), fill = TRUE), "No power or timing plan.")
    })
    output$experiment_threats_table <- renderUI({
      plan <- experiment_plan()
      if (is.null(plan)) return(ui_empty_state("No validity threats.", "Generate an experiment design plan."))
      causal_render_table(plan$threats, "No validity threats.")
    })
  })
}
