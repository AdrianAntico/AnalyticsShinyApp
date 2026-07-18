test_that("central path helpers return normalized paths", {
  package_path <- AnalyticsShinyApp:::workstation_package_path(mustWork = FALSE)
  resource_path <- AnalyticsShinyApp:::workstation_resource_path(mustWork = FALSE)
  user_path <- AnalyticsShinyApp:::workstation_user_path("projects", "Example Project", create = TRUE)
  runtime_path <- AnalyticsShinyApp:::workstation_runtime_path("health", create = TRUE)

  expect_match(package_path, "/", fixed = TRUE)
  expect_match(resource_path, "/", fixed = TRUE)
  expect_match(user_path, "/", fixed = TRUE)
  expect_match(runtime_path, "/", fixed = TRUE)
  expect_true(dir.exists(dirname(user_path)))
  expect_true(dir.exists(dirname(runtime_path)))
})

