guide_artifact_module_ids <- function(artifacts) {
  if (!length(artifacts)) {
    return(character())
  }
  unique(vapply(artifacts, function(artifact) {
    metadata <- artifact$metadata %||% list()
    metadata$module_id %||% artifact$source_module %||% ""
  }, character(1)))
}

guide_state_from_context <- function(ctx = NULL, overrides = list()) {
  get_value <- function(name, expr, default) {
    if (!is.null(overrides[[name]])) {
      return(overrides[[name]])
    }
    if (is.null(ctx)) {
      return(default)
    }
    tryCatch(expr, error = function(e) default)
  }

  data <- get_value("data", ctx$project_data(), NULL)
  data_info <- get_value("data_info", ctx$project_data_info(), list(path = NULL, name = NULL))
  artifacts <- get_value("artifacts", ctx$all_artifacts(), list())
  collector <- get_value("collector", ctx$project_collector_summary(), data.table::data.table())
  workflow <- get_value("workflow", workflow_state_summary(ctx), workflow_state_summary(NULL))
  plans <- get_value("plans", ctx$report_plan_state$plans, list())
  async <- get_value("async", async_job_status_counts(refresh = FALSE), list(total = 0L, running = 0L, completed = 0L, failed = 0L, latest_status = "unavailable"))
  genai <- get_value("genai", ctx$genai_status(check_availability = FALSE), genai_provider_status(genai_config(provider = "none")))
  evidence_strategy <- get_value("evidence_strategy", ctx$evidence_strategy_config(), evidence_strategy_config("balanced"))
  execution_policy <- get_value("execution_policy", ctx$code_runner_state$policy, create_code_execution_policy())

  module_ids <- guide_artifact_module_ids(artifacts)
  collector_artifacts <- if (nrow(collector)) collector$artifact_count[[1]] %||% 0L else 0L
  collector_ready <- nrow(collector) && collector_artifacts > 0L && identical(collector$manifest_status[[1]] %||% "", "ready")
  project_exists <- !is.null(data) || length(artifacts) > 0L || collector_artifacts > 0L || length(plans) > 0L
  collector_project_name <- if (nrow(collector) && "project_name" %in% names(collector)) {
    collector$project_name[[1]]
  } else {
    NULL
  }
  project_name <- data_info$name %||% collector_project_name

  knowledge_state <- if (!project_exists) {
    "Not started"
  } else if (is.null(data) && length(artifacts) > 0L) {
    "Evidence restored"
  } else if (!is.null(data) && !length(artifacts)) {
    "Data known, evidence missing"
  } else if (length(artifacts) && !collector_ready) {
    "Evidence generated, memory incomplete"
  } else if (collector_ready) {
    "Evidence preserved"
  } else {
    "Project active"
  }

  decision_readiness <- if (!project_exists || (!length(artifacts) && collector_artifacts == 0L)) {
    "Insufficient Evidence"
  } else if (length(artifacts) < 5L || !collector_ready) {
    "Preliminary"
  } else if (collector_ready && length(artifacts) >= 5L) {
    "Reasonable"
  } else {
    "Unknown"
  }

  list(
    project_exists = project_exists,
    project_name = project_name %||% "No project loaded",
    data = data,
    data_info = data_info,
    artifacts = artifacts,
    artifact_count = length(artifacts),
    module_ids = module_ids,
    collector = collector,
    collector_artifacts = collector_artifacts,
    collector_ready = collector_ready,
    workflow = workflow,
    plans = plans,
    plan_count = length(plans),
    async = async,
    genai = genai,
    evidence_strategy = evidence_strategy,
    execution_policy = execution_policy,
    knowledge_state = knowledge_state,
    decision_readiness = decision_readiness
  )
}

guide_has_module <- function(state, module_id) {
  module_id %in% state$module_ids
}

