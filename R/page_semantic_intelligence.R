semantic_intelligence_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_decision_context",
      "aq_assess_decision_alternatives",
      "aq_assess_decision_optionality",
      "aq_decision_context_artifact",
      "aq_review_decision",
      "aq_decision_timeline",
      "aq_decision_learning_summary",
      "aq_decision_memory_artifact"
    ) %in% getNamespaceExports("AutoQuant"))
}

semantic_intelligence_demo_context <- function() {
  if (!semantic_intelligence_available()) {
    return(NULL)
  }
  AutoQuant::aq_decision_context(
    context = list(
      decision_context_id = "semantic_demo_budget_decision",
      title = "Next best governed action",
      decision_question = "Should the project keep the current policy, collect more evidence, or pilot a bounded change?",
      authority = "human_review",
      coverage = "project_scope",
      status = "draft"
    ),
    alternatives = list(
      list(alternative_id = "alt_current_policy", name = "Continue current policy", alternative_type = "do_nothing", baseline = TRUE, authority_compatible = TRUE, scope_compatible = TRUE),
      list(alternative_id = "alt_collect_more_evidence", name = "Collect more evidence", alternative_type = "collect_more_evidence", baseline = FALSE, authority_compatible = TRUE, scope_compatible = TRUE),
      list(alternative_id = "alt_bounded_pilot", name = "Run bounded pilot", alternative_type = "pilot", baseline = FALSE, authority_compatible = FALSE, scope_compatible = TRUE, coverage_limitation = "Requires explicit approval before execution")
    ),
    criteria = list(
      list(criterion_id = "criterion_expected_value", name = "Expected value", direction = "maximize", weight = 0.45),
      list(criterion_id = "criterion_authority", name = "Authority compatibility", direction = "maximize", hard_constraint = TRUE),
      list(criterion_id = "criterion_learning", name = "Learning value", direction = "maximize", weight = 0.25)
    ),
    financial_impacts = list(
      list(financial_id = "fin_current", alternative_id = "alt_current_policy", recurring_cost = 100, expected_benefit = 108, opportunity_cost = 10, source_type = "baseline"),
      list(financial_id = "fin_evidence", alternative_id = "alt_collect_more_evidence", initial_cost = 5, recurring_cost = 100, expected_benefit = 112, source_type = "diagnostic"),
      list(financial_id = "fin_pilot", alternative_id = "alt_bounded_pilot", initial_cost = 15, recurring_cost = 120, expected_benefit = 150, downside_estimate = -25, upside_estimate = 50, source_type = "scenario_assumption")
    ),
    uncertainties = list(
      list(uncertainty_id = "unc_pilot_transfer", alternative_id = "alt_bounded_pilot", uncertainty_category = "transfer_uncertainty", reducibility = "reducible", decision_sensitivity = "high", candidate_experiment = "bounded pilot"),
      list(uncertainty_id = "unc_evidence_quality", alternative_id = "alt_collect_more_evidence", uncertainty_category = "measurement_uncertainty", reducibility = "partially_reducible", decision_sensitivity = "medium", candidate_experiment = "additional diagnostics")
    ),
    optionality = list(
      list(optionality_id = "opt_pilot_learning", alternative_id = "alt_bounded_pilot", option_type = "learn", future_decisions_enabled = list(c("expand", "abandon")), reversibility = TRUE, confidence = 0.6),
      list(optionality_id = "opt_evidence_defer", alternative_id = "alt_collect_more_evidence", option_type = "defer", future_decisions_enabled = list("stage"), reversibility = TRUE, confidence = 0.55)
    ),
    recommendations = list(
      recommendation_id = "rec_collect_more_evidence",
      preferred_alternative_id = "alt_collect_more_evidence",
      viable_alternatives = list(c("alt_current_policy", "alt_bounded_pilot")),
      recommendation_category = "collect_more_evidence",
      evidence_basis = "Project evidence is not yet sufficient for a bounded pilot.",
      required_approvers = list("human_review")
    ),
    decisions = list(
      decision_id = "semantic_demo_decision",
      selected_alternative_id = "alt_collect_more_evidence",
      alternatives_considered = list(c("alt_current_policy", "alt_collect_more_evidence", "alt_bounded_pilot")),
      decision = "approved",
      approver = "human_review",
      review_date = as.character(Sys.Date() + 30)
    ),
    outcomes = list(
      outcome_review_id = "semantic_demo_outcome_pending",
      decision_id = "semantic_demo_decision",
      actual_execution_state = "not_started",
      realized_outcomes = NA_character_
    )
  )
}

semantic_intelligence_status <- function(ctx) {
  artifacts <- ctx$all_artifacts()
  collector <- ctx$project_collector_summary()
  data <- ctx$data()
  workspace <- tryCatch(ctx$semantic_workspace(), error = function(e) semantic_workspace_empty())
  workspace_objects <- semantic_workspace_objects_table(workspace)
  list(
    has_autoquant = semantic_intelligence_available(),
    has_data = !is.null(data),
    artifact_count = length(artifacts),
    semantic_object_count = nrow(workspace_objects),
    semantic_review_count = sum(workspace_objects$status == "review", na.rm = TRUE),
    semantic_draft_count = sum(workspace_objects$status == "draft", na.rm = TRUE),
    collector_status = if (nrow(collector)) collector$collector_status[[1]] %||% "not_created" else "not_created",
    recommendation = if (length(artifacts)) {
      "Review project evidence and create a decision context around the next business question."
    } else if (!is.null(data)) {
      "Run Explore Data or Model Readiness before forming a decision recommendation."
    } else {
      "Load data or open a project, then build evidence before deciding."
    }
  )
}

