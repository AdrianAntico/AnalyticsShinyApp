page_artifact_library_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Artifact Studio",
    ui_page(
      title = "Artifact Studio",
      subtitle = "Explore project evidence through filters, gallery cards, a persistent inspector, and the artifact filmstrip.",
      eyebrow = "Evidence",
      uiOutput(ns("artifact_studio_overview")),
      tags$div(
        class = "aq-artifact-studio",
        tags$aside(
          class = "aq-artifact-studio-left",
          ui_card(
            title = "Filters",
            subtitle = "Narrow the evidence field.",
            selectInput(ns("artifact_collection_filter"), "Collection", choices = c("All"), selected = "All"),
            selectInput(ns("artifact_type_filter"), "Type", choices = c("All"), selected = "All"),
            selectInput(ns("artifact_module_filter"), "Module", choices = c("All"), selected = "All"),
            selectInput(ns("artifact_run_filter"), "Run", choices = c("All"), selected = "All"),
            selectInput(
              ns("artifact_quality_filter"),
              "Quality",
              choices = c("All", "High", "Warning", "Needs Attention"),
              selected = "All"
            ),
            textInput(ns("artifact_search"), "Search", value = "", placeholder = "Search title, module, intent, section")
          ),
          ui_card(
            title = "Project Collections",
            uiOutput(ns("artifact_collection_summary"))
          )
        ),
        tags$main(
          class = "aq-artifact-studio-center",
          ui_card(
            title = "Artifact Gallery",
            subtitle = "Cards are selectable analytical evidence objects.",
            uiOutput(ns("artifact_gallery"))
          )
        ),
        tags$aside(
          class = "aq-artifact-studio-right",
          uiOutput(ns("artifact_inspector"))
        )
      ),
      tags$section(
        class = "aq-artifact-studio-bottom",
        ui_section_header("Filmstrip", "Recently generated artifacts for quick switching.", eyebrow = "Recent Evidence"),
        uiOutput(ns("artifact_filmstrip"))
      )
    )
  )
}

