# Phase Completion Template

Use this template for every future implementation phase.

## Implementation Summary

- Objective:
- Scope completed:
- Scope explicitly not completed:
- User-visible behavior:
- Internal architecture changes:
- Worker/job changes, if any:
- Schema/recovery changes, if any:
- Improvement ledger changes, if any:
- Remediation plan changes, if any:

## QA Results

| Command | Result | Notes |
| --- | --- | --- |
| `source("app.R")` |  |  |
|  |  |  |

## Known Limitations

Each limitation must reference a registered ID from `config/technical_debt.yml`.

- `[ID]` ...

## Debt and Boundary Review

### New debt introduced

- None, or:
- `[ID]` Title - reason introduced.

### Existing debt resolved

- None, or:
- `[ID]` Title - acceptance evidence and resolved phase.

### Existing debt changed

- None, or:
- `[ID]` Title - what changed and why.

### Intentional constraints added

- None, or:
- `[ID]` Boundary - safety/product rationale.

### Compatibility behavior retained

- None, or:
- `[ID]` Compatibility item - why retained and canonical current behavior.

### Improvement ledger review

- New project-scoped improvement items introduced:
- Existing project-scoped improvement items resolved:
- Items intentionally deferred or accepted as limitations:
- Re-evaluation evidence:

### Remediation plan review

- New governed remediation templates introduced:
- Existing plans created/updated:
- Manual checkpoints introduced:
- Step approval behavior:
- Recovery/restart behavior:

## Recommended Next Phase

- Recommended next work:
- Preconditions:
- Blocking debt IDs:
- Deferred capability IDs:

## Phase Gate Checklist

- [ ] New debt introduced is registered.
- [ ] Existing debt changes are updated.
- [ ] Known limitations reference IDs.
- [ ] Compatibility aliases reference compatibility-debt IDs.
- [ ] Safety boundaries reference intentional-boundary IDs.
- [ ] Schema changes are added to `docs/architecture/schema_version_inventory.md`.
- [ ] Remediation plan changes are documented in `docs/architecture/remediation_plans.md`.
- [ ] `qa_technical_debt_register()` passes.
- [ ] Existing regression QA passes.
