empty_choice <- function(label = "(none)") {
  stats::setNames("", label)
}

column_choices <- function(data, include_none = FALSE, label = "(none)") {
  if (is.null(data)) {
    return(empty_choice(label))
  }

  choices <- names(data)
  if (include_none) {
    return(c(empty_choice(label), choices))
  }

  choices
}

r_string <- function(value) {
  if (is.null(value) || identical(value, "")) {
    return("NULL")
  }

  deparse(value, width.cutoff = 500L)
}

default_value <- function(value, default) {
  if (is.null(value)) {
    return(default)
  }

  value
}

selected_value <- function(value) {
  if (is.null(value) || !length(value) || identical(value, "")) {
    return(NULL)
  }
  if (length(value) == 1L && is.atomic(value) && is.na(value)) {
    return(NULL)
  }
  if (is.character(value) && all(is.na(value) | !nzchar(value))) {
    return(NULL)
  }

  value
}

selected_vector <- function(value) {
  value <- selected_value(value)
  if (is.null(value)) {
    return(NULL)
  }

  value
}

is_empty_arg <- function(value) {
  is.null(value) || length(value) == 0L || (is.character(value) && any(value == ""))
}

logical_value <- function(value) {
  isTRUE(value)
}

numeric_or_null <- function(value) {
  if (is.null(value) || identical(value, "") || is.na(value)) {
    return(NULL)
  }

  as.numeric(value)
}

plot_spec <- function(plot_type) {
  plot_registry[[plot_type]]
}

mapping_input_id <- function(mapping) {
  paste0("mapping_", mapping)
}

mapping_value <- function(input, mapping) {
  value <- input[[mapping_input_id(mapping)]]
  if (identical(mapping, "CorrVars")) {
    value <- selected_vector(value)
    if (is.null(value) || length(value) == 0L) {
      return(NULL)
    }

    return(value)
  }

  selected_value(value)
}

active_mappings <- function(plot_type) {
  spec <- plot_spec(plot_type)
  c(spec$mappings, spec$optional_mappings)
}


required_app_packages <- function() {
  c("shiny", "AutoPlots", "AutoQuant", "data.table", "htmltools", "htmlwidgets", "openxlsx")
}

first_party_app_packages <- function() {
  c("AutoPlots", "AutoQuant", "AutoNLS", "Rodeo")
}

optional_app_packages <- function() {
  c(
    "AutoNLS",
    "Rodeo",
    "reactable",
    "jsonlite",
    "httr2",
    "httr",
    "curl",
    "mirai",
    "callr",
    "ps",
    "arrow",
    "commonmark",
    "base64enc",
    "png",
    "digest",
    "yaml",
    "chromote",
    "roxygen2",
    "testthat"
  )
}

local_first_party_package_paths <- function(root = getwd()) {
  package_names <- first_party_app_packages()
  parent <- normalizePath(file.path(root, ".."), winslash = "/", mustWork = FALSE)
  paths <- file.path(parent, package_names)
  stats::setNames(paths, package_names)
}

app_dependency_inventory <- function() {
  package_groups <- list(
    startup_required = required_app_packages(),
    full_analytics_optional = c("AutoNLS", "Rodeo"),
    tables_and_documents = c("reactable", "openxlsx", "commonmark"),
    genai_and_runtime = c("jsonlite", "httr2", "httr", "curl", "mirai", "callr", "ps"),
    data_and_artifacts = c("arrow", "base64enc", "png", "digest", "yaml", "chromote"),
    development_qa = c("roxygen2", "testthat")
  )

  rows <- lapply(names(package_groups), function(group) {
    packages <- package_groups[[group]]
    local_paths <- local_first_party_package_paths()
    data.table::data.table(
      group = group,
      package = packages,
      required_for_startup = packages %in% required_app_packages(),
      available = vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1)),
      local_repo_exists = packages %in% names(local_paths) & file.exists(unname(local_paths[packages]))
    )
  })

  data.table::rbindlist(rows, use.names = TRUE)
}

qa_app_dependency_capabilities <- function(require_optional = TRUE) {
  inventory <- app_dependency_inventory()
  required_missing <- inventory[inventory$required_for_startup == TRUE & inventory$available == FALSE]
  local_first_party_missing <- inventory[
    inventory$package %in% first_party_app_packages() &
      inventory$local_repo_exists == TRUE &
      inventory$available == FALSE
  ]
  optional_missing <- inventory[inventory$required_for_startup == FALSE & inventory$available == FALSE]

  data.table::data.table(
    check = c(
      "startup_dependencies_available",
      "local_first_party_packages_installed",
      "optional_capabilities_reported",
      "full_optional_capabilities_available"
    ),
    status = c(
      if (nrow(required_missing) == 0L) "success" else "error",
      if (nrow(local_first_party_missing) == 0L) "success" else "error",
      if (all(optional_app_packages() %in% inventory$package)) "success" else "error",
      if (!require_optional || nrow(optional_missing) == 0L) "success" else "warning"
    ),
    message = c(
      if (nrow(required_missing) == 0L) {
        "All startup dependencies are available in the active R library."
      } else {
        paste("Missing startup dependencies:", paste(unique(required_missing$package), collapse = ", "))
      },
      if (nrow(local_first_party_missing) == 0L) {
        "All local first-party ecosystem repositories are installed in the active R library."
      } else {
        paste("Local first-party repos exist but are not installed:", paste(unique(local_first_party_missing$package), collapse = ", "))
      },
      "Optional capabilities are explicitly inventoried instead of failing silently.",
      if (nrow(optional_missing) == 0L) {
        "All optional capability packages in the inventory are available."
      } else {
        paste("Optional packages unavailable:", paste(unique(optional_missing$package), collapse = ", "))
      }
    )
  )
}

check_app_dependencies <- function(packages = required_app_packages()) {
  installed <- vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
  missing <- names(installed)[!installed]

  if (length(missing)) {
    return(list(
      ok = FALSE,
      missing = missing,
      messages = c(
        "Missing required R packages:",
        paste0("- ", missing),
        "Install the missing packages, then run the app again."
      )
    ))
  }

  list(
    ok = TRUE,
    missing = character(),
    messages = "All required R packages are installed."
  )
}
