args <- commandArgs(trailingOnly = TRUE)
user_data <- file.path(Sys.getenv("LOCALAPPDATA"), "AnalyticsWorkstation")
log_dir <- file.path(user_data, "logs")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

pid_file <- file.path(log_dir, "launcher-shiny.pid")
log_file <- file.path(log_dir, "launcher-shiny.log")
writeLines(as.character(Sys.getpid()), pid_file)

sink(log_file, append = TRUE, split = TRUE)
on.exit(sink(), add = TRUE)
message("Starting Analytics Workstation from installed AnalyticsShinyApp package")
port <- suppressWarnings(as.integer(Sys.getenv("ANALYTICS_WORKSTATION_PORT", unset = "0")))
AnalyticsShinyApp::run_workstation(host = "127.0.0.1", port = port, launch_browser = TRUE)
