repo_root <- normalizePath(file.path("..", ".."), mustWork = TRUE)
setwd(repo_root)

port <- suppressWarnings(as.integer(Sys.getenv("AW_RECORDING_PORT", unset = "3899")))
if (is.na(port) || port <= 0L) {
  port <- 3899L
}

app <- source("app.R")$value
shiny::runApp(app, host = "127.0.0.1", port = port, launch.browser = FALSE)
