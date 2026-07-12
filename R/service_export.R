.export_selected_value <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }

  value
}

.export_clean_name <- function(export_name) {
  export_name <- .export_selected_value(export_name)
  if (is.null(export_name)) {
    return(NULL)
  }

  tools::file_path_sans_ext(basename(export_name))
}

.export_output_path <- function(export_dir, export_name, extension) {
  file.path(export_dir, paste0(export_name, extension))
}

.export_invalid_name <- function(export_name) {
  is.null(export_name) ||
    !nzchar(export_name) ||
    grepl('[<>:"/\\\\|?*]', export_name)
}

.export_save_widget <- function(report, export_dir, export_name, html_path) {
  if ("save_widget" %in% getNamespaceExports("AutoPlots")) {
    AutoPlots::save_widget(
      widget = report,
      path = export_dir,
      name = export_name,
      selfcontained = TRUE,
      overwrite = TRUE,
      open = FALSE
    )
    return("autoplots")
  }

  if (inherits(report, "htmlwidget")) {
    htmlwidgets::saveWidget(
      widget = report,
      file = html_path,
      selfcontained = TRUE
    )
    return("htmlwidgets")
  }

  htmltools::save_html(
    htmltools::browsable(report),
    file = html_path,
    libdir = paste0(export_name, "_files")
  )
  "htmltools"
}

validate_export_config <- function(export_dir, export_name) {
  tryCatch({
    export_dir <- .export_selected_value(export_dir)
    if (is.null(export_dir)) {
      return(service_result(
        status = "needs_input",
        errors = "Export directory is required.",
        metadata = list(error_code = "EXPORT_PATH_INVALID")
      ))
    }

    export_name <- .export_clean_name(export_name)
    if (.export_invalid_name(export_name)) {
      return(service_result(
        status = "needs_input",
        errors = "File name is required and cannot contain invalid filename characters.",
        metadata = list(error_code = "EXPORT_PATH_INVALID")
      ))
    }

    if (!dir.exists(export_dir)) {
      dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)
    }

    if (!dir.exists(export_dir)) {
      return(service_result(
        status = "error",
        errors = "Export directory could not be created.",
        metadata = list(error_code = "EXPORT_PATH_INVALID")
      ))
    }

    normalized_dir <- normalizePath(export_dir, winslash = "/", mustWork = TRUE)
    if (exists("storage_repo_root", mode = "function") &&
        exists("path_within_root", mode = "function") &&
        path_within_root(normalized_dir, storage_repo_root())) {
      return(service_result(
        status = "error",
        errors = "Export directory is inside the application repository and was blocked.",
        metadata = list(error_code = "EXPORT_INSIDE_REPOSITORY")
      ))
    }
    test_file <- tempfile(tmpdir = normalized_dir)
    can_write <- tryCatch({
      writeLines("", con = test_file, useBytes = TRUE)
      unlink(test_file)
      TRUE
    }, error = function(e) {
      FALSE
    })

    if (!isTRUE(can_write)) {
      return(service_result(
        status = "error",
        errors = "Export directory is not writable.",
        metadata = list(error_code = "EXPORT_PATH_INVALID")
      ))
    }

    service_result(
      status = "success",
      value = list(
        export_dir = normalized_dir,
        export_name = export_name
      )
    )
  }, error = function(e) {
    service_result(
      status = "error",
      errors = paste("Export validation failed:", conditionMessage(e)),
      diagnostics = list(condition = e),
      metadata = list(error_code = "RUNTIME_ERROR")
    )
  })
}

export_html_service <- function(report, export_dir, export_name) {
  if (is.null(report)) {
    return(service_result(
      status = "needs_input",
      errors = "No report layout is available. Add saved plots and preview a layout before exporting.",
      metadata = list(error_code = "DATA_MISSING")
    ))
  }

  validation <- validate_export_config(export_dir, export_name)
  if (!identical(validation$status, "success")) {
    return(validation)
  }

  export_dir <- validation$value$export_dir
  export_name <- validation$value$export_name
  html_path <- .export_output_path(export_dir, export_name, ".html")

  tryCatch({
    export_method <- .export_save_widget(report, export_dir, export_name, html_path)
    fallback_warning <- if (identical(export_method, "htmltools")) {
      paste(
        "AutoPlots::save_widget() is unavailable; exported HTML with an asset directory beside",
        basename(html_path)
      )
    } else {
      character()
    }

    service_result(
      status = "success",
      artifacts = list(html_path = html_path),
      messages = paste("Exported HTML to", html_path),
      warnings = fallback_warning
    )
  }, error = function(e) {
    service_result(
      status = "error",
      errors = paste("Export failed:", conditionMessage(e)),
      diagnostics = list(condition = e),
      metadata = list(error_code = "RUNTIME_ERROR")
    )
  })
}

export_code_service <- function(code, export_dir, export_name) {
  if (is.null(code) || !length(code) || !nzchar(code)) {
    return(service_result(
      status = "needs_input",
      errors = "No generated report code is available to export.",
      metadata = list(error_code = "DATA_MISSING")
    ))
  }

  validation <- validate_export_config(export_dir, export_name)
  if (!identical(validation$status, "success")) {
    return(validation)
  }

  export_dir <- validation$value$export_dir
  export_name <- validation$value$export_name
  code_path <- .export_output_path(export_dir, export_name, ".R")

  tryCatch({
    writeLines(code, con = code_path, useBytes = TRUE)

    service_result(
      status = "success",
      artifacts = list(code_path = normalizePath(code_path, winslash = "/", mustWork = TRUE)),
      messages = paste("Exported R code to", normalizePath(code_path, winslash = "/", mustWork = TRUE)),
      code = code
    )
  }, error = function(e) {
    service_result(
      status = "error",
      errors = paste("Export failed:", conditionMessage(e)),
      diagnostics = list(condition = e),
      metadata = list(error_code = "RUNTIME_ERROR")
    )
  })
}

export_all_service <- function(report, code, export_dir, export_name) {
  html_result <- export_html_service(report, export_dir, export_name)
  if (!identical(html_result$status, "success")) {
    return(html_result)
  }

  code_result <- export_code_service(code, export_dir, export_name)
  if (!identical(code_result$status, "success")) {
    return(code_result)
  }

  service_result(
    status = "success",
    artifacts = c(html_result$artifacts, code_result$artifacts),
    messages = paste(
      "Exported HTML to",
      html_result$artifacts$html_path,
      "and R code to",
      code_result$artifacts$code_path
    ),
    code = code,
    metadata = list(html_status = html_result$status, code_status = code_result$status)
  )
}

.ap_qa_export_service <- function() {
  code <- "library(AutoPlots)\nreport <- NULL"
  export_dir <- file.path(tempdir(), paste0("autoplots_export_service_", as.integer(Sys.time())))

  list(
    missing_report = export_html_service(NULL, export_dir, "report"),
    code_export = export_code_service(code, export_dir, "report"),
    missing_code = export_code_service(NULL, export_dir, "report"),
    invalid_name = validate_export_config(export_dir, "bad:name")
  )
}
