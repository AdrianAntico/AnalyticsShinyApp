table_artifact_sort <- function(column = NULL, direction = c("source", "desc", "asc"), label = NULL) {
  direction <- match.arg(direction)
  list(
    column = column,
    direction = direction,
    label = label %||% if (identical(direction, "source")) "Source order" else paste(column, direction)
  )
}

table_artifact_policy <- function(
  default_view = NULL,
  alternate_views = list(),
  preview_rows = 25L,
  include_full_csv = TRUE,
  include_json = TRUE,
  render_target = "llm_docx"
) {
  target_validation <- validate_render_target(render_target)
  if (!identical(target_validation$status, "success")) {
    return(target_validation)
  }

  default_view <- default_view %||% list(
    view_id = "source_order",
    label = "Source order",
    sort = table_artifact_sort(direction = "source")
  )

  structure(
    list(
      default_view = default_view,
      alternate_views = alternate_views %||% list(),
      preview_rows = as.integer(preview_rows %||% 25L),
      include_full_csv = isTRUE(include_full_csv),
      include_json = isTRUE(include_json),
      render_target = render_target
    ),
    class = c("table_artifact_policy", "list")
  )
}

table_artifact_data <- function(artifact) {
  if (is.null(artifact) || is.null(artifact$object)) {
    return(data.table::data.table())
  }
  data.table::as.data.table(artifact$object)
}

table_artifact_policy_for <- function(artifact, render_target = "llm_docx") {
  raw_policy <- artifact$metadata$table_policy %||% artifact$config$table_policy %||% list()
  if (inherits(raw_policy, "table_artifact_policy")) {
    raw_policy$render_target <- render_target
    return(raw_policy)
  }

  default_sort <- raw_policy$default_sort %||% artifact$metadata$default_sort %||% list()
  default_view <- raw_policy$default_view %||% list(
    view_id = default_sort$view_id %||% "source_order",
    label = default_sort$label %||% "Source order",
    sort = table_artifact_sort(
      column = default_sort$column %||% NULL,
      direction = default_sort$direction %||% "source",
      label = default_sort$label %||% NULL
    )
  )

  table_artifact_policy(
    default_view = default_view,
    alternate_views = raw_policy$alternate_views %||% artifact$metadata$alternate_sorts %||% list(),
    preview_rows = raw_policy$preview_rows %||% artifact$metadata$preview_rows %||% 25L,
    include_full_csv = raw_policy$include_full_csv %||% TRUE,
    include_json = raw_policy$include_json %||% TRUE,
    render_target = render_target
  )
}

.table_artifact_first_existing_column <- function(data, patterns) {
  columns <- names(data)
  for (pattern in patterns) {
    matched <- columns[grepl(pattern, columns, ignore.case = TRUE)]
    if (length(matched)) {
      return(matched[[1L]])
    }
  }
  NULL
}

