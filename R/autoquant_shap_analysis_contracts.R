shap_problem_types <- function() {
  c("regression", "binary_classification", "multiclass")
}

shap_date_aggregations <- function() {
  c("day", "week", "month")
}

shap_sections <- function() {
  c(
    "SHAP Overview",
    "Global Importance",
    "Threshold Context",
    "Class Balance / Outcome Context",
    "Interaction Importance",
    "Single Feature Effects",
    "SHAP Dependence",
    "Segment Effects",
    "Time Effects",
    "Local Explanations",
    "Appendix"
  )
}

shap_lenses <- function() {
  c(
    "overview",
    "global_importance",
    "threshold_context",
    "class_balance",
    "interaction_importance",
    "single_feature_effects",
    "shap_dependence",
    "segment_effects",
    "time_effects",
    "local_explanations",
    "diagnostics"
  )
}

shap_artifact_id_prefix <- function(problem_type) {
  problem_type <- normalize_shap_problem_type(problem_type)
  prefixes <- c(
    regression = "aq_rshap_",
    binary_classification = "aq_bshap_",
    multiclass = "aq_mshap_"
  )

  if (problem_type %in% names(prefixes)) {
    return(prefixes[[problem_type]])
  }

  "aq_shap_"
}

normalize_shap_problem_type <- function(problem_type) {
  value <- tolower(trimws(problem_type %||% ""))
  value <- gsub("[ -]+", "_", value)

  aliases <- c(
    regression = "regression",
    reg = "regression",
    binary = "binary_classification",
    binary_classification = "binary_classification",
    classification_binary = "binary_classification",
    binomial = "binary_classification",
    multiclass = "multiclass",
    multi_class = "multiclass"
  )

  normalized <- aliases[[value]]
  if (is.null(normalized)) {
    return(value)
  }

  normalized
}

normalize_shap_date_aggregation <- function(date_aggregation) {
  value <- tolower(trimws(date_aggregation %||% ""))
  if (!nzchar(value)) {
    return(NULL)
  }

  aliases <- c(
    daily = "day",
    day = "day",
    weekly = "week",
    week = "week",
    monthly = "month",
    month = "month"
  )

  aliases[[value]] %||% value
}

.shap_clean_character_vector <- function(value) {
  value <- value %||% character()
  value <- as.character(value)
  value[nzchar(value)]
}