guide_recommendation <- function(state) {
  if (!isTRUE(state$project_exists)) {
    return(list(
      title = "Start with a project",
      action = "Load data or open an existing project.",
      reason = "No project state is loaded, so the workstation has no evidence, collector memory, or Knowledge State to reason over.",
      benefit = "Creates the project context needed for Explore Data, Model Readiness, artifacts, and recommendations.",
      cost = "Low",
      confidence = "High",
      target = "Project"
    ))
  }

  if (is.null(state$data) && state$artifact_count == 0L) {
    return(list(
      title = "Restore analytical context",
      action = "Open an existing project or load data.",
      reason = "The workstation does not have active data or artifacts available in memory.",
      benefit = "Restores the project world so evidence can be generated or inspected.",
      cost = "Low",
      confidence = "High",
      target = "Project"
    ))
  }

  if (!is.null(state$data) && state$artifact_count == 0L) {
    return(list(
      title = "Run Explore Data",
      action = "Generate foundational Explore Data artifacts.",
      reason = "Data are loaded, but no foundational evidence exists yet. Explore Data establishes distributions, missingness, correlations, and early diagnostics.",
      benefit = "Creates the first evidence layer for the project.",
      cost = "Low",
      confidence = "High",
      target = "Analysis Modules"
    ))
  }

  if (!guide_has_module(state, "autoquant_model_readiness") && state$artifact_count > 0L) {
    return(list(
      title = "Run Model Readiness",
      action = "Check whether the data are suitable for modeling.",
      reason = "Evidence exists, but readiness diagnostics have not been generated. Target analysis, leakage, collider risk, drift, balance, and missingness should be checked before modeling.",
      benefit = "Reduces the chance of building a model on untrustworthy data.",
      cost = "Low to medium",
      confidence = "High",
      target = "Analysis Modules"
    ))
  }

  if ((guide_has_module(state, "autoquant_regression_model_insights") || guide_has_module(state, "autoquant_binary_model_insights")) &&
      !guide_has_module(state, "autoquant_regression_shap_analysis") &&
      !guide_has_module(state, "autoquant_binary_shap_analysis")) {
    return(list(
      title = "Generate SHAP Analysis",
      action = "Add feature-level explanation artifacts.",
      reason = "Model insight artifacts exist, but SHAP evidence is missing. SHAP usually has high expected information gain for understanding feature importance and local effect behavior.",
      benefit = "Improves interpretability and helps explain model behavior.",
      cost = "Medium",
      confidence = "Medium",
      target = "Analysis Modules"
    ))
  }

  if (state$artifact_count > 0L && !isTRUE(state$collector_ready)) {
    return(list(
      title = "Preserve evidence in the Collector",
      action = "Review collector status and append generated module artifacts.",
      reason = "Artifacts exist, but collector memory is not fully ready. The project should preserve evidence before reporting or AI-oriented review.",
      benefit = "Makes evidence durable and ready for reports, LLM DOCX, and future knowledge workflows.",
      cost = "Low",
      confidence = "High",
      target = "Project"
    ))
  }

  if (state$artifact_count > 0L) {
    return(list(
      title = "Review Artifact Studio",
      action = "Inspect the generated evidence.",
      reason = "The project contains artifacts. The next useful move is to inspect quality, diagnostics, recommendations, and backing assets before deciding what to report or investigate next.",
      benefit = "Turns generated output into understood evidence.",
      cost = "Low",
      confidence = "High",
      target = "Artifact Studio"
    ))
  }

  list(
    title = "Review Mission Control",
    action = "Inspect project health and workflow state.",
    reason = "The deterministic Guide did not detect a more specific next step.",
    benefit = "Mission Control will surface operational gaps, warnings, and readiness indicators.",
    cost = "Low",
    confidence = "Medium",
    target = "Mission Control"
  )
}

guide_status <- function(value) {
  switch(
    value,
    good = "success",
    attention = "warning",
    missing = "error",
    unknown = "neutral",
    "neutral"
  )
}

guide_health_rows <- function(state) {
  genai_value <- state$genai$value %||% list()
  data.table::data.table(
    area = c("Data", "Artifacts", "Collector", "Knowledge", "GenAI", "Async Jobs"),
    status = c(
      if (is.null(state$data)) "Missing" else "Good",
      if (state$artifact_count > 0L) "Good" else "Missing",
      if (isTRUE(state$collector_ready)) "Good" else if (state$artifact_count > 0L) "Needs Attention" else "Missing",
      if (state$decision_readiness %in% c("Reasonable", "High Confidence")) "Good" else if (state$project_exists) "Needs Attention" else "Missing",
      if (isTRUE(genai_value$available)) "Good" else if (isTRUE(genai_value$configured)) "Needs Attention" else "Missing",
      if ((state$async$running %||% 0L) > 0L) "Good" else if (identical(state$async$latest_status %||% "", "unavailable")) "Unknown" else "Good"
    ),
    detail = c(
      if (is.null(state$data)) "Load data or open a project." else paste(nrow(state$data), "rows x", ncol(state$data), "columns"),
      paste(state$artifact_count, "artifact(s) in memory."),
      if (isTRUE(state$collector_ready)) paste(state$collector_artifacts, "artifact(s) preserved.") else "Collector memory is not fully ready.",
      paste(state$knowledge_state, "-", state$decision_readiness),
      state$genai$metadata$diagnostic_reason %||% "not_checked",
      paste("running:", state$async$running %||% 0L, "failed:", state$async$failed %||% 0L)
    )
  )
}

