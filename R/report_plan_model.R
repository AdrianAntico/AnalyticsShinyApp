create_report_plan <- function(
  plan_id,
  label,
  source_module,
  description = NULL,
  layout_type = "sections",
  cols = 2,
  sections = list(),
  artifact_ids = character(),
  rationale = character(),
  metadata = list(),
  status = "draft",
  created_at = Sys.time(),
  updated_at = Sys.time()
) {
  structure(
    list(
      plan_id = plan_id,
      label = label,
      source_module = source_module,
      description = description,
      layout_type = layout_type,
      cols = cols,
      sections = sections,
      artifact_ids = artifact_ids,
      rationale = rationale,
      metadata = metadata,
      status = status,
      created_at = created_at,
      updated_at = updated_at
    ),
    class = c("aq_report_plan", "list")
  )
}

create_report_plan_section <- function(
  section_id,
  title,
  description = NULL,
  artifact_ids = character(),
  order = NA_integer_,
  collapsed = FALSE
) {
  list(
    section_id = section_id,
    title = title,
    description = description,
    artifact_ids = artifact_ids,
    order = order,
    collapsed = collapsed
  )
}

report_plan_artifact_ids <- function(plan) {
  unique(c(
    plan$artifact_ids %||% character(),
    unlist(lapply(plan$sections %||% list(), function(section) {
      section$artifact_ids %||% character()
    }), use.names = FALSE)
  ))
}

repair_report_plan <- function(plan) {
  if (!inherits(plan, "aq_report_plan")) {
    return(plan)
  }

  if (is.na(suppressWarnings(as.integer(plan$cols))) || as.integer(plan$cols) < 1L) {
    plan$cols <- 2L
  } else {
    plan$cols <- as.integer(plan$cols)
  }

  if (is.list(plan$sections) && length(plan$sections)) {
    section_names <- names(plan$sections)
    if (is.null(section_names)) {
      section_names <- rep("", length(plan$sections))
    }

    section_order <- vapply(seq_along(plan$sections), function(index) {
      section <- plan$sections[[index]]
      order <- suppressWarnings(as.integer(section$order %||% NA_integer_))
      if (is.na(order)) index else order
    }, integer(1))
    plan$sections <- plan$sections[order(section_order, section_names, na.last = TRUE)]
    section_names <- names(plan$sections)
    if (is.null(section_names)) {
      section_names <- rep("", length(plan$sections))
    }

    for (index in seq_along(plan$sections)) {
      section <- plan$sections[[index]]
      section$artifact_ids <- unique(section$artifact_ids %||% character())
      section$order <- index
      if (is.null(section$section_id) || !nzchar(section$section_id)) {
        section_name <- section_names[[index]]
        section$section_id <- if (nzchar(section_name)) section_name else paste0("section_", index)
      }
      if (is.null(section$title) || !nzchar(section$title)) {
        section$title <- section$section_id
      }
      plan$sections[[index]] <- section
    }
    names(plan$sections) <- vapply(plan$sections, function(section) {
      section$section_id %||% ""
    }, character(1))
  }

  plan$artifact_ids <- unique(unlist(lapply(plan$sections %||% list(), function(section) {
    section$artifact_ids %||% character()
  }), use.names = FALSE))
  plan$updated_at <- Sys.time()
  plan
}

repair_report_plan_collection <- function(plans) {
  if (inherits(plans, "aq_report_plan")) {
    plans <- list(plans)
  }
  if (is.null(plans) || !length(plans) || !is.list(plans)) {
    return(list())
  }

  plan_names <- names(plans)
  if (is.null(plan_names)) {
    plan_names <- rep("", length(plans))
  }

  repaired <- list()
  used_ids <- character()
  for (index in seq_along(plans)) {
    plan <- repair_report_plan(plans[[index]])
    if (!inherits(plan, "aq_report_plan")) {
      next
    }

    base_id <- plan$plan_id %||% plan_names[[index]]
    if (is.null(base_id) || !nzchar(base_id)) {
      base_id <- paste0("plan_", index)
    }

    plan_id <- base_id
    suffix <- 2L
    while (plan_id %in% used_ids) {
      plan_id <- paste0(base_id, "_", suffix)
      suffix <- suffix + 1L
    }
    if (!identical(plan_id, plan$plan_id)) {
      plan$plan_id <- plan_id
      plan$updated_at <- Sys.time()
    }

    repaired[[plan_id]] <- plan
    used_ids <- c(used_ids, plan_id)
  }

  repaired
}

report_plan_validation_status <- function(result, plan = NULL) {
  if (identical(result$status, "error")) {
    return("Invalid")
  }
  if (length(result$warnings)) {
    return("Has warnings")
  }
  if (!is.null(plan) && identical(plan$status, "applied")) {
    return("Applied")
  }
  "Ready"
}

