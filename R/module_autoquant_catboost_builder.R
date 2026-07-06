autoquant_catboost_builder_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_catboost_builder_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

.autoquant_catboost_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_catboost_builder_", format(timestamp, "%Y%m%d%H%M%S"))
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
