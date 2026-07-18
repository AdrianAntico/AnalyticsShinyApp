report_contract_version <- "0.1.0"
report_contract_schema_version <- "report_contract_v0_1"

report_component_types <- c(
  "title",
  "orientation",
  "executive_summary",
  "finding",
  "recommendation",
  "metric_summary",
  "narrative",
  "visualization",
  "table",
  "diagnostic",
  "methodology",
  "evidence_link",
  "technical_appendix"
)

report_capabilities <- c(
  "interactive",
  "filtering",
  "linked_views",
  "drilldown",
  "annotations",
  "export_pdf",
  "export_docx",
  "export_pptx",
  "export_html",
  "evidence_trace",
  "ai_summary"
)

report_component_schema <- function() {
  list(
    title = list(required = c("title")),
    orientation = list(required = c("question")),
    executive_summary = list(required = c("summary")),
    finding = list(required = c("statement")),
    recommendation = list(required = c("action")),
    metric_summary = list(required_any = list(c("metrics", "metric_table"))),
    narrative = list(required = c("text")),
    visualization = list(required_any = list(c("plot_ref", "visual_ref", "specification"))),
    table = list(required_any = list(c("table_ref", "data", "table_contract"))),
    diagnostic = list(required_any = list(c("status", "messages"))),
    methodology = list(required = c("method")),
    evidence_link = list(required = c("artifact_id")),
    technical_appendix = list(required = c("content"))
  )
}

report_component_type_labels <- function() {
  c(
    title = "Title",
    orientation = "Orientation",
    executive_summary = "Executive Summary",
    finding = "Finding",
    recommendation = "Recommendation",
    metric_summary = "Metric Summary",
    narrative = "Narrative",
    visualization = "Visualization",
    table = "Table",
    diagnostic = "Diagnostic",
    methodology = "Methodology",
    evidence_link = "Evidence Link",
    technical_appendix = "Technical Appendix"
  )
}

normalize_report_component_type <- function(component_type) {
  value <- tolower(gsub("[^A-Za-z0-9]+", "_", as.character(component_type %||% "")))
  value <- gsub("^_+|_+$", "", value)
  aliases <- c(
    titles = "title",
    report_title = "title",
    executive = "executive_summary",
    summary = "executive_summary",
    metrics = "metric_summary",
    plot = "visualization",
    visual = "visualization",
    evidence = "evidence_link",
    appendix = "technical_appendix"
  )
  if (value %in% names(aliases)) aliases[[value]] else value
}

report_safe_id <- function(prefix, value = NULL) {
  text <- paste(as.character(value %||% prefix), collapse = "_")
  id <- tolower(gsub("[^A-Za-z0-9]+", "_", text))
  id <- gsub("^_+|_+$", "", id)
  if (!nzchar(id)) {
    id <- prefix
  }
  id
}

create_canonical_analysis_result <- function(
  result_id,
  analysis_id,
  module_id,
  run_id = NULL,
  inputs = list(),
  configuration = list(),
  outputs = list(),
  metrics = list(),
  diagnostics = list(),
  findings = list(),
  recommendations = list(),
  metadata = list(),
  provenance = list()
) {
  structure(
    list(
      result_id = result_id,
      analysis_id = analysis_id,
      module_id = module_id,
      run_id = run_id,
      inputs = inputs,
      configuration = configuration,
      outputs = outputs,
      metrics = metrics,
      diagnostics = diagnostics,
      findings = findings,
      recommendations = recommendations,
      metadata = metadata,
      provenance = provenance
    ),
    class = c("canonical_analysis_result", "list")
  )
}

create_presentation_profile <- function(
  profile_id = "workstation_default",
  density = c("balanced", "compact", "comfortable"),
  typography = list(scale = "standard", emphasis = "semantic"),
  spacing = list(mode = "balanced"),
  theme = "inherit",
  responsiveness = list(mode = "responsive"),
  print_behavior = list(mode = "degrade_gracefully"),
  metadata = list()
) {
  density <- match.arg(density)
  structure(
    list(
      profile_id = profile_id,
      density = density,
      typography = typography,
      spacing = spacing,
      theme = theme,
      responsiveness = responsiveness,
      print_behavior = print_behavior,
      metadata = metadata
    ),
    class = c("presentation_profile", "list")
  )
}

