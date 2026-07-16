# Evidence Review Production Candidate

Spatial Information Architecture Phase 3 implements the first production-candidate product experience slice.

This is not a shell-wide redesign. It is one room:

```text
Evidence Review / Decision Evaluation
```

The architecture remains unchanged. The experience changes.

## Product Geography

The production candidate follows the hybrid geography:

```text
Front Door
-> Mission Control Hallway
-> Evidence Review Room
-> Evidence Studio
-> Developer Backstage
```

Evidence Review is the reference implementation for the room/studio pattern.

## Experience Hierarchy

The user should experience:

```text
Relationship
-> Decision Frame
-> Current Evidence
-> Current Understanding
-> Current Decision
-> Current Action
-> Progressive Depth
```

The page should not feel like a dashboard of peer panels. It should feel like a focused room where the decision frame orients the user and the current understanding becomes the main work object.

## Room Structure

Evidence Review now uses these zones:

| Zone | Purpose |
| --- | --- |
| Room Header | Shows decision frame, evidence status, blocker, workflow stage, and recommended next action. |
| Evidence Set | Holds the bounded evidence binder and selected evidence object. |
| Evidence Canvas | Dominant center of the room: synthesis, contradictions, sufficiency, and valuation. |
| Current Understanding | First object inside the canvas; summarizes readiness, limitation, recommendation, and contradiction count. |
| Supporting Detail | Shows selected artifact detail and contextual mentor support. |
| Action Dock | Keeps draft/review/persist actions reachable while the room scrolls. |
| Progressive Depth | Separates current work, hallway signals, technical detail, and backstage return paths. |

## Primary Action Placement

Primary actions are no longer placed at the bottom merely because controls appear earlier in source order.

The production candidate uses:

- canvas header actions for evidence-object work;
- sticky action dock for draft and persistence actions;
- contextual disabled/explanatory state through the action summary;
- progressive depth for deeper details.

Canonical action input IDs remain unchanged:

- `inspect_artifact`
- `compile_synthesis`
- `refresh_binder`
- `mark_contradiction_reviewed`
- `request_more_evidence`
- `preview_draft`
- `persist_draft`

This preserves existing observers and mutation paths.

## Guide and AI Philosophy

Guide is no longer treated as a separate destination inside Evidence Review.

The page includes contextual mentor support:

- explain sufficiency;
- summarize binder;
- clarify current evidence;
- support bounded next action reasoning.

Provider configuration, AI Runtime, prompt mechanics, and diagnostics remain backstage. Normal users should experience understanding, not AI infrastructure.

## Mission Control Hallway

Evidence Review links to Mission Control as `Hallway`.

Mission Control remains the place for orientation:

- current work;
- attention;
- changes;
- recommendations;
- entry into rooms.

Evidence Review does not duplicate the full Mission Control dashboard. It receives compact hallway signals through the `Hallway Signals` progressive-depth section.

## Developer Backstage

Developer surfaces remain reachable through contextual return paths and the broader app, but they do not dominate Evidence Review.

Backstage includes:

- AI Runtime;
- Product Experience Lab;
- replay;
- QA;
- generated code;
- provider diagnostics;
- architecture tooling.

## Preserved Canonical Paths

The redesign preserves:

- Working Context contract;
- evidence binder creation;
- artifact inspection;
- synthesis compilation;
- contradiction review;
- sufficiency assessment;
- valuation interpretation;
- ranked next actions;
- draft preview;
- explicit confirmation before persistence;
- artifact registration;
- audit record creation;
- context state persistence;
- related-task transitions.

## Responsive Behavior

Desktop:

- evidence rail, canvas, and inspector appear side by side;
- rail and inspector remain sticky;
- action dock remains sticky.

Medium screens:

- inspector moves below the canvas;
- room facts collapse to two columns.

Small screens:

- all zones stack;
- sticky side panels become static;
- action dock stacks vertically.

## Founder Review Questions

Founder review should answer:

- Does this feel like a room rather than a dashboard?
- Does the Evidence Studio become the visual center?
- Is the current question obvious?
- Is the current evidence obvious?
- Is the current understanding obvious?
- Is the next action obvious?
- Does the page breathe?
- Does contextual guidance help without becoming another panel?
- Does AI disappear into the work?
- What still feels artificial?
- Would future Working Contexts be built from this pattern?

## QA

`qa_evidence_review_production_candidate()` verifies:

- production-candidate marker;
- room header;
- evidence rail/canvas/inspector;
- sticky action dock;
- contextual guide;
- progressive depth;
- canonical action IDs;
- mutation path confirmation and persistence;
- context state preservation;
- responsive CSS;
- developer backstage treatment;
- documentation.

This QA does not judge beauty. Founder review remains necessary for resonance.
