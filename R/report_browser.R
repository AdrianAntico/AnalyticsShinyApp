report_browser_component_registry <- function() {
  renderers <- list(
    title = report_browser_render_title,
    orientation = report_browser_render_orientation,
    executive_summary = report_browser_render_executive_summary,
    finding = report_browser_render_finding_component,
    recommendation = report_browser_render_recommendation,
    metric_summary = report_browser_render_metric_summary,
    narrative = report_browser_render_narrative,
    visualization = report_browser_render_visualization,
    table = report_browser_render_table,
    diagnostic = report_browser_render_diagnostic,
    methodology = report_browser_render_methodology,
    evidence_link = report_browser_render_evidence_link,
    technical_appendix = report_browser_render_technical_appendix,
    unknown = report_browser_render_unknown
  )
  missing <- setdiff(report_component_types, names(renderers))
  if (length(missing)) {
    stop("Missing report browser renderer(s): ", paste(missing, collapse = ", "), call. = FALSE)
  }
  renderers
}

report_browser_safe_anchor <- function(prefix, value) {
  report_safe_id(prefix, value %||% prefix)
}

report_browser_text <- function(value, fallback = "Not supplied") {
  if (is.null(value) || !length(value)) {
    return(fallback)
  }
  text <- trimws(paste(as.character(value), collapse = " "))
  if (!nzchar(text) || identical(text, "NA")) fallback else text
}

report_browser_component_map <- function(report) {
  components <- report$components %||% list()
  ids <- vapply(components, function(component) component$component_id %||% "", character(1))
  names(components) <- ids
  components
}

report_browser_badge <- function(label, class = "neutral") {
  tags$span(class = .aq_class("aq-report-browser-badge", paste0("aq-report-browser-badge-", class)), label)
}

report_browser_key_values <- function(values) {
  if (is.null(values) || !length(values)) {
    return(tags$p(class = "aq-report-browser-muted", "No metadata supplied."))
  }
  tags$dl(
    class = "aq-report-browser-kv",
    lapply(names(values), function(name) {
      tagList(
        tags$dt(tools::toTitleCase(gsub("_", " ", name))),
        tags$dd(report_browser_text(values[[name]], "-"))
      )
    })
  )
}

report_browser_list <- function(values, empty = "None supplied.") {
  values <- values %||% character()
  if (!length(values)) {
    return(tags$p(class = "aq-report-browser-muted", empty))
  }
  tags$ul(class = "aq-report-browser-list", lapply(values, tags$li))
}

report_browser_component_shell <- function(component, ..., class = NULL, header = TRUE) {
  tags$article(
    id = report_browser_safe_anchor("component", component$component_id),
    class = .aq_class(
      "aq-report-browser-component",
      paste0("aq-report-browser-component-", component$component_type %||% "unknown"),
      paste0("aq-report-browser-importance-", component$importance %||% "recommended"),
      class
    ),
    if (isTRUE(header)) {
      tags$header(
        class = "aq-report-browser-component-header",
        tags$div(
          tags$p(class = "aq-report-browser-component-type", ui_display_label(component$component_type %||% "component")),
          tags$h4(component$title %||% ui_display_label(component$component_type %||% "Component"))
        ),
        tags$div(
          class = "aq-report-browser-component-badges",
          report_browser_badge(ui_display_label(component$importance %||% "recommended"), component$importance %||% "neutral")
        )
      )
    },
    tags$div(class = "aq-report-browser-component-body", ...)
  )
}

report_browser_render_title <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  tags$section(
    id = report_browser_safe_anchor("component", component$component_id),
    class = "aq-report-browser-title-block",
    tags$p(class = "aq-report-browser-eyebrow", ui_display_label(report$report_type %||% "Analytical Report")),
    tags$h2(payload$title %||% component$title %||% report$title %||% "Analytical Report"),
    if (!is.null(payload$subtitle)) tags$p(class = "aq-report-browser-lede", payload$subtitle),
    tags$div(
      class = "aq-report-browser-title-meta",
      report_browser_badge(ui_display_label(report$purpose %||% "review"), "info"),
      report_browser_badge(paste("Mode:", ui_display_label(report$mode %||% "automatic")), "neutral")
    )
  )
}

report_browser_render_orientation <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    tags$p(class = "aq-report-browser-lede", report_browser_text(payload$question, "No guiding question supplied.")),
    report_browser_key_values(list(
      scope = payload$scope %||% "Not supplied",
      audience = payload$audience %||% (report$audience$primary %||% "analyst")
    ))
  )
}

