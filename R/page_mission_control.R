mission_control_artifact_counts <- function(artifacts) {
  types <- if (length(artifacts)) {
    vapply(artifacts, function(artifact) artifact$artifact_type %||% "artifact", character(1))
  } else {
    character()
  }
  metadata <- lapply(artifacts, function(artifact) artifact$metadata %||% list())
  list(
    total = length(artifacts),
    plots = sum(types == "plot"),
    tables = sum(types == "table"),
    narratives = sum(types %in% c("text", "narrative", "genai_narrative")),
    recommendations = sum(types == "recommendation") + sum(vapply(metadata, function(x) length(x$recommendations %||% character()), integer(1)) > 0L),
    diagnostics = sum(types == "diagnostic") + sum(vapply(metadata, function(x) length(x$diagnostics %||% x$warnings %||% character()), integer(1)) > 0L),
    json = sum(vapply(metadata, function(x) !is.null(x$json_path) || !is.null(x$json), logical(1)))
  )
}

mission_control_quality_summary <- function(artifacts) {
  if (!length(artifacts)) {
    return(list(avg = NA_real_, warnings = 0L, failures = 0L, scored = 0L))
  }
  assessments <- lapply(artifacts, function(artifact) {
    tryCatch(assess_artifact_quality(artifact, render_target = "llm_docx"), error = function(e) NULL)
  })
  assessments <- Filter(Negate(is.null), assessments)
  scores <- suppressWarnings(as.numeric(vapply(assessments, function(x) x$artifact_completeness %||% NA_real_, numeric(1))))
  severities <- vapply(assessments, function(x) x$severity %||% "neutral", character(1))
  list(
    avg = if (length(scores) && any(!is.na(scores))) round(mean(scores, na.rm = TRUE), 1) else NA_real_,
    warnings = sum(severities == "warning"),
    failures = sum(severities == "error"),
    scored = length(assessments)
  )
}

mission_control_status_group <- function(status, artifact_count = 0L, warnings = 0L, errors = 0L) {
  if (errors > 0L || status %in% c("failed", "error")) return("error")
  if (warnings > 0L || status %in% c("warning", "partial")) return("warning")
  if (artifact_count > 0L || status %in% c("completed", "success", "ready", "created")) return("success")
  if (status %in% c("running", "active")) return("info")
  "neutral"
}

mission_control_ai_status <- function(collector, artifacts) {
  artifact_count <- if (nrow(collector)) collector$artifact_count[[1]] %||% 0L else length(artifacts)
  manifest_ready <- nrow(collector) && identical(collector$manifest_status[[1]] %||% "", "ready")
  if (artifact_count > 0L && manifest_ready) return("Ready")
  if (artifact_count > 0L) return("Partial")
  "Incomplete"
}

mission_control_priority_summary <- function(alerts) {
  if (!length(alerts)) {
    return(list(
      title = "No active priorities",
      message = "Mission Control has no open warnings or operational blockers.",
      status = "success"
    ))
  }
  severity_rank <- c(high = 1L, medium = 2L, low = 3L, success = 4L)
  ordered <- alerts[order(vapply(alerts, function(alert) severity_rank[[alert$severity %||% "low"]] %||% 3L, integer(1)))]
  top <- ordered[[1L]]
  status <- switch(top$severity %||% "low", high = "error", medium = "warning", low = "info", success = "success", "neutral")
  list(
    title = paste("Priority:", top$title),
    message = top$message %||% "Review the alert queue for details.",
    status = status
  )
}

