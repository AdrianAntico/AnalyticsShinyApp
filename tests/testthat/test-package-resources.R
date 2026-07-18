test_that("package resources are immutable package assets", {
  www <- AnalyticsShinyApp:::workstation_resource_path("www", mustWork = TRUE)
  config <- AnalyticsShinyApp:::workstation_resource_path("config", mustWork = TRUE)
  demo_data <- AnalyticsShinyApp:::build_week_demo_data_path()

  expect_true(dir.exists(www))
  expect_true(file.exists(file.path(www, "app.css")))
  expect_true(file.exists(file.path(www, "brand", "analytics-workstation-mark.svg")))
  expect_true(dir.exists(config))
  expect_true(file.exists(demo_data))
  expect_false(grepl("build_week_demo_ground_truth", demo_data, fixed = TRUE))
})

test_that("user state paths are outside installed package resources", {
  info <- AnalyticsShinyApp::workstation_installation_info(create = TRUE)
  user_data <- normalizePath(info$paths$user_data, winslash = "/", mustWork = FALSE)
  package_path <- normalizePath(info$package_path, winslash = "/", mustWork = FALSE)

  expect_true(dir.exists(user_data))
  expect_false(startsWith(user_data, package_path))
  expect_true(all(dir.exists(unlist(info$paths[c("config", "projects", "exports", "logs", "cache", "runtime")]))))
})

