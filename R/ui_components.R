.aq_class <- function(...) {
  classes <- unlist(list(...), use.names = FALSE)
  classes <- classes[!is.null(classes) & nzchar(classes)]
  paste(classes, collapse = " ")
}

ui_card <- function(title = NULL, subtitle = NULL, ..., footer = NULL, class = NULL) {
  tags$section(
    class = .aq_class("aq-card", class),
    if (!is.null(title) || !is.null(subtitle)) {
      tags$header(
        class = "aq-card-header",
        if (!is.null(title)) tags$h3(class = "aq-card-title", title),
        if (!is.null(subtitle)) tags$p(class = "aq-card-subtitle", subtitle)
      )
    },
    tags$div(class = "aq-card-body", ...),
    if (!is.null(footer)) tags$footer(class = "aq-card-footer", footer)
  )
}

ui_app_shell <- function(..., theme = "dark") {
  theme <- match.arg(theme, c("light", "dark", "cyberpunk", "pimp"))

  tagList(
    tags$script(HTML(sprintf(
      "
      (function() {
        var themes = ['light', 'dark', 'cyberpunk', 'pimp'];
        var defaultTheme = '%s';
        function normalizeTheme(value) {
          return themes.indexOf(value) >= 0 ? value : defaultTheme;
        }
        function applyTheme(value) {
          var theme = normalizeTheme(value);
          themes.forEach(function(item) {
            document.body.classList.remove('aq-theme-' + item);
          });
          document.body.classList.add('aq-theme-' + theme);
          document.documentElement.setAttribute('data-aq-theme', theme);
          try { window.localStorage.setItem('aq.theme', theme); } catch (error) {}
          var control = document.getElementById('aq-theme-select');
          if (control && control.value !== theme) control.value = theme;
        }
        window.aqApplyTheme = applyTheme;
        try {
          applyTheme(window.localStorage.getItem('aq.theme') || defaultTheme);
        } catch (error) {
          applyTheme(defaultTheme);
        }
        document.addEventListener('DOMContentLoaded', function() {
          var control = document.getElementById('aq-theme-select');
          if (!control) return;
          try { control.value = normalizeTheme(window.localStorage.getItem('aq.theme') || defaultTheme); } catch (error) {}
          control.addEventListener('change', function(event) {
            applyTheme(event.target.value);
          });
        });
      })();
      ",
      theme
    ))),
    tags$div(
      class = "aq-app-shell aq-workstation-shell",
      ...
    )
  )
}

ui_theme_switcher <- function(theme = "dark") {
  theme <- match.arg(theme, c("light", "dark", "cyberpunk", "pimp"))

  tags$div(
    class = "aq-theme-switcher",
    tags$label(`for` = "aq-theme-select", "Theme"),
    tags$select(
      id = "aq-theme-select",
      class = "aq-theme-select",
      tags$option(value = "dark", selected = if (identical(theme, "dark")) "selected" else NULL, "Dark"),
      tags$option(value = "light", selected = if (identical(theme, "light")) "selected" else NULL, "Light"),
      tags$option(value = "cyberpunk", selected = if (identical(theme, "cyberpunk")) "selected" else NULL, "Cyberpunk")
    )
  )
}

app_tab_value <- function(page) {
  page <- page %||% ""
  value_map <- c(
    "Evidence Review" = "evidence_review",
    "Decision Management" = "decision_management",
    "Semantic Intelligence" = "semantic_intelligence",
    "AI Runtime" = "ai_runtime",
    "Product Experience" = "product_experience"
  )
  if (page %in% names(value_map)) {
    return(unname(value_map[[page]]))
  }
  page
}

ui_page <- function(title, subtitle = NULL, ..., actions = NULL, eyebrow = NULL) {
  tags$div(
    class = "aq-page",
    ui_section_header(title, subtitle, actions = actions, eyebrow = eyebrow),
    ...
  )
}

ui_object_spine <- function(object, intent, state = NULL, next_action = NULL, depth = NULL, class = NULL) {
  tags$section(
    class = .aq_class("aq-object-spine", class),
    tags$div(
      class = "aq-object-spine-primary",
      tags$p(class = "aq-object-spine-label", "Dominant object"),
      tags$h3(class = "aq-object-spine-object", object),
      tags$p(class = "aq-object-spine-intent", intent)
    ),
    tags$dl(
      class = "aq-object-spine-facts",
      if (!is.null(state)) tagList(tags$dt("State"), tags$dd(state)),
      if (!is.null(next_action)) tagList(tags$dt("Next"), tags$dd(next_action)),
      if (!is.null(depth)) tagList(tags$dt("Depth"), tags$dd(depth))
    )
  )
}

ui_section_header <- function(title, subtitle = NULL, actions = NULL, eyebrow = NULL) {
  tags$header(
    class = "aq-section-header",
    tags$div(
      class = "aq-section-heading",
      if (!is.null(eyebrow)) tags$p(class = "aq-section-eyebrow", eyebrow),
      tags$h2(class = "aq-section-title", title),
      if (!is.null(subtitle)) tags$p(class = "aq-section-subtitle", subtitle)
    ),
    if (!is.null(actions)) tags$div(class = "aq-section-actions", actions)
  )
}

ui_empty_state <- function(title, message = NULL, icon = NULL) {
  tags$div(
    class = "aq-empty-state",
    if (!is.null(icon)) tags$div(class = "aq-empty-state-icon", icon),
    tags$h3(class = "aq-empty-state-title", title),
    if (!is.null(message)) tags$p(class = "aq-empty-state-message", message)
  )
}

ui_loading_state <- function(title = "Working", message = NULL) {
  tags$div(
    class = "aq-loading-state",
    tags$span(class = "aq-loading-indicator", " "),
    tags$div(
      class = "aq-loading-copy",
      tags$strong(title),
      if (!is.null(message)) tags$p(message)
    )
  )
}

ui_status_badge <- function(
  label,
  status = c("success", "warning", "error", "info", "neutral")
) {
  status <- match.arg(status)

  tags$span(
    class = .aq_class("aq-status-badge", paste0("aq-status-badge-", status)),
    label
  )
}

