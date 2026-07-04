save_project_state <- function(project_state, path) {
  output_path <- normalize_project_path(path)
  output_dir <- dirname(output_path)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!dir.exists(output_dir)) {
    stop("Project output directory could not be created.", call. = FALSE)
  }

  saveRDS(project_state, output_path)
  normalizePath(output_path, winslash = "/", mustWork = TRUE)
}
