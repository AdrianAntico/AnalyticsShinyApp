workflow_stage_registry <- function() {
  list(
    list(
      order = 1L,
      stage_id = "eda",
      label = "EDA",
      subtitle = NULL,
      status = "implemented",
      modules = list("autoquant_eda"),
      page = "Analysis Modules",
      purpose = "Understand data structure, distributions, correlations, and trends.",
      recommended_next_stage = "Feature Engineering"
    ),
    list(
      order = 2L,
      stage_id = "feature_engineering",
      label = "Feature Engineering",
      subtitle = NULL,
      status = "external_or_future",
      modules = list(NULL),
      page = NULL,
      purpose = "Create modeling features. This can be completed outside the app today.",
      recommended_next_stage = "Model Prep"
    ),
    list(
      order = 3L,
      stage_id = "model_prep",
      label = "Model Prep",
      subtitle = NULL,
      status = "external_or_future",
      modules = list(NULL),
      page = NULL,
      purpose = "Define partitions, folds, train/test splits, and leakage-safe model data.",
      recommended_next_stage = "Model Readiness"
    ),
    list(
      order = 4L,
      stage_id = "model_readiness",
      label = "Model Readiness",
      subtitle = "Target Analysis",
      status = "implemented",
      modules = list("autoquant_model_assessment"),
      page = "Analysis Modules",
      purpose = "Review target diagnostics, leakage/collider risk, drift, class balance, and modeling recommendations.",
      recommended_next_stage = "CatBoost Builder"
    ),
    list(
      order = 5L,
      stage_id = "catboost_builder",
      label = "CatBoost Builder",
      subtitle = NULL,
      status = "experimental",
      modules = list("autoquant_catboost_builder"),
      page = "Analysis Modules",
      purpose = "Train and score CatBoost regression or binary classification models.",
      recommended_next_stage = "Model Assessment"
    ),
    list(
      order = 6L,
      stage_id = "model_assessment",
      label = "Model Assessment",
      subtitle = "Post-model evaluation",
      status = "external_or_future",
      modules = list(NULL),
      page = NULL,
      purpose = "Evaluate trained/scored model performance. This stage is reserved for post-model assessment only.",
      recommended_next_stage = "Model Insights"
    ),
    list(
      order = 7L,
      stage_id = "model_insights",
      label = "Model Insights",
      subtitle = NULL,
      status = "implemented",
      modules = list(c("autoquant_regression_model_insights", "autoquant_binary_model_insights")),
      page = "Analysis Modules",
      purpose = "Understand model behavior, diagnostics, and feature effects.",
      recommended_next_stage = "SHAP Insights"
    ),
    list(
      order = 8L,
      stage_id = "shap_insights",
      label = "SHAP Insights",
      subtitle = NULL,
      status = "implemented",
      modules = list(c("autoquant_regression_shap_analysis", "autoquant_binary_shap_analysis")),
      page = "Analysis Modules",
      purpose = "Understand prediction-surface behavior using precomputed SHAP columns.",
      recommended_next_stage = "Report / Export"
    ),
    list(
      order = 9L,
      stage_id = "report_export",
      label = "Report / Export",
      subtitle = NULL,
      status = "implemented",
      modules = list(NULL),
      page = "Layouts / Export",
      purpose = "Compose, export, and share selected report artifacts.",
      recommended_next_stage = NULL
    )
  )
}

workflow_stage_table <- function() {
  data.table::rbindlist(lapply(workflow_stage_registry(), function(stage) {
    data.table::data.table(
      order = stage$order,
      stage_id = stage$stage_id,
      label = stage$label,
      subtitle = stage$subtitle %||% NA_character_,
      status = stage$status,
      modules = paste(stage$modules[[1]] %||% character(), collapse = ", "),
      page = stage$page %||% NA_character_,
      purpose = stage$purpose,
      recommended_next_stage = stage$recommended_next_stage %||% NA_character_
    )
  }), use.names = TRUE, fill = TRUE)
}

workflow_stage_module_ids <- function(stage) {
  modules <- stage$modules[[1]] %||% character()
  modules[!is.na(modules) & nzchar(modules)]
}

workflow_stage_for_module <- function(module_id) {
  registry <- workflow_stage_registry()
  for (stage in registry) {
    if (module_id %in% workflow_stage_module_ids(stage)) {
      return(stage$stage_id)
    }
  }

  NA_character_
}

workflow_status_badge_status <- function(status) {
  if (status %in% c("implemented", "experimental")) {
    return("success")
  }
  if (identical(status, "external_or_future")) {
    return("info")
  }
  if (identical(status, "deferred")) {
    return("neutral")
  }
  "warning"
}

