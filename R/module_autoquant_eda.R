autoquant_eda_available <- function() {
  requireNamespace("AutoQuant", quietly = TRUE) &&
    exists("generate_eda_artifacts", envir = asNamespace("AutoQuant"), inherits = FALSE)
}

autoquant_eda_unavailable_result <- function() {
  service_result(
    status = "error",
    errors = "AutoQuant::generate_eda_artifacts() was not found. Install/update AutoQuant before running this module.",
    metadata = list(
      error_code = "MODULE_DEPENDENCY_MISSING",
      module_id = "autoquant_eda"
    )
  )
}

.autoquant_eda_selected_columns <- function(config, fields) {
  unique(unlist(lapply(fields, function(field) config[[field]] %||% character()), use.names = FALSE))
}

.autoquant_eda_missing_columns <- function(data, config) {
  selected <- .autoquant_eda_selected_columns(
    config,
    c("UnivariateVars", "CorrVars", "TrendVars", "TrendDateVar", "TrendGroupVar", "TargetVar")
  )
  selected <- selected[nzchar(selected)]
  setdiff(selected, names(data))
}

validate_autoquant_eda_config <- function(data, config) {
  if (!autoquant_eda_available()) {
    return(autoquant_eda_unavailable_result())
  }

  if (is.null(data)) {
    return(service_result(
      status = "error",
      errors = "Upload data before running AutoQuant EDA.",
      metadata = list(
        error_code = "DATA_MISSING",
        module_id = "autoquant_eda"
      )
    ))
  }

  if (is.null(config)) {
    config <- list()
  }

  if (!is.list(config)) {
    return(service_result(
      status = "error",
      errors = "AutoQuant EDA config must be a list.",
      metadata = list(
        error_code = "MODULE_CONFIG_INVALID",
        module_id = "autoquant_eda"
      )
    ))
  }

  if (!length(config$UnivariateVars %||% character()) &&
      !length(config$CorrVars %||% character()) &&
      !length(config$TrendVars %||% character())) {
    return(service_result(
      status = "error",
      errors = "Select at least one univariate, correlation, or trend variable.",
      metadata = list(
        error_code = "MODULE_CONFIG_INVALID",
        module_id = "autoquant_eda"
      )
    ))
  }

  missing_columns <- .autoquant_eda_missing_columns(data, config)
  if (length(missing_columns)) {
    return(service_result(
      status = "error",
      errors = paste("Selected columns are missing:", paste(missing_columns, collapse = ", ")),
      metadata = list(
        error_code = "COLUMN_MISSING",
        module_id = "autoquant_eda",
        missing_columns = missing_columns
      )
    ))
  }

  service_result(
    status = "success",
    value = config,
    messages = "AutoQuant EDA config is valid.",
    metadata = list(
      module_id = "autoquant_eda",
      n_rows = nrow(data),
      n_cols = ncol(data)
    )
  )
}

.autoquant_eda_run_id <- function(timestamp = Sys.time()) {
  paste0("autoquant_eda_", format(timestamp, "%Y%m%d%H%M%S"))
}

.autoquant_eda_selected_variables <- function(config) {
  list(
    univariate = config$UnivariateVars %||% character(),
    correlation = config$CorrVars %||% character(),
    trend = config$TrendVars %||% character(),
    trend_date = config$TrendDateVar %||% NULL,
    trend_group = config$TrendGroupVar %||% NULL,
    target = config$TargetVar %||% NULL
  )
}

.autoquant_eda_call_args <- function(data, config) {
  list(
    data = data,
    DataName = config$DataName %||% NULL,
    UnivariateVars = config$UnivariateVars %||% NULL,
    CorrVars = config$CorrVars %||% NULL,
    TrendVars = config$TrendVars %||% NULL,
    TrendDateVar = config$TrendDateVar %||% NULL,
    TrendGroupVar = config$TrendGroupVar %||% NULL,
    Theme = config$Theme %||% "light",
    MaxCategoricalLevels = config$MaxCategoricalLevels %||% 25L,
    MaxDiscreteNumericLevels = config$MaxDiscreteNumericLevels %||% 20L,
    MaxCorrelationPairsToPlot = config$MaxCorrelationPairsToPlot %||% 25L
  )
}

