supported_data_extensions <- function() {
  c("csv", "xlsx", "xlsm", "parquet")
}

supported_data_accept_types <- function() {
  c(
    ".csv",
    "text/csv",
    ".xlsx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".xlsm",
    "application/vnd.ms-excel.sheet.macroEnabled.12",
    ".parquet",
    "application/vnd.apache.parquet"
  )
}

data_loader_extension <- function(path) {
  ext <- tolower(tools::file_ext(path %||% ""))
  if (!nzchar(ext)) {
    return(NA_character_)
  }
  ext
}

read_dataset_file <- function(path, name = path) {
  if (is.null(path) || !length(path) || is.na(path[[1]]) || !file.exists(path[[1]])) {
    stop("Dataset file does not exist.", call. = FALSE)
  }

  ext <- data_loader_extension(name %||% path)
  if (is.na(ext) || !ext %in% supported_data_extensions()) {
    stop(
      paste(
        "Unsupported dataset format.",
        "Supported formats are CSV, XLSX, XLSM, and Parquet."
      ),
      call. = FALSE
    )
  }

  data <- switch(
    ext,
    csv = data.table::fread(path),
    xlsx = {
      if (!requireNamespace("openxlsx", quietly = TRUE)) {
        stop("Excel loading requires the openxlsx package.", call. = FALSE)
      }
      data.table::as.data.table(openxlsx::read.xlsx(path, sheet = 1L))
    },
    xlsm = {
      if (!requireNamespace("openxlsx", quietly = TRUE)) {
        stop("Excel loading requires the openxlsx package.", call. = FALSE)
      }
      data.table::as.data.table(openxlsx::read.xlsx(path, sheet = 1L))
    },
    parquet = {
      if (!requireNamespace("arrow", quietly = TRUE)) {
        stop("Parquet loading requires the arrow package.", call. = FALSE)
      }
      data.table::as.data.table(arrow::read_parquet(path))
    }
  )

  data.table::as.data.table(data)
}

qa_data_loader <- function(output_dir = file.path(tempdir(), "data_loader_qa")) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  sample <- data.table::data.table(
    id = 1:3,
    channel = c("Search", "Social", "Email"),
    value = c(10.2, 20.4, 30.6)
  )
  csv_path <- file.path(output_dir, "sample.csv")
  xlsx_path <- file.path(output_dir, "sample.xlsx")
  xlsm_path <- file.path(output_dir, "sample.xlsm")
  parquet_path <- file.path(output_dir, "sample.parquet")
  data.table::fwrite(sample, csv_path)
  if (requireNamespace("openxlsx", quietly = TRUE)) {
    openxlsx::write.xlsx(sample, xlsx_path, overwrite = TRUE)
    openxlsx::write.xlsx(sample, xlsm_path, overwrite = TRUE)
  }
  if (requireNamespace("arrow", quietly = TRUE)) {
    arrow::write_parquet(sample, parquet_path)
  }

  read_ok <- function(path) {
    result <- tryCatch(read_dataset_file(path), error = function(e) e)
    data.table::is.data.table(result) && nrow(result) == nrow(sample) && ncol(result) == ncol(sample)
  }

  data.table::data.table(
    check = c("csv", "xlsx", "xlsm", "parquet", "accept_types"),
    status = c(
      if (read_ok(csv_path)) "success" else "error",
      if (!requireNamespace("openxlsx", quietly = TRUE)) "warning" else if (read_ok(xlsx_path)) "success" else "error",
      if (!requireNamespace("openxlsx", quietly = TRUE)) "warning" else if (read_ok(xlsm_path)) "success" else "error",
      if (!requireNamespace("arrow", quietly = TRUE)) "warning" else if (read_ok(parquet_path)) "success" else "error",
      if (all(c(".csv", ".xlsx", ".xlsm", ".parquet") %in% supported_data_accept_types())) "success" else "error"
    ),
    message = c(
      "CSV files load through the shared data loader.",
      "XLSX files load through the shared data loader when openxlsx is available.",
      "XLSM files load through the shared data loader when openxlsx is available.",
      "Parquet files load through the shared data loader when arrow is available.",
      "Upload control advertises supported dataset formats."
    )
  )
}
