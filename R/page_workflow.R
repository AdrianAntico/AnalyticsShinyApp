workflow_stage_registry <- function() {
  list(
    list(
      order = 1L,
      stage_id = "eda",
      label = "Explore Data",
      subtitle = "EDA",
      status = "implemented",
      modules = list("autoquant_eda"),
      page = "Analysis Modules",
      purpose = "Understand data structure, distributions, correlations, and trends.",
      recommended_next_stage = "Model Readiness"
    ),
    list(
      order = 2L,
      stage_id = "model_readiness",
      label = "Model Readiness",
      subtitle = "Target Analysis",
      status = "implemented",
      modules = list("autoquant_model_readiness"),
      page = "Analysis Modules",
      purpose = "Review target diagnostics, leakage/collider risk, drift, class balance, and modeling recommendations.",
      recommended_next_stage = "Feature Engineering / Model Preparation"
    ),
    list(
      order = 3L,
      stage_id = "feature_engineering_model_prep",
      label = "Feature Engineering / Model Preparation",
      subtitle = NULL,
      status = "implemented",
      modules = list("feature_engineering_model_prep"),
      page = "Analysis Modules",
      purpose = "Prepare deterministic modeling data with visible transformations, lineage, and reusable prepared-data artifacts.",
      recommended_next_stage = "CatBoost Builder"
    ),
    list(
      order = 4L,
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
      order = 5L,
      stage_id = "model_assessment",
      label = "Model Assessment",
      subtitle = "Post-model evaluation",
      status = "planned",
      modules = list(NULL),
      page = NULL,
      purpose = "Evaluate trained/scored model performance. A true post-model assessment adapter is reserved for this stage; do not use the pre-model readiness adapter here.",
      recommended_next_stage = "Model Insights"
    ),
    list(
      order = 6L,
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
      order = 7L,
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
      order = 8L,
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

workflow_stage_for_artifact <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  explicit_stage <- metadata$workflow_stage %||% metadata$context$workflow_stage %||% NA_character_
  if (!is.na(explicit_stage) && nzchar(explicit_stage)) {
    return(explicit_stage)
  }

  module_id <- metadata$module_id %||% artifact$source_module %||% NA_character_
  workflow_stage_for_module(module_id)
}

workflow_status_badge_status <- function(status) {
  if (status %in% c("implemented", "experimental")) {
    return("success")
  }
  if (identical(status, "external_or_future")) {
    return("info")
  }
  if (status %in% c("deferred", "planned")) {
    return("neutral")
  }
  "warning"
}

workflow_status_label <- function(status) {
  ui_status_label(status)
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
      data.table::data.table(
        stage_id = workflow_stage_for_artifact(artifact),
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
      module_id <- metadata$module_id %||% metadata$source_module %||% plan$source_module %||% NA_character_
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
      ui_status_badge(workflow_status_label(stage$status), status),
      if (length(module_ids)) tags$span(class = "aq-workflow-module-id", paste(vapply(module_ids, module_display_label, character(1)), collapse = " / "))
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
      ui_empty_state(
        "No native module yet.",
        "Use Code Runner hooks or external tools for this stage. Artifacts created from stage hooks are counted here."
      )
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
      title = "Next Best Move",
      subtitle = "The workstation route from current evidence to the next useful analytical action.",
      eyebrow = "Lifecycle",
      tags$section(
        class = "aq-workflow-room",
        uiOutput(ns("workflow_hero")),
        tags$div(
          class = "aq-workflow-room-grid",
          tags$main(
            class = "aq-workflow-main",
            uiOutput(ns("workflow_pathway")),
            uiOutput(ns("workflow_evidence_strip")),
            uiOutput(ns("workflow_backstage"))
          ),
          tags$aside(
            class = "aq-workflow-next-panel",
            uiOutput(ns("workflow_action_panel")),
            ui_disclosure(
              "Project Evidence Memory",
              uiOutput(ns("collector_summary")),
              level = "artifact",
              open = FALSE
            )
          )
        )
      )
    )
  )
}

page_workflow_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    workflow_message <- reactiveVal(NULL)

    summary_reactive <- reactive({
      workflow_state_summary(ctx)
    })

    next_stage_reactive <- reactive({
      summary <- summary_reactive()
      next_stage <- summary[status %in% c("implemented", "experimental") & artifact_count == 0L][order(order)][1]
      if (nrow(next_stage)) {
        return(next_stage)
      }
      summary[order(-artifact_count, order)][1]
    })

    output$workflow_hero <- renderUI({
      summary <- summary_reactive()
      next_stage <- next_stage_reactive()
      completed <- summary[artifact_count > 0L, .N]
      evidence_count <- sum(summary$artifact_count, na.rm = TRUE)
      plan_count <- sum(summary$report_plan_count, na.rm = TRUE)
      if (!nrow(next_stage)) {
        next_label <- "Start the analytical route"
        next_reason <- "No workflow stage could be selected from the current project state."
        next_state <- "Not Started"
      } else if (evidence_count == 0L) {
        next_label <- next_stage$label[[1]]
        next_reason <- paste("No foundational evidence exists yet.", next_stage$purpose[[1]])
        next_state <- "First Move"
      } else if (next_stage$artifact_count[[1]] == 0L) {
        next_label <- next_stage$label[[1]]
        next_reason <- paste("This is the earliest evidence gap in the current route.", next_stage$purpose[[1]])
        next_state <- "Evidence Gap"
      } else {
        next_label <- "Review Evidence"
        next_reason <- "The implemented route has evidence. Review Artifact Studio, Mission Control, or Delivery next."
        next_state <- "Review"
      }

      tags$section(
        class = "aq-workflow-hero",
        tags$div(
          class = "aq-workflow-hero-copy",
          tags$p(class = "aq-workflow-kicker", "What should happen next?"),
          tags$h2(next_label),
          tags$p(next_reason),
          tags$div(
            class = "aq-workflow-hero-actions",
            ui_status_badge(next_state, status = if (identical(next_state, "Review")) "success" else "info"),
            tags$span(paste(completed, "of", nrow(summary), "stages have evidence")),
            tags$span(paste(evidence_count, "artifact(s)")),
            tags$span(paste(plan_count, "report plan(s)"))
          )
        ),
        tags$div(
          class = "aq-workflow-current-position",
          tags$span("Current position"),
          tags$strong(if (nrow(next_stage)) next_stage$label[[1]] else "Unknown"),
          tags$p(if (nrow(next_stage)) next_stage$recommended_next_stage[[1]] %||% "Review and deliver evidence." else "Load or open a project to begin.")
        )
      )
    })

    output$workflow_pathway <- renderUI({
      summary <- summary_reactive()
      next_stage <- next_stage_reactive()
      current_id <- if (nrow(next_stage)) next_stage$stage_id[[1]] else NA_character_
      tags$section(
        class = "aq-workflow-route",
        tags$div(
          class = "aq-workflow-route-header",
          tags$p(class = "aq-workflow-kicker", "Route"),
          tags$h3("Business question to exportable evidence"),
          tags$p("Follow the route left to right. Completed stages become evidence; the highlighted stage is the next useful move.")
        ),
        tags$ol(
          class = "aq-workflow-timeline",
          lapply(seq_len(nrow(summary)), function(i) {
            row <- summary[i]
            state <- if (row$artifact_count[[1]] > 0L) {
              "complete"
            } else if (identical(row$stage_id[[1]], current_id)) {
              "current"
            } else if (row$status[[1]] %in% c("planned", "deferred")) {
              "planned"
            } else {
              "pending"
            }
            tags$li(
              class = paste("aq-workflow-step", paste0("aq-workflow-step-", state)),
              tags$span(class = "aq-workflow-step-index", row$order[[1]]),
              tags$div(
                class = "aq-workflow-step-body",
                tags$strong(row$label[[1]]),
                tags$p(row$purpose[[1]]),
                tags$div(
                  class = "aq-workflow-step-facts",
                  ui_status_badge(if (state == "complete") "Evidence exists" else if (state == "current") "Next move" else workflow_status_label(row$status[[1]]), status = if (state == "complete") "success" else if (state == "current") "info" else workflow_status_badge_status(row$status[[1]])),
                  tags$span(paste(row$artifact_count[[1]], "artifact(s)"))
                )
              )
            )
          })
        )
      )
    })

    output$workflow_evidence_strip <- renderUI({
      summary <- summary_reactive()
      tags$section(
        class = "aq-workflow-evidence-strip",
        tags$div(
          tags$p(class = "aq-workflow-kicker", "Evidence"),
          tags$h3("What already exists")
        ),
        tags$div(
          class = "aq-workflow-evidence-grid",
          lapply(seq_len(nrow(summary)), function(i) {
            row <- summary[i]
            tags$article(
              class = "aq-workflow-evidence-tile",
              tags$span(row$label[[1]]),
              tags$strong(row$artifact_count[[1]]),
              tags$p(paste(row$report_plan_count[[1]], "report plan(s)"))
            )
          })
        )
      )
    })

    output$workflow_action_panel <- renderUI({
      next_stage <- next_stage_reactive()
      if (!nrow(next_stage)) {
        return(ui_empty_state("No next move detected.", "Load data or open a project, then return to Workflow."))
      }
      stage <- workflow_stage_registry()[[which(vapply(workflow_stage_registry(), function(x) identical(x$stage_id, next_stage$stage_id[[1]]), logical(1)))[[1]]]]
      module_ids <- workflow_stage_module_ids(stage)
      actions <- list()
      if (length(module_ids)) {
        actions <- lapply(module_ids, function(module_id) {
          module <- get_module_definition(module_id)
          actionButton(
            session$ns(paste0("open_module_", stage$stage_id, "_", module_id)),
            paste("Open", module$label %||% module_id),
            class = "btn-primary btn-block"
          )
        })
      }

      tags$section(
        class = "aq-workflow-action-card",
        tags$p(class = "aq-workflow-kicker", "Next action"),
        tags$h3(stage$label),
        tags$p(stage$purpose),
        if (length(actions)) do.call(tagList, actions) else ui_empty_state("No native module yet.", "Use a governed Code Runner hook or external tool for this stage."),
        tags$div(
          class = "aq-workflow-action-secondary",
          tags$p("Need custom support?"),
          ui_action_row(
            actionButton(session$ns(paste0("hook_pre_", stage$stage_id)), "Draft pre-stage code", class = "btn-secondary btn-sm"),
            actionButton(session$ns(paste0("hook_post_", stage$stage_id)), "Draft post-stage code", class = "btn-secondary btn-sm"),
            actionButton(session$ns(paste0("hook_standalone_", stage$stage_id)), "Draft standalone code", class = "btn-secondary btn-sm")
          )
        ),
        uiOutput(session$ns("workflow_message"))
      )
    })

    output$workflow_backstage <- renderUI({
      summary <- data.table::copy(summary_reactive())
      summary[, `:=`(
        status = vapply(status, workflow_status_label, character(1)),
        latest_run_status = vapply(latest_run_status, ui_status_label, character(1)),
        catboost_handoff_available = data.table::fifelse(catboost_handoff_available, "Available", "Not Detected")
      )]
      ui_disclosure(
        "Route Details",
        render_table(
          summary[, list(
            order,
            stage = label,
            status,
            artifacts = artifact_count,
            report_plans = report_plan_count,
            code_drafts = custom_code_hook_count,
            latest_run = latest_run_status,
            handoff = catboost_handoff_available
          )],
          title = NULL,
          page_size = 9,
          searchable = FALSE,
          filterable = FALSE
        ),
        level = "advanced",
        open = FALSE
      )
    })

    output$workflow_message <- renderUI({
      message <- workflow_message()
      if (is.null(message) || !nzchar(message)) {
        return(tags$p(class = "aq-workflow-message", "No workflow action has been taken from this route yet."))
      }
      tags$p(class = "aq-workflow-message", message)
    })

    output$workflow_summary <- renderUI({
      summary <- data.table::copy(summary_reactive())
      summary[, `:=`(
        status = vapply(status, workflow_status_label, character(1)),
        latest_run_status = vapply(latest_run_status, ui_status_label, character(1)),
        catboost_handoff_available = data.table::fifelse(catboost_handoff_available, "Available", "Not Detected")
      )]
      render_table(
        summary[, list(
          order,
          stage = label,
          status,
          artifacts = artifact_count,
          report_plans = report_plan_count,
          code_drafts = custom_code_hook_count,
          latest_run = latest_run_status,
          handoff = catboost_handoff_available
        )],
        title = NULL,
        page_size = 9,
        searchable = FALSE,
        filterable = FALSE
      )
    })

    output$workflow_next_step <- renderUI({
      summary <- summary_reactive()
      next_stage <- summary[status %in% c("implemented", "experimental") & artifact_count == 0L][order(order)][1]
      if (nrow(next_stage)) {
        return(ui_callout(
          paste("Next:", next_stage$label[[1]]),
          paste(next_stage$purpose[[1]], "Open the stage card below to run the module or draft supporting code."),
          status = "info"
        ))
      }
      ui_callout(
        "Workflow evidence is populated",
        "Review Artifact Studio or Mission Control to inspect quality, recommendations, and any remaining open decisions.",
        status = "success"
      )
    })

    output$collector_summary <- renderUI({
      if (!is.function(ctx$project_collector_summary)) {
        return(ui_empty_state("Collector status is unavailable."))
      }
      summary <- ctx$project_collector_summary()
      render_table(
        summary[, list(
          collector_status,
          current_run_id,
          artifact_count,
          bundle_count,
          render_target,
          manifest_status,
          collector_docx
        )],
        title = NULL,
        page_size = 1,
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
    "model_readiness",
    "feature_engineering_model_prep",
    "catboost_builder",
    "model_assessment",
    "model_insights",
    "shap_insights",
    "report_export"
  )

  data.table::data.table(
    check = c("stage_ids", "stage_order", "no_pre_model_assessment_label", "feature_preparation_implemented", "user_friendly_eda_label"),
    status = c(
      if (identical(stages$stage_id, expected)) "success" else "error",
      if (identical(stages$order, seq_along(expected))) "success" else "error",
      if (!any(stages$stage_id %in% c("eda", "model_readiness", "feature_engineering_model_prep") & grepl("Model Assessment", stages$label))) "success" else "error",
      if (identical(stages$status[stages$stage_id == "feature_engineering_model_prep"], "implemented")) "success" else "error",
      if (identical(stages$label[stages$stage_id == "eda"], "Explore Data") && identical(stages$subtitle[stages$stage_id == "eda"], "EDA")) "success" else "error"
    ),
    message = c(
      paste(stages$stage_id, collapse = " -> "),
      paste(stages$order, collapse = ", "),
      "Pre-model stages do not use Model Assessment terminology.",
      "Feature Engineering / Model Preparation is an implemented native workflow stage.",
      "The first workflow stage uses a friendly label while preserving EDA as context."
    )
  )
}

qa_workflow_external_stage_artifact_counts <- function() {
  artifact <- create_artifact(
    artifact_id = "qa_feature_preparation_table",
    artifact_type = "table",
    label = "Feature Preparation QA Table",
    source_module = "code_runner",
    object = data.table::data.table(feature = "x", value = 1),
    metadata = list(
      module_id = "code_runner",
      workflow_stage = "feature_engineering_model_prep",
      custom_code_hook = TRUE
    )
  )
  ctx <- new.env(parent = emptyenv())
  ctx$all_artifacts <- function() list(artifact)
  ctx$report_plan_state <- list(plans = list())
  ctx$code_runner_state <- list(records = list(), requests = list())

  summary <- workflow_state_summary(ctx)
  feature_row <- summary[stage_id == "feature_engineering_model_prep"]

  data.table::data.table(
    check = c("explicit_artifact_stage", "feature_preparation_artifact_count", "code_runner_source_preserved"),
    status = c(
      if (identical(workflow_stage_for_artifact(artifact), "feature_engineering_model_prep")) "success" else "error",
      if (nrow(feature_row) && identical(feature_row$artifact_count[[1]], 1L)) "success" else "error",
      if (identical(artifact$source_module, "code_runner")) "success" else "error"
    ),
    message = c(
      "Workflow summary prefers explicit artifact metadata$workflow_stage when present.",
      "Feature Engineering / Model Preparation counts artifacts created through Code Runner stage hooks.",
      "The producing surface remains Code Runner; the workflow stage supplies lifecycle placement."
    )
  )
}

qa_workflow_feature_engineering_handoff <- function() {
  run_record <- create_code_tracker_record(
    run_id = "qa_feature_preparation_run",
    label = "Feature Engineering / Model Preparation custom code",
    code = "data.table::data.table(feature = 'x', value = 1)",
    source = "manual",
    status = "success",
    metadata = list(
      custom_code_hook = TRUE,
      workflow_stage = "feature_engineering_model_prep",
      hook_timing = "standalone"
    )
  )
  artifacts <- code_output_to_artifact_candidates(
    data.table::data.table(feature = "x", value = 1),
    run_record
  )
  artifact <- artifacts[[1]]

  data.table::data.table(
    check = c("artifact_created", "workflow_stage_metadata", "hook_metadata"),
    status = c(
      if (length(artifacts) == 1L && identical(artifact$artifact_type, "table")) "success" else "error",
      if (identical(artifact$metadata$workflow_stage, "feature_engineering_model_prep")) "success" else "error",
      if (isTRUE(artifact$metadata$custom_code_hook) && identical(artifact$metadata$hook_timing, "standalone")) "success" else "error"
    ),
    message = c(
      "Code Runner output can become a table artifact.",
      "Code Runner stage metadata is preserved on generated artifacts.",
      "Custom hook metadata remains available for workflow attribution."
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
            isTRUE(request$metadata$custom_code_hook) &&
            identical(context$workflow_stage, stage) &&
            identical(request$metadata$workflow_stage, stage) &&
            identical(context$hook_timing, timing) &&
            identical(request$metadata$hook_timing, timing) &&
            identical(request$source, "manual") &&
            !isTRUE(context$auto_run)
        ) "success" else "error",
        message = paste(validation$errors %||% validation$messages %||% "", collapse = " | ")
      )
    }
  }

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

qa_workflow_state_summary <- function() {
  ctx <- new.env(parent = emptyenv())
  ctx$all_artifacts <- function() {
    list(
      artifact_1 = structure(list(
        artifact_id = "artifact_1",
        source_module = "autoquant_eda",
        metadata = list(module_id = "autoquant_eda")
      ), class = c("aq_artifact", "list")),
      artifact_2 = structure(list(
        artifact_id = "artifact_2",
        source_module = "autoquant_catboost_builder",
        metadata = list(module_id = "autoquant_catboost_builder", downstream_handoff = list(available = TRUE))
      ), class = c("aq_artifact", "list"))
    )
  }
  ctx$report_plan_state <- list(plans = list(
    plan_1 = list(plan_id = "plan_1", metadata = list(module_id = "autoquant_eda")),
    plan_2 = list(plan_id = "plan_2", source_module = "autoquant_catboost_builder")
  ))
  ctx$code_runner_state <- list(
    requests = list(
      hook_1 = create_custom_code_hook_request(
        run_id = "hook_1",
        stage = "eda",
        timing = "pre_stage",
        label = "QA hook",
        code = "# QA hook\n",
        status = "draft"
      )
    ),
    records = list()
  )

  summary <- workflow_state_summary(ctx)
  data.table::data.table(
    check = c(
      "summary_rows",
      "artifact_counts",
      "report_plan_counts",
      "handoff_available",
      "hook_counts"
    ),
    status = c(
      if (nrow(summary) == length(workflow_stage_registry())) "success" else "error",
      if (summary[stage_id == "eda", artifact_count][[1L]] == 1L &&
          summary[stage_id == "catboost_builder", artifact_count][[1L]] == 1L) "success" else "error",
      if (summary[stage_id == "eda", report_plan_count][[1L]] == 1L &&
          summary[stage_id == "catboost_builder", report_plan_count][[1L]] == 1L) "success" else "error",
      if (isTRUE(summary[stage_id == "catboost_builder", catboost_handoff_available][[1L]])) "success" else "error",
      if (summary[stage_id == "eda", custom_code_hook_count][[1L]] == 1L) "success" else "error"
    ),
    message = c(
      paste("Summary rows:", nrow(summary)),
      "Artifact counts map through source module metadata.",
      "Report plan counts map through source module metadata.",
      "CatBoost handoff availability is detected from artifact metadata.",
      "Custom hook drafts/history are counted from Code Runner requests."
    )
  )
}

qa_workflow_page_contract <- function() {
  ui <- page_workflow_ui("workflow")
  summary <- workflow_state_summary()
  modules <- unlist(lapply(workflow_stage_registry(), workflow_stage_module_ids), use.names = FALSE)
  modules <- modules[nzchar(modules)]
  registry <- get_module_registry()

  data.table::data.table(
    check = c("ui_constructs", "server_exists", "implemented_modules_valid", "summary_returns_rows", "no_autonls_direct_call", "no_dt_usage"),
    status = c(
      if (inherits(ui, "shiny.tag")) "success" else "error",
      if (exists("page_workflow_server", mode = "function")) "success" else "error",
      if (all(modules %in% names(registry))) "success" else "error",
      if (nrow(summary) == length(workflow_stage_registry())) "success" else "error",
      if (!any(grepl(paste0("AutoNLS", "::"), readLines("R/page_workflow.R", warn = FALSE), ignore.case = TRUE))) "success" else "error",
      if (!any(grepl("\\bDT::|datatable\\(", readLines("R/page_workflow.R", warn = FALSE)))) "success" else "error"
    ),
    message = c(
      "Workflow UI tab constructs.",
      "Workflow server module exists.",
      paste(modules, collapse = ", "),
      paste("Summary rows:", nrow(summary)),
      "Workflow page does not call AutoNLS directly.",
      "Workflow page does not add DT usage."
    )
  )
}