.autoquant_eda_grouped_trend_preflight <- function(data, config, min_rows_per_group = 4L) {
  trend_vars <- config$TrendVars %||% character()
  trend_group <- config$TrendGroupVar %||% NULL
  if (is.null(trend_group) || !nzchar(trend_group) || !length(trend_vars)) {
    return(list(config = config, warnings = character()))
  }
  if (is.null(data) || !trend_group %in% names(data)) {
    return(list(config = config, warnings = character()))
  }

  group_counts <- data.table::as.data.table(data)[!is.na(get(trend_group)), .N, by = trend_group]
  if (!nrow(group_counts) || min(group_counts$N, na.rm = TRUE) < min_rows_per_group) {
    config$TrendGroupVar <- NULL
    return(list(
      config = config,
      warnings = paste(
        "Grouped EDA trend artifacts skipped because TrendGroupVar",
        trend_group,
        "has fewer than",
        min_rows_per_group,
        "usable rows in at least one group. Overall trend artifacts were still generated."
      )
    ))
  }

  list(config = config, warnings = character())
}

.autoquant_eda_r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }

  deparse(value, width.cutoff = 500L)
}

.autoquant_eda_code <- function(config) {
  vec_code <- function(value) {
    if (is.null(value) || !length(value)) {
      return("NULL")
    }
    paste0("c(", paste(vapply(value, .autoquant_eda_r_string, character(1)), collapse = ", "), ")")
  }

  paste(
    "eda_result <- AutoQuant::generate_eda_artifacts(",
    "  data = data,",
    paste0("  DataName = ", .autoquant_eda_r_string(config$DataName %||% "data"), ","),
    paste0("  UnivariateVars = ", vec_code(config$UnivariateVars), ","),
    paste0("  CorrVars = ", vec_code(config$CorrVars), ","),
    paste0("  TrendVars = ", vec_code(config$TrendVars), ","),
    paste0("  TrendDateVar = ", .autoquant_eda_r_string(config$TrendDateVar %||% NULL), ","),
    paste0("  TrendGroupVar = ", .autoquant_eda_r_string(config$TrendGroupVar %||% NULL), ","),
    paste0("  Theme = ", .autoquant_eda_r_string(config$Theme %||% "light")),
    ")",
    "",
    "# TODO: Add app-side artifact/report-plan conversion when exporting a complete module replay script.",
    sep = "\n"
  )
}

.autoquant_eda_section <- function(path) {
  text <- tolower(paste(path, collapse = " "))
  if (grepl("missing|null|na", text)) return("Missingness")
  if (grepl("describe|description|schema|overview", text)) return("Data Overview")
  if (grepl("univariate|histogram|box|categorical|discrete", text)) return("Univariate Analysis")
  if (grepl("correlation|correlogram", text)) return("Correlation Diagnostics")
  if (grepl("trend", text)) return("Trend Analysis")
  if (grepl("target", text)) return("Target Analysis")
  if (grepl("drift", text)) return("Drift Diagnostics")
  if (grepl("leakage|risk|flag", text)) return("Risk / Leakage Flags")
  "Appendix"
}

.autoquant_eda_slug <- function(value) {
  slug <- tolower(value)
  slug <- gsub("[^a-z0-9]+", "_", slug)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) {
    return("artifact")
  }

  slug
}

