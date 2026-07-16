# Semantic Interaction Design Phase 6

Industrial Design Phase 6 introduces the governing UX principle for Analytics Workstation:

```text
Maximize semantic cognition.
Minimize syntactic cognition.
```

This is not a call to make the application simpler in the shallow sense. It is a call to spend the user's finite working memory on the analytical problem instead of on operating the product.

The product should consume as little cognitive effort as possible for navigation, configuration, workflow mechanics, locations, labels, state names, and controls. It should preserve as much cognitive effort as possible for questions, evidence, contradictions, tradeoffs, judgment, uncertainty, decisions, and learning.

The working question for this phase is:

```text
Does this consume brainpower because the analysis requires it,
or because the software requires it?
```

Only the first is desirable.

## Relationship to Prior Phases

Industrial Design Phases 1 through 5 transformed Evidence Review from an enterprise dashboard into a coherent Working Context.

The system already has:

- Current Answer as the focal object for Evidence Review.
- Current Decision as the focal object for Decision Management.
- Progressive teaching through What, Why, How, and technical explanation.
- Mentor surfaces framed as clarification rather than primary instruction.
- Stage-aware actions.
- Context transitions to adjacent work.
- First-class contradictions, sufficiency, alternatives, and tradeoffs.

Phase 6 does not add another context or capability. It audits the existing production rooms for unnecessary syntactic cognition.

## Semantic vs Syntax Audit

The deterministic audit lives in:

```r
working_context_semantic_syntax_audit()
```

Each visible element is classified as:

| Classification | Meaning |
| --- | --- |
| Semantic | The element directly helps the user understand evidence, meaning, uncertainty, tradeoff, judgment, or decision. |
| Syntactic | The element mainly helps the user operate the software. |
| Mixed | The element has analytical value but still requires product-operation cognition. |

Representative classification:

| Room | Element | Classification | Reduction opportunity |
| --- | --- | --- | --- |
| Evidence Review | Current Answer | Semantic | Strengthen as the first visual object. |
| Evidence Review | Compile Answer | Semantic | Eventually make automatic when evidence changes, with visible stale state. |
| Evidence Review | Refresh | Syntactic | Hide until evidence source changes or stale state exists. |
| Evidence Review | Technical reason | Mixed | Keep advanced. |
| Decision Management | Current Decision | Semantic | Strengthen as the first visual object. |
| Decision Management | Alternatives | Semantic | Keep first-class. |
| Decision Management | Edit Decision | Mixed | Preserve as adjacent authoring work with return context. |
| Cross-Room | Top navigation | Syntactic | Future geography should reduce tab scanning. |

## Syntax Elimination

For every syntactic interaction, the design question becomes:

- Can this disappear?
- Can this become automatic?
- Can this become contextual?
- Can this become inferred?
- Can this become progressive?
- Can this become a consequence rather than an action?

The important distinction is that necessary control should remain. The goal is not to remove agency. The goal is to remove unnecessary thought about how the software works.

### Immediate Reductions

This phase made small but meaningful visible language reductions:

| Before | After | Reason |
| --- | --- | --- |
| Hallway | Project Health | The user is not trying to visit a hallway; they may need operational status. |
| Decision Workbench | Edit Decision | The user is trying to modify the decision, not reason about a named workbench. |
| Submit Review | Request Review | The action is human governance, not form submission. |
| Diagnostics and Architecture | How This Was Determined | The user wants explanation before architecture. |
| Reasoning and Draft | Recommendation Reasoning | The disclosure now names the work product. |
| Hallway Signals | Project Signals | The signal source matters less than the project meaning. |

These are deliberately small because this phase is reduction, not redesign.

## Cognitive Budget

The rough cognitive budget lives in:

```r
working_context_cognitive_budget()
```

Current estimate:

| Room | Finding things | Understanding software | Understanding evidence | Making judgment |
| --- | ---: | ---: | ---: | ---: |
| Evidence Review | 15 | 20 | 40 | 25 |
| Decision Management | 15 | 18 | 25 | 42 |

These are not measured behavioral data. They are an explicit design estimate to make the goal visible.

The target direction is:

```text
Finding things + understanding software -> down
Understanding evidence + making judgment -> up
```

## Cognitive Leverage

Cognitive leverage means that one unit of user attention should produce more analytical understanding than it costs in operational effort.

High-leverage interactions:

- reveal why an answer is safe or unsafe;
- expose a contradiction that changes judgment;
- compare alternatives in a way that changes the decision;
- preserve uncertainty without making the user hunt for it;
- turn evidence into an explicit next action.

Low-leverage interactions:

- ask the user to remember where a feature lives;
- require a refresh when the system already knows state is stale;
- expose internal architecture before the analytical meaning is clear;
- make the user expand a section only to discover implementation detail;
- require a destination choice when the next semantic move is obvious.

The product should maximize high-leverage interactions and aggressively challenge low-leverage ones.

## Progressive Semantics

The two production rooms should unfold meaning in this order:

```text
Question
-> Current Answer or Current Decision
-> Why
-> Evidence
-> Contradictions or Tradeoffs
-> Decision
-> Learning
```

Progressive disclosure is useful only when it reveals meaning. It becomes syntactic clutter when it exists merely because there is more content.

## Current Answer

Evidence Review should revolve around understanding, not state.

The Current Answer answers:

- What can we safely say?
- Why do we believe it?
- What limits it?
- What happens next?
- How confident are we?

The Current Answer is semantic. Tables, diagnostics, lineage, and technical state are supporting material.

## Current Decision

Decision Management should revolve around judgment, not workflow.

The Current Decision answers:

- What are we currently recommending?
- Which alternatives exist?
- What tradeoffs matter?
- What remains uncertain?
- What governance still blocks action?
- What happens after approval or implementation?

The Current Decision is semantic. Workflow state, valuation records, and decision provenance are supporting material.

## Action Review

Actions deserve direct visibility when they make meaning visible or move a governed state forward.

Keep visible:

- Compile Answer, until safe stale-state automation exists.
- Preview Recommendation, because it reveals the position before commitment.
- Request Review, because governance is a meaningful human action.
- Approve, because authority is a meaningful human action.
- Implement, because it crosses from decision to action.

Challenge:

- Refresh, when stale state can infer it.
- Inspect, when selected claims can open provenance automatically.
- Destination buttons, when the next context can be a consequence of current work.

## Mentor

The mentor becomes semantic, not procedural.

It should explain:

- why evidence is insufficient;
- why a contradiction matters;
- why a recommendation is guarded;
- why governance blocks action;
- what tradeoff deserves attention.

It should not primarily explain:

- where a tab is;
- how to operate the app;
- what a control is called;
- how the implementation is wired.

The room should teach first. The mentor should clarify.

## Cross-Room Comparison

Evidence Review and Decision Management now form a clean semantic sequence:

| Room | Governing question | Focal object | Semantic work |
| --- | --- | --- | --- |
| Evidence Review | What do we know? | Current Answer | Interpret evidence, limits, contradictions, sufficiency. |
| Decision Management | What should we do? | Current Decision | Compare alternatives, tradeoffs, readiness, governance. |

The Working Context Framework appears to generalize when the room changes focal object without changing architectural rules.

## Campaigns

Semantic design campaigns live in:

```r
working_context_semantic_campaigns()
```

Current campaigns:

- Reduce syntax.
- Promote meaning.
- Language cleanup.
- Interaction reduction.
- Current Answer leverage.
- Tradeoff clarity.
- Narrative before tables.
- Understanding-first mentor.

These campaigns should be used when future founder review finds moments where the user is thinking about the product instead of the problem.

## Founder Review

Founder review should capture:

- Where did I think about software?
- Where did I think about analysis?
- Where did I stop thinking about the interface?
- Where did the interface interrupt me?
- Which action felt like a natural consequence?
- Which action felt like operating machinery?
- Which label described the work best?
- Which label exposed implementation?

These prompts are encoded in:

```r
working_context_semantic_founder_review()
```

## Remaining Syntactic Friction

The largest remaining syntactic costs are:

- Top navigation still asks users to choose a place.
- Some transitions remain destination choices rather than consequences of current work.
- Refresh exists as a visible operation.
- Artifact selection and inspection still require mechanics.
- Technical disclosures still exist, though they are mostly hidden.
- Some raw tables still appear once the user asks for depth.

These are not all defects. They are open design pressure points.

## QA

The deterministic QA entry point is:

```r
qa_semantic_interaction_design()
```

It verifies:

- semantic/syntax audit coverage;
- cognitive budget;
- semantic campaigns;
- founder review prompts;
- Evidence Review language reduction;
- Decision Management language reduction;
- mentor framing;
- Product Vision constitution update;
- final assessment coverage.

## Final Assessment

The phase succeeds when the user spends nearly all mental effort answering:

```text
What does this mean?
```

instead of:

```text
How do I operate this?
```

The current product is not fully there. But Evidence Review and Decision Management now spend substantially more attention on reasoning than on operating software.

The strongest remaining obstacle is not layout. It is destination cognition: the product still sometimes asks the user where to go when it should infer the next semantic move from the current answer or decision.

The governing principle should now be treated as constitutional:

```text
Spend the user's brainpower on the problem, not on the product.
```