report_browser_render_executive_summary <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    tags$p(class = "aq-report-browser-summary-text", report_browser_text(payload$summary, "No summary supplied.")),
    tags$div(
      class = "aq-report-browser-callout-row",
      tags$div(
        class = "aq-report-browser-callout",
        tags$span("Confidence"),
        tags$strong(report_browser_text(payload$confidence, "Not assessed"))
      ),
      tags$div(
        class = "aq-report-browser-callout",
        tags$span("Next action"),
        tags$strong(report_browser_text(payload$next_action, "Review the report evidence."))
      )
    )
  )
}

report_browser_render_finding <- function(finding) {
  tags$article(
    id = report_browser_safe_anchor("finding", finding$finding_id),
    class = .aq_class("aq-report-browser-finding", paste0("aq-report-browser-importance-", finding$importance %||% "recommended")),
    tags$header(
      class = "aq-report-browser-finding-header",
      tags$div(
        tags$p(class = "aq-report-browser-component-type", "Finding"),
        tags$h4(finding$title %||% "Analytical Finding")
      ),
      tags$div(
        class = "aq-report-browser-component-badges",
        report_browser_badge(ui_display_label(finding$confidence %||% "not_assessed"), "info"),
        report_browser_badge(ui_display_label(finding$importance %||% "recommended"), finding$importance %||% "neutral")
      )
    ),
    tags$p(class = "aq-report-browser-finding-statement", report_browser_text(finding$statement)),
    tags$div(
      class = "aq-report-browser-link-strip",
      tags$span("Evidence"),
      if (length(finding$evidence_ids %||% character())) {
        lapply(finding$evidence_ids, function(id) tags$a(href = paste0("#evidence-", id), id))
      } else {
        tags$em("No evidence links")
      }
    ),
    tags$div(
      class = "aq-report-browser-link-strip",
      tags$span("Recommendations"),
      if (length(finding$recommendation_ids %||% character())) {
        lapply(finding$recommendation_ids, function(id) tags$a(href = paste0("#recommendation-", id), id))
      } else {
        tags$em("No linked recommendations")
      }
    )
  )
}

report_browser_render_finding_component <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    tags$p(class = "aq-report-browser-finding-statement", report_browser_text(payload$statement)),
    report_browser_key_values(list(
      support = payload$support %||% "Not supplied",
      caveat = payload$caveat %||% "Not supplied",
      confidence = payload$confidence %||% "not_assessed"
    ))
  )
}

report_browser_render_recommendation <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    class = "aq-report-browser-recommendation",
    tags$p(class = "aq-report-browser-summary-text", report_browser_text(payload$action, "No action supplied.")),
    report_browser_key_values(list(
      rationale = payload$rationale %||% "Not supplied",
      risk = payload$risk %||% "Not supplied"
    ))
  )
}

report_browser_render_metric_summary <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  metrics <- payload$metrics %||% list()
  report_browser_component_shell(
    component,
    tags$div(
      class = "aq-report-browser-metric-grid",
      lapply(names(metrics), function(name) {
        tags$div(
          class = "aq-report-browser-metric",
          tags$span(tools::toTitleCase(gsub("_", " ", name))),
          tags$strong(report_browser_text(metrics[[name]], "-"))
        )
      })
    )
  )
}

report_browser_render_narrative <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    tags$p(class = "aq-report-browser-prose", report_browser_text(payload$text, "No narrative supplied."))
  )
}

report_browser_render_visual_payload <- function(visual) {
  if (is.null(visual)) {
    return(NULL)
  }
  if (inherits(visual, "shiny.tag") || inherits(visual, "shiny.tag.list")) {
    return(visual)
  }
  if (inherits(visual, "htmlwidget")) {
    return(htmltools::as.tags(visual))
  }
  if (is.character(visual) && length(visual) == 1L && grepl("^\\s*<", visual)) {
    return(htmltools::HTML(visual))
  }
  NULL
}

report_browser_visual_mode <- function(visual) {
  if (is.null(visual)) {
    return("semantic_reference")
  }
  if (inherits(visual, "htmlwidget")) {
    return("interactive_widget")
  }
  if (inherits(visual, "shiny.tag") || inherits(visual, "shiny.tag.list")) {
    return("static_inline_visual")
  }
  if (is.character(visual) && length(visual) == 1L && grepl("^\\s*<", visual)) {
    return("static_html_fragment")
  }
  "unsupported_visual_payload"
}