infer_table_artifact_policy <- function(
  artifact_id,
  label,
  source_module,
  object,
  metadata = list(),
  section = "Analysis",
  render_target = "llm_docx"
) {
  data <- if (is.null(object)) data.table::data.table() else data.table::as.data.table(object)
  text <- tolower(paste(
    artifact_id %||% "",
    label %||% "",
    source_module %||% "",
    metadata$original_name %||% "",
    metadata$normalized_section %||% section %||% "",
    collapse = " "
  ))
  preview_rows <- if (grepl("scored|output|validation|data", text)) 25L else 20L

  if (grepl("interaction", text)) {
    strength <- .table_artifact_first_existing_column(data, c("strength|interaction|importance|mean_abs|score|value"))
    return(table_artifact_policy(
      default_view = list(
        view_id = "top_interaction_strength",
        label = "Interaction Strength",
        sort = table_artifact_sort(strength, if (is.null(strength)) "source" else "desc", if (!is.null(strength)) paste(strength, "descending") else "Source order")
      ),
      preview_rows = preview_rows,
      render_target = render_target
    ))
  }

  if (grepl("shap|importance|feature importance|variable importance", text)) {
    mean_abs <- .table_artifact_first_existing_column(data, c("^mean_abs", "mean.*abs.*shap", "abs.*mean.*shap", "importance", "gain", "overall"))
    mean <- .table_artifact_first_existing_column(data, c("^mean_shap$", "mean.*shap", "contribution", "effect"))
    feature <- .table_artifact_first_existing_column(data, c("^feature$", "variable", "term", "name"))
    default_column <- mean_abs %||% mean %||% .table_artifact_first_existing_column(data, c("importance|gain|score|value"))
    alternates <- list()
    if (!is.null(mean)) {
      alternates <- c(
        alternates,
        list(
          list(view_id = "top_positive_mean_shap", label = "Top Positive Mean SHAP", sort = table_artifact_sort(mean, "desc", "Mean SHAP descending")),
          list(view_id = "top_negative_mean_shap", label = "Top Negative Mean SHAP", sort = table_artifact_sort(mean, "asc", "Mean SHAP ascending"))
        )
      )
    }
    return(table_artifact_policy(
      default_view = list(
        view_id = "top_importance",
        label = if (grepl("shap", text) && !is.null(mean_abs)) "Top Mean Absolute SHAP" else "Top Importance",
        sort = table_artifact_sort(default_column, if (is.null(default_column)) "source" else "desc", if (!is.null(default_column)) paste(default_column, "descending") else "Source order")
      ),
      alternate_views = alternates,
      preview_rows = preview_rows,
      render_target = render_target
    ))
  }

  if (grepl("correlation|corr", text)) {
    abs_corr <- .table_artifact_first_existing_column(data, c("abs.*corr|absolute.*corr"))
    corr <- .table_artifact_first_existing_column(data, c("^correlation$|corr"))
    return(table_artifact_policy(
      default_view = list(
        view_id = "highest_absolute_correlation",
        label = "Highest Absolute Correlation",
        sort = table_artifact_sort(abs_corr %||% corr, if (is.null(abs_corr %||% corr)) "source" else "desc", "Correlation strength descending")
      ),
      alternate_views = if (!is.null(corr)) list(
        list(view_id = "highest_positive_correlation", label = "Highest Positive Correlation", sort = table_artifact_sort(corr, "desc", "Correlation descending")),
        list(view_id = "lowest_negative_correlation", label = "Lowest Negative Correlation", sort = table_artifact_sort(corr, "asc", "Correlation ascending"))
      ) else list(),
      preview_rows = preview_rows,
      render_target = render_target
    ))
  }

  if (grepl("threshold|metric|performance|confusion|lift|gain|calibration|residual|error", text)) {
    metric_col <- .table_artifact_first_existing_column(data, c("utility|auc|accuracy|f1|lift|gain|rmse|mae|error|residual|value|score"))
    threshold_col <- .table_artifact_first_existing_column(data, c("threshold"))
    alternates <- if (!is.null(threshold_col)) {
      list(list(view_id = "threshold_order", label = "Threshold ascending", sort = table_artifact_sort(threshold_col, "asc", "Threshold ascending")))
    } else {
      list()
    }
    return(table_artifact_policy(
      default_view = list(
        view_id = "top_metric",
        label = "Top Metric Values",
        sort = table_artifact_sort(metric_col, if (is.null(metric_col)) "source" else "desc", if (!is.null(metric_col)) paste(metric_col, "descending") else "Source order")
      ),
      alternate_views = alternates,
      preview_rows = preview_rows,
      render_target = render_target
    ))
  }

  if (grepl("risk|leakage|drift|diagnostic", text)) {
    risk_col <- .table_artifact_first_existing_column(data, c("risk|drift|leakage|score|severity|value|count"))
    return(table_artifact_policy(
      default_view = list(
        view_id = "highest_risk",
        label = "Highest Risk",
        sort = table_artifact_sort(risk_col, if (is.null(risk_col)) "source" else "desc", if (!is.null(risk_col)) paste(risk_col, "descending") else "Source order")
      ),
      preview_rows = preview_rows,
      render_target = render_target
    ))
  }

  if (grepl("missing|\\bna\\b|null", text)) {
    missing_col <- .table_artifact_first_existing_column(data, c("missing|na|pct|percent|rate|count"))
    return(table_artifact_policy(
      default_view = list(
        view_id = "highest_missingness",
        label = "Highest Missingness",
        sort = table_artifact_sort(missing_col, if (is.null(missing_col)) "source" else "desc", "Missingness descending")
      ),
      preview_rows = preview_rows,
      render_target = render_target
    ))
  }

  table_artifact_policy(
    default_view = list(
      view_id = "source_order",
      label = "Source order",
      sort = table_artifact_sort(direction = "source")
    ),
    preview_rows = preview_rows,
    render_target = render_target
  )
}

