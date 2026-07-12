crv_null_coalesce <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

cross_repo_manifest_path <- function(root = ".") {
  file.path(root, "config", "cross_repo_workspace.json")
}

cross_repo_read_manifest <- function(path = cross_repo_manifest_path()) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package jsonlite is required to read the cross-repo workspace manifest.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop(paste("Cross-repo workspace manifest not found:", path), call. = FALSE)
  }
  jsonlite::read_json(path, simplifyVector = FALSE)
}

cross_repo_validate_manifest <- function(manifest) {
  issues <- character()
  if (is.null(manifest$workspace_version)) {
    issues <- c(issues, "workspace_version is missing")
  }
  repos <- manifest$repositories %||% list()
  if (!length(repos)) {
    issues <- c(issues, "repositories is empty")
  }
  repo_names <- vapply(repos, function(repo) repo$name %||% "", character(1))
  if (any(!nzchar(repo_names))) {
    issues <- c(issues, "one or more repositories are missing name")
  }
  if (any(duplicated(repo_names))) {
    issues <- c(issues, paste("duplicate repository names:", paste(unique(repo_names[duplicated(repo_names)]), collapse = ", ")))
  }
  for (repo in repos) {
    if (is.null(repo$relative_path) && is.null(repo$env_var)) {
      issues <- c(issues, paste("repository has no path resolver:", repo$name %||% "<unnamed>"))
    }
  }
  contracts <- manifest$contracts %||% list()
  contract_ids <- vapply(contracts, function(contract) contract$contract_id %||% "", character(1))
  if (any(duplicated(contract_ids[nzchar(contract_ids)]))) {
    issues <- c(issues, paste("duplicate contract ids:", paste(unique(contract_ids[duplicated(contract_ids)]), collapse = ", ")))
  }

  list(
    status = if (length(issues)) "error" else "success",
    issues = issues
  )
}

cross_repo_normalize_path <- function(path) {
  if (is.null(path) || !length(path)) {
    return(NA_character_)
  }
  out <- as.character(path)
  empty <- !nzchar(out)
  out[!empty] <- normalizePath(out[!empty], winslash = "/", mustWork = FALSE)
  out[empty] <- NA_character_
  out
}

cross_repo_resolve_path <- function(repo, workspace_root = getwd()) {
  tried <- character()
  env_var <- repo$env_var %||% NA_character_
  if (!is.na(env_var) && nzchar(env_var)) {
    env_path <- Sys.getenv(env_var, unset = NA_character_)
    if (!is.na(env_path) && nzchar(env_path)) {
      tried <- c(tried, paste0(env_var, "=", env_path))
      if (dir.exists(env_path)) {
        return(list(path = cross_repo_normalize_path(env_path), source = "environment_variable", tried = tried))
      }
    }
  }

  relative_path <- repo$relative_path %||% NA_character_
  if (!is.na(relative_path) && nzchar(relative_path)) {
    manifest_path <- file.path(workspace_root, relative_path)
    tried <- c(tried, manifest_path)
    if (dir.exists(manifest_path)) {
      return(list(path = cross_repo_normalize_path(manifest_path), source = "manifest_relative_path", tried = tried))
    }
  }

  sibling_path <- file.path(dirname(cross_repo_normalize_path(workspace_root)), repo$name %||% "")
  tried <- c(tried, sibling_path)
  if (dir.exists(sibling_path)) {
    return(list(path = cross_repo_normalize_path(sibling_path), source = "sibling_directory", tried = tried))
  }

  list(path = NA_character_, source = "not_found", tried = tried)
}

cross_repo_git_metadata <- function(path) {
  if (is.na(path) || !dir.exists(path)) {
    return(list(available = FALSE, error = "repository path is unavailable"))
  }
  git <- Sys.which("git")
  if (!nzchar(git)) {
    return(list(available = FALSE, error = "git executable was not found on PATH"))
  }
  run_git <- function(args) {
    tryCatch(
      paste(system2(git, c("-C", path, args), stdout = TRUE, stderr = TRUE), collapse = "\n"),
      error = function(e) paste("ERROR:", conditionMessage(e))
    )
  }
  status <- run_git(c("status", "--porcelain"))
  list(
    available = TRUE,
    branch = run_git(c("rev-parse", "--abbrev-ref", "HEAD")),
    commit = run_git(c("rev-parse", "--short", "HEAD")),
    dirty = nzchar(status),
    changed_files = if (nzchar(status)) length(strsplit(status, "\n", fixed = TRUE)[[1]]) else 0L,
    status_excerpt = substr(status, 1L, 1000L)
  )
}

cross_repo_package_metadata <- function(path) {
  desc_path <- file.path(path, "DESCRIPTION")
  if (is.na(path) || !file.exists(desc_path)) {
    return(list(available = FALSE, package = NA_character_, version = NA_character_))
  }
  desc <- read.dcf(desc_path)
  desc_value <- function(field) {
    if (field %in% colnames(desc)) unname(desc[1, field]) else NA_character_
  }
  list(
    available = TRUE,
    package = desc_value("Package"),
    version = desc_value("Version"),
    needs_compilation = desc_value("NeedsCompilation"),
    imports = desc_value("Imports"),
    depends = desc_value("Depends")
  )
}