report_browser_visual_interaction_label <- function(mode, spec, component) {
  if (identical(mode, "interactive_widget")) {
    return(paste(spec$interaction_capability %||% component$interaction_descriptor$capabilities %||% "interactive widget", collapse = ", "))
  }
  if (identical(mode, "static_inline_visual") || identical(mode, "static_html_fragment")) {
    return("static inline visual")
  }
  if (identical(mode, "semantic_reference")) {
    return("semantic reference only")
  }
  "unsupported visual payload"
}

report_browser_visual_fallback_label <- function(mode, spec, component) {
  fallback <- spec$export_fallback %||% component$static_fallback %||% list(strategy = "static_placeholder")
  if (identical(mode, "interactive_widget")) {
    return(fallback$strategy %||% "htmlwidget")
  }
  if (identical(mode, "static_inline_visual") || identical(mode, "static_html_fragment")) {
    return("inline_static_visual")
  }
  fallback$strategy %||% "static_placeholder"
}

report_browser_visual_placeholder <- function(component, payload, spec) {
  tags$div(
    class = "aq-report-browser-visual-placeholder",
    tags$span(class = "aq-report-browser-visual-glyph", ""),
    tags$strong(component$title %||% "Visualization"),
    tags$p(report_browser_text(payload$caption %||% spec$purpose, "Semantic visualization reference."))
  )
}

report_browser_render_visualization <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  spec <- payload$specification %||% list()
  source_id <- spec$source_artifact_id %||% component$metadata$source_artifact_id %||% payload$plot_ref %||% payload$visual_ref
  visual_payload <- payload$visual %||% component$metadata$visual
  visual_mode <- report_browser_visual_mode(visual_payload)
  visual <- report_browser_render_visual_payload(visual_payload)
  report_browser_component_shell(
    component,
    class = "aq-report-browser-visualization",
    if (is.null(visual)) report_browser_visual_placeholder(component, payload, spec) else tags$div(class = "aq-report-browser-visual-render", visual),
    report_browser_key_values(list(
      source_artifact = source_id %||% "Not linked",
      interaction = report_browser_visual_interaction_label(visual_mode, spec, component),
      fallback = report_browser_visual_fallback_label(visual_mode, spec, component)
    ))
  )
}

report_browser_render_table_preview <- function(data, max_rows = 8L, max_cols = 6L) {
  if (!is.data.frame(data) || !nrow(data)) {
    return(ui_empty_state("No table preview available.", "The semantic table component did not include inline preview rows."))
  }
  rows <- utils::head(data, max_rows)
  cols <- utils::head(names(rows), max_cols)
  tags$div(
    class = "aq-table-wrapper aq-report-browser-table-preview",
    tags$table(
      class = "aq-html-table aq-report-browser-table",
      tags$thead(tags$tr(lapply(cols, tags$th))),
      tags$tbody(lapply(seq_len(nrow(rows)), function(row_index) {
        tags$tr(lapply(cols, function(col) tags$td(report_browser_text(rows[[col]][[row_index]], ""))))
      }))
    )
  )
}

report_browser_render_table <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  contract <- payload$table_contract %||% list()
  report_browser_component_shell(
    component,
    report_browser_render_table_preview(payload$data),
    tags$div(
      class = "aq-report-browser-table-contract",
      report_browser_badge(paste("Density:", contract$density %||% "adaptive"), "info"),
      report_browser_badge(paste("Rows:", contract$row_height %||% "automatic"), "neutral"),
      report_browser_badge(paste("Pinned:", if (length(contract$pinned_columns %||% character())) paste(contract$pinned_columns, collapse = ", ") else "none"), "neutral"),
      report_browser_badge(paste("Expandable:", if (isTRUE(contract$expandable_rows)) "planned" else "no"), "neutral")
    )
  )
}

report_browser_render_diagnostic <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  severity <- payload$severity %||% if (identical(payload$status, "success")) "success" else "warning"
  report_browser_component_shell(
    component,
    report_browser_badge(ui_display_label(payload$status %||% "not_checked"), severity),
    report_browser_list(as.character(payload$messages %||% character()), "No diagnostics supplied.")
  )
}

