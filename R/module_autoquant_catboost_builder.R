autoquant_catboost_builder_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_catboost_builder_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

.autoquant_catboost_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_catboost_builder_", gsub("[^0-9]", "", format(timestamp, "%Y%m%d%H%M%OS3")))
}

.autoquant_catboost_clean_choices <- function(value) {
  value <- value %||% character()
  value <- as.character(value)
  value[!is.na(value) & nzchar(value)]
}

.autoquant_catboost_selected_value <- function(value) {
  value <- selected_value(value)
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }

  value
}

.autoquant_catboost_problem_type <- function(problem_type) {
  value <- tolower(trimws(as.character(problem_type %||% "regression")))
  value <- gsub("[ -]+", "_", value)
  if (value %in% c("binary", "binary_classification", "classification")) {
    return("binary")
  }
  "regression"
}

normalize_catboost_builder_config <- function(config = list()) {
  config <- config %||% list()
  list(
    problem_type = .autoquant_catboost_problem_type(config$problem_type),
    target_col = .autoquant_catboost_selected_value(config$target_col),
    feature_cols = .autoquant_catboost_clean_choices(config$feature_cols),
    positive_class = .autoquant_catboost_selected_value(config$positive_class),
    id_cols = .autoquant_catboost_clean_choices(config$id_cols),
    DateVar = .autoquant_catboost_selected_value(config$DateVar %||% config$date_var),
    ByVars = .autoquant_catboost_clean_choices(config$ByVars %||% config$by_vars),
    train_fraction = as.numeric(config$train_fraction %||% 0.8),
    split_method = tolower(as.character(config$split_method %||% "random")),
    split_col = .autoquant_catboost_selected_value(config$split_col),
    seed = as.integer(config$seed %||% 123L),
    iterations = as.integer(config$iterations %||% 100L),
    depth = as.integer(config$depth %||% 6L),
    learning_rate = as.numeric(config$learning_rate %||% NA_real_),
    threshold = as.numeric(config$threshold %||% 0.5),
    compute_shap = isTRUE(config$compute_shap),
    include_plots = isTRUE(config$include_plots %||% TRUE),
    top_n = as.integer(config$top_n %||% 20L),
    data_name = config$data_name %||% "Uploaded Data"
  )
}

validate_catboost_builder_config <- function(data, config) {
  config <- normalize_catboost_builder_config(config)
  errors <- character()
  warnings <- character()

  if (!autoquant_catboost_builder_available()) {
    errors <- c(
      errors,
      "AutoQuant::generate_catboost_builder_artifacts() was not found. Install/update AutoQuant before running CatBoost Builder."
    )
  }

  if (is.null(data)) {
    errors <- c(errors, "Upload data before running CatBoost Builder.")
  } else {
    columns <- names(data)
    if (is.null(config$target_col)) {
      errors <- c(errors, "Select a target column.")
    } else if (!config$target_col %in% columns) {
      errors <- c(errors, paste("Target column was not found:", config$target_col))
    }

    if (!length(config$feature_cols)) {
      errors <- c(errors, "Select at least one feature column.")
    }
    missing_features <- setdiff(config$feature_cols, columns)
    if (length(missing_features)) {
      errors <- c(errors, paste("Feature columns were not found:", paste(missing_features, collapse = ", ")))
    }
    if (!is.null(config$target_col) && config$target_col %in% config$feature_cols) {
      errors <- c(errors, "Feature columns must not include the target column.")
    }

    context_cols <- unique(c(config$id_cols, config$DateVar, config$ByVars, config$split_col))
    context_cols <- context_cols[!is.na(context_cols) & nzchar(context_cols)]
    missing_context <- setdiff(context_cols, columns)
    if (length(missing_context)) {
      errors <- c(errors, paste("Selected context/split columns were not found:", paste(missing_context, collapse = ", ")))
    }

    if (identical(config$problem_type, "regression") &&
        !is.null(config$target_col) && config$target_col %in% columns &&
        !is.numeric(data[[config$target_col]])) {
      errors <- c(errors, "Regression CatBoost Builder requires a numeric target column.")
    }

    if (identical(config$problem_type, "binary")) {
      if (is.null(config$positive_class)) {
        errors <- c(errors, "positive_class is required for Binary Classification CatBoost Builder.")
      } else if (!is.null(config$target_col) && config$target_col %in% columns) {
        target_values <- unique(as.character(stats::na.omit(data[[config$target_col]])))
        if (length(target_values) != 2L) {
          errors <- c(errors, "Binary Classification CatBoost Builder requires a target with exactly two non-missing classes.")
        }
        if (length(target_values) && !as.character(config$positive_class) %in% target_values) {
          errors <- c(errors, paste("positive_class was not found in target_col:", config$positive_class))
        }
      }
    }
  }

  if (!config$split_method %in% c("random", "date", "column", "predefined")) {
    errors <- c(errors, "split_method must be one of: random, date, column, predefined.")
  }
  if (is.na(config$train_fraction) || config$train_fraction <= 0 || config$train_fraction >= 1) {
    errors <- c(errors, "train_fraction must be between 0 and 1.")
  }
  if (is.na(config$iterations) || config$iterations < 1L) {
    errors <- c(errors, "iterations must be a positive integer.")
  }
  if (is.na(config$depth) || config$depth < 1L) {
    errors <- c(errors, "depth must be a positive integer.")
  }
  if (!is.na(config$learning_rate) && config$learning_rate <= 0) {
    errors <- c(errors, "learning_rate must be positive when supplied.")
  }
  if (is.na(config$threshold) || config$threshold < 0 || config$threshold > 1) {
    errors <- c(errors, "threshold must be between 0 and 1.")
  }
  if (is.na(config$top_n) || config$top_n < 1L) {
    errors <- c(errors, "top_n must be a positive integer.")
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      value = config,
      errors = errors,
      warnings = warnings,
      metadata = list(
        error_code = if (autoquant_catboost_builder_available()) "MODULE_CONFIG_INVALID" else "MODULE_DEPENDENCY_MISSING",
        module_id = "autoquant_catboost_builder"
      )
    ))
  }

  service_result(
    status = if (length(warnings)) "warning" else "success",
    value = config,
    messages = "AutoQuant CatBoost Builder config is valid.",
    warnings = warnings,
    metadata = list(
      module_id = "autoquant_catboost_builder",
      problem_type = config$problem_type,
      n_rows = if (is.null(data)) NA_integer_ else nrow(data),
      n_cols = if (is.null(data)) NA_integer_ else ncol(data)
    )
  )
}