.autoquant_eda_label <- function(name) {
  clean <- gsub("^tables_?|^plots_?", "", name)
  clean <- gsub("GroupedBoxPlots", "Grouped Box Plots", clean)
  clean <- gsub("DiscreteNumericBarPlots", "Discrete Numeric Bar Plots", clean)
  clean <- gsub("CategoricalTopNBarPlots", "Categorical Top N Bar Plots", clean)
  clean <- gsub("([a-z])([A-Z])", "\\1 \\2", clean)
  clean <- gsub("[_.]+", " ", clean)
  clean <- gsub("\\s+", " ", clean)
  clean <- trimws(clean)
  text <- tolower(clean)

  replacements <- c(
    "describe data" = "Data Description",
    "univariate stats" = "Univariate Summary",
    "correlation stats" = "Correlation Summary",
    "high correlation stats" = "High Correlations",
    "top abs correlation stats" = "Top Absolute Correlations",
    "top positive correlation stats" = "Top Positive Correlations",
    "top negative correlation stats" = "Top Negative Correlations",
    "correlogram" = "Correlation Matrix"
  )
  if (text %in% names(replacements)) {
    return(unname(replacements[[text]]))
  }

  label <- tools::toTitleCase(clean)
  label <- gsub("\\bHistograms\\b", "Distribution", label)
  label <- gsub("\\bBox Plots\\b|\\bBoxPlots\\b", "Box Plot", label)
  label <- gsub("\\bGrouped Box Plots\\b|\\bGroupedBoxPlots\\b", "Grouped Box Plot", label)
  label <- gsub("\\bDiscrete Numeric Bar Plots\\b|\\bDiscreteNumericBarPlots\\b", "Discrete Numeric Bars", label)
  label <- gsub("\\bCategorical Top N Bar Plots\\b|\\bCategoricalTopNBarPlots\\b", "Top Categories", label)
  label <- gsub("\\bCorrelation Pairs Top Absolute Correlations\\b", "Top Absolute Correlation Pairs", label)
  label <- gsub("\\bCorrelation Pairs Top Positive Correlations\\b", "Top Positive Correlation Pairs", label)
  label <- gsub("\\bCorrelation Pairs Top Negative Correlations\\b", "Top Negative Correlation Pairs", label)
  label <- gsub("\\bTrend Area\\b", "Trend", label)
  label <- gsub("\\bTrend Grouped Lines\\b", "Grouped Trend", label)
  label <- sub("^Univariate Distribution (.+)$", "\\1 Distribution", label)
  label <- sub("^Univariate Box Plot (.+)$", "\\1 Box Plot", label)
  label <- sub("^Univariate Grouped Box Plot (.+)$", "\\1 Grouped Box Plot", label)
  label <- sub("^Univariate Discrete Numeric Bars (.+)$", "\\1 Discrete Numeric Bars", label)
  label <- sub("^Univariate Top Categories (.+)$", "\\1 Top Categories", label)
  label <- sub("^Univariate Categorical Top N Bar Plots (.+)$", "\\1 Top Categories", label)
  label <- sub("^Trend Stats (.+)$", "\\1 Trend Summary", label)
  label <- sub("^Trend Grouped Stats (.+)$", "\\1 Grouped Trend Summary", label)
  label <- sub("^Trend (.+)$", "\\1 Trend", label)
  label <- sub("^Grouped Trend (.+)$", "\\1 Grouped Trend", label)
  label <- gsub("\\s+", " ", label)
  label <- trimws(label)

  if (!nzchar(label) || grepl("^item [0-9]+$", tolower(label))) {
    return("EDA Artifact")
  }

  label
}

.autoquant_eda_flatten <- function(x, path = character()) {
  if (is.null(x)) {
    return(list())
  }

  if (inherits(x, "htmlwidget") || data.table::is.data.table(x) || is.data.frame(x) || is.character(x)) {
    name <- paste(path, collapse = "_")
    return(stats::setNames(list(x), name))
  }

  if (!is.list(x)) {
    return(list())
  }

  parts <- list()
  item_names <- names(x)
  if (is.null(item_names)) {
    item_names <- paste0("item_", seq_along(x))
  }

  for (index in seq_along(x)) {
    child_path <- c(path, item_names[[index]])
    parts <- c(parts, .autoquant_eda_flatten(x[[index]], child_path))
  }

  parts
}

.autoquant_eda_artifact_type <- function(value, root_name) {
  if (data.table::is.data.table(value) || is.data.frame(value)) {
    return("table")
  }
  if (is.character(value)) {
    return("text")
  }
  if (inherits(value, "htmlwidget")) {
    return("plot")
  }
  if (identical(root_name, "plots")) {
    return("plot")
  }
  NULL
}

