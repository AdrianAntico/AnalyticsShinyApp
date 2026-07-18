#!/usr/bin/env Rscript

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "app.R")) || !file.exists(file.path(repo_root, "DESCRIPTION"))) {
  stop("Run scripts/install_workstation.R from the AnalyticsShinyApp repository root.", call. = FALSE)
}

source(file.path(repo_root, "R", "utils_paths.R"))
source(file.path(repo_root, "R", "installation_paths.R"))
source(file.path(repo_root, "R", "installation_diagnostics.R"))

paths <- workstation_standard_dirs(create = TRUE)
log_file <- file.path(paths[["logs"]], paste0("install_", timestamp, ".log"))
sink(log_file, append = TRUE, split = TRUE)
message_log <- file(log_file, open = "at")
sink(message_log, type = "message")
on.exit({
  sink(type = "message")
  close(message_log)
  sink()
}, add = TRUE)

message("Analytics Workstation ", workstation_release_version(), " installation started.")
message("Repository: ", repo_root)
message("R: ", R.version.string)
message("Library: ", paste(.libPaths(), collapse = "; "))

source(file.path(repo_root, "scripts", "install_app_dependencies.R"), local = TRUE)

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos = "https://cloud.r-project.org")
}
remotes::install_local(repo_root, dependencies = FALSE, upgrade = "never", quiet = FALSE)

app_source <- paths[["app_source"]]
if (dir.exists(app_source)) {
  unlink(app_source, recursive = TRUE, force = TRUE)
}
dir.create(app_source, recursive = TRUE, showWarnings = FALSE)

copy_items <- c("app.R", "DESCRIPTION", "LICENSE", "README.md", "R", "www", "docs", "data", "inst", "config", "scripts", "tests")
for (item in copy_items) {
  src <- file.path(repo_root, item)
  if (file.exists(src)) {
    invisible(file.copy(src, app_source, recursive = TRUE, copy.date = TRUE, overwrite = TRUE))
  }
}

electron_src <- file.path(repo_root, "inst", "electron")
electron_dest <- file.path(paths[["program"]], "electron")
if (dir.exists(electron_dest)) {
  unlink(electron_dest, recursive = TRUE, force = TRUE)
}
if (dir.exists(electron_src)) {
  dir.create(electron_dest, recursive = TRUE, showWarnings = FALSE)
  invisible(file.copy(list.files(electron_src, full.names = TRUE, all.files = FALSE), electron_dest, recursive = TRUE, overwrite = TRUE))
}

rscript <- workstation_find_rscript()
if (is.na(rscript) || !file.exists(rscript)) {
  stop("Rscript was not found. Install R 4.5.x or add Rscript.exe to PATH.", call. = FALSE)
}
launcher <- paths[["launcher"]]
launcher_lines <- c(
  "@echo off",
  "setlocal",
  paste0("set \"ANALYTICS_WORKSTATION_APP_SOURCE=", app_source, "\""),
  paste0("\"", rscript, "\" \"", file.path(app_source, "scripts", "launch_installed_workstation.R"), "\" \"", app_source, "\""),
  "endlocal"
)
writeLines(launcher_lines, launcher, useBytes = TRUE)

electron_launcher <- file.path(paths[["program"]], "Analytics Workstation Electron.cmd")
electron_lines <- c(
  "@echo off",
  "setlocal",
  paste0("set \"ANALYTICS_WORKSTATION_APP_SOURCE=", app_source, "\""),
  paste0("cd /d \"", electron_dest, "\""),
  "if exist node_modules\\electron\\dist\\electron.exe (",
  "  node_modules\\electron\\dist\\electron.exe .",
  ") else (",
  "  echo Electron dependencies are not installed. Run repair_windows.ps1 or npm install in the electron directory.",
  "  pause",
  ")",
  "endlocal"
)
writeLines(electron_lines, electron_launcher, useBytes = TRUE)

node <- workstation_find_command("node")
npm <- workstation_find_command("npm")
electron_status <- "skipped"
if (!is.na(node) && !is.na(npm) && dir.exists(electron_dest)) {
  old <- getwd()
  setwd(electron_dest)
  on.exit(setwd(old), add = TRUE)
  node_dir <- dirname(node)
  old_path <- Sys.getenv("PATH", unset = "")
  Sys.setenv(PATH = paste(node_dir, old_path, sep = .Platform$path.sep))
  on.exit(Sys.setenv(PATH = old_path), add = TRUE)
  status <- system2(npm, "install", stdout = TRUE, stderr = TRUE)
  message(paste(status, collapse = "\n"))
  electron_status <- if (file.exists(file.path(electron_dest, "node_modules", "electron", "dist", "electron.exe"))) "PASS" else "ATTENTION"
} else {
  message("Node/npm not available; Electron dependency install skipped.")
}