.autoquant_catboost_r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }
  deparse(value, width.cutoff = 500L)
}

.autoquant_catboost_vec_code <- function(value) {
  value <- .autoquant_catboost_clean_choices(value)
  if (!length(value)) {
    return("NULL")
  }
  paste0("c(", paste(vapply(value, .autoquant_catboost_r_string, character(1)), collapse = ", "), ")")
}

.autoquant_catboost_code <- function(config) {
  paste(
    "catboost_builder_result <- AutoQuant::generate_catboost_builder_artifacts(",
    "  data = data,",
    paste0("  problem_type = ", .autoquant_catboost_r_string(config$problem_type), ","),
    paste0("  target_col = ", .autoquant_catboost_r_string(config$target_col), ","),
    paste0("  feature_cols = ", .autoquant_catboost_vec_code(config$feature_cols), ","),
    paste0("  positive_class = ", .autoquant_catboost_r_string(config$positive_class), ","),
    paste0("  id_cols = ", .autoquant_catboost_vec_code(config$id_cols), ","),
    paste0("  DateVar = ", .autoquant_catboost_r_string(config$DateVar), ","),
    paste0("  ByVars = ", .autoquant_catboost_vec_code(config$ByVars), ","),
    paste0("  train_fraction = ", config$train_fraction, ","),
    paste0("  split_method = ", .autoquant_catboost_r_string(config$split_method), ","),
    paste0("  split_col = ", .autoquant_catboost_r_string(config$split_col), ","),
    paste0("  seed = ", config$seed, ","),
    paste0("  iterations = ", config$iterations, ","),
    paste0("  depth = ", config$depth, ","),
    paste0("  learning_rate = ", if (is.na(config$learning_rate)) "NULL" else config$learning_rate, ","),
    paste0("  threshold = ", config$threshold, ","),
    paste0("  compute_shap = ", if (isTRUE(config$compute_shap)) "TRUE" else "FALSE", ","),
    paste0("  include_plots = ", if (isTRUE(config$include_plots)) "TRUE" else "FALSE", ","),
    paste0("  top_n = ", config$top_n),
    ")",
    sep = "\n"
  )
}

.autoquant_catboost_call_args <- function(data, config) {
  generator <- get("generate_catboost_builder_artifacts", envir = asNamespace("AutoQuant"))
  allowed <- names(formals(generator))
  supports_dots <- "..." %in% allowed
  args <- list(
    data = data,
    problem_type = config$problem_type,
    target_col = config$target_col,
    feature_cols = config$feature_cols,
    positive_class = config$positive_class,
    id_cols = config$id_cols,
    DateVar = config$DateVar,
    ByVars = config$ByVars,
    train_fraction = config$train_fraction,
    split_method = config$split_method,
    split_col = config$split_col,
    seed = config$seed,
    iterations = config$iterations,
    depth = config$depth,
    learning_rate = if (is.na(config$learning_rate)) NULL else config$learning_rate,
    threshold = config$threshold,
    compute_shap = isTRUE(config$compute_shap),
    include_plots = isTRUE(config$include_plots),
    top_n = config$top_n
  )
  if (!supports_dots) {
    args <- args[names(args) %in% allowed]
  }
  args[!vapply(args, is.null, logical(1))]
}

.autoquant_catboost_slug <- function(value) {
  slug <- tolower(value %||% "artifact")
  slug <- gsub("[^a-z0-9]+", "_", slug)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) "artifact" else slug
}

.autoquant_catboost_label <- function(name, artifact_type = "Artifact") {
  clean <- gsub("^artifacts_?|^tables_?|^plots_?|^widgets_?|^texts_?|^narratives_?", "", name)
  clean <- gsub("([a-z])([A-Z])", "\\1 \\2", clean)
  clean <- gsub("[_.]+", " ", clean)
  clean <- trimws(gsub("\\s+", " ", clean))
  if (!nzchar(clean) || tolower(clean) %in% c("unnamed", "plot 1", "table 1", "artifact")) {
    return(paste("CatBoost Builder", tools::toTitleCase(artifact_type)))
  }
  label <- tools::toTitleCase(clean)
  label <- gsub("\\bShap\\b", "SHAP", label)
  label <- gsub("\\bQa\\b", "QA", label)
  label
}

.autoquant_catboost_section <- function(path, fallback = "CatBoost Builder Summary") {
  text <- tolower(paste(path, collapse = " "))
  if (grepl("handoff|downstream", text)) return("Downstream Handoff")
  if (grepl("score|scored|prediction|predict", text)) return("Scored Output")
  if (grepl("split|train|test|metric|residual|confusion|threshold|diagnostic|importance|parameter", text)) {
    return("Training Diagnostics")
  }
  if (grepl("summary|config|overview|model", text)) return("CatBoost Builder Summary")
  fallback
}

.autoquant_catboost_artifact_type <- function(value, declared_type = NULL) {
  declared_type <- tolower(as.character(declared_type %||% ""))
  if (declared_type %in% c("plot", "table", "text", "metric", "model_summary")) {
    return(declared_type)
  }
  if (data.table::is.data.table(value) || is.data.frame(value) || is.matrix(value)) return("table")
  if (inherits(value, "htmlwidget") || inherits(value, "shiny.tag") || inherits(value, "shiny.tag.list")) return("plot")
  if (is.character(value)) return("text")
  NULL
}

.autoquant_catboost_flatten <- function(x, path = character()) {
  if (is.null(x)) return(list())
  if (inherits(x, "aq_artifact")) return(stats::setNames(list(x), paste(path, collapse = "_")))
  if (inherits(x, "htmlwidget") || inherits(x, "shiny.tag") || inherits(x, "shiny.tag.list") ||
      data.table::is.data.table(x) || is.data.frame(x) || is.matrix(x) || is.character(x)) {
    return(stats::setNames(list(x), paste(path, collapse = "_")))
  }
  if (is.list(x) && !is.null(x$object)) {
    return(stats::setNames(list(x), paste(path, collapse = "_")))
  }
  if (!is.list(x)) return(list())
  item_names <- names(x)
  if (is.null(item_names)) item_names <- paste0("item_", seq_along(x))
  parts <- list()
  for (index in seq_along(x)) {
    parts <- c(parts, .autoquant_catboost_flatten(x[[index]], c(path, item_names[[index]])))
  }
  parts
}