ui_guide_action_card <- function(title, message, when = NULL, action = NULL, status = "info") {
  tags$article(
    class = .aq_class("aq-guide-action-card", paste0("aq-guide-action-card-", status)),
    tags$div(
      class = "aq-guide-action-card-copy",
      tags$strong(title),
      tags$p(message),
      if (!is.null(when)) tags$span(class = "aq-guide-action-card-when", when)
    ),
    if (!is.null(action)) tags$div(class = "aq-guide-action-card-action", action)
  )
}

ui_guide_learn_item <- function(title, message, href = "#") {
  tags$a(
    class = "aq-guide-learn-item",
    href = href,
    tags$strong(title),
    tags$span(message)
  )
}

ui_guide_recommendation <- function(recommendation) {
  ui_card(
    title = "Recommended Next Step",
    subtitle = "Deterministic guidance based on the current workspace state.",
    class = "aq-guide-recommendation-card",
    tags$div(
      class = "aq-guide-recommendation",
      tags$p(class = "aq-guide-recommendation-label", recommendation$title),
      tags$h3(recommendation$action),
      tags$p(recommendation$reason),
      tags$div(
        class = "aq-guide-recommendation-facts",
        ui_stat_tile("Benefit", recommendation$benefit, status = "info"),
        ui_stat_tile("Cost", recommendation$cost, status = "neutral"),
        ui_stat_tile("Confidence", recommendation$confidence, status = "success")
      )
    )
  )
}

page_guide_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Guide",
    ui_page(
      title = "Welcome to Analytics Workstation",
      subtitle = "A senior analytical mentor for evidence-centered work.",
      eyebrow = "Guide",
      actions = ui_action_row(
        actionButton(ns("open_project"), "Open Project", class = "btn-secondary"),
        actionButton(ns("open_mission_control"), "Review Mission Control", class = "btn-secondary")
      ),
      tags$div(
        class = "aq-guide-page",
        tags$section(
          class = "aq-guide-hero",
          tags$div(
            class = "aq-guide-hero-copy",
            tags$p(class = "aq-guide-hero-kicker", "What are you trying to accomplish today?"),
            tags$h2("Transform business questions into evidence-backed decisions."),
            tags$p("Analytics Workstation is evidence-centered. It helps move from questions to knowledge, from knowledge to evidence, and from evidence to decisions.")
          ),
          tags$div(
            class = "aq-guide-loop",
            tags$span("Business Questions"),
            tags$span("Knowledge"),
            tags$span("Evidence"),
            tags$span("Decisions")
          )
        ),
        ui_split_panel(
          main = tagList(
            uiOutput(ns("current_workspace")),
            uiOutput(ns("recommended_next_step")),
            ui_card(
              title = "Primary Actions",
              subtitle = "Start from intent, not modules.",
              uiOutput(ns("primary_actions"))
            ),
            uiOutput(ns("current_investigation")),
            ui_card(
              title = "Learn the Workstation",
              subtitle = "Short paths into the architecture. These are stable reference hooks for the future Knowledge Library.",
              tags$div(
                class = "aq-guide-learn-grid",
                ui_guide_learn_item("How Analytics Workstation Works", "Project -> evidence -> collector -> decisions.", "#guide-how-it-works"),
                ui_guide_learn_item("Analytical Intelligence Loop", "Question -> plan -> evidence -> reasoning -> learning.", "#guide-intelligence-loop"),
                ui_guide_learn_item("Artifacts as Evidence", "Generated outputs become inspectable evidence.", "#guide-artifacts"),
                ui_guide_learn_item("Knowledge State", "Knowns, unknowns, assumptions, and readiness.", "#guide-knowledge-state"),
                ui_guide_learn_item("Evidence Routing", "Choose evidence before asking GenAI to reason.", "#guide-evidence-routing"),
                ui_guide_learn_item("Context Optimization", "Use the best context for the lowest cost.", "#guide-context-optimization"),
                ui_guide_learn_item("Execution Modes", "Manual, guided, assisted, autonomous, research.", "#guide-execution-modes"),
                ui_guide_learn_item("Knowledge Library", "The future authoritative reference surface.", "#guide-knowledge-library"),
                ui_guide_learn_item("Book", "The long-form argument for AI-native analytical systems.", "#guide-book")
              )
            )
          ),
          side_content = tags$aside(
            class = "aq-guide-panel",
            uiOutput(ns("guide_panel")),
            uiOutput(ns("workspace_health"))
          )
        )
      )
    )
  )
}