semantic_intelligence_demo_review <- function(decision) {
  AutoQuant::aq_review_decision(
    decision,
    decision_id = "semantic_demo_decision",
    realized_outcome = "Decision memory demo outcome recorded for project lifecycle validation.",
    actual_value = 14,
    lessons_learned = "Durable reviews preserve why a recommendation did or did not hold.",
    strategy_implications = "Use evidence-backed decisions as reusable but context-bounded organizational memory.",
    lever_implications = "Levers should remain governed by authority and coverage.",
    assumption_updates = "Demo assumptions held for lifecycle wiring.",
    future_recommendations = "Review memory artifacts before promoting decision patterns.",
    assumption_status = "held"
  )
}

semantic_intelligence_memory_app_artifact <- function(decision, review) {
  timeline <- AutoQuant::aq_decision_timeline(decision, review)
  learning <- AutoQuant::aq_decision_learning_summary(decision, review)
  aq_memory <- AutoQuant::aq_decision_memory_artifact(decision, review)
  artifact_id <- paste0("semantic_decision_memory_", decision$decision_context_id)
  create_artifact(
    artifact_id = artifact_id,
    artifact_type = "table",
    label = "Decision Lifecycle Memory",
    source_module = "semantic_intelligence",
    object = timeline,
    content = "Durable decision timeline and organizational learning summary.",
    metadata = list(
      module_id = "semantic_intelligence",
      module_run_id = paste0("semantic_intelligence_", format(Sys.time(), "%Y%m%d%H%M%S")),
      source_module = "semantic_intelligence",
      original_name = "decision_memory",
      original_section = "Decision Memory",
      normalized_section = "Decision Memory",
      artifact_index = 1L,
      created_by_module = TRUE,
      generated_at = Sys.time(),
      run_timestamp = Sys.time(),
      analytical_intent = "Decision",
      artifact_importance = "critical",
      caption = "Decision lifecycle timeline and organizational learning.",
      diagnostics = c("Generated from deterministic AutoQuant decision lifecycle contracts."),
      recommendations = learning$recommendation[[1]],
      decision_context_id = decision$decision_context_id,
      review_id = review$review_id[[1]],
      review_status = review$review_status[[1]],
      learning_state = learning$learning_state[[1]],
      autoquant_artifact_id = aq_memory$id %||% NA_character_,
      supported_actions = aq_memory$metadata$supported_actions %||% character()
    ),
    section = "Decision Memory",
    order = 1L
  )
}

