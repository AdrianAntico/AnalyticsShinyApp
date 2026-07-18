package_distribution_test_env <- function() {
  env <- new.env(parent = globalenv())
  oldwd <- getwd()
  on.exit(setwd(oldwd), add = TRUE)
  setwd(normalizePath(file.path("..", ".."), winslash = "/", mustWork = TRUE))
  source("app.R", local = env)
  env$app_env
}

test_that("distribution paths are per-user and writable", {
  app <- package_distribution_test_env()
  paths <- app$workstation_standard_dirs(create = TRUE)

  expect_true(grepl("AnalyticsWorkstation", paths[["user_data"]], fixed = TRUE))
  expect_true(grepl("Programs/Analytics Workstation", paths[["program"]], fixed = TRUE))
  expect_true(all(dir.exists(unname(paths[c("user_data", "config", "logs", "projects", "exports", "cache", "runtime")]))))
  expect_false(grepl(normalizePath(getwd(), winslash = "/", mustWork = FALSE), paths[["user_data"]], fixed = TRUE))
})

test_that("public package API and diagnostics are available", {
  app <- package_distribution_test_env()

  expect_true(is.function(app$run_workstation))
  expect_true(is.function(app$launch_workstation))
  expect_true(is.function(app$workstation_diagnostics))
  expect_true(is.function(app$workstation_installation_info))

  diagnostics <- app$workstation_diagnostics(create = TRUE)
  expect_s3_class(diagnostics, "data.table")
  expect_true(all(c("item", "status", "value") %in% names(diagnostics)))
  expect_true(any(diagnostics$item == "Rscript"))
  expect_true(any(diagnostics$item == "npm"))
})

test_that("package distribution QA returns explicit status rows", {
  app <- package_distribution_test_env()
  qa <- app$qa_package_distribution()

  expect_s3_class(qa, "data.table")
  expect_true(all(c("check", "status", "message") %in% names(qa)))
  expect_true(all(qa$status %in% c("success", "error", "warning", "needs_input", "skipped")))
  expect_true("package_metadata_valid" %in% qa$check)
  expect_true("dependency_capability_qa" %in% qa$check)
})
