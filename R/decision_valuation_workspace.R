decision_valuation_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    all(c(
      "aq_decision_valuation_context",
      "aq_assess_alternative_economics",
      "aq_governed_decision_valuation_recommendation",
      "aq_decision_valuation_artifact"
    ) %in% getNamespaceExports("AutoQuant"))
}

decision_valuation_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "decision_valuation_workspace_v1",
    project_id = project_id,
    active_valuation_context_id = NA_character_,
    contexts = data.table::data.table(),
    cash_flows = data.table::data.table(),
    impact_mappings = data.table::data.table(),
    scenarios = data.table::data.table(),
    thresholds = data.table::data.table(),
    sensitivity_assumptions = data.table::data.table(),
    effort = data.table::data.table(),
    risks = data.table::data.table(),
    criteria_values = data.table::data.table(),
    results = list(),
    artifact_registry = character(),
    message = "Decision valuation has not been run.",
    history = data.table::data.table(
      event_id = character(),
      valuation_context_id = character(),
      event_type = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

decision_valuation_tables <- function() {
  c("contexts", "cash_flows", "impact_mappings", "scenarios", "thresholds", "sensitivity_assumptions", "effort", "risks", "criteria_values")
}

decision_valuation_now <- function() as.character(Sys.time())

decision_valuation_normalize <- function(state) {
  state <- state %||% decision_valuation_empty()
  empty <- decision_valuation_empty(state$project_id %||% NA_character_)
  for (name in names(empty)) {
    if (is.null(state[[name]])) state[[name]] <- empty[[name]]
  }
  for (table_name in decision_valuation_tables()) {
    if (!data.table::is.data.table(state[[table_name]])) state[[table_name]] <- data.table::as.data.table(state[[table_name]])
  }
  if (!data.table::is.data.table(state$history)) state$history <- data.table::as.data.table(state$history)
  state
}

decision_valuation_event <- function(valuation_context_id, event_type, summary) {
  data.table::data.table(
    event_id = paste0("decision_valuation_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    valuation_context_id = valuation_context_id %||% NA_character_,
    event_type = event_type,
    summary = summary %||% "",
    timestamp = decision_valuation_now()
  )
}

decision_valuation_upsert <- function(state, table_name, id_col, row, valuation_context_id = NULL, event_type = NULL) {
  state <- decision_valuation_normalize(state)
  if (!table_name %in% decision_valuation_tables()) {
    return(service_result(status = "error", errors = paste("Unsupported decision valuation table:", table_name)))
  }
  row <- data.table::as.data.table(row)
  if (!id_col %in% names(row) || !nzchar(row[[id_col]][[1]] %||% "")) {
    return(service_result(status = "error", errors = paste(id_col, "is required.")))
  }
  valuation_context_id <- valuation_context_id %||% row$valuation_context_id %||% state$active_valuation_context_id
  row[, updated_at := decision_valuation_now()]
  if (!"created_at" %in% names(row)) row[, created_at := updated_at]
  existing <- state[[table_name]]
  record_id <- row[[id_col]][[1]]
  was_existing <- nrow(existing) && id_col %in% names(existing) && record_id %in% existing[[id_col]]
  if (was_existing) {
    old <- existing[get(id_col) == record_id][1]
    row[, created_at := old$created_at %||% updated_at]
    existing <- existing[get(id_col) != record_id]
  }
  state[[table_name]] <- data.table::rbindlist(list(existing, row), use.names = TRUE, fill = TRUE)
  if (identical(table_name, "contexts")) state$active_valuation_context_id <- record_id
  state$history <- data.table::rbindlist(
    list(state$history, decision_valuation_event(valuation_context_id, event_type %||% if (was_existing) "modified" else "created", paste(if (was_existing) "Modified" else "Created", table_name, record_id))),
    use.names = TRUE,
    fill = TRUE
  )
  state$message <- paste("Saved", table_name, record_id)
  service_result(status = "success", value = state, messages = state$message, metadata = list(record_id = record_id, valuation_context_id = valuation_context_id))
}

decision_valuation_rows <- function(state, table_name, valuation_context_id = NULL) {
  state <- decision_valuation_normalize(state)
  rows <- state[[table_name]]
  if (!nrow(rows) || is.null(valuation_context_id) || !nzchar(valuation_context_id %||% "")) return(rows)
  target_valuation_context_id <- valuation_context_id
  if ("valuation_context_id" %in% names(rows)) rows[valuation_context_id == target_valuation_context_id] else rows
}

decision_valuation_active_id <- function(state) {
  state <- decision_valuation_normalize(state)
  id <- state$active_valuation_context_id %||% NA_character_
  if (nzchar(id)) return(id)
  if (nrow(state$contexts)) state$contexts$valuation_context_id[[1]] else NA_character_
}

decision_valuation_build_context <- function(state, semantic_decision_state = semantic_decision_empty()) {
  if (!decision_valuation_available()) {
    return(service_result(status = "warning", warnings = "AutoQuant decision valuation API is unavailable."))
  }
  state <- decision_valuation_normalize(state)
  id <- decision_valuation_active_id(state)
  contexts <- decision_valuation_rows(state, "contexts", id)
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  decision_context_id <- semantic_decision_active_context_id(decision_state)
  alternatives <- semantic_decision_rows(decision_state, "alternatives", decision_context_id)
  baseline <- if (nrow(alternatives) && any(vapply(alternatives$baseline %||% FALSE, semantic_decision_bool, logical(1L)))) {
    alternatives[vapply(baseline %||% FALSE, semantic_decision_bool, logical(1L)), alternative_id][[1]]
  } else {
    "baseline"
  }
  alt_ids <- if (nrow(alternatives)) alternatives$alternative_id else baseline
  row <- if (nrow(contexts)) contexts[1] else data.table::data.table()
  context <- AutoQuant::aq_decision_valuation_context(
    valuation_context_id = row$valuation_context_id %||% id %||% paste0("valuation_", decision_context_id),
    decision_context_id = row$decision_context_id %||% decision_context_id,
    decision_version = row$decision_version %||% NA_character_,
    alternatives_included = if (nzchar(row$alternatives_included %||% "")) semantic_decision_parse_list(row$alternatives_included) else alt_ids,
    baseline_alternative = row$baseline_alternative %||% baseline,
    objective_refs = semantic_decision_parse_list(row$objective_refs %||% ""),
    strategy_refs = semantic_decision_parse_list(row$strategy_refs %||% ""),
    tactic_refs = semantic_decision_parse_list(row$tactic_refs %||% ""),
    lever_refs = semantic_decision_parse_list(row$lever_refs %||% ""),
    time_horizon_periods = semantic_decision_numeric(row$time_horizon_periods %||% 1),
    period_unit = row$period_unit %||% "period",
    currency = row$currency %||% "USD",
    discount_rate = semantic_decision_numeric(row$discount_rate %||% 0),
    authority = row$authority %||% "",
    coverage = row$coverage %||% "",
    evidence_cutoff = row$evidence_cutoff %||% ""
  )
  service_result(status = "success", value = context, messages = "Decision valuation context built.")
}

decision_valuation_financial_cash_flows <- function(semantic_decision_state) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  fin <- semantic_decision_rows(decision_state, "financial_impacts", context_id)
  if (!nrow(fin)) return(data.table::data.table())
  rows <- list()
  for (i in seq_len(nrow(fin))) {
    row <- fin[i]
    add <- function(kind, amount) {
      rows[[length(rows) + 1L]] <<- data.table::data.table(
        cash_flow_id = paste(row$financial_id %||% paste0("financial_", i), kind, sep = "_"),
        valuation_context_id = NA_character_,
        alternative_id = row$alternative_id,
        cash_flow_type = kind,
        amount = amount,
        period = 0L,
        scenario = "base",
        source_type = switch(row$source_type %||% "missing",
          observed = "directly_observed",
          modeled = "predictively_modeled",
          imported_evidence = "imported_financial_input",
          unknown = "missing",
          row$source_type %||% "missing"
        ),
        evidence_reference = row$financial_id,
        confidence = row$confidence %||% NA_real_,
        limitation = "Imported from authored decision financial-impact inputs."
      )
    }
    add("investment", row$initial_cost %||% NA_real_)
    add("cost", row$recurring_cost %||% NA_real_)
    add("benefit", row$expected_benefit %||% NA_real_)
    add("downside", row$downside_estimate %||% NA_real_)
    add("upside", row$upside_estimate %||% NA_real_)
  }
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

decision_valuation_run <- function(state, semantic_decision_state = semantic_decision_empty()) {
  context_result <- decision_valuation_build_context(state, semantic_decision_state)
  if (!identical(context_result$status, "success")) return(context_result)
  context <- context_result$value
  state <- decision_valuation_normalize(state)
  id <- context$valuation_context_id
  cash <- data.table::rbindlist(
    list(decision_valuation_financial_cash_flows(semantic_decision_state), decision_valuation_rows(state, "cash_flows", id)),
    use.names = TRUE,
    fill = TRUE
  )
  economics <- AutoQuant::aq_assess_alternative_economics(
    context,
    cash_flows = cash,
    impact_mappings = decision_valuation_rows(state, "impact_mappings", id),
    scenarios = decision_valuation_rows(state, "scenarios", id)
  )
  sensitivity <- AutoQuant::aq_decision_valuation_sensitivity(economics, decision_valuation_rows(state, "sensitivity_assumptions", id))
  thresholds <- AutoQuant::aq_assess_decision_thresholds(economics, decision_valuation_rows(state, "thresholds", id))
  information_value <- AutoQuant::aq_assess_decision_information_value(
    uncertainties = semantic_decision_rows(semantic_decision_state, "uncertainties", semantic_decision_active_context_id(semantic_decision_state)),
    sensitivity = sensitivity,
    experiment_cost = NA_real_,
    reversibility = TRUE
  )
  recommendation <- AutoQuant::aq_governed_decision_valuation_recommendation(
    context,
    economics,
    thresholds = decision_valuation_rows(state, "thresholds", id),
    optionality = semantic_decision_rows(semantic_decision_state, "optionality", semantic_decision_active_context_id(semantic_decision_state)),
    effort = decision_valuation_rows(state, "effort", id),
    risks = decision_valuation_rows(state, "risks", id),
    criteria = decision_valuation_rows(state, "criteria_values", id),
    information_value = information_value
  )
  mapping_validation <- AutoQuant::aq_validate_evidence_impact_mapping(AutoQuant::aq_evidence_impact_mapping(decision_valuation_rows(state, "impact_mappings", id)))
  artifact <- AutoQuant::aq_decision_valuation_artifact(context, economics, recommendation, validations = list(mapping = mapping_validation, thresholds = thresholds, sensitivity = sensitivity, information_value = information_value))
  state$active_valuation_context_id <- id
  state$results[[id]] <- list(
    context = context,
    economics = economics,
    sensitivity = sensitivity,
    thresholds = thresholds,
    information_value = information_value,
    recommendation = recommendation,
    mapping_validation = mapping_validation,
    autoquant_artifact = artifact,
    run_at = decision_valuation_now()
  )
  state$message <- "Decision valuation completed."
  state$history <- data.table::rbindlist(list(state$history, decision_valuation_event(id, "valuation_run", state$message)), use.names = TRUE, fill = TRUE)
  service_result(status = "success", value = state, messages = state$message, metadata = list(valuation_context_id = id))
}

decision_valuation_summary <- function(state) {
  state <- decision_valuation_normalize(state)
  id <- decision_valuation_active_id(state)
  result <- state$results[[id]]
  economics <- result$economics %||% data.table::data.table()
  recommendation <- result$recommendation %||% data.table::data.table()
  data.table::data.table(
    contexts = nrow(state$contexts),
    active_valuation_context_id = id %||% NA_character_,
    cash_flows = nrow(state$cash_flows),
    impact_mappings = nrow(state$impact_mappings),
    scenarios = nrow(state$scenarios),
    thresholds = nrow(state$thresholds),
    valuation_status = if (is.null(result)) "not_run" else "current",
    alternatives_valued = if (nrow(economics)) length(unique(economics$alternative_id)) else 0L,
    missing_inputs = if (nrow(economics)) sum(economics$missing_inputs %||% FALSE, na.rm = TRUE) else 0L,
    recommendation_count = if (nrow(recommendation)) nrow(recommendation) else 0L,
    primary_recommendation = if (nrow(recommendation)) recommendation$recommendation_category[[1]] else "not_available",
    registered_artifacts = length(state$artifact_registry),
    last_message = state$message %||% "not_started"
  )
}

decision_valuation_app_artifact <- function(result) {
  id <- result$context$valuation_context_id
  create_artifact(
    artifact_id = paste0("decision_valuation_", id),
    artifact_type = "table",
    label = "Decision Valuation Evidence",
    source_module = "semantic_intelligence",
    object = result$recommendation,
    content = result$recommendation,
    metadata = list(
      created_by_module = TRUE,
      module_id = "semantic_intelligence",
      source_function = "aq_decision_valuation_artifact",
      analytical_intent = "Decision",
      artifact_importance = "critical",
      artifact_purpose = "Translate evidence, economics, uncertainty, optionality, thresholds, and authority into governed decision valuation.",
      autoquant_artifact_id = result$autoquant_artifact$id %||% result$autoquant_artifact$artifact_envelope$artifact_id,
      decision_context_id = result$context$decision_context_id,
      valuation_context_id = id,
      render_targets = c("human_report", "llm_docx", "artifact_studio")
    ),
    section = "Decision Valuation"
  )
}

decision_valuation_service_result <- function(artifact, context_id) {
  service_result(
    status = "success",
    artifacts = list(artifact),
    messages = "Decision valuation artifact registered.",
    metadata = list(
      module_id = "semantic_intelligence",
      module_run_id = paste0("decision_valuation_", format(Sys.time(), "%Y%m%d%H%M%S")),
      generated_at = Sys.time(),
      source_package = "AutoQuant",
      source_function = "aq_decision_valuation_artifact",
      configured_inputs = list(valuation_context_id = context_id),
      artifact_count = 1L,
      table_count = 1L,
      plot_count = 0L,
      text_count = 0L,
      report_plan_count = 0L
    )
  )
}

decision_valuation_register_artifact <- function(ctx, state) {
  state <- decision_valuation_normalize(state)
  id <- decision_valuation_active_id(state)
  result <- state$results[[id]]
  if (is.null(result)) return(service_result(status = "error", errors = "Run decision valuation before registering an artifact."))
  artifact <- decision_valuation_app_artifact(result)
  ctx$saved_module_artifacts$artifacts[[artifact$artifact_id]] <- artifact
  state$artifact_registry <- unique(c(state$artifact_registry, artifact$artifact_id))
  state$message <- "Decision valuation artifact registered."
  service <- decision_valuation_service_result(artifact, id)
  if (!is.null(ctx$append_module_result_to_collector)) {
    append_result <- ctx$append_module_result_to_collector(service, "semantic_intelligence", record_skipped = FALSE)
    if (!identical(append_result$status, "success")) {
      state$message <- paste(state$message, service_result_message(append_result), sep = " ")
    }
  }
  service_result(status = "success", value = state, artifacts = list(artifact), messages = state$message)
}

decision_valuation_campaign_seeds <- function(state) {
  state <- decision_valuation_normalize(state)
  id <- decision_valuation_active_id(state)
  result <- state$results[[id]]
  if (is.null(result)) return(data.table::data.table(seed_type = character(), alternative_id = character(), reason = character()))
  AutoQuant::aq_decision_valuation_campaign_seeds(result$recommendation)
}

decision_valuation_authoring_ui <- function(ns) {
  ui_card(
    "Decision Valuation",
    "Translate alternatives, evidence, economics, uncertainty, optionality, thresholds, effort, and risk into governed valuation evidence.",
    uiOutput(ns("decision_valuation_summary")),
    ui_disclosure(
      "Valuation Context",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("valuation_context_id"), "Valuation ID", placeholder = "valuation_next_quarter_budget"),
        textInput(ns("valuation_decision_context_id"), "Decision ID", placeholder = "Uses active authored decision if blank"),
        textInput(ns("valuation_alternatives"), "Alternatives", placeholder = "baseline,pilot,full"),
        textInput(ns("valuation_baseline"), "Baseline Alternative", placeholder = "baseline"),
        textInput(ns("valuation_objectives"), "Objective IDs", placeholder = "objective_revenue_growth"),
        textInput(ns("valuation_strategies"), "Strategy IDs", placeholder = "strategy_qualified_demand"),
        textInput(ns("valuation_tactics"), "Tactic IDs", placeholder = "tactic_paid_search"),
        textInput(ns("valuation_levers"), "Lever IDs", placeholder = "lever_paid_search_budget"),
        numericInput(ns("valuation_horizon"), "Time Horizon", value = 1, min = 1),
        textInput(ns("valuation_period_unit"), "Period Unit", placeholder = "quarter"),
        textInput(ns("valuation_currency"), "Currency", value = "USD"),
        numericInput(ns("valuation_discount_rate"), "Discount Rate", value = 0, min = -0.99),
        textInput(ns("valuation_authority"), "Authority ID", placeholder = "authority_marketing"),
        textInput(ns("valuation_coverage"), "Coverage ID", placeholder = "coverage_marketing")
      ),
      ui_action_row(actionButton(ns("save_valuation_context"), "Save Valuation Context", class = "btn-primary btn-sm")),
      open = TRUE
    ),
    ui_disclosure(
      "Evidence Impact Mapping",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("valuation_mapping_id"), "Mapping ID", placeholder = "impact_itt_lift"),
        textInput(ns("valuation_mapping_artifact"), "Evidence Artifact ID", placeholder = "itt_effect_artifact"),
        textInput(ns("valuation_mapping_alternative"), "Alternative ID", placeholder = "pilot"),
        selectInput(ns("valuation_mapping_evidence_type"), "Evidence Type", choices = c("randomized_itt", "design_aware_causal", "forecast", "prediction", "scenario", "assumption", "unknown")),
        textInput(ns("valuation_mapping_estimand"), "Estimand / Prediction", placeholder = "ATE"),
        textInput(ns("valuation_mapping_scale"), "Effect Scale", placeholder = "incremental conversions"),
        numericInput(ns("valuation_mapping_effect"), "Effect Value", value = NA),
        numericInput(ns("valuation_mapping_population"), "Affected Population", value = NA),
        numericInput(ns("valuation_mapping_duration"), "Duration Periods", value = 1, min = 0),
        numericInput(ns("valuation_mapping_unit_value"), "Unit Value", value = NA),
        numericInput(ns("valuation_mapping_capacity"), "Capacity Limit", value = NA),
        selectInput(ns("valuation_mapping_source"), "Source Status", choices = c("causally_estimated", "experimentally_estimated", "predictively_modeled", "forecast", "scenario_assumption", "expert_judgment", "imported_financial_input", "llm_suggestion", "missing", "unsupported")),
        selectInput(ns("valuation_mapping_guardrail"), "Guardrail Status", choices = c("not_checked", "passed", "warning", "failed", "blocked", "harmful")),
        numericInput(ns("valuation_mapping_confidence"), "Confidence", value = NA)
      ),
      textAreaInput(ns("valuation_mapping_limitations"), "Applicability / Validity Limits", rows = 2),
      ui_action_row(actionButton(ns("save_valuation_mapping"), "Save Impact Mapping", class = "btn-primary btn-sm"))
    ),
    ui_disclosure(
      "Thresholds, Effort, And Risk",
      tags$div(
        class = "aq-form-grid",
        textInput(ns("valuation_threshold_id"), "Threshold ID", placeholder = "min_incremental_npv"),
        textInput(ns("valuation_threshold_alternative"), "Alternative ID", placeholder = "pilot"),
        selectInput(ns("valuation_threshold_metric"), "Metric", choices = c("incremental_npv", "incremental_net_benefit", "npv", "net_benefit", "roi")),
        selectInput(ns("valuation_threshold_operator"), "Operator", choices = c(">=", ">", "<=", "<", "==", "!=")),
        numericInput(ns("valuation_threshold_value"), "Threshold Value", value = 0),
        checkboxInput(ns("valuation_threshold_guardrail"), "Blocking guardrail", value = FALSE)
      ),
      ui_action_row(actionButton(ns("save_valuation_threshold"), "Save Threshold", class = "btn-secondary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("valuation_effort_alternative"), "Effort Alternative ID", placeholder = "pilot"),
        numericInput(ns("valuation_effort_hours"), "Implementation Hours", value = NA),
        numericInput(ns("valuation_effort_capacity"), "Capacity Available", value = NA),
        selectInput(ns("valuation_effort_burden"), "Burden", choices = c("low", "medium", "high", "severe")),
        textInput(ns("valuation_effort_owner"), "Owner", placeholder = "Analytics")
      ),
      ui_action_row(actionButton(ns("save_valuation_effort"), "Save Effort", class = "btn-secondary btn-sm")),
      tags$hr(),
      tags$div(
        class = "aq-form-grid",
        textInput(ns("valuation_risk_id"), "Risk ID", placeholder = "risk_margin_guardrail"),
        textInput(ns("valuation_risk_alternative"), "Risk Alternative ID", placeholder = "full"),
        selectInput(ns("valuation_risk_type"), "Risk Type", choices = c("financial", "guardrail", "execution", "capacity", "strategic", "legal", "reputation")),
        numericInput(ns("valuation_downside_amount"), "Downside Amount", value = NA),
        selectInput(ns("valuation_risk_guardrail"), "Guardrail Status", choices = c("passed", "warning", "failed", "blocked", "harmful", "not_checked")),
        textInput(ns("valuation_risk_mitigation"), "Mitigation", placeholder = "bounded pilot")
      ),
      ui_action_row(actionButton(ns("save_valuation_risk"), "Save Risk", class = "btn-secondary btn-sm"))
    ),
    ui_disclosure(
      "Run And Evidence",
      ui_action_row(
        actionButton(ns("run_decision_valuation"), "Run Valuation", class = "btn-primary btn-sm"),
        actionButton(ns("register_decision_valuation_artifact"), "Register Artifact", class = "btn-secondary btn-sm")
      ),
      uiOutput(ns("decision_valuation_message")),
      uiOutput(ns("decision_valuation_recommendation")),
      uiOutput(ns("decision_valuation_economics")),
      uiOutput(ns("decision_valuation_campaign_seeds"))
    )
  )
}

