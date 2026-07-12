analytical_campaign_schema_version <- function() "analytical_campaign_v1"
analytical_campaign_plan_schema_version <- function() "analytical_campaign_plan_v1"
analytical_campaign_synthesis_schema_version <- function() "analytical_campaign_synthesis_v1"
analytical_campaign_learning_schema_version <- function() "analytical_campaign_learning_assessment_v1"
analytical_campaign_closure_schema_version <- function() "analytical_campaign_closure_assessment_v1"

analytical_campaign_now <- function() {
  if (exists("storage_now", mode = "function")) storage_now() else as.character(Sys.time())
}

analytical_campaign_id <- function(project_id = "active_project", objective = "analytical_improvement") {
  paste0("campaign_", substr(storage_hash_value(list(project_id, objective, analytical_campaign_now())), 1L, 16L))
}

analytical_campaign_objective <- function(text = "Improve model evidence using the smallest set of high-value governed feature experiments.") {
  text
}

analytical_campaign_evidence_assessment <- function(evidence_context) {
  schema <- evidence_context$dataset_schema %||% data.table::data.table()
  artifacts <- evidence_context$artifact_refs %||% data.table::data.table()
  target <- evidence_context$target_col %||% NA_character_
  features <- evidence_context$feature_manifest %||% character()
  baseline_id <- evidence_context$baseline_model_result_id %||% NA_character_
  prior <- evidence_context$prior_feature_outcomes %||% data.table::data.table()
  has_target <- !is.na(target) && nzchar(target) && (!nrow(schema) || target %in% schema$column)
  has_features <- length(features) > 0L
  has_schema <- nrow(schema) > 0L
  has_artifacts <- nrow(artifacts) > 0L
  has_baseline <- !is.na(baseline_id) && nzchar(baseline_id)
  has_prior <- nrow(prior) > 0L

  gaps <- character()
  if (!has_schema) gaps <- c(gaps, "missing_dataset_schema")
  if (!has_target) gaps <- c(gaps, "missing_target")
  if (!has_features) gaps <- c(gaps, "missing_feature_manifest")
  if (!has_artifacts) gaps <- c(gaps, "missing_artifact_evidence")
  if (!has_baseline) gaps <- c(gaps, "missing_frozen_baseline")
  if (!has_prior) gaps <- c(gaps, "no_prior_feature_experiment_outcomes")

  score <- 0
  score <- score + if (has_schema) 20 else 0
  score <- score + if (has_target) 20 else 0
  score <- score + if (has_features) 15 else 0
  score <- score + if (has_artifacts) 20 else 0
  score <- score + if (has_baseline) 15 else 0
  score <- score + if (has_prior) 10 else 0

  readiness <- if (!has_schema || !has_target || !has_features) {
    "insufficient"
  } else if (!has_artifacts || !has_baseline) {
    "preliminary"
  } else if (has_prior) {
    "strong"
  } else {
    "reasonable"
  }

  recommendation <- switch(
    readiness,
    insufficient = "Collect a valid dataset schema, target, and feature manifest before starting a campaign.",
    preliminary = "Campaign can identify bounded opportunities, but challenger comparison may pause until baseline and artifact evidence exist.",
    reasonable = "Campaign evidence is sufficient for bounded opportunity ranking and governed challenger testing.",
    strong = "Campaign evidence is strong enough to use prior outcomes while ranking new bounded opportunities.",
    "Review campaign evidence before continuing."
  )

  list(
    assessment_version = "analytical_campaign_evidence_assessment_v1",
    readiness = readiness,
    confidence_score = as.integer(score),
    gaps = gaps,
    uncertainty_signals = gaps,
    evidence_counts = list(
      schema_columns = nrow(schema),
      feature_count = length(features),
      artifact_ref_count = nrow(artifacts),
      prior_outcome_count = nrow(prior),
      raw_rows_included = evidence_context$bounds$raw_rows_included %||% NA_integer_
    ),
    target_col = target,
    baseline_available = has_baseline,
    recommendation = recommendation
  )
}

analytical_campaign_evidence_is_runnable <- function(assessment) {
  !identical(assessment$readiness %||% "", "insufficient")
}

analytical_campaign_learning_assessment <- function(
  campaign,
  opportunity,
  execution = NULL,
  experiment = NULL,
  interpretation = NULL
) {
  proposal <- opportunity$proposal %||% list()
  comparison <- tryCatch(experiment$value$comparison %||% NULL, error = function(e) NULL)
  experiment_value <- tryCatch(experiment$value$experiment %||% list(), error = function(e) list())
  decision <- experiment_value$decision %||% comparison$deterministic_decision %||% if (!is.null(execution) && execution$status %in% c("success", "warning")) "evidence_only" else "failed"
  execution_success <- !is.null(execution) && execution$status %in% c("success", "warning")
  experiment_success <- !is.null(experiment) && identical(experiment$status %||% "", "success")
  evidence_generated <- unique(c(
    execution$value$prepared_dataset_artifact_id %||% character(),
    experiment_value$experiment_id %||% character(),
    comparison$experiment_id %||% character()
  ))
  evidence_generated <- evidence_generated[nzchar(evidence_generated)]
  expected <- c(
    proposal$expected_model_effect %||% "model effect unknown",
    proposal$expected_diagnostic_effect %||% "diagnostic effect unknown"
  )
  observed <- if (experiment_success) {
    comparison$decision_rationale %||% experiment_value$decision_rationale %||% paste("Experiment decision:", decision)
  } else if (execution_success) {
    "Transformation executed and produced prepared-data evidence, but no challenger comparison was available."
  } else {
    "The opportunity did not generate useful execution evidence."
  }
  before <- switch(
    campaign$evidence_assessment$readiness %||% "unknown",
    insufficient = "high",
    preliminary = "high",
    reasonable = "moderate",
    strong = "moderate",
    "unknown"
  )
  outcome <- if (!execution_success) {
    "failed_to_generate_useful_evidence"
  } else if (identical(decision, "accept")) {
    "resolved"
  } else if (identical(decision, "reject")) {
    "reduced_uncertainty"
  } else if (identical(decision, "inconclusive")) {
    "maintained_uncertainty"
  } else {
    "shifted_uncertainty"
  }
  after <- switch(
    outcome,
    resolved = "low",
    reduced_uncertainty = "lower",
    maintained_uncertainty = before,
    shifted_uncertainty = "moderate",
    created_new_uncertainty = "higher",
    failed_to_generate_useful_evidence = before,
    before
  )
  confidence_change <- switch(
    outcome,
    resolved = "increased",
    reduced_uncertainty = "increased",
    shifted_uncertainty = "changed",
    maintained_uncertainty = "unchanged",
    failed_to_generate_useful_evidence = "decreased",
    "unchanged"
  )
  hypothesis <- proposal$hypothesis %||% proposal$rationale %||% opportunity$rationale %||% ""
  unresolved <- switch(
    outcome,
    resolved = character(),
    reduced_uncertainty = "Whether a different bounded transformation would improve the model.",
    maintained_uncertainty = "The tested hypothesis remains uncertain and needs different evidence.",
    shifted_uncertainty = "The experiment generated evidence but shifted the next question.",
    failed_to_generate_useful_evidence = "Execution failure prevented learning.",
    character()
  )
  new_questions <- if (identical(outcome, "resolved")) {
    "Should the accepted challenger be adopted after explicit review?"
  } else if (identical(outcome, "reduced_uncertainty")) {
    "Which alternative opportunity has higher expected learning now?"
  } else if (identical(outcome, "maintained_uncertainty")) {
    "What additional diagnostic evidence would make this hypothesis testable?"
  } else {
    character()
  }
  repeat_value <- outcome %in% c("maintained_uncertainty", "shifted_uncertainty") && !identical(decision, "reject")
  recommendation <- switch(
    outcome,
    resolved = "Treat this hypothesis as supported and review adoption before continuing.",
    reduced_uncertainty = "Retire or revise this hypothesis; repeating the same bounded test is low value.",
    maintained_uncertainty = "Do not repeat the same test without new evidence; choose a different bounded diagnostic.",
    shifted_uncertainty = "Use the new evidence to select the next bounded opportunity.",
    failed_to_generate_useful_evidence = "Resolve execution failure before using this opportunity as evidence.",
    "Review learning assessment."
  )
  list(
    learning_schema_version = analytical_campaign_learning_schema_version(),
    opportunity_id = opportunity$opportunity_id %||% NA_character_,
    proposal_id = proposal$proposal_id %||% NA_character_,
    hypothesis = hypothesis,
    uncertainty_before = before,
    uncertainty_after = after,
    expected_evidence = expected,
    observed_evidence = observed,
    evidence_generated = evidence_generated,
    model_outcome = decision,
    learning_outcome = outcome,
    confidence_change = confidence_change,
    unresolved_questions = unresolved,
    newly_created_questions = new_questions,
    informative = outcome %in% c("resolved", "reduced_uncertainty", "shifted_uncertainty"),
    repeat_likely_adds_value = isTRUE(repeat_value),
    retire_hypothesis = outcome %in% c("resolved", "reduced_uncertainty"),
    revise_hypothesis = outcome %in% c("maintained_uncertainty", "shifted_uncertainty"),
    recommendation = recommendation
  )
}