create_shortcut <- function(shortcut_path, target_path) {
  if (!nzchar(Sys.which("powershell"))) {
    return(FALSE)
  }
  dir.create(dirname(shortcut_path), recursive = TRUE, showWarnings = FALSE)
  ps <- sprintf(
    "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%s');$s.TargetPath='%s';$s.WorkingDirectory='%s';$s.Save()",
    gsub("'", "''", shortcut_path),
    gsub("'", "''", target_path),
    gsub("'", "''", dirname(target_path))
  )
  result <- tryCatch(
    system2("powershell", c("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps), stdout = TRUE, stderr = TRUE),
    error = function(e) structure(character(), status = 1L)
  )
  is.null(attr(result, "status")) || identical(attr(result, "status"), 0L)
}

start_shortcut <- workstation_start_menu_shortcut()
desktop_shortcut <- workstation_desktop_shortcut()
invisible(create_shortcut(start_shortcut, launcher))
if ("--desktop" %in% commandArgs(trailingOnly = TRUE)) {
  invisible(create_shortcut(desktop_shortcut, launcher))
}

diagnostics <- AnalyticsShinyApp::workstation_diagnostics(create = TRUE)
validation <- AnalyticsShinyApp::qa_package_distribution()
electron_validation <- AnalyticsShinyApp::qa_electron_distribution()
print(validation)
print(electron_validation)
ok <- all(validation$status == "success")
emit <- function(...) {
  cat(paste0(...), "\n", sep = "")
}

emit("")
emit("=================================================")
emit("")
emit("Analytics Workstation")
emit("Version: ", workstation_release_version())
emit("")
emit(if (requireNamespace("AnalyticsShinyApp", quietly = TRUE)) "\u2713 R package installed" else "x R package not installed")
emit(if (file.exists(file.path(app_source, "app.R"))) "\u2713 Application source installed" else "x Application source missing")
emit(if (electron_status == "PASS") "\u2713 Electron application installed" else "! Electron application needs attention")
emit(if (file.exists(start_shortcut)) "\u2713 Start Menu shortcut created" else "! Start Menu shortcut not found")
emit(if (file.exists(desktop_shortcut)) "\u2713 Desktop shortcut created" else "! Desktop shortcut not created")
emit(if (ok) "\u2713 Validation passed" else "x Validation failed")
emit("")
emit("Launch:")
emit("  Start Menu > Analytics Workstation")
emit("")
emit("Next Steps")
emit("")
emit("1. Launch Analytics Workstation.")
emit("2. Configure your preferred AI provider.")
emit("3. Open the Build Week demonstration.")
emit("4. Run the guided investigation.")
emit("5. Right-click the taskbar icon and choose \"Pin to taskbar\" if desired.")
emit("")
emit("Documentation")
emit("")
emit("README.md")
emit("docs/windows_installation.md")
emit("")
emit("=================================================")
emit("")
emit("Installation status: ", if (ok) "completed." else "completed with issues.")
emit("")
emit("Open the application:")
emit("  Start Menu > Analytics Workstation")
emit("")
emit("Installed application:")
emit("  ", paths[["program"]])
emit("")
emit("Installed launcher:")
emit("  ", launcher)
emit("")
emit("User projects:")
emit("  ", paths[["projects"]])
emit("")
emit("Logs:")
emit("  ", paths[["logs"]])
emit("")
emit("Pin to taskbar:")
emit("  1. Open Analytics Workstation.")
emit("  2. Right-click its taskbar icon.")
emit("  3. Select \"Pin to taskbar.\"")
emit("")
emit("Validation:")
emit("  R package: ", if (requireNamespace("AnalyticsShinyApp", quietly = TRUE)) "PASS" else "FAIL")
emit("  Application resources: ", if (file.exists(file.path(app_source, "app.R"))) "PASS" else "FAIL")
emit("  Electron shell: ", electron_status)
emit("  Distribution QA: ", if (ok) "PASS" else "FAIL")
emit("")
emit("Log:")
emit("  ", log_file)

if (!ok) {
  quit(status = 1L)
}
