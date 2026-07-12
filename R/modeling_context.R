modeling_context_schema_version <- function() {
  "modeling_context_v1"
}

new_modeling_context <- function(
  project_id = NA_character_,
  active_dataset_id = "active_dataset",
  active_dataset_label = NA_character_,
  active_dataset_source = "source_dataset",
  source_dataset_id = "active_dataset",
  source_dataset_label = NA_character_,
  active_dataset_artifact_id = NA_character_,
  source_dataset_artifact_id = NA_character_,
  preparation_execution_id = NA_character_,
  transformation_specification_ids = character(),
  fitted_transformation_ids = character(),
  feature_manifest = character(),
  target = NA_character_,
  date_field = NA_character_,
  group_field = NA_character_,
  partition_identity = NA_character_,
  activation_timestamp = Sys.time(),
  lineage_summary = "Source dataset is active."
) {
  structure(
    list(
      schema_version = modeling_context_schema_version(),
      project_id = project_id %||% NA_character_,
      active_dataset_id = active_dataset_id %||% "active_dataset",
      active_dataset_label = active_dataset_label %||% NA_character_,
      active_dataset_source = active_dataset_source %||% "source_dataset",
      source_dataset_id = source_dataset_id %||% "active_dataset",
      source_dataset_label = source_dataset_label %||% NA_character_,
      active_dataset_artifact_id = active_dataset_artifact_id %||% NA_character_,
      source_dataset_artifact_id = source_dataset_artifact_id %||% NA_character_,
      preparation_execution_id = preparation_execution_id %||% NA_character_,
      transformation_specification_ids = transformation_specification_ids %||% character(),
      fitted_transformation_ids = fitted_transformation_ids %||% character(),
      feature_manifest = feature_manifest %||% character(),
      target = target %||% NA_character_,
      date_field = date_field %||% NA_character_,
      group_field = group_field %||% NA_character_,
      partition_identity = partition_identity %||% NA_character_,
      activation_timestamp = as.character(activation_timestamp %||% Sys.time()),
      lineage_summary = lineage_summary %||% "Source dataset is active."
    ),
    class = c("aw_modeling_context", "list")
  )
}

modeling_context_from_source <- function(data = NULL, data_info = list(), project = NULL) {
  columns <- if (is.null(data)) character() else names(data)
  project_id <- if (is.list(project)) project$project_id %||% NA_character_ else NA_character_
  label <- data_info$name %||% "Source Dataset"
  new_modeling_context(
    project_id = project_id,
    active_dataset_label = label,
    source_dataset_label = label,
    feature_manifest = columns,
    lineage_summary = "The original source/project dataset is active."
  )
}

modeling_context_from_prepared_activation <- function(artifact, activation, source_info = list(), project = NULL) {
  metadata <- artifact$metadata %||% list()
  lineage <- metadata$transformation_lineage %||% list()
  data <- activation$value$data %||% artifact$object
  project_id <- if (is.list(project)) project$project_id %||% NA_character_ else NA_character_
  source_label <- source_info$name %||% activation$value$data_info$previous_dataset_name %||% "Source Dataset"

  new_modeling_context(
    project_id = project_id,
    active_dataset_label = artifact$label %||% "Prepared Modeling Data",
    active_dataset_source = "prepared_artifact",
    source_dataset_id = lineage$input_artifact %||% "active_dataset",
    source_dataset_label = source_label,
    active_dataset_artifact_id = artifact$artifact_id,
    source_dataset_artifact_id = lineage$input_artifact %||% "active_dataset",
    preparation_execution_id = metadata$module_run_id %||% lineage$preparation_execution_id %||% NA_character_,
    transformation_specification_ids = lineage$transformation_specification_ids %||% character(),
    fitted_transformation_ids = lineage$fitted_transformation_ids %||% character(),
    feature_manifest = if (is.null(data)) character() else names(data),
    target = metadata$target_col %||% metadata$target %||% NA_character_,
    date_field = metadata$date_col %||% metadata$DateVar %||% NA_character_,
    group_field = paste(metadata$group_cols %||% metadata$ByVars %||% character(), collapse = ", "),
    partition_identity = metadata$partition_identity %||% if ("model_split" %in% names(data %||% list())) "model_split" else NA_character_,
    activation_timestamp = activation$value$data_info$activated_at %||% Sys.time(),
    lineage_summary = sprintf(
      "Prepared dataset artifact %s is active; source dataset remains %s.",
      artifact$artifact_id,
      source_label
    )
  )
}