analytical_campaign_learning_row <- function(assessment) {
  data.table::data.table(
    opportunity_id = assessment$opportunity_id %||% NA_character_,
    proposal_id = assessment$proposal_id %||% NA_character_,
    hypothesis = assessment$hypothesis %||% NA_character_,
    model_outcome = assessment$model_outcome %||% NA_character_,
    learning_outcome = assessment$learning_outcome %||% NA_character_,
    confidence_change = assessment$confidence_change %||% NA_character_,
    uncertainty_before = assessment$uncertainty_before %||% NA_character_,
    uncertainty_after = assessment$uncertainty_after %||% NA_character_,
    informative = isTRUE(assessment$informative),
    repeat_likely_adds_value = isTRUE(assessment$repeat_likely_adds_value),
    recommendation = assessment$recommendation %||% NA_character_
  )
}

analytical_campaign_knowledge_promotion <- function(campaign) {
  memory <- campaign$memory %||% list()
  learning <- memory$learning_assessments %||% data.table::data.table()
  if (!nrow(learning)) {
    return(list(
      promoted = data.table::data.table(),
      not_promoted = data.table::data.table(reason = "No learning assessments are available.")
    ))
  }
  evidence_readiness <- campaign$evidence_assessment$readiness %||% "unknown"
  sufficient_evidence <- evidence_readiness %in% c("reasonable", "strong") || length(memory$experiment_ids %||% character()) > 0L
  promoted_rows <- list()
  not_rows <- list()
  for (i in seq_len(nrow(learning))) {
    row <- learning[i]
    can_promote <- isTRUE(sufficient_evidence) && row$learning_outcome %in% c("resolved", "reduced_uncertainty") && isTRUE(row$informative)
    if (can_promote) {
      knowledge_type <- if (identical(row$learning_outcome, "resolved")) "supported_hypothesis" else "repeat_avoidance_guidance"
      promoted_rows[[length(promoted_rows) + 1L]] <- data.table::data.table(
        knowledge_id = paste0("ck_", substr(storage_hash_value(list(campaign$campaign_id, row$opportunity_id, row$learning_outcome)), 1L, 12L)),
        campaign_id = campaign$campaign_id,
        opportunity_id = row$opportunity_id,
        proposal_id = row$proposal_id,
        knowledge_type = knowledge_type,
        conclusion = row$hypothesis,
        support_level = if (identical(row$learning_outcome, "resolved")) "strong" else "moderate",
        evidence_refs = paste(unique(c(row$opportunity_id, row$proposal_id)), collapse = ", "),
        future_guidance = if (identical(knowledge_type, "repeat_avoidance_guidance")) "Avoid repeating this bounded hypothesis without new evidence." else "Prioritize related bounded opportunities when the same evidence context appears.",
        promoted_at = analytical_campaign_now()
      )
    } else {
      not_rows[[length(not_rows) + 1L]] <- data.table::data.table(
        opportunity_id = row$opportunity_id,
        proposal_id = row$proposal_id,
        learning_outcome = row$learning_outcome,
        reason = if (!isTRUE(sufficient_evidence)) "Evidence support is not strong enough for reusable knowledge." else "Learning outcome is not stable enough for promotion."
      )
    }
  }
  list(
    promoted = if (length(promoted_rows)) data.table::rbindlist(promoted_rows, use.names = TRUE, fill = TRUE) else data.table::data.table(),
    not_promoted = if (length(not_rows)) data.table::rbindlist(not_rows, use.names = TRUE, fill = TRUE) else data.table::data.table()
  )
}

analytical_campaign_reopening_guidance <- function(campaign, closure_recommendation = NULL) {
  conditions <- c("new_data", "new_model", "new_evidence", "new_operator_capability", "new_transformation_support", "new_business_objective", "significant_performance_regression")
  if ((campaign$evidence_assessment$readiness %||% "") %in% c("insufficient", "preliminary")) {
    conditions <- unique(c("additional_evidence", conditions))
  }
  if (identical(closure_recommendation %||% "", "continue_campaign")) {
    conditions <- unique(c("remaining_high_value_opportunity", conditions))
  }
  data.table::data.table(
    condition = conditions,
    guidance = c(
      additional_evidence = "Reopen when missing campaign evidence becomes available.",
      remaining_high_value_opportunity = "Continue or reopen while a high-learning candidate remains.",
      new_data = "Reopen when source data materially changes.",
      new_model = "Reopen when a new frozen baseline model exists.",
      new_evidence = "Reopen when new artifacts contradict or extend campaign conclusions.",
      new_operator_capability = "Reopen when deterministic operators can test previously unsupported ideas.",
      new_transformation_support = "Reopen when Rodeo supports a previously blocked transformation.",
      new_business_objective = "Reopen when the decision objective changes.",
      significant_performance_regression = "Reopen when model performance regresses enough to invalidate prior conclusions."
    )[conditions]
  )
}

analytical_campaign_closure_assessment <- function(campaign) {
  memory <- campaign$memory %||% list()
  learning <- memory$learning_assessments %||% data.table::data.table()
  remaining <- Filter(function(x) identical(x$status %||% "", "candidate"), campaign$opportunities %||% list())
  blocked <- Filter(function(x) (x$status %||% "") %in% c("blocked_dependency", "low_value", "low_learning_value", "superseded"), campaign$opportunities %||% list())
  gates <- campaign$status %||% "unknown"
  learning_count <- nrow(learning)
  uncertainty_reduced <- sum((learning$learning_outcome %||% character()) %in% c("resolved", "reduced_uncertainty"))
  unresolved_count <- length(memory$unresolved_questions %||% character()) + length(memory$hypotheses_uncertain %||% character())
  failed_count <- length(memory$failed_executions %||% character())
  confidence <- as.integer(max(0, min(100,
    (campaign$evidence_assessment$confidence_score %||% 0L) +
      (uncertainty_reduced * 10L) -
      (unresolved_count * 5L) -
      (failed_count * 10L) -
      (length(remaining) * 5L)
  )))
  expected_next_value <- if (length(remaining)) {
    round(max(vapply(remaining, function(x) x$score %||% 0, numeric(1))), 3)
  } else {
    0
  }
  recommendation <- if (gates %in% c("awaiting_approval", "awaiting_adoption_decision")) {
    "await_approval"
  } else if (identical(gates, "awaiting_baseline")) {
    "await_additional_evidence"
  } else if (identical(gates, "blocked")) {
    "blocked"
  } else if (length(remaining) && expected_next_value > (campaign$stopping_criteria$min_opportunity_score %||% 0.1) && learning_count == 0L) {
    "continue_campaign"
  } else if (length(remaining) && expected_next_value > 0.5 && unresolved_count > 0L) {
    "continue_campaign"
  } else if (confidence >= 70L && uncertainty_reduced > 0L) {
    "ready_for_closure"
  } else if (learning_count == 0L) {
    "requires_human_judgment"
  } else {
    "ready_for_closure"
  }
  promotion <- analytical_campaign_knowledge_promotion(campaign)
  list(
    closure_schema_version = analytical_campaign_closure_schema_version(),
    campaign_id = campaign$campaign_id,
    objective = campaign$objective,
    recommendation = recommendation,
    campaign_confidence = confidence,
    confidence_factors = list(
      evidence_score = campaign$evidence_assessment$confidence_score %||% NA_integer_,
      learning_assessments = learning_count,
      uncertainty_reduced = uncertainty_reduced,
      unresolved_questions = unresolved_count,
      failed_opportunities = failed_count,
      remaining_opportunities = length(remaining),
      blocked_or_deprioritized_opportunities = length(blocked)
    ),
    campaign_completeness = if (!length(remaining)) "complete" else "partial",
    expected_value_of_next_opportunity = expected_next_value,
    governance_status = gates,
    remaining_uncertainty = unique(c(memory$unresolved_questions %||% character(), memory$hypotheses_uncertain %||% character())),
    remaining_evidence_gaps = campaign$evidence_assessment$gaps %||% character(),
    knowledge_promoted = promotion$promoted,
    knowledge_not_promoted = promotion$not_promoted,
    reopening_guidance = analytical_campaign_reopening_guidance(campaign, recommendation),
    summary = switch(
      recommendation,
      ready_for_closure = "Campaign has generated enough supported learning to close under current evidence.",
      continue_campaign = "Campaign has remaining uncertainty and a worthwhile bounded next opportunity.",
      await_approval = "Campaign closure is waiting on an explicit governance decision.",
      await_additional_evidence = "Campaign closure is waiting on additional model/evidence support.",
      blocked = "Campaign is blocked and needs recovery before closure.",
      requires_human_judgment = "Campaign evidence is not sufficient for deterministic closure.",
      "Review campaign closure assessment."
    )
  )
}

