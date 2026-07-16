# Evidence Review Interaction Design Phase 2

Purpose: refine the experience of working inside Evidence Review.

This phase does not introduce a new room, runtime, navigation model, or capability. It focuses on how the existing room responds as a user reviews evidence, compiles an answer, previews a draft, and persists a governed result.

## Interaction Inventory

| Interaction | User Intent | Cognitive Steps | Visual Steps | Physical Steps | Refinement |
| --- | --- | --- | --- | --- | --- |
| Compile Synthesis | Understand what the evidence currently supports | Decide whether evidence has been reviewed, compile answer, inspect gaps | Canvas header, Current Answer, feedback strip | One click | Current Answer and feedback now visibly change. |
| Inspect Artifact | Understand a claim source | Choose evidence, open details, compare to answer | Evidence Set, Supporting Detail | One click after selection | Empty state now teaches when no artifact exists. |
| Mark Reviewed | Record contradiction review | Identify contradiction, mark room-level review, keep evidence visible | Contradictions, feedback strip | One click | Feedback clarifies that evidence is unchanged. |
| Request Evidence | Preserve uncertainty | Notice gap, record evidence need, avoid overclaiming | Current Answer, feedback strip | One click | Feedback states that no evidence is fabricated. |
| Preview Draft | Check governed output before persistence | Read current answer, check sufficiency, preview draft | Action dock, Current Work and Draft | One click | Persist is not the dominant action until preview exists. |
| Confirm & Persist | Create durable project evidence | Confirm draft, persist, verify audit outcome | Action dock, feedback strip, Current Work and Draft | One click after preview | Persist becomes primary only in draft-preview state. |
| Explain Sufficiency | Clarify readiness | Ask mentor, compare answer to evidence | Supporting Detail, feedback strip | One click | Feedback reminds user AI is explanatory, not evidence. |
| Summarize Binder | Clarify evidence set | Ask mentor, compare to binder | Supporting Detail, feedback strip | One click | Feedback reinforces evidence verification. |

## Attention Flow

The intended flow is:

```text
Decision Frame
-> Current Answer
-> Main limitation / recommended interpretation
-> Evidence details
-> Next useful action
-> Feedback
-> Deeper detail only when needed
```

The page should not require the user to hunt for what changed. Every meaningful click now updates either the Current Answer, the feedback strip, Supporting Detail, or the draft/persist action state.

## Current Answer

`Current Understanding` was refined to `Current Answer`.

Rationale:

- A user comes to Evidence Review to know what can currently be said.
- "Understanding" is useful but soft.
- "Current Answer" is stronger, more work-like, and closer to the object being refined.

The Current Answer is not a final answer. It is the best currently supported answer under the evidence, sufficiency, valuation, and guardrail constraints.

## Action Evolution

Actions now follow the work:

| Stage | Primary Visible Action |
| --- | --- |
| Evidence review | Preview Draft, with persistence deferred. |
| Synthesis review | Preview Draft, informed by updated Current Answer. |
| Draft preview | Confirm & Persist becomes primary. |
| Persisted result | Persisted state is shown; review remains available. |

This keeps the existing canonical action IDs while reducing premature workflow transitions.

## Feedback Principle

Every click should answer:

```text
What changed because I clicked?
```

The feedback strip records the latest meaningful interaction in plain language:

- synthesis updated;
- selected evidence opened;
- evidence request recorded;
- mentor explanation returned;
- draft preview created;
- draft persisted.

## Microinteraction Principles

- Hover should reveal affordance without turning the room into animation.
- Focus should make the current work surface feel selected.
- Success and warning states should be visible but restrained.
- Reduced-motion preferences must be respected.
- Motion is allowed only when it clarifies state or attention.

## Founder Review Notes

Review the room by asking:

- Did the first click visibly change the room?
- Did the room tell me what happened?
- Did the next action become more obvious?
- Did persistence wait until preview made it relevant?
- Did mentor output feel like support rather than chat pasted onto the page?
- Did I spend more time thinking about evidence than operating the app?

## Remaining Weaknesses

- With no artifacts loaded, Evidence Review still cannot demonstrate its full five-minute working rhythm.
- The interaction flow is stronger, but populated evidence is needed to judge whether the Current Answer becomes genuinely magnetic.
- Tables remain the weakest craft surface; they are correct but not yet as expressive as the Current Answer.

