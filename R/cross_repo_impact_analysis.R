cross_repo_capability_ownership <- function(manifest = cross_repo_read_manifest()) {
  rows <- list(
    list(
      capability = "workflow_orchestration",
      owner = "AnalyticsShinyApp",
      consumers = "AnalyticsShinyApp",
      public_contract = "app pages, module registry, workflow registry",
      validation_contract = "qa_analysis_modules_integration(); qa_cross_system_invariants()",
      documentation_owner = "AnalyticsShinyApp",
      docs = "docs/workflow_architecture.md"
    ),
    list(
      capability = "artifact_model_and_collector",
      owner = "AnalyticsShinyApp",
      consumers = "AnalyticsShinyApp, AutoQuant adapters, Rodeo adapters",
      public_contract = "create_artifact(); Project Artifact Collector bundle contract",
      validation_contract = "qa_project_artifact_collector(); qa_artifact_quality_policy()",
      documentation_owner = "AnalyticsShinyApp",
      docs = "docs/project_artifact_collector_architecture.md"
    ),
    list(
      capability = "feature_transformations",
      owner = "Rodeo",
      consumers = "AnalyticsShinyApp",
      public_contract = "generate_rodeo_feature_engineering_artifacts(); transformation fit/apply contracts",
      validation_contract = "Rodeo::qa_rodeo_package(); qa_feature_preparation_integration()",
      documentation_owner = "Rodeo",
      docs = "Rodeo/README.md; docs/architecture/feature_experiment_loop.md"
    ),
    list(
      capability = "model_preparation",
      owner = "Rodeo",
      consumers = "AnalyticsShinyApp",
      public_contract = "generate_rodeo_model_prep_artifacts(); partition/fold contracts",
      validation_contract = "Rodeo::qa_rodeo_package(); qa_feature_preparation_integration()",
      documentation_owner = "Rodeo",
      docs = "Rodeo/README.md; docs/workflow_architecture.md"
    ),
    list(
      capability = "analytical_artifact_generation",
      owner = "AutoQuant",
      consumers = "AnalyticsShinyApp",
      public_contract = "generate_*_artifacts()",
      validation_contract = "AutoQuant::qa_autoquant_package(); qa_analysis_modules_integration()",
      documentation_owner = "AutoQuant",
      docs = "AutoQuant/README.md; docs/analysis_module_architecture.md"
    ),
    list(
      capability = "model_training_and_scoring",
      owner = "AutoQuant",
      consumers = "AnalyticsShinyApp",
      public_contract = "generate_catboost_builder_artifacts()",
      validation_contract = "AutoQuant::qa_autoquant_package(); qa_autoquant_catboost_builder_integration()",
      documentation_owner = "AutoQuant",
      docs = "docs/analysis_modules_status.md"
    ),
    list(
      capability = "visualization_rendering",
      owner = "AutoPlots",
      consumers = "AnalyticsShinyApp, AutoQuant",
      public_contract = "AutoPlots high-level plot functions and display helpers",
      validation_contract = "AutoPlots::qa_autoplots_package(); qa_screenshot_pipeline_reliability()",
      documentation_owner = "AutoPlots",
      docs = "AutoPlots/README.md; docs/ui_ux_architecture.md"
    ),
    list(
      capability = "genai_action_layer",
      owner = "AnalyticsShinyApp",
      consumers = "AnalyticsShinyApp",
      public_contract = "registered GenAI action descriptors and governed action execution",
      validation_contract = "qa_genai_service_contract(); qa_cross_system_invariants()",
      documentation_owner = "AnalyticsShinyApp",
      docs = "docs/genai_service_architecture.md"
    ),
    list(
      capability = "campaigns_and_remediation",
      owner = "AnalyticsShinyApp",
      consumers = "AnalyticsShinyApp",
      public_contract = "campaign registry, remediation plan state machine, improvement ledger",
      validation_contract = "qa_analytical_improvement_campaign(); qa_remediation_plans(); qa_improvement_ledger()",
      documentation_owner = "AnalyticsShinyApp",
      docs = "docs/architecture/analytical_improvement_campaign.md"
    ),
    list(
      capability = "cross_repo_validation",
      owner = "AnalyticsShinyApp",
      consumers = "AnalyticsShinyApp, Rodeo, AutoQuant, AutoPlots",
      public_contract = "config/cross_repo_workspace.json; cross_repo_validate()",
      validation_contract = "qa_cross_repo_validation_orchestrator()",
      documentation_owner = "AnalyticsShinyApp",
      docs = "docs/cross_repository_agent_guide.md; docs/package_qa_surface.md"
    )
  )

  data.table::rbindlist(lapply(rows, as.data.frame), fill = TRUE)
}