ui_display_label <- function(value) {
  value <- as.character(value %||% "")
  if (!length(value) || is.na(value[[1]]) || !nzchar(value[[1]])) {
    return("Not Available")
  }
  value <- value[[1]]
  labels <- c(
    not_created = "Not Created",
    not_written = "Not Written",
    no_project = "No Project",
    project_ready = "Ready",
    project_closing = "Closing",
    workspace_ready = "Ready",
    workspace_unconfigured = "Not Configured",
    configured_workspace = "Saved Workspace",
    local_server_directory = "Local Folder",
    managed_workspace = "App-Managed Folder",
    native_host_directory = "Choose Folder",
    llm_docx = "LLM DOCX",
    human_report = "Human Report",
    artifact_studio = "Artifact Studio",
    success = "Completed",
    created = "Created",
    ready = "Ready",
    pending = "Pending",
    unavailable = "Unavailable",
    not_checked = "Not Checked",
    missing = "Missing",
    healthy = "Healthy",
    implemented = "Available",
    experimental = "Experimental",
    planned = "Planned",
    external_or_future = "External / Future",
    partial_tail = "Partial History"
  )
  label <- unname(labels[value])
  if (length(label) && !is.na(label) && nzchar(label)) {
    return(label)
  }
  tools::toTitleCase(gsub("_", " ", value))
}

ui_status_label <- function(value) {
  ui_display_label(value)
}

ui_project_safe_id_label <- function(value) {
  value <- as.character(value %||% "")
  if (!length(value) || is.na(value[[1]]) || !nzchar(value[[1]])) {
    return("Not Created")
  }
  value <- value[[1]]
  gsub("_(20[0-9]{6})([0-9]{6})$", " (created \\1)", value)
}

ui_action_row <- function(...) {
  tags$div(class = "aq-action-row", ...)
}

ui_action_bar <- function(..., left = NULL, right = NULL) {
  tags$div(
    class = "aq-action-bar",
    tags$div(class = "aq-action-bar-left", left %||% tagList(...)),
    if (!is.null(right)) tags$div(class = "aq-action-bar-right", right)
  )
}

ui_workspace_grid <- function(..., columns = c("main-sidebar", "two", "three", "auto"), class = NULL) {
  columns <- match.arg(columns)
  tags$div(class = .aq_class("aq-workspace-grid", paste0("aq-workspace-grid-", columns), class), ...)
}

ui_split_panel <- function(main, side_content, side = c("right", "left"), class = NULL) {
  side <- match.arg(side)
  tags$div(
    class = .aq_class("aq-split-panel", paste0("aq-split-panel-", side), class),
    tags$div(class = "aq-split-main", main),
    tags$aside(class = "aq-split-side", side_content)
  )
}

ui_stat_tile <- function(label, value, status = "neutral", detail = NULL) {
  tags$div(
    class = .aq_class("aq-stat-tile", paste0("aq-stat-tile-", status)),
    tags$span(class = "aq-stat-label", label),
    tags$strong(class = "aq-stat-value", value %||% "-"),
    if (!is.null(detail)) tags$span(class = "aq-stat-detail", detail)
  )
}

ui_stat_grid <- function(...) {
  tags$div(class = "aq-stat-grid", ...)
}

ui_status_tile <- function(label, value, status = "neutral", detail = NULL, trend = NULL, action = NULL) {
  tags$article(
    class = .aq_class("aq-status-tile", paste0("aq-status-tile-", status)),
    tags$div(
      class = "aq-status-tile-main",
      tags$span(class = "aq-status-tile-label", label),
      tags$strong(class = "aq-status-tile-value", value %||% "-"),
      if (!is.null(detail)) tags$span(class = "aq-status-tile-detail", detail)
    ),
    if (!is.null(trend)) tags$span(class = "aq-status-tile-trend", trend),
    if (!is.null(action)) tags$div(class = "aq-status-tile-action", action)
  )
}

ui_health_summary <- function(...) {
  tags$section(class = "aq-health-summary", ...)
}

ui_mission_state_banner <- function(status, title, message = NULL, facts = list()) {
  status <- status %||% "neutral"
  tags$section(
    class = .aq_class("aq-mission-state-banner", paste0("aq-mission-state-banner-", status)),
    tags$div(
      class = "aq-mission-state-signal",
      tags$span(class = "aq-mission-state-pulse", ""),
      tags$span(class = "aq-mission-state-label", toupper(status))
    ),
    tags$div(
      class = "aq-mission-state-copy",
      tags$strong(title),
      if (!is.null(message)) tags$p(message)
    ),
    if (length(facts)) {
      tags$dl(
        class = "aq-mission-state-facts",
        lapply(names(facts), function(name) {
          tagList(tags$dt(name), tags$dd(facts[[name]] %||% "-"))
        })
      )
    }
  )
}

ui_alert_card <- function(title, message = NULL, severity = "medium", source = NULL, action = NULL) {
  status <- switch(severity, high = "error", medium = "warning", low = "info", success = "success", "neutral")
  tags$article(
    class = .aq_class("aq-alert-card", paste0("aq-alert-card-", severity)),
    tags$div(
      class = "aq-alert-card-content",
      tags$header(
        class = "aq-alert-card-header",
        ui_status_badge(toupper(severity), status = status),
        if (!is.null(source)) tags$span(class = "aq-alert-card-source", source)
      ),
      tags$strong(class = "aq-alert-card-title", title),
      if (!is.null(message)) tags$p(class = "aq-alert-card-message", message)
    ),
    if (!is.null(action)) tags$div(class = "aq-alert-card-action", action)
  )
}

ui_timeline <- function(items) {
  if (is.null(items) || !length(items)) {
    return(ui_empty_state("No activity yet.", "Project events will appear here as data, modules, artifacts, collector writes, and reports are generated."))
  }
  tags$ol(
    class = "aq-timeline",
    lapply(items, function(item) {
      status <- item$status %||% "neutral"
      tags$li(
        class = .aq_class("aq-timeline-item", paste0("aq-timeline-item-", status)),
        tags$span(class = "aq-timeline-time", item$time %||% "--:--"),
        tags$div(
          class = "aq-timeline-content",
          tags$strong(item$title %||% "Project event"),
          if (!is.null(item$detail)) tags$p(item$detail)
        )
      )
    })
  )
}

