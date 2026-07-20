plot_contract_version <- "0.1.0"

plot_contract_aliases <- function() {
  c(
    theme = "Theme",
    auto_aggregate = "PreAgg",
    AutoAggregate = "PreAgg",
    pre_agg = "PreAgg",
    preagg = "PreAgg",
    aggregation_method = "AggMethod",
    agg_method = "AggMethod",
    title = "title.text",
    title_text = "title.text",
    subtitle = "title.subtext",
    title_subtext = "title.subtext",
    x_axis = "XVar",
    x_var = "XVar",
    x = "XVar",
    y_axis = "YVar",
    y_var = "YVar",
    y = "YVar",
    z_var = "ZVar",
    z = "ZVar",
    group = "GroupVar",
    group_var = "GroupVar",
    color = "GroupVar",
    corr_vars = "CorrVars",
    correlation_columns = "CorrVars",
    x_axis_title = "xAxis.title",
    y_axis_title = "yAxis.title",
    x_axis_rotate = "xAxis.axisLabel.rotate",
    show_labels = "ShowLabels",
    mouse_scroll = "MouseScroll",
    legend_show = "legend.show"
  )
}

plot_contract_semantic_fields <- function() {
  c(
    "id", "object_id", "object_type", "name", "label", "caption",
    "description", "purpose", "finding", "finding_id", "finding_ids",
    "recommendation", "recommendation_id", "recommendation_ids",
    "evidence", "evidence_id", "evidence_ids", "provenance",
    "provenance_diagnostics", "metadata", "tags", "domain_memory",
    "knowledge_synthesis", "claim", "claim_id", "confidence",
    "importance", "quality_status"
  )
}

plot_contract_composition_fields <- function() {
  c(
    "visual_document", "document", "objects", "selected_object",
    "selected_object_id", "layout", "position", "size", "width",
    "height", "x", "y", "z_index", "z_order", "group_id",
    "responsive", "constraints", "inspector", "layers", "children",
    "parent_id", "canvas", "renderer", "render_target"
  )
}

plot_contract_service_fields <- function() {
  c(
    "plot_type", "mode", "status", "fallback_status", "runtime_fallback",
    "export_fallback", "source_artifact", "source_artifact_id",
    "artifact_id", "report_contract_id", "tool_id", "component_id",
    "created_at", "updated_at", "contract_version"
  )
}

plot_contract_quarantined_fields <- function() {
  unique(c(
    plot_contract_semantic_fields(),
    plot_contract_composition_fields(),
    plot_contract_service_fields()
  ))
}

plot_contract_normalize_name <- function(name) {
  aliases <- plot_contract_aliases()
  mapped <- unname(aliases[name])
  if (length(mapped) && !is.na(mapped) && nzchar(mapped)) {
    return(mapped)
  }

  name
}

plot_contract_registry_fields <- function(plot_type) {
  spec <- plot_spec(plot_type)
  options <- vapply(spec$options, function(option_name) {
    if (identical(option_name, "AutoAggregate")) {
      return("PreAgg")
    }
    if (identical(option_name, "AggMethod")) {
      return("AggMethod")
    }
    option_name
  }, character(1))

  unique(c(spec$mappings, spec$optional_mappings, options))
}

resolve_plot_contract <- function(plot_type) {
  if (is.null(plot_type) || !nzchar(plot_type) || !plot_type %in% plot_types) {
    stop("Unknown plot type: ", plot_type %||% "<missing>", call. = FALSE)
  }
  if (!requireNamespace("AutoPlots", quietly = TRUE)) {
    stop("AutoPlots is required for Visual Studio plot rendering.", call. = FALSE)
  }
  if (!exists(plot_type, envir = asNamespace("AutoPlots"), inherits = FALSE)) {
    stop("AutoPlots::", plot_type, "() is unavailable. Install the current GitHub version of AutoPlots.", call. = FALSE)
  }

  plot_fun <- getExportedValue("AutoPlots", plot_type)
  formal_names <- names(formals(plot_fun))
  spec <- plot_spec(plot_type)
  registry_fields <- plot_contract_registry_fields(plot_type)
  required_formals <- formal_names[vapply(formals(plot_fun), identical, logical(1), quote(expr = ))]
  required_fields <- unique(c("dt", spec$mappings, required_formals))

  list(
    version = plot_contract_version,
    plot_type = plot_type,
    function_name = paste0("AutoPlots::", plot_type),
    function_object = plot_fun,
    function_environment = environmentName(environment(plot_fun)),
    formal_arguments = formal_names,
    supports_dots = "..." %in% formal_names,
    registry_fields = registry_fields,
    required_fields = required_fields,
    package_version = as.character(utils::packageVersion("AutoPlots")),
    package_path = find.package("AutoPlots")
  )
}

