# Contributor Roadmap

This roadmap suggests contribution areas without turning the repository into a bureaucracy.

## Documentation

- Good first issue: fix broken links or stale install language.
- Intermediate issue: add a short "how to validate this area" section to one architecture doc.
- Advanced issue: consolidate duplicate docs around one concept without deleting history.
- Research issue: map which docs should feed future runtime knowledge compilation.

## Bug Fixes

- Good first issue: replace a red Shiny error surface with a clear empty state.
- Intermediate issue: make a failing optional dependency path degrade explicitly.
- Advanced issue: fix a source artifact generator that silently skips output.
- Research issue: classify recurring failure modes across evidence-generation modules.

## UI

- Good first issue: fix spacing, label overlap, or scrollbar styling on one page.
- Intermediate issue: improve a page's first viewport without changing backend contracts.
- Advanced issue: make a complex workflow clearer with progressive disclosure.
- Research issue: compare screenshots before/after using the product experience scorecards.

## Visualization

- Good first issue: add a deterministic plot smoke test.
- Intermediate issue: improve theme consistency for an existing chart family.
- Advanced issue: add an artifact preview path that works in package-installed mode.
- Research issue: evaluate which visual encodings best transfer information to humans and LLMs.

## Package

- Good first issue: improve package documentation for one exported function.
- Intermediate issue: tighten package-resource tests for a new installed asset.
- Advanced issue: reduce `R CMD check` NSE notes without changing behavior.
- Research issue: evaluate cross-platform package launch behavior on macOS/Linux.

## Electron

- Good first issue: improve Electron diagnostics text when Node/npm is missing.
- Intermediate issue: add a startup log check for installed-package launch.
- Advanced issue: harden process ownership so Electron only manages the R process it starts.
- Research issue: design a signed native installer path.

## Testing

- Good first issue: add one regression test for a previously fixed UI error.
- Intermediate issue: convert a source-only test to package namespace testing.
- Advanced issue: add an installed-package integration test for a workflow.
- Research issue: build a stable cross-platform screenshot validation harness.

## Evidence System

- Good first issue: improve wording for an evidence empty state.
- Intermediate issue: add validation for missing evidence references.
- Advanced issue: harden claim-to-evidence traceability in one report family.
- Research issue: compare evidence sufficiency scoring against human review.

## Demo

- Good first issue: clarify a Build Week demo instruction.
- Intermediate issue: improve replay timing or stage labels.
- Advanced issue: make the demo reset path more robust.
- Research issue: design a new deterministic demo world without adding production scope.

## Architecture

- Good first issue: add a small diagram to an existing orientation doc.
- Intermediate issue: document an invariant discovered during a bug fix.
- Advanced issue: remove an obsolete compatibility shim after proving no tests use it.
- Research issue: identify concepts that can be compiled into runtime bundles.

## Build Week vs Later

Build Week scope should focus on reliability, clarity, package installation, demo communication, and contributor trust.

Post Build Week can broaden into cross-platform packaging, richer renderer work, and more analysis adapters.

Long-term research includes evidence routing calibration, information transfer experiments, semantic/caual intelligence expansion, and governed AI operation.

