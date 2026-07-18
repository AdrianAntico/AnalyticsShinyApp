args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/generate_build_week_demo_data.R"
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
oldwd <- getwd()
on.exit(setwd(oldwd), add = TRUE)
setwd(root)

env <- new.env(parent = globalenv())
source("app.R", local = env)
app <- env$app_env

result <- app$generate_build_week_demo_data(output_dir = "data", seed = 20260717L, write_files = TRUE)
cat(sprintf("Generated Build Week mystery dataset: %s rows x %s columns\n", nrow(result$data), ncol(result$data)))
cat("Data: data/build_week_demo.csv\n")
cat("Ground truth: data/build_week_demo_ground_truth.csv\n")
