# Visual Studio Architecture

Analytics Workstation's Visual Studio begins as an extension of Plot Studio, but it is not only a plot form. It introduces a durable visual document that can describe editable visual objects, their renderer boundary, and their evidence context before any richer direct manipulation UI exists.

## Phase 1 Implementation

The current implementation establishes:

- A canonical visual document schema with a versioned contract.
- Stable object IDs for the plot surface: canvas, plot, title, axes, series, legend, interaction, and an evidence note.
- A hierarchical scene model where objects declare parent/child relationships.
- Selected-object state for contextual inspection.
- Object-type schemas that define editable properties and supported renderers.
- A schema-driven inspector contract used by Plot Studio.
- Undoable object mutations for property changes.
- JSON serialization and roundtrip validation.
- Saved-plot metadata that preserves the visual document with the plot artifact.
- A non-plot text object proof so the model is not limited to charts.

## Phase 2 Implementation

The semantic object model is now operational for the supported Plot Studio loop:

- Selecting objects updates the authoritative visual document selection state.
- Inspector edits mutate visual document object properties before rendering.
- Visibility, lock state, ordering, rename, undo, redo, and checkpoints are command-backed document mutations.
- Rendering still flows through the canonical Plot service and AutoPlots path after the visual document compiles into plot configuration.
- Saved and duplicated plots preserve the compiled visual document rather than regenerating unrelated semantic state.
- Invalid locked-object edits surface as user-visible diagnostics instead of silent fallbacks.

The current bridge intentionally keeps mapping and data-grain controls in the existing plot configuration layer. Supported object properties are document-owned; renderer execution remains service-owned.

## Phase 3 Implementation

Visual Studio now proves semantic composition beyond a single plot object:

- The visual document supports top-level composition objects: heading text, plot, evidence callout, explanatory text, source/provenance block, and object groups.
- Objects carry layout metadata for position, size, grid unit, responsive behavior, and z-order.
- Groups can contain heterogeneous child objects without becoming renderer-specific containers.
- The inspector can select and inspect non-plot objects such as callouts, provenance blocks, and groups.
- The `make_explanatory_visual` document mutation turns the current plot into a composed analytical visual by adding narrative and evidence objects around the existing plot.
- The `add_object` and `set_layout` mutations provide the minimal document-editing surface required to prove structured composition.
- Each object type declares a renderer adapter boundary: AutoPlots for the plot, semantic text for narrative blocks, evidence callout for findings, provenance block for sources, and object group for composition.
- Document serialization, reload, validation, and plot-config compilation preserve the composed visual document.

The Phase 3 proof intentionally composes around the canonical Plot service output. It does not duplicate chart generation, bypass AutoPlots, or introduce a freeform canvas renderer.

## Phase 4 Implementation

Visual Studio now includes a governed semantic authoring loop:

- The authoring engine inspects the current visual document and evidence context for missing explanatory components such as interpretation, uncertainty, recommendations, limitations, provenance, and references.
- Authoring produces proposals, not immediate document mutations.
- Each proposal records its timestamp, originating evidence IDs, source artifacts, rationale, confidence, expected user value, object decisions, and rollback metadata.
- Proposed objects carry authoring provenance: originating evidence, source artifacts, generation rationale, confidence, schema version, proposal ID, and creation pathway.
- Users can approve all proposed objects, approve selected objects, reject individual objects, or reject the full proposal.
- Accepted proposals become ordinary visual document state and continue through the existing undo, redo, checkpoint, serialization, and persistence contracts.
- Rejected proposals remain in authoring history so discarded reasoning does not disappear.
- Object adapters expose the contract expected by future authoring surfaces: render, propose, validate, mutate, serialize, deserialize, and inspect.

The Phase 4 proof is deliberately deterministic. It does not call a model, does not execute autonomous edits, and does not invent evidence. It proves the human-approved semantic mutation path that future AI-assisted authoring can use.

## Phase 5 Implementation

Visual Studio now includes governed composition intelligence at the document level:

- A `CompositionReview` contract evaluates the current visual document across evidence coverage, narrative coherence, visual hierarchy, completeness, redundancy, integrity, and accessibility/readability.
- A registry of composition strategies provides bounded alternatives: Minimal Explanation, Executive Narrative, and Evidence-Forward Analysis.
- Strategies are compared dimension-by-dimension rather than collapsed into an opaque score.
- Each strategy produces a semantic mutation plan using the shared operation vocabulary: add, update, remove, move, resize, reorder, group, ungroup, update layout, update provenance, update narrative, and replace.
- Mutation objects preserve evidence links, claim classification, rationale, dependencies, strategy provenance, and schema version.
- Preview branches clone the document and apply selected mutations without changing canonical document state.
- Users can accept a full strategy, accept selected mutations, or reject a strategy while preserving the rejected strategy in history.
- Duplicate and contradiction checks are deterministic review findings, not hidden heuristics.
- Existing visual documents normalize safely into the new composition schema so older saved plots can still load.

The Phase 5 proof remains evidence-bounded. It does not invent new analysis, bypass the Plot service, or add a second rendering path. Composition intelligence changes how a visual document communicates what is already supported by evidence.

## Phase 6 Implementation

Visual Studio now supports governed knowledge synthesis across multiple evidence artifacts:

- An `EvidenceContext` contract collects artifact references, filters, lineage, quality status, findings, recommendations, assumptions, limitations, and explicit contradiction links.
- `KnowledgeClaim` records observation, calculation, inference, interpretation, recommendation, limitation, assumption, hypothesis, open question, conflict, and consensus claims without flattening them into renderer state.
- `SynthesisReview` evaluates strength of evidence, conflicts, evidence gaps, uncertainty, duplicate findings, and provenance integrity.
- Evidence graphs connect artifacts to claims using bounded edge types such as supports, contradicts, depends on, derived from, visualizes, and references.
- Coverage matrices classify claims as well investigated, partially investigated, or not investigated based on supporting and contradicting evidence.
- Four bounded synthesis strategies are available: Consensus, Balanced, Exploratory, and Executive.
- Strategy preview branches clone the visual document and apply semantic objects without mutating canonical document state.
- Strategy acceptance requires supported claims, writes ordinary visual document objects, preserves decisions, and continues through existing serialization and validation.
- Rejected synthesis strategies remain available as governed history rather than disappearing.

The Phase 6 proof remains deterministic and evidence-bounded. It does not introduce autonomous agents, direct AI edits, a second renderer, or an external graph database. Synthesized visual objects still use the existing object adapters and preserve the canonical path from Evidence Artifacts to Evidence Context to VisualDocument to Semantic Composition to Object Adapters to the existing Plot Service and AutoPlots.

## Phase 7 Implementation

Visual Studio now includes governed domain memory downstream of accepted synthesis:

- `DomainMemory` stores reusable project/domain knowledge entries only after human-approved memory operations.
- `KnowledgeEntry` records canonical statements, semantic type, scope, provenance, supporting and contradicting evidence, confidence, uncertainty, usage history, status history, and supersession links.
- `MemoryReview` records the explicit review event that approves or rejects each memory operation.
- Memory status is governed through a transition registry covering provisional, accepted, validated, deprecated, superseded, rejected, contradicted, archived, and restored paths.
- Memory operations are registry-backed: create, review, update, deprecate, supersede, archive, restore, merge, split, reject, and governed usage recording.
- Discovery returns proposals only. It can suggest relevant entries for the current context, but it never mutates memory.
- Drift detection returns findings only for stale evidence, outdated assumptions, superseded knowledge, conflicting accepted entries, unused entries, orphaned entries, confidence drift, and scope violations.
- Revalidation produces a review proposal rather than silently changing entry status.
- Backward compatibility is explicit: older visual documents normalize with an empty domain memory contract.
- Dependency graph links connect claims, evidence, entries, documents, and supersession relationships without introducing an external graph database.

The Phase 7 proof preserves the canonical rendering path. Domain memory may inform future visual authoring proposals, but it does not render, restyle, or mutate charts directly. Accepted knowledge remains inspectable and defensible; hidden AI-owned memory and silent learning remain out of scope.

## Renderer Boundary

The visual document does not render charts directly. Plot rendering remains delegated to the existing Plot service and AutoPlots/echarts4r path. The visual document records renderer intent and editable semantics; renderer services remain responsible for producing the visible widget.

## Current Scope

This phase intentionally does not implement:

- Drag-and-drop editing.
- Freeform canvas layout.
- Full layer tree editing.
- Ungoverned AI-generated design operations.
- A general visual programming system.

Those capabilities can be added later because the core document, object, inspector, mutation, and persistence contracts now exist.

## Invariant

Any future visual editing surface should mutate the visual document first, then let canonical renderers produce the output. The UI should not create hidden renderer-specific state that cannot be serialized, inspected, or defended.
