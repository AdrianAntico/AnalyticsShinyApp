load_test_app_env <- function() {
  if (exists("app_env", envir = .GlobalEnv, inherits = FALSE)) {
    return(get("app_env", envir = .GlobalEnv, inherits = FALSE))
  }

  candidates <- c(
    "app.R",
    file.path("..", "..", "app.R"),
    file.path("..", "..", "..", "app.R")
  )
  app_file <- candidates[file.exists(candidates)][1]

  if (is.na(app_file) && "AnalyticsShinyApp" %in% loadedNamespaces()) {
    return(asNamespace("AnalyticsShinyApp"))
  }

  if (is.na(app_file)) {
    stop("Could not locate app.R for Analytics Workstation tests.", call. = FALSE)
  }

  app_file <- normalizePath(app_file, winslash = "/", mustWork = TRUE)
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(dirname(app_file))
  source(app_file, local = .GlobalEnv)
  get("app_env", envir = .GlobalEnv, inherits = FALSE)
}

app_env <- load_test_app_env()