plot_contract_signature <- function(plot_type, args, contract) {
  paste(
    plot_contract_version,
    plot_type,
    paste(sort(names(args)), collapse = "|"),
    contract$package_version,
    sep = "::"
  )
}

compile_plot_arg_list <- function(plot_type, raw_args, require_data = TRUE) {
  contract <- resolve_plot_contract(plot_type)
  raw_args <- raw_args %||% list()
  accepted <- list()
  aliases <- list()
  semantic_removed <- character()
  composition_removed <- character()
  service_removed <- character()
  unsupported <- character()
  warnings <- character()
  errors <- character()
  quarantined <- plot_contract_quarantined_fields()

  for (arg_name in names(raw_args)) {
    value <- raw_args[[arg_name]]
    if (is_empty_arg(value)) {
      next
    }

    normalized_name <- plot_contract_normalize_name(arg_name)
    if (!identical(normalized_name, arg_name)) {
      aliases[[arg_name]] <- normalized_name
    }

    if (normalized_name %in% contract$formal_arguments) {
      accepted[[normalized_name]] <- value
      next
    }

    if (normalized_name %in% plot_contract_semantic_fields()) {
      semantic_removed <- c(semantic_removed, normalized_name)
      next
    }
    if (normalized_name %in% plot_contract_composition_fields()) {
      composition_removed <- c(composition_removed, normalized_name)
      next
    }
    if (normalized_name %in% plot_contract_service_fields()) {
      service_removed <- c(service_removed, normalized_name)
      next
    }
    if (arg_name %in% quarantined) {
      semantic_removed <- c(semantic_removed, arg_name)
      next
    }

    unsupported <- c(unsupported, arg_name)
  }

  if (length(unsupported)) {
    warnings <- c(
      warnings,
      paste0("Unsupported plot arguments rejected: ", paste(unique(unsupported), collapse = ", "))
    )
  }

  required_fields <- contract$required_fields
  if (!isTRUE(require_data)) {
    required_fields <- setdiff(required_fields, "dt")
  }
  missing_required <- required_fields[!required_fields %in% names(accepted)]
  if (length(missing_required)) {
    errors <- c(
      errors,
      paste0("Required plot arguments are missing: ", paste(unique(missing_required), collapse = ", "))
    )
  }

  list(
    status = if (length(errors)) "error" else "success",
    contract_version = contract$version,
    plot_type = plot_type,
    resolved_function = contract$function_object,
    function_name = contract$function_name,
    package_version = contract$package_version,
    package_path = contract$package_path,
    function_environment = contract$function_environment,
    accepted_arguments = accepted,
    accepted_argument_names = names(accepted),
    semantic_fields_removed = unique(semantic_removed),
    composition_fields_removed = unique(composition_removed),
    service_fields_removed = unique(service_removed),
    aliases_applied = aliases,
    unsupported_fields_rejected = unique(unsupported),
    warnings = warnings,
    errors = errors,
    deterministic_signature = plot_contract_signature(plot_type, accepted, contract),
    contract = contract
  )
}

plot_contract_error_message <- function(compiled) {
  paste(
    c(
      paste0("Plot contract validation failed for ", compiled$function_name, "."),
      compiled$errors,
      if (length(compiled$unsupported_fields_rejected)) {
        paste0(
          "Rejected unsupported fields: ",
          paste(compiled$unsupported_fields_rejected, collapse = ", ")
        )
      }
    ),
    collapse = " "
  )
}

invoke_registered_plot <- function(compiled) {
  if (!identical(compiled$status, "success")) {
    stop(plot_contract_error_message(compiled), call. = FALSE)
  }

  tryCatch(
    do.call(compiled$resolved_function, compiled$accepted_arguments),
    error = function(error) {
      stop(
        paste0(
          "AutoPlots invocation failed for ", compiled$function_name,
          " using contract ", compiled$contract_version,
          ". Arguments: ", paste(names(compiled$accepted_arguments), collapse = ", "),
          ". Error: ", conditionMessage(error)
        ),
        call. = FALSE
      )
    }
  )
}

