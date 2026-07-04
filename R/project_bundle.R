normalize_bundle_dir <- function(path) {
  path <- selected_value(path)
  if (is.null(path)) {
    stop("Project bundle directory is required.", call. = FALSE)
  }

  path
}

ensure_bundle_dirs <- function(bundle_dir) {
  if (!dir.exists(bundle_dir)) {
    dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(bundle_dir)) {
    stop("Project bundle directory could not be created.", call. = FALSE)
  }

  exports_dir <- file.path(bundle_dir, "exports")
  if (!dir.exists(exports_dir)) {
    dir.create(exports_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(exports_dir)) {
    stop("Project bundle exports directory could not be created.", call. = FALSE)
  }

  list(
    bundle_dir = normalizePath(bundle_dir, winslash = "/", mustWork = TRUE),
    project_path = normalizePath(file.path(bundle_dir, "project.rds"), winslash = "/", mustWork = FALSE),
    data_path = normalizePath(file.path(bundle_dir, "data.csv"), winslash = "/", mustWork = FALSE),
    exports_dir = normalizePath(exports_dir, winslash = "/", mustWork = TRUE)
  )
}
