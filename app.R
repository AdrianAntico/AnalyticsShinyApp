app_env <- new.env(parent = globalenv())

source(file.path("R", "utils_paths.R"), local = app_env)

dependency_check <- app_env$check_app_dependencies()
if (!isTRUE(dependency_check$ok)) {
  stop(paste(dependency_check$messages, collapse = "\n"), call. = FALSE)
}

library(shiny)
library(AutoPlots)

app_env$APP_VERSION <- "0.1.0"
app_env$MAX_UPLOAD_MB <- 50
options(shiny.maxRequestSize = app_env$MAX_UPLOAD_MB * 1024^2)

source(file.path("R", "service_result.R"), local = app_env)
source(file.path("R", "registry_plots.R"), local = app_env)
source(file.path("R", "registry_options.R"), local = app_env)
source(file.path("R", "service_export.R"), local = app_env)
source(file.path("R", "service_plot.R"), local = app_env)
source(file.path("R", "project_state.R"), local = app_env)
source(file.path("R", "service_project.R"), local = app_env)
source(file.path("R", "project_bundle.R"), local = app_env)
source(file.path("R", "utils_messages.R"), local = app_env)
source(file.path("R", "app_ui.R"), local = app_env)
source(file.path("R", "app_server.R"), local = app_env)

ui <- app_env$build_app_ui()
server <- app_env$server

shinyApp(ui, server)
