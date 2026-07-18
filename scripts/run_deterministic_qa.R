source("app.R")

qa_names <- c(
  "qa_build_week_demo",
  "qa_report_browser",
  "qa_agent_operation_runtime"
)

has_error <- FALSE

for (qa_name in qa_names) {
  qa_fn <- app_env[[qa_name]]
  qa_result <- qa_fn()

  message("\n", qa_name)
  print(qa_result)

  if (any(qa_result[["status"]] == "error")) {
    has_error <- TRUE
  }
}

if (has_error) {
  stop("One or more deterministic QA suites returned error status.", call. = FALSE)
}
