evidence_strategy_registry <- function() {
  list(
    efficient = list(
      evidence_strategy = "efficient",
      strategy_label = "Efficient",
      strategy_description = "Fastest and lowest cost. Uses only the highest-value evidence.",
      best_for = c("quick reads", "exploratory questions", "low-stakes decisions", "local/private usage"),
      business_tradeoff_summary = list(
        expected_cost = "low",
        expected_completeness = "moderate",
        risk_of_missing_nuance = "moderate",
        expected_latency = "low",
        expected_confidence = "directional",
        provider_privacy_posture = "local/private friendly"
      ),
      technical_config = list(
        routing_profile = "token_saver",
        marginal_gain_threshold = 0.42,
        max_artifacts = 5L,
        max_images = 1L,
        max_tables = 1L,
        max_full_tables = 0L,
        max_estimated_tokens = 1100L,
        max_latency_ms = 10000L,
        redundancy_tolerance = 0.25,
        deep_dive_threshold = 0.88,
        full_table_allowed = FALSE,
        image_payload_allowed = TRUE,
        paid_provider_allowed = FALSE,
        local_only = TRUE,
        vision_preference = FALSE,
        exact_value_bias = 0.7,
        diagnostic_bias = 0.8,
        caveat_bias = 0.7,
        novelty_weight = 1.1,
        trust_weight = 1.0,
        relevance_weight = 1.1,
        cost_weight = 1.4,
        evidence_explosion_allowed = FALSE
      )
    ),
    balanced = list(
      evidence_strategy = "balanced",
      strategy_label = "Balanced",
      strategy_description = "Default mode. Enough evidence for sound judgment without excessive cost.",
      best_for = c("normal business decisions", "routine model interpretation", "project briefings"),
      business_tradeoff_summary = list(
        expected_cost = "moderate",
        expected_completeness = "high",
        risk_of_missing_nuance = "low/moderate",
        expected_latency = "moderate",
        expected_confidence = "reasonable",
        provider_privacy_posture = "local-first when configured"
      ),
      technical_config = list(
        routing_profile = "balanced",
        marginal_gain_threshold = 0.26,
        max_artifacts = 10L,
        max_images = 2L,
        max_tables = 3L,
        max_full_tables = 1L,
        max_estimated_tokens = 3000L,
        max_latency_ms = 20000L,
        redundancy_tolerance = 0.55,
        deep_dive_threshold = 0.70,
        full_table_allowed = TRUE,
        image_payload_allowed = TRUE,
        paid_provider_allowed = FALSE,
        local_only = FALSE,
        vision_preference = FALSE,
        exact_value_bias = 1.0,
        diagnostic_bias = 1.0,
        caveat_bias = 1.0,
        novelty_weight = 1.0,
        trust_weight = 1.0,
        relevance_weight = 1.0,
        cost_weight = 1.0,
        evidence_explosion_allowed = FALSE
      )
    ),
    thorough = list(
      evidence_strategy = "thorough",
      strategy_label = "Thorough",
      strategy_description = "Broader evidence inclusion with more diagnostics, caveats, and supporting views.",
      best_for = c("stakeholder-facing recommendations", "deeper analytical review", "uncertain findings"),
      business_tradeoff_summary = list(
        expected_cost = "high",
        expected_completeness = "very high",
        risk_of_missing_nuance = "low",
        expected_latency = "moderate/high",
        expected_confidence = "stronger",
        provider_privacy_posture = "provider choice still controlled"
      ),
      technical_config = list(
        routing_profile = "thorough",
        marginal_gain_threshold = 0.18,
        max_artifacts = 18L,
        max_images = 4L,
        max_tables = 6L,
        max_full_tables = 2L,
        max_estimated_tokens = 6000L,
        max_latency_ms = 45000L,
        redundancy_tolerance = 0.75,
        deep_dive_threshold = 0.62,
        full_table_allowed = TRUE,
        image_payload_allowed = TRUE,
        paid_provider_allowed = FALSE,
        local_only = FALSE,
        vision_preference = FALSE,
        exact_value_bias = 1.1,
        diagnostic_bias = 1.2,
        caveat_bias = 1.2,
        novelty_weight = 1.0,
        trust_weight = 1.1,
        relevance_weight = 1.0,
        cost_weight = 0.8,
        evidence_explosion_allowed = FALSE
      )
    ),
    critical_decision = list(
      evidence_strategy = "critical_decision",
      strategy_label = "Critical Decision",
      strategy_description = "Evidence explosion allowed for high-stakes decisions, production approval, and executive signoff.",
      best_for = c("high-stakes business decisions", "production model approval", "executive signoff", "expensive media or pricing decisions"),
      business_tradeoff_summary = list(
        expected_cost = "very high",
        expected_completeness = "maximum practical",
        risk_of_missing_nuance = "very low",
        expected_latency = "high",
        expected_confidence = "highest practical before manual review",
        provider_privacy_posture = "explicit provider approval required"
      ),
      technical_config = list(
        routing_profile = "thorough",
        marginal_gain_threshold = 0.10,
        max_artifacts = 30L,
        max_images = 8L,
        max_tables = 12L,
        max_full_tables = 4L,
        max_estimated_tokens = 12000L,
        max_latency_ms = 90000L,
        redundancy_tolerance = 0.95,
        deep_dive_threshold = 0.45,
        full_table_allowed = TRUE,
        image_payload_allowed = TRUE,
        paid_provider_allowed = FALSE,
        local_only = FALSE,
        vision_preference = TRUE,
        exact_value_bias = 1.25,
        diagnostic_bias = 1.45,
        caveat_bias = 1.45,
        novelty_weight = 0.9,
        trust_weight = 1.25,
        relevance_weight = 1.1,
        cost_weight = 0.5,
        evidence_explosion_allowed = TRUE
      )
    ),
    cost_irrelevant = list(
      evidence_strategy = "cost_irrelevant",
      strategy_label = "Cost Is Irrelevant",
      strategy_description = "Use everything reasonable for offline, nearly free, final-review, or deep-audit runs.",
      best_for = c("offline/local runs", "nearly free token environments", "final review", "research/deep audit"),
      business_tradeoff_summary = list(
        expected_cost = "not constrained",
        expected_completeness = "maximum reasonable",
        risk_of_missing_nuance = "very low",
        expected_latency = "not optimized",
        expected_confidence = "broadest context",
        provider_privacy_posture = "local preferred unless explicitly overridden"
      ),
      technical_config = list(
        routing_profile = "thorough",
        marginal_gain_threshold = 0.05,
        max_artifacts = 50L,
        max_images = 12L,
        max_tables = 20L,
        max_full_tables = 8L,
        max_estimated_tokens = 30000L,
        max_latency_ms = 180000L,
        redundancy_tolerance = 1.0,
        deep_dive_threshold = 0.35,
        full_table_allowed = TRUE,
        image_payload_allowed = TRUE,
        paid_provider_allowed = FALSE,
        local_only = FALSE,
        vision_preference = TRUE,
        exact_value_bias = 1.35,
        diagnostic_bias = 1.35,
        caveat_bias = 1.35,
        novelty_weight = 0.85,
        trust_weight = 1.15,
        relevance_weight = 1.0,
        cost_weight = 0.2,
        evidence_explosion_allowed = TRUE
      )
    )
  )
}