create_report_component <- function(
  component_type,
  component_id = NULL,
  title = NULL,
  payload = list(),
  semantic_role = NULL,
  importance = c("recommended", "critical", "supplementary"),
  evidence_links = list(),
  interaction_descriptor = list(),
  static_fallback = list(),
  presentation_hints = list(),
  metadata = list()
) {
  component_type <- normalize_report_component_type(component_type)
  importance <- match.arg(importance)
  component_id <- component_id %||% report_safe_id(component_type, title %||% component_type)
  structure(
    list(
      component_id = component_id,
      component_type = component_type,
      title = title,
      payload = payload,
      semantic_role = semantic_role,
      importance = importance,
      evidence_links = evidence_links,
      interaction_descriptor = interaction_descriptor,
      static_fallback = static_fallback,
      presentation_hints = presentation_hints,
      metadata = metadata
    ),
    class = c("report_component", "list")
  )
}

report_component_title <- function(title, subtitle = NULL, component_id = "report_title", metadata = list()) {
  create_report_component("title", component_id = component_id, title = title, payload = list(title = title, subtitle = subtitle), metadata = metadata)
}

report_component_orientation <- function(question, scope = NULL, audience = NULL, component_id = "orientation", metadata = list()) {
  create_report_component("orientation", component_id = component_id, title = "Orientation", payload = list(question = question, scope = scope, audience = audience), metadata = metadata)
}

report_component_executive_summary <- function(summary, confidence = NULL, next_action = NULL, component_id = "executive_summary", metadata = list()) {
  create_report_component("executive_summary", component_id = component_id, title = "Executive Summary", payload = list(summary = summary, confidence = confidence, next_action = next_action), importance = "critical", metadata = metadata)
}

report_component_finding <- function(statement, support = NULL, caveat = NULL, confidence = NULL, component_id = NULL, metadata = list()) {
  create_report_component("finding", component_id = component_id, title = "Finding", payload = list(statement = statement, support = support, caveat = caveat, confidence = confidence), importance = "critical", metadata = metadata)
}

create_report_finding <- function(
  finding_id,
  title,
  statement,
  confidence = "not_assessed",
  importance = c("recommended", "critical", "supplementary"),
  evidence_ids = character(),
  recommendation_ids = character(),
  quality_status = "not_assessed",
  metadata = list()
) {
  importance <- match.arg(importance)
  structure(
    list(
      finding_id = finding_id,
      title = title,
      statement = statement,
      confidence = confidence %||% "not_assessed",
      importance = importance,
      evidence_ids = as.character(evidence_ids %||% character()),
      recommendation_ids = as.character(recommendation_ids %||% character()),
      quality_status = quality_status %||% "not_assessed",
      metadata = metadata
    ),
    class = c("report_finding", "list")
  )
}

report_component_recommendation <- function(action, rationale = NULL, risk = NULL, component_id = NULL, metadata = list()) {
  create_report_component("recommendation", component_id = component_id, title = "Recommendation", payload = list(action = action, rationale = rationale, risk = risk), importance = "critical", metadata = metadata)
}

report_component_metric_summary <- function(metrics, component_id = "metric_summary", title = "Metric Summary", metadata = list()) {
  create_report_component("metric_summary", component_id = component_id, title = title, payload = list(metrics = metrics), metadata = metadata)
}

report_component_narrative <- function(text, component_id = NULL, title = "Narrative", metadata = list()) {
  create_report_component("narrative", component_id = component_id, title = title, payload = list(text = text), metadata = metadata)
}

report_component_visualization <- function(plot_ref = NULL, visual_ref = NULL, specification = NULL, caption = NULL, component_id = NULL, title = "Visualization", metadata = list()) {
  create_report_component("visualization", component_id = component_id, title = title, payload = list(plot_ref = plot_ref, visual_ref = visual_ref, specification = specification, caption = caption), metadata = metadata)
}

