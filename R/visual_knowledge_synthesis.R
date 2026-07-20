VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION <- "0.1.0"

if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}

visual_knowledge_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

visual_knowledge_hash <- function(value) {
  if (requireNamespace("digest", quietly = TRUE)) {
    return(digest::digest(value, algo = "xxhash64"))
  }
  paste(charToRaw(paste(utils::capture.output(str(value)), collapse = "|")), collapse = "")
}

visual_knowledge_slug <- function(value) {
  value <- tolower(trimws(as.character(value %||% "")))
  value <- gsub("[^a-z0-9]+", "_", value)
  value <- gsub("^_|_$", "", value)
  if (!nzchar(value)) "item" else value
}

visual_knowledge_normalize_statement <- function(value) {
  value <- tolower(trimws(as.character(value %||% "")))
  value <- gsub("[^a-z0-9 ]+", " ", value)
  gsub("\\s+", " ", value)
}

visual_knowledge_claim_type_registry <- function() {
  list(
    observation = list(label = "Observation", requires_evidence = TRUE),
    calculation = list(label = "Calculation", requires_evidence = TRUE),
    inference = list(label = "Inference", requires_evidence = TRUE),
    interpretation = list(label = "Interpretation", requires_evidence = TRUE),
    recommendation = list(label = "Recommendation", requires_evidence = TRUE),
    limitation = list(label = "Limitation", requires_evidence = FALSE),
    assumption = list(label = "Assumption", requires_evidence = FALSE),
    hypothesis = list(label = "Hypothesis", requires_evidence = FALSE),
    open_question = list(label = "Open Question", requires_evidence = FALSE),
    conflict = list(label = "Conflict", requires_evidence = TRUE),
    consensus = list(label = "Consensus", requires_evidence = TRUE)
  )
}

visual_knowledge_graph_edge_type_registry <- function() {
  c(
    "supports", "contradicts", "depends_on", "derived_from", "visualizes",
    "references", "requires", "supersedes", "summarizes"
  )
}

visual_knowledge_review_dimension_registry <- function() {
  list(
    strength_of_evidence = "Evidence strength",
    conflicts = "Contradictory evidence",
    evidence_gaps = "Evidence gaps",
    uncertainty = "Uncertainty",
    duplicate_findings = "Duplicate findings",
    provenance_integrity = "Provenance integrity"
  )
}

visual_knowledge_synthesis_strategy_registry <- function() {
  list(
    consensus = list(
      label = "Consensus",
      intent = "Emphasize claims supported by multiple artifacts before disputed claims."
    ),
    balanced = list(
      label = "Balanced",
      intent = "Present supported claims, conflicts, gaps, and assumptions together."
    ),
    exploratory = list(
      label = "Exploratory",
      intent = "Surface hypotheses and open questions for further investigation."
    ),
    executive = list(
      label = "Executive",
      intent = "Compress the defensible answer, uncertainty, and next action."
    )
  )
}

visual_knowledge_empty_state <- function() {
  list(
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION,
    evidence_contexts = list(),
    claims = list(),
    reviews = list(),
    graphs = list(),
    coverage_matrices = list(),
    conflicts = list(),
    strategies = list(),
    branches = list(),
    decisions = list(),
    history = list(),
    active_context_id = NULL,
    active_review_id = NULL,
    active_strategy_id = NULL,
    active_branch_id = NULL
  )
}

visual_knowledge_normalize_document <- function(document) {
  document <- visual_document_normalize(document)
  document$knowledge_synthesis <- document$knowledge_synthesis %||% visual_knowledge_empty_state()
  defaults <- visual_knowledge_empty_state()
  for (field in names(defaults)) {
    document$knowledge_synthesis[[field]] <- document$knowledge_synthesis[[field]] %||% defaults[[field]]
  }
  document$knowledge_synthesis$schema_version <- VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  document
}

visual_knowledge_artifact_id <- function(artifact, index = 1L) {
  artifact$artifact_id %||% artifact$id %||% artifact$name %||%
    paste0("artifact_", sprintf("%03d", as.integer(index)))
}

visual_knowledge_extract_text_items <- function(value) {
  if (is.null(value)) return(character())
  if (is.character(value)) return(value[nzchar(value)])
  if (is.list(value)) {
    items <- vapply(value, function(item) {
      if (is.character(item)) return(item[[1]])
      if (is.list(item)) return(item$statement %||% item$title %||% item$text %||% item$recommendation %||% "")
      ""
    }, character(1))
    return(items[nzchar(items)])
  }
  character()
}