ui_workflow_status <- function(rows, ns = identity) {
  if (is.null(rows) || !nrow(rows)) {
    return(ui_empty_state("Workflow status unavailable.", "The workflow registry did not return any stages."))
  }
  tags$div(
    class = "aq-workflow-status-board",
    lapply(seq_len(nrow(rows)), function(index) {
      row <- rows[index]
      status <- row$status_group[[1]] %||% "neutral"
      action <- row$action[[1]] %||% ""
      tags$article(
        class = .aq_class("aq-workflow-status-card", paste0("aq-workflow-status-card-", status)),
        tags$header(
          class = "aq-workflow-status-card-header",
          tags$div(
            tags$strong(row$label[[1]]),
            tags$span(row$subtitle[[1]] %||% row$stage_id[[1]])
          ),
          ui_status_badge(row$display_status[[1]] %||% "Unknown", status = status)
        ),
        tags$dl(
          class = "aq-workflow-status-facts",
          tags$dt("Artifacts"), tags$dd(row$artifact_count[[1]] %||% 0L),
          tags$dt("Reports"), tags$dd(row$report_plan_count[[1]] %||% 0L)
        ),
        tags$p(class = "aq-workflow-status-purpose", row$purpose[[1]] %||% ""),
        if (nzchar(action)) {
          actionButton(ns(paste0("mission_open_", row$stage_id[[1]])), action, class = "btn-secondary btn-sm")
        }
      )
    })
  )
}

ui_quality_panel <- function(score = NULL, status = "neutral", title = "Artifact Quality", details = NULL) {
  score_value <- suppressWarnings(as.numeric(score %||% NA_real_))
  score_label <- if (!length(score_value) || is.na(score_value[[1]])) "Not scored" else paste0(round(score_value[[1]]), "%")
  ui_card(
    title = title,
    class = "aq-quality-panel",
    tags$div(
      class = .aq_class("aq-quality-meter", paste0("aq-quality-meter-", status)),
      tags$strong(class = "aq-quality-score", score_label),
      ui_status_badge(status, status = if (status %in% c("success", "warning", "error", "info", "neutral")) status else "neutral")
    ),
    if (!is.null(details)) tags$p(class = "aq-quality-details", details)
  )
}

ui_inspector_section <- function(
  title,
  ...,
  subtitle = NULL,
  eyebrow = NULL,
  collapsed = FALSE,
  class = NULL
) {
  content <- tagList(...)
  if (isTRUE(collapsed)) {
    return(ui_disclosure(
      title,
      tags$div(class = .aq_class("aq-inspector-section-body", class), content),
      level = "artifact",
      open = FALSE
    ))
  }

  tags$section(
    class = .aq_class("aq-inspector-section", class),
    tags$header(
      class = "aq-inspector-section-header",
      if (!is.null(eyebrow)) tags$p(class = "aq-inspector-section-eyebrow", eyebrow),
      tags$h4(class = "aq-inspector-section-title", title),
      if (!is.null(subtitle)) tags$p(class = "aq-inspector-section-subtitle", subtitle)
    ),
    tags$div(class = "aq-inspector-section-body", content)
  )
}

ui_metadata_grid <- function(items, empty_message = "No metadata supplied.") {
  items <- items[!is.na(items$value) & nzchar(as.character(items$value))]
  if (is.null(items) || !nrow(items)) {
    return(ui_empty_state(empty_message))
  }
  tags$dl(
    class = "aq-metadata-grid",
    lapply(seq_len(nrow(items)), function(index) {
      tagList(
        tags$dt(items$field[[index]]),
        tags$dd(items$value[[index]])
      )
    })
  )
}

ui_evidence_summary <- function(title, caption = NULL, purpose = NULL, items = NULL, badges = NULL) {
  tags$section(
    class = "aq-evidence-summary",
    tags$header(
      class = "aq-evidence-summary-header",
      tags$h3(class = "aq-evidence-summary-title", title),
      if (!is.null(caption) && nzchar(caption)) tags$p(class = "aq-evidence-summary-caption", caption),
      if (!is.null(purpose) && nzchar(purpose)) tags$p(class = "aq-evidence-summary-purpose", purpose)
    ),
    if (!is.null(badges)) tags$div(class = "aq-evidence-summary-badges", badges),
    if (!is.null(items)) ui_metadata_grid(items)
  )
}

ui_quality_summary <- function(
  score = NULL,
  severity = "neutral",
  completeness = NULL,
  warnings = character(),
  collector_status = NULL,
  ai_readiness = NULL
) {
  score_value <- suppressWarnings(as.numeric(score %||% NA_real_))
  if (!length(score_value) || is.na(score_value[[1]])) {
    score_label <- "Not scored"
  } else {
    score_label <- paste0(round(score_value[[1]]), "%")
  }
  severity_status <- if (severity %in% c("success", "warning", "error", "info", "neutral")) severity else "neutral"
  warning_text <- warnings[nzchar(warnings)]

  tags$section(
    class = .aq_class("aq-quality-summary", paste0("aq-quality-summary-", severity_status)),
    tags$div(
      class = "aq-quality-summary-score",
      tags$span(class = "aq-quality-summary-label", "Quality"),
      tags$strong(score_label),
      ui_status_badge(severity %||% "neutral", status = severity_status)
    ),
    tags$div(
      class = "aq-quality-summary-facts",
      tags$span(tags$strong("Completeness"), completeness %||% score_label),
      tags$span(tags$strong("Collector"), ui_status_label(collector_status %||% "not_created")),
      tags$span(tags$strong("AI readiness"), ui_status_label(ai_readiness %||% "pending"))
    ),
    if (length(warning_text)) {
      tags$ul(class = "aq-quality-summary-warnings", lapply(warning_text, tags$li))
    } else {
      tags$p(class = "aq-quality-summary-muted", "No quality warnings were generated.")
    }
  )
}

ui_backing_asset_panel <- function(items, empty_message = "No backing assets are available.") {
  if (is.null(items) || !nrow(items)) {
    return(ui_empty_state(empty_message))
  }
  tags$div(
    class = "aq-backing-assets",
    lapply(seq_len(nrow(items)), function(index) {
      tags$article(
        class = "aq-backing-asset",
        tags$div(
          tags$strong(items$asset[[index]]),
          tags$span(items$status[[index]])
        ),
        tags$div(
          class = "aq-backing-asset-actions",
          tags$button(type = "button", class = "btn btn-secondary btn-sm", disabled = "disabled", "Open"),
          tags$button(type = "button", class = "btn btn-secondary btn-sm", disabled = "disabled", "Copy Path")
        )
      )
    })
  )
}