create_shap_analysis_config <- function(
  problem_type,
  data_name = NULL,
  target_col = NULL,
  target_var = NULL,
  prediction_col = NULL,
  predicted_class_col = NULL,
  feature_cols = character(),
  feature_vars = character(),
  shap_prefix = "Shap_",
  id_cols = character(),
  model_ref = NULL,
  prediction_function = NULL,
  prediction_type = NULL,
  prediction_scale = NULL,
  positive_class = NULL,
  threshold = 0.5,
  threshold_bands = NULL,
  DateVar = NULL,
  date_var = NULL,
  ByVars = character(),
  date_aggregation = "month",
  by_vars = character(),
  segment_vars = character(),
  selected_features = character(),
  interaction_pairs = list(),
  local_row_ids = integer(),
  top_n = 20L,
  max_dependence_rows = 5000L,
  max_segment_levels = 20L,
  max_byvars = 3L,
  include_dependence = TRUE,
  include_segments = TRUE,
  include_time = TRUE,
  include_local = FALSE,
  include_interactions = FALSE,
  include_threshold_context = TRUE,
  include_class_balance = TRUE,
  include_plots = TRUE,
  max_feature_effect_plots = 5L,
  max_dependence_plots = 5L,
  max_segment_plots = 5L,
  max_time_plots = 5L,
  max_local_plots = 5L,
  max_interaction_surface_plots = 10L,
  numeric_interaction_bins = 5L,
  max_interaction_levels = 12L,
  min_interaction_cell_n = 5L,
  sample_n = NULL,
  background_n = NULL,
  seed = 123L,
  shap_backend = "auto",
  sample_size = 10000L,
  max_features = 20L,
  max_interaction_pairs = 10L,
  backend = NULL,
  artifact_options = list(),
  report_plan_options = list()
) {
  normalized_DateVar <- DateVar %||% date_var
  normalized_ByVars <- .shap_clean_character_vector(c(ByVars, by_vars))
  normalized_backend <- shap_backend %||% backend %||% "auto"
  normalized_target <- target_col %||% target_var
  normalized_features <- .shap_clean_character_vector(c(feature_cols, feature_vars))

  list(
    data_name = data_name,
    problem_type = normalize_shap_problem_type(problem_type),
    target_col = normalized_target,
    target_var = normalized_target,
    prediction_col = prediction_col,
    predicted_class_col = predicted_class_col,
    feature_cols = normalized_features,
    feature_vars = normalized_features,
    shap_prefix = shap_prefix %||% "Shap_",
    id_cols = .shap_clean_character_vector(id_cols),
    model_ref = model_ref,
    prediction_function = prediction_function,
    prediction_type = prediction_type,
    prediction_scale = prediction_scale %||% prediction_type,
    positive_class = positive_class,
    threshold = as.numeric(threshold %||% 0.5),
    threshold_bands = threshold_bands,
    DateVar = normalized_DateVar,
    date_var = normalized_DateVar,
    date_aggregation = normalize_shap_date_aggregation(date_aggregation),
    ByVars = normalized_ByVars,
    by_vars = normalized_ByVars,
    segment_vars = .shap_clean_character_vector(segment_vars),
    selected_features = .shap_clean_character_vector(selected_features),
    interaction_pairs = interaction_pairs %||% list(),
    local_row_ids = local_row_ids %||% character(),
    top_n = as.integer(top_n %||% 20L),
    max_dependence_rows = as.integer(max_dependence_rows %||% 5000L),
    max_segment_levels = as.integer(max_segment_levels %||% 20L),
    max_byvars = as.integer(max_byvars %||% 3L),
    include_dependence = isTRUE(include_dependence),
    include_segments = isTRUE(include_segments),
    include_time = isTRUE(include_time),
    include_local = isTRUE(include_local),
    include_interactions = isTRUE(include_interactions),
    include_threshold_context = isTRUE(include_threshold_context),
    include_class_balance = isTRUE(include_class_balance),
    include_plots = isTRUE(include_plots),
    max_feature_effect_plots = as.integer(max_feature_effect_plots %||% 5L),
    max_dependence_plots = as.integer(max_dependence_plots %||% 5L),
    max_segment_plots = as.integer(max_segment_plots %||% 5L),
    max_time_plots = as.integer(max_time_plots %||% 5L),
    max_local_plots = as.integer(max_local_plots %||% 5L),
    max_interaction_surface_plots = as.integer(max_interaction_surface_plots %||% 10L),
    numeric_interaction_bins = as.integer(numeric_interaction_bins %||% 5L),
    max_interaction_levels = as.integer(max_interaction_levels %||% 12L),
    min_interaction_cell_n = as.integer(min_interaction_cell_n %||% 5L),
    sample_n = sample_n,
    background_n = background_n,
    seed = as.integer(seed %||% 123L),
    shap_backend = normalized_backend,
    sample_size = as.integer(sample_size %||% 10000L),
    max_features = as.integer(max_features %||% 20L),
    max_interaction_pairs = as.integer(max_interaction_pairs %||% 10L),
    backend = normalized_backend,
    artifact_options = artifact_options %||% list(),
    report_plan_options = report_plan_options %||% list()
  )
}