visual_knowledge_create_evidence_context <- function(
  artifacts,
  project_id = "current_project",
  active_filters = list(),
  context_id = NULL
) {
  artifacts <- artifacts %||% list()
  if (!is.list(artifacts)) {
    stop("EvidenceContext artifacts must be a list.", call. = FALSE)
  }

  normalized <- list()
  for (index in seq_along(artifacts)) {
    artifact <- artifacts[[index]]
    artifact_id <- visual_knowledge_artifact_id(artifact, index)
    normalized[[artifact_id]] <- list(
      artifact_id = artifact_id,
      title = artifact$title %||% artifact$name %||% artifact_id,
      artifact_type = artifact$artifact_type %||% artifact$type %||% "evidence_artifact",
      version = artifact$version %||% artifact$schema_version %||% "unknown",
      generated_at = artifact$generated_at %||% artifact$timestamp %||% artifact$created_at %||% NA_character_,
      quality_status = artifact$quality_status %||% artifact$status %||% "unknown",
      findings = visual_knowledge_extract_text_items(artifact$findings %||% artifact$finding),
      recommendations = visual_knowledge_extract_text_items(artifact$recommendations %||% artifact$recommendation),
      limitations = visual_knowledge_extract_text_items(artifact$limitations %||% artifact$limitation),
      assumptions = visual_knowledge_extract_text_items(artifact$assumptions %||% artifact$assumption),
      contradicts = artifact$contradicts %||% artifact$contradicting_evidence_ids %||% character(),
      lineage = artifact$lineage %||% artifact$provenance %||% list()
    )
  }

  basis <- list(project_id = project_id, artifact_ids = names(normalized), active_filters = active_filters)
  context_id <- context_id %||% paste0("evidence_context_", substr(visual_knowledge_hash(basis), 1L, 10L))
  list(
    context_id = context_id,
    project_id = project_id,
    created_at = visual_knowledge_timestamp(),
    active_filters = active_filters,
    artifacts = normalized,
    artifact_ids = names(normalized),
    artifact_count = length(normalized),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION,
    provenance = list(
      creation_pathway = "visual_studio_governed_knowledge_synthesis",
      source = "evidence_context",
      artifact_ids = names(normalized)
    )
  )
}