workflow_state_summary <- function(ctx = NULL) {
  stages <- workflow_stage_table()
  stages[, `:=`(
    artifact_count = 0L,
    report_plan_count = 0L,
    latest_run_status = NA_character_,
    catboost_handoff_available = FALSE,
    custom_code_hook_count = 0L
  )]

  if (is.null(ctx)) {
    return(stages)
  }

  artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
  if (length(artifacts)) {
    artifact_rows <- lapply(artifacts, function(artifact) {
      metadata <- artifact$metadata %||% list()
      module_id <- metadata$module_id %||% artifact$source_module %||% NA_character_
      data.table::data.table(
        stage_id = workflow_stage_for_module(module_id),
        artifact_id = artifact$artifact_id %||% NA_character_,
        catboost_handoff_available = !is.null(metadata$catboost_handoff) || !is.null(metadata$downstream_handoff)
      )
    })
    artifact_summary <- data.table::rbindlist(artifact_rows, use.names = TRUE, fill = TRUE)
    artifact_summary <- artifact_summary[!is.na(stage_id)]
    if (nrow(artifact_summary)) {
      counts <- artifact_summary[, list(
        artifact_count = .N,
        catboost_handoff_available = any(catboost_handoff_available)
      ), by = stage_id]
      stages[counts, `:=`(
        artifact_count = i.artifact_count,
        catboost_handoff_available = i.catboost_handoff_available
      ), on = "stage_id"]
    }
  }

  plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
  if (length(plans)) {
    plan_rows <- lapply(plans, function(plan) {
      metadata <- plan$metadata %||% list()
      module_id <- metadata$module_id %||% metadata$source_module %||% NA_character_
      data.table::data.table(stage_id = workflow_stage_for_module(module_id))
    })
    plan_summary <- data.table::rbindlist(plan_rows, use.names = TRUE, fill = TRUE)
    plan_summary <- plan_summary[!is.na(stage_id)]
    if (nrow(plan_summary)) {
      counts <- plan_summary[, list(report_plan_count = .N), by = stage_id]
      stages[counts, report_plan_count := i.report_plan_count, on = "stage_id"]
    }
  }

  records <- tryCatch(ctx$code_runner_state$records, error = function(e) list())
  requests <- tryCatch(ctx$code_runner_state$requests, error = function(e) list())
  hook_rows <- list()
  if (length(records)) {
    hook_rows <- c(hook_rows, lapply(records, function(record) {
      metadata <- record$metadata %||% list()
      context <- metadata$context %||% list()
      data.table::data.table(
        stage_id = metadata$workflow_stage %||% context$workflow_stage %||% NA_character_,
        status = record$status %||% NA_character_,
        is_hook = isTRUE(metadata$custom_code_hook) || isTRUE(context$custom_code_hook)
      )
    }))
  }
  if (length(requests)) {
    hook_rows <- c(hook_rows, lapply(requests, function(request) {
      context <- request$context %||% list()
      data.table::data.table(
        stage_id = context$workflow_stage %||% NA_character_,
        status = request$status %||% NA_character_,
        is_hook = isTRUE(context$custom_code_hook)
      )
    }))
  }
  if (length(hook_rows)) {
    hook_summary <- data.table::rbindlist(hook_rows, use.names = TRUE, fill = TRUE)
    hook_summary <- hook_summary[is_hook == TRUE & !is.na(stage_id)]
    if (nrow(hook_summary)) {
      counts <- hook_summary[, list(
        custom_code_hook_count = .N,
        latest_run_status = status[.N]
      ), by = stage_id]
      stages[counts, `:=`(
        custom_code_hook_count = i.custom_code_hook_count,
        latest_run_status = i.latest_run_status
      ), on = "stage_id"]
    }
  }

  stages[]
}

