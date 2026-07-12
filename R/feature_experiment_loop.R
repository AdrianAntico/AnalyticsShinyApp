feature_proposal_schema_version <- function() "feature_proposal_v1"
feature_execution_schema_version <- function() "feature_execution_v1"
feature_experiment_schema_version <- function() "feature_experiment_v1"
feature_comparison_schema_version <- function() "feature_comparison_v1"
feature_adoption_schema_version <- function() "feature_adoption_v1"

feature_experiment_supported_transformations <- function() {
  c("missing_impute", "constant_remove", "near_zero_variance_remove", "factor_levels", "date_features")
}

feature_experiment_statuses <- function() {
  c(
    "proposed", "unsupported", "blocked", "awaiting_approval", "approved",
    "rejected", "executed", "execution_failed", "experiment_running",
    "compared", "accepted", "inconclusive", "failed", "adopted", "deferred"
  )
}

feature_experiment_slug <- function(value, fallback = "feature") {
  value <- tolower(as.character(value %||% fallback)[[1L]])
  value <- gsub("[^a-z0-9]+", "_", value)
  value <- gsub("^_+|_+$", "", value)
  if (!nzchar(value)) fallback else value
}

feature_experiment_id <- function(prefix, ...) {
  paste0(prefix, "_", substr(storage_hash_value(list(..., storage_now())), 1L, 16L))
}

feature_experiment_now <- function() {
  if (exists("storage_now", mode = "function")) storage_now() else as.character(Sys.time())
}

feature_experiment_project_id <- function(ctx = NULL, project_id = NULL) {
  project_id %||%
    tryCatch((ctx$current_project() %||% list())$project_id, error = function(e) NULL) %||%
    tryCatch(ctx$project_collector_project_id(), error = function(e) NULL) %||%
    "active_project"
}

feature_experiment_schema <- function(data) {
  if (is.null(data)) {
    return(data.table::data.table(column = character(), class = character(), missing = integer(), unique_values = integer()))
  }
  dt <- data.table::as.data.table(data)
  data.table::data.table(
    column = names(dt),
    class = vapply(dt, function(x) paste(class(x), collapse = "/"), character(1)),
    missing = vapply(dt, function(x) sum(is.na(x)), integer(1)),
    missing_pct = round(vapply(dt, function(x) mean(is.na(x)), numeric(1)) * 100, 2),
    unique_values = vapply(dt, function(x) data.table::uniqueN(x, na.rm = TRUE), integer(1))
  )
}

feature_experiment_evidence_context <- function(
  ctx = NULL,
  data = NULL,
  artifacts = NULL,
  baseline_result = NULL,
  modeling_context = NULL,
  feature_experiment_state = NULL,
  target_col = NULL,
  feature_cols = NULL,
  project_id = NULL,
  max_artifact_refs = 30L
) {
  data <- data %||% tryCatch(ctx$project_data(), error = function(e) NULL)
  artifacts <- artifacts %||% tryCatch(ctx$all_artifacts(), error = function(e) list())
  modeling_context <- modeling_context %||% tryCatch(ctx$current_modeling_context(), error = function(e) NULL)
  project_id <- feature_experiment_project_id(ctx, project_id)
  schema <- feature_experiment_schema(data)
  artifact_rows <- if (length(artifacts)) {
    rows <- lapply(artifacts, function(artifact) {
      data.table::data.table(
        artifact_id = artifact$artifact_id %||% NA_character_,
        artifact_type = artifact$artifact_type %||% NA_character_,
        label = artifact$label %||% artifact$artifact_id %||% NA_character_,
        source_module = artifact$source_module %||% NA_character_,
        analytical_intent = (artifact$metadata %||% list())$analytical_intent %||% NA_character_,
        importance = (artifact$metadata %||% list())$artifact_importance %||% NA_character_
      )
    })
    utils::head(data.table::rbindlist(rows, use.names = TRUE, fill = TRUE), max_artifact_refs)
  } else {
    data.table::data.table()
  }
  target_col <- target_col %||% tryCatch((baseline_result$metadata$configured_inputs %||% list())$target_col, error = function(e) NULL)
  feature_cols <- feature_cols %||% tryCatch((baseline_result$metadata$configured_inputs %||% list())$feature_cols, error = function(e) NULL)
  if (is.null(feature_cols) && nrow(schema)) {
    feature_cols <- setdiff(schema$column, target_col %||% character())
  }
  baseline_id <- tryCatch(baseline_result$metadata$module_run_id, error = function(e) NULL)
  feature_experiment_state <- feature_experiment_state %||% tryCatch(list(
    proposals = ctx$feature_experiment_state$proposals,
    executions = ctx$feature_experiment_state$executions,
    experiments = ctx$feature_experiment_state$experiments,
    adoptions = ctx$feature_experiment_state$adoptions
  ), error = function(e) NULL)
  prior_outcomes <- if (!is.null(feature_experiment_state)) {
    feature_experiment_history_table(feature_experiment_state)
  } else {
    data.table::data.table()
  }
  list(
    context_schema_version = "feature_evidence_context_v1",
    project_id = project_id,
    created_at = feature_experiment_now(),
    active_modeling_context = modeling_context %||% list(),
    source_dataset_artifact_id = (modeling_context %||% list())$active_dataset_artifact_id %||% "active_dataset",
    target_col = target_col %||% NA_character_,
    feature_manifest = as.character(feature_cols %||% character()),
    dataset_schema = schema,
    artifact_refs = artifact_rows,
    baseline_model_result_id = baseline_id %||% NA_character_,
    baseline_metadata = baseline_result$metadata %||% list(),
    prior_feature_outcomes = prior_outcomes,
    bounds = list(max_artifact_refs = max_artifact_refs, raw_rows_included = 0L)
  )
}

feature_proposal <- function(
  diagnosed_problem,
  hypothesis,
  transformation_type,
  source_columns,
  output_columns = character(),
  parameters = list(),
  evidence_artifact_ids = character(),
  project_id = "active_project",
  source_model_result_id = NA_character_,
  source_dataset_artifact_id = "active_dataset",
  active_modeling_context_id = "active_dataset",
  expected_model_effect = "unknown",
  expected_diagnostic_effect = "unknown",
  rationale = "",
  confidence = "medium",
  proposal_id = NULL,
  created_at = feature_experiment_now()
) {
  supported <- transformation_type %in% feature_experiment_supported_transformations()
  risk <- feature_proposal_risk_tier(transformation_type, parameters)
  status <- if (supported && !identical(risk, "blocked")) "awaiting_approval" else if (!supported) "unsupported" else "blocked"
  list(
    proposal_id = proposal_id %||% feature_experiment_id("fp", project_id, transformation_type, source_columns, output_columns, parameters),
    project_id = project_id,
    created_at = created_at,
    proposal_version = feature_proposal_schema_version(),
    source_model_result_id = source_model_result_id,
    source_dataset_artifact_id = source_dataset_artifact_id,
    active_modeling_context_id = active_modeling_context_id,
    evidence_artifact_ids = as.character(evidence_artifact_ids %||% character()),
    diagnosed_problem = diagnosed_problem,
    hypothesis = hypothesis,
    transformation_type = transformation_type,
    source_columns = as.character(source_columns %||% character()),
    output_columns = as.character(output_columns %||% character()),
    parameters = parameters %||% list(),
    expected_model_effect = expected_model_effect,
    expected_diagnostic_effect = expected_diagnostic_effect,
    rationale = rationale,
    leakage_risk = if (identical(risk, "blocked")) "high" else "low",
    stability_risk = if (transformation_type %in% c("factor_levels", "near_zero_variance_remove")) "medium" else "low",
    subgroup_risk = "low",
    temporal_risk = if (identical(transformation_type, "date_features")) "medium" else "low",
    operational_complexity = if (transformation_type %in% c("date_features", "factor_levels")) "medium" else "low",
    confidence = confidence,
    rodeo_support_status = if (supported) "supported" else "unsupported",
    required_approval_tier = risk,
    experiment_pattern = "baseline_vs_one_challenger",
    validation_metrics = c("rmse", "mae", "artifact_count", "feature_count"),
    acceptance_criteria = list(primary_metric = "rmse", direction = "decrease", min_relative_improvement = 0),
    rejection_criteria = list(block_on_leakage = TRUE, reject_if_metric_regresses = TRUE),
    confirmation_criteria = list(confirm_if_relative_delta_under = 0.01),
    unsupported_reason = if (supported) NA_character_ else "Transformation is not supported by the current Rodeo contract.",
    proposal_status = status,
    audit_references = character()
  )
}

