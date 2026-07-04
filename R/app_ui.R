build_app_ui <- function() {
  fluidPage(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "app.css")),
    ui_app_shell(
      theme = "light",
      titlePanel("Analytics Shiny App"),
      tabsetPanel(
        id = "main_tabs",
        page_project_ui("project"),
        page_data_ui("data"),
        page_plot_builder_ui("plot_builder"),
        page_artifact_library_ui("artifact_library"),
        page_layouts_ui("layouts"),
        page_export_ui("export")
      )
    )
  )
}
