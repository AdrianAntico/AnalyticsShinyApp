causal_effect_contract_fields <- function() {
  c(
    "causal_question_id", "estimand_id", "decision_context_id",
    "treatment_or_intervention", "comparison", "target_population",
    "analysis_population", "assignment_mechanism", "design_family",
    "estimator_family", "time_horizon", "outcome", "guardrail",
    "effect_scale", "point_estimate", "standard_error", "conf_low",
    "conf_high", "materiality", "readiness", "assumptions",
    "diagnostics", "sensitivity", "applicability", "permitted_claims",
    "prohibited_claims", "review_status", "lineage", "supported_actions"
  )
}

causal_extract_metadata <- function(artifact) {
  if (is.null(artifact)) return(list())
  artifact$metadata %||% artifact$artifact_metadata %||% list()
}

causal_design_family_from_metadata <- function(metadata) {
  source_contract <- tolower(metadata$source_contract %||% metadata$artifact_type %||% "")
  intent <- tolower(metadata$analytical_intent %||% metadata$caption %||% "")
  if (grepl("did|difference", source_contract) || grepl("difference-in-differences|did", intent)) return("time_based_observational")
  if (grepl("observational", source_contract) || grepl("aipw|observational", intent)) return("adjustment_based_observational")
  if (grepl("itt|random", source_contract) || grepl("randomized|intent-to-treat|itt", intent)) return("randomized")
  "unknown"
}

causal_estimator_family_from_metadata <- function(metadata) {
  source_contract <- tolower(metadata$source_contract %||% metadata$artifact_type %||% "")
  intent <- tolower(metadata$analytical_intent %||% metadata$caption %||% "")
  if (grepl("did|difference", source_contract) || grepl("difference-in-differences|did", intent)) return("classic_two_group_did")
  if (grepl("aipw", source_contract) || grepl("aipw", intent)) return("aipw")
  if (grepl("itt", source_contract) || grepl("itt|intent-to-treat", intent)) return("itt")
  metadata$estimator_family %||% "unknown"
}

causal_extract_numeric <- function(metadata, artifact, field) {
  value <- suppressWarnings(as.numeric(metadata[[field]] %||% NA_real_))
  if (is.finite(value)) return(value)
  object <- artifact$object %||% artifact$table %||% NULL
  if (is.data.frame(object) && field %in% names(object) && nrow(object)) {
    value <- suppressWarnings(as.numeric(object[[field]][[1]]))
    if (is.finite(value)) return(value)
  }
  NA_real_
}

causal_normalize_effect_artifact <- function(artifact) {
  metadata <- causal_extract_metadata(artifact)
  artifact_id <- artifact$artifact_id %||% metadata$artifact_id %||% NA_character_
  estimate <- causal_extract_numeric(metadata, artifact, "estimate")
  if (!is.finite(estimate)) estimate <- causal_extract_numeric(metadata, artifact, "point_estimate")
  conf_low <- causal_extract_numeric(metadata, artifact, "conf_low")
  conf_high <- causal_extract_numeric(metadata, artifact, "conf_high")
  design_family <- metadata$design_family %||% causal_design_family_from_metadata(metadata)
  estimator_family <- metadata$estimator_family %||% causal_estimator_family_from_metadata(metadata)
  readiness <- metadata$readiness %||% metadata$effect_status %||% metadata$status %||% if (isTRUE(metadata$effect_estimated %||% FALSE)) "estimate_requires_review" else "not_estimated"
  data.table::data.table(
    artifact_id = artifact_id,
    causal_question_id = metadata$causal_question_id %||% metadata$observational_study_id %||% metadata$analysis_id %||% NA_character_,
    estimand_id = metadata$estimand_id %||% metadata$estimand %||% NA_character_,
    decision_context_id = metadata$decision_context_id %||% NA_character_,
    treatment_or_intervention = metadata$treatment_or_intervention %||% metadata$treatment %||% metadata$intervention %||% NA_character_,
    comparison = metadata$comparison %||% NA_character_,
    target_population = metadata$target_population %||% NA_character_,
    analysis_population = metadata$analysis_population %||% metadata$population %||% NA_character_,
    assignment_mechanism = metadata$assignment_mechanism %||% NA_character_,
    design_family = design_family,
    estimator_family = estimator_family,
    time_horizon = metadata$time_horizon %||% metadata$outcome_window %||% NA_character_,
    outcome = metadata$outcome %||% metadata$outcome_col %||% NA_character_,
    guardrail = metadata$guardrail %||% NA_character_,
    effect_scale = metadata$effect_scale %||% "outcome_level_difference",
    point_estimate = estimate,
    standard_error = causal_extract_numeric(metadata, artifact, "standard_error"),
    conf_low = conf_low,
    conf_high = conf_high,
    materiality = metadata$materiality %||% metadata$materiality_state %||% "not_assessed",
    readiness = readiness,
    assumptions = paste(metadata$assumptions %||% character(), collapse = " | "),
    diagnostics = paste(metadata$diagnostics %||% character(), collapse = " | "),
    sensitivity = paste(metadata$sensitivity %||% character(), collapse = " | "),
    applicability = metadata$applicability %||% metadata$applicability_limitations %||% "requires_review",
    permitted_claims = paste(metadata$permitted_claims %||% character(), collapse = " | "),
    prohibited_claims = paste(metadata$prohibited_claims %||% character(), collapse = " | "),
    review_status = metadata$review_status %||% if (isTRUE(metadata$requires_human_review %||% TRUE)) "requires_human_review" else "not_required",
    lineage = metadata$frozen_design_hash %||% metadata$lineage %||% NA_character_,
    supported_actions = paste(metadata$supported_actions %||% "review_evidence", collapse = " | ")
  )
}