feature_proposal_risk_tier <- function(transformation_type, parameters = list()) {
  if (transformation_type %in% c("target_encoding", "rolling_window", "lag_feature", "arbitrary_expression")) return("blocked")
  if (transformation_type %in% c("constant_remove", "missing_impute", "factor_levels", "date_features")) return("low")
  if (transformation_type %in% c("near_zero_variance_remove", "ratio_feature", "interaction_feature", "drop_feature")) return("medium")
  "blocked"
}

validate_feature_proposal <- function(proposal, evidence_context = NULL) {
  errors <- character()
  required <- c("proposal_id", "project_id", "proposal_version", "transformation_type", "source_columns", "proposal_status")
  missing <- required[!required %in% names(proposal)]
  if (length(missing)) errors <- c(errors, paste("Missing proposal fields:", paste(missing, collapse = ", ")))
  if (!identical(proposal$proposal_version %||% "", feature_proposal_schema_version())) errors <- c(errors, "Unsupported proposal schema version.")
  if (!storage_resource_id_is_valid(proposal$proposal_id %||% "")) errors <- c(errors, "proposal_id is malformed.")
  if (!proposal$proposal_status %in% feature_experiment_statuses()) errors <- c(errors, paste("Invalid proposal status:", proposal$proposal_status))
  if (identical(proposal$rodeo_support_status %||% "", "supported") && !proposal$transformation_type %in% feature_experiment_supported_transformations()) {
    errors <- c(errors, "Proposal claims Rodeo support for an unsupported transformation.")
  }
  if (!is.null(evidence_context) && nrow(evidence_context$dataset_schema %||% data.table::data.table())) {
    missing_cols <- setdiff(proposal$source_columns %||% character(), evidence_context$dataset_schema$column)
    if (length(missing_cols)) errors <- c(errors, paste("Proposal source columns are missing:", paste(missing_cols, collapse = ", ")))
  }
  if (identical(proposal$rodeo_support_status %||% "", "supported") && !length(proposal$evidence_artifact_ids %||% character())) {
    errors <- c(errors, "Supported feature proposals require at least one evidence artifact or trusted evidence reference.")
  }
  service_result(
    status = if (length(errors)) "error" else "success",
    value = proposal,
    errors = errors,
    messages = if (!length(errors)) "Feature proposal is valid." else character(),
    metadata = list(proposal_id = proposal$proposal_id %||% NA_character_)
  )
}

generate_feature_proposals <- function(evidence_context, max_proposals = 3L) {
  schema <- evidence_context$dataset_schema %||% data.table::data.table()
  evidence_ids <- evidence_context$artifact_refs$artifact_id %||% character()
  if (!length(evidence_ids)) evidence_ids <- "active_dataset"
  proposals <- list()
  add <- function(...) {
    if (length(proposals) < max_proposals) proposals[[length(proposals) + 1L]] <<- feature_proposal(...)
  }
  missing_cols <- schema[missing > 0, column]
  numeric_missing <- missing_cols[schema[column %in% missing_cols, grepl("numeric|integer", class)]]
  if (length(numeric_missing)) {
    col <- numeric_missing[[1L]]
    add(
      diagnosed_problem = paste("Missing values detected in", col),
      hypothesis = paste("Imputing", col, "with a fitted median may reduce training instability."),
      transformation_type = "missing_impute",
      source_columns = col,
      parameters = list(method = "median_mode"),
      evidence_artifact_ids = evidence_ids,
      project_id = evidence_context$project_id,
      source_model_result_id = evidence_context$baseline_model_result_id,
      source_dataset_artifact_id = evidence_context$source_dataset_artifact_id,
      active_modeling_context_id = evidence_context$active_modeling_context$active_dataset_id %||% "active_dataset",
      expected_model_effect = "reduce missing-value sensitivity",
      expected_diagnostic_effect = "lower missingness warnings",
      rationale = "The bounded evidence context reports missing values in a modeling feature."
    )
  }
  date_cols <- schema[grepl("Date|POSIX|IDate", class), column]
  if (length(date_cols)) {
    col <- date_cols[[1L]]
    add(
      diagnosed_problem = paste("Temporal signal may be compressed in", col),
      hypothesis = paste("Adding deterministic calendar features from", col, "may expose seasonal structure."),
      transformation_type = "date_features",
      source_columns = col,
      output_columns = paste0(col, "_", c("year", "month", "dow")),
      parameters = list(features = c("year", "month", "dow")),
      evidence_artifact_ids = evidence_ids,
      project_id = evidence_context$project_id,
      source_model_result_id = evidence_context$baseline_model_result_id,
      source_dataset_artifact_id = evidence_context$source_dataset_artifact_id,
      active_modeling_context_id = evidence_context$active_modeling_context$active_dataset_id %||% "active_dataset",
      expected_model_effect = "capture calendar effects",
      expected_diagnostic_effect = "improve temporal diagnostics",
      rationale = "The schema includes a date-like column and no raw-data rows are sent to GenAI."
    )
  }
  factor_cols <- schema[grepl("character|factor", class), column]
  if (length(factor_cols)) {
    col <- factor_cols[[1L]]
    add(
      diagnosed_problem = paste("Categorical scoring drift may appear in", col),
      hypothesis = paste("Fitting a stable level map for", col, "can make unseen levels explicit."),
      transformation_type = "factor_levels",
      source_columns = col,
      parameters = list(unseen_level = "__UNSEEN__", include_missing_level = TRUE),
      evidence_artifact_ids = evidence_ids,
      project_id = evidence_context$project_id,
      source_model_result_id = evidence_context$baseline_model_result_id,
      source_dataset_artifact_id = evidence_context$source_dataset_artifact_id,
      active_modeling_context_id = evidence_context$active_modeling_context$active_dataset_id %||% "active_dataset",
      expected_model_effect = "improve scoring stability",
      expected_diagnostic_effect = "make unseen levels auditable",
      rationale = "The schema includes categorical features that benefit from deterministic level management."
    )
  }
  if (!length(proposals)) {
    proposals[[1L]] <- feature_proposal(
      diagnosed_problem = "No supported deterministic feature hypothesis was identified.",
      hypothesis = "Review additional model diagnostics before executing feature changes.",
      transformation_type = "unsupported_review",
      source_columns = character(),
      evidence_artifact_ids = evidence_ids,
      project_id = evidence_context$project_id,
      rationale = "The bounded context did not contain missingness, date, or categorical signals supported by the initial Rodeo adapter.",
      confidence = "low"
    )
  }
  ranked <- stats::setNames(proposals, vapply(proposals, function(x) x$proposal_id, character(1)))
  service_result(
    status = "success",
    value = ranked,
    messages = paste("Generated", length(ranked), "bounded feature proposal(s)."),
    metadata = list(proposal_count = length(ranked), max_proposals = max_proposals)
  )
}