analytical_campaign_apply_promoted_knowledge <- function(campaign, promoted_knowledge = data.table::data.table()) {
  knowledge <- data.table::as.data.table(promoted_knowledge %||% data.table::data.table())
  if (!nrow(knowledge)) return(campaign)
  avoid <- knowledge[knowledge_type == "repeat_avoidance_guidance", unique(proposal_id)]
  supported <- knowledge[knowledge_type == "supported_hypothesis", unique(proposal_id)]
  campaign$opportunities <- lapply(campaign$opportunities %||% list(), function(opp) {
    proposal_id <- opp$proposal$proposal_id %||% ""
    if (proposal_id %in% avoid) {
      opp$status <- "low_learning_value"
      opp$status_reason <- "Promoted campaign knowledge recommends avoiding this repeated hypothesis without new evidence."
      opp$score <- 0
    } else if (proposal_id %in% supported && identical(opp$status %||% "", "candidate")) {
      opp$score <- round(min(1, (opp$score %||% 0) + 0.05), 3)
      opp$status_reason <- "Promoted campaign knowledge supports a related bounded hypothesis."
    }
    opp
  })
  campaign$memory$promoted_knowledge <- knowledge
  analytical_campaign_record_event(campaign, "promoted_knowledge_applied", campaign$campaign_id, paste(nrow(knowledge), "promoted knowledge record(s) considered."))
}

analytical_campaign_score_opportunity <- function(proposal, prior_outcomes = data.table::data.table()) {
  impact <- switch(
    proposal$transformation_type %||% "",
    missing_impute = 0.78,
    date_features = 0.72,
    factor_levels = 0.64,
    near_zero_variance_remove = 0.54,
    constant_remove = 0.45,
    0.25
  )
  feasibility <- if (identical(proposal$rodeo_support_status %||% "", "supported")) 1 else 0
  risk_penalty <- switch(proposal$required_approval_tier %||% "blocked", low = 0.05, medium = 0.20, blocked = 1, 0.35)
  duplicate_penalty <- 0
  if (nrow(prior_outcomes)) {
    duplicate_penalty <- if (proposal$proposal_id %in% prior_outcomes$related_id || proposal$proposal_id %in% prior_outcomes$id) 0.50 else 0
  }
  round(max(0, impact + feasibility - risk_penalty - duplicate_penalty), 3)
}

analytical_campaign_decision_bucket <- function(decision) {
  switch(decision %||% "inconclusive", accept = "accepted", reject = "rejected", inconclusive = "inconclusive", "inconclusive")
}

analytical_campaign_timeline <- function(campaign) {
  events <- campaign$memory$events %||% data.table::data.table(timestamp = character(), event = character(), id = character(), detail = character())
  if (!nrow(events)) return(events)
  events[, sequence := seq_len(.N)]
  data.table::setcolorder(events, c("sequence", setdiff(names(events), "sequence")))
  events
}

analytical_campaign_mark_opportunity <- function(campaign, opportunity_id, status, reason = "") {
  campaign$opportunities <- lapply(campaign$opportunities %||% list(), function(opp) {
    if (identical(opp$opportunity_id %||% "", opportunity_id %||% "")) {
      opp$status <- status
      opp$status_reason <- reason
      opp$updated_at <- analytical_campaign_now()
    }
    opp
  })
  campaign
}

analytical_campaign_prerequisites_met <- function(campaign, opportunity) {
  dependencies <- opportunity$dependencies %||% character()
  if (!length(dependencies)) return(TRUE)
  all(dependencies %in% (campaign$memory$completed_opportunity_ids %||% character()))
}

analytical_campaign_reprioritize <- function(campaign, evidence_context = NULL) {
  memory <- campaign$memory %||% list()
  if (!is.null(evidence_context)) {
    campaign$evidence_assessment <- analytical_campaign_evidence_assessment(evidence_context)
  }
  evidence_penalty <- switch(campaign$evidence_assessment$readiness %||% "reasonable", preliminary = 0.05, insufficient = 1, 0)
  accepted_count <- length(memory$accepted %||% character())
  rejected_count <- length(memory$rejected %||% character())
  failed_count <- length(memory$failed_executions %||% character())
  low_learning <- memory$low_learning_opportunity_ids %||% character()
  resolved <- memory$resolved_opportunity_ids %||% character()
  evaluated <- memory$evaluated_opportunity_ids %||% character()
  campaign$opportunities <- lapply(campaign$opportunities %||% list(), function(opp) {
    if (opp$opportunity_id %in% evaluated) return(opp)
    if (!analytical_campaign_prerequisites_met(campaign, opp)) {
      opp$status <- "blocked_dependency"
      opp$status_reason <- "Prerequisite opportunity has not completed."
      opp$score <- max(0, (opp$score %||% 0) - 0.75)
      return(opp)
    }
    penalty <- (accepted_count * 0.10) + (rejected_count * 0.05) + (failed_count * 0.20) + evidence_penalty
    if (length(memory$superseded %||% character()) && (opp$proposal$proposal_id %||% "") %in% memory$superseded) {
      opp$status <- "superseded"
      opp$status_reason <- "Superseded by earlier campaign evidence."
      opp$score <- 0
    } else if (opp$opportunity_id %in% c(low_learning, resolved)) {
      opp$status <- "low_learning_value"
      opp$status_reason <- "Prior campaign learning indicates repeating this opportunity is unlikely to add value."
      opp$score <- 0
    } else {
      opp$score <- round(max(0, (opp$score %||% 0) - penalty), 3)
      if ((opp$score %||% 0) <= (campaign$stopping_criteria$min_opportunity_score %||% 0.1)) {
        opp$status <- "low_value"
        opp$status_reason <- "Expected value fell below the campaign usefulness threshold."
      }
    }
    opp
  })
  remaining <- Filter(function(opp) identical(opp$status %||% "", "candidate"), campaign$opportunities %||% list())
  remaining <- remaining[order(vapply(remaining, function(x) -x$score, numeric(1)))]
  fixed <- Filter(function(opp) !identical(opp$status %||% "", "candidate"), campaign$opportunities %||% list())
  combined <- c(remaining, fixed)
  for (i in seq_along(combined)) combined[[i]]$rank <- i
  campaign$opportunities <- combined
  campaign <- analytical_campaign_record_event(campaign, "opportunities_reprioritized", campaign$campaign_id, paste(length(remaining), "candidate opportunit(ies) remain."))
  campaign
}