mission_control_alerts <- function(artifacts, collector, quality, workflow, improvement = NULL, remediation = NULL, feature_experiments = NULL, campaigns = NULL, decisions = NULL, semantic_workspace = NULL, semantic_decision = NULL, decision_valuation = NULL, decision_workflow = NULL, causal_intelligence = NULL, causal_experiment = NULL, causal_completed_experiment = NULL, causal_itt = NULL, causal_observational = NULL, ai_drafts = NULL, mutations = NULL) {
  alerts <- list()
  add <- function(title, message, severity = "medium", source = NULL) {
    alerts[[length(alerts) + 1L]] <<- list(title = title, message = message, severity = severity, source = source)
  }

  if (!length(artifacts)) {
    add("No evidence generated", "Run Explore Data, Model Readiness, Model Insights, or SHAP to populate the project evidence base.", "high", "Artifacts")
  }
  if (!nrow(collector) || (collector$artifact_count[[1]] %||% 0L) == 0L) {
    add("Collector has no artifacts", "The Project Artifact Collector is not yet preserving evidence for this project.", "high", "Collector")
  } else if (!identical(collector$manifest_status[[1]] %||% "", "ready")) {
    add("Collector manifest not ready", "Artifacts exist, but the manifest is not written or restored as ready.", "medium", "Collector")
  }
  if (!is.na(quality$avg) && quality$avg < 70) {
    add("Artifact quality needs review", paste0("Average LLM completeness is ", quality$avg, "%. Inspect warning artifacts before export."), "medium", "Quality")
  }
  if (quality$warnings > 0L) {
    add("Artifact warnings present", paste(quality$warnings, "artifact(s) have quality warnings."), "medium", "Quality")
  }
  if (quality$failures > 0L) {
    add("Artifact failures present", paste(quality$failures, "artifact(s) failed quality checks."), "high", "Quality")
  }
  implemented_without_artifacts <- workflow[status %in% c("implemented", "experimental") & artifact_count == 0L]
  if (nrow(implemented_without_artifacts)) {
    add(
      "Workflow evidence gaps",
      paste("No artifacts yet for:", paste(implemented_without_artifacts$label, collapse = ", ")),
      "low",
      "Workflow"
    )
  }
  if (!is.null(improvement) && nrow(improvement)) {
    if ((improvement$critical_open[[1]] %||% 0L) > 0L) {
      add("Critical improvement items open", paste(improvement$critical_open[[1]], "critical item(s) require governed review."), "high", "Improvement Ledger")
    }
    if ((improvement$awaiting_user[[1]] %||% 0L) > 0L) {
      add("Improvement items need triage", paste(improvement$awaiting_user[[1]], "item(s) are awaiting user input, approval, or triage."), "medium", "Improvement Ledger")
    }
    if ((improvement$high_priority[[1]] %||% 0L) > 0L) {
      add("High priority improvement work", paste(improvement$high_priority[[1]], "open high-priority item(s) are tracked."), "medium", "Improvement Ledger")
    }
    if (!identical(improvement$ledger_health[[1]] %||% "missing", "healthy") && !identical(improvement$ledger_health[[1]] %||% "missing", "missing")) {
      add("Improvement ledger health issue", paste("Ledger health:", improvement$ledger_health[[1]]), "high", "Improvement Ledger")
    }
  }
  if (!is.null(remediation) && nrow(remediation)) {
    if ((remediation$failed_plans[[1]] %||% 0L) > 0L) {
      add("Remediation plan failed", paste(remediation$failed_plans[[1]], "remediation plan(s) failed or expired."), "high", "Remediation Plans")
    }
    if ((remediation$awaiting_input[[1]] %||% 0L) > 0L) {
      add("Remediation needs manual input", paste(remediation$awaiting_input[[1]], "plan(s) are waiting for user input."), "medium", "Remediation Plans")
    }
    if ((remediation$awaiting_approval[[1]] %||% 0L) > 0L) {
      add("Remediation approval required", paste(remediation$awaiting_approval[[1]], "plan(s) are waiting for approval."), "medium", "Remediation Plans")
    }
    if (!identical(remediation$ledger_health[[1]] %||% "missing", "healthy") && !identical(remediation$ledger_health[[1]] %||% "missing", "missing")) {
      add("Remediation ledger health issue", paste("Ledger health:", remediation$ledger_health[[1]]), "high", "Remediation Plans")
    }
  }
  if (!is.null(feature_experiments) && nrow(feature_experiments)) {
    if ((feature_experiments$awaiting_review[[1]] %||% 0L) > 0L) {
      add("Feature proposals need review", paste(feature_experiments$awaiting_review[[1]], "feature proposal(s) are awaiting approval or rejection."), "medium", "Feature Experiments")
    }
    if ((feature_experiments$approved_proposals[[1]] %||% 0L) > (feature_experiments$executions[[1]] %||% 0L)) {
      add("Approved feature proposal not executed", "At least one approved feature proposal has not produced a Rodeo execution artifact.", "medium", "Feature Experiments")
    }
    if ((feature_experiments$failed_executions[[1]] %||% 0L) > 0L) {
      add("Feature execution failed", paste(feature_experiments$failed_executions[[1]], "Rodeo feature execution(s) failed."), "high", "Feature Experiments")
    }
    if ((feature_experiments$accepted[[1]] %||% 0L) > (feature_experiments$adoptions[[1]] %||% 0L)) {
      add("Accepted challenger awaiting adoption", "A feature challenger was accepted but has not been explicitly adopted.", "medium", "Feature Experiments")
    }
  }
  if (!is.null(campaigns) && nrow(campaigns)) {
    if ((campaigns$awaiting_approval[[1]] %||% 0L) > 0L) {
      add("Analytical campaign awaiting approval", paste(campaigns$awaiting_approval[[1]], "campaign(s) are paused at a governance gate."), "medium", "Analytical Campaign")
    }
    if ((campaigns$blocked_campaigns[[1]] %||% 0L) > 0L) {
      add("Analytical campaign blocked", paste(campaigns$blocked_campaigns[[1]], "campaign(s) need recovery or human decision."), "high", "Analytical Campaign")
    }
    if ((campaigns$awaiting_adoption[[1]] %||% 0L) > 0L) {
      add("Campaign has accepted challenger", "A campaign found an accepted challenger and is waiting for an explicit adoption decision.", "medium", "Analytical Campaign")
    }
    if ((campaigns$low_utility_guidance[[1]] %||% 0L) > 0L) {
      add("Campaign guidance needs review", paste(campaigns$low_utility_guidance[[1]], "promoted knowledge record(s) have low observed transfer utility."), "medium", "Analytical Campaign")
    }
  }
  if (!is.null(decisions) && nrow(decisions)) {
    if ((decisions$awaiting_review[[1]] %||% 0L) > 0L) {
      add("Decision awaiting outcome review", paste(decisions$awaiting_review[[1]], "decision context(s) have not yet been reviewed."), "medium", "Decision Memory")
    }
    if ((decisions$negative_reviews[[1]] %||% 0L) > 0L) {
      add("Decision memory contains negative evidence", paste(decisions$negative_reviews[[1]], "decision review(s) should inform future recommendations."), "medium", "Decision Memory")
    }
    if ((decisions$validated_reviews[[1]] %||% 0L) > 0L) {
      add("Decision learning available", paste(decisions$validated_reviews[[1]], "validated decision review(s) are available for bounded context and future knowledge promotion."), "success", "Decision Memory")
    }
  }
  if (!is.null(semantic_workspace) && nrow(semantic_workspace)) {
    if ((semantic_workspace$validation_errors[[1]] %||% 0L) > 0L) {
      add("Semantic workspace has invalid links", paste(semantic_workspace$validation_errors[[1]], "semantic integrity error(s) require repair before downstream use."), "high", "Semantic Intelligence")
    }
    if ((semantic_workspace$validation_warnings[[1]] %||% 0L) > 0L) {
      add("Semantic workspace needs completion", paste(semantic_workspace$validation_warnings[[1]], "authored knowledge warning(s) remain."), "medium", "Semantic Intelligence")
    }
    if ((semantic_workspace$review_objects[[1]] %||% 0L) > 0L) {
      add("Semantic objects awaiting review", paste(semantic_workspace$review_objects[[1]], "business-intent object(s) are in review state."), "medium", "Semantic Intelligence")
    }
  }
  if (!is.null(semantic_decision) && nrow(semantic_decision)) {
    if ((semantic_decision$validation_errors[[1]] %||% 0L) > 0L) {
      add("Authored decision has blockers", paste(semantic_decision$validation_errors[[1]], "decision lifecycle validation error(s) block assessment or artifact registration."), "high", "Decision Lifecycle")
    }
    if ((semantic_decision$validation_warnings[[1]] %||% 0L) > 0L) {
      add("Authored decision needs evidence", paste(semantic_decision$validation_warnings[[1]], "decision lifecycle warning(s) remain."), "medium", "Decision Lifecycle")
    }
    if (identical(semantic_decision$assessment_status[[1]] %||% "", "stale")) {
      add("Decision assessment is stale", "Authored decision inputs changed after the last deterministic assessment.", "high", "Decision Lifecycle")
    } else if (identical(semantic_decision$assessment_status[[1]] %||% "", "not_assessed") && (semantic_decision$contexts[[1]] %||% 0L) > 0L) {
      add("Decision not assessed", "A decision context exists but has not yet been assessed with AutoQuant.", "medium", "Decision Lifecycle")
    }
    if ((semantic_decision$decisions[[1]] %||% 0L) > 0L && (semantic_decision$reviews[[1]] %||% 0L) == 0L) {
      add("Decision outcome review missing", "A human decision exists without an attached outcome review.", "medium", "Decision Lifecycle")
    }
  }
  if (!is.null(decision_valuation) && nrow(decision_valuation)) {
    if ((decision_valuation$contexts[[1]] %||% 0L) > 0L && identical(decision_valuation$valuation_status[[1]] %||% "", "not_run")) {
      add("Decision valuation not run", "Authored valuation context exists but no economics/recommendation has been generated.", "medium", "Decision Valuation")
    }
    if ((decision_valuation$missing_inputs[[1]] %||% 0L) > 0L) {
      add("Decision valuation has missing inputs", paste(decision_valuation$missing_inputs[[1]], "alternative/scenario row(s) include missing valuation inputs."), "medium", "Decision Valuation")
    }
    if ((decision_valuation$registered_artifacts[[1]] %||% 0L) == 0L && identical(decision_valuation$valuation_status[[1]] %||% "", "current")) {
      add("Decision valuation artifact not registered", "Valuation evidence exists in memory but has not been registered to the collector.", "medium", "Decision Valuation")
    }
    if ((decision_valuation$primary_recommendation[[1]] %||% "") %in% c("escalate_authority", "reject_or_escalate")) {
      add("Decision valuation requires escalation", paste("Primary recommendation:", ui_display_label(decision_valuation$primary_recommendation[[1]])), "high", "Decision Valuation")
    }
  }
  if (!is.null(decision_workflow) && nrow(decision_workflow)) {
    if ((decision_workflow$workflows[[1]] %||% 0L) > 0L && identical(decision_workflow$workflow_status[[1]] %||% "", "not_run")) {
      add("Decision workflow not assessed", "A decision workflow exists but review readiness and follow-through evidence have not been assessed.", "medium", "Decision Workflow")
    }
    if ((decision_workflow$workflows[[1]] %||% 0L) > 0L && !identical(decision_workflow$readiness_state[[1]] %||% "", "ready_for_review") && !identical(decision_workflow$readiness_state[[1]] %||% "", "not_assessed")) {
      add("Decision not ready for review", paste("Readiness:", ui_display_label(decision_workflow$readiness_state[[1]])), "medium", "Decision Workflow")
    }
    if ((decision_workflow$open_conditions[[1]] %||% 0L) > 0L) {
      add("Decision workflow has open conditions", paste(decision_workflow$open_conditions[[1]], "condition(s) remain open, breached, or expired."), "medium", "Decision Workflow")
    }
    if ((decision_workflow$implementation_deviations[[1]] %||% 0L) > 0L) {
      add("Implementation deviation requires review", paste(decision_workflow$implementation_deviations[[1]], "material implementation deviation(s) require escalation or review."), "high", "Decision Workflow")
    }
    if ((decision_workflow$followup_candidates[[1]] %||% 0L) > 0L) {
      add("Follow-up decision candidate available", paste(decision_workflow$followup_candidates[[1]], "follow-up candidate(s) are available from workflow evidence."), "medium", "Decision Workflow")
    }
    if ((decision_workflow$registered_artifacts[[1]] %||% 0L) == 0L && identical(decision_workflow$workflow_status[[1]] %||% "", "current")) {
      add("Decision workflow artifact not registered", "Workflow evidence exists in memory but has not been registered to the collector.", "medium", "Decision Workflow")
    }
  }
  if (!is.null(causal_intelligence) && nrow(causal_intelligence)) {
    if ((causal_intelligence$questions[[1]] %||% 0L) > 0L && !identical(causal_intelligence$assessment_status[[1]] %||% "", "current")) {
      add("Causal plan is not current", "A causal question exists but its identification plan has not been assessed or is stale.", "medium", "Causal Intelligence")
    }
    if (identical(causal_intelligence$identification_status[[1]] %||% "", "conflicting causal structure")) {
      add("Causal structure has blockers", "Causal graph diagnostics report structural blockers before any effect estimation can be considered.", "high", "Causal Intelligence")
    }
    if ((causal_intelligence$registered_artifacts[[1]] %||% 0L) == 0L && identical(causal_intelligence$assessment_status[[1]] %||% "", "current")) {
      add("Causal planning artifact not registered", "The current identification plan has not been preserved as a project artifact.", "medium", "Causal Intelligence")
    }
  }
  if (!is.null(causal_experiment) && nrow(causal_experiment)) {
    if ((causal_experiment$experiment_questions[[1]] %||% 0L) > 0L && !identical(causal_experiment$plan_status[[1]] %||% "", "current")) {
      add("Experiment design plan is not current", "An experiment question exists but its governed design plan has not been generated or is stale.", "medium", "Causal Experiment Design")
    }
    if (identical(causal_experiment$gate_status[[1]] %||% "", "approval_required")) {
      add("Experiment design requires approval", "Authority, coverage, measurement, or design blockers remain before any operational handoff.", "high", "Causal Experiment Design")
    }
    if ((causal_experiment$registered_artifacts[[1]] %||% 0L) == 0L && identical(causal_experiment$plan_status[[1]] %||% "", "current")) {
      add("Experiment plan artifact not registered", "The current governed experiment design has not been preserved as project evidence.", "medium", "Causal Experiment Design")
    }
  }
  if (!is.null(causal_completed_experiment) && nrow(causal_completed_experiment)) {
    if ((causal_completed_experiment$completed_experiments[[1]] %||% 0L) > 0L && !identical(causal_completed_experiment$assessment_status[[1]] %||% "", "current")) {
      add("Completed experiment readiness is not current", "Completed or in-progress experiment evidence exists but readiness has not been assessed or is stale.", "medium", "Causal Completed Evidence")
    }
    if (!isTRUE(causal_completed_experiment$assignment_preserved[[1]]) && (causal_completed_experiment$completed_experiments[[1]] %||% 0L) > 0L) {
      add("Original assignment evidence missing", "Completed experiment evidence cannot support ITT analysis until original assignment is preserved.", "high", "Causal Completed Evidence")
    }
    if (!isTRUE(causal_completed_experiment$outcome_available[[1]]) && (causal_completed_experiment$completed_experiments[[1]] %||% 0L) > 0L) {
      add("Outcome evidence missing", "Completed experiment evidence has no mapped outcome evidence for analysis readiness.", "high", "Causal Completed Evidence")
    }
    if ((causal_completed_experiment$readiness_state[[1]] %||% "") %in% c("estimand_revision_required", "blocked", "invalid_for_planned_estimand")) {
      add("Completed experiment has causal readiness blockers", paste("Readiness:", ui_display_label(causal_completed_experiment$readiness_state[[1]])), "high", "Causal Completed Evidence")
    }
    if ((causal_completed_experiment$registered_artifacts[[1]] %||% 0L) == 0L && identical(causal_completed_experiment$assessment_status[[1]] %||% "", "current")) {
      add("Completed experiment readiness artifact not registered", "The completed-experiment readiness assessment has not been preserved as project evidence.", "medium", "Causal Completed Evidence")
    }
  }
  if (!is.null(causal_itt) && nrow(causal_itt)) {
    if ((causal_itt$specs[[1]] %||% 0L) > 0L && identical(causal_itt$analysis_status[[1]] %||% "", "not_run")) {
      add("Randomized ITT spec not run", "A governed ITT specification exists but has not produced effect evidence.", "medium", "Causal ITT")
    }
    if (identical(causal_itt$analysis_status[[1]] %||% "", "readiness_blocked")) {
      add("Randomized ITT analysis blocked", "The ITT readiness gate blocked estimation. Review completed-experiment evidence before using causal effect claims.", "high", "Causal ITT")
    }
    if (isTRUE(causal_itt$effect_estimated[[1]]) && !identical(causal_itt$review_status[[1]] %||% "", "approved_evidence")) {
      add("Randomized ITT evidence needs review", "An ITT effect has been estimated but not approved as decision evidence.", "medium", "Causal ITT")
    }
    if (isTRUE(causal_itt$effect_estimated[[1]]) && (causal_itt$registered_artifacts[[1]] %||% 0L) == 0L) {
      add("Randomized ITT artifact not registered", "The ITT effect evidence has not been preserved as a project artifact.", "medium", "Causal ITT")
    }
    if (isTRUE(causal_itt$effect_estimated[[1]]) && identical(causal_itt$design_depth_status[[1]] %||% "", "not_available")) {
      add("Randomized design-depth evidence unavailable", "Run with the updated AutoQuant randomized design analysis contract to inspect variance reduction, robustness, and report evidence.", "medium", "Causal ITT")
    }
    if ((causal_itt$robustness_rows[[1]] %||% 0L) > 1L && identical(causal_itt$causal_report_status[[1]] %||% "", "available")) {
      add("Causal effect report available", "Review the randomized evidence report before linking evidence to a decision.", "low", "Causal ITT")
    }
    if ((causal_itt$materiality_state[[1]] %||% "") %in% c("materially_harmful", "possible_harm")) {
      add("Randomized ITT indicates possible harm", paste("Materiality:", ui_display_label(causal_itt$materiality_state[[1]])), "high", "Causal ITT")
    }
  }
  if (!is.null(causal_observational) && nrow(causal_observational)) {
    if ((causal_observational$studies[[1]] %||% 0L) > 0L && isTRUE(causal_observational$stale[[1]])) {
      add("Observational causal plan is stale", "Study inputs changed or readiness has not been assessed.", "medium", "Observational Causal")
    }
    if ((causal_observational$assignment_mechanism[[1]] %||% "") %in% c("unknown", "")) {
      add("Assignment mechanism unknown", "Observational causal planning requires evidence about why units received treatment.", "medium", "Observational Causal")
    }
    if ((causal_observational$overlap_state[[1]] %||% "") %in% c("severe positivity concern", "no credible support")) {
      add("Observational overlap concern", paste("Overlap state:", ui_display_label(causal_observational$overlap_state[[1]])), "high", "Observational Causal")
    }
    if ((causal_observational$readiness_state[[1]] %||% "") %in% c("experiment_preferred", "blocked", "unidentified")) {
      add("Observational estimation not supported", paste("Readiness:", ui_display_label(causal_observational$readiness_state[[1]])), "high", "Observational Causal")
    } else if ((causal_observational$readiness_state[[1]] %||% "") %in% c("ready_for_design_implementation", "ready_with_strong_assumptions")) {
      add("Observational design plan ready", "Planning evidence exists for a future observational estimator under explicit assumptions.", "success", "Observational Causal")
    }
    if ((causal_observational$did_status[[1]] %||% "not_estimated") %in% c("estimated_requires_review", "diagnostic_blocked")) {
      add("DiD evidence needs review", paste("Difference-in-Differences status:", ui_display_label(causal_observational$did_status[[1]])), "medium", "Observational Causal")
    }
  }
  if (exists("ai_runtime_qualification_summary", mode = "function")) {
    ai_runtime <- tryCatch(ai_runtime_qualification_summary(), error = function(e) NULL)
    if (!is.null(ai_runtime) && nrow(ai_runtime)) {
      if ((ai_runtime$expired[[1]] %||% 0L) > 0L) {
        add("AI runtime qualification expired", "At least one model qualification is stale after runtime or bundle changes and should be re-evaluated.", "medium", "AI Runtime")
      }
      if ((ai_runtime$failures[[1]] %||% 0L) > 0L) {
        add("AI runtime has unqualified tasks", paste(ai_runtime$failures[[1]], "task/model qualification result(s) require human review, stronger model routing, or validation."), "medium", "AI Runtime")
      }
      if ((ai_runtime$qualified_tasks[[1]] %||% 0L) > 0L) {
        add("AI runtime qualification available", paste("Preferred runtime profile:", ui_display_label(ai_runtime$preferred_model_tier[[1]] %||% "human")), "low", "AI Runtime")
      }
    }
  }
  if (exists("product_experience_runtime_discovery", mode = "function")) {
    product_experience_runtime <- tryCatch(product_experience_runtime_discovery(), error = function(e) NULL)
    if (!is.null(product_experience_runtime) && nrow(product_experience_runtime)) {
      available <- stats::setNames(product_experience_runtime$available, product_experience_runtime$component)
      if (!isTRUE(available[["node"]]) || !isTRUE(available[["playwright"]])) {
        add("Product Experience recorder unavailable", "The Golden Workflow browser runtime is not fully provisioned. Product Experience Lab can provision and validate it.", "medium", "Product Experience")
      } else if (isTRUE(available[["previous_reports"]]) && isTRUE(available[["previous_videos"]]) && isTRUE(available[["previous_traces"]])) {
        add("Golden Workflow recording available", "Product Experience Lab has recorded browser replay evidence with report, video, and trace artifacts.", "low", "Product Experience")
      } else {
        add("Product Experience runtime ready", "Browser automation is provisioned; run the Golden Workflow replay to create recording evidence.", "low", "Product Experience")
      }
    }
  }
  if (exists("run_artifact_retrieval_benchmark", mode = "function")) {
    retrieval_benchmark <- tryCatch(run_artifact_retrieval_benchmark(), error = function(e) NULL)
    if (!is.null(retrieval_benchmark) && nrow(retrieval_benchmark)) {
      progressive <- retrieval_benchmark[strategy == "progressive_retrieval"]
      everything <- retrieval_benchmark[strategy == "retrieve_everything"]
      if (nrow(progressive) && nrow(everything) && (progressive$average_total_tokens[[1]] %||% Inf) > (everything$average_total_tokens[[1]] %||% 0L)) {
        add("AI context growth needs review", "Progressive artifact retrieval is using more context than retrieve-everything for the current fixture.", "medium", "AI Runtime")
      }
      if (nrow(progressive) && (progressive$retrieval_count[[1]] %||% 0L) > 3L) {
        add("AI retrieval loop risk", "Progressive retrieval needed repeated expansion. Review artifact summaries or bundle fit.", "medium", "AI Runtime")
      }
    }
  }
  if (exists("plan_cross_artifact_synthesis", mode = "function")) {
    synthesis_plan <- tryCatch(plan_cross_artifact_synthesis(), error = function(e) NULL)
    if (!is.null(synthesis_plan)) {
      if (!isTRUE(synthesis_plan$sufficiency$sufficient)) {
        add("Evidence synthesis is insufficient", paste("Sufficiency:", ui_display_label(synthesis_plan$sufficiency$state %||% "unknown")), "medium", "AI Runtime")
      }
      if (nrow(synthesis_plan$contradictions %||% data.table::data.table()) > 0L) {
        add("Contradictory artifacts need review", paste(nrow(synthesis_plan$contradictions), "artifact contradiction or scope-difference signal(s) detected."), "medium", "AI Runtime")
      }
      missing <- synthesis_plan$sufficiency$missing_evidence_classes %||% character()
      if (length(missing)) {
        if ("Valuation" %in% missing) add("Missing valuation evidence", "Cross-artifact synthesis cannot fully support economics-sensitive guidance without valuation evidence.", "medium", "AI Runtime")
        if (any(missing %in% c("Observational", "Randomized", "Experimental"))) add("Missing causal evidence", "Cross-artifact synthesis needs causal or design evidence before stronger effect claims.", "medium", "AI Runtime")
        if ("Workflow" %in% missing) add("Missing workflow evidence", "Workflow evidence is needed to explain readiness or next supported actions.", "low", "AI Runtime")
        if ("Authority" %in% missing) add("Missing authority evidence", "Authority or approval evidence is missing for governance-sensitive synthesis.", "medium", "AI Runtime")
      }
    }
  }
  if (exists("run_ai_operated_evidence_review", mode = "function")) {
    evidence_review <- tryCatch(run_ai_operated_evidence_review(ctx, "What evidence supports the next action?")$value, error = function(e) NULL)
    if (!is.null(evidence_review)) {
      add("Evidence review available", "A governed evidence review can inspect current artifacts and recommend the next supported action.", "low", "AI Runtime")
      if (!isTRUE(evidence_review$sufficiency$sufficient)) {
        add("Evidence review incomplete", paste("Action sufficiency:", ui_display_label(evidence_review$sufficiency$state %||% "unknown")), "medium", "AI Runtime")
      }
      if (nrow(evidence_review$synthesis_summary$contradictions %||% data.table::data.table()) > 0L) {
        add("Contradiction requires review", "The governed review found contradiction or scope-difference evidence that should be inspected before strengthening recommendations.", "medium", "AI Runtime")
      }
      if (isTRUE(evidence_review$sufficiency$sufficient)) {
        add("Evidence sufficient for next step", paste("Recommended action:", evidence_review$recommended_next_action$action_id %||% "review"), "success", "AI Runtime")
      }
      if (nrow(evidence_review$ranked_actions %||% data.table::data.table()) == 0L) {
        add("No supported AI action", "The evidence review did not find an action from existing supported-action contracts.", "medium", "AI Runtime")
      } else if (identical(evidence_review$ranked_actions$current_eligibility[[1]] %||% "", "blocked")) {
        add("Recommended next action blocked", evidence_review$ranked_actions$reason_blocked[[1]] %||% "A prerequisite blocks the top action.", "medium", "AI Runtime")
      }
      if (identical(evidence_review$model_routing$escalation %||% "", "human_review")) {
        add("Human review required", evidence_review$model_routing$reason %||% "The review requires human judgment.", "high", "AI Runtime")
      }
      if (identical(evidence_review$draft$confirmation_state %||% "", "preview_only") && any((evidence_review$ranked_actions$action_class %||% integer()) == 2L)) {
        add("Evidence review draft awaiting confirmation", "A Class 2 preview draft is available; explicit confirmation is required before any storage path is used.", "low", "AI Runtime")
      }
      stale_ids <- evidence_review$binder$stale_artifacts %||% character()
      if (length(stale_ids)) {
        add("Evidence review stale", paste(length(stale_ids), "artifact(s) should be refreshed before downstream claims."), "medium", "AI Runtime")
      }
    }
  }
  if (!is.null(ai_drafts) && nrow(ai_drafts)) {
    if ((ai_drafts$drafts_confirmed[[1]] %||% 0L) > 0L) {
      add("AI draft awaiting persistence", paste(ai_drafts$drafts_confirmed[[1]], "confirmed AI draft(s) are awaiting governed persistence."), "medium", "AI Drafts")
    }
    if ((ai_drafts$drafts_persisted[[1]] %||% 0L) > 0L) {
      add("AI draft persisted", paste(ai_drafts$drafts_persisted[[1]], "AI draft(s) are persisted in project state."), "success", "AI Drafts")
    }
    if ((ai_drafts$drafts_rejected[[1]] %||% 0L) > 0L) {
      add("AI draft rejected", paste(ai_drafts$drafts_rejected[[1]], "AI draft(s) were rejected and retained for audit."), "low", "AI Drafts")
    }
    if ((ai_drafts$drafts_archived[[1]] %||% 0L) > 0L) {
      add("AI draft archived", paste(ai_drafts$drafts_archived[[1]], "AI draft(s) are archived."), "low", "AI Drafts")
    }
    if ((ai_drafts$drafts_undone[[1]] %||% 0L) > 0L) {
      add("AI draft undo recorded", paste(ai_drafts$drafts_undone[[1]], "AI draft persistence operation(s) were undone."), "medium", "AI Drafts")
    }
    if ((ai_drafts$validation_failures[[1]] %||% 0L) > 0L ||
        (ai_drafts$citation_failures[[1]] %||% 0L) > 0L ||
        (ai_drafts$handler_failures[[1]] %||% 0L) > 0L) {
      add("AI draft validation failed", "At least one AI draft failed deterministic validation before persistence.", "high", "AI Drafts")
    }
  }
  if (!is.null(mutations) && nrow(mutations)) {
    if ((mutations$pending[[1]] %||% 0L) > 0L) {
      add("Mutation pending governance", paste(mutations$pending[[1]], "AI mutation proposal(s) are pending validation, preview, confirmation, or persistence."), "medium", "Mutation Governance")
    }
    if ((mutations$persisted[[1]] %||% 0L) > 0L) {
      add("Mutation persisted", paste(mutations$persisted[[1]], "governed mutation(s) are persisted with audit history."), "success", "Mutation Governance")
    }
    if ((mutations$rejected[[1]] %||% 0L) > 0L) {
      add("Mutation rejected", paste(mutations$rejected[[1]], "mutation proposal(s) were rejected and retained for audit."), "low", "Mutation Governance")
    }
    if ((mutations$expired[[1]] %||% 0L) > 0L) {
      add("Mutation expired", paste(mutations$expired[[1]], "mutation proposal(s) expired before confirmation."), "medium", "Mutation Governance")
    }
    if ((mutations$high_or_critical[[1]] %||% 0L) > 0L) {
      add("High-risk mutation present", paste(mutations$high_or_critical[[1]], "high or critical mutation proposal(s) require stronger governance."), "high", "Mutation Governance")
    }
    if ((mutations$validation_failures[[1]] %||% 0L) > 0L) {
      add("Mutation validation failed", "At least one mutation failed deterministic validation before persistence.", "high", "Mutation Governance")
    }
    if ((mutations$undo_available[[1]] %||% 0L) > 0L) {
      add("Mutation undo available", paste(mutations$undo_available[[1]], "persisted mutation(s) can be undone, archived, or superseded."), "low", "Mutation Governance")
    }
  }

  if (!length(alerts)) {
    alerts <- list(list(
      title = "No open decisions",
      message = "Mission Control did not detect active warnings, missing collector evidence, or artifact quality failures.",
      severity = "success",
      source = "Project"
    ))
  }
  alerts
}

