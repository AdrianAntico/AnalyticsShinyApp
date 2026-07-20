mapping_control <- function(mapping, data, required = TRUE, selected = NULL, ns = identity) {
  choices <- column_choices(data, include_none = !required)
  if (identical(mapping, "CorrVars")) {
    all_choices <- column_choices(data)
    if (is.null(selected)) {
      selected <- names(data)
    }

    selected <- selected[selected %in% all_choices]
    if (!length(selected)) {
      selected <- all_choices
    }

    return(selectInput(
      ns(mapping_input_id(mapping)),
      mapping_label(mapping),
      choices = all_choices,
      selected = selected,
      multiple = TRUE
    ))
  }

  if (is.null(selected) || !selected %in% choices) {
    if (!required && "" %in% choices) {
      selected <- ""
    } else {
      selected <- choices[1L]
    }
  }

  selectInput(
    ns(mapping_input_id(mapping)),
    mapping_label(mapping),
    choices = choices,
    selected = selected
  )
}

plot_theme_preset_id <- function(theme) {
  paste0("theme_preset_", gsub("[^A-Za-z0-9]+", "_", theme))
}

plot_theme_label <- function(theme) {
  tools::toTitleCase(gsub("[-_]+", " ", theme))
}

plot_layer_label <- function(plot_type) {
  plot_type <- tolower(plot_type %||% "")
  labels <- c(
    area = "Area Layer",
    line = "Line Layer",
    bar = "Bar Layer",
    scatter = "Point Layer",
    histogram = "Distribution Layer",
    boxplot = "Distribution Layer",
    heatmap = "Heatmap Layer",
    correlation = "Correlation Layer",
    density = "Density Layer"
  )

  labels[[plot_type]] %||% "Data Layer"
}

plot_spec_option_names <- function(spec) {
  plot_type <- spec[["function"]] %||% spec[["id"]]
  tryCatch(
    plot_supported_option_names(plot_type),
    error = function(e) spec[["options"]] %||% character()
  )
}

plot_inspector_available_options <- function(spec) {
  setdiff(plot_spec_option_names(spec), c("AutoAggregate", "AggMethod", "Theme"))
}

plot_inspector_values <- function(option_names, values = list()) {
  values <- values %||% list()
  result <- lapply(option_names, function(option_name) {
    values[[option_name]] %||% option_registry[[option_name]]$default
  })
  names(result) <- option_names
  result
}

plot_inspector_value_equal <- function(a, b) {
  if (is.null(a) && is.null(b)) {
    return(TRUE)
  }
  if (is.null(a) || is.null(b)) {
    return(FALSE)
  }
  identical(a, b) || identical(as.character(a), as.character(b))
}

plot_inspector_dirty_fields <- function(original_label, draft_label, original_values, draft_values, fields) {
  dirty <- character()
  original_label <- trimws(as.character(original_label %||% ""))
  draft_label <- trimws(as.character(draft_label %||% ""))
  if (!identical(original_label, draft_label)) {
    dirty <- c(dirty, "label")
  }
  for (field in fields %||% character()) {
    if (!plot_inspector_value_equal(original_values[[field]], draft_values[[field]])) {
      dirty <- c(dirty, field)
    }
  }
  unique(dirty)
}

plot_inspector_validate_draft <- function(label, values, fields) {
  errors <- character()
  label <- trimws(as.character(label %||% ""))
  if (!nzchar(label)) {
    errors <- c(errors, "Object name is required.")
  }
  for (field in fields %||% character()) {
    opt <- option_registry[[field]]
    if (is.null(opt) || !identical(opt$type, "numeric")) {
      next
    }
    value <- values[[field]]
    if (!is.null(value) && !is.na(value) && !is.finite(value)) {
      errors <- c(errors, paste(opt$label %||% field, "must be a finite number."))
    }
  }
  errors
}

plot_inspector_objects <- function(spec, document, mode = "simple") {
  option_names <- plot_inspector_available_options(spec)
  document <- visual_document_normalize(document)
  objects <- lapply(names(document$objects), function(object_id) {
    contract <- visual_inspector_contract(
      document,
      object_id,
      mode = mode,
      available_options = option_names
    )

    list(
      label = contract$label,
      subtitle = contract$subtitle,
      options = contract$option_names,
      type = contract$object_type,
      renderer = contract$renderer,
      visible = contract$visible,
      locked = contract$locked
    )
  })
  names(objects) <- names(document$objects)

  Filter(function(object) {
    identical(object$type, "plot") ||
      object$type %in% c(
        "visual_document",
        "canvas",
        "boundary_line",
        "text",
        "group",
        "callout",
        "provenance"
      ) ||
      length(intersect(object$options, option_names)) > 0L
  }, objects)
}

plot_inspector_group <- function(title, subtitle, option_names, available_options, values = list(), ns = identity) {
  controls <- intersect(option_names, available_options)
  control_body <- if (!length(controls)) {
    tags$div(
      class = "aq-plot-inspector-empty-state",
      tags$p("No direct controls are available for this object yet."),
      tags$small("Use the command bar, theme rail, or select another plot object.")
    )
  } else {
    tags$div(
      class = "aq-plot-inspector-controls",
      lapply(controls, function(option_name) {
        opt <- option_registry[[option_name]]
        tags$div(
          class = paste(
            "aq-plot-inspector-control",
            paste0("aq-plot-inspector-control-", opt$type %||% "unknown")
          ),
          option_control(option_name, ns = ns, value = values[[option_name]])
        )
      })
    )
  }

  tagList(
    tags$div(
      class = "aq-plot-inspector-group-header",
      tags$h4(title),
      tags$p(subtitle)
    ),
    control_body
  )
}

plot_inspector_ui <- function(spec, document, selected_object = NULL, mode = "simple", draft = NULL, ns = identity) {
  option_names <- plot_inspector_available_options(spec)
  legacy_selection <- c(
    plot = "plot_001",
    title = "title_001",
    x_axis = "x_axis_001",
    y_axis = "y_axis_001",
    layer = "series_001",
    legend = "legend_001",
    interaction = "interaction_001"
  )
  selected_object <- if (!is.null(selected_object) && selected_object %in% names(legacy_selection)) {
    legacy_selection[[selected_object]]
  } else {
    selected_object
  }
  visual_document <- visual_document_normalize(document)
  objects <- plot_inspector_objects(spec, visual_document, mode = mode)
  object_ids <- names(objects)
  if (is.null(selected_object) || !selected_object %in% object_ids) {
    selected_object <- visual_document$selected_object_id %||% object_ids[[1L]]
  }
  if (!selected_object %in% object_ids) {
    selected_object <- object_ids[[1L]]
  }

  if (!length(option_names)) {
    return(tags$section(
      class = "aq-plot-inspector aq-plot-inspector-empty",
      tags$div(
        class = "aq-plot-inspector-header",
        tags$div(
          tags$p(class = "aq-plot-kicker", "Plot inspector"),
          tags$h3("No formatting controls for this plot type.")
        )
      )
    ))
  }

  selected <- visual_inspector_contract(
    visual_document,
    selected_object,
    mode = mode,
    available_options = option_names
  )
  selected_values <- selected$values %||% list()
  assigned_options <- visual_document_assigned_options(visual_document, mode = "expert")
  expert_options <- setdiff(option_names, assigned_options)
  if (identical(mode, "expert") && length(expert_options)) {
    selected$option_names <- unique(c(selected$option_names, expert_options))
    selected$subtitle <- paste(selected$subtitle, "Expert mode also exposes additional AutoPlots controls.")
  }
  selected_values <- plot_inspector_values(selected$option_names, selected_values)
  if (is.list(draft) && identical(draft$object_id, selected_object)) {
    selected$label <- draft$draft_label %||% selected$label
    selected_values <- plot_inspector_values(selected$option_names, draft$draft_values %||% selected_values)
  }

  tags$section(
    class = "aq-plot-inspector",
    tags$div(
      class = "aq-plot-inspector-header",
      tags$div(
        tags$p(class = "aq-plot-kicker", "Plot inspector"),
        tags$h3("Select an object, then edit its properties")
      ),
      tags$div(
        class = "aq-plot-inspector-mode",
        radioButtons(
          ns("plot_inspector_mode"),
          label = NULL,
          choices = c("Simple" = "simple", "Expert" = "expert"),
          selected = if (identical(mode, "expert")) "expert" else "simple",
          inline = TRUE
        )
      )
    ),
    tags$div(
      class = "aq-plot-inspector-workbench",
      tags$nav(
        class = "aq-plot-object-rail",
        radioButtons(
          ns("plot_selected_object"),
          label = NULL,
          choices = {
            object_choices <- visual_document_object_choices(visual_document)
            object_choices[object_choices %in% object_ids]
          },
          selected = selected_object
        )
      ),
      tags$section(
        class = "aq-plot-inspector-group aq-plot-selected-properties",
        tags$div(
          class = "aq-plot-inspector-status",
          tags$span(paste("Revision", visual_document$revision %||% 0L)),
          tags$span(if (isTRUE(selected$visible)) "Visible" else "Hidden"),
          tags$span(if (isTRUE(selected$locked)) "Locked" else "Editable"),
          tags$span(selected$renderer %||% "No renderer")
        ),
        tags$div(
          class = "aq-plot-inspector-commandbar",
          actionButton(ns("visual_make_explanatory"), "Propose Explanation", class = "btn-primary"),
          actionButton(ns("visual_toggle_visibility"), if (isTRUE(selected$visible)) "Hide" else "Show", class = "btn-secondary"),
          actionButton(ns("visual_toggle_lock"), if (isTRUE(selected$locked)) "Unlock" else "Lock", class = "btn-secondary"),
          actionButton(ns("visual_move_up"), "Move Up", class = "btn-secondary"),
          actionButton(ns("visual_move_down"), "Move Down", class = "btn-secondary"),
          actionButton(ns("visual_undo"), "Undo", class = "btn-secondary"),
          actionButton(ns("visual_redo"), "Redo", class = "btn-secondary"),
          actionButton(ns("visual_checkpoint"), "Checkpoint", class = "btn-secondary")
        ),
        tags$div(
          class = "aq-plot-inspector-rename aq-plot-inspector-draft-editor",
          textInput(ns("visual_object_label"), "Object name", value = selected$label),
          tags$small(
            class = "aq-plot-inspector-draft-note",
            "Draft only. Apply changes to update the visual document."
          )
        ),
        plot_inspector_group(
          title = selected$label,
          subtitle = selected$subtitle,
          option_names = selected$option_names,
          available_options = option_names,
          values = selected_values,
          ns = ns
        ),
        uiOutput(ns("plot_inspector_draft_footer")),
        uiOutput(ns("visual_authoring_proposal")),
        uiOutput(ns("visual_composition_review"))
      )
    )
  )
}