cross_repo_discover_repositories <- function(manifest = cross_repo_read_manifest(), workspace_root = getwd()) {
  repos <- manifest$repositories %||% list()
  rows <- lapply(repos, function(repo) {
    resolved <- cross_repo_resolve_path(repo, workspace_root = workspace_root)
    package_metadata <- if (!is.na(resolved$path)) cross_repo_package_metadata(resolved$path) else list(available = FALSE)
    list(
      name = repo$name,
      package = repo$package %||% package_metadata$package %||% repo$name,
      required = isTRUE(repo$required),
      is_package = isTRUE(repo$is_package),
      role = repo$role %||% "",
      path = resolved$path,
      path_source = resolved$source,
      path_tried = resolved$tried,
      exists = !is.na(resolved$path) && dir.exists(resolved$path),
      docs = repo$docs %||% list(),
      validation = repo$validation %||% list(),
      expected_exports = repo$expected_exports %||% list(),
      package_metadata = package_metadata,
      git = if (!is.na(resolved$path)) cross_repo_git_metadata(resolved$path) else list(available = FALSE)
    )
  })
  names(rows) <- vapply(rows, function(row) row$name, character(1))
  rows
}

cross_repo_issue_class <- function(status, message = "", required = FALSE) {
  text <- tolower(paste(status, message, collapse = " "))
  if (grepl("not_found|unavailable|missing repo|not installed|there is no package|cannot open|no such file|package load|dependency", text)) {
    return("environment")
  }
  if (grepl("missing export|contract|function unavailable|qa function", text)) {
    return("contract")
  }
  if (grepl("error|failed|failure|stop", text)) {
    return("product")
  }
  if (required) "product" else "not_applicable"
}

cross_repo_rscript <- function() {
  candidates <- c(
    Sys.which("Rscript"),
    "C:/Program Files/R/R-4.5.2/bin/Rscript.exe",
    "C:/Program Files/R/R-4.5.1/bin/Rscript.exe"
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates)) {
    return(cross_repo_normalize_path(candidates[[1]]))
  }
  r_dirs <- list.dirs("C:/Program Files/R", full.names = TRUE, recursive = FALSE)
  rscript_paths <- file.path(sort(r_dirs, decreasing = TRUE), "bin", "Rscript.exe")
  rscript_paths <- rscript_paths[file.exists(rscript_paths)]
  if (length(rscript_paths)) cross_repo_normalize_path(rscript_paths[[1]]) else NA_character_
}

cross_repo_r_quote <- function(x) {
  paste0('"', gsub('"', '\\"', cross_repo_normalize_path(x), fixed = TRUE), '"')
}

cross_repo_run_r <- function(repo, expression, timeout = 180, temp_lib = NULL) {
  rscript <- cross_repo_rscript()
  if (is.na(rscript) || !file.exists(rscript)) {
    return(list(status = "skipped", message = "Rscript executable was not found.", output = character(), elapsed = NA_real_))
  }
  if (!isTRUE(repo$exists)) {
    return(list(status = "skipped", message = paste("Repository path is unavailable:", repo$name), output = character(), elapsed = NA_real_))
  }
  setup <- sprintf("setwd(%s);", cross_repo_r_quote(repo$path))
  if (!is.null(temp_lib)) {
    setup <- paste0(
      sprintf("dir.create(%s, recursive = TRUE, showWarnings = FALSE);", cross_repo_r_quote(temp_lib)),
      sprintf(".libPaths(c(%s, .libPaths()));", cross_repo_r_quote(temp_lib)),
      setup
    )
  }
  script <- paste(setup, expression)
  script_path <- tempfile("cross_repo_expr_", fileext = ".R")
  writeLines(script, script_path, useBytes = TRUE)
  started <- Sys.time()
  output <- tryCatch(
    system2(rscript, c("--vanilla", script_path), stdout = TRUE, stderr = TRUE, timeout = timeout),
    error = function(e) structure(conditionMessage(e), class = "cross_repo_r_error")
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(output, "cross_repo_r_error")) {
    return(list(status = "error", message = as.character(output), output = as.character(output), elapsed = elapsed))
  }
  exit_status <- attr(output, "status") %||% 0L
  status <- if (identical(as.integer(exit_status), 0L)) "success" else "error"
  list(
    status = status,
    message = if (identical(status, "success")) "R expression completed." else paste("R expression failed with exit status", exit_status),
    output = as.character(output),
    elapsed = elapsed
  )
}

cross_repo_package_expression <- function(repo, body) {
  pkg <- repo$package %||% repo$name
  sprintf(
    "pkg <- %s; if (!requireNamespace(pkg, quietly = TRUE)) stop('package not installed: ', pkg); suppressPackageStartupMessages(library(pkg, character.only = TRUE)); %s",
    deparse(pkg),
    body
  )
}

