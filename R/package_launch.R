run_workstation <- function(app_dir = NULL, port = NULL, host = "127.0.0.1", launch.browser = TRUE) {
  if (is.null(app_dir) || !nzchar(app_dir)) {
    installed_source <- workstation_standard_dirs(create = TRUE)[["app_source"]]
    if (dir.exists(installed_source) && file.exists(file.path(installed_source, "app.R"))) {
      app_dir <- installed_source
    } else if (file.exists(file.path(getwd(), "app.R"))) {
      app_dir <- getwd()
    } else {
      stop("Analytics Workstation app source was not found. Run scripts/install_workstation.R or install_windows.ps1.", call. = FALSE)
    }
  }

  app_dir <- normalizePath(app_dir, winslash = "/", mustWork = TRUE)
  if (is.null(port)) {
    port <- as.integer(Sys.getenv("ANALYTICS_WORKSTATION_PORT", unset = "0"))
  }

  old <- getwd()
  on.exit(setwd(old), add = TRUE)
  setwd(app_dir)
  shiny::runApp(".", port = port, host = host, launch.browser = launch.browser)
}

launch_workstation <- function(prefer_desktop = TRUE) {
  info <- workstation_installation_info(create = TRUE)
  launcher <- info$paths$launcher

  if (isTRUE(prefer_desktop) && file.exists(launcher)) {
    shell.exec(launcher)
    return(invisible(service_result(
      status = "success",
      messages = "Analytics Workstation launcher opened.",
      metadata = list(launcher = launcher)
    )))
  }

  run_workstation()
}