validate_shap_analysis_config <- function(config, data = NULL, problem_type = NULL) {
  errors <- character()
  warnings <- character()

  if (is.null(config)) {
    config <- list()
  }

  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "SHAP config must be a list.",
      metadata = list(error_code = "SHAP_CONFIG_INVALID")
    ))
  }

  configured_problem_type <- normalize_shap_problem_type(problem_type %||% config$problem_type)
  if (!configured_problem_type %in% shap_problem_types()) {
    errors <- c(
      errors,
      paste("problem_type must be one of:", paste(shap_problem_types(), collapse = ", "))
    )
  }
  if (identical(configured_problem_type, "multiclass")) {
    errors <- c(errors, "Multiclass SHAP Analysis is deferred and is not implemented yet.")
  }

  config$DateVar <- config$DateVar %||% config$date_var
  config$date_var <- config$DateVar
  config$ByVars <- .shap_clean_character_vector(c(config$ByVars, config$by_vars))
  config$by_vars <- config$ByVars
  config$target_col <- config$target_col %||% config$target_var
  config$target_var <- config$target_col
  config$feature_cols <- .shap_clean_character_vector(c(config$feature_cols, config$feature_vars))
  config$feature_vars <- config$feature_cols
  config$id_cols <- .shap_clean_character_vector(config$id_cols)
  config$predicted_class_col <- config$predicted_class_col %||% NULL
  config$shap_prefix <- config$shap_prefix %||% "Shap_"
  config$prediction_scale <- config$prediction_scale %||% config$prediction_type
  config$shap_backend <- config$shap_backend %||% config$backend %||% "auto"
  config$backend <- config$shap_backend

  date_aggregation <- normalize_shap_date_aggregation(config$date_aggregation)
  if (!is.null(date_aggregation) && !date_aggregation %in% shap_date_aggregations()) {
    errors <- c(
      errors,
      paste("date_aggregation must be one of:", paste(shap_date_aggregations(), collapse = ", "))
    )
  }

  if (identical(configured_problem_type, "binary_classification")) {
    if (is.null(config$positive_class) || !nzchar(as.character(config$positive_class))) {
      errors <- c(errors, "positive_class is required for Binary Classification SHAP Analysis.")
    }
    prediction_scale <- tolower(as.character(config$prediction_scale %||% "probability"))
    if (!prediction_scale %in% c("probability", "logit", "margin", "unknown")) {
      warnings <- c(warnings, "prediction_scale was not recognized; using unknown for Binary Classification SHAP Analysis.")
      prediction_scale <- "unknown"
    }
    config$prediction_scale <- prediction_scale
    threshold_value <- suppressWarnings(as.numeric(config$threshold %||% 0.5))
    if (is.na(threshold_value) || threshold_value <= 0 || threshold_value >= 1) {
      warnings <- c(warnings, "threshold should be between 0 and 1 for Binary Classification SHAP Analysis; using 0.5.")
      threshold_value <- 0.5
    }
    config$threshold <- threshold_value
  }

  numeric_limits <- c(
    "sample_size", "max_features", "top_n", "max_dependence_rows",
    "max_segment_levels", "max_byvars", "max_interaction_pairs",
    "max_interaction_surface_plots", "numeric_interaction_bins",
    "max_interaction_levels", "min_interaction_cell_n",
    "max_feature_effect_plots", "max_dependence_plots",
    "max_segment_plots", "max_time_plots", "max_local_plots"
  )
  for (limit_name in numeric_limits) {
    limit_value <- suppressWarnings(as.integer(config[[limit_name]] %||% NA_integer_))
    if (!is.na(limit_value) && limit_value < 1L) {
      errors <- c(errors, paste(limit_name, "must be a positive integer."))
    }
  }

  if (!is.null(data)) {
    columns <- names(data)
    if (configured_problem_type %in% c("regression", "binary_classification")) {
      shap_prefix <- as.character(config$shap_prefix %||% "Shap_")
      if (!nzchar(shap_prefix)) {
        errors <- c(errors, "shap_prefix must be a non-empty character value.")
      }

      shap_cols <- columns[startsWith(columns, shap_prefix)]
      shap_cols <- shap_cols[vapply(shap_cols, function(column) is.numeric(data[[column]]), logical(1))]
      shap_features <- sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", shap_prefix)), "", shap_cols)
      if (!length(shap_cols)) {
        label <- if (identical(configured_problem_type, "binary_classification")) "Binary Classification" else "Regression"
        errors <- c(errors, paste0(label, " SHAP Analysis requires numeric precomputed SHAP columns using prefix ", shap_prefix, "."))
      }

      if (!length(config$feature_cols)) {
        config$feature_cols <- intersect(shap_features, columns)
        config$feature_vars <- config$feature_cols
      }
      if (!length(config$selected_features)) {
        config$selected_features <- config$feature_cols
      }
      if (is.null(config$prediction_col) && "Predict" %in% columns) {
        config$prediction_col <- "Predict"
      }
      if (identical(configured_problem_type, "binary_classification") &&
          is.null(config$predicted_class_col) && "PredictedClass" %in% columns) {
        config$predicted_class_col <- "PredictedClass"
      }

      shap_feature_names <- sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", shap_prefix)), "", shap_cols)
      invalid_features <- setdiff(config$feature_cols, shap_feature_names)
      if (length(invalid_features)) {
        warnings <- c(
          warnings,
          paste("Some selected features do not have matching SHAP columns and will be skipped if AutoQuant cannot use them:", paste(invalid_features, collapse = ", "))
        )
        config$feature_cols <- intersect(config$feature_cols, shap_feature_names)
        config$feature_vars <- config$feature_cols
      }

      source_missing <- setdiff(config$feature_cols, columns)
      if (length(source_missing)) {
        warnings <- c(
          warnings,
          paste("Some source feature columns are missing; feature-level plots may be skipped:", paste(source_missing, collapse = ", "))
        )
      }

      optional_context <- unique(c(config$DateVar, config$ByVars, config$id_cols, config$predicted_class_col))
      optional_context <- optional_context[!is.na(optional_context) & nzchar(optional_context)]
      missing_context <- setdiff(optional_context, columns)
      if (length(missing_context)) {
        warnings <- c(warnings, paste("Optional SHAP context columns were not found and will be ignored:", paste(missing_context, collapse = ", ")))
        if (!is.null(config$DateVar) && config$DateVar %in% missing_context) {
          config$DateVar <- NULL
          config$date_var <- NULL
        }
        config$ByVars <- setdiff(config$ByVars, missing_context)
        config$by_vars <- config$ByVars
        config$id_cols <- setdiff(config$id_cols, missing_context)
        if (!is.null(config$predicted_class_col) && config$predicted_class_col %in% missing_context) {
          config$predicted_class_col <- NULL
        }
      }

      required_existing <- unique(c(config$target_col, config$prediction_col))
      required_existing <- required_existing[!is.na(required_existing) & nzchar(required_existing)]
      missing_required <- setdiff(required_existing, columns)
      if (length(missing_required)) {
        label <- if (identical(configured_problem_type, "binary_classification")) "Binary Classification" else "Regression"
        errors <- c(errors, paste("Selected", label, "SHAP columns are missing from data:", paste(missing_required, collapse = ", ")))
      }

      if (identical(configured_problem_type, "binary_classification")) {
        if (is.null(config$prediction_col) || !nzchar(as.character(config$prediction_col))) {
          errors <- c(errors, "prediction_col is required for Binary Classification SHAP Analysis.")
        }
        if (!is.null(config$prediction_col) && config$prediction_col %in% columns &&
            identical(config$prediction_scale, "probability")) {
          prediction_values <- suppressWarnings(as.numeric(data[[config$prediction_col]]))
          prediction_values <- prediction_values[!is.na(prediction_values)]
          if (length(prediction_values) && (min(prediction_values) < 0 || max(prediction_values) > 1)) {
            warnings <- c(warnings, "prediction_col contains values outside [0, 1]; prediction_scale was set to unknown.")
            config$prediction_scale <- "unknown"
          }
        }
        if (!is.null(config$target_col) && config$target_col %in% columns) {
          target_values <- unique(as.character(data[[config$target_col]]))
          target_values <- target_values[!is.na(target_values)]
          if (length(target_values) > 2L) {
            warnings <- c(warnings, "target_col contains more than two observed classes; Binary SHAP expects binary outcomes.")
          }
          if (!is.null(config$positive_class) && nzchar(as.character(config$positive_class)) &&
              length(target_values) && !as.character(config$positive_class) %in% target_values) {
            errors <- c(errors, paste("positive_class was not found in target_col:", as.character(config$positive_class)))
          }
        }
      }
    } else {
      requested_columns <- unique(c(
        config$target_var,
        config$feature_vars,
        config$DateVar,
        config$ByVars,
        config$segment_vars,
        config$selected_features
      ))
      requested_columns <- requested_columns[!is.na(requested_columns) & nzchar(requested_columns)]
      missing_columns <- setdiff(requested_columns, columns)
      if (length(missing_columns)) {
        errors <- c(errors, paste("Selected SHAP columns are missing from data:", paste(missing_columns, collapse = ", ")))
      }
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      value = config,
      errors = errors,
      warnings = warnings,
      metadata = list(
        error_code = "SHAP_CONFIG_INVALID",
        problem_type = configured_problem_type
      )
    ))
  }

  service_result(
    status = if (length(warnings)) "warning" else "success",
    value = config,
    messages = paste("SHAP config contract is valid for", configured_problem_type),
    warnings = warnings,
    metadata = list(
      problem_type = configured_problem_type,
      date_aggregation = date_aggregation,
      shap_prefix = config$shap_prefix %||% NULL,
      feature_cols = config$feature_cols %||% character()
    )
  )
}

