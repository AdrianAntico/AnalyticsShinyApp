build_app_ui <- function() {
  css_file <- file.path("www", "app.css")
  css_version <- if (file.exists(css_file)) {
    as.integer(file.info(css_file)$mtime)
  } else {
    APP_VERSION
  }
  fluidPage(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = paste0("app.css?v=", css_version))),
    ui_app_shell(
      theme = "dark",
      titlePanel("Analytics Workstation"),
      ui_command_palette("command_palette"),
      tabsetPanel(
        id = "main_tabs",
        page_mission_control_ui("mission_control"),
        page_project_ui("project"),
        page_data_ui("data"),
        page_plot_builder_ui("plot_builder"),
        page_workflow_ui("workflow"),
        page_analysis_modules_ui("analysis_modules"),
        page_code_runner_ui("code_runner"),
        page_artifact_library_ui("artifact_library"),
        page_layouts_ui("layouts"),
        page_export_ui("export")
      )
    )
  )
}
