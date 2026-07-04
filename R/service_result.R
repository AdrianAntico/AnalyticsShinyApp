service_result <- function(
  status = c("success", "warning", "error", "needs_input"),
  value = NULL,
  artifacts = list(),
  messages = character(),
  warnings = character(),
  errors = character(),
  diagnostics = list(),
  code = NULL,
  metadata = list()
) {
  status <- match.arg(status)

  list(
    status = status,
    value = value,
    artifacts = artifacts,
    messages = messages,
    warnings = warnings,
    errors = errors,
    diagnostics = diagnostics,
    code = code,
    metadata = metadata
  )
}