cross_repo_dependency_graph <- function(
  manifest = cross_repo_read_manifest(),
  discovery = cross_repo_discover_repositories(manifest, workspace_root = getwd())
) {
  repo_rows <- lapply(discovery, function(repo) {
    data.frame(
      from = repo$name,
      to = repo$name,
      relationship = "repository",
      contract_id = NA_character_,
      detail = repo$role %||% "",
      source = "manifest",
      stringsAsFactors = FALSE
    )
  })

  contract_rows <- lapply(manifest$contracts %||% list(), function(contract) {
    data.frame(
      from = contract$consumer %||% NA_character_,
      to = contract$provider %||% NA_character_,
      relationship = "contract_dependency",
      contract_id = contract$contract_id %||% NA_character_,
      detail = paste(unlist(contract$required_exports %||% list()), collapse = ", "),
      source = "manifest_contracts",
      stringsAsFactors = FALSE
    )
  })

  package_rows <- lapply(discovery, function(repo) {
    imports <- paste(repo$package_metadata$imports %||% "", repo$package_metadata$depends %||% "")
    packages <- vapply(discovery, function(x) x$package %||% x$name, character(1))
    local_deps <- names(packages)[packages %in% unique(unlist(regmatches(imports, gregexpr("[A-Za-z][A-Za-z0-9.]*", imports))))]
    local_deps <- setdiff(local_deps, repo$name)
    if (!length(local_deps)) {
      return(NULL)
    }
    data.frame(
      from = repo$name,
      to = local_deps,
      relationship = "package_dependency",
      contract_id = NA_character_,
      detail = "DESCRIPTION Imports/Depends",
      source = "package_metadata",
      stringsAsFactors = FALSE
    )
  })

  capability <- cross_repo_capability_ownership(manifest)
  capability_rows <- data.frame(
    from = capability$consumers,
    to = capability$owner,
    relationship = "capability_ownership",
    contract_id = capability$capability,
    detail = capability$public_contract,
    source = "capability_inventory",
    stringsAsFactors = FALSE
  )

  data.table::rbindlist(c(repo_rows, contract_rows, package_rows, list(capability_rows)), fill = TRUE)
}

cross_repo_contract_consumer_analysis <- function(manifest = cross_repo_read_manifest()) {
  contracts <- manifest$contracts %||% list()
  if (!length(contracts)) {
    return(data.frame())
  }
  rows <- lapply(contracts, function(contract) {
    required_exports <- unlist(contract$required_exports %||% list(), use.names = FALSE)
    data.frame(
      contract_id = contract$contract_id %||% NA_character_,
      provider = contract$provider %||% NA_character_,
      consumer = contract$consumer %||% NA_character_,
      required_exports = paste(required_exports, collapse = ", "),
      compatibility = "installed namespace exports must include required_exports",
      version_assumptions = "package version captured during fresh validation",
      migration_required_if_changed = if (length(required_exports)) "yes, update consumer adapter and manifest contract" else "no",
      impact = if (length(required_exports) >= 5L) "high" else "medium",
      stringsAsFactors = FALSE
    )
  })
  data.table::rbindlist(rows, fill = TRUE)
}

cross_repo_change_categories <- function() {
  data.frame(
    category = c(
      "documentation_only",
      "internal_implementation",
      "public_api_additive",
      "public_api_breaking",
      "contract_update",
      "workflow_update",
      "operator_change",
      "artifact_change",
      "campaign_behavior",
      "ui_only",
      "qa_only"
    ),
    validation_scope = c(
      "source; targeted docs QA; git diff check",
      "targeted owner QA; package load if package-owned",
      "metadata regeneration; package build/install; installed QA; consumer contract validation",
      "metadata regeneration; package build/install; installed QA; consumer migration; full cross-repo validation",
      "manifest contract validation; upstream package QA; downstream adapter QA; full cross-repo validation",
      "workflow QA; analysis module integration; cross-system invariants",
      "owner package QA; adapter QA; artifact QA when outputs change",
      "artifact model QA; collector QA; report/render QA; package/app QA as applicable",
      "campaign QA; remediation QA; ledger QA; Mission Control visibility",
      "ui consistency QA; source app; affected page QA",
      "targeted QA; orchestrator QA when QA surface changes"
    ),
    default_blast_radius = c(
      "local",
      "repository",
      "cross-package",
      "cross-system",
      "cross-system",
      "cross-system",
      "cross-package",
      "cross-system",
      "campaign",
      "local",
      "repository"
    ),
    stringsAsFactors = FALSE
  )
}