semantic_decision_lifecycle_authoring_ui <- function(ns) {
  ui_card(
    "Authored Decision Lifecycle",
    "Create the full decision package from project-authored inputs. AutoQuant validates and assesses; the app authors and preserves.",
    uiOutput(ns("authored_decision_summary")),
    ui_disclosure(
      "Context",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("decision_context_id"), "Decision ID", placeholder = "decision_next_quarter_budget"),
        textInput(ns("decision_title"), "Decision Title", placeholder = "Next-quarter budget decision"),
        textInput(ns("decision_question"), "Decision Question", placeholder = "What should we do next?"),
        textInput(ns("decision_owner"), "Owner", placeholder = "Marketing"),
        textInput(ns("decision_domain"), "Decision Domain", placeholder = "marketing"),
        textInput(ns("decision_scope"), "Organizational Scope", placeholder = "function"),
        textInput(ns("decision_objectives"), "Objective IDs", placeholder = "objective_revenue_growth"),
        textInput(ns("decision_strategies"), "Strategy IDs", placeholder = "strategy_qualified_demand"),
        textInput(ns("decision_tactics"), "Tactic IDs", placeholder = "tactic_paid_search"),
        textInput(ns("decision_levers"), "Lever IDs", placeholder = "lever_paid_search_budget"),
        textInput(ns("decision_kpis"), "KPI IDs", placeholder = "kpi_revenue"),
        textInput(ns("decision_authority"), "Authority ID", placeholder = "authority_marketing_advisory"),
        textInput(ns("decision_coverage"), "Coverage ID", placeholder = "coverage_marketing"),
        textInput(ns("decision_deadline"), "Deadline", placeholder = as.character(Sys.Date() + 30)),
        textInput(ns("decision_horizon"), "Time Horizon", placeholder = "quarter"),
        textInput(ns("decision_review_cadence"), "Review Cadence", placeholder = "monthly")
      ),
      textAreaInput(ns("decision_description"), "Description", rows = 2),
      ui_action_row(actionButton(ns("save_decision_context"), "Save Context", class = "btn-primary btn-sm")),
      open = TRUE
    ),
    ui_disclosure(
      "Alternatives And Lever Changes",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("alternative_id"), "Alternative ID", placeholder = "alt_current_policy"),
        textInput(ns("alternative_name"), "Alternative Name", placeholder = "Continue current policy"),
        selectInput(ns("alternative_type"), "Alternative Type", choices = c("do_nothing", "defer", "pilot", "partial_implementation", "full_implementation", "expand", "contract", "abandon", "switch", "staged_implementation", "custom")),
        checkboxInput(ns("alternative_baseline"), "Current-policy baseline", value = TRUE),
        checkboxInput(ns("alternative_authority"), "Authority compatible", value = TRUE),
        checkboxInput(ns("alternative_scope"), "Coverage compatible", value = TRUE),
        textInput(ns("alternative_levers"), "Affected Levers", placeholder = "lever_paid_search_budget"),
        textInput(ns("alternative_evidence"), "Evidence References", placeholder = "artifact_id, memory_id")
      ),
      ui_action_row(actionButton(ns("save_alternative"), "Save Alternative", class = "btn-primary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("setting_id"), "Lever Setting ID", placeholder = "setting_alt_current_policy_budget"),
        textInput(ns("setting_alternative_id"), "Alternative ID", placeholder = "alt_current_policy"),
        textInput(ns("setting_lever_id"), "Lever ID", placeholder = "lever_paid_search_budget"),
        numericInput(ns("setting_current_value"), "Current Value", value = NA),
        numericInput(ns("setting_proposed_value"), "Proposed Value", value = NA),
        textInput(ns("setting_unit"), "Unit", placeholder = "USD"),
        numericInput(ns("setting_permitted_min"), "Permitted Min", value = NA),
        numericInput(ns("setting_permitted_max"), "Permitted Max", value = NA),
        numericInput(ns("setting_validated_min"), "Validated Min", value = NA),
        numericInput(ns("setting_validated_max"), "Validated Max", value = NA),
        checkboxInput(ns("setting_actionable"), "Actionable under current authority", value = TRUE)
      ),
      ui_action_row(actionButton(ns("save_lever_setting"), "Save Lever Setting", class = "btn-secondary btn-sm"))
    ),
    ui_disclosure(
      "Criteria And Economics",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("criterion_id"), "Criterion ID", placeholder = "criterion_value"),
        textInput(ns("criterion_name"), "Criterion Name", placeholder = "Expected value"),
        selectInput(ns("criterion_direction"), "Direction", choices = c("maximize", "minimize", "target")),
        numericInput(ns("criterion_weight"), "Weight", value = NA),
        checkboxInput(ns("criterion_hard"), "Hard constraint", value = FALSE),
        numericInput(ns("criterion_confidence"), "Confidence", value = NA)
      ),
      textAreaInput(ns("criterion_definition"), "Criterion Definition", rows = 2),
      ui_action_row(actionButton(ns("save_criterion"), "Save Criterion", class = "btn-primary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("financial_id"), "Financial ID", placeholder = "fin_current"),
        textInput(ns("financial_alternative_id"), "Alternative ID", placeholder = "alt_current_policy"),
        numericInput(ns("financial_initial_cost"), "Initial Cost", value = NA),
        numericInput(ns("financial_recurring_cost"), "Recurring Cost", value = NA),
        numericInput(ns("financial_expected_benefit"), "Expected Benefit", value = NA),
        numericInput(ns("financial_downside"), "Downside Scenario", value = NA),
        numericInput(ns("financial_upside"), "Upside Scenario", value = NA),
        numericInput(ns("financial_confidence"), "Confidence", value = NA),
        selectInput(ns("financial_source_type"), "Source Type", choices = c("observed", "modeled", "forecast", "scenario_assumption", "expert_judgment", "imported_evidence", "unknown"))
      ),
      ui_action_row(actionButton(ns("save_financial"), "Save Financial Evidence", class = "btn-secondary btn-sm"))
    ),
    ui_disclosure(
      "Uncertainty And Optionality",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("uncertainty_id"), "Uncertainty ID", placeholder = "unc_response"),
        textInput(ns("uncertainty_alternative_id"), "Alternative ID", placeholder = "alt_increase"),
        textInput(ns("uncertainty_criterion_id"), "Criterion ID", placeholder = "criterion_value"),
        selectInput(ns("uncertainty_category"), "Category", choices = c("model", "parameter", "causal", "execution", "cost", "timing", "measurement", "environmental", "transfer", "regulatory", "strategic")),
        selectInput(ns("uncertainty_direction"), "Direction", choices = c("two_sided", "upside", "downside", "unknown")),
        selectInput(ns("uncertainty_magnitude"), "Magnitude", choices = c("low", "medium", "high", "unknown")),
        selectInput(ns("uncertainty_reducibility"), "Reducibility", choices = c("reducible", "partially_reducible", "irreducible", "unknown")),
        selectInput(ns("uncertainty_sensitivity"), "Decision Sensitivity", choices = c("low", "medium", "high", "unknown")),
        textInput(ns("uncertainty_experiment"), "Candidate Experiment", placeholder = "bounded pilot")
      ),
      ui_action_row(actionButton(ns("save_uncertainty"), "Save Uncertainty", class = "btn-primary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("optionality_id"), "Optionality ID", placeholder = "opt_learn"),
        textInput(ns("optionality_alternative_id"), "Alternative ID", placeholder = "alt_increase"),
        selectInput(ns("optionality_type"), "Option Type", choices = c("defer", "expand", "contract", "abandon", "switch", "stage", "learn", "growth", "compound")),
        textInput(ns("optionality_enabling_action"), "Enabling Action", placeholder = "bounded pilot"),
        textInput(ns("optionality_future_decisions"), "Future Decisions Enabled", placeholder = "expand,abandon"),
        textInput(ns("optionality_foreclosed"), "Options Foreclosed", placeholder = "near_term_growth"),
        checkboxInput(ns("optionality_reversible"), "Reversible", value = TRUE),
        numericInput(ns("optionality_confidence"), "Confidence", value = NA)
      ),
      ui_action_row(actionButton(ns("save_optionality"), "Save Optionality", class = "btn-secondary btn-sm"))
    ),
    ui_disclosure(
      "Assessment, Decision, And Review",
      ui_action_row(
        actionButton(ns("assess_authored_decision"), "Assess Authored Decision", class = "btn-primary btn-sm"),
        actionButton(ns("record_authored_recommendation"), "Record Recommendation", class = "btn-secondary btn-sm"),
        actionButton(ns("register_authored_decision_artifacts"), "Register Artifacts", class = "btn-secondary btn-sm")
      ),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("human_decision_id"), "Decision ID", placeholder = "decision_budget_approval"),
        textInput(ns("selected_alternative_id"), "Selected Alternative ID", placeholder = "alt_increase"),
        selectInput(ns("human_decision_status"), "Human Decision", choices = c("accepted", "rejected", "modified", "deferred", "request_more_evidence", "escalated", "retain_baseline", "approved", "awaiting_approval")),
        textInput(ns("human_approver"), "Approver", placeholder = "CMO"),
        textInput(ns("human_review_date"), "Review Date", placeholder = as.character(Sys.Date() + 30)),
        textInput(ns("human_conditions"), "Conditions", placeholder = "monitor weekly")
      ),
      textAreaInput(ns("human_rationale"), "Decision Rationale", rows = 2),
      ui_action_row(actionButton(ns("save_human_decision"), "Save Human Decision", class = "btn-primary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("review_id"), "Review ID", placeholder = "review_budget_outcome"),
        numericInput(ns("review_actual_value"), "Actual Value", value = NA),
        selectInput(ns("review_execution_state"), "Execution State", choices = c("not_started", "implemented", "partial", "cancelled", "blocked")),
        selectInput(ns("review_assumption_status"), "Assumption Status", choices = c("held", "partial", "failed", "unknown"))
      ),
      textAreaInput(ns("review_realized_outcome"), "Realized Outcome", rows = 2),
      textAreaInput(ns("review_lessons"), "Lessons Learned", rows = 2),
      ui_action_row(actionButton(ns("save_outcome_review"), "Save Outcome Review", class = "btn-secondary btn-sm"))
    ),
    uiOutput(ns("authored_decision_message"))
  )
}