.autoquant_catboost_extract_artifacts <- function(autoquant_result) {
  if (!is.null(autoquant_result$artifacts) && is.list(autoquant_result$artifacts)) {
    return(.autoquant_catboost_flatten(autoquant_result$artifacts, "artifacts"))
  }
  list()
}

normalize_autoquant_catboost_builder_artifacts <- function(
  autoquant_result,
  config,
  module_run_id = .autoquant_catboost_run_id(),
  generated_at = Sys.time()
) {
  raw_artifacts <- .autoquant_catboost_extract_artifacts(autoquant_result)
  artifacts <- list()
  used_ids <- character()
  order <- 1L

  for (raw_name in names(raw_artifacts)) {
    raw <- raw_artifacts[[raw_name]]
    if (inherits(raw, "aq_artifact")) {
      artifacts[[raw$artifact_id]] <- raw
      next
    }

    raw_object <- if (is.list(raw) && !data.table::is.data.table(raw) && "object" %in% names(raw)) raw$object else raw
    raw_artifact_name <- if (is.list(raw) && !data.table::is.data.table(raw)) raw$name %||% raw_name else raw_name
    raw_label <- if (is.list(raw) && !data.table::is.data.table(raw)) raw$label %||% raw$title %||% NULL else NULL
    raw_type <- if (is.list(raw) && !data.table::is.data.table(raw)) raw$type %||% raw$artifact_type %||% NULL else NULL
    raw_section <- if (is.list(raw) && !data.table::is.data.table(raw)) raw$section %||% raw$metadata$section %||% NULL else NULL
    raw_metadata <- if (is.list(raw) && !data.table::is.data.table(raw)) raw$metadata %||% list() else list()
    artifact_type <- .autoquant_catboost_artifact_type(raw_object, raw_type)
    if (is.null(artifact_type)) {
      next
    }

    base_id <- paste0("aq_catboost_", module_run_id, "_", .autoquant_catboost_slug(raw_artifact_name))
    artifact_id <- base_id
    suffix <- 2L
    while (artifact_id %in% used_ids) {
      artifact_id <- paste0(base_id, "_", suffix)
      suffix <- suffix + 1L
    }
    used_ids <- c(used_ids, artifact_id)

    label <- raw_label %||% .autoquant_catboost_label(raw_artifact_name, artifact_type)
    section <- raw_section %||% .autoquant_catboost_section(c(raw_name, label))
    object <- NULL
    content <- NULL
    if (identical(artifact_type, "table")) {
      object <- data.table::as.data.table(raw_object)
    } else if (identical(artifact_type, "text")) {
      content <- if (is.character(raw_object)) paste(raw_object, collapse = "\n\n") else paste(utils::capture.output(str(raw_object)), collapse = "\n")
    } else {
      object <- raw_object
    }

    artifacts[[artifact_id]] <- create_artifact(
      artifact_id = artifact_id,
      artifact_type = artifact_type,
      label = label,
      source_module = "autoquant_catboost_builder",
      object = object,
      content = content,
      config = config,
      code = .autoquant_catboost_code(config),
      metadata = module_artifact_metadata(
        module_id = "autoquant_catboost_builder",
        module_run_id = module_run_id,
        source_module = "autoquant_catboost_builder",
        original_name = raw_artifact_name,
        original_section = raw_section %||% section,
        normalized_section = section,
        artifact_index = order,
        generated_at = generated_at,
        extra = list(
          problem_type = config$problem_type,
          target_col = config$target_col,
          feature_cols = config$feature_cols,
          positive_class = config$positive_class,
          threshold = config$threshold,
          source_package = "AutoQuant",
          source_function = "generate_catboost_builder_artifacts",
          autoquant_metadata = raw_metadata
        )
      ),
      section = section,
      order = order,
      status = "ready"
    )
    order <- order + 1L
  }

  artifacts
}

.autoquant_catboost_plan_sections <- function() {
  c("CatBoost Builder Summary", "Training Diagnostics", "Scored Output", "Downstream Handoff")
}

.autoquant_catboost_create_plan <- function(summary, plan_type, module_run_id, config) {
  plan_specs <- list(
    summary = list(label = "CatBoost Builder Summary", sections = c("CatBoost Builder Summary", "Training Diagnostics")),
    diagnostics = list(label = "Training Diagnostics", sections = "Training Diagnostics"),
    scored_output = list(label = "Scored Output", sections = "Scored Output"),
    handoff = list(label = "Downstream Handoff", sections = "Downstream Handoff")
  )
  spec <- plan_specs[[plan_type]]
  selected <- summary[section %in% spec$sections]
  if (!nrow(selected)) return(NULL)

  sections <- list()
  for (section_title in .autoquant_catboost_plan_sections()) {
    rows <- selected[section == section_title][order(order, artifact_id)]
    if (!nrow(rows)) next
    section_id <- .autoquant_catboost_slug(section_title)
    sections[[section_id]] <- create_report_plan_section(
      section_id = section_id,
      title = section_title,
      artifact_ids = rows$artifact_id,
      order = length(sections) + 1L
    )
  }
  artifact_ids <- unlist(lapply(sections, function(section) section$artifact_ids), use.names = FALSE)

  create_report_plan(
    plan_id = paste(module_run_id, plan_type, sep = "_"),
    label = spec$label,
    source_module = "autoquant_catboost_builder",
    description = paste(spec$label, "generated from AutoQuant CatBoost Builder artifacts."),
    layout_type = "sections",
    cols = 2L,
    sections = sections,
    artifact_ids = artifact_ids,
    rationale = "CatBoost Builder report plan references normalized artifact IDs only.",
    metadata = list(
      module_id = "autoquant_catboost_builder",
      module_run_id = module_run_id,
      plan_type = plan_type,
      problem_type = config$problem_type
    ),
    status = "recommended"
  )
}

