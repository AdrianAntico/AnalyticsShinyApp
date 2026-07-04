# Analytics Shiny App Smoke Test

Run these checks from the extracted Analytics Shiny App repository, not from the AutoPlots package repository.

## Launch

1. Confirm required packages are installed:

   ```r
   source("R/utils_paths.R")
   check_app_dependencies()
   ```

2. Launch the app from the repository root:

   ```r
   shiny::runApp(".")
   ```

3. Confirm the app starts without sourcing files from the AutoPlots repository.

## Manual App Flow

Use `inst/sample_data/app_qa_transactional.csv`.

1. Upload the sample CSV.
2. Build a `Line` plot:
   - `XVar`: `Date`
   - `YVar`: `Revenue`
   - optional `GroupVar`: `Channel`
3. Add the plot as `p1`.
4. Build a `Bar` plot:
   - `XVar`: `Category`
   - `YVar`: `Spend`
   - optional `GroupVar`: `Channel`
5. Add the plot as `p2`.
6. Preview a `Grid` layout and confirm both plots render.
7. Assign plots to sections and preview a `Sections` layout.
8. Export HTML.
9. Export R code.
10. Save a project `.rds`.
11. Load the saved project `.rds`.
12. Save a project bundle.
13. Load the saved project bundle.

## Pass Criteria

- The app launches from this repository root.
- `AutoPlots` loads as an installed package via `library(AutoPlots)`.
- No production app code calls `devtools::load_all("../AutoPlots")`.
- No production app code sources internal AutoPlots files such as `PlotFunctions_NEW.R`.
- Plot preview, grid preview, and section preview work with the sample data.
- HTML export, R code export, project save/load, and bundle save/load write to paths selected in the app.
- If `AutoPlots::save_widget()` is unavailable, HTML export may create an asset directory beside the HTML file.
- Browser Shiny failures are fixed in this repository.
- Electron-only failures are fixed in the separate Electron wrapper repository.
