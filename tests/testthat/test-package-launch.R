test_that("workstation app factory builds without changing the working directory", {
  old <- getwd()
  app <- AnalyticsShinyApp:::workstation_app()

  expect_s3_class(app, "shiny.appobj")
  expect_equal(getwd(), old)
})

test_that("workstation launch resolves browser-safe localhost ports", {
  old <- Sys.getenv("ANALYTICS_WORKSTATION_PORT", unset = NA_character_)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("ANALYTICS_WORKSTATION_PORT")
    } else {
      Sys.setenv(ANALYTICS_WORKSTATION_PORT = old)
    }
  }, add = TRUE)

  Sys.setenv(ANALYTICS_WORKSTATION_PORT = "0")
  expect_gt(AnalyticsShinyApp:::workstation_resolve_port(NULL), 0L)
  expect_gt(AnalyticsShinyApp:::workstation_resolve_port(0), 0L)
  expect_gt(AnalyticsShinyApp:::workstation_resolve_port(NA), 0L)
  expect_equal(AnalyticsShinyApp:::workstation_resolve_port(4791), 4791L)
})