workflow_stage_card <- function(stage, ns, summary = NULL) {
  module_ids <- workflow_stage_module_ids(stage)
  status <- workflow_status_badge_status(stage$status)
  stage_summary <- if (!is.null(summary) && nrow(summary)) {
    summary[summary$stage_id == stage$stage_id]
  } else {
    data.table::data.table()
  }
  artifact_count <- if (nrow(stage_summary)) stage_summary$artifact_count[[1]] else 0L
  plan_count <- if (nrow(stage_summary)) stage_summary$report_plan_count[[1]] else 0L
  hook_count <- if (nrow(stage_summary)) stage_summary$custom_code_hook_count[[1]] else 0L
  handoff <- if (nrow(stage_summary)) isTRUE(stage_summary$catboost_handoff_available[[1]]) else FALSE

  ui_card(
    class = "aq-workflow-stage-card",
    title = paste0(stage$order, ". ", stage$label),
    subtitle = stage$subtitle,
    tags$div(
      class = "aq-workflow-stage-meta",
      ui_status_badge(stage$status, status),
      if (length(module_ids)) tags$span(class = "aq-workflow-module-id", paste(module_ids, collapse = " / "))
    ),
    tags$p(class = "aq-workflow-purpose", stage$purpose),
    tags$dl(
      class = "aq-workflow-counts",
      tags$dt("Artifacts"), tags$dd(artifact_count),
      tags$dt("Report plans"), tags$dd(plan_count),
      tags$dt("Custom code drafts/history"), tags$dd(hook_count),
      tags$dt("Handoff"), tags$dd(if (handoff) "Available" else "Not detected")
    ),
    if (!is.null(stage$recommended_next_stage)) {
      tags$p(class = "aq-workflow-next", paste("Next:", stage$recommended_next_stage))
    },
    if (length(module_ids)) {
      do.call(ui_action_row, lapply(module_ids, function(module_id) {
        module <- get_module_definition(module_id)
        actionButton(
          ns(paste0("open_module_", stage$stage_id, "_", module_id)),
          paste("Open", module$label %||% module_id),
          class = "btn-secondary btn-sm"
        )
      }))
    } else {
      ui_empty_state("External or report stage", "Use the existing app pages or external tools for this stage.")
    },
    ui_action_row(
      actionButton(ns(paste0("hook_pre_", stage$stage_id)), "Draft pre-stage code", class = "btn-default btn-sm"),
      actionButton(ns(paste0("hook_post_", stage$stage_id)), "Draft post-stage code", class = "btn-default btn-sm"),
      actionButton(ns(paste0("hook_standalone_", stage$stage_id)), "Draft standalone code", class = "btn-default btn-sm")
    )
  )
}

page_workflow_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Workflow",
    ui_page(
      title = "Workflow",
      subtitle = "A flexible analytical lifecycle. Nothing auto-runs; modules and custom code remain user-triggered.",
      ui_card(
        title = "Workflow Summary",
        uiOutput(ns("workflow_message")),
        uiOutput(ns("workflow_summary"))
      ),
      uiOutput(ns("workflow_stages"))
    )
  )
}

page_workflow_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    workflow_message <- reactiveVal(NULL)

    summary_reactive <- reactive({
      workflow_state_summary(ctx)
    })

    output$workflow_message <- renderUI({
      message <- workflow_message()
      if (is.null(message) || !nzchar(message)) {
        return(ui_empty_state(
          "Use Workflow as a launchpad.",
          "Open existing modules or draft Code Runner hooks for each stage."
        ))
      }
      tags$p(class = "aq-workflow-message", message)
    })

    output$workflow_summary <- renderUI({
      render_table(
        summary_reactive()[, list(
          order,
          stage_id,
          label,
          status,
          artifact_count,
          report_plan_count,
          custom_code_hook_count,
          latest_run_status,
          catboost_handoff_available
        )],
        title = NULL,
        page_size = 9,
        searchable = FALSE,
        filterable = FALSE
      )
    })

    output$workflow_stages <- renderUI({
      summary <- summary_reactive()
      tags$div(
        class = "aq-workflow-stage-grid",
        lapply(workflow_stage_registry(), workflow_stage_card, ns = session$ns, summary = summary)
      )
    })

    for (stage in workflow_stage_registry()) {
      stage_id <- stage$stage_id
      module_ids <- workflow_stage_module_ids(stage)
      for (module_id in module_ids) {
        local({
          selected_module_id <- module_id
          button_id <- paste0("open_module_", stage_id, "_", selected_module_id)
          observeEvent(input[[button_id]], {
            if (is.function(ctx$select_analysis_module)) {
              ctx$select_analysis_module(selected_module_id)
              workflow_message(paste("Opened Analysis Modules for", get_module_definition(selected_module_id)$label %||% selected_module_id))
            } else {
              workflow_message(paste("Open the Analysis Modules page and select", selected_module_id))
            }
          }, ignoreInit = TRUE)
        })
      }

      for (timing in custom_code_hook_timings()) {
        local({
          selected_stage_id <- stage_id
          selected_stage_label <- stage$label
          selected_timing <- timing
          button_id <- switch(
            selected_timing,
            pre_stage = paste0("hook_pre_", selected_stage_id),
            post_stage = paste0("hook_post_", selected_stage_id),
            standalone = paste0("hook_standalone_", selected_stage_id)
          )
          observeEvent(input[[button_id]], {
            result <- ctx$add_custom_code_hook_request(
              stage = selected_stage_id,
              timing = selected_timing,
              label = paste(selected_stage_label, gsub("_", " ", selected_timing), "code"),
              code = paste0("# ", selected_stage_label, " ", gsub("_", " ", selected_timing), " code\n"),
              context = list(source_page = "workflow")
            )
            if (identical(result$status, "success")) {
              workflow_message(result$messages %||% "Draft custom code hook created.")
              if (is.function(ctx$select_code_run)) {
                ctx$select_code_run(result$metadata$run_id)
              }
            } else {
              workflow_message(paste(result$errors %||% result$warnings %||% "Failed to create custom code hook.", collapse = " | "))
            }
          }, ignoreInit = TRUE)
        })
      }
    }
  })
}

