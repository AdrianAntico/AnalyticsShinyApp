storage_schema_version <- "1"
project_schema_version <- "1"
storage_policy_version <- "storage_policy_v1"
persistence_schema_version <- "result_persistence_v1"

workspace_states <- c(
  "workspace_unconfigured",
  "workspace_configuring",
  "workspace_ready",
  "workspace_invalid",
  "workspace_unavailable",
  "workspace_error"
)

project_states <- c(
  "no_project",
  "project_loading",
  "project_ready",
  "project_error",
  "project_closing"
)

storage_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
}

storage_normalize_path <- function(path, must_work = FALSE) {
  path <- selected_value(path)
  if (is.null(path)) {
    return(NULL)
  }
  path <- trimws(as.character(path[[1]]))
  path <- gsub("^[\"']+|[\"']+$", "", path)
  path <- trimws(path)
  if (!nzchar(path)) {
    return(NULL)
  }
  path <- path.expand(chartr("\\", "/", path))
  suppressWarnings(normalizePath(path, winslash = "/", mustWork = must_work))
}

storage_repo_root <- function(start = getwd()) {
  root <- storage_normalize_path(start, must_work = FALSE)
  if (is.null(root)) {
    return(NA_character_)
  }
  current <- root
  repeat {
    if (file.exists(file.path(current, "app.R")) && dir.exists(file.path(current, "R"))) {
      return(storage_normalize_path(current, must_work = FALSE))
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      return(root)
    }
    current <- parent
  }
}

storage_canonical <- function(path) {
  path <- storage_normalize_path(path, must_work = FALSE)
  if (is.null(path)) {
    return(NULL)
  }
  path <- gsub("/+$", "", path)
  if (.Platform$OS.type == "windows") {
    path <- tolower(path)
  }
  path
}

path_within_root <- function(path, root) {
  path <- storage_canonical(path)
  root <- storage_canonical(root)
  if (is.null(path) || is.null(root) || !nzchar(path) || !nzchar(root)) {
    return(FALSE)
  }
  identical(path, root) || startsWith(path, paste0(root, "/"))
}

path_outside_root <- function(path, root) {
  !path_within_root(path, root)
}

safe_path_component <- function(value, fallback = "item") {
  value <- as.character(value %||% fallback)
  value <- gsub("[^A-Za-z0-9._-]+", "_", value)
  value <- gsub("^_+|_+$", "", value)
  if (!nzchar(value)) fallback else value
}

storage_resource_id_is_valid <- function(resource_id) {
  is.character(resource_id) &&
    length(resource_id) == 1L &&
    !is.na(resource_id) &&
    nzchar(resource_id) &&
    grepl("^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$", resource_id)
}

storage_error_result <- function(error_code, message, workspace_state = NULL, project_state = NULL,
                                 requested_resource_type = NULL, metadata = list()) {
  service_result(
    status = "error",
    errors = message,
    metadata = c(
      list(
        error_code = error_code,
        workspace_state = workspace_state,
        project_state = project_state,
        requested_resource_type = requested_resource_type
      ),
      metadata
    )
  )
}

storage_provider <- function(
  provider_id,
  provider_type,
  display_name = provider_id,
  root_path = NULL,
  available = TRUE,
  selection_supported = FALSE,
  managed = FALSE,
  writable = NA,
  capabilities = list(),
  validation_status = "not_checked",
  safe_display_label = NULL
) {
  default_capabilities <- list(
    can_choose_directory = FALSE,
    can_browse_server_directories = FALSE,
    can_open_directory = FALSE,
    workspace_is_managed = isTRUE(managed),
    supports_external_projects = FALSE,
    native_directory_picker = FALSE
  )
  capabilities <- utils::modifyList(default_capabilities, capabilities %||% list())
  structure(
    list(
      provider_id = provider_id,
      provider_type = provider_type,
      display_name = display_name,
      available = isTRUE(available),
      selection_supported = isTRUE(selection_supported),
      managed = isTRUE(managed),
      root_path = storage_normalize_path(root_path, must_work = FALSE),
      writable = writable,
      capabilities = capabilities,
      validation_status = validation_status,
      safe_display_label = safe_display_label %||% display_name
    ),
    class = c("aw_storage_provider", "list")
  )
}

storage_provider_capability <- function(provider, capability) {
  isTRUE((provider$capabilities %||% list())[[capability]])
}

storage_hash_value <- function(value) {
  path <- tempfile("storage_hash_", fileext = ".rds")
  on.exit(if (file.exists(path)) unlink(path), add = TRUE)
  saveRDS(value, path)
  unname(tools::md5sum(path))
}

storage_root_identity <- function(path) {
  paste0("root:", storage_hash_value(storage_canonical(path) %||% ""))
}

storage_provider_capability_version <- function(provider) {
  paste0("cap:", storage_hash_value(provider$capabilities %||% list()))
}

storage_provider_write_policy <- function(provider) {
  list(
    durable_project_writes = isTRUE(provider$available) && !identical(provider$writable, FALSE),
    workspace_is_managed = isTRUE(provider$managed),
    supports_external_projects = storage_provider_capability(provider, "supports_external_projects"),
    selection_capabilities_required = FALSE,
    provider_type = provider$provider_type %||% NA_character_
  )
}

storage_provider_write_policy_id <- function(provider) {
  paste0("write:", storage_hash_value(storage_provider_write_policy(provider)))
}

safe_project_destination_label <- function(workspace, project, resource_type = "results") {
  provider <- workspace$provider %||% list(managed = FALSE, safe_display_label = "Workspace")
  root_label <- if (isTRUE(provider$managed)) {
    provider$safe_display_label %||% "Managed workspace"
  } else {
    workspace$provider_safe_display_label %||% provider$safe_display_label %||% "Workspace"
  }
  paste(root_label, project$project_name %||% project$project_id %||% "Project", resource_type, sep = " / ")
}

storage_persistence_fingerprint <- function(workspace, project) {
  provider <- workspace$provider %||% storage_provider(
    provider_id = workspace$provider_id %||% "configured_workspace",
    provider_type = workspace$provider_type %||% "configured_workspace",
    display_name = workspace$provider_display_name %||% "Configured Workspace",
    root_path = workspace$workspace_root %||% NULL,
    available = !is.null(workspace$workspace_root),
    writable = TRUE,
    capabilities = (workspace$provider %||% list())$capabilities %||% list()
  )
  binding <- list(
    workspace_provider_id = provider$provider_id %||% workspace$provider_id %||% NA_character_,
    workspace_provider_type = provider$provider_type %||% workspace$provider_type %||% NA_character_,
    workspace_state = workspace$workspace_state %||% NA_character_,
    workspace_root_identity = storage_root_identity(workspace$workspace_root %||% provider$root_path %||% ""),
    provider_capability_version = storage_provider_capability_version(provider),
    provider_write_policy = storage_provider_write_policy_id(provider),
    active_project_id = project$project_id %||% NA_character_,
    project_root_identity = storage_root_identity(project$project_root %||% "")
  )
  binding$fingerprint <- paste0("persist:", storage_hash_value(binding))
  binding
}

