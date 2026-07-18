workstation_display_name <- function() {
  "Analytics Workstation"
}

workstation_package_name <- function() {
  "AnalyticsShinyApp"
}

workstation_release_version <- function() {
  release <- get0("APP_RELEASE", ifnotfound = NA_character_, inherits = TRUE)
  if (is.character(release) && length(release) == 1L && !is.na(release) && nzchar(release)) {
    return(release)
  }

  version <- get0("APP_VERSION", ifnotfound = NA_character_, inherits = TRUE)
  if (is.character(version) && length(version) == 1L && !is.na(version) && nzchar(version)) {
    return(version)
  }

  desc <- tryCatch(
    utils::packageDescription(workstation_package_name(), fields = "Version"),
    error = function(e) NA_character_
  )
  if (is.character(desc) && length(desc) == 1L && !is.na(desc) && nzchar(desc)) {
    return(desc)
  }

  "unknown"
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
    launcher = normalizePath(file.path(workstation_program_dir(create = create), "Analytics Workstation.cmd"), winslash = "/", mustWork = FALSE),
    paths
  )
}

workstation_package_path <- function(..., mustWork = FALSE) {
  path <- system.file(..., package = workstation_package_name())
  if (!nzchar(path)) {
    fallback <- file.path(getwd(), "inst", ...)
    if (!file.exists(fallback)) {
      fallback <- file.path(getwd(), ...)
    }
    if (!length(list(...))) {
      fallback <- getwd()
    }
    if (file.exists(fallback) || !isTRUE(mustWork)) {
      return(normalizePath(fallback, winslash = "/", mustWork = FALSE))
    }
    return(NA_character_)
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_resource_path <- function(..., mustWork = FALSE) {
  path <- system.file("app", ..., package = workstation_package_name())
  if (!nzchar(path)) {
    fallback_candidates <- c(
      file.path(getwd(), "inst", "app", ...),
      file.path(getwd(), ...)
    )
    found <- fallback_candidates[file.exists(fallback_candidates)]
    if (length(found)) {
      return(normalizePath(found[[1]], winslash = "/", mustWork = FALSE))
    }
    if (!isTRUE(mustWork)) {
      return(normalizePath(fallback_candidates[[1]], winslash = "/", mustWork = FALSE))
    }
    return(NA_character_)
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_user_path <- function(..., create = TRUE) {
  path <- file.path(workstation_user_data_dir(create = create), ...)
  if (isTRUE(create)) {
    ext <- tools::file_ext(path)
    dir_path <- if (nzchar(ext)) dirname(path) else path
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_runtime_path <- function(..., create = TRUE) {
  path <- file.path(workstation_user_subdir("runtime", create = create), ...)
  if (isTRUE(create)) {
    ext <- tools::file_ext(path)
    dir_path <- if (nzchar(ext)) dirname(path) else path
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

workstation_initialize_user_dirs <- function(create = TRUE) {
  dirs <- workstation_standard_dirs(create = create)
  config_src <- workstation_resource_path("config", mustWork = FALSE)
  config_dest <- dirs[["config"]]
  if (isTRUE(create) && dir.exists(config_src)) {
    for (src in list.files(config_src, full.names = TRUE, all.files = FALSE)) {
      dest <- file.path(config_dest, basename(src))
      if (!file.exists(dest)) {
        if (dir.exists(src)) {
          file.copy(src, dest, recursive = TRUE, overwrite = FALSE, copy.date = TRUE)
        } else {
          file.copy(src, dest, overwrite = FALSE, copy.date = TRUE)
        }
      }
    }
  }
  dirs
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
  path <- workstation_package_path(..., mustWork = FALSE)
  if (!is.na(path) && file.exists(path)) path else NA_character_
}
