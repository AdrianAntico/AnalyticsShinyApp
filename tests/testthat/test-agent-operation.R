agent_operation_test_env <- function() {
  asNamespace("AnalyticsShinyApp")
}

test_that("agent operation runtime QA passes", {
  app <- agent_operation_test_env()
  checks <- app$qa_agent_operation_runtime()
  expect_false(any(checks$status == "error"), info = paste(checks$message[checks$status == "error"], collapse = "\n"))
})

test_that("agent session lifecycle rejects illegal transitions", {
  app <- agent_operation_test_env()
  session <- app$create_agent_session("Lifecycle QA")
  expect_error(app$agent_session_transition(session, "completed"), "Illegal AgentSession transition")
  session <- app$agent_session_transition(session, "planning")
  session <- app$agent_session_transition(session, "running")
  session <- app$agent_session_pause(session)
  expect_equal(session$status, "paused")
  session <- app$agent_session_resume(session)
  expect_equal(session$status, "running")
})

test_that("funnel driver campaign handles approval, rejection, and invalid data", {
  app <- agent_operation_test_env()
  approved <- app$run_funnel_driver_investigation(approve_shap = TRUE)
  expect_equal(approved$status, "success")
  expect_equal(approved$value$status, "completed")
  expect_true(any(vapply(approved$value$service_runs, function(run) identical(run$service_id, "shap_analysis"), logical(1))))
  expect_equal(app$validate_inquiry_state(approved$value$inquiry, require_complete = TRUE)$status, "success")
  expect_true(length(approved$value$inquiry$belief_revisions) >= 2)

  rejected <- app$run_funnel_driver_investigation(approve_shap = FALSE)
  expect_equal(rejected$status, "success")
  expect_equal(rejected$value$status, "completed")
  expect_false(any(vapply(rejected$value$service_runs, function(run) identical(run$service_id, "shap_analysis"), logical(1))))
  expect_equal(rejected$value$inquiry$stopping_rule$outcome, "needs_additional_analysis")

  failed <- app$run_funnel_driver_investigation(data = data.frame(channel = "Search"))
  expect_equal(failed$status, "error")
  expect_equal(failed$value$status, "failed")
})

test_that("agent session serialization and replay are deterministic", {
  app <- agent_operation_test_env()
  result <- app$run_funnel_driver_investigation(approve_shap = TRUE)
  json <- app$serialize_agent_session(result$value)
  restored <- app$deserialize_agent_session(json)
  expect_equal(app$validate_agent_session(restored)$status, "success")

  replay <- app$agent_session_replay(restored)
  expect_equal(replay$status, "replaying")
  expect_equal(length(replay$service_runs), length(restored$service_runs))
  expect_true(isTRUE(replay$presentation_state$replay))
})

test_that("campaign report exposes a deterministic claim trace", {
  app <- agent_operation_test_env()
  result <- app$run_funnel_driver_investigation(approve_shap = TRUE)
  validation <- app$validate_report(result$value$report_contract)
  expect_false(identical(validation$status, "error"))

  trace <- app$agent_campaign_claim_trace(result$value)
  expect_equal(trace$status, "success")
  expect_true(length(trace$value$evidence_ids) > 0)
  expect_true(length(trace$value$belief_revisions) > 0)
  expect_true(nzchar(trace$value$final_conclusion))
  expect_equal(trace$value$provenance$agent_session_id, result$value$session_id)
})