validate_project_provider_compatibility <- function(workspace, project, provider = workspace$provider %||% NULL) {
  provider <- provider %||% storage_provider(
    provider_id = workspace$provider_id %||% "configured_workspace",
    provider_type = workspace$provider_type %||% "configured_workspace",
    display_name = workspace$provider_display_name %||% "Configured Workspace",
    root_path = workspace$workspace_root %||% NULL,
    available = !is.null(workspace$workspace_root),
    writable = TRUE,
    capabilities = list(supports_external_projects = TRUE)
  )
  if (!isTRUE(provider$available)) {
    return(storage_error_result(
      "workspace_provider_unavailable",
      "The active storage provider is unavailable.",
      workspace_state = workspace$workspace_state %||% "workspace_unavailable",
      project_state = project$project_state %||% "project_error",
      metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)
    ))
  }
  if (identical(provider$writable, FALSE)) {
    return(storage_error_result(
      "workspace_provider_write_denied",
      "The active storage provider does not permit durable project writes.",
      workspace_state = workspace$workspace_state %||% "workspace_ready",
      project_state = project$project_state %||% "project_ready",
      metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)
    ))
  }
  project_provider_id <- project$workspace_provider_id %||% NA_character_
  active_provider_id <- provider$provider_id %||% workspace$provider_id %||% NA_character_
  if (!is.na(project_provider_id) && nzchar(project_provider_id) && !identical(project_provider_id, active_provider_id)) {
    return(storage_error_result(
      "workspace_provider_mismatch",
      "The active project was created for a different storage provider.",
      workspace_state = workspace$workspace_state %||% "workspace_ready",
      project_state = project$project_state %||% "project_ready",
      metadata = list(project_provider_id = project_provider_id, active_provider_id = active_provider_id)
    ))
  }
  workspace_root <- workspace$workspace_root %||% provider$root_path
  project_inside_workspace <- path_within_root(project$project_root, workspace_root)
  if (!isTRUE(project_inside_workspace) && !storage_provider_capability(provider, "supports_external_projects")) {
    return(storage_error_result(
      "workspace_provider_write_denied",
      "The active provider does not permit persistence to an external project root.",
      workspace_state = workspace$workspace_state %||% "workspace_ready",
      project_state = project$project_state %||% "project_ready",
      metadata = list(provider_id = active_provider_id, project_provider_match = FALSE)
    ))
  }
  service_result(
    status = "success",
    value = list(
      provider = provider,
      project_provider_match = TRUE,
      project_inside_workspace = project_inside_workspace,
      provider_write_policy = storage_provider_write_policy(provider),
      persistence_fingerprint = storage_persistence_fingerprint(workspace, project)
    ),
    metadata = list(
      provider_id = active_provider_id,
      provider_type = provider$provider_type,
      workspace_is_managed = isTRUE(provider$managed),
      provider_capability_version = storage_provider_capability_version(provider),
      provider_write_policy = storage_provider_write_policy_id(provider),
      project_provider_match = TRUE
    )
  )
}

detect_storage_deployment_mode <- function() {
  mode <- Sys.getenv("ANALYTICS_WORKSTATION_DEPLOYMENT_MODE", unset = "")
  if (nzchar(mode)) {
    return(mode)
  }
  if (nzchar(Sys.getenv("SHINY_PORT", unset = "")) ||
      nzchar(Sys.getenv("R_CONFIG_ACTIVE", unset = ""))) {
    return("local_or_hosted_shiny")
  }
  "local_shiny"
}

storage_provider_registry <- function(settings = read_workspace_settings()) {
  managed_root <- Sys.getenv("ANALYTICS_WORKSTATION_MANAGED_WORKSPACE_ROOT", unset = "")
  configured_root <- settings$workspace_root %||% Sys.getenv("ANALYTICS_WORKSTATION_WORKSPACE_ROOT", unset = "")
  providers <- list()

  providers$managed_workspace <- storage_provider(
    provider_id = "managed_workspace",
    provider_type = "managed_workspace",
    display_name = "Managed Workspace",
    root_path = if (nzchar(managed_root)) managed_root else NULL,
    available = nzchar(managed_root),
    selection_supported = FALSE,
    managed = TRUE,
    capabilities = list(
      workspace_is_managed = TRUE,
      supports_external_projects = FALSE,
      can_choose_directory = FALSE,
      can_browse_server_directories = FALSE
    ),
    validation_status = if (nzchar(managed_root)) "configured" else "unavailable",
    safe_display_label = "Managed server workspace"
  )

  providers$configured_workspace <- storage_provider(
    provider_id = "configured_workspace",
    provider_type = "configured_workspace",
    display_name = "Configured Workspace",
    root_path = if (nzchar(configured_root)) configured_root else NULL,
    available = nzchar(configured_root),
    selection_supported = TRUE,
    managed = FALSE,
    capabilities = list(
      can_choose_directory = TRUE,
      can_browse_server_directories = FALSE,
      supports_external_projects = TRUE
    ),
    validation_status = if (nzchar(configured_root)) "configured" else "unconfigured",
    safe_display_label = "Configured local/server workspace"
  )

  providers$local_server_directory <- storage_provider(
    provider_id = "local_server_directory",
    provider_type = "local_server_directory",
    display_name = "Local Server Directory",
    root_path = NULL,
    available = TRUE,
    selection_supported = TRUE,
    managed = FALSE,
    capabilities = list(
      can_choose_directory = TRUE,
      can_browse_server_directories = TRUE,
      supports_external_projects = TRUE
    ),
    validation_status = "available",
    safe_display_label = "Typed local/server path"
  )

  providers$native_host_directory <- storage_provider(
    provider_id = "native_host_directory",
    provider_type = "native_host_directory",
    display_name = "Native Host Directory",
    root_path = NULL,
    available = identical(Sys.getenv("ANALYTICS_WORKSTATION_NATIVE_PICKER", unset = "false"), "true"),
    selection_supported = identical(Sys.getenv("ANALYTICS_WORKSTATION_NATIVE_PICKER", unset = "false"), "true"),
    managed = FALSE,
    capabilities = list(
      can_choose_directory = identical(Sys.getenv("ANALYTICS_WORKSTATION_NATIVE_PICKER", unset = "false"), "true"),
      native_directory_picker = identical(Sys.getenv("ANALYTICS_WORKSTATION_NATIVE_PICKER", unset = "false"), "true"),
      supports_external_projects = TRUE
    ),
    validation_status = if (identical(Sys.getenv("ANALYTICS_WORKSTATION_NATIVE_PICKER", unset = "false"), "true")) "available" else "unavailable",
    safe_display_label = "Native host picker"
  )

  providers
}

storage_provider_summary <- function(providers = storage_provider_registry()) {
  data.table::rbindlist(lapply(providers, function(provider) {
    caps <- provider$capabilities %||% list()
    data.table::data.table(
      provider_id = provider$provider_id,
      provider_type = provider$provider_type,
      display_name = provider$display_name,
      available = isTRUE(provider$available),
      selection_supported = isTRUE(provider$selection_supported),
      managed = isTRUE(provider$managed),
      root_path = provider$root_path %||% NA_character_,
      writable = as.character(provider$writable %||% NA),
      capabilities = paste(names(caps)[vapply(caps, isTRUE, logical(1))], collapse = ", "),
      validation_status = provider$validation_status
    )
  }), fill = TRUE)
}

resolve_storage_provider <- function(provider_id = NULL, settings = read_workspace_settings()) {
  providers <- storage_provider_registry(settings)
  provider_id <- provider_id %||% settings$workspace_provider_id
  if (!is.null(provider_id) && nzchar(provider_id) && provider_id %in% names(providers)) {
    return(providers[[provider_id]])
  }
  if (isTRUE(providers$managed_workspace$available)) {
    return(providers$managed_workspace)
  }
  if (isTRUE(providers$configured_workspace$available)) {
    return(providers$configured_workspace)
  }
  providers$local_server_directory
}