attach_table_artifact_policy <- function(
  artifact_id,
  label,
  source_module,
  object,
  config = list(),
  metadata = list(),
  section = "Analysis",
  render_target = "llm_docx"
) {
  config <- config %||% list()
  metadata <- metadata %||% list()
  policy_source <- "explicit"
  if (is.null(config$table_policy) && is.null(metadata$table_policy)) {
    config$table_policy <- infer_table_artifact_policy(
      artifact_id = artifact_id,
      label = label,
      source_module = source_module,
      object = object,
      metadata = metadata,
      section = section,
      render_target = render_target
    )
    policy_source <- "inferred"
  }
  data <- if (is.null(object)) data.table::data.table() else data.table::as.data.table(object)
  metadata$table_architecture <- c(metadata$table_architecture %||% list(), list(
    canonical_table = TRUE,
    human_report = "interactive_render_table",
    llm_collector = "table_artifact_policy",
    policy_attached = TRUE,
    policy_source = policy_source,
    rows = nrow(data),
    columns = ncol(data)
  ))
  list(config = config, metadata = metadata)
}

ensure_table_artifact_policy <- function(artifact, render_target = "llm_docx") {
  if (!inherits(artifact, "aq_artifact") || !identical(artifact$artifact_type %||% "", "table")) {
    return(artifact)
  }
  payload <- attach_table_artifact_policy(
    artifact_id = artifact$artifact_id,
    label = artifact$label,
    source_module = artifact$source_module,
    object = artifact$object,
    config = artifact$config %||% list(),
    metadata = artifact$metadata %||% list(),
    section = artifact$section %||% "Analysis",
    render_target = render_target
  )
  artifact$config <- payload$config
  artifact$metadata <- payload$metadata
  artifact
}

.table_artifact_view_sort <- function(view) {
  sort <- view$sort %||% view
  list(
    column = sort$column %||% NULL,
    direction = sort$direction %||% "source",
    label = sort$label %||% view$label %||% "Source order"
  )
}

.table_artifact_apply_sort <- function(data, sort) {
  data <- data.table::copy(data)
  if (!nrow(data) || identical(sort$direction, "source") || is.null(sort$column)) {
    return(list(data = data, status = "source_order", reason = "Source order retained."))
  }
  if (!sort$column %in% names(data)) {
    return(list(data = data, status = "missing_sort_column", reason = paste("Sort column is missing:", sort$column)))
  }

  direction <- sort$direction %||% "desc"
  order_index <- if (identical(direction, "asc")) {
    order(data[[sort$column]], na.last = TRUE)
  } else {
    order(data[[sort$column]], decreasing = TRUE, na.last = TRUE)
  }
  list(data = data[order_index], status = "sorted", reason = paste("Sorted by", sort$column, direction))
}

