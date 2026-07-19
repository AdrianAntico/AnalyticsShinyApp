#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
script_path <- if (length(file_arg)) {
  sub("^--file=", "", file_arg[[1]])
} else {
  file.path("scripts", "pre_push_release_check.R")
}

repo_root <- normalizePath(file.path(dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE)), ".."), winslash = "/", mustWork = TRUE)
setwd(repo_root)

if (!file.exists("DESCRIPTION")) {
  stop("pre_push_release_check.R must run from the AnalyticsShinyApp repository.", call. = FALSE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

run_command <- function(label, command, args = character(), env = character()) {
  message("\n==> ", label)
  output <- system2(command, args = args, stdout = TRUE, stderr = TRUE, env = env)
  status <- attr(output, "status") %||% 0L
  if (length(output)) {
    cat(paste(output, collapse = "\n"), "\n", sep = "")
  }
  if (!identical(as.integer(status), 0L)) {
    stop(label, " failed with exit code ", status, ".", call. = FALSE)
  }
  invisible(output)
}

find_rscript <- function() {
  rscript <- Sys.which("Rscript")
  if (nzchar(rscript)) {
    return(unname(rscript))
  }

  candidate <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  if (file.exists(candidate)) {
    return(candidate)
  }

  stop("Rscript is not available on PATH and could not be resolved from R.home().", call. = FALSE)
}

configure_pandoc <- function() {
  if (requireNamespace("rmarkdown", quietly = TRUE)) {
    found <- rmarkdown::find_pandoc()
    if (!is.null(found$dir) && nzchar(found$dir) && dir.exists(found$dir)) {
      return(found$dir)
    }
  }

  candidates <- c(
    Sys.getenv("RSTUDIO_PANDOC", unset = NA_character_),
    Sys.getenv("QUARTO_PANDOC", unset = NA_character_),
    "C:/Users/Bizon/AppData/Local/Pandoc",
    "C:/Program Files/Positron/bin/pandoc",
    "C:/Program Files/Positron/resources/app/quarto/bin/tools",
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools"
  )
  candidates <- unique(candidates[!is.na(candidates) & nzchar(candidates)])
  candidates <- candidates[
    file.exists(file.path(candidates, "pandoc.exe")) |
      file.exists(file.path(candidates, "pandoc"))
  ]

  if (length(candidates)) {
    Sys.setenv(RSTUDIO_PANDOC = normalizePath(candidates[[1]], winslash = "/", mustWork = TRUE))
    return(Sys.getenv("RSTUDIO_PANDOC"))
  }

  stop(
    "Pandoc is required for local R CMD check and pkgdown validation. ",
    "Install Pandoc or set RSTUDIO_PANDOC to the folder containing pandoc.exe.",
    call. = FALSE
  )
}

git <- Sys.which("git")
if (!nzchar(git)) {
  stop("git is required for release-steward pre-push validation.", call. = FALSE)
}
rscript <- find_rscript()
pandoc_dir <- configure_pandoc()

message("Analytics Workstation release-steward pre-push validation")
message("Repository: ", repo_root)
message("Rscript: ", rscript)
message("Pandoc: ", pandoc_dir)
message(R.version.string)

status <- run_command("Check repository cleanliness", git, c("status", "--porcelain"))
if (length(status)) {
  stop(
    "Working tree is not clean. Commit, stash, or remove local changes before guarded push.\n",
    paste(status, collapse = "\n"),
    call. = FALSE
  )
}

run_command("git diff --check", git, c("diff", "--check", "HEAD"))
run_command("Install declared and first-party dependencies", rscript, c("scripts/install_app_dependencies.R"))

rcmdcheck_script <- tempfile("analytics_workstation_rcmdcheck_", fileext = ".R")
writeLines(
  c(
    "if (!requireNamespace('rcmdcheck', quietly = TRUE)) {",
    "  install.packages('rcmdcheck', repos = 'https://cloud.r-project.org')",
    "}",
    "rcmdcheck::rcmdcheck(args = '--no-manual', error_on = 'error')"
  ),
  rcmdcheck_script,
  useBytes = TRUE
)
on.exit(unlink(rcmdcheck_script), add = TRUE)

run_command(
  "R CMD check",
  rscript,
  rcmdcheck_script
)
run_command("Deterministic QA", rscript, c("scripts/run_deterministic_qa.R"))
run_command("pkgdown build", rscript, c("scripts/build_pkgdown_site.R"))

status_after <- run_command("Confirm validation left no tracked changes", git, c("status", "--porcelain"))
tracked_dirty <- status_after[!grepl("^\\?\\?", status_after)]
if (length(tracked_dirty)) {
  stop(
    "Validation modified tracked files. Review and commit those changes before pushing.\n",
    paste(tracked_dirty, collapse = "\n"),
    call. = FALSE
  )
}

message("\nRelease-steward pre-push validation passed.")
message("This push is aligned with the current GitHub Actions package and pkgdown gates.")