semantic_intelligence_decision_service_result <- function(artifact) {
  service_result(
    status = "success",
    artifacts = list(artifact),
    messages = "Decision memory artifact registered.",
    metadata = list(
      module_id = "semantic_intelligence",
      module_run_id = artifact$metadata$module_run_id,
      generated_at = Sys.time(),
      source_package = "AutoQuant",
      source_function = "aq_decision_memory_artifact",
      configured_inputs = list(decision_context_id = artifact$metadata$decision_context_id),
      artifact_count = 1L,
      plot_count = 0L,
      table_count = 1L,
      text_count = 0L,
      report_plan_count = 0L
    )
  )
}

page_semantic_intelligence_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    title = "Semantic Intelligence",
    value = "semantic_intelligence",
    ui_page(
      "Semantic Intelligence",
      "Connect business intent, variable semantics, evidence, alternatives, and governed decisions.",
      eyebrow = "DECISIONS",
      ui_workspace_grid(
        columns = "two",
        ui_card(
          "Business Workspace",
          "Author the organization's mission, objectives, strategies, tactics, levers, KPIs, assumptions, authority, and coverage.",
          uiOutput(ns("business_workspace_status")),
          tags$div(
            class = "aq-form-grid",
            selectInput(ns("object_type"), "Object Type", choices = semantic_object_types(), selected = "objective"),
            selectInput(ns("object_status"), "Status", choices = semantic_object_statuses(), selected = "draft"),
            textInput(ns("object_id"), "Object ID", placeholder = "Leave blank to generate"),
            textInput(ns("object_title"), "Title", placeholder = "e.g. Increase revenue"),
            textInput(ns("object_owner"), "Owner", placeholder = "e.g. Marketing"),
            textInput(ns("object_tags"), "Tags", placeholder = "comma,separated,tags")
          ),
          textAreaInput(ns("object_description"), "Description", rows = 3),
          ui_action_row(
            actionButton(ns("save_object"), "Save Object", class = "btn-primary btn-sm"),
            actionButton(ns("approve_object"), "Approve", class = "btn-secondary btn-sm"),
            actionButton(ns("archive_object"), "Archive", class = "btn-secondary btn-sm")
          ),
          uiOutput(ns("business_workspace_message"))
        ),
        ui_card(
          "Relationship Editor",
          "Connect authored objects into a deterministic organizational model.",
          tags$div(
            class = "aq-form-grid",
            selectInput(ns("relationship_type"), "Relationship", choices = semantic_relationship_types(), selected = "objective_strategy"),
            selectInput(ns("relationship_from"), "From", choices = character()),
            selectInput(ns("relationship_to"), "To", choices = character())
          ),
          ui_action_row(actionButton(ns("save_relationship"), "Save Relationship", class = "btn-primary btn-sm")),
          uiOutput(ns("relationship_message")),
          uiOutput(ns("relationship_map"))
        )
      ),
      semantic_decision_lifecycle_authoring_ui(ns),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          "Decision Workbench",
          "A governed decision is an alternative set, not just a model recommendation.",
          uiOutput(ns("decision_status")),
          uiOutput(ns("decision_recommendation")),
          ui_callout("Authored lifecycle", "Use the Authored Decision Lifecycle section to assess alternatives, record recommendations and decisions, attach outcomes, and register memory artifacts.", status = "info"),
          uiOutput(ns("decision_memory_status"))
        ),
        ui_card(
          "Semantic Signals",
          "Current project evidence that can feed decision context.",
          uiOutput(ns("semantic_signals"))
        )
      ),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          "Integrity Validation",
          "Actionable diagnostics for missing links, broken references, orphaned objects, and draft governance.",
          uiOutput(ns("workspace_validation"))
        ),
        ui_card(
          "Search",
          "Deterministic search over authored organizational knowledge.",
          tags$div(
            class = "aq-form-grid",
            textInput(ns("search_query"), "Query", placeholder = "objective, owner, status, tag..."),
            selectInput(ns("search_type"), "Type", choices = c("all", semantic_object_types()), selected = "all"),
            selectInput(ns("search_status"), "Status", choices = c("all", semantic_object_statuses()), selected = "all")
          ),
          uiOutput(ns("search_results"))
        )
      ),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          "Alternative Assessment",
          "Deterministic tradeoff evidence from the canonical AutoQuant contract.",
          uiOutput(ns("alternative_assessment"))
        ),
        ui_card(
          "Optionality",
          "Future choices created, preserved, constrained, or foreclosed.",
          uiOutput(ns("optionality_assessment"))
        )
      ),
      ui_card(
        "Version History",
        "Created, modified, approved, archived, restored, superseded, and relationship-change events.",
        uiOutput(ns("version_history"))
      ),
      ui_card(
        "Decision Artifact Contract",
        "Canonical artifact metadata available to reports, collectors, campaigns, and GenAI context.",
        uiOutput(ns("decision_artifact"))
      ),
      ui_workspace_grid(
        columns = "two",
        ui_card(
          "Decision Timeline",
          "Durable context, recommendation, decision, outcome, and learning events.",
          uiOutput(ns("decision_timeline"))
        ),
        ui_card(
          "Learning Summary",
          "Outcome evidence that can later inform campaigns, reports, and bounded GenAI context.",
          uiOutput(ns("decision_learning"))
        )
      )
    )
  )
}