normalize_autoquant_eda_artifacts <- function(autoquant_result, config, module_run_id, generated_at = Sys.time()) {
  roots <- c("tables", "plots", "texts", "text", "narratives")
  artifacts <- list()
  order <- 1L
  used_ids <- character()

  for (root in roots) {
    flattened <- .autoquant_eda_flatten(autoquant_result[[root]], root)
    for (name in names(flattened)) {
      value <- flattened[[name]]
      artifact_type <- .autoquant_eda_artifact_type(value, root)
      if (is.null(artifact_type)) {
        next
      }

      base_id <- paste("aq_eda", module_run_id, .autoquant_eda_slug(name), sep = "_")
      artifact_id <- base_id
      suffix <- 2L
      while (artifact_id %in% used_ids) {
        artifact_id <- paste0(base_id, "_", suffix)
        suffix <- suffix + 1L
      }
      used_ids <- c(used_ids, artifact_id)

      autoquant_section <- root
      section <- .autoquant_eda_section(strsplit(name, "_", fixed = TRUE)[[1]])
      label <- .autoquant_eda_label(sub(paste0("^", root, "_?"), "", name))
      if (tolower(label) %in% c("unnamed", "plot_1", "table_1", "artifact", "eda artifact")) {
        label <- paste(section, "Artifact", order)
      }
      object <- NULL
      content <- NULL
      if (identical(artifact_type, "table")) {
        object <- data.table::as.data.table(value)
      } else if (identical(artifact_type, "text")) {
        content <- paste(value, collapse = "\n\n")
      } else {
        object <- value
      }

      artifacts[[artifact_id]] <- create_artifact(
        artifact_id = artifact_id,
        artifact_type = artifact_type,
        label = label,
        source_module = "autoquant_eda",
        object = object,
        content = content,
        config = config,
        code = .autoquant_eda_code(config),
        metadata = module_artifact_metadata(
          module_id = "autoquant_eda",
          module_run_id = module_run_id,
          source_module = "autoquant_eda",
          original_name = name,
          original_section = autoquant_section,
          normalized_section = section,
          artifact_index = order,
          generated_at = generated_at,
          extra = list(
            data_name = config$DataName %||% NULL,
            autoquant_section = autoquant_section,
            section = section,
            selected_variables = .autoquant_eda_selected_variables(config),
            theme = config$Theme %||% "light"
          )
        ),
        section = section,
        order = order,
        status = "ready"
      )
      order <- order + 1L
    }
  }

  artifacts
}

.autoquant_eda_plan_section <- function(section) {
  text <- tolower(section)
  if (grepl("data description|overview", text)) return("Data Overview")
  if (grepl("missing", text)) return("Missingness")
  if (grepl("univariate", text)) return("Univariate Analysis")
  if (grepl("correlation", text)) return("Correlation Diagnostics")
  if (grepl("trend", text)) return("Trend Analysis")
  if (grepl("target", text)) return("Target Analysis")
  if (grepl("drift", text)) return("Drift Diagnostics")
  if (grepl("risk|leakage|flag", text)) return("Risk / Leakage Flags")
  "Appendix"
}

.autoquant_eda_section_id <- function(title) {
  gsub("[^a-z0-9]+", "_", tolower(title))
}

.autoquant_eda_plan_section_limits <- function(plan_type) {
  switch(
    plan_type,
    recommended = c(
      "Data Overview" = 3L,
      "Missingness" = 3L,
      "Univariate Analysis" = 8L,
      "Correlation Diagnostics" = 6L,
      "Trend Analysis" = 5L,
      "Target Analysis" = 5L,
      "Drift Diagnostics" = 4L,
      "Risk / Leakage Flags" = 4L,
      "Appendix" = 2L
    ),
    diagnostics = c(
      "Correlation Diagnostics" = 8L,
      "Trend Analysis" = 5L,
      "Target Analysis" = 6L,
      "Drift Diagnostics" = 6L,
      "Risk / Leakage Flags" = 6L
    ),
    integer()
  )
}

.autoquant_eda_select_plan_rows <- function(summary, plan_type) {
  if (identical(plan_type, "full")) {
    return(summary)
  }

  limits <- .autoquant_eda_plan_section_limits(plan_type)
  if (!length(limits)) {
    return(summary[0])
  }

  selected <- lapply(names(limits), function(section_title) {
    rows <- summary[plan_section == section_title][order(order, artifact_id)]
    if (!nrow(rows)) {
      return(rows)
    }

    utils::head(rows, limits[[section_title]])
  })

  data.table::rbindlist(selected, use.names = TRUE, fill = TRUE)
}