approve_feature_proposal <- function(proposal, approved_by = "user") {
  validation <- validate_feature_proposal(proposal)
  if (!identical(validation$status, "success")) return(validation)
  if (!identical(proposal$rodeo_support_status, "supported")) {
    return(service_result(status = "error", errors = "Unsupported feature proposals cannot be approved for execution.", value = proposal))
  }
  if (identical(proposal$required_approval_tier, "blocked")) {
    return(service_result(status = "error", errors = "Blocked feature proposals cannot be approved.", value = proposal))
  }
  proposal$proposal_status <- "approved"
  proposal$approved_at <- feature_experiment_now()
  proposal$approved_by <- approved_by
  service_result(status = "success", value = proposal, messages = paste("Approved feature proposal:", proposal$proposal_id))
}

reject_feature_proposal <- function(proposal, reason = "Rejected by user.") {
  proposal$proposal_status <- "rejected"
  proposal$rejected_at <- feature_experiment_now()
  proposal$rejection_reason <- reason
  service_result(status = "success", value = proposal, messages = paste("Rejected feature proposal:", proposal$proposal_id))
}

feature_experiment_proposal_signature <- function(proposal) {
  storage_hash_value(list(
    project_id = proposal$project_id %||% NA_character_,
    transformation_type = proposal$transformation_type %||% NA_character_,
    source_columns = proposal$source_columns %||% character(),
    output_columns = proposal$output_columns %||% character(),
    parameters = proposal$parameters %||% list(),
    source_dataset_artifact_id = proposal$source_dataset_artifact_id %||% NA_character_
  ))
}

feature_experiment_execution_matches_proposal <- function(execution, proposal) {
  existing <- execution$value$proposal %||% execution$proposal %||% list()
  identical(existing$proposal_id %||% "", proposal$proposal_id %||% "") ||
    identical(feature_experiment_proposal_signature(existing), feature_experiment_proposal_signature(proposal))
}

feature_experiment_find_existing_execution <- function(proposal, executions = list()) {
  if (!length(executions)) return(NULL)
  matches <- Filter(function(execution) {
    identical(execution$status %||% "", "success") && feature_experiment_execution_matches_proposal(execution, proposal)
  }, executions)
  if (length(matches)) matches[[1L]] else NULL
}

feature_experiment_rodeo_env <- function() {
  needed <- c("rodeo_transformation_spec", "rodeo_fit_transformation", "rodeo_apply_transformation", "rodeo_save_transformation")
  if (requireNamespace("Rodeo", quietly = TRUE)) {
    ns <- asNamespace("Rodeo")
    if (all(vapply(needed, exists, logical(1), envir = ns, inherits = FALSE, mode = "function"))) {
      return(ns)
    }
  }
  if (all(vapply(needed, exists, logical(1), mode = "function"))) return(.GlobalEnv)
  rodeo_path <- normalizePath(file.path(dirname(getwd()), "Rodeo", "R", "TransformationContract_vNext.R"), winslash = "/", mustWork = FALSE)
  if (file.exists(rodeo_path)) {
    source(rodeo_path, local = .GlobalEnv)
    if (all(vapply(needed, exists, logical(1), mode = "function"))) return(.GlobalEnv)
  }
  NULL
}

feature_proposal_to_rodeo_spec <- function(proposal, data) {
  approval_required <- !identical(proposal$proposal_status %||% "", "approved")
  if (approval_required) return(service_result(status = "error", errors = "Feature proposal must be approved before Rodeo translation.", value = proposal))
  if (!proposal$transformation_type %in% feature_experiment_supported_transformations()) {
    return(service_result(status = "error", errors = paste("Unsupported Rodeo transformation:", proposal$transformation_type), value = proposal))
  }
  dt <- data.table::as.data.table(data)
  missing_cols <- setdiff(proposal$source_columns, names(dt))
  if (length(missing_cols)) return(service_result(status = "error", errors = paste("Source columns are missing:", paste(missing_cols, collapse = ", "))))
  output_collision <- intersect(proposal$output_columns %||% character(), names(dt))
  if (length(output_collision) && identical(proposal$transformation_type, "date_features")) {
    return(service_result(status = "error", errors = paste("Output columns already exist:", paste(output_collision, collapse = ", "))))
  }
  rodeo_env <- feature_experiment_rodeo_env()
  if (is.null(rodeo_env)) {
    return(service_result(status = "error", errors = "Rodeo transformation contract is unavailable. Install Rodeo or provide the local Rodeo source checkout."))
  }
  spec <- get("rodeo_transformation_spec", envir = rodeo_env)(
    type = proposal$transformation_type,
    id = paste0("rodeo_", feature_experiment_slug(proposal$proposal_id)),
    input_columns = proposal$source_columns,
    output_columns = if (length(proposal$output_columns)) proposal$output_columns else NULL,
    parameters = proposal$parameters,
    metadata = list(
      proposal_id = proposal$proposal_id,
      project_id = proposal$project_id,
      evidence_artifact_ids = proposal$evidence_artifact_ids,
      source_dataset_artifact_id = proposal$source_dataset_artifact_id,
      schema_version = feature_execution_schema_version()
    )
  )
  service_result(status = "success", value = spec, messages = "Feature proposal translated to Rodeo transformation spec.")
}