analytical_campaign_discover_opportunities <- function(evidence_context, max_opportunities = 3L) {
  generated <- generate_feature_proposals(evidence_context, max_proposals = max_opportunities)
  if (!identical(generated$status, "success")) return(generated)
  prior <- evidence_context$prior_feature_outcomes %||% data.table::data.table()
  proposals <- generated$value %||% list()
  opportunities <- lapply(seq_along(proposals), function(i) {
    proposal <- proposals[[i]]
    score <- analytical_campaign_score_opportunity(proposal, prior)
    already_evaluated <- nrow(prior) && proposal$proposal_id %in% c(prior$id, prior$related_id)
    list(
      opportunity_id = paste0("opp_", substr(storage_hash_value(list(proposal$proposal_id, i)), 1L, 12L)),
      rank = i,
      score = score,
      status = if (isTRUE(already_evaluated)) "skipped_previous_evidence" else "candidate",
      rationale = proposal$rationale %||% proposal$hypothesis %||% "",
      dependencies = character(),
      proposal = proposal,
      supporting_evidence = proposal$evidence_artifact_ids %||% character()
    )
  })
  opportunities <- opportunities[order(vapply(opportunities, function(x) -x$score, numeric(1)))]
  for (i in seq_along(opportunities)) opportunities[[i]]$rank <- i
  service_result(
    status = "success",
    value = opportunities,
    messages = paste("Discovered", length(opportunities), "bounded analytical improvement opportunit(ies)."),
    metadata = list(opportunity_count = length(opportunities), prior_outcome_count = nrow(prior))
  )
}

create_analytical_campaign <- function(
  evidence_context,
  objective = analytical_campaign_objective(),
  max_opportunities = 3L,
  stopping_criteria = list(max_experiments = 1L, stop_on_accept = TRUE, stop_when_no_candidates = TRUE)
) {
  evidence_assessment <- analytical_campaign_evidence_assessment(evidence_context)
  if (analytical_campaign_evidence_is_runnable(evidence_assessment)) {
    opportunities <- analytical_campaign_discover_opportunities(evidence_context, max_opportunities)
    if (!identical(opportunities$status, "success")) return(opportunities)
  } else {
    opportunities <- service_result(status = "success", value = list(), messages = "Campaign evidence is insufficient for opportunity discovery.")
  }
  campaign <- list(
    campaign_id = analytical_campaign_id(evidence_context$project_id %||% "active_project", objective),
    campaign_version = analytical_campaign_schema_version(),
    project_id = evidence_context$project_id %||% "active_project",
    objective = objective,
    created_at = analytical_campaign_now(),
    status = if (!analytical_campaign_evidence_is_runnable(evidence_assessment)) "blocked" else if (length(opportunities$value)) "planned" else "completed",
    evidence_context_summary = list(
      context_schema_version = evidence_context$context_schema_version,
      target_col = evidence_context$target_col,
      feature_count = length(evidence_context$feature_manifest %||% character()),
      artifact_ref_count = nrow(evidence_context$artifact_refs %||% data.table::data.table()),
      prior_outcome_count = nrow(evidence_context$prior_feature_outcomes %||% data.table::data.table()),
      raw_rows_included = evidence_context$bounds$raw_rows_included %||% NA_integer_
    ),
    evidence_assessment = evidence_assessment,
    opportunities = opportunities$value,
    memory = list(
      evaluated_opportunity_ids = character(),
      completed_opportunity_ids = character(),
      proposal_ids = character(),
      execution_ids = character(),
      experiment_ids = character(),
      accepted = character(),
      rejected = character(),
      inconclusive = character(),
      failed_executions = character(),
      blocked = character(),
      skipped = character(),
      superseded = character(),
      facts_learned = character(),
      evidence_collected = character(),
      hypotheses_supported = character(),
      hypotheses_rejected = character(),
      hypotheses_uncertain = character(),
      unresolved_questions = character(),
      newly_created_questions = character(),
      resolved_opportunity_ids = character(),
      low_learning_opportunity_ids = character(),
      promoted_knowledge = data.table::data.table(),
      non_promoted_knowledge = data.table::data.table(),
      supporting_evidence_refs = character(),
      learning_assessments = data.table::data.table(opportunity_id = character(), proposal_id = character(), hypothesis = character(), model_outcome = character(), learning_outcome = character(), confidence_change = character(), uncertainty_before = character(), uncertainty_after = character(), informative = logical(), repeat_likely_adds_value = logical(), recommendation = character()),
      proposal_lineage = data.table::data.table(opportunity_id = character(), proposal_id = character(), evidence_refs = character()),
      experiment_lineage = data.table::data.table(opportunity_id = character(), experiment_id = character(), execution_id = character(), decision = character()),
      adoption_lineage = data.table::data.table(experiment_id = character(), adoption_id = character(), status = character()),
      events = data.table::data.table(timestamp = character(), event = character(), id = character(), detail = character())
    ),
    stopping_criteria = stopping_criteria,
    required_approvals = data.table::data.table(),
    deliverables = character()
  )
  if (!analytical_campaign_evidence_is_runnable(evidence_assessment)) {
    campaign <- analytical_campaign_record_event(campaign, "evidence_insufficient", campaign$campaign_id, evidence_assessment$recommendation)
  }
  service_result(status = "success", value = campaign, messages = paste("Created analytical improvement campaign:", campaign$campaign_id))
}

analytical_campaign_record_event <- function(campaign, event, id = NA_character_, detail = "") {
  event_row <- data.table::data.table(timestamp = analytical_campaign_now(), event = event, id = id %||% NA_character_, detail = detail %||% "")
  campaign$memory$events <- data.table::rbindlist(list(campaign$memory$events %||% data.table::data.table(), event_row), use.names = TRUE, fill = TRUE)
  campaign
}

analytical_campaign_record_learning <- function(campaign, assessment) {
  campaign$memory$learning_assessments <- data.table::rbindlist(list(
    campaign$memory$learning_assessments %||% data.table::data.table(),
    analytical_campaign_learning_row(assessment)
  ), use.names = TRUE, fill = TRUE)
  campaign$memory$evidence_collected <- unique(c(campaign$memory$evidence_collected, assessment$evidence_generated %||% character()))
  campaign$memory$unresolved_questions <- unique(c(campaign$memory$unresolved_questions, assessment$unresolved_questions %||% character()))
  campaign$memory$newly_created_questions <- unique(c(campaign$memory$newly_created_questions, assessment$newly_created_questions %||% character()))
  if (identical(assessment$learning_outcome, "resolved")) {
    campaign$memory$facts_learned <- unique(c(campaign$memory$facts_learned, paste("Supported:", assessment$hypothesis %||% assessment$proposal_id)))
    campaign$memory$hypotheses_supported <- unique(c(campaign$memory$hypotheses_supported, assessment$hypothesis %||% assessment$proposal_id))
    campaign$memory$resolved_opportunity_ids <- unique(c(campaign$memory$resolved_opportunity_ids, assessment$opportunity_id))
  } else if (identical(assessment$learning_outcome, "reduced_uncertainty")) {
    campaign$memory$facts_learned <- unique(c(campaign$memory$facts_learned, paste("Rejected or deprioritized:", assessment$hypothesis %||% assessment$proposal_id)))
    campaign$memory$hypotheses_rejected <- unique(c(campaign$memory$hypotheses_rejected, assessment$hypothesis %||% assessment$proposal_id))
    campaign$memory$low_learning_opportunity_ids <- unique(c(campaign$memory$low_learning_opportunity_ids, assessment$opportunity_id))
  } else if (assessment$learning_outcome %in% c("maintained_uncertainty", "shifted_uncertainty")) {
    campaign$memory$hypotheses_uncertain <- unique(c(campaign$memory$hypotheses_uncertain, assessment$hypothesis %||% assessment$proposal_id))
    if (!isTRUE(assessment$repeat_likely_adds_value)) {
      campaign$memory$low_learning_opportunity_ids <- unique(c(campaign$memory$low_learning_opportunity_ids, assessment$opportunity_id))
    }
  } else {
    campaign$memory$low_learning_opportunity_ids <- unique(c(campaign$memory$low_learning_opportunity_ids, assessment$opportunity_id))
  }
  analytical_campaign_record_event(campaign, paste0("learning_", assessment$learning_outcome), assessment$opportunity_id, assessment$recommendation)
}