cross_repo_classify_change <- function(change) {
  if (is.character(change)) {
    change <- list(summary = change)
  }
  summary <- tolower(change$summary %||% "")
  files <- tolower(paste(unlist(change$files %||% character()), collapse = " "))
  explicit <- change$category %||% NA_character_
  if (!is.na(explicit) && nzchar(explicit)) {
    return(explicit)
  }
  text <- paste(summary, files)
  if (grepl("namespace|export\\(|public api|breaking|remove export", text)) {
    return(if (grepl("breaking|remove export|rename|delete", text)) "public_api_breaking" else "public_api_additive")
  }
  if (grepl("cross_repo_workspace|contract|required_exports|manifest", text)) {
    return("contract_update")
  }
  if (grepl("campaign|remediation|improvement ledger|audit ledger", text)) {
    return("campaign_behavior")
  }
  if (grepl("workflow|module registry|analysis modules|mission control", text)) {
    return("workflow_update")
  }
  if (grepl("artifact|collector|render target|table artifact|quality policy", text)) {
    return("artifact_change")
  }
  if (grepl("\\.md|docs/|readme|documentation|book/", text) && !grepl("\\.r|namespace|config/", text)) {
    return("documentation_only")
  }
  if (grepl("qa_|test|validation", text)) {
    return("qa_only")
  }
  if (grepl("ui|css|page_|www/|theme", text)) {
    return("ui_only")
  }
  "internal_implementation"
}

cross_repo_infer_affected_repos <- function(change, capability_map = cross_repo_capability_ownership()) {
  explicit <- unique(unlist(change$repositories %||% character(), use.names = FALSE))
  if (length(explicit)) {
    return(explicit)
  }
  text <- tolower(paste(change$summary %||% "", paste(unlist(change$files %||% character()), collapse = " ")))
  repos <- character()
  repo_names <- c("AnalyticsShinyApp", "Rodeo", "AutoQuant", "AutoPlots")
  for (repo in repo_names) {
    if (grepl(tolower(repo), text, fixed = TRUE)) repos <- c(repos, repo)
  }
  for (i in seq_len(nrow(capability_map))) {
    if (grepl(gsub("_", " ", tolower(capability_map$capability[[i]])), text, fixed = TRUE)) {
      repos <- c(repos, capability_map$owner[[i]])
    }
  }
  if (!length(repos)) "AnalyticsShinyApp" else unique(repos)
}

cross_repo_validation_plan <- function(category, affected_repos, manifest = cross_repo_read_manifest()) {
  categories <- cross_repo_change_categories()
  category_row <- categories[categories$category == category, , drop = FALSE]
  if (!nrow(category_row)) {
    category_row <- categories[categories$category == "internal_implementation", , drop = FALSE]
  }
  package_repos <- intersect(affected_repos, c("Rodeo", "AutoQuant", "AutoPlots"))
  rebuild_required <- category %in% c("public_api_additive", "public_api_breaking", "contract_update", "operator_change") ||
    length(package_repos) > 0L && !identical(category, "documentation_only")
  mode <- if (category %in% c("public_api_breaking", "contract_update", "campaign_behavior")) {
    "full"
  } else if (category %in% c("public_api_additive", "operator_change", "artifact_change", "workflow_update")) {
    "standard"
  } else {
    "fast"
  }
  qa <- c("source('app.R')", "git diff --check")
  if (length(package_repos)) {
    qa <- c(qa, paste0(package_repos, "::qa_", tolower(package_repos), "_package()"))
  }
  if (category %in% c("workflow_update", "artifact_change", "contract_update")) {
    qa <- c(qa, "qa_analysis_modules_integration()", "qa_cross_system_invariants()")
  }
  if (category %in% c("campaign_behavior")) {
    qa <- c(qa, "qa_analytical_improvement_campaign()", "qa_remediation_plans()", "qa_improvement_ledger()")
  }
  if (category %in% c("ui_only")) {
    qa <- c(qa, "qa_ui_consistency()")
  }
  qa <- c(qa, paste0("cross_repo_validate(mode = '", mode, "')"))
  data.frame(
    category = category,
    validation_scope = category_row$validation_scope[[1]],
    cross_repo_mode = mode,
    rebuild_required = rebuild_required,
    required_qa = paste(unique(qa), collapse = " -> "),
    stringsAsFactors = FALSE
  )
}