cross_repo_run_suite <- function(repo, suite, mode, temp_lib_root = NULL, install_packages = FALSE, validation_lib = NULL) {
  required <- isTRUE(suite$required)
  timeout <- as.integer(suite$timeout_seconds %||% 180L)
  suite_type <- suite$type %||% "r_expression"
  temp_lib <- NULL
  message <- NULL
  expression <- NULL

  if (!isTRUE(repo$exists)) {
    message <- paste("Repository is unavailable:", repo$name)
    return(data.frame(
      repo = repo$name,
      mode = mode,
      suite_id = suite$id %||% suite_type,
      suite_type = suite_type,
      status = if (required) "error" else "skipped",
      classification = "environment",
      required = required,
      message = message,
      elapsed_seconds = NA_real_,
      output_excerpt = "",
      stringsAsFactors = FALSE
    ))
  }

  if (identical(suite_type, "package_install")) {
    if (!isTRUE(install_packages)) {
      message <- "Package install was not requested; validation intentionally skipped."
      return(data.frame(
        repo = repo$name,
        mode = mode,
        suite_id = suite$id %||% "package_install",
        suite_type = suite_type,
        status = "skipped",
        classification = "environment",
        required = required,
        message = message,
        elapsed_seconds = NA_real_,
        output_excerpt = "",
        stringsAsFactors = FALSE
      ))
    }
  }

  if (isTRUE(suite$temp_library) || identical(suite_type, "package_install")) {
    temp_lib <- file.path(temp_lib_root %||% tempdir(), paste0("lib_", repo$name, "_", gsub("[^A-Za-z0-9]", "_", suite$id %||% suite_type)))
  }
  if (!is.null(validation_lib) && !identical(suite_type, "package_install")) {
    temp_lib <- validation_lib
  }

  if (identical(suite_type, "r_expression")) {
    expression <- suite$expression %||% "TRUE"
  } else if (identical(suite_type, "app_env_qa")) {
    fn <- suite[["function"]]
    args <- suite$args %||% ""
    call <- if (nzchar(args)) sprintf("app_env$%s(%s)", fn, args) else sprintf("app_env$%s()", fn)
    expression <- sprintf(
      "source('app.R'); if (!exists(%s, envir = app_env, inherits = FALSE)) stop('QA function unavailable: %s'); result <- %s; statuses <- result$status; if (any(statuses == 'error')) stop(paste(result$message[statuses == 'error'], collapse = ' | ')); TRUE",
      deparse(fn),
      fn,
      call
    )
  } else if (identical(suite_type, "package_load")) {
    expression <- cross_repo_package_expression(repo, "TRUE")
  } else if (identical(suite_type, "package_install")) {
    expression <- sprintf("install.packages(%s, repos = NULL, type = 'source', lib = .libPaths()[[1]]); library(%s, character.only = TRUE); TRUE", cross_repo_r_quote(repo$path), deparse(repo$package))
  } else if (identical(suite_type, "package_qa")) {
    fn <- suite[["function"]]
    qa_scope <- suite$qa_scope %||% "public"
    qa_lookup <- if (identical(qa_scope, "internal")) {
      sprintf("get(%s, envir = asNamespace(pkg), inherits = FALSE)", deparse(fn))
    } else {
      sprintf("get(%s, mode = 'function')", deparse(fn))
    }
    expression <- cross_repo_package_expression(
      repo,
      sprintf("if (%s == 'internal' && !exists(%s, envir = asNamespace(pkg), inherits = FALSE)) stop('Internal QA function unavailable: %s'); if (%s == 'public' && !exists(%s, mode = 'function')) stop('Public QA function unavailable: %s'); qa_fn <- %s; result <- qa_fn(); if (is.data.frame(result) && 'status' %%in%% names(result) && any(result$status == 'error')) stop('QA returned error rows'); TRUE", deparse(qa_scope), deparse(fn), fn, deparse(qa_scope), deparse(fn), fn, qa_lookup)
    )
  } else {
    message <- paste("Unknown suite type:", suite_type)
    return(data.frame(
      repo = repo$name,
      mode = mode,
      suite_id = suite$id %||% suite_type,
      suite_type = suite_type,
      status = if (required) "error" else "skipped",
      classification = "contract",
      required = required,
      message = message,
      elapsed_seconds = NA_real_,
      output_excerpt = "",
      stringsAsFactors = FALSE
    ))
  }

  result <- cross_repo_run_r(repo, expression, timeout = timeout, temp_lib = temp_lib)
  output_text <- paste(result$output %||% character(), collapse = "\n")
  status <- result$status
  if (identical(status, "error") && !required) {
    status <- "warning"
  }
  data.frame(
    repo = repo$name,
    mode = mode,
    suite_id = suite$id %||% suite_type,
    suite_type = suite_type,
    status = status,
    classification = if (identical(result$status, "success")) "not_applicable" else cross_repo_issue_class(result$status, paste(result$message, output_text), required = required),
    required = required,
    message = result$message,
    elapsed_seconds = result$elapsed,
    output_excerpt = substr(output_text, 1L, 2000L),
    stringsAsFactors = FALSE
  )
}

cross_repo_suites_for_mode <- function(repo, mode = c("fast", "standard", "full")) {
  mode <- match.arg(mode)
  validation <- repo$validation %||% list()
  mode_order <- switch(
    mode,
    fast = "fast",
    standard = c("fast", "standard"),
    full = c("fast", "standard", "full")
  )
  suites <- unlist(validation[mode_order], recursive = FALSE)
  if (is.null(suites)) list() else suites
}

