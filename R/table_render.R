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

aq_reactable_exclusion_filter <- function() {
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    return(NULL)
  }

  htmlwidgets::JS("
    function(rows, columnId, filterValue) {
      if (!filterValue) return rows;

      const filter = String(filterValue).toLowerCase().trim();
      const exclude = filter.startsWith('!') || filter.startsWith('-');
      const term = exclude ? filter.slice(1).trim() : filter;

      if (!term) return rows;

      return rows.filter(function(row) {
        const rawValue = row.values[columnId];
        const value = rawValue == null ? '' : String(rawValue).toLowerCase();
        const match = value.includes(term);
        return exclude ? !match : match;
      });
    }
  ")
}

aq_reactable_is_text_like <- function(x) {
  is.character(x) || is.factor(x) || is.logical(x)
}

aq_reactable_column_defs <- function(data, digits = 3) {
  data <- .table_as_data_table(data)
  numeric_cols <- names(data)[vapply(data, is.numeric, logical(1))]
  text_cols <- names(data)[vapply(data, aq_reactable_is_text_like, logical(1))]
  exclusion_filter <- aq_reactable_exclusion_filter()

  stats::setNames(
    lapply(names(data), function(column) {
      if (column %in% numeric_cols) {
        return(reactable::colDef(format = reactable::colFormat(digits = digits)))
      }

      if (column %in% text_cols && !is.null(exclusion_filter)) {
        return(reactable::colDef(filterMethod = exclusion_filter))
      }

      reactable::colDef()
    }),
    names(data)
  )
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
  theme = c("auto", "light", "dark", "cyberpunk", "pimp")
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
    if (isTRUE(filterable) && identical(engine, "reactable")) {
      htmltools::tags$p(
        class = "aq-table-filter-help",
        "Text filters support exclusion: use !term or -term to exclude rows."
      )
    },
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
  theme = c("auto", "light", "dark", "cyberpunk", "pimp")
) {
  if (!requireNamespace("reactable", quietly = TRUE)) {
    return(render_html_table(data = data, digits = digits, theme = theme))
  }

  data <- .table_as_data_table(data)
  columns <- aq_reactable_column_defs(data, digits = digits)

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
  theme = c("auto", "light", "dark", "cyberpunk", "pimp")
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