causal_effect_comparability <- function(left, right) {
  left <- if (is.data.frame(left)) left[1] else causal_normalize_effect_artifact(left)
  right <- if (is.data.frame(right)) right[1] else causal_normalize_effect_artifact(right)
  checks <- c("estimand_id", "target_population", "analysis_population", "effect_scale", "time_horizon", "outcome", "treatment_or_intervention", "comparison")
  mismatches <- checks[vapply(checks, function(field) {
    l <- left[[field]][[1]] %||% NA_character_
    r <- right[[field]][[1]] %||% NA_character_
    nzchar(l %||% "") && nzchar(r %||% "") && !identical(l, r)
  }, logical(1))]
  comparable <- !length(mismatches)
  data.table::data.table(
    comparable = comparable,
    relationship = if (comparable) "comparable_with_review" else "methodologically_incomparable",
    mismatch_fields = paste(mismatches, collapse = ", "),
    recommendation = if (comparable) {
      "Review diagnostics and assumptions before interpreting effects together; do not average estimates automatically."
    } else {
      "Do not compare side by side without reconciling estimand, population, scale, timing, outcome, treatment, and comparison."
    }
  )
}

causal_review_effect_set <- function(artifacts) {
  if (!length(artifacts)) {
    return(data.table::data.table(review_status = "empty", message = "No causal effect artifacts were supplied."))
  }
  normalized <- data.table::rbindlist(lapply(artifacts, causal_normalize_effect_artifact), fill = TRUE)
  if (nrow(normalized) < 2L) {
    normalized[, `:=`(review_relationship = "single_artifact", review_message = "One causal artifact is available; review diagnostics, assumptions, and claims before decision use.")]
    return(normalized)
  }
  pairs <- utils::combn(seq_len(nrow(normalized)), 2L, simplify = FALSE)
  pair_rows <- data.table::rbindlist(lapply(pairs, function(idx) {
    cmp <- causal_effect_comparability(normalized[idx[1]], normalized[idx[2]])
    direction <- if (is.finite(normalized$point_estimate[[idx[1]]]) && is.finite(normalized$point_estimate[[idx[2]]])) {
      if (sign(normalized$point_estimate[[idx[1]]]) == sign(normalized$point_estimate[[idx[2]]])) "directionally_consistent" else "materially_contradictory"
    } else {
      "unresolved"
    }
    data.table::data.table(
      artifact_id_a = normalized$artifact_id[[idx[1]]],
      artifact_id_b = normalized$artifact_id[[idx[2]]],
      design_family_a = normalized$design_family[[idx[1]]],
      design_family_b = normalized$design_family[[idx[2]]],
      relationship = if (isTRUE(cmp$comparable[[1]])) direction else cmp$relationship[[1]],
      mismatch_fields = cmp$mismatch_fields[[1]],
      recommendation = cmp$recommendation[[1]]
    )
  }), fill = TRUE)
  pair_rows
}

causal_design_selection_summary <- function(randomized_ready = FALSE, aipw_ready = FALSE, did_ready = FALSE, descriptive_only = FALSE, missing_prerequisites = character()) {
  eligible <- c(
    if (isTRUE(randomized_ready)) "randomized_analysis",
    if (isTRUE(aipw_ready)) "adjustment_based_observational",
    if (isTRUE(did_ready)) "classic_did",
    if (isTRUE(descriptive_only)) "descriptive_only"
  )
  if (!length(eligible)) eligible <- "unresolved_design_selection"
  data.table::data.table(
    design_status = if ("unresolved_design_selection" %in% eligible) "unresolved" else "eligible",
    eligible_methods = paste(eligible, collapse = ", "),
    missing_prerequisites = paste(missing_prerequisites, collapse = ", "),
    recommendation = if ("unresolved_design_selection" %in% eligible) "Collect design/readiness evidence before estimating." else "Select a method based on design evidence, not based on which estimate is favorable."
  )
}

