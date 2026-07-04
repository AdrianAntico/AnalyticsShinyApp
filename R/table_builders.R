build_data_preview_table <- function(data, vars = NULL, max_rows = 25L) {
  data <- .table_as_data_table(data)
  if (!is.null(vars)) {
    vars <- intersect(vars, names(data))
    data <- data[, ..vars]
  }

  data[seq_len(min(nrow(data), max_rows))]
}

build_summary_statistics_table <- function(data, vars = NULL, digits = 3) {
  data <- .table_as_data_table(data)
  numeric_vars <- names(data)[vapply(data, is.numeric, logical(1))]
  if (!is.null(vars)) {
    numeric_vars <- intersect(numeric_vars, vars)
  }

  if (!length(numeric_vars)) {
    return(data.table::data.table(
      variable = character(),
      n = integer(),
      missing = integer(),
      missing_pct = numeric(),
      mean = numeric(),
      sd = numeric(),
      min = numeric(),
      p25 = numeric(),
      median = numeric(),
      p75 = numeric(),
      max = numeric()
    ))
  }

  numeric_stat <- function(values, fn) {
    non_missing <- values[!is.na(values)]
    if (!length(non_missing)) {
      return(NA_real_)
    }

    fn(non_missing)
  }

  data.table::rbindlist(lapply(numeric_vars, function(variable) {
    values <- data[[variable]]
    non_missing <- values[!is.na(values)]
    quantiles <- if (length(non_missing)) {
      stats::quantile(non_missing, probs = c(0.25, 0.5, 0.75), names = FALSE, na.rm = TRUE)
    } else {
      c(NA_real_, NA_real_, NA_real_)
    }

    data.table::data.table(
      variable = variable,
      n = length(non_missing),
      missing = sum(is.na(values)),
      missing_pct = round(mean(is.na(values)) * 100, digits),
      mean = round(numeric_stat(values, mean), digits),
      sd = round(numeric_stat(values, stats::sd), digits),
      min = round(numeric_stat(values, min), digits),
      p25 = round(quantiles[[1]], digits),
      median = round(quantiles[[2]], digits),
      p75 = round(quantiles[[3]], digits),
      max = round(numeric_stat(values, max), digits)
    )
  }), use.names = TRUE)
}

build_frequency_table <- function(data, vars = NULL, max_levels = 50L, digits = 3) {
  data <- .table_as_data_table(data)
  if (is.null(vars)) {
    vars <- names(data)[!vapply(data, is.numeric, logical(1))]
  } else {
    vars <- intersect(vars, names(data))
  }

  if (!length(vars)) {
    return(data.table::data.table(
      variable = character(),
      level = character(),
      n = integer(),
      pct = numeric()
    ))
  }

  data.table::rbindlist(lapply(vars, function(variable) {
    values <- as.character(data[[variable]])
    values[is.na(values)] <- "(missing)"
    counts <- data.table::data.table(level = values)[, .(n = .N), by = level][order(-n, level)]
    counts <- counts[seq_len(min(nrow(counts), max_levels))]
    counts[, `:=`(
      variable = variable,
      pct = round(n / nrow(data) * 100, digits)
    )]
    counts[, .(variable, level, n, pct)]
  }), use.names = TRUE)
}
