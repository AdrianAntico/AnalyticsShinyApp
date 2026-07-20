test_that("Plot Studio inspector draft workflow is guarded", {
  qa <- qa_inspector_draft_workflow()
  expect_true(
    all(qa[["status"]] == "success"),
    info = paste(capture.output(print(qa)), collapse = "\n")
  )
})