create_catboost_builder_report_plans <- function(artifacts, config = list(), module_run_id = NULL) {
  if (is.null(artifacts) || !length(artifacts)) return(list())
  module_run_id <- module_run_id %||% .autoquant_catboost_run_id()
  summary <- artifact_summary(artifacts)
  plans <- list(
    summary = .autoquant_catboost_create_plan(summary, "summary", module_run_id, config),
    diagnostics = .autoquant_catboost_create_plan(summary, "diagnostics", module_run_id, config),
    scored_output = .autoquant_catboost_create_plan(summary, "scored_output", module_run_id, config),
    handoff = .autoquant_catboost_create_plan(summary, "handoff", module_run_id, config)
  )
  plans <- Filter(Negate(is.null), plans)
  stats::setNames(plans, vapply(plans, function(plan) plan$plan_id, character(1)))
}

.autoquant_catboost_scored_data <- function(result) {
  result$scored_data %||% result$value$scored_data %||% result$metadata$scored_data %||% NULL
}

.autoquant_catboost_downstream_handoff <- function(result, config) {
  handoff <- result$downstream_handoff %||% result$metadata$downstream_handoff %||% list()
  defaults <- list(
    problem_type = config$problem_type,
    target_col = config$target_col,
    prediction_col = "Predict",
    predicted_class_col = if (identical(config$problem_type, "binary")) "PredictedClass" else NULL,
    positive_class = config$positive_class,
    threshold = config$threshold,
    DateVar = config$DateVar,
    ByVars = config$ByVars,
    id_cols = config$id_cols,
    shap_prefix = "Shap_",
    feature_cols = config$feature_cols
  )
  for (name in names(defaults)) {
    handoff[[name]] <- handoff[[name]] %||% defaults[[name]]
  }
  handoff
}

create_catboost_handoff <- function(
  source_run_id,
  scored_data,
  downstream_handoff = list(),
  config = list()
) {
  scored_data <- if (is.null(scored_data)) NULL else data.table::as.data.table(data.table::copy(scored_data))
  scored_cols <- if (is.null(scored_data)) character() else names(scored_data)
  problem_type <- .autoquant_catboost_problem_type(
    downstream_handoff$problem_type %||% config$problem_type %||% "regression"
  )
  shap_prefix <- downstream_handoff$shap_prefix %||% "Shap_"
  shap_cols <- scored_cols[startsWith(scored_cols, shap_prefix)]
  target_col <- downstream_handoff$target_col %||% config$target_col
  feature_cols <- .autoquant_catboost_clean_choices(downstream_handoff$feature_cols %||% config$feature_cols)
  id_cols <- .autoquant_catboost_clean_choices(downstream_handoff$id_cols %||% config$id_cols)
  DateVar <- downstream_handoff$DateVar %||% config$DateVar
  ByVars <- .autoquant_catboost_clean_choices(downstream_handoff$ByVars %||% config$ByVars)

  handoff <- list(
    source_module = "autoquant_catboost_builder",
    source_run_id = source_run_id,
    problem_type = problem_type,
    scored_data = scored_data,
    scored_data_summary = data.table::data.table(
      rows = if (is.null(scored_data)) 0L else nrow(scored_data),
      cols = if (is.null(scored_data)) 0L else ncol(scored_data),
      has_predict = "Predict" %in% scored_cols,
      has_predicted_class = "PredictedClass" %in% scored_cols,
      has_residual = "residual" %in% scored_cols,
      shap_cols = length(shap_cols)
    ),
    target_col = target_col,
    prediction_col = downstream_handoff$prediction_col %||% "Predict",
    predicted_class_col = downstream_handoff$predicted_class_col %||%
      if (identical(problem_type, "binary")) "PredictedClass" else NULL,
    positive_class = downstream_handoff$positive_class %||% config$positive_class,
    threshold = as.numeric(downstream_handoff$threshold %||% config$threshold %||% 0.5),
    feature_cols = feature_cols,
    id_cols = id_cols,
    DateVar = DateVar,
    ByVars = ByVars,
    shap_prefix = shap_prefix,
    shap_cols = shap_cols,
    available_downstream_modules = character(),
    recommended_configs = list()
  )

  configs <- create_catboost_downstream_configs(handoff)
  validation <- validate_catboost_handoff(handoff)
  handoff$available_downstream_modules <- validation$metadata$available_downstream_modules %||% character()
  handoff$recommended_configs <- configs[names(configs) %in% handoff$available_downstream_modules]
  handoff$validation <- validation
  handoff
}

.catboost_downstream_module_label <- function(module_id) {
  labels <- c(
    model_assessment = "Model Assessment",
    autoquant_regression_model_insights = "Regression Model Insights",
    autoquant_binary_model_insights = "Binary Classification Model Insights",
    autoquant_regression_shap_analysis = "Regression SHAP Analysis",
    autoquant_binary_shap_analysis = "Binary Classification SHAP Analysis"
  )
  labels[[module_id]] %||% module_id
}

