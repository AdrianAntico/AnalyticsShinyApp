.table_export_data <- function(artifact_or_data) {
  if (inherits(artifact_or_data, "aq_artifact")) {
    data <- artifact_or_data$object %||% artifact_or_data$content
  } else {
    data <- artifact_or_data
  }

  .table_as_data_table(data)
}

.table_export_name <- function(name, extension) {
  name <- name %||% "table"
  name <- tools::file_path_sans_ext(basename(name))
  if (!nzchar(name)) {
    name <- "table"
  }

  paste0(name, extension)
}

export_table_csv <- function(
  artifact_or_data,
  path,
  name,
  overwrite = TRUE
) {
  tryCatch({
    if (is.null(path) || !nzchar(path)) {
      return(service_result(status = "needs_input", errors = "Export path is required."))
    }

    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
    }
    if (!dir.exists(path)) {
      return(service_result(status = "error", errors = "Export path could not be created."))
    }
    path <- normalizePath(path, winslash = "/", mustWork = TRUE)
    if (exists("storage_repo_root", mode = "function") &&
        exists("path_within_root", mode = "function") &&
        path_within_root(path, storage_repo_root())) {
      return(service_result(status = "error", errors = "Export path is inside the application repository and was blocked."))
    }

    output_path <- file.path(path, .table_export_name(name, ".csv"))
    if (file.exists(output_path) && !isTRUE(overwrite)) {
      return(service_result(status = "error", errors = paste("File already exists:", output_path)))
    }

    data.table::fwrite(.table_export_data(artifact_or_data), output_path)
    service_result(
      status = "success",
      artifacts = list(csv_path = normalizePath(output_path, winslash = "/", mustWork = TRUE)),
      messages = paste("Exported CSV to", normalizePath(output_path, winslash = "/", mustWork = TRUE))
    )
  }, error = function(e) {
    service_result(
      status = "error",
      errors = paste("CSV export failed:", conditionMessage(e)),
      diagnostics = list(condition = e),
      metadata = list(error_code = "RUNTIME_ERROR")
    )
  })
}

sanitize_excel_sheet_name <- function(names) {
  names <- as.character(names)
  names[is.na(names) | !nzchar(names)] <- "Sheet"
  names <- gsub("[\\[\\]\\:\\*\\?\\/\\\\]", "_", names)
  names <- trimws(substr(names, 1L, 31L))
  names[!nzchar(names)] <- "Sheet"

  seen <- character()
  vapply(names, function(name) {
    candidate <- name
    index <- 1L
    while (candidate %in% seen) {
      suffix <- paste0("_", index)
      candidate <- paste0(substr(name, 1L, 31L - nchar(suffix)), suffix)
      index <- index + 1L
    }
    seen <<- c(seen, candidate)
    candidate
  }, character(1))
}

export_table_xlsx <- function(
  artifacts_or_tables,
  path,
  name,
  overwrite = TRUE
) {
  tryCatch({
    if (!requireNamespace("openxlsx", quietly = TRUE)) {
      return(service_result(
        status = "error",
        errors = "XLSX export requires the openxlsx package.",
        metadata = list(error_code = "PACKAGE_MISSING", package = "openxlsx")
      ))
    }

    if (is.null(path) || !nzchar(path)) {
      return(service_result(status = "needs_input", errors = "Export path is required."))
    }
    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE, showWarnings = FALSE)
    }
    if (!dir.exists(path)) {
      return(service_result(status = "error", errors = "Export path could not be created."))
    }
    path <- normalizePath(path, winslash = "/", mustWork = TRUE)
    if (exists("storage_repo_root", mode = "function") &&
        exists("path_within_root", mode = "function") &&
        path_within_root(path, storage_repo_root())) {
      return(service_result(status = "error", errors = "Export path is inside the application repository and was blocked."))
    }

    tables <- artifacts_or_tables
    if (inherits(tables, "aq_artifact") || data.table::is.data.table(tables) || !is.list(tables)) {
      tables <- list(table = tables)
    }
    if (is.null(names(tables)) || any(!nzchar(names(tables)))) {
      names(tables) <- paste0("Table", seq_along(tables))
    }

    output_path <- file.path(path, .table_export_name(name, ".xlsx"))
    if (file.exists(output_path) && !isTRUE(overwrite)) {
      return(service_result(status = "error", errors = paste("File already exists:", output_path)))
    }

    workbook <- openxlsx::createWorkbook()
    sheet_names <- sanitize_excel_sheet_name(names(tables))
    for (index in seq_along(tables)) {
      openxlsx::addWorksheet(workbook, sheet_names[[index]])
      openxlsx::writeDataTable(workbook, sheet_names[[index]], .table_export_data(tables[[index]]))
    }
    openxlsx::saveWorkbook(workbook, output_path, overwrite = overwrite)

    service_result(
      status = "success",
      artifacts = list(xlsx_path = normalizePath(output_path, winslash = "/", mustWork = TRUE)),
      messages = paste("Exported XLSX to", normalizePath(output_path, winslash = "/", mustWork = TRUE))
    )
  }, error = function(e) {
    service_result(
      status = "error",
      errors = paste("XLSX export failed:", conditionMessage(e)),
      diagnostics = list(condition = e),
      metadata = list(error_code = "RUNTIME_ERROR")
    )
  })
}

