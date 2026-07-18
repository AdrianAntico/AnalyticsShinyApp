run_workstation <- function(
  host = "127.0.0.1",
  port = NULL,
  launch_browser = TRUE,
  options = list(),
  app_dir = NULL,
  launch.browser = NULL
) {
  if (!is.null(launch.browser)) {
    launch_browser <- launch.browser
  }
  if (!is.null(app_dir)) {
    warning("app_dir is ignored. Analytics Workstation now launches from installed package resources.", call. = FALSE)
  }
  if (is.null(port)) {
    port <- suppressWarnings(as.integer(Sys.getenv("ANALYTICS_WORKSTATION_PORT", unset = "0")))
    if (is.na(port)) {
      port <- 0L
    }
  }

  app <- workstation_app(options = options)
  shiny::runApp(app, port = port, host = host, launch.browser = launch_browser)
}

launch_workstation <- function(prefer_desktop = TRUE, ...) {
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

  run_workstation(...)
}
