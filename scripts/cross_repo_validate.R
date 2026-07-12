args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args) >= 1L && nzchar(args[[1]])) args[[1]] else "fast"
install_packages <- any(args %in% c("--install-packages", "--install"))

if (!mode %in% c("fast", "standard", "full")) {
  stop("Usage: Rscript scripts/cross_repo_validate.R [fast|standard|full] [--install-packages]", call. = FALSE)
}

source("app.R")

result <- app_env$cross_repo_validate(
  mode = mode,
  install_packages = install_packages
)

cat("Cross-repo validation status:", result$status, "\n")
cat("Mode:", result$mode, "\n")
cat("Output:", result$output_dir, "\n")

if (identical(result$status, "error")) {
  quit(status = 1L)
}
