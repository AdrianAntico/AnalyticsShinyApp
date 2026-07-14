# Knowledge Compilation Runtime Phase 4

Phase 4 makes the AI Runtime artifact-centered and progressively retrieval-oriented.

The runtime now favors:

```text
Question
-> Task router
-> Minimal runtime bundle
-> Minimal artifact digest
-> Reason
-> Retrieve more if needed
-> Validated response
```

instead of sending broad project-wide context by default.

## Artifact Runtime

The artifact runtime discovers artifacts from the project context, explicit artifact lists, or collector bundles. Discovery records:

- artifact id
- artifact type
- owner
- run id
- status
- freshness
- dependencies
- permissions
- summary availability
- runtime digest availability
- relationships
- token estimate

Discovery is deterministic and read-only.

## Digest Compiler

`compile_artifact_digest()` creates compact, task-aware artifact digests. Digests preserve:

- artifact ids
- artifact type
- title
- owner
- status
- question/objective when available
- recommendations
- uncertainty
- next action
- artifact references
- finding ids
- quality gates
- claim ids
- lineage
- source
- confidence
- limitations

The digest is cached by runtime version, artifact identity, update stamp, digest type, and task.

## Progressive Retrieval

The runtime supports validated retrieval requests such as:

- `need_findings`
- `need_lineage`
- `need_contradictory_evidence`
- `need_quality_gates`
- `need_valuation`
- `need_causal_evidence`
- `need_workflow`
- `need_review`
- `need_outcome`
- `need_memory`
- `need_related_artifact`
- `need_source`
- `need_authority`
- `need_context_expansion`

The LLM does not retrieve directly. It emits a retrieval request; the deterministic runtime validates the request, chooses the permitted layer, retrieves a digest, records token growth, and updates context.

Unsupported or mutating requests are rejected.

## Context Sufficiency

The runtime evaluates sufficiency using canonical states:

- `sufficient`
- `probably_sufficient`
- `needs_finding`
- `needs_workflow`
- `needs_evidence`
- `needs_valuation`
- `needs_causal`
- `needs_review`
- `needs_contradiction`
- `needs_human`

This prevents the model from silently deciding that insufficient context is enough.

## Read-Only Navigation

Artifact navigation supports read-only open/inspect actions:

- related artifact
- parent
- child
- evidence
- decision
- workflow
- valuation
- finding
- contradiction
- review
- campaign

Navigation validation returns handler-ready references and never mutates artifacts.

## Diagnostics

Retrieval diagnostics record:

- initial context tokens
- retrieval requests
- granted retrievals
- denied retrievals
- token increase
- retrieval depth
- retrieval chain
- final context tokens
- sufficiency state
- final context hash

The AI Runtime page displays these diagnostics.

## Benchmarking

`run_artifact_retrieval_benchmark()` compares progressive retrieval against retrieve-everything for token growth, retrieval count, task quality placeholder, latency placeholder, and correction-rate placeholder.

The purpose is empirical: progressive retrieval should win often, but the runtime measures rather than assumes.

## Boundaries

Phase 4 does not introduce:

- artifact mutation
- automatic editing
- workflow transitions
- approvals
- execution
- vector search
- semantic search
- autonomous operation

The AI now behaves more like an analyst opening a file cabinet: it starts with the smallest useful folder, requests additional folders only when needed, and preserves citations back to artifact ids.