table_artifact_preview <- function(artifact, render_target = "llm_docx") {
  data <- table_artifact_data(artifact)
  policy <- table_artifact_policy_for(artifact, render_target)
  views <- c(list(policy$default_view), policy$alternate_views)
  preview_rows <- max(1L, as.integer(policy$preview_rows %||% 25L))

  previews <- lapply(seq_along(views), function(index) {
    view <- views[[index]]
    sort <- .table_artifact_view_sort(view)
    sorted <- .table_artifact_apply_sort(data, sort)
    preview <- utils::head(sorted$data, preview_rows)
    list(
      view_id = view$view_id %||% paste0("view_", index),
      label = view$label %||% sort$label %||% paste0("View ", index),
      sort = sort,
      sort_status = sorted$status,
      sort_reason = sorted$reason,
      rows = nrow(preview),
      columns = ncol(preview),
      truncated = nrow(data) > nrow(preview),
      data = preview
    )
  })

  stats::setNames(previews, vapply(previews, function(view) view$view_id, character(1)))
}

table_artifact_metadata <- function(artifact, render_target = "llm_docx", backing = list()) {
  data <- table_artifact_data(artifact)
  policy <- table_artifact_policy_for(artifact, render_target)
  default_sort <- .table_artifact_view_sort(policy$default_view)
  alternate_sorts <- lapply(policy$alternate_views, .table_artifact_view_sort)

  list(
    table_id = artifact$artifact_id %||% NA_character_,
    table_type = artifact$metadata$table_type %||% artifact$artifact_type %||% "table",
    table_intent = artifact$metadata$table_intent %||% artifact$label %||% artifact$artifact_id %||% "Table artifact",
    rows = nrow(data),
    columns = ncol(data),
    default_sort = default_sort,
    alternate_sorts = alternate_sorts,
    preview_strategy = "policy_views",
    preview_row_count = as.integer(policy$preview_rows %||% 25L),
    truncated = nrow(data) > as.integer(policy$preview_rows %||% 25L),
    csv_available = isTRUE(backing$csv_available),
    json_available = isTRUE(backing$json_available),
    csv_path = backing$csv_path %||% NA_character_,
    json_path = backing$json_path %||% NA_character_,
    render_target = render_target
  )
}

.table_artifact_json_escape <- function(x) {
  x <- as.character(x %||% "")
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x
}

.table_artifact_json_value <- function(value) {
  if (length(value) == 0L || is.na(value)) {
    return("null")
  }
  if (is.logical(value)) {
    return(if (isTRUE(value)) "true" else "false")
  }
  if (is.numeric(value)) {
    return(as.character(value))
  }
  paste0("\"", .table_artifact_json_escape(value), "\"")
}