cross_repo_check_exports <- function(repo, required_exports, validation_lib = NULL) {
  required_exports <- unlist(required_exports, use.names = FALSE)
  if (!length(required_exports)) {
    return(data.frame(
      repo = repo$name,
      contract_id = NA_character_,
      status = "success",
      classification = "not_applicable",
      message = "No required exports declared.",
      missing_exports = "",
      stringsAsFactors = FALSE
    ))
  }
  expr <- cross_repo_package_expression(
    repo,
    sprintf(
      "exports <- getNamespaceExports(%s); missing <- setdiff(c(%s), exports); if (length(missing)) stop('missing exports: ', paste(missing, collapse = ', ')); TRUE",
      deparse(repo$package),
      paste(vapply(required_exports, deparse, character(1)), collapse = ", ")
    )
  )
  result <- cross_repo_run_r(repo, expr, timeout = 180, temp_lib = validation_lib)
  output_text <- paste(result$output %||% character(), collapse = "\n")
  missing <- if (grepl("missing exports:", output_text, fixed = TRUE)) {
    gsub("\nExecution halted.*", "", sub(".*missing exports: ", "", output_text))
  } else {
    ""
  }
  source_exports <- cross_repo_source_namespace_exports(repo$path)
  missing_vector <- trimws(strsplit(missing, ",", fixed = TRUE)[[1]] %||% character())
  missing_vector <- missing_vector[nzchar(missing_vector)]
  classification <- if (identical(result$status, "success")) {
    "not_applicable"
  } else {
    cross_repo_issue_class(result$status, output_text, required = TRUE)
  }
  status <- if (identical(result$status, "success")) "success" else "error"
  if (length(missing_vector) && all(missing_vector %in% source_exports)) {
    classification <- "environment"
    status <- "warning"
  } else if (length(missing_vector)) {
    classification <- "contract"
  }
  data.frame(
    repo = repo$name,
    contract_id = NA_character_,
    status = status,
    classification = classification,
    message = result$message,
    missing_exports = missing,
    stringsAsFactors = FALSE
  )
}

cross_repo_source_namespace_exports <- function(path) {
  namespace_path <- file.path(path, "NAMESPACE")
  if (!file.exists(namespace_path)) {
    return(character())
  }
  lines <- readLines(namespace_path, warn = FALSE)
  matches <- regmatches(lines, regexec("^export\\(([^)]+)\\)", lines))
  exports <- unlist(lapply(matches, function(match) if (length(match) >= 2L) match[[2]] else character()), use.names = FALSE)
  trimws(exports)
}

cross_repo_package_files <- function(path) {
  roots <- c("DESCRIPTION", "NAMESPACE", "R", "man", "inst")
  files <- unlist(lapply(roots, function(root) {
    full <- file.path(path, root)
    if (file.exists(full) && !dir.exists(full)) {
      full
    } else if (dir.exists(full)) {
      list.files(full, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE)
    } else {
      character()
    }
  }), use.names = FALSE)
  files[file.exists(files)]
}

cross_repo_source_fingerprint <- function(repo) {
  if (!isTRUE(repo$exists)) {
    return(list(fingerprint = NA_character_, file_count = 0L))
  }
  files <- cross_repo_package_files(repo$path)
  hashes <- if (length(files)) tools::md5sum(files) else character()
  payload <- paste(
    repo$git$commit %||% "",
    repo$git$status_excerpt %||% "",
    paste(sort(paste(cross_repo_normalize_path(names(hashes)), hashes, sep = "=")), collapse = "|"),
    sep = "\n"
  )
  fingerprint_file <- tempfile("cross_repo_fingerprint_", fileext = ".txt")
  writeLines(payload, fingerprint_file, useBytes = TRUE)
  list(
    fingerprint = unname(tools::md5sum(fingerprint_file) %||% NA_character_),
    file_count = length(files),
    files = cross_repo_normalize_path(files)
  )
}

cross_repo_local_package_order <- function(discovery) {
  package_repos <- Filter(function(repo) isTRUE(repo$is_package) && !identical(repo$name, "AnalyticsShinyApp"), discovery)
  local_packages <- vapply(package_repos, function(repo) repo$package, character(1))
  deps <- lapply(package_repos, function(repo) {
    imports <- repo$package_metadata$imports %||% ""
    depends <- repo$package_metadata$depends %||% ""
    text <- paste(imports, depends)
    intersect(local_packages, unique(unlist(regmatches(text, gregexpr("[A-Za-z][A-Za-z0-9.]*", text)))))
  })
  names(deps) <- names(package_repos)

  ordered <- character()
  remaining <- names(package_repos)
  while (length(remaining)) {
    ready <- remaining[vapply(remaining, function(name) {
      repo_deps <- deps[[name]]
      length(repo_deps) == 0L || all(repo_deps %in% vapply(package_repos[ordered], function(repo) repo$package, character(1)))
    }, logical(1))]
    if (!length(ready)) {
      ordered <- c(ordered, remaining)
      break
    }
    ordered <- c(ordered, ready)
    remaining <- setdiff(remaining, ready)
  }
  ordered
}