plot_contract_demo_data <- function() {
  data.frame(
    id = seq_len(36),
    event_date = seq.Date(as.Date("2026-01-01"), by = "day", length.out = 36),
    category = rep(c("Alpha", "Beta", "Gamma"), length.out = 36),
    segment = rep(c("North", "South"), each = 18),
    value = round(20 + seq_len(36) * 0.8 + sin(seq_len(36) / 2) * 4, 2),
    value2 = round(12 + seq_len(36) * 0.6 + cos(seq_len(36) / 3) * 3, 2),
    stringsAsFactors = FALSE
  )
}

plot_contract_demo_config <- function(plot_type) {
  mappings <- switch(
    plot_type,
    Area = list(XVar = "event_date", YVar = "value", GroupVar = NULL),
    Line = list(XVar = "event_date", YVar = "value", GroupVar = NULL),
    Bar = list(XVar = "category", YVar = "value", GroupVar = "segment"),
    Scatter = list(XVar = "value", YVar = "value2", GroupVar = "segment"),
    Histogram = list(XVar = "value", GroupVar = "segment"),
    Density = list(XVar = "value", GroupVar = "segment"),
    Pie = list(XVar = "category", YVar = "value", GroupVar = NULL),
    Donut = list(XVar = "category", YVar = "value", GroupVar = NULL),
    HeatMap = list(XVar = "category", YVar = "segment", ZVar = "value"),
    CorrMatrix = list(CorrVars = c("id", "value", "value2")),
    list(XVar = "event_date", YVar = "value")
  )

  list(
    plot_type = plot_type,
    mappings = mappings,
    options = list(
      Theme = "dark",
      AutoAggregate = "raw",
      AggMethod = "mean",
      `title.text` = paste(plot_type_label(plot_type), "Contract Check"),
      `title.subtext` = "",
      ShowLabels = FALSE,
      MouseScroll = FALSE,
      `legend.show` = TRUE,
      `xAxis.title` = "",
      `yAxis.title` = "",
      `xAxis.axisLabel.rotate` = 0
    ),
    visual_document = list(
      id = paste0("qa_visual_document_", tolower(plot_type)),
      objects = list(),
      layout = list(width = 1200, height = 700),
      provenance = list(source = "qa")
    )
  )
}

plot_contract_qa_row <- function(check, status = "success", message = "") {
  data.frame(
    check = check,
    status = status,
    message = message,
    stringsAsFactors = FALSE
  )
}

plot_contract_qa_try <- function(check, expr) {
  tryCatch(
    {
      result <- force(expr)
      if (isTRUE(result)) {
        plot_contract_qa_row(check)
      } else {
        plot_contract_qa_row(check, "error", as.character(result))
      }
    },
    error = function(error) {
      plot_contract_qa_row(check, "error", conditionMessage(error))
    }
  )
}

plot_supported_option_names <- function(plot_type) {
  spec <- plot_spec(plot_type)
  contract <- resolve_plot_contract(plot_type)
  spec$options[vapply(spec$options, function(option_name) {
    canonical <- if (identical(option_name, "AutoAggregate")) {
      "PreAgg"
    } else if (identical(option_name, "AggMethod")) {
      "AggMethod"
    } else {
      option_name
    }

    canonical %in% contract$formal_arguments
  }, logical(1))]
}