report_browser_render_methodology <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    tags$p(class = "aq-report-browser-prose", report_browser_text(payload$method, "No method supplied.")),
    tags$div(class = "aq-report-browser-two-list", tags$div(tags$strong("Assumptions"), report_browser_list(payload$assumptions)), tags$div(tags$strong("Limitations"), report_browser_list(payload$limitations)))
  )
}

report_browser_render_evidence_link <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    class = "aq-report-browser-evidence-link",
    tags$div(
      id = paste0("evidence-", payload$artifact_id %||% component$component_id),
      class = "aq-report-browser-evidence-object",
      tags$strong(payload$artifact_id %||% "Unlinked artifact"),
      tags$span(paste(ui_display_label(payload$relationship %||% "supports"), "as", ui_display_label(payload$role %||% "evidence")))
    )
  )
}

report_browser_render_technical_appendix <- function(component, report = NULL, registry = NULL) {
  payload <- component$payload %||% list()
  report_browser_component_shell(
    component,
    tags$pre(class = "aq-report-browser-appendix", report_browser_text(payload$content, "No appendix content supplied."))
  )
}

report_browser_render_unknown <- function(component, report = NULL, registry = NULL) {
  report_browser_component_shell(
    component,
    tags$p(class = "aq-report-browser-muted", "No renderer is registered for this component type.")
  )
}

render_report_component <- function(component, report = NULL, registry = report_browser_component_registry()) {
  if (!inherits(component, "report_component")) {
    return(tags$article(class = "aq-report-browser-component aq-report-browser-invalid", "Invalid report component."))
  }
  renderer <- registry[[component$component_type %||% "unknown"]] %||% registry$unknown
  renderer(component, report = report, registry = registry)
}

render_component <- render_report_component

render_report_section <- function(section, report, registry = report_browser_component_registry()) {
  components <- report_browser_component_map(report)
  component_ids <- section$components %||% character()
  section_components <- components[component_ids]
  section_components <- section_components[!vapply(section_components, is.null, logical(1))]
  default_open <- !identical(section$default_state %||% "expanded", "collapsed")

  tags$details(
    id = report_browser_safe_anchor("section", section$section_id),
    class = .aq_class("aq-report-browser-section", paste0("aq-report-browser-section-", section$priority %||% "recommended")),
    open = if (isTRUE(default_open)) "open" else NULL,
    tags$summary(
      class = "aq-report-browser-section-summary",
      tags$span(section$title %||% ui_display_label(section$section_id %||% "Section")),
      tags$small(section$purpose %||% paste(length(section_components), "component(s)"))
    ),
    tags$div(
      class = "aq-report-browser-section-body",
      if (length(section_components)) {
        lapply(section_components, render_report_component, report = report, registry = registry)
      } else {
        ui_empty_state("No report material in this section.", "The section is valid, but no readable material is attached yet.")
      }
    )
  )
}

render_section <- render_report_section

render_report_browser_navigation <- function(report) {
  sections <- report$sections %||% list()
  findings <- report$findings %||% list()
  tags$aside(
    class = "aq-report-browser-nav",
    tags$strong("Report"),
    tags$a(href = "#report-browser-top", report$title %||% "Analytical Report"),
    tags$strong("Sections"),
    lapply(sections, function(section) {
      tags$a(href = paste0("#", report_browser_safe_anchor("section", section$section_id)), section$title %||% section$section_id)
    }),
    tags$strong("Findings"),
    if (length(findings)) {
      lapply(findings, function(finding) {
        tags$a(href = paste0("#", report_browser_safe_anchor("finding", finding$finding_id)), finding$title %||% finding$finding_id)
      })
    } else {
      tags$span(class = "aq-report-browser-muted", "No findings")
    }
  )
}

