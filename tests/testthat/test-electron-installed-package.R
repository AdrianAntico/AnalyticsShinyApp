test_that("Electron launches the installed package rather than copied app source", {
  main_js <- AnalyticsShinyApp:::workstation_package_path("electron", "main.js", mustWork = TRUE)
  script <- paste(readLines(main_js, warn = FALSE), collapse = "\n")

  expect_match(script, "AnalyticsShinyApp::run_workstation", fixed = TRUE)
  expect_false(grepl("shiny::runApp\\('\\.'", script))
  expect_false(grepl("ANALYTICS_WORKSTATION_APP_SOURCE", script, fixed = TRUE))
})