create_shap_artifact_metadata <- function(config, lens = NULL, section = NULL, extra = list()) {
  problem_type <- normalize_shap_problem_type(config$problem_type)
  metadata <- list(
    problem_type = problem_type,
    positive_class = config$positive_class %||% NULL,
    prediction_scale = config$prediction_scale %||% config$prediction_type %||% NULL,
    target_col = config$target_col %||% config$target_var %||% NULL,
    target_var = config$target_var %||% NULL,
    prediction_col = config$prediction_col %||% NULL,
    predicted_class_col = config$predicted_class_col %||% NULL,
    threshold = config$threshold %||% NULL,
    threshold_bands = config$threshold_bands %||% NULL,
    include_threshold_context = isTRUE(config$include_threshold_context),
    include_class_balance = isTRUE(config$include_class_balance),
    feature_cols = config$feature_cols %||% config$feature_vars %||% character(),
    feature_vars = config$feature_vars %||% character(),
    shap_prefix = config$shap_prefix %||% "Shap_",
    DateVar = config$DateVar %||% config$date_var %||% NULL,
    date_aggregation = normalize_shap_date_aggregation(config$date_aggregation),
    ByVars = config$ByVars %||% config$by_vars %||% character(),
    id_cols = config$id_cols %||% character(),
    selected_features = config$selected_features %||% character(),
    segment_vars = config$segment_vars %||% character(),
    lens = lens,
    shap_source = "precomputed_columns",
    exact_shap_interaction_values = FALSE,
    shap_backend = config$shap_backend %||% config$backend %||% "auto",
    normalized_section = section %||% NULL,
    interaction_order = if (identical(lens, "interaction_importance")) 2L else NA_integer_,
    class_label = config$positive_class %||% NULL,
    comparison_group = NULL,
    model_registry_id = config$model_ref %||% NULL,
    shap_cache_key = NULL
  )

  for (name in names(extra %||% list())) {
    metadata[[name]] <- extra[[name]]
  }

  metadata
}