page_guide_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    guide_state <- reactive(guide_state_from_context(ctx))
    guide_next <- reactive(guide_recommendation(guide_state()))

    observeEvent(input$open_project, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$open_mission_control, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)
    observeEvent(input$load_data, ctx$navigate_to("Data"), ignoreInit = TRUE)
    observeEvent(input$open_existing_project, ctx$navigate_to("Project"), ignoreInit = TRUE)
    observeEvent(input$resume_investigation, ctx$navigate_to("Workflow"), ignoreInit = TRUE)
    observeEvent(input$ask_business_question, ctx$navigate_to("Workflow"), ignoreInit = TRUE)
    observeEvent(input$open_artifact_studio, ctx$navigate_to("Artifact Studio"), ignoreInit = TRUE)
    observeEvent(input$review_mission_control, ctx$navigate_to("Mission Control"), ignoreInit = TRUE)
    observeEvent(input$read_knowledge_library, ctx$navigate_to("Knowledge Library"), ignoreInit = TRUE)
    observeEvent(input$run_recommended, ctx$navigate_to(guide_next()$target %||% "Mission Control"), ignoreInit = TRUE)

    output$current_workspace <- renderUI({
      state <- guide_state()
      strategy_label <- state$evidence_strategy$strategy_label %||% state$evidence_strategy$strategy_id %||% "Balanced"
      execution_mode <- state$execution_policy$execution_mode %||% "disabled"
      collector_status <- if (isTRUE(state$collector_ready)) "Ready" else if (state$collector_artifacts > 0L) "Partial" else "Missing"
      running_jobs <- state$async$running %||% 0L

      ui_card(
        title = "Current Workspace",
        subtitle = if (state$project_exists) "The Guide reads this state before recommending a next step." else "No project loaded. Start from one of the actions below.",
        ui_stat_grid(
          ui_stat_tile("Project", state$project_name, status = if (state$project_exists) "success" else "neutral"),
          ui_stat_tile("Knowledge State", state$knowledge_state, status = if (state$project_exists) "info" else "neutral"),
          ui_stat_tile("Decision Readiness", state$decision_readiness, status = if (state$decision_readiness == "Reasonable") "success" else "warning"),
          ui_stat_tile("Execution Mode", execution_mode, status = if (identical(execution_mode, "disabled")) "neutral" else "info"),
          ui_stat_tile("Evidence Strategy", strategy_label, status = "info"),
          ui_stat_tile("Collector", collector_status, status = if (isTRUE(state$collector_ready)) "success" else "warning"),
          ui_stat_tile("Running Jobs", running_jobs, status = if (running_jobs > 0L) "info" else "neutral"),
          ui_stat_tile("Current Recommendation", guide_next()$title, status = "success")
        )
      )
    })

    output$recommended_next_step <- renderUI({
      tagList(
        ui_guide_recommendation(guide_next()),
        ui_action_row(actionButton(session$ns("run_recommended"), "Go to Recommended Surface", class = "btn-primary"))
      )
    })

    output$primary_actions <- renderUI({
      ns <- session$ns
      tags$div(
        class = "aq-guide-action-grid",
        ui_guide_action_card("Load Data", "Bring a dataset into the project world.", "Use when you are starting from raw data.", actionButton(ns("load_data"), "Open Data", class = "btn-primary btn-sm"), "success"),
        ui_guide_action_card("Open Existing Project", "Restore a saved workstation state.", "Use when evidence, collector files, or project settings already exist.", actionButton(ns("open_existing_project"), "Open Project", class = "btn-secondary btn-sm"), "info"),
        ui_guide_action_card("Resume Investigation", "Continue from workflow state and available evidence.", "Use when a project already has a question or partial evidence.", actionButton(ns("resume_investigation"), "Open Workflow", class = "btn-secondary btn-sm"), "info"),
        ui_guide_action_card("Ask a Business Question", "Start from the decision you are trying to make.", "Use when you know the decision before the analysis path.", actionButton(ns("ask_business_question"), "Plan Investigation", class = "btn-secondary btn-sm"), "warning"),
        ui_guide_action_card("Explore Artifact Studio", "Inspect evidence, thumbnails, diagnostics, recommendations, and sidecars.", "Use when artifacts already exist.", actionButton(ns("open_artifact_studio"), "Open Studio", class = "btn-secondary btn-sm"), "success"),
        ui_guide_action_card("Review Mission Control", "Check operational health, warnings, collector status, and readiness.", "Use when you need project state at a glance.", actionButton(ns("review_mission_control"), "Review", class = "btn-secondary btn-sm"), "info"),
        ui_guide_action_card("Read the Knowledge Library", "Learn concepts, architecture, research, and the evolving book.", "Use when you want the authoritative reference layer.", actionButton(ns("read_knowledge_library"), "Open Library", class = "btn-secondary btn-sm"), "info")
      )
    })

    output$current_investigation <- renderUI({
      state <- guide_state()
      known <- if (!state$project_exists) {
        "No project state is loaded."
      } else if (is.null(state$data)) {
        "Project evidence may exist, but no active dataset is loaded."
      } else {
        paste("Dataset loaded with", nrow(state$data), "rows and", ncol(state$data), "columns.")
      }
      unknown <- if (state$artifact_count == 0L) {
        "Distributions, readiness, model behavior, and recommendations are unknown."
      } else if (!guide_has_module(state, "autoquant_model_readiness")) {
        "Model readiness is unknown."
      } else if (!guide_has_module(state, "autoquant_regression_shap_analysis") && !guide_has_module(state, "autoquant_binary_shap_analysis")) {
        "Feature-level SHAP evidence may still be missing."
      } else {
        "Remaining unknowns depend on the business decision and artifact diagnostics."
      }
      evidence_needed <- guide_next()$action

      ui_card(
        title = "Current Investigation",
        subtitle = "A deterministic sketch of knowns, unknowns, evidence needed, and readiness.",
        tags$div(
          class = "aq-guide-investigation-grid",
          ui_callout("Known", known, status = if (state$project_exists) "success" else "info"),
          ui_callout("Unknown", unknown, status = "warning"),
          ui_callout("Evidence Needed", evidence_needed, status = "info"),
          ui_callout("Decision Readiness", state$decision_readiness, status = if (state$decision_readiness == "Reasonable") "success" else "warning")
        )
      )
    })

    output$guide_panel <- renderUI({
      state <- guide_state()
      recommendation <- guide_next()
      genai_status <- state$genai$metadata$display_name %||% "No GenAI Provider"
      genai_reason <- state$genai$metadata$diagnostic_reason %||% "not_configured"
      ui_card(
        title = "Guide Panel",
        subtitle = "Contextual mentoring without chat or autonomous action.",
        class = "aq-guide-side-card",
        ui_callout("Did you know?", "The workstation treats artifacts as evidence, not disposable output.", status = "info"),
        ui_callout("Why this recommendation?", recommendation$reason, status = "success"),
        ui_callout("Current Execution Mode", state$execution_policy$execution_mode %||% "disabled", status = "info"),
        ui_callout("Current Evidence Strategy", state$evidence_strategy$strategy_label %||% "Balanced", status = "info"),
        ui_callout("Next Suggested Action", recommendation$action, status = "success"),
        ui_callout("Architecture Tip", "The Guide teaches in context. The future Knowledge Library will preserve the authoritative references.", status = "info"),
        ui_callout("Guide AI", paste(genai_status, "-", genai_reason, ". The Guide remains deterministic when GenAI is unavailable."), status = if (identical(genai_reason, "available")) "success" else "warning")
      )
    })

    output$workspace_health <- renderUI({
      rows <- guide_health_rows(guide_state())
      ui_card(
        title = "Workspace Health",
        subtitle = "Good, needs attention, missing, or unknown.",
        class = "aq-guide-side-card",
        tags$div(
          class = "aq-guide-health-list",
          lapply(seq_len(nrow(rows)), function(index) {
            status <- rows$status[[index]]
            status_key <- switch(status, Good = "good", `Needs Attention` = "attention", Missing = "missing", Unknown = "unknown", "unknown")
            tags$article(
              class = .aq_class("aq-guide-health-item", paste0("aq-guide-health-item-", status_key)),
              tags$div(tags$strong(rows$area[[index]]), tags$p(rows$detail[[index]])),
              ui_status_badge(status, status = guide_status(status_key))
            )
          })
        )
      )
    })
  })
}