ui_ai_readiness_panel <- function(status = "pending", details = NULL, artifacts = NULL, render_target = NULL) {
  badge_status <- switch(
    status,
    ready = "success",
    partial = "warning",
    blocked = "error",
    "neutral"
  )
  ui_card(
    title = "AI Readiness",
    subtitle = "LLM-oriented evidence availability.",
    class = "aq-ai-readiness-panel",
    ui_stat_grid(
      ui_stat_tile("Status", ui_status_label(status), status = badge_status),
      ui_stat_tile("Evidence", artifacts %||% 0L, detail = "collector artifacts"),
      ui_stat_tile("Target", ui_display_label(render_target %||% "llm_docx"), detail = "render target")
    ),
    if (!is.null(details)) tags$p(class = "aq-ai-readiness-details", details)
  )
}

ui_callout <- function(title, message = NULL, status = c("info", "success", "warning", "error"), actions = NULL) {
  status <- match.arg(status)
  tags$aside(
    class = .aq_class("aq-callout", paste0("aq-callout-", status)),
    tags$div(
      class = "aq-callout-content",
      tags$strong(class = "aq-callout-title", title),
      if (!is.null(message)) tags$p(class = "aq-callout-message", message)
    ),
    if (!is.null(actions)) tags$div(class = "aq-callout-actions", actions)
  )
}

ui_progress_steps <- function(steps, active = NULL, completed = character()) {
  tags$ol(
    class = "aq-progress-steps",
    lapply(seq_along(steps), function(index) {
      step <- steps[[index]]
      step_id <- names(steps)[[index]] %||% as.character(index)
      status <- if (step_id %in% completed) {
        "complete"
      } else if (identical(step_id, active)) {
        "active"
      } else {
        "pending"
      }
      tags$li(
        class = .aq_class("aq-progress-step", paste0("aq-progress-step-", status)),
        tags$span(class = "aq-progress-step-index", index),
        tags$span(class = "aq-progress-step-label", step)
      )
    })
  )
}

ui_artifact_preview_card <- function(title, artifact_type, module = NULL, status = "neutral", details = NULL, actions = NULL) {
  tags$article(
    class = "aq-artifact-preview-card",
    tags$header(
      class = "aq-artifact-preview-header",
      tags$div(
        tags$h4(class = "aq-artifact-preview-title", title),
        if (!is.null(module)) tags$p(class = "aq-artifact-preview-module", module)
      ),
      ui_status_badge(artifact_type, status = status)
    ),
    if (!is.null(details)) tags$div(class = "aq-artifact-preview-details", details),
    if (!is.null(actions)) tags$footer(class = "aq-artifact-preview-actions", actions)
  )
}

ui_artifact_studio_card <- function(
  artifact,
  quality = NULL,
  selected = FALSE,
  ns = identity
) {
  metadata <- artifact$metadata %||% list()
  quality_score <- suppressWarnings(as.numeric(quality$artifact_completeness %||% NA_real_))
  if (!length(quality_score) || is.na(quality_score[[1]])) {
    quality_score <- NA_real_
  } else {
    quality_score <- quality_score[[1]]
  }
  quality_label <- if (is.na(quality_score)) "quality n/a" else paste0(round(quality_score), "% quality")
  importance <- metadata$artifact_importance %||% infer_artifact_importance(
    artifact$source_module,
    artifact$artifact_type,
    artifact$label,
    artifact$section,
    metadata$original_name
  )
  intent <- metadata$analytical_intent %||% infer_artifact_intent(
    artifact$artifact_type,
    artifact$label,
    artifact$section,
    metadata$original_name
  )
  render_targets <- paste(metadata$render_targets %||% c("human_report", "llm_docx"), collapse = ", ")
  card_status <- if (identical(quality$severity %||% "", "error")) "error" else if (identical(quality$severity %||% "", "warning")) "warning" else "success"
  thumbnail_src <- artifact_thumbnail_src(artifact)
  has_thumbnail <- !is.null(thumbnail_src) && identical(artifact$artifact_type, "plot")
  preview_hint <- paste(
    artifact$label %||% artifact$artifact_id,
    artifact_type_label(artifact$artifact_type %||% "artifact"),
    paste0("quality: ", quality_label),
    paste0("intent: ", intent),
    sep = " | "
  )

  tags$article(
    class = .aq_class(
      "aq-studio-card",
      paste0("aq-studio-card-", artifact$artifact_type %||% "artifact"),
      paste0("aq-studio-card-quality-", card_status),
      if (isTRUE(selected)) "aq-studio-card-selected"
    ),
    tabindex = "0",
    `aria-current` = if (isTRUE(selected)) "true" else "false",
    `data-artifact-id` = artifact$artifact_id %||% "",
    `data-intent` = intent,
    `data-importance` = importance,
    `data-quality` = quality_label,
    title = preview_hint,
    tags$div(
      class = .aq_class(
        "aq-studio-card-thumb",
        paste0("aq-studio-card-thumb-", artifact$artifact_type %||% "unknown"),
        if (has_thumbnail) "aq-studio-card-thumb-image"
      ),
      if (has_thumbnail) {
        tags$img(src = thumbnail_src, alt = artifact$label %||% artifact$artifact_id, loading = "lazy")
      } else {
        tags$span(class = "aq-studio-card-icon", artifact_studio_type_icon(artifact$artifact_type))
      },
      tags$span(class = "aq-studio-card-live-indicator", "Selected"),
      tags$span(class = "aq-studio-card-type", artifact_type_label(artifact$artifact_type %||% "artifact"))
    ),
    tags$div(
      class = "aq-studio-card-content",
      tags$h4(class = "aq-studio-card-title", artifact$label %||% artifact$artifact_id),
      tags$p(class = "aq-studio-card-module", module_display_label(artifact$source_module, "Unknown module")),
      tags$div(
        class = "aq-studio-card-badges",
        ui_status_badge(quality_label, status = card_status),
        ui_status_badge(importance, status = if (identical(importance, "critical")) "warning" else "neutral"),
        ui_status_badge(intent, status = "info")
      ),
      tags$dl(
        class = "aq-studio-card-meta",
        tags$dt("Run"), tags$dd(metadata$module_run_id %||% metadata$run_id %||% "-"),
        tags$dt("Targets"), tags$dd(render_targets)
      )
    ),
    tags$footer(
      class = "aq-studio-card-actions",
      actionButton(ns(paste0("inspect_", artifact_studio_safe_id(artifact$artifact_id))), "Inspect", class = "btn-primary btn-sm"),
      actionButton(ns(paste0("compare_", artifact_studio_safe_id(artifact$artifact_id))), "Compare", class = "btn-secondary btn-sm"),
      actionButton(ns(paste0("story_", artifact_studio_safe_id(artifact$artifact_id))), "Add to Story", class = "btn-secondary btn-sm")
    )
  )
}