execute_feature_proposal_with_rodeo <- function(proposal, data, output_dir = tempfile("feature_experiment_"), existing_executions = list()) {
  existing <- feature_experiment_find_existing_execution(proposal, existing_executions)
  if (!is.null(existing)) {
    return(service_result(
      status = "warning",
      value = existing$value,
      artifacts = existing$artifacts %||% list(),
      messages = paste("Duplicate Rodeo execution prevented for proposal:", proposal$proposal_id),
      metadata = c(existing$metadata %||% list(), list(duplicate_prevented = TRUE, existing_execution_id = existing$metadata$execution_id %||% existing$value$execution_id %||% NA_character_))
    ))
  }
  spec_result <- feature_proposal_to_rodeo_spec(proposal, data)
  if (!identical(spec_result$status, "success")) return(spec_result)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  rodeo_env <- feature_experiment_rodeo_env()
  execution_id <- feature_experiment_id("fexec", proposal$proposal_id)
  before <- feature_experiment_schema(data)
  input_copy <- data.table::as.data.table(data.table::copy(data))
  result <- tryCatch({
    fitted <- get("rodeo_fit_transformation", envir = rodeo_env)(input_copy, spec_result$value)
    transformed <- get("rodeo_apply_transformation", envir = rodeo_env)(input_copy, fitted, copy_data = TRUE)
    fitted_path <- file.path(output_dir, paste0(execution_id, "_fitted_rodeo.rds"))
    get("rodeo_save_transformation", envir = rodeo_env)(fitted, fitted_path)
    after <- feature_experiment_schema(transformed)
    if (!isTRUE(all.equal(input_copy, data.table::as.data.table(data), check.attributes = FALSE))) {
      stop("Rodeo execution mutated the input dataset.", call. = FALSE)
    }
    metadata_common <- list(
      module_id = "feature_experiment_loop",
      module_run_id = execution_id,
      source_module = "feature_experiment_loop",
      created_by_module = TRUE,
      generated_at = Sys.time(),
      proposal_id = proposal$proposal_id,
      transformation_execution_id = execution_id,
      feature_proposal_schema = feature_proposal_schema_version(),
      feature_execution_schema = feature_execution_schema_version(),
      project_id = proposal$project_id
    )
    artifacts <- list(
      proposal = create_artifact(
        artifact_id = paste0("aq_fexp_", execution_id, "_proposal"),
        artifact_type = "json",
        label = "Feature Proposal",
        source_module = "feature_experiment_loop",
        object = proposal,
        metadata = c(metadata_common, list(original_name = "proposal", artifact_importance = "critical", analytical_intent = "Recommendation")),
        section = "Feature Experiment",
        order = 1L
      ),
      transformation_spec = create_artifact(
        artifact_id = paste0("aq_fexp_", execution_id, "_rodeo_spec"),
        artifact_type = "json",
        label = "Rodeo Transformation Specification",
        source_module = "feature_experiment_loop",
        object = spec_result$value,
        metadata = c(metadata_common, list(original_name = "transformation_spec", artifact_importance = "critical", analytical_intent = "Diagnostic")),
        section = "Feature Experiment",
        order = 2L
      ),
      transformed_dataset = create_artifact(
        artifact_id = paste0("aq_fexp_", execution_id, "_challenger_dataset"),
        artifact_type = "table",
        label = "Feature Experiment Challenger Dataset",
        source_module = "feature_experiment_loop",
        object = transformed,
        metadata = c(metadata_common, list(
          original_name = "prepared_dataset",
          prepared_dataset = TRUE,
          feature_experiment_dataset = TRUE,
          source_dataset_artifact_id = proposal$source_dataset_artifact_id,
          fitted_transformation_path = normalizePath(fitted_path, winslash = "/", mustWork = FALSE),
          artifact_importance = "critical",
          analytical_intent = "Data"
        )),
        section = "Prepared Dataset",
        order = 3L
      ),
      schema_compare = create_artifact(
        artifact_id = paste0("aq_fexp_", execution_id, "_schema_compare"),
        artifact_type = "table",
        label = "Feature Experiment Schema Change",
        source_module = "feature_experiment_loop",
        object = data.table::rbindlist(list(
          data.table::data.table(side = "before", before),
          data.table::data.table(side = "after", after)
        ), use.names = TRUE, fill = TRUE),
        metadata = c(metadata_common, list(original_name = "schema_compare", artifact_importance = "recommended", analytical_intent = "Comparison")),
        section = "Feature Experiment",
        order = 4L
      ),
      diagnostics = create_artifact(
        artifact_id = paste0("aq_fexp_", execution_id, "_diagnostics"),
        artifact_type = "table",
        label = "Rodeo Execution Diagnostics",
        source_module = "feature_experiment_loop",
        object = fitted$diagnostics %||% data.table::data.table(),
        metadata = c(metadata_common, list(original_name = "diagnostics", artifact_importance = "critical", analytical_intent = "Diagnostic")),
        section = "Feature Experiment",
        order = 5L
      )
    )
    service_result(
      status = "success",
      value = list(
        execution_id = execution_id,
        proposal = proposal,
        spec = spec_result$value,
        fitted_spec = fitted,
        transformed_data = transformed,
        fitted_transformation_path = normalizePath(fitted_path, winslash = "/", mustWork = FALSE),
        prepared_dataset_artifact_id = artifacts$transformed_dataset$artifact_id,
        before_schema = before,
        after_schema = after
      ),
      artifacts = artifacts,
      messages = paste("Executed approved feature proposal through Rodeo:", proposal$proposal_id),
      metadata = list(
        execution_schema_version = feature_execution_schema_version(),
        execution_id = execution_id,
        proposal_id = proposal$proposal_id,
        prepared_dataset_artifact_id = artifacts$transformed_dataset$artifact_id,
        fitted_transformation_path = normalizePath(fitted_path, winslash = "/", mustWork = FALSE),
        status = "executed"
      )
    )
  }, error = function(e) {
    service_result(
      status = "error",
      errors = paste("Rodeo feature execution failed:", conditionMessage(e)),
      metadata = list(execution_schema_version = feature_execution_schema_version(), execution_id = execution_id, proposal_id = proposal$proposal_id, status = "execution_failed")
    )
  })
  result
}

is_prepared_feature_experiment_dataset_artifact <- function(artifact) {
  inherits(artifact, "aq_artifact") &&
    identical(artifact$artifact_type, "table") &&
    identical(artifact$source_module, "feature_experiment_loop") &&
    isTRUE((artifact$metadata %||% list())$prepared_dataset) &&
    isTRUE((artifact$metadata %||% list())$feature_experiment_dataset)
}

feature_experiment_metric_table <- function(result, data = NULL, config = list()) {
  scored <- tryCatch(.autoquant_catboost_scored_data(result$value %||% result), error = function(e) NULL)
  target <- config$target_col %||% result$metadata$configured_inputs$target_col %||% NULL
  prediction <- "Predict"
  if (!is.null(scored) && !is.null(target) && target %in% names(scored) && prediction %in% names(scored)) {
    actual <- suppressWarnings(as.numeric(scored[[target]]))
    pred <- suppressWarnings(as.numeric(scored[[prediction]]))
    ok <- is.finite(actual) & is.finite(pred)
    if (any(ok)) {
      return(data.table::data.table(
        metric = c("rmse", "mae"),
        value = c(sqrt(mean((actual[ok] - pred[ok])^2)), mean(abs(actual[ok] - pred[ok]))),
        source = "scored_output"
      ))
    }
  }
  data.table::data.table(
    metric = c("artifact_count", "feature_count"),
    value = c(length(result$artifacts %||% list()), length(config$feature_cols %||% character())),
    source = "module_metadata"
  )
}

