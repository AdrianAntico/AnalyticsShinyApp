args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) sub("^--file=", "", file_arg[[1]]) else "scripts/validate_build_week_demo_data.R"
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
oldwd <- getwd()
on.exit(setwd(oldwd), add = TRUE)
setwd(root)

env <- new.env(parent = globalenv())
source("app.R", local = env)
app <- env$app_env

if (!file.exists(app$build_week_demo_data_path())) {
  app$generate_build_week_demo_data(output_dir = "data", seed = 20260717L, write_files = TRUE)
}

result <- app$validate_build_week_demo_data(app$build_week_demo_dataset(), write_report = TRUE, output_dir = "validation_output")
print(result$value[, c("check", "status", "message"), with = FALSE])
cat(app$service_result_message(result), "\n")
if (!identical(result$status, "success")) {
  quit(status = 1L)
}