artifact_thumbnail_path <- function(artifact) {
  metadata <- artifact$metadata %||% list()
  candidates <- c(
    metadata$thumbnail_path,
    metadata$screenshot_path,
    metadata$collector_screenshot_path
  )
  candidates <- unlist(candidates, use.names = FALSE)
  candidates <- as.character(candidates %||% character())
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates)) {
    return(normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE))
  }
  NULL
}

artifact_thumbnail_src <- function(artifact) {
  path <- artifact_thumbnail_path(artifact)
  if (is.null(path) || !requireNamespace("base64enc", quietly = TRUE)) {
    return(NULL)
  }
  ext <- tolower(tools::file_ext(path))
  mime <- switch(ext, jpg = "image/jpeg", jpeg = "image/jpeg", webp = "image/webp", "image/png")
  paste0("data:", mime, ";base64,", base64enc::base64encode(path))
}

ui_artifact_filmstrip <- function(artifacts, selected_id = NULL, ns = identity, limit = 24L) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(tags$div(
      class = "aq-artifact-filmstrip aq-artifact-filmstrip-empty",
      tags$div(
        class = "aq-artifact-filmstrip-placeholder",
        tags$span(class = "aq-artifact-filmstrip-icon", "A"),
        tags$strong("Recent artifacts will land here automatically."),
        tags$small("The filmstrip becomes your quick-switch lane once analysis modules start producing evidence.")
      )
    ))
  }
  ordered <- artifacts[order(vapply(artifacts, function(artifact) {
    as.numeric(artifact$updated_at %||% artifact$created_at %||% Sys.time())
  }, numeric(1)), decreasing = TRUE)]
  ordered <- utils::head(ordered, limit)

  tags$div(
    class = "aq-artifact-filmstrip",
    lapply(ordered, function(artifact) {
      is_selected <- identical(artifact$artifact_id, selected_id)
      preview_hint <- paste(
        artifact$label %||% artifact$artifact_id,
        artifact_type_label(artifact$artifact_type %||% "artifact"),
        module_display_label(artifact$source_module, artifact$source_module),
        sep = " | "
      )
      tags$button(
        type = "button",
        class = .aq_class("aq-artifact-filmstrip-item", if (is_selected) "aq-artifact-filmstrip-item-selected"),
        `aria-pressed` = if (is_selected) "true" else "false",
        `data-preview` = preview_hint,
        title = preview_hint,
        onclick = sprintf(
          "Shiny.setInputValue('%s', '%s', {priority: 'event'});",
          ns("filmstrip_select"),
          gsub("'", "\\\\'", artifact$artifact_id %||% "", fixed = TRUE)
        ),
        tags$span(class = "aq-artifact-filmstrip-icon", artifact_studio_type_icon(artifact$artifact_type)),
        tags$span(class = "aq-artifact-filmstrip-title", artifact$label %||% artifact$artifact_id),
        tags$span(class = "aq-artifact-filmstrip-module", module_display_label(artifact$source_module, artifact$source_module))
      )
    })
  )
}

artifact_studio_type_icon <- function(artifact_type) {
  switch(
    artifact_type %||% "",
    plot = "P",
    table = "T",
    text = "N",
    narrative = "N",
    genai_narrative = "N",
    recommendation = "R",
    diagnostic = "D",
    json = "J",
    metric = "M",
    "A"
  )
}

artifact_studio_safe_id <- function(value) {
  gsub("[^A-Za-z0-9_]+", "_", value %||% "artifact")
}

ui_collector_status_panel <- function(summary) {
  if (is.null(summary) || !nrow(summary)) {
    return(ui_empty_state("Project evidence memory not created.", "Run an analysis module to start preserving generated evidence for this project."))
  }
  summary_value <- function(name, default = NULL) {
    if (!name %in% names(summary)) {
      return(default)
    }
    summary[[name]][[1]] %||% default
  }
  status <- summary$collector_status[[1]] %||% "not_created"
  ui_card(
    title = "Project Evidence Memory",
    subtitle = "Generated evidence preserved for reports, review, and AI-ready project context.",
    ui_stat_grid(
      ui_stat_tile("Status", ui_status_label(status), status = if (status %in% c("success", "created")) "success" else "neutral"),
      ui_stat_tile("Run", summary_value("current_run_id", "-"), detail = "current run"),
      ui_stat_tile("Artifacts", summary_value("artifact_count", 0L), detail = paste(summary_value("bundle_count", 0L), "bundles")),
      ui_stat_tile("AI Context", ui_display_label(summary_value("render_target", "llm_docx"))),
      ui_stat_tile("Index", ui_status_label(summary_value("manifest_status", "not_written")))
    ),
    ui_disclosure(
      "Technical Files",
      render_table(
        summary[, list(collector_docx, manifest_file)],
        engine = "html",
        searchable = FALSE,
        sortable = FALSE
      ),
      level = "developer"
    )
  )
}

ui_disclosure <- function(title, ..., open = FALSE, level = c("common", "advanced", "artifact", "developer", "qa")) {
  level <- match.arg(level)
  tags$details(
    class = .aq_class("aq-disclosure", paste0("aq-disclosure-", level)),
    open = if (isTRUE(open)) "open" else NULL,
    tags$summary(class = "aq-disclosure-title", title),
    tags$div(class = "aq-disclosure-body", ...)
  )
}

