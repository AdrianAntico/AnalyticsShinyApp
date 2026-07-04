.table_as_data_table <- function(data) {
  if (is.null(data)) {
    return(data.table::data.table())
  }

  data.table::as.data.table(data)
}

.format_table_numbers <- function(data, digits = 3) {
  data <- data.table::copy(.table_as_data_table(data))
  numeric_cols <- names(data)[vapply(data, is.numeric, logical(1))]
  for (column in numeric_cols) {
    data[[column]] <- round(data[[column]], digits = digits)
  }

  data
}

render_table <- function(
  data,
  engine = c("reactable", "html"),
  title = NULL,
  subtitle = NULL,
  page_size = 10,
  searchable = TRUE,
  sortable = TRUE,
  filterable = FALSE,
  digits = 3,
  theme = c("auto", "light", "dark", "pimp")
) {
  engine <- match.arg(engine)
  theme <- .normalize_table_theme(theme)

  table <- if (identical(engine, "reactable") &&
               requireNamespace("reactable", quietly = TRUE)) {
    render_reactable_table(
      data = data,
      page_size = page_size,
      searchable = searchable,
      sortable = sortable,
      filterable = filterable,
      digits = digits,
      theme = theme
    )
  } else {
    render_html_table(data = data, digits = digits, theme = theme)
  }

  htmltools::tags$div(
    class = paste("aq-table-wrapper", paste0("aq-table-", theme)),
    if (!is.null(title)) htmltools::tags$h3(class = "aq-table-title", title),
    if (!is.null(subtitle)) htmltools::tags$p(class = "aq-table-subtitle", subtitle),
    table
  )
}

render_reactable_table <- function(
  data,
  page_size = 10,
  searchable = TRUE,
  sortable = TRUE,
  filterable = FALSE,
  digits = 3,
  theme = c("auto", "light", "dark", "pimp")
) {
  if (!requireNamespace("reactable", quietly = TRUE)) {
    return(render_html_table(data = data, digits = digits, theme = theme))
  }

  data <- .table_as_data_table(data)
  numeric_cols <- names(data)[vapply(data, is.numeric, logical(1))]
  columns <- stats::setNames(
    lapply(names(data), function(column) {
      if (column %in% numeric_cols) {
        return(reactable::colDef(format = reactable::colFormat(digits = digits)))
      }

      reactable::colDef()
    }),
    names(data)
  )

  reactable::reactable(
    data,
    columns = columns,
    searchable = searchable,
    sortable = sortable,
    filterable = filterable,
    defaultPageSize = page_size,
    theme = get_reactable_theme(theme),
    class = "aq-table aq-reactable"
  )
}

render_html_table <- function(
  data,
  digits = 3,
  theme = c("auto", "light", "dark", "pimp")
) {
  theme <- .normalize_table_theme(theme)
  data <- .format_table_numbers(data, digits = digits)

  if (!nrow(data)) {
    return(htmltools::tags$div(
      class = paste("aq-table aq-html-table", paste0("aq-table-", theme)),
      "No rows to display."
    ))
  }

  htmltools::tags$table(
    class = paste("aq-table aq-html-table", paste0("aq-table-", theme)),
    htmltools::tags$thead(
      htmltools::tags$tr(lapply(names(data), htmltools::tags$th))
    ),
    htmltools::tags$tbody(
      lapply(seq_len(nrow(data)), function(row_index) {
        htmltools::tags$tr(lapply(names(data), function(column) {
          value <- data[[column]][[row_index]]
          htmltools::tags$td(if (is.na(value)) "" else as.character(value))
        }))
      })
    )
  )
}
