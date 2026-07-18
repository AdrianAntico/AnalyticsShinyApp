# Final Demo Reliability Checklist

Run this before recording or presenting the Build Week demo.

## Environment

- Start from a fresh R session.
- Use R 4.5.2 for the current validation environment.
- Confirm `source("app.R")` succeeds.
- Confirm the app launches with `shiny::runApp(".")`.
- Confirm no unexpected startup dialogs appear.

## Provider

- For deterministic recording, select `Mock rehearsal`.
- For live GPT-5.6 recording, set `OPENAI_API_KEY`, `ANALYTICS_GENAI_PROVIDER=openai`, and `ANALYTICS_GENAI_MODEL=gpt-5.6`.
- Confirm missing provider setup degrades visibly and does not crash.

## Data

- Confirm `data/build_week_demo.csv` exists.
- Confirm `data/build_week_demo_ground_truth.csv` exists for QA only.
- Regenerate if needed:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts\generate_build_week_demo_data.R
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" scripts\validate_build_week_demo_data.R
```

## Demo Path

- Open `More -> Build Week Demo`.
- Click `Reset`.
- Click `Run Preflight`.
- Confirm every expected preflight check has an intentional status.
- Click `Launch Demo`.
- Confirm the campaign reaches `completed`.
- Click `Why should I believe this?`.
- Confirm claim verification appears.
- Confirm Investigation Integrity Review appears.
- Confirm Decision Readiness appears.
- Open Report Browser.
- Confirm `Agent Campaign` appears.
- Click `Replay`.
- Confirm replay uses recorded state and does not rerun analytics.
- Click `Reset`.
- Run the same path a second time.

## QA Commands

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" -e 'source("app.R"); qa <- app_env$qa_build_week_demo(); print(qa)'
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" -e 'source("app.R"); qa <- app_env$qa_report_browser(); print(qa)'
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" -e 'source("app.R"); qa <- app_env$qa_agent_operation_runtime(); print(qa)'
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" -e 'testthat::test_file("tests/testthat/test-build-week-demo.R")'
git diff --check
```

## Recording Gate

Do not mark a recording as submission-ready unless:

- the first minute clearly communicates the problem and product;
- the demo executes meaningful app behavior;
- the investigation path is understandable without architecture explanation;
- the AI contribution is visible but bounded;
- claim verification is clear;
- integrity review is visible;
- final decision readiness is obvious;
- no developer-only error or diagnostic appears in the recording;
- the unedited recording feels credible.