qa_guide_page <- function() {
  empty_state <- guide_state_from_context(overrides = list())
  empty_rec <- guide_recommendation(empty_state)
  loaded_state <- guide_state_from_context(overrides = list(
    data = data.frame(x = 1:5, y = c(2, 4, 3, 5, 6)),
    data_info = list(path = "demo.csv", name = "Demo Project")
  ))
  loaded_rec <- guide_recommendation(loaded_state)
  artifact_state <- guide_state_from_context(overrides = list(
    data = data.frame(x = 1:5, y = c(2, 4, 3, 5, 6)),
    data_info = list(path = "demo.csv", name = "Demo Project"),
    artifacts = list(list(artifact_id = "a1", artifact_type = "plot", source_module = "autoquant_eda", metadata = list(module_id = "autoquant_eda")))
  ))
  artifact_rec <- guide_recommendation(artifact_state)
  ui_text <- paste(as.character(page_guide_ui("guide")), collapse = " ")
  panel_text <- paste(as.character(ui_guide_recommendation(empty_rec)), collapse = " ")
  app_ui_text <- if (file.exists(file.path("R", "app_ui.R"))) {
    paste(readLines(file.path("R", "app_ui.R"), warn = FALSE), collapse = " ")
  } else {
    ""
  }
  command_ids <- names(command_registry())
  css_text <- if (file.exists(file.path("www", "app.css"))) {
    paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = " ")
  } else {
    ""
  }

  data.table::data.table(
    check = c(
      "page_loads",
      "links_exist",
      "no_project_state",
      "loaded_project_state",
      "deterministic_recommendation_no_project",
      "deterministic_recommendation_loaded_data",
      "deterministic_recommendation_artifacts",
      "guide_panel_renders",
      "default_landing",
      "command_palette_registration",
      "dark_theme_consistency"
    ),
    status = c(
      if (grepl("Welcome to Analytics Workstation", ui_text, fixed = TRUE) && grepl("aq-guide-page", ui_text, fixed = TRUE)) "success" else "error",
      if (grepl("href=\"#guide-artifacts\"", ui_text, fixed = TRUE) && grepl("Knowledge Library", ui_text, fixed = TRUE)) "success" else "error",
      if (!isTRUE(empty_state$project_exists) && identical(empty_state$decision_readiness, "Insufficient Evidence")) "success" else "error",
      if (isTRUE(loaded_state$project_exists) && identical(loaded_state$project_name, "Demo Project")) "success" else "error",
      if (identical(empty_rec$title, "Start with a project")) "success" else "error",
      if (identical(loaded_rec$title, "Run Explore Data")) "success" else "error",
      if (identical(artifact_rec$title, "Run Model Readiness")) "success" else "error",
      if (grepl("Recommended Next Step", panel_text, fixed = TRUE)) "success" else "error",
      if (regexpr("page_guide_ui", app_ui_text, fixed = TRUE)[[1]] > 0L && regexpr("page_guide_ui", app_ui_text, fixed = TRUE)[[1]] < regexpr("page_mission_control_ui", app_ui_text, fixed = TRUE)[[1]]) "success" else "error",
      if ("open_guide" %in% command_ids) "success" else "error",
      if (grepl("aq-guide-hero", ui_text, fixed = TRUE) && grepl(".aq-guide-action-card", css_text, fixed = TRUE)) "success" else "error"
    ),
    message = c(
      "Guide page markup is available.",
      "Learn-workstation reference anchors and Knowledge Library placeholder exist.",
      "No-project state degrades gracefully.",
      "Loaded project state is summarized.",
      "No-project recommendation asks user to start with project context.",
      "Loaded data without artifacts recommends Explore Data.",
      "Artifacts without readiness recommend Model Readiness.",
      "Recommendation panel renders.",
      "Guide is registered before Mission Control as the default landing tab.",
      "Command palette can open the Guide.",
      "Guide-specific dark workstation classes are present."
    )
  )
}