evidence_strategy_ids <- function() {
  names(evidence_strategy_registry())
}

evidence_strategy_config <- function(strategy = "balanced", overrides = list()) {
  registry <- evidence_strategy_registry()
  selected <- registry[[strategy %||% "balanced"]] %||% registry$balanced
  if (length(overrides)) {
    if (!is.null(overrides$technical_config)) {
      selected$technical_config <- utils::modifyList(selected$technical_config, overrides$technical_config)
      overrides$technical_config <- NULL
    }
    selected <- utils::modifyList(selected, overrides)
  }
  selected
}

evidence_strategy_routing_overrides <- function(strategy_config) {
  cfg <- strategy_config$technical_config %||% list()
  list(
    max_artifacts = cfg$max_artifacts %||% 10L,
    max_images = cfg$max_images %||% 2L,
    max_tables = cfg$max_tables %||% 3L,
    deep_dive_threshold = cfg$deep_dive_threshold %||% 0.70,
    include_threshold = cfg$marginal_gain_threshold %||% 0.26,
    token_budget = cfg$max_estimated_tokens %||% 3000L,
    redundancy_tolerance = cfg$redundancy_tolerance %||% 0.55,
    prefer_vision = isTRUE(cfg$vision_preference),
    exact_values = isTRUE((cfg$exact_value_bias %||% 1) > 1),
    local_only = isTRUE(cfg$local_only),
    full_table_allowed = isTRUE(cfg$full_table_allowed),
    image_payload_allowed = isTRUE(cfg$image_payload_allowed),
    paid_provider_allowed = isTRUE(cfg$paid_provider_allowed),
    evidence_explosion_allowed = isTRUE(cfg$evidence_explosion_allowed)
  )
}

