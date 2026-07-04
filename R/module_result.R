validate_module_config <- function(module_id, config, data) {
  module <- get_module_definition(module_id)
  if (is.null(module)) {
    return(service_result(
      status = "error",
      errors = paste("Unknown analysis module:", module_id),
      metadata = list(
        error_code = "MODULE_NOT_FOUND",
        module_id = module_id
      )
    ))
  }

  if (is.null(config)) {
    config <- list()
  }

  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "Module config must be a list.",
      metadata = list(
        error_code = "MODULE_CONFIG_INVALID",
        module_id = module_id
      )
    ))
  }

  if (identical(module_id, "autoquant_eda")) {
    return(validate_autoquant_eda_config(data = data, config = config))
  }
  if (identical(module_id, "autoquant_model_assessment")) {
    return(validate_autoquant_model_assessment_config(data = data, config = config))
  }

  service_result(
    status = "success",
    value = config,
    messages = paste("Module config is valid for", module$label),
    metadata = list(
      module_id = module_id,
      status = module$status,
      n_rows = if (is.null(data)) NA_integer_ else nrow(data),
      n_cols = if (is.null(data)) NA_integer_ else ncol(data)
    )
  )
}

run_analysis_module <- function(module_id, data, config = list()) {
  module <- get_module_definition(module_id)
  if (is.null(module)) {
    return(service_result(
      status = "error",
      errors = paste("Unknown analysis module:", module_id),
      metadata = list(
        error_code = "MODULE_NOT_FOUND",
        module_id = module_id
      )
    ))
  }

  validation <- validate_module_config(module_id, config, data)
  if (!identical(validation$status, "success")) {
    return(validation)
  }

  if (identical(module_id, "autoquant_eda")) {
    return(run_autoquant_eda_module(data = data, config = config))
  }
  if (identical(module_id, "autoquant_model_assessment")) {
    return(run_autoquant_model_assessment_module(data = data, config = config))
  }

  service_result(
    status = "needs_input",
    artifacts = list(),
    messages = paste(module$label, "is registered but not implemented yet."),
    metadata = list(
      module_id = module_id,
      label = module$label,
      status = module$status,
      n_artifacts = 0L
    ),
    code = NULL
  )
}
