# Knowledge Compilation Runtime Phase 7

Status: implemented
Date: 2026-07-14

## Scope

Phase 7 adds the first governed Class 3 persistence path for AI-generated drafts.

Only two draft types are persistable:

- confirmed evidence review drafts;
- confirmed campaign seed drafts.

This phase does not implement autonomous execution, approval, evidence mutation, decision mutation, workflow transition, recommendation adoption, campaign execution, review submission, causal estimation, MMM, or optimization.

## Lifecycle

The supported lifecycle is:

```text
AI Evidence Review
-> Validated Draft
-> Deterministic Validation
-> User Preview
-> Explicit Confirmation
-> Existing App Handler
-> Project Mutation
-> Artifact Collector
-> Operator Audit
-> Undo / Archive
```

The lifecycle states are:

- `preview_only`
- `confirmed`
- `persisted`
- `archived`
- `undone`
- `restored`
- `superseded`
- `rejected`
- `expired`

## Persistable Draft Contract

The `persistable_ai_draft` contract records:

- draft id and type;
- originating evidence review session;
- runtime and bundle versions;
- artifact binder and binder hash;
- citations;
- supported actions;
- validation and confirmation status;
- handler and project target;
- creation and confirmation time;
- user, model tier, and qualification;
- audit id;
- undo and archive ids;
- stale dependencies;
- generated-content flag;
- immutable draft content hash.

## Validation Gates

Drafts must pass deterministic validation before persistence:

- action is one of the two Phase 7 Class 3 persistence actions;
- draft type is supported;
- handler is present;
- runtime version is current;
- artifact binder is unchanged;
- draft content hash is unchanged;
- citations resolve to the current evidence binder;
- stale dependencies are absent;
- explicit confirmation is current.

Validation failure blocks persistence and returns a `service_result` error. It does not crash the app.

## Persistence Behavior

Persistence reuses existing app structures:

- evidence review drafts become unsubmitted review draft records in project state;
- campaign seed drafts become draft campaign records with `automatic_execution = FALSE`;
- both produce standard project artifacts;
- collector append uses `project_collector_append_bundle()` when a collector object is available;
- lifecycle state is stored in the project `ai_draft_store`.

Undo, archive, restore, reject, expire, and supersede update draft lifecycle state. They do not delete collector history.

## UI Integration

The AI Runtime page exposes:

- generated / confirmed / persisted / rejected counts;
- validation failure counts;
- undo/archive availability;
- draft lifecycle table;
- audit timeline.

Mission Control surfaces:

- confirmed drafts awaiting persistence;
- persisted drafts;
- rejected, archived, and undone drafts;
- validation, citation, or handler failures.

## QA

`qa_ai_draft_persistence()` verifies:

- draft generation;
- campaign draft generation;
- confirmation preview;
- explicit confirmation;
- unconfirmed persistence rejection;
- runtime, bundle, citation, stale-dependency, and hash validation;
- governed persistence;
- artifact collector append;
- project state mutation;
- undo, archive, restore, and supersede transitions;
- no decision approval;
- no campaign execution;
- no review submission;
- no evidence mutation;
- Class 3 scope limited to the two Phase 7 persistence actions.

`qa_knowledge_compilation_runtime_phase7()` composes Phase 6 QA with the new draft-persistence QA.
