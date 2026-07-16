# Evidence Review Industrial Design Phase 4

Purpose: refine the current Evidence Review production candidate through editing, not expansion.

This phase treats Evidence Review as a working room. The goal is not to add capability. The goal is to make the room clearer, calmer, and more useful for sustained evidence review.

## Attention Audit

| Surface | Previous Attention Level | Intended Role | Decision |
| --- | --- | --- | --- |
| Page title and subtitle | High | Orientation | Keep, but do not make it the emotional center. |
| Current Question header | Very high | Decision frame | Demote from hero object to orientation frame. |
| Action dock | Very high | Workflow control | Keep sticky and persistent, but quiet its visual weight. |
| Current Understanding / Current Answer | Medium | Primary working object | Elevate to the emotional and visual center; refine language toward Current Answer. |
| Cross-artifact synthesis tables | High | Evidence detail | Keep visible, but place below the interpretation brief. |
| Evidence rail | Medium | Bounded evidence set | Rename to Evidence Set and keep compact. |
| Inspector | Medium | Supporting detail | Rename to Supporting Detail to avoid property-panel framing. |
| Technical detail | Low | Developer/backstage | Keep progressively disclosed. |
| Backstage paths | Low | Escape hatch | Keep hidden by default. |

## Visual Hierarchy Decision

Evidence Review now follows this attention order:

1. Decision frame.
2. Current answer.
3. Main limitation and recommended interpretation.
4. Evidence details.
5. Governed actions.
6. Technical and backstage detail.

The emotional center is **Current Answer**, not the action dock and not the question header. The question tells the user why they are in the room. The answer brief tells the user what the evidence currently lets them say.

## Action Hierarchy

Primary analytical action:

- Compile Synthesis

Primary governance action:

- Preview Draft
- Confirm & Persist

Contextual evidence actions:

- Inspect Artifact
- Mark Reviewed
- Request Evidence

Contextual mentor actions:

- Explain Sufficiency
- Summarize Binder

This preserves the existing service and mutation paths while clarifying which actions belong to understanding, evidence inspection, governance, and mentorship.

## Refinement Campaigns Applied

| Campaign | Change |
| --- | --- |
| Center the primary object | Added a Current Answer brief above detailed evidence tables. |
| Reduce chrome | Softened the header, action dock, and panel borders. |
| Demote implementation language | Removed the visible Action Class tile from the main header. |
| Improve room language | Renamed Evidence Rail to Evidence Set and Inspector to Supporting Detail. |
| Preserve progressive depth | Kept technical detail and backstage paths collapsed by default. |
| Preserve canonical paths | Kept existing input IDs and service calls unchanged. |

## Rejected Changes

These were intentionally not implemented:

- A new working context.
- Shell-wide navigation changes.
- A new evidence runtime.
- A new artifact model.
- A new AI action layer.
- Compare, Story Builder, or Agentic Lab behavior.
- A full page redesign unrelated to Evidence Review.

## Founder Review Questions

- Does the page now make the current answer obvious within five seconds?
- Does the action dock feel useful without dominating the room?
- Does the side panel feel like supporting evidence rather than a property inspector?
- Does the room feel calmer without becoming empty?
- Is the next governed action visible but not theatrical?
- Is any developer-only language still competing with analytical work?

## Remaining Weaknesses

- Empty-project states still cannot fully demonstrate the intended evidence density.
- The table-heavy sections remain useful but visually plain compared with the understanding brief.
- The best future proof will come from replaying the golden workflow with real artifacts and reviewing attention flow in motion.