report_component_table <- function(table_ref = NULL, data = NULL, table_contract = NULL, component_id = NULL, title = "Table", metadata = list()) {
  create_report_component("table", component_id = component_id, title = title, payload = list(table_ref = table_ref, data = data, table_contract = table_contract), metadata = metadata)
}

report_component_diagnostic <- function(status = NULL, messages = character(), severity = NULL, component_id = NULL, title = "Diagnostic", metadata = list()) {
  create_report_component("diagnostic", component_id = component_id, title = title, payload = list(status = status, messages = messages, severity = severity), metadata = metadata)
}

report_component_methodology <- function(method, assumptions = character(), limitations = character(), component_id = "methodology", metadata = list()) {
  create_report_component("methodology", component_id = component_id, title = "Methodology", payload = list(method = method, assumptions = assumptions, limitations = limitations), metadata = metadata)
}

report_component_evidence_link <- function(artifact_id, relationship = "supports", role = "evidence", component_id = NULL, metadata = list()) {
  create_report_component("evidence_link", component_id = component_id, title = "Evidence Link", payload = list(artifact_id = artifact_id, relationship = relationship, role = role), metadata = metadata)
}

report_component_technical_appendix <- function(content, component_id = "technical_appendix", title = "Technical Appendix", metadata = list()) {
  create_report_component("technical_appendix", component_id = component_id, title = title, payload = list(content = content), importance = "supplementary", metadata = metadata)
}

create_report_section <- function(
  section_id,
  title,
  purpose = NULL,
  priority = c("recommended", "critical", "supplementary"),
  depth_level = 1L,
  components = character(),
  evidence_links = list(),
  default_state = "expanded",
  fallback_policy = "render_static"
) {
  priority <- match.arg(priority)
  list(
    section_id = section_id,
    title = title,
    purpose = purpose,
    priority = priority,
    depth_level = as.integer(depth_level),
    components = as.character(components %||% character()),
    evidence_links = evidence_links,
    default_state = default_state,
    fallback_policy = fallback_policy
  )
}

create_report_contract <- function(
  report_id = "report_contract",
  title = "Analytical Report",
  report_type = "analytical_report",
  analysis_ids = character(),
  source_result_ids = character(),
  metadata = list(),
  audience = list(primary = "analyst", secondary = character(), technical_depth = "standard"),
  purpose = "diagnostic_review",
  presentation_profile = create_presentation_profile(),
  sections = list(create_report_section("summary", "Summary", purpose = "Orient the reader.")),
  components = list(),
  findings = list(),
  recommendations = list(),
  evidence_links = list(),
  capabilities = c("evidence_trace"),
  validation = list(status = "not_validated"),
  provenance = list(),
  mode = c("automatic", "guided", "studio"),
  contract_version = report_contract_version,
  schema_version = report_contract_schema_version
) {
  mode <- match.arg(mode)
  structure(
    list(
      contract_version = contract_version,
      schema_version = schema_version,
      report_id = report_id,
      report_type = report_type,
      title = title,
      analysis_ids = as.character(analysis_ids %||% character()),
      source_result_ids = as.character(source_result_ids %||% character()),
      metadata = metadata,
      audience = audience,
      purpose = purpose,
      mode = mode,
      presentation_profile = presentation_profile,
      sections = sections,
      components = components,
      findings = findings,
      recommendations = recommendations,
      evidence_links = evidence_links,
      capabilities = as.character(capabilities %||% character()),
      validation = validation,
      provenance = provenance
    ),
    class = c("report_contract", "list")
  )
}

add_component <- function(report, component, section_id = NULL) {
  report$components <- c(report$components %||% list(), list(component))
  if (!is.null(section_id)) {
    section_ids <- vapply(report$sections %||% list(), function(section) section$section_id %||% "", character(1))
    index <- match(section_id, section_ids)
    if (is.na(index)) {
      report$sections <- c(report$sections %||% list(), list(create_report_section(section_id, tools::toTitleCase(gsub("_", " ", section_id)))))
      index <- length(report$sections)
    }
    report$sections[[index]]$components <- unique(c(report$sections[[index]]$components %||% character(), component$component_id))
  }
  report
}

