test_that("project persistence accepts paths outside the package tree", {
  project_dir <- AnalyticsShinyApp:::workstation_user_path("projects", "Package Path QA", create = TRUE)
  project_path <- file.path(project_dir, "path qa project.rds")
  project <- list(
    app_version = AnalyticsShinyApp:::APP_VERSION,
    saved_at = Sys.time(),
    plot_configs = list(),
    plot_code = list(),
    plot_metadata = list(),
    layout_type = "Grid",
    layout_cols = 2L,
    export_dir = project_dir,
    export_name = "path_qa_project"
  )

  AnalyticsShinyApp:::save_project_state(project, project_path, allow_unsafe_dev_fixture = TRUE)
  loaded <- readRDS(project_path)

  expect_true(file.exists(project_path))
  expect_equal(loaded$app_version, AnalyticsShinyApp:::APP_VERSION)
  expect_equal(normalizePath(loaded$export_dir, winslash = "/", mustWork = FALSE), normalizePath(project_dir, winslash = "/", mustWork = FALSE))
})