causal_report_shell <- function(contract_row) {
  row <- if (is.data.frame(contract_row)) contract_row[1] else causal_normalize_effect_artifact(contract_row)
  list(
    report_type = "unified_causal_evidence_report",
    sections = c(
      "Business decision", "Causal question", "Estimand", "Design family and rationale",
      "Treatment and comparison", "Population and timing", "Readiness",
      "Data and implementation evidence", "Primary estimate", "Uncertainty",
      "Materiality", "Method-specific diagnostics", "Guardrails", "Sensitivity and falsification",
      "Applicability", "Contradictory evidence", "Permitted claims", "Prohibited claims",
      "Decision implications", "Recommended next action", "Review status", "Evidence lineage"
    ),
    design_family = row$design_family[[1]],
    estimator_family = row$estimator_family[[1]],
    review_status = row$review_status[[1]],
    prohibited_claims = row$prohibited_claims[[1]]
  )
}

qa_causal_cross_method_contracts <- function() {
  artifact <- function(id, design, estimator, estimate, estimand = "ATE", population = "customers", scale = "outcome_level_difference") {
    list(
      artifact_id = id,
      metadata = list(
        source_contract = paste0(estimator, "_effect_artifact"),
        analytical_intent = paste(design, estimator),
        design_family = design,
        estimator_family = estimator,
        causal_question_id = "cq_001",
        estimand = estimand,
        target_population = population,
        analysis_population = population,
        treatment_or_intervention = "offer",
        comparison = "no_offer",
        outcome = "revenue",
        time_horizon = "30_days",
        effect_scale = scale,
        estimate = estimate,
        assumptions = c("Explicit assumptions required."),
        diagnostics = c("Diagnostics preserved."),
        prohibited_claims = c("Do not claim design proves all assumptions."),
        requires_human_review = TRUE,
        frozen_design_hash = paste0("hash_", id)
      )
    )
  }
  randomized <- artifact("rand", "randomized", "itt", 2.0)
  aipw <- artifact("aipw", "adjustment_based_observational", "aipw", 1.8)
  did <- artifact("did", "time_based_observational", "classic_two_group_did", 2.1, estimand = "ATT")
  rand_contract <- causal_normalize_effect_artifact(randomized)
  aipw_contract <- causal_normalize_effect_artifact(aipw)
  did_contract <- causal_normalize_effect_artifact(did)
  comparable <- causal_effect_comparability(rand_contract, aipw_contract)
  incompatible <- causal_effect_comparability(rand_contract, did_contract)
  review <- causal_review_effect_set(list(randomized, aipw, did))
  design <- causal_design_selection_summary(randomized_ready = TRUE, aipw_ready = TRUE, did_ready = FALSE, missing_prerequisites = "frozen intervention time")
  shell <- causal_report_shell(rand_contract)
  data.table::data.table(
    check = c(
      "contract_fields_declared",
      "randomized_normalized",
      "aipw_normalized",
      "did_normalized",
      "compatible_effects_allowed_with_review",
      "incompatible_estimands_block_naive_comparison",
      "multi_artifact_review_no_averaging",
      "design_selection_summary",
      "report_shell_sections",
      "null_negative_evidence_preserved"
    ),
    status = c(
      if (all(causal_effect_contract_fields() %in% names(rand_contract))) "success" else "error",
      if (identical(rand_contract$design_family[[1]], "randomized") && identical(rand_contract$review_status[[1]], "requires_human_review")) "success" else "error",
      if (identical(aipw_contract$estimator_family[[1]], "aipw")) "success" else "error",
      if (identical(did_contract$estimator_family[[1]], "classic_two_group_did")) "success" else "error",
      if (isTRUE(comparable$comparable[[1]]) && grepl("do not average", tolower(comparable$recommendation[[1]]))) "success" else "error",
      if (!isTRUE(incompatible$comparable[[1]]) && grepl("estimand", incompatible$mismatch_fields[[1]])) "success" else "error",
      if (nrow(review) == 3L && !any(grepl("average", tolower(review$relationship)))) "success" else "error",
      if (identical(design$design_status[[1]], "eligible") && grepl("design evidence", design$recommendation[[1]])) "success" else "error",
      if (length(shell$sections) >= 20L && identical(shell$report_type, "unified_causal_evidence_report")) "success" else "error",
      if (identical(causal_normalize_effect_artifact(artifact("null", "randomized", "itt", 0))$point_estimate[[1]], 0)) "success" else "error"
    ),
    message = c(
      "The shared causal-effect evidence vocabulary is declared.",
      "Randomized evidence normalizes into the shared contract without losing review status.",
      "AIPW evidence normalizes into the shared contract.",
      "DiD evidence normalizes into the shared contract.",
      "Comparable artifacts may be reviewed together but are not averaged automatically.",
      "Estimand mismatch blocks naive side-by-side comparison.",
      "Cross-method review classifies relationships without aggregating estimates.",
      "Design selection preserves eligible methods, missing prerequisites, and method-selection rationale.",
      "Unified causal report shell includes common and method-specific evidence sections.",
      "Null or practically null point estimates remain valid evidence."
    )
  )
}
