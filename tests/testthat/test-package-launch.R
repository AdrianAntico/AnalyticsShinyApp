test_that("workstation app factory builds without changing the working directory", {
  old <- getwd()
  app <- AnalyticsShinyApp:::workstation_app()

  expect_s3_class(app, "shiny.appobj")
  expect_equal(getwd(), old)
})