create_feature_challenger_experiment <- function(
  baseline_result,
  challenger_execution,
  source_data,
  catboost_config,
  output_dir = tempfile("feature_challenger_")
) {
  if (is.null(baseline_result) || !identical(baseline_result$status %||% "", "success")) {
    return(service_result(status = "error", errors = "A successful frozen baseline CatBoost result is required."))
  }
  if (!identical(challenger_execution$status, "success")) {
    return(service_result(status = "error", errors = "A successful Rodeo feature execution is required."))
  }
  frozen <- baseline_result$metadata$configured_inputs %||% normalize_catboost_builder_config(catboost_config)
  if (is.null(frozen$target_col) || !length(frozen$feature_cols %||% character())) {
    return(service_result(status = "error", errors = "Baseline cannot be reconstructed because target or feature manifest is missing."))
  }
  transformed <- challenger_execution$value$transformed_data
  added <- setdiff(names(transformed), names(source_data))
  removed <- setdiff(names(source_data), names(transformed))
  challenger_features <- setdiff(unique(c(frozen$feature_cols, added)), removed)
  challenger_features <- setdiff(challenger_features, frozen$target_col)
  context <- new_modeling_context(
    active_dataset_id = "active_dataset",
    active_dataset_label = "Feature Experiment Challenger Dataset",
    active_dataset_source = "prepared_artifact",
    active_dataset_artifact_id = challenger_execution$value$prepared_dataset_artifact_id,
    feature_manifest = challenger_features,
    target = frozen$target_col,
    preparation_execution_id = challenger_execution$value$execution_id,
    transformation_specification_ids = challenger_execution$value$spec$id,
    fitted_transformation_ids = challenger_execution$value$fitted_spec$id,
    lineage_summary = paste("Challenger produced by", challenger_execution$value$execution_id)
  )
  challenger_config <- frozen
  challenger_config$feature_cols <- challenger_features
  challenger_config$data_name <- "Feature Experiment Challenger"
  challenger_config$modeling_context <- context
  experiment_id <- feature_experiment_id("fexp", challenger_execution$value$execution_id, frozen$module_run_id)
  challenger_config$experiment_id <- experiment_id
  challenger <- run_autoquant_catboost_builder(transformed, challenger_config)
  if (!identical(challenger$status, "success")) {
    return(service_result(status = "error", value = list(challenger_result = challenger), errors = challenger$errors %||% "CatBoost challenger failed.", metadata = list(experiment_id = experiment_id, status = "failed")))
  }
  baseline_metrics <- feature_experiment_metric_table(baseline_result, source_data, frozen)
  challenger_metrics <- feature_experiment_metric_table(challenger, transformed, challenger_config)
  comparison <- compare_feature_experiment_results(
    baseline_metrics = baseline_metrics,
    challenger_metrics = challenger_metrics,
    baseline_result = baseline_result,
    challenger_result = challenger,
    experiment_id = experiment_id,
    acceptance_criteria = (challenger_execution$value$proposal %||% list())$acceptance_criteria %||% list(primary_metric = "rmse", direction = "decrease")
  )
  experiment <- list(
    experiment_id = experiment_id,
    project_id = challenger_execution$value$proposal$project_id,
    experiment_version = feature_experiment_schema_version(),
    proposal_ids = challenger_execution$value$proposal$proposal_id,
    baseline_model_result_id = baseline_result$metadata$module_run_id,
    baseline_dataset_artifact_id = (frozen$modeling_context %||% list())$active_dataset_artifact_id %||% "active_dataset",
    baseline_feature_manifest = frozen$feature_cols,
    challenger_dataset_artifact_id = challenger_execution$value$prepared_dataset_artifact_id,
    challenger_feature_manifest = challenger_features,
    transformation_execution_ids = challenger_execution$value$execution_id,
    experiment_pattern = "baseline_vs_one_challenger",
    frozen_target = frozen$target_col,
    frozen_partition_id = frozen$split_col %||% frozen$split_method %||% "random",
    frozen_seed = frozen$seed,
    frozen_catboost_parameters = frozen[c("iterations", "depth", "learning_rate", "train_fraction", "split_method", "threshold")],
    evaluation_metrics = unique(c(baseline_metrics$metric, challenger_metrics$metric)),
    acceptance_criteria = (challenger_execution$value$proposal %||% list())$acceptance_criteria,
    rejection_criteria = (challenger_execution$value$proposal %||% list())$rejection_criteria,
    confirmation_criteria = (challenger_execution$value$proposal %||% list())$confirmation_criteria,
    status = "compared",
    decision = comparison$value$deterministic_decision,
    decision_rationale = comparison$value$decision_rationale,
    created_at = feature_experiment_now(),
    completed_at = feature_experiment_now(),
    audit_references = character()
  )
  artifact <- create_artifact(
    artifact_id = paste0("aq_fexp_", experiment_id, "_comparison"),
    artifact_type = "table",
    label = "Feature Experiment Baseline vs Challenger Comparison",
    source_module = "feature_experiment_loop",
    object = comparison$value$comparison_table,
    metadata = list(
      module_id = "feature_experiment_loop",
      module_run_id = experiment_id,
      source_module = "feature_experiment_loop",
      original_name = "comparison",
      created_by_module = TRUE,
      generated_at = Sys.time(),
      experiment_id = experiment_id,
      comparison_schema_version = feature_comparison_schema_version(),
      artifact_importance = "critical",
      analytical_intent = "Comparison"
    ),
    section = "Feature Experiment",
    order = 1L
  )
  service_result(
    status = "success",
    value = list(experiment = experiment, challenger_result = challenger, comparison = comparison$value),
    artifacts = c(list(comparison = artifact), challenger$artifacts %||% list()),
    messages = paste("Completed feature challenger experiment:", experiment_id),
    metadata = list(experiment_id = experiment_id, experiment_schema_version = feature_experiment_schema_version(), status = "compared")
  )
}

compare_feature_experiment_results <- function(
  baseline_metrics,
  challenger_metrics,
  baseline_result = NULL,
  challenger_result = NULL,
  experiment_id = NULL,
  acceptance_criteria = list(primary_metric = "rmse", direction = "decrease", min_relative_improvement = 0)
) {
  base <- data.table::as.data.table(baseline_metrics)
  chall <- data.table::as.data.table(challenger_metrics)
  data.table::setnames(base, "value", "baseline_value")
  data.table::setnames(chall, "value", "challenger_value")
  comparison <- merge(base[, .(metric, baseline_value)], chall[, .(metric, challenger_value)], by = "metric", all = TRUE)
  comparison[, absolute_delta := challenger_value - baseline_value]
  comparison[, relative_delta := data.table::fifelse(is.finite(baseline_value) & baseline_value != 0, absolute_delta / abs(baseline_value), NA_real_)]
  primary <- acceptance_criteria$primary_metric %||% comparison$metric[[1L]]
  row <- comparison[metric == primary]
  if (!nrow(row)) row <- comparison[1L]
  direction <- acceptance_criteria$direction %||% "decrease"
  min_improvement <- as.numeric(acceptance_criteria$min_relative_improvement %||% 0)
  improved <- if (identical(direction, "decrease")) {
    is.finite(row$absolute_delta) && row$absolute_delta < 0 && (is.na(row$relative_delta) || abs(row$relative_delta) >= min_improvement)
  } else {
    is.finite(row$absolute_delta) && row$absolute_delta > 0 && (is.na(row$relative_delta) || abs(row$relative_delta) >= min_improvement)
  }
  decision <- if (isTRUE(improved)) "accept" else if (!is.finite(row$absolute_delta)) "inconclusive" else "reject"
  rationale <- if (identical(decision, "accept")) {
    paste("Primary metric improved:", row$metric)
  } else if (identical(decision, "reject")) {
    paste("Primary metric did not improve:", row$metric)
  } else {
    "Primary metric was unavailable or inconclusive."
  }
  service_result(
    status = "success",
    value = list(
      comparison_schema_version = feature_comparison_schema_version(),
      experiment_id = experiment_id %||% NA_character_,
      comparison_table = comparison,
      deterministic_decision = decision,
      decision_rationale = rationale,
      warnings = character()
    ),
    messages = rationale
  )
}