add_finding <- function(report, statement, support = NULL, caveat = NULL, confidence = NULL, finding_id = NULL, metadata = list()) {
  finding <- create_report_finding(
    finding_id = finding_id %||% report_safe_id("finding", statement),
    title = metadata$title %||% "Finding",
    statement = statement,
    confidence = confidence,
    evidence_ids = metadata$evidence_ids %||% character(),
    recommendation_ids = metadata$recommendation_ids %||% character(),
    quality_status = metadata$quality_status %||% "not_assessed",
    metadata = c(metadata, list(support = support, caveat = caveat))
  )
  report$findings <- c(report$findings %||% list(), list(finding))
  report
}

set_presentation_profile <- function(report, presentation_profile) {
  report$presentation_profile <- presentation_profile
  report
}

validate_contract_version <- function(contract_version, schema_version = report_contract_schema_version) {
  errors <- character()
  warnings <- character()
  if (is.null(contract_version) || !nzchar(contract_version)) {
    errors <- c(errors, "ReportContract is missing contract_version.")
  } else if (!identical(contract_version, report_contract_version)) {
    warnings <- c(warnings, paste("ReportContract version differs from runtime:", contract_version, "runtime:", report_contract_version))
  }
  if (is.null(schema_version) || !nzchar(schema_version)) {
    errors <- c(errors, "ReportContract is missing schema_version.")
  } else if (!identical(schema_version, report_contract_schema_version)) {
    warnings <- c(warnings, paste("ReportContract schema_version differs from runtime:", schema_version, "runtime:", report_contract_schema_version))
  }
  service_result(if (length(errors)) "error" else if (length(warnings)) "warning" else "success", warnings = warnings, errors = errors)
}

validate_capabilities <- function(capabilities) {
  capabilities <- as.character(capabilities %||% character())
  unsupported <- setdiff(capabilities, report_capabilities)
  service_result(
    if (length(unsupported)) "error" else "success",
    value = capabilities,
    errors = if (length(unsupported)) paste("Unsupported report capabilities:", paste(unsupported, collapse = ", ")) else character()
  )
}

validate_presentation_profile <- function(profile) {
  errors <- character()
  if (!inherits(profile, "presentation_profile")) {
    errors <- c(errors, "presentation_profile must inherit from presentation_profile.")
  }
  if (is.null(profile$profile_id) || !nzchar(profile$profile_id)) {
    errors <- c(errors, "presentation_profile is missing profile_id.")
  }
  if (is.null(profile$density) || !profile$density %in% c("balanced", "compact", "comfortable")) {
    errors <- c(errors, "presentation_profile density must be balanced, compact, or comfortable.")
  }
  service_result(if (length(errors)) "error" else "success", value = profile, errors = errors)
}

report_payload_has <- function(payload, names) {
  any(vapply(names, function(name) {
    value <- payload[[name]]
    !is.null(value) && length(value) > 0L && !identical(value, "") && !all(is.na(value))
  }, logical(1)))
}

validate_report_component <- function(component) {
  errors <- character()
  warnings <- character()
  if (!inherits(component, "report_component")) {
    errors <- c(errors, "Component must inherit from report_component.")
  }
  component_type <- normalize_report_component_type(component$component_type)
  if (!component_type %in% report_component_types) {
    errors <- c(errors, paste("Unsupported report component type:", component$component_type %||% "missing"))
  }
  if (is.null(component$component_id) || !nzchar(component$component_id)) {
    errors <- c(errors, "Component is missing component_id.")
  }
  schema <- report_component_schema()[[component_type]]
  payload <- component$payload %||% list()
  for (field in schema$required %||% character()) {
    if (!report_payload_has(payload, field)) {
      errors <- c(errors, paste("Component", component$component_id %||% "unknown", "is missing required payload field:", field))
    }
  }
  for (fields in schema$required_any %||% list()) {
    if (!report_payload_has(payload, fields)) {
      errors <- c(errors, paste("Component", component$component_id %||% "unknown", "must include one of:", paste(fields, collapse = ", ")))
    }
  }
  if (!component$importance %in% c("critical", "recommended", "supplementary")) {
    errors <- c(errors, paste("Component", component$component_id %||% "unknown", "has invalid importance."))
  }
  service_result(if (length(errors)) "error" else if (length(warnings)) "warning" else "success", value = component, warnings = warnings, errors = errors)
}

