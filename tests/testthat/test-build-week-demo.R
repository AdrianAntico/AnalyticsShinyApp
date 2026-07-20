build_week_test_env <- function() {
  load_test_app_env()
}

test_that("Build Week preflight and campaign path are deterministic", {
  app <- build_week_test_env()
  demo_a <- app$generate_build_week_demo_data(write_files = FALSE, seed = 20260717L)$data
  demo_b <- app$generate_build_week_demo_data(write_files = FALSE, seed = 20260717L)$data
  expect_identical(demo_a, demo_b)
  expect_identical(names(demo_a), app$build_week_demo_schema())
  expect_equal(nrow(demo_a), 80L)
  expect_equal(ncol(demo_a), 9L)
  expect_identical(app$validate_build_week_demo_data(demo_a)$status, "success")

  mock_config <- app$build_week_demo_config(provider = "mock", model = "mock-model")
  preflight <- app$build_week_demo_preflight(config = mock_config, check_provider = TRUE)
  expect_true(is.list(preflight))
  expect_true("status" %in% names(preflight))
  expect_true(nrow(preflight$value) >= 6)
  expect_true(any(preflight$value$check == "Provider" & preflight$value$status == "success"))

  launched <- app$build_week_demo_launch(provider_config = mock_config, preset = "Instant", approve_shap = TRUE)
  expect_identical(launched$status, "success")
  expect_identical(launched$value$status, "completed")
  expect_identical(app$validate_report(launched$value$report_contract)$status, "success")
  expect_identical(app$validate_inquiry_state(launched$value$inquiry, require_complete = TRUE)$status, "success")
  expect_gte(length(launched$value$inquiry$explanations), 3)
  expect_gte(length(launched$value$inquiry$candidate_investigations), 3)
  expect_true(nzchar(launched$value$inquiry$selected_investigation_id))
  expect_gte(length(launched$value$inquiry$belief_revisions), 2)
  expect_gte(length(launched$value$inquiry$recommendation_revisions), 2)
  expect_gt(length(launched$value$inquiry$remaining_uncertainty), 0)
  expect_true(is.list(launched$value$inquiry$integrity_review))
  expect_true(nzchar(launched$value$inquiry$integrity_review$executive_summary))
  expect_true(nzchar(launched$value$inquiry$integrity_review$decision_readiness$status))

  trace <- app$agent_campaign_claim_trace(launched$value)
  expect_identical(trace$status, "success")
  expect_gt(length(trace$value$evidence_ids), 0)
  expect_true(nzchar(trace$value$initial_belief))
  expect_gt(length(trace$value$belief_revisions), 0)
  expect_true(nzchar(trace$value$final_conclusion))
  expect_gt(length(trace$value$remaining_uncertainty), 0)
  expect_true(is.list(trace$value$integrity_review))
  expect_true(nzchar(trace$value$integrity_review$recommendation_robustness$confidence))
})

test_that("OpenAI GPT-5.6 setup failures are visible and nonfatal", {
  app <- build_week_test_env()
  config <- app$build_week_demo_config(provider = "openai", model = "gpt-5.6", api_key = "")
  status <- app$genai_provider_status(config, check_availability = TRUE)
  expect_identical(status$status, "needs_input")
  expect_identical(status$metadata$diagnostic_reason, "api_key_missing")
  expect_false(isTRUE(status$value$available))
})

test_that("QA helper reports the Build Week demo contract", {
  app <- build_week_test_env()
  qa <- app$qa_build_week_demo()
  expect_true(all(qa$status == "success"))
})