qa_plot_contract_parity <- function() {
  data <- plot_contract_demo_data()
  rows <- list()

  for (plot_type in plot_types) {
    rows[[length(rows) + 1L]] <- plot_contract_qa_try(
      paste0(plot_type, " resolves to current AutoPlots export"),
      {
        contract <- resolve_plot_contract(plot_type)
        identical(contract$function_name, paste0("AutoPlots::", plot_type)) &&
          !grepl("^AutoPlots::Plot\\.", contract$function_name)
      }
    )

    rows[[length(rows) + 1L]] <- plot_contract_qa_try(
      paste0(plot_type, " registry fields are supported by AutoPlots"),
      {
        contract <- resolve_plot_contract(plot_type)
        unsupported <- setdiff(contract$registry_fields, contract$formal_arguments)
        if (!length(unsupported)) TRUE else paste("Unsupported:", paste(unsupported, collapse = ", "))
      }
    )

    rows[[length(rows) + 1L]] <- plot_contract_qa_try(
      paste0(plot_type, " strips visual document metadata before AutoPlots"),
      {
        config <- plot_contract_demo_config(plot_type)
        raw_args <- build_plot_args_from_config(config, data = data, include_data = TRUE)
        raw_args$visual_document <- config$visual_document
        raw_args$metadata <- list(author = "qa")
        raw_args$layout <- list(columns = 2)
        raw_args$tool_id <- "qa.plot.render"
        raw_args$unsupported_runtime_field <- "must-not-cross-boundary"
        compiled <- compile_plot_arg_list(plot_type, raw_args, require_data = TRUE)

        accepted_supported <- all(compiled$accepted_argument_names %in% compiled$contract$formal_arguments)
        semantic_removed <- all(c("metadata", "visual_document") %in% c(compiled$semantic_fields_removed, compiled$composition_fields_removed))
        service_removed <- "tool_id" %in% compiled$service_fields_removed
        unsupported_rejected <- "unsupported_runtime_field" %in% compiled$unsupported_fields_rejected
        no_leaks <- !any(c(
          "visual_document", "metadata", "layout", "tool_id", "unsupported_runtime_field"
        ) %in% compiled$accepted_argument_names)

        if (identical(compiled$status, "success") &&
            accepted_supported &&
            semantic_removed &&
            service_removed &&
            unsupported_rejected &&
            no_leaks) {
          TRUE
        } else {
          paste(
            "status=", compiled$status,
            "accepted_supported=", accepted_supported,
            "semantic_removed=", semantic_removed,
            "service_removed=", service_removed,
            "unsupported_rejected=", unsupported_rejected,
            "no_leaks=", no_leaks
          )
        }
      }
    )

    rows[[length(rows) + 1L]] <- plot_contract_qa_try(
      paste0(plot_type, " invokes only compiled AutoPlots arguments"),
      {
        config <- plot_contract_demo_config(plot_type)
        args <- build_plot_args_from_config(config, data = data, include_data = TRUE)
        compiled <- compile_plot_arg_list(plot_type, args, require_data = TRUE)
        widget <- apply_autoplots_full_grid(invoke_registered_plot(compiled))
        inherits(widget, "htmlwidget")
      }
    )
  }

  do.call(rbind, rows)
}

qa_plot_runtime_integrity <- function() {
  data <- plot_contract_demo_data()
  rows <- list(qa_plot_contract_parity())

  rows[[length(rows) + 1L]] <- plot_contract_qa_try(
    "missing required mappings fail before AutoPlots invocation",
    {
      config <- plot_contract_demo_config("Area")
      config$mappings$XVar <- NULL
      args <- build_plot_args_from_config(config, data = data, include_data = TRUE)
      compiled <- compile_plot_arg_list("Area", args, require_data = TRUE)
      identical(compiled$status, "error") &&
        any(grepl("Required plot arguments are missing", compiled$errors, fixed = TRUE))
    }
  )

  rows[[length(rows) + 1L]] <- plot_contract_qa_try(
    "alias normalization preserves canonical AutoPlots argument names",
    {
      args <- list(
        dt = data,
        x_var = "event_date",
        y_var = "value",
        theme = "dark",
        auto_aggregate = FALSE
      )
      compiled <- compile_plot_arg_list("Area", args, require_data = TRUE)
      all(c("XVar", "YVar", "Theme", "PreAgg") %in% compiled$accepted_argument_names) &&
        !any(c("x_var", "y_var", "theme", "auto_aggregate") %in% compiled$accepted_argument_names)
    }
  )

  rows[[length(rows) + 1L]] <- plot_contract_qa_try(
    "generated plot code contains no semantic or composition leakage",
    {
      config <- plot_contract_demo_config("Line")
      code <- build_autoplots_assignment_code("p1", config)
      !grepl("visual_document|metadata|layout|provenance|unsupported_runtime_field", code)
    }
  )

  do.call(rbind, rows)
}