validate_components <- function(components) {
  components <- components %||% list()
  errors <- character()
  warnings <- character()
  ids <- vapply(components, function(component) component$component_id %||% NA_character_, character(1))
  duplicates <- unique(ids[!is.na(ids) & duplicated(ids)])
  if (length(duplicates)) {
    errors <- c(errors, paste("Duplicate report component IDs:", paste(duplicates, collapse = ", ")))
  }
  results <- lapply(components, validate_report_component)
  errors <- c(errors, unlist(lapply(results, function(result) result$errors), use.names = FALSE))
  warnings <- c(warnings, unlist(lapply(results, function(result) result$warnings), use.names = FALSE))
  service_result(if (length(errors)) "error" else if (length(warnings)) "warning" else "success", value = components, warnings = warnings, errors = errors)
}

validate_report_finding <- function(finding) {
  errors <- character()
  if (!inherits(finding, "report_finding")) {
    errors <- c(errors, "Finding must inherit from report_finding.")
  }
  for (field in c("finding_id", "title", "statement")) {
    if (is.null(finding[[field]]) || !nzchar(as.character(finding[[field]]))) {
      errors <- c(errors, paste("Finding is missing required field:", field))
    }
  }
  if (!finding$importance %in% c("critical", "recommended", "supplementary")) {
    errors <- c(errors, paste("Finding", finding$finding_id %||% "unknown", "has invalid importance."))
  }
  service_result(if (length(errors)) "error" else "success", value = finding, errors = errors)
}

validate_report_findings <- function(findings) {
  findings <- findings %||% list()
  errors <- character()
  ids <- vapply(findings, function(finding) finding$finding_id %||% NA_character_, character(1))
  duplicates <- unique(ids[!is.na(ids) & duplicated(ids)])
  if (length(duplicates)) {
    errors <- c(errors, paste("Duplicate report finding IDs:", paste(duplicates, collapse = ", ")))
  }
  results <- lapply(findings, validate_report_finding)
  errors <- c(errors, unlist(lapply(results, function(result) result$errors), use.names = FALSE))
  service_result(if (length(errors)) "error" else "success", value = findings, errors = errors)
}

validate_report_metadata <- function(metadata) {
  if (!is.list(metadata)) {
    return(service_result(status = "error", errors = "Report metadata must be a list."))
  }
  service_result(status = "success", value = metadata)
}

