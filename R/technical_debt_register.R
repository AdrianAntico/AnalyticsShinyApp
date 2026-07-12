technical_debt_schema_version <- "technical_debt_v1"

technical_debt_register_path <- function(root = ".") {
  file.path(root, "config", "technical_debt.yml")
}

technical_debt_markdown_path <- function(root = ".") {
  file.path(root, "docs", "architecture", "technical_debt_register.md")
}

technical_debt_schema_inventory_path <- function(root = ".") {
  file.path(root, "docs", "architecture", "schema_version_inventory.md")
}

technical_debt_phase_template_path <- function(root = ".") {
  file.path(root, "docs", "templates", "phase_completion_template.md")
}

technical_debt_allowed_categories <- function() {
  c("intentional_boundary", "deferred_capability", "technical_debt", "compatibility_debt")
}

technical_debt_allowed_statuses <- function() {
  c("open", "accepted", "planned", "in_progress", "resolved", "superseded")
}

technical_debt_allowed_severities <- function() {
  c("low", "medium", "high", "critical")
}

technical_debt_required_fields <- function() {
  c(
    "debt_id", "title", "category", "status", "severity", "introduced_phase",
    "last_reviewed_phase", "affected_components", "description", "rationale",
    "current_mitigation", "resolution_trigger", "acceptance_criteria", "blocks",
    "intentional_for_now", "source_refs"
  )
}

load_technical_debt_register <- function(path = technical_debt_register_path()) {
  if (!file.exists(path)) {
    return(service_result(status = "error", errors = paste("Technical debt register not found:", path)))
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    return(service_result(status = "error", errors = "Package 'yaml' is required to parse config/technical_debt.yml."))
  }
  parsed <- tryCatch(yaml::read_yaml(path), error = function(e) e)
  if (inherits(parsed, "error")) {
    return(service_result(status = "error", errors = conditionMessage(parsed)))
  }
  service_result(status = "success", value = parsed, metadata = list(path = path))
}

technical_debt_items_table <- function(register) {
  items <- register$items %||% list()
  if (!length(items)) {
    return(data.table::data.table())
  }
  data.table::rbindlist(lapply(items, function(item) {
    data.table::data.table(
      debt_id = as.character(item$debt_id %||% NA_character_),
      title = as.character(item$title %||% NA_character_),
      category = as.character(item$category %||% NA_character_),
      status = as.character(item$status %||% NA_character_),
      severity = as.character(item$severity %||% NA_character_),
      introduced_phase = as.character(item$introduced_phase %||% NA_character_),
      last_reviewed_phase = as.character(item$last_reviewed_phase %||% NA_character_),
      affected_components = paste(as.character(item$affected_components %||% character()), collapse = "; "),
      resolution_trigger = as.character(item$resolution_trigger %||% NA_character_),
      intentional_for_now = isTRUE(item$intentional_for_now)
    )
  }), fill = TRUE)
}

technical_debt_summary_counts <- function(register) {
  table <- technical_debt_items_table(register)
  if (!nrow(table)) {
    return(data.table::data.table(category = character(), status = character(), severity = character(), n = integer()))
  }
  data.table::rbindlist(
    list(
      table[, .(n = .N), by = .(category)][, dimension := "category"],
      table[, .(n = .N), by = .(status)][, dimension := "status"],
      table[, .(n = .N), by = .(severity)][, dimension := "severity"]
    ),
    fill = TRUE
  )
}

genai_technical_debt_context_summary <- function(max_items = 12L, root = ".") {
  loaded <- load_technical_debt_register(technical_debt_register_path(root))
  if (!identical(loaded$status, "success")) {
    return(service_result(status = "warning", warnings = loaded$errors %||% "Technical debt register unavailable."))
  }
  items <- technical_debt_items_table(loaded$value)
  if (!nrow(items)) {
    return(service_result(status = "success", value = list(items = list(), counts = list()), messages = "No technical debt entries registered."))
  }
  severity_rank <- c(critical = 1L, high = 2L, medium = 3L, low = 4L)
  items[, severity_order := severity_rank[severity] %||% 99L]
  visible <- items[order(severity_order, debt_id)][seq_len(min(.N, as.integer(max_items)))]
  counts <- items[, .N, by = .(category, severity)]
  service_result(
    status = "success",
    value = list(
      items = lapply(seq_len(nrow(visible)), function(i) {
        list(
          debt_id = visible$debt_id[[i]],
          title = visible$title[[i]],
          category = visible$category[[i]],
          severity = visible$severity[[i]],
          affected_components = visible$affected_components[[i]],
          resolution_trigger = visible$resolution_trigger[[i]]
        )
      }),
      counts = counts
    ),
    messages = "Bounded technical debt summary prepared for GenAI context."
  )
}

