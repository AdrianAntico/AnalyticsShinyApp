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
            "Causal Intelligence estimates effects only after governed readiness evidence exists.",
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
            "Observational Study Design",
            "Assess whether non-randomized data can support a governed causal analysis, then estimate only when readiness passes.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("observational_study_id"), "Study ID", value = "obs_project_study"),
              textInput(ns("observational_title"), "Study Title", placeholder = "Observational study for intervention and outcome"),
              textInput(ns("observational_treatment"), "Treatment / Exposure", placeholder = "treated condition"),
              textInput(ns("observational_comparison"), "Comparison", placeholder = "untreated or current policy"),
              textInput(ns("observational_population"), "Population", placeholder = "eligible units"),
              textInput(ns("observational_unit"), "Unit of Analysis", placeholder = "customer / market-week"),
              textInput(ns("observational_assignment_time"), "Time Zero / Assignment Time", placeholder = "date treatment eligibility was determined"),
              textInput(ns("observational_outcome_window"), "Outcome Window", placeholder = "60 days after assignment"),
              textInput(ns("observational_baseline_window"), "Baseline Window", placeholder = "90 days before assignment"),
              selectInput(ns("observational_assignment_mechanism"), "Assignment Mechanism", choices = c("unknown", "deterministic_rule", "eligibility_threshold", "discretionary_assignment", "self_selection", "resource_constrained_allocation", "geographic_rollout", "staggered_adoption", "historical_policy", "provider_preference", "customer_choice")),
              textInput(ns("observational_assignment_inputs"), "Assignment Inputs", placeholder = "prior_spend,region"),
              selectInput(ns("observational_assignment_confidence"), "Assignment Confidence", choices = c("unknown", "low", "moderate", "high"))
            ),
            textAreaInput(ns("observational_assignment_process"), "Assignment Process", rows = 2, placeholder = "Why did some units receive treatment while others did not?"),
            tags$div(
              class = "aq-form-grid",
              textInput(ns("observational_confounders"), "Approved Confounder Candidates", placeholder = "prior_spend,region"),
              textInput(ns("observational_precision"), "Precision Variables", placeholder = "tenure"),
              textInput(ns("observational_mediators"), "Excluded Mediators", placeholder = "post_treatment_clicks"),
              textInput(ns("observational_colliders"), "Excluded Colliders", placeholder = "observed_purchase"),
              textInput(ns("observational_post_treatment"), "Excluded Post-Treatment Variables", placeholder = "future_status"),
              uiOutput(ns("observational_treatment_column")),
              uiOutput(ns("observational_outcome_column")),
              uiOutput(ns("observational_did_time_column")),
              uiOutput(ns("observational_did_unit_column")),
              textInput(ns("observational_did_intervention_time"), "DiD Intervention Time", placeholder = "date or numeric time value"),
              selectInput(ns("observational_estimand"), "Effect Estimand", choices = c("ATE", "ATT"), selected = "ATE"),
              numericInput(ns("observational_treated_count"), "Treated Count", value = 50, min = 0, step = 1),
              numericInput(ns("observational_comparison_count"), "Comparison Count", value = 50, min = 0, step = 1),
              textInput(ns("observational_probabilities"), "Diagnostic Treatment Probabilities", placeholder = "0.2,0.4,0.6,0.8"),
              selectInput(ns("observational_unmeasured_risk_level"), "Unmeasured Confounding Risk", choices = c("unknown", "low", "moderate", "high", "critical")),
              textInput(ns("observational_unmeasured_risk"), "Unmeasured Risk Factor", placeholder = "manager discretion"),
              selectInput(ns("observational_selection_severity"), "Selection / Missingness Severity", choices = c("unknown", "low", "moderate", "high", "critical"))
            ),
            tags$div(
              class = "aq-form-grid",
              checkboxInput(ns("observational_pre_period"), "Pre-Period Available", value = FALSE),
              checkboxInput(ns("observational_negative_control"), "Negative Control Available", value = FALSE),
              checkboxInput(ns("observational_donor_pool"), "Donor Pool Available", value = FALSE),
              checkboxInput(ns("observational_cutoff"), "Running Variable / Cutoff Available", value = FALSE),
              checkboxInput(ns("observational_instrument"), "Candidate Instrument Available", value = FALSE),
              checkboxInput(ns("observational_adjustment_approved"), "Adjustment Set Human Approved", value = FALSE)
            ),
            ui_action_row(
              actionButton(ns("save_observational_study"), "Save Observational Study", class = "btn-primary"),
              actionButton(ns("run_observational_plan"), "Assess Readiness", class = "btn-secondary"),
              actionButton(ns("run_observational_estimate"), "Estimate Governed Effect", class = "btn-secondary"),
              actionButton(ns("run_observational_did"), "Run Governed DiD", class = "btn-secondary"),
              actionButton(ns("register_observational_artifact"), "Register Planning Artifact", class = "btn-secondary"),
              actionButton(ns("register_observational_effect_artifact"), "Register Effect Artifact", class = "btn-secondary"),
              actionButton(ns("register_observational_did_artifact"), "Register DiD Artifact", class = "btn-secondary")
            ),
            verbatimTextOutput(ns("observational_message")),
            uiOutput(ns("observational_summary_cards")),
            ui_disclosure("Readiness", uiOutput(ns("observational_readiness_table"))),
            ui_disclosure("Effect Evidence", uiOutput(ns("observational_effect_table"))),
            ui_disclosure("Difference-in-Differences Evidence", uiOutput(ns("observational_did_table"))),
            ui_disclosure("Overlap and Design Eligibility", uiOutput(ns("observational_design_table"))),
            ui_disclosure("Balance / Timing / Threats", uiOutput(ns("observational_diagnostics_table")))
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
          ),
          ui_card(
            "Completed Experiment Evidence",
            "Ingest completed or in-progress experiment evidence, preserve original assignment, and classify analysis readiness. This does not estimate effects.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("completed_experiment_id"), "Completed Experiment ID", value = "ce_project_test"),
              textInput(ns("completed_plan_artifact_id"), "Experiment Plan Artifact ID", placeholder = "aq_experiment_plan_project_test"),
              textInput(ns("completed_estimand_id"), "Estimand ID", placeholder = "estimand_itt"),
              selectInput(ns("completed_status"), "Experiment Status", choices = c("completed", "in_progress", "stopped_early", "canceled", "compromised", "outcome_pending", "analysis_pending", "closed")),
              textInput(ns("actual_start_date"), "Actual Start Date", placeholder = "2026-01-01"),
              textInput(ns("actual_end_date"), "Actual End Date", placeholder = "2026-02-01"),
              textInput(ns("data_cutoff_date"), "Data Cutoff Date", placeholder = "2026-02-15"),
              textInput(ns("execution_owner"), "Execution Owner", value = "analytics")
            ),
            tags$div(
              class = "aq-form-grid",
              uiOutput(ns("map_unit_id")),
              uiOutput(ns("map_planned_arm")),
              uiOutput(ns("map_realized_arm")),
              uiOutput(ns("map_delivery")),
              uiOutput(ns("map_delivery_status")),
              uiOutput(ns("map_exposure")),
              uiOutput(ns("map_received")),
              uiOutput(ns("map_primary_outcome")),
              uiOutput(ns("map_guardrail")),
              uiOutput(ns("map_exclusion"))
            ),
            ui_action_row(
              actionButton(ns("save_completed_experiment"), "Save Completed Record", class = "btn-primary"),
              actionButton(ns("save_completed_mappings"), "Save Evidence Mappings", class = "btn-secondary"),
              actionButton(ns("assess_completed_readiness"), "Assess Readiness", class = "btn-secondary"),
              actionButton(ns("register_completed_artifact"), "Register Readiness Artifact", class = "btn-secondary")
            ),
            verbatimTextOutput(ns("completed_message")),
            uiOutput(ns("completed_summary_cards")),
            ui_disclosure("Analysis Readiness", uiOutput(ns("completed_readiness_table"))),
            ui_disclosure("Execution Reconciliation", uiOutput(ns("completed_reconciliation_table"))),
            ui_disclosure("Fidelity / Missingness / Estimand", uiOutput(ns("completed_integrity_table"))),
            ui_disclosure("Completed-Evidence Campaign Seeds", uiOutput(ns("completed_campaign_seeds_table")))
          ),
          ui_card(
            "Randomized ITT Estimation",
            "Estimate assignment-to-treatment effects only after completed-experiment readiness is current.",
            tags$div(
              class = "aq-form-grid",
              textInput(ns("itt_analysis_id"), "Analysis ID", value = "itt_project_test"),
              textInput(ns("itt_treatment_arm"), "Treatment Arm", value = "treatment"),
              textInput(ns("itt_comparison_arm"), "Comparison Arm", value = "control"),
              textInput(ns("itt_outcome"), "Outcome", placeholder = "revenue"),
              selectInput(ns("itt_outcome_type"), "Outcome Type", choices = c("continuous", "binary")),
              textInput(ns("itt_baseline_covariates"), "Approved Baseline Covariates", placeholder = "baseline_y,pre_period_value"),
              textInput(ns("itt_cluster_variable"), "Cluster Variable", placeholder = "market"),
              selectInput(ns("itt_se_method"), "Uncertainty Method", choices = c("welch", "hc0", "cluster")),
              numericInput(ns("itt_minimum_effect"), "Minimum Meaningful Effect", value = NA, step = 0.1),
              selectInput(ns("itt_design_type"), "Randomized Design", choices = c("completely_randomized", "blocked_randomized", "stratified_randomized", "cluster_randomized", "geographic_randomized", "switchback", "stepped_wedge", "factorial")),
              textInput(ns("itt_analysis_modes"), "Eligible Analysis Modes", value = "unadjusted,ancova,cuped,randomization_inference"),
              textInput(ns("itt_block_fields"), "Block Fields", placeholder = "block"),
              textInput(ns("itt_stratum_fields"), "Stratum Fields", placeholder = "stratum"),
              textInput(ns("itt_period_field"), "Period Field", placeholder = "period"),
              textInput(ns("itt_pre_period_fields"), "Pre-Period Fields", placeholder = "pre_revenue"),
              textInput(ns("itt_factorial_terms"), "Factorial Terms", placeholder = "creative,bid"),
              numericInput(ns("itt_material_harm"), "Maximum Acceptable Harm", value = NA, step = 0.1)
            ),
            ui_action_row(
              actionButton(ns("save_itt_spec"), "Save ITT Spec", class = "btn-primary"),
              actionButton(ns("run_itt_analysis"), "Run ITT Analysis", class = "btn-secondary"),
              actionButton(ns("approve_itt_evidence"), "Approve Evidence", class = "btn-secondary"),
              actionButton(ns("register_itt_artifact"), "Register Effect Artifact", class = "btn-secondary")
            ),
            verbatimTextOutput(ns("itt_message")),
            uiOutput(ns("itt_summary_cards")),
            ui_disclosure("Readiness Gate", uiOutput(ns("itt_gate_table"))),
            ui_disclosure("Primary Effect", uiOutput(ns("itt_primary_table"))),
            ui_disclosure("Design-Aware Methods", uiOutput(ns("itt_design_methods_table"))),
            ui_disclosure("Robustness Matrix", uiOutput(ns("itt_robustness_table"))),
            ui_disclosure("Carryover / Multiplicity / Guardrails", uiOutput(ns("itt_design_evidence_table"))),
            ui_disclosure("Causal Effect Report Sections", uiOutput(ns("itt_report_sections_table"))),
            ui_disclosure("Sensitivity / Materiality / Guardrails", uiOutput(ns("itt_evidence_table"))),
            ui_disclosure("Permitted and Prohibited Claims", uiOutput(ns("itt_claims_table"))),
            ui_disclosure("ITT Campaign Seeds", uiOutput(ns("itt_campaign_seeds_table")))
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

    observational_message <- reactiveVal("Observational planning is ready. Save a study, then assess readiness.")
    output$observational_message <- renderText(observational_message())

    output$observational_treatment_column <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      cols <- if (is.data.frame(data)) names(data) else character()
      selectInput(ns("observational_treatment_column_value"), "Treatment Column", choices = c("(manual counts)" = "", cols), selected = "")
    })
    output$observational_outcome_column <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      cols <- if (is.data.frame(data)) names(data) else character()
      selectInput(ns("observational_outcome_column_value"), "Outcome Column", choices = c("(select outcome)" = "", cols), selected = "")
    })
    output$observational_did_time_column <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      cols <- if (is.data.frame(data)) names(data) else character()
      selectInput(ns("observational_did_time_column_value"), "DiD Time Column", choices = c("(select time)" = "", cols), selected = "")
    })
    output$observational_did_unit_column <- renderUI({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      cols <- if (is.data.frame(data)) names(data) else character()
      selectInput(ns("observational_did_unit_column_value"), "DiD Unit Column", choices = c("(optional)" = "", cols), selected = "")
    })

    observeEvent(input$save_observational_study, {
      qid <- current_question_id()
      row <- data.table::data.table(
        observational_study_id = input$observational_study_id %||% "",
        decision_context_id = input$decision_context_id %||% "",
        causal_question_id = qid,
        estimand_id = paste0(input$observational_study_id %||% "obs", "_estimand"),
        study_title = input$observational_title %||% "",
        treatment = input$observational_treatment %||% "",
        comparison_condition = input$observational_comparison %||% "",
        treatment_levels = "",
        unit_of_analysis = input$observational_unit %||% "",
        population = input$observational_population %||% "",
        eligibility = input$observational_population %||% "",
        treatment_assignment_time = input$observational_assignment_time %||% "",
        treatment_window = input$treatment_window %||% "",
        outcome_window = input$observational_outcome_window %||% "",
        baseline_window = input$observational_baseline_window %||% "",
        index_date = input$observational_assignment_time %||% "",
        data_cutoff = "",
        organizational_scope = input$business_objective %||% "",
        authority = "user_authored",
        coverage = input$observational_population %||% "",
        status = "draft",
        outcome = input$outcome %||% "",
        estimand = input$estimand %||% "ATE",
        assignment_mechanism = input$observational_assignment_mechanism %||% "unknown",
        assignment_process = input$observational_assignment_process %||% "",
        assignment_inputs = input$observational_assignment_inputs %||% "",
        assignment_confidence = input$observational_assignment_confidence %||% "unknown",
        approved_confounders = input$observational_confounders %||% "",
        precision_variables = input$observational_precision %||% "",
        excluded_mediators = input$observational_mediators %||% "",
        excluded_colliders = input$observational_colliders %||% "",
        excluded_post_treatment = input$observational_post_treatment %||% "",
        treatment_column = input$observational_treatment_column_value %||% "",
        outcome_column = input$observational_outcome_column_value %||% "",
        did_time_column = input$observational_did_time_column_value %||% "",
        did_unit_column = input$observational_did_unit_column_value %||% "",
        did_intervention_time = input$observational_did_intervention_time %||% "",
        observational_estimand = input$observational_estimand %||% "ATE",
        treated_count = input$observational_treated_count,
        comparison_count = input$observational_comparison_count,
        diagnostic_probabilities = input$observational_probabilities %||% "",
        unmeasured_risk_level = input$observational_unmeasured_risk_level %||% "unknown",
        unmeasured_confounding_risk = input$observational_unmeasured_risk %||% "",
        decision_consequence = "decision uncertainty remains bounded by observational assumptions",
        selection_threat = "selection/missingness review",
        selection_timing = "unknown",
        selection_severity = input$observational_selection_severity %||% "unknown",
        falsification_test = if (isTRUE(input$observational_negative_control)) "negative_control" else "missing_falsification_plan",
        falsification_rationale = "user-authored observational readiness",
        falsification_required_data = "",
        contamination_risk = "unknown",
        pre_period_available = input$observational_pre_period,
        negative_control_available = input$observational_negative_control,
        donor_pool_available = input$observational_donor_pool,
        running_variable_cutoff = input$observational_cutoff,
        candidate_instrument = input$observational_instrument,
        adjustment_approved = input$observational_adjustment_approved
      )
      result <- causal_observational_upsert_study(ctx$causal_observational_state(), row)
      if (identical(result$status, "success")) ctx$causal_observational_state(result$value)
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$run_observational_plan, {
      result <- causal_observational_build_plan(ctx$causal_observational_state(), ctx$causal_intelligence_state(), ctx$uploaded_data())
      if (identical(result$status, "success")) ctx$causal_observational_state(result$value)
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })
    observeEvent(input$run_observational_estimate, {
      result <- causal_observational_run_estimation(ctx$causal_observational_state(), ctx$uploaded_data())
      if (identical(result$status, "success")) ctx$causal_observational_state(result$value)
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })
    observeEvent(input$run_observational_did, {
      result <- causal_observational_run_did(ctx$causal_observational_state(), ctx$uploaded_data())
      if (identical(result$status, "success")) ctx$causal_observational_state(result$value)
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$register_observational_artifact, {
      result <- causal_observational_register_artifact(ctx, ctx$causal_observational_state())
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })
    observeEvent(input$register_observational_effect_artifact, {
      result <- causal_observational_register_effect_artifact(ctx, ctx$causal_observational_state())
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })
    observeEvent(input$register_observational_did_artifact, {
      result <- causal_observational_register_did_artifact(ctx, ctx$causal_observational_state())
      observational_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
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
    completed_message <- reactiveVal("Completed-experiment evidence is ready. Save a record, map evidence columns, then assess readiness.")
    output$completed_message <- renderText(completed_message())
    itt_message <- reactiveVal("Randomized ITT estimation is ready after completed-experiment readiness is current.")
    output$itt_message <- renderText(itt_message())

    completed_column_choices <- reactive({
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      cols <- if (is.data.frame(data)) names(data) else character()
      c("(none)" = "", cols)
    })

    completed_select <- function(input_id, label, preferred = character()) {
      renderUI({
        choices <- completed_column_choices()
        selected <- intersect(preferred, unname(choices))
        selectInput(ns(input_id), label, choices = choices, selected = if (length(selected)) selected[[1]] else "")
      })
    }

    output$map_unit_id <- completed_select("completed_unit_id_col", "Unit ID Column", c("unit_id", "id"))
    output$map_planned_arm <- completed_select("completed_planned_arm_col", "Original Assignment Column", c("planned_arm", "assignment", "arm"))
    output$map_realized_arm <- completed_select("completed_realized_arm_col", "Realized Assignment Column", c("realized_assigned_arm", "planned_arm", "assignment", "arm"))
    output$map_delivery <- completed_select("completed_delivery_col", "Delivered Condition Column", c("delivered_condition", "treatment", "arm"))
    output$map_delivery_status <- completed_select("completed_delivery_status_col", "Delivery Status Column", c("delivery_status"))
    output$map_exposure <- completed_select("completed_exposure_col", "Exposure Column", c("exposure", "spend"))
    output$map_received <- completed_select("completed_received_col", "Treatment Received Column", c("treatment_received", "delivered_condition"))
    output$map_primary_outcome <- completed_select("completed_primary_outcome_col", "Primary Outcome Column", c(input$experiment_primary_outcome %||% "", input$outcome %||% "", "outcome", "revenue"))
    output$map_guardrail <- completed_select("completed_guardrail_col", "Guardrail Column", c("guardrail", "cost_guardrail", "cpa"))
    output$map_exclusion <- completed_select("completed_exclusion_col", "Exclusion Stage Column", c("exclusion_stage"))

    observeEvent(input$save_completed_experiment, {
      row <- data.table::data.table(
        completed_experiment_id = input$completed_experiment_id,
        experiment_plan_artifact_id = input$completed_plan_artifact_id %||% paste0("aq_experiment_plan_", input$experiment_question_id %||% ""),
        decision_context_id = input$decision_context_id %||% "",
        causal_question_id = current_question_id(),
        estimand_id = input$completed_estimand_id %||% input$estimand %||% "",
        design_version = "v1",
        assignment_version = "v1",
        experiment_status = input$completed_status %||% "completed",
        actual_start_date = input$actual_start_date %||% "",
        actual_end_date = input$actual_end_date %||% "",
        data_cutoff_date = input$data_cutoff_date %||% "",
        execution_owner = input$execution_owner %||% "analytics",
        primary_outcome = input$completed_primary_outcome_col %||% input$experiment_primary_outcome %||% input$outcome %||% ""
      )
      result <- causal_completed_experiment_upsert_completed(ctx$causal_completed_experiment_state(), row)
      if (identical(result$status, "success")) ctx$causal_completed_experiment_state(result$value)
      completed_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$save_completed_mappings, {
      id <- input$completed_experiment_id %||% causal_completed_experiment_active_id(ctx$causal_completed_experiment_state())
      mappings <- data.table::data.table(
        evidence_role = c("unit_id", "planned_arm", "realized_assigned_arm", "delivered_condition", "delivery_status", "exposure", "treatment_received", "primary_outcome", "guardrail", "exclusion_stage"),
        source_column = c(input$completed_unit_id_col, input$completed_planned_arm_col, input$completed_realized_arm_col, input$completed_delivery_col, input$completed_delivery_status_col, input$completed_exposure_col, input$completed_received_col, input$completed_primary_outcome_col, input$completed_guardrail_col, input$completed_exclusion_col)
      )
      result <- causal_completed_experiment_save_mappings(ctx$causal_completed_experiment_state(), id, mappings)
      if (identical(result$status, "success")) ctx$causal_completed_experiment_state(result$value)
      completed_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$assess_completed_readiness, {
      result <- causal_completed_experiment_assess(ctx$causal_completed_experiment_state(), ctx$uploaded_data())
      if (identical(result$status, "success")) ctx$causal_completed_experiment_state(result$value)
      completed_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$register_completed_artifact, {
      result <- causal_completed_experiment_register_artifact(ctx, ctx$causal_completed_experiment_state())
      completed_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$save_itt_spec, {
      completed_id <- causal_completed_experiment_active_id(ctx$causal_completed_experiment_state())
      row <- data.table::data.table(
        analysis_id = input$itt_analysis_id %||% "",
        completed_experiment_id = completed_id,
        treatment_arm = input$itt_treatment_arm %||% "",
        comparison_arm = input$itt_comparison_arm %||% "",
        outcome = input$itt_outcome %||% "",
        outcome_type = input$itt_outcome_type %||% "continuous",
        baseline_covariates = input$itt_baseline_covariates %||% "",
        cluster_variable = input$itt_cluster_variable %||% "",
        standard_error_method = input$itt_se_method %||% "welch",
        minimum_meaningful_effect = suppressWarnings(as.numeric(input$itt_minimum_effect)),
        design_type = input$itt_design_type %||% "completely_randomized",
        analysis_modes = input$itt_analysis_modes %||% "unadjusted,ancova",
        block_fields = input$itt_block_fields %||% "",
        stratum_fields = input$itt_stratum_fields %||% "",
        period_field = input$itt_period_field %||% "",
        cluster_unit = input$itt_cluster_variable %||% "",
        pre_period_fields = input$itt_pre_period_fields %||% "",
        factorial_terms = input$itt_factorial_terms %||% "",
        material_benefit = suppressWarnings(as.numeric(input$itt_minimum_effect)),
        material_harm = suppressWarnings(as.numeric(input$itt_material_harm))
      )
      result <- causal_itt_upsert_spec(ctx$causal_itt_state(), row)
      if (identical(result$status, "success")) ctx$causal_itt_state(result$value)
      itt_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$run_itt_analysis, {
      result <- causal_itt_run(ctx$causal_itt_state(), ctx$causal_completed_experiment_state(), ctx$uploaded_data())
      if (identical(result$status, "success")) ctx$causal_itt_state(result$value)
      itt_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$approve_itt_evidence, {
      result <- causal_itt_review(ctx$causal_itt_state(), approve = TRUE, reviewer = "user")
      if (identical(result$status, "success")) ctx$causal_itt_state(result$value)
      itt_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

    observeEvent(input$register_itt_artifact, {
      result <- causal_itt_register_artifact(ctx, ctx$causal_itt_state())
      itt_message(paste(result$messages %||% result$errors %||% result$warnings, collapse = " | "))
    })

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
    observational_plan <- reactive({
      state <- causal_observational_normalize(ctx$causal_observational_state())
      state$plans[[causal_observational_active_id(state)]]
    })
    output$observational_summary_cards <- renderUI({
      summary <- causal_observational_summary(ctx$causal_observational_state())
      tags$div(
        class = "aq-metric-grid",
        ui_card("Studies", NULL, tags$strong(summary$studies[[1]]), tags$p("observational plans")),
        ui_card("Readiness", NULL, tags$strong(ui_display_label(summary$readiness_state[[1]])), tags$p(if (summary$stale[[1]]) "stale or not planned" else "current")),
        ui_card("Overlap", NULL, tags$strong(ui_display_label(summary$overlap_state[[1]])), tags$p("positivity support")),
        ui_card("Assignment", NULL, tags$strong(ui_display_label(summary$assignment_mechanism[[1]])), tags$p("documented mechanism")),
        ui_card("Effect", NULL, tags$strong(ui_display_label(summary$effect_status[[1]])), tags$p("requires review")),
        ui_card("DiD", NULL, tags$strong(ui_display_label(summary$did_status[[1]])), tags$p("time-based evidence"))
      )
    })
    output$observational_readiness_table <- renderUI({
      plan <- observational_plan()
      if (is.null(plan)) return(ui_empty_state("No observational readiness yet.", "Save an observational study and assess readiness."))
      causal_render_table(plan$readiness, "No readiness result.")
    })
    output$observational_effect_table <- renderUI({
      state <- causal_observational_normalize(ctx$causal_observational_state())
      effect <- state$effect_results[[causal_observational_active_id(state)]]
      if (is.null(effect)) return(ui_empty_state("No governed effect evidence yet.", "Assess readiness, map treatment/outcome columns, then estimate the governed effect."))
      rows <- data.table::rbindlist(
        list(
          data.table::as.data.table(effect$result$primary_estimate),
          data.table::as.data.table(effect$result$balance_diagnostics),
          data.table::as.data.table(effect$result$weights[, intersect(c("weight_type", "effective_sample_size", "extreme_weight_share", "status"), names(effect$result$weights)), with = FALSE])
        ),
        use.names = TRUE,
        fill = TRUE
      )
      causal_render_table(rows, "No effect evidence.")
    })
    output$observational_did_table <- renderUI({
      state <- causal_observational_normalize(ctx$causal_observational_state())
      did <- state$did_results[[causal_observational_active_id(state)]]
      if (is.null(did)) return(ui_empty_state("No Difference-in-Differences evidence yet.", "Assess readiness, map time/unit/intervention fields, then run governed DiD."))
      rows <- data.table::rbindlist(
        list(
          data.table::as.data.table(did$result$primary_estimate),
          data.table::as.data.table(did$result$parallel_trends),
          data.table::as.data.table(did$result$composition)
        ),
        use.names = TRUE,
        fill = TRUE
      )
      causal_render_table(rows, "No DiD evidence.")
    })
    output$observational_design_table <- renderUI({
      plan <- observational_plan()
      if (is.null(plan)) return(ui_empty_state("No overlap or design eligibility yet.", "Assess observational readiness."))
      rows <- data.table::rbindlist(
        list(
          data.table::as.data.table(plan$overlap),
          data.table::as.data.table(utils::head(plan$design_eligibility[, intersect(c("design_family", "eligibility", "required_data", "recommended_priority"), names(plan$design_eligibility)), with = FALSE], 12L))
        ),
        use.names = TRUE,
        fill = TRUE
      )
      causal_render_table(rows, "No overlap or design eligibility.")
    })
    output$observational_diagnostics_table <- renderUI({
      plan <- observational_plan()
      if (is.null(plan)) return(ui_empty_state("No diagnostics yet.", "Assess observational readiness."))
      rows <- data.table::rbindlist(
        list(
          data.table::as.data.table(plan$temporal[, intersect(c("variable", "role", "temporal_classification", "adjustment_eligible", "recommendation"), names(plan$temporal)), with = FALSE]),
          data.table::as.data.table(plan$balance[, intersect(c("variable", "balance_metric", "standardized_difference", "severity", "recommendation"), names(plan$balance)), with = FALSE]),
          data.table::as.data.table(plan$selection[, intersect(c("threat", "state", "recommendation"), names(plan$selection)), with = FALSE]),
          data.table::as.data.table(plan$unmeasured[, intersect(c("factor", "risk_state", "recommendation"), names(plan$unmeasured)), with = FALSE])
        ),
        use.names = TRUE,
        fill = TRUE
      )
      causal_render_table(rows, "No timing, balance, selection, or unmeasured-confounding diagnostics.")
    })
    experiment_plan <- reactive({
      state <- causal_experiment_normalize(ctx$causal_experiment_state())
      state$plans[[causal_experiment_active_id(state)]]
    })
    completed_assessment <- reactive({
      state <- causal_completed_experiment_normalize(ctx$causal_completed_experiment_state())
      state$assessments[[causal_completed_experiment_active_id(state)]]
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
    output$completed_summary_cards <- renderUI({
      summary <- causal_completed_experiment_summary(ctx$causal_completed_experiment_state())
      tags$div(
        class = "aq-metric-grid",
        ui_card("Completed Records", NULL, tags$strong(summary$completed_experiments[[1]]), tags$p("execution records")),
        ui_card("Mappings", NULL, tags$strong(summary$evidence_mappings[[1]]), tags$p("evidence columns")),
        ui_card("Readiness", NULL, tags$strong(ui_display_label(summary$readiness_state[[1]])), tags$p(ui_display_label(summary$assessment_status[[1]]))),
        ui_card("Assignment", NULL, tags$strong(if (isTRUE(summary$assignment_preserved[[1]])) "Preserved" else "Missing"), tags$p("ITT anchor"))
      )
    })
    output$completed_readiness_table <- renderUI({
      a <- completed_assessment()
      if (is.null(a)) return(ui_empty_state("No completed-experiment readiness yet.", "Assess completed experiment readiness."))
      causal_render_table(a$readiness, "No readiness assessment.")
    })
    output$completed_reconciliation_table <- renderUI({
      a <- completed_assessment()
      if (is.null(a)) return(ui_empty_state("No execution reconciliation yet.", "Assess completed experiment readiness."))
      causal_render_table(a$reconciliation, "No execution reconciliation.")
    })
    output$completed_integrity_table <- renderUI({
      a <- completed_assessment()
      if (is.null(a)) return(ui_empty_state("No integrity diagnostics yet.", "Assess completed experiment readiness."))
      rows <- data.table::rbindlist(list(
        data.table::data.table(topic = "fidelity", status = a$fidelity$fidelity_status[[1]] %||% "unknown", finding = a$fidelity$reasons[[1]] %||% ""),
        data.table::data.table(topic = "estimand", status = a$estimand$estimand_preservation_status[[1]] %||% "unknown", finding = a$estimand$reasons[[1]] %||% ""),
        data.table::data.table(topic = "guardrails", status = a$guardrails$guardrail_status[[1]] %||% "unknown", finding = a$guardrails$finding[[1]] %||% "")
      ), use.names = TRUE, fill = TRUE)
      causal_render_table(rows, "No integrity diagnostics.")
    })
    output$completed_campaign_seeds_table <- renderUI({
      causal_render_table(causal_completed_experiment_campaign_seeds(ctx$causal_completed_experiment_state()), "No completed-evidence campaign seeds.")
    })
    itt_record <- reactive({
      state <- causal_itt_normalize(ctx$causal_itt_state())
      state$results[[causal_itt_active_id(state)]]
    })
    output$itt_summary_cards <- renderUI({
      summary <- causal_itt_summary(ctx$causal_itt_state())
      tags$div(
        class = "aq-metric-grid",
        ui_card("Specs", NULL, tags$strong(summary$specs[[1]]), tags$p("frozen requests")),
        ui_card("Status", NULL, tags$strong(ui_display_label(summary$analysis_status[[1]])), tags$p(if (isTRUE(summary$effect_estimated[[1]])) "effect estimated" else "not estimated")),
        ui_card("Materiality", NULL, tags$strong(ui_display_label(summary$materiality_state[[1]])), tags$p("separate from p-values")),
        ui_card("Review", NULL, tags$strong(ui_display_label(summary$review_status[[1]])), tags$p(paste(summary$registered_artifacts[[1]], "artifact(s)"))),
        ui_card("Design Depth", NULL, tags$strong(ui_display_label(summary$design_depth_status[[1]])), tags$p(paste(summary$robustness_rows[[1]], "robustness row(s)"))),
        ui_card("Report", NULL, tags$strong(ui_display_label(summary$causal_report_status[[1]])), tags$p("causal evidence contract"))
      )
    })
    output$itt_gate_table <- renderUI({
      record <- itt_record()
      if (is.null(record) || is.null(record$result)) return(ui_empty_state("No ITT readiness gate yet.", "Run ITT Analysis after saving the spec."))
      causal_render_table(record$result$gate, "No ITT readiness gate.")
    })
    output$itt_primary_table <- renderUI({
      record <- itt_record()
      if (is.null(record) || is.null(record$result) || !isTRUE(record$result$effect_estimated)) return(ui_empty_state("No ITT effect estimate.", "Resolve readiness blockers and rerun."))
      rows <- data.table::rbindlist(list(record$result$primary_estimate, record$result$adjusted_estimate), use.names = TRUE, fill = TRUE)
      causal_render_table(rows, "No primary effect estimate.")
    })
    output$itt_design_methods_table <- renderUI({
      record <- itt_record()
      depth <- record$design_depth %||% NULL
      if (is.null(depth)) return(ui_empty_state("No design-aware method evidence.", "Run ITT Analysis with the updated AutoQuant Phase 5 API installed."))
      causal_render_table(depth$method_eligibility, "No method eligibility evidence.")
    })
    output$itt_robustness_table <- renderUI({
      record <- itt_record()
      depth <- record$design_depth %||% NULL
      if (is.null(depth)) return(ui_empty_state("No robustness matrix.", "Run ITT Analysis after selecting eligible design-aware methods."))
      causal_render_table(depth$robustness_matrix, "No robustness matrix.")
    })
    output$itt_design_evidence_table <- renderUI({
      record <- itt_record()
      depth <- record$design_depth %||% NULL
      if (is.null(depth)) return(ui_empty_state("No design-depth diagnostics.", "Run ITT Analysis with design-aware settings."))
      rows <- data.table::rbindlist(list(
        data.table::as.data.table(depth$carryover),
        data.table::as.data.table(depth$multiplicity),
        data.table::as.data.table(depth$guardrail_decision),
        data.table::as.data.table(depth$materiality_regions)
      ), use.names = TRUE, fill = TRUE)
      causal_render_table(rows, "No design-depth diagnostics.")
    })
    output$itt_report_sections_table <- renderUI({
      record <- itt_record()
      report <- record$causal_report %||% NULL
      if (is.null(report)) return(ui_empty_state("No causal report contract.", "Run ITT Analysis after design-depth evidence is available."))
      causal_render_table(report$sections, "No causal report sections.")
    })
    output$itt_evidence_table <- renderUI({
      record <- itt_record()
      if (is.null(record) || is.null(record$result) || !isTRUE(record$result$effect_estimated)) return(ui_empty_state("No sensitivity evidence yet.", "Run a successful ITT analysis."))
      rows <- data.table::rbindlist(list(
        data.table::as.data.table(record$result$materiality),
        data.table::as.data.table(record$result$sensitivity),
        data.table::as.data.table(record$result$guardrails)
      ), use.names = TRUE, fill = TRUE)
      causal_render_table(rows, "No sensitivity, materiality, or guardrail evidence.")
    })
    output$itt_claims_table <- renderUI({
      record <- itt_record()
      if (is.null(record) || is.null(record$result)) return(ui_empty_state("No claim boundaries yet.", "Run ITT Analysis."))
      rows <- data.table::rbindlist(list(
        data.table::data.table(claim_type = "permitted", claim = record$result$permitted_claims %||% character()),
        data.table::data.table(claim_type = "prohibited", claim = record$result$prohibited_claims %||% character())
      ), use.names = TRUE, fill = TRUE)
      causal_render_table(rows, "No claim boundaries.")
    })
    output$itt_campaign_seeds_table <- renderUI({
      causal_render_table(causal_itt_campaign_seeds(ctx$causal_itt_state()), "No ITT campaign seeds.")
    })
  })
}
