# Production Workflow Exercise

Phase 17 treats Analytics Workstation as production software rather than as a set of isolated architecture pieces. The goal is not to add architecture. The goal is to exercise a realistic path through the existing platform, remove small debt exposed by use, and keep future maintenance costs down.

## Scope

The production workflow exercise validates the following end-to-end chain:

1. Create a trusted workspace.
2. Create a project.
3. Import a dataset into project storage.
4. Generate standardized artifacts.
5. Append artifacts to the Project Artifact Collector.
6. Write the collector manifest and DOCX.
7. Record a governed action audit event.
8. Create and accept an improvement item.
9. Generate and execute a remediation plan.
10. Verify the Improvement Ledger records the resolved outcome.
11. Exercise an expired-plan failure path.
12. Verify audit, improvement, remediation, and Mission Control source summaries.
13. Verify closing projects reject additional project-path writes.

This is intentionally an integration exercise. It is not a replacement for lower-level QA suites.

## QA Entry Point

`qa_production_workflow_exercise()` lives in `R/cross_system_contracts.R` and is included in `qa_analysis_modules_integration()`.

The QA uses synthetic data and local temporary project storage. It does not require GenAI, Ollama, a browser, AutoQuant, or a user-selected dataset. That keeps the check deterministic while still crossing the important production boundaries.

## Friction Found

- The platform had many focused QA suites but lacked one small deterministic workflow exercise that walked from project creation through collector, audit, improvement, remediation, and ledger visibility.
- User-facing replay snippets still emitted `TODO` comments for intentionally omitted app-side artifact/report-plan conversion. Those were changed to explicit notes so exported code does not look unfinished.
- The technical debt register already documents the remaining temporary-result, compatibility, and future-work limitations. No unexplained debt was discovered that required broad removal.

## Debt Burned Down

- Added a workflow-oriented QA harness for the production path.
- Removed user-visible `TODO` wording from replay code.
- Updated analysis module status documentation to describe the replay-code limitation as intentional.

## Intentional Limitations

- The workflow exercise does not run screenshot-heavy EDA or model workflows. Those remain covered by module-specific QA and should not be pulled into this deterministic production smoke test unless a future defect proves it necessary.
- Compatibility aliases and documented technical debt remain in place where they preserve migration safety.
- This phase does not add autonomous execution, new storage providers, new GenAI actions, or new workflow engines.

## Production-Readiness Principle

Future workflow QA should prefer complete, representative paths over additional narrow checks when the risk is cross-system coordination. If a defect appears only when several systems interact, it belongs in this exercise or a sibling integration QA.