storage_user_config_dir <- function() {
  dir <- tryCatch(
    tools::R_user_dir("AnalyticsWorkstation", which = "config"),
    error = function(e) file.path(path.expand("~"), "AppData", "Roaming", "AnalyticsWorkstation")
  )
  storage_normalize_path(dir, must_work = FALSE)
}

storage_settings_file <- function(config_dir = storage_user_config_dir()) {
  file.path(config_dir, "workspace_settings.rds")
}

read_workspace_settings <- function(settings_file = storage_settings_file()) {
  if (!file.exists(settings_file)) {
    return(list())
  }
  value <- tryCatch(readRDS(settings_file), error = function(e) structure(list(), error = conditionMessage(e)))
  if (!is.list(value)) {
    return(list(settings_error = "Stored settings are not a list."))
  }
  value
}

write_workspace_settings <- function(settings, settings_file = storage_settings_file()) {
  dir <- dirname(settings_file)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  tmp <- tempfile("workspace_settings_", tmpdir = dir, fileext = ".rds")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  saveRDS(settings, tmp)
  if (file.exists(settings_file)) {
    unlink(settings_file)
  }
  file.rename(tmp, settings_file)
  storage_normalize_path(settings_file, must_work = TRUE)
}

storage_can_write_dir <- function(path) {
  if (!dir.exists(path)) {
    return(FALSE)
  }
  test <- tempfile("write_check_", tmpdir = path)
  ok <- tryCatch({
    writeLines("ok", test, useBytes = TRUE)
    file.exists(test)
  }, error = function(e) FALSE)
  if (file.exists(test)) {
    unlink(test)
  }
  isTRUE(ok)
}