render_report_browser <- function(report_contract, registry = report_browser_component_registry()) {
  if (!inherits(report_contract, "report_contract")) {
    return(tags$section(
      class = "aq-report-browser aq-report-browser-invalid",
      ui_empty_state("Invalid report record.", "The interactive browser can only render validated report records.")
    ))
  }
  validation <- validate_report(report_contract)
  if (!identical(validation$status, "success")) {
    return(tags$section(
      class = "aq-report-browser aq-report-browser-invalid",
      ui_empty_state("Report validation failed.", paste(validation$errors, collapse = " | "))
    ))
  }

  profile <- report_contract$presentation_profile %||% create_presentation_profile()
  density <- profile$density %||% "balanced"
  findings <- report_contract$findings %||% list()
  sections <- report_contract$sections %||% list()

  tags$section(
    id = "report-browser-top",
    class = .aq_class("aq-report-browser", paste0("aq-report-browser-density-", density)),
    render_report_browser_navigation(report_contract),
    tags$main(
      class = "aq-report-browser-content",
      tags$header(
        class = "aq-report-browser-header",
        tags$p(class = "aq-report-browser-eyebrow", "Interactive Report Browser"),
        tags$h2(report_contract$title %||% "Analytical Report"),
        tags$p(class = "aq-report-browser-lede", "Native workstation rendering from a validated report record."),
        tags$div(
          class = "aq-report-browser-title-meta",
          report_browser_badge(paste("Profile:", profile$profile_id %||% "default"), "info"),
          report_browser_badge(paste("Density:", ui_display_label(density)), "neutral"),
          report_browser_badge(paste("Capabilities:", length(report_contract$capabilities %||% character())), "neutral")
        )
      ),
      tags$section(
        class = "aq-report-browser-findings",
        tags$header(
          class = "aq-report-browser-strip-header",
          tags$p(class = "aq-report-browser-eyebrow", "Findings"),
          tags$h3("What the report asserts")
        ),
        if (length(findings)) {
          lapply(findings, report_browser_render_finding)
        } else {
          ui_empty_state("No findings supplied.", "The report still renders, but no formal findings are attached yet.")
        }
      ),
      tags$section(
        class = "aq-report-browser-sections",
        tags$header(
          class = "aq-report-browser-strip-header",
          tags$p(class = "aq-report-browser-eyebrow", "Sections"),
          tags$h3("Report body")
        ),
        if (length(sections)) {
          lapply(sections, render_report_section, report = report_contract, registry = registry)
        } else {
          ui_empty_state("No report sections supplied.", "A valid interactive report needs at least one section.")
        }
      )
    )
  )
}

render_report <- render_report_browser

report_browser_demo_observed_predicted_widget <- function() {
  if (!requireNamespace("echarts4r", quietly = TRUE)) {
    return(NULL)
  }
  points <- data.frame(
    observed = c(18, 28, 37, 45, 53, 63, 70, 80, 88),
    predicted = c(21, 26, 39, 43, 57, 60, 73, 77, 91)
  )
  points$ideal <- points$observed
  chart <- points |>
    echarts4r::e_charts(observed) |>
    echarts4r::e_scatter(
      predicted,
      symbol_size = 16,
      name = "Prediction pairs",
      itemStyle = list(color = "#e8f1ff", borderColor = "#48e0c2", borderWidth = 3)
    ) |>
    echarts4r::e_line(
      ideal,
      symbol = "none",
      name = "Ideal fit",
      lineStyle = list(type = "dashed", color = "rgba(234, 242, 255, 0.45)", width = 2)
    ) |>
    echarts4r::e_title(
      text = "Observed vs Predicted",
      left = "center",
      textStyle = list(color = "#e8f1ff", fontWeight = 800, fontSize = 22)
    ) |>
    echarts4r::e_tooltip(trigger = "item") |>
    echarts4r::e_legend(
      bottom = 10,
      textStyle = list(color = "#9db7df")
    ) |>
    echarts4r::e_x_axis(
      name = "Observed",
      nameLocation = "middle",
      nameGap = 34,
      axisLine = list(lineStyle = list(color = "#9db7df")),
      splitLine = list(lineStyle = list(color = "rgba(132, 163, 213, 0.18)"))
    ) |>
    echarts4r::e_y_axis(
      name = "Predicted",
      nameLocation = "middle",
      nameGap = 42,
      axisLine = list(lineStyle = list(color = "#9db7df")),
      splitLine = list(lineStyle = list(color = "rgba(132, 163, 213, 0.18)"))
    ) |>
    echarts4r::e_grid(left = "8%", right = "5%", top = "16%", bottom = "18%")
  chart$x$theme <- NULL
  chart
}

