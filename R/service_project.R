save_project_state <- function(project_state, path, workspace = NULL, project = NULL, resource_type = "project_state",
                               allow_unsafe_dev_fixture = FALSE) {
  output_path <- normalize_project_path(path)
  output_dir <- dirname(output_path)

  if ((is.null(workspace) || is.null(project)) && !isTRUE(allow_unsafe_dev_fixture)) {
    stop("Project save requires a configured workspace and a ready active project.", call. = FALSE)
  }

  if (!isTRUE(allow_unsafe_dev_fixture)) {
    gate <- persistent_write_gate(
      workspace = workspace,
      project = project,
      target = output_path,
      requested_resource_type = resource_type
    )
    if (!identical(gate$status, "success")) {
      stop(paste(gate$errors %||% "Persistent write blocked.", collapse = " "), call. = FALSE)
    }
  }

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!dir.exists(output_dir)) {
    stop("Project output directory could not be created.", call. = FALSE)
  }

  atomic_save_rds(project_state, output_path)
}