.shap_slug <- function(value) {
  value <- tolower(gsub("[^A-Za-z0-9]+", "_", value %||% "artifact"))
  value <- gsub("^_+|_+$", "", value)
  if (!nzchar(value)) {
    return("artifact")
  }

  value
}

.shap_extract_artifact_type <- function(item) {
  artifact_type <- .shap_field(item, "artifact_type") %||% .shap_field(item, "type") %||% .shap_field(item, "kind") %||% NULL
  artifact_type <- tolower(as.character(artifact_type %||% ""))
  if (artifact_type %in% artifact_types) {
    return(artifact_type)
  }
  if (inherits(item, "htmlwidget") || inherits(item, "shiny.tag") || inherits(item, "shiny.tag.list")) {
    return("plot")
  }
  if (data.table::is.data.table(item) || is.matrix(item)) {
    return("table")
  }
  if (is.character(item) && length(item) == 1L) {
    return("text")
  }

  "text"
}

.shap_extract_artifact_object <- function(item, artifact_type) {
  if (is.list(item) && !data.table::is.data.table(item)) {
    if (identical(artifact_type, "text")) {
      return(NULL)
    }
    return(item$object %||% item$plot %||% item$widget %||% item$table %||% item$data %||% item$value %||% item)
  }

  if (identical(artifact_type, "text")) {
    return(NULL)
  }

  item
}

.shap_extract_artifact_content <- function(item, artifact_type) {
  if (!identical(artifact_type, "text")) {
    return(NULL)
  }
  if (is.list(item) && !data.table::is.data.table(item)) {
    value <- item$content %||% item$text %||% NULL
    if (is.null(value) && is.character(item$value) && length(item$value) == 1L) {
      value <- item$value
    }
    return(value %||% item$description %||% item$label %||% "SHAP text artifact")
  }

  as.character(item %||% "SHAP text artifact")
}

.shap_field <- function(item, field) {
  if (is.list(item) && !data.table::is.data.table(item) && field %in% names(item)) {
    return(item[[field]])
  }

  NULL
}

.shap_metadata_field <- function(item, field) {
  metadata <- .shap_field(item, "metadata") %||% list()
  if (is.list(metadata) && field %in% names(metadata)) {
    return(metadata[[field]])
  }

  NULL
}