report_browser_demo_observed_predicted_static <- function() {
  points <- data.frame(
    observed = c(18, 28, 37, 45, 53, 63, 70, 80, 88),
    predicted = c(21, 26, 39, 43, 57, 60, 73, 77, 91)
  )
  x <- 48 + points$observed * 4.2
  y <- 420 - points$predicted * 3.6
  tags$svg(
    class = "aq-report-browser-demo-plot",
    viewBox = "0 0 520 440",
    role = "img",
    `aria-label` = "Observed versus predicted diagnostic plot",
    tags$defs(
      tags$linearGradient(
        id = "reportDemoPlotGradient",
        x1 = "0%", y1 = "0%", x2 = "100%", y2 = "100%",
        tags$stop(offset = "0%", `stop-color` = "#61a8ff", `stop-opacity` = "0.95"),
        tags$stop(offset = "100%", `stop-color` = "#48e0c2", `stop-opacity` = "0.85")
      )
    ),
    tags$rect(x = 0, y = 0, width = 520, height = 440, rx = 18, fill = "rgba(11, 20, 38, 0.94)"),
    tags$g(
      stroke = "rgba(132, 163, 213, 0.22)",
      `stroke-width` = 1,
      lapply(seq(80, 400, by = 80), function(pos) {
        tagList(
          tags$line(x1 = 52, y1 = pos, x2 = 460, y2 = pos),
          tags$line(x1 = pos + 20, y1 = 40, x2 = pos + 20, y2 = 392)
        )
      })
    ),
    tags$line(x1 = 58, y1 = 374, x2 = 430, y2 = 54, stroke = "rgba(255,255,255,0.32)", `stroke-width` = 2, `stroke-dasharray` = "8 10"),
    tags$polyline(
      points = paste(paste(round(x), round(y), sep = ","), collapse = " "),
      fill = "none",
      stroke = "url(#reportDemoPlotGradient)",
      `stroke-width` = 4,
      `stroke-linecap` = "round",
      `stroke-linejoin` = "round"
    ),
    tags$g(
      fill = "#e8f1ff",
      stroke = "#48e0c2",
      `stroke-width` = 2,
      lapply(seq_along(x), function(i) tags$circle(cx = round(x[[i]]), cy = round(y[[i]]), r = 6))
    ),
    tags$text(x = 58, y = 410, fill = "#9db7df", `font-size` = 16, `font-weight` = 700, "Observed"),
    tags$text(x = 20, y = 60, fill = "#9db7df", `font-size` = 16, `font-weight` = 700, transform = "rotate(-90 20 60)", "Predicted"),
    tags$text(x = 58, y = 34, fill = "#e8f1ff", `font-size` = 20, `font-weight` = 800, "Observed vs Predicted")
  )
}

report_browser_demo_observed_predicted_visual <- function() {
  report_browser_demo_observed_predicted_widget() %||% report_browser_demo_observed_predicted_static()
}

report_browser_demo_artifacts <- function(prefix = "demo") {
  list(
    list(
      artifact_id = paste0(prefix, "_visual_observed_predicted"),
      title = "Observed vs Predicted",
      label = "Observed vs Predicted",
      artifact_type = "plot",
      section = "Prediction Diagnostics",
      source_module = prefix,
      status = "ready",
      object = report_browser_demo_observed_predicted_visual(),
      metadata = list(
        recommended_caption = "Predicted values should track observed values without systematic structure.",
        analytical_intent = "diagnostic",
        artifact_importance = "critical"
      )
    ),
    list(
      artifact_id = paste0(prefix, "_metrics"),
      title = "Model Metrics",
      label = "Model Metrics",
      artifact_type = "table",
      section = "Model Overview",
      source_module = prefix,
      status = "ready",
      metadata = list(
        recommended_caption = "Core performance metrics for report review.",
        analytical_intent = "comparison",
        artifact_importance = "critical",
        table_architecture = list(pinned_columns = "metric", grouped_rows = FALSE)
      ),
      content = data.frame(metric = c("RMSE", "MAE", "R Squared"), value = c(12.4, 8.7, 0.82), stringsAsFactors = FALSE)
    ),
    list(
      artifact_id = paste0(prefix, "_finding"),
      title = "Model Fit Finding",
      label = "Model Fit Finding",
      artifact_type = "text",
      section = "Model Overview",
      source_module = prefix,
      status = "ready",
      content = "The current model has usable fit for directional review, but residual diagnostics should be checked before decision use.",
      metadata = list(
        confidence = "source_supplied",
        artifact_importance = "recommended",
        quality_status = "ready"
      )
    ),
    list(
      artifact_id = paste0(prefix, "_recommendation"),
      title = "Review Residuals",
      label = "Review Residuals",
      artifact_type = "recommendation",
      section = "Recommendations",
      source_module = prefix,
      status = "ready",
      content = "Review residual structure before presenting model conclusions.",
      metadata = list(artifact_importance = "recommended")
    )
  )
}

