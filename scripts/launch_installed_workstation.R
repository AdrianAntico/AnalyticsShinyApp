args <- commandArgs(trailingOnly = TRUE)
app_source <- Sys.getenv("ANALYTICS_WORKSTATION_APP_SOURCE", unset = "")
if (!nzchar(app_source) && length(args)) {
  app_source <- args[[1]]
}
if (!nzchar(app_source)) {
  app_source <- file.path(Sys.getenv("LOCALAPPDATA"), "Programs", "Analytics Workstation", "app-source")
}

app_source <- normalizePath(app_source, winslash = "/", mustWork = TRUE)
user_data <- file.path(Sys.getenv("LOCALAPPDATA"), "AnalyticsWorkstation")
log_dir <- file.path(user_data, "logs")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

pid_file <- file.path(log_dir, "launcher-shiny.pid")
log_file <- file.path(log_dir, "launcher-shiny.log")
writeLines(as.character(Sys.getpid()), pid_file)

sink(log_file, append = TRUE, split = TRUE)
on.exit(sink(), add = TRUE)
message("Starting Analytics Workstation from ", app_source)
setwd(app_source)
port <- suppressWarnings(as.integer(Sys.getenv("ANALYTICS_WORKSTATION_PORT", unset = "0")))
shiny::runApp(".", host = "127.0.0.1", port = port, launch.browser = TRUE)