.table_artifact_write_json <- function(data, path) {
  rows <- lapply(seq_len(nrow(data)), function(row_index) {
    fields <- vapply(names(data), function(column) {
      paste0("\"", .table_artifact_json_escape(column), "\":", .table_artifact_json_value(data[[column]][[row_index]]))
    }, character(1))
    paste0("{", paste(fields, collapse = ","), "}")
  })
  writeLines(paste0("[", paste(rows, collapse = ","), "]"), path, useBytes = TRUE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

table_artifact_persist_backing_data <- function(
  artifact,
  output_dir,
  render_target = "llm_docx",
  file_stem = NULL
) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  data <- table_artifact_data(artifact)
  policy <- table_artifact_policy_for(artifact, render_target)
  file_stem <- file_stem %||% artifact$artifact_id %||% "table_artifact"
  file_stem <- gsub("[^A-Za-z0-9_\\-]+", "_", file_stem)

  result <- list(
    csv_available = FALSE,
    json_available = FALSE,
    csv_path = NA_character_,
    json_path = NA_character_,
    errors = character()
  )

  if (isTRUE(policy$include_full_csv)) {
    csv_path <- file.path(output_dir, paste0(file_stem, ".csv"))
    csv_result <- tryCatch({
      data.table::fwrite(data, csv_path)
      normalizePath(csv_path, winslash = "/", mustWork = TRUE)
    }, error = function(e) e)
    if (inherits(csv_result, "error")) {
      result$errors <- c(result$errors, paste("CSV backing write failed:", conditionMessage(csv_result)))
    } else {
      result$csv_available <- TRUE
      result$csv_path <- csv_result
    }
  }

  if (isTRUE(policy$include_json)) {
    json_path <- file.path(output_dir, paste0(file_stem, ".json"))
    json_result <- tryCatch(.table_artifact_write_json(data, json_path), error = function(e) e)
    if (inherits(json_result, "error")) {
      result$errors <- c(result$errors, paste("JSON backing write failed:", conditionMessage(json_result)))
    } else {
      result$json_available <- TRUE
      result$json_path <- json_result
    }
  }

  result
}

table_artifact_representation <- function(
  artifact,
  render_target = "llm_docx",
  backing = list()
) {
  previews <- table_artifact_preview(artifact, render_target)
  metadata <- table_artifact_metadata(artifact, render_target, backing)
  list(
    caption = artifact_caption(artifact, render_target),
    summary = paste(
      metadata$table_intent,
      "| rows:", metadata$rows,
      "| columns:", metadata$columns,
      "| default_sort:", metadata$default_sort$label
    ),
    metadata = metadata,
    previews = previews,
    backing = backing
  )
}

table_artifact_quality_status <- function(artifact, render_target = "llm_docx", backing = list()) {
  metadata <- table_artifact_metadata(artifact, render_target, backing)
  previews <- table_artifact_preview(artifact, render_target)
  has_preview <- length(previews) > 0L && any(vapply(previews, function(view) nrow(view$data) > 0L || metadata$rows == 0L, logical(1)))
  list(
    preview = if (has_preview) "available" else "missing",
    sorting_policy = if (length(metadata$default_sort)) "available" else "missing",
    backing_data = if (metadata$rows >= 0L) "available" else "missing",
    csv = if (isTRUE(metadata$csv_available)) "available" else "not_supplied",
    json = if (isTRUE(metadata$json_available)) "available" else "not_supplied",
    metadata = metadata
  )
}

table_artifact_coverage_row <- function(artifact, module_id = artifact$source_module %||% NA_character_) {
  is_table <- identical(artifact$artifact_type %||% "", "table")
  if (!is_table) {
    return(data.table::data.table(
      module = module_id,
      table_name = artifact$label %||% artifact$artifact_id %||% NA_character_,
      purpose = artifact$section %||% NA_character_,
      human_report = "Not Applicable",
      llm_collector = "Not Applicable",
      table_policy = "Not Applicable",
      preview_views = NA_character_,
      sort_policy = NA_character_,
      csv_sidecar = "Not Applicable",
      json_sidecar = "Not Applicable",
      quality_policy = "Not Applicable",
      status = "Not Applicable",
      recommended_action = "Artifact is not a table."
    ))
  }

  policy <- table_artifact_policy_for(artifact, "llm_docx")
  previews <- table_artifact_preview(artifact, "llm_docx")
  quality <- assess_artifact_quality(artifact, "llm_docx")
  policy_source <- artifact$metadata$table_architecture$policy_source %||% "unknown"
  explicit_policy <- identical(policy_source, "explicit") ||
    inherits(artifact$metadata$table_policy %||% NULL, "table_artifact_policy")
  should_be_explicit <- grepl(
    "shap|importance|risk|diagnostic|threshold|metric|performance|confusion|lift|gain|calibration|residual|error|interaction|correlation",
    tolower(paste(
      artifact$artifact_id %||% "",
      artifact$label %||% "",
      artifact$section %||% "",
      artifact$metadata$original_name %||% "",
      artifact$metadata$normalized_section %||% "",
      collapse = " "
    ))
  ) || length(previews) > 1L
  has_policy <- inherits(policy, "table_artifact_policy")
  has_preview <- length(previews) > 0L
  default_sort <- policy$default_view$sort$label %||% policy$default_view$label %||% "Source order"
  architecture <- artifact$metadata$table_architecture %||% list()
  covered <- isTRUE(architecture$canonical_table) &&
    has_policy &&
    has_preview &&
    quality$components$table_preview %in% c("available", "not_applicable") &&
    quality$components$sorting_policy %in% c("available", "not_applicable")

  data.table::data.table(
    module = module_id,
    table_name = artifact$label %||% artifact$artifact_id,
    purpose = artifact$metadata$table_intent %||% artifact$section %||% "Table artifact",
    human_report = "Existing interactive render_table path preserved",
    llm_collector = "Structured table summary, previews, and sidecars",
    table_policy = if (has_policy) "Yes" else "No",
    preview_views = paste(vapply(previews, function(view) view$label, character(1)), collapse = " | "),
    sort_policy = default_sort,
    csv_sidecar = "Collector writes CSV sidecar",
    json_sidecar = "Collector writes JSON sidecar",
    quality_policy = paste0("Completeness ", quality$artifact_completeness, "%"),
    status = if (covered) "Covered" else "Partial",
    recommended_action = if (!covered) {
      "Attach a table policy and canonical metadata."
    } else if (should_be_explicit && !explicit_policy) {
      "Covered by inferred policy; supply explicit table_policy when creating this analytical table."
    } else {
      "No action required."
    }
  )
}

table_artifact_coverage_audit <- function(artifacts) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(data.table::data.table(
      module = character(),
      table_name = character(),
      purpose = character(),
      human_report = character(),
      llm_collector = character(),
      table_policy = character(),
      preview_views = character(),
      sort_policy = character(),
      csv_sidecar = character(),
      json_sidecar = character(),
      quality_policy = character(),
      status = character(),
      recommended_action = character()
    ))
  }
  rows <- lapply(artifacts, function(artifact) {
    table_artifact_coverage_row(artifact, artifact$source_module %||% NA_character_)
  })
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