cross_repo_r_binary <- function() {
  cross_repo_normalize_path(file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R"))
}

cross_repo_build_package <- function(repo, build_dir) {
  dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
  rbin <- cross_repo_r_binary()
  started <- Sys.time()
  output <- tryCatch(
    system2(
      rbin,
      c("CMD", "build", "--no-manual", "--no-build-vignettes", repo$path),
      stdout = TRUE,
      stderr = TRUE,
      timeout = 600,
      env = character(),
      wait = TRUE
    ),
    error = function(e) structure(conditionMessage(e), class = "cross_repo_build_error")
  )
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(output, "cross_repo_build_error")) {
    return(list(status = "error", message = as.character(output), output = as.character(output), elapsed = elapsed, archive = NA_character_))
  }
  archive_candidates <- list.files(getwd(), pattern = paste0("^", repo$package, "_.*[.]tar[.]gz$"), full.names = TRUE)
  archive_candidates <- archive_candidates[order(file.info(archive_candidates)$mtime, decreasing = TRUE)]
  archive <- if (length(archive_candidates)) archive_candidates[[1]] else NA_character_
  if (!is.na(archive)) {
    target <- file.path(build_dir, basename(archive))
    file.copy(archive, target, overwrite = TRUE)
    unlink(archive)
    archive <- target
  }
  exit_status <- attr(output, "status") %||% 0L
  list(
    status = if (identical(as.integer(exit_status), 0L) && !is.na(archive) && file.exists(archive)) "success" else "error",
    message = if (!is.na(archive) && file.exists(archive)) "Package archive built." else "Package archive was not produced.",
    output = as.character(output),
    elapsed = elapsed,
    archive = cross_repo_normalize_path(archive)
  )
}

cross_repo_install_built_package <- function(repo, archive, temp_lib, timeout = 600) {
  expr <- sprintf(
    "dir.create(%s, recursive = TRUE, showWarnings = FALSE); .libPaths(c(%s, .libPaths())); install.packages(%s, repos = NULL, type = 'source', lib = %s); pkg <- %s; library(pkg, character.only = TRUE); loaded <- normalizePath(find.package(pkg), winslash = '/', mustWork = TRUE); if (!startsWith(loaded, normalizePath(%s, winslash = '/', mustWork = TRUE))) stop('stale global-package contamination: ', loaded); cat('LOADED_PATH=', loaded, '\\n', sep = ''); cat('PACKAGE_VERSION=', as.character(packageVersion(pkg)), '\\n', sep = ''); TRUE",
    cross_repo_r_quote(temp_lib),
    cross_repo_r_quote(temp_lib),
    cross_repo_r_quote(archive),
    cross_repo_r_quote(temp_lib),
    deparse(repo$package),
    cross_repo_r_quote(temp_lib)
  )
  cross_repo_run_r(repo, expr, timeout = timeout)
}

cross_repo_extract_loaded_field <- function(output, prefix) {
  lines <- strsplit(paste(output, collapse = "\n"), "\n", fixed = TRUE)[[1]]
  hit <- lines[startsWith(lines, prefix)]
  if (length(hit)) sub(paste0("^", prefix), "", hit[[1]]) else NA_character_
}

cross_repo_installed_contract_snapshot <- function(repo, temp_lib, suites = list()) {
  qa_entries <- lapply(suites, function(suite) {
    if (!identical(suite$type %||% "", "package_qa")) {
      return(NULL)
    }
    list(
      id = suite$id %||% suite[["function"]],
      qa_function = suite[["function"]],
      scope = suite$qa_scope %||% "public"
    )
  })
  qa_entries <- Filter(Negate(is.null), qa_entries)
  expr <- sprintf(
    ".libPaths(c(%s, .libPaths())); pkg <- %s; suppressPackageStartupMessages(library(pkg, character.only = TRUE)); exports <- getNamespaceExports(pkg); cat(jsonlite::toJSON(list(path = normalizePath(find.package(pkg), winslash = '/', mustWork = TRUE), version = as.character(packageVersion(pkg)), exports = sort(exports)), auto_unbox = TRUE))",
    cross_repo_r_quote(temp_lib),
    deparse(repo$package)
  )
  result <- cross_repo_run_r(repo, expr, timeout = 180)
  output_text <- paste(result$output, collapse = "\n")
  json_text <- if (grepl("\\{", output_text)) {
    sub("^[^{]*", "", sub("[^}]*$", "", output_text))
  } else {
    output_text
  }
  payload <- tryCatch(jsonlite::fromJSON(json_text), error = function(e) list())
  list(
    package = repo$package,
    version = payload$version %||% NA_character_,
    installed_path = payload$path %||% NA_character_,
    exports = payload$exports %||% character(),
    qa_entries = qa_entries,
    status = result$status,
    message = result$message
  )
}

