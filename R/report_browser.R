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

report_browser_visual_output_id <- function(component) {
  id <- component$component_id %||% component$title %||% "visual"
  plot_service_output_id(id, prefix = "report_visual")
}

report_browser_render_visual_payload <- function(visual, component = NULL, output = NULL, session = NULL) {
  if (is.null(visual)) {
    return(NULL)
  }
  if (inherits(visual, "shiny.tag") || inherits(visual, "shiny.tag.list")) {
    return(visual)
  }
  if (inherits(visual, "htmlwidget")) {
    output_id <- report_browser_visual_output_id(component %||% list(component_id = "visual"))
    return(render_plot_service_widget(visual, output = output, session = session, output_id = output_id, height = "520px"))
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

report_browser_render_visualization <- function(component, report = NULL, registry = NULL, output = NULL, session = NULL) {
  payload <- component$payload %||% list()
  spec <- payload$specification %||% list()
  source_id <- spec$source_artifact_id %||% component$metadata$source_artifact_id %||% payload$plot_ref %||% payload$visual_ref
  visual_payload <- payload$visual %||% component$metadata$visual
  visual_mode <- report_browser_visual_mode(visual_payload)
  visual <- report_browser_render_visual_payload(visual_payload, component = component, output = output, session = session)
  provenance <- component$metadata$provenance_diagnostics %||% list()
  runtime_fallback <- component$metadata$fallback_status %||% provenance$fallback_path %||% "not reported"
  report_browser_component_shell(
    component,
    class = "aq-report-browser-visualization",
    if (is.null(visual)) report_browser_visual_placeholder(component, payload, spec) else tags$div(class = "aq-report-browser-visual-render", visual),
    report_browser_key_values(list(
      source_artifact = source_id %||% "Not linked",
      interaction = report_browser_visual_interaction_label(visual_mode, spec, component),
      runtime_fallback = runtime_fallback,
      export_fallback = report_browser_visual_fallback_label(visual_mode, spec, component)
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

render_report_component <- function(component, report = NULL, registry = report_browser_component_registry(), output = NULL, session = NULL) {
  if (!inherits(component, "report_component")) {
    return(tags$article(class = "aq-report-browser-component aq-report-browser-invalid", "Invalid report component."))
  }
  renderer <- registry[[component$component_type %||% "unknown"]] %||% registry$unknown
  renderer_args <- list(component = component, report = report, registry = registry)
  renderer_formals <- names(formals(renderer))
  if ("output" %in% renderer_formals) renderer_args$output <- output
  if ("session" %in% renderer_formals) renderer_args$session <- session
  do.call(renderer, renderer_args)
}

render_component <- render_report_component

render_report_section <- function(section, report, registry = report_browser_component_registry(), output = NULL, session = NULL) {
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
        lapply(section_components, render_report_component, report = report, registry = registry, output = output, session = session)
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

render_report_browser <- function(report_contract, registry = report_browser_component_registry(), output = NULL, session = NULL) {
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
          lapply(sections, render_report_section, report = report_contract, registry = registry, output = output, session = session)
        } else {
          ui_empty_state("No report sections supplied.", "A valid interactive report needs at least one section.")
        }
      )
    )
  )
}

render_report <- render_report_browser

report_browser_demo_observed_predicted_widget <- function() {
  if (!requireNamespace("AutoPlots", quietly = TRUE)) {
    return(NULL)
  }
  points <- data.frame(
    observed = c(18, 28, 37, 45, 53, 63, 70, 80, 88),
    predicted = c(21, 26, 39, 43, 57, 60, 73, 77, 91)
  )
  points$ideal <- points$observed
  chart <- AutoPlots::Scatter(
    dt = points,
    XVar = "observed",
    YVar = "predicted",
    SampleSize = nrow(points),
    Theme = "dark",
    MouseScroll = TRUE,
    ShowLabels = FALSE,
    AddGLM = FALSE,
    Height = NULL,
    Width = NULL,
    title.text = "Observed vs Predicted",
    title.Align = "center",
    title.top = 14,
    title.left = "center",
    title.padding = c(4, 4, 10, 4),
    title.itemGap = 6,
    title.textStyle.color = "#FFFFFF",
    title.textStyle.fontWeight = "bolder",
    title.textStyle.fontSize = 20,
    title.textStyle.textShadowColor = "#CE1141",
    title.textStyle.textShadowBlur = 14,
    title.textStyle.textShadowOffsetX = 0,
    title.textStyle.textShadowOffsetY = 0,
    title.subtextStyle.color = "#CE1141",
    title.subtextStyle.textShadowColor = "#CE1141",
    title.subtextStyle.textShadowBlur = 8,
    title.subtextStyle.textShadowOffsetX = 0,
    title.subtextStyle.textShadowOffsetY = 0,
    title.subtextStyle.fontWeight = "bold",
    xAxis.title = "Observed",
    xAxis.nameTextStyle.fontSize = 20,
    xAxis.nameTextStyle.color = "#FFFFFF",
    xAxis.nameTextStyle.textShadowColor = "#CE1141",
    xAxis.nameTextStyle.textShadowBlur = 8,
    xAxis.nameTextStyle.textShadowOffsetX = 0,
    xAxis.nameTextStyle.textShadowOffsetY = 0,
    xAxis.axisLabel.color = "#E8EEF7",
    xAxis.axisLabel.overflow = "truncate",
    yAxis.title = "Predicted",
    yAxis.nameTextStyle.fontSize = 20,
    yAxis.nameTextStyle.padding = 60,
    yAxis.nameTextStyle.color = "#CE1141",
    yAxis.nameTextStyle.textShadowColor = "#CE1141",
    yAxis.nameTextStyle.textShadowBlur = 10,
    yAxis.nameTextStyle.textShadowOffsetX = 0,
    yAxis.nameTextStyle.textShadowOffsetY = 0,
    yAxis.axisLabel.color = "#F3F6FB",
    tooltip.backgroundColor = "rgba(12, 35, 64, 0.96)",
    tooltip.textStyle.color = "#FFFFFF",
    legend.show = FALSE,
    toolbox.show = FALSE,
    toolbox.iconStyle.borderColor = "#FFFFFF",
    toolbox.emphasis.iconStyle.borderColor = "#CE1141"
  )
  if (requireNamespace("echarts4r", quietly = TRUE)) {
    chart <- echarts4r::e_line(
      chart,
      ideal,
      symbol = "none",
      name = "Ideal fit",
      lineStyle = list(type = "dashed", color = "rgba(234, 242, 255, 0.45)", width = 2)
    )
  }
  chart <- AutoPlots::e_grid_full(
    chart,
    grid.left = "10%",
    grid.right = "6%",
    grid.top = "18%",
    grid.bottom = "20%",
    grid.containLabel = TRUE
  ) |>
    echarts4r::e_color(background = "transparent")
  attr(chart, "report_browser_visual_source") <- "AutoPlots::Scatter"
  chart
}

report_browser_demo_observed_predicted_visual <- function() {
  report_browser_demo_observed_predicted_widget()
}

report_browser_demo_regression_data <- function() {
  observed <- c(18, 28, 37, 45, 53, 63, 70, 80, 88)
  predicted <- c(21, 26, 39, 43, 57, 60, 73, 77, 91)
  data.table::data.table(
    y = observed,
    Predict = predicted,
    signal_strength = seq_along(observed),
    exposure_index = round(observed / max(observed), 4),
    segment = rep(c("Baseline", "Growth", "Mature"), length.out = length(observed))
  )
}

report_browser_demo_direct_observed_predicted_autoplots <- function(data = report_browser_demo_regression_data(), theme = "dark") {
  if (!requireNamespace("AutoPlots", quietly = TRUE) || !requireNamespace("echarts4r", quietly = TRUE)) {
    return(NULL)
  }
  plot_data <- data.table::data.table(
    Actual = data$y,
    Prediction = data$Predict
  )
  plot_data[, Ideal := Actual]
  chart <- AutoPlots::Scatter(
    dt = plot_data,
    XVar = "Actual",
    YVar = "Prediction",
    SampleSize = nrow(plot_data),
    Theme = theme,
    title.text = "Observed vs Predicted: Direct QA",
    xAxis.title = "Observed",
    yAxis.title = "Predicted",
    legend.show = FALSE
  )
  chart <- echarts4r::e_line(
    chart,
    Ideal,
    symbol = "none",
    name = "Ideal fit",
    lineStyle = list(type = "dashed", width = 2)
  )
  AutoPlots::e_grid_full(
    chart,
    grid.left = "8%",
    grid.right = "5%",
    grid.top = "16%",
    grid.bottom = "18%",
    grid.containLabel = TRUE
  ) |>
    echarts4r::e_color(background = "transparent")
}

report_browser_package_location <- function(package) {
  tryCatch(normalizePath(find.package(package), winslash = "/", mustWork = TRUE), error = function(e) NA_character_)
}

report_browser_function_namespace <- function(package, function_name) {
  tryCatch(
    environmentName(environment(get(function_name, envir = asNamespace(package), inherits = FALSE))),
    error = function(e) NA_character_
  )
}

report_browser_demo_regression_provenance <- function(data, config, selected_artifact, original_artifact_id, fallback_status = "none") {
  list(
    tool_id = "build_week_demo.regression_model_insights",
    report_contract_id = "demo_regression_model_insights_report",
    adapter = "build_regression_model_insights_report",
    autoquant_function = "AutoQuant::generate_regression_model_insights_artifacts",
    autoquant_version = tryCatch(as.character(utils::packageVersion("AutoQuant")), error = function(e) NA_character_),
    autoquant_library_path = report_browser_package_location("AutoQuant"),
    autoquant_function_namespace = report_browser_function_namespace("AutoQuant", "generate_regression_model_insights_artifacts"),
    autoplots_function = "AutoPlots::Scatter",
    autoplots_version = tryCatch(as.character(utils::packageVersion("AutoPlots")), error = function(e) NA_character_),
    autoplots_library_path = report_browser_package_location("AutoPlots"),
    autoplots_function_namespace = report_browser_function_namespace("AutoPlots", "Scatter"),
    renderer_function = "render_plot_service_widget",
    shiny_renderer = "echarts4r::renderEcharts4r",
    input_column_names = names(data),
    input_row_count = nrow(data),
    argument_values = list(
      target_column = config$target_column,
      prediction_column = config$prediction_column,
      feature_columns = config$feature_columns,
      theme = config$theme,
      sample_size = config$sample_size,
      generate_calibration_pdp = config$generate_calibration_pdp,
      generate_uplift_pdp = config$generate_uplift_pdp,
      generate_stratified_effects = config$generate_stratified_effects,
      detect_simpsons_paradox = config$detect_simpsons_paradox
    ),
    output_class = class(selected_artifact$object),
    original_artifact_id = original_artifact_id,
    final_artifact_id = selected_artifact$artifact_id,
    fallback_status = fallback_status,
    fallback_path = "none",
    display_mode = if (inherits(selected_artifact$object, "htmlwidget")) "interactive_htmlwidget" else "unexpected"
  )
}

report_browser_log_regression_provenance <- function(record) {
  if (!identical(tolower(Sys.getenv("AQ_REPORT_PROVENANCE_LOG", "false")), "true")) {
    return(invisible(record))
  }
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    message("AQ_REPORT_PROVENANCE ", jsonlite::toJSON(record, auto_unbox = TRUE, null = "null"))
  } else {
    message("AQ_REPORT_PROVENANCE ", paste(names(record), unlist(record, recursive = FALSE, use.names = FALSE), sep = "=", collapse = "; "))
  }
  invisible(record)
}

report_browser_select_regression_observed_predicted <- function(artifacts) {
  if (!length(artifacts)) {
    stop("AutoQuant regression module returned no artifacts.", call. = FALSE)
  }
  candidates <- Filter(function(artifact) {
    metadata <- artifact$metadata %||% list()
    haystack <- paste(
      artifact$artifact_id %||% "",
      artifact$label %||% "",
      metadata$original_name %||% "",
      artifact$section %||% "",
      collapse = " "
    )
    identical(artifact$artifact_type, "plot") &&
      inherits(artifact$object, "htmlwidget") &&
      grepl("actual.*predicted|observed.*predicted|predicted.*actual", haystack, ignore.case = TRUE)
  }, artifacts)
  if (!length(candidates)) {
    stop("AutoQuant regression module did not return an interactive observed-vs-predicted plot artifact.", call. = FALSE)
  }
  preferred <- Filter(function(artifact) {
    grepl("test.*actual.*predicted|actual.*predicted.*scatter", (artifact$metadata %||% list())$original_name %||% artifact$artifact_id, ignore.case = TRUE)
  }, candidates)
  if (length(preferred)) {
    preferred[[1]]
  } else {
    candidates[[1]]
  }
}

report_browser_demo_regression_artifacts <- function() {
  data <- report_browser_demo_regression_data()
  config <- list(
    data_name = "Deterministic regression demo",
    model_id = "build_week_regression_demo",
    algo = "external_predictions",
    target_column = "y",
    prediction_column = "Predict",
    feature_columns = c("signal_strength", "exposure_index", "segment"),
    theme = "dark",
    sample_size = nrow(data),
    generate_calibration_pdp = FALSE,
    generate_uplift_pdp = FALSE,
    generate_stratified_effects = FALSE,
    detect_simpsons_paradox = FALSE
  )
  if (!exists("run_autoquant_regression_model_insights_module", mode = "function")) {
    stop("Registered AutoQuant regression module wrapper is not available for the demo report.", call. = FALSE)
  }
  result <- run_autoquant_regression_model_insights_module(data, config)
  if (!identical(result$status, "success")) {
    stop(
      paste("AutoQuant regression module failed while producing the demo report:", paste(result$errors %||% "unknown error", collapse = "; ")),
      call. = FALSE
    )
  }
  selected <- report_browser_select_regression_observed_predicted(result$artifacts)
  original_artifact_id <- selected$artifact_id
  selected$artifact_id <- "regression_visual_observed_predicted"
  selected$label <- "Observed vs Predicted"
  selected$title <- "Observed vs Predicted"
  selected$section <- "Prediction Diagnostics"
  selected$order <- 1L
  selected$status <- "ready"
  selected$metadata <- selected$metadata %||% list()
  selected$metadata$recommended_caption <- "Predicted values should track observed values without systematic structure."
  selected$metadata$analytical_intent <- "diagnostic"
  selected$metadata$artifact_importance <- "critical"
  selected$metadata$demo_fixture <- FALSE
  selected$metadata$source_function <- "AutoQuant::generate_regression_model_insights_artifacts"
  selected$metadata$visual_source <- "AutoPlots::Scatter"
  selected$metadata$fallback_status <- "none"
  selected$metadata$provenance_diagnostics <- report_browser_demo_regression_provenance(data, config, selected, original_artifact_id)
  report_browser_log_regression_provenance(selected$metadata$provenance_diagnostics)
  c(
    list(selected),
    report_browser_demo_artifacts("regression_fixture")
  )
}

report_browser_demo_artifacts <- function(prefix = "demo") {
  if (identical(prefix, "regression")) {
    return(report_browser_demo_regression_artifacts())
  }
  module_id <- if (identical(prefix, "regression")) "autoquant_regression_model_insights" else prefix
  source_function <- if (identical(prefix, "regression")) "deterministic_regression_report_demo_fixture" else "deterministic_report_demo_fixture"
  list(
    list(
      artifact_id = paste0(prefix, "_metrics"),
      title = "Model Metrics",
      label = "Model Metrics",
      artifact_type = "table",
      section = "Model Overview",
      source_module = module_id,
      status = "ready",
      metadata = list(
        recommended_caption = "Core performance metrics for report review.",
        analytical_intent = "comparison",
        artifact_importance = "critical",
        table_architecture = list(pinned_columns = "metric", grouped_rows = FALSE),
        demo_fixture = TRUE,
        source_function = source_function
      ),
      content = data.frame(metric = c("RMSE", "MAE", "R Squared"), value = c(12.4, 8.7, 0.82), stringsAsFactors = FALSE)
    ),
    list(
      artifact_id = paste0(prefix, "_finding"),
      title = "Model Fit Finding",
      label = "Model Fit Finding",
      artifact_type = "text",
      section = "Model Overview",
      source_module = module_id,
      status = "ready",
      content = "The current model has usable fit for directional review, but residual diagnostics should be checked before decision use.",
      metadata = list(
        confidence = "source_supplied",
        artifact_importance = "recommended",
        quality_status = "ready",
        demo_fixture = TRUE,
        source_function = source_function
      )
    ),
    list(
      artifact_id = paste0(prefix, "_recommendation"),
      title = "Review Residuals",
      label = "Review Residuals",
      artifact_type = "recommendation",
      section = "Recommendations",
      source_module = module_id,
      status = "ready",
      content = "Review residual structure before presenting model conclusions.",
      metadata = list(artifact_importance = "recommended", demo_fixture = TRUE, source_function = source_function)
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
  visual_binding_html <- ""
  if (requireNamespace("AutoPlots", quietly = TRUE) && requireNamespace("echarts4r", quietly = TRUE)) {
    fake_output <- new.env(parent = emptyenv())
    fake_session <- list(ns = identity)
    visual_binding <- report_browser_render_visual_payload(
      report_browser_demo_observed_predicted_visual(),
      component = list(component_id = "qa_observed_predicted"),
      output = fake_output,
      session = fake_session
    )
    visual_binding_html <- as.character(htmltools::renderTags(visual_binding)$html)
  }
  regression_artifacts <- report_browser_demo_artifacts("regression")
  regression_visual_artifact <- regression_artifacts[[1]]
  regression_visual_metadata <- regression_visual_artifact$metadata %||% list()
  regression_visual_provenance <- regression_visual_metadata$provenance_diagnostics %||% list()
  direct_autoplots_visual <- report_browser_demo_direct_observed_predicted_autoplots()
  regression_visual_background <- regression_visual_artifact$object$x$opts$backgroundColor %||%
    regression_visual_artifact$object$x$opts$background %||%
    NA_character_
  direct_visual_background <- direct_autoplots_visual$x$opts$backgroundColor %||%
    direct_autoplots_visual$x$opts$background %||%
    NA_character_
  fabricated_generic_plot_count <- sum(vapply(
    c(report_browser_demo_artifacts("shap"), report_browser_demo_artifacts("eda")),
    function(artifact) identical(artifact$artifact_type, "plot"),
    logical(1)
  ))

  rows <- list(
    data.table::data.table(check = "registry covers component types", status = if (all(report_component_types %in% names(registry))) "success" else "error"),
    data.table::data.table(check = "component renderer returns html", status = if (inherits(rendered_component, "shiny.tag") || inherits(rendered_component, "shiny.tag.list")) "success" else "error"),
    data.table::data.table(check = "section renderer returns html", status = if (inherits(rendered_section, "shiny.tag") || inherits(rendered_section, "shiny.tag.list")) "success" else "error"),
    data.table::data.table(check = "report renderer returns html", status = if (inherits(rendered_report, "shiny.tag") || inherits(rendered_report, "shiny.tag.list")) "success" else "error"),
    data.table::data.table(check = "section navigation rendered", status = if (grepl("aq-report-browser-nav", rendered_html, fixed = TRUE) && grepl("section-", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "findings rendered prominently", status = if (grepl("aq-report-browser-findings", rendered_html, fixed = TRUE) && grepl("What the report asserts", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "visualization renders real payload", status = if ((grepl("html-widget", rendered_html, fixed = TRUE) || grepl("echarts4r", rendered_html, fixed = TRUE)) && !grepl("aq-report-browser-demo-plot", rendered_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "Shiny visual binding uses echarts4r output", status = if (!requireNamespace("AutoPlots", quietly = TRUE) || grepl("html-widget-output", visual_binding_html, fixed = TRUE)) "success" else "error"),
    data.table::data.table(check = "demo visual uses modern AutoPlots when available", status = if (!requireNamespace("AutoPlots", quietly = TRUE) || identical(attr(report_browser_demo_observed_predicted_visual(), "report_browser_visual_source"), "AutoPlots::Scatter")) "success" else "error"),
    data.table::data.table(check = "regression demo visual comes from AutoQuant", status = if (identical(regression_visual_metadata$source_function, "AutoQuant::generate_regression_model_insights_artifacts") && identical(regression_visual_artifact$source_module, "autoquant_regression_model_insights")) "success" else "error"),
    data.table::data.table(check = "regression demo visual comes from AutoPlots Scatter", status = if (identical(regression_visual_metadata$visual_source, "AutoPlots::Scatter") && identical(regression_visual_provenance$autoplots_function, "AutoPlots::Scatter")) "success" else "error"),
    data.table::data.table(check = "regression demo visual has no fallback", status = if (identical(regression_visual_metadata$fallback_status, "none") && identical(regression_visual_provenance$fallback_path, "none")) "success" else "error"),
    data.table::data.table(check = "regression demo visual is interactive htmlwidget", status = if (inherits(regression_visual_artifact$object, "htmlwidget") && identical(regression_visual_provenance$display_mode, "interactive_htmlwidget")) "success" else "error"),
    data.table::data.table(check = "regression demo visual matches direct AutoPlots class", status = if (is.null(direct_autoplots_visual) || identical(class(regression_visual_artifact$object), class(direct_autoplots_visual))) "success" else "error"),
    data.table::data.table(check = "regression demo visual has transparent chart background", status = if (identical(regression_visual_background, "transparent") && (is.null(direct_autoplots_visual) || identical(direct_visual_background, "transparent"))) "success" else "error"),
    data.table::data.table(check = "generic demo fixtures do not fabricate plot artifacts", status = if (identical(fabricated_generic_plot_count, 0L)) "success" else "error"),
    data.table::data.table(check = "visual interaction metadata matches payload", status = if (grepl("interactive, tooltip", rendered_html, fixed = TRUE) && !grepl("static inline visual", rendered_html, fixed = TRUE)) "success" else "error"),
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
