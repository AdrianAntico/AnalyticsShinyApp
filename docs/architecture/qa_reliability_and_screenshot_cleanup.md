# QA Reliability and Screenshot Cleanup

Phase 18 hardens QA signal quality around screenshot-heavy workflows. The goal is to make QA output easier to trust without changing the production rendering engine.

## Browser Dependency

Screenshot generation uses the production helper `AutoQuant::ObjectToPNG`. That helper uses the existing HTML widget screenshot stack and may rely on Chromote/webshot2 and a local browser.

The app does not introduce a second screenshot engine. QA should fail when the production helper cannot create a valid screenshot unless the tested collector behavior is explicitly graceful degradation.

## Chromote Close Timeout Classification

Observed signature:

```text
Unhandled promise error: Chromote: timed out waiting for response to command Browser.close
```

Root cause classification:

- Screenshots and collector DOCX files were already written successfully.
- The message occurred during teardown, after successful artifact creation.
- The collector cleanup path called the default Chromote object with a blocking close request.
- On this Windows/Chromote combination, waiting for the browser to acknowledge `Browser.close` can time out even when the primary screenshot work succeeded.

Resolution:

- Collector cleanup now requests browser close with `wait_ = FALSE`.
- Cleanup status is captured separately in `metadata$screenshot_cleanup`.
- Cleanup warnings do not overwrite the primary screenshot or collector result.
- Real screenshot creation errors are still captured in `metadata$screenshot_index` and surface as warnings or QA failures depending on the test.

## Screenshot Validation

Screenshot success now requires more than no exception. The collector validates:

- file exists
- file is non-empty
- file extension is `.png`
- PNG can be read by `png::readPNG()`
- image dimensions are plausible

The screenshot index records:

- status
- file
- helper
- render target
- HTML staging path when available
- self-contained flag when available
- requested width/height
- actual image width/height
- file size

## Cleanup Guarantees

`project_collector_write()` restores screenshot-related options with `on.exit()`.

The browser cleanup path is also guarded with `on.exit()`, and normal returns explicitly run cleanup before returning service metadata. Unexpected errors still trigger cleanup, though those unexpected paths may not be able to include cleanup metadata in the returned object.

## QA Coverage

`qa_screenshot_pipeline_reliability()` validates:

- successful screenshots are readable PNGs
- successful screenshots record dimensions and file size
- missing PNG files are detected
- empty PNG files are detected
- corrupt PNG files are detected
- screenshot generation failures are recorded per artifact
- collector writing degrades gracefully when a plot screenshot fails
- cleanup status is classified separately
- cleanup warnings cannot overwrite the primary write status

`qa_production_workflow_exercise()` now also verifies:

- collector table sidecars exist and are non-empty
- exact improvement item outcome counts
- exact remediation terminal statuses through the plan table
- event histories meet expected minimum counts

## Signal Interpretation

Use these distinctions when reading QA output:

- `success`: product behavior or infrastructure behavior matched the contract.
- `warning`: expected compatibility or non-fatal product limitation.
- `cleanup_warning`: browser teardown concern after the primary task completed. This is not equivalent to a product failure.
- `error`: product behavior, artifact generation, storage, schema, or primary infrastructure behavior violated the contract.

Known tolerated cleanup behavior must be documented with its exact signature and rationale. Broad warning suppression is not allowed.

## Remaining Limitations

Screenshot-heavy QA still prints successful screenshot paths from the underlying helper. These messages are noisy but useful enough to retain because they identify the actual staged HTML files. They are not treated as warnings or failures.

No pixel-level comparisons are performed. This is intentional. QA validates file existence, format, and plausible dimensions; visual quality remains covered by manual visual QA and targeted plot-sizing work.