build_plot_args <- function(
  plot_type,
  data,
  input,
  include_data = TRUE
) {
  args <- list()
  if (include_data) {
    args$dt <- data
  }

  for (mapping in active_mappings(plot_type)) {
    args[[mapping]] <- mapping_value(input, mapping)
  }

  for (option_name in plot_spec(plot_type)$options) {
    args <- add_option_arg(args, option_name, option_value(input, option_name))
  }

  args <- apply_inferred_plot_title(plot_type, args)

  args[!vapply(args, is.null, logical(1))]
}

plot_title_term <- function(value) {
  value <- selected_value(value)
  if (is.null(value) || !length(value)) {
    return(NULL)
  }

  text <- as.character(value[[1]])
  text <- trimws(gsub("\\s+", " ", gsub("[_.]+", " ", text)))
  if (!nzchar(text)) {
    return(NULL)
  }

  words <- strsplit(text, " ", fixed = TRUE)[[1]]
  words <- vapply(words, function(word) {
    if (grepl("[[:upper:]]", word)) {
      return(word)
    }

    tools::toTitleCase(tolower(word))
  }, character(1))

  paste(words, collapse = " ")
}

infer_plot_title <- function(plot_type, args) {
  x <- plot_title_term(args$XVar)
  y <- plot_title_term(args$YVar)
  z <- plot_title_term(args$ZVar)
  group <- plot_title_term(args$GroupVar)

  if (identical(plot_type, "CorrMatrix")) {
    return("Correlation Matrix")
  }

  if (plot_type %in% c("Histogram", "Density")) {
    title <- if (!is.null(x)) paste("Distribution of", x) else plot_type_label(plot_type)
    if (!is.null(group)) {
      title <- paste(title, "by", group)
    }
    return(title)
  }

  if (identical(plot_type, "Scatter")) {
    if (!is.null(x) && !is.null(y)) {
      title <- paste(y, "vs", x)
      if (!is.null(group)) {
        title <- paste(title, "by", group)
      }
      return(title)
    }
  }

  if (identical(plot_type, "HeatMap")) {
    if (!is.null(x) && !is.null(y) && !is.null(z)) {
      return(paste(z, "by", x, "and", y))
    }
  }

  if (!is.null(x) && !is.null(y)) {
    title <- paste(y, "by", x)
    if (!is.null(group)) {
      title <- paste(title, "and", group)
    }
    return(title)
  }

  if (!is.null(x)) {
    return(paste(plot_type_label(plot_type), "of", x))
  }

  plot_type_label(plot_type)
}

apply_inferred_plot_title <- function(plot_type, args) {
  if (!"title.text" %in% plot_spec(plot_type)$options) {
    return(args)
  }

  if (!is_empty_arg(args[["title.text"]])) {
    return(args)
  }

  args[["title.text"]] <- infer_plot_title(plot_type, args)
  args
}

build_autoplots_call <- function(plot_type, data, input) {
  args <- build_plot_args(plot_type, data, input)
  compiled <- compile_plot_arg_list(plot_type, args, require_data = TRUE)
  apply_autoplots_full_grid(invoke_registered_plot(compiled))
}

plot_service_output_id <- function(id, prefix = "plot") {
  paste0(prefix, "_", gsub("[^A-Za-z0-9_]", "_", id %||% "visual"))
}

render_plot_service_widget <- function(widget, output, session, output_id, height = "520px") {
  if (is.null(widget)) {
    return(NULL)
  }
  if (!inherits(widget, "htmlwidget")) {
    return(htmltools::tagList(widget))
  }
  if (is.null(output) || is.null(session)) {
    return(htmltools::tagList(widget))
  }
  if (!requireNamespace("echarts4r", quietly = TRUE)) {
    return(htmltools::tagList(widget))
  }

  local_widget <- widget
  output[[output_id]] <- echarts4r::renderEcharts4r({
    local_widget
  })
  echarts4r::echarts4rOutput(session$ns(output_id), width = "100%", height = height)
}

snapshot_plot_config <- function(plot_type, input, mapping_values = list()) {
  spec <- plot_spec(plot_type)

  mappings <- list()
  for (mapping in active_mappings(plot_type)) {
    value <- mapping_value(input, mapping)
    if (is_empty_arg(value)) {
      remembered_value <- mapping_values[[mapping]]
      if (!is_empty_arg(remembered_value)) {
        value <- remembered_value
      }
    }

    mappings[[mapping]] <- value
  }

  options <- list()
  for (option_name in spec$options) {
    options[[option_name]] <- option_value(input, option_name)
  }

  list(
    plot_type = plot_type,
    mappings = mappings,
    options = options
  )
}