interpret_feature_experiment_outcome <- function(comparison, genai_recommendation = NULL) {
  deterministic <- comparison$deterministic_decision %||% "inconclusive"
  genai <- genai_recommendation %||% deterministic
  conflict <- !is.na(genai) && nzchar(genai) && !identical(genai, deterministic)
  list(
    interpretation_schema_version = "feature_experiment_interpretation_v1",
    recommendation = deterministic,
    genai_recommendation = genai,
    conflict_with_deterministic_rule = conflict,
    explanation = if (conflict) {
      paste("GenAI recommendation", genai, "conflicts with deterministic comparison", deterministic, "and requires human review.")
    } else {
      paste("Outcome classification follows deterministic comparison:", deterministic)
    },
    evidence_references = comparison$experiment_id %||% NA_character_,
    next_action = switch(deterministic, accept = "Review and explicitly adopt or defer.", reject = "Retain negative evidence and avoid reproposal without new evidence.", inconclusive = "Run a confirmation experiment or gather more diagnostics.", "Review result.")
  )
}

feature_experiment_find_existing_adoption <- function(experiment_id, adoptions = list()) {
  if (!length(adoptions) || !nzchar(experiment_id %||% "")) return(NULL)
  matches <- Filter(function(adoption) {
    value <- adoption$value %||% adoption
    identical(value$experiment_id %||% "", experiment_id)
  }, adoptions)
  if (length(matches)) matches[[1L]] else NULL
}

adopt_feature_challenger <- function(experiment_result, approval = FALSE, ctx = NULL, existing_adoptions = list()) {
  experiment <- experiment_result$value$experiment %||% experiment_result$experiment %||% list()
  if (!isTRUE(approval)) {
    return(service_result(status = "error", errors = "Explicit user approval is required before adopting a challenger.", value = experiment))
  }
  if (!identical(experiment$decision %||% "", "accept")) {
    return(service_result(status = "error", errors = "Only accepted challenger experiments can be adopted.", value = experiment))
  }
  existing <- feature_experiment_find_existing_adoption(experiment$experiment_id, existing_adoptions)
  if (!is.null(existing)) {
    return(service_result(
      status = "warning",
      value = existing$value %||% existing,
      messages = paste("Duplicate challenger adoption prevented for experiment:", experiment$experiment_id),
      metadata = list(duplicate_prevented = TRUE, experiment_id = experiment$experiment_id)
    ))
  }
  adoption <- list(
    adoption_id = feature_experiment_id("fadopt", experiment$experiment_id),
    adoption_schema_version = feature_adoption_schema_version(),
    experiment_id = experiment$experiment_id,
    project_id = experiment$project_id,
    challenger_dataset_artifact_id = experiment$challenger_dataset_artifact_id,
    challenger_feature_manifest = experiment$challenger_feature_manifest,
    prior_model_result_id = experiment$baseline_model_result_id,
    adopted_at = feature_experiment_now(),
    approval = "explicit_user_approval",
    adoption_status = "adopted",
    audit_references = character()
  )
  if (!is.null(ctx) && is.function(ctx$activate_prepared_dataset_artifact)) {
    activation <- ctx$activate_prepared_dataset_artifact(experiment$challenger_dataset_artifact_id)
    adoption$activation_status <- activation$status
    adoption$activation_message <- service_result_message(activation)
  }
  service_result(status = "success", value = adoption, messages = paste("Adopted challenger experiment:", experiment$experiment_id), metadata = list(adoption_id = adoption$adoption_id, experiment_id = experiment$experiment_id))
}

reconcile_feature_experiment_loop <- function(proposals = list(), executions = list(), experiments = list(), adoptions = list(), project_id = NULL) {
  issues <- list()
  add <- function(code, severity, detail) {
    issues[[length(issues) + 1L]] <<- data.table::data.table(code = code, severity = severity, detail = detail)
  }
  for (proposal in proposals) {
    if (!length(proposal$evidence_artifact_ids %||% character())) add("proposal_without_evidence", "error", proposal$proposal_id)
    if (!is.null(project_id) && !identical(proposal$project_id, project_id)) add("proposal_cross_project", "error", proposal$proposal_id)
    if (identical(proposal$proposal_status, "approved")) {
      matched <- any(vapply(executions, function(x) identical((x$value$proposal %||% list())$proposal_id, proposal$proposal_id), logical(1)))
      if (!matched) add("approved_without_execution", "warning", proposal$proposal_id)
    }
  }
  for (execution in executions) {
    if (identical(execution$status, "success") && is.null(execution$artifacts$transformed_dataset)) add("execution_without_prepared_artifact", "error", execution$metadata$execution_id %||% "")
  }
  for (experiment_result in experiments) {
    experiment <- experiment_result$value$experiment %||% list()
    if (is.null(experiment$baseline_model_result_id) || is.null(experiment$challenger_dataset_artifact_id)) add("experiment_missing_lineage", "error", experiment$experiment_id %||% "")
    if (identical(experiment$decision, "accept")) {
      adopted <- any(vapply(adoptions, function(x) identical((x$value %||% x)$experiment_id, experiment$experiment_id), logical(1)))
      if (!adopted) add("accepted_without_adoption_state", "warning", experiment$experiment_id)
    }
  }
  table <- if (length(issues)) data.table::rbindlist(issues) else data.table::data.table(code = character(), severity = character(), detail = character())
  service_result(status = if (any(table$severity == "error")) "error" else if (nrow(table)) "warning" else "success", value = table, messages = if (!nrow(table)) "Feature experiment references reconcile." else "Feature experiment reconciliation found issues.")
}

feature_experiment_state_summary <- function(state = list()) {
  proposals <- state$proposals %||% list()
  executions <- state$executions %||% list()
  experiments <- state$experiments %||% list()
  adoptions <- state$adoptions %||% list()
  proposal_statuses <- vapply(proposals, function(x) x$proposal_status %||% "unknown", character(1))
  execution_statuses <- vapply(executions, function(x) x$status %||% "unknown", character(1))
  experiment_decisions <- vapply(experiments, function(x) (x$value$experiment %||% x$experiment %||% list())$decision %||% "unknown", character(1))
  adoption_statuses <- vapply(adoptions, function(x) (x$value %||% x)$adoption_status %||% "unknown", character(1))
  data.table::data.table(
    total_proposals = length(proposals),
    awaiting_review = sum(proposal_statuses %in% c("proposed", "awaiting_approval")),
    approved_proposals = sum(proposal_statuses == "approved"),
    unsupported_or_blocked = sum(proposal_statuses %in% c("unsupported", "blocked")),
    executions = length(executions),
    failed_executions = sum(execution_statuses == "error"),
    experiments = length(experiments),
    accepted = sum(experiment_decisions == "accept"),
    rejected = sum(experiment_decisions == "reject"),
    inconclusive = sum(experiment_decisions == "inconclusive"),
    adoptions = sum(adoption_statuses == "adopted")
  )
}