normalize_autoquant_shap_artifacts <- function(
  autoquant_result,
  config,
  module_id,
  module_run_id,
  source_function,
  generated_at = Sys.time()
) {
  items <- autoquant_result$artifacts %||% autoquant_result
  if (inherits(items, "aq_artifact")) {
    items <- list(items)
  }
  if (is.null(items) || !is.list(items) || !length(items)) {
    return(list())
  }

  problem_type <- normalize_shap_problem_type(config$problem_type)
  prefix <- shap_artifact_id_prefix(problem_type)
  item_names <- names(items)
  if (is.null(item_names)) {
    item_names <- rep("", length(items))
  }

  artifacts <- lapply(seq_along(items), function(index) {
    item <- items[[index]]
    if (inherits(item, "aq_artifact")) {
      return(item)
    }

    original_name <- item_names[[index]]
    if (!nzchar(original_name)) {
      original_name <- paste0("shap_artifact_", index)
    }
    artifact_type <- .shap_extract_artifact_type(item)
    section <- .shap_field(item, "section") %||%
      .shap_field(item, "original_section") %||%
      .shap_field(item, "normalized_section") %||%
      .shap_metadata_field(item, "normalized_section") %||%
      .shap_metadata_field(item, "original_section") %||%
      "Appendix"
    if (!section %in% shap_sections()) {
      section <- "Appendix"
    }
    autoquant_metadata <- .shap_field(item, "metadata") %||% list()
    lens <- .shap_field(item, "lens") %||% .shap_metadata_field(item, "lens") %||% .shap_slug(section)
    artifact_id <- paste0(prefix, module_run_id, "_", .shap_slug(original_name))

    module_metadata <- module_artifact_metadata(
      module_id = module_id,
      module_run_id = module_run_id,
      source_module = module_id,
      original_name = original_name,
      original_section = .shap_field(item, "section") %||% .shap_field(item, "original_section") %||%
        .shap_metadata_field(item, "original_section") %||% section,
      normalized_section = section,
      artifact_index = index,
      generated_at = generated_at,
      extra = create_shap_artifact_metadata(
        config = config,
        lens = lens,
        section = section,
        extra = list(
          source_package = "AutoQuant",
          source_function = source_function,
          autoquant_metadata = autoquant_metadata,
          shap_source = .shap_metadata_field(item, "shap_source") %||% "precomputed_columns",
          exact_shap_interaction_values = .shap_metadata_field(item, "exact_shap_interaction_values") %||% FALSE
        )
      )
    )

    create_artifact(
      artifact_id = artifact_id,
      artifact_type = artifact_type,
      label = .shap_field(item, "label") %||% .shap_field(item, "title") %||% original_name,
      source_module = module_id,
      object = .shap_extract_artifact_object(item, artifact_type),
      content = .shap_extract_artifact_content(item, artifact_type),
      config = config,
      code = .shap_field(item, "code") %||% NULL,
      metadata = module_metadata,
      section = section,
      order = index,
      status = .shap_field(item, "status") %||% "ready"
    )
  })

  stats::setNames(artifacts, vapply(artifacts, function(artifact) artifact$artifact_id, character(1)))
}