create_catboost_downstream_configs <- function(handoff) {
  problem_type <- .autoquant_catboost_problem_type(handoff$problem_type)
  common_assessment <- list(
    assessment_problem_type = if (identical(problem_type, "binary")) "Binary Classification" else "Regression",
    actual_var = handoff$target_col,
    prediction_var = handoff$prediction_col %||% "Predict",
    predicted_class_var = if (identical(problem_type, "binary")) handoff$predicted_class_col %||% "PredictedClass" else NULL,
    positive_class = handoff$positive_class,
    date_var = handoff$DateVar,
    group_var = (handoff$ByVars %||% character())[1L] %||% NULL,
    model_name = "CatBoost Builder Output",
    artifact_section = "Model Assessment",
    theme = "light",
    max_rows = 100000L,
    max_groups = 25L,
    handoff_source_run_id = handoff$source_run_id
  )

  configs <- list(model_assessment = common_assessment)

  if (identical(problem_type, "regression")) {
    configs$autoquant_regression_model_insights <- list(
      target_column = handoff$target_col,
      prediction_column = handoff$prediction_col %||% "Predict",
      feature_columns = handoff$feature_cols,
      segment_vars = handoff$ByVars,
      by_vars = handoff$ByVars,
      date_var = handoff$DateVar,
      algo = "catboost_builder",
      theme = "light",
      sample_size = 100000L,
      max_pdp_features = 10L,
      generate_calibration_pdp = FALSE,
      generate_uplift_pdp = FALSE,
      generate_stratified_effects = FALSE,
      detect_simpsons_paradox = FALSE,
      handoff_source_run_id = handoff$source_run_id
    )
    configs$autoquant_regression_shap_analysis <- create_shap_analysis_config(
      problem_type = "regression",
      data_name = "CatBoost Builder Scored Output",
      target_col = handoff$target_col,
      prediction_col = handoff$prediction_col %||% "Predict",
      feature_cols = handoff$feature_cols,
      shap_prefix = handoff$shap_prefix %||% "Shap_",
      id_cols = handoff$id_cols,
      prediction_scale = "response",
      DateVar = handoff$DateVar,
      date_aggregation = "month",
      ByVars = handoff$ByVars,
      selected_features = handoff$feature_cols,
      local_row_ids = 1L,
      include_dependence = TRUE,
      include_segments = TRUE,
      include_time = TRUE,
      include_local = FALSE,
      include_interactions = TRUE,
      include_plots = TRUE,
      max_feature_effect_plots = 5L,
      max_dependence_plots = 5L,
      max_segment_plots = 5L,
      max_time_plots = 5L,
      max_local_plots = 5L
    )
    configs$autoquant_regression_shap_analysis$handoff_source_run_id <- handoff$source_run_id
  } else {
    configs$autoquant_binary_model_insights <- list(
      train_data_include = FALSE,
      feature_columns = handoff$feature_cols,
      sample_size = 100000L,
      model_id = "CatBoost Builder Output",
      source_path = NULL,
      prediction_column = handoff$prediction_col %||% "Predict",
      target_column = handoff$target_col,
      positive_class = handoff$positive_class,
      threshold = as.numeric(handoff$threshold %||% 0.5),
      optimize_metric = "Utility",
      utility_tp = 1,
      utility_tn = 0,
      utility_fp = -1,
      utility_fn = -5,
      beta = 1,
      theme = "light",
      handoff_source_run_id = handoff$source_run_id
    )
    configs$autoquant_binary_shap_analysis <- create_shap_analysis_config(
      problem_type = "binary_classification",
      data_name = "CatBoost Builder Scored Output",
      target_col = handoff$target_col,
      prediction_col = handoff$prediction_col %||% "Predict",
      predicted_class_col = handoff$predicted_class_col %||% "PredictedClass",
      positive_class = handoff$positive_class,
      prediction_scale = "probability",
      threshold = as.numeric(handoff$threshold %||% 0.5),
      feature_cols = handoff$feature_cols,
      shap_prefix = handoff$shap_prefix %||% "Shap_",
      id_cols = handoff$id_cols,
      DateVar = handoff$DateVar,
      date_aggregation = "month",
      ByVars = handoff$ByVars,
      selected_features = handoff$feature_cols,
      local_row_ids = 1L,
      include_threshold_context = TRUE,
      include_class_balance = TRUE,
      include_dependence = TRUE,
      include_segments = TRUE,
      include_time = TRUE,
      include_local = FALSE,
      include_interactions = TRUE,
      include_plots = TRUE,
      max_feature_effect_plots = 5L,
      max_dependence_plots = 5L,
      max_segment_plots = 5L,
      max_time_plots = 5L,
      max_local_plots = 5L
    )
    configs$autoquant_binary_shap_analysis$handoff_source_run_id <- handoff$source_run_id
  }

  configs
}

validate_catboost_handoff <- function(handoff) {
  errors <- character()
  warnings <- character()
  available <- character()
  scored_data <- handoff$scored_data
  cols <- if (is.null(scored_data)) character() else names(scored_data)
  problem_type <- .autoquant_catboost_problem_type(handoff$problem_type)
  prediction_col <- handoff$prediction_col %||% "Predict"
  predicted_class_col <- handoff$predicted_class_col %||% "PredictedClass"
  shap_cols <- cols[startsWith(cols, handoff$shap_prefix %||% "Shap_")]

  if (is.null(scored_data) || !nrow(scored_data)) {
    errors <- c(errors, "CatBoost handoff requires non-empty scored_data.")
  }
  if (!prediction_col %in% cols) {
    errors <- c(errors, paste("CatBoost handoff scored_data must include prediction_col:", prediction_col))
  }
  if (is.null(handoff$target_col) || !handoff$target_col %in% cols) {
    errors <- c(errors, "CatBoost handoff target_col must exist in scored_data.")
  }
  if (identical(problem_type, "regression") && !"residual" %in% cols) {
    warnings <- c(warnings, "Regression handoff scored_data does not include residual; Model Assessment can still run.")
  }
  if (identical(problem_type, "binary")) {
    if (!predicted_class_col %in% cols) {
      errors <- c(errors, paste("Binary CatBoost handoff scored_data must include predicted_class_col:", predicted_class_col))
    }
    if (is.null(handoff$positive_class) || !nzchar(as.character(handoff$positive_class))) {
      errors <- c(errors, "Binary CatBoost handoff requires positive_class.")
    }
  }

  missing_features <- setdiff(handoff$feature_cols %||% character(), cols)
  if (length(missing_features)) {
    errors <- c(errors, paste("CatBoost handoff feature_cols missing from scored_data:", paste(missing_features, collapse = ", ")))
  }
  context_cols <- unique(c(handoff$id_cols, handoff$DateVar, handoff$ByVars))
  context_cols <- context_cols[!is.na(context_cols) & nzchar(context_cols)]
  missing_context <- setdiff(context_cols, cols)
  if (length(missing_context)) {
    warnings <- c(warnings, paste("CatBoost handoff context columns missing and will be ignored:", paste(missing_context, collapse = ", ")))
  }

  if (!length(errors)) {
    available <- c(available, "model_assessment")
  }
  if (identical(problem_type, "regression") && !length(errors)) {
    if (autoquant_regression_model_insights_available()) {
      available <- c(available, "autoquant_regression_model_insights")
    }
    if (length(shap_cols) && autoquant_regression_shap_analysis_available()) {
      available <- c(available, "autoquant_regression_shap_analysis")
    } else if (!length(shap_cols)) {
      warnings <- c(warnings, "Regression SHAP handoff is unavailable because scored_data has no Shap_ columns.")
    }
  }
  if (identical(problem_type, "binary") && !length(errors)) {
    if (autoquant_binary_model_insights_available()) {
      available <- c(available, "autoquant_binary_model_insights")
    }
    if (length(shap_cols) && autoquant_binary_shap_analysis_available()) {
      available <- c(available, "autoquant_binary_shap_analysis")
    } else if (!length(shap_cols)) {
      warnings <- c(warnings, "Binary SHAP handoff is unavailable because scored_data has no Shap_ columns.")
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      value = handoff,
      errors = errors,
      warnings = warnings,
      metadata = list(
        error_code = "CATBOOST_HANDOFF_INVALID",
        available_downstream_modules = character()
      )
    ))
  }

  service_result(
    status = if (length(warnings)) "warning" else "success",
    value = handoff,
    messages = "CatBoost handoff is valid.",
    warnings = warnings,
    metadata = list(
      available_downstream_modules = unique(available),
      shap_cols = shap_cols
    )
  )
}