visual_knowledge_create_claim <- function(
  statement,
  claim_type = "observation",
  supporting_evidence_ids = character(),
  contradicting_evidence_ids = character(),
  originating_artifacts = character(),
  confidence = "medium",
  uncertainty = "not_assessed",
  rationale = "",
  metadata = list(),
  claim_id = NULL
) {
  claim_type <- visual_knowledge_slug(claim_type)
  if (!claim_type %in% names(visual_knowledge_claim_type_registry())) {
    stop("Unsupported knowledge claim type: ", claim_type, call. = FALSE)
  }
  statement <- trimws(as.character(statement %||% ""))
  if (!nzchar(statement)) {
    stop("KnowledgeClaim statement is required.", call. = FALSE)
  }
  basis <- list(statement = statement, claim_type = claim_type, evidence = supporting_evidence_ids, artifacts = originating_artifacts)
  claim_id <- claim_id %||% paste0("claim_", substr(visual_knowledge_hash(basis), 1L, 12L))
  list(
    claim_id = claim_id,
    claim_type = claim_type,
    statement = statement,
    normalized_statement = visual_knowledge_normalize_statement(statement),
    confidence = confidence,
    uncertainty = uncertainty,
    supporting_evidence_ids = unique(as.character(supporting_evidence_ids %||% character())),
    contradicting_evidence_ids = unique(as.character(contradicting_evidence_ids %||% character())),
    originating_artifacts = unique(as.character(originating_artifacts %||% character())),
    rationale = rationale,
    metadata = metadata,
    status = "proposed",
    created_at = visual_knowledge_timestamp(),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
}

visual_knowledge_generate_claims <- function(evidence_context) {
  claims <- list()
  for (artifact_id in names(evidence_context$artifacts %||% list())) {
    artifact <- evidence_context$artifacts[[artifact_id]]
    add_claim <- function(statement, claim_type, suffix) {
      claim <- visual_knowledge_create_claim(
        statement = statement,
        claim_type = claim_type,
        supporting_evidence_ids = artifact_id,
        contradicting_evidence_ids = artifact$contradicts %||% character(),
        originating_artifacts = artifact_id,
        confidence = if (identical(artifact$quality_status, "failed")) "low" else "medium",
        rationale = paste("Claim extracted from", artifact$title %||% artifact_id),
        claim_id = paste0("claim_", suffix, "_", substr(visual_knowledge_hash(list(artifact_id, statement)), 1L, 10L))
      )
      claims[[claim$claim_id]] <<- claim
    }
    for (statement in artifact$findings %||% character()) add_claim(statement, "observation", "finding")
    for (statement in artifact$recommendations %||% character()) add_claim(statement, "recommendation", "recommendation")
    for (statement in artifact$limitations %||% character()) add_claim(statement, "limitation", "limitation")
    for (statement in artifact$assumptions %||% character()) add_claim(statement, "assumption", "assumption")
  }
  claims
}

visual_knowledge_detect_agreements <- function(claims) {
  groups <- split(claims, vapply(claims, function(claim) claim$normalized_statement %||% "", character(1)))
  agreements <- list()
  for (statement in names(groups)) {
    group <- groups[[statement]]
    artifacts <- unique(unlist(lapply(group, function(claim) claim$originating_artifacts %||% character()), use.names = FALSE))
    if (nzchar(statement) && length(group) > 1L && length(artifacts) > 1L) {
      agreement_id <- paste0("agreement_", substr(visual_knowledge_hash(list(statement, artifacts)), 1L, 10L))
      agreements[[agreement_id]] <- list(
        agreement_id = agreement_id,
        statement = group[[1]]$statement,
        claim_ids = names(group),
        artifact_ids = artifacts,
        agreement_type = "independent_support",
        schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
      )
    }
  }
  agreements
}

visual_knowledge_detect_conflicts <- function(claims) {
  conflicts <- list()
  for (claim in claims) {
    contradicted <- claim$contradicting_evidence_ids %||% character()
    if (!length(contradicted) && claim$claim_type != "conflict") next
    conflict_id <- paste0("conflict_", substr(visual_knowledge_hash(list(claim$claim_id, contradicted)), 1L, 10L))
    conflicts[[conflict_id]] <- list(
      conflict_id = conflict_id,
      claim_id = claim$claim_id,
      statement = claim$statement,
      supporting_evidence_ids = claim$supporting_evidence_ids %||% character(),
      contradicting_evidence_ids = contradicted,
      status = "unresolved",
      reason = "Claim carries explicit contradicting evidence references.",
      schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
    )
  }
  conflicts
}

visual_knowledge_coverage_matrix <- function(claims, evidence_context, conflicts = list()) {
  rows <- lapply(claims, function(claim) {
    supported <- length(claim$supporting_evidence_ids %||% character())
    contradicted <- length(claim$contradicting_evidence_ids %||% character())
    data.frame(
      claim_id = claim$claim_id,
      claim_type = claim$claim_type,
      coverage = if (supported > 1L) "well_investigated" else if (supported == 1L) "partially_investigated" else "not_investigated",
      supported_by = supported,
      contradicted_by = contradicted,
      artifact_count = length(unique(claim$originating_artifacts %||% character())),
      stringsAsFactors = FALSE
    )
  })
  if (!length(rows)) {
    return(data.frame(
      claim_id = character(), claim_type = character(), coverage = character(),
      supported_by = integer(), contradicted_by = integer(), artifact_count = integer(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

visual_knowledge_build_evidence_graph <- function(evidence_context, claims = list()) {
  nodes <- list()
  edges <- list()
  for (artifact_id in names(evidence_context$artifacts %||% list())) {
    artifact <- evidence_context$artifacts[[artifact_id]]
    nodes[[artifact_id]] <- list(id = artifact_id, node_type = "artifact", label = artifact$title %||% artifact_id)
  }
  for (claim_id in names(claims %||% list())) {
    claim <- claims[[claim_id]]
    nodes[[claim_id]] <- list(id = claim_id, node_type = "claim", label = claim$statement)
    for (evidence_id in claim$supporting_evidence_ids %||% character()) {
      edges[[paste(claim_id, evidence_id, "supports", sep = "_")]] <- list(
        from = evidence_id, to = claim_id, edge_type = "supports"
      )
    }
    for (evidence_id in claim$contradicting_evidence_ids %||% character()) {
      edges[[paste(claim_id, evidence_id, "contradicts", sep = "_")]] <- list(
        from = evidence_id, to = claim_id, edge_type = "contradicts"
      )
    }
  }
  list(
    graph_id = paste0("evidence_graph_", substr(visual_knowledge_hash(list(evidence_context$context_id, names(claims))), 1L, 10L)),
    context_id = evidence_context$context_id,
    nodes = nodes,
    edges = edges,
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
}

visual_knowledge_create_synthesis_review <- function(evidence_context, claims = NULL) {
  claims <- claims %||% visual_knowledge_generate_claims(evidence_context)
  agreements <- visual_knowledge_detect_agreements(claims)
  conflicts <- visual_knowledge_detect_conflicts(claims)
  coverage <- visual_knowledge_coverage_matrix(claims, evidence_context, conflicts)
  graph <- visual_knowledge_build_evidence_graph(evidence_context, claims)
  review_id <- paste0("synthesis_review_", substr(visual_knowledge_hash(list(evidence_context$context_id, names(claims))), 1L, 10L))
  dimensions <- list(
    strength_of_evidence = list(status = if (length(claims)) "reviewed" else "missing", finding = paste(length(claims), "claim(s) extracted")),
    conflicts = list(status = if (length(conflicts)) "needs_attention" else "clear", finding = paste(length(conflicts), "conflict(s) detected")),
    evidence_gaps = list(status = if (any(coverage$coverage == "not_investigated")) "needs_attention" else "reviewed", finding = "Coverage matrix computed"),
    uncertainty = list(status = "reviewed", finding = "Claims retain uncertainty fields"),
    duplicate_findings = list(status = if (length(agreements)) "reviewed" else "clear", finding = paste(length(agreements), "independent agreement(s) detected")),
    provenance_integrity = list(status = if (all(vapply(claims, function(claim) length(claim$originating_artifacts) > 0L, logical(1)))) "clear" else "needs_attention", finding = "Claim provenance checked")
  )
  list(
    review_id = review_id,
    context_id = evidence_context$context_id,
    created_at = visual_knowledge_timestamp(),
    dimensions = dimensions,
    claims = claims,
    agreements = agreements,
    conflicts = conflicts,
    coverage_matrix = coverage,
    evidence_graph = graph,
    recommended_synthesis_strategies = names(visual_knowledge_synthesis_strategy_registry()),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
}

visual_knowledge_store_review <- function(document, evidence_context, review = NULL) {
  document <- visual_knowledge_normalize_document(document)
  review <- review %||% visual_knowledge_create_synthesis_review(evidence_context)
  document$knowledge_synthesis$evidence_contexts[[evidence_context$context_id]] <- evidence_context
  for (claim in review$claims %||% list()) {
    document$knowledge_synthesis$claims[[claim$claim_id]] <- claim
  }
  document$knowledge_synthesis$reviews[[review$review_id]] <- review
  document$knowledge_synthesis$graphs[[review$evidence_graph$graph_id]] <- review$evidence_graph
  document$knowledge_synthesis$coverage_matrices[[review$review_id]] <- review$coverage_matrix
  for (conflict in review$conflicts %||% list()) {
    document$knowledge_synthesis$conflicts[[conflict$conflict_id]] <- conflict
  }
  document$knowledge_synthesis$active_context_id <- evidence_context$context_id
  document$knowledge_synthesis$active_review_id <- review$review_id
  document$knowledge_synthesis$history <- append(document$knowledge_synthesis$history, list(list(
    type = "synthesis_review_created",
    review_id = review$review_id,
    context_id = evidence_context$context_id,
    at = visual_knowledge_timestamp()
  )))
  visual_knowledge_normalize_document(document)
}

visual_knowledge_claim_object <- function(claim, strategy_key, order) {
  type <- switch(
    claim$claim_type,
    recommendation = "recommendation",
    limitation = "limitation",
    assumption = "methodology",
    open_question = "warning",
    conflict = "warning",
    "callout"
  )
  visual_make_object(
    id = paste0("knowledge_", strategy_key, "_", substr(visual_knowledge_hash(claim$claim_id), 1L, 8L)),
    type = type,
    label = visual_knowledge_claim_type_registry()[[claim$claim_type]]$label %||% "Knowledge Claim",
    parent = "canvas_001",
    renderer = visual_renderer_adapter(list(type = type)),
    role = paste0("knowledge_", claim$claim_type),
    properties = if (identical(type, "callout")) {
      list(`callout.label` = visual_knowledge_claim_type_registry()[[claim$claim_type]]$label, `callout.value` = claim$statement, content = claim$rationale)
    } else {
      list(content = claim$statement)
    },
    evidence_refs = unique(c(claim$supporting_evidence_ids, claim$originating_artifacts)),
    extension = list(
      knowledge_synthesis = list(
        creation_pathway = "governed_knowledge_synthesis",
        claim_id = claim$claim_id,
        claim_type = claim$claim_type,
        strategy_key = strategy_key,
        supporting_evidence_ids = claim$supporting_evidence_ids,
        contradicting_evidence_ids = claim$contradicting_evidence_ids,
        schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
      )
    ),
    order = order,
    layout = list(x = 1, y = order, width = 12, height = 2, unit = "grid", z = order)
  )
}

visual_knowledge_strategy_claims <- function(review, strategy_key) {
  claims <- review$claims %||% list()
  if (!length(claims)) return(list())
  if (identical(strategy_key, "consensus")) {
    agreement_claim_ids <- unique(unlist(lapply(review$agreements %||% list(), function(agreement) agreement$claim_ids), use.names = FALSE))
    selected <- claims[names(claims) %in% agreement_claim_ids]
    if (length(selected)) return(selected)
  }
  if (identical(strategy_key, "executive")) {
    selected <- claims[vapply(claims, function(claim) claim$claim_type %in% c("recommendation", "observation", "limitation"), logical(1))]
    return(utils::head(selected, 4L))
  }
  if (identical(strategy_key, "exploratory")) {
    selected <- claims[vapply(claims, function(claim) claim$claim_type %in% c("hypothesis", "open_question", "assumption", "limitation"), logical(1))]
    if (length(selected)) return(selected)
  }
  utils::head(claims, 6L)
}

visual_knowledge_create_strategy <- function(document, review, strategy_key) {
  registry <- visual_knowledge_synthesis_strategy_registry()
  template <- registry[[strategy_key]]
  if (is.null(template)) {
    stop("Unknown knowledge synthesis strategy: ", strategy_key, call. = FALSE)
  }
  selected_claims <- visual_knowledge_strategy_claims(review, strategy_key)
  objects <- list()
  order <- 30L
  for (claim in selected_claims) {
    order <- order + 1L
    object <- visual_knowledge_claim_object(claim, strategy_key, order)
    objects[[object$id]] <- object
  }
  strategy_id <- paste0("knowledge_strategy_", strategy_key, "_", substr(visual_knowledge_hash(list(review$review_id, names(selected_claims))), 1L, 8L))
  list(
    strategy_id = strategy_id,
    strategy_key = strategy_key,
    review_id = review$review_id,
    label = template$label,
    intent = template$intent,
    status = "proposed",
    claim_ids = names(selected_claims),
    semantic_objects = objects,
    provenance = list(
      creation_pathway = "governed_knowledge_synthesis",
      review_id = review$review_id,
      context_id = review$context_id
    ),
    created_at = visual_knowledge_timestamp(),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
}

visual_knowledge_generate_strategies <- function(document, review = NULL) {
  document <- visual_knowledge_normalize_document(document)
  review <- review %||% document$knowledge_synthesis$reviews[[document$knowledge_synthesis$active_review_id]]
  if (is.null(review)) {
    stop("No synthesis review is available.", call. = FALSE)
  }
  strategies <- lapply(names(visual_knowledge_synthesis_strategy_registry()), function(strategy_key) {
    visual_knowledge_create_strategy(document, review, strategy_key)
  })
  names(strategies) <- vapply(strategies, function(strategy) strategy$strategy_id, character(1))
  for (strategy in strategies) {
    document$knowledge_synthesis$strategies[[strategy$strategy_id]] <- strategy
  }
  document$knowledge_synthesis$active_strategy_id <- strategies[[1]]$strategy_id
  document$knowledge_synthesis$history <- append(document$knowledge_synthesis$history, list(list(
    type = "synthesis_strategies_generated",
    strategy_ids = names(strategies),
    at = visual_knowledge_timestamp()
  )))
  visual_knowledge_normalize_document(document)
}

visual_knowledge_get_strategy <- function(document, strategy_id = NULL) {
  document <- visual_knowledge_normalize_document(document)
  strategy_id <- strategy_id %||% document$knowledge_synthesis$active_strategy_id
  if (is.null(strategy_id)) return(NULL)
  document$knowledge_synthesis$strategies[[strategy_id]]
}

visual_knowledge_apply_objects <- function(document, strategy, object_ids = NULL) {
  object_ids <- object_ids %||% names(strategy$semantic_objects %||% list())
  for (object_id in object_ids) {
    object <- strategy$semantic_objects[[object_id]]
    if (is.null(object)) next
    if (object$id %in% names(document$objects)) next
    document <- visual_document_add_object(document, object, parent_id = object$parent %||% "canvas_001", select = FALSE)
  }
  visual_knowledge_normalize_document(document)
}

visual_knowledge_create_branch <- function(document, strategy_id = NULL, object_ids = NULL) {
  document <- visual_knowledge_normalize_document(document)
  strategy <- visual_knowledge_get_strategy(document, strategy_id)
  if (is.null(strategy)) {
    stop("No knowledge synthesis strategy is available for preview.", call. = FALSE)
  }
  preview <- visual_knowledge_apply_objects(visual_document_snapshot(document), strategy, object_ids)
  branch_id <- paste0("knowledge_branch_", substr(visual_knowledge_hash(list(document$id, strategy$strategy_id, object_ids)), 1L, 10L))
  document$knowledge_synthesis$branches[[branch_id]] <- list(
    branch_id = branch_id,
    strategy_id = strategy$strategy_id,
    object_ids = object_ids %||% names(strategy$semantic_objects %||% list()),
    status = "preview",
    preview_document = preview,
    created_at = visual_knowledge_timestamp(),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
  document$knowledge_synthesis$active_branch_id <- branch_id
  visual_knowledge_normalize_document(document)
}

visual_knowledge_claim_supported <- function(claim) {
  registry <- visual_knowledge_claim_type_registry()
  required <- isTRUE(registry[[claim$claim_type]]$requires_evidence)
  !required || length(claim$supporting_evidence_ids %||% character()) > 0L
}

visual_knowledge_accept_strategy <- function(document, strategy_id = NULL, object_ids = NULL, claim_ids = NULL) {
  document <- visual_knowledge_normalize_document(document)
  strategy <- visual_knowledge_get_strategy(document, strategy_id)
  if (is.null(strategy)) {
    stop("No knowledge synthesis strategy is available for acceptance.", call. = FALSE)
  }
  claim_ids <- claim_ids %||% strategy$claim_ids %||% character()
  unsupported <- claim_ids[vapply(claim_ids, function(claim_id) {
    claim <- document$knowledge_synthesis$claims[[claim_id]]
    is.null(claim) || !visual_knowledge_claim_supported(claim)
  }, logical(1))]
  if (length(unsupported)) {
    stop("Cannot accept unsupported knowledge claim(s): ", paste(unsupported, collapse = ", "), call. = FALSE)
  }
  document <- visual_knowledge_apply_objects(document, strategy, object_ids)
  for (claim_id in claim_ids) {
    if (!is.null(document$knowledge_synthesis$claims[[claim_id]])) {
      document$knowledge_synthesis$claims[[claim_id]]$status <- "accepted"
    }
  }
  document$knowledge_synthesis$strategies[[strategy$strategy_id]]$status <- "accepted"
  decision_id <- paste0("knowledge_decision_", substr(visual_knowledge_hash(list(strategy$strategy_id, claim_ids, object_ids)), 1L, 10L))
  document$knowledge_synthesis$decisions[[decision_id]] <- list(
    decision_id = decision_id,
    strategy_id = strategy$strategy_id,
    accepted_claim_ids = claim_ids,
    accepted_object_ids = object_ids %||% names(strategy$semantic_objects %||% list()),
    status = "accepted",
    at = visual_knowledge_timestamp(),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
  visual_knowledge_normalize_document(document)
}

visual_knowledge_reject_strategy <- function(document, strategy_id = NULL, reason = "Rejected by user") {
  document <- visual_knowledge_normalize_document(document)
  strategy <- visual_knowledge_get_strategy(document, strategy_id)
  if (is.null(strategy)) {
    stop("No knowledge synthesis strategy is available for rejection.", call. = FALSE)
  }
  document$knowledge_synthesis$strategies[[strategy$strategy_id]]$status <- "rejected"
  document$knowledge_synthesis$strategies[[strategy$strategy_id]]$rejection_reason <- reason
  document$knowledge_synthesis$history <- append(document$knowledge_synthesis$history, list(list(
    type = "synthesis_strategy_rejected",
    strategy_id = strategy$strategy_id,
    reason = reason,
    at = visual_knowledge_timestamp()
  )))
  visual_knowledge_normalize_document(document)
}

visual_knowledge_validate <- function(document) {
  issues <- character()
  document <- visual_knowledge_normalize_document(document)
  synthesis <- document$knowledge_synthesis %||% list()
  if (!identical(synthesis$schema_version, VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION)) {
    issues <- c(issues, "knowledge synthesis schema_version is not current")
  }
  claim_types <- names(visual_knowledge_claim_type_registry())
  for (claim_id in names(synthesis$claims %||% list())) {
    claim <- synthesis$claims[[claim_id]]
    if (!identical(claim$schema_version %||% NULL, VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION)) {
      issues <- c(issues, paste("knowledge claim schema_version is not current", claim_id))
    }
    if (!claim$claim_type %in% claim_types) {
      issues <- c(issues, paste("knowledge claim has unsupported type", claim_id))
    }
    if (!nzchar(claim$statement %||% "")) {
      issues <- c(issues, paste("knowledge claim missing statement", claim_id))
    }
    if (!visual_knowledge_claim_supported(claim) && identical(claim$status %||% "proposed", "accepted")) {
      issues <- c(issues, paste("accepted knowledge claim lacks required evidence", claim_id))
    }
  }
  for (review_id in names(synthesis$reviews %||% list())) {
    review <- synthesis$reviews[[review_id]]
    required <- c("review_id", "context_id", "dimensions", "claims", "coverage_matrix", "evidence_graph", "schema_version")
    missing <- setdiff(required, names(review))
    if (length(missing)) {
      issues <- c(issues, paste("synthesis review missing fields", review_id, paste(missing, collapse = ", ")))
    }
    missing_dimensions <- setdiff(names(visual_knowledge_review_dimension_registry()), names(review$dimensions %||% list()))
    if (length(missing_dimensions)) {
      issues <- c(issues, paste("synthesis review missing dimensions", review_id, paste(missing_dimensions, collapse = ", ")))
    }
  }
  edge_types <- visual_knowledge_graph_edge_type_registry()
  for (graph_id in names(synthesis$graphs %||% list())) {
    graph <- synthesis$graphs[[graph_id]]
    node_ids <- names(graph$nodes %||% list())
    for (edge_id in names(graph$edges %||% list())) {
      edge <- graph$edges[[edge_id]]
      if (!edge$edge_type %in% edge_types) {
        issues <- c(issues, paste("knowledge graph edge has unsupported type", edge_id))
      }
      if (!edge$from %in% node_ids || !edge$to %in% node_ids) {
        issues <- c(issues, paste("knowledge graph edge references missing node", edge_id))
      }
    }
  }
  for (strategy_id in names(synthesis$strategies %||% list())) {
    strategy <- synthesis$strategies[[strategy_id]]
    if (!strategy$strategy_key %in% names(visual_knowledge_synthesis_strategy_registry())) {
      issues <- c(issues, paste("knowledge strategy has unsupported key", strategy_id))
    }
    missing_claims <- setdiff(strategy$claim_ids %||% character(), names(synthesis$claims %||% list()))
    if (length(missing_claims)) {
      issues <- c(issues, paste("knowledge strategy references missing claims", strategy_id, paste(missing_claims, collapse = ", ")))
    }
    for (object_id in names(strategy$semantic_objects %||% list())) {
      object <- strategy$semantic_objects[[object_id]]
      if (!identical(object$extension$knowledge_synthesis$creation_pathway %||% NULL, "governed_knowledge_synthesis")) {
        issues <- c(issues, paste("synthesis object missing governed pathway", object_id))
      }
    }
  }
  list(status = if (length(issues)) "error" else "success", issues = unique(issues))
}

visual_knowledge_integrity_findings <- function(document) {
  validation <- visual_knowledge_validate(document)
  document <- visual_knowledge_normalize_document(document)
  synthesis <- document$knowledge_synthesis
  unsupported <- names(Filter(function(claim) !visual_knowledge_claim_supported(claim), synthesis$claims %||% list()))
  list(
    status = validation$status,
    validation_issues = validation$issues,
    unsupported_claim_ids = unsupported,
    conflict_count = length(synthesis$conflicts %||% list()),
    accepted_claim_count = sum(vapply(synthesis$claims %||% list(), function(claim) identical(claim$status, "accepted"), logical(1))),
    strategy_count = length(synthesis$strategies %||% list())
  )
}

qa_knowledge_synthesis <- function() {
  document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "date", YVar = "sales"),
    options = list(Theme = "dark"),
    plot_name = "Synthesis proof"
  )
  artifacts <- list(
    list(
      artifact_id = "eda_summary",
      title = "EDA Summary",
      type = "eda",
      quality_status = "passed",
      findings = c("Revenue increased in premium segments.", "Mobile traffic has missing campaign tags."),
      limitations = "EDA cannot establish causal impact."
    ),
    list(
      artifact_id = "model_insights",
      title = "Regression Model Insights",
      type = "model",
      quality_status = "passed",
      findings = c("Revenue increased in premium segments."),
      recommendations = "Prioritize premium segment creative refresh after reviewing tracking gaps."
    ),
    list(
      artifact_id = "regional_exception",
      title = "Regional Exception",
      type = "diagnostic",
      quality_status = "passed",
      findings = "Premium segment growth is weaker in the West.",
      contradicts = "model_insights"
    )
  )
  context <- visual_knowledge_create_evidence_context(artifacts, project_id = "qa_project")
  review <- visual_knowledge_create_synthesis_review(context)
  document <- visual_knowledge_store_review(document, context, review)
  document <- visual_knowledge_generate_strategies(document, review)
  strategy <- visual_knowledge_get_strategy(document)
  canonical_count <- length(document$objects)
  branch <- visual_knowledge_create_branch(document, strategy$strategy_id)
  preview_count <- length(branch$knowledge_synthesis$branches[[branch$knowledge_synthesis$active_branch_id]]$preview_document$objects)
  branch_canonical_count <- length(branch$objects)
  document <- visual_knowledge_accept_strategy(document, strategy$strategy_id, claim_ids = strategy$claim_ids)
  rejected <- visual_knowledge_reject_strategy(document, names(document$knowledge_synthesis$strategies)[[2]], reason = "QA preserves rejected alternatives.")
  roundtrip <- visual_document_roundtrip(rejected)
  validation <- visual_document_validate(rejected)
  synthesis_validation <- visual_knowledge_validate(rejected)
  integrity <- visual_knowledge_integrity_findings(rejected)
  graph <- rejected$knowledge_synthesis$graphs[[review$evidence_graph$graph_id]]
  coverage <- rejected$knowledge_synthesis$coverage_matrices[[review$review_id]]
  old_document <- visual_document_from_plot_spec("Area", mappings = list(XVar = "x", YVar = "y"))
  old_document$knowledge_synthesis <- NULL
  normalized_old <- visual_knowledge_normalize_document(old_document)
  unsupported_claim <- visual_knowledge_create_claim(
    "Unsupported recommendation should not be accepted.",
    claim_type = "recommendation",
    supporting_evidence_ids = character(),
    originating_artifacts = character()
  )
  rejected$knowledge_synthesis$claims[[unsupported_claim$claim_id]] <- unsupported_claim
  rejected$knowledge_synthesis$strategies$unsupported_test <- list(
    strategy_id = "unsupported_test",
    strategy_key = "executive",
    review_id = review$review_id,
    label = "Unsupported",
    intent = "Should fail",
    status = "proposed",
    claim_ids = unsupported_claim$claim_id,
    semantic_objects = list(),
    schema_version = VISUAL_KNOWLEDGE_SYNTHESIS_SCHEMA_VERSION
  )
  dependency_guard <- tryCatch({
    visual_knowledge_accept_strategy(rejected, "unsupported_test")
    FALSE
  }, error = function(e) TRUE)

  data.frame(
    check = c(
      "evidence context records artifacts",
      "claims generated from artifacts",
      "independent agreement detected",
      "explicit conflict detected",
      "coverage matrix created",
      "evidence graph connects nodes",
      "strategy registry has four bounded strategies",
      "strategies stored on document",
      "preview branch does not mutate canonical objects",
      "accepted strategy mutates canonical document",
      "rejected strategy is preserved",
      "roundtrip persists knowledge synthesis",
      "visual document validator includes synthesis",
      "synthesis validator succeeds",
      "integrity findings summarize state",
      "older documents normalize safely",
      "unsupported acceptance fails loudly",
      "renderer boundary remains AutoPlots"
    ),
    status = c(
      if (length(context$artifact_ids) == 3L) "success" else "error",
      if (length(review$claims) >= 5L) "success" else "error",
      if (length(review$agreements) >= 1L) "success" else "error",
      if (length(review$conflicts) >= 1L) "success" else "error",
      if (nrow(coverage) == length(review$claims)) "success" else "error",
      if (length(graph$nodes) >= length(context$artifact_ids) && length(graph$edges) >= length(review$claims)) "success" else "error",
      if (length(visual_knowledge_synthesis_strategy_registry()) == 4L) "success" else "error",
      if (length(document$knowledge_synthesis$strategies) == 4L) "success" else "error",
      if (preview_count > canonical_count && branch_canonical_count == canonical_count) "success" else "error",
      if (length(document$objects) > canonical_count) "success" else "error",
      if (any(vapply(rejected$knowledge_synthesis$strategies, function(item) identical(item$status, "rejected"), logical(1)))) "success" else "error",
      if (!is.null(roundtrip$knowledge_synthesis)) "success" else "error",
      validation$status,
      synthesis_validation$status,
      if (integrity$strategy_count >= 4L) "success" else "error",
      if (!is.null(normalized_old$knowledge_synthesis)) "success" else "error",
      if (isTRUE(dependency_guard)) "success" else "error",
      if (any(vapply(document$objects, function(object) identical(object$renderer, "AutoPlots"), logical(1)))) "success" else "error"
    ),
    stringsAsFactors = FALSE
  )
}
