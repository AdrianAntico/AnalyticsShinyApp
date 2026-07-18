#!/usr/bin/env Rscript

repo_root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  stop("Run scripts/build_pkgdown_site.R from the repository root.", call. = FALSE)
}

if (!requireNamespace("pkgdown", quietly = TRUE)) {
  stop("pkgdown is required to build the public site.", call. = FALSE)
}

pkgdown::build_site()

media_source <- file.path(repo_root, "docs", "media")
site_media <- file.path(repo_root, "pkgdown-site", "docs", "media")

if (dir.exists(media_source)) {
  dir.create(site_media, recursive = TRUE, showWarnings = FALSE)
  media_files <- list.files(media_source, full.names = TRUE, recursive = FALSE)
  if (length(media_files)) {
    file.copy(media_files, site_media, overwrite = TRUE)
  }
}

required <- file.path("pkgdown-site", c(
  "index.html",
  "articles/build-week-demo.html",
  "reference/run_workstation.html",
  "docs/media/hero.png",
  "docs/media/demo.webm"
))

missing <- required[!file.exists(required)]
if (length(missing)) {
  stop(
    "pkgdown build completed, but required public site assets are missing: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

message("pkgdown site is available at pkgdown-site/index.html")