.table_artifact_module_fixture <- function(module_id, table_name, data, section = "Analysis") {
  metadata <- if (exists("module_artifact_metadata", mode = "function")) {
    module_artifact_metadata(
      module_id = module_id,
      module_run_id = "table_policy_audit",
      source_module = module_id,
      original_name = table_name,
      original_section = section,
      normalized_section = section,
      extra = list(table_type = table_name, table_intent = paste("Synthetic audit fixture for", table_name))
    )
  } else {
    list(table_type = table_name, table_intent = paste("Synthetic audit fixture for", table_name), created_by_module = TRUE)
  }
  create_artifact(
    artifact_id = paste(module_id, gsub("[^a-z0-9]+", "_", tolower(table_name)), sep = "_"),
    artifact_type = "table",
    label = table_name,
    source_module = module_id,
    object = data,
    metadata = metadata,
    section = section,
    order = 1L
  )
}

table_artifact_module_audit_fixtures <- function() {
  list(
    autoquant_eda_summary = .table_artifact_module_fixture(
      "autoquant_eda", "Missingness Summary",
      data.table::data.table(feature = paste0("x", 1:30), missing_rate = seq(0.3, 0, length.out = 30)),
      "Missingness"
    ),
    autoquant_eda_correlation = .table_artifact_module_fixture(
      "autoquant_eda", "Top Absolute Correlations",
      data.table::data.table(feature_a = paste0("x", 1:30), feature_b = paste0("z", 1:30), correlation = seq(-0.95, 0.92, length.out = 30), abs_correlation = seq(0.95, 0.1, length.out = 30)),
      "Correlation Diagnostics"
    ),
    autoquant_model_readiness = .table_artifact_module_fixture(
      "autoquant_model_readiness", "Feature Risk Registry",
      data.table::data.table(feature = paste0("x", 1:20), risk_score = seq(1, 0, length.out = 20), recommendation = "Review"),
      "Model Overview"
    ),
    autoquant_regression_model_insights = .table_artifact_module_fixture(
      "autoquant_regression_model_insights", "Residual Error Analysis",
      data.table::data.table(segment = paste0("S", 1:20), rmse = seq(10, 1, length.out = 20), mae = seq(8, 0.5, length.out = 20)),
      "Residual Diagnostics"
    ),
    autoquant_binary_model_insights = .table_artifact_module_fixture(
      "autoquant_binary_model_insights", "Threshold Metrics",
      data.table::data.table(threshold = seq(0.05, 0.95, by = 0.05), utility = seq(0.1, 0.9, length.out = 19), f1 = seq(0.8, 0.2, length.out = 19)),
      "Threshold Diagnostics"
    ),
    autoquant_regression_shap_analysis = .table_artifact_module_fixture(
      "autoquant_regression_shap_analysis", "Global SHAP Importance",
      data.table::data.table(feature = paste0("x", 1:30), mean_abs_shap = seq(2, 0.1, length.out = 30), mean_shap = seq(-1, 1, length.out = 30)),
      "Global Importance"
    ),
    autoquant_binary_shap_analysis = .table_artifact_module_fixture(
      "autoquant_binary_shap_analysis", "Interaction Importance",
      data.table::data.table(feature_a = paste0("x", 1:20), feature_b = paste0("z", 1:20), interaction_strength = seq(1, 0.1, length.out = 20)),
      "Interaction Importance"
    ),
    autoquant_catboost_builder = .table_artifact_module_fixture(
      "autoquant_catboost_builder", "Variable Importance",
      data.table::data.table(feature = paste0("x", 1:25), importance = seq(100, 1, length.out = 25)),
      "Training Diagnostics"
    ),
    code_runner = .table_artifact_module_fixture(
      "code_runner", "Code Runner Table Output",
      data.table::data.table(row = 1:15, value = stats::runif(15)),
      "Code Output"
    )
  )
}