validate_report_plan <- function(plan, artifact_inventory = NULL, repair = TRUE) {
  errors <- character()
  warnings <- character()

  if (isTRUE(repair)) {
    plan <- repair_report_plan(plan)
  }

  if (!inherits(plan, "aq_report_plan")) {
    return(service_result(
      status = "error",
      errors = "Report plan must inherit from aq_report_plan.",
      value = plan,
      metadata = list(error_code = "REPORT_PLAN_INVALID")
    ))
  }
  if (!is.character(plan$plan_id) || length(plan$plan_id) != 1L || !nzchar(plan$plan_id)) {
    errors <- c(errors, "plan_id must be a non-empty character value.")
  }
  if (!is.character(plan$label) || length(plan$label) != 1L || !nzchar(plan$label)) {
    errors <- c(errors, "label must be a non-empty character value.")
  }
  if (!is.character(plan$source_module) || length(plan$source_module) != 1L || !nzchar(plan$source_module)) {
    errors <- c(errors, "source_module must be a non-empty character value.")
  }
  if (!plan$layout_type %in% c("grid", "sections", "carousel", "canvas")) {
    errors <- c(errors, "layout_type must be one of: grid, sections, carousel, canvas.")
  }
  cols <- suppressWarnings(as.integer(plan$cols))
  if (is.na(cols) || cols < 1L) {
    errors <- c(errors, "cols must be a positive integer.")
  }
  if (!is.list(plan$sections)) {
    errors <- c(errors, "sections must be a list.")
  } else if (!length(plan$sections)) {
    warnings <- c(warnings, "Report plan has no sections.")
  }
  if (!plan$status %in% c("draft", "recommended", "applied", "archived")) {
    errors <- c(errors, "status must be one of: draft, recommended, applied, archived.")
  }

  artifact_ids <- report_plan_artifact_ids(plan)
  duplicated_ids <- unlist(lapply(plan$sections %||% list(), function(section) {
    ids <- section$artifact_ids %||% character()
    ids[duplicated(ids)]
  }), use.names = FALSE)
  if (length(duplicated_ids)) {
    warnings <- c(
      warnings,
      paste("Duplicate artifact IDs were removed:", paste(unique(duplicated_ids), collapse = ", "))
    )
  }
  empty_sections <- vapply(plan$sections %||% list(), function(section) {
    !length(section$artifact_ids %||% character())
  }, logical(1))
  if (any(empty_sections)) {
    empty_section_names <- names(empty_sections)
    if (is.null(empty_section_names)) {
      empty_section_names <- rep("", length(empty_sections))
    }
    empty_section_names[!nzchar(empty_section_names)] <- paste0("section_", which(!nzchar(empty_section_names)))
    warnings <- c(
      warnings,
      paste("Some sections have no artifacts:", paste(empty_section_names[empty_sections], collapse = ", "))
    )
  }

  if (!is.null(artifact_inventory)) {
    inventory_ids <- if (inherits(artifact_inventory, "data.table") && "artifact_id" %in% names(artifact_inventory)) {
      artifact_inventory$artifact_id
    } else {
      names(artifact_inventory)
    }
    missing_ids <- setdiff(artifact_ids, inventory_ids)
    if (length(missing_ids)) {
      warnings <- c(warnings, paste("Report plan references missing artifacts:", paste(missing_ids, collapse = ", ")))
    }

    if (is.list(artifact_inventory) && length(artifact_inventory)) {
      hidden_ids <- artifact_ids[vapply(artifact_ids, function(artifact_id) {
        artifact <- artifact_inventory[[artifact_id]]
        inherits(artifact, "aq_artifact") && !isTRUE(artifact$visible)
      }, logical(1))]
      if (length(hidden_ids)) {
        warnings <- c(
          warnings,
          paste("Report plan references hidden artifacts:", paste(hidden_ids, collapse = ", "))
        )
      }
    }
  }

  if (length(errors)) {
    return(service_result(
      status = "error",
      errors = errors,
      warnings = warnings,
      value = plan,
      metadata = list(error_code = "REPORT_PLAN_INVALID")
    ))
  }

  service_result(
    status = if (length(warnings)) "warning" else "success",
    value = plan,
    messages = paste("Report plan is valid:", plan$plan_id),
    warnings = warnings
  )
}