build_plot_args_from_config <- function(config, data, include_data = TRUE) {
  args <- list()

  if (include_data) {
    args$dt <- data
  }

  for (name in names(config$mappings)) {
    args[[name]] <- config$mappings[[name]]
  }

  for (name in names(config$options)) {
    args <- add_option_arg(args, name, config$options[[name]])
  }

  args <- apply_inferred_plot_title(config$plot_type, args)

  args[!vapply(args, is_empty_arg, logical(1))]
}

build_autoplots_call_from_config <- function(config, data) {
  args <- build_plot_args_from_config(config, data = data, include_data = TRUE)
  compiled <- compile_plot_arg_list(config$plot_type, args, require_data = TRUE)
  apply_autoplots_full_grid(invoke_registered_plot(compiled))
}

apply_autoplots_full_grid <- function(widget) {
  if (is.null(widget) || !inherits(widget, "htmlwidget")) {
    return(widget)
  }
  if (!requireNamespace("AutoPlots", quietly = TRUE)) {
    stop("AutoPlots is required to apply full-pane plot grid sizing.", call. = FALSE)
  }
  if (!exists("e_grid_full", envir = asNamespace("AutoPlots"), inherits = FALSE)) {
    stop("AutoPlots::e_grid_full() is unavailable. Install the current GitHub version of AutoPlots.", call. = FALSE)
  }

  AutoPlots::e_grid_full(
    widget,
    grid.left = 45,
    grid.right = 40,
    grid.top = 52,
    grid.bottom = 58,
    grid.containLabel = TRUE
  )
}

validate_plot_ready <- function(plot_type, data, input) {
  if (is.null(data)) {
    return("No data is available.")
  }

  spec <- plot_spec(plot_type)

  for (mapping in spec$mappings) {
    value <- mapping_value(input, mapping)

    if (is.null(value) || length(value) == 0L || any(value == "")) {
      return(paste0("Required mapping is missing: ", mapping))
    }

    if (identical(mapping, "CorrVars")) {
      missing_cols <- setdiff(value, names(data))
      if (length(missing_cols)) {
        return(paste0(
          "CorrVars contains columns not in data: ",
          paste(missing_cols, collapse = ", ")
        ))
      }
    } else if (!value %in% names(data)) {
      return(paste0(mapping, " column is not in data: ", value))
    }
  }

  TRUE
}

validate_plot_config_ready <- function(config, data) {
  if (is.null(data)) {
    return("No data is available.")
  }

  spec <- plot_spec(config$plot_type)

  for (mapping in spec$mappings) {
    value <- config$mappings[[mapping]]

    if (is.null(value) || length(value) == 0L || any(value == "")) {
      return(paste0("Required mapping is missing: ", mapping))
    }

    if (identical(mapping, "CorrVars")) {
      missing_cols <- setdiff(value, names(data))
      if (length(missing_cols)) {
        return(paste0(
          "CorrVars contains columns not in data: ",
          paste(missing_cols, collapse = ", ")
        ))
      }
    } else if (!value %in% names(data)) {
      return(paste0(mapping, " column is not in data: ", value))
    }
  }

  TRUE
}

arg_to_code <- function(name, value) {
  if (is.logical(value) || is.numeric(value)) {
    return(paste0(name, " = ", deparse(value, width.cutoff = 500L)))
  }

  paste0(name, " = ", r_string(value))
}

build_autoplots_code <- function(plot_type, input) {
  args <- build_plot_args(plot_type, data = NULL, input = input, include_data = FALSE)
  compiled <- compile_plot_arg_list(plot_type, args, require_data = FALSE)
  if (!identical(compiled$status, "success")) {
    stop(plot_contract_error_message(compiled), call. = FALSE)
  }
  args <- compiled$accepted_arguments
  arg_lines <- c(
    "dt = data",
    unlist(Map(arg_to_code, names(args), args), use.names = FALSE)
  )

  paste0(
    "library(AutoPlots)\n\n",
    "data <- data.table::fread(\"path/to/data.csv\")\n\n",
    "p1 <- AutoPlots::", plot_type, "(\n",
    "  ", paste(arg_lines, collapse = ",\n  "), "\n",
    ") |>\n",
    "  AutoPlots::e_grid_full(\n",
    "    grid.left = 45,\n",
    "    grid.right = 40,\n",
    "    grid.top = 52,\n",
    "    grid.bottom = 58,\n",
    "    grid.containLabel = TRUE\n",
    "  )\n\n",
    "p1"
  )
}