.autoquant_eda_create_plan <- function(summary, plan_type, module_run_id, config, section_order) {
  selected_summary <- .autoquant_eda_select_plan_rows(summary, plan_type)
  if (!nrow(selected_summary)) {
    return(NULL)
  }

  plan_labels <- c(
    recommended = "Recommended EDA Report",
    full = "Full EDA Report",
    diagnostics = "Diagnostics Only"
  )
  plan_descriptions <- c(
    recommended = "Balanced curated AutoQuant EDA report plan grouped by recommended report sections.",
    full = "Complete AutoQuant EDA report plan containing every generated artifact.",
    diagnostics = "Focused AutoQuant EDA diagnostics plan for correlation, trend, target, drift, and risk artifacts."
  )

  sections <- list()
  for (section_title in section_order) {
    section_rows <- selected_summary[plan_section == section_title][order(order, artifact_id)]
    if (!nrow(section_rows)) {
      next
    }

    sections[[.autoquant_eda_section_id(section_title)]] <- create_report_plan_section(
      section_id = .autoquant_eda_section_id(section_title),
      title = section_title,
      description = paste(plan_labels[[plan_type]], "-", section_title),
      artifact_ids = section_rows$artifact_id,
      order = length(sections) + 1L
    )
  }

  artifact_ids <- unlist(lapply(sections, function(section) section$artifact_ids), use.names = FALSE)
  create_report_plan(
    plan_id = paste(module_run_id, plan_type, sep = "_"),
    label = plan_labels[[plan_type]],
    source_module = "autoquant_eda",
    description = plan_descriptions[[plan_type]],
    layout_type = "sections",
    cols = 2L,
    sections = sections,
    artifact_ids = artifact_ids,
    rationale = paste("AutoQuant EDA", plan_type, "plan generated from standard artifact sections."),
    metadata = list(
      module_id = "autoquant_eda",
      module_run_id = module_run_id,
      data_name = config$DataName %||% NULL,
      plan_type = plan_type
    ),
    status = "recommended"
  )
}

build_autoquant_eda_report_plans <- function(artifacts, config = list(), module_run_id = NULL) {
  if (is.null(artifacts) || !length(artifacts)) {
    return(list())
  }

  module_run_id <- module_run_id %||% .autoquant_eda_run_id()
  summary <- artifact_summary(artifacts)
  summary[, plan_section := vapply(section, .autoquant_eda_plan_section, character(1))]
  section_order <- c(
    "Data Overview",
    "Missingness",
    "Univariate Analysis",
    "Correlation Diagnostics",
    "Trend Analysis",
    "Target Analysis",
    "Drift Diagnostics",
    "Risk / Leakage Flags",
    "Appendix"
  )

  plans <- list(
    recommended = .autoquant_eda_create_plan(summary, "recommended", module_run_id, config, section_order),
    full = .autoquant_eda_create_plan(summary, "full", module_run_id, config, section_order),
    diagnostics = .autoquant_eda_create_plan(summary, "diagnostics", module_run_id, config, section_order)
  )
  plans <- Filter(Negate(is.null), plans)
  names(plans) <- vapply(plans, function(plan) plan$plan_id, character(1))
  plans
}