cross_repo_build_install_packages <- function(discovery, output_dir, mode = "fast") {
  temp_lib <- file.path(output_dir, "temp_library")
  build_dir <- file.path(output_dir, "package_builds")
  dir.create(temp_lib, recursive = TRUE, showWarnings = FALSE)
  dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
  order <- cross_repo_local_package_order(discovery)
  rows <- list()
  snapshots <- list()

  for (repo_name in order) {
    repo <- discovery[[repo_name]]
    fingerprint <- cross_repo_source_fingerprint(repo)
    build <- cross_repo_build_package(repo, build_dir = build_dir)
    install <- if (identical(build$status, "success")) {
      cross_repo_install_built_package(repo, build$archive, temp_lib = temp_lib)
    } else {
      list(status = "skipped", message = "Build failed; install skipped.", output = character(), elapsed = NA_real_)
    }
    loaded_path <- cross_repo_extract_loaded_field(install$output %||% character(), "LOADED_PATH=")
    installed_version <- cross_repo_extract_loaded_field(install$output %||% character(), "PACKAGE_VERSION=")
    source_exports <- cross_repo_source_namespace_exports(repo$path)
    snapshot <- if (identical(install$status, "success")) {
      cross_repo_installed_contract_snapshot(repo, temp_lib, suites = unlist(repo$validation %||% list(), recursive = FALSE))
    } else {
      list(package = repo$package, status = "skipped", message = install$message, exports = character())
    }
    snapshots[[repo$name]] <- snapshot
    missing_exports <- setdiff(unlist(repo$expected_exports %||% list(), use.names = FALSE), snapshot$exports %||% character())
    status <- if (identical(build$status, "success") && identical(install$status, "success") && !length(missing_exports)) "success" else "error"
    classification <- if (!identical(build$status, "success")) {
      "package_build_failure"
    } else if (!identical(install$status, "success")) {
      "package_installation_failure"
    } else if (length(missing_exports)) {
      "export_mismatch"
    } else {
      "not_applicable"
    }
    rows[[length(rows) + 1L]] <- data.frame(
      repo = repo$name,
      package = repo$package,
      source_path = repo$path,
      branch = repo$git$branch %||% NA_character_,
      commit = repo$git$commit %||% NA_character_,
      dirty = isTRUE(repo$git$dirty),
      source_fingerprint = fingerprint$fingerprint %||% NA_character_,
      source_file_count = fingerprint$file_count %||% 0L,
      package_version = repo$package_metadata$version %||% NA_character_,
      build_status = build$status,
      install_status = install$status,
      status = status,
      classification = classification,
      archive = build$archive %||% NA_character_,
      temp_library = cross_repo_normalize_path(temp_lib),
      loaded_path = loaded_path,
      installed_version = installed_version,
      missing_exports = paste(missing_exports, collapse = ", "),
      source_exports_count = length(source_exports),
      installed_exports_count = length(snapshot$exports %||% character()),
      build_seconds = build$elapsed %||% NA_real_,
      install_seconds = install$elapsed %||% NA_real_,
      build_log = paste(build$output %||% character(), collapse = "\n"),
      install_log = paste(install$output %||% character(), collapse = "\n"),
      stringsAsFactors = FALSE
    )
  }
  list(
    temp_library = cross_repo_normalize_path(temp_lib),
    build_dir = cross_repo_normalize_path(build_dir),
    install_order = order,
    results = if (length(rows)) do.call(rbind, rows) else data.frame(),
    snapshots = snapshots
  )
}