ui_activity_list <- function(items = character()) {
  if (is.null(items) || !length(items)) {
    return(ui_empty_state("No recent activity yet.", "Run a module, save a project, or generate artifacts to populate this timeline."))
  }
  tags$ol(
    class = "aq-activity-list",
    lapply(items, function(item) tags$li(item))
  )
}

ui_choice_explainer <- function(input_id, label, choices, selected = NULL) {
  enabled_values <- vapply(choices, function(choice) {
    !isFALSE(choice$enabled %||% TRUE)
  }, logical(1))
  first_enabled <- which(enabled_values)[1]
  default_index <- if (is.na(first_enabled)) 1L else first_enabled
  selected <- selected %||% choices[[default_index]]$value
  if (!selected %in% vapply(choices[enabled_values], `[[`, character(1), "value")) {
    selected <- choices[[default_index]]$value
  }
  tags$div(
    class = "aq-choice-explainer",
    tags$div(class = "aq-choice-explainer-label", label),
    tags$div(
      id = input_id,
      class = "aq-choice-explainer-grid shiny-input-radiogroup",
      lapply(choices, function(choice) {
        value <- choice$value
        input_id_safe <- paste0(gsub("[^A-Za-z0-9_-]", "_", input_id), "_", gsub("[^A-Za-z0-9_-]", "_", value))
        enabled <- !isFALSE(choice$enabled %||% TRUE)
        tags$label(
          class = .aq_class(
            "aq-choice-explainer-card",
            if (!enabled) "aq-choice-explainer-card-disabled" else NULL
          ),
          `for` = input_id_safe,
          title = if (!enabled) choice$unavailable_reason %||% choice$description else NULL,
          tags$input(
            id = input_id_safe,
            type = "radio",
            name = input_id,
            value = value,
            checked = if (enabled && identical(value, selected)) "checked" else NULL,
            disabled = if (!enabled) "disabled" else NULL,
            `aria-disabled` = if (!enabled) "true" else NULL
          ),
          tags$span(
            class = "aq-choice-explainer-copy",
            tags$strong(choice$title),
            tags$p(choice$description),
            if (isTRUE(choice$recommended %||% FALSE) && enabled) ui_status_badge("Recommended", status = "success") else NULL,
            if (!enabled) ui_status_badge("Unavailable", status = "warning") else NULL,
            if (!enabled && nzchar(choice$unavailable_reason %||% "")) tags$p(class = "aq-choice-unavailable-reason", choice$unavailable_reason) else NULL
          )
        )
      })
    )
  )
}

ui_control_group <- function(title = NULL, ..., description = NULL) {
  tags$section(
    class = "aq-control-group",
    if (!is.null(title)) tags$h3(class = "aq-control-group-title", title),
    if (!is.null(description)) tags$p(class = "aq-control-group-description", description),
    tags$div(class = "aq-control-group-body", ...)
  )
}

ui_preview_panel <- function(title = "Preview", ..., height = NULL) {
  style <- if (!is.null(height)) paste0("min-height:", height, ";") else NULL

  ui_card(
    title = title,
    tags$div(class = "aq-preview-panel", style = style, ...)
  )
}

ui_code_panel <- function(title = "Generated Code", ..., collapsed = TRUE) {
  content <- tags$div(class = "aq-code-panel-body", ...)

  if (isTRUE(collapsed)) {
    return(tags$details(
      class = "aq-code-panel",
      tags$summary(class = "aq-code-panel-title", title),
      content
    ))
  }

  tags$section(
    class = "aq-code-panel",
    tags$h3(class = "aq-code-panel-title", title),
    content
  )
}