analytical_campaign_plan <- function(campaign) {
  opportunities <- campaign$opportunities %||% list()
  rows <- if (length(opportunities)) {
    data.table::rbindlist(lapply(opportunities, function(opp) {
      proposal <- opp$proposal %||% list()
      data.table::data.table(
        rank = opp$rank,
        opportunity_id = opp$opportunity_id,
        score = opp$score,
        status = opp$status,
        dependencies = paste(opp$dependencies %||% character(), collapse = ", "),
        transformation_type = proposal$transformation_type %||% NA_character_,
        approval_tier = proposal$required_approval_tier %||% NA_character_,
        proposal_status = proposal$proposal_status %||% NA_character_,
        rationale = opp$rationale %||% NA_character_
      )
    }), use.names = TRUE, fill = TRUE)
  } else {
    data.table::data.table()
  }
  list(
    plan_version = analytical_campaign_plan_schema_version(),
    campaign_id = campaign$campaign_id,
    objective = campaign$objective,
    opportunities = rows,
    stopping_criteria = campaign$stopping_criteria,
    evidence_assessment = campaign$evidence_assessment %||% list(),
    required_approvals = rows[proposal_status %in% c("awaiting_approval", "proposed")],
    expected_deliverables = c("feature proposals", "Rodeo execution artifacts", "challenger comparison", "campaign synthesis")
  )
}

analytical_campaign_next_opportunity <- function(campaign) {
  evaluated <- campaign$memory$evaluated_opportunity_ids %||% character()
  candidates <- Filter(function(opp) {
    identical(opp$status %||% "", "candidate") && !opp$opportunity_id %in% evaluated
  }, campaign$opportunities %||% list())
  if (length(candidates)) candidates[[1L]] else NULL
}

analytical_campaign_execute_next <- function(
  campaign,
  data,
  baseline_result = NULL,
  catboost_config = list(),
  output_dir = tempfile("analytical_campaign_"),
  approval = FALSE
) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if ((campaign$status %||% "") %in% c("awaiting_approval", "awaiting_adoption_decision", "awaiting_baseline", "blocked")) {
    reason <- switch(
      campaign$status,
      awaiting_approval = "Campaign is waiting for proposal approval.",
      awaiting_adoption_decision = "Campaign is waiting for an explicit adoption or defer decision.",
      awaiting_baseline = "Campaign is waiting for a frozen baseline before challenger comparison.",
      blocked = if (identical(campaign$evidence_assessment$readiness %||% "", "insufficient")) campaign$evidence_assessment$recommendation else "Campaign is blocked and requires recovery.",
      "Campaign is not in a runnable state."
    )
    return(service_result(status = "needs_input", value = campaign, messages = reason, metadata = list(blocked_status = campaign$status)))
  }
  opp <- analytical_campaign_next_opportunity(campaign)
  if (is.null(opp)) {
    campaign$status <- "completed"
    campaign <- analytical_campaign_record_event(campaign, "campaign_completed", campaign$campaign_id, "No remaining candidate opportunities.")
    return(service_result(status = "success", value = campaign, messages = "Campaign completed: no remaining candidate opportunities."))
  }
  proposal <- opp$proposal
  campaign$memory$proposal_ids <- unique(c(campaign$memory$proposal_ids, proposal$proposal_id))
  campaign$memory$supporting_evidence_refs <- unique(c(campaign$memory$supporting_evidence_refs, opp$supporting_evidence %||% character()))
  campaign$memory$proposal_lineage <- data.table::rbindlist(list(
    campaign$memory$proposal_lineage %||% data.table::data.table(),
    data.table::data.table(opportunity_id = opp$opportunity_id, proposal_id = proposal$proposal_id, evidence_refs = paste(opp$supporting_evidence %||% character(), collapse = ", "))
  ), use.names = TRUE, fill = TRUE)
  if (!isTRUE(approval)) {
    campaign$status <- "awaiting_approval"
    campaign$required_approvals <- data.table::data.table(
      opportunity_id = opp$opportunity_id,
      proposal_id = proposal$proposal_id,
      transformation_type = proposal$transformation_type,
      approval_tier = proposal$required_approval_tier,
      rationale = proposal$rationale
    )
    campaign <- analytical_campaign_record_event(campaign, "approval_required", proposal$proposal_id, "Campaign paused before deterministic execution.")
    return(service_result(status = "needs_input", value = campaign, metadata = list(action = "approve_feature_proposal", proposal = proposal), messages = "Campaign paused: feature proposal approval is required."))
  }
  approved <- approve_feature_proposal(proposal)
  if (!identical(approved$status, "success")) {
    campaign$status <- "blocked"
    campaign$memory$blocked <- unique(c(campaign$memory$blocked, proposal$proposal_id))
    campaign <- analytical_campaign_record_event(campaign, "proposal_blocked", proposal$proposal_id, service_result_message(approved))
    return(service_result(status = "error", value = campaign, errors = approved$errors %||% "Proposal could not be approved."))
  }
  execution <- execute_feature_proposal_with_rodeo(approved$value, data, output_dir)
  if (!execution$status %in% c("success", "warning")) {
    learning <- analytical_campaign_learning_assessment(campaign, opp, execution = execution)
    campaign <- analytical_campaign_record_learning(campaign, learning)
    campaign$status <- "blocked"
    campaign$memory$blocked <- unique(c(campaign$memory$blocked, proposal$proposal_id))
    campaign$memory$failed_executions <- unique(c(campaign$memory$failed_executions, proposal$proposal_id))
    campaign <- analytical_campaign_record_event(campaign, "execution_failed", proposal$proposal_id, service_result_message(execution))
    return(service_result(status = "error", value = campaign, errors = execution$errors %||% "Feature execution failed.", metadata = list(execution = execution)))
  }
  campaign$memory$execution_ids <- unique(c(campaign$memory$execution_ids, execution$value$execution_id %||% execution$metadata$execution_id))
  experiment <- NULL
  interpretation <- NULL
  if (!is.null(baseline_result) && identical(baseline_result$status %||% "", "success")) {
    experiment <- create_feature_challenger_experiment(baseline_result, execution, data, catboost_config, output_dir)
    if (identical(experiment$status, "success")) {
      decision <- experiment$value$experiment$decision %||% "inconclusive"
      campaign$memory$experiment_ids <- unique(c(campaign$memory$experiment_ids, experiment$value$experiment$experiment_id))
      bucket <- analytical_campaign_decision_bucket(decision)
      campaign$memory[[bucket]] <- unique(c(campaign$memory[[bucket]] %||% character(), experiment$value$experiment$experiment_id))
      campaign$memory$experiment_lineage <- data.table::rbindlist(list(
        campaign$memory$experiment_lineage %||% data.table::data.table(),
        data.table::data.table(opportunity_id = opp$opportunity_id, experiment_id = experiment$value$experiment$experiment_id, execution_id = execution$value$execution_id %||% execution$metadata$execution_id, decision = decision)
      ), use.names = TRUE, fill = TRUE)
      interpretation <- interpret_feature_experiment_outcome(experiment$value$comparison)
      campaign <- analytical_campaign_record_event(campaign, paste0("experiment_", decision), experiment$value$experiment$experiment_id, interpretation$explanation)
      if (identical(decision, "accept")) {
        remaining_ids <- vapply(campaign$opportunities %||% list(), function(x) if (!identical(x$opportunity_id, opp$opportunity_id)) x$proposal$proposal_id %||% "" else "", character(1))
        campaign$memory$superseded <- unique(c(campaign$memory$superseded, remaining_ids[nzchar(remaining_ids)]))
      }
      if (identical(decision, "accept") && isTRUE(campaign$stopping_criteria$stop_on_accept)) {
        campaign$status <- "awaiting_adoption_decision"
      } else {
        campaign$status <- "running"
      }
    } else {
      campaign$status <- "blocked"
      campaign <- analytical_campaign_record_event(campaign, "challenger_failed", proposal$proposal_id, service_result_message(experiment))
      return(service_result(status = "error", value = campaign, errors = experiment$errors %||% "Challenger experiment failed.", metadata = list(execution = execution, experiment = experiment)))
    }
  } else {
    campaign$status <- "awaiting_baseline"
    campaign <- analytical_campaign_record_event(campaign, "execution_completed_baseline_missing", execution$value$execution_id, "Rodeo execution completed; baseline model is required for challenger comparison.")
  }
  learning <- analytical_campaign_learning_assessment(campaign, opp, execution = execution, experiment = experiment, interpretation = interpretation)
  campaign <- analytical_campaign_record_learning(campaign, learning)
  campaign$memory$evaluated_opportunity_ids <- unique(c(campaign$memory$evaluated_opportunity_ids, opp$opportunity_id))
  campaign$memory$completed_opportunity_ids <- unique(c(campaign$memory$completed_opportunity_ids, opp$opportunity_id))
  campaign <- analytical_campaign_mark_opportunity(campaign, opp$opportunity_id, "completed", "Opportunity executed and evidence was recorded.")
  campaign <- analytical_campaign_reprioritize(campaign)
  remaining_candidates <- Filter(function(x) identical(x$status %||% "", "candidate"), campaign$opportunities %||% list())
  if (!length(remaining_candidates) && !campaign$status %in% c("awaiting_adoption_decision", "awaiting_baseline", "blocked")) {
    campaign$status <- "completed"
    campaign <- analytical_campaign_record_event(campaign, "campaign_completed", campaign$campaign_id, "No meaningful candidate opportunities remain.")
  }
  service_result(
    status = "success",
    value = campaign,
    messages = paste("Campaign executed opportunity:", opp$opportunity_id),
    metadata = list(opportunity = opp, execution = execution, experiment = experiment, interpretation = interpretation)
  )
}

