report_browser_test_env <- function() {
  asNamespace("AnalyticsShinyApp")
}

test_that("interactive report browser renders validated report contracts", {
  app <- report_browser_test_env()

  qa <- app$qa_report_browser()
  expect_true(nrow(qa) >= 10)
  expect_false(any(qa$status != "success"), info = paste(qa$check[qa$status != "success"], collapse = "; "))
})

test_that("report browser registry covers the ReportContract component surface", {
  app <- report_browser_test_env()
  registry <- app$report_browser_component_registry()

  expect_true(all(app$report_component_types %in% names(registry)))
  expect_true(is.function(registry$unknown))
})

test_that("report browser exposes navigation, findings, and section components", {
  app <- report_browser_test_env()
  report <- app$report_browser_demo_reports()$Regression
  html <- as.character(htmltools::renderTags(app$render_report_browser(report))$html)

  expect_match(html, "aq-report-browser-nav", fixed = TRUE)
  expect_match(html, "aq-report-browser-findings", fixed = TRUE)
  expect_match(html, "aq-report-browser-section", fixed = TRUE)
  expect_match(html, "aq-report-browser-component", fixed = TRUE)
})

test_that("report browser degrades gracefully for malformed contracts", {
  app <- report_browser_test_env()
  rendered <- app$render_report_browser(list(title = "Bad report"))
  html <- as.character(htmltools::renderTags(rendered)$html)

  expect_match(html, "Invalid report record", fixed = TRUE)
})