qa_workflow_stage_registry <- function() {
  stages <- workflow_stage_table()
  expected <- c(
    "eda",
    "feature_engineering",
    "model_prep",
    "model_readiness",
    "catboost_builder",
    "model_assessment",
    "model_insights",
    "shap_insights",
    "report_export"
  )

  data.table::data.table(
    check = c("stage_ids", "stage_order", "no_pre_model_assessment_label", "external_stages_allowed"),
    status = c(
      if (identical(stages$stage_id, expected)) "success" else "error",
      if (identical(stages$order, seq_along(expected))) "success" else "error",
      if (!any(stages$stage_id %in% c("eda", "feature_engineering", "model_prep", "model_readiness") & grepl("Model Assessment", stages$label))) "success" else "error",
      if (all(stages$status[stages$stage_id %in% c("feature_engineering", "model_prep")] == "external_or_future")) "success" else "error"
    ),
    message = c(
      paste(stages$stage_id, collapse = " -> "),
      paste(stages$order, collapse = ", "),
      "Pre-model stages do not use Model Assessment terminology.",
      "Feature Engineering and Model Prep are non-failing external/future stages."
    )
  )
}

qa_workflow_model_readiness_mapping <- function() {
  stages <- workflow_stage_registry()
  readiness <- stages[[which(vapply(stages, function(stage) identical(stage$stage_id, "model_readiness"), logical(1)))]]
  assessment <- stages[[which(vapply(stages, function(stage) identical(stage$stage_id, "model_assessment"), logical(1)))]]
  readiness_module <- workflow_stage_module_ids(readiness)

  data.table::data.table(
    check = c("readiness_module_valid", "readiness_label", "readiness_subtitle", "assessment_post_model"),
    status = c(
      if (length(readiness_module) && !is.null(get_module_definition(readiness_module[[1]]))) "success" else "error",
      if (identical(readiness$label, "Model Readiness")) "success" else "error",
      if (identical(readiness$subtitle, "Target Analysis")) "success" else "error",
      if (grepl("post-model", assessment$purpose, fixed = TRUE)) "success" else "error"
    ),
    message = c(
      paste("Model Readiness maps to", paste(readiness_module, collapse = ", ")),
      "User-facing label is Model Readiness.",
      "Target Analysis remains subtitle/context.",
      "Model Assessment is reserved for post-model evaluation."
    )
  )
}

qa_workflow_custom_code_hooks_integration <- function() {
  rows <- list()
  for (stage in workflow_stage_table()$stage_id) {
    for (timing in custom_code_hook_timings()) {
      request <- create_custom_code_hook_request(
        run_id = paste("qa", stage, timing, sep = "_"),
        stage = stage,
        timing = timing,
        label = paste("QA", stage, timing),
        code = "# QA hook\n",
        requested_outputs = "handoff_notes",
        data_name = "qa_data"
      )
      validation <- validate_custom_code_hook_request(request)
      context <- request$context %||% list()
      rows[[length(rows) + 1L]] <- data.table::data.table(
        stage_id = stage,
        hook_timing = timing,
        status = if (
          identical(validation$status, "success") &&
            isTRUE(context$custom_code_hook) &&
            identical(context$workflow_stage, stage) &&
            identical(context$hook_timing, timing) &&
            identical(request$source, "manual") &&
            !isTRUE(context$auto_run)
        ) "success" else "error",
        message = paste(validation$errors %||% validation$messages %||% "", collapse = " | ")
      )
    }
  }

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

qa_workflow_page_contract <- function() {
  ui <- page_workflow_ui("workflow")
  summary <- workflow_state_summary()
  modules <- unlist(lapply(workflow_stage_registry(), workflow_stage_module_ids), use.names = FALSE)
  modules <- modules[nzchar(modules)]
  registry <- get_module_registry()

  data.table::data.table(
    check = c("ui_constructs", "server_exists", "implemented_modules_valid", "summary_returns_rows"),
    status = c(
      if (inherits(ui, "shiny.tag")) "success" else "error",
      if (exists("page_workflow_server", mode = "function")) "success" else "error",
      if (all(modules %in% names(registry))) "success" else "error",
      if (nrow(summary) == length(workflow_stage_registry())) "success" else "error"
    ),
    message = c(
      "Workflow UI tab constructs.",
      "Workflow server module exists.",
      paste(modules, collapse = ", "),
      paste("Summary rows:", nrow(summary))
    )
  )
}