mission_control_timeline <- function(ctx, artifacts, collector) {
  items <- list()
  add <- function(time, title, detail = NULL, status = "neutral") {
    items[[length(items) + 1L]] <<- list(time = time, title = title, detail = detail, status = status)
  }
  fmt <- function(x) {
    time <- suppressWarnings(as.POSIXct(x))
    if (is.na(time)) return("--:--")
    format(time, "%H:%M")
  }

  data_info <- tryCatch(ctx$project_data_info(), error = function(e) list(path = NULL, name = NULL))
  if (!is.null(data_info$name)) {
    add(format(Sys.time(), "%H:%M"), "Dataset loaded", data_info$name, "success")
  }
  if (length(artifacts)) {
    artifact_rows <- lapply(artifacts, function(artifact) {
      time <- artifact$updated_at %||% artifact$created_at %||% artifact$metadata$generated_at %||% artifact$metadata$run_timestamp %||% Sys.time()
      list(time = time, artifact = artifact)
    })
    artifact_rows <- artifact_rows[order(vapply(artifact_rows, function(x) as.numeric(as.POSIXct(x$time)), numeric(1)), decreasing = TRUE)]
    for (row in utils::head(artifact_rows, 8L)) {
      artifact <- row$artifact
      add(
        fmt(row$time),
        paste(artifact$label %||% artifact$artifact_id, "created"),
        module_display_label(artifact$source_module, "Artifact"),
        "success"
      )
    }
  }
  if (nrow(collector) && (collector$artifact_count[[1]] %||% 0L) > 0L) {
    add(format(Sys.time(), "%H:%M"), "Collector available", paste(collector$artifact_count[[1]], "artifacts preserved"), "success")
  }
  if (!length(items)) {
    return(list())
  }
  items
}