run_catboost_downstream_handoff <- function(handoff, downstream_module_id) {
  validation <- validate_catboost_handoff(handoff)
  if (identical(validation$status, "error")) {
    return(validation)
  }
  available <- validation$metadata$available_downstream_modules %||% character()
  if (!downstream_module_id %in% available) {
    return(service_result(
      status = "error",
      errors = paste("Downstream module is not available for this CatBoost handoff:", downstream_module_id),
      metadata = list(
        error_code = "CATBOOST_HANDOFF_ACTION_UNAVAILABLE",
        module_id = downstream_module_id,
        available_downstream_modules = available
      )
    ))
  }
  config <- handoff$recommended_configs[[downstream_module_id]]
  if (is.null(config)) {
    config <- create_catboost_downstream_configs(handoff)[[downstream_module_id]]
  }

  result <- run_analysis_module(
    module_id = downstream_module_id,
    data = handoff$scored_data,
    config = config
  )
  result$metadata$handoff_source_module <- handoff$source_module
  result$metadata$handoff_source_run_id <- handoff$source_run_id
  result$metadata$handoff_problem_type <- handoff$problem_type
  result$metadata$handoff_downstream_module <- downstream_module_id
  if (length(result$artifacts)) {
    for (artifact_id in names(result$artifacts)) {
      result$artifacts[[artifact_id]]$metadata$handoff_source_module <- handoff$source_module
      result$artifacts[[artifact_id]]$metadata$handoff_source_run_id <- handoff$source_run_id
      result$artifacts[[artifact_id]]$metadata$handoff_downstream_module <- downstream_module_id
    }
  }
  if (length(result$metadata$report_plans %||% list())) {
    for (plan_id in names(result$metadata$report_plans)) {
      result$metadata$report_plans[[plan_id]]$metadata$handoff_source_module <- handoff$source_module
      result$metadata$report_plans[[plan_id]]$metadata$handoff_source_run_id <- handoff$source_run_id
      result$metadata$report_plans[[plan_id]]$metadata$handoff_downstream_module <- downstream_module_id
    }
  }
  result
}

run_autoquant_catboost_builder <- function(data, config) {
  validation <- validate_catboost_builder_config(data, config)
  if (identical(validation$status, "error")) {
    validation$code <- .autoquant_catboost_code(normalize_catboost_builder_config(config))
    return(validation)
  }

  generated_at <- Sys.time()
  module_run_id <- .autoquant_catboost_run_id(generated_at)
  config <- validation$value
  result <- tryCatch(
    do.call(
      get("generate_catboost_builder_artifacts", envir = asNamespace("AutoQuant")),
      .autoquant_catboost_call_args(data, config)
    ),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant CatBoost Builder failed:", conditionMessage(e)),
        diagnostics = list(condition = e),
        metadata = list(
          error_code = "AUTOQUANT_CATBOOST_BUILDER_FAILED",
          module_id = "autoquant_catboost_builder",
          module_run_id = module_run_id,
          generated_at = generated_at
        ),
        code = .autoquant_catboost_code(config)
      )
    }
  )
  if (is.list(result) && identical(result$status, "error")) {
    return(service_result(
      status = "error",
      value = result,
      errors = result$error %||% result$errors %||% "AutoQuant CatBoost Builder returned an error result.",
      diagnostics = result$diagnostics %||% list(),
      metadata = list(
        error_code = "AUTOQUANT_CATBOOST_BUILDER_FAILED",
        module_id = "autoquant_catboost_builder",
        module_run_id = module_run_id,
        generated_at = generated_at,
        source_package = "AutoQuant",
        source_function = "generate_catboost_builder_artifacts",
        autoquant_metadata = result$metadata %||% list()
      ),
      code = .autoquant_catboost_code(config)
    ))
  }

  artifacts <- normalize_autoquant_catboost_builder_artifacts(result, config, module_run_id, generated_at)
  plans <- create_catboost_builder_report_plans(artifacts, config, module_run_id)
  scored_data <- .autoquant_catboost_scored_data(result)
  downstream_handoff <- .autoquant_catboost_downstream_handoff(result, config)
  catboost_handoff <- create_catboost_handoff(
    source_run_id = module_run_id,
    scored_data = scored_data,
    downstream_handoff = downstream_handoff,
    config = config
  )
  scored_cols <- if (is.null(scored_data)) character() else names(scored_data)
  counts <- module_artifact_counts(artifacts)

  service_result(
    status = if (length(artifacts)) "success" else "warning",
    value = result,
    artifacts = artifacts,
    messages = sprintf(
      "Generated %s CatBoost Builder artifacts: %s plots, %s tables, %s text blocks. Created %s report plan(s).",
      counts$artifact_count,
      counts$plot_count,
      counts$table_count,
      counts$text_count,
      length(plans)
    ),
    warnings = c(validation$warnings %||% character(), result$warnings %||% character()),
    metadata = module_run_metadata(
      module_id = "autoquant_catboost_builder",
      module_run_id = module_run_id,
      generated_at = result$metadata$generated_at %||% generated_at,
      data_name = config$data_name,
      source_package = "AutoQuant",
      source_function = "generate_catboost_builder_artifacts",
      configured_inputs = config,
      artifacts = artifacts,
      report_plans = plans,
      extra = list(
        problem_type = config$problem_type,
        scored_output_available = !is.null(scored_data),
        scored_output_rows = if (is.null(scored_data)) 0L else nrow(scored_data),
        scored_output_cols = if (is.null(scored_data)) 0L else ncol(scored_data),
        scored_output_has_predict = "Predict" %in% scored_cols,
        scored_output_has_shap = any(startsWith(scored_cols, "Shap_")),
        downstream_handoff = downstream_handoff,
        catboost_handoff = catboost_handoff,
        available_downstream_modules = catboost_handoff$available_downstream_modules,
        recommended_downstream_configs = catboost_handoff$recommended_configs,
        autoquant_metadata = result$metadata %||% list()
      )
    ),
    code = result$code %||% .autoquant_catboost_code(config)
  )
}