qa_ui_consistency <- function() {
  read_file <- function(path) {
    if (!file.exists(path)) {
      return(character())
    }
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }
  has_patterns <- function(patterns, text) {
    all(vapply(patterns, function(pattern) grepl(pattern, text, fixed = TRUE), logical(1)))
  }

  css <- read_file(file.path("www", "app.css"))
  project_page <- read_file(file.path("R", "page_project.R"))
  data_page <- read_file(file.path("R", "page_data.R"))
  plot_builder_page <- read_file(file.path("R", "page_plot_builder.R"))
  workflow_page <- read_file(file.path("R", "page_workflow.R"))
  analysis_modules_page <- read_file(file.path("R", "page_analysis_modules.R"))
  artifact_library_page <- read_file(file.path("R", "page_artifact_library.R"))
  layouts_page <- read_file(file.path("R", "page_layouts.R"))
  export_page <- read_file(file.path("R", "page_export.R"))
  app_ui <- read_file(file.path("R", "app_ui.R"))
  ui_components <- read_file(file.path("R", "ui_components.R"))
  table_theme <- read_file(file.path("R", "table_theme.R"))
  page_files <- list.files("R", pattern = "^page_.*\\.R$", full.names = TRUE)
  page_text <- paste(vapply(page_files, read_file, character(1)), collapse = "\n")
  component_names <- c(
    "ui_page",
    "ui_object_spine",
    "ui_card",
    "ui_empty_state",
    "ui_status_badge",
    "ui_action_bar",
    "ui_workspace_grid",
    "ui_split_panel",
    "ui_stat_tile",
    "ui_callout",
    "ui_progress_steps",
    "ui_artifact_preview_card",
    "ui_collector_status_panel",
    "ui_disclosure",
    "ui_activity_list",
    "ui_loading_state",
    "ui_theme_switcher",
    "ui_quality_panel",
    "ui_ai_readiness_panel",
    "ui_artifact_studio_card",
    "ui_artifact_filmstrip"
  )

  data.table::data.table(
    check = c(
      "shared_layout_components",
      "workstation_primitives",
      "consistent_spacing_tokens",
      "consistent_button_placement",
      "progressive_disclosure",
      "project_workspace_home",
      "artifact_presentation",
      "collector_visibility",
      "render_target_visibility",
      "workflow_consistency",
      "empty_states",
      "responsive_layout",
      "dark_first_shell",
      "app_branding",
      "workspace_utility_shell",
      "theme_switcher",
      "cyberpunk_theme_tokens",
      "dark_first_tokens",
      "data_workspace_page",
      "plot_builder_workspace_page",
      "layout_studio_page",
      "artifact_studio_mode",
      "analysis_module_code_panel",
      "export_report_context",
      "quality_ai_primitives",
      "dark_form_control_styling",
      "themed_numeric_spinners",
      "dark_selectize_dropdown_styling",
      "themed_selectize_scrollbars",
      "themed_app_scrollbars",
      "dark_button_styling",
      "dark_table_fallback_styling",
      "table_overflow_containment",
      "dark_reactable_styling",
      "no_raw_shiny_table_outputs",
      "dark_auto_table_theme",
      "user_friendly_module_labels",
      "user_friendly_plot_control_labels",
      "control_spacing_contract",
      "user_friendly_status_labels"
    ),
    status = c(
      if (all(vapply(component_names, function(name) exists(name, envir = environment(), mode = "function"), logical(1)))) "success" else "error",
      if (has_patterns(c(".aq-object-spine", ".aq-action-bar", ".aq-split-panel", ".aq-callout", ".aq-progress-steps", ".aq-artifact-preview-card"), css)) "success" else "error",
      if (has_patterns(c("--aq-radius", "--aq-border", "--aq-surface", "--aq-space-4", ".aq-workspace-grid", ".aq-stat-grid"), css)) "success" else "error",
      if (grepl("aq-section-actions", css, fixed = TRUE) && grepl("actions = ui_action_row", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("ui_disclosure", project_page, fixed = TRUE) && grepl(".aq-disclosure", css, fixed = TRUE)) "success" else "error",
      if (grepl("Project Workspace", project_page, fixed = TRUE) && grepl("project_persistent_context", project_page, fixed = TRUE) && grepl("project_chapter_surface", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("Project Location", project_page, fixed = TRUE) && grepl("Evidence", project_page, fixed = TRUE) && grepl("Next Action", project_page, fixed = TRUE)) "success" else "error",
      if (grepl("project_collector_summary", project_page, fixed = TRUE) && (grepl("Project Evidence Memory", workflow_page, fixed = TRUE) || grepl("Project Artifact Collector", workflow_page, fixed = TRUE))) "success" else "error",
      if (grepl("render_target", workflow_page, fixed = TRUE) || grepl("render target", app_ui, ignore.case = TRUE)) "success" else "warning",
      if (grepl("workflow_stage_registry", workflow_page, fixed = TRUE) && grepl("workflow_stage_card", workflow_page, fixed = TRUE)) "success" else "error",
      if (grepl("ui_empty_state", project_page, fixed = TRUE) && grepl("ui_empty_state", workflow_page, fixed = TRUE)) "success" else "error",
      if (grepl("@media (max-width: 900px)", css, fixed = TRUE) && grepl("aq-workspace-grid-main-sidebar", css, fixed = TRUE)) "success" else "error",
      if (grepl("theme = \"dark\"", app_ui, fixed = TRUE) && grepl("ui_app_shell <- function(..., theme = \"dark\")", ui_components, fixed = TRUE)) "success" else "error",
      if (has_patterns(c("aq-brand-lockup", "aq-brand-mark", "analytics-workstation-mark.svg"), app_ui) &&
          has_patterns(c(".aq-brand-lockup", ".aq-brand-mark", ".aq-brand-name", ".aq-brand-subtitle"), css) &&
          file.exists(file.path("www", "brand", "analytics-workstation-mark.svg"))) "success" else "error",
      if (has_patterns(c("aq-shell-primary-nav", "Project", "Data", "Analysis", "Evidence", "Decisions", "Delivery", "AI Runtime", "Knowledge Library", "Code Runner", "Product Experience"), app_ui) &&
          has_patterns(c("shell_nav_target", "aq-main-tabset", "aq-shell-menu", "aq-shell-utility-link"), app_ui) &&
          has_patterns(c(".aq-shell-primary-nav", ".aq-workstation-utilities", ".aq-main-tabset > .tabbable > .nav-tabs", "display: none"), css)) "success" else "error",
      if (has_patterns(c("ui_theme_switcher", "aq-theme-switcher", "aq-theme-select", "window.aqApplyTheme", "localStorage.setItem('aq.theme'"), ui_components) &&
          has_patterns(c("aq-workstation-header", "aq-workstation-utilities", "ui_theme_switcher(theme = \"dark\")"), app_ui)) "success" else "error",
      if (has_patterns(c("body.aq-theme-cyberpunk", "#00f5ff", "#ff2bd6", ".aq-theme-switcher"), css) && has_patterns(c("cyberpunk", "reactable_theme_cyberpunk"), table_theme)) "success" else "error",
      if (has_patterns(c("body.aq-theme-dark", "body:not(.aq-theme-light):not(.aq-theme-pimp):not(.aq-theme-cyberpunk)", "--aq-bg-base", "--aq-focus-ring", "--aq-secondary"), css)) "success" else "error",
      if (has_patterns(c("Data Workspace", "supported_data_accept_types", "aq-data-workbench", "aq-data-loader-band", "aq-data-preview-wide"), data_page)) "success" else "error",
      if (grepl("Plot Builder", plot_builder_page, fixed = TRUE) &&
          grepl("ui_preview_panel", plot_builder_page, fixed = TRUE) &&
          grepl("ui_code_panel", plot_builder_page, fixed = TRUE) &&
          grepl("aq-plot-builder-primary-actions", plot_builder_page, fixed = TRUE) &&
          grepl(".aq-plot-builder-primary-actions", css, fixed = TRUE) &&
          grepl("aq-plot-mapping-controls", plot_builder_page, fixed = TRUE) &&
          grepl(".aq-plot-mapping-controls", css, fixed = TRUE)) "success" else "error",
      if (grepl("Layout Studio", layouts_page, fixed = TRUE) && grepl("aq-layout-studio", layouts_page, fixed = TRUE) && grepl("ui_code_panel", layouts_page, fixed = TRUE)) "success" else "error",
      if (grepl("Artifact Studio", artifact_library_page, fixed = TRUE) && grepl("ui_artifact_filmstrip", artifact_library_page, fixed = TRUE) && grepl("artifact_studio_overview", artifact_library_page, fixed = TRUE)) "success" else "error",
      if (grepl("ui_code_panel", analysis_modules_page, fixed = TRUE)) "success" else "error",
      if (grepl("subtitle = \"Write human-facing report outputs", export_page, fixed = TRUE)) "success" else "error",
      if (has_patterns(c(".aq-loading-state", ".aq-quality-panel", ".aq-ai-readiness-panel"), css) && grepl("ui_ai_readiness_panel", ui_components, fixed = TRUE)) "success" else "error",
      if (has_patterns(c(".aq-app-shell input", ".aq-app-shell textarea", ".aq-app-shell select", ".aq-app-shell .form-control:focus", "--aq-input-bg"), css)) "success" else "error",
      if (has_patterns(c("input[type=\"number\"]", "color-scheme: dark", "::-webkit-inner-spin-button", "::-webkit-outer-spin-button"), css)) "success" else "error",
      if (has_patterns(c(".aq-app-shell .selectize-input", ".aq-app-shell .selectize-dropdown", ".aq-app-shell .selectize-dropdown .active", ".aq-app-shell .selectize-control.multi"), css)) "success" else "error",
      if (has_patterns(c(".aq-app-shell .selectize-dropdown-content", "::-webkit-scrollbar-thumb", "scrollbar-color"), css)) "success" else "error",
      if (has_patterns(c(".aq-app-shell ::-webkit-scrollbar-thumb", ".aq-app-shell ::-webkit-scrollbar-thumb:horizontal", ".aq-app-shell ::-webkit-scrollbar-corner", "scrollbar-width: thin"), css)) "success" else "error",
      if (has_patterns(c(".aq-app-shell .btn", ".aq-app-shell .btn-primary", ".aq-app-shell .btn-success", ".aq-app-shell .btn-danger"), css)) "success" else "error",
      if (has_patterns(c(".aq-app-shell table", ".aq-app-shell .shiny-html-output table", ".aq-html-table tbody tr:nth-child(even)", ".aq-app-shell .table-hover"), css)) "success" else "error",
      if (has_patterns(c(".aq-table-wrapper", "overflow-x: auto", "width: max-content", ".aq-card-body", "min-width: 0"), css)) "success" else "error",
      if (has_patterns(c(".aq-app-shell .ReactTable", ".aq-app-shell .rt-table", ".aq-app-shell .dataTables_wrapper", ".aq-app-shell table.dataTable"), css) && has_patterns(c("backgroundColor = \"#0B1326\"", "filterInputStyle", "selectStyle"), table_theme)) "success" else "error",
      if (!grepl("tableOutput\\(|renderTable\\(", page_text)) "success" else "error",
      if (grepl("return(getOption(\"aq.theme\", \"dark\"))", table_theme, fixed = TRUE)) "success" else "error",
      if (!any(grepl("^AutoQuant\\b|autoquant_", vapply(get_module_registry(), function(module) module$label %||% "", character(1))))) "success" else "error",
      if (all(c("Plot Type", "X-Axis Column", "Y-Axis Column", "Color / Group Column", "Correlation Columns", "Aggregation Method", "Chart Title", "Rotate X-Axis Labels") %in% c(
        "Plot Type",
        vapply(c("XVar", "YVar", "GroupVar", "CorrVars"), mapping_label, character(1)),
        vapply(option_registry, function(option) option$label %||% "", character(1))
      ))) "success" else "error",
      if (has_patterns(c(
        ".aq-control-group-title + .aq-control-group-body",
        ".aq-control-group-body",
        ".aq-action-row + .shiny-html-output",
        ".aq-card-body > .form-group + .aq-control-group",
        ".aq-card-body > .aq-control-group + .aq-plot-builder-primary-actions"
      ), css)) "success" else "error",
      if (identical(ui_status_label("not_created"), "Not Created") &&
          identical(ui_status_label("workspace_ready"), "Ready") &&
          identical(ui_display_label("llm_docx"), "LLM DOCX")) "success" else "error"
    ),
    message = c(
      "Shared page/card/stat/disclosure/activity components exist.",
      "Custom workstation primitives are defined outside stock Shiny widgets.",
      "Core spacing, border, surface, grid, and stat classes are defined.",
      "Page actions use shared section action placement.",
      "Progressive disclosure is available and used.",
      "Project page is now the Project Workspace.",
      "Workspace surfaces artifact and report-plan counts.",
      "Collector status is visible in Project and Workflow surfaces.",
      "Render target visibility remains primarily in workflow/collector surfaces.",
      "Workflow registry and stage cards remain the workflow backbone.",
      "Empty states are present on workspace and workflow pages.",
      "Responsive workspace layouts are defined.",
      "The app shell defaults to the dark workstation theme.",
      "The app shell uses the Analytics Workstation brand mark and wordmark.",
      "The shell exposes static workspaces with fixed right-side utilities while preserving hidden tab routing.",
      "The app shell exposes a persistent selectable theme switcher.",
      "Cyberpunk theme tokens and table theme support are available.",
      "Dark-first tokens include base surfaces, focus states, and secondary accent.",
      "Data page uses a top dataset loader/status band with a full-width preview.",
      "Plot Builder uses shared preview/code panels and keeps primary plot actions sticky.",
      "Layout Studio uses a dedicated composition stage, disclosure, preview, and code panels.",
      "Artifact Studio surfaces evidence gallery, inspector, and filmstrip.",
      "Analysis Modules uses the shared code panel.",
      "Export page is framed as a report/export workspace.",
      "Quality, loading, and AI readiness primitives are present and used.",
      "Text, numeric, select, textarea, and focus states use workstation tokens.",
      "Numeric input spinner controls inherit theme-aware browser chrome where supported.",
      "Selectize inputs and dropdown menus use dark workstation styling.",
      "Long selectize dropdowns use themed scrollbars instead of default browser chrome.",
      "Scrollable app surfaces use theme-aware scrollbar styling.",
      "Action and download buttons use dark workstation styling.",
      "Plain HTML, Shiny fallback, and striped/hover table styles use dark tokens.",
      "Tables are constrained to their parent panel and scroll horizontally when needed.",
      "Reactable and DT/DataTables selectors have dark styling and the shared reactable helper is dark.",
      "Page UI/server files use themed table rendering instead of raw Shiny table outputs.",
      "The automatic table theme resolves to dark unless explicitly overridden.",
      "Module registry labels are user-facing names, not implementation package ids.",
      "Plot Builder controls use user-facing labels instead of raw AutoPlots argument names.",
      "Control groups and action rows reserve spacing before adjacent labels and outputs.",
      "Internal status ids have user-friendly display labels."
    )
  )
}