mission_control_workflow_rows <- function(ctx) {
  workflow <- workflow_state_summary(ctx)
  workflow[, display_status := data.table::fifelse(
    artifact_count > 0L,
    "Completed",
    data.table::fifelse(status %in% c("implemented", "experimental"), "Not Started", data.table::fifelse(status == "planned", "Planned", "Future"))
  )]
  workflow[, status_group := mapply(mission_control_status_group, display_status, artifact_count, 0L, 0L)]
  workflow[, action := data.table::fifelse(!is.na(page) & nzchar(page), "Open", "Planned")]
  workflow[]
}

page_mission_control_ui <- function(id) {
  ns <- NS(id)
  tabPanel(
    "Mission Control",
    ui_page(
      title = "Mission Control",
      subtitle = "Operational awareness for the project, modules, evidence, collector, QA, and AI readiness.",
      eyebrow = "Operations",
      actions = ui_action_row(
        actionButton(ns("open_artifacts"), "Open Artifact Studio", class = "btn-primary"),
        actionButton(ns("open_modules"), "Run Analysis", class = "btn-secondary")
      ),
      tags$div(
        class = "aq-mission-control",
        uiOutput(ns("project_health")),
        uiOutput(ns("priority_summary")),
        tags$div(
          class = "aq-mission-control-grid",
          ui_card(
            title = "System Status",
            subtitle = "Module and workflow readiness.",
            uiOutput(ns("system_status"))
          ),
          ui_card(
            title = "Alerts / Open Decisions",
            subtitle = "Prioritized operational queue, not an error dump.",
            uiOutput(ns("alerts"))
          ),
          ui_card(
            title = "Decision Work Queue",
            subtitle = "Deterministic next actions from authored decision, valuation, and workflow state.",
            uiOutput(ns("decision_work_queue"))
          ),
          ui_card(
            title = "Async Jobs",
            subtitle = "Long-running workstation work.",
            uiOutput(ns("async_jobs"))
          ),
          uiOutput(ns("genai_status"))
        ),
        tags$div(
          class = "aq-mission-control-grid",
          ui_card(
            title = "AI Assistance",
            subtitle = "Read-only explanations from the configured GenAI provider.",
            ui_action_row(
              actionButton(ns("explain_alerts"), "Explain Alerts", class = "btn-primary btn-sm"),
              actionButton(ns("suggest_next_action"), "Suggest Next Action", class = "btn-secondary btn-sm")
            ),
            uiOutput(ns("genai_result"))
          )
        ),
        ui_card(
          title = "Run Timeline",
          subtitle = "Recent analytical activity reconstructed from project evidence.",
          uiOutput(ns("timeline"))
        )
      )
    )
  )
}