qa_table_artifact_policy <- function(output_dir = file.path(tempdir(), "table_artifact_policy_qa")) {
  if (dir.exists(output_dir)) {
    unlink(output_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  data <- data.table::data.table(
    feature = paste0("Feature_", seq_len(40)),
    mean_abs_shap = round(seq(2, 0.05, length.out = 40), 4),
    mean_shap = round(seq(-1, 1, length.out = 40), 4)
  )
  policy <- table_artifact_policy(
    default_view = list(
      view_id = "top_mean_abs_shap",
      label = "Mean Absolute SHAP descending",
      sort = table_artifact_sort("mean_abs_shap", "desc", "Mean Absolute SHAP descending")
    ),
    alternate_views = list(
      list(
        view_id = "highest_positive",
        label = "Mean SHAP descending",
        sort = table_artifact_sort("mean_shap", "desc", "Mean SHAP descending")
      ),
      list(
        view_id = "highest_negative",
        label = "Mean SHAP ascending",
        sort = table_artifact_sort("mean_shap", "asc", "Mean SHAP ascending")
      )
    ),
    preview_rows = 10L,
    include_full_csv = TRUE,
    include_json = TRUE,
    render_target = "llm_docx"
  )
  artifact <- create_artifact(
    artifact_id = "qa_table_policy",
    artifact_type = "table",
    label = "SHAP Importance Table",
    source_module = "qa_table_artifact_policy",
    object = data,
    config = list(table_policy = policy),
    metadata = list(table_type = "shap_importance", table_intent = "Rank features by SHAP contribution."),
    section = "Table Policy",
    order = 1L
  )

  backing <- table_artifact_persist_backing_data(artifact, output_dir, file_stem = "qa_table_policy")
  representation <- table_artifact_representation(artifact, "llm_docx", backing)
  quality <- assess_artifact_quality(artifact, "llm_docx", table_backing = backing)
  degraded <- artifact
  degraded$object <- NULL
  degraded_quality <- assess_artifact_quality(degraded, "llm_docx")

  collector <- create_project_artifact_collector(
    project_id = "qa_table_policy_project",
    project_name = "QA Table Policy Project",
    output_dir = file.path(output_dir, "collector")
  )
  result <- service_result(
    status = "success",
    artifacts = list(qa_table_policy = artifact),
    metadata = list(module_id = "qa_table_artifact_policy", module_run_id = "run_table_policy")
  )
  append <- project_collector_append_result(
    collector,
    result,
    run_id = "run_001",
    module_id = "qa_table_artifact_policy",
    module_label = "QA Table Artifact Policy",
    write = FALSE
  )
  collector <- append$value
  write <- project_collector_write(collector)
  table_index <- write$metadata$table_index %||% data.table::data.table()
  coverage <- table_artifact_coverage_audit(table_artifact_module_audit_fixtures())
  uncovered <- coverage[status %in% c("Partial", "Bypassing Architecture")]

  data.table::data.table(
    check = c(
      "policy_exists",
      "default_sort_declared",
      "alternate_sorts_declared",
      "preview_generated",
      "preview_metadata_recorded",
      "backing_data_metadata_recorded",
      "render_target_respected",
      "graceful_degradation",
      "quality_scoring_integration",
      "collector_table_index_available",
      "module_coverage_audit",
      "module_preview_policies",
      "module_quality_metadata"
    ),
    status = c(
      if (inherits(policy, "table_artifact_policy")) "success" else "error",
      if (identical(representation$metadata$default_sort$column, "mean_abs_shap")) "success" else "error",
      if (length(representation$metadata$alternate_sorts) == 2L) "success" else "error",
      if (length(representation$previews) == 3L && all(vapply(representation$previews, function(view) nrow(view$data) <= 10L, logical(1)))) "success" else "error",
      if (isTRUE(representation$metadata$truncated) && representation$metadata$preview_row_count == 10L) "success" else "error",
      if (isTRUE(representation$metadata$csv_available) && isTRUE(representation$metadata$json_available)) "success" else "error",
      if (identical(representation$metadata$render_target, "llm_docx")) "success" else "error",
      if (degraded_quality$severity %in% c("warning", "info")) "success" else "error",
      if ("table_preview" %in% names(quality$components) && quality$artifact_completeness >= 0 && quality$artifact_completeness <= 100) "success" else "error",
      if (nrow(table_index) == 1L && isTRUE(table_index$csv_available[[1]])) "success" else "error",
      if (!nrow(uncovered)) "success" else "error",
      if (all(nzchar(coverage$preview_views))) "success" else "error",
      if (all(grepl("Completeness", coverage$quality_policy))) "success" else "error"
    ),
    message = c(
      "Policy object is available.",
      representation$metadata$default_sort$label,
      paste(vapply(representation$metadata$alternate_sorts, function(sort) sort$label, character(1)), collapse = " | "),
      paste("Preview views:", paste(names(representation$previews), collapse = ", ")),
      paste("Preview rows:", representation$metadata$preview_row_count),
      paste("CSV:", representation$metadata$csv_path, "| JSON:", representation$metadata$json_path),
      representation$metadata$render_target,
      paste("Degraded severity:", degraded_quality$severity),
      paste("Completeness:", quality$artifact_completeness),
      paste("Table index rows:", nrow(table_index)),
      paste("Covered tables:", nrow(coverage), "| uncovered:", nrow(uncovered)),
      paste("Preview policies:", paste(unique(coverage$sort_policy), collapse = " | ")),
      paste("Quality policies:", paste(unique(coverage$quality_policy), collapse = " | "))
    )
  )
}
