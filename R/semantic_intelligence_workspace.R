semantic_object_types <- function() {
  c(
    "mission", "objective", "strategy", "tactic", "lever", "kpi",
    "guardrail", "constraint", "risk", "assumption", "authority", "coverage",
    "decision_context", "alternative", "recommendation", "decision", "review",
    "learning_summary"
  )
}

semantic_object_statuses <- function() {
  c("draft", "review", "approved", "archived", "retired")
}

semantic_relationship_types <- function() {
  c(
    "mission_objective", "objective_strategy", "strategy_tactic",
    "tactic_lever", "lever_variable", "objective_kpi",
    "strategy_assumption", "decision_alternative", "decision_evidence",
    "review_decision", "decision_recommendation", "review_learning"
  )
}

semantic_workspace_empty <- function(project_id = NA_character_) {
  list(
    schema_version = "semantic_workspace_v1",
    project_id = project_id,
    objects = list(),
    relationships = data.table::data.table(
      relationship_id = character(),
      relationship_type = character(),
      from_id = character(),
      to_id = character(),
      status = character(),
      created_at = character(),
      updated_at = character()
    ),
    history = data.table::data.table(
      event_id = character(),
      object_id = character(),
      object_type = character(),
      event_type = character(),
      version = integer(),
      status = character(),
      summary = character(),
      timestamp = character()
    )
  )
}

semantic_workspace_slug <- function(x, prefix = "semantic") {
  x <- tolower(gsub("[^A-Za-z0-9]+", "_", as.character(x %||% "")))
  x <- gsub("^_+|_+$", "", x)
  if (!nzchar(x)) x <- format(Sys.time(), "%Y%m%d%H%M%S")
  paste(prefix, x, sep = "_")
}

semantic_workspace_event <- function(object_id, object_type, event_type, version, status, summary) {
  data.table::data.table(
    event_id = paste0("semantic_event_", format(Sys.time(), "%Y%m%d%H%M%S"), "_", sample.int(999999, 1L)),
    object_id = object_id,
    object_type = object_type,
    event_type = event_type,
    version = as.integer(version),
    status = status,
    summary = summary,
    timestamp = as.character(Sys.time())
  )
}

semantic_workspace_get_object <- function(workspace, object_id) {
  (workspace$objects %||% list())[[object_id]] %||% NULL
}

semantic_workspace_upsert_object <- function(
  workspace,
  object_type,
  title,
  object_id = NULL,
  status = "draft",
  owner = NA_character_,
  description = NA_character_,
  tags = character(),
  fields = list(),
  event_type = NULL
) {
  if (!object_type %in% semantic_object_types()) {
    return(service_result(status = "error", errors = paste("Unsupported semantic object type:", object_type)))
  }
  if (!status %in% semantic_object_statuses()) {
    return(service_result(status = "error", errors = paste("Unsupported semantic object status:", status)))
  }
  if (!nzchar(title %||% "")) {
    return(service_result(status = "error", errors = "Title is required."))
  }
  object_id <- object_id %||% semantic_workspace_slug(title, object_type)
  existing <- semantic_workspace_get_object(workspace, object_id)
  version <- as.integer((existing$version %||% 0L) + 1L)
  now <- Sys.time()
  object <- list(
    object_id = object_id,
    object_type = object_type,
    title = title,
    status = status,
    owner = owner %||% NA_character_,
    description = description %||% NA_character_,
    tags = as.character(tags %||% character()),
    fields = fields %||% list(),
    version = version,
    created_at = existing$created_at %||% as.character(now),
    updated_at = as.character(now)
  )
  workspace$objects[[object_id]] <- object
  event_type <- event_type %||% if (is.null(existing)) "created" else "modified"
  workspace$history <- data.table::rbindlist(
    list(workspace$history, semantic_workspace_event(object_id, object_type, event_type, version, status, paste(event_type, title))),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = workspace, messages = paste("Saved", object_type, title), metadata = list(object_id = object_id))
}

semantic_workspace_transition_object <- function(workspace, object_id, status, event_type = status) {
  object <- semantic_workspace_get_object(workspace, object_id)
  if (is.null(object)) return(service_result(status = "error", errors = paste("Object not found:", object_id)))
  semantic_workspace_upsert_object(
    workspace = workspace,
    object_type = object$object_type,
    title = object$title,
    object_id = object_id,
    status = status,
    owner = object$owner,
    description = object$description,
    tags = object$tags,
    fields = object$fields,
    event_type = event_type
  )
}