run_autoquant_catboost_builder_module <- function(data, config) {
  run_autoquant_catboost_builder(data = data, config = config)
}

qa_autoquant_catboost_builder_integration <- function() {
  if (!autoquant_catboost_builder_available()) {
    return(data.table::data.table(
      check = "generator_available",
      status = "warning",
      message = "AutoQuant::generate_catboost_builder_artifacts() is not available in the installed AutoQuant namespace."
    ))
  }

  set.seed(501)
  n <- 120L
  regression_data <- data.table::data.table(
    id = seq_len(n),
    Date = as.Date("2026-01-01") + seq_len(n),
    Channel = sample(c("Email", "Search", "Social"), n, TRUE),
    Spend = stats::runif(n, 10, 100),
    Clicks = stats::rpois(n, 40),
    DiscountRate = stats::runif(n, 0, 0.25)
  )
  regression_data[, Revenue := 15 + 1.8 * Spend + 0.4 * Clicks - 20 * DiscountRate + stats::rnorm(n, 0, 5)]

  binary_data <- data.table::copy(regression_data)
  binary_data[, Target := ifelse(Revenue > stats::median(Revenue), "Yes", "No")]

  regression_result <- run_autoquant_catboost_builder(
    regression_data,
    list(
      problem_type = "regression",
      target_col = "Revenue",
      feature_cols = c("Spend", "Clicks", "DiscountRate", "Channel"),
      id_cols = "id",
      DateVar = "Date",
      ByVars = "Channel",
      iterations = 20L,
      depth = 4L,
      compute_shap = TRUE,
      include_plots = TRUE,
      top_n = 5L
    )
  )
  binary_result <- run_autoquant_catboost_builder(
    binary_data,
    list(
      problem_type = "binary",
      target_col = "Target",
      positive_class = "Yes",
      feature_cols = c("Spend", "Clicks", "DiscountRate", "Channel"),
      id_cols = "id",
      DateVar = "Date",
      ByVars = "Channel",
      iterations = 20L,
      depth = 4L,
      threshold = 0.5,
      compute_shap = TRUE,
      include_plots = TRUE,
      top_n = 5L
    )
  )

  qa_rows <- function(result, prefix, expected_problem_type) {
    if (identical(result$status, "error")) {
      return(data.table::data.table(
        check = paste0(prefix, "_generator_run"),
        status = "warning",
        message = paste(
          "AutoQuant CatBoost Builder returned an upstream error during",
          prefix,
          "QA; the app adapter preserved the failure as a service_result:",
          service_result_message(result)
        )
      ))
    }

    scored_data <- .autoquant_catboost_scored_data(result$value %||% list())
    scored_cols <- if (is.null(scored_data)) character() else names(scored_data)
    artifacts <- result$artifacts %||% list()
    plans <- result$metadata$report_plans %||% list()
    summary <- artifact_summary(artifacts)
    plan_summary <- report_plan_summary(plans)
    data.table::data.table(
      check = paste0(prefix, "_", c(
        "service_result",
        "artifacts",
        "artifact_summary",
        "report_plans",
        "scored_data",
        "predict_col",
        "residual_or_class_col",
        "downstream_handoff"
      )),
      status = c(
        result$status,
        if (length(artifacts)) "success" else "error",
        if (nrow(summary)) "success" else "error",
        if (nrow(plan_summary)) "success" else "error",
        if (!is.null(scored_data) && nrow(scored_data)) "success" else "error",
        if ("Predict" %in% scored_cols) "success" else "error",
        if ((identical(expected_problem_type, "regression") && "residual" %in% scored_cols) ||
            (identical(expected_problem_type, "binary") && "PredictedClass" %in% scored_cols)) "success" else "error",
        if (identical(result$metadata$downstream_handoff$problem_type, expected_problem_type)) "success" else "error"
      ),
      message = c(
        service_result_message(result),
        paste("Artifacts:", length(artifacts)),
        paste("Artifact rows:", nrow(summary)),
        paste("Report plans:", nrow(plan_summary)),
        paste("Scored rows:", if (is.null(scored_data)) 0L else nrow(scored_data)),
        "Predict column is preserved in scored output.",
        if (identical(expected_problem_type, "regression")) "Regression residual column is preserved." else "Binary PredictedClass column is preserved.",
        "Downstream handoff metadata is preserved."
      )
    )
  }

  data.table::rbindlist(list(
    qa_rows(regression_result, "regression", "regression"),
    qa_rows(binary_result, "binary", "binary")
  ), use.names = TRUE, fill = TRUE)
}