validate_report <- function(report) {
  errors <- character()
  warnings <- character()
  if (!inherits(report, "report_contract")) {
    errors <- c(errors, "Report must inherit from report_contract.")
  }
  for (field in c("contract_version", "schema_version", "report_id", "title", "report_type")) {
    if (is.null(report[[field]]) || !nzchar(as.character(report[[field]]))) {
      errors <- c(errors, paste("ReportContract is missing required field:", field))
    }
  }

  version <- validate_contract_version(report$contract_version, report$schema_version)
  capabilities <- validate_capabilities(report$capabilities)
  profile <- validate_presentation_profile(report$presentation_profile)
  components <- validate_components(report$components)
  findings <- validate_report_findings(report$findings)
  metadata <- validate_report_metadata(report$metadata %||% list())

  for (result in list(version, capabilities, profile, components, findings, metadata)) {
    errors <- c(errors, result$errors)
    warnings <- c(warnings, result$warnings)
  }

  sections <- report$sections %||% list()
  if (!is.list(sections)) {
    errors <- c(errors, "ReportContract sections must be a list.")
  } else {
    section_ids <- vapply(sections, function(section) section$section_id %||% NA_character_, character(1))
    duplicate_sections <- unique(section_ids[!is.na(section_ids) & duplicated(section_ids)])
    if (length(duplicate_sections)) {
      errors <- c(errors, paste("Duplicate report section IDs:", paste(duplicate_sections, collapse = ", ")))
    }
    component_ids <- vapply(report$components %||% list(), function(component) component$component_id %||% NA_character_, character(1))
    referenced <- unique(unlist(lapply(sections, function(section) section$components %||% character()), use.names = FALSE))
    missing_refs <- setdiff(referenced, component_ids)
    if (length(missing_refs)) {
      errors <- c(errors, paste("Report sections reference missing components:", paste(missing_refs, collapse = ", ")))
    }
  }

  if (!length(report$components %||% list())) {
    warnings <- c(warnings, "ReportContract has no components.")
  }

  status <- if (length(errors)) "error" else if (length(warnings)) "warning" else "success"
  service_result(
    status = status,
    value = report,
    warnings = warnings,
    errors = errors,
    diagnostics = list(
      component_count = length(report$components %||% list()),
      section_count = length(report$sections %||% list()),
      capability_count = length(report$capabilities %||% character())
    )
  )
}

report_to_list <- function(report) {
  unclass_report <- function(value) {
    if (is.list(value)) {
      value <- unclass(value)
      return(lapply(value, unclass_report))
    }
    value
  }
  unclass_report(report)
}

restore_report_classes <- function(report) {
  report$presentation_profile <- structure(report$presentation_profile %||% list(), class = c("presentation_profile", "list"))
  report$components <- lapply(report$components %||% list(), function(component) {
    structure(component, class = c("report_component", "list"))
  })
  report$findings <- lapply(report$findings %||% list(), function(finding) {
    structure(finding, class = c("report_finding", "list"))
  })
  structure(report, class = c("report_contract", "list"))
}

serialize_report <- function(report, pretty = TRUE) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for report serialization.", call. = FALSE)
  }
  jsonlite::toJSON(report_to_list(report), auto_unbox = TRUE, null = "null", pretty = pretty, digits = NA)
}

deserialize_report <- function(json) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for report deserialization.", call. = FALSE)
  }
  parsed <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  restore_report_classes(parsed)
}

report_summary <- function(report) {
  validation <- validate_report(report)
  data.table::data.table(
    report_id = report$report_id %||% NA_character_,
    report_type = report$report_type %||% NA_character_,
    title = report$title %||% NA_character_,
    contract_version = report$contract_version %||% NA_character_,
    schema_version = report$schema_version %||% NA_character_,
    mode = report$mode %||% NA_character_,
    sections = length(report$sections %||% list()),
    components = length(report$components %||% list()),
    findings = length(report$findings %||% list()),
    recommendations = length(report$recommendations %||% list()),
    capabilities = paste(report$capabilities %||% character(), collapse = ", "),
    validation_status = validation$status
  )
}

validate_analytics_service_outputs <- function(canonical_analysis_result, artifact_bundle, report_contract) {
  errors <- character()
  if (!inherits(canonical_analysis_result, "canonical_analysis_result")) {
    errors <- c(errors, "Analytics Service output is missing CanonicalAnalysisResult.")
  }
  if (!inherits(artifact_bundle, "project_artifact_bundle")) {
    errors <- c(errors, "Analytics Service output is missing ArtifactBundle/project_artifact_bundle.")
  }
  report_validation <- validate_report(report_contract)
  errors <- c(errors, report_validation$errors)
  service_result(
    status = if (length(errors)) "error" else if (length(report_validation$warnings)) "warning" else "success",
    errors = errors,
    warnings = report_validation$warnings,
    diagnostics = list(report_validation = report_validation$diagnostics)
  )
}