feature_experiment_history_table <- function(state = list()) {
  proposals <- state$proposals %||% list()
  executions <- state$executions %||% list()
  experiments <- state$experiments %||% list()
  adoptions <- state$adoptions %||% list()
  rows <- list()
  add <- function(stage, id, status, title, project_id = NA_character_, timestamp = NA_character_, related_id = NA_character_) {
    rows[[length(rows) + 1L]] <<- data.table::data.table(
      stage = stage,
      id = id %||% NA_character_,
      status = status %||% NA_character_,
      title = title %||% NA_character_,
      project_id = project_id %||% NA_character_,
      timestamp = as.character(timestamp %||% NA_character_),
      related_id = related_id %||% NA_character_
    )
  }
  for (proposal in proposals) {
    add(
      "proposal",
      proposal$proposal_id,
      proposal$proposal_status,
      proposal$diagnosed_problem,
      proposal$project_id,
      proposal$created_at,
      proposal$source_model_result_id
    )
  }
  for (execution in executions) {
    value <- execution$value %||% list()
    proposal <- value$proposal %||% list()
    add(
      "execution",
      value$execution_id %||% execution$metadata$execution_id,
      execution$status,
      paste("Rodeo execution for", proposal$transformation_type %||% "proposal"),
      proposal$project_id,
      execution$metadata$generated_at %||% execution$metadata$created_at,
      proposal$proposal_id
    )
  }
  for (experiment_result in experiments) {
    experiment <- experiment_result$value$experiment %||% experiment_result$experiment %||% list()
    add(
      "experiment",
      experiment$experiment_id,
      experiment$decision %||% experiment$status,
      experiment$decision_rationale,
      experiment$project_id,
      experiment$completed_at %||% experiment$created_at,
      paste(experiment$proposal_ids %||% character(), collapse = ", ")
    )
  }
  for (adoption in adoptions) {
    value <- adoption$value %||% adoption
    add(
      "adoption",
      value$adoption_id,
      value$adoption_status,
      paste("Adoption for", value$challenger_dataset_artifact_id %||% "challenger"),
      value$project_id,
      value$adopted_at,
      value$experiment_id
    )
  }
  if (!length(rows)) {
    return(data.table::data.table(stage = character(), id = character(), status = character(), title = character(), project_id = character(), timestamp = character(), related_id = character()))
  }
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

feature_experiment_recovery_summary <- function(state = list(), project_id = NULL) {
  reconciliation <- reconcile_feature_experiment_loop(
    proposals = state$proposals %||% list(),
    executions = state$executions %||% list(),
    experiments = state$experiments %||% list(),
    adoptions = state$adoptions %||% list(),
    project_id = project_id
  )
  issues <- reconciliation$value %||% data.table::data.table()
  actions <- if (!nrow(issues)) {
    data.table::data.table(priority = "none", recommendation = "No feature experiment recovery action is required.")
  } else {
    data.table::rbindlist(lapply(seq_len(nrow(issues)), function(i) {
      issue <- issues[i]
      data.table::data.table(
        priority = if (identical(issue$severity, "error")) "high" else "medium",
        recommendation = switch(
          issue$code,
          proposal_without_evidence = "Review the proposal and attach evidence before execution.",
          proposal_cross_project = "Do not reuse this proposal in the current project without reproposal.",
          approved_without_execution = "Execute the approved proposal through Rodeo or reject/defer it.",
          execution_without_prepared_artifact = "Rerun the Rodeo execution to produce a prepared dataset artifact.",
          experiment_missing_lineage = "Treat the experiment as incomplete until baseline and challenger lineage are restored.",
          accepted_without_adoption_state = "Explicitly adopt or defer the accepted challenger.",
          "Review the feature experiment issue."
        )
      )
    }), use.names = TRUE, fill = TRUE)
  }
  service_result(
    status = reconciliation$status,
    value = list(issues = issues, recommendations = actions),
    messages = service_result_message(reconciliation)
  )
}

save_feature_experiment_bundle <- function(bundle, path) {
  saveRDS(bundle, path, version = 3)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

load_feature_experiment_bundle <- function(path) {
  readRDS(path)
}

qa_feature_experiment_loop <- function(output_dir = file.path(tempdir(), "feature_experiment_loop_qa"), run_catboost = TRUE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(2601)
  n <- 80L
  data <- data.table::data.table(
    id = seq_len(n),
    event_date = as.Date("2026-01-01") + seq_len(n),
    channel = sample(c("Search", "Social", "Email"), n, TRUE),
    spend = stats::runif(n, 1, 100),
    clicks = stats::rpois(n, 25)
  )
  data$spend[sample(seq_len(n), 8L)] <- NA_real_
  data[, revenue := 25 + data.table::fifelse(is.na(spend), 45, spend * 1.8) + clicks * 0.7 + stats::rnorm(n, 0, 5)]
  context <- feature_experiment_evidence_context(
    data = data,
    artifacts = list(create_artifact("qa_evidence_missingness", "diagnostic", "Missingness Evidence", "qa", metadata = list(created_by_module = TRUE))),
    modeling_context = modeling_context_from_source(data = data, data_info = list(name = "QA Source"), project = list(project_id = "qa_project")),
    target_col = "revenue",
    feature_cols = c("spend", "clicks"),
    project_id = "qa_project"
  )
  generated <- generate_feature_proposals(context, max_proposals = 3L)
  proposals <- generated$value
  proposal <- proposals[[which(vapply(proposals, function(x) identical(x$transformation_type, "missing_impute"), logical(1)))[[1L]]]]
  validation <- validate_feature_proposal(proposal, context)
  unsupported <- feature_proposal("Unsupported idea", "Try arbitrary expression", "arbitrary_expression", "spend", evidence_artifact_ids = "qa_evidence_missingness", project_id = "qa_project")
  approved <- approve_feature_proposal(proposal)$value
  rejected <- reject_feature_proposal(proposal, "QA rejection branch.")
  blocked_execution <- execute_feature_proposal_with_rodeo(proposal, data, output_dir)
  execution <- execute_feature_proposal_with_rodeo(approved, data, output_dir)
  duplicate_execution <- execute_feature_proposal_with_rodeo(approved, data, output_dir, existing_executions = list(execution))
  no_mutation <- any(is.na(data$spend))
  artifact_ok <- is_prepared_feature_experiment_dataset_artifact(execution$artifacts$transformed_dataset)
  reload_path <- file.path(output_dir, "bundle.rds")
  bundle_path <- save_feature_experiment_bundle(list(proposals = proposals, execution = execution), reload_path)
  reloaded <- load_feature_experiment_bundle(bundle_path)

  baseline <- NULL
  experiment <- NULL
  interpretation <- NULL
  adoption_fail <- NULL
  adoption <- NULL
  catboost_status <- "warning"
  if (isTRUE(run_catboost) && autoquant_catboost_builder_available()) {
    config <- list(
      problem_type = "regression",
      target_col = "revenue",
      feature_cols = c("spend", "clicks"),
      train_fraction = 0.75,
      seed = 2601L,
      iterations = 10L,
      depth = 4L,
      compute_shap = FALSE,
      include_plots = FALSE,
      top_n = 5L,
      data_name = "Feature Experiment Baseline",
      modeling_context = modeling_context_from_source(data = data, data_info = list(name = "QA Source"), project = list(project_id = "qa_project"))
    )
    baseline <- run_autoquant_catboost_builder(data, config)
    if (identical(baseline$status, "success")) {
      experiment <- create_feature_challenger_experiment(baseline, execution, data, config, output_dir)
      if (identical(experiment$status, "success")) {
        interpretation <- interpret_feature_experiment_outcome(experiment$value$comparison)
        adoption_fail <- adopt_feature_challenger(experiment, approval = FALSE)
        adoption <- if (identical(experiment$value$experiment$decision, "accept")) {
          adopt_feature_challenger(experiment, approval = TRUE)
        } else {
          service_result(status = "success", value = list(experiment_id = experiment$value$experiment$experiment_id, adoption_status = "not_adopted", reason = "Challenger was not accepted."), messages = "Rejected or inconclusive challenger was retained without adoption.")
        }
        catboost_status <- "success"
      } else {
        catboost_status <- "error"
      }
    } else {
      catboost_status <- "error"
    }
  }
  comparison <- if (!is.null(experiment) && identical(experiment$status, "success")) experiment$value$comparison else compare_feature_experiment_results(
    baseline_metrics = data.table::data.table(metric = "rmse", value = 10, source = "qa"),
    challenger_metrics = data.table::data.table(metric = "rmse", value = 9, source = "qa"),
    experiment_id = "qa_fallback"
  )$value
  interpretation <- interpretation %||% interpret_feature_experiment_outcome(comparison)
  fake_experiment <- if (!is.null(experiment)) experiment else service_result(status = "success", value = list(experiment = list(experiment_id = "qa_fallback", decision = "accept", project_id = "qa_project", baseline_model_result_id = "base", challenger_dataset_artifact_id = execution$value$prepared_dataset_artifact_id, challenger_feature_manifest = c("spend", "clicks"))))
  adoption_fail <- adoption_fail %||% adopt_feature_challenger(fake_experiment, approval = FALSE)
  adoption <- adoption %||% adopt_feature_challenger(fake_experiment, approval = TRUE)
  accepted_fixture <- service_result(status = "success", value = list(experiment = list(
    experiment_id = "qa_accept_fixture",
    decision = "accept",
    project_id = "qa_project",
    baseline_model_result_id = "base",
    challenger_dataset_artifact_id = execution$value$prepared_dataset_artifact_id,
    challenger_feature_manifest = c("spend", "clicks")
  )))
  accepted_adoption <- adopt_feature_challenger(accepted_fixture, approval = TRUE)
  duplicate_adoption <- adopt_feature_challenger(accepted_fixture, approval = TRUE, existing_adoptions = list(accepted_adoption))
  reconciliation <- reconcile_feature_experiment_loop(list(approved), list(execution), list(fake_experiment), list(adoption), project_id = "qa_project")
  history <- feature_experiment_history_table(list(proposals = list(approved, rejected$value), executions = list(execution), experiments = list(fake_experiment), adoptions = list(adoption)))
  recovery <- feature_experiment_recovery_summary(list(proposals = list(approved), executions = list(), experiments = list(fake_experiment), adoptions = list(adoption)), project_id = "qa_project")
  context_with_history <- feature_experiment_evidence_context(
    data = data,
    artifacts = list(create_artifact("qa_evidence_missingness", "diagnostic", "Missingness Evidence", "qa", metadata = list(created_by_module = TRUE))),
    feature_experiment_state = list(proposals = list(approved), executions = list(execution), experiments = list(fake_experiment), adoptions = list(adoption)),
    target_col = "revenue",
    feature_cols = c("spend", "clicks"),
    project_id = "qa_project"
  )
  rows <- data.table::data.table(
    check = c(
      "evidence_context_bounded",
      "evidence_context_includes_prior_outcomes",
      "proposal_generation_bounded",
      "proposal_schema_valid",
      "unsupported_classified",
      "approval_required_before_execution",
      "proposal_rejection_retained",
      "rodeo_execution_success",
      "duplicate_execution_prevented",
      "input_not_mutated",
      "prepared_dataset_artifact_created",
      "serialization_reload",
      "catboost_challenger_path",
      "comparison_deterministic",
      "interpretation_created",
      "adoption_requires_approval",
      "explicit_adoption_records_decision",
      "duplicate_adoption_prevented",
      "history_table_created",
      "recovery_summary_created",
      "reconciliation_runs"
    ),
    status = c(
      if (nrow(context$dataset_schema) == ncol(data) && identical(context$bounds$raw_rows_included, 0L)) "success" else "error",
      if (nrow(context_with_history$prior_feature_outcomes) >= 3L) "success" else "error",
      if (identical(generated$status, "success") && length(proposals) <= 3L) "success" else "error",
      if (identical(validation$status, "success")) "success" else "error",
      if (identical(unsupported$proposal_status, "unsupported") || identical(unsupported$proposal_status, "blocked")) "success" else "error",
      if (identical(blocked_execution$status, "error")) "success" else "error",
      if (identical(rejected$status, "success") && identical(rejected$value$proposal_status, "rejected")) "success" else "error",
      if (identical(execution$status, "success")) "success" else "error",
      if (identical(duplicate_execution$status, "warning") && isTRUE(duplicate_execution$metadata$duplicate_prevented)) "success" else "error",
      if (isTRUE(no_mutation)) "success" else "error",
      if (isTRUE(artifact_ok)) "success" else "error",
      if (file.exists(bundle_path) && identical(reloaded$execution$metadata$execution_id, execution$metadata$execution_id)) "success" else "error",
      catboost_status,
      if (comparison$deterministic_decision %in% c("accept", "reject", "inconclusive")) "success" else "error",
      if (interpretation$recommendation %in% c("accept", "reject", "inconclusive")) "success" else "error",
      if (identical(adoption_fail$status, "error")) "success" else "error",
      if (identical(adoption$status, "success")) "success" else "error",
      if (identical(duplicate_adoption$status, "warning") && isTRUE(duplicate_adoption$metadata$duplicate_prevented)) "success" else "error",
      if (nrow(history) >= 4L && all(c("proposal", "execution", "experiment") %in% history$stage)) "success" else "error",
      if (recovery$status %in% c("success", "warning") && nrow(recovery$value$recommendations) >= 1L) "success" else "error",
      if (reconciliation$status %in% c("success", "warning")) "success" else "error"
    ),
    message = c(
      "Context includes schema and artifact refs, not raw rows.",
      paste("Prior outcomes:", nrow(context_with_history$prior_feature_outcomes)),
      paste("Generated proposals:", length(proposals)),
      validation$messages %||% paste(validation$errors, collapse = " | "),
      paste("Unsupported status:", unsupported$proposal_status),
      "Unapproved proposal execution is blocked.",
      "Rejected proposal is preserved as a result object.",
      execution$messages %||% paste(execution$errors, collapse = " | "),
      duplicate_execution$messages %||% paste(duplicate_execution$errors, collapse = " | "),
      "Source data still contains original missing values.",
      execution$value$prepared_dataset_artifact_id %||% "",
      bundle_path,
      if (identical(catboost_status, "success")) "Baseline and challenger CatBoost path completed." else "CatBoost unavailable or challenger path failed.",
      comparison$decision_rationale,
      interpretation$explanation,
      "Adoption without approval is rejected.",
      adoption$messages %||% paste(adoption$errors, collapse = " | "),
      duplicate_adoption$messages %||% paste(duplicate_adoption$errors, collapse = " | "),
      paste("History rows:", nrow(history)),
      service_result_message(recovery),
      service_result_message(reconciliation)
    )
  )
  rows
}