cross_repo_blast_radius <- function(category, affected_repos, affected_contracts = character()) {
  if (category %in% c("public_api_breaking", "contract_update") && length(affected_contracts)) {
    return("cross-system")
  }
  if (category %in% c("campaign_behavior")) {
    return("campaign")
  }
  if (length(intersect(affected_repos, c("Rodeo", "AutoQuant", "AutoPlots"))) && "AnalyticsShinyApp" %in% affected_repos) {
    return("cross-package")
  }
  if (length(affected_repos) > 1L) {
    return("cross-system")
  }
  categories <- cross_repo_change_categories()
  categories$default_blast_radius[match(category, categories$category)] %||% "repository"
}

cross_repo_impact_plan <- function(change, manifest = cross_repo_read_manifest(), workspace_root = getwd()) {
  if (is.character(change)) {
    change <- list(summary = change)
  }
  discovery <- cross_repo_discover_repositories(manifest, workspace_root = workspace_root)
  capability_map <- cross_repo_capability_ownership(manifest)
  contracts <- cross_repo_contract_consumer_analysis(manifest)
  category <- cross_repo_classify_change(change)
  affected_repos <- cross_repo_infer_affected_repos(change, capability_map)
  owned_capabilities <- capability_map[capability_map$owner %in% affected_repos, , drop = FALSE]
  affected_contracts <- contracts[contracts$provider %in% affected_repos | contracts$consumer %in% affected_repos, , drop = FALSE]
  if (category %in% c("contract_update", "public_api_breaking", "public_api_additive") && nrow(affected_contracts)) {
    affected_repos <- unique(c(affected_repos, affected_contracts$provider, affected_contracts$consumer))
    affected_repos <- affected_repos[nzchar(affected_repos)]
    owned_capabilities <- capability_map[capability_map$owner %in% affected_repos, , drop = FALSE]
    affected_contracts <- contracts[contracts$provider %in% affected_repos | contracts$consumer %in% affected_repos, , drop = FALSE]
  }
  validation <- cross_repo_validation_plan(category, affected_repos, manifest)
  install_order <- cross_repo_local_package_order(discovery)
  rebuilds <- intersect(install_order, affected_repos)
  downstream <- unique(affected_contracts$consumer %||% character())
  downstream <- downstream[nzchar(downstream) & !downstream %in% affected_repos]
  implementation_order <- unique(c(rebuilds, setdiff(affected_repos, rebuilds), downstream))
  blast_radius <- cross_repo_blast_radius(category, affected_repos, affected_contracts$contract_id %||% character())

  list(
    change_summary = change$summary %||% "",
    category = category,
    blast_radius = blast_radius,
    repositories_affected = affected_repos,
    capabilities_affected = owned_capabilities,
    contracts_affected = affected_contracts,
    validation = validation,
    implementation_order = implementation_order,
    package_rebuild_order = rebuilds,
    downstream_validation_repos = downstream,
    documentation_affected = unique(owned_capabilities$docs %||% character()),
    migration_guidance = if (nrow(affected_contracts) && category %in% c("public_api_breaking", "contract_update")) {
      "Update provider contract first, regenerate metadata, rebuild/install provider, update consumers, then run full cross-repo validation."
    } else if (nrow(affected_contracts)) {
      "Preserve existing exports where practical; run installed provider QA and consumer contract validation."
    } else {
      "No downstream migration required by the current manifest."
    },
    remaining_uncertainty = if (nrow(affected_contracts)) {
      "Static analysis identifies declared contracts only; runtime-only or undocumented dependencies may still exist."
    } else {
      "No declared cross-repo contract was affected."
    }
  )
}

cross_repo_impact_report <- function(plan) {
  capabilities <- plan$capabilities_affected
  contracts <- plan$contracts_affected
  c(
    "# Cross-Repository Impact Plan",
    "",
    paste("- Change:", plan$change_summary),
    paste("- Category:", plan$category),
    paste("- Blast radius:", plan$blast_radius),
    paste("- Repositories affected:", paste(plan$repositories_affected, collapse = ", ")),
    paste("- Implementation order:", paste(plan$implementation_order, collapse = " -> ")),
    paste("- Package rebuild order:", if (length(plan$package_rebuild_order)) paste(plan$package_rebuild_order, collapse = " -> ") else "none"),
    paste("- Validation:", plan$validation$required_qa[[1]]),
    paste("- Migration:", plan$migration_guidance),
    paste("- Remaining uncertainty:", plan$remaining_uncertainty),
    "",
    "## Capabilities Affected",
    if (nrow(capabilities)) paste(sprintf("- `%s` owned by `%s`", capabilities$capability, capabilities$owner), collapse = "\n") else "- None identified.",
    "",
    "## Contracts Affected",
    if (nrow(contracts)) paste(sprintf("- `%s`: `%s` -> `%s`", contracts$contract_id, contracts$provider, contracts$consumer), collapse = "\n") else "- None identified."
  )
}