run_autoquant_eda_module <- function(data, config) {
  validation <- validate_autoquant_eda_config(data, config)
  if (!identical(validation$status, "success")) {
    return(validation)
  }

  trend_preflight <- .autoquant_eda_grouped_trend_preflight(data, config)
  config <- trend_preflight$config
  preflight_warnings <- trend_preflight$warnings

  generated_at <- Sys.time()
  module_run_id <- .autoquant_eda_run_id(generated_at)

  result <- tryCatch(
    do.call(AutoQuant::generate_eda_artifacts, .autoquant_eda_call_args(data, config)),
    error = function(e) {
      service_result(
        status = "error",
        errors = paste("AutoQuant EDA failed:", conditionMessage(e)),
        diagnostics = list(condition = e),
        metadata = list(
          error_code = "RUNTIME_ERROR",
          module_id = "autoquant_eda",
          module_run_id = module_run_id,
          generated_at = generated_at,
          run_timestamp = generated_at
        )
      )
    }
  )

  if (is.list(result) && identical(result$status, "error")) {
    return(result)
  }

  artifacts <- normalize_autoquant_eda_artifacts(
    result,
    config,
    module_run_id = module_run_id,
    generated_at = generated_at
  )
  plans <- build_autoquant_eda_report_plans(artifacts, config, module_run_id = module_run_id)
  counts <- module_artifact_counts(artifacts)

  service_result(
    status = "success",
    value = result,
    artifacts = artifacts,
    messages = sprintf(
      "Generated %s EDA artifacts: %s plots, %s tables, %s text blocks. Created %s report plan(s).",
      counts$artifact_count,
      counts$plot_count,
      counts$table_count,
      counts$text_count,
      length(plans)
    ),
    warnings = preflight_warnings,
    metadata = module_run_metadata(
      module_id = "autoquant_eda",
      module_run_id = module_run_id,
      data_name = config$DataName %||% NULL,
      generated_at = generated_at,
      source_function = "generate_eda_artifacts",
      configured_inputs = list(
        selected_variables = .autoquant_eda_selected_variables(config),
        target_variable = config$TargetVar %||% NULL,
        theme = config$Theme %||% "light"
      ),
      artifacts = artifacts,
      report_plans = plans,
      extra = list(
        selected_variables = .autoquant_eda_selected_variables(config),
        target_variable = config$TargetVar %||% NULL,
        theme = config$Theme %||% "light"
      )
    ),
    code = .autoquant_eda_code(config)
  )
}

qa_autoquant_eda_integration <- function(data = NULL, config = NULL) {
  if (!autoquant_eda_available()) {
    return(data.table::data.table(
      check = "dependency",
      status = "warning",
      message = "AutoQuant::generate_eda_artifacts() is not available."
    ))
  }

  if (is.null(data)) {
    sample_path <- file.path("inst", "sample_data", "app_qa_transactional.csv")
    if (!file.exists(sample_path)) {
      return(data.table::data.table(
        check = "sample_data",
        status = "error",
        message = paste("Sample data was not found:", sample_path)
      ))
    }
    data <- data.table::fread(sample_path)
  }

  if (is.null(config)) {
    choices <- names(data)
    numeric_choices <- names(data)[vapply(data, is.numeric, logical(1))]
    config <- list(
      DataName = "app_qa_transactional",
      UnivariateVars = intersect(c("Spend", "Revenue", "Clicks", "Channel", "Category"), choices),
      CorrVars = intersect(c("Spend", "Revenue", "Clicks"), numeric_choices),
      TrendVars = intersect("Revenue", numeric_choices),
      TrendDateVar = if ("Date" %in% choices) "Date" else NULL,
      TrendGroupVar = if ("Channel" %in% choices) "Channel" else NULL,
      Theme = "light"
    )
  }

  result <- run_autoquant_eda_module(data, config)
  if (!identical(result$status, "success")) {
    return(data.table::data.table(
      check = "run_module",
      status = result$status,
      message = paste(c(result$messages, result$warnings, result$errors), collapse = " ")
    ))
  }

  artifacts <- result$artifacts
  plans <- result$metadata$report_plans %||% list()
  artifact_summary_result <- artifact_summary(artifacts)
  plan_summary_result <- report_plan_summary(plans)

  base_checks <- data.table::data.table(
    check = c(
      "run_module",
      "artifacts_returned",
      "report_plans_returned",
      "artifact_labels",
      "artifact_sections",
      "artifact_summary",
      "report_plan_summary"
    ),
    status = c(
      result$status,
      if (length(artifacts)) "success" else "error",
      if (length(plans)) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$label, character(1))))) "success" else "error",
      if (all(nzchar(vapply(artifacts, function(artifact) artifact$section, character(1))))) "success" else "error",
      if (nrow(artifact_summary_result) == length(artifacts)) "success" else "error",
      if (nrow(plan_summary_result) == length(plans)) "success" else "error"
    ),
    message = c(
      result$messages,
      paste("Artifacts:", length(artifacts)),
      paste("Report plans:", length(plans)),
      "All artifact labels are non-empty.",
      "All artifact sections are non-empty.",
      paste("Artifact summary rows:", nrow(artifact_summary_result)),
      paste("Report plan summary rows:", nrow(plan_summary_result))
    )
  )
  data.table::rbindlist(
    list(base_checks, module_result_convention_checks(result, "aq_eda_")),
    use.names = TRUE,
    fill = TRUE
  )
}
