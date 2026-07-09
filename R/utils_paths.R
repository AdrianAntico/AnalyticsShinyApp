empty_choice <- function(label = "(none)") {
  stats::setNames("", label)
}

column_choices <- function(data, include_none = FALSE, label = "(none)") {
  if (is.null(data)) {
    return(empty_choice(label))
  }

  choices <- names(data)
  if (include_none) {
    return(c(empty_choice(label), choices))
  }

  choices
}

r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }

  deparse(value, width.cutoff = 500L)
}

default_value <- function(value, default) {
  if (is.null(value)) {
    return(default)
  }

  value
}

selected_value <- function(value) {
  if (is.null(value) || !length(value) || identical(value, "")) {
    return(NULL)
  }
  if (length(value) == 1L && is.atomic(value) && is.na(value)) {
    return(NULL)
  }
  if (is.character(value) && all(is.na(value) | !nzchar(value))) {
    return(NULL)
  }

  value
}

selected_vector <- function(value) {
  value <- selected_value(value)
  if (is.null(value)) {
    return(NULL)
  }

  value
}

is_empty_arg <- function(value) {
  is.null(value) || length(value) == 0L || (is.character(value) && any(value == ""))
}

logical_value <- function(value) {
  isTRUE(value)
}

numeric_or_null <- function(value) {
  if (is.null(value) || identical(value, "") || is.na(value)) {
    return(NULL)
  }

  as.numeric(value)
}

plot_spec <- function(plot_type) {
  plot_registry[[plot_type]]
}

mapping_input_id <- function(mapping) {
  paste0("mapping_", mapping)
}

mapping_value <- function(input, mapping) {
  value <- input[[mapping_input_id(mapping)]]
  if (identical(mapping, "CorrVars")) {
    value <- selected_vector(value)
    if (is.null(value) || length(value) == 0L) {
      return(NULL)
    }

    return(value)
  }

  selected_value(value)
}

active_mappings <- function(plot_type) {
  spec <- plot_spec(plot_type)
  c(spec$mappings, spec$optional_mappings)
}


required_app_packages <- function() {
  c("shiny", "AutoPlots", "data.table", "htmltools", "htmlwidgets")
}

check_app_dependencies <- function(packages = required_app_packages()) {
  installed <- vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
  missing <- names(installed)[!installed]

  if (length(missing)) {
    return(list(
      ok = FALSE,
      missing = missing,
      messages = c(
        "Missing required R packages:",
        paste0("- ", missing),
        "Install the missing packages, then run the app again."
      )
    ))
  }

  list(
    ok = TRUE,
    missing = character(),
    messages = "All required R packages are installed."
  )
}