analytical_campaign_synthesis <- function(campaign) {
  opportunities <- campaign$opportunities %||% list()
  rows <- if (length(opportunities)) data.table::rbindlist(lapply(opportunities, function(opp) {
    proposal <- opp$proposal %||% list()
    data.table::data.table(
      opportunity_id = opp$opportunity_id,
      rank = opp$rank,
      score = opp$score,
      status = opp$status,
      proposal_id = proposal$proposal_id %||% NA_character_,
      transformation_type = proposal$transformation_type %||% NA_character_,
      rationale = proposal$rationale %||% NA_character_
    )
  }), use.names = TRUE, fill = TRUE) else data.table::data.table()
  memory <- campaign$memory %||% list()
  closure <- analytical_campaign_closure_assessment(campaign)
  list(
    synthesis_version = analytical_campaign_synthesis_schema_version(),
    campaign_id = campaign$campaign_id,
    status = campaign$status,
    objective = campaign$objective,
    evidence_reviewed = campaign$evidence_context_summary,
    evidence_assessment = campaign$evidence_assessment %||% list(),
    opportunities_considered = nrow(rows),
    experiments_executed = length(memory$experiment_ids %||% character()),
    accepted_improvements = memory$accepted %||% character(),
    rejected_improvements = memory$rejected %||% character(),
    inconclusive_improvements = memory$inconclusive %||% character(),
    failed_executions = memory$failed_executions %||% character(),
    facts_learned = memory$facts_learned %||% character(),
    evidence_collected = memory$evidence_collected %||% character(),
    hypotheses_supported = memory$hypotheses_supported %||% character(),
    hypotheses_rejected = memory$hypotheses_rejected %||% character(),
    hypotheses_uncertain = memory$hypotheses_uncertain %||% character(),
    unresolved_questions = memory$unresolved_questions %||% character(),
    newly_created_questions = memory$newly_created_questions %||% character(),
    learning_assessments = memory$learning_assessments %||% data.table::data.table(),
    learning_summary = data.table::data.table(
      resolved = sum((memory$learning_assessments$learning_outcome %||% character()) == "resolved"),
      reduced_uncertainty = sum((memory$learning_assessments$learning_outcome %||% character()) == "reduced_uncertainty"),
      maintained_uncertainty = sum((memory$learning_assessments$learning_outcome %||% character()) == "maintained_uncertainty"),
      shifted_uncertainty = sum((memory$learning_assessments$learning_outcome %||% character()) == "shifted_uncertainty"),
      failed_to_generate_useful_evidence = sum((memory$learning_assessments$learning_outcome %||% character()) == "failed_to_generate_useful_evidence")
    ),
    closure_assessment = closure,
    knowledge_promoted = closure$knowledge_promoted,
    knowledge_not_promoted = closure$knowledge_not_promoted,
    reopening_guidance = closure$reopening_guidance,
    blocked_items = memory$blocked %||% character(),
    skipped_items = memory$skipped %||% character(),
    superseded_items = memory$superseded %||% character(),
    supporting_evidence_refs = memory$supporting_evidence_refs %||% character(),
    proposal_lineage = memory$proposal_lineage %||% data.table::data.table(),
    experiment_lineage = memory$experiment_lineage %||% data.table::data.table(),
    adoption_lineage = memory$adoption_lineage %||% data.table::data.table(),
    remaining_opportunities = rows[!opportunity_id %in% (memory$evaluated_opportunity_ids %||% character())],
    event_history = analytical_campaign_timeline(campaign),
    recommendation = if (!is.null(closure$summary) && closure$recommendation %in% c("ready_for_closure", "continue_campaign", "requires_human_judgment")) {
      closure$summary
    } else if (identical(campaign$status, "awaiting_approval")) {
      "Human approval is required before deterministic execution."
    } else if (identical(campaign$status, "awaiting_adoption_decision")) {
      "Review accepted challenger evidence and explicitly adopt or defer."
    } else if (identical(campaign$status, "awaiting_baseline")) {
      "Train or provide a frozen CatBoost baseline before comparing challenger evidence."
    } else if (identical(campaign$status, "blocked") && identical(campaign$evidence_assessment$readiness %||% "", "insufficient")) {
      campaign$evidence_assessment$recommendation
    } else if (identical(campaign$status, "completed")) {
      "Campaign has no remaining candidate opportunities."
    } else {
      "Continue with the next ranked bounded opportunity."
    }
  )
}

reconcile_analytical_campaign <- function(campaign) {
  issues <- list()
  add <- function(code, severity, detail) {
    issues[[length(issues) + 1L]] <<- data.table::data.table(code = code, severity = severity, detail = detail)
  }
  if (!identical(campaign$campaign_version %||% "", analytical_campaign_schema_version())) add("schema_mismatch", "error", campaign$campaign_id %||% "")
  if (!identical((campaign$evidence_assessment %||% list())$assessment_version %||% "", "analytical_campaign_evidence_assessment_v1")) add("missing_evidence_assessment", "error", campaign$campaign_id %||% "")
  if (identical(campaign$status %||% "", "awaiting_approval") && !nrow(campaign$required_approvals %||% data.table::data.table())) add("approval_state_without_request", "error", campaign$campaign_id)
  if (any(duplicated(campaign$memory$evaluated_opportunity_ids %||% character()))) add("duplicate_evaluated_opportunity", "error", campaign$campaign_id)
  if (any(duplicated(campaign$memory$completed_opportunity_ids %||% character()))) add("duplicate_completed_opportunity", "error", campaign$campaign_id)
  opportunity_ids <- vapply(campaign$opportunities %||% list(), function(x) x$opportunity_id %||% "", character(1))
  if (nrow(campaign$memory$learning_assessments %||% data.table::data.table())) {
    bad_learning <- setdiff(campaign$memory$learning_assessments$opportunity_id, opportunity_ids)
    if (length(bad_learning)) add("learning_unknown_opportunity", "error", paste(bad_learning, collapse = ", "))
  }
  unknown <- setdiff(campaign$memory$evaluated_opportunity_ids %||% character(), opportunity_ids)
  if (length(unknown)) add("evaluated_unknown_opportunity", "error", paste(unknown, collapse = ", "))
  completed_unknown <- setdiff(campaign$memory$completed_opportunity_ids %||% character(), opportunity_ids)
  if (length(completed_unknown)) add("completed_unknown_opportunity", "error", paste(completed_unknown, collapse = ", "))
  if (nrow(campaign$memory$experiment_lineage %||% data.table::data.table())) {
    missing_lineage <- setdiff(campaign$memory$experiment_lineage$opportunity_id, opportunity_ids)
    if (length(missing_lineage)) add("experiment_lineage_unknown_opportunity", "error", paste(missing_lineage, collapse = ", "))
  }
  table <- if (length(issues)) data.table::rbindlist(issues) else data.table::data.table(code = character(), severity = character(), detail = character())
  service_result(status = if (any(table$severity == "error")) "error" else if (nrow(table)) "warning" else "success", value = table, messages = if (nrow(table)) "Campaign reconciliation found issues." else "Campaign reconciles.")
}