.qa_catboost_handoff_fixture <- function(problem_type = c("regression", "binary")) {
  problem_type <- match.arg(problem_type)
  set.seed(if (identical(problem_type, "regression")) 711L else 712L)
  n <- 140L
  data <- data.table::data.table(
    id = seq_len(n),
    Date = as.Date("2026-01-01") + seq_len(n),
    Channel = sample(c("Email", "Search", "Social"), n, TRUE),
    Region = sample(c("West", "South", "Midwest"), n, TRUE),
    Spend = stats::runif(n, 20, 200),
    Clicks = stats::rpois(n, 55),
    DiscountRate = stats::runif(n, 0, 0.3)
  )
  data[, Revenue := 20 + 1.5 * Spend + 0.35 * Clicks - 25 * DiscountRate +
    ifelse(Channel == "Search", 18, ifelse(Channel == "Email", 8, -4)) +
    stats::rnorm(n, 0, 8)]

  if (identical(problem_type, "binary")) {
    data[, Target := ifelse(Revenue > stats::median(Revenue), "Yes", "No")]
    config <- list(
      problem_type = "binary",
      target_col = "Target",
      positive_class = "Yes",
      feature_cols = c("Spend", "Clicks", "DiscountRate", "Channel", "Region"),
      id_cols = "id",
      DateVar = "Date",
      ByVars = c("Channel", "Region"),
      iterations = 15L,
      depth = 4L,
      threshold = 0.5,
      compute_shap = TRUE,
      include_plots = FALSE,
      top_n = 5L,
      data_name = "CatBoost Binary Handoff QA"
    )
  } else {
    config <- list(
      problem_type = "regression",
      target_col = "Revenue",
      feature_cols = c("Spend", "Clicks", "DiscountRate", "Channel", "Region"),
      id_cols = "id",
      DateVar = "Date",
      ByVars = c("Channel", "Region"),
      iterations = 15L,
      depth = 4L,
      compute_shap = TRUE,
      include_plots = FALSE,
      top_n = 5L,
      data_name = "CatBoost Regression Handoff QA"
    )
  }

  list(data = data, config = config)
}

.qa_catboost_downstream_rows <- function(builder_result, problem_type) {
  prefix <- if (identical(problem_type, "binary")) "binary" else "regression"
  if (identical(builder_result$status, "error")) {
    return(data.table::data.table(
      check = paste0(prefix, "_builder_result"),
      status = "warning",
      message = paste(
        "CatBoost Builder did not produce a handoff during QA:",
        service_result_message(builder_result)
      )
    ))
  }

  handoff <- builder_result$metadata$catboost_handoff
  validation <- validate_catboost_handoff(handoff)
  configs <- create_catboost_downstream_configs(handoff)
  available <- validation$metadata$available_downstream_modules %||% character()
  desired <- c(
    "model_assessment",
    if (identical(problem_type, "binary")) "autoquant_binary_model_insights" else "autoquant_regression_model_insights",
    if (identical(problem_type, "binary")) "autoquant_binary_shap_analysis" else "autoquant_regression_shap_analysis"
  )
  runnable <- intersect(desired, available)
  run_results <- lapply(runnable, function(module_id) {
    run_catboost_downstream_handoff(handoff, module_id)
  })
  names(run_results) <- runnable

  artifact_ids <- unlist(lapply(run_results, function(result) names(result$artifacts %||% list())), use.names = FALSE)
  plan_ids <- unlist(lapply(run_results, function(result) names(result$metadata$report_plans %||% list())), use.names = FALSE)
  handoff_sources <- unlist(lapply(run_results, function(result) {
    vapply(result$artifacts %||% list(), function(artifact) {
      artifact$metadata$handoff_source_run_id %||% ""
    }, character(1))
  }), use.names = FALSE)
  module_messages <- vapply(run_results, service_result_message, character(1))
  module_statuses <- vapply(run_results, function(result) result$status %||% "missing", character(1))
  modules_with_artifacts <- vapply(run_results, function(result) length(result$artifacts %||% list()) > 0L, logical(1))
  modules_with_plans <- vapply(run_results, function(result) length(result$metadata$report_plans %||% list()) > 0L, logical(1))

  data.table::rbindlist(list(
    data.table::data.table(
      check = paste0(prefix, "_", c(
        "handoff_exists",
        "handoff_validation",
        "recommended_configs",
        "available_modules",
        "builder_did_not_auto_run_downstream",
        "downstream_artifact_ids_unique",
        "downstream_plan_ids_unique",
        "handoff_source_run_id_preserved"
      )),
      status = c(
        if (!is.null(handoff)) "success" else "error",
        validation$status,
        if (all(desired %in% names(configs))) "success" else "error",
        if (length(runnable) >= 2L) "success" else "warning",
        if (is.null(builder_result$metadata$downstream_run_results)) "success" else "error",
        if (!length(artifact_ids) || length(unique(artifact_ids)) == length(artifact_ids)) "success" else "error",
        if (!length(plan_ids) || length(unique(plan_ids)) == length(plan_ids)) "success" else "error",
        if (length(handoff_sources) && all(handoff_sources == handoff$source_run_id)) "success" else "error"
      ),
      message = c(
        paste("Handoff source run:", handoff$source_run_id %||% "missing"),
        service_result_message(validation),
        paste("Configs:", paste(names(configs), collapse = ", ")),
        paste("Runnable modules:", paste(runnable, collapse = ", ")),
        "Builder QA result contains no downstream run payload.",
        paste("Artifact IDs:", length(artifact_ids)),
        paste("Report plan IDs:", length(plan_ids)),
        "Downstream artifacts preserve handoff source run id."
      )
    ),
    if (length(run_results)) {
      data.table::data.table(
        check = paste0(prefix, "_run_", names(run_results)),
        status = ifelse(module_statuses == "success" & modules_with_artifacts & modules_with_plans, "success", module_statuses),
        message = paste0(
          names(run_results),
          ": ",
          module_messages,
          " | artifacts=",
          vapply(run_results, function(result) length(result$artifacts %||% list()), integer(1)),
          " | plans=",
          vapply(run_results, function(result) length(result$metadata$report_plans %||% list()), integer(1))
        )
      )
    } else {
      data.table::data.table(
        check = paste0(prefix, "_downstream_runs"),
        status = "warning",
        message = "No downstream modules were available for this CatBoost handoff."
      )
    }
  ), use.names = TRUE, fill = TRUE)
}

qa_catboost_downstream_handoff <- function() {
  if (!autoquant_catboost_builder_available()) {
    return(data.table::data.table(
      check = "catboost_builder_available",
      status = "warning",
      message = "AutoQuant::generate_catboost_builder_artifacts() is not available."
    ))
  }

  regression_fixture <- .qa_catboost_handoff_fixture("regression")
  binary_fixture <- .qa_catboost_handoff_fixture("binary")
  regression_builder <- run_autoquant_catboost_builder(regression_fixture$data, regression_fixture$config)
  binary_builder <- run_autoquant_catboost_builder(binary_fixture$data, binary_fixture$config)

  data.table::rbindlist(list(
    .qa_catboost_downstream_rows(regression_builder, "regression"),
    .qa_catboost_downstream_rows(binary_builder, "binary")
  ), use.names = TRUE, fill = TRUE)
}
