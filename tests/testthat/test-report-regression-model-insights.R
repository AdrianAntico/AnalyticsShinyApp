source_app_for_regression_report_tests <- function() {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)
  source("app.R", local = globalenv())
}

regression_report_fixture_result <- function() {
  artifact_table <- app_env$create_artifact(
    artifact_id = "rmi_metrics_table",
    artifact_type = "table",
    label = "Model Metrics",
    source_module = "autoquant_regression_model_insights",
    object = data.table::data.table(metric = c("RMSE", "MAE"), value = c(1.2, 0.9)),
    metadata = list(created_by_module = TRUE, module_id = "autoquant_regression_model_insights", recommended_caption = "Model Metrics"),
    section = "Prediction Diagnostics"
  )
  artifact_plot <- app_env$create_artifact(
    artifact_id = "rmi_residual_plot",
    artifact_type = "plot",
    label = "Residual Plot",
    source_module = "autoquant_regression_model_insights",
    metadata = list(created_by_module = TRUE, module_id = "autoquant_regression_model_insights", recommended_caption = "Residual Plot"),
    section = "Residual Diagnostics"
  )
  artifact_text <- app_env$create_artifact(
    artifact_id = "rmi_summary_text",
    artifact_type = "text",
    label = "Model Summary Narrative",
    source_module = "autoquant_regression_model_insights",
    content = "Regression diagnostics were generated from existing model predictions.",
    metadata = list(created_by_module = TRUE, module_id = "autoquant_regression_model_insights", key_finding = "Regression diagnostics are available for review."),
    section = "Model Overview"
  )
  app_env$service_result(
    status = "success",
    value = list(source = "fixture"),
    artifacts = list(artifact_table, artifact_plot, artifact_text),
    metadata = list(module_run_id = "rmi_fixture_run", source_function = "fixture", configured_inputs = list(target_column = "y", prediction_column = "pred"))
  )
}

testthat::test_that("Regression Model Insights adapter creates a valid ReportContract", {
  source_app_for_regression_report_tests()
  report <- app_env$build_regression_model_insights_report(regression_report_fixture_result())
  validation <- app_env$validate_report(report)

  testthat::expect_s3_class(report, "report_contract")
  testthat::expect_identical(report$report_type, "regression_model_insights")
  testthat::expect_identical(validation$status, "success")
  testthat::expect_gte(length(report$components), 8L)
  testthat::expect_gte(length(report$findings), 2L)
  testthat::expect_gte(length(report$evidence_links), 3L)
})

testthat::test_that("Regression Model Insights adapter preserves semantic components without rendering", {
  source_app_for_regression_report_tests()
  report <- app_env$build_regression_model_insights_report(regression_report_fixture_result())
  component_types <- vapply(report$components, function(component) component$component_type, character(1))

  testthat::expect_true("visualization" %in% component_types)
  testthat::expect_true("table" %in% component_types)
  testthat::expect_true("methodology" %in% component_types)
  testthat::expect_true("technical_appendix" %in% component_types)
  testthat::expect_false(any(component_types %in% c("html", "pdf", "docx", "shiny")))
})

testthat::test_that("Regression Model Insights adapter round-trips and degrades missing inputs", {
  source_app_for_regression_report_tests()
  result <- regression_report_fixture_result()
  report <- app_env$build_regression_model_insights_report(result)
  restored <- app_env$deserialize_report(app_env$serialize_report(report))
  testthat::expect_identical(app_env$validate_report(restored)$status, "success")

  result$artifacts <- list(result$artifacts[[1]])
  missing_report <- app_env$build_regression_model_insights_report(result)
  component_ids <- vapply(missing_report$components, function(component) component$component_id, character(1))
  testthat::expect_true("missing_regression_visualizations" %in% component_ids)
  testthat::expect_identical(app_env$validate_report(missing_report)$status, "success")
})

