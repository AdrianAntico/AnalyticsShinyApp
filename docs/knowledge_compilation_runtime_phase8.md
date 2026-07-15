# Knowledge Compilation Runtime Phase 8

Status: implemented
Date: 2026-07-14

## Purpose

Phase 8 establishes Mutation Governance as the reusable framework for future AI-operated project mutations.

The runtime no longer treats every new AI persistence capability as a one-off special case. Instead, every proposed project mutation follows:

```text
AI Proposal
-> Mutation Classification
-> Risk Assessment
-> Governance Requirements
-> Validation
-> Confirmation
-> Existing Handler
-> Audit
-> Lifecycle
-> Undo / Archive / Restore / Supersede
```

## Canonical Mutation Taxonomy

The canonical mutation types are:

- read-only
- navigation
- draft creation
- draft persistence
- relationship staging
- relationship persistence
- metadata update
- workflow update
- evidence attachment
- evidence removal
- recommendation change
- decision change
- authority change
- analytical specification
- execution
- deletion
- unknown

Each mutation must classify into exactly one canonical type.

## Risk Model

Mutation risk is determined from deterministic factors:

- reversibility;
- authority impact;
- evidence impact;
- workflow impact;
- project impact;
- epistemic impact;
- organizational impact.

Risk levels are:

- negligible
- low
- moderate
- high
- critical

The model is intentionally conservative. Risk classification does not grant authority; it only determines governance requirements.

## Governance Policy

Governance outcomes include:

- no confirmation;
- user confirmation;
- reviewer acknowledgement;
- independent review;
- approval required;
- authority escalation;
- blocked;
- unsupported.

Execution-class and authority-changing mutations remain blocked in this phase.

## First Governed Class 3 Operations

Phase 8 implements only two new Class 3 mutations:

- Persist confirmed review request draft.
- Persist confirmed evidence-link draft.

Review request persistence creates an unsubmitted review request object. It does not submit a review.

Evidence-link persistence creates a proposed artifact relationship. It does not accept, attach, or promote evidence.

## Relationship Validation

Evidence-link drafts validate:

- source artifact exists;
- target artifact exists;
- source and target are different;
- relationship type is allowlisted;
- duplicate relationship draft is absent;
- citations resolve to known artifacts.

Hallucinated or prohibited relationships are rejected before persistence.

## Lifecycle

Mutation lifecycle states are:

- proposed
- validated
- previewed
- confirmed
- persisted
- rejected
- archived
- undone
- restored
- expired
- superseded

Every mutation retains lifecycle history and audit metadata.

## Audit

Mutation audit records include:

- mutation type;
- classification;
- risk;
- governance;
- validation;
- confirmation;
- handler;
- objects changed;
- artifacts changed;
- workflow and authority impact;
- undo/archive identifiers;
- runtime and bundle versions;
- model and qualification;
- token and latency placeholders.

## Runtime and UI

The operator runtime now includes mutation policy, risk policy, governance policy, confirmation policy, and review policy through deterministic functions.

The AI Runtime page shows mutation counts, pending/persisted/rejected state, risk state, validation failures, lifecycle rows, and audit events.

Mission Control surfaces pending, persisted, rejected, expired, high-risk, validation-failed, and undoable mutations.

## Boundaries

Phase 8 does not implement:

- review submission;
- evidence attachment or removal;
- workflow mutation;
- decision mutation;
- recommendation mutation;
- approval;
- authority changes;
- execution;
- deletion;
- observational estimation;
- optimization;
- MMM;
- autonomous execution.

The AI may prepare, classify, explain, and persist only the supported confirmed drafts through existing app handlers.

## QA

`qa_mutation_governance()` verifies:

- taxonomy uniqueness;
- classification;
- risk;
- governance;
- review request draft generation;
- evidence-link draft generation;
- validation and confirmation gates;
- persistence;
- hallucinated relationship rejection;
- prohibited relationship rejection;
- duplicate relationship rejection;
- undo, archive, restore, and supersede;
- audit retention;
- runtime version;
- Mission Control and AI Runtime data;
- collector append;
- no review submission;
- no evidence attachment;
- Class 3 scope.

`qa_knowledge_compilation_runtime_phase8()` composes Phase 7 QA with mutation governance QA.
