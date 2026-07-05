code_execution_modes <- function() {
  c("disabled", "local_trusted", "local_restricted", "external_worker")
}

create_code_execution_policy <- function(
  code_execution_enabled = FALSE,
  execution_mode = "disabled",
  allow_manual_code = FALSE,
  allow_genai_code = FALSE,
  require_approval_for_genai_code = TRUE,
  allow_file_read = FALSE,
  allow_file_write = FALSE,
  allow_network = FALSE,
  allow_package_install = FALSE,
  allow_system_calls = FALSE,
  max_runtime_seconds = 30,
  max_memory_mb = 1024,
  allowed_packages = character(),
  blocked_functions = c("system", "system2", "shell", "file.remove", "unlink", "download.file", "install.packages")
) {
  structure(
    list(
      code_execution_enabled = code_execution_enabled,
      execution_mode = execution_mode,
      allow_manual_code = allow_manual_code,
      allow_genai_code = allow_genai_code,
      require_approval_for_genai_code = require_approval_for_genai_code,
      allow_file_read = allow_file_read,
      allow_file_write = allow_file_write,
      allow_network = allow_network,
      allow_package_install = allow_package_install,
      allow_system_calls = allow_system_calls,
      max_runtime_seconds = max_runtime_seconds,
      max_memory_mb = max_memory_mb,
      allowed_packages = allowed_packages,
      blocked_functions = blocked_functions
    ),
    class = c("aq_code_execution_policy", "list")
  )
}

validate_code_execution_policy <- function(policy) {
  errors <- character()

  if (!inherits(policy, "aq_code_execution_policy") && !is.list(policy)) {
    errors <- c(errors, "Code execution policy must be a list.")
  } else {
    boolean_fields <- c(
      "code_execution_enabled",
      "allow_manual_code",
      "allow_genai_code",
      "require_approval_for_genai_code",
      "allow_file_read",
      "allow_file_write",
      "allow_network",
      "allow_package_install",
      "allow_system_calls"
    )

    if (!policy$execution_mode %in% code_execution_modes()) {
      errors <- c(errors, paste("execution_mode must be one of:", paste(code_execution_modes(), collapse = ", ")))
    }

    for (field in boolean_fields) {
      value <- policy[[field]]
      if (!is.logical(value) || length(value) != 1L || is.na(value)) {
        errors <- c(errors, paste(field, "must be TRUE or FALSE."))
      }
    }

    max_runtime_seconds <- suppressWarnings(as.numeric(policy$max_runtime_seconds))
    if (is.na(max_runtime_seconds) || max_runtime_seconds <= 0) {
      errors <- c(errors, "max_runtime_seconds must be positive.")
    }

    max_memory_mb <- suppressWarnings(as.numeric(policy$max_memory_mb))
    if (is.na(max_memory_mb) || max_memory_mb <= 0) {
      errors <- c(errors, "max_memory_mb must be positive.")
    }

    if (!is.character(policy$allowed_packages)) {
      errors <- c(errors, "allowed_packages must be character.")
    }

    if (!is.character(policy$blocked_functions)) {
      errors <- c(errors, "blocked_functions must be character.")
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      metadata = list(error_code = "CODE_EXECUTION_POLICY_INVALID")
    ))
  }

  service_result(
    status = "success",
    value = policy,
    messages = "Code execution policy is valid.",
    metadata = list(
      code_execution_enabled = isTRUE(policy$code_execution_enabled),
      execution_mode = policy$execution_mode
    )
  )
}
