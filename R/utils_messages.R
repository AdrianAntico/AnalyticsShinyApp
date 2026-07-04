plot_config_summary <- function(name, config, metadata = NULL, status = NULL) {
  option_text <- function(option_name) {
    value <- config$options[[option_name]]
    if (is.null(value) || length(value) == 0L || identical(value, "")) {
      return("")
    }

    paste(value, collapse = ", ")
  }

  mapping_text <- function(mapping) {
    value <- config$mappings[[mapping]]
    if (is.null(value) || length(value) == 0L || identical(value, "")) {
      return("")
    }

    paste(value, collapse = ", ")
  }

  data.table::data.table(
    Plot = name,
    PlotType = config$plot_type,
    Section = if (is.null(metadata$section_name)) "Analysis" else metadata$section_name,
    Order = if (is.null(metadata$sort_order)) NA_integer_ else metadata$sort_order,
    Status = if (is.null(status$status)) "Needs data" else status$status,
    Title = option_text("title.text"),
    XVar = mapping_text("XVar"),
    YVar = mapping_text("YVar"),
    GroupVar = mapping_text("GroupVar")
  )
}

file_size_mb <- function(size) {
  round(size / 1024^2, 1)
}

plot_error_message <- function(message) {
  tags$div(
    style = paste0(
      "padding: 14px;",
      "border: 1px solid #FCA5A5;",
      "border-radius: 8px;",
      "background: #FEF2F2;",
      "color: #991B1B;"
    ),
    tags$b("Plot could not be built."),
    tags$br(),
    message
  )
}

layout_error_message <- function(message) {
  tags$div(
    style = paste0(
      "padding: 14px;",
      "border: 1px solid #FCA5A5;",
      "border-radius: 8px;",
      "background: #FEF2F2;",
      "color: #991B1B;"
    ),
    tags$b("Layout could not be rendered."),
    tags$br(),
    message
  )
}

service_result_message <- function(result) {
  parts <- c(result$messages, result$warnings, result$errors)
  parts <- parts[nzchar(parts)]
  if (!length(parts)) {
    return("")
  }

  paste(parts, collapse = " ")
}
