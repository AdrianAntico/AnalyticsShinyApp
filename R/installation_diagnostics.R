workstation_find_rscript <- function() {
  candidates <- unique(c(
    file.path(R.home("bin"), "Rscript.exe"),
    file.path(R.home("bin"), "Rscript"),
    Sys.which("Rscript")
  ))
  candidates <- candidates[nzchar(candidates)]
  found <- candidates[file.exists(candidates)]
  if (length(found)) found[[1]] else NA_character_
}

workstation_find_command <- function(command) {
  env_name <- toupper(paste0(command, "_EXE"))
  env_value <- Sys.getenv(env_name, unset = "")
  if (nzchar(env_value) && file.exists(env_value)) {
    return(normalizePath(env_value, winslash = "/", mustWork = FALSE))
  }

  if (identical(tolower(command), "npm")) {
    env_value <- Sys.getenv("NPM_CMD", unset = "")
    if (nzchar(env_value) && file.exists(env_value)) {
      return(normalizePath(env_value, winslash = "/", mustWork = FALSE))
    }
  }

  value <- Sys.which(command)
  if (!nzchar(value)) {
    repo_node_root <- file.path(getwd(), "runtime", "product-experience", "node")
    if (dir.exists(repo_node_root)) {
      candidates <- list.files(repo_node_root, pattern = "^node-", full.names = TRUE)
      candidate_file <- if (identical(tolower(command), "npm")) "npm.cmd" else paste0(command, ".exe")
      candidate_paths <- file.path(candidates, candidate_file)
      found <- candidate_paths[file.exists(candidate_paths)]
      if (length(found)) {
        return(normalizePath(found[[1]], winslash = "/", mustWork = FALSE))
      }
    }

    return(NA_character_)
  }

  normalizePath(value, winslash = "/", mustWork = FALSE)
}