page_mission_control_server <- function(id, ctx) {
  moduleServer(id, function(input, output, session) {
    mission_state <- reactive({
      artifacts <- tryCatch(ctx$all_artifacts(), error = function(e) list())
      collector <- tryCatch(ctx$project_collector_summary(), error = function(e) data.table::data.table())
      data <- tryCatch(ctx$project_data(), error = function(e) NULL)
      plans <- tryCatch(ctx$report_plan_state$plans, error = function(e) list())
      workflow <- mission_control_workflow_rows(ctx)
      async <- tryCatch(async_job_status_counts(), error = function(e) list(total = 0L, running = 0L, completed = 0L, failed = 0L, latest_status = "unavailable", latest_job_id = NA_character_))
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      genai_jobs <- tryCatch(genai_job_summary(project), error = function(e) data.table::data.table())
      improvement <- tryCatch({
        if (is.list(project) && identical(project$project_state %||% "", "project_ready")) improvement_ledger_summary(project) else data.table::data.table(ledger_health = "missing", total_items = 0L, open_items = 0L, critical_open = 0L, awaiting_user = 0L, high_priority = 0L, resolved_items = 0L)
      }, error = function(e) data.table::data.table(ledger_health = "unavailable", total_items = 0L, open_items = 0L, critical_open = 0L, awaiting_user = 0L, high_priority = 0L, resolved_items = 0L))
      remediation <- tryCatch({
        if (is.list(project) && identical(project$project_state %||% "", "project_ready")) remediation_plan_summary(project) else data.table::data.table(ledger_health = "missing", total_plans = 0L, active_plans = 0L, awaiting_input = 0L, awaiting_approval = 0L, failed_plans = 0L)
      }, error = function(e) data.table::data.table(ledger_health = "unavailable", total_plans = 0L, active_plans = 0L, awaiting_input = 0L, awaiting_approval = 0L, failed_plans = 0L))
      feature_experiments <- tryCatch(feature_experiment_state_summary(list(
        proposals = ctx$feature_experiment_state$proposals,
        executions = ctx$feature_experiment_state$executions,
        experiments = ctx$feature_experiment_state$experiments,
        adoptions = ctx$feature_experiment_state$adoptions
      )), error = function(e) data.table::data.table(total_proposals = 0L, awaiting_review = 0L, approved_proposals = 0L, unsupported_or_blocked = 0L, executions = 0L, failed_executions = 0L, experiments = 0L, accepted = 0L, rejected = 0L, inconclusive = 0L, adoptions = 0L))
      campaigns <- tryCatch(analytical_campaign_state_summary(ctx$analytical_campaign_state$campaigns), error = function(e) data.table::data.table(total_campaigns = 0L, active_campaigns = 0L, awaiting_approval = 0L, awaiting_adoption = 0L, blocked_campaigns = 0L, completed_campaigns = 0L, latest_status = "none", latest_evidence_readiness = "unknown", latest_evidence_score = NA_integer_, current_opportunity = "", remaining_opportunities = 0L, blocked_opportunities = 0L, completed_opportunities = 0L, learning_assessments = 0L, resolved_learning = 0L, uncertainty_reduced = 0L, unresolved_questions = 0L, closure_recommendation = "none", campaign_confidence = NA_integer_, promoted_knowledge = 0L, knowledge_awaiting_validation = 0L, knowledge_validated = 0L, knowledge_weakened = 0L, knowledge_superseded = 0L, knowledge_conflicts = 0L, knowledge_applicable = 0L, knowledge_uncertain = 0L, knowledge_narrowed = 0L, knowledge_broadened = 0L, knowledge_utility_events = 0L, high_value_guidance = 0L, guidance_needing_validation = 0L, low_utility_guidance = 0L, guidance_calibration_changes = 0L, knowledge_helped = 0L, knowledge_did_not_help = 0L))
      decisions <- tryCatch(ctx$decision_memory_summary(), error = function(e) data.table::data.table(decision_contexts = 0L, reviews = 0L, memory_artifacts = 0L, validated_reviews = 0L, negative_reviews = 0L, awaiting_review = 0L, last_status = "unavailable"))
      semantic_workspace <- tryCatch(semantic_workspace_summary(ctx$semantic_workspace()), error = function(e) data.table::data.table(total_objects = 0L, draft_objects = 0L, review_objects = 0L, approved_objects = 0L, archived_objects = 0L, relationships = 0L, validation_errors = 0L, validation_warnings = 0L, last_event = "unavailable"))
      semantic_decision <- tryCatch(semantic_decision_summary(ctx$semantic_decision_state(), ctx$semantic_workspace()), error = function(e) data.table::data.table(contexts = 0L, alternatives = 0L, criteria = 0L, financial_impacts = 0L, uncertainties = 0L, optionality = 0L, recommendations = 0L, decisions = 0L, reviews = 0L, validation_errors = 0L, validation_warnings = 0L, assessment_status = "unavailable", registered_artifacts = 0L))
      decision_valuation <- tryCatch(decision_valuation_summary(ctx$decision_valuation_state()), error = function(e) data.table::data.table(contexts = 0L, active_valuation_context_id = NA_character_, cash_flows = 0L, impact_mappings = 0L, scenarios = 0L, thresholds = 0L, valuation_status = "unavailable", alternatives_valued = 0L, missing_inputs = 0L, recommendation_count = 0L, primary_recommendation = "unavailable", registered_artifacts = 0L, last_message = "unavailable"))
      decision_workflow <- tryCatch(decision_workflow_summary(ctx$decision_workflow_state()), error = function(e) data.table::data.table(workflows = 0L, active_workflow_id = NA_character_, workflow_status = "unavailable", readiness_state = "unavailable", reviews = 0L, approvals = 0L, open_conditions = 0L, implementation_deviations = 0L, quality_state = "unavailable", followup_candidates = 0L, registered_artifacts = 0L))
      causal_intelligence <- tryCatch(causal_intelligence_summary(ctx$causal_intelligence_state()), error = function(e) data.table::data.table(questions = 0L, roles = 0L, relationships = 0L, assessment_status = "unavailable", identification_status = "unavailable", registered_artifacts = 0L))
      causal_experiment <- tryCatch(causal_experiment_summary(ctx$causal_experiment_state()), error = function(e) data.table::data.table(experiment_questions = 0L, design_specs = 0L, plan_status = "unavailable", gate_status = "unavailable", execution_ready = FALSE, registered_artifacts = 0L))
      causal_completed_experiment <- tryCatch(causal_completed_experiment_summary(ctx$causal_completed_experiment_state()), error = function(e) data.table::data.table(completed_experiments = 0L, evidence_mappings = 0L, readiness_state = "unavailable", assessment_status = "unavailable", assignment_preserved = FALSE, outcome_available = FALSE, guardrail_status = "unavailable", registered_artifacts = 0L))
      causal_itt <- tryCatch(causal_itt_summary(ctx$causal_itt_state()), error = function(e) data.table::data.table(specs = 0L, active_analysis_id = NA_character_, analysis_status = "unavailable", effect_estimated = FALSE, review_status = "unavailable", estimate = NA_real_, conf_low = NA_real_, conf_high = NA_real_, materiality_state = "unavailable", registered_artifacts = 0L, design_depth_status = "unavailable", causal_report_status = "unavailable", robustness_rows = 0L))
      causal_observational <- tryCatch(causal_observational_summary(ctx$causal_observational_state()), error = function(e) data.table::data.table(studies = 0L, active_study_id = NA_character_, readiness_state = "unavailable", overlap_state = "unavailable", assignment_mechanism = "unknown", effect_status = "unavailable", did_status = "unavailable", stale = TRUE, registered_artifacts = 0L))
      ai_drafts <- tryCatch(ai_draft_mutation_diagnostics(list(ai_draft_store = ctx$ai_draft_state$store)), error = function(e) data.table::data.table(drafts_generated = 0L, drafts_confirmed = 0L, drafts_persisted = 0L, drafts_rejected = 0L, drafts_undone = 0L, drafts_archived = 0L, validation_failures = 0L, confirmation_failures = 0L, runtime_failures = 0L, handler_failures = 0L, citation_failures = 0L, undo_available = 0L, archive_available = 0L))
      mutations <- tryCatch(mutation_governance_diagnostics(list(ai_mutation_store = ctx$ai_mutation_state$store)), error = function(e) data.table::data.table(mutations = 0L, pending = 0L, persisted = 0L, rejected = 0L, archived = 0L, undone = 0L, expired = 0L, superseded = 0L, high_or_critical = 0L, validation_failures = 0L, undo_available = 0L, archive_available = 0L))
      counts <- mission_control_artifact_counts(artifacts)
      quality <- mission_control_quality_summary(artifacts)
      ai_status <- mission_control_ai_status(collector, artifacts)
      list(
        artifacts = artifacts,
        collector = collector,
        data = data,
        plans = plans,
        workflow = workflow,
        async = async,
        genai_jobs = genai_jobs,
        improvement = improvement,
        remediation = remediation,
        feature_experiments = feature_experiments,
        campaigns = campaigns,
        decisions = decisions,
        semantic_workspace = semantic_workspace,
        semantic_decision = semantic_decision,
        decision_valuation = decision_valuation,
        decision_workflow = decision_workflow,
        causal_intelligence = causal_intelligence,
        causal_experiment = causal_experiment,
        causal_completed_experiment = causal_completed_experiment,
        causal_itt = causal_itt,
        causal_observational = causal_observational,
        ai_drafts = ai_drafts,
        mutations = mutations,
        counts = counts,
        quality = quality,
        ai_status = ai_status,
        alerts = mission_control_alerts(artifacts, collector, quality, workflow, improvement, remediation, feature_experiments, campaigns, decisions, semantic_workspace, semantic_decision, decision_valuation, decision_workflow, causal_intelligence, causal_experiment, causal_completed_experiment, causal_itt, causal_observational, ai_drafts, mutations),
        timeline = mission_control_timeline(ctx, artifacts, collector)
      )
    })

    output$project_health <- renderUI({
      state <- mission_state()
      collector_status <- if (nrow(state$collector)) state$collector$collector_status[[1]] %||% "not_created" else "not_created"
      manifest_status <- if (nrow(state$collector)) state$collector$manifest_status[[1]] %||% "not_written" else "not_written"
      qa_status <- tryCatch({
        qa <- qa_artifact_studio()
        if (any(qa$status == "error")) "warning" else "healthy"
      }, error = function(e) "unknown")
      quality_status <- mission_control_status_group("success", warnings = state$quality$warnings, errors = state$quality$failures)
      mission_status <- if (state$quality$failures > 0L || state$counts$total == 0L) {
        "critical"
      } else if (state$quality$warnings > 0L || !identical(manifest_status, "ready") || !identical(state$ai_status, "Ready")) {
        "attention"
      } else {
        "healthy"
      }
      mission_title <- switch(
        mission_status,
        critical = "Mission state: evidence gap",
        attention = "Mission state: attention required",
        healthy = "Mission state: operational",
        "Mission state: monitoring"
      )
      mission_message <- switch(
        mission_status,
        critical = "Evidence generation or collector readiness needs immediate attention before this project can be trusted.",
        attention = "The project is active and evidence is available, but readiness gaps or quality warnings deserve review.",
        healthy = "Core evidence, collector output, QA, and AI readiness are aligned.",
        "Mission Control is monitoring project state."
      )
      mission_facts <- list(
        Evidence = paste(state$counts$total, "artifacts"),
        Collector = ui_status_label(collector_status),
        Quality = if (is.na(state$quality$avg)) "Not scored" else paste0(state$quality$avg, "%"),
        Alerts = length(state$alerts)
      )
      ui_health_summary(
        ui_mission_state_banner(mission_status, mission_title, mission_message, mission_facts),
        ui_status_tile("Project", if (is.null(state$data)) "Waiting" else "Active", status = if (is.null(state$data)) "neutral" else "success", detail = if (is.null(state$data)) "No dataset loaded" else paste(nrow(state$data), "rows")),
        ui_status_tile("Collector", ui_status_label(collector_status), status = mission_control_status_group(collector_status, artifact_count = state$counts$total), detail = paste(state$counts$total, "artifacts")),
        ui_status_tile("AI Readiness", state$ai_status, status = mission_control_status_group(tolower(state$ai_status), artifact_count = state$counts$total), detail = ui_status_label(manifest_status)),
        ui_status_tile("Artifact Quality", if (is.na(state$quality$avg)) "Not scored" else paste0(state$quality$avg, "%"), status = quality_status, detail = paste(state$quality$warnings, "warnings")),
        ui_status_tile("Workflow", paste(sum(state$workflow$artifact_count > 0L), "/", nrow(state$workflow)), status = if (sum(state$workflow$artifact_count > 0L) > 0L) "success" else "neutral", detail = "stages with evidence"),
        ui_status_tile("Async Jobs", paste(state$async$running, "running"), status = if (state$async$failed > 0L) "warning" else if (state$async$running > 0L) "info" else "neutral", detail = paste(state$async$total, "tracked")),
        ui_status_tile("GenAI Jobs", paste(sum((state$genai_jobs$status %||% character()) %in% c("queued", "starting", "running", "cancel_requested", "cancelling")), "running"), status = if (any((state$genai_jobs$status %||% character()) %in% c("failed", "timed_out", "orphaned"))) "warning" else if (nrow(state$genai_jobs)) "info" else "neutral", detail = paste(nrow(state$genai_jobs), "tracked")),
        ui_status_tile("Improvement Ledger", paste(state$improvement$open_items[[1]] %||% 0L, "open"), status = if ((state$improvement$critical_open[[1]] %||% 0L) > 0L) "error" else if ((state$improvement$awaiting_user[[1]] %||% 0L) > 0L) "warning" else if ((state$improvement$open_items[[1]] %||% 0L) > 0L) "info" else "success", detail = paste(state$improvement$awaiting_user[[1]] %||% 0L, "awaiting user")),
        ui_status_tile("Remediation Plans", paste(state$remediation$active_plans[[1]] %||% 0L, "active"), status = if ((state$remediation$failed_plans[[1]] %||% 0L) > 0L) "error" else if (((state$remediation$awaiting_input[[1]] %||% 0L) + (state$remediation$awaiting_approval[[1]] %||% 0L)) > 0L) "warning" else if ((state$remediation$active_plans[[1]] %||% 0L) > 0L) "info" else "success", detail = paste((state$remediation$awaiting_input[[1]] %||% 0L) + (state$remediation$awaiting_approval[[1]] %||% 0L), "waiting")),
        ui_status_tile("Feature Experiments", paste(state$feature_experiments$experiments[[1]] %||% 0L, "experiments"), status = if ((state$feature_experiments$failed_executions[[1]] %||% 0L) > 0L) "error" else if (((state$feature_experiments$awaiting_review[[1]] %||% 0L) + (state$feature_experiments$approved_proposals[[1]] %||% 0L)) > 0L) "warning" else if ((state$feature_experiments$experiments[[1]] %||% 0L) > 0L) "info" else "neutral", detail = paste(state$feature_experiments$awaiting_review[[1]] %||% 0L, "awaiting review")),
        ui_status_tile("Analytical Campaigns", paste(state$campaigns$total_campaigns[[1]] %||% 0L, "campaigns"), status = if ((state$campaigns$knowledge_conflicts[[1]] %||% 0L) > 0L || (state$campaigns$blocked_campaigns[[1]] %||% 0L) > 0L) "error" else if (((state$campaigns$low_utility_guidance[[1]] %||% 0L) + (state$campaigns$knowledge_weakened[[1]] %||% 0L) + (state$campaigns$knowledge_superseded[[1]] %||% 0L) + (state$campaigns$knowledge_uncertain[[1]] %||% 0L) + (state$campaigns$awaiting_approval[[1]] %||% 0L) + (state$campaigns$awaiting_adoption[[1]] %||% 0L)) > 0L) "warning" else if ((state$campaigns$active_campaigns[[1]] %||% 0L) > 0L) "info" else if ((state$campaigns$completed_campaigns[[1]] %||% 0L) > 0L) "success" else "neutral", detail = paste(ui_status_label(state$campaigns$closure_recommendation[[1]] %||% state$campaigns$latest_status[[1]] %||% "none"), "-", state$campaigns$high_value_guidance[[1]] %||% 0L, "useful,", state$campaigns$low_utility_guidance[[1]] %||% 0L, "low-utility,", state$campaigns$knowledge_conflicts[[1]] %||% 0L, "conflicts")),
        ui_status_tile("Decision Memory", paste(state$decisions$decision_contexts[[1]] %||% 0L, "contexts"), status = if ((state$decisions$negative_reviews[[1]] %||% 0L) > 0L) "warning" else if ((state$decisions$validated_reviews[[1]] %||% 0L) > 0L) "success" else if ((state$decisions$decision_contexts[[1]] %||% 0L) > 0L) "info" else "neutral", detail = paste(state$decisions$reviews[[1]] %||% 0L, "review(s),", state$decisions$memory_artifacts[[1]] %||% 0L, "artifact(s)")),
        ui_status_tile("Decision Lifecycle", paste(state$semantic_decision$contexts[[1]] %||% 0L, "contexts"), status = if ((state$semantic_decision$validation_errors[[1]] %||% 0L) > 0L) "error" else if (identical(state$semantic_decision$assessment_status[[1]] %||% "", "stale") || (state$semantic_decision$validation_warnings[[1]] %||% 0L) > 0L) "warning" else if (identical(state$semantic_decision$assessment_status[[1]] %||% "", "current")) "success" else if ((state$semantic_decision$contexts[[1]] %||% 0L) > 0L) "info" else "neutral", detail = paste(ui_status_label(state$semantic_decision$assessment_status[[1]] %||% "none"), "-", state$semantic_decision$registered_artifacts[[1]] %||% 0L, "artifact(s)")),
        ui_status_tile("Decision Valuation", paste(state$decision_valuation$alternatives_valued[[1]] %||% 0L, "alternatives"), status = if (identical(state$decision_valuation$valuation_status[[1]] %||% "", "current") && (state$decision_valuation$missing_inputs[[1]] %||% 0L) == 0L) "success" else if ((state$decision_valuation$contexts[[1]] %||% 0L) > 0L || (state$decision_valuation$missing_inputs[[1]] %||% 0L) > 0L) "warning" else "neutral", detail = paste(ui_status_label(state$decision_valuation$primary_recommendation[[1]] %||% "not_run"), "-", state$decision_valuation$registered_artifacts[[1]] %||% 0L, "artifact(s)")),
        ui_status_tile("Decision Workflow", paste(state$decision_workflow$workflows[[1]] %||% 0L, "workflow(s)"), status = if (identical(state$decision_workflow$workflow_status[[1]] %||% "", "current") && (state$decision_workflow$implementation_deviations[[1]] %||% 0L) == 0L) "success" else if ((state$decision_workflow$workflows[[1]] %||% 0L) > 0L || (state$decision_workflow$open_conditions[[1]] %||% 0L) > 0L) "warning" else "neutral", detail = paste(ui_status_label(state$decision_workflow$readiness_state[[1]] %||% "not_run"), "-", state$decision_workflow$registered_artifacts[[1]] %||% 0L, "artifact(s)")),
        ui_status_tile("Semantic Workspace", paste(state$semantic_workspace$total_objects[[1]] %||% 0L, "objects"), status = if ((state$semantic_workspace$validation_errors[[1]] %||% 0L) > 0L) "error" else if ((state$semantic_workspace$validation_warnings[[1]] %||% 0L) > 0L || (state$semantic_workspace$review_objects[[1]] %||% 0L) > 0L) "warning" else if ((state$semantic_workspace$total_objects[[1]] %||% 0L) > 0L) "success" else "neutral", detail = paste(state$semantic_workspace$relationships[[1]] %||% 0L, "relationship(s),", state$semantic_workspace$review_objects[[1]] %||% 0L, "review")),
        ui_status_tile("Reports", length(state$plans), status = if (length(state$plans)) "success" else "neutral", detail = "report plans"),
        ui_status_tile("Warnings", state$quality$warnings + state$quality$failures, status = if ((state$quality$warnings + state$quality$failures) > 0L) "warning" else "success", detail = "quality signals"),
        ui_status_tile("QA", qa_status, status = if (identical(qa_status, "healthy")) "success" else "warning", detail = "studio smoke")
      )
    })

    output$priority_summary <- renderUI({
      priority <- mission_control_priority_summary(mission_state()$alerts)
      ui_callout(priority$title, priority$message, status = priority$status)
    })

    output$system_status <- renderUI({
      ui_workflow_status(mission_state()$workflow, ns = session$ns)
    })

    output$alerts <- renderUI({
      alerts <- mission_state()$alerts
      tags$div(
        class = "aq-alert-queue",
        lapply(alerts, function(alert) {
          ui_alert_card(
            title = alert$title,
            message = alert$message,
            severity = alert$severity,
            source = alert$source
          )
        })
      )
    })

    output$decision_work_queue <- renderUI({
      actions <- tryCatch(
        decision_workflow_next_actions(ctx$semantic_decision_state(), ctx$decision_valuation_state(), ctx$decision_workflow_state()),
        error = function(e) data.table::data.table()
      )
      if (!nrow(actions)) return(ui_empty_state("No decision queue yet.", "Create a decision context to populate guided decision work."))
      first <- actions[1]
      tagList(
        ui_callout(
          paste("Next:", first$action[[1]]),
          first$why[[1]],
          status = if (isTRUE(first$required[[1]])) "warning" else "info"
        ),
        render_table(actions[1:min(.N, 6L), .(stage, action, required, authority_required)], engine = "html", searchable = FALSE, sortable = FALSE)
      )
    })

    output$genai_status <- renderUI({
      ui_genai_status_panel(ctx$genai_status(check_availability = FALSE), title = "GenAI Provider")
    })

    output$async_jobs <- renderUI({
      summary <- tryCatch(async_job_summary(), error = function(e) data.table::data.table())
      project <- tryCatch(ctx$current_project(), error = function(e) NULL)
      genai_jobs <- tryCatch(genai_job_summary(project), error = function(e) data.table::data.table())
      if (!nrow(summary)) {
        if (!nrow(genai_jobs)) {
          return(ui_empty_state("No async jobs yet.", "Long-running work will appear here when submitted."))
        }
        latest_genai <- genai_jobs[order(created_at, decreasing = TRUE)][1:min(.N, 4L)]
        return(tags$div(
          class = "aq-async-job-list",
          lapply(seq_len(nrow(latest_genai)), function(i) {
            row <- latest_genai[i]
            status <- row$status[[1]] %||% "neutral"
            status_group <- if (status %in% c("failed", "timed_out", "cancelled", "orphaned")) "error" else if (status %in% c("queued", "starting", "running", "cancel_requested", "cancelling")) "info" else "success"
            tags$div(
              class = paste("aq-async-job-row", paste0("aq-async-job-row-", status_group)),
              tags$div(tags$strong(row$result_type[[1]] %||% row$job_id[[1]]), tags$span(row$progress_message[[1]] %||% "")),
              ui_status_badge(status, status_group)
            )
          })
        ))
      }
      latest <- summary[order(submitted_at, decreasing = TRUE)][1:min(.N, 4L)]
      tags$div(
        class = "aq-async-job-list",
        lapply(seq_len(nrow(latest)), function(i) {
          row <- latest[i]
          status <- row$status[[1]] %||% "neutral"
          status_group <- if (status %in% c("failed", "timed_out", "cancelled", "unavailable")) "error" else if (status %in% c("queued", "running")) "info" else "success"
          tags$div(
            class = paste("aq-async-job-row", paste0("aq-async-job-row-", status_group)),
            tags$div(
              tags$strong(row$job_type[[1]] %||% row$job_id[[1]]),
              tags$span(row$function_name[[1]] %||% "")
            ),
            tags$div(
              ui_status_badge(status, status = status_group),
              tags$span(class = "aq-muted", paste0(round(row$elapsed_seconds[[1]] %||% 0, 1), "s"))
            )
          )
        })
      )
    })

    output$genai_result <- renderUI({
      result <- ctx$genai_last_result()
      if (is.null(result)) {
        return(ui_empty_state("No GenAI explanation requested.", "Use Explain Alerts or Suggest Next Action for read-only assistance."))
      }
      tags$div(
        ui_status_badge(result$status, status = if (identical(result$status, "success")) "success" else if (identical(result$status, "error")) "error" else "warning"),
        tags$pre(class = "aq-genai-output", result$value$text %||% service_result_message(result))
      )
    })

    output$timeline <- renderUI({
      ui_timeline(mission_state()$timeline)
    })

    observeEvent(input$open_artifacts, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Artifact Studio")
    }, ignoreInit = TRUE)

    observeEvent(input$open_modules, {
      if (!is.null(ctx$navigate_to)) ctx$navigate_to("Analysis Modules")
    }, ignoreInit = TRUE)

    observeEvent(input$explain_alerts, {
      result <- genai_explain_alerts(mission_state()$alerts, config = ctx$genai_config())
      ctx$genai_last_result(result)
    }, ignoreInit = TRUE)

    observeEvent(input$suggest_next_action, {
      result <- genai_suggest_next_action(ctx, config = ctx$genai_config())
      ctx$genai_last_result(result)
    }, ignoreInit = TRUE)

    lapply(workflow_stage_registry(), function(stage) {
      stage_id <- stage$stage_id
      input_id <- paste0("mission_open_", stage_id)
      observeEvent(input[[input_id]], {
        target_page <- stage$page %||% NA_character_
        if (!is.na(target_page) && nzchar(target_page)) {
          if (!is.null(ctx$navigate_to)) ctx$navigate_to(target_page)
        }
      }, ignoreInit = TRUE)
    })
  })
}