qa_report_contract_runtime <- function() {
  checks <- list()
  add <- function(check, status, message) {
    checks[[length(checks) + 1L]] <<- data.table::data.table(check = check, status = status, message = message)
  }

  profile <- create_presentation_profile(density = "compact", theme = "dark")
  report <- create_report_contract(
    report_id = "qa_report",
    title = "QA Report",
    report_type = "qa",
    analysis_ids = "analysis_1",
    presentation_profile = profile,
    capabilities = c("interactive", "evidence_trace", "export_html")
  )
  report <- add_component(report, report_component_title("QA Report"), section_id = "summary")
  report <- add_component(report, report_component_orientation("Can the report runtime validate?"), section_id = "summary")
  report <- add_component(report, report_component_executive_summary("The runtime can build and validate semantic report contracts."), section_id = "summary")
  report <- add_component(report, report_component_metric_summary(list(rows = 10L, columns = 3L)), section_id = "summary")
  report <- add_component(report, report_component_narrative("Narrative text."), section_id = "summary")
  report <- add_component(report, report_component_visualization(plot_ref = "plot_1", caption = "Example plot reference."), section_id = "summary")
  report <- add_component(report, report_component_table(table_ref = "table_1"), section_id = "summary")
  report <- add_component(report, report_component_diagnostic(status = "passed", messages = "No issues."), section_id = "summary")
  report <- add_component(report, report_component_methodology("Deterministic QA fixture."), section_id = "summary")
  report <- add_component(report, report_component_evidence_link("artifact_1"), section_id = "summary")
  report <- add_component(report, report_component_technical_appendix("Appendix content."), section_id = "summary")
  report <- add_finding(report, "Report contracts can be validated.")
  report$recommendations <- list(list(recommendation_id = "rec_1", action = "Proceed to Phase 2 after review."))

  validation <- validate_report(report)
  add("valid_contract", if (identical(validation$status, "success")) "success" else "error", paste(c(validation$errors, validation$warnings, "Report validates."), collapse = " "))

  json <- tryCatch(serialize_report(report), error = function(e) e)
  add("serialization", if (is.character(json) && nzchar(json)) "success" else "error", if (is.character(json)) "Report serialized to JSON." else conditionMessage(json))

  restored <- tryCatch(deserialize_report(json), error = function(e) e)
  restored_validation <- if (inherits(restored, "report_contract")) validate_report(restored) else service_result(status = "error", errors = conditionMessage(restored))
  add("deserialization", if (identical(restored_validation$status, "success")) "success" else "error", paste(c(restored_validation$errors, restored_validation$warnings, "Report deserialized and validates."), collapse = " "))

  duplicate <- report
  duplicate$components <- c(duplicate$components, list(duplicate$components[[1]]))
  duplicate_validation <- validate_report(duplicate)
  add("duplicate_detection", if (identical(duplicate_validation$status, "error") && any(grepl("Duplicate report component IDs", duplicate_validation$errors))) "success" else "error", "Duplicate component IDs are detected.")

  malformed <- create_report_component("table", component_id = "bad_table", payload = list())
  malformed_validation <- validate_report_component(malformed)
  add("malformed_component_detection", if (identical(malformed_validation$status, "error")) "success" else "error", "Malformed table component is rejected.")

  bad_capabilities <- validate_capabilities(c("interactive", "telepathy"))
  add("capability_validation", if (identical(bad_capabilities$status, "error")) "success" else "error", "Unsupported capabilities are rejected.")

  bad_version <- validate_contract_version("9.9.9", report_contract_schema_version)
  add("version_warning", if (identical(bad_version$status, "warning")) "success" else "error", "Version mismatch produces a warning.")

  profile_validation <- validate_presentation_profile(profile)
  add("presentation_profile_validation", if (identical(profile_validation$status, "success")) "success" else "error", "PresentationProfile validates.")

  summary <- report_summary(report)
  add("report_summary", if (nrow(summary) == 1L && identical(summary$report_id[[1]], "qa_report")) "success" else "error", "Report summary returns one row.")

  data.table::rbindlist(checks)
}