qa_table_framework <- function() {
  sample_data <- data.table::data.table(
    Date = as.Date("2026-01-01") + 0:11,
    Channel = rep(c("Search", "Social", "Email"), 4),
    Category = rep(c("A", "B"), 6),
    IsPaid = rep(c(TRUE, FALSE), 6),
    Revenue = c(100, 125, 140, NA, 180, 210, 205, 230, 260, 300, 320, 340),
    Spend = c(40, 55, 65, 75, 80, 90, 95, 100, 120, 130, 140, 150)
  )

  preview <- build_data_preview_table(sample_data, max_rows = 8L)
  summary <- build_summary_statistics_table(sample_data)
  frequency <- build_frequency_table(sample_data, vars = c("Channel", "Category"))
  rendered <- list()
  for (theme in c("light", "dark", "pimp")) {
    rendered[[paste0("preview_", theme)]] <- render_table(preview, theme = theme)
    rendered[[paste0("summary_", theme)]] <- render_table(summary, theme = theme)
    rendered[[paste0("frequency_", theme)]] <- render_table(frequency, theme = theme)
  }

  export_dir <- file.path(tempdir(), paste0("aq_table_framework_", as.integer(Sys.time())))
  dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)
  csv_result <- export_table_csv(preview, export_dir, "preview")
  xlsx_result <- export_table_xlsx(
    list(preview = preview, summary = summary, frequency = frequency),
    export_dir,
    "tables"
  )
  filter_columns <- if (requireNamespace("reactable", quietly = TRUE)) {
    aq_reactable_column_defs(sample_data)
  } else {
    list()
  }
  has_filter <- function(column) {
    !is.null(filter_columns[[column]]) && !is.null(filter_columns[[column]]$filterMethod)
  }
  filter_js <- aq_reactable_exclusion_filter()
  filter_source <- paste(as.character(filter_js), collapse = "\n")
  filter_checks <- data.table::data.table(
    check = c(
      "text_filter_helper_available",
      "normal_filter_semantics_documented",
      "bang_exclusion_semantics_documented",
      "dash_exclusion_semantics_documented",
      "text_column_filter",
      "logical_column_filter",
      "numeric_column_unmodified",
      "date_column_unmodified"
    ),
    status = c(
      if (!is.null(filter_js)) "success" else "warning",
      if (nzchar(filter_source) && grepl("includes\\(term\\)", filter_source, fixed = FALSE)) "success" else "error",
      if (nzchar(filter_source) && grepl("startsWith('!')", filter_source, fixed = TRUE)) "success" else "error",
      if (nzchar(filter_source) && grepl("startsWith('-')", filter_source, fixed = TRUE)) "success" else "error",
      if (has_filter("Channel")) "success" else "error",
      if (has_filter("IsPaid")) "success" else "error",
      if (!has_filter("Revenue")) "success" else "error",
      if (!has_filter("Date")) "success" else "error"
    )
  )

  qa_status <- if (identical(csv_result$status, "success") &&
                   identical(xlsx_result$status, "success") &&
                   !any(filter_checks$status == "error")) {
    "success"
  } else {
    "warning"
  }

  service_result(
    status = qa_status,
    value = list(
      preview = preview,
      summary = summary,
      frequency = frequency,
      rendered = rendered,
      csv_result = csv_result,
      xlsx_result = xlsx_result,
      filter_checks = filter_checks
    ),
    artifacts = c(csv_result$artifacts, xlsx_result$artifacts),
    messages = "Table framework QA completed.",
    warnings = if (!identical(xlsx_result$status, "success")) xlsx_result$errors else character(),
    metadata = list(
      reactable_available = requireNamespace("reactable", quietly = TRUE),
      openxlsx_available = requireNamespace("openxlsx", quietly = TRUE),
      reactable_filter_checks = filter_checks
    )
  )
}
