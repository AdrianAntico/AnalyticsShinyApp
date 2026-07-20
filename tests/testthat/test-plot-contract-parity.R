plot_contract_test_env <- function() {
  if (exists("load_test_app_env", mode = "function")) {
    return(load_test_app_env())
  }

  candidates <- c(
    "app.R",
    file.path("..", "..", "app.R"),
    file.path("..", "..", "..", "app.R")
  )
  app_file <- candidates[file.exists(candidates)][1]
  if (is.na(app_file)) {
    stop("Could not locate app.R for plot contract parity tests.")
  }
  app_file <- normalizePath(app_file, winslash = "/", mustWork = TRUE)
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(dirname(app_file))
  source(app_file, local = .GlobalEnv)
  get("app_env", envir = .GlobalEnv, inherits = FALSE)
}

test_that("Visual Studio plot contracts match installed AutoPlots functions", {
  app <- plot_contract_test_env()
  qa <- get("qa_plot_contract_parity", envir = app, inherits = FALSE)()
  plot_types <- get("plot_types", envir = app, inherits = FALSE)

  expect_true(nrow(qa) >= 4L * length(plot_types))
  expect_false(any(qa$status != "success"), info = paste(qa$check[qa$status != "success"], collapse = "; "))
})

test_that("Visual Studio plot runtime rejects leaks and missing mappings", {
  app <- plot_contract_test_env()
  qa <- get("qa_plot_runtime_integrity", envir = app, inherits = FALSE)()
  plot_types <- get("plot_types", envir = app, inherits = FALSE)

  expect_true(nrow(qa) >= 4L * length(plot_types))
  expect_false(any(qa$status != "success"), info = paste(qa$check[qa$status != "success"], collapse = "; "))
})
