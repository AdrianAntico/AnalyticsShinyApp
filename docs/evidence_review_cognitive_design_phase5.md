# Evidence Review Cognitive Design Phase 5

Purpose: make Evidence Review teach itself through work. This phase does not add a new Working Context, analytics capability, routing layer, or navigation model. It refines the Evidence Review room so the user learns what the room means, why it matters, what changed, and what should happen next without leaving the room for documentation.

## Cognitive Load Audit

| Visible object | What the user had to know | What the room should teach | Decision |
| --- | --- | --- | --- |
| Decision frame | That the room is evaluating a specific decision question | The question is orientation, not the answer | Keep, simplify |
| Evidence rail | What counts as evidence | Evidence is what the answer can cite | Keep, teach in empty state |
| Current Answer | Why an answer may not exist yet | The answer matures from no answer to supported answer to durable decision evidence | Elevate |
| Supporting Evidence | What synthesis does | Synthesis turns artifacts into cited claims, gaps, exclusions, and prohibited claims | Rename and keep |
| Contradictions | Why conflict is not merely an error | Contradictions protect the room from overclaiming | Keep visible when relevant |
| Sufficiency | Why the room blocks stronger action | Sufficiency is action-specific; it may permit inspection while blocking a decision draft | Keep, explain |
| Valuation | Why evidence alone is not always enough | Economic inputs connect evidence to alternatives and decision value | Keep, secondary |
| Next useful move | Why the room recommends one action | The recommendation is a bounded work order based on current sufficiency | Keep as prose |
| Draft and persistence | Why preview precedes saving | Preview separates thinking from durable project evidence | Keep, teach through feedback |
| Mentor | When AI helps | AI clarifies when the room's own teaching is not enough | Defer |
| Technical detail | How the system is structured | Technical reasoning is available after the user understands the work | Collapse |

## Self-Teaching Room

The room should answer these questions in place:

- Why is this important?
- Why is this blocked?
- Why is this the next useful move?
- Why can't the room recommend more?
- Why does contradiction matter?
- Why does sufficiency matter?

The answer should not be a tutorial. It should appear as state-specific explanation, empty-state language, and action feedback.

## Progressive Understanding

Evidence Review now exposes understanding in five levels:

1. What: the plain-language state of the answer.
2. Why: why that state matters for decision use.
3. How: how the user should move the work forward.
4. Technical: deterministic reason behind the state.
5. Architecture: backstage context remains collapsed.

This keeps business users oriented while preserving analyst and developer depth.

## Current Answer Maturity

The Current Answer is the evolving story:

- No Answer: evidence has not been compiled or no evidence exists.
- Insufficient Evidence: the room refuses to overclaim.
- Conflicting Evidence: evidence exists but commitment is limited.
- Tentative Answer: the direction is useful but not decision-ready.
- Supported Answer: the room can move toward a governed recommendation.
- Recommendation Ready: a preview exists but has not become durable.
- Decision Complete: the recommendation is saved as project evidence.

Each state carries What, Why, How, and Technical explanation.

## Contextual Explanation Philosophy

Contextual teaching should be:

- short;
- state-specific;
- located next to the work;
- secondary to the Current Answer;
- explicit about uncertainty;
- clear about what changed after an action.

It should not become:

- a help center;
- a large tutorial panel;
- a substitute for evidence;
- a second navigation system;
- a theatrical AI surface.

## Action Feedback

Actions now explain what changed:

- Compile Answer: evidence became claims, gaps, limits, and a bounded next move.
- Refresh Evidence: previous answer cleared because the evidence changed.
- Mark Reviewed: contradiction stays visible so certainty is not overstated.
- Request Evidence: the gap becomes a work order, not permission to overclaim.
- Preview Recommendation: the claim is visible before becoming durable.
- Save Recommendation: the recommendation becomes durable, traceable project evidence.

## Founder Review Questions

- What did I learn naturally?
- What still required thought?
- What still required explanation?
- Where did I feel more capable?
- Where did I feel lost?
- What surprised me?
- Did the room reveal the next idea at the right moment?

## Cognitive Design Campaigns

| Campaign | Purpose | Comparison |
| --- | --- | --- |
| Current Answer learning | Test whether users understand answer maturity without explanation | Before/after founder review |
| Sufficiency explanation | Test whether action-specific sufficiency is understandable | Static table vs teaching strip |
| Contradiction teaching | Test whether conflict feels useful rather than broken | No conflict copy vs contradiction copy |
| Action feedback | Test whether users understand what changed after every click | Status-only vs explanation feedback |
| Empty-state learning | Test whether empty rooms still teach | Generic placeholder vs waiting/why/next |
| Mentor restraint | Test whether AI clarifies without stealing focus | Always-open vs deferred mentor |

## Remaining Weaknesses

- Sufficiency and valuation tables still feel mechanical once expanded.
- The global shell and Guide bubble can still compete with the room.
- Real populated evidence is needed to prove the teaching model under higher cognitive load.
- The technical disclosure is useful but may need better wording after founder review.

## Final Phase 5 Position

Evidence Review is close to a canonical Working Context template. The single remaining refinement before generalizing is to validate the self-teaching behavior against a real populated decision review and decide whether the lower tables should become prose-first summaries.