analytical_campaign_state_summary <- function(campaigns = list()) {
  campaigns <- campaigns %||% list()
  statuses <- vapply(campaigns, function(x) x$status %||% "unknown", character(1))
  latest <- if (length(campaigns)) campaigns[[length(campaigns)]] else list()
  latest_opportunities <- latest$opportunities %||% list()
  current <- Filter(function(x) identical(x$status %||% "", "candidate"), latest_opportunities)
  current <- current[order(vapply(current, function(x) -(x$score %||% 0), numeric(1)))]
  current_opportunity <- if (length(current)) current[[1]]$title %||% current[[1]]$opportunity_id %||% "" else ""
  latest_learning <- latest$memory$learning_assessments %||% data.table::data.table()
  latest_closure <- if (length(campaigns)) tryCatch(analytical_campaign_closure_assessment(latest), error = function(e) list(recommendation = "unknown", campaign_confidence = NA_integer_, knowledge_promoted = data.table::data.table())) else list(recommendation = "none", campaign_confidence = NA_integer_, knowledge_promoted = data.table::data.table())
  data.table::data.table(
    total_campaigns = length(campaigns),
    active_campaigns = sum(statuses %in% c("planned", "running")),
    awaiting_approval = sum(statuses == "awaiting_approval"),
    awaiting_adoption = sum(statuses == "awaiting_adoption_decision"),
    blocked_campaigns = sum(statuses %in% c("blocked", "failed")),
    completed_campaigns = sum(statuses == "completed"),
    latest_status = if (length(statuses)) statuses[[length(statuses)]] else "none",
    latest_evidence_readiness = latest$evidence_assessment$readiness %||% "unknown",
    latest_evidence_score = latest$evidence_assessment$confidence_score %||% NA_integer_,
    current_opportunity = current_opportunity,
    remaining_opportunities = sum(vapply(latest_opportunities, function(x) identical(x$status %||% "", "candidate"), logical(1))),
    blocked_opportunities = sum(vapply(latest_opportunities, function(x) identical(x$status %||% "", "blocked_dependency"), logical(1))),
    completed_opportunities = length(latest$memory$completed_opportunity_ids %||% character()),
    learning_assessments = nrow(latest_learning),
    resolved_learning = sum((latest_learning$learning_outcome %||% character()) == "resolved"),
    uncertainty_reduced = sum((latest_learning$learning_outcome %||% character()) %in% c("resolved", "reduced_uncertainty")),
    unresolved_questions = length(latest$memory$unresolved_questions %||% character()),
    closure_recommendation = latest_closure$recommendation %||% "unknown",
    campaign_confidence = latest_closure$campaign_confidence %||% NA_integer_,
    promoted_knowledge = nrow(latest_closure$knowledge_promoted %||% data.table::data.table())
  )
}