page_plot_builder_ui <- function(id) {
  ns <- NS(id)

  tabPanel(
    "Plots",
    ui_page(
      title = "Plot Studio",
      subtitle = "A creative studio for analytical storytelling with production AutoPlots underneath.",
      eyebrow = "Artifacts",
      tags$section(
        class = "aq-plot-studio-v3",
        tags$div(
          class = "aq-plot-instrument",
          tags$div(
            class = "aq-plot-instrument-copy",
            tags$p(class = "aq-plot-kicker", "Visual instrument"),
            tags$h2("Compose, preview, preserve."),
            tags$p("Plotting should feel fast enough to explore and structured enough to become evidence.")
          ),
          uiOutput(ns("plot_operation_status"))
        ),
        tags$div(
          class = "aq-plot-definition",
          tags$div(
            class = "aq-plot-definition-head",
            tags$div(
              tags$p(class = "aq-plot-kicker", "Plot definition"),
              tags$h3("Map the visual.")
            ),
            tags$div(
              class = "aq-plot-definition-actions",
              actionButton(ns("build_plot"), "Build / Refresh", class = "btn-primary"),
              actionButton(ns("add_plot"), "Preserve Plot", class = "btn-success"),
              actionButton(ns("clear_plot_preview"), "Clear Preview", class = "btn-secondary"),
              tags$details(
                class = "aq-plot-destructive-menu",
                tags$summary("More"),
                actionButton(ns("remove_last_plot"), "Remove Last Saved Plot", class = "btn-secondary")
              )
            )
          ),
          tags$div(
            class = "aq-plot-definition-grid",
            tags$div(
              class = "aq-plot-definition-panel aq-plot-map-panel",
              tags$div(
                class = "aq-plot-map-grid",
                tags$div(
                  class = "aq-plot-command-cell aq-plot-type-cell",
                  selectInput(ns("plot_type"), "Plot Type", choices = plot_type_choices())
                ),
                tags$div(
                  class = "aq-plot-command-cell aq-plot-mapping-cell",
                  tags$div(
                    class = "aq-plot-mapping-controls",
                    uiOutput(ns("mapping_inputs"))
                  )
                )
              )
            ),
            tags$div(
              class = "aq-plot-definition-panel aq-plot-treatment-panel",
              tags$div(
                class = "aq-plot-treatment-grid",
                tags$div(
                  class = "aq-plot-command-cell aq-plot-grain-cell",
                  uiOutput(ns("grain_input"))
                ),
                tags$div(
                  class = "aq-plot-command-cell aq-plot-aggregation-cell",
                  uiOutput(ns("aggregation_input"))
                )
              )
            )
          )
        ),
        uiOutput(ns("theme_presets")),
        tags$main(
          class = "aq-plot-stage-v3",
          tags$div(
            class = "aq-plot-stage-header",
            tags$div(
              tags$p(class = "aq-plot-kicker", "Live preview"),
              tags$h3("Current Plot")
            ),
            tags$div(class = "aq-plot-stage-message", textOutput(ns("plot_list_message")))
          ),
          tags$div(
            class = "aq-plot-stage-body",
            uiOutput(ns("preview_plot"))
          )
        ),
        tags$section(
          class = "aq-plot-artifact-tray",
          ui_card(
            title = "Saved Plot Tray",
            subtitle = "Preserved plots become report-ready artifacts.",
            tags$div(
              class = "aq-plot-tray-grid",
              tags$div(
                class = "aq-plot-tray-controls",
                selectInput(ns("selected_saved_plot"), "Saved Plot", choices = character()),
                ui_action_row(
                  actionButton(ns("load_saved_plot"), "Edit Selected", class = "btn-secondary"),
                  actionButton(ns("update_saved_plot"), "Update", class = "btn-primary"),
                  actionButton(ns("duplicate_saved_plot"), "Duplicate", class = "btn-secondary")
                ),
                selectInput(ns("section_for_plot"), "Report Section", choices = character()),
                textInput(ns("new_section_name"), "New Section", value = ""),
                ui_action_row(
                  actionButton(ns("assign_plot_section"), "Assign to Section", class = "btn-primary"),
                  actionButton(ns("move_plot_up"), "Move Up", class = "btn-secondary"),
                  actionButton(ns("move_plot_down"), "Move Down", class = "btn-secondary")
                )
              ),
              tags$div(
                class = "aq-plot-tray-list",
                uiOutput(ns("saved_plot_list"))
              )
            )
          )
        ),
        tags$section(
          class = "aq-plot-depth",
          uiOutput(ns("plot_inspector")),
          ui_code_panel(
            "Current Plot Code",
            verbatimTextOutput(ns("generated_code")),
            collapsed = TRUE
          ),
          ui_code_panel(
            "All Saved Plots Code",
            verbatimTextOutput(ns("saved_plots_code")),
            collapsed = TRUE
          )
        )
      )
    )
  )
}

