workstation_register_resource_paths <- function() {
  www_path <- workstation_resource_path("www", mustWork = TRUE)
  if (is.na(www_path) || !dir.exists(www_path)) {
    stop("Analytics Workstation UI resources were not found in the installed package.", call. = FALSE)
  }

  suppressWarnings(try(shiny::removeResourcePath("aw-assets"), silent = TRUE))
  shiny::addResourcePath("aw-assets", www_path)
  invisible(www_path)
}

workstation_app <- function(options = list()) {
  workstation_initialize_user_dirs(create = TRUE)
  workstation_register_resource_paths()
  options(shiny.maxRequestSize = MAX_UPLOAD_MB * 1024^2)
  shiny::shinyApp(ui = build_app_ui(), server = server, options = options)
}