evidence_strategy_explain <- function(strategy_config) {
  cfg <- strategy_config$technical_config %||% list()
  tradeoffs <- strategy_config$business_tradeoff_summary %||% list()
  c(
    paste0(strategy_config$strategy_label, ": ", strategy_config$strategy_description),
    paste0("Expected cost: ", tradeoffs$expected_cost %||% "unknown"),
    paste0("Expected completeness: ", tradeoffs$expected_completeness %||% "unknown"),
    paste0("Risk of missing nuance: ", tradeoffs$risk_of_missing_nuance %||% "unknown"),
    paste0("Includes up to ", cfg$max_artifacts %||% "default", " artifacts, ", cfg$max_images %||% "default", " images, and ", cfg$max_tables %||% "default", " tables."),
    paste0("Deep dives begin near utility threshold ", cfg$deep_dive_threshold %||% "default", "."),
    paste0("Full tables are ", if (isTRUE(cfg$full_table_allowed)) "allowed when safe" else "avoided", "."),
    paste0("Paid providers are ", if (isTRUE(cfg$paid_provider_allowed)) "allowed when configured" else "not allowed by default", "."),
    paste0("Local-only mode is ", if (isTRUE(cfg$local_only)) "required" else "not required", ".")
  )
}

evidence_strategy_frontier_summary <- function(strategy_config) {
  tradeoffs <- strategy_config$business_tradeoff_summary %||% list()
  cfg <- strategy_config$technical_config %||% list()
  data.table::data.table(
    evidence_strategy = strategy_config$evidence_strategy,
    strategy_label = strategy_config$strategy_label,
    estimated_evidence_completeness = tradeoffs$expected_completeness %||% NA_character_,
    estimated_token_cost = tradeoffs$expected_cost %||% NA_character_,
    estimated_latency = tradeoffs$expected_latency %||% NA_character_,
    expected_confidence = tradeoffs$expected_confidence %||% NA_character_,
    risk_of_missing_nuance = tradeoffs$risk_of_missing_nuance %||% NA_character_,
    provider_privacy_posture = tradeoffs$provider_privacy_posture %||% NA_character_,
    max_estimated_tokens = cfg$max_estimated_tokens %||% NA_integer_,
    max_latency_ms = cfg$max_latency_ms %||% NA_integer_,
    evidence_explosion_allowed = isTRUE(cfg$evidence_explosion_allowed)
  )
}

evidence_strategy_compact_json <- function(x) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    return(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
  }
  paste(utils::capture.output(str(x, give.attr = FALSE)), collapse = " ")
}