validate_workspace_root <- function(path, create = FALSE, repo_root = storage_repo_root(), provider = NULL) {
  provider <- provider %||% resolve_storage_provider()
  if (!isTRUE(provider$available)) {
    return(storage_error_result(
      "workspace_unavailable",
      paste("Storage provider is unavailable:", provider$display_name),
      workspace_state = "workspace_unavailable",
      metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)
    ))
  }
  normalized <- storage_normalize_path(path %||% provider$root_path, must_work = FALSE)
  if (is.null(normalized)) {
    return(storage_error_result(
      "workspace_not_configured",
      "Choose a workspace directory before saving artifacts, reports, layouts, or project results.",
      workspace_state = "workspace_unconfigured",
      metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)
    ))
  }
  if (file.exists(normalized) && !dir.exists(normalized)) {
    return(storage_error_result("workspace_path_is_file", "Workspace path points to a file.", workspace_state = "workspace_invalid", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
  }
  if (path_within_root(normalized, repo_root)) {
    return(storage_error_result("workspace_inside_repository", "Workspace cannot be the application repository or a folder inside it.", workspace_state = "workspace_invalid", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
  }
  if (!dir.exists(normalized) && isTRUE(create)) {
    ok <- tryCatch(dir.create(normalized, recursive = TRUE, showWarnings = FALSE), error = function(e) FALSE)
    if (!isTRUE(ok) && !dir.exists(normalized)) {
      return(storage_error_result("workspace_create_failed", "Workspace directory could not be created.", workspace_state = "workspace_error", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
    }
  }
  if (!dir.exists(normalized)) {
    return(storage_error_result("workspace_missing", "Configured workspace directory does not exist.", workspace_state = "workspace_invalid", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
  }
  normalized <- storage_normalize_path(normalized, must_work = TRUE)
  required <- file.path(normalized, c("projects", "temp", "cache", "logs", "settings"))
  if (isTRUE(create)) {
    for (dir in required) {
      if (!dir.exists(dir)) {
        dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      }
    }
  }
  missing_required <- required[!dir.exists(required)]
  if (length(missing_required)) {
    return(storage_error_result("workspace_structure_incomplete", "Workspace subdirectories are missing.", workspace_state = "workspace_invalid", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
  }
  if (!storage_can_write_dir(normalized)) {
    return(storage_error_result("workspace_not_writable", "Workspace directory is not writable.", workspace_state = "workspace_invalid", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
  }
  if (identical(provider$writable, FALSE)) {
    return(storage_error_result("workspace_provider_write_denied", "Storage provider policy does not permit durable writes.", workspace_state = "workspace_invalid", metadata = list(provider_id = provider$provider_id, provider_type = provider$provider_type)))
  }
  provider$root_path <- normalized
  provider$writable <- TRUE
  provider$validation_status <- "workspace_ready"
  service_result(
    status = "success",
    value = list(
      provider = provider,
      provider_id = provider$provider_id,
      provider_type = provider$provider_type,
      provider_display_name = provider$display_name,
      provider_safe_display_label = provider$safe_display_label,
      workspace_root = normalized,
      projects_dir = file.path(normalized, "projects"),
      temp_dir = file.path(normalized, "temp"),
      cache_dir = file.path(normalized, "cache"),
      logs_dir = file.path(normalized, "logs"),
      settings_dir = file.path(normalized, "settings"),
      workspace_state = "workspace_ready"
    ),
    metadata = list(
      workspace_state = "workspace_ready",
      provider_id = provider$provider_id,
      provider_type = provider$provider_type
    )
  )
}

configure_workspace_root <- function(path, settings_file = storage_settings_file(), repo_root = storage_repo_root(), provider_id = "configured_workspace") {
  provider <- resolve_storage_provider(provider_id)
  if (provider$provider_id %in% c("configured_workspace", "local_server_directory", "native_host_directory")) {
    provider$root_path <- path
    provider$available <- TRUE
    provider$selection_supported <- TRUE
    provider$validation_status <- "configuring"
  }
  validation <- validate_workspace_root(path, create = TRUE, repo_root = repo_root, provider = provider)
  if (!identical(validation$status, "success")) {
    return(validation)
  }
  settings <- list(
    workspace_provider_id = validation$value$provider_id,
    workspace_root = validation$value$workspace_root,
    workspace_configured_at = storage_now(),
    workspace_schema_version = storage_schema_version
  )
  settings_path <- write_workspace_settings(settings, settings_file = settings_file)
  validation$value$settings_file <- settings_path
  validation$messages <- paste("Workspace configured:", validation$value$workspace_root)
  validation
}

load_workspace_state <- function(settings_file = storage_settings_file(), repo_root = storage_repo_root()) {
  settings <- read_workspace_settings(settings_file)
  provider <- resolve_storage_provider(settings$workspace_provider_id, settings = settings)
  validation <- validate_workspace_root(settings$workspace_root %||% provider$root_path, create = FALSE, repo_root = repo_root, provider = provider)
  if (!identical(validation$status, "success")) {
    validation$value <- list(
      provider = provider,
      provider_id = provider$provider_id,
      provider_type = provider$provider_type,
      workspace_root = settings$workspace_root %||% NA_character_,
      settings_file = settings_file,
      workspace_state = validation$metadata$workspace_state %||% "workspace_unconfigured"
    )
    return(validation)
  }
  validation$value$settings_file <- settings_file
  validation$value$workspace_schema_version <- settings$workspace_schema_version %||% NA_character_
  validation
}

workspace_path <- function(workspace, ..., create_dir = FALSE) {
  root <- workspace$workspace_root %||% workspace
  root <- storage_normalize_path(root, must_work = TRUE)
  target <- storage_normalize_path(file.path(root, ...), must_work = FALSE)
  if (!path_within_root(target, root)) {
    stop("Resolved workspace path escaped the workspace root.", call. = FALSE)
  }
  if (isTRUE(create_dir) && !dir.exists(target)) {
    dir.create(target, recursive = TRUE, showWarnings = FALSE)
  }
  target
}

new_project_metadata <- function(project_name, project_root, workspace_root = NULL, project_id = NULL, workspace_provider_id = NULL) {
  project_name <- trimws(as.character(project_name %||% "Analytics Project"))
  if (!nzchar(project_name)) {
    project_name <- "Analytics Project"
  }
  project_id <- project_id %||% paste0(safe_path_component(project_name, "project"), "_", format(Sys.time(), "%Y%m%d%H%M%S"))
  project_root <- storage_normalize_path(project_root, must_work = FALSE)
  list(
    project_id = project_id,
    project_name = project_name,
    project_root = project_root,
    workspace_root = workspace_root,
    workspace_provider_id = workspace_provider_id %||% NA_character_,
    project_schema_version = project_schema_version,
    created_at = storage_now(),
    updated_at = storage_now(),
    project_state = "project_ready"
  )
}

project_manifest_path <- function(project_root) {
  file.path(storage_normalize_path(project_root, must_work = FALSE), "project.json")
}

write_project_manifest <- function(project) {
  path <- project_manifest_path(project$project_root)
  json <- paste0(
    "{\n",
    paste(
      sprintf(
        '  "%s": "%s"',
        names(project),
        gsub('"', '\\"', vapply(project, function(x) paste(as.character(x), collapse = ", "), character(1)))
      ),
      collapse = ",\n"
    ),
    "\n}\n"
  )
  writeLines(json, path, useBytes = TRUE)
  path
}

validate_project_root <- function(project_root, workspace = NULL, create = FALSE, repo_root = storage_repo_root()) {
  normalized <- storage_normalize_path(project_root, must_work = FALSE)
  if (is.null(normalized)) {
    return(storage_error_result("project_root_invalid", "Project root is required.", project_state = "project_error"))
  }
  if (file.exists(normalized) && !dir.exists(normalized)) {
    return(storage_error_result("project_root_is_file", "Project root points to a file.", project_state = "project_error"))
  }
  if (path_within_root(normalized, repo_root)) {
    return(storage_error_result("project_inside_repository", "Project root cannot be inside the application repository.", project_state = "project_error"))
  }
  if (isTRUE(create) && !dir.exists(normalized)) {
    dir.create(normalized, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(normalized)) {
    return(storage_error_result("project_root_missing", "Project root does not exist.", project_state = "project_error"))
  }
  normalized <- storage_normalize_path(normalized, must_work = TRUE)
  if (!storage_can_write_dir(normalized)) {
    return(storage_error_result("project_root_not_writable", "Project root is not writable.", project_state = "project_error"))
  }
  service_result(status = "success", value = normalized, metadata = list(project_state = "project_ready"))
}

ensure_project_structure <- function(project_root) {
  dirs <- c("data", "artifacts", "reports", "layouts", "results", "logs", "temp", "collector")
  for (dir in file.path(project_root, dirs)) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    }
  }
  invisible(file.path(project_root, dirs))
}

create_project_in_workspace <- function(workspace, project_name = "Analytics Project", project_id = NULL) {
  validation <- validate_workspace_root(
    workspace$workspace_root %||% workspace,
    create = TRUE,
    provider = workspace$provider %||% NULL
  )
  if (!identical(validation$status, "success")) {
    return(validation)
  }
  workspace <- validation$value
  project_id <- project_id %||% paste0(safe_path_component(project_name, "project"), "_", format(Sys.time(), "%Y%m%d%H%M%S"))
  project_root <- workspace_path(workspace, "projects", project_id)
  root_validation <- validate_project_root(project_root, workspace = workspace, create = TRUE)
  if (!identical(root_validation$status, "success")) {
    return(root_validation)
  }
  project_root <- root_validation$value
  ensure_project_structure(project_root)
  project <- new_project_metadata(
    project_name,
    project_root,
    workspace$workspace_root,
    project_id,
    workspace_provider_id = workspace$provider_id %||% "configured_workspace"
  )
  write_project_manifest(project)
  service_result(status = "success", value = project, messages = paste("Project created:", project$project_name))
}

project_path <- function(project, ..., create_dir = FALSE) {
  if (is.null(project) || !identical(project$project_state %||% "", "project_ready")) {
    stop("No project is open. Current analytical results are temporary and cannot be saved until a project is created or opened.", call. = FALSE)
  }
  root <- storage_normalize_path(project$project_root, must_work = TRUE)
  target <- storage_normalize_path(file.path(root, ...), must_work = FALSE)
  if (!path_within_root(target, root)) {
    stop("Resolved project path escaped the project root.", call. = FALSE)
  }
  if (path_within_root(target, storage_repo_root())) {
    stop("Project path resolves inside the application repository and was blocked.", call. = FALSE)
  }
  if (isTRUE(create_dir) && !dir.exists(target)) {
    dir.create(target, recursive = TRUE, showWarnings = FALSE)
  }
  target
}

project_artifact_path <- function(project, ..., create_dir = FALSE) project_path(project, "artifacts", ..., create_dir = create_dir)
project_report_path <- function(project, ..., create_dir = FALSE) project_path(project, "reports", ..., create_dir = create_dir)
project_layout_path <- function(project, ..., create_dir = FALSE) project_path(project, "layouts", ..., create_dir = create_dir)
project_result_path <- function(project, ..., create_dir = FALSE) project_path(project, "results", ..., create_dir = create_dir)
project_log_path <- function(project, ..., create_dir = FALSE) project_path(project, "logs", ..., create_dir = create_dir)
project_temp_path <- function(project, ..., create_dir = FALSE) project_path(project, "temp", ..., create_dir = create_dir)

session_temp_path <- function(workspace = NULL, ..., create_dir = FALSE) {
  root <- if (!is.null(workspace) && !is.null(workspace$workspace_root) && dir.exists(workspace$workspace_root)) {
    workspace_path(workspace, "temp")
  } else {
    file.path(tempdir(), "AnalyticsWorkstation")
  }
  if (!dir.exists(root)) {
    dir.create(root, recursive = TRUE, showWarnings = FALSE)
  }
  target <- storage_normalize_path(file.path(root, ...), must_work = FALSE)
  if (!path_within_root(target, root)) {
    stop("Resolved session temporary path escaped the session root.", call. = FALSE)
  }
  if (isTRUE(create_dir) && !dir.exists(target)) {
    dir.create(target, recursive = TRUE, showWarnings = FALSE)
  }
  target
}

persistent_write_gate <- function(workspace, project, target, requested_resource_type = "resource") {
  active_provider <- workspace$provider %||% storage_provider(
    provider_id = workspace$provider_id %||% "configured_workspace",
    provider_type = workspace$provider_type %||% "configured_workspace",
    display_name = workspace$provider_display_name %||% "Configured Workspace",
    root_path = workspace$workspace_root %||% NULL,
    available = !is.null(workspace$workspace_root),
    selection_supported = TRUE,
    managed = isTRUE((workspace$provider %||% list())$managed),
    capabilities = (workspace$provider %||% list())$capabilities %||% list(can_choose_directory = TRUE, supports_external_projects = TRUE)
  )
  workspace_validation <- validate_workspace_root(workspace$workspace_root %||% NULL, create = FALSE, provider = active_provider)
  if (!identical(workspace_validation$status, "success")) {
    workspace_validation$metadata$requested_resource_type <- requested_resource_type
    return(workspace_validation)
  }
  if (is.null(project) || !identical(project$project_state %||% "", "project_ready")) {
    return(storage_error_result(
      "project_required",
      "No project is open. Current analytical results are temporary and cannot be saved until a project is created or opened.",
      workspace_state = "workspace_ready",
      project_state = "no_project",
      requested_resource_type = requested_resource_type
    ))
  }
  provider <- workspace_validation$value$provider %||% workspace$provider
  compatibility <- validate_project_provider_compatibility(workspace_validation$value, project, provider = provider)
  if (!identical(compatibility$status, "success")) {
    compatibility$metadata$requested_resource_type <- requested_resource_type
    return(compatibility)
  }
  target <- storage_normalize_path(target, must_work = FALSE)
  project_root <- storage_normalize_path(project$project_root, must_work = TRUE)
  if (!path_within_root(target, project_root)) {
    return(storage_error_result("target_outside_project", "Persistent target is outside the active project.", workspace_state = "workspace_ready", project_state = "project_ready", requested_resource_type = requested_resource_type))
  }
  if (path_within_root(target, storage_repo_root())) {
    return(storage_error_result("target_inside_repository", "Persistent target is inside the application repository.", workspace_state = "workspace_ready", project_state = "project_ready", requested_resource_type = requested_resource_type))
  }
  service_result(
    status = "success",
    value = target,
    metadata = list(
      allowed = TRUE,
      workspace_state = "workspace_ready",
      project_state = "project_ready",
      provider_id = workspace_validation$value$provider_id %||% project$workspace_provider_id %||% NA_character_,
      workspace_provider_id = workspace_validation$value$provider_id %||% NA_character_,
      workspace_provider_type = workspace_validation$value$provider_type %||% NA_character_,
      workspace_is_managed = isTRUE((workspace_validation$value$provider %||% list())$managed),
      provider_capability_version = compatibility$metadata$provider_capability_version %||% NA_character_,
      provider_write_policy = compatibility$metadata$provider_write_policy %||% NA_character_,
      provider_validation_result = compatibility$status,
      project_provider_match = compatibility$metadata$project_provider_match %||% FALSE,
      project_id = project$project_id %||% NA_character_,
      requested_resource_type = requested_resource_type,
      normalized_target = target,
      safe_destination = safe_project_destination_label(workspace_validation$value, project, requested_resource_type),
      persistence_fingerprint = (compatibility$value$persistence_fingerprint %||% list())$fingerprint %||% NA_character_
    )
  )
}

atomic_save_rds <- function(object, path) {
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  tmp <- tempfile("atomic_", tmpdir = dir, fileext = ".rds")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  saveRDS(object, tmp)
  if (file.exists(path)) {
    unlink(path)
  }
  if (!file.rename(tmp, path)) {
    stop("Atomic RDS write failed.", call. = FALSE)
  }
  storage_normalize_path(path, must_work = TRUE)
}

atomic_save_json <- function(object, path, pretty = TRUE) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for JSON persistence.", call. = FALSE)
  }
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  tmp <- tempfile("atomic_", tmpdir = dir, fileext = ".json")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  jsonlite::write_json(object, tmp, auto_unbox = TRUE, null = "null", pretty = pretty)
  if (file.exists(path)) {
    unlink(path)
  }
  if (!file.rename(tmp, path)) {
    stop("Atomic JSON write failed.", call. = FALSE)
  }
  storage_normalize_path(path, must_work = TRUE)
}

storage_file_hash <- function(path) {
  if (!file.exists(path)) {
    return(NA_character_)
  }
  unname(tools::md5sum(path))
}

project_result_bundle_root <- function(project, persisted_result_id = NULL, create_dir = FALSE) {
  if (is.null(persisted_result_id)) {
    return(project_result_path(project, create_dir = create_dir))
  }
  if (!storage_resource_id_is_valid(persisted_result_id)) {
    stop("Persisted result id is malformed.", call. = FALSE)
  }
  project_result_path(project, persisted_result_id, create_dir = create_dir)
}

persisted_result_manifest_path <- function(bundle_dir) {
  file.path(bundle_dir, "manifest.json")
}

read_persisted_result_manifest <- function(path) {
  if (!requireNamespace("jsonlite", quietly = TRUE) || !file.exists(path)) {
    return(NULL)
  }
  tryCatch(jsonlite::read_json(path, simplifyVector = FALSE), error = function(e) NULL)
}

persisted_result_supported_types <- function() {
  c("dataset_profile", "model_assessment_regression", "model_assessment_binary")
}

persisted_result_classify_errors <- function(errors) {
  errors_text <- paste(tolower(errors %||% character()), collapse = " ")
  if (!length(errors %||% character())) return("healthy")
  if (grepl("missing or unreadable manifest|malformed|unreadable manifest", errors_text)) return("invalid_manifest")
  if (grepl("missing fields|manifest missing", errors_text)) return("invalid_manifest")
  if (grepl("not complete", errors_text)) return("incomplete")
  if (grepl("different project", errors_text)) return("project_mismatch")
  if (grepl("hash mismatch", errors_text)) return("hash_mismatch")
  if (grepl("path missing|required file|missing:", errors_text)) return("missing_content")
  if (grepl("unsupported persistence schema", errors_text)) return("unsupported_schema")
  if (grepl("unsupported result type", errors_text)) return("unsupported_result_type")
  "unavailable"
}

validate_persisted_result_bundle <- function(bundle_dir, project = NULL, supported_result_types = persisted_result_supported_types()) {
  manifest_path <- persisted_result_manifest_path(bundle_dir)
  manifest <- read_persisted_result_manifest(manifest_path)
  errors <- character()
  if (is.null(manifest)) {
    errors <- c(errors, "Missing or unreadable manifest.")
  } else {
    required <- c(
      "persisted_result_id", "persistence_schema_version", "result_type", "project_id",
      "status", "relative_resource_paths", "content_hashes", "idempotency_key"
    )
    missing <- setdiff(required, names(manifest))
    if (length(missing)) errors <- c(errors, paste("Manifest missing fields:", paste(missing, collapse = ", ")))
    if (!identical(manifest$status %||% "", "complete")) errors <- c(errors, "Manifest is not complete.")
    if (!identical(manifest$persistence_schema_version %||% "", persistence_schema_version)) {
      errors <- c(errors, paste("Unsupported persistence schema:", manifest$persistence_schema_version %||% "missing"))
    }
    if (!(manifest$result_type %||% "") %in% supported_result_types) {
      errors <- c(errors, paste("Unsupported result type:", manifest$result_type %||% "missing"))
    }
    if (!is.null(project) && !identical(manifest$project_id %||% "", project$project_id %||% "")) {
      errors <- c(errors, "Persisted result belongs to a different project.")
    }
    paths <- manifest$relative_resource_paths %||% list()
    hashes <- manifest$content_hashes %||% list()
    for (name in names(paths)) {
      rel <- paths[[name]]
      if (!is.character(rel) || length(rel) != 1L || grepl("\\.\\.|^[A-Za-z]:|^/|\\\\", rel)) {
        errors <- c(errors, paste("Manifest contains unsafe relative path:", name))
        next
      }
      full <- storage_normalize_path(file.path(bundle_dir, rel), must_work = FALSE)
      if (!path_within_root(full, bundle_dir)) {
        errors <- c(errors, paste("Manifest path escapes bundle:", name))
      } else if (!file.exists(full)) {
        errors <- c(errors, paste("Manifest path missing:", name))
      } else if (!is.null(hashes[[name]]) && !identical(storage_file_hash(full), hashes[[name]])) {
        errors <- c(errors, paste("Manifest hash mismatch:", name))
      }
    }
  }
  health_status <- persisted_result_classify_errors(errors)
  service_result(
    status = if (length(errors)) "error" else "success",
    value = list(bundle_dir = storage_normalize_path(bundle_dir, must_work = FALSE), manifest = manifest),
    errors = errors,
    metadata = list(health_status = health_status)
  )
}

read_persisted_result_resource <- function(bundle_dir, manifest, resource_name) {
  rel <- (manifest$relative_resource_paths %||% list())[[resource_name]]
  if (is.null(rel) || !is.character(rel) || length(rel) != 1L) return(NULL)
  path <- file.path(bundle_dir, rel)
  if (!file.exists(path) || !requireNamespace("jsonlite", quietly = TRUE)) return(NULL)
  tryCatch(jsonlite::read_json(path, simplifyVector = TRUE), error = function(e) NULL)
}

list_project_persisted_results <- function(project, include_invalid = FALSE) {
  root <- project_result_bundle_root(project, create_dir = FALSE)
  if (!dir.exists(root)) {
    return(data.table::data.table())
  }
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  safe_names <- basename(dirs)
  dirs <- dirs[!grepl("^[.]", safe_names) & !grepl("(^|/)[.]staging_", storage_normalize_path(dirs, must_work = FALSE))]
  rows <- lapply(dirs, function(dir) {
    validation <- validate_persisted_result_bundle(dir, project = project)
    if (!identical(validation$status, "success")) {
      if (!isTRUE(include_invalid)) return(NULL)
      manifest <- validation$value$manifest %||% list()
      return(data.table::data.table(
        persisted_result_id = manifest$persisted_result_id %||% basename(dir),
        result_type = manifest$result_type %||% NA_character_,
        display_name = manifest$display_name %||% basename(dir),
        project_id = manifest$project_id %||% NA_character_,
        source_temporary_result_id = manifest$source_temporary_result_id %||% NA_character_,
        source_execution_id = manifest$source_execution_id %||% NA_character_,
        module_id = manifest$module_id %||% NA_character_,
        module_version = manifest$module_version %||% NA_character_,
        mode_id = manifest$mode_id %||% NA_character_,
        dataset_id = manifest$dataset_id %||% NA_character_,
        dataset_version = manifest$dataset_version %||% NA_character_,
        positive_class = manifest$positive_class %||% NA_character_,
        decision_threshold = manifest$decision_threshold %||% NA_real_,
        prediction_scale = manifest$prediction_scale %||% NA_character_,
        created_at = manifest$created_at %||% NA_character_,
        persisted_at = manifest$persisted_at %||% NA_character_,
        health_status = validation$metadata$health_status %||% "unavailable",
        manifest_status = manifest$status %||% "unavailable",
        hash_status = if (identical(validation$metadata$health_status %||% "", "hash_mismatch")) "failed" else "not_validated",
        diagnostic_count = NA_integer_,
        warning_count = NA_integer_,
        table_count = NA_integer_,
        content_size = NA_real_,
        safe_relative_location = file.path("results", basename(dir)),
        validation_errors = paste(validation$errors %||% character(), collapse = "; "),
        bundle_dir = storage_normalize_path(dir, must_work = FALSE),
        manifest_path = persisted_result_manifest_path(dir)
      ))
    }
    manifest <- validation$value$manifest
    content_paths <- unlist(manifest$relative_resource_paths %||% list(), use.names = FALSE)
    content_files <- file.path(dir, content_paths)
    content_size <- sum(file.info(content_files[file.exists(content_files)])$size %||% 0, na.rm = TRUE)
    diagnostics <- read_persisted_result_resource(dir, manifest, "diagnostics")
    warnings <- read_persisted_result_resource(dir, manifest, "warnings")
    data.table::data.table(
      persisted_result_id = manifest$persisted_result_id %||% basename(dir),
      result_type = manifest$result_type %||% NA_character_,
      display_name = manifest$display_name %||% NA_character_,
      project_id = manifest$project_id %||% NA_character_,
      source_temporary_result_id = manifest$source_temporary_result_id %||% NA_character_,
      source_execution_id = manifest$source_execution_id %||% NA_character_,
      module_id = manifest$module_id %||% NA_character_,
      module_version = manifest$module_version %||% NA_character_,
      mode_id = manifest$mode_id %||% NA_character_,
      dataset_id = manifest$dataset_id %||% NA_character_,
      dataset_version = manifest$dataset_version %||% NA_character_,
      positive_class = manifest$positive_class %||% NA_character_,
      decision_threshold = manifest$decision_threshold %||% NA_real_,
      prediction_scale = manifest$prediction_scale %||% NA_character_,
      created_at = manifest$created_at %||% NA_character_,
      persisted_at = manifest$persisted_at %||% NA_character_,
      health_status = "healthy",
      manifest_status = manifest$status %||% "complete",
      hash_status = "validated",
      diagnostic_count = length(diagnostics %||% list()),
      warning_count = length(warnings %||% character()),
      table_count = sum(grepl("^table_", names(manifest$relative_resource_paths %||% list()))),
      content_size = content_size,
      safe_relative_location = file.path("results", manifest$persisted_result_id %||% basename(dir)),
      validation_errors = "",
      bundle_dir = storage_normalize_path(dir, must_work = TRUE),
      manifest_path = persisted_result_manifest_path(dir)
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(data.table::data.table())
  out <- data.table::rbindlist(rows, fill = TRUE)
  if (nrow(out)) data.table::setorder(out, health_status, persisted_at)
  out
}

read_persisted_result_bundle <- function(project, persisted_result_id, table_row_limit = 25L) {
  resolved <- resolve_project_persisted_result(project, persisted_result_id)
  if (!identical(resolved$status, "success")) return(resolved)
  bundle_dir <- resolved$value$bundle_dir
  manifest <- resolved$value$manifest
  paths <- manifest$relative_resource_paths %||% list()
  table_names <- names(paths)[grepl("^table_", names(paths))]
  plot_names <- names(paths)[grepl("^plot_", names(paths))]
  tables <- lapply(table_names, function(name) {
    data <- read_persisted_result_resource(bundle_dir, manifest, name)
    if (is.null(data)) return(NULL)
    dt <- tryCatch(data.table::as.data.table(data), error = function(e) data.table::data.table(value = as.character(data)))
    list(
      table_id = sub("^table_", "", name),
      row_count = nrow(dt),
      column_count = ncol(dt),
      truncated = nrow(dt) > table_row_limit,
      preview = utils::head(dt, table_row_limit)
    )
  })
  names(tables) <- sub("^table_", "", table_names)
  plots <- lapply(plot_names, function(name) {
    spec <- read_persisted_result_resource(bundle_dir, manifest, name)
    if (is.null(spec) || !is.list(spec)) return(NULL)
    spec
  })
  names(plots) <- sub("^plot_", "", plot_names)
  service_result(
    status = "success",
    value = list(
      manifest = manifest,
      bundle_dir = bundle_dir,
      summary = read_persisted_result_resource(bundle_dir, manifest, "summary"),
      metrics = read_persisted_result_resource(bundle_dir, manifest, "metrics"),
      threshold_metrics = read_persisted_result_resource(bundle_dir, manifest, "threshold_metrics"),
      diagnostics = read_persisted_result_resource(bundle_dir, manifest, "diagnostics"),
      warnings = read_persisted_result_resource(bundle_dir, manifest, "warnings"),
      resource_usage = read_persisted_result_resource(bundle_dir, manifest, "resource_usage"),
      tables = Filter(Negate(is.null), tables),
      plots = Filter(Negate(is.null), plots),
      safe_relative_location = file.path("results", manifest$persisted_result_id %||% persisted_result_id)
    )
  )
}

resolve_project_persisted_result <- function(project, persisted_result_id) {
  if (!storage_resource_id_is_valid(persisted_result_id)) {
    return(storage_error_result("persisted_result_id_invalid", "Persisted result id is malformed.", project_state = project$project_state %||% "project_error"))
  }
  bundle <- project_result_bundle_root(project, persisted_result_id, create_dir = FALSE)
  validation <- validate_persisted_result_bundle(bundle, project = project)
  if (!identical(validation$status, "success")) {
    return(storage_error_result("persisted_result_invalid", paste(validation$errors, collapse = " "), project_state = project$project_state %||% "project_error"))
  }
  service_result(status = "success", value = validation$value)
}

qa_workspace_project_storage <- function(output_dir = file.path(tempdir(), "workspace_project_storage_qa")) {
  repo <- storage_repo_root()
  workspace <- file.path(output_dir, "workspace")
  managed_workspace <- file.path(output_dir, "managed_workspace")
  file_workspace <- file.path(output_dir, "workspace_file")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines("not a dir", file_workspace, useBytes = TRUE)

  providers <- storage_provider_registry()
  provider_summary <- storage_provider_summary(providers)
  configured_provider <- resolve_storage_provider("configured_workspace")
  managed_provider <- storage_provider(
    provider_id = "managed_qa",
    provider_type = "managed_workspace",
    display_name = "Managed QA",
    root_path = managed_workspace,
    available = TRUE,
    managed = TRUE,
    capabilities = list(workspace_is_managed = TRUE, supports_external_projects = FALSE)
  )
  local_provider <- storage_provider(
    provider_id = "local_qa",
    provider_type = "local_server_directory",
    display_name = "Local QA",
    root_path = file.path(output_dir, "local_workspace"),
    available = TRUE,
    capabilities = list(can_browse_server_directories = FALSE, can_choose_directory = FALSE, supports_external_projects = TRUE)
  )
  native_provider_no_picker <- storage_provider(
    provider_id = "native_qa",
    provider_type = "native_host_directory",
    display_name = "Native QA",
    root_path = file.path(output_dir, "native_workspace"),
    available = TRUE,
    capabilities = list(native_directory_picker = FALSE, can_choose_directory = FALSE, supports_external_projects = TRUE)
  )
  unavailable_provider <- storage_provider(
    provider_id = "unavailable_qa",
    provider_type = "managed_workspace",
    display_name = "Unavailable QA",
    root_path = file.path(output_dir, "unavailable_workspace"),
    available = FALSE,
    managed = TRUE
  )
  readonly_provider <- storage_provider(
    provider_id = "readonly_qa",
    provider_type = "managed_workspace",
    display_name = "Read Only QA",
    root_path = file.path(output_dir, "readonly_workspace"),
    available = TRUE,
    managed = TRUE,
    writable = FALSE
  )
  native_provider <- resolve_storage_provider("native_host_directory")
  no_workspace <- validate_workspace_root(NULL)
  repo_workspace <- validate_workspace_root(repo)
  file_workspace_result <- validate_workspace_root(file_workspace)
  managed_workspace_result <- validate_workspace_root(managed_workspace, create = TRUE, provider = managed_provider, repo_root = repo)
  local_workspace_result <- validate_workspace_root(local_provider$root_path, create = TRUE, provider = local_provider, repo_root = repo)
  native_workspace_result <- validate_workspace_root(native_provider_no_picker$root_path, create = TRUE, provider = native_provider_no_picker, repo_root = repo)
  unavailable_workspace_result <- validate_workspace_root(unavailable_provider$root_path, create = TRUE, provider = unavailable_provider, repo_root = repo)
  readonly_workspace_result <- validate_workspace_root(readonly_provider$root_path, create = TRUE, provider = readonly_provider, repo_root = repo)
  workspace_result <- configure_workspace_root(workspace, settings_file = file.path(output_dir, "settings.rds"), repo_root = repo, provider_id = "configured_workspace")
  loaded_workspace <- load_workspace_state(settings_file = file.path(output_dir, "settings.rds"), repo_root = repo)
  stale_workspace <- load_workspace_state(settings_file = file.path(output_dir, "missing_settings.rds"), repo_root = repo)
  project_result <- create_project_in_workspace(workspace_result$value, "QA Project", project_id = "qa_project")
  project <- project_result$value
  artifact_path <- project_artifact_path(project, "qa.txt")
  report_path <- project_report_path(project, "qa.html")
  layout_path <- project_layout_path(project, "qa.rds")
  result_path <- project_result_path(project, "qa.rds")
  log_path <- project_log_path(project, "qa.log")
  temp_path <- session_temp_path(workspace_result$value, "session", create_dir = TRUE)
  traversal <- tryCatch(project_artifact_path(project, "..", "..", "escape.txt"), error = function(e) e)
  repo_project <- validate_project_root(file.path(repo, "runtime_project"), create = FALSE, repo_root = repo)
  no_project_gate <- persistent_write_gate(workspace_result$value, NULL, artifact_path, "artifact")
  valid_gate <- persistent_write_gate(workspace_result$value, project, artifact_path, "artifact")
  repo_gate <- persistent_write_gate(workspace_result$value, project, file.path(repo, "bad.txt"), "artifact")
  write_path <- tryCatch(atomic_save_rds(list(ok = TRUE), result_path), error = function(e) NA_character_)
  save_without_project <- tryCatch(
    save_project_state(list(app_version = "qa"), file.path(output_dir, "unsafe_project.rds")),
    error = function(e) e
  )
  managed_project <- create_project_in_workspace(managed_workspace_result$value, "Managed Project", project_id = "managed_project")$value
  managed_gate <- persistent_write_gate(managed_workspace_result$value, managed_project, project_result_path(managed_project, "managed.rds"), "result")
  local_project <- create_project_in_workspace(local_workspace_result$value, "Local Project", project_id = "local_project")$value
  local_gate <- persistent_write_gate(local_workspace_result$value, local_project, project_result_path(local_project, "local.rds"), "result")
  native_project <- create_project_in_workspace(native_workspace_result$value, "Native Project", project_id = "native_project")$value
  native_gate <- persistent_write_gate(native_workspace_result$value, native_project, project_result_path(native_project, "native.rds"), "result")
  unavailable_project <- new_project_metadata("Unavailable Project", file.path(output_dir, "unavailable_project"), workspace_provider_id = "unavailable_qa")
  unavailable_gate <- persistent_write_gate(list(provider = unavailable_provider, workspace_root = unavailable_provider$root_path, workspace_state = "workspace_unavailable"), unavailable_project, file.path(unavailable_project$project_root, "x.rds"), "result")
  readonly_project <- new_project_metadata("Read Only Project", readonly_provider$root_path, workspace_provider_id = "readonly_qa")
  readonly_gate <- persistent_write_gate(list(provider = readonly_provider, workspace_root = readonly_provider$root_path, workspace_state = "workspace_ready"), readonly_project, file.path(readonly_provider$root_path, "x.rds"), "result")
  switch_workspace <- workspace_result$value
  switch_project <- project
  switch_fingerprint_a <- storage_persistence_fingerprint(switch_workspace, switch_project)$fingerprint
  switch_workspace$provider$provider_id <- "native_host_directory"
  switch_workspace$provider_id <- "native_host_directory"
  switch_fingerprint_b <- storage_persistence_fingerprint(switch_workspace, switch_project)$fingerprint
  capability_workspace <- workspace_result$value
  capability_project <- project
  capability_fingerprint_a <- storage_persistence_fingerprint(capability_workspace, capability_project)$fingerprint
  capability_workspace$provider$capabilities$can_open_directory <- TRUE
  capability_fingerprint_b <- storage_persistence_fingerprint(capability_workspace, capability_project)$fingerprint
  mismatch_project <- project
  mismatch_project$workspace_provider_id <- "other_provider"
  mismatch_gate <- persistent_write_gate(workspace_result$value, mismatch_project, project_result_path(project, "mismatch.rds"), "result")
  external_root <- file.path(output_dir, "external_project")
  dir.create(external_root, recursive = TRUE, showWarnings = FALSE)
  external_managed_project <- new_project_metadata("External Managed", external_root, workspace_provider_id = managed_workspace_result$value$provider_id)
  ensure_project_structure(external_root)
  external_managed_gate <- persistent_write_gate(managed_workspace_result$value, external_managed_project, file.path(external_root, "results", "external.rds"), "result")
  external_allowed_project <- new_project_metadata("External Allowed", external_root, workspace_provider_id = workspace_result$value$provider_id)
  external_allowed_gate <- persistent_write_gate(workspace_result$value, external_allowed_project, file.path(external_root, "results", "external_allowed.rds"), "result")

  data.table::data.table(
    check = c(
      "no_workspace_configured",
      "provider_registry_exists",
      "configured_provider_capabilities",
      "managed_provider_ready",
      "native_provider_optional",
      "managed_provider_persistence_no_selection",
      "configured_provider_persistence",
      "local_provider_persistence_without_browse",
      "native_provider_persistence_without_picker",
      "unavailable_provider_blocks_persistence",
      "readonly_provider_blocks_persistence",
      "provider_switch_invalidates_fingerprint",
      "provider_capability_change_invalidates_fingerprint",
      "provider_id_mismatch_blocks_persistence",
      "managed_external_project_rejected",
      "external_project_allowed_when_provider_permits",
      "repository_workspace_rejected",
      "file_workspace_rejected",
      "workspace_configured",
      "stored_settings_load",
      "missing_settings_safe",
      "project_created",
      "artifact_path_inside_project",
      "report_path_inside_project",
      "layout_path_inside_project",
      "result_path_inside_project",
      "log_path_inside_project",
      "session_temp_not_repo",
      "path_traversal_rejected",
      "project_inside_repo_rejected",
      "persistent_write_no_project_blocked",
      "persistent_write_valid",
      "persistent_write_repo_target_blocked",
      "atomic_write_succeeds",
      "save_project_requires_project_context"
    ),
    status = c(
      if (identical(no_workspace$status, "error")) "success" else "error",
      if (nrow(provider_summary) >= 4L && all(c("managed_workspace", "configured_workspace", "local_server_directory", "native_host_directory") %in% provider_summary$provider_id)) "success" else "error",
      if (storage_provider_capability(configured_provider, "can_choose_directory") && storage_provider_capability(configured_provider, "supports_external_projects")) "success" else "error",
      if (identical(managed_workspace_result$status, "success") && isTRUE(managed_workspace_result$value$provider$managed)) "success" else "error",
      if (!isTRUE(native_provider$available) && !isTRUE(storage_provider_capability(native_provider, "native_directory_picker"))) "success" else "error",
      if (identical(managed_gate$status, "success") && !storage_provider_capability(managed_workspace_result$value$provider, "can_choose_directory")) "success" else "error",
      if (identical(valid_gate$status, "success")) "success" else "error",
      if (identical(local_gate$status, "success") && !storage_provider_capability(local_workspace_result$value$provider, "can_browse_server_directories")) "success" else "error",
      if (identical(native_gate$status, "success") && !storage_provider_capability(native_workspace_result$value$provider, "native_directory_picker")) "success" else "error",
      if (identical(unavailable_gate$status, "error")) "success" else "error",
      if (identical(readonly_gate$status, "error")) "success" else "error",
      if (!identical(switch_fingerprint_a, switch_fingerprint_b)) "success" else "error",
      if (!identical(capability_fingerprint_a, capability_fingerprint_b)) "success" else "error",
      if (identical(mismatch_gate$status, "error")) "success" else "error",
      if (identical(external_managed_gate$status, "error")) "success" else "error",
      if (identical(external_allowed_gate$status, "success")) "success" else "error",
      if (identical(repo_workspace$status, "error")) "success" else "error",
      if (identical(file_workspace_result$status, "error")) "success" else "error",
      if (identical(workspace_result$status, "success")) "success" else "error",
      if (identical(loaded_workspace$status, "success")) "success" else "error",
      if (identical(stale_workspace$status, "error")) "success" else "error",
      if (identical(project_result$status, "success") && file.exists(project_manifest_path(project$project_root))) "success" else "error",
      if (path_within_root(artifact_path, project$project_root) && path_outside_root(artifact_path, repo)) "success" else "error",
      if (path_within_root(report_path, project$project_root) && path_outside_root(report_path, repo)) "success" else "error",
      if (path_within_root(layout_path, project$project_root) && path_outside_root(layout_path, repo)) "success" else "error",
      if (path_within_root(result_path, project$project_root) && path_outside_root(result_path, repo)) "success" else "error",
      if (path_within_root(log_path, project$project_root) && path_outside_root(log_path, repo)) "success" else "error",
      if (path_outside_root(temp_path, repo)) "success" else "error",
      if (inherits(traversal, "error")) "success" else "error",
      if (identical(repo_project$status, "error")) "success" else "error",
      if (identical(no_project_gate$status, "error")) "success" else "error",
      if (identical(valid_gate$status, "success")) "success" else "error",
      if (identical(repo_gate$status, "error")) "success" else "error",
      if (!is.na(write_path) && file.exists(write_path)) "success" else "error",
      if (inherits(save_without_project, "error")) "success" else "error"
    ),
    message = c(
      no_workspace$errors %||% no_workspace$messages %||% "",
      paste("Providers:", paste(provider_summary$provider_id, collapse = ", ")),
      paste("Configured capabilities:", paste(names(configured_provider$capabilities)[vapply(configured_provider$capabilities, isTRUE, logical(1))], collapse = ", ")),
      managed_workspace_result$value$workspace_root %||% paste(managed_workspace_result$errors, collapse = " | "),
      "Native host picker is optional and may be unavailable without breaking storage.",
      managed_gate$metadata$safe_destination %||% paste(managed_gate$errors, collapse = " | "),
      valid_gate$metadata$safe_destination %||% paste(valid_gate$errors, collapse = " | "),
      local_gate$metadata$safe_destination %||% paste(local_gate$errors, collapse = " | "),
      native_gate$metadata$safe_destination %||% paste(native_gate$errors, collapse = " | "),
      unavailable_gate$errors %||% "",
      readonly_gate$errors %||% "",
      paste(switch_fingerprint_a, "->", switch_fingerprint_b),
      paste(capability_fingerprint_a, "->", capability_fingerprint_b),
      mismatch_gate$errors %||% "",
      external_managed_gate$errors %||% "",
      external_allowed_gate$metadata$safe_destination %||% "",
      repo_workspace$errors %||% "",
      file_workspace_result$errors %||% "",
      workspace_result$messages %||% "",
      "Workspace settings loaded from user-level settings path.",
      "Missing settings do not fall back to the repository.",
      project_result$messages %||% "",
      artifact_path,
      report_path,
      layout_path,
      result_path,
      log_path,
      temp_path,
      if (inherits(traversal, "error")) conditionMessage(traversal) else "not rejected",
      repo_project$errors %||% "",
      no_project_gate$errors %||% "",
      valid_gate$value %||% "",
      repo_gate$errors %||% "",
      write_path,
      if (inherits(save_without_project, "error")) conditionMessage(save_without_project) else "not blocked"
    )
  )
}