semantic_workspace_add_relationship <- function(workspace, relationship_type, from_id, to_id, status = "active") {
  if (!relationship_type %in% semantic_relationship_types()) {
    return(service_result(status = "error", errors = paste("Unsupported semantic relationship type:", relationship_type)))
  }
  if (is.null(semantic_workspace_get_object(workspace, from_id))) {
    return(service_result(status = "error", errors = paste("Relationship source not found:", from_id)))
  }
  if (is.null(semantic_workspace_get_object(workspace, to_id))) {
    return(service_result(status = "error", errors = paste("Relationship target not found:", to_id)))
  }
  rel_id <- paste(relationship_type, from_id, to_id, sep = "::")
  existing <- workspace$relationships
  existing <- existing[relationship_id != rel_id]
  now <- as.character(Sys.time())
  row <- data.table::data.table(
    relationship_id = rel_id,
    relationship_type = relationship_type,
    from_id = from_id,
    to_id = to_id,
    status = status,
    created_at = now,
    updated_at = now
  )
  workspace$relationships <- data.table::rbindlist(list(existing, row), use.names = TRUE, fill = TRUE)
  workspace$history <- data.table::rbindlist(
    list(workspace$history, semantic_workspace_event(from_id, semantic_workspace_get_object(workspace, from_id)$object_type, "relationship_modified", semantic_workspace_get_object(workspace, from_id)$version, semantic_workspace_get_object(workspace, from_id)$status, paste("Linked", from_id, "to", to_id))),
    use.names = TRUE,
    fill = TRUE
  )
  service_result(status = "success", value = workspace, messages = paste("Linked", from_id, "to", to_id))
}

semantic_workspace_objects_table <- function(workspace) {
  objects <- workspace$objects %||% list()
  if (!length(objects)) {
    return(data.table::data.table(object_id = character(), object_type = character(), title = character(), status = character(), owner = character(), tags = character(), version = integer(), updated_at = character()))
  }
  data.table::rbindlist(lapply(objects, function(x) {
    data.table::data.table(
      object_id = x$object_id,
      object_type = x$object_type,
      title = x$title,
      status = x$status,
      owner = x$owner %||% NA_character_,
      tags = paste(x$tags %||% character(), collapse = ", "),
      version = as.integer(x$version %||% 1L),
      updated_at = x$updated_at %||% NA_character_
    )
  }), use.names = TRUE, fill = TRUE)
}

semantic_workspace_search <- function(workspace, query = "", object_type = "all", status = "all", owner = "") {
  objects <- semantic_workspace_objects_table(workspace)
  if (!nrow(objects)) return(objects)
  object_type_filter <- object_type
  status_filter <- status
  owner_filter <- owner
  if (!identical(object_type_filter, "all")) objects <- objects[object_type == object_type_filter]
  if (!identical(status_filter, "all")) objects <- objects[status == status_filter]
  if (nzchar(owner_filter %||% "")) objects <- objects[grepl(owner_filter, objects$owner, ignore.case = TRUE)]
  query <- trimws(query %||% "")
  if (nzchar(query)) {
    haystack <- paste(objects$object_id, objects$object_type, objects$title, objects$status, objects$owner, objects$tags)
    objects <- objects[grepl(query, haystack, ignore.case = TRUE)]
  }
  objects[order(object_type, title)]
}

semantic_workspace_validation_row <- function(check, status, issue, recommendation, object_id = NA_character_) {
  data.table::data.table(check = check, status = status, object_id = object_id, issue = issue, recommendation = recommendation)
}