build_autoplots_assignment_code <- function(name, config) {
  args <- build_plot_args_from_config(config, data = NULL, include_data = FALSE)
  compiled <- compile_plot_arg_list(config$plot_type, args, require_data = FALSE)
  if (!identical(compiled$status, "success")) {
    stop(plot_contract_error_message(compiled), call. = FALSE)
  }
  args <- compiled$accepted_arguments
  arg_lines <- c(
    "dt = data",
    unlist(Map(arg_to_code, names(args), args), use.names = FALSE)
  )

  paste0(
    name, " <- AutoPlots::", config$plot_type, "(\n",
    "  ", paste(arg_lines, collapse = ",\n  "), "\n",
    ") |>\n",
    "  AutoPlots::e_grid_full(\n",
    "    grid.left = 45,\n",
    "    grid.right = 40,\n",
    "    grid.top = 52,\n",
    "    grid.bottom = 58,\n",
    "    grid.containLabel = TRUE\n",
    "  )"
  )
}

next_plot_name <- function(plot_names) {
  if (!length(plot_names)) {
    return("p1")
  }

  plot_ids <- suppressWarnings(as.integer(sub("^p", "", plot_names)))
  plot_ids <- plot_ids[!is.na(plot_ids)]
  if (!length(plot_ids)) {
    return("p1")
  }

  paste0("p", max(plot_ids) + 1L)
}

next_sort_order <- function(metadata) {
  if (!length(metadata)) {
    return(1L)
  }

  orders <- vapply(metadata, function(item) {
    if (is.null(item$sort_order)) {
      return(NA_integer_)
    }

    as.integer(item$sort_order)
  }, integer(1))
  orders <- orders[!is.na(orders)]
  if (!length(orders)) {
    return(1L)
  }

  max(orders) + 1L
}

plot_metadata <- function(plot_name, config, section_name = "Analysis", sort_order = 1L) {
  list(
    plot_name = plot_name,
    plot_type = config$plot_type,
    section_name = section_name,
    sort_order = as.integer(sort_order),
    visual_document = config$visual_document %||%
      visual_document_from_plot_config(config, plot_name = plot_name)
  )
}

ordered_plot_names_from_metadata <- function(metadata) {
  plot_names <- names(metadata)
  if (!length(plot_names)) {
    return(character())
  }

  orders <- vapply(metadata, function(item) {
    if (is.null(item$sort_order)) {
      return(NA_integer_)
    }

    as.integer(item$sort_order)
  }, integer(1))
  orders[is.na(orders)] <- seq_along(orders)[is.na(orders)]
  plot_names[order(orders, plot_names)]
}

section_plot_names_from_metadata <- function(metadata) {
  plot_names <- ordered_plot_names_from_metadata(metadata)
  sections <- list()

  for (plot_name in plot_names) {
    section_name <- metadata[[plot_name]]$section_name
    if (is.null(section_name) || !nzchar(section_name)) {
      section_name <- "Analysis"
    }

    sections[[section_name]] <- c(sections[[section_name]], plot_name)
  }

  sections
}

ordered_list_by_names <- function(items, item_names) {
  item_names <- item_names[item_names %in% names(items)]
  items[item_names]
}

build_saved_plots_code <- function(saved_code) {
  plot_names <- names(saved_code)
  if (!length(plot_names)) {
    return(paste0(
      "library(AutoPlots)\n\n",
      "data <- data.table::fread(\"path/to/data.csv\")\n\n",
      "list()"
    ))
  }

  paste0(
    "library(AutoPlots)\n\n",
    "data <- data.table::fread(\"path/to/data.csv\")\n\n",
    paste(unlist(saved_code, use.names = FALSE), collapse = "\n\n"),
    "\n\n",
    "list(", paste(plot_names, collapse = ", "), ")"
  )
}