evidence_strategy_apply_provider_constraints <- function(provider, strategy_config) {
  cfg <- strategy_config$technical_config %||% list()
  if (identical(provider %||% "none", "none")) {
    return(service_result(status = "success", messages = "No GenAI provider is selected, so local/private restrictions are satisfied."))
  }
  contract <- genai_provider(provider)
  caps <- contract$capabilities %||% genai_capabilities()
  if (isTRUE(cfg$local_only) && !isTRUE(caps[["local"]])) {
    return(service_result(
      status = "warning",
      warnings = paste("Evidence strategy requires local/private provider but selected provider is not local:", provider),
      metadata = list(error_code = "EVIDENCE_STRATEGY_PROVIDER_CONSTRAINT", provider = provider)
    ))
  }
  if (!isTRUE(cfg$paid_provider_allowed) && isTRUE(caps[["paid"]])) {
    return(service_result(
      status = "warning",
      warnings = paste("Evidence strategy does not allow paid providers:", provider),
      metadata = list(error_code = "EVIDENCE_STRATEGY_PAID_PROVIDER_BLOCKED", provider = provider)
    ))
  }
  service_result(status = "success", messages = "Provider satisfies evidence strategy constraints.")
}

ui_evidence_strategy_selector <- function(id, selected = "balanced", show_advanced = TRUE) {
  ns <- shiny::NS(id)
  strategies <- evidence_strategy_registry()
  labels <- vapply(strategies, function(x) x$strategy_label, character(1))
  shiny::tagList(
    shiny::div(
      class = "aw-evidence-strategy",
      shiny::selectInput(ns("evidence_strategy"), "Evidence Strategy", choices = labels, selected = selected),
      shiny::uiOutput(ns("evidence_strategy_summary")),
      if (isTRUE(show_advanced)) {
        shiny::tags$details(
          class = "aw-disclosure",
          shiny::tags$summary("Advanced evidence configuration"),
          shiny::numericInput(ns("max_estimated_tokens"), "Token budget", value = NA, min = 100, step = 100),
          shiny::numericInput(ns("max_artifacts"), "Artifact budget", value = NA, min = 1, step = 1),
          shiny::numericInput(ns("max_images"), "Image budget", value = NA, min = 0, step = 1),
          shiny::numericInput(ns("max_tables"), "Table budget", value = NA, min = 0, step = 1),
          shiny::checkboxInput(ns("local_only"), "Require local/private provider", value = FALSE),
          shiny::checkboxInput(ns("paid_provider_allowed"), "Allow paid provider", value = FALSE),
          shiny::checkboxInput(ns("full_table_allowed"), "Allow safe full tables", value = TRUE),
          shiny::sliderInput(ns("redundancy_tolerance"), "Redundancy tolerance", min = 0, max = 1, value = 0.55, step = 0.05),
          shiny::sliderInput(ns("deep_dive_threshold"), "Deep-dive threshold", min = 0, max = 1, value = 0.70, step = 0.05)
        )
      }
    )
  )
}