modeling_context_label <- function(context) {
  if (is.null(context)) {
    return("No active modeling context")
  }
  paste0(
    context$active_dataset_label %||% "Active Dataset",
    " [", context$active_dataset_source %||% "unknown", "]"
  )
}

validate_modeling_context <- function(context, artifacts = list(), data = NULL, project_id = NULL) {
  errors <- character()
  warnings <- character()
  if (!is.list(context)) {
    return(service_result(status = "error", errors = "Modeling context is not a list.", metadata = list(error_code = "MODELING_CONTEXT_INVALID")))
  }
  if (!identical(context$schema_version %||% "", modeling_context_schema_version())) {
    warnings <- c(warnings, paste("Unexpected modeling context schema:", context$schema_version %||% "<missing>"))
  }
  if (!identical(context$active_dataset_id %||% "", "active_dataset")) {
    errors <- c(errors, "The current action layer supports only active_dataset as the trusted dataset id.")
  }
  if (!is.null(project_id) && !is.na(context$project_id %||% NA_character_) && nzchar(context$project_id %||% "") &&
      !identical(context$project_id, project_id)) {
    errors <- c(errors, "Modeling context belongs to a different project.")
  }
  artifact_id <- context$active_dataset_artifact_id %||% NA_character_
  if (!is.na(artifact_id) && nzchar(artifact_id) && !artifact_id %in% names(artifacts)) {
    errors <- c(errors, paste("Active prepared dataset artifact is missing:", artifact_id))
  }
  if (!is.null(data)) {
    missing_features <- setdiff(context$feature_manifest %||% character(), names(data))
    if (length(missing_features)) {
      errors <- c(errors, paste("Active data is missing feature manifest columns:", paste(missing_features, collapse = ", ")))
    }
  }

  status <- if (length(errors)) "error" else if (length(warnings)) "warning" else "success"
  service_result(
    status = status,
    value = context,
    warnings = warnings,
    errors = errors,
    metadata = list(
      active_dataset_id = context$active_dataset_id %||% NA_character_,
      active_dataset_source = context$active_dataset_source %||% NA_character_,
      active_dataset_artifact_id = artifact_id
    )
  )
}

qa_modeling_context_lifecycle <- function() {
  source_data <- data.table::data.table(id = 1:5, event_date = as.Date("2026-01-01") + 0:4, target = c(1, 0, 1, 0, 1), x = c(1, NA, 3, 4, 5))
  config <- feature_prep_default_config(source_data)
  config$target_col <- "target"
  config$date_col <- "event_date"
  result <- run_feature_preparation_module(source_data, config)
  artifact <- result$artifacts$prepared_dataset
  activation <- prepared_dataset_activation_result(artifact, "Source Data")
  context <- modeling_context_from_prepared_activation(
    artifact,
    activation,
    source_info = list(name = "Source Data"),
    project = list(project_id = "qa_project")
  )
  artifacts <- list()
  artifacts[[artifact$artifact_id]] <- artifact
  validation <- validate_modeling_context(context, artifacts = artifacts, data = activation$value$data, project_id = "qa_project")
  missing_validation <- validate_modeling_context(context, artifacts = list(), data = activation$value$data, project_id = "qa_project")
  source_context <- modeling_context_from_source(source_data, list(name = "Source Data"), list(project_id = "qa_project"))

  data.table::data.table(
    check = c(
      "prepared_context_created",
      "prepared_context_validates",
      "missing_artifact_rejected",
      "source_context_created",
      "trusted_dataset_identity_preserved",
      "feature_manifest_recorded"
    ),
    status = c(
      if (inherits(context, "aw_modeling_context") && identical(context$active_dataset_source, "prepared_artifact")) "success" else "error",
      if (identical(validation$status, "success")) "success" else "error",
      if (identical(missing_validation$status, "error")) "success" else "error",
      if (inherits(source_context, "aw_modeling_context") && identical(source_context$active_dataset_source, "source_dataset")) "success" else "error",
      if (identical(context$active_dataset_id, "active_dataset") && identical(source_context$active_dataset_id, "active_dataset")) "success" else "error",
      if (length(context$feature_manifest) == ncol(activation$value$data)) "success" else "error"
    ),
    message = c(
      "Prepared dataset activation creates a modeling context.",
      "Prepared modeling context validates against artifacts and active data.",
      "Missing prepared artifacts are rejected instead of silently ignored.",
      "Source dataset context can be restored.",
      "The action layer trusted dataset id remains active_dataset.",
      "The active feature manifest is recorded for downstream lineage."
    )
  )
}
