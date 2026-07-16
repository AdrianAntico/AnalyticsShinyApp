# Evidence Review Narrative Design Phase 3

Purpose: make Evidence Review read like the evolution of analytical understanding rather than a collection of widgets.

This phase does not add analytical capability, navigation, architecture, or another Working Context. It changes how the existing Evidence Review room tells its story.

## Narrative Audit

| Surface | Narrative Role | Decision |
| --- | --- | --- |
| Decision Frame | Question | Keep as orientation. It tells the user what question is being evaluated. |
| Current Answer | Answer | Elevate as the dominant object. It should state what is currently known before explaining how. |
| Evidence Set | Support | Keep on the left as the bounded material supporting the answer. Empty state now teaches what evidence is. |
| Cross-Artifact Synthesis | Reasoning | Do not auto-compile silently. Before compilation, explain how synthesis turns artifacts into claims, gaps, and prohibited claims. |
| Contradictions | Uncertainty | Keep visible, but when empty explain that absence of contradiction is not proof of certainty. |
| Evidence Sufficiency | Confidence | Keep as supporting evidence for the confidence state, not the headline. |
| Valuation | Decision relevance | Keep as a constraint on whether evidence can support economic recommendation. |
| Supporting Detail | Provenance | Keep secondary. It opens when the user needs to trust or inspect a claim. |
| Current Work and Draft | Action/history | Keep as common depth. Language now emphasizes recommendation preview and saving. |
| Technical Detail / Backstage | Developer | Keep hidden unless explicitly opened. |

## Current Answer Contract

Current Answer must answer, in order:

1. What do we currently believe?
2. How confident should the user be?
3. Why do we believe it?
4. What limits that belief?
5. What should happen next?

It is not a final decision. It is the strongest currently supportable statement under available evidence, contradictions, valuation, sufficiency, and guardrails.

## Narrative States

Evidence Review now supports explicit Current Answer states:

| State | Meaning |
| --- | --- |
| No Answer Yet | Evidence has not yet been compiled into a bounded answer. |
| Insufficient Evidence | The safest answer is that the question remains open. |
| Conflicting Evidence | Evidence can be inspected but should not be strengthened until conflict is scoped. |
| Tentative Answer | Evidence suggests a direction but is not decision-ready. |
| Supported Answer | Current evidence supports a bounded answer. |
| Recommendation Ready | A governed recommendation preview exists but has not been saved. |
| Decision Complete | The recommendation has been saved as project evidence. |

These are comprehension states, not new backend workflow states.

## Empty State Philosophy

Empty states should teach the product philosophy:

- no evidence means no answer;
- no synthesis means understanding has not yet emerged;
- no contradiction means no deterministic conflict has been recorded, not certainty;
- no detail means provenance is available when needed, but not the first thing to read;
- no recommendation preview means saving is premature.

The room should never merely say "No data" when it can explain why the absence matters.

## Language Principles

Prefer human reasoning language:

- "Compile Answer" over "Compile Synthesis" on primary buttons.
- "Preview Recommendation" over "Preview Draft" in the main action dock.
- "Save Recommendation" over "Confirm & Persist".
- "Recommendation Saved" over "persisted_result".
- "Story State" over "Workflow".

Implementation vocabulary remains acceptable in Technical Detail or Backstage.

## Action Story

Every action should visibly advance the story:

| Action | Story Change |
| --- | --- |
| Compile Answer | Current Answer moves from uncompiled to a narrative state. |
| Request Evidence | The current limitation remains visible and the room refuses to fabricate evidence. |
| Preview Recommendation | The room moves from answer interpretation to recommendation preparation. |
| Save Recommendation | The room becomes durable only if persistence succeeds. |
| Inspect Evidence | Supporting Detail explains provenance for a claim. |

## Founder Review

Review the room by asking:

- Did I understand the question?
- Did I understand what we currently believe?
- Did I understand why?
- Did I understand what limits that belief?
- Did I understand what happens next?
- Did empty states teach rather than apologize?
- Did the room feel like understanding was emerging?

## Campaign Seeds

Narrative campaigns to run next:

| Campaign | Purpose | Priority |
| --- | --- | --- |
| Current Answer comparison | Compare state language with populated evidence. | High |
| Empty-state teaching | Test whether first-time users understand why evidence matters. | High |
| Confidence communication | Refine supported/tentative/blocked/conflicted language. | Medium |
| Action evolution | Verify action copy matches user expectation at each state. | Medium |
| Evidence story with real artifacts | Validate the room using a populated project. | High |
| Technical language cleanup | Move remaining implementation terms below progressive disclosure. | Medium |

## Remaining Weaknesses

- Populated evidence is still required to judge whether Current Answer becomes magnetic in real analytical use.
- Evidence tables remain more mechanical than the narrative surfaces.
- The room now teaches better when empty, but the most compelling version will require high-quality real artifacts.