qa_analytical_improvement_campaign <- function(output_dir = file.path(tempdir(), "analytical_campaign_qa"), run_catboost = TRUE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  set.seed(2801)
  n <- 80L
  data <- data.table::data.table(
    id = seq_len(n),
    event_date = as.Date("2026-01-01") + seq_len(n),
    channel = sample(c("Search", "Social", "Email"), n, TRUE),
    spend = stats::runif(n, 1, 100),
    clicks = stats::rpois(n, 25)
  )
  data$spend[sample(seq_len(n), 8L)] <- NA_real_
  data[, revenue := 25 + data.table::fifelse(is.na(spend), 45, spend * 1.8) + clicks * 0.7 + stats::rnorm(n, 0, 5)]
  evidence <- feature_experiment_evidence_context(
    data = data,
    artifacts = list(create_artifact("qa_campaign_evidence", "diagnostic", "Campaign Evidence", "qa", metadata = list(created_by_module = TRUE))),
    feature_experiment_state = list(),
    target_col = "revenue",
    feature_cols = c("spend", "clicks"),
    project_id = "qa_campaign_project"
  )
  insufficient_evidence <- evidence
  insufficient_evidence$target_col <- NA_character_
  insufficient_evidence$feature_manifest <- character()
  insufficient_created <- create_analytical_campaign(insufficient_evidence, max_opportunities = 3L)
  created <- create_analytical_campaign(evidence, max_opportunities = 3L)
  campaign <- created$value
  campaign$stopping_criteria$stop_on_accept <- FALSE
  plan <- analytical_campaign_plan(campaign)
  first_pause <- analytical_campaign_execute_next(campaign, data, approval = FALSE, output_dir = output_dir)
  baseline <- NULL
  config <- list()
  catboost_status <- "warning"
  if (isTRUE(run_catboost) && autoquant_catboost_builder_available()) {
    config <- list(
      problem_type = "regression",
      target_col = "revenue",
      feature_cols = c("spend", "clicks"),
      train_fraction = 0.75,
      seed = 2801L,
      iterations = 10L,
      depth = 4L,
      compute_shap = FALSE,
      include_plots = FALSE,
      data_name = "Campaign Baseline",
      modeling_context = modeling_context_from_source(data = data, data_info = list(name = "Campaign Source"), project = list(project_id = "qa_campaign_project"))
    )
    baseline <- run_autoquant_catboost_builder(data, config)
    catboost_status <- if (identical(baseline$status, "success")) "success" else "error"
  }
  executed <- analytical_campaign_execute_next(campaign, data, baseline_result = baseline, catboost_config = config, approval = TRUE, output_dir = output_dir)
  replay <- analytical_campaign_execute_next(executed$value, data, baseline_result = baseline, catboost_config = config, approval = TRUE, output_dir = output_dir)
  second <- analytical_campaign_execute_next(executed$value, data, baseline_result = baseline, catboost_config = config, approval = TRUE, output_dir = output_dir)
  synthesis <- analytical_campaign_synthesis(executed$value)
  second_synthesis <- analytical_campaign_synthesis(second$value)
  reconciliation <- reconcile_analytical_campaign(executed$value)
  campaign_summary <- analytical_campaign_state_summary(list(second$value))
  learning_table <- second$value$memory$learning_assessments %||% data.table::data.table()
  closure <- analytical_campaign_closure_assessment(second$value)
  reuse_campaign <- analytical_campaign_apply_promoted_knowledge(campaign, closure$knowledge_promoted)
  weak_campaign <- second$value
  weak_campaign$evidence_assessment$readiness <- "preliminary"
  weak_campaign$memory$experiment_ids <- character()
  weak_promotion <- analytical_campaign_knowledge_promotion(weak_campaign)
  reloaded <- readRDS(saveRDS(executed$value, file.path(output_dir, "campaign.rds"), version = 3) %||% file.path(output_dir, "campaign.rds"))
  dependency_campaign <- campaign
  if (length(dependency_campaign$opportunities) >= 2L) {
    dependency_campaign$opportunities[[2L]]$dependencies <- "missing_prerequisite_opportunity"
    dependency_campaign <- analytical_campaign_reprioritize(dependency_campaign)
  }
  rows <- data.table::data.table(
    check = c(
      "campaign_creation",
      "opportunity_ranking",
      "evidence_assessment",
      "insufficient_evidence_blocks",
      "campaign_plan",
      "approval_pause",
      "approved_execution",
      "campaign_memory",
      "multi_opportunity_sequence",
      "adaptive_reprioritization",
      "dependency_handling",
      "catboost_baseline_optional",
      "stopping_or_continuation",
      "restart_replay",
      "historical_timeline",
      "remaining_opportunities_updated",
      "campaign_state_summary",
      "learning_assessment",
      "uncertainty_reduction",
      "hypothesis_memory",
      "learning_repeat_prevention",
      "learning_synthesis",
      "closure_recommendation",
      "campaign_confidence",
      "knowledge_promotion",
      "knowledge_non_promotion",
      "reopening_guidance",
      "future_campaign_reuse",
      "closure_traceability",
      "campaign_synthesis",
      "campaign_reconciliation"
    ),
    status = c(
      if (identical(created$status, "success") && identical(campaign$campaign_version, analytical_campaign_schema_version())) "success" else "error",
      if (length(campaign$opportunities) > 0L && all(diff(vapply(campaign$opportunities, function(x) x$score, numeric(1))) <= 0)) "success" else "error",
      if (identical(campaign$evidence_assessment$assessment_version %||% "", "analytical_campaign_evidence_assessment_v1") && campaign$evidence_assessment$readiness %in% c("preliminary", "reasonable", "strong")) "success" else "error",
      if (identical(insufficient_created$status, "success") && identical(insufficient_created$value$status, "blocked") && identical(insufficient_created$value$evidence_assessment$readiness, "insufficient")) "success" else "error",
      if (identical(plan$plan_version, analytical_campaign_plan_schema_version()) && nrow(plan$opportunities) > 0L) "success" else "error",
      if (identical(first_pause$status, "needs_input") && identical(first_pause$value$status, "awaiting_approval")) "success" else "error",
      if (identical(executed$status, "success")) "success" else "error",
      if (length(executed$value$memory$evaluated_opportunity_ids) >= 1L && length(executed$value$memory$execution_ids) >= 1L) "success" else "error",
      if ((identical(catboost_status, "success") && identical(second$status, "success") && length(second$value$memory$evaluated_opportunity_ids) >= 2L) || (!identical(catboost_status, "success") && identical(second$status, "needs_input"))) "success" else "error",
      if (any((second$value$memory$events$event %||% character()) == "opportunities_reprioritized")) "success" else "error",
      if (length(dependency_campaign$opportunities) < 2L || any(vapply(dependency_campaign$opportunities, function(x) identical(x$status %||% "", "blocked_dependency"), logical(1)))) "success" else "error",
      catboost_status,
      if (executed$value$status %in% c("running", "awaiting_adoption_decision", "awaiting_baseline", "completed")) "success" else "error",
      if (identical(reloaded$campaign_id, executed$value$campaign_id) && replay$status %in% c("success", "error", "needs_input")) "success" else "error",
      if (nrow(analytical_campaign_timeline(second$value)) >= 2L) "success" else "error",
      if (nrow(second_synthesis$remaining_opportunities) < nrow(plan$opportunities) || identical(second$status, "needs_input")) "success" else "error",
      if (nrow(campaign_summary) == 1L && all(c("current_opportunity", "remaining_opportunities", "completed_opportunities") %in% names(campaign_summary))) "success" else "error",
      if (nrow(learning_table) >= 1L && all(c("model_outcome", "learning_outcome", "confidence_change") %in% names(learning_table))) "success" else "error",
      if (any((learning_table$learning_outcome %||% character()) %in% c("resolved", "reduced_uncertainty", "maintained_uncertainty", "shifted_uncertainty", "failed_to_generate_useful_evidence"))) "success" else "error",
      if (length(second$value$memory$hypotheses_supported %||% character()) + length(second$value$memory$hypotheses_rejected %||% character()) + length(second$value$memory$hypotheses_uncertain %||% character()) >= 1L) "success" else "error",
      if (length(second$value$memory$low_learning_opportunity_ids %||% character()) >= 1L || any(isFALSE(learning_table$repeat_likely_adds_value))) "success" else if (!identical(catboost_status, "success")) "warning" else "error",
      if (nrow(second_synthesis$learning_assessments %||% data.table::data.table()) >= 1L && nrow(second_synthesis$learning_summary %||% data.table::data.table()) == 1L) "success" else "error",
      if (identical(closure$closure_schema_version, analytical_campaign_closure_schema_version()) && closure$recommendation %in% c("ready_for_closure", "continue_campaign", "await_approval", "await_additional_evidence", "blocked", "requires_human_judgment")) "success" else "error",
      if (is.numeric(closure$campaign_confidence) && closure$campaign_confidence >= 0L && closure$campaign_confidence <= 100L && length(closure$confidence_factors) > 0L) "success" else "error",
      if (nrow(closure$knowledge_promoted %||% data.table::data.table()) >= 1L) "success" else if (!identical(catboost_status, "success")) "warning" else "error",
      if (nrow(weak_promotion$promoted %||% data.table::data.table()) == 0L && nrow(weak_promotion$not_promoted %||% data.table::data.table()) >= 1L) "success" else "error",
      if (nrow(closure$reopening_guidance %||% data.table::data.table()) >= 1L && "new_data" %in% closure$reopening_guidance$condition) "success" else "error",
      if (nrow(closure$knowledge_promoted %||% data.table::data.table()) == 0L || any(vapply(reuse_campaign$opportunities %||% list(), function(x) identical(x$status %||% "", "low_learning_value") || nzchar(x$status_reason %||% ""), logical(1)))) "success" else "error",
      if (nrow(closure$knowledge_promoted %||% data.table::data.table()) == 0L || all(c("campaign_id", "opportunity_id", "proposal_id", "evidence_refs") %in% names(closure$knowledge_promoted))) "success" else "error",
      if (identical(synthesis$synthesis_version, analytical_campaign_synthesis_schema_version()) && nzchar(synthesis$recommendation)) "success" else "error",
      if (identical(reconciliation$status, "success")) "success" else "error"
    ),
    message = c(
      service_result_message(created),
      paste("Opportunities:", length(campaign$opportunities)),
      paste("Evidence readiness:", campaign$evidence_assessment$readiness, "score:", campaign$evidence_assessment$confidence_score),
      service_result_message(analytical_campaign_execute_next(insufficient_created$value, data, approval = TRUE, output_dir = output_dir)),
      paste("Plan opportunities:", nrow(plan$opportunities)),
      service_result_message(first_pause),
      service_result_message(executed),
      paste("Evaluated:", length(executed$value$memory$evaluated_opportunity_ids)),
      paste("Sequential evaluated opportunities:", length(second$value$memory$evaluated_opportunity_ids %||% character())),
      "Campaign reprioritized remaining opportunities after execution.",
      "Dependent opportunities wait for prerequisite completion.",
      if (identical(catboost_status, "success")) "Baseline model available for challenger experiments." else "CatBoost baseline unavailable or skipped.",
      paste("Campaign status:", executed$value$status),
      "Campaign can be serialized and replayed without corrupting state.",
      paste("Timeline entries:", nrow(analytical_campaign_timeline(second$value))),
      paste("Remaining opportunities:", nrow(second_synthesis$remaining_opportunities)),
      paste(campaign_summary$remaining_opportunities[[1]] %||% 0L, "remaining;", campaign_summary$completed_opportunities[[1]] %||% 0L, "completed"),
      paste("Learning assessments:", nrow(learning_table)),
      paste("Learning outcomes:", paste(unique(learning_table$learning_outcome %||% character()), collapse = ", ")),
      paste("Hypothesis memory:", length(second$value$memory$hypotheses_supported %||% character()) + length(second$value$memory$hypotheses_rejected %||% character()) + length(second$value$memory$hypotheses_uncertain %||% character())),
      paste("Low-learning opportunities:", length(second$value$memory$low_learning_opportunity_ids %||% character())),
      paste("Learning summary rows:", nrow(second_synthesis$learning_summary %||% data.table::data.table())),
      paste("Closure recommendation:", closure$recommendation),
      paste("Campaign confidence:", closure$campaign_confidence),
      paste("Promoted knowledge:", nrow(closure$knowledge_promoted %||% data.table::data.table())),
      paste("Weak-evidence non-promoted records:", nrow(weak_promotion$not_promoted %||% data.table::data.table())),
      paste("Reopen conditions:", nrow(closure$reopening_guidance %||% data.table::data.table())),
      "Promoted knowledge can be applied to a future campaign.",
      "Promoted knowledge keeps traceable campaign/opportunity/proposal references.",
      synthesis$recommendation,
      service_result_message(reconciliation)
    )
  )
  rows
}
