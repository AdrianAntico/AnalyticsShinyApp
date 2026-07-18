# Contributing to Analytics Workstation

Thanks for helping make Analytics Workstation more trustworthy, reproducible, and useful.

## Start Here

Read these first:

1. `README.md`
2. `docs/architecture_orientation.md`
3. `docs/development_principles.md`
4. `docs/contributor_roadmap.md`

## Local Setup

Use R 4.5.x when possible.

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts/install_app_dependencies.R
```

Then launch either from source:

```r
shiny::runApp(".")
```

or from the installed package:

```r
install.packages("release/AnalyticsShinyApp_1.0.0.tar.gz", repos = NULL, type = "source")
library(AnalyticsShinyApp)
run_workstation()
```

## Development Rules

- Do not add analytical features as part of cleanup PRs.
- Keep deterministic computation separate from GenAI synthesis.
- Use package/resource path helpers instead of hard-coded local paths.
- Keep mutable runtime state outside the installed package.
- Prefer small, testable changes over broad rewrites.
- Make unsupported capabilities degrade explicitly instead of failing silently.

## Validation Before Pull Request

Run the checks that match your change:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" -e 'source("app.R"); q <- app_env$qa_package_distribution(); print(q); stopifnot(all(q$status %in% c("success","warning")))'
& "C:\Program Files\R\R-4.5.2\bin\R.exe" CMD build .
& "C:\Program Files\R\R-4.5.2\bin\R.exe" CMD check --no-manual AnalyticsShinyApp_1.0.0.tar.gz
git diff --check
```

For focused work, also run the relevant `testthat` file under `tests/testthat/`.

## Pull Request Checklist

- Explain the user or contributor problem.
- List the files changed.
- Include validation output.
- Note any remaining limitation honestly.
- Include screenshots for UI changes.
- Do not include generated runtime files, local projects, secrets, or bulky recordings.