qa_cross_repo_impact_analysis <- function() {
  manifest <- cross_repo_read_manifest()
  graph <- cross_repo_dependency_graph(manifest)
  ownership <- cross_repo_capability_ownership(manifest)
  contracts <- cross_repo_contract_consumer_analysis(manifest)
  categories <- cross_repo_change_categories()
  api_plan <- cross_repo_impact_plan(list(
    summary = "Add exported AutoPlots composite plotting API and update AnalyticsShinyApp rendering consumers.",
    repositories = c("AutoPlots", "AnalyticsShinyApp"),
    category = "public_api_additive"
  ))
  docs_plan <- cross_repo_impact_plan(list(
    summary = "Update docs for package QA surface.",
    files = c("docs/package_qa_surface.md")
  ))
  contract_plan <- cross_repo_impact_plan(list(
    summary = "Change AutoQuant artifact generator contract in cross_repo_workspace manifest.",
    repositories = c("AutoQuant", "AnalyticsShinyApp"),
    category = "contract_update"
  ))
  report <- cross_repo_impact_report(contract_plan)

  checks <- data.frame(
    check = c(
      "dependency_graph_contains_contract_edges",
      "ownership_map_contains_core_repos",
      "ownership_map_contains_package_qa_contracts",
      "contract_consumer_analysis_covers_manifest",
      "change_categories_cover_required_cases",
      "documentation_change_classified",
      "public_api_change_requires_rebuild",
      "contract_change_full_validation",
      "contract_change_includes_provider_and_consumer",
      "blast_radius_cross_system_for_contract",
      "implementation_order_respects_package_owner",
      "migration_guidance_present",
      "planning_report_generated"
    ),
    status = c(
      if (any(graph$relationship == "contract_dependency")) "success" else "error",
      if (all(c("AnalyticsShinyApp", "Rodeo", "AutoQuant", "AutoPlots") %in% unique(ownership$owner))) "success" else "error",
      if (all(grepl("qa_.*_package", ownership$validation_contract[ownership$owner %in% c("Rodeo", "AutoQuant", "AutoPlots")]))) "success" else "error",
      if (nrow(contracts) == length(manifest$contracts %||% list())) "success" else "error",
      if (all(c("documentation_only", "public_api_additive", "public_api_breaking", "contract_update", "ui_only", "qa_only") %in% categories$category)) "success" else "error",
      if (identical(docs_plan$category, "documentation_only")) "success" else "error",
      if (isTRUE(api_plan$validation$rebuild_required[[1]])) "success" else "error",
      if (identical(contract_plan$validation$cross_repo_mode[[1]], "full")) "success" else "error",
      if (all(c("AutoQuant", "AnalyticsShinyApp") %in% contract_plan$repositories_affected)) "success" else "error",
      if (identical(contract_plan$blast_radius, "cross-system")) "success" else "error",
      if ("AutoQuant" %in% contract_plan$implementation_order) "success" else "error",
      if (nzchar(contract_plan$migration_guidance)) "success" else "error",
      if (length(report) > 5L && any(grepl("Contracts Affected", report, fixed = TRUE))) "success" else "error"
    ),
    message = c(
      paste(sum(graph$relationship == "contract_dependency"), "contract edge(s) found."),
      paste(sort(unique(ownership$owner)), collapse = ", "),
      paste(ownership$validation_contract[ownership$owner %in% c("Rodeo", "AutoQuant", "AutoPlots")], collapse = " | "),
      paste(nrow(contracts), "contract(s) analyzed."),
      paste(categories$category, collapse = ", "),
      docs_plan$category,
      api_plan$validation$required_qa[[1]],
      contract_plan$validation$required_qa[[1]],
      paste(contract_plan$repositories_affected, collapse = ", "),
      contract_plan$blast_radius,
      paste(contract_plan$implementation_order, collapse = " -> "),
      contract_plan$migration_guidance,
      paste(report[1:min(length(report), 4L)], collapse = " | ")
    ),
    stringsAsFactors = FALSE
  )
  checks
}