decision_valuation_bind_server <- function(input, output, session, ctx, decision_state, active_decision_id) {
  valuation_state <- reactive(decision_valuation_normalize(ctx$decision_valuation_state()))
  active_valuation_id <- reactive(decision_valuation_active_id(valuation_state()))

  output$decision_valuation_summary <- renderUI({
    summary <- decision_valuation_summary(valuation_state())
    ui_stat_grid(
      ui_stat_tile("Contexts", summary$contexts[[1]], status = if (summary$contexts[[1]] > 0L) "success" else "neutral"),
      ui_stat_tile("Valuation", ui_status_label(summary$valuation_status[[1]]), status = if (identical(summary$valuation_status[[1]], "current")) "success" else "neutral"),
      ui_stat_tile("Alternatives", summary$alternatives_valued[[1]], status = if (summary$alternatives_valued[[1]] > 1L) "success" else "warning"),
      ui_stat_tile("Missing Inputs", summary$missing_inputs[[1]], status = if (summary$missing_inputs[[1]] > 0L) "warning" else "success"),
      ui_stat_tile("Recommendation", ui_status_label(summary$primary_recommendation[[1]]), status = if (summary$recommendation_count[[1]] > 0L) "info" else "neutral"),
      ui_stat_tile("Artifacts", summary$registered_artifacts[[1]], status = if (summary$registered_artifacts[[1]] > 0L) "success" else "neutral")
    )
  })

  output$decision_valuation_message <- renderUI({
    ui_callout("Valuation status", valuation_state()$message %||% "Decision valuation has not been run.", status = "info")
  })

  output$decision_valuation_recommendation <- renderUI({
    state <- valuation_state()
    result <- state$results[[active_valuation_id()]]
    if (is.null(result)) return(ui_empty_state("No valuation recommendation yet.", "Run valuation after authoring a context and evidence mapping."))
    render_table(result$recommendation[, .(alternative_id, scenario, npv, incremental_npv, roi, missing_inputs, dominance_state, recommendation_category, recommendation_reason)], engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_valuation_economics <- renderUI({
    state <- valuation_state()
    result <- state$results[[active_valuation_id()]]
    if (is.null(result)) return(ui_empty_state("No economics yet.", "Run valuation to compute transparent economics."))
    render_table(result$economics[, .(alternative_id, scenario, gross_benefit, total_cost, net_benefit, roi, npv, incremental_npv, missing_inputs, evidence_source_status)], engine = "html", searchable = FALSE, sortable = FALSE)
  })

  output$decision_valuation_campaign_seeds <- renderUI({
    seeds <- decision_valuation_campaign_seeds(valuation_state())
    if (!nrow(seeds)) return(ui_empty_state("No campaign seeds yet.", "Valuation seeds appear when recommendation states imply evidence, authority, or staged-action follow-up."))
    render_table(seeds, engine = "html", searchable = FALSE, sortable = FALSE)
  })

  save_valuation_row <- function(result) {
    if (identical(result$status, "success")) {
      ctx$decision_valuation_state(result$value)
    }
    ctx$decision_valuation_message <- service_result_message(result)
  }

  observeEvent(input$save_valuation_context, {
    decision_id <- input$valuation_decision_context_id
    if (!nzchar(decision_id %||% "")) decision_id <- active_decision_id()
    valuation_id <- input$valuation_context_id
    if (!nzchar(valuation_id %||% "")) valuation_id <- paste0("valuation_", decision_id)
    row <- data.table::data.table(
      valuation_context_id = valuation_id,
      decision_context_id = decision_id,
      alternatives_included = input$valuation_alternatives %||% "",
      baseline_alternative = input$valuation_baseline %||% "",
      objective_refs = input$valuation_objectives %||% "",
      strategy_refs = input$valuation_strategies %||% "",
      tactic_refs = input$valuation_tactics %||% "",
      lever_refs = input$valuation_levers %||% "",
      time_horizon_periods = input$valuation_horizon,
      period_unit = input$valuation_period_unit %||% "period",
      currency = input$valuation_currency %||% "USD",
      discount_rate = input$valuation_discount_rate,
      authority = input$valuation_authority %||% "",
      coverage = input$valuation_coverage %||% ""
    )
    save_valuation_row(decision_valuation_upsert(valuation_state(), "contexts", "valuation_context_id", row, valuation_id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_valuation_mapping, {
    id <- active_valuation_id()
    if (!nzchar(id %||% "")) id <- paste0("valuation_", active_decision_id())
    row <- data.table::data.table(
      valuation_context_id = id,
      mapping_id = input$valuation_mapping_id %||% "",
      source_artifact_id = input$valuation_mapping_artifact %||% "",
      alternative_id = input$valuation_mapping_alternative %||% "",
      evidence_type = input$valuation_mapping_evidence_type %||% "unknown",
      estimand_or_prediction = input$valuation_mapping_estimand %||% "",
      effect_scale = input$valuation_mapping_scale %||% "",
      effect_value = input$valuation_mapping_effect,
      affected_population = input$valuation_mapping_population,
      duration_periods = input$valuation_mapping_duration,
      unit_value = input$valuation_mapping_unit_value,
      capacity_limit = input$valuation_mapping_capacity,
      source_type = input$valuation_mapping_source %||% "missing",
      guardrail_status = input$valuation_mapping_guardrail %||% "not_checked",
      confidence = input$valuation_mapping_confidence,
      applicability_limitations = input$valuation_mapping_limitations %||% ""
    )
    save_valuation_row(decision_valuation_upsert(valuation_state(), "impact_mappings", "mapping_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_valuation_threshold, {
    id <- active_valuation_id()
    row <- data.table::data.table(
      valuation_context_id = id,
      threshold_id = input$valuation_threshold_id %||% "",
      alternative_id = input$valuation_threshold_alternative %||% "",
      metric = input$valuation_threshold_metric %||% "incremental_npv",
      operator = input$valuation_threshold_operator %||% ">=",
      value = input$valuation_threshold_value,
      guardrail_blocking = isTRUE(input$valuation_threshold_guardrail),
      recommendation_if_met = "consider_action",
      recommendation_if_not_met = "retain_baseline_or_collect_evidence"
    )
    save_valuation_row(decision_valuation_upsert(valuation_state(), "thresholds", "threshold_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_valuation_effort, {
    id <- active_valuation_id()
    row <- data.table::data.table(
      valuation_context_id = id,
      alternative_id = input$valuation_effort_alternative %||% "",
      implementation_hours = input$valuation_effort_hours,
      capacity_available_hours = input$valuation_effort_capacity,
      burden_level = input$valuation_effort_burden %||% "medium",
      owner = input$valuation_effort_owner %||% ""
    )
    save_valuation_row(decision_valuation_upsert(valuation_state(), "effort", "alternative_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$save_valuation_risk, {
    id <- active_valuation_id()
    row <- data.table::data.table(
      valuation_context_id = id,
      alternative_id = input$valuation_risk_alternative %||% "",
      risk_id = input$valuation_risk_id %||% "",
      risk_type = input$valuation_risk_type %||% "financial",
      downside_amount = input$valuation_downside_amount,
      guardrail_status = input$valuation_risk_guardrail %||% "not_checked",
      mitigation = input$valuation_risk_mitigation %||% ""
    )
    save_valuation_row(decision_valuation_upsert(valuation_state(), "risks", "risk_id", row, id))
  }, ignoreInit = TRUE)

  observeEvent(input$run_decision_valuation, {
    result <- decision_valuation_run(valuation_state(), decision_state())
    save_valuation_row(result)
  }, ignoreInit = TRUE)

  observeEvent(input$register_decision_valuation_artifact, {
    result <- decision_valuation_register_artifact(ctx, valuation_state())
    save_valuation_row(result)
  }, ignoreInit = TRUE)
}

qa_decision_valuation_workspace <- function() {
  rows <- list()
  add <- function(check, ok, message) rows[[length(rows) + 1L]] <<- data.table::data.table(suite = "decision_valuation_workspace", check = check, status = if (isTRUE(ok)) "success" else "error", message = message)
  add("autoquant_available", decision_valuation_available(), "AutoQuant valuation API is available.")
  state <- decision_valuation_empty("qa_project")
  semantic <- semantic_decision_empty("qa_project")
  semantic <- semantic_decision_upsert_row(semantic, "contexts", "decision_context_id", data.table::data.table(decision_context_id = "decision_1", decision_question = "What should we do?", authority_id = "authority_1", coverage_id = "coverage_1"), "decision_1")$value
  semantic <- semantic_decision_upsert_row(semantic, "alternatives", "alternative_id", data.table::data.table(decision_context_id = "decision_1", alternative_id = "baseline", name = "Baseline", baseline = TRUE, alternative_type = "do_nothing"), "decision_1")$value
  semantic <- semantic_decision_upsert_row(semantic, "alternatives", "alternative_id", data.table::data.table(decision_context_id = "decision_1", alternative_id = "pilot", name = "Pilot", baseline = FALSE, alternative_type = "pilot"), "decision_1")$value
  semantic <- semantic_decision_upsert_row(semantic, "financial_impacts", "financial_id", data.table::data.table(decision_context_id = "decision_1", financial_id = "fin_base", alternative_id = "baseline", expected_benefit = 100, initial_cost = 0, recurring_cost = 0, source_type = "observed"), "decision_1")$value
  state <- decision_valuation_upsert(state, "contexts", "valuation_context_id", data.table::data.table(valuation_context_id = "valuation_1", decision_context_id = "decision_1", alternatives_included = "baseline,pilot", baseline_alternative = "baseline", currency = "USD", discount_rate = 0, time_horizon_periods = 1, authority = "authority_1", coverage = "coverage_1"), "valuation_1")$value
  state <- decision_valuation_upsert(state, "impact_mappings", "mapping_id", data.table::data.table(valuation_context_id = "valuation_1", mapping_id = "impact_1", source_artifact_id = "itt_1", alternative_id = "pilot", evidence_type = "randomized_itt", effect_value = 0.1, affected_population = 1000, duration_periods = 1, unit_value = 5, source_type = "causally_estimated"), "valuation_1")$value
  state <- decision_valuation_upsert(state, "thresholds", "threshold_id", data.table::data.table(valuation_context_id = "valuation_1", threshold_id = "min_npv", alternative_id = "pilot", metric = "incremental_npv", operator = ">=", value = 0), "valuation_1")$value
  run <- decision_valuation_run(state, semantic)
  add("run_success", identical(run$status, "success"), "Decision valuation run succeeds.")
  summary <- decision_valuation_summary(run$value)
  add("summary_reports_value", summary$alternatives_valued[[1]] >= 2L && identical(summary$valuation_status[[1]], "current"), "Summary reports valued alternatives.")
  artifact <- decision_valuation_app_artifact(run$value$results[[decision_valuation_active_id(run$value)]])
  add("artifact_created", identical(artifact$artifact_type, "table") && nzchar(artifact$artifact_id), "App artifact is created.")
  seeds <- decision_valuation_campaign_seeds(run$value)
  add("campaign_seed_table", data.table::is.data.table(seeds), "Campaign seeds are available.")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
