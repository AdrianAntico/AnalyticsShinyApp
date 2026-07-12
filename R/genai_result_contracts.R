genai_dataset_profile_result_type <- function() {
  "dataset_profile"
}

genai_model_assessment_regression_result_type <- function() {
  "model_assessment_regression"
}

genai_model_assessment_binary_result_type <- function() {
  "model_assessment_binary"
}

genai_result_type_registry <- function() {
  list(
    dataset_profile = list(
      result_type = genai_dataset_profile_result_type(),
      display_name = "Dataset Profile",
      temporary_schema_version = "dataset_profile_temporary_v1",
      output_contract_version = "dataset_profile_output_v1",
      persistence_enabled = TRUE,
      inspection_enabled = TRUE,
      required_output_fields = c("status", "summary", "tables", "diagnostics", "warnings", "resource_usage"),
      max_generated_plots = 0L
    ),
    model_assessment_regression = list(
      result_type = genai_model_assessment_regression_result_type(),
      display_name = "Regression Model Assessment",
      temporary_schema_version = "model_assessment_regression_temporary_v1",
      output_contract_version = "model_assessment_regression_output_v1",
      persistence_enabled = TRUE,
      inspection_enabled = TRUE,
      required_output_fields = c("status", "summary", "metrics", "tables", "diagnostics", "warnings", "resource_usage", "plots"),
      max_generated_plots = 2L
    ),
    model_assessment_binary = list(
      result_type = genai_model_assessment_binary_result_type(),
      display_name = "Binary Classification Model Assessment",
      temporary_schema_version = "model_assessment_binary_temporary_v1",
      output_contract_version = "model_assessment_binary_output_v1",
      persistence_enabled = TRUE,
      inspection_enabled = TRUE,
      required_output_fields = c("status", "summary", "metrics", "threshold_metrics", "tables", "diagnostics", "warnings", "resource_usage", "plots"),
      max_generated_plots = 5L
    )
  )
}

genai_result_type_definition <- function(result_type) {
  registry <- genai_result_type_registry()
  result_type <- as.character(result_type %||% "")
  registry[[result_type]] %||% NULL
}

genai_supported_temporary_result_types <- function() {
  names(Filter(function(def) isTRUE(def$persistence_enabled), genai_result_type_registry()))
}

genai_result_output_contract_version <- function(result_type = genai_dataset_profile_result_type()) {
  definition <- genai_result_type_definition(result_type)
  definition$output_contract_version %||% "dataset_profile_output_v1"
}

genai_result_required_output_fields <- function(result_type = genai_dataset_profile_result_type()) {
  definition <- genai_result_type_definition(result_type)
  definition$required_output_fields %||% genai_result_type_registry()$dataset_profile$required_output_fields
}

genai_model_assessment_mode_registry <- function() {
  list(
    regression = list(
      mode_id = "regression",
      display_name = "Regression Scored-Output Diagnostics",
      result_type = genai_model_assessment_regression_result_type(),
      configuration_schema_version = "model_assessment_regression_config_v1",
      input_contract_version = "model_assessment_regression_input_v1",
      output_contract_version = "model_assessment_regression_output_v1",
      required_roles = c("target_column", "prediction_column"),
      optional_roles = "weight_column",
      preflight_handler_id = "model_assessment_regression_preflight",
      execution_handler_id = "model_assessment_regression_execute",
      result_validator_id = "model_assessment_regression_validator",
      persistence_serializer_id = "persisted_result_bundle_v1",
      browser_renderer_id = "persisted_result_browser_v1",
      genai_summary_id = "model_assessment_regression_safe_summary",
      audit_projection_id = "registered_analysis_audit_v1",
      resource_profile_id = "model_assessment_regression_resource_v1"
    ),
    binary_classification = list(
      mode_id = "binary_classification",
      display_name = "Binary Classification Scored-Output Diagnostics",
      result_type = genai_model_assessment_binary_result_type(),
      configuration_schema_version = "model_assessment_binary_config_v1",
      input_contract_version = "model_assessment_binary_input_v1",
      output_contract_version = "model_assessment_binary_output_v1",
      required_roles = c("target_column", "prediction_column", "positive_class", "decision_threshold", "prediction_scale"),
      optional_roles = "weight_column",
      preflight_handler_id = "model_assessment_binary_preflight",
      execution_handler_id = "model_assessment_binary_execute",
      result_validator_id = "model_assessment_binary_validator",
      persistence_serializer_id = "persisted_result_bundle_v1",
      browser_renderer_id = "persisted_result_browser_v1",
      genai_summary_id = "model_assessment_binary_safe_summary",
      audit_projection_id = "registered_analysis_audit_v1",
      resource_profile_id = "model_assessment_binary_resource_v1"
    )
  )
}

genai_model_assessment_mode_definition <- function(mode_id) {
  registry <- genai_model_assessment_mode_registry()
  mode_id <- as.character(mode_id %||% "")
  registry[[mode_id]] %||% NULL
}

genai_model_assessment_supported_modes <- function() {
  names(genai_model_assessment_mode_registry())
}

genai_model_assessment_mode_from_config <- function(configuration_values) {
  task_type <- tolower(as.character((configuration_values %||% list())$task_type %||% "regression"))
  if (task_type %in% c("binary", "binary_classification", "classification_binary")) {
    return("binary_classification")
  }
  if (identical(task_type, "regression")) {
    return("regression")
  }
  NA_character_
}

genai_model_assessment_result_type_for_mode <- function(mode_id) {
  definition <- genai_model_assessment_mode_definition(mode_id)
  definition$result_type %||% NA_character_
}

genai_model_assessment_result_type_for_config <- function(configuration_values) {
  genai_model_assessment_result_type_for_mode(genai_model_assessment_mode_from_config(configuration_values))
}

genai_module_supported_result_types <- function(module_id) {
  module_id <- normalize_module_id(module_id)
  if (identical(module_id, genai_registered_analysis_second_module_id())) {
    return(vapply(genai_model_assessment_mode_registry(), function(def) def$result_type, character(1)))
  }
  if (identical(module_id, genai_registered_analysis_initial_module_id())) {
    return(genai_dataset_profile_result_type())
  }
  character()
}

genai_module_result_type <- function(module_id, configuration_values = NULL) {
  module_id <- normalize_module_id(module_id)
  if (identical(module_id, genai_registered_analysis_second_module_id())) {
    if (!is.null(configuration_values)) {
      return(genai_model_assessment_result_type_for_config(configuration_values))
    }
    return(genai_model_assessment_regression_result_type())
  }
  if (identical(module_id, genai_registered_analysis_initial_module_id())) {
    return(genai_dataset_profile_result_type())
  }
  NA_character_
}
