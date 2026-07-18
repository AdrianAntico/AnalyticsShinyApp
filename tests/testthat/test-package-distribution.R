test_that("distribution paths are per-user and writable", {
  paths <- AnalyticsShinyApp:::workstation_standard_dirs(create = TRUE)

  expect_true(grepl("AnalyticsWorkstation", paths[["user_data"]], fixed = TRUE))
  expect_true(grepl("Programs/Analytics Workstation", paths[["program"]], fixed = TRUE))
  expect_true(all(dir.exists(unname(paths[c("user_data", "config", "logs", "projects", "exports", "cache", "runtime")]))))
  expect_false(grepl(normalizePath(getwd(), winslash = "/", mustWork = FALSE), paths[["user_data"]], fixed = TRUE))
})

test_that("public package API and diagnostics are available", {
  expect_true(is.function(AnalyticsShinyApp::run_workstation))
  expect_true(is.function(AnalyticsShinyApp::launch_workstation))
  expect_true(is.function(AnalyticsShinyApp::workstation_diagnostics))
  expect_true(is.function(AnalyticsShinyApp::workstation_installation_info))

  diagnostics <- AnalyticsShinyApp::workstation_diagnostics(create = TRUE)
  expect_s3_class(diagnostics, "data.table")
  expect_true(all(c("item", "status", "value") %in% names(diagnostics)))
  expect_true(any(diagnostics$item == "Rscript"))
  expect_true(any(diagnostics$item == "npm"))
})

test_that("package distribution QA returns explicit status rows", {
  qa <- AnalyticsShinyApp::qa_package_distribution()

  expect_s3_class(qa, "data.table")
  expect_true(all(c("check", "status", "message") %in% names(qa)))
  expect_true(all(qa$status %in% c("success", "error", "warning", "needs_input", "skipped")))
  expect_true("package_metadata_valid" %in% qa$check)
  expect_true("dependency_capability_qa" %in% qa$check)
})
