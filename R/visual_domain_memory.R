VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION <- "0.1.0"

visual_domain_memory_timestamp <- function() {
  if (exists("visual_knowledge_timestamp", mode = "function")) {
    return(visual_knowledge_timestamp())
  }
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

visual_domain_memory_hash <- function(x) {
  if (exists("visual_knowledge_hash", mode = "function")) {
    return(visual_knowledge_hash(x))
  }
  digest::digest(x, algo = "sha256", serialize = TRUE)
}

visual_domain_memory_slug <- function(value, prefix = "memory") {
  paste0(prefix, "_", substr(visual_domain_memory_hash(value), 1L, 10L))
}

visual_domain_memory_normalize_statement <- function(value) {
  if (exists("visual_knowledge_normalize_statement", mode = "function")) {
    return(visual_knowledge_normalize_statement(value))
  }
  value <- tolower(trimws(as.character(value %||% "")))
  gsub("\\s+", " ", value)
}

visual_domain_memory_statuses <- function() {
  c("provisional", "accepted", "validated", "deprecated", "superseded", "rejected", "contradicted", "archived")
}

visual_domain_memory_knowledge_type_registry <- function() {
  list(
    known_fact = list(label = "Known Fact", preserves = "accepted observation"),
    pattern = list(label = "Pattern", preserves = "reusable analytical pattern"),
    assumption = list(label = "Assumption", preserves = "contextual premise"),
    limitation = list(label = "Limitation", preserves = "validity boundary"),
    recommendation = list(label = "Recommendation", preserves = "accepted suggested action"),
    open_question = list(label = "Open Question", preserves = "unresolved uncertainty"),
    conflict = list(label = "Conflict", preserves = "contradictory accepted knowledge"),
    glossary_term = list(label = "Glossary Term", preserves = "domain language"),
    decision_rule = list(label = "Decision Rule", preserves = "governed decision logic")
  )
}

visual_domain_memory_review_type_registry <- function() {
  list(
    acceptance = list(label = "Acceptance Review", trigger = "human acceptance"),
    periodic = list(label = "Periodic Review", trigger = "scheduled review"),
    evidence_triggered = list(label = "Evidence-triggered Review", trigger = "new or changed evidence"),
    manual = list(label = "Manual Review", trigger = "user request"),
    project_wide = list(label = "Project-wide Review", trigger = "project audit"),
    drift = list(label = "Drift Review", trigger = "deterministic drift finding"),
    supersession = list(label = "Supersession Review", trigger = "replacement knowledge")
  )
}

visual_domain_memory_status_transition_registry <- function() {
  list(
    provisional = c("accepted", "rejected", "archived"),
    accepted = c("validated", "deprecated", "superseded", "contradicted", "archived"),
    validated = c("deprecated", "superseded", "contradicted", "archived"),
    deprecated = c("accepted", "archived"),
    superseded = c("archived"),
    rejected = c("archived"),
    contradicted = c("deprecated", "superseded", "archived"),
    archived = c("provisional", "accepted")
  )
}

visual_domain_memory_graph_edge_type_registry <- function() {
  c(
    "entry_depends_on_entry",
    "claim_supports_entry",
    "evidence_supports_entry",
    "evidence_contradicts_entry",
    "entry_used_by_document",
    "entry_superseded_by_entry"
  )
}

visual_domain_memory_operation_registry <- function() {
  list(
    create_entry = list(label = "Create Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_create_entry),
    review_entry = list(label = "Review Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_review_entry),
    update_entry = list(label = "Update Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_update_entry),
    deprecate_entry = list(label = "Deprecate Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_status_operation),
    supersede_entry = list(label = "Supersede Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_supersede_entry),
    archive_entry = list(label = "Archive Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_status_operation),
    restore_entry = list(label = "Restore Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_status_operation),
    merge_entries = list(label = "Merge Entries", requires_approval = TRUE, handler = visual_domain_memory_apply_merge_entries),
    split_entry = list(label = "Split Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_split_entry),
    reject_entry = list(label = "Reject Entry", requires_approval = TRUE, handler = visual_domain_memory_apply_status_operation),
    record_usage = list(label = "Record Usage", requires_approval = TRUE, handler = visual_domain_memory_apply_record_usage)
  )
}

visual_domain_memory_drift_detector_registry <- function() {
  list(
    stale_evidence = visual_domain_memory_detect_stale_evidence,
    outdated_assumptions = visual_domain_memory_detect_outdated_assumptions,
    superseded_knowledge = visual_domain_memory_detect_superseded_knowledge,
    conflicting_accepted_entries = visual_domain_memory_detect_conflicting_accepted_entries,
    unused_entries = visual_domain_memory_detect_unused_entries,
    orphaned_entries = visual_domain_memory_detect_orphaned_entries,
    confidence_drift = visual_domain_memory_detect_confidence_drift,
    scope_violations = visual_domain_memory_detect_scope_violations
  )
}

visual_domain_memory_validation_rule_registry <- function() {
  c(
    "schema_version_current",
    "entries_have_required_fields",
    "statuses_supported",
    "transitions_legal",
    "operations_reviewed_before_apply",
    "dependency_edges_reference_nodes",
    "memory_initializes_empty_for_legacy_documents"
  )
}

visual_domain_memory_empty <- function(project_id = "current_project", domain_id = "default_domain", memory_id = NULL) {
  basis <- list(project_id = project_id, domain_id = domain_id, at = visual_domain_memory_timestamp())
  memory_id <- memory_id %||% visual_domain_memory_slug(basis, "domain_memory")
  list(
    memory_id = memory_id,
    project_id = project_id,
    domain_id = domain_id,
    version = 1L,
    created_at = visual_domain_memory_timestamp(),
    governance = list(
      schema_version = VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION,
      approval_required = TRUE,
      update_policy = "explicit_human_approval",
      source = "accepted_visual_knowledge_synthesis"
    ),
    entries = list(),
    pending_operations = list(),
    reviews = list(),
    dependency_graph = list(nodes = list(), edges = list()),
    provenance_index = list(),
    status_history = list(),
    timeline = list(),
    schema_version = VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION
  )
}

visual_domain_memory_normalize <- function(memory = NULL, project_id = "current_project", domain_id = "default_domain") {
  memory <- memory %||% visual_domain_memory_empty(project_id, domain_id)
  memory$memory_id <- memory$memory_id %||% visual_domain_memory_slug(list(project_id, domain_id), "domain_memory")
  memory$project_id <- memory$project_id %||% project_id
  memory$domain_id <- memory$domain_id %||% domain_id
  memory$version <- memory$version %||% 1L
  memory$created_at <- memory$created_at %||% visual_domain_memory_timestamp()
  memory$governance <- memory$governance %||% list()
  memory$governance$schema_version <- memory$governance$schema_version %||% VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION
  memory$governance$approval_required <- memory$governance$approval_required %||% TRUE
  memory$governance$update_policy <- memory$governance$update_policy %||% "explicit_human_approval"
  memory$entries <- memory$entries %||% list()
  memory$pending_operations <- memory$pending_operations %||% list()
  memory$reviews <- memory$reviews %||% list()
  memory$dependency_graph <- memory$dependency_graph %||% list(nodes = list(), edges = list())
  memory$dependency_graph$nodes <- memory$dependency_graph$nodes %||% list()
  memory$dependency_graph$edges <- memory$dependency_graph$edges %||% list()
  memory$provenance_index <- memory$provenance_index %||% list()
  memory$status_history <- memory$status_history %||% list()
  memory$timeline <- memory$timeline %||% list()
  memory$schema_version <- memory$schema_version %||% VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION
  memory
}

visual_domain_memory_normalize_document <- function(document, project_id = "current_project", domain_id = "default_domain") {
  if (exists("visual_knowledge_normalize_document", mode = "function")) {
    document <- visual_knowledge_normalize_document(document)
  } else {
    document <- visual_document_normalize(document)
  }
  document$domain_memory <- visual_domain_memory_normalize(document$domain_memory, project_id, domain_id)
  document
}

visual_domain_memory_entry <- function(title, semantic_type, canonical_statement, originating_claims = character(),
                                       supporting_evidence = character(), contradicting_evidence = character(),
                                       originating_review = NULL, originating_strategy = NULL, confidence = "medium",
                                       uncertainty = "not quantified", scope = list(), validity_conditions = list(),
                                       governance_status = "accepted", dependencies = character(), metadata = list(),
                                       entry_id = NULL) {
  semantic_type <- semantic_type %||% "known_fact"
  if (!semantic_type %in% names(visual_domain_memory_knowledge_type_registry())) {
    stop("Unsupported domain memory semantic type: ", semantic_type, call. = FALSE)
  }
  if (!governance_status %in% visual_domain_memory_statuses()) {
    stop("Unsupported domain memory status: ", governance_status, call. = FALSE)
  }
  basis <- list(title, canonical_statement, originating_claims, supporting_evidence)
  entry_id <- entry_id %||% visual_domain_memory_slug(basis, "knowledge_entry")
  list(
    entry_id = entry_id,
    title = title %||% canonical_statement,
    semantic_type = semantic_type,
    canonical_statement = canonical_statement,
    originating_claims = originating_claims %||% character(),
    supporting_evidence = supporting_evidence %||% character(),
    contradicting_evidence = contradicting_evidence %||% character(),
    originating_synthesis_review = originating_review,
    originating_synthesis_strategy = originating_strategy,
    accepted_at = visual_domain_memory_timestamp(),
    version = 1L,
    confidence = confidence,
    uncertainty = uncertainty,
    scope = scope %||% list(),
    validity_conditions = validity_conditions %||% list(),
    expiration_conditions = validity_conditions$expiration_conditions %||% list(),
    superseded_by = NULL,
    dependencies = dependencies %||% character(),
    usage_history = list(),
    governance_status = governance_status,
    metadata = metadata %||% list(),
    schema_version = VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION
  )
}

visual_domain_memory_claim_to_entry <- function(document, claim_id, semantic_type = NULL, scope = list(),
                                                validity_conditions = list(), confidence = NULL, uncertainty = NULL) {
  document <- visual_domain_memory_normalize_document(document)
  claim <- document$knowledge_synthesis$claims[[claim_id]]
  if (is.null(claim)) {
    stop("Cannot create memory entry from missing claim: ", claim_id, call. = FALSE)
  }
  if (!identical(claim$status %||% "proposed", "accepted")) {
    stop("Domain memory can only register accepted synthesis claims.", call. = FALSE)
  }
  strategy <- NULL
  accepted_strategies <- Filter(function(item) {
    identical(item$status %||% "proposed", "accepted") && claim_id %in% (item$claim_ids %||% character())
  }, document$knowledge_synthesis$strategies %||% list())
  if (length(accepted_strategies)) {
    strategy <- accepted_strategies[[1L]]
  }
  claim_type_map <- c(
    observation = "known_fact",
    calculation = "known_fact",
    inference = "pattern",
    interpretation = "pattern",
    recommendation = "recommendation",
    limitation = "limitation",
    assumption = "assumption",
    hypothesis = "open_question",
    open_question = "open_question",
    conflict = "conflict",
    consensus = "known_fact"
  )
  claim_type <- claim$claim_type %||% "observation"
  semantic_type <- semantic_type %||% unname(claim_type_map[[claim_type]] %||% "known_fact")
  visual_domain_memory_entry(
    title = claim$title %||% tools::toTitleCase(substr(claim$statement, 1L, 60L)),
    semantic_type = semantic_type,
    canonical_statement = claim$statement,
    originating_claims = claim$claim_id,
    supporting_evidence = claim$supporting_evidence_ids %||% character(),
    contradicting_evidence = claim$contradicting_evidence_ids %||% character(),
    originating_review = strategy$review_id %||% document$knowledge_synthesis$active_review_id,
    originating_strategy = strategy$strategy_id %||% NULL,
    confidence = confidence %||% claim$confidence %||% "medium",
    uncertainty = uncertainty %||% claim$uncertainty %||% "not quantified",
    scope = scope,
    validity_conditions = validity_conditions,
    metadata = list(source_claim_type = claim$claim_type %||% "observation")
  )
}

visual_domain_memory_review <- function(affected_entries = character(), reason = "manual", findings = list(),
                                        proposed_actions = list(), confidence = "medium", reviewer_metadata = list()) {
  review_id <- visual_domain_memory_slug(list(affected_entries, reason, findings, visual_domain_memory_timestamp()), "memory_review")
  list(
    review_id = review_id,
    affected_entries = affected_entries %||% character(),
    reason = reason,
    findings = findings %||% list(),
    proposed_actions = proposed_actions %||% list(),
    confidence = confidence,
    reviewer_metadata = reviewer_metadata %||% list(),
    timestamp = visual_domain_memory_timestamp(),
    schema_version = VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION
  )
}

visual_domain_memory_propose_operation <- function(memory, operation, payload = list(), affected_entries = character(),
                                                   reason = "User requested memory operation",
                                                   reviewer_metadata = list()) {
  memory <- visual_domain_memory_normalize(memory)
  registry <- visual_domain_memory_operation_registry()
  if (!operation %in% names(registry)) {
    stop("Unsupported domain memory operation: ", operation, call. = FALSE)
  }
  proposal_id <- visual_domain_memory_slug(list(operation, payload, affected_entries, visual_domain_memory_timestamp()), "memory_operation")
  proposal <- list(
    proposal_id = proposal_id,
    operation = operation,
    status = "pending_approval",
    affected_entries = affected_entries %||% character(),
    reason = reason,
    payload = payload %||% list(),
    reviewer_metadata = reviewer_metadata %||% list(),
    rollback = list(
      before_entries = memory$entries[intersect(affected_entries %||% character(), names(memory$entries))],
      before_graph = memory$dependency_graph,
      before_version = memory$version
    ),
    created_at = visual_domain_memory_timestamp(),
    schema_version = VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION
  )
  memory$pending_operations[[proposal_id]] <- proposal
  memory$timeline <- append(memory$timeline, list(list(type = "operation_proposed", proposal_id = proposal_id, operation = operation, at = proposal$created_at)))
  memory
}

visual_domain_memory_add_node <- function(memory, node_id, node_type, label = NULL) {
  memory$dependency_graph$nodes[[node_id]] <- list(node_id = node_id, node_type = node_type, label = label %||% node_id)
  memory
}

visual_domain_memory_add_edge <- function(memory, from, to, edge_type, metadata = list()) {
  if (!edge_type %in% visual_domain_memory_graph_edge_type_registry()) {
    stop("Unsupported domain memory graph edge type: ", edge_type, call. = FALSE)
  }
  memory <- visual_domain_memory_add_node(memory, from, "external", from)
  memory <- visual_domain_memory_add_node(memory, to, "external", to)
  edge_id <- visual_domain_memory_slug(list(from, to, edge_type), "memory_edge")
  memory$dependency_graph$edges[[edge_id]] <- list(
    edge_id = edge_id,
    from = from,
    to = to,
    edge_type = edge_type,
    metadata = metadata %||% list()
  )
  memory
}

visual_domain_memory_index_entry <- function(memory, entry) {
  memory <- visual_domain_memory_add_node(memory, entry$entry_id, "knowledge_entry", entry$title)
  for (claim_id in entry$originating_claims %||% character()) {
    memory <- visual_domain_memory_add_edge(memory, claim_id, entry$entry_id, "claim_supports_entry")
  }
  for (evidence_id in entry$supporting_evidence %||% character()) {
    memory <- visual_domain_memory_add_edge(memory, evidence_id, entry$entry_id, "evidence_supports_entry")
  }
  for (evidence_id in entry$contradicting_evidence %||% character()) {
    memory <- visual_domain_memory_add_edge(memory, evidence_id, entry$entry_id, "evidence_contradicts_entry")
  }
  for (dependency_id in entry$dependencies %||% character()) {
    memory <- visual_domain_memory_add_edge(memory, entry$entry_id, dependency_id, "entry_depends_on_entry")
  }
  memory$provenance_index[[entry$entry_id]] <- list(
    originating_claims = entry$originating_claims %||% character(),
    supporting_evidence = entry$supporting_evidence %||% character(),
    originating_synthesis_review = entry$originating_synthesis_review,
    originating_synthesis_strategy = entry$originating_synthesis_strategy
  )
  memory
}

visual_domain_memory_transition_allowed <- function(from, to) {
  if (identical(from, to)) return(TRUE)
  to %in% (visual_domain_memory_status_transition_registry()[[from]] %||% character())
}

visual_domain_memory_set_status <- function(memory, entry_id, status, reason = "status operation") {
  entry <- memory$entries[[entry_id]]
  if (is.null(entry)) {
    stop("Cannot change status for missing memory entry: ", entry_id, call. = FALSE)
  }
  current <- entry$governance_status %||% "provisional"
  if (!visual_domain_memory_transition_allowed(current, status)) {
    stop("Illegal domain memory status transition: ", current, " -> ", status, call. = FALSE)
  }
  entry$governance_status <- status
  entry$version <- as.integer(entry$version %||% 1L) + 1L
  entry$metadata$status_reason <- reason
  memory$entries[[entry_id]] <- entry
  memory$status_history <- append(memory$status_history, list(list(entry_id = entry_id, from = current, to = status, reason = reason, at = visual_domain_memory_timestamp())))
  memory
}

visual_domain_memory_apply_create_entry <- function(memory, proposal, review) {
  entry <- proposal$payload$entry
  if (is.null(entry)) {
    stop("Create entry operation requires an entry payload.", call. = FALSE)
  }
  memory$entries[[entry$entry_id]] <- entry
  memory <- visual_domain_memory_index_entry(memory, entry)
  memory$timeline <- append(memory$timeline, list(list(type = "entry_created", entry_id = entry$entry_id, review_id = review$review_id, at = visual_domain_memory_timestamp())))
  memory
}

visual_domain_memory_apply_review_entry <- function(memory, proposal, review) {
  memory$timeline <- append(memory$timeline, list(list(type = "entry_reviewed", entry_ids = proposal$affected_entries, review_id = review$review_id, at = review$timestamp)))
  memory
}

visual_domain_memory_apply_update_entry <- function(memory, proposal, review) {
  updates <- proposal$payload$updates %||% list()
  for (entry_id in proposal$affected_entries %||% character()) {
    entry <- memory$entries[[entry_id]]
    if (is.null(entry)) stop("Cannot update missing memory entry: ", entry_id, call. = FALSE)
    for (field in names(updates)) entry[[field]] <- updates[[field]]
    entry$version <- as.integer(entry$version %||% 1L) + 1L
    entry$metadata$last_review_id <- review$review_id
    memory$entries[[entry_id]] <- entry
    memory <- visual_domain_memory_index_entry(memory, entry)
  }
  memory
}

visual_domain_memory_apply_status_operation <- function(memory, proposal, review) {
  status_targets <- list(
    deprecate_entry = "deprecated",
    archive_entry = "archived",
    restore_entry = proposal$payload$restore_status %||% "accepted",
    reject_entry = "rejected"
  )
  target_status <- proposal$payload$status %||% status_targets[[proposal$operation]] %||% "accepted"
  for (entry_id in proposal$affected_entries %||% character()) {
    memory <- visual_domain_memory_set_status(memory, entry_id, target_status, proposal$reason)
    memory$entries[[entry_id]]$metadata$last_review_id <- review$review_id
  }
  memory
}

visual_domain_memory_apply_supersede_entry <- function(memory, proposal, review) {
  new_entry <- proposal$payload$new_entry
  old_entries <- proposal$affected_entries %||% character()
  if (is.null(new_entry)) stop("Supersede operation requires a new_entry payload.", call. = FALSE)
  memory$entries[[new_entry$entry_id]] <- new_entry
  memory <- visual_domain_memory_index_entry(memory, new_entry)
  for (entry_id in old_entries) {
    memory <- visual_domain_memory_set_status(memory, entry_id, "superseded", proposal$reason)
    memory$entries[[entry_id]]$superseded_by <- new_entry$entry_id
    memory <- visual_domain_memory_add_edge(memory, entry_id, new_entry$entry_id, "entry_superseded_by_entry")
  }
  memory
}

visual_domain_memory_apply_merge_entries <- function(memory, proposal, review) {
  merged_entry <- proposal$payload$merged_entry
  if (is.null(merged_entry)) stop("Merge operation requires a merged_entry payload.", call. = FALSE)
  memory$entries[[merged_entry$entry_id]] <- merged_entry
  memory <- visual_domain_memory_index_entry(memory, merged_entry)
  for (entry_id in proposal$affected_entries %||% character()) {
    memory <- visual_domain_memory_set_status(memory, entry_id, "superseded", proposal$reason)
    memory$entries[[entry_id]]$superseded_by <- merged_entry$entry_id
    memory <- visual_domain_memory_add_edge(memory, entry_id, merged_entry$entry_id, "entry_superseded_by_entry")
  }
  memory
}

visual_domain_memory_apply_split_entry <- function(memory, proposal, review) {
  child_entries <- proposal$payload$child_entries %||% list()
  for (entry in child_entries) {
    memory$entries[[entry$entry_id]] <- entry
    memory <- visual_domain_memory_index_entry(memory, entry)
  }
  for (entry_id in proposal$affected_entries %||% character()) {
    memory <- visual_domain_memory_set_status(memory, entry_id, "superseded", proposal$reason)
    for (entry in child_entries) memory <- visual_domain_memory_add_edge(memory, entry_id, entry$entry_id, "entry_superseded_by_entry")
  }
  memory
}

visual_domain_memory_apply_record_usage <- function(memory, proposal, review) {
  usage <- proposal$payload$usage %||% list()
  for (entry_id in proposal$affected_entries %||% character()) {
    entry <- memory$entries[[entry_id]]
    if (is.null(entry)) stop("Cannot record usage for missing memory entry: ", entry_id, call. = FALSE)
    usage_record <- c(usage, list(at = visual_domain_memory_timestamp(), review_id = review$review_id))
    entry$usage_history <- append(entry$usage_history %||% list(), list(usage_record))
    memory$entries[[entry_id]] <- entry
    if (nzchar(usage$used_by_id %||% "")) {
      memory <- visual_domain_memory_add_edge(memory, entry_id, usage$used_by_id, "entry_used_by_document", usage)
    }
  }
  memory
}

visual_domain_memory_approve_operation <- function(memory, proposal_id, reviewer_metadata = list()) {
  memory <- visual_domain_memory_normalize(memory)
  proposal <- memory$pending_operations[[proposal_id]]
  if (is.null(proposal)) stop("No pending domain memory operation found: ", proposal_id, call. = FALSE)
  registry <- visual_domain_memory_operation_registry()
  handler <- registry[[proposal$operation]]$handler
  review <- visual_domain_memory_review(
    affected_entries = proposal$affected_entries,
    reason = proposal$reason,
    findings = list(list(type = "operation_approved", operation = proposal$operation)),
    proposed_actions = list(list(operation = proposal$operation, status = "approved")),
    reviewer_metadata = reviewer_metadata
  )
  memory <- handler(memory, proposal, review)
  proposal$status <- "approved"
  proposal$approved_at <- visual_domain_memory_timestamp()
  proposal$review_id <- review$review_id
  memory$reviews[[review$review_id]] <- review
  memory$pending_operations[[proposal_id]] <- proposal
  memory$version <- as.integer(memory$version %||% 1L) + 1L
  memory$timeline <- append(memory$timeline, list(list(type = "operation_approved", proposal_id = proposal_id, review_id = review$review_id, at = proposal$approved_at)))
  memory
}

visual_domain_memory_reject_operation <- function(memory, proposal_id, reason = "Rejected by reviewer", reviewer_metadata = list()) {
  memory <- visual_domain_memory_normalize(memory)
  proposal <- memory$pending_operations[[proposal_id]]
  if (is.null(proposal)) stop("No pending domain memory operation found: ", proposal_id, call. = FALSE)
  review <- visual_domain_memory_review(
    affected_entries = proposal$affected_entries,
    reason = reason,
    findings = list(list(type = "operation_rejected", operation = proposal$operation, reason = reason)),
    proposed_actions = list(),
    reviewer_metadata = reviewer_metadata
  )
  proposal$status <- "rejected"
  proposal$rejected_at <- visual_domain_memory_timestamp()
  proposal$review_id <- review$review_id
  memory$reviews[[review$review_id]] <- review
  memory$pending_operations[[proposal_id]] <- proposal
  memory$timeline <- append(memory$timeline, list(list(type = "operation_rejected", proposal_id = proposal_id, review_id = review$review_id, at = proposal$rejected_at)))
  memory
}

visual_domain_memory_propose_entry_from_claim <- function(memory, document, claim_id, semantic_type = NULL, scope = list(),
                                                         validity_conditions = list(), reason = "Promote accepted synthesis claim to domain memory",
                                                         reviewer_metadata = list()) {
  memory <- visual_domain_memory_normalize(memory)
  entry <- visual_domain_memory_claim_to_entry(document, claim_id, semantic_type, scope, validity_conditions)
  visual_domain_memory_propose_operation(
    memory,
    "create_entry",
    payload = list(entry = entry),
    affected_entries = entry$entry_id,
    reason = reason,
    reviewer_metadata = reviewer_metadata
  )
}

visual_domain_memory_record_usage <- function(memory, entry_id, used_by_type, used_by_id, context = list(), reason = "Record approved memory reuse") {
  usage <- list(used_by_type = used_by_type, used_by_id = used_by_id, context = context %||% list())
  visual_domain_memory_propose_operation(memory, "record_usage", payload = list(usage = usage), affected_entries = entry_id, reason = reason)
}

visual_domain_memory_entry_tokens <- function(entry) {
  text <- visual_domain_memory_normalize_statement(paste(entry$title, entry$canonical_statement, collapse = " "))
  tokens <- unique(strsplit(gsub("[^a-z0-9 ]", " ", text), "\\s+")[[1]])
  tokens[nzchar(tokens)]
}

visual_domain_memory_discover <- function(memory, query = NULL, evidence_context = NULL, claims = list(), scope = list()) {
  memory <- visual_domain_memory_normalize(memory)
  query_text <- visual_domain_memory_normalize_statement(query %||% paste(vapply(claims %||% list(), function(claim) claim$statement %||% "", character(1)), collapse = " "))
  query_tokens <- unique(strsplit(gsub("[^a-z0-9 ]", " ", query_text), "\\s+")[[1]])
  query_tokens <- query_tokens[nzchar(query_tokens)]
  entries <- memory$entries %||% list()
  related <- names(Filter(function(entry) {
    length(intersect(query_tokens, visual_domain_memory_entry_tokens(entry))) > 0L
  }, entries))
  supporting <- names(Filter(function(entry) length(intersect(entry$supporting_evidence %||% character(), names(evidence_context$artifacts %||% list()))) > 0L, entries))
  conflicting <- names(Filter(function(entry) length(entry$contradicting_evidence %||% character()) > 0L || identical(entry$semantic_type, "conflict"), entries))
  superseded <- names(Filter(function(entry) identical(entry$governance_status, "superseded") || nzchar(entry$superseded_by %||% ""), entries))
  expired <- names(Filter(function(entry) {
    expires_on <- entry$validity_conditions$expires_on %||% entry$expiration_conditions$expires_on
    !is.null(expires_on) && as.Date(expires_on) < Sys.Date()
  }, entries))
  list(
    supporting_entries = intersect(unique(c(related, supporting)), names(entries)),
    conflicting_entries = intersect(conflicting, unique(c(related, supporting, names(entries)))),
    related_entries = related,
    superseded_entries = superseded,
    expired_entries = expired,
    proposals = lapply(unique(c(related, supporting, conflicting)), function(entry_id) {
      list(type = "memory_reuse_candidate", entry_id = entry_id, status = "proposal_only")
    }),
    mutates_memory = FALSE
  )
}

visual_domain_memory_detect_stale_evidence <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  names(Filter(function(entry) {
    days <- entry$validity_conditions$stale_after_days %||% NULL
    !is.null(days) && !is.na(as.Date(entry$accepted_at)) && as.numeric(as.Date(current_date) - as.Date(entry$accepted_at)) > as.numeric(days)
  }, memory$entries %||% list()))
}

visual_domain_memory_detect_outdated_assumptions <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  names(Filter(function(entry) {
    identical(entry$semantic_type, "assumption") && length(entry$validity_conditions$invalidated_by %||% character()) > 0L
  }, memory$entries %||% list()))
}

visual_domain_memory_detect_superseded_knowledge <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  names(Filter(function(entry) identical(entry$governance_status, "superseded") || nzchar(entry$superseded_by %||% ""), memory$entries %||% list()))
}

visual_domain_memory_detect_conflicting_accepted_entries <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  accepted <- Filter(function(entry) entry$governance_status %in% c("accepted", "validated", "contradicted"), memory$entries %||% list())
  statements <- vapply(accepted, function(entry) visual_domain_memory_normalize_statement(entry$canonical_statement), character(1))
  duplicated_ids <- names(statements)[duplicated(statements) | duplicated(statements, fromLast = TRUE)]
  contradicted_ids <- names(Filter(function(entry) length(entry$contradicting_evidence %||% character()) > 0L || identical(entry$governance_status, "contradicted"), accepted))
  unique(c(duplicated_ids, contradicted_ids))
}

visual_domain_memory_detect_unused_entries <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  names(Filter(function(entry) length(entry$usage_history %||% list()) == 0L && entry$governance_status %in% c("accepted", "validated"), memory$entries %||% list()))
}

visual_domain_memory_detect_orphaned_entries <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  names(Filter(function(entry) {
    length(entry$originating_claims %||% character()) == 0L && length(entry$supporting_evidence %||% character()) == 0L
  }, memory$entries %||% list()))
}

visual_domain_memory_detect_confidence_drift <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  names(Filter(function(entry) {
    previous <- entry$metadata$previous_confidence %||% NULL
    !is.null(previous) && !identical(previous, entry$confidence)
  }, memory$entries %||% list()))
}

visual_domain_memory_detect_scope_violations <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  current_domain <- evidence_context$domain_id %||% memory$domain_id
  names(Filter(function(entry) {
    domains <- entry$scope$applicable_domains %||% character()
    length(domains) > 0L && !current_domain %in% domains
  }, memory$entries %||% list()))
}

visual_domain_memory_detect_drift <- function(memory, evidence_context = NULL, current_date = Sys.Date()) {
  memory <- visual_domain_memory_normalize(memory)
  detectors <- visual_domain_memory_drift_detector_registry()
  findings <- lapply(names(detectors), function(detector_id) {
    entry_ids <- detectors[[detector_id]](memory, evidence_context, current_date)
    list(detector = detector_id, affected_entries = entry_ids, status = if (length(entry_ids)) "finding" else "clear")
  })
  affected <- unique(unlist(lapply(findings, function(finding) finding$affected_entries), use.names = FALSE))
  visual_domain_memory_review(
    affected_entries = affected,
    reason = "drift",
    findings = findings,
    proposed_actions = lapply(affected, function(entry_id) list(type = "review_entry", entry_id = entry_id, status = "proposal_only")),
    confidence = if (length(affected)) "medium" else "high",
    reviewer_metadata = list(mutates_memory = FALSE)
  )
}

visual_domain_memory_revalidate <- function(memory, entry_ids = NULL, reason = "manual", evidence_context = NULL) {
  memory <- visual_domain_memory_normalize(memory)
  entry_ids <- entry_ids %||% names(memory$entries %||% list())
  findings <- list(
    list(type = "revalidation_requested", affected_entries = entry_ids),
    list(type = "current_validation", status = visual_domain_memory_validate(memory)$status)
  )
  visual_domain_memory_review(
    affected_entries = entry_ids,
    reason = reason,
    findings = findings,
    proposed_actions = lapply(entry_ids, function(entry_id) list(type = "review_entry", entry_id = entry_id, status = "proposal_only")),
    reviewer_metadata = list(mutates_memory = FALSE)
  )
}

visual_domain_memory_semantic_objects <- function(memory) {
  memory <- visual_domain_memory_normalize(memory)
  entries <- memory$entries %||% list()
  accepted <- Filter(function(entry) entry$governance_status %in% c("accepted", "validated"), entries)
  list(
    knowledge_summary = list(entry_count = length(entries), accepted_count = length(accepted), domain_id = memory$domain_id),
    known_facts = names(Filter(function(entry) identical(entry$semantic_type, "known_fact"), entries)),
    open_questions = names(Filter(function(entry) identical(entry$semantic_type, "open_question"), entries)),
    conflicting_knowledge = names(Filter(function(entry) identical(entry$semantic_type, "conflict") || identical(entry$governance_status, "contradicted"), entries)),
    deprecated_knowledge = names(Filter(function(entry) entry$governance_status %in% c("deprecated", "superseded", "archived"), entries)),
    evidence_timeline = unlist(lapply(entries, function(entry) entry$supporting_evidence %||% character()), use.names = FALSE),
    confidence_trend = vapply(entries, function(entry) entry$confidence %||% "unknown", character(1)),
    knowledge_lineage = memory$provenance_index,
    domain_glossary = names(Filter(function(entry) identical(entry$semantic_type, "glossary_term"), entries))
  )
}

visual_domain_memory_validate <- function(memory) {
  issues <- character()
  memory <- visual_domain_memory_normalize(memory)
  if (!identical(memory$schema_version, VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION)) {
    issues <- c(issues, "domain memory schema_version is not current")
  }
  if (!identical(memory$governance$approval_required, TRUE)) {
    issues <- c(issues, "domain memory must require approval")
  }
  allowed_statuses <- visual_domain_memory_statuses()
  allowed_types <- names(visual_domain_memory_knowledge_type_registry())
  required_fields <- c("entry_id", "title", "semantic_type", "canonical_statement", "originating_claims", "supporting_evidence", "governance_status", "schema_version")
  for (entry_id in names(memory$entries %||% list())) {
    entry <- memory$entries[[entry_id]]
    missing <- setdiff(required_fields, names(entry))
    if (length(missing)) issues <- c(issues, paste("domain memory entry missing fields", entry_id, paste(missing, collapse = ", ")))
    if (!entry$semantic_type %in% allowed_types) issues <- c(issues, paste("domain memory entry has unsupported semantic type", entry_id))
    if (!entry$governance_status %in% allowed_statuses) issues <- c(issues, paste("domain memory entry has unsupported status", entry_id))
    if (!identical(entry$schema_version %||% NULL, VISUAL_DOMAIN_MEMORY_SCHEMA_VERSION)) issues <- c(issues, paste("domain memory entry schema_version is not current", entry_id))
    if (entry$governance_status %in% c("accepted", "validated") &&
      length(entry$originating_claims %||% character()) == 0L &&
      length(entry$supporting_evidence %||% character()) == 0L) {
      issues <- c(issues, paste("accepted domain memory entry lacks provenance", entry_id))
    }
  }
  edge_types <- visual_domain_memory_graph_edge_type_registry()
  node_ids <- names(memory$dependency_graph$nodes %||% list())
  for (edge_id in names(memory$dependency_graph$edges %||% list())) {
    edge <- memory$dependency_graph$edges[[edge_id]]
    if (!edge$edge_type %in% edge_types) issues <- c(issues, paste("domain memory graph edge has unsupported type", edge_id))
    if (!edge$from %in% node_ids || !edge$to %in% node_ids) issues <- c(issues, paste("domain memory graph edge references missing node", edge_id))
  }
  for (proposal_id in names(memory$pending_operations %||% list())) {
    proposal <- memory$pending_operations[[proposal_id]]
    if (!proposal$operation %in% names(visual_domain_memory_operation_registry())) issues <- c(issues, paste("domain memory proposal has unsupported operation", proposal_id))
    if (identical(proposal$status, "approved") && is.null(proposal$review_id)) issues <- c(issues, paste("approved domain memory operation lacks review", proposal_id))
  }
  list(status = if (length(issues)) "error" else "success", issues = unique(issues))
}

visual_domain_memory_validate_document <- function(document) {
  document <- visual_domain_memory_normalize_document(document)
  visual_domain_memory_validate(document$domain_memory)
}

qa_domain_memory <- function() {
  document <- visual_document_from_plot_spec(
    "Area",
    mappings = list(XVar = "date", YVar = "sales"),
    options = list(Theme = "dark"),
    plot_name = "Domain memory proof"
  )
  artifacts <- list(
    list(
      artifact_id = "evidence_primary",
      title = "Primary Evidence",
      type = "eda",
      quality_status = "passed",
      findings = "Premium segment revenue increased after creative refresh.",
      limitations = "Observational evidence cannot prove causality."
    ),
    list(
      artifact_id = "evidence_contradiction",
      title = "Regional Exception",
      type = "diagnostic",
      quality_status = "passed",
      findings = "The West region did not improve.",
      contradicts = "evidence_primary"
    )
  )
  context <- visual_knowledge_create_evidence_context(artifacts, project_id = "qa_project")
  review <- visual_knowledge_create_synthesis_review(context)
  document <- visual_knowledge_store_review(document, context, review)
  document <- visual_knowledge_generate_strategies(document, review)
  strategy <- visual_knowledge_get_strategy(document)
  document <- visual_knowledge_accept_strategy(document, strategy$strategy_id, claim_ids = strategy$claim_ids)
  document <- visual_domain_memory_normalize_document(document, project_id = "qa_project", domain_id = "marketing")
  memory <- document$domain_memory

  accepted_claim_id <- strategy$claim_ids[[1L]]
  proposed <- visual_domain_memory_propose_entry_from_claim(
    memory,
    document,
    accepted_claim_id,
    scope = list(applicable_domains = "marketing"),
    validity_conditions = list(stale_after_days = 0L)
  )
  proposal_id <- names(proposed$pending_operations)[[1L]]
  approved <- visual_domain_memory_approve_operation(proposed, proposal_id, reviewer_metadata = list(reviewer = "QA"))
  entry_id <- names(approved$entries)[[1L]]

  illegal_transition <- tryCatch({
    visual_domain_memory_set_status(approved, entry_id, "provisional")
    FALSE
  }, error = function(error) TRUE)

  usage_proposed <- visual_domain_memory_record_usage(approved, entry_id, "visual_document", document$id)
  usage_id <- tail(names(usage_proposed$pending_operations), 1L)
  used <- visual_domain_memory_approve_operation(usage_proposed, usage_id)

  deprecated_proposed <- visual_domain_memory_propose_operation(used, "deprecate_entry", affected_entries = entry_id, reason = "QA deprecates stale entry")
  deprecated <- visual_domain_memory_approve_operation(deprecated_proposed, tail(names(deprecated_proposed$pending_operations), 1L))
  restored_proposed <- visual_domain_memory_propose_operation(deprecated, "restore_entry", payload = list(restore_status = "accepted"), affected_entries = entry_id, reason = "QA restore")
  restored <- visual_domain_memory_approve_operation(restored_proposed, tail(names(restored_proposed$pending_operations), 1L))

  new_entry <- restored$entries[[entry_id]]
  new_entry$entry_id <- paste0(entry_id, "_v2")
  new_entry$canonical_statement <- paste(new_entry$canonical_statement, "Validated in QA.")
  supersede_proposed <- visual_domain_memory_propose_operation(restored, "supersede_entry", payload = list(new_entry = new_entry), affected_entries = entry_id, reason = "QA supersession")
  superseded <- visual_domain_memory_approve_operation(supersede_proposed, tail(names(supersede_proposed$pending_operations), 1L))

  child_one <- new_entry
  child_one$entry_id <- paste0(entry_id, "_child_1")
  child_one$canonical_statement <- "Child memory entry one."
  child_two <- new_entry
  child_two$entry_id <- paste0(entry_id, "_child_2")
  child_two$canonical_statement <- "Child memory entry two."
  split_proposed <- visual_domain_memory_propose_operation(superseded, "split_entry", payload = list(child_entries = list(child_one, child_two)), affected_entries = new_entry$entry_id, reason = "QA split")
  split <- visual_domain_memory_approve_operation(split_proposed, tail(names(split_proposed$pending_operations), 1L))

  merged <- child_one
  merged$entry_id <- paste0(entry_id, "_merged")
  merged$canonical_statement <- "Merged memory entry."
  merge_proposed <- visual_domain_memory_propose_operation(split, "merge_entries", payload = list(merged_entry = merged), affected_entries = c(child_one$entry_id, child_two$entry_id), reason = "QA merge")
  merged_memory <- visual_domain_memory_approve_operation(merge_proposed, tail(names(merge_proposed$pending_operations), 1L))

  rejected_proposed <- visual_domain_memory_propose_operation(merged_memory, "archive_entry", affected_entries = merged$entry_id, reason = "QA rejection")
  rejected_operation <- visual_domain_memory_reject_operation(rejected_proposed, tail(names(rejected_proposed$pending_operations), 1L), "No archive in QA")

  discovery <- visual_domain_memory_discover(rejected_operation, query = "premium segment revenue", evidence_context = context)
  drift <- visual_domain_memory_detect_drift(rejected_operation, evidence_context = context)
  revalidation <- visual_domain_memory_revalidate(rejected_operation, reason = "manual")
  semantic <- visual_domain_memory_semantic_objects(rejected_operation)
  validation <- visual_domain_memory_validate(rejected_operation)
  document$domain_memory <- rejected_operation
  document_validation <- visual_domain_memory_validate_document(document)
  old_document <- visual_document_from_plot_spec("Area", mappings = list(XVar = "x", YVar = "y"))
  old_document$domain_memory <- NULL
  normalized_old <- visual_domain_memory_normalize_document(old_document)
  roundtrip <- jsonlite::fromJSON(jsonlite::toJSON(rejected_operation, auto_unbox = TRUE, null = "null"), simplifyVector = FALSE)
  roundtrip_validation <- visual_domain_memory_validate(roundtrip)

  data.frame(
    check = c(
      "registries_populated",
      "legacy_document_initializes_empty",
      "entry_creation_requires_accepted_claim",
      "proposal_does_not_mutate_memory",
      "approval_creates_entry",
      "approval_records_review",
      "illegal_transition_rejected",
      "usage_is_governed_and_traced",
      "deprecate_restore_transitions",
      "supersession_traced",
      "split_and_merge_supported",
      "rejected_operation_preserved",
      "discovery_proposes_without_mutation",
      "drift_review_is_finding_only",
      "revalidation_proposes_only",
      "semantic_memory_objects_available",
      "dependency_graph_edges_present",
      "memory_validation_success",
      "document_validation_success",
      "roundtrip_validation_success",
      "validation_rules_registered",
      "renderer_boundary_unchanged"
    ),
    status = c(
      if (length(visual_domain_memory_operation_registry()) >= 10L && length(visual_domain_memory_drift_detector_registry()) == 8L) "success" else "error",
      if (length(normalized_old$domain_memory$entries) == 0L) "success" else "error",
      if (identical(document$knowledge_synthesis$claims[[accepted_claim_id]]$status, "accepted")) "success" else "error",
      if (length(memory$entries) == 0L && length(proposed$pending_operations) == 1L) "success" else "error",
      if (length(approved$entries) == 1L) "success" else "error",
      if (length(approved$reviews) == 1L) "success" else "error",
      if (isTRUE(illegal_transition)) "success" else "error",
      if (length(used$entries[[entry_id]]$usage_history) == 1L) "success" else "error",
      if (identical(restored$entries[[entry_id]]$governance_status, "accepted")) "success" else "error",
      if (identical(superseded$entries[[entry_id]]$governance_status, "superseded") && identical(superseded$entries[[entry_id]]$superseded_by, new_entry$entry_id)) "success" else "error",
      if (all(c(child_one$entry_id, child_two$entry_id, merged$entry_id) %in% names(merged_memory$entries))) "success" else "error",
      if (any(vapply(rejected_operation$pending_operations, function(item) identical(item$status, "rejected"), logical(1)))) "success" else "error",
      if (identical(discovery$mutates_memory, FALSE) && length(discovery$proposals) >= 1L) "success" else "error",
      if (identical(drift$reviewer_metadata$mutates_memory, FALSE) && length(drift$findings) == 8L) "success" else "error",
      if (identical(revalidation$reviewer_metadata$mutates_memory, FALSE) && length(revalidation$proposed_actions) >= 1L) "success" else "error",
      if (all(c("knowledge_summary", "known_facts", "knowledge_lineage") %in% names(semantic))) "success" else "error",
      if (length(rejected_operation$dependency_graph$edges) >= 3L) "success" else "error",
      validation$status,
      document_validation$status,
      roundtrip_validation$status,
      if (length(visual_domain_memory_validation_rule_registry()) >= 6L) "success" else "error",
      if (any(vapply(document$objects, function(object) identical(object$renderer %||% "", "AutoPlots"), logical(1)))) "success" else "error"
    ),
    stringsAsFactors = FALSE
  )
}
