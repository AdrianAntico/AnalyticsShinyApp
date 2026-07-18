# run_build_week_demo_data.R

generator_path <- file.path("scripts", "generate_build_week_demo_data.R")
validator_path <- file.path("scripts", "validate_build_week_demo_data.R")
if (!file.exists(generator_path)) generator_path <- "generate_build_week_demo_data.R"
if (!file.exists(validator_path)) validator_path <- "validate_build_week_demo_data.R"

source(generator_path, local = FALSE)
source(validator_path, local = FALSE)

generate_build_week_demo_data(output_dir = "data", seed = 20260717L, write_files = TRUE)
validate_build_week_demo_data(data_path = file.path("data", "build_week_demo.csv"), output_dir = "validation_output")

cat("\nBuild Week synthetic dataset is ready.\n")
cat("Data: data/build_week_demo.csv\n")
cat("Ground truth: data/build_week_demo_ground_truth.csv\n")
cat("Validation: validation_output/build_week_demo_validation.txt\n")
