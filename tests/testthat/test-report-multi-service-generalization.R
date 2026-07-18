source_app_for_multi_service_report_tests <- function() {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = TRUE)
  old <- setwd(root)
  on.exit(setwd(old), add = TRUE)
  source("app.R", local = globalenv())
}

testthat::test_that("SHAP Analysis adapter creates a valid renderer-free ReportContract", {
  source_app_for_multi_service_report_tests()
  qa <- app_env$qa_shap_analysis_report_contract()

  testthat::expect_true(all(qa$status == "success"))

  config <- app_env$create_shap_analysis_config(
    problem_type = "regression",
    target_col = "y",
    prediction_col = "pred",
    feature_cols = c("spend", "clicks"),
    shap_prefix = "Shap_"
  )
  artifact <- app_env$create_artifact(
    artifact_id = "shap_importance_table_test",
    artifact_type = "table",
    label = "Global SHAP Importance",
    source_module = "autoquant_regression_shap_analysis",
    object = data.table::data.table(feature = "spend", mean_abs_shap = 0.42),
    metadata = app_env$create_shap_artifact_metadata(config, lens = "global_importance", section = "Global Importance"),
    section = "Global Importance"
  )
  report <- app_env$build_shap_analysis_report(app_env$service_result(
    status = "success",
    artifacts = list(artifact),
    metadata = list(module_run_id = "shap_test", configured_inputs = config)
  ))
  component_types <- vapply(report$components, function(component) component$component_type, character(1))

  testthat::expect_s3_class(report, "report_contract")
  testthat::expect_identical(report$report_type, "shap_analysis")
  testthat::expect_identical(app_env$validate_report(report)$status, "success")
  testthat::expect_true("table" %in% component_types)
  testthat::expect_false(any(component_types %in% c("html", "pdf", "docx", "shiny")))
})

testthat::test_that("EDA adapter creates a valid renderer-free ReportContract", {
  source_app_for_multi_service_report_tests()
  qa <- app_env$qa_eda_report_contract()

  testthat::expect_true(all(qa$status == "success"))

  artifact <- app_env$create_artifact(
    artifact_id = "eda_distribution_plot_test",
    artifact_type = "plot",
    label = "Revenue Distribution",
    source_module = "autoquant_eda",
    metadata = list(module_id = "autoquant_eda", recommended_caption = "Revenue Distribution"),
    section = "Univariate Analysis"
  )
  report <- app_env$build_eda_report(app_env$service_result(
    status = "success",
    artifacts = list(artifact),
    metadata = list(module_run_id = "eda_test", configured_inputs = list(DataName = "qa"))
  ))
  component_types <- vapply(report$components, function(component) component$component_type, character(1))

  testthat::expect_s3_class(report, "report_contract")
  testthat::expect_identical(report$report_type, "exploratory_data_analysis")
  testthat::expect_identical(app_env$validate_report(report)$status, "success")
  testthat::expect_true("visualization" %in% component_types)
  testthat::expect_false(any(component_types %in% c("html", "pdf", "docx", "shiny")))
})

testthat::test_that("three materially different report families share validation and serialization semantics", {
  source_app_for_multi_service_report_tests()
  reports <- list(
    regression = app_env$build_regression_model_insights_report(app_env$service_result(status = "warning", artifacts = list(), metadata = list(module_run_id = "rmi_empty"))),
    shap = app_env$build_shap_analysis_report(app_env$service_result(status = "warning", artifacts = list(), metadata = list(module_run_id = "shap_empty", configured_inputs = list(problem_type = "regression")))),
    eda = app_env$build_eda_report(app_env$service_result(status = "warning", artifacts = list(), metadata = list(module_run_id = "eda_empty")))
  )

  for (report in reports) {
    testthat::expect_s3_class(report, "report_contract")
    testthat::expect_identical(app_env$validate_report(report)$status, "success")
    restored <- app_env$deserialize_report(app_env$serialize_report(report))
    testthat::expect_identical(app_env$validate_report(restored)$status, "success")
    testthat::expect_gte(length(report$findings), 1L)
  }
})