page_artifact_library_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    selected_artifact_id <- ctx$artifact_studio_selected_artifact_id %||% reactiveVal(NULL)
    observed_artifact_actions <- new.env(parent = emptyenv())

    artifact_quality <- function(artifact) {
      tryCatch(
        assess_artifact_quality(artifact, render_target = "llm_docx"),
        error = function(e) list(
          artifact_completeness = NA_real_,
          severity = "warning",
          recommendation = conditionMessage(e),
          components = list()
        )
      )
    }

    artifact_run_id <- function(artifact) {
      artifact <- artifact_with_thumbnail(artifact)
      metadata <- artifact$metadata %||% list()
      metadata$module_run_id %||% metadata$run_id %||% "No run"
    }

    artifact_intent <- function(artifact) {
      metadata <- artifact$metadata %||% list()
      metadata$analytical_intent %||% infer_artifact_intent(
        artifact$artifact_type,
        artifact$label,
        artifact$section,
        metadata$original_name
      )
    }

    artifact_importance <- function(artifact) {
      metadata <- artifact$metadata %||% list()
      metadata$artifact_importance %||% infer_artifact_importance(
        artifact$source_module,
        artifact$artifact_type,
        artifact$label,
        artifact$section,
        metadata$original_name
      )
    }

    artifact_by_id <- function(artifacts, artifact_id) {
      if (is.null(artifact_id) || !length(artifacts)) {
        return(NULL)
      }
      if (artifact_id %in% names(artifacts)) {
        return(artifacts[[artifact_id]])
      }
      ids <- vapply(artifacts, function(artifact) artifact$artifact_id %||% "", character(1))
      match_index <- match(artifact_id, ids)
      if (is.na(match_index)) {
        return(NULL)
      }
      artifacts[[match_index]]
    }

    artifact_with_thumbnail <- function(artifact) {
      if (is.null(artifact) || !identical(artifact$artifact_type, "plot")) {
        return(artifact)
      }
      if (!is.null(artifact_thumbnail_path(artifact))) {
        return(artifact)
      }

      metadata <- artifact$metadata %||% list()
      run_id <- metadata$module_run_id %||% metadata$run_id %||% NULL
      module_id <- artifact$source_module %||% metadata$module_id %||% NULL
      collector <- ctx$project_collector_state$collector
      if (is.null(run_id) || is.null(module_id) || !inherits(collector, "project_artifact_collector")) {
        return(artifact)
      }

      screenshot_stem <- .project_collector_slug(paste(run_id, module_id, artifact$artifact_id, sep = "_"))
      screenshot_path <- file.path(collector$screenshot_directory, paste0(screenshot_stem, ".png"))
      if (file.exists(screenshot_path)) {
        artifact$metadata$thumbnail_path <- normalizePath(screenshot_path, winslash = "/", mustWork = TRUE)
        artifact$metadata$screenshot_path <- artifact$metadata$thumbnail_path
      }
      artifact
    }

    render_studio_preview <- function(artifact) {
      artifact <- artifact_with_thumbnail(artifact)
      thumbnail_src <- artifact_thumbnail_src(artifact)
      if (identical(artifact$artifact_type, "plot") && !is.null(thumbnail_src)) {
        return(tags$figure(
          class = "aq-artifact-inspector-figure",
          tags$img(src = thumbnail_src, alt = artifact$label %||% artifact$artifact_id),
          tags$figcaption("Collector screenshot preview")
        ))
      }
      render_artifact(artifact)
    }

    artifact_quality_group <- function(quality) {
      score <- suppressWarnings(as.numeric(quality$artifact_completeness %||% NA_real_))
      if (!length(score) || is.na(score[[1]])) {
        score <- NA_real_
      } else {
        score <- score[[1]]
      }
      if (identical(quality$severity %||% "", "error")) return("Needs Attention")
      if (identical(quality$severity %||% "", "warning")) return("Warning")
      if (!is.na(score) && score >= 80) return("High")
      "Warning"
    }

    artifact_index <- reactive({
      artifacts <- ctx$all_artifacts()
      if (is.null(artifacts) || !length(artifacts)) {
        return(data.table::data.table(
          artifact_id = character(),
          title = character(),
          artifact_type = character(),
          type_label = character(),
          module = character(),
          section = character(),
          run_id = character(),
          quality = numeric(),
          quality_group = character(),
          importance = character(),
          intent = character(),
          render_targets = character(),
          updated_at = as.POSIXct(character())
        ))
      }

      rows <- lapply(artifacts, function(artifact) {
        metadata <- artifact$metadata %||% list()
        quality <- artifact_quality(artifact)
        quality_score <- suppressWarnings(as.numeric(quality$artifact_completeness %||% NA_real_))
        if (!length(quality_score) || is.na(quality_score[[1]])) {
          quality_score <- NA_real_
        } else {
          quality_score <- quality_score[[1]]
        }
        data.table::data.table(
          artifact_id = artifact$artifact_id %||% NA_character_,
          title = artifact$label %||% artifact$artifact_id %||% NA_character_,
          artifact_type = artifact$artifact_type %||% NA_character_,
          type_label = artifact_type_label(artifact$artifact_type %||% "artifact"),
          module = module_display_label(artifact$source_module, artifact$source_module),
          section = artifact$section %||% "Analysis",
          run_id = artifact_run_id(artifact),
          quality = quality_score,
          quality_group = artifact_quality_group(quality),
          importance = artifact_importance(artifact),
          intent = artifact_intent(artifact),
          render_targets = paste(metadata$render_targets %||% c("human_report", "llm_docx"), collapse = ", "),
          updated_at = as.POSIXct(artifact$updated_at %||% artifact$created_at %||% Sys.time())
        )
      })
      data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
    })

    filtered_artifact_index <- reactive({
      index <- artifact_index()
      if (!nrow(index)) return(index)

      collection <- selected_value(input$artifact_collection_filter) %||% "All"
      type <- selected_value(input$artifact_type_filter) %||% "All"
      module <- selected_value(input$artifact_module_filter) %||% "All"
      run_filter <- selected_value(input$artifact_run_filter) %||% "All"
      quality <- selected_value(input$artifact_quality_filter) %||% "All"
      search <- trimws(selected_value(input$artifact_search) %||% "")

      if (!identical(collection, "All")) index <- index[section == collection]
      if (!identical(type, "All")) index <- index[type_label == type]
      if (!identical(module, "All")) index <- index[module == module]
      if (!identical(run_filter, "All")) index <- index[run_id == run_filter]
      if (!identical(quality, "All")) index <- index[quality_group == quality]
      if (nzchar(search)) {
        haystack <- tolower(paste(index$title, index$module, index$intent, index$section, index$artifact_id))
        index <- index[grepl(tolower(search), haystack, fixed = TRUE)]
      }

      index[order(-updated_at, section, title)]
    })

    selected_artifact <- reactive({
      artifacts <- ctx$all_artifacts()
      selected <- selected_artifact_id() %||% selected_value(input$selected_artifact_id)
      artifact <- artifact_by_id(artifacts, selected)
      if (is.null(artifact)) {
        index <- filtered_artifact_index()
        if (!nrow(index)) return(NULL)
        selected <- index$artifact_id[[1]]
        selected_artifact_id(selected)
        artifact <- artifact_by_id(artifacts, selected)
      }
      artifact
    })

    observe({
      index <- artifact_index()
      collections <- sort(unique(index$section))
      types <- sort(unique(index$type_label))
      modules <- sort(unique(index$module))
      runs <- sort(unique(index$run_id))
      updateSelectInput(session, "artifact_collection_filter", choices = c("All", collections), selected = selected_value(input$artifact_collection_filter) %||% "All")
      updateSelectInput(session, "artifact_type_filter", choices = c("All", types), selected = selected_value(input$artifact_type_filter) %||% "All")
      updateSelectInput(session, "artifact_module_filter", choices = c("All", modules), selected = selected_value(input$artifact_module_filter) %||% "All")
      updateSelectInput(session, "artifact_run_filter", choices = c("All", runs), selected = selected_value(input$artifact_run_filter) %||% "All")
    })

    observe({
      index <- filtered_artifact_index()
      if (!nrow(index)) {
        selected_artifact_id(NULL)
        return()
      }
      selected <- selected_artifact_id()
      if (is.null(selected) || !selected %in% index$artifact_id) {
        selected_artifact_id(index$artifact_id[[1]])
      }
    })

    observe({
      artifacts <- ctx$all_artifacts()
      for (artifact in artifacts) {
        artifact_id <- artifact$artifact_id %||% NULL
        if (is.null(artifact_id) || !nzchar(artifact_id)) next
        safe_id <- artifact_studio_safe_id(artifact_id)
        inspect_id <- paste0("inspect_", safe_id)
        if (!isTRUE(observed_artifact_actions[[inspect_id]])) {
          observed_artifact_actions[[inspect_id]] <- TRUE
          local({
            artifact_id_local <- artifact_id
            inspect_id_local <- inspect_id
            observeEvent(input[[inspect_id_local]], {
              selected_artifact_id(artifact_id_local)
            }, ignoreInit = TRUE)
          })
        }
        for (prefix in c("compare_", "story_")) {
          action_id <- paste0(prefix, safe_id)
          if (!isTRUE(observed_artifact_actions[[action_id]])) {
            observed_artifact_actions[[action_id]] <- TRUE
            local({
              artifact_id_local <- artifact_id
              action_id_local <- action_id
              observeEvent(input[[action_id_local]], {
                selected_artifact_id(artifact_id_local)
                ctx$artifact_library_message("Placeholder action. Compare and Story Builder are planned roadmap capabilities.")
              }, ignoreInit = TRUE)
            })
          }
        }
      }
    })

    observeEvent(input$filmstrip_select, {
      selected_artifact_id(input$filmstrip_select)
    }, ignoreInit = TRUE)

    output$artifact_studio_overview <- renderUI({
      index <- artifact_index()
      total <- nrow(index)
      selected <- selected_artifact()
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      collector_status <- if (nrow(collector)) collector$collector_status[[1]] %||% "created" else "not_created"
      ui_stat_grid(
        ui_stat_tile("Artifacts", total, status = if (total) "success" else "neutral", detail = "project evidence"),
        ui_stat_tile("Selected", if (is.null(selected)) "-" else selected$label %||% selected$artifact_id, detail = if (is.null(selected)) "none" else selected$artifact_type),
        ui_stat_tile("Collections", length(unique(index$section)), detail = "sections"),
        ui_stat_tile("Collector", collector_status, status = if (collector_status %in% c("success", "created")) "success" else "neutral")
      )
    })

    output$artifact_collection_summary <- renderUI({
      index <- artifact_index()
      if (!nrow(index)) {
        return(ui_empty_state("No collections yet.", "Run an analysis module or create artifacts to populate collections."))
      }
      collection_summary <- index[, .(
        artifacts = .N,
        avg_quality = round(mean(quality, na.rm = TRUE), 1)
      ), by = section][order(section)]
      render_table(collection_summary, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$artifact_gallery <- renderUI({
      index <- filtered_artifact_index()
      artifacts <- ctx$all_artifacts()
      if (!nrow(index)) {
        return(tags$div(
          class = "aq-artifact-studio-empty",
          ui_empty_state(
            "No artifacts match this view.",
            "Clear filters or run an analysis module to generate EDA, readiness, model insight, SHAP, plot, text, or table artifacts."
          ),
          tags$div(
            class = "aq-artifact-studio-empty-actions",
            tags$article(
              class = "aq-artifact-studio-empty-action",
              tags$strong("Generate evidence"),
              tags$span("Run EDA, Model Readiness, Model Insights, or SHAP from Analysis Modules.")
            ),
            tags$article(
              class = "aq-artifact-studio-empty-action",
              tags$strong("Create manual artifacts"),
              tags$span("Use Plot Builder or Layout Studio to add plots, text, and tables.")
            ),
            tags$article(
              class = "aq-artifact-studio-empty-action",
              tags$strong("Return here"),
              tags$span("New artifacts will appear as cards and in the bottom filmstrip automatically.")
            )
          )
        ))
      }
      selected <- selected_artifact_id()
      tags$div(
        class = "aq-artifact-gallery",
        lapply(index$artifact_id, function(artifact_id) {
          artifact <- artifact_by_id(artifacts, artifact_id)
          if (is.null(artifact)) {
            return(NULL)
          }
          artifact <- artifact_with_thumbnail(artifact)
          ui_artifact_studio_card(
            artifact = artifact,
            quality = artifact_quality(artifact),
            selected = identical(artifact_id, selected),
            ns = session$ns
          )
        })
      )
    })

    output$artifact_inspector <- renderUI({
      artifact <- selected_artifact()
      if (is.null(artifact)) {
        return(ui_card(
          title = "Artifact Inspector",
          ui_empty_state(
            "Inspector is waiting for evidence.",
            "Select an artifact to inspect its preview, quality, diagnostics, metadata, collector status, and backing assets."
          ),
          tags$div(
            class = "aq-artifact-inspector-placeholder",
            tags$span("Preview"),
            tags$span("Quality"),
            tags$span("Diagnostics"),
            tags$span("Backing Assets")
          )
        ))
      }

      metadata <- artifact$metadata %||% list()
      quality <- artifact_quality(artifact)
      components <- quality$components %||% list()
      thumbnail_path <- artifact_thumbnail_path(artifact)
      if (!is.null(thumbnail_path)) {
        components$screenshot <- "available"
      }
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      collector_status <- if (nrow(collector)) collector$collector_status[[1]] %||% "not_created" else "not_created"
      ai_readiness <- if (nrow(collector) && (collector$artifact_count[[1]] %||% 0L) > 0L) "ready" else "pending"
      collector_rows <- if (nrow(collector)) {
        collector[, list(collector_status, current_run_id, artifact_count, bundle_count, render_target, collector_docx, manifest_status)]
      } else {
        data.table::data.table(status = "not_created")
      }
      backing_rows <- data.table::data.table(
        asset = c("CSV", "JSON", "Table Preview", "Screenshot"),
        status = c(
          components$csv %||% "not_supplied",
          components$json %||% "not_supplied",
          components$table_preview %||% "not_applicable",
          components$screenshot %||% "not_applicable"
        )
      )
      if (!is.null(thumbnail_path)) {
        backing_rows <- data.table::rbindlist(list(
          backing_rows,
          data.table::data.table(asset = "Thumbnail", status = thumbnail_path)
        ), use.names = TRUE, fill = TRUE)
      }
      meta_rows <- data.table::data.table(
        field = c("Artifact ID", "Producer", "Timestamp", "Run ID", "Collection", "Render Targets", "Policy Source", "Quality Source", "Status", "Visible"),
        value = c(
          artifact$artifact_id %||% "",
          artifact$source_module %||% "",
          as.character(metadata$generated_at %||% artifact$created_at %||% ""),
          artifact_run_id(artifact),
          artifact$section %||% "",
          paste(metadata$render_targets %||% c("human_report", "llm_docx"), collapse = ", "),
          metadata$policy_source %||% "inferred",
          quality$source %||% "artifact_quality_policy",
          artifact$status %||% "",
          as.character(isTRUE(artifact$visible))
        )
      )
      diagnostics <- metadata$diagnostics %||% metadata$warnings %||% character()
      recommendations <- metadata$recommendations %||% quality$recommendation %||% character()
      if (!is.null(thumbnail_path)) {
        recommendations <- recommendations[!grepl("screenshot", recommendations, ignore.case = TRUE)]
      }
      quality_warnings <- c(
        quality$missing_required_components %||% character(),
        quality$missing_required_metadata %||% character(),
        metadata$warnings %||% character()
      )
      if (!is.null(thumbnail_path)) {
        quality_warnings <- quality_warnings[tolower(quality_warnings) != "screenshot"]
      }
      quality_status <- if (identical(quality$severity %||% "", "error")) "error" else if (identical(quality$severity %||% "", "warning")) "warning" else "success"
      completeness_value <- suppressWarnings(as.numeric(quality$artifact_completeness %||% NA_real_))
      completeness_label <- if (!length(completeness_value) || is.na(completeness_value[[1]])) {
        "Not scored"
      } else {
        paste0(round(completeness_value[[1]]), "%")
      }
      summary_rows <- data.table::data.table(
        field = c("Module", "Run", "Type", "Intent", "Importance", "Targets"),
        value = c(
          artifact$source_module %||% "",
          artifact_run_id(artifact),
          artifact_type_label(artifact$artifact_type %||% ""),
          artifact_intent(artifact),
          artifact_importance(artifact),
          paste(metadata$render_targets %||% c("human_report", "llm_docx"), collapse = ", ")
        )
      )
      summary_badges <- tagList(
        ui_status_badge(artifact_type_label(artifact$artifact_type %||% "artifact"), status = "info"),
        ui_status_badge(artifact_intent(artifact), status = "info"),
        ui_status_badge(artifact_importance(artifact), status = if (identical(artifact_importance(artifact), "critical")) "warning" else "neutral")
      )

      ui_card(
        title = "Evidence Inspector",
        subtitle = artifact$label %||% artifact$artifact_id,
        tags$div(
          class = "aq-artifact-inspector",
          ui_inspector_section(
            "Hero Preview",
            tags$div(
              class = "aq-artifact-inspector-preview",
              render_studio_preview(artifact)
            ),
            eyebrow = "Evidence",
            class = "aq-inspector-hero"
          ),
          ui_evidence_summary(
            title = artifact$label %||% artifact$artifact_id,
            caption = quality$caption %||% artifact_caption(artifact, "llm_docx"),
            purpose = metadata$artifact_purpose %||% paste(
              artifact_intent(artifact),
              "evidence from",
              module_display_label(artifact$source_module, artifact$source_module)
            ),
            items = summary_rows,
            badges = summary_badges
          ),
          ui_quality_summary(
            score = quality$artifact_completeness,
            severity = quality_status,
            completeness = completeness_label,
            warnings = quality_warnings,
            collector_status = collector_status,
            ai_readiness = ai_readiness
          ),
          ui_inspector_section(
            "GenAI Assistance",
            ui_genai_status_panel(
              ctx$genai_status(check_availability = FALSE),
              title = "Artifact Summary Assistant",
              actions = ui_action_row(
                actionButton(session$ns("summarize_selected_artifact"), "Summarize Artifact", class = "btn-primary btn-sm")
              ),
              result = ctx$genai_last_result()
            ),
            eyebrow = "Read Only",
            collapsed = TRUE
          ),
          ui_inspector_section(
            "Recommendations",
            if (length(recommendations)) {
              tags$ul(class = "aq-recommendation-list", lapply(as.character(recommendations), tags$li))
            } else {
              ui_empty_state("No recommendations are available.", "This artifact did not generate follow-up guidance.")
            },
            eyebrow = "Next Best Action",
            class = "aq-inspector-recommendations"
          ),
          ui_inspector_section(
            "Diagnostics",
            if (length(diagnostics)) {
              tags$ul(class = "aq-diagnostic-list", lapply(as.character(diagnostics), tags$li))
            } else {
              ui_empty_state("No diagnostics were generated.", "There are no warnings, validation messages, or risk indicators attached to this artifact.")
            },
            collapsed = TRUE
          ),
          ui_inspector_section(
            "Metadata",
            ui_metadata_grid(meta_rows),
            render_table(collector_rows, engine = "html", searchable = FALSE, sortable = FALSE),
            collapsed = TRUE
          ),
          ui_inspector_section(
            "Backing Assets",
            ui_backing_asset_panel(backing_rows),
            uiOutput(session$ns("artifact_library_table_exports")),
            collapsed = TRUE
          )
        )
      )
    })

    output$artifact_filmstrip <- renderUI({
      ui_artifact_filmstrip(
        artifacts = ctx$all_artifacts(),
        selected_id = selected_artifact_id(),
        ns = session$ns
      )
    })

    output$artifact_library_table_exports <- renderUI({
      artifact <- selected_artifact()
      if (is.null(artifact) || !identical(artifact$artifact_type, "table")) {
        return(ui_empty_state("No table sidecar actions.", "CSV/XLSX export appears here for table artifacts."))
      }

      ui_action_row(
        actionButton(session$ns("library_export_table_csv"), "Export Table CSV", class = "btn-secondary"),
        actionButton(session$ns("library_export_table_xlsx"), "Export Table XLSX", class = "btn-secondary")
      )
    })

    observeEvent(input$library_export_table_csv, {
      artifact <- selected_artifact()
      if (is.null(artifact) || !identical(artifact$artifact_type, "table")) {
        ctx$artifact_library_message("Select a table artifact before exporting CSV.")
        return()
      }

      result <- tryCatch(
        export_table_csv(
          artifact_or_data = artifact,
          path = ctx$get_export_dir(),
          name = artifact$artifact_id
        ),
        error = function(e) service_result(status = "error", errors = conditionMessage(e))
      )
      ctx$artifact_library_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$library_export_table_xlsx, {
      artifact <- selected_artifact()
      if (is.null(artifact) || !identical(artifact$artifact_type, "table")) {
        ctx$artifact_library_message("Select a table artifact before exporting XLSX.")
        return()
      }

      result <- tryCatch(
        export_table_xlsx(
          artifacts_or_tables = artifact,
          path = ctx$get_export_dir(),
          name = artifact$artifact_id
        ),
        error = function(e) service_result(status = "error", errors = conditionMessage(e))
      )
      ctx$artifact_library_message(service_result_message(result))
    }, ignoreInit = TRUE)

    observeEvent(input$summarize_selected_artifact, {
      artifact <- selected_artifact()
      if (is.null(artifact)) {
        ctx$artifact_library_message("Select an artifact before requesting a GenAI summary.")
        return()
      }
      result <- genai_summarize_artifact(artifact, config = ctx$genai_config())
      ctx$genai_last_result(result)
      ctx$artifact_library_message(service_result_message(result))
    }, ignoreInit = TRUE)
  })
}

qa_artifact_studio <- function() {
  page <- if (file.exists(file.path("R", "page_artifact_library.R"))) {
    paste(readLines(file.path("R", "page_artifact_library.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  components <- if (file.exists(file.path("R", "ui_components.R"))) {
    paste(readLines(file.path("R", "ui_components.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  css <- if (file.exists(file.path("www", "app.css"))) {
    paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  has <- function(text, patterns) {
    all(vapply(patterns, function(pattern) grepl(pattern, text, fixed = TRUE), logical(1)))
  }

  data.table::data.table(
    check = c(
      "studio_mode_label",
      "four_region_layout",
      "gallery_cards",
      "inspector",
      "inspector_preview",
      "inspector_summary",
      "inspector_quality",
      "inspector_diagnostics",
      "inspector_recommendations",
      "inspector_metadata",
      "inspector_backing_assets",
      "inspector_progressive_disclosure",
      "inspector_empty_states",
      "filmstrip",
      "selection",
      "selection_state",
      "active_highlighting",
      "hover_states",
      "inspector_transitions",
      "filmstrip_state",
      "gallery_consistency",
      "layout_stability",
      "reduced_motion",
      "empty_state",
      "collector_integration",
      "artifact_quality",
      "placeholder_actions",
      "reusable_components",
      "studio_css"
    ),
    status = c(
      if (grepl("Artifact Studio", page, fixed = TRUE)) "success" else "error",
      if (has(page, c("aq-artifact-studio-left", "aq-artifact-studio-center", "aq-artifact-studio-right", "aq-artifact-studio-bottom"))) "success" else "error",
      if (grepl("ui_artifact_studio_card", page, fixed = TRUE)) "success" else "error",
      if (has(page, c("artifact_inspector", "Evidence Inspector")) || grepl("aq-artifact-inspector-preview", page, fixed = TRUE)) "success" else "error",
      if (has(page, c("Hero Preview", "render_studio_preview", "aq-artifact-inspector-preview"))) "success" else "error",
      if (has(page, c("ui_evidence_summary", "summary_rows", "artifact_purpose"))) "success" else "error",
      if (has(page, c("ui_quality_summary", "collector_status", "ai_readiness"))) "success" else "error",
      if (has(page, c("Diagnostics", "No diagnostics were generated"))) "success" else "error",
      if (has(page, c("Recommendations", "No recommendations are available"))) "success" else "error",
      if (has(page, c("Metadata", "ui_metadata_grid", "Policy Source"))) "success" else "error",
      if (has(page, c("Backing Assets", "ui_backing_asset_panel", "Thumbnail"))) "success" else "error",
      if (has(page, c("collapsed = TRUE", "ui_inspector_section"))) "success" else "error",
      if (has(page, c("No diagnostics were generated", "No recommendations are available", "No table sidecar actions"))) "success" else "error",
      if (grepl("ui_artifact_filmstrip", page, fixed = TRUE)) "success" else "error",
      if (has(page, c("selected_artifact_id", "filmstrip_select", "inspect_"))) "success" else "error",
      if (has(components, c("aria-current", "data-artifact-id", "aq-studio-card-selected"))) "success" else "error",
      if (has(css, c(".aq-studio-card-selected::after", ".aq-artifact-filmstrip-item-selected")) && grepl("aria-pressed", components, fixed = TRUE)) "success" else "error",
      if (has(css, c(".aq-studio-card:hover", ".aq-studio-card:focus-within", ".aq-artifact-filmstrip-item:hover::after"))) "success" else "error",
      if (has(css, c("aq-inspector-enter", ".aq-artifact-inspector", "animation: aq-inspector-enter"))) "success" else "error",
      if (has(components, c("data-preview", "aq-artifact-filmstrip-item-selected", "aria-pressed"))) "success" else "error",
      if (has(components, c("aq-studio-card-quality-", "data-intent", "data-importance", "data-quality"))) "success" else "error",
      if (has(css, c("grid-template-rows: 104px 1fr auto", "min-height: 36px", "max-height: 560px"))) "success" else "error",
      if (has(css, c("prefers-reduced-motion", "animation: none !important", "transition: none !important"))) "success" else "error",
      if (grepl("No artifacts match this view", page, fixed = TRUE) && grepl("No artifact selected", page, fixed = TRUE)) "success" else "error",
      if (grepl("project_collector_summary", page, fixed = TRUE)) "success" else "error",
      if (grepl("assess_artifact_quality", page, fixed = TRUE)) "success" else "error",
      if (grepl("Compare and Story Builder are planned roadmap capabilities", page, fixed = TRUE)) "success" else "error",
      if (has(components, c("ui_artifact_studio_card", "ui_artifact_filmstrip", "artifact_studio_type_icon", "ui_inspector_section", "ui_quality_summary", "ui_metadata_grid", "ui_backing_asset_panel"))) "success" else "error",
      if (has(css, c(".aq-artifact-studio", ".aq-artifact-gallery", ".aq-artifact-inspector", ".aq-artifact-filmstrip", ".aq-evidence-summary", ".aq-quality-summary", ".aq-backing-assets"))) "success" else "error"
    ),
    message = c(
      "Artifact Library is now presented as Artifact Studio.",
      "Studio includes left filters, center gallery, right inspector, and bottom filmstrip regions.",
      "Artifact cards are rendered as visual evidence objects.",
      "Inspector region is present for selected artifact details.",
      "Inspector has a hero preview section.",
      "Inspector has an executive evidence summary.",
      "Inspector has a first-class quality summary.",
      "Inspector diagnostics are available behind disclosure.",
      "Inspector recommendations are surfaced as their own section.",
      "Inspector metadata is moved to an advanced area.",
      "Inspector backing assets have a dedicated section.",
      "Inspector uses progressive disclosure.",
      "Inspector has meaningful empty states.",
      "Reusable filmstrip is present.",
      "Gallery and filmstrip selection paths are present.",
      "Selected artifacts expose state for cards and assistive technology.",
      "Active card and filmstrip highlighting are styled.",
      "Gallery and filmstrip hover/focus states are styled.",
      "Inspector has a short transition when artifacts change.",
      "Filmstrip items expose selected and hover-preview state.",
      "Gallery cards expose quality, intent, and importance state.",
      "Card and inspector dimensions reduce layout jumps.",
      "Reduced-motion preferences are respected.",
      "Studio has guided empty states.",
      "Inspector surfaces Project Artifact Collector information.",
      "Artifact Quality Policy is used in Studio surfaces.",
      "Compare and Add to Story are explicit placeholders.",
      "Studio card and filmstrip are reusable workstation components.",
      "Studio CSS selectors are present."
    )
  )
}
