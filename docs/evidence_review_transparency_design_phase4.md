# Evidence Review Industrial Design Phase 4

Purpose: reduce cognitive friction until Evidence Review feels less like an interface and more like a transparent reasoning surface.

This phase does not add analytical capability, navigation, architecture, or a new Working Context. It asks every visible object to justify its attention cost.

## Transparency Philosophy

The room should be remembered for the analytical story:

Question -> Current Answer -> Evidence -> Reasoning -> Next Action -> Future Learning

The user should not remember decorative borders, repeated labels, configuration controls, implementation terms, or operational scaffolding. When a surface exists primarily because the software needs it, not because the analyst needs it, it should be reduced, merged, or moved below progressive disclosure.

## Product Disappearance

This is the product disappearance test: the product succeeds when the user remembers the reasoning more than the interface.

## Transparency Audit

| Object | Classification | Why It Exists | Decision |
| --- | --- | --- | --- |
| Page title | Contextual | Locates the room. | Keep, but label as Evidence Room rather than architecture. |
| Navigation actions | Contextual | Provide escape routes to related surfaces. | Keep unchanged functionally; do not expand. |
| Breadcrumb path | Historical | Explained product geography. | Remove from the visible header; it made the room feel like a diagram. |
| Status badge | Helpful | Shows whether evidence can support action. | Keep small. |
| Business question | Essential | Establishes the analytical frame. | Keep. |
| Recommended next action | Helpful | Prevents dead ends. | Keep, but subordinate to Current Answer. |
| Binder id | Developer | Useful for traceability, not normal reasoning. | Remove from prominent summary. Keep in deeper state if needed. |
| Evidence facts | Helpful | Summarize evidence, blocker, answer state. | Replace heavy stat tiles with quiet facts. |
| Action selector | Configuration | Only needed when there are real alternatives. | Collapse to plain text when only one next move exists. |
| Preview action before answer | Redundant | Invited operation before understanding. | Hide until the answer is compiled. |
| Evidence rail | Essential | Shows what can be cited. | Rename to Evidence and quiet its chrome. |
| Current Answer | Essential | The room's primary object. | Make more editorial and dominant. |
| Cross-artifact synthesis | Helpful | Explains claim construction. | Keep as reasoning below the answer. |
| Contradictions | Helpful | Prevents overclaiming. | Keep, but continue treating empty state as teaching. |
| Sufficiency and valuation | Helpful | Explain confidence and decision relevance. | Keep as supporting reasoning, not headline objects. |
| Detail inspector | Contextual | Used when provenance is needed. | Rename to Detail and keep secondary. |
| Contextual mentor | Contextual | Helps when uncertainty or explanation is needed. | Collapse behind a disclosure by default. |
| Technical detail/backstage | Developer | Supports traceability and QA. | Keep hidden. |

## Friction Audit

| Interaction | Classification | Decision |
| --- | --- | --- |
| Compile Answer | Reasoning | Keep prominent. It turns evidence into an answer. |
| Preview Recommendation | Confirmation | Defer until an answer exists. |
| Save Recommendation | Confirmation | Keep visible only after preview exists. |
| Next move selection | Configuration | Hide when there is only one meaningful move. |
| Inspect evidence | Thinking | Keep in Evidence rail. |
| Refresh evidence | Maintenance | Quiet as secondary. |
| Mark reviewed | Maintenance | Quiet as secondary. |
| Request evidence | Reasoning | Keep available but quiet. |
| Mentor explanation | Thinking | Collapse until requested. |
| Technical/backstage review | Developer | Keep behind progressive disclosure. |

## Changes Made

- Removed visible product-geography breadcrumb from the room header.
- Removed binder id from the prominent Evidence Status tile.
- Replaced heavy stat tiles with quieter facts.
- Collapsed the next-action select input into text when only one next move exists.
- Hid recommendation preview until an answer has been compiled.
- Renamed Evidence Set to Evidence.
- Renamed Supporting Detail to Detail.
- Collapsed the contextual mentor by default.
- Reduced border contrast, shadows, and panel chrome.
- Increased Current Answer typography so it reads more like an editorial answer than a widget.
- Kept canonical server actions and mutation paths unchanged.

## Founder Review Questions

- Did I remember the reasoning more than the interface?
- Did any object demand attention before it earned it?
- Did I hesitate because of the software rather than because of the analysis?
- Did Current Answer feel like the center of the room?
- Did the room become quieter without becoming vague?
- Did the empty state teach purpose without overexplaining?

## Transparency Campaigns

| Campaign | Purpose | Priority |
| --- | --- | --- |
| Border removal | Compare current subdued chrome against a nearly borderless version. | High |
| Populated evidence transparency | Validate whether the same hierarchy holds with real artifacts. | High |
| Action disappearance | Find the next action that can become contextual or implicit. | Medium |
| Mentor timing | Determine when mentor affordances should appear automatically. | Medium |
| Header compression | Reduce vertical space before Current Answer, especially on narrow screens. | High |
| Table quieting | Make reasoning tables support the story instead of competing with it. | Medium |

## Remaining Friction

- The page shell and navigation still occupy meaningful vertical attention before the room begins.
- Empty evidence is now clearer, but populated evidence is required to test real cognitive transparency.
- The lower reasoning tables still feel more mechanical than the Current Answer.
- The global Guide bubble can visually compete with the answer in some viewport positions.
