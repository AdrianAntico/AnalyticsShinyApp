source_app_for_report_tests <- function() {
  assign("app_env", asNamespace("AnalyticsShinyApp"), envir = globalenv())
}

testthat::test_that("ReportContract runtime constructs, validates, and round-trips", {
  source_app_for_report_tests()

  report <- app_env$create_report_contract(
    report_id = "test_report",
    title = "Test Report",
    report_type = "test",
    capabilities = c("interactive", "evidence_trace")
  )
  report <- app_env$add_component(report, app_env$report_component_title("Test Report"), section_id = "summary")
  report <- app_env$add_component(report, app_env$report_component_table(table_ref = "table_1"), section_id = "summary")

  validation <- app_env$validate_report(report)
  testthat::expect_identical(validation$status, "success")

  json <- app_env$serialize_report(report)
  restored <- app_env$deserialize_report(json)
  testthat::expect_s3_class(restored, "report_contract")
  testthat::expect_identical(restored$report_id, report$report_id)
  testthat::expect_identical(app_env$validate_report(restored)$status, "success")
})

testthat::test_that("ReportContract validation rejects malformed runtime objects", {
  source_app_for_report_tests()

  duplicate <- app_env$create_report_contract(report_id = "dup", title = "Duplicate Test")
  component <- app_env$report_component_title("Duplicate Test")
  duplicate$components <- list(component, component)

  validation <- app_env$validate_report(duplicate)
  testthat::expect_identical(validation$status, "error")
  testthat::expect_true(any(grepl("Duplicate report component IDs", validation$errors)))

  bad_capability <- app_env$validate_capabilities(c("interactive", "not_real"))
  testthat::expect_identical(bad_capability$status, "error")

  bad_component <- app_env$create_report_component("table", component_id = "bad_table", payload = list())
  testthat::expect_identical(app_env$validate_report_component(bad_component)$status, "error")
})