create_shap_report_plan_specs <- function(problem_type, available_sections = NULL) {
  problem_type <- normalize_shap_problem_type(problem_type)
  available_sections <- available_sections %||% shap_sections()
  available_sections <- intersect(shap_sections(), available_sections)

  if (identical(problem_type, "regression")) {
    return(list(
      recommended = list(
        label = "Recommended Regression SHAP Analysis Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c(
          "SHAP Overview",
          "Global Importance",
          "Single Feature Effects",
          "SHAP Dependence",
          "Appendix"
        ), available_sections)
      ),
      full = list(
        label = "Full Regression SHAP Analysis Report",
        layout_type = "sections",
        cols = 2L,
        sections = available_sections
      ),
      interactions = list(
        label = "Interaction Diagnostics Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Interaction Importance", "SHAP Dependence", "Appendix"), available_sections)
      ),
      segment_time = list(
        label = "Segment And Time Effects Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Segment Effects", "Time Effects", "Appendix"), available_sections)
      ),
      local_explanations = list(
        label = "Local Explanations Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Local Explanations", "Appendix"), available_sections)
      ),
      diagnostics_only = list(
        label = "Diagnostics Only",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("SHAP Overview", "Appendix"), available_sections)
      )
    ))
  }

  if (identical(problem_type, "binary_classification")) {
    return(list(
      recommended = list(
        label = "Recommended Binary Classification SHAP Analysis Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c(
          "SHAP Overview",
          "Global Importance",
          "Threshold Context",
          "Class Balance / Outcome Context",
          "Single Feature Effects",
          "SHAP Dependence",
          "Appendix"
        ), available_sections)
      ),
      full = list(
        label = "Full Binary Classification SHAP Analysis Report",
        layout_type = "sections",
        cols = 2L,
        sections = available_sections
      ),
      threshold_context = list(
        label = "Threshold Context SHAP Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Threshold Context", "SHAP Dependence", "Appendix"), available_sections)
      ),
      class_balance = list(
        label = "Class Balance And Outcome Context Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Class Balance / Outcome Context", "SHAP Overview", "Appendix"), available_sections)
      ),
      interactions = list(
        label = "Interaction Diagnostics Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Interaction Importance", "SHAP Dependence", "Appendix"), available_sections)
      ),
      segment_time = list(
        label = "Segment And Time Effects Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Segment Effects", "Time Effects", "Appendix"), available_sections)
      ),
      local_explanations = list(
        label = "Local Explanations Report",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("Local Explanations", "Appendix"), available_sections)
      ),
      diagnostics_only = list(
        label = "Diagnostics Only",
        layout_type = "sections",
        cols = 2L,
        sections = intersect(c("SHAP Overview", "Appendix"), available_sections)
      )
    ))
  }

  list()
}

qa_shap_artifact_contract <- function() {
  regression_config <- create_shap_analysis_config(
    problem_type = "regression",
    target_var = "y",
    feature_vars = c("x1", "x2"),
    prediction_col = "Predict",
    shap_prefix = "Shap_",
    date_var = "date",
    date_aggregation = "month",
    by_vars = "segment"
  )
  binary_config <- create_shap_analysis_config(
    problem_type = "binary",
    target_var = "target",
    prediction_col = "p",
    feature_vars = c("x1", "x2"),
    positive_class = "1",
    prediction_type = "probability",
    date_aggregation = "week"
  )
  qa_data <- data.table::data.table(
    y = 1:3,
    Predict = c(1.1, 2.1, 2.9),
    p = c(0.2, 0.7, 0.8),
    target = c(0, 1, 1),
    x1 = c(1, 2, 3),
    x2 = c(3, 2, 1),
    Shap_x1 = c(0.1, -0.1, 0.2),
    Shap_x2 = c(0.05, -0.02, 0.01),
    date = as.Date("2026-01-01") + 0:2,
    segment = c("A", "B", "A")
  )

  regression_validation <- validate_shap_analysis_config(regression_config, qa_data, "regression")
  binary_validation <- validate_shap_analysis_config(binary_config, qa_data, "binary_classification")
  regression_specs <- create_shap_report_plan_specs("regression")
  binary_specs <- create_shap_report_plan_specs("binary_classification")
  metadata <- create_shap_artifact_metadata(regression_config, lens = "global_importance", section = "Global Importance")

  data.table::data.table(
    check = c(
      "regression_config",
      "binary_config",
      "regression_prefix",
      "binary_prefix",
      "sections",
      "lenses",
      "regression_plan_specs",
      "binary_plan_specs",
      "artifact_metadata"
    ),
    status = c(
      regression_validation$status,
      binary_validation$status,
      if (identical(shap_artifact_id_prefix("regression"), "aq_rshap_")) "success" else "error",
      if (identical(shap_artifact_id_prefix("binary_classification"), "aq_bshap_")) "success" else "error",
      if (length(shap_sections()) == 11L) "success" else "error",
      if (all(c("global_importance", "shap_dependence") %in% shap_lenses())) "success" else "error",
      if (length(regression_specs) >= 3L) "success" else "error",
      if (length(binary_specs) >= 3L) "success" else "error",
      if (identical(metadata$lens, "global_importance") && identical(metadata$normalized_section, "Global Importance")) "success" else "error"
    ),
    message = c(
      service_result_message(regression_validation),
      service_result_message(binary_validation),
      "Regression SHAP prefix is aq_rshap_.",
      "Binary SHAP prefix is aq_bshap_.",
      "SHAP section contract is available.",
      "SHAP lens contract is available.",
      "Regression SHAP report plan specs are available.",
      "Binary SHAP report plan specs are available.",
      "SHAP artifact metadata includes lens and section context."
    )
  )
}