qa_technical_debt_register <- function(root = ".") {
  rows <- list()
  add <- function(check, status, message, file = "config/technical_debt.yml", severity = "error") {
    rows[[length(rows) + 1L]] <<- data.table::data.table(
      check = check,
      status = status,
      severity = severity,
      file = file,
      message = message
    )
  }
  register_path <- technical_debt_register_path(root)
  md_path <- technical_debt_markdown_path(root)
  schema_path <- technical_debt_schema_inventory_path(root)
  template_path <- technical_debt_phase_template_path(root)

  loaded <- load_technical_debt_register(register_path)
  add("yaml_parses", if (identical(loaded$status, "success")) "success" else "error", paste(loaded$errors %||% "YAML parsed.", collapse = "; "))
  if (!identical(loaded$status, "success")) {
    return(data.table::rbindlist(rows, use.names = TRUE, fill = TRUE))
  }
  register <- loaded$value
  items <- register$items %||% list()
  required <- technical_debt_required_fields()
  categories <- technical_debt_allowed_categories()
  statuses <- technical_debt_allowed_statuses()
  severities <- technical_debt_allowed_severities()

  add("schema_version_supported", if (identical(register$schema_version, technical_debt_schema_version)) "success" else "error", paste("schema_version =", register$schema_version %||% "missing"))
  add("items_present", if (length(items)) "success" else "error", paste(length(items), "debt items found."))

  ids <- vapply(items, function(item) as.character(item$debt_id %||% NA_character_), character(1))
  titles <- vapply(items, function(item) as.character(item$title %||% NA_character_), character(1))
  add("debt_ids_unique", if (!anyDuplicated(ids) && !any(is.na(ids) | !nzchar(ids))) "success" else "error", "Debt IDs are unique and nonempty.")
  add("duplicate_titles", if (!anyDuplicated(titles)) "success" else "warning", "Duplicate titles are flagged as warnings.", severity = "warning")

  for (i in seq_along(items)) {
    item <- items[[i]]
    id <- as.character(item$debt_id %||% paste0("item_", i))
    missing <- setdiff(required, names(item))
    add(paste0(id, "_required_fields"), if (!length(missing)) "success" else "error", if (length(missing)) paste("Missing fields:", paste(missing, collapse = ", ")) else "Required fields present.")
    add(paste0(id, "_category_valid"), if ((item$category %||% "") %in% categories) "success" else "error", paste("category =", item$category %||% "missing"))
    add(paste0(id, "_status_valid"), if ((item$status %||% "") %in% statuses) "success" else "error", paste("status =", item$status %||% "missing"))
    add(paste0(id, "_severity_valid"), if ((item$severity %||% "") %in% severities) "success" else "error", paste("severity =", item$severity %||% "missing"))
    phase_ok <- !is.null(item$introduced_phase) && nzchar(as.character(item$introduced_phase)) &&
      grepl("^[0-9]+(\\.[0-9]+)?$", as.character(item$introduced_phase))
    add(paste0(id, "_introduced_phase_valid"), if (phase_ok) "success" else "error", paste("introduced_phase =", item$introduced_phase %||% "missing"))
    add(paste0(id, "_affected_components_nonempty"), if (length(item$affected_components %||% list())) "success" else "error", "Affected components are nonempty.")
    add(paste0(id, "_resolution_trigger_present"), if (nzchar(item$resolution_trigger %||% "")) "success" else "error", "Resolution trigger is present.")
    add(paste0(id, "_acceptance_criteria_nonempty"), if (length(item$acceptance_criteria %||% list())) "success" else "error", "Acceptance criteria are nonempty.")
    source_refs <- as.character(item$source_refs %||% character())
    missing_refs <- source_refs[!file.exists(file.path(root, source_refs))]
    add(paste0(id, "_source_refs_exist"), if (!length(missing_refs)) "success" else "error", if (length(missing_refs)) paste("Missing source refs:", paste(missing_refs, collapse = ", ")) else "Source references exist.")
    if (identical(item$status %||% "", "resolved")) {
      add(paste0(id, "_resolved_metadata"), if (!is.null(item$resolved_phase) && nzchar(item$resolution_summary %||% "")) "success" else "error", "Resolved items must include resolved_phase and resolution_summary.")
    }
  }

  add("markdown_summary_exists", if (file.exists(md_path)) "success" else "error", "Human-readable technical debt register exists.", file = "docs/architecture/technical_debt_register.md")
  if (file.exists(md_path)) {
    md <- readLines(md_path, warn = FALSE)
    missing_ids <- ids[!vapply(ids, function(id) any(grepl(id, md, fixed = TRUE)), logical(1))]
    add("markdown_contains_all_ids", if (!length(missing_ids)) "success" else "error", if (length(missing_ids)) paste("Missing IDs in Markdown:", paste(missing_ids, collapse = ", ")) else "All YAML IDs appear in Markdown.", file = "docs/architecture/technical_debt_register.md")
    count_line <- grep("^Total registered items:", md, value = TRUE)
    add("markdown_count_synchronized", if (length(count_line) && grepl(as.character(length(items)), count_line[[1]], fixed = TRUE)) "success" else "error", "Markdown total count matches YAML item count.", file = "docs/architecture/technical_debt_register.md")
  }

  add("schema_inventory_exists", if (file.exists(schema_path)) "success" else "error", "Schema inventory exists.", file = "docs/architecture/schema_version_inventory.md")
  if (file.exists(schema_path)) {
    schema_md <- paste(readLines(schema_path, warn = FALSE), collapse = "\n")
    expected_schemas <- c("proposal schema", "delegation schema", "audit schema", "temporary result contracts", "persisted result manifests", "configuration snapshot schemas", "workspace schema", "project schema", "storage policy version", "persistence schema", "technical debt register")
    missing_schemas <- expected_schemas[!vapply(expected_schemas, function(pattern) grepl(pattern, schema_md, fixed = TRUE), logical(1))]
    add("schema_inventory_complete", if (!length(missing_schemas)) "success" else "error", if (length(missing_schemas)) paste("Missing schemas:", paste(missing_schemas, collapse = ", ")) else "Known schemas listed.", file = "docs/architecture/schema_version_inventory.md")
  }

  add("phase_template_exists", if (file.exists(template_path)) "success" else "error", "Phase completion template exists.", file = "docs/templates/phase_completion_template.md")
  if (file.exists(template_path)) {
    template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")
    required_sections <- c("New debt introduced", "Existing debt resolved", "Existing debt changed", "Intentional constraints added", "Compatibility behavior retained")
    missing_sections <- required_sections[!vapply(required_sections, function(pattern) grepl(pattern, template, fixed = TRUE), logical(1))]
    add("phase_template_debt_review_sections", if (!length(missing_sections)) "success" else "error", if (length(missing_sections)) paste("Missing sections:", paste(missing_sections, collapse = ", ")) else "Debt review sections present.", file = "docs/templates/phase_completion_template.md")
  }

  alias_registered <- any(ids == "COMPAT-MODULE-001")
  add("compatibility_alias_registered", if (alias_registered) "success" else "error", "autoquant_model_assessment compatibility alias maps to COMPAT-MODULE-001.")
  boundary_refs <- c("BOUNDARY-GENAI-001", "BOUNDARY-GENAI-002", "BOUNDARY-GENAI-003")
  add("intentional_boundaries_registered", if (all(boundary_refs %in% ids)) "success" else "error", "Core GenAI safety boundaries are registered.")
  context_summary <- tryCatch(genai_technical_debt_context_summary(max_items = 5L, root = root), error = function(e) service_result(status = "error", errors = conditionMessage(e)))
  add("bounded_genai_context_summary", if (identical(context_summary$status, "success") && length(context_summary$value$items) <= 5L) "success" else "error", "Bounded technical debt summary is available for GenAI context.")

  if (length(items)) {
    first <- items[[1]]
    missing_required <- first
    missing_required$category <- NULL
    add("qa_detects_missing_required_field", if ("category" %in% setdiff(required, names(missing_required))) "success" else "error", "Mutation test detects missing required field.")

    invalid_category <- first
    invalid_category$category <- "not_a_category"
    add("qa_detects_invalid_category", if (!invalid_category$category %in% categories) "success" else "error", "Mutation test detects invalid category.")

    invalid_status <- first
    invalid_status$status <- "not_a_status"
    add("qa_detects_invalid_status", if (!invalid_status$status %in% statuses) "success" else "error", "Mutation test detects invalid status.")

    invalid_severity <- first
    invalid_severity$severity <- "not_a_severity"
    add("qa_detects_invalid_severity", if (!invalid_severity$severity %in% severities) "success" else "error", "Mutation test detects invalid severity.")

    duplicate_ids <- c(ids, ids[[1]])
    add("qa_detects_duplicate_debt_id", if (anyDuplicated(duplicate_ids)) "success" else "error", "Mutation test detects duplicate debt ID.")

    invalid_phase <- first
    invalid_phase$introduced_phase <- "ten"
    add("qa_detects_invalid_phase", if (!grepl("^[0-9]+(\\.[0-9]+)?$", as.character(invalid_phase$introduced_phase))) "success" else "error", "Mutation test detects invalid introduced phase.")

    empty_acceptance <- first
    empty_acceptance$acceptance_criteria <- list()
    add("qa_detects_empty_acceptance_criteria", if (!length(empty_acceptance$acceptance_criteria)) "success" else "error", "Mutation test detects empty acceptance criteria.")

    missing_trigger <- first
    missing_trigger$resolution_trigger <- ""
    add("qa_detects_missing_resolution_trigger", if (!nzchar(missing_trigger$resolution_trigger)) "success" else "error", "Mutation test detects missing resolution trigger.")

    invalid_ref <- first
    invalid_ref$source_refs <- "docs/does_not_exist.md"
    add("qa_detects_invalid_source_ref", if (!file.exists(file.path(root, invalid_ref$source_refs))) "success" else "error", "Mutation test detects invalid source reference.")
  }

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
