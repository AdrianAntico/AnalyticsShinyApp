args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2L) {
  stop("Usage: Rscript scripts/refresh_ecosystem_package.R <Rodeo|AutoQuant|AutoPlots|AutoNLS|all> <destination_library>", call. = FALSE)
}

target <- args[[1]]
destination_library <- normalizePath(args[[2]], winslash = "/", mustWork = FALSE)
allowed <- c("Rodeo", "AutoQuant", "AutoPlots", "AutoNLS", "all")

if (!target %in% allowed) {
  stop("Unknown package target. Use Rodeo, AutoQuant, AutoPlots, AutoNLS, or all.", call. = FALSE)
}

if (!dir.exists(destination_library)) {
  dir.create(destination_library, recursive = TRUE, showWarnings = FALSE)
}

source("app.R")

manifest <- app_env$cross_repo_read_manifest()
discovery <- app_env$cross_repo_discover_repositories(manifest, workspace_root = getwd())
package_order <- app_env$cross_repo_local_package_order(discovery)

if (!identical(target, "all")) {
  package_order <- package_order[package_order == target]
}

if (!length(package_order)) {
  stop("No matching package repositories were discovered.", call. = FALSE)
}

build_dir <- file.path(getwd(), "exports", "package_refresh", format(Sys.time(), "%Y%m%d_%H%M%S"))
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)

for (repo_name in package_order) {
  repo <- discovery[[repo_name]]
  cat("Refreshing", repo$name, "from", repo$path, "\n")
  build <- app_env$cross_repo_build_package(repo, build_dir = build_dir)
  cat("Build:", build$status, build$archive, "\n")
  if (!identical(build$status, "success")) {
    cat(paste(build$output, collapse = "\n"), "\n")
    quit(status = 1L)
  }
  install <- app_env$cross_repo_install_built_package(repo, build$archive, temp_lib = destination_library)
  cat("Install:", install$status, "\n")
  cat(paste(install$output, collapse = "\n"), "\n")
  if (!identical(install$status, "success")) {
    quit(status = 1L)
  }
}

cat("Refresh complete. Destination library:", destination_library, "\n")