workstation_command_version <- function(command, args = "--version") {
  exe <- workstation_find_command(command)
  if (is.na(exe)) {
    return(NA_character_)
  }

  out <- tryCatch(
    system2(exe, args = args, stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  if (!length(out)) {
    return(NA_character_)
  }

  out[[1]]
}

workstation_redact_value <- function(value) {
  if (is.null(value) || is.na(value) || !nzchar(value)) {
    return(value)
  }
  if (grepl("key|token|secret|password", value, ignore.case = TRUE)) {
    return("<redacted>")
  }

  value
}

workstation_installation_info <- function(create = TRUE) {
  paths <- workstation_initialize_user_dirs(create = create)
  package_version <- tryCatch(
    as.character(utils::packageVersion(workstation_package_name())),
    error = function(e) NA_character_
  )

  list(
    display_name = workstation_display_name(),
    package = workstation_package_name(),
    package_version = package_version,
    app_version = APP_VERSION,
    app_release = workstation_release_version(),
    package_path = workstation_package_path(mustWork = FALSE),
    app_resource_path = workstation_resource_path(mustWork = FALSE),
    paths = as.list(paths),
    start_menu_shortcut = workstation_start_menu_shortcut(),
    desktop_shortcut = workstation_desktop_shortcut(),
    instructions = c(
      "Open from Start Menu > Analytics Workstation.",
      "To pin to the taskbar: open Analytics Workstation, right-click its taskbar icon, then select Pin to taskbar.",
      "Save Project stores workstation state. Export Report creates a shareable deliverable. Pinning only saves convenient access."
    )
  )
}

workstation_diagnostics <- function(create = TRUE) {
  info <- workstation_installation_info(create = create)
  paths <- info$paths
  dependency <- if (exists("qa_app_dependency_capabilities", mode = "function")) {
    qa_app_dependency_capabilities(require_optional = TRUE)
  } else {
    data.table::data.table(check = "dependency_qa_available", status = "error", message = "qa_app_dependency_capabilities() is not available.")
  }

  data.table::data.table(
    item = c(
      "package",
      "package_version",
      "app_release",
      "R",
      "Rscript",
      "R_library",
      "package_path",
      "app_resource_path",
      "app_www",
      "build_week_data",
      "user_data",
      "program_dir",
      "launcher",
      "start_menu_shortcut",
      "desktop_shortcut",
      "node",
      "npm",
      "genai_provider",
      "genai_model",
      "dependency_status"
    ),
    status = c(
      "available",
      "available",
      "available",
      "available",
      if (!is.na(workstation_find_rscript())) "available" else "missing",
      "available",
      if (dir.exists(info$package_path)) "available" else "missing",
      if (dir.exists(info$app_resource_path)) "available" else "missing",
      if (dir.exists(workstation_resource_path("www", mustWork = FALSE))) "available" else "missing",
      if (file.exists(build_week_demo_data_path())) "available" else "missing",
      if (dir.exists(paths$user_data)) "available" else "missing",
      if (dir.exists(paths$program)) "available" else "missing",
      if (file.exists(paths$launcher)) "available" else "missing",
      if (!is.na(info$start_menu_shortcut) && file.exists(info$start_menu_shortcut)) "available" else "missing",
      if (file.exists(info$desktop_shortcut)) "available" else "missing",
      if (!is.na(workstation_find_command("node"))) "available" else "missing",
      if (!is.na(workstation_find_command("npm"))) "available" else "missing",
      if (nzchar(Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = ""))) "configured" else "not_configured",
      if (nzchar(Sys.getenv("ANALYTICS_GENAI_MODEL", unset = ""))) "configured" else "not_configured",
      if (all(dependency$status == "success")) "pass" else "attention"
    ),
    value = c(
      workstation_package_name(),
      info$package_version,
      info$app_release,
      R.version.string,
      workstation_find_rscript(),
      paste(.libPaths(), collapse = "; "),
      info$package_path,
      info$app_resource_path,
      workstation_resource_path("www", mustWork = FALSE),
      build_week_demo_data_path(),
      paths$user_data,
      paths$program,
      paths$launcher,
      info$start_menu_shortcut,
      info$desktop_shortcut,
      workstation_command_version("node"),
      workstation_command_version("npm"),
      workstation_redact_value(Sys.getenv("ANALYTICS_GENAI_PROVIDER", unset = "")),
      workstation_redact_value(Sys.getenv("ANALYTICS_GENAI_MODEL", unset = "")),
      paste(dependency$status, collapse = ", ")
    )
  )
}

qa_package_distribution <- function() {
  info <- workstation_installation_info(create = TRUE)
  diagnostics <- workstation_diagnostics(create = TRUE)
  paths <- info$paths
  rscript <- workstation_find_rscript()
  expected_exports <- c(
    "run_workstation",
    "launch_workstation",
    "workstation_diagnostics",
    "workstation_installation_info"
  )
  namespace_exports <- tryCatch(
    getNamespaceExports(workstation_package_name()),
    error = function(e) character()
  )
  source_exports_available <- all(vapply(
    expected_exports,
    exists,
    logical(1),
    where = environment(),
    mode = "function",
    inherits = TRUE
  ))
  export_status <- all(expected_exports %in% namespace_exports) || source_exports_available
  dependency_status <- tryCatch(
    all(qa_app_dependency_capabilities(require_optional = TRUE)$status == "success"),
    error = function(e) FALSE
  )

  data.table::data.table(
    check = c(
      "package_metadata_valid",
      "namespace_exports_supported_api",
      "user_data_paths_created",
      "package_resources_available",
      "build_week_data_resource",
      "rscript_discovered",
      "launcher_path_stable",
      "package_electron_resource",
      "diagnostics_structured",
      "dependency_capability_qa"
    ),
    status = c(
      if (nzchar(info$package_version)) "success" else "error",
      if (export_status) "success" else "error",
      if (all(dir.exists(unlist(paths[c("user_data", "config", "logs", "projects", "exports", "cache", "runtime")])))) "success" else "error",
      if (dir.exists(workstation_resource_path("www", mustWork = FALSE)) && dir.exists(workstation_resource_path("config", mustWork = FALSE))) "success" else "error",
      if (file.exists(build_week_demo_data_path())) "success" else "error",
      if (!is.na(rscript) && file.exists(rscript)) "success" else "error",
      if (grepl("AppData/Local/Programs/Analytics Workstation", paths$launcher, fixed = TRUE)) "success" else "error",
      if (file.exists(workstation_package_path("electron", "main.js", mustWork = FALSE))) "success" else "error",
      if (data.table::is.data.table(diagnostics) && all(c("item", "status", "value") %in% names(diagnostics))) "success" else "error",
      if (dependency_status) "success" else "error"
    ),
    message = c(
      "Package metadata is readable.",
      "Supported workstation API is exported.",
      "Per-user writable directories are created outside the package.",
      "Immutable UI and config resources are available from the package resource tree.",
      "Build Week demo data is available from package resources without exposing ground truth.",
      "A compatible Rscript executable is discoverable.",
      "Launcher path points to the stable per-user program location.",
      "Electron shell resources are available from package resources.",
      "Diagnostics return a structured table.",
      "Required and optional development capability packages are available."
    )
  )
}

qa_electron_distribution <- function() {
  paths <- workstation_standard_dirs(create = TRUE)
  package_electron <- workstation_package_resource("electron")
  installed_electron <- file.path(paths[["program"]], "electron")
  node <- workstation_find_command("node")
  npm <- workstation_find_command("npm")
  node_message <- if (!is.na(node)) {
    "Node.js is available for Electron dependency installation."
  } else {
    "Node.js is unavailable; Electron dependency installation is skipped."
  }
  npm_message <- if (!is.na(npm)) {
    "npm is available for Electron dependency installation."
  } else {
    "npm is unavailable; Electron dependency installation is skipped."
  }

  data.table::data.table(
    check = c(
      "package_electron_directory",
      "package_electron_main",
      "package_electron_manifest",
      "installed_electron_directory",
      "node_available",
      "npm_available",
      "launcher_command_path",
      "owned_process_log_directory"
    ),
    status = c(
      if (!is.na(package_electron) && dir.exists(package_electron)) "success" else "error",
      if (file.exists(workstation_package_path("electron", "main.js", mustWork = FALSE))) "success" else "error",
      if (file.exists(workstation_package_path("electron", "package.json", mustWork = FALSE))) "success" else "error",
      if (dir.exists(installed_electron)) "success" else "warning",
      if (!is.na(node)) "success" else "warning",
      if (!is.na(npm)) "success" else "warning",
      if (grepl("Analytics Workstation.cmd", paths[["launcher"]], fixed = TRUE)) "success" else "error",
      if (dir.exists(paths[["logs"]])) "success" else "error"
    ),
    message = c(
      "Electron resources are included in the R package resource tree.",
      "Electron main process script is discoverable.",
      "Electron package manifest is discoverable.",
      "Prepared Electron desktop directory exists after installation.",
      node_message,
      npm_message,
      "Launcher uses the stable per-user program directory.",
      "Launch logs have a writable per-user destination."
    )
  )
}