semantic_workspace_validate <- function(workspace) {
  objects <- semantic_workspace_objects_table(workspace)
  rels <- workspace$relationships %||% data.table::data.table()
  rows <- list()
  add <- function(check, status, issue, recommendation, object_id = NA_character_) {
    rows[[length(rows) + 1L]] <<- semantic_workspace_validation_row(check, status, issue, recommendation, object_id)
  }
  type_ids <- function(type) objects[object_type == type & !status %in% c("archived", "retired"), object_id]
  linked_to <- function(type) unique(rels[relationship_type == type & status == "active", to_id])
  linked_from <- function(type) unique(rels[relationship_type == type & status == "active", from_id])

  if (!nrow(objects)) {
    add("workspace_has_objects", "warning", "No semantic objects have been authored.", "Create a mission, objective, and decision context.")
  } else {
    add("workspace_has_objects", "success", "Semantic workspace contains authored objects.", "Continue validating relationships.")
  }

  for (id in setdiff(type_ids("objective"), linked_to("mission_objective"))) add("orphaned_objective", "warning", "Objective is not linked to a mission.", "Link objective to a mission.", id)
  for (id in setdiff(type_ids("strategy"), linked_to("objective_strategy"))) add("orphaned_strategy", "warning", "Strategy is not linked to an objective.", "Link strategy to an objective.", id)
  for (id in setdiff(type_ids("tactic"), linked_to("strategy_tactic"))) add("unused_tactic", "warning", "Tactic is not linked to a strategy.", "Link tactic to a strategy.", id)
  for (id in setdiff(type_ids("lever"), linked_to("tactic_lever"))) add("unused_lever", "warning", "Lever is not linked to a tactic.", "Link lever to a tactic.", id)
  for (id in setdiff(type_ids("objective"), linked_from("objective_kpi"))) add("missing_kpi", "warning", "Objective has no KPI relationship.", "Link at least one KPI to the objective.", id)
  for (id in setdiff(type_ids("strategy"), linked_from("strategy_assumption"))) add("missing_assumption", "warning", "Strategy has no assumption relationship.", "Link assumptions to the strategy.", id)
  for (id in type_ids("decision_context")) {
    obj <- semantic_workspace_get_object(workspace, id)
    if (!nzchar(obj$fields$authority_id %||% "")) add("missing_authority", "warning", "Decision context has no authority reference.", "Assign an authority object.", id)
    if (!nzchar(obj$fields$coverage_id %||% "")) add("missing_coverage", "warning", "Decision context has no coverage reference.", "Assign a coverage object.", id)
    if (!id %in% linked_from("decision_alternative")) add("missing_alternatives", "error", "Decision context has no linked alternatives.", "Create and link at least one alternative.", id)
  }
  broken <- rels[!(from_id %in% objects$object_id) | !(to_id %in% objects$object_id)]
  if (nrow(broken)) {
    for (i in seq_len(nrow(broken))) add("broken_reference", "error", "Relationship points to a missing object.", "Remove or repair the relationship.", broken$relationship_id[[i]])
  }
  dupes <- rels[, .N, by = .(relationship_type, from_id, to_id)][N > 1]
  if (nrow(dupes)) add("duplicate_mappings", "warning", "Duplicate semantic relationships were found.", "Deduplicate relationship mappings.")
  if (!length(rows)) add("validation_summary", "success", "Semantic workspace integrity checks passed.", "Continue authoring organizational knowledge.")
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

semantic_workspace_summary <- function(workspace) {
  objects <- semantic_workspace_objects_table(workspace)
  validation <- semantic_workspace_validate(workspace)
  data.table::data.table(
    total_objects = nrow(objects),
    draft_objects = sum(objects$status == "draft", na.rm = TRUE),
    review_objects = sum(objects$status == "review", na.rm = TRUE),
    approved_objects = sum(objects$status == "approved", na.rm = TRUE),
    archived_objects = sum(objects$status %in% c("archived", "retired"), na.rm = TRUE),
    relationships = nrow(workspace$relationships %||% data.table::data.table()),
    validation_errors = sum(validation$status == "error", na.rm = TRUE),
    validation_warnings = sum(validation$status == "warning", na.rm = TRUE),
    last_event = if (nrow(workspace$history %||% data.table::data.table())) {
      workspace$history[order(timestamp, decreasing = TRUE), event_type][[1]]
    } else {
      "none"
    }
  )
}

semantic_workspace_to_business_intent <- function(workspace) {
  if (!requireNamespace("AutoQuant", quietly = TRUE) || !"aq_business_intent" %in% getNamespaceExports("AutoQuant")) {
    return(service_result(status = "warning", warnings = "AutoQuant business-intent API is unavailable."))
  }
  table <- semantic_workspace_objects_table(workspace)
  rels <- workspace$relationships %||% data.table::data.table()
  rel_targets <- function(relationship_type, from_id) {
    rels[relationship_type == relationship_type & from_id == from_id & status == "active", to_id]
  }
  rel_sources <- function(relationship_type, to_id) {
    rels[relationship_type == relationship_type & to_id == to_id & status == "active", from_id]
  }
  relationship_fields <- function(type, object_id) {
    switch(
      type,
      objective = list(mission_id = rel_sources("mission_objective", object_id)),
      strategy = list(objective_id = rel_sources("objective_strategy", object_id)),
      tactic = list(strategy_id = rel_sources("strategy_tactic", object_id)),
      lever = list(tactic_id = rel_sources("tactic_lever", object_id), related_variables = rel_targets("lever_variable", object_id)),
      kpi = list(objective_id = rel_sources("objective_kpi", object_id)),
      assumption = list(strategy_id = rel_sources("strategy_assumption", object_id)),
      list()
    )
  }
  records <- function(type, id_col) {
    rows <- table[object_type == type]
    if (!nrow(rows)) return(NULL)
    unname(lapply(seq_len(nrow(rows)), function(i) {
      obj <- semantic_workspace_get_object(workspace, rows$object_id[[i]])
      c(
        stats::setNames(list(obj$object_id), id_col),
        list(title = obj$title, status = obj$status, owner = obj$owner, description = obj$description),
        relationship_fields(type, obj$object_id),
        obj$fields %||% list()
      )
    }))
  }
  value <- tryCatch(
    AutoQuant::aq_business_intent(
      missions = records("mission", "mission_id"),
      objectives = records("objective", "objective_id"),
      strategies = records("strategy", "strategy_id"),
      tactics = records("tactic", "tactic_id"),
      levers = records("lever", "lever_id"),
      kpis = records("kpi", "kpi_id"),
      guardrails = records("guardrail", "guardrail_id"),
      constraints = records("constraint", "constraint_id"),
      risks = records("risk", "risk_id"),
      assumptions = records("assumption", "assumption_id"),
      authority = records("authority", "authority_id"),
      coverage = records("coverage", "coverage_id")
    ),
    error = function(e) e
  )
  if (inherits(value, "error")) return(service_result(status = "error", errors = conditionMessage(value)))
  service_result(status = "success", value = value)
}

semantic_workspace_fixture <- function() {
  ws <- semantic_workspace_empty("semantic_fixture")
  specs <- list(
    list("mission", "Grow efficiently", "mission_growth", "approved"),
    list("objective", "Increase revenue", "objective_revenue_growth", "approved"),
    list("strategy", "Increase qualified demand", "strategy_qualified_demand", "review"),
    list("tactic", "Scale paid search", "tactic_paid_search", "review"),
    list("lever", "Paid-search budget", "lever_paid_search_budget", "draft"),
    list("kpi", "Revenue", "kpi_revenue", "approved"),
    list("assumption", "Search response holds", "assumption_search_response", "review"),
    list("authority", "Marketing advisory", "authority_marketing_advisory", "approved"),
    list("coverage", "Marketing only", "coverage_marketing", "approved"),
    list("decision_context", "Next-quarter budget decision", "decision_next_quarter_budget", "draft")
  )
  for (spec in specs) {
    ws <- semantic_workspace_upsert_object(ws, spec[[1]], spec[[2]], object_id = spec[[3]], status = spec[[4]], owner = "Marketing")$value
  }
  ws$objects$decision_next_quarter_budget$fields$authority_id <- "authority_marketing_advisory"
  ws$objects$decision_next_quarter_budget$fields$coverage_id <- "coverage_marketing"
  links <- list(
    list("mission_objective", "mission_growth", "objective_revenue_growth"),
    list("objective_strategy", "objective_revenue_growth", "strategy_qualified_demand"),
    list("strategy_tactic", "strategy_qualified_demand", "tactic_paid_search"),
    list("tactic_lever", "tactic_paid_search", "lever_paid_search_budget"),
    list("objective_kpi", "objective_revenue_growth", "kpi_revenue"),
    list("strategy_assumption", "strategy_qualified_demand", "assumption_search_response")
  )
  for (link in links) ws <- semantic_workspace_add_relationship(ws, link[[1]], link[[2]], link[[3]])$value
  alt <- semantic_workspace_upsert_object(ws, "alternative", "Increase within validated range", object_id = "alt_validated_increase", status = "draft")$value
  semantic_workspace_add_relationship(alt, "decision_alternative", "decision_next_quarter_budget", "alt_validated_increase")$value
}

qa_semantic_intelligence_workspace <- function() {
  ws <- semantic_workspace_fixture()
  validation <- semantic_workspace_validate(ws)
  search <- semantic_workspace_search(ws, query = "paid", object_type = "all", status = "all")
  intent <- semantic_workspace_to_business_intent(ws)
  rows <- list(
    data.table::data.table(check = "workspace_creation", status = if (length(ws$objects) >= 10L) "success" else "error", message = "Workspace fixture creates organizational objects."),
    data.table::data.table(check = "relationship_integrity", status = if (!any(validation$status == "error")) "success" else "error", message = paste(validation$issue, collapse = " | ")),
    data.table::data.table(check = "version_history", status = if (nrow(ws$history) >= length(ws$objects)) "success" else "error", message = "History records object creation and relationship changes."),
    data.table::data.table(check = "search", status = if (nrow(search) >= 1L) "success" else "error", message = "Deterministic search returns authored objects."),
    data.table::data.table(check = "autoquant_business_intent", status = if (identical(intent$status, "success")) "success" else "warning", message = paste(intent$errors %||% intent$warnings %||% "AutoQuant business intent contract constructed.", collapse = " | "))
  )
  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}