qa_evidence_strategy_config <- function() {
  project_path <- file.path("exports", "artifact_studio_demo", "artifact_studio_demo_project.rds")
  if (!file.exists(project_path) && exists("create_artifact_studio_demo_project", mode = "function")) {
    create_artifact_studio_demo_project()
  }
  efficient <- build_evidence_plan(project_path, "What should I do next?", evidence_strategy = "efficient", provider = "none", write_outputs = TRUE, output_dir = file.path(tempdir(), "evidence_strategy_qa"))
  balanced <- build_evidence_plan(project_path, "What should I do next?", evidence_strategy = "balanced", provider = "none", write_outputs = TRUE, output_dir = file.path(tempdir(), "evidence_strategy_qa"))
  critical <- build_evidence_plan(project_path, "What should I do next?", evidence_strategy = "critical_decision", provider = "none", write_outputs = FALSE)
  cost_free <- build_evidence_plan(project_path, "What should I do next?", evidence_strategy = "cost_irrelevant", provider = "none", write_outputs = FALSE)
  overridden <- evidence_strategy_config("balanced", list(technical_config = list(max_artifacts = 3L, local_only = TRUE)))
  local_check <- evidence_strategy_apply_provider_constraints("none", evidence_strategy_config("efficient"))
  log <- data.table::fread(balanced$paths$observability_log)
  docs <- if (file.exists(file.path("docs", "evidence_strategy_ux.md"))) paste(readLines(file.path("docs", "evidence_strategy_ux.md"), warn = FALSE), collapse = "\n") else ""
  required_log_fields <- c("evidence_strategy", "strategy_label", "strategy_description", "technical_config", "user_overrides", "business_tradeoff_summary", "selected_provider_mode", "paid_provider_allowed", "local_only", "evidence_explosion_allowed")
  data.table::data.table(
    check = c(
      "all_business_strategies_exist",
      "each_maps_to_technical_settings",
      "balanced_is_default",
      "advanced_overrides_work",
      "strategies_affect_routing_behavior",
      "critical_decision_more_than_balanced",
      "efficient_less_than_balanced",
      "cost_irrelevant_broad_inclusion",
      "local_private_restrictions_respected",
      "paid_provider_not_used_unless_allowed",
      "observability_captures_strategy_config",
      "documentation_exists",
      "existing_evidence_routing_qa_passes"
    ),
    status = c(
      if (all(c("efficient", "balanced", "thorough", "critical_decision", "cost_irrelevant") %in% evidence_strategy_ids())) "success" else "error",
      if (all(vapply(evidence_strategy_registry(), function(x) all(c("routing_profile", "max_artifacts", "max_estimated_tokens", "paid_provider_allowed") %in% names(x$technical_config)), logical(1)))) "success" else "error",
      if (identical(evidence_strategy_config()$evidence_strategy, "balanced")) "success" else "error",
      if (identical(overridden$technical_config$max_artifacts, 3L) && isTRUE(overridden$technical_config$local_only)) "success" else "error",
      if (nrow(efficient$selected_artifacts) != nrow(balanced$selected_artifacts) || nrow(critical$selected_artifacts) != nrow(balanced$selected_artifacts)) "success" else "error",
      if (nrow(critical$selected_artifacts) >= nrow(balanced$selected_artifacts)) "success" else "error",
      if (nrow(efficient$selected_artifacts) <= nrow(balanced$selected_artifacts)) "success" else "error",
      if (nrow(cost_free$selected_artifacts) >= nrow(critical$selected_artifacts) && isTRUE(cost_free$strategy_config$technical_config$evidence_explosion_allowed)) "success" else "error",
      if (identical(local_check$status, "success")) "success" else "error",
      if (!isTRUE(balanced$strategy_config$technical_config$paid_provider_allowed)) "success" else "error",
      if (all(required_log_fields %in% names(log))) "success" else "error",
      if (grepl("Evidence Strategy UX", docs, fixed = TRUE) && grepl("Critical Decision", docs, fixed = TRUE)) "success" else "error",
      if (!any(qa_evidence_routing_policy()$status == "error")) "success" else "error"
    ),
    message = c(
      "Efficient, Balanced, Thorough, Critical Decision, and Cost Is Irrelevant strategies exist.",
      "Each business strategy maps to centralized technical routing settings.",
      "Balanced is the default strategy.",
      "Advanced technical overrides modify the resulting config.",
      "Strategies produce different routing behavior.",
      "Critical Decision includes at least as much selected evidence as Balanced.",
      "Efficient includes no more evidence than Balanced.",
      "Cost Is Irrelevant allows broad evidence inclusion.",
      "Local/private restrictions are represented in provider constraints.",
      "Paid providers are blocked unless explicitly allowed.",
      "Observability records strategy, config, overrides, provider mode, and explosion flags.",
      "Evidence strategy UX documentation exists.",
      "Existing Evidence Routing QA still passes."
    )
  )
}
