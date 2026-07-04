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

ui_app_shell <- function(..., theme = "light") {
  theme <- match.arg(theme, c("light", "dark", "pimp"))

  tagList(
    tags$script(HTML(sprintf(
      "document.body.classList.add('aq-theme-%s');",
      theme
    ))),
    tags$div(class = "aq-app-shell", ...)
  )
}

ui_page <- function(title, subtitle = NULL, ...) {
  tags$div(
    class = "aq-page",
    ui_section_header(title, subtitle),
    ...
  )
}

ui_section_header <- function(title, subtitle = NULL) {
  tags$header(
    class = "aq-section-header",
    tags$h2(class = "aq-section-title", title),
    if (!is.null(subtitle)) tags$p(class = "aq-section-subtitle", subtitle)
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

ui_action_row <- function(...) {
  tags$div(class = "aq-action-row", ...)
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