qa_mission_control <- function() {
  page <- if (file.exists(file.path("R", "page_mission_control.R"))) {
    paste(readLines(file.path("R", "page_mission_control.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  app_ui <- if (file.exists(file.path("R", "app_ui.R"))) {
    paste(readLines(file.path("R", "app_ui.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  app <- if (file.exists("app.R")) paste(readLines("app.R", warn = FALSE), collapse = "\n") else ""
  components <- if (file.exists(file.path("R", "ui_components.R"))) {
    paste(readLines(file.path("R", "ui_components.R"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  css <- if (file.exists(file.path("www", "app.css"))) {
    paste(readLines(file.path("www", "app.css"), warn = FALSE), collapse = "\n")
  } else {
    ""
  }
  docs <- paste(
    if (file.exists(file.path("docs", "ui_ux_architecture.md"))) readLines(file.path("docs", "ui_ux_architecture.md"), warn = FALSE) else character(),
    if (file.exists(file.path("docs", "roadmap", "ux_roadmap.md"))) readLines(file.path("docs", "roadmap", "ux_roadmap.md"), warn = FALSE) else character(),
    collapse = "\n"
  )
  has <- function(text, patterns) all(vapply(patterns, grepl, logical(1), x = text, fixed = TRUE))
  draft_alerts <- mission_control_alerts(
    artifacts = list(create_artifact("qa_artifact", "diagnostic", "QA Artifact", "qa")),
    collector = data.table::data.table(artifact_count = 1L, manifest_status = "ready"),
    quality = list(avg = 100, warnings = 0L, failures = 0L),
    workflow = data.table::data.table(status = "implemented", artifact_count = 1L, label = "Explore Data"),
    ai_drafts = data.table::data.table(
      drafts_generated = 2L, drafts_confirmed = 1L, drafts_persisted = 1L,
      drafts_rejected = 0L, drafts_undone = 0L, drafts_archived = 0L,
      validation_failures = 1L, confirmation_failures = 0L, runtime_failures = 0L,
      handler_failures = 0L, citation_failures = 0L, undo_available = 1L,
      archive_available = 1L
    )
  )
  mutation_alerts <- mission_control_alerts(
    artifacts = list(create_artifact("qa_artifact", "diagnostic", "QA Artifact", "qa")),
    collector = data.table::data.table(artifact_count = 1L, manifest_status = "ready"),
    quality = list(avg = 100, warnings = 0L, failures = 0L),
    workflow = data.table::data.table(status = "implemented", artifact_count = 1L, label = "Explore Data"),
    mutations = data.table::data.table(
      mutations = 2L, pending = 1L, persisted = 1L, rejected = 0L, archived = 0L,
      undone = 0L, expired = 0L, superseded = 0L, high_or_critical = 1L,
      validation_failures = 1L, undo_available = 1L, archive_available = 1L
    )
  )

  data.table::data.table(
    check = c(
      "mission_control_page",
      "app_registration",
      "health_tiles",
      "workflow_status",
      "collector_summary",
      "ai_readiness",
      "alert_queue",
      "priority_summary",
      "timeline",
      "empty_state",
      "selection_behavior",
      "navigation_links",
      "reusable_components",
      "namespace_safe_helpers",
      "css_layout",
      "visual_hierarchy",
      "status_presentation",
      "alert_ordering",
      "timeline_rendering",
      "health_tile_consistency",
      "collector_presentation",
      "semantic_workspace_presentation",
      "semantic_decision_lifecycle_presentation",
      "decision_work_queue",
      "ai_draft_alerts",
      "mutation_governance_alerts",
      "async_job_status",
      "css_cache_busting",
      "documentation"
    ),
    status = c(
      if (grepl("page_mission_control_ui", page, fixed = TRUE)) "success" else "error",
      if (has(app, "page_mission_control.R") && has(app_ui, "page_mission_control_ui")) "success" else "error",
      if (has(page, c("ui_health_summary", "ui_status_tile", "Artifact Quality"))) "success" else "error",
      if (has(page, c("ui_workflow_status", "workflow_state_summary", "System Status"))) "success" else "error",
      if (has(page, c("project_collector_summary", "Collector", "manifest_status"))) "success" else "error",
      if (has(page, c("mission_control_ai_status", "AI Readiness"))) "success" else "error",
      if (has(page, c("mission_control_alerts", "Alerts / Open Decisions", "aq-alert-queue"))) "success" else "error",
      if (has(page, c("mission_control_priority_summary", "priority_summary", "Priority:"))) "success" else "error",
      if (has(page, c("mission_control_timeline", "Run Timeline", "ui_timeline"))) "success" else "error",
      if (has(components, c("No activity yet.", "Workflow status unavailable."))) "success" else "error",
      if (has(page, c("mission_open_", "observeEvent", "open_artifacts"))) "success" else "error",
      if (has(page, c("updateTabsetPanel", "Analysis Modules", "Artifact Studio"))) "success" else "error",
      if (has(components, c("ui_status_tile", "ui_health_summary", "ui_mission_state_banner", "ui_alert_card", "ui_timeline", "ui_workflow_status"))) "success" else "error",
      if (!grepl("[^:]\\bfifelse\\(", page, perl = TRUE)) "success" else "error",
      if (has(css, c(".aq-mission-control", ".aq-health-summary", ".aq-alert-card", ".aq-timeline", ".aq-workflow-status-board"))) "success" else "error",
      if (has(page, c("ui_mission_state_banner", "mission_status", "mission_title")) && has(css, c(".aq-mission-state-banner", ".aq-mission-state-pulse"))) "success" else "error",
      if (has(css, c(".aq-status-tile-success::before", ".aq-status-tile-warning::before", ".aq-status-tile-error::before"))) "success" else "error",
      if (has(page, c("mission_control_alerts", "critical", "attention", "quality warnings", "Decision Memory"))) "success" else "error",
      if (has(css, c(".aq-timeline-item::before", ".aq-timeline-item:not(:last-child)::after"))) "success" else "error",
      if (has(css, c(".aq-health-summary", "grid-column: 1 / -1", ".aq-status-tile-value"))) "success" else "error",
      if (has(page, c("Collector", "manifest_status", "collector_status", "state$counts$total"))) "success" else "error",
      if (has(page, c("semantic_workspace_summary", "Semantic Workspace", "Semantic Intelligence"))) "success" else "error",
      if (has(page, c("semantic_decision_summary", "Decision Lifecycle", "assessment_status", "Authored decision"))) "success" else "error",
      if (has(page, c("Decision Work Queue", "decision_workflow_next_actions", "output$decision_work_queue"))) "success" else "error",
      if (any(vapply(draft_alerts, function(x) identical(x$source, "AI Drafts"), logical(1)))) "success" else "error",
      if (any(vapply(mutation_alerts, function(x) identical(x$source, "Mutation Governance"), logical(1)))) "success" else "error",
      if (has(page, c("async_job_summary", "Async Jobs", "aq-async-job-list")) && has(css, c(".aq-async-job-list", ".aq-async-job-row"))) "success" else "error",
      if (has(app_ui, c("app.css?v=", "file.info(css_file)$mtime"))) "success" else "error",
      if (has(docs, c("Mission Control", "Operational awareness", "Alert philosophy", "Timeline"))) "success" else "error"
    ),
    message = c(
      "Mission Control page module exists.",
      "Mission Control is sourced and registered in the app shell.",
      "Project health tiles are present.",
      "Workflow/system status board is present.",
      "Collector status is surfaced.",
      "AI readiness is surfaced.",
      "Alert queue is present.",
      "Mission Control surfaces the top operational priority before detailed queues.",
      "Run timeline is present.",
      "Empty states are present.",
      "Selection/open behavior is wired.",
      "Navigation links target existing modes.",
      "Reusable Mission Control primitives exist.",
      "Mission Control helpers use namespace-safe data.table calls.",
      "Mission Control CSS selectors exist.",
      "Mission Control has a first-read mission state banner.",
      "Health and workflow statuses use state-bearing color rails.",
      "Alert generation preserves operational priority semantics.",
      "Timeline uses connected event markers.",
      "Health tiles share consistent sizing and hierarchy.",
      "Collector state is included in health and alert presentation.",
      "Authored semantic workspace health is included in Mission Control.",
      "Authored decision lifecycle assessment and artifact status are included in Mission Control.",
      "Mission Control exposes a bounded decision work queue.",
      "Mission Control reports confirmed, persisted, rejected, archived, undone, stale, and validation-failed AI draft lifecycle states.",
      "Mission Control reports pending, persisted, rejected, expired, blocked, high-risk, validation-failed, and undoable mutation states.",
      "Mission Control surfaces basic async job status.",
      "App CSS is cache-busted so Mission Control visual updates render after restart.",
      "Mission Control documentation is present."
    )
  )
}