report_browser_demo_reports <- function() {
  regression_result <- create_canonical_analysis_result(
    result_id = "demo_regression_result",
    analysis_id = "regression_model_insights",
    module_id = "autoquant_regression_model_insights",
    run_id = "demo_regression_run",
    metadata = list(module_run_id = "demo_regression_run")
  )
  shap_result <- create_canonical_analysis_result(
    result_id = "demo_shap_result",
    analysis_id = "shap_analysis",
    module_id = "autoquant_regression_shap_analysis",
    run_id = "demo_shap_run",
    metadata = list(module_run_id = "demo_shap_run", problem_type = "regression")
  )
  eda_result <- create_canonical_analysis_result(
    result_id = "demo_eda_result",
    analysis_id = "exploratory_data_analysis",
    module_id = "autoquant_eda",
    run_id = "demo_eda_run",
    metadata = list(module_run_id = "demo_eda_run")
  )
  list(
    Regression = build_regression_model_insights_report(regression_result, artifacts = report_browser_demo_artifacts("regression")),
    SHAP = build_shap_analysis_report(shap_result, artifacts = report_browser_demo_artifacts("shap")),
    EDA = build_eda_report(eda_result, artifacts = report_browser_demo_artifacts("eda"))
  )
}

qa_report_browser <- function() {
  registry <- report_browser_component_registry()
  reports <- report_browser_demo_reports()
  regression <- reports$Regression
  first_component <- regression$components[[1]]
  first_section <- regression$sections[[1]]
  rendered_component <- render_report_component(first_component, regression, registry)
  rendered_section <- render_report_section(first_section, regression, registry)
  rendered_report <- render_report_browser(regression, registry)
  rendered_html <- as.character(htmltools::renderTags(rendered_report)$html)
  malformed <- render_report_browser(list(title = "Malformed"))

  rows <- list(
    data.table::data.table(check = "registry covers component types", status = if (all(report_component_types %in% names(registry))) "success" else "error"),
    data.table::data.table(check = "component renderer returns html", status = if (inherits(rendered_component, "shiny.tag") || inherits(rendered_component, "shiny.tag.list")) "success" else "error"),
    data.table::data.table(check = "section renderer returns html", status = if (inherits(rendered_section, "shiny.tag") || inherits(rendered_section, "shiny.tag.list")) "success" else "error"),
    data.table::data.table(check = "report renderer returns html", status = if (inherits(rendered_report, "shiny.tag") || inherits(rendered_report, "shiny.tag.list")) "success" else "error"),
    data.table::data.table(check = "section navigation rendered", status = if (grepl("aq-report-browser-nav", rendered_html, fixed = TRUE) && grepl("section-", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "findings rendered prominently", status = if (grepl("aq-report-browser-findings", rendered_html, fixed = TRUE) && grepl("What the report asserts", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "visualization renders real payload", status = if (grepl("html-widget", rendered_html, fixed = TRUE) || grepl("echarts4r", rendered_html, fixed = TRUE) || grepl("aq-report-browser-demo-plot", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "demo visual uses echarts when available", status = if (!requireNamespace("echarts4r", quietly = TRUE) || inherits(report_browser_demo_observed_predicted_visual(), "htmlwidget")) "success" else "error"),
    data.table::data.table(check = "visual interaction metadata matches payload", status = if (grepl("interactive, tooltip", rendered_html, fixed = TRUE) || grepl("static inline visual", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "presentation profile class rendered", status = if (grepl("aq-report-browser-density-", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "malformed contract degrades gracefully", status = if (inherits(malformed, "shiny.tag") || inherits(malformed, "shiny.tag.list")) "success" else "error")
  )
  adapter_rows <- lapply(names(reports), function(name) {
    report <- reports[[name]]
    validation <- validate_report(report)
    rendered <- render_report_browser(report)
    data.table::data.table(
      check = paste("renders", name, "ReportContract"),
      status = if (identical(validation$status, "success") && (inherits(rendered, "shiny.tag") || inherits(rendered, "shiny.tag.list"))) "success" else "error"
    )
  })
  data.table::rbindlist(c(rows, adapter_rows), use.names = TRUE, fill = TRUE)
}
