workstation_display_name <- function() {
  "Analytics Workstation"
}

workstation_package_name <- function() {
  "AnalyticsShinyApp"
}

workstation_release_version <- function() {
  "1.0.0-buildweek"
}

workstation_local_app_data <- function() {
  path <- Sys.getenv("LOCALAPPDATA", unset = "")
  if (nzchar(path)) {
    return(normalizePath(path, winslash = "/", mustWork = FALSE))
  }

  normalizePath(file.path(path.expand("~"), "AppData", "Local"), winslash = "/", mustWork = FALSE)
}

workstation_user_data_dir <- function(create = TRUE) {
  path <- file.path(workstation_local_app_data(), "AnalyticsWorkstation")
  if (isTRUE(create)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_program_dir <- function(create = TRUE) {
  path <- file.path(workstation_local_app_data(), "Programs", "Analytics Workstation")
  if (isTRUE(create)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_user_subdir <- function(name, create = TRUE) {
  path <- file.path(workstation_user_data_dir(create = create), name)
  if (isTRUE(create)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_standard_dirs <- function(create = TRUE) {
  dirs <- c("config", "logs", "projects", "exports", "cache", "runtime")
  paths <- stats::setNames(
    vapply(dirs, workstation_user_subdir, create = create, FUN.VALUE = character(1)),
    dirs
  )
  c(
    user_data = workstation_user_data_dir(create = create),
    program = workstation_program_dir(create = create),
    app_source = normalizePath(file.path(workstation_program_dir(create = create), "app-source"), winslash = "/", mustWork = FALSE),
    launcher = normalizePath(file.path(workstation_program_dir(create = create), "Analytics Workstation.cmd"), winslash = "/", mustWork = FALSE),
    paths
  )
}

workstation_start_menu_shortcut <- function() {
  appdata <- Sys.getenv("APPDATA", unset = "")
  if (!nzchar(appdata)) {
    return(NA_character_)
  }

  normalizePath(
    file.path(appdata, "Microsoft", "Windows", "Start Menu", "Programs", "Analytics Workstation.lnk"),
    winslash = "/",
    mustWork = FALSE
  )
}

workstation_desktop_shortcut <- function() {
  user_profile <- Sys.getenv("USERPROFILE", unset = "")
  desktop_root <- if (nzchar(user_profile)) file.path(user_profile, "Desktop") else file.path(path.expand("~"), "Desktop")
  normalizePath(
    file.path(desktop_root, "Analytics Workstation.lnk"),
    winslash = "/",
    mustWork = FALSE
  )
}

workstation_package_resource <- function(...) {
  path <- system.file(..., package = workstation_package_name())
  if (!nzchar(path)) {
    fallback <- file.path(getwd(), "inst", ...)
    if (file.exists(fallback)) {
      return(normalizePath(fallback, winslash = "/", mustWork = FALSE))
    }
    return(NA_character_)
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}