plot_list_code <- function(plot_names) {
  if (!length(plot_names)) {
    return("list()")
  }

  paste0("list(", paste(plot_names, collapse = ", "), ")")
}

section_list_code <- function(section_plot_names) {
  section_names <- names(section_plot_names)
  if (!length(section_names)) {
    return("list()")
  }

  section_lines <- unlist(lapply(section_names, function(section_name) {
    paste0(
      "  ", r_string(section_name), " = ",
      plot_list_code(section_plot_names[[section_name]])
    )
  }), use.names = FALSE)

  paste0(
    "list(\n",
    paste(section_lines, collapse = ",\n"),
    "\n)"
  )
}

build_layout_code <- function(plot_names, section_plot_names = list(), layout_type = "Grid", cols = 2) {
  if (identical(layout_type, "Sections")) {
    return(paste0(
      "sections <- ", section_list_code(section_plot_names), "\n\n",
      "report <- AutoPlots::display_plots_sections(\n",
      "  sections = sections,\n",
      "  cols = ", cols, "\n",
      ")\n\n",
      "report"
    ))
  }

  paste0(
    "plots <- ", plot_list_code(plot_names), "\n\n",
    "report <- AutoPlots::display_plots_grid(\n",
    "  plots = plots,\n",
    "  cols = ", cols, "\n",
    ")\n\n",
    "report"
  )
}

build_export_code <- function(export_dir = "path/to/output", export_name = "autoplots_report") {
  paste0(
    "html_path <- file.path(", r_string(export_dir), ", ", r_string(paste0(tools::file_path_sans_ext(basename(export_name)), ".html")), ")\n",
    "if (inherits(report, \"htmlwidget\")) {\n",
    "  htmlwidgets::saveWidget(\n",
    "    widget = report,\n",
    "    file = html_path,\n",
    "    selfcontained = TRUE\n",
    "  )\n",
    "} else {\n",
    "  htmltools::save_html(\n",
    "    htmltools::browsable(report),\n",
    "    file = html_path,\n",
    "    libdir = paste0(", r_string(tools::file_path_sans_ext(basename(export_name))), ", \"_files\")\n",
    "  )\n",
    "}"
  )
}

build_report_code <- function(
  saved_code,
  section_plot_names = list(),
  layout_type = "Grid",
  cols = 2,
  export_dir = "path/to/output",
  export_name = "autoplots_report",
  data_path = "path/to/data.csv"
) {
  plot_names <- names(saved_code)
  assignment_code <- if (length(plot_names)) {
    paste(unlist(saved_code, use.names = FALSE), collapse = "\n\n")
  } else {
    ""
  }

  layout_code <- build_layout_code(
    plot_names = plot_names,
    section_plot_names = section_plot_names,
    layout_type = layout_type,
    cols = cols
  )

  paste0(
    "library(AutoPlots)\n\n",
    "data <- data.table::fread(", r_string(data_path), ")\n\n",
    if (nzchar(assignment_code)) paste0(assignment_code, "\n\n") else "",
    layout_code,
    "\n\n",
    build_export_code(export_dir = export_dir, export_name = export_name)
  )
}

write_report_code <- function(code, path, name) {
  export_dir <- selected_value(path)
  if (is.null(export_dir)) {
    stop("Export directory is required.", call. = FALSE)
  }

  export_name <- selected_value(name)
  if (is.null(export_name)) {
    stop("File name is required.", call. = FALSE)
  }

  if (!dir.exists(export_dir)) {
    dir.create(export_dir, recursive = TRUE, showWarnings = FALSE)
  }

  if (!dir.exists(export_dir)) {
    stop("Export directory could not be created.", call. = FALSE)
  }
  if (exists("storage_repo_root", mode = "function") &&
      exists("path_within_root", mode = "function") &&
      path_within_root(export_dir, storage_repo_root())) {
    stop("Export directory is inside the application repository and was blocked.", call. = FALSE)
  }

  output_path <- file.path(
    normalizePath(export_dir, winslash = "/", mustWork = TRUE),
    paste0(tools::file_path_sans_ext(basename(export_name)), ".R")
  )

  writeLines(code, con = output_path, useBytes = TRUE)
  normalizePath(output_path, winslash = "/", mustWork = TRUE)
}