page_semantic_intelligence_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    state <- reactive(semantic_intelligence_status(ctx))
    workspace <- reactive(ctx$semantic_workspace())
    workspace_objects <- reactive(semantic_workspace_objects_table(workspace()))
    decision_state <- reactive(semantic_decision_normalize(ctx$semantic_decision_state()))
    active_decision_id <- reactive(semantic_decision_active_context_id(decision_state()))
    authored_decision <- reactive({
      result <- semantic_decision_build_autoquant(decision_state(), workspace())
      if (identical(result$status, "success")) result$value else NULL
    })

    observe({
      objects <- workspace_objects()
      choices <- if (nrow(objects)) stats::setNames(objects$object_id, paste(objects$title, "(", objects$object_type, ")")) else character()
      updateSelectInput(session, "relationship_from", choices = choices)
      updateSelectInput(session, "relationship_to", choices = choices)
    })

    output$decision_status <- renderUI({
      status <- state()
      if (!isTRUE(status$has_autoquant)) {
        return(ui_callout("AutoQuant decision API unavailable", "Install or refresh AutoQuant to enable Semantic Intelligence decision contracts.", status = "warning"))
      }
      decision <- authored_decision()
      if (is.null(decision)) return(ui_empty_state("No authored decision is assessment-ready.", "Create a decision context and alternatives in the authored lifecycle section."))
      validation <- semantic_decision_validate(decision_state(), workspace())
      assessment <- decision_state()$assessments[[active_decision_id()]]
      ui_stat_grid(
        ui_stat_tile("Contract", "Ready", status = "success", detail = "AutoQuant decision API"),
        ui_stat_tile("Question", decision$context$decision_question[[1]], status = "info"),
        ui_stat_tile("Alternatives", nrow(decision$alternatives), status = "info", detail = "including baseline"),
        ui_stat_tile("Assessment", if (is.null(assessment)) "Not Assessed" else if (identical(assessment$signature, semantic_decision_signature(decision_state(), active_decision_id()))) "Current" else "Stale", status = if (is.null(assessment)) "neutral" else if (identical(assessment$signature, semantic_decision_signature(decision_state(), active_decision_id()))) "success" else "warning"),
        ui_stat_tile("Validation", if (any(validation$status == "error")) "Blocked" else if (any(validation$status == "warning")) "Needs Review" else "Pass", status = if (any(validation$status == "error")) "error" else if (any(validation$status == "warning")) "warning" else "success")
      )
    })

    output$decision_recommendation <- renderUI({
      status <- state()
      ui_callout("Recommended next step", status$recommendation, status = if (status$artifact_count > 0L) "success" else "info")
    })

    output$authored_decision_summary <- renderUI({
      summary <- semantic_decision_summary(decision_state())
      ui_stat_grid(
        ui_stat_tile("Contexts", summary$contexts[[1]], status = if (summary$contexts[[1]] > 0L) "success" else "neutral"),
        ui_stat_tile("Alternatives", summary$alternatives[[1]], status = if (summary$alternatives[[1]] > 1L) "success" else "warning"),
        ui_stat_tile("Criteria", summary$criteria[[1]], status = if (summary$criteria[[1]] > 0L) "success" else "warning"),
        ui_stat_tile("Economics", summary$financial_impacts[[1]], status = if (summary$financial_impacts[[1]] > 0L) "success" else "warning"),
        ui_stat_tile("Uncertainty", summary$uncertainties[[1]], status = if (summary$uncertainties[[1]] > 0L) "info" else "neutral"),
        ui_stat_tile("Optionality", summary$optionality[[1]], status = if (summary$optionality[[1]] > 0L) "info" else "neutral"),
        ui_stat_tile("Assessment", ui_status_label(summary$assessment_status[[1]]), status = if (identical(summary$assessment_status[[1]], "current")) "success" else if (identical(summary$assessment_status[[1]], "stale")) "warning" else "neutral")
      )
    })

    output$authored_decision_message <- renderUI({
      msg <- ctx$semantic_decision_message %||% "Author a context, baseline, alternatives, criteria, economics, uncertainty, and optionality before assessment."
      validation <- semantic_decision_validate(decision_state(), workspace())
      tagList(
        ui_callout("Decision lifecycle status", msg, status = if (any(validation$status == "error")) "warning" else "info"),
        render_table(validation, engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$semantic_signals <- renderUI({
      status <- state()
      memory <- ctx$decision_memory_summary()
      ui_stat_grid(
        ui_stat_tile("Data", if (status$has_data) "Loaded" else "Missing", status = if (status$has_data) "success" else "warning"),
        ui_stat_tile("Authored Objects", status$semantic_object_count, status = if (status$semantic_object_count > 0L) "success" else "neutral", detail = paste(status$semantic_draft_count, "draft,", status$semantic_review_count, "review")),
        ui_stat_tile("Artifacts", status$artifact_count, status = if (status$artifact_count > 0L) "success" else "neutral", detail = "project evidence"),
        ui_stat_tile("Collector", ui_status_label(status$collector_status), status = if (status$collector_status %in% c("success", "created", "restored")) "success" else "warning"),
        ui_stat_tile("Decision Memory", memory$memory_artifacts[[1]], status = if (memory$memory_artifacts[[1]] > 0L) "success" else "neutral", detail = paste(memory$reviews[[1]], "review(s)")),
        ui_stat_tile("GenAI Context", "Structured", status = "info", detail = "decision artifact ready")
      )
    })

    output$business_workspace_status <- renderUI({
      objects <- workspace_objects()
      validation <- semantic_workspace_validate(workspace())
      ui_stat_grid(
        ui_stat_tile("Objects", nrow(objects), status = if (nrow(objects)) "success" else "neutral"),
        ui_stat_tile("Drafts", sum(objects$status == "draft", na.rm = TRUE), status = "info"),
        ui_stat_tile("Review", sum(objects$status == "review", na.rm = TRUE), status = "warning"),
        ui_stat_tile("Diagnostics", sum(validation$status %in% c("warning", "error"), na.rm = TRUE), status = if (any(validation$status == "error")) "error" else if (any(validation$status == "warning")) "warning" else "success")
      )
    })

    output$business_workspace_message <- renderUI({
      msg <- ctx$semantic_workspace_message %||% "Create or select an object to begin authoring organizational knowledge."
      ui_callout("Workspace status", msg, status = "info")
    })

    output$relationship_message <- renderUI({
      msg <- ctx$semantic_relationship_message %||% "Relationships make the authored model usable by evidence routing, campaigns, and decisions."
      ui_callout("Relationship status", msg, status = "info")
    })

    output$relationship_map <- renderUI({
      rels <- workspace()$relationships %||% data.table::data.table()
      if (!nrow(rels)) return(ui_empty_state("No relationships yet.", "Link objectives, strategies, tactics, levers, KPIs, assumptions, and decisions."))
      render_table(rels[, .(relationship_type, from_id, to_id, status)], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$workspace_validation <- renderUI({
      validation <- semantic_workspace_validate(workspace())
      render_table(validation, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$search_results <- renderUI({
      results <- semantic_workspace_search(
        workspace(),
        query = input$search_query %||% "",
        object_type = input$search_type %||% "all",
        status = input$search_status %||% "all"
      )
      if (!nrow(results)) return(ui_empty_state("No matching objects.", "Adjust the deterministic search filters or author more records."))
      render_table(results, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$version_history <- renderUI({
      history <- workspace()$history %||% data.table::data.table()
      if (!nrow(history)) return(ui_empty_state("No history yet.", "Object creation, modification, approval, archival, and relationship events will appear here."))
      render_table(history[order(timestamp, decreasing = TRUE)][1:min(.N, 25L)], engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$decision_memory_status <- renderUI({
      memory <- ctx$decision_memory_summary()
      message <- ctx$decision_memory_state$message %||% "No durable decision memory has been registered yet."
      ui_callout(
        "Decision memory",
        paste(
          message,
          paste0("Contexts: ", memory$decision_contexts[[1]], "."),
          paste0("Reviews: ", memory$reviews[[1]], "."),
          paste0("Memory artifacts: ", memory$memory_artifacts[[1]], ".")
        ),
        status = if (memory$memory_artifacts[[1]] > 0L) "success" else if (memory$reviews[[1]] > 0L) "info" else "neutral"
      )
    })

    output$alternative_assessment <- renderUI({
      assessment <- decision_state()$assessments[[active_decision_id()]]
      if (is.null(assessment)) return(ui_empty_state("No authored assessment yet.", "Run Assess Authored Decision after authoring the package."))
      render_table(assessment$alternative_assessment, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$optionality_assessment <- renderUI({
      assessment <- decision_state()$assessments[[active_decision_id()]]
      if (is.null(assessment)) return(ui_empty_state("No optionality assessment yet.", "Run Assess Authored Decision after adding optionality records."))
      render_table(assessment$optionality_assessment, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$decision_artifact <- renderUI({
      decision <- authored_decision()
      if (is.null(decision)) return(ui_empty_state("No authored decision artifact.", "Author and validate a decision context first."))
      artifact <- AutoQuant::aq_decision_context_artifact(decision)
      metadata <- data.table::data.table(
        field = c("artifact_id", "artifact_type", "decision_context_id", "supported_actions", "producer"),
        value = c(
          artifact$id,
          artifact$metadata$artifact_type %||% "decision_context_artifact",
          artifact$metadata$decision_context_id %||% decision$decision_context_id,
          paste(artifact$metadata$supported_actions %||% character(), collapse = ", "),
          artifact$metadata$producer %||% "aq_decision_context_artifact"
        )
      )
      render_table(metadata, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$decision_timeline <- renderUI({
      decision <- authored_decision()
      if (is.null(decision)) return(ui_empty_state("No decision context.", "Author a decision context before reviewing the lifecycle."))
      timeline <- AutoQuant::aq_decision_timeline(decision, semantic_decision_rows(decision_state(), "reviews", active_decision_id()))
      render_table(timeline, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$decision_learning <- renderUI({
      decision <- authored_decision()
      review <- semantic_decision_rows(decision_state(), "reviews", active_decision_id())
      if (is.null(decision) || !nrow(review)) {
        return(ui_empty_state("No outcome review yet.", "Attach an outcome review to create organizational learning."))
      }
      learning <- AutoQuant::aq_decision_learning_summary(decision, review)
      render_table(learning, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    save_decision_row <- function(result) {
      if (identical(result$status, "success")) {
        ctx$semantic_decision_state(result$value)
        ctx$semantic_decision_message <- service_result_message(result)
      } else {
        ctx$semantic_decision_message <- paste(result$errors %||% result$warnings %||% "Decision lifecycle update failed.", collapse = " | ")
      }
    }

    observeEvent(input$save_decision_context, {
      context_id <- input$decision_context_id %||% ""
      if (!nzchar(context_id)) context_id <- semantic_workspace_slug(input$decision_title %||% "decision", "decision")
      row <- data.table::data.table(
        decision_context_id = context_id,
        title = input$decision_title %||% context_id,
        decision_question = input$decision_question %||% "",
        description = input$decision_description %||% "",
        owner = input$decision_owner %||% "",
        decision_domain = input$decision_domain %||% "",
        organizational_scope = input$decision_scope %||% "",
        objective_ids = input$decision_objectives %||% "",
        strategy_ids = input$decision_strategies %||% "",
        tactic_ids = input$decision_tactics %||% "",
        lever_ids = input$decision_levers %||% "",
        kpi_ids = input$decision_kpis %||% "",
        authority_id = input$decision_authority %||% "",
        coverage_id = input$decision_coverage %||% "",
        deadline = input$decision_deadline %||% "",
        time_horizon = input$decision_horizon %||% "",
        review_cadence = input$decision_review_cadence %||% "",
        status = "draft"
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "contexts", "decision_context_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$save_alternative, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        alternative_id = input$alternative_id %||% "",
        name = input$alternative_name %||% input$alternative_id %||% "",
        alternative_type = input$alternative_type %||% "custom",
        baseline = isTRUE(input$alternative_baseline),
        affected_levers = input$alternative_levers %||% "",
        evidence_refs = input$alternative_evidence %||% "",
        authority_compatible = isTRUE(input$alternative_authority),
        scope_compatible = isTRUE(input$alternative_scope),
        status = "draft"
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "alternatives", "alternative_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$save_lever_setting, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        setting_id = input$setting_id %||% "",
        alternative_id = input$setting_alternative_id %||% "",
        lever_id = input$setting_lever_id %||% "",
        current_value = input$setting_current_value,
        proposed_value = input$setting_proposed_value,
        unit = input$setting_unit %||% "",
        permitted_min = input$setting_permitted_min,
        permitted_max = input$setting_permitted_max,
        validated_min = input$setting_validated_min,
        validated_max = input$setting_validated_max,
        actionable = isTRUE(input$setting_actionable)
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "lever_settings", "setting_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$save_criterion, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        criterion_id = input$criterion_id %||% "",
        name = input$criterion_name %||% input$criterion_id %||% "",
        definition = input$criterion_definition %||% "",
        direction = input$criterion_direction %||% "maximize",
        weight = input$criterion_weight,
        hard_constraint = isTRUE(input$criterion_hard),
        confidence = input$criterion_confidence
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "criteria", "criterion_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$save_financial, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        financial_id = input$financial_id %||% "",
        alternative_id = input$financial_alternative_id %||% "",
        initial_cost = input$financial_initial_cost,
        recurring_cost = input$financial_recurring_cost,
        expected_benefit = input$financial_expected_benefit,
        downside_estimate = input$financial_downside,
        upside_estimate = input$financial_upside,
        confidence = input$financial_confidence,
        source_type = input$financial_source_type %||% "unknown"
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "financial_impacts", "financial_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$save_uncertainty, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        uncertainty_id = input$uncertainty_id %||% "",
        alternative_id = input$uncertainty_alternative_id %||% "",
        criterion_id = input$uncertainty_criterion_id %||% "",
        uncertainty_category = input$uncertainty_category %||% "unknown",
        direction = input$uncertainty_direction %||% "unknown",
        magnitude = input$uncertainty_magnitude %||% "unknown",
        reducibility = input$uncertainty_reducibility %||% "unknown",
        decision_sensitivity = input$uncertainty_sensitivity %||% "unknown",
        candidate_experiment = input$uncertainty_experiment %||% ""
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "uncertainties", "uncertainty_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$save_optionality, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        optionality_id = input$optionality_id %||% "",
        alternative_id = input$optionality_alternative_id %||% "",
        option_type = input$optionality_type %||% "learn",
        enabling_action = input$optionality_enabling_action %||% "",
        future_decisions_enabled = input$optionality_future_decisions %||% "",
        options_foreclosed = input$optionality_foreclosed %||% "",
        reversibility = isTRUE(input$optionality_reversible),
        confidence = input$optionality_confidence
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "optionality", "optionality_id", row, context_id))
    }, ignoreInit = TRUE)

    observeEvent(input$assess_authored_decision, {
      result <- semantic_decision_assess(decision_state(), workspace())
      save_decision_row(result)
    }, ignoreInit = TRUE)

    observeEvent(input$record_authored_recommendation, {
      result <- semantic_decision_record_recommendation(decision_state())
      save_decision_row(result)
    }, ignoreInit = TRUE)

    observeEvent(input$save_human_decision, {
      context_id <- active_decision_id()
      row <- data.table::data.table(
        decision_context_id = context_id,
        decision_id = input$human_decision_id %||% "",
        selected_alternative_id = input$selected_alternative_id %||% "",
        alternatives_considered = paste(semantic_decision_rows(decision_state(), "alternatives", context_id)$alternative_id, collapse = ","),
        decision = input$human_decision_status %||% "awaiting_approval",
        approver = input$human_approver %||% "",
        rationale = input$human_rationale %||% "",
        conditions = input$human_conditions %||% "",
        review_date = input$human_review_date %||% ""
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "decisions", "decision_id", row, context_id, "decided"))
    }, ignoreInit = TRUE)

    observeEvent(input$save_outcome_review, {
      context_id <- active_decision_id()
      decision <- authored_decision()
      if (is.null(decision)) {
        ctx$semantic_decision_message <- "Author a valid decision context before attaching an outcome review."
        return()
      }
      review <- AutoQuant::aq_review_decision(
        decision,
        review_id = input$review_id %||% NULL,
        actual_value = input$review_actual_value,
        realized_outcome = input$review_realized_outcome %||% "",
        actual_execution_state = input$review_execution_state %||% "not_started",
        lessons_learned = input$review_lessons %||% "",
        assumption_status = input$review_assumption_status %||% "unknown"
      )
      save_decision_row(semantic_decision_upsert_row(decision_state(), "reviews", "review_id", review, context_id, "reviewed"))
    }, ignoreInit = TRUE)

    observeEvent(input$register_authored_decision_artifacts, {
      result <- semantic_decision_register_artifacts(ctx, decision_state(), active_decision_id())
      ctx$semantic_decision_message <- service_result_message(result)
    }, ignoreInit = TRUE)

    observeEvent(input$save_object, {
      fields <- list(description = input$object_description %||% "")
      result <- semantic_workspace_upsert_object(
        workspace = workspace(),
        object_type = input$object_type,
        title = input$object_title,
        object_id = if (nzchar(input$object_id %||% "")) input$object_id else NULL,
        status = input$object_status,
        owner = input$object_owner,
        description = input$object_description,
        tags = trimws(strsplit(input$object_tags %||% "", ",", fixed = TRUE)[[1]]),
        fields = fields
      )
      if (identical(result$status, "success")) {
        ctx$semantic_workspace(result$value)
        ctx$semantic_workspace_message <- service_result_message(result)
      } else {
        ctx$semantic_workspace_message <- paste(result$errors, collapse = " | ")
      }
    }, ignoreInit = TRUE)

    observeEvent(input$approve_object, {
      target_id <- input$object_id %||% ""
      result <- semantic_workspace_transition_object(workspace(), target_id, "approved", "approved")
      if (identical(result$status, "success")) {
        ctx$semantic_workspace(result$value)
        ctx$semantic_workspace_message <- service_result_message(result)
      } else {
        ctx$semantic_workspace_message <- paste(result$errors, collapse = " | ")
      }
    }, ignoreInit = TRUE)

    observeEvent(input$archive_object, {
      target_id <- input$object_id %||% ""
      result <- semantic_workspace_transition_object(workspace(), target_id, "archived", "archived")
      if (identical(result$status, "success")) {
        ctx$semantic_workspace(result$value)
        ctx$semantic_workspace_message <- service_result_message(result)
      } else {
        ctx$semantic_workspace_message <- paste(result$errors, collapse = " | ")
      }
    }, ignoreInit = TRUE)

    observeEvent(input$save_relationship, {
      result <- semantic_workspace_add_relationship(
        workspace(),
        relationship_type = input$relationship_type,
        from_id = input$relationship_from,
        to_id = input$relationship_to
      )
      if (identical(result$status, "success")) {
        ctx$semantic_workspace(result$value)
        ctx$semantic_relationship_message <- service_result_message(result)
      } else {
        ctx$semantic_relationship_message <- paste(result$errors, collapse = " | ")
      }
    }, ignoreInit = TRUE)

  })
}

qa_semantic_intelligence_page <- function() {
  page_text <- paste(readLines(file.path("R", "page_semantic_intelligence.R"), warn = FALSE), collapse = "\n")
  rows <- list(
    data.table::data.table(suite = "semantic_intelligence_page", check = "page_defines_ui", status = if (grepl("page_semantic_intelligence_ui", page_text, fixed = TRUE)) "success" else "error", message = "Semantic Intelligence UI is defined."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "page_defines_server", status = if (grepl("page_semantic_intelligence_server", page_text, fixed = TRUE)) "success" else "error", message = "Semantic Intelligence server is defined."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "uses_autoquant_contract", status = if (grepl("aq_decision_context", page_text, fixed = TRUE) && grepl("aq_decision_context_artifact", page_text, fixed = TRUE)) "success" else "error", message = "Page uses AutoQuant decision contracts."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "uses_decision_lifecycle", status = if (grepl("aq_review_decision", page_text, fixed = TRUE) && grepl("aq_decision_memory_artifact", page_text, fixed = TRUE)) "success" else "error", message = "Page uses AutoQuant decision lifecycle contracts."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "collector_append", status = if (grepl("append_module_result_to_collector", page_text, fixed = TRUE)) "success" else "error", message = "Decision memory artifacts append through the existing collector path."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "project_memory_state", status = if (grepl("decision_memory_state", page_text, fixed = TRUE)) "success" else "error", message = "Page reads and writes durable project decision memory state."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "authored_workspace", status = if (grepl("semantic_workspace_upsert_object", page_text, fixed = TRUE) && grepl("semantic_workspace_add_relationship", page_text, fixed = TRUE)) "success" else "error", message = "Page supports project-authored semantic objects and relationships."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "workspace_validation_search_history", status = if (grepl("semantic_workspace_validate", page_text, fixed = TRUE) && grepl("semantic_workspace_search", page_text, fixed = TRUE) && grepl("version_history", page_text, fixed = TRUE)) "success" else "error", message = "Page exposes validation, deterministic search, and version history."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "authored_decision_lifecycle", status = if (grepl("semantic_decision_lifecycle_authoring_ui", page_text, fixed = TRUE) && grepl("assess_authored_decision", page_text, fixed = TRUE) && grepl("semantic_decision_build_autoquant", page_text, fixed = TRUE)) "success" else "error", message = "Page exposes the authored decision lifecycle and AutoQuant assessment path."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "no_production_demo_fallback", status = if (!grepl("actionButton\\(ns\\(\"save_demo_decision\"", page_text) && !grepl("observeEvent\\(input\\$save_demo_decision", page_text) && !grepl("observeEvent\\(input\\$attach_outcome_review", page_text) && !grepl("observeEvent\\(input\\$register_memory_artifact", page_text)) "success" else "error", message = "Production page no longer wires demo decision lifecycle fallbacks."),
    data.table::data.table(suite = "semantic_intelligence_page", check = "qa_autoquant_available", status = if (semantic_intelligence_available()) "success" else "warning", message = "Installed AutoQuant exposes decision-management exports.")
  )
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