report_plan_summary <- function(plans) {
  plans <- repair_report_plan_collection(plans)

  if (is.null(plans) || !length(plans)) {
    return(data.table::data.table(
      plan_id = character(),
      label = character(),
      source_module = character(),
      layout_type = character(),
      cols = integer(),
      n_sections = integer(),
      n_artifacts = integer(),
      validation_status = character(),
      status = character()
    ))
  }

  data.table::rbindlist(lapply(plans, function(plan) {
    validation <- validate_report_plan(plan, repair = TRUE)
    repaired_plan <- validation$value

    data.table::data.table(
      validation_status = report_plan_validation_status(validation, repaired_plan),
      plan_id = repaired_plan$plan_id,
      label = repaired_plan$label,
      source_module = repaired_plan$source_module,
      layout_type = repaired_plan$layout_type,
      cols = as.integer(repaired_plan$cols),
      n_sections = length(repaired_plan$sections),
      n_artifacts = length(report_plan_artifact_ids(repaired_plan)),
      status = repaired_plan$status
    )
  }), use.names = TRUE)
}

apply_report_plan_to_layout_state <- function(plan, artifact_state, layout_state) {
  validation <- validate_report_plan(plan, artifact_state$all_artifacts())
  if (identical(validation$status, "error")) {
    return(validation)
  }
  plan <- validation$value

  artifact_state$apply_artifact_layout(
    artifact_ids = plan$artifact_ids,
    sections = plan$sections
  )
  layout_state$set_layout_settings(
    layout_type = if (identical(plan$layout_type, "sections")) "Sections" else "Grid",
    layout_cols = plan$cols
  )

  service_result(
    status = "success",
    value = plan,
    messages = paste("Applied report plan:", plan$label),
    warnings = validation$warnings,
    metadata = list(
      plan_id = plan$plan_id,
      n_artifacts = length(plan$artifact_ids)
    )
  )
}

qa_report_plan_workflow <- function() {
  artifacts <- list(
    p1 = create_artifact("p1", "plot", "Plot", "qa", object = NULL),
    t1 = create_artifact("t1", "text", "Text", "qa", content = "Narrative"),
    tbl1 = create_artifact("tbl1", "table", "Table", "qa", object = data.table::data.table(a = 1:3))
  )

  valid_plan <- create_report_plan(
    plan_id = "qa_valid",
    label = "QA Valid Plan",
    source_module = "qa",
    layout_type = "sections",
    sections = list(
      overview = create_report_plan_section(
        "overview",
        "Overview",
        artifact_ids = c("p1", "t1"),
        order = 1L
      ),
      tables = create_report_plan_section(
        "tables",
        "Tables",
        artifact_ids = "tbl1",
        order = 2L
      )
    ),
    artifact_ids = c("p1", "t1", "tbl1"),
    status = "recommended"
  )

  missing_plan <- create_report_plan(
    plan_id = "qa_missing",
    label = "QA Missing Artifact Plan",
    source_module = "qa",
    layout_type = "sections",
    sections = list(
      overview = create_report_plan_section(
        "overview",
        "Overview",
        artifact_ids = c("p1", "missing_artifact", "p1"),
        order = 1L
      )
    ),
    artifact_ids = c("p1", "missing_artifact"),
    status = "recommended"
  )

  duplicate_plan <- valid_plan
  duplicate_plan$plan_id <- "qa_valid_copy"
  duplicate_plan$label <- "QA Valid Plan Copy"
  duplicate_plan$sections$overview$title <- "Renamed Overview"
  duplicate_plan$sections$overview$artifact_ids <- rev(duplicate_plan$sections$overview$artifact_ids)
  duplicate_plan <- repair_report_plan(duplicate_plan)

  applied <- FALSE
  apply_result <- apply_report_plan_to_layout_state(
    duplicate_plan,
    artifact_state = list(
      all_artifacts = function() artifacts,
      apply_artifact_layout = function(artifact_ids, sections) {
        applied <<- length(artifact_ids) == 3L && length(sections) == 2L
      }
    ),
    layout_state = list(
      set_layout_settings = function(layout_type, layout_cols) {
        invisible(TRUE)
      }
    )
  )

  duplicate_id_plans <- list(valid_plan, valid_plan)
  duplicate_id_plans[[2]]$label <- "QA Duplicate ID Plan"
  duplicate_id_repair <- repair_report_plan_collection(duplicate_id_plans)

  data.table::data.table(
    check = c("valid_plan", "missing_plan", "duplicate_edit_apply", "duplicate_id_repair"),
    status = c(
      validate_report_plan(valid_plan, artifacts)$status,
      validate_report_plan(missing_plan, artifacts)$status,
      apply_result$status,
      if (length(unique(names(duplicate_id_repair))) == 2L) "success" else "error"
    ),
    validation_status = c(
      report_plan_validation_status(validate_report_plan(valid_plan, artifacts), valid_plan),
      report_plan_validation_status(validate_report_plan(missing_plan, artifacts), missing_plan),
      if (isTRUE(applied)) "Applied" else "Invalid",
      if (length(unique(names(duplicate_id_repair))) == 2L) "Ready" else "Invalid"
    )
  )
}