page_plot_builder_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    ctx$get_current_plot_type <- function() {
      input$plot_type
    }

    current_visual_document <- reactiveVal(NULL)
    current_visual_authoring_proposal <- reactiveVal(NULL)
    current_visual_composition_review <- reactiveVal(NULL)
    current_visual_composition_strategy <- reactiveVal(NULL)
    current_visual_composition_branch <- reactiveVal(NULL)
    plot_action_state <- reactiveValues(
      status = "idle",
      active = FALSE,
      action_id = NULL,
      action_type = NULL,
      input_id = NULL,
      started_at = NULL,
      finished_at = NULL,
      elapsed_ms = NA_real_,
      message = "Ready.",
      last_completed = "None",
      trace = list()
    )
    inspector_state <- reactiveValues(
      loading = FALSE,
      applying = FALSE,
      object_id = NULL,
      revision = NULL,
      original_label = NULL,
      draft_label = NULL,
      fields = character(),
      original_values = list(),
      draft_values = list(),
      dirty_fields = character(),
      validation_errors = character(),
      conflict = FALSE,
      message = "Select an object to edit."
    )

    snapshot_current_plot_config <- function() {
      snapshot_plot_config(
        plot_type = input$plot_type,
        input = input,
        mapping_values = ctx$mapping_state$values
      )
    }

    set_current_visual_document <- function(document) {
      document <- visual_document_normalize(document)
      current_visual_document(document)
      document
    }

    ensure_current_visual_document <- function(config = NULL) {
      plot_type <- if (!is.null(config)) config$plot_type else selected_value(input$plot_type)
      plot_type <- plot_type %||% "area"
      document <- current_visual_document()
      document_plot_type <- if (is.null(document)) NULL else document$metadata$plot_type %||% NULL

      if (is.null(document) || !identical(document_plot_type, plot_type)) {
        document <- if (!is.null(config) && !is.null(config$visual_document)) {
          visual_document_normalize(config$visual_document)
        } else if (!is.null(config)) {
          visual_document_from_plot_config(config)
        } else {
          visual_document_from_plot_spec(plot_type %||% "area")
        }
        set_current_visual_document(document)
      }

      document
    }

    selected_visual_object_id <- function(document = NULL) {
      document <- document %||% ensure_current_visual_document()
      choices <- names(document$objects)
      selected <- selected_value(input$plot_selected_object) %||%
        document$selected_object_id %||%
        choices[[1L]]

      if (!selected %in% choices) {
        selected <- document$selected_object_id %||% choices[[1L]]
      }

      selected
    }

    plot_action_snapshot <- function(document = NULL) {
      document <- tryCatch(document %||% current_visual_document(), error = function(e) NULL)
      list(
        plot_type = selected_value(input$plot_type) %||% NA_character_,
        plot_ready = !is.null(ctx$plot_result()) && is.null(ctx$plot_error()),
        selected_object_id = if (is.null(document)) NA_character_ else document$selected_object_id %||% NA_character_,
        object_count = if (is.null(document)) 0L else length(document$objects),
        revision = if (is.null(document)) 0L else length(document$history %||% list())
      )
    }

    record_plot_action <- function(entry) {
      trace <- c(list(entry), plot_action_state$trace %||% list())
      plot_action_state$trace <- head(trace, 25L)
      invisible(entry)
    }

    run_plot_studio_action <- function(action_id, label, fn, type = "ui_action", input_id = action_id) {
      if (isTRUE(plot_action_state$active)) {
        message <- paste("Still running:", plot_action_state$message %||% "another Plot Studio operation")
        ctx$plot_list_message(message)
        record_plot_action(list(
          action_id = action_id,
          label = label,
          status = "ignored",
          reason = "busy",
          timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
        ))
        return(invisible(FALSE))
      }

      start <- Sys.time()
      plot_action_state$active <- TRUE
      plot_action_state$status <- "running"
      plot_action_state$action_id <- action_id
      plot_action_state$action_type <- type
      plot_action_state$input_id <- input_id
      plot_action_state$started_at <- start
      plot_action_state$finished_at <- NULL
      plot_action_state$elapsed_ms <- NA_real_
      plot_action_state$message <- paste(label, "is running...")

      result <- tryCatch(
        {
          value <- fn()
          if (isFALSE(value)) {
            stop(paste(label, "did not complete."), call. = FALSE)
          }
          list(ok = TRUE, value = value)
        },
        error = function(e) {
          list(ok = FALSE, error = conditionMessage(e))
        }
      )

      end <- Sys.time()
      elapsed <- as.numeric(difftime(end, start, units = "secs")) * 1000
      plot_action_state$active <- FALSE
      plot_action_state$finished_at <- end
      plot_action_state$elapsed_ms <- elapsed

      if (isTRUE(result$ok)) {
        plot_action_state$status <- "completed"
        plot_action_state$message <- paste(label, "completed.")
        plot_action_state$last_completed <- paste(label, format(end, "%H:%M:%S"))
        record_plot_action(list(
          action_id = action_id,
          label = label,
          status = "completed",
          elapsed_ms = elapsed,
          snapshot = plot_action_snapshot(),
          timestamp = format(end, "%Y-%m-%d %H:%M:%S")
        ))
        return(invisible(TRUE))
      }

      plot_action_state$status <- "failed"
      plot_action_state$message <- paste(label, "failed:", result$error %||% "unknown error")
      ctx$plot_list_message(plot_action_state$message)
      record_plot_action(list(
        action_id = action_id,
        label = label,
        status = "failed",
        error = result$error,
        elapsed_ms = elapsed,
        snapshot = plot_action_snapshot(),
        timestamp = format(end, "%Y-%m-%d %H:%M:%S")
      ))
      invisible(FALSE)
    }

    mutate_current_visual_document <- function(mutation) {
      document <- ensure_current_visual_document()
      set_current_visual_document(visual_document_apply_mutation(document, mutation))
      TRUE
    }

    run_visual_command <- function(command_id, args = list()) {
      document <- ensure_current_visual_document()
      args$object_id <- args$object_id %||% selected_visual_object_id(document)
      set_current_visual_document(visual_execute_command(document, command_id, args))
      ctx$plot_list_message(paste("Visual document:", gsub("_", " ", command_id)))
      TRUE
    }

    visual_document_revision <- function(document) {
      as.integer(document$revision %||% 0L)
    }

    inspector_contract_for <- function(document = NULL, object_id = NULL, mode = NULL) {
      document <- visual_document_normalize(document %||% ensure_current_visual_document())
      object_id <- object_id %||% selected_visual_object_id(document)
      mode <- mode %||% selected_value(input$plot_inspector_mode) %||% "simple"
      spec <- plot_spec(document$metadata$plot_type %||% selected_value(input$plot_type) %||% "area")
      available_options <- plot_inspector_available_options(spec)
      contract <- visual_inspector_contract(
        document,
        object_id,
        mode = mode,
        available_options = available_options
      )
      assigned_options <- visual_document_assigned_options(document, mode = "expert")
      expert_options <- setdiff(available_options, assigned_options)
      if (identical(mode, "expert") && length(expert_options)) {
        contract$option_names <- unique(c(contract$option_names, expert_options))
      }
      contract$option_names <- intersect(contract$option_names %||% character(), available_options)
      contract
    }

    inspector_load_draft <- function(document = NULL, object_id = NULL, reason = "load") {
      document <- visual_document_normalize(document %||% ensure_current_visual_document())
      object_id <- object_id %||% selected_visual_object_id(document)
      contract <- inspector_contract_for(document, object_id)
      fields <- contract$option_names %||% character()
      values <- plot_inspector_values(fields, contract$values %||% list())

      inspector_state$loading <- TRUE
      on.exit({
        inspector_state$loading <- FALSE
      }, add = TRUE)
      inspector_state$object_id <- object_id
      inspector_state$revision <- visual_document_revision(document)
      inspector_state$original_label <- contract$label
      inspector_state$draft_label <- contract$label
      inspector_state$fields <- fields
      inspector_state$original_values <- values
      inspector_state$draft_values <- values
      inspector_state$dirty_fields <- character()
      inspector_state$validation_errors <- character()
      inspector_state$conflict <- FALSE
      inspector_state$message <- if (identical(reason, "reset")) {
        "Draft reset to the current visual document."
      } else {
        "Draft matches the current visual document."
      }
      invisible(TRUE)
    }

    inspector_collect_from_inputs <- function(force = FALSE) {
      if (!isTRUE(force) && (isTRUE(inspector_state$loading) || isTRUE(inspector_state$applying))) {
        return(FALSE)
      }
      fields <- inspector_state$fields %||% character()
      if (is.null(inspector_state$object_id)) {
        return(FALSE)
      }

      draft_values <- inspector_state$draft_values %||% list()
      for (field in fields) {
        opt <- option_registry[[field]]
        if (is.null(opt)) {
          next
        }
        value <- option_value(input, field)
        if (!is.null(value)) {
          draft_values[[field]] <- value
        }
      }

      draft_label <- selected_value(input$visual_object_label) %||% inspector_state$draft_label
      inspector_state$draft_label <- draft_label
      inspector_state$draft_values <- plot_inspector_values(fields, draft_values)
      inspector_state$dirty_fields <- plot_inspector_dirty_fields(
        inspector_state$original_label,
        inspector_state$draft_label,
        inspector_state$original_values,
        inspector_state$draft_values,
        fields
      )
      inspector_state$validation_errors <- plot_inspector_validate_draft(
        inspector_state$draft_label,
        inspector_state$draft_values,
        fields
      )
      inspector_state$message <- if (length(inspector_state$validation_errors)) {
        "Draft has validation issues."
      } else if (length(inspector_state$dirty_fields)) {
        "Draft changes are ready to apply."
      } else {
        "Draft matches the current visual document."
      }
      TRUE
    }

    composition_evidence_context <- function(document) {
      document <- visual_document_normalize(document)
      plot_object <- document$objects$plot_001 %||% list()
      title <- plot_object$properties[["title.text"]] %||%
        plot_object$label %||%
        "Current visual finding"
      list(
        evidence_ids = "current_plot_evidence",
        source_artifacts = plot_object$id %||% "plot_001",
        title = title,
        statement = paste("The current", tolower(plot_object$label %||% "visual"), "is available as visual evidence."),
        explanation = "Review composition before promoting this visual into an explanatory artifact.",
        recommendation = "Use the strategy that best fits the audience and evidence burden.",
        limitation = "Composition review changes communication only; it does not change the underlying analysis.",
        source = "Plot Studio visual document"
      )
    }

    ctx$current_plot_options <- function() {
      if (is.null(input$plot_type)) {
        return(list())
      }

      config <- snapshot_current_plot_config()
      config$options
    }

    remember_mapping <- function(mapping) {
      force(mapping)
      observeEvent(input[[mapping_input_id(mapping)]], {
        ctx$mapping_state$values[[mapping]] <- input[[mapping_input_id(mapping)]]
      }, ignoreInit = TRUE)
    }

    lapply(c("XVar", "YVar", "ZVar", "GroupVar", "CorrVars"), remember_mapping)

    update_mapping_control <- function(mapping, value) {
      if (identical(mapping, "CorrVars")) {
        updateSelectInput(
          session = session,
          inputId = mapping_input_id(mapping),
          selected = if (is.null(value)) character() else value
        )
        return()
      }

      updateSelectInput(
        session = session,
        inputId = mapping_input_id(mapping),
        selected = if (is.null(value)) "" else value
      )
    }

    update_option_control <- function(option_name, value) {
      opt <- option_registry[[option_name]]
      if (is.null(opt)) {
        return()
      }

      if (is.null(value)) {
        value <- opt$default
      }

      switch(
        opt$type,
        select = updateSelectInput(session, opt$input_id, selected = value),
        text = updateTextInput(session, opt$input_id, value = if (is.null(value)) "" else value),
        checkbox = updateCheckboxInput(session, opt$input_id, value = isTRUE(value)),
        grain = updateRadioButtons(
          session,
          opt$input_id,
          selected = if (identical(value, "raw") || identical(value, FALSE)) "raw" else "preaggregated"
        ),
        numeric = updateNumericInput(session, opt$input_id, value = value),
        NULL
      )
    }

    ctx$load_config_into_builder <- function(config) {
      for (mapping in c("XVar", "YVar", "ZVar", "GroupVar", "CorrVars")) {
        ctx$mapping_state$values[[mapping]] <- config$mappings[[mapping]]
      }

      set_current_visual_document(
        if (!is.null(config$visual_document)) {
          visual_document_normalize(config$visual_document)
        } else {
          visual_document_from_plot_config(config)
        }
      )

      updateSelectInput(session, "plot_type", selected = config$plot_type)

      session$onFlushed(function() {
        for (mapping in active_mappings(config$plot_type)) {
          update_mapping_control(mapping, config$mappings[[mapping]])
        }

        for (option_name in plot_spec(config$plot_type)$options) {
          update_option_control(option_name, config$options[[option_name]])
        }
      }, once = TRUE)
    }

    update_saved_plot_references <- function(plot_name, plot) {
      sections <- ctx$saved_sections$sections
      for (section_name in names(sections)) {
        if (plot_name %in% names(sections[[section_name]])) {
          sections[[section_name]][[plot_name]] <- plot
        }
      }

      ctx$saved_sections$sections <- sections
    }

    observe({
      plot_names <- ctx$ordered_plot_names()
      selected <- isolate(input$selected_saved_plot)
      if (!length(plot_names)) {
        selected <- character()
      } else if (is.null(selected) || !selected %in% plot_names) {
        selected <- plot_names[1L]
      }

      updateSelectInput(
        session = session,
        inputId = "selected_saved_plot",
        choices = plot_names,
        selected = selected
      )

      section_names <- unique(vapply(ctx$saved_plots$metadata, function(item) {
        section_name <- item$section_name
        if (is.null(section_name) || !nzchar(section_name)) {
          return("Analysis")
        }

        section_name
      }, character(1)))

      if (!length(section_names)) {
        section_names <- "Analysis"
      }

      selected_section <- isolate(input$section_for_plot)
      if (is.null(selected_section) || !selected_section %in% section_names) {
        selected_section <- section_names[1L]
      }

      updateSelectInput(
        session = session,
        inputId = "section_for_plot",
        choices = section_names,
        selected = selected_section
      )
    })

    output$mapping_inputs <- renderUI({
      req(input$plot_type)
      data <- tryCatch(ctx$uploaded_data(), error = function(e) NULL)
      spec <- plot_spec(input$plot_type)

      tagList(
        lapply(spec$mappings, function(mapping) {
          mapping_control(
            mapping = mapping,
            data = data,
            required = TRUE,
            selected = ctx$mapping_state$values[[mapping]],
            ns = session$ns
          )
        }),
        lapply(spec$optional_mappings, function(mapping) {
          mapping_control(
            mapping = mapping,
            data = data,
            required = FALSE,
            selected = ctx$mapping_state$values[[mapping]],
            ns = session$ns
          )
        })
      )
    })

    output$grain_input <- renderUI({
      req(input$plot_type)
      spec <- plot_spec(input$plot_type)
      if (!"AutoAggregate" %in% plot_spec_option_names(spec)) {
        return(tags$div(
          class = "aq-plot-grain-control aq-plot-grain-control-disabled",
          tags$div(
            class = "aq-plot-grain-copy",
            tags$span("Data grain"),
            tags$small("This plot type does not summarize repeated rows.")
          )
        ))
      }

      option_control("AutoAggregate", ns = session$ns)
    })

    output$aggregation_input <- renderUI({
      req(input$plot_type)
      spec <- plot_spec(input$plot_type)
      if (!"AggMethod" %in% plot_spec_option_names(spec)) {
        return(tags$div(
          class = "aq-plot-aggregation-control aq-plot-aggregation-control-disabled",
          tags$div(
            class = "aq-plot-aggregation-copy",
            tags$span("Summarize by"),
            tags$small("No row summarization method is needed for this plot type.")
          )
        ))
      }

      opt <- option_registry$AggMethod
      grain <- selected_value(input$auto_aggregate) %||% option_registry$AutoAggregate$default
      hint <- if (identical(grain, "preaggregated")) {
        "Not used when rows are already summarized."
      } else {
        "Used when raw rows are summarized."
      }

      tags$div(
        class = paste(
          "aq-plot-aggregation-control",
          if (identical(grain, "preaggregated")) "is-muted" else ""
        ),
        tags$div(
          class = "aq-plot-aggregation-copy",
          tags$span("Summarize by"),
          tags$small(hint)
        ),
        selectInput(
          session$ns(opt$input_id),
          label = NULL,
          choices = opt$choices,
          selected = selected_value(input[[opt$input_id]]) %||% opt$default
        )
      )
    })

    output$plot_inspector <- renderUI({
      req(input$plot_type)
      spec <- plot_spec(input$plot_type)
      config <- tryCatch(snapshot_current_plot_config(), error = function(e) NULL)
      document <- ensure_current_visual_document(config)
      plot_inspector_ui(
        spec,
        document = document,
        selected_object = selected_visual_object_id(document),
        mode = selected_value(input$plot_inspector_mode) %||% "simple",
        draft = reactiveValuesToList(inspector_state),
        ns = session$ns
      )
    })

    output$plot_inspector_draft_footer <- renderUI({
      dirty <- inspector_state$dirty_fields %||% character()
      errors <- inspector_state$validation_errors %||% character()
      conflict <- isTRUE(inspector_state$conflict)
      can_apply <- length(dirty) > 0L && !length(errors) && !conflict && !is.null(inspector_state$object_id)
      apply_button <- actionButton(session$ns("visual_inspector_apply"), "Apply Changes", class = "btn-primary")
      reset_button <- actionButton(session$ns("visual_inspector_reset"), "Reset Draft", class = "btn-secondary")
      if (!can_apply) {
        apply_button$attribs$disabled <- "disabled"
      }
      if (!length(dirty) && !conflict) {
        reset_button$attribs$disabled <- "disabled"
      }

      tags$div(
        class = paste(
          "aq-plot-inspector-draft-footer",
          if (length(dirty)) "is-dirty" else "is-clean",
          if (conflict) "is-conflicted" else ""
        ),
        tags$div(
          class = "aq-plot-inspector-draft-status",
          tags$strong(if (conflict) "Draft is stale" else inspector_state$message %||% "Draft ready."),
          tags$small(if (length(dirty)) {
            paste("Pending:", paste(dirty, collapse = ", "))
          } else {
            "No unapplied inspector changes."
          }),
          if (length(errors)) {
            tags$ul(class = "aq-plot-inspector-validation", lapply(errors, tags$li))
          }
        ),
        tags$div(
          class = "aq-plot-inspector-draft-actions",
          apply_button,
          reset_button
        )
      )
    })

    output$visual_authoring_proposal <- renderUI({
      document <- tryCatch(ensure_current_visual_document(), error = function(e) NULL)
      proposal <- if (!is.null(document)) {
        visual_authoring_get_proposal(document, current_visual_authoring_proposal())
      } else {
        NULL
      }
      if (is.null(proposal) || !proposal$status %in% c("proposed", "partially_accepted")) {
        return(tags$div(
          class = "aq-plot-inspector-empty-state",
          tags$strong("No pending semantic authoring proposal."),
          tags$p("Use Propose Explanation to draft governed objects before changing the document.")
        ))
      }
      summary <- visual_authoring_proposal_summary(proposal)
      active_summary <- summary[summary$status %in% c("proposed", "accepted"), , drop = FALSE]
      if (!nrow(active_summary)) {
        active_summary <- summary
      }
      choices <- stats::setNames(
        active_summary$object_id,
        paste(active_summary$label, active_summary$object_type, sep = " - ")
      )
      selected <- active_summary$object_id[active_summary$status == "proposed"]
      tags$div(
        class = "aq-plot-authoring-proposal",
        tags$div(
          class = "aq-plot-inspector-group-title",
          tags$h4("Pending proposal"),
          tags$p(proposal$rationale %||% "")
        ),
        tags$div(
          class = "aq-plot-inspector-status",
          tags$span(paste("Confidence", proposal$confidence %||% "unknown")),
          tags$span(proposal$expected_user_value %||% "Expected value not supplied")
        ),
        checkboxGroupInput(
          session$ns("visual_authoring_object_selection"),
          "Objects to add",
          choices = choices,
          selected = selected
        ),
        tags$div(
          class = "aq-plot-inspector-commandbar",
          actionButton(session$ns("visual_authoring_accept_selected"), "Accept Selected", class = "btn-primary"),
          actionButton(session$ns("visual_authoring_accept_all"), "Accept All", class = "btn-secondary"),
          actionButton(session$ns("visual_authoring_reject"), "Reject", class = "btn-secondary")
        )
      )
    })

    output$visual_composition_review <- renderUI({
      document <- tryCatch(ensure_current_visual_document(), error = function(e) NULL)
      if (is.null(document)) {
        return(NULL)
      }

      review <- visual_composition_get_review(document, current_visual_composition_review())
      strategies <- document$composition$strategies %||% list()
      strategy <- visual_composition_get_strategy(document, current_visual_composition_strategy())
      branch_id <- current_visual_composition_branch() %||% document$composition$active_branch_id
      branch <- if (!is.null(branch_id)) document$composition$branches[[branch_id]] else NULL

      if (is.null(review)) {
        return(tags$div(
          class = "aq-plot-authoring-proposal",
          tags$div(
            class = "aq-plot-inspector-group-title",
            tags$h4("Composition Review"),
            tags$p("Generate a bounded review before turning this visual document into a governed composition.")
          ),
          tags$div(
            class = "aq-plot-inspector-commandbar",
            actionButton(session$ns("visual_composition_create_review"), "Review Composition", class = "btn-primary"),
            actionButton(session$ns("visual_composition_generate_strategies"), "Generate Strategies", class = "btn-secondary")
          )
        ))
      }

      dimension_chips <- lapply(review$dimensions %||% list(), function(dimension) {
        tags$span(
          title = dimension$finding %||% "",
          paste(dimension$label, dimension$status, sep = ": ")
        )
      })

      strategy_choices <- if (length(strategies)) {
        stats::setNames(
          vapply(strategies, function(x) x$strategy_id, character(1)),
          vapply(strategies, function(x) {
            paste0(x$label, " (", x$status %||% "candidate", ")")
          }, character(1))
        )
      } else {
        character()
      }

      mutation_choices <- if (!is.null(strategy)) {
        stats::setNames(
          names(strategy$mutation_plan %||% list()),
          vapply(strategy$mutation_plan %||% list(), function(mutation) {
            paste(mutation$label %||% mutation$semantic_operation, mutation$claim_classification %||% "inferred", sep = " - ")
          }, character(1))
        )
      } else {
        character()
      }

      comparison <- visual_composition_compare_strategies(document)
      selected_comparison <- if (!is.null(strategy) && nrow(comparison)) {
        comparison[comparison$strategy_id == strategy$strategy_id, , drop = FALSE]
      } else {
        data.frame()
      }

      tags$div(
        class = "aq-plot-authoring-proposal",
        tags$div(
          class = "aq-plot-inspector-group-title",
          tags$h4("Composition Review"),
          tags$p("Review communication risks, compare strategies, preview a branch, then accept only the mutations you want.")
        ),
        tags$div(class = "aq-plot-inspector-status", dimension_chips),
        if (length(review$contradictions %||% character())) {
          tags$div(
            class = "aq-plot-inspector-empty-state",
            tags$strong("Integrity attention"),
            tags$p(paste(review$contradictions, collapse = " "))
          )
        },
        tags$div(
          class = "aq-plot-inspector-commandbar",
          actionButton(session$ns("visual_composition_create_review"), "Refresh Review", class = "btn-secondary"),
          actionButton(session$ns("visual_composition_generate_strategies"), "Generate Strategies", class = "btn-secondary")
        ),
        if (length(strategy_choices)) {
          selectInput(
            session$ns("visual_composition_strategy"),
            "Strategy",
            choices = strategy_choices,
            selected = strategy$strategy_id %||% names(strategy_choices)[[1L]]
          )
        },
        if (nrow(selected_comparison)) {
          tags$div(
            class = "aq-plot-inspector-empty-state",
            tags$strong("Selected strategy review"),
            tags$ul(lapply(seq_len(nrow(selected_comparison)), function(i) {
              tags$li(paste(
                selected_comparison$dimension[[i]],
                selected_comparison$status[[i]],
                selected_comparison$finding[[i]],
                sep = " - "
              ))
            }))
          )
        },
        if (length(mutation_choices)) {
          checkboxGroupInput(
            session$ns("visual_composition_mutation_selection"),
            "Mutations",
            choices = mutation_choices,
            selected = names(mutation_choices)
          )
        },
        if (!is.null(branch)) {
          tags$div(
            class = "aq-plot-inspector-status",
            tags$span(paste("Preview branch", branch$branch_id)),
            tags$span(paste(length(branch$mutation_ids %||% character()), "mutation(s)")),
            tags$span("Canonical document unchanged")
          )
        },
        tags$div(
          class = "aq-plot-inspector-commandbar",
          actionButton(session$ns("visual_composition_preview_branch"), "Preview Branch", class = "btn-secondary"),
          actionButton(session$ns("visual_composition_accept_selected"), "Accept Selected", class = "btn-primary"),
          actionButton(session$ns("visual_composition_accept_all"), "Accept All", class = "btn-secondary"),
          actionButton(session$ns("visual_composition_reject_strategy"), "Reject Strategy", class = "btn-secondary")
        )
      )
    })

    output$theme_presets <- renderUI({
      req(input$plot_type)
      spec <- plot_spec(input$plot_type)
      if (!"Theme" %in% plot_spec_option_names(spec)) {
        return(tags$div(
          class = "aq-plot-theme-strip aq-plot-theme-strip-disabled",
          tags$span("AutoPlots themes are not available for this plot type.")
        ))
      }

      document <- tryCatch(ensure_current_visual_document(), error = function(e) NULL)
      selected_theme <- document$objects$plot_001$properties$Theme %||%
        selected_value(input$theme) %||%
        option_registry$Theme$default
      tags$section(
        class = "aq-plot-theme-strip aq-plot-theme-browser",
        tags$div(
          class = "aq-plot-hidden-state",
          option_control("Theme", ns = session$ns)
        ),
        tags$details(
          class = "aq-plot-theme-details",
          tags$summary(
            tags$div(
              class = "aq-plot-theme-copy",
              tags$span("Appearance"),
              tags$p(paste("Theme:", plot_theme_label(selected_theme)))
            ),
            tags$span(class = "aq-plot-theme-summary-action", "Browse themes")
          ),
          tags$div(
            class = "aq-plot-theme-rail",
            lapply(theme_choices, function(theme) {
              actionButton(
                session$ns(plot_theme_preset_id(theme)),
                plot_theme_label(theme),
                class = paste(
                  "aq-plot-theme-chip",
                  paste0("aq-plot-theme-chip-", gsub("[^A-Za-z0-9]+", "-", theme)),
                  if (identical(theme, selected_theme)) "is-active" else ""
                )
              )
            })
          )
        )
      )
    })

    output$plot_operation_status <- renderUI({
      status <- plot_action_state$status %||% "idle"
      elapsed <- plot_action_state$elapsed_ms
      elapsed_label <- if (is.na(elapsed)) {
        NULL
      } else {
        paste0(round(elapsed / 1000, 1), "s")
      }
      tags$div(
        class = paste("aq-plot-operation-status", paste0("is-", status)),
        `aria-live` = "polite",
        tags$span(class = "aq-plot-operation-dot"),
        tags$div(
          tags$span(class = "aq-plot-operation-label", "Operation status"),
          tags$strong(plot_action_state$message %||% "Ready.")
        ),
        tags$div(
          class = "aq-plot-operation-meta",
          if (!is.null(elapsed_label)) tags$span(elapsed_label),
          tags$span(paste("Last:", plot_action_state$last_completed %||% "None"))
        )
      )
    })

    rebuild_current_plot <- function(option_overrides = list(), status_message = NULL) {
      ctx$plot_result(NULL)
      ctx$plot_error(NULL)
      ctx$plot_config(NULL)

      tryCatch({
        config <- snapshot_current_plot_config()
        document <- ensure_current_visual_document(config)

        for (option_name in names(option_overrides)) {
          config$options[[option_name]] <- option_overrides[[option_name]]
          target_object <- if (identical(option_name, "Theme")) "plot_001" else selected_visual_object_id(document)
          if (
            target_object %in% names(document$objects) &&
              option_name %in% visual_object_property_names(document, target_object, mode = "expert")
          ) {
            document <- visual_document_apply_mutation(
              document,
              list(
                type = "set_property",
                object_id = target_object,
                property = option_name,
                value = option_overrides[[option_name]]
              )
            )
          }
        }
        set_current_visual_document(document)

        config <- visual_document_to_plot_config(document, config)

        data <- ctx$uploaded_data()
        ready <- validate_plot_config_ready(config, data)
        if (!isTRUE(ready)) {
          stop(ready, call. = FALSE)
        }

        ctx$plot_result(build_autoplots_call_from_config(config, data))
        ctx$plot_config(config)
        if (!is.null(status_message)) {
          ctx$plot_list_message(status_message)
        }
        TRUE
      }, error = function(e) {
        message <- conditionMessage(e)
        if (!nzchar(message)) {
          message <- "AutoPlots returned an error without a message."
        }
        ctx$plot_error(message)
        FALSE
      })
    }

    observeEvent(input$build_plot, {
      run_plot_studio_action(
        "build_plot",
        "Build plot",
        function() rebuild_current_plot(),
        type = "plot_render",
        input_id = "build_plot"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$clear_plot_preview, {
      run_plot_studio_action(
        "clear_plot_preview",
        "Clear preview",
        function() {
          ctx$plot_result(NULL)
          ctx$plot_error(NULL)
          ctx$plot_config(NULL)
          ctx$plot_list_message("Cleared plot preview.")
          TRUE
        },
        type = "plot_state",
        input_id = "clear_plot_preview"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$plot_type, {
      config <- tryCatch(snapshot_current_plot_config(), error = function(e) NULL)
      if (!is.null(config)) {
        set_current_visual_document(visual_document_from_plot_config(config))
        current_visual_authoring_proposal(NULL)
        current_visual_composition_review(NULL)
        current_visual_composition_strategy(NULL)
        current_visual_composition_branch(NULL)
      }
    }, ignoreInit = TRUE)

    observe({
      document <- current_visual_document()
      if (is.null(document)) {
        return()
      }
      document <- visual_document_normalize(document)
      object_id <- selected_visual_object_id(document)
      revision <- visual_document_revision(document)
      dirty <- length(inspector_state$dirty_fields %||% character()) > 0L

      if (is.null(inspector_state$object_id) || !identical(inspector_state$object_id, object_id)) {
        inspector_load_draft(document, object_id, "selection")
      } else if (!identical(as.integer(inspector_state$revision %||% -1L), revision)) {
        if (dirty) {
          inspector_state$conflict <- TRUE
          inspector_state$message <- "Document changed before these draft edits were applied. Reset the draft before applying."
        } else {
          inspector_load_draft(document, object_id, "load")
        }
      }
    })

    observeEvent(input$plot_selected_object, {
      object_id <- selected_value(input$plot_selected_object)
      if (is.null(object_id)) {
        return()
      }
      document <- ensure_current_visual_document()
      if (object_id %in% names(document$objects)) {
        updated <- visual_document_select(document, object_id, origin = "object_tree")
        set_current_visual_document(updated)
        inspector_load_draft(updated, object_id, "selection")
      }
    }, ignoreInit = TRUE)

    observeEvent(input$visual_inspector_apply, {
      run_plot_studio_action(
        "visual_inspector_apply",
        "Apply inspector changes",
        function() {
          inspector_collect_from_inputs(force = TRUE)
          if (isTRUE(inspector_state$conflict)) {
            stop("Inspector draft is stale. Reset it before applying.", call. = FALSE)
          }

          errors <- inspector_state$validation_errors %||% character()
          if (length(errors)) {
            ctx$plot_list_message(paste(errors, collapse = " "))
            return(TRUE)
          }

          dirty <- inspector_state$dirty_fields %||% character()
          if (!length(dirty)) {
            ctx$plot_list_message("No inspector draft changes to apply.")
            return(TRUE)
          }

          document <- ensure_current_visual_document()
          if (!identical(visual_document_revision(document), as.integer(inspector_state$revision %||% -1L))) {
            stop("The visual document changed before the draft was applied. Reset the draft and try again.", call. = FALSE)
          }

          object_id <- inspector_state$object_id %||% selected_visual_object_id(document)
          draft_fields <- intersect(dirty, inspector_state$fields %||% character())
          values <- (inspector_state$draft_values %||% list())[draft_fields]
          mutation <- list(
            type = "update_object",
            object_id = object_id,
            values = values
          )
          if ("label" %in% dirty) {
            mutation$label <- inspector_state$draft_label
          }

          inspector_state$applying <- TRUE
          on.exit({
            inspector_state$applying <- FALSE
          }, add = TRUE)

          updated <- visual_document_apply_mutation(document, mutation)
          updated <- visual_document_select(updated, object_id, origin = "inspector_apply")
          set_current_visual_document(updated)
          inspector_load_draft(updated, object_id, "apply")
          ctx$plot_list_message("Inspector changes applied.")
          TRUE
        },
        type = "visual_document",
        input_id = "visual_inspector_apply"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_inspector_reset, {
      run_plot_studio_action(
        "visual_inspector_reset",
        "Reset inspector draft",
        function() {
          document <- ensure_current_visual_document()
          object_id <- inspector_state$object_id %||% selected_visual_object_id(document)
          inspector_load_draft(document, object_id, "reset")
          ctx$plot_list_message("Inspector draft reset.")
          TRUE
        },
        type = "inspector_draft",
        input_id = "visual_inspector_reset"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_toggle_visibility, {
      run_plot_studio_action("visual_toggle_visibility", "Toggle visibility", function() run_visual_command("toggle_visibility"), type = "visual_document", input_id = "visual_toggle_visibility")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_toggle_lock, {
      run_plot_studio_action("visual_toggle_lock", "Toggle lock", function() run_visual_command("toggle_lock"), type = "visual_document", input_id = "visual_toggle_lock")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_move_up, {
      run_plot_studio_action("visual_move_up", "Move visual object up", function() run_visual_command("move_up"), type = "visual_document", input_id = "visual_move_up")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_move_down, {
      run_plot_studio_action("visual_move_down", "Move visual object down", function() run_visual_command("move_down"), type = "visual_document", input_id = "visual_move_down")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_undo, {
      run_plot_studio_action("visual_undo", "Undo visual change", function() run_visual_command("undo"), type = "visual_document", input_id = "visual_undo")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_redo, {
      run_plot_studio_action("visual_redo", "Redo visual change", function() run_visual_command("redo"), type = "visual_document", input_id = "visual_redo")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_checkpoint, {
      run_plot_studio_action("visual_checkpoint", "Save visual checkpoint", function() run_visual_command("checkpoint", list(label = paste("Checkpoint", Sys.time()))), type = "visual_document", input_id = "visual_checkpoint")
    }, ignoreInit = TRUE)

    observeEvent(input$visual_make_explanatory, {
      run_plot_studio_action(
        "visual_make_explanatory",
        "Draft explanatory visual",
        function() {
          document <- ensure_current_visual_document()
          plot_object <- document$objects$plot_001 %||% list()
          finding <- list(
            evidence_ids = "current_plot_evidence",
            source_artifacts = plot_object$id %||% "plot_001",
            title = plot_object$properties[["title.text"]] %||%
              plot_object$label %||%
              "Current visual finding",
            statement = paste(
              "This",
              tolower(plot_object$label %||% "visual"),
              "has been promoted into an explanatory visual with evidence context."
            ),
            explanation = "Use the visual, highlighted finding, interpretation, and provenance together before treating this as decision evidence.",
            source = "Plot Studio visual document generated from the current AutoPlots configuration."
          )
          proposal <- visual_authoring_create_proposal(
            document,
            evidence = finding,
            timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
          )
          document <- visual_authoring_store_proposal(document, proposal)
          set_current_visual_document(document)
          current_visual_authoring_proposal(proposal$proposal_id)
          ctx$plot_list_message("Drafted a semantic authoring proposal. Review and approve before the document changes.")
          TRUE
        },
        type = "visual_authoring",
        input_id = "visual_make_explanatory"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_authoring_accept_selected, {
      run_plot_studio_action(
        "visual_authoring_accept_selected",
        "Accept selected authoring objects",
        function() {
          document <- ensure_current_visual_document()
          object_ids <- input$visual_authoring_object_selection %||% character()
          if (!length(object_ids)) {
            ctx$plot_list_message("Select at least one proposed object to accept.")
            return(TRUE)
          }
          set_current_visual_document(visual_authoring_accept_proposal(
            document,
            current_visual_authoring_proposal(),
            object_ids
          ))
          current_visual_authoring_proposal(NULL)
          ctx$plot_list_message("Accepted selected semantic authoring objects.")
          TRUE
        },
        type = "visual_authoring",
        input_id = "visual_authoring_accept_selected"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_authoring_accept_all, {
      run_plot_studio_action(
        "visual_authoring_accept_all",
        "Accept authoring proposal",
        function() {
          document <- ensure_current_visual_document()
          set_current_visual_document(visual_authoring_accept_proposal(
            document,
            current_visual_authoring_proposal(),
            NULL
          ))
          current_visual_authoring_proposal(NULL)
          ctx$plot_list_message("Accepted semantic authoring proposal.")
          TRUE
        },
        type = "visual_authoring",
        input_id = "visual_authoring_accept_all"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_authoring_reject, {
      run_plot_studio_action(
        "visual_authoring_reject",
        "Reject authoring proposal",
        function() {
          document <- ensure_current_visual_document()
          set_current_visual_document(visual_document_apply_mutation(document, list(
            type = "reject_authoring_proposal",
            proposal_id = current_visual_authoring_proposal(),
            reason = "Rejected in Plot Studio"
          )))
          current_visual_authoring_proposal(NULL)
          ctx$plot_list_message("Rejected semantic authoring proposal.")
          TRUE
        },
        type = "visual_authoring",
        input_id = "visual_authoring_reject"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_create_review, {
      run_plot_studio_action(
        "visual_composition_create_review",
        "Review composition",
        function() {
          document <- ensure_current_visual_document()
          review <- visual_composition_create_review(
            document,
            evidence = composition_evidence_context(document)
          )
          document <- visual_composition_store_review(document, review)
          set_current_visual_document(document)
          current_visual_composition_review(review$review_id)
          current_visual_composition_branch(NULL)
          ctx$plot_list_message("Composition review generated.")
          TRUE
        },
        type = "visual_composition",
        input_id = "visual_composition_create_review"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_generate_strategies, {
      run_plot_studio_action(
        "visual_composition_generate_strategies",
        "Generate composition strategies",
        function() {
          document <- ensure_current_visual_document()
          review <- visual_composition_get_review(document, current_visual_composition_review())
          evidence <- composition_evidence_context(document)

          if (is.null(review)) {
            review <- visual_composition_create_review(document, evidence = evidence)
            document <- visual_composition_store_review(document, review)
            current_visual_composition_review(review$review_id)
          }

          strategies <- visual_composition_generate_strategies(document, review, evidence)
          document <- visual_composition_store_strategies(document, strategies)
          set_current_visual_document(document)
          current_visual_composition_strategy(document$composition$active_strategy_id)
          current_visual_composition_branch(NULL)
          ctx$plot_list_message("Composition strategies generated.")
          TRUE
        },
        type = "visual_composition",
        input_id = "visual_composition_generate_strategies"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_strategy, {
      strategy_id <- selected_value(input$visual_composition_strategy)
      if (is.null(strategy_id) || !nzchar(strategy_id)) {
        return()
      }

      document <- ensure_current_visual_document()
      if (!is.null(document$composition$strategies[[strategy_id]])) {
        document$composition$active_strategy_id <- strategy_id
        set_current_visual_document(document)
        current_visual_composition_strategy(strategy_id)
        current_visual_composition_branch(NULL)
      }
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_preview_branch, {
      run_plot_studio_action(
        "visual_composition_preview_branch",
        "Preview composition branch",
        function() {
          document <- ensure_current_visual_document()
          strategy_id <- current_visual_composition_strategy() %||% document$composition$active_strategy_id
          mutation_ids <- input$visual_composition_mutation_selection %||% NULL

          if (is.null(strategy_id)) {
            ctx$plot_list_message("Generate and select a composition strategy before previewing.")
            return(TRUE)
          }

          document <- visual_composition_create_branch(document, strategy_id, mutation_ids)
          set_current_visual_document(document)
          current_visual_composition_branch(document$composition$active_branch_id)
          ctx$plot_list_message("Preview branch created. Canonical document is unchanged.")
          TRUE
        },
        type = "visual_composition",
        input_id = "visual_composition_preview_branch"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_accept_selected, {
      run_plot_studio_action(
        "visual_composition_accept_selected",
        "Accept selected composition mutations",
        function() {
          document <- ensure_current_visual_document()
          strategy_id <- current_visual_composition_strategy() %||% document$composition$active_strategy_id
          mutation_ids <- input$visual_composition_mutation_selection %||% character()

          if (!length(mutation_ids)) {
            ctx$plot_list_message("Select at least one composition mutation to accept.")
            return(TRUE)
          }

          document <- visual_composition_accept_strategy(document, strategy_id, mutation_ids)
          set_current_visual_document(document)
          current_visual_composition_branch(NULL)
          ctx$plot_list_message("Accepted selected composition mutations.")
          TRUE
        },
        type = "visual_composition",
        input_id = "visual_composition_accept_selected"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_accept_all, {
      run_plot_studio_action(
        "visual_composition_accept_all",
        "Accept composition strategy",
        function() {
          document <- ensure_current_visual_document()
          strategy_id <- current_visual_composition_strategy() %||% document$composition$active_strategy_id

          if (is.null(strategy_id)) {
            ctx$plot_list_message("Generate and select a composition strategy before accepting.")
            return(TRUE)
          }

          document <- visual_composition_accept_strategy(document, strategy_id)
          set_current_visual_document(document)
          current_visual_composition_branch(NULL)
          ctx$plot_list_message("Accepted composition strategy.")
          TRUE
        },
        type = "visual_composition",
        input_id = "visual_composition_accept_all"
      )
    }, ignoreInit = TRUE)

    observeEvent(input$visual_composition_reject_strategy, {
      run_plot_studio_action(
        "visual_composition_reject_strategy",
        "Reject composition strategy",
        function() {
          document <- ensure_current_visual_document()
          strategy_id <- current_visual_composition_strategy() %||% document$composition$active_strategy_id

          if (is.null(strategy_id)) {
            ctx$plot_list_message("Generate and select a composition strategy before rejecting.")
            return(TRUE)
          }

          document <- visual_composition_reject_strategy(document, strategy_id, "Rejected in Plot Studio")
          set_current_visual_document(document)
          current_visual_composition_strategy(NULL)
          current_visual_composition_branch(NULL)
          ctx$plot_list_message("Rejected composition strategy. It remains preserved for review.")
          TRUE
        },
        type = "visual_composition",
        input_id = "visual_composition_reject_strategy"
      )
    }, ignoreInit = TRUE)

    lapply(names(option_registry), function(option_name) {
      force(option_name)
      opt <- option_registry[[option_name]]
      observeEvent(input[[opt$input_id]], {
        if (is.null(input$plot_type)) {
          return()
        }
        if (isTRUE(inspector_state$loading) || isTRUE(inspector_state$applying)) {
          return()
        }
        if (!option_name %in% (inspector_state$fields %||% character())) {
          return()
        }

        inspector_collect_from_inputs()
      }, ignoreInit = TRUE)
    })

    observeEvent(input$visual_object_label, {
      if (isTRUE(inspector_state$loading) || isTRUE(inspector_state$applying)) {
        return()
      }
      inspector_collect_from_inputs()
    }, ignoreInit = TRUE)

    lapply(theme_choices, function(theme) {
      force(theme)
      observeEvent(input[[plot_theme_preset_id(theme)]], {
        update_option_control("Theme", theme)
        has_live_plot <- !is.null(ctx$plot_config()) || !is.null(ctx$plot_result())
        if (!has_live_plot) {
          document <- ensure_current_visual_document()
          tryCatch({
            set_current_visual_document(visual_document_apply_mutation(
              document,
              list(
                type = "set_property",
                object_id = "plot_001",
                property = "Theme",
                value = theme
              )
            ))
          }, error = function(e) {
            ctx$plot_list_message(conditionMessage(e))
          })
        }
        if (has_live_plot) {
          rebuild_current_plot(
            option_overrides = list(Theme = theme),
            status_message = paste("Applied", plot_theme_label(theme), "theme.")
          )
        }
      }, ignoreInit = TRUE)
    })

    observeEvent(input$add_plot, {
      if (is.null(ctx$plot_result()) || is.null(ctx$plot_config()) || !is.null(ctx$plot_error())) {
        ctx$plot_list_message("Build a plot successfully before adding it.")
        return()
      }

      plot_name <- next_plot_name(names(ctx$saved_plots$plots))
      config <- ctx$plot_config()

      ctx$saved_plots$plots[[plot_name]] <- ctx$plot_result()
      ctx$saved_plots$configs[[plot_name]] <- config
      ctx$saved_plots$code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
      ctx$saved_plots$metadata[[plot_name]] <- plot_metadata(
        plot_name = plot_name,
        config = config,
        section_name = "Analysis",
        sort_order = next_sort_order(ctx$saved_plots$metadata)
      )
      ctx$saved_plots$status[[plot_name]] <- list(status = "Ready", message = "")
      ctx$plot_list_message(paste("Added", plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$remove_last_plot, {
      plot_names <- names(ctx$saved_plots$plots)
      if (!length(plot_names)) {
        ctx$plot_list_message("No saved plots to remove.")
        return()
      }

      plot_name <- plot_names[length(plot_names)]
      ctx$remove_artifact_by_id(plot_name)
      ctx$plot_list_message(paste("Removed", plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$load_saved_plot, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$configs)) {
        ctx$plot_list_message("Select a saved plot to load.")
        return()
      }

      config <- ctx$saved_plots$configs[[plot_name]]
      ctx$plot_result(NULL)
      ctx$plot_error(NULL)
      ctx$plot_config(NULL)
      ctx$load_config_into_builder(config)
      ctx$plot_list_message(paste0("Loaded ", plot_name, " for editing. Click Build / Refresh Plot."))
    }, ignoreInit = TRUE)

    observeEvent(input$update_saved_plot, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$plots)) {
        ctx$plot_list_message("Select a saved plot to update.")
        return()
      }

      if (is.null(ctx$plot_result()) || is.null(ctx$plot_config()) || !is.null(ctx$plot_error())) {
        ctx$plot_list_message("Build the edited plot successfully before updating the saved plot.")
        return()
      }

      config <- ctx$plot_config()
      ctx$saved_plots$plots[[plot_name]] <- ctx$plot_result()
      ctx$saved_plots$configs[[plot_name]] <- config
      ctx$saved_plots$code[[plot_name]] <- build_autoplots_assignment_code(plot_name, config)
      metadata <- ctx$saved_plots$metadata[[plot_name]]
      if (is.null(metadata)) {
        metadata <- plot_metadata(
          plot_name = plot_name,
          config = config,
          section_name = "Analysis",
          sort_order = next_sort_order(ctx$saved_plots$metadata)
        )
      }
      metadata$plot_type <- config$plot_type
      metadata$visual_document <- config$visual_document %||% visual_document_from_plot_config(config, plot_name = plot_name)
      ctx$saved_plots$metadata[[plot_name]] <- metadata
      ctx$saved_plots$status[[plot_name]] <- list(status = "Ready", message = "")
      update_saved_plot_references(plot_name, ctx$plot_result())
      ctx$plot_list_message(paste("Updated", plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$duplicate_saved_plot, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$plots)) {
        ctx$plot_list_message("Select a saved plot to duplicate.")
        return()
      }

      new_plot_name <- next_plot_name(names(ctx$saved_plots$plots))
      config <- ctx$saved_plots$configs[[plot_name]]
      metadata <- ctx$saved_plots$metadata[[plot_name]]
      section_name <- if (is.null(metadata$section_name)) "Analysis" else metadata$section_name
      ctx$saved_plots$plots[[new_plot_name]] <- ctx$saved_plots$plots[[plot_name]]
      ctx$saved_plots$configs[[new_plot_name]] <- config
      ctx$saved_plots$code[[new_plot_name]] <- build_autoplots_assignment_code(new_plot_name, config)
      ctx$saved_plots$metadata[[new_plot_name]] <- plot_metadata(
        plot_name = new_plot_name,
        config = config,
        section_name = section_name,
        sort_order = next_sort_order(ctx$saved_plots$metadata)
      )
      ctx$saved_plots$status[[new_plot_name]] <- ctx$saved_plots$status[[plot_name]]
      ctx$plot_list_message(paste("Duplicated", plot_name, "as", new_plot_name))
    }, ignoreInit = TRUE)

    observeEvent(input$assign_plot_section, {
      plot_name <- selected_value(input$selected_saved_plot)
      if (is.null(plot_name) || !plot_name %in% names(ctx$saved_plots$plots)) {
        ctx$plot_list_message("Select a saved plot before assigning a section.")
        return()
      }

      section_name <- selected_value(input$new_section_name)
      if (is.null(section_name)) {
        section_name <- selected_value(input$section_for_plot)
      }
      if (is.null(section_name)) {
        section_name <- "Analysis"
      }

      metadata <- ctx$saved_plots$metadata[[plot_name]]
      if (is.null(metadata)) {
        metadata <- plot_metadata(
          plot_name = plot_name,
          config = ctx$saved_plots$configs[[plot_name]],
          sort_order = next_sort_order(ctx$saved_plots$metadata)
        )
      }

      metadata$section_name <- section_name
      if (is.null(metadata$visual_document)) {
        metadata$visual_document <- visual_document_from_plot_config(
          ctx$saved_plots$configs[[plot_name]],
          plot_name = plot_name
        )
      }
      ctx$saved_plots$metadata[[plot_name]] <- metadata
      ctx$plot_list_message(paste("Assigned", plot_name, "to", section_name))
    }, ignoreInit = TRUE)

    move_saved_plot <- function(direction) {
      plot_name <- selected_value(input$selected_saved_plot)
      plot_names <- ctx$ordered_plot_names()
      if (is.null(plot_name) || !plot_name %in% plot_names) {
        ctx$plot_list_message("Select a saved plot to move.")
        return()
      }

      index <- match(plot_name, plot_names)
      swap_index <- index + direction
      if (swap_index < 1L || swap_index > length(plot_names)) {
        ctx$plot_list_message(paste(plot_name, "is already at that end of the order."))
        return()
      }

      swap_name <- plot_names[swap_index]
      current_order <- ctx$saved_plots$metadata[[plot_name]]$sort_order
      swap_order <- ctx$saved_plots$metadata[[swap_name]]$sort_order
      ctx$saved_plots$metadata[[plot_name]]$sort_order <- swap_order
      ctx$saved_plots$metadata[[swap_name]]$sort_order <- current_order
      ctx$plot_list_message(paste("Moved", plot_name))
    }

    observeEvent(input$move_plot_up, {
      move_saved_plot(-1L)
    }, ignoreInit = TRUE)

    observeEvent(input$move_plot_down, {
      move_saved_plot(1L)
    }, ignoreInit = TRUE)

    output$preview_plot <- renderUI({
      if (is.null(input$build_plot) || input$build_plot == 0L) {
        return(tags$div(
          class = "aq-plot-empty-preview",
          tags$strong("No plot built yet."),
          tags$span("Map variables, choose the data treatment, then build the preview.")
        ))
      }

      if (!ctx$has_upload_or_project_data()) {
        return(plot_error_message("No data is available."))
      }

      if (!is.null(ctx$plot_error())) {
        return(plot_error_message(ctx$plot_error()))
      }

      if (is.null(ctx$plot_result())) {
        return(tags$div(
          class = "aq-plot-empty-preview",
          tags$strong("Preparing plot preview..."),
          tags$span("The current plot operation is still resolving.")
        ))
      }

      uiOutput(session$ns("preview_plot_widget"))
    })

    output$preview_plot_widget <- renderUI({
      req(ctx$plot_result())
      plot_ui <- render_plot_service_widget(
        ctx$plot_result(),
        output = output,
        session = session,
        output_id = "preview_plot_echarts",
        height = "600px"
      )
      visual_document_composition_ui(ensure_current_visual_document(), plot_ui)
    })

    output$generated_code <- renderText({
      req(input$plot_type)

      build_autoplots_code(
        plot_type = input$plot_type,
        input = input
      )
    })

    output$plot_list_message <- renderText({
      ctx$plot_list_message()
    })

    output$saved_plot_list <- renderUI({
      plot_names <- ctx$ordered_plot_names()
      if (!length(plot_names)) {
        return(render_table(
          data.table::data.table(Message = "No saved plots yet."),
          engine = "html",
          searchable = FALSE,
          sortable = FALSE
        ))
      }

      data <- data.table::rbindlist(
        lapply(plot_names, function(plot_name) {
          plot_config_summary(
            name = plot_name,
            config = ctx$saved_plots$configs[[plot_name]],
            metadata = ctx$saved_plots$metadata[[plot_name]],
            status = ctx$saved_plots$status[[plot_name]]
          )
        }),
        use.names = TRUE
      )
      render_table(data, engine = "html", searchable = FALSE, sortable = FALSE)
    })

    output$saved_plots_code <- renderText({
      build_saved_plots_code(ordered_list_by_names(ctx$saved_plots$code, ctx$ready_plot_names()))
    })
  })
}

#' QA Plot Studio Responsiveness
#'
#' Verifies that the Plot Studio uses bounded controls, unclipped mapping
#' dropdowns, guarded visual actions, and a single-column evidence disclosure.
#'
#' @export
qa_plot_studio_responsiveness <- function() {
  read_text <- function(path) {
    candidates <- unique(c(
      path,
      file.path("..", path),
      file.path("..", "..", path)
    ))
    existing <- candidates[file.exists(candidates)]
    if (!length(existing)) {
      return("")
    }
    paste(readLines(existing[[1]], warn = FALSE), collapse = "\n")
  }

  package_css <- system.file("app/www/app.css", package = "AnalyticsShinyApp")
  css_path <- if (file.exists(file.path("www", "app.css"))) {
    file.path("www", "app.css")
  } else {
    package_css
  }
  css_text <- read_text(css_path)
  plot_builder_page <- read_text(file.path("R", "page_plot_builder.R"))
  visual_document_page <- read_text(file.path("R", "visual_document.R"))

  append_function_source <- function(text, fn_name) {
    if (!exists(fn_name, mode = "function")) {
      return(text)
    }
    paste(text, paste(deparse(get(fn_name, mode = "function")), collapse = "\n"), sep = "\n")
  }

  plot_builder_page <- append_function_source(plot_builder_page, "page_plot_builder_ui")
  plot_builder_page <- append_function_source(plot_builder_page, "page_plot_builder_server")
  visual_document_page <- append_function_source(
    visual_document_page,
    "visual_document_composition_ui"
  )

  count_fixed <- function(text, pattern) {
    matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
    if (identical(matches, -1L)) {
      0L
    } else {
      length(matches)
    }
  }

  checks <- list(
    "operation status is visible" =
      grepl("plot_operation_status", plot_builder_page, fixed = TRUE) &&
        grepl("aq-plot-operation-status", css_text, fixed = TRUE),
    "plot definition groups mapping and treatment" =
      grepl("aq-plot-definition", plot_builder_page, fixed = TRUE) &&
        grepl("aq-plot-map-grid", plot_builder_page, fixed = TRUE) &&
        grepl("aq-plot-treatment-grid", plot_builder_page, fixed = TRUE),
    "theme catalog is collapsible" =
      grepl("aq-plot-theme-details", plot_builder_page, fixed = TRUE) &&
        grepl("Browse themes", plot_builder_page, fixed = TRUE),
    "clear preview action exists" =
      grepl("clear_plot_preview", plot_builder_page, fixed = TRUE),
    "operation guard exists" =
      grepl("run_plot_studio_action", plot_builder_page, fixed = TRUE) &&
        grepl("plot_action_state", plot_builder_page, fixed = TRUE),
    "expensive visual actions use guarded operation path" =
      grepl("visual_authoring_accept_selected", plot_builder_page, fixed = TRUE) &&
        grepl("visual_composition_accept_all", plot_builder_page, fixed = TRUE) &&
        count_fixed(plot_builder_page, "run_plot_studio_action") >= 10L,
    "visual composition uses single column evidence disclosure" =
      grepl("aq-visual-composition-grid-single", visual_document_page, fixed = TRUE) &&
        grepl("tags$details", visual_document_page, fixed = TRUE),
    "select dropdowns can escape plot definition containers" =
      grepl(".aq-plot-studio-v3 .selectize-dropdown", css_text, fixed = TRUE) &&
        grepl("z-index: 10060", css_text, fixed = TRUE) &&
        grepl("overflow: visible", css_text, fixed = TRUE),
    "responsive plot definition css exists" =
      grepl(".aq-plot-definition-grid", css_text, fixed = TRUE) &&
        grepl("@media (max-width: 1180px)", css_text, fixed = TRUE),
    "composition evidence grid css exists" =
      grepl(".aq-visual-composition-evidence-grid", css_text, fixed = TRUE)
  )

  ok <- unlist(checks, use.names = FALSE)
  data.table::data.table(
    check = names(checks),
    status = ifelse(ok, "success", "error"),
    detail = ifelse(ok, "ok", "missing or stale")
  )
}

#' QA Plot Studio Inspector Draft Workflow
#'
#' Verifies that inspector edits are local drafts until Apply creates one
#' governed visual document mutation.
#'
#' @export
qa_inspector_draft_workflow <- function() {
  qa_result <- function(check, ok, detail = "ok") {
    data.table::data.table(
      check = check,
      status = if (isTRUE(ok)) "success" else "error",
      detail = detail
    )
  }

  results <- list()
  document <- visual_document_from_plot_spec("area")
  document <- visual_document_select(document, "title_001", origin = "qa")
  original_revision <- as.integer(document$revision %||% 0L)
  original_undo <- length(document$history$undo %||% list())

  fields <- c("title.text", "title.subtext")
  original_values <- plot_inspector_values(fields, document$objects$title_001$properties)
  draft_values <- plot_inspector_values(fields, list(
    `title.text` = "Revenue Trend",
    `title.subtext` = "Draft subtitle"
  ))
  dirty <- plot_inspector_dirty_fields(
    document$objects$title_001$label,
    "Draft Title Object",
    original_values,
    draft_values,
    fields
  )

  results[["draft detects local changes"]] <- qa_result(
    "draft detects local changes",
    setequal(dirty, c("label", "title.text", "title.subtext"))
  )
  results[["draft leaves document revision unchanged"]] <- qa_result(
    "draft leaves document revision unchanged",
    identical(as.integer(document$revision), original_revision)
  )
  results[["draft leaves undo history unchanged"]] <- qa_result(
    "draft leaves undo history unchanged",
    identical(length(document$history$undo %||% list()), original_undo)
  )

  mutated <- visual_document_apply_mutation(document, list(
    type = "update_object",
    object_id = "title_001",
    label = "Draft Title Object",
    values = draft_values
  ))
  results[["apply batches changes into one revision"]] <- qa_result(
    "apply batches changes into one revision",
    identical(as.integer(mutated$revision), original_revision + 1L)
  )
  results[["apply writes one undo entry"]] <- qa_result(
    "apply writes one undo entry",
    identical(length(mutated$history$undo %||% list()), original_undo + 1L)
  )
  results[["apply preserves selected object"]] <- qa_result(
    "apply preserves selected object",
    identical(mutated$selected_object_id, "title_001")
  )
  results[["apply stores updated label"]] <- qa_result(
    "apply stores updated label",
    identical(mutated$objects$title_001$label, "Draft Title Object")
  )
  results[["apply stores updated title"]] <- qa_result(
    "apply stores updated title",
    identical(mutated$objects$title_001$properties[["title.text"]], "Revenue Trend")
  )
  results[["apply records update_object mutation"]] <- qa_result(
    "apply records update_object mutation",
    identical(tail(mutated$history$undo, 1)[[1]]$mutation$type, "update_object")
  )

  invalid <- plot_inspector_validate_draft("", draft_values, fields)
  results[["draft validation rejects empty object name"]] <- qa_result(
    "draft validation rejects empty object name",
    length(invalid) > 0L
  )

  runtime_source <- paste(deparse(body(page_plot_builder_server), width.cutoff = 500L), collapse = "\n")
  composition_source <- sub(
    "[\\s\\S]*output\\$visual_composition_review <- renderUI\\(\\{",
    "",
    runtime_source,
    perl = TRUE
  )
  composition_source <- sub(
    "output\\$theme_presets <- renderUI\\(\\{[\\s\\S]*$",
    "",
    composition_source,
    perl = TRUE
  )
  results[["legacy rename command removed"]] <- qa_result(
    "legacy rename command removed",
    !grepl("visual_rename_object", runtime_source, fixed = TRUE)
  )
  results[["inspector apply command exists"]] <- qa_result(
    "inspector apply command exists",
    grepl("visual_inspector_apply", runtime_source, fixed = TRUE)
  )
  results[["inspector reset command exists"]] <- qa_result(
    "inspector reset command exists",
    grepl("visual_inspector_reset", runtime_source, fixed = TRUE)
  )
  results[["inspector controls collect draft"]] <- qa_result(
    "inspector controls collect draft",
    grepl("inspector_collect_from_inputs()", runtime_source, fixed = TRUE)
  )
  results[["composition review ignores inspector draft state"]] <- qa_result(
    "composition review ignores inspector draft state",
    !grepl("inspector_state", composition_source, fixed = TRUE)
  )

  data.table::rbindlist(results, use.names = TRUE, fill = TRUE)
}
