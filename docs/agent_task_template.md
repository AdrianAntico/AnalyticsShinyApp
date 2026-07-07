# Codex Task Template

Read docs/architecture_constitution.md and docs/ecosystem_operating_model.md before making changes.

## Task

Describe the concrete outcome.

## Primary Repo

Name the repo that owns the work.

## Secondary Repos

List any repos that may need inspection or follow-up.

## Goal

Explain why this change matters for analytical report artifacts.

## Rules

- Do not add unrelated product features.
- Do not cross repo ownership boundaries.
- Do not modify AutoPlots plotting internals from the app repo.
- Do not create a second code execution system.
- Keep changes small and reviewable.
- Preserve existing contracts unless this task explicitly updates them.

## Context To Read

- `docs/architecture_constitution.md`
- `docs/ecosystem_operating_model.md`
- `docs/repo_contracts.md`
- relevant module/service/report docs
- relevant source files

## Required Work

1. Inspect current implementation.
2. Identify the owning contract.
3. Make the smallest correct change.
4. Add or update targeted QA.
5. Update docs/status/backlog if architecture changed.

## Non-Goals

List what must not be implemented in this task.

## QA

List exact QA helpers or commands to run.

## Documentation

List docs that must be updated.

## Final Response

Summarize:

- files changed
- contract decisions
- QA results
- remaining limitations
- recommended next task