cross_repo_validate_contracts <- function(discovery, manifest, validation_lib = NULL) {
  contracts <- manifest$contracts %||% list()
  if (!length(contracts)) {
    return(data.frame(
      contract_id = character(),
      consumer = character(),
      provider = character(),
      status = character(),
      classification = character(),
      message = character(),
      missing_exports = character(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- lapply(contracts, function(contract) {
    provider <- discovery[[contract$provider]]
    if (is.null(provider) || !isTRUE(provider$exists)) {
      return(data.frame(
        contract_id = contract$contract_id,
        consumer = contract$consumer,
        provider = contract$provider,
        status = "error",
        classification = "environment",
        message = paste("Provider repository is unavailable:", contract$provider),
        missing_exports = paste(unlist(contract$required_exports), collapse = ", "),
        stringsAsFactors = FALSE
      ))
    }
    check <- cross_repo_check_exports(provider, contract$required_exports, validation_lib = validation_lib)
    check$contract_id <- contract$contract_id
    check$consumer <- contract$consumer
    check$provider <- contract$provider
    check[, c("contract_id", "consumer", "provider", "status", "classification", "message", "missing_exports")]
  })
  do.call(rbind, rows)
}

cross_repo_write_results <- function(result, output_dir) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package jsonlite is required to write cross-repo validation results.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(result, file.path(output_dir, "result.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
  summary <- cross_repo_markdown_summary(result)
  writeLines(summary, file.path(output_dir, "summary.md"), useBytes = TRUE)
  invisible(output_dir)
}

cross_repo_markdown_summary <- function(result) {
  rows <- result$validation_results
  contract_rows <- result$contract_results
  package_rows <- result$package_refresh$results %||% list()
  status_counts <- if (length(rows)) table(vapply(rows, `[[`, character(1), "status")) else integer()
  contract_counts <- if (length(contract_rows)) table(vapply(contract_rows, `[[`, character(1), "status")) else integer()
  package_counts <- if (length(package_rows)) table(vapply(package_rows, `[[`, character(1), "status")) else integer()
  repo_lines <- vapply(result$repositories, function(repo) {
    sprintf("- `%s`: %s (`%s`, branch `%s`, commit `%s`, dirty: `%s`)", repo$name, if (isTRUE(repo$exists)) repo$path else "not found", repo$path_source, repo$git$branch %||% NA_character_, repo$git$commit %||% NA_character_, repo$git$dirty %||% NA)
  }, character(1))
  c(
    "# Cross-Repository Validation Summary",
    "",
    paste("- Run id:", result$run_id),
    paste("- Mode:", result$mode),
    paste("- Status:", result$status),
    paste("- R:", result$r_version),
    paste("- Started:", result$started_at),
    paste("- Completed:", result$completed_at),
    "",
    "## Repositories",
    repo_lines,
    "",
    "## Validation Counts",
    if (length(status_counts)) paste(sprintf("- %s: %s", names(status_counts), as.integer(status_counts)), collapse = "\n") else "- No validation suites were run.",
    "",
    "## Source-to-Install Counts",
    if (length(package_counts)) paste(sprintf("- %s: %s", names(package_counts), as.integer(package_counts)), collapse = "\n") else "- Fresh package build/install was not run.",
    "",
    "## Package Install Order",
    if (length(result$package_install_order %||% character())) paste(sprintf("- `%s`", result$package_install_order), collapse = "\n") else "- No package install order was resolved.",
    "",
    "## Contract Counts",
    if (length(contract_counts)) paste(sprintf("- %s: %s", names(contract_counts), as.integer(contract_counts)), collapse = "\n") else "- No contract checks were run.",
    "",
    "## Notes",
    "- Environment failures usually indicate missing repos, unavailable packages, dependency issues, or package install problems.",
    "- Contract failures indicate missing expected exports or unavailable QA functions.",
    "- Product failures indicate required validation code executed and failed."
  )
}

cross_repo_validate <- function(
  mode = c("fast", "standard", "full"),
  manifest_path = cross_repo_manifest_path(),
  workspace_root = getwd(),
  output_dir = file.path("exports", "cross_repo_validation"),
  install_packages = FALSE,
  fresh_packages = TRUE
) {
  mode <- match.arg(mode)
  started <- Sys.time()
  manifest <- cross_repo_read_manifest(manifest_path)
  manifest_validation <- cross_repo_validate_manifest(manifest)
  run_id <- paste0("cross_repo_", format(started, "%Y%m%d_%H%M%S"))
  run_output_dir <- file.path(output_dir, run_id)
  if (!identical(manifest_validation$status, "success")) {
    result <- list(
      run_id = run_id,
      mode = mode,
      status = "error",
      started_at = as.character(started),
      completed_at = as.character(Sys.time()),
      r_version = R.version.string,
      manifest_path = cross_repo_normalize_path(manifest_path),
      manifest_issues = manifest_validation$issues,
      repositories = list(),
      validation_results = list(),
      contract_results = list(),
      package_refresh = list(),
      output_dir = cross_repo_normalize_path(run_output_dir)
    )
    cross_repo_write_results(result, run_output_dir)
    return(result)
  }

  discovery <- cross_repo_discover_repositories(manifest, workspace_root = workspace_root)
  dir.create(run_output_dir, recursive = TRUE, showWarnings = FALSE)
  package_refresh <- if (isTRUE(fresh_packages)) {
    cross_repo_build_install_packages(discovery, output_dir = run_output_dir, mode = mode)
  } else {
    list(temp_library = NULL, build_dir = NULL, install_order = character(), results = data.frame(), snapshots = list())
  }
  validation_lib <- package_refresh$temp_library
  temp_lib_root <- file.path(tempdir(), run_id)
  validation_frames <- list()
  for (repo_name in names(discovery)) {
    repo <- discovery[[repo_name]]
    suites <- cross_repo_suites_for_mode(repo, mode = mode)
    if (!length(suites)) {
      validation_frames[[length(validation_frames) + 1L]] <- data.frame(
        repo = repo$name,
        mode = mode,
        suite_id = "no_suites_declared",
        suite_type = "skip_note",
        status = "skipped",
        classification = "not_applicable",
        required = FALSE,
        message = paste("No", mode, "validation suites are declared for this repository."),
        elapsed_seconds = NA_real_,
        output_excerpt = "",
        stringsAsFactors = FALSE
      )
      next
    }
    for (suite in suites) {
      validation_frames[[length(validation_frames) + 1L]] <- cross_repo_run_suite(
        repo = repo,
        suite = suite,
        mode = mode,
        temp_lib_root = temp_lib_root,
        install_packages = install_packages,
        validation_lib = validation_lib
      )
    }
  }
  validation_df <- if (length(validation_frames)) do.call(rbind, validation_frames) else data.frame()
  contract_df <- cross_repo_validate_contracts(discovery, manifest, validation_lib = validation_lib)
  package_df <- package_refresh$results
  terminal_statuses <- c(validation_df$status, contract_df$status, package_df$status)
  status <- if (any(terminal_statuses == "error")) {
    "error"
  } else if (any(terminal_statuses %in% c("warning", "skipped"))) {
    "warning"
  } else {
    "success"
  }

  result <- list(
    run_id = run_id,
    mode = mode,
    status = status,
    started_at = as.character(started),
    completed_at = as.character(Sys.time()),
    r_version = R.version.string,
    manifest_path = cross_repo_normalize_path(manifest_path),
    install_packages = isTRUE(install_packages),
    fresh_packages = isTRUE(fresh_packages),
    validation_temp_library = validation_lib,
    package_install_order = package_refresh$install_order,
    repositories = discovery,
    package_refresh = list(
      temp_library = package_refresh$temp_library,
      build_dir = package_refresh$build_dir,
      install_order = package_refresh$install_order,
      results = lapply(seq_len(nrow(package_df)), function(i) as.list(package_df[i, , drop = FALSE])),
      snapshots = package_refresh$snapshots
    ),
    validation_results = lapply(seq_len(nrow(validation_df)), function(i) as.list(validation_df[i, , drop = FALSE])),
    contract_results = lapply(seq_len(nrow(contract_df)), function(i) as.list(contract_df[i, , drop = FALSE])),
    output_dir = cross_repo_normalize_path(run_output_dir)
  )
  cross_repo_write_results(result, run_output_dir)
  result
}

qa_cross_repo_validation_orchestrator <- function(output_dir = file.path(tempdir(), "cross_repo_validation_qa")) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  repo_root <- normalizePath(".", winslash = "/", mustWork = FALSE)
  manifest <- cross_repo_read_manifest()
  manifest_status <- cross_repo_validate_manifest(manifest)
  discovery <- cross_repo_discover_repositories(manifest, workspace_root = repo_root)
  fast_suites <- cross_repo_suites_for_mode(discovery$AnalyticsShinyApp, mode = "fast")
  standard_suites <- cross_repo_suites_for_mode(discovery$AnalyticsShinyApp, mode = "standard")
  full_suites <- cross_repo_suites_for_mode(discovery$AnalyticsShinyApp, mode = "full")
  package_order <- cross_repo_local_package_order(discovery)
  app_fingerprint <- cross_repo_source_fingerprint(discovery$AnalyticsShinyApp)
  autoquant_full_suites <- cross_repo_suites_for_mode(discovery$AutoQuant, mode = "full")
  internal_qa_declared <- any(vapply(autoquant_full_suites, function(suite) identical(suite$qa_scope %||% "public", "internal"), logical(1)))

  fixture_manifest <- manifest
  fixture_manifest$repositories <- list(list(
    name = "MissingRequiredRepo",
    package = "MissingRequiredRepo",
    required = TRUE,
    is_package = FALSE,
    relative_path = file.path(output_dir, "does_not_exist"),
    validation = list(fast = list(list(id = "missing_path", type = "r_expression", expression = "TRUE", required = TRUE)))
  ))
  fixture_discovery <- cross_repo_discover_repositories(fixture_manifest, workspace_root = repo_root)
  missing_repo_result <- cross_repo_run_suite(
    repo = fixture_discovery$MissingRequiredRepo,
    suite = fixture_manifest$repositories[[1]]$validation$fast[[1]],
    mode = "fast"
  )

  contract_classification <- cross_repo_issue_class("error", "missing exports: definitely_missing_export_for_qa", required = TRUE)

  result <- cross_repo_validate(
    mode = "fast",
    manifest_path = cross_repo_manifest_path(),
    workspace_root = repo_root,
    output_dir = output_dir,
    install_packages = FALSE,
    fresh_packages = FALSE
  )

  checks <- data.frame(
    check = c(
      "manifest_valid",
      "analytics_repo_discovered",
      "rodeo_repo_discovered",
      "autoquant_repo_discovered",
      "autoplots_repo_discovered",
      "mode_fast_suites_exist",
      "mode_standard_extends_fast",
      "mode_full_extends_standard",
      "missing_required_repo_classified_environment",
      "missing_export_classified_contract",
      "partial_result_written_json",
      "partial_result_written_summary",
      "git_metadata_captured",
      "package_metadata_captured",
      "source_fingerprint_captured",
      "package_dependency_order_resolved",
      "internal_qa_scope_declared",
      "unified_result_fields_exist"
    ),
    status = c(
      if (identical(manifest_status$status, "success")) "success" else "error",
      if (isTRUE(discovery$AnalyticsShinyApp$exists)) "success" else "error",
      if (isTRUE(discovery$Rodeo$exists)) "success" else "warning",
      if (isTRUE(discovery$AutoQuant$exists)) "success" else "warning",
      if (isTRUE(discovery$AutoPlots$exists)) "success" else "warning",
      if (length(fast_suites) > 0L) "success" else "error",
      if (length(standard_suites) >= length(fast_suites)) "success" else "error",
      if (length(full_suites) >= length(standard_suites)) "success" else "error",
      if (identical(missing_repo_result$classification[[1]], "environment")) "success" else "error",
      if (identical(contract_classification, "contract")) "success" else "error",
      if (file.exists(file.path(result$output_dir, "result.json"))) "success" else "error",
      if (file.exists(file.path(result$output_dir, "summary.md"))) "success" else "error",
      if (isTRUE(discovery$AnalyticsShinyApp$git$available)) "success" else "warning",
      if (isTRUE(discovery$AnalyticsShinyApp$package_metadata$available)) "success" else "error",
      if (nzchar(app_fingerprint$fingerprint %||% "")) "success" else "error",
      if (all(c("Rodeo", "AutoPlots", "AutoQuant") %in% package_order)) "success" else "error",
      if (isTRUE(internal_qa_declared)) "success" else "error",
      if (all(c("run_id", "mode", "status", "repositories", "validation_results", "contract_results", "output_dir") %in% names(result))) "success" else "error"
    ),
    message = c(
      paste(manifest_status$issues, collapse = " | "),
      discovery$AnalyticsShinyApp$path %||% "missing",
      discovery$Rodeo$path %||% "missing",
      discovery$AutoQuant$path %||% "missing",
      discovery$AutoPlots$path %||% "missing",
      paste(length(fast_suites), "fast suite(s) discovered for AnalyticsShinyApp."),
      paste(length(standard_suites), "standard suite(s) after mode expansion."),
      paste(length(full_suites), "full suite(s) after mode expansion."),
      missing_repo_result$message[[1]],
      "missing exports: definitely_missing_export_for_qa",
      file.path(result$output_dir, "result.json"),
      file.path(result$output_dir, "summary.md"),
      discovery$AnalyticsShinyApp$git$commit %||% "git metadata unavailable",
      discovery$AnalyticsShinyApp$package_metadata$package %||% "package metadata unavailable",
      app_fingerprint$fingerprint %||% "missing fingerprint",
      paste(package_order, collapse = " -> "),
      "Internal installed QA functions are declared explicitly in the manifest.",
      result$output_dir
    ),
    stringsAsFactors = FALSE
  )
  checks
}
