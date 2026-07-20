test_that("Plot Studio has bounded responsive production controls", {
  qa <- qa_plot_studio_responsiveness()
  failed <- qa$check[qa$status != "success"]
  expect_false(length(failed) > 0L, info = paste(failed, collapse = ", "))
})
