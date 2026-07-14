# Knowledge Compilation Runtime Phase 6

## Governed Evidence Review

Phase 6 introduces the first complete AI-operated analytical workflow:

```text
bounded question or selected object
-> deterministic scope resolution
-> synthesis plan
-> progressive artifact retrieval
-> evidence binder
-> cited review findings
-> sufficiency for action
-> ranked supported next actions
-> preview-only draft or safe navigation
-> operator audit record
```

The workflow is governed. The AI may review, synthesize, explain, navigate through validated read-only handlers, and prepare preview-only drafts. It may not alter evidence, approve work, change authority, execute campaigns, mutate analytical specifications, or perform Class 3/4 operations.

## Reuse And Ownership

| Existing component | Reused responsibility | Phase 6 extension | Owner |
| --- | --- | --- | --- |
| Knowledge runtime bundles | Policy compilation, task routing, model-tier context | Adds `review_evidence_and_recommend_next_action` | AnalyticsShinyApp |
| Artifact registry | Discover current project artifacts | Evidence binder classification | AnalyticsShinyApp |
| Progressive retrieval | Bounded context growth | Retrieval chain, loop, and budget stopping records | AnalyticsShinyApp |
| Cross-artifact synthesis | Evidence classes, contradictions, sufficiency | Review findings and action-specific sufficiency | AnalyticsShinyApp |
| Operator action registry | Supported actions and action classes | Candidate generation and transparent ranking | AnalyticsShinyApp |
| Operator validation | Reject unsafe/invented actions | Citation completeness and handler eligibility | AnalyticsShinyApp |
| Mission Control | Operational signals | Review availability, gaps, contradictions, stale evidence, and draft status | AnalyticsShinyApp |
| GenAI provider layer | Optional model execution | Token/cost/qualification comparison for review workflows | AnalyticsShinyApp |

AutoQuant is unchanged. The Phase 6 operator workflow is private application runtime behavior, not a portable package API.

## Evidence Review Session

`create_evidence_review_session()` records exactly what the runtime is reviewing:

- session id
- task id
- initiating request
- selected project object
- decision context id
- active page
- synthesis plan id
- artifacts considered, retrieved, and omitted
- evidence classes
- contradiction records
- sufficiency result
- scope and audience
- model tier
- runtime and bundle versions
- status and timestamp

The session stores references and summaries, not full artifact payloads.

## Evidence Binder

`build_evidence_binder()` assembles a compiled view from existing artifact and synthesis runtime objects. It classifies:

- primary artifacts
- supporting artifacts
- contradictory artifacts
- contextual artifacts
- superseded artifacts
- stale artifacts
- unavailable expected evidence
- excluded artifacts and reasons
- artifact freshness
- applicability
- evidence classes
- lineage
- retrieval chain

The binder is not a new storage system. It is a bounded review representation.

## Review Findings

`evidence_review_findings()` produces deterministic findings for:

- material supporting evidence
- material contradictory evidence
- applicability mismatch
- stale evidence
- missing evidence
- causal-language overreach
- missing valuation
- missing authority
- evidence sufficient for scope

Every finding carries evidence references or states that evidence is missing.

## Sufficiency For Action

`assess_evidence_sufficiency_for_action()` separates evidence sufficiency from approval. Supported states are:

- `sufficient`
- `sufficient_with_limitations`
- `missing_mandatory_evidence`
- `contradiction_resolution_required`
- `authority_review_required`
- `stale_evidence_must_be_refreshed`
- `human_judgment_required`
- `action_not_supported`

Sufficient evidence means the next step is supportable. It never means the business decision is approved.

## Ranked Supported Actions

`generate_evidence_review_action_candidates()` creates candidates only from `knowledge_operator_action_registry()`. Ranking is transparent and decomposable:

- mandatory blockers before optional refinement
- stale evidence before downstream synthesis
- inexpensive deterministic checks before model calls
- contradiction review before recommendation strengthening
- authority review before prohibited action

Each candidate records action class, purpose, evidence gap addressed, prerequisite, expected information gain, effort, cost, urgency, reversibility, authority requirement, confirmation requirement, handler, eligibility, blocked reason, and evidence references.

## Draft Boundary

Phase 6 supports:

- Class 0 explanation
- Class 1 read-only navigation
- Class 2 preview-only drafts

`create_evidence_review_draft()` and `create_campaign_seed_draft()` produce generated content with `confirmation_state = "preview_only"`. Confirmation can mark the draft as preview-confirmed, but the runtime does not save hidden project state.

Class 3 and Class 4 operations remain blocked.

## Citation Completeness

`validate_evidence_review_citations()` rejects hallucinated or unconsumed artifact ids. Material claims must cite ids present in the binder.

## Audit Artifact

`evidence_review_audit_record()` records:

- review session id
- user request
- selected scope
- task
- model tier and qualification route
- bundles
- artifact binder summary
- retrieval chain
- synthesis summary
- deterministic findings
- action candidates
- selected proposal
- validation
- confirmation state
- handler result
- token usage
- cost estimate
- latency
- context hash
- output hash
- warnings

This is operational AI evidence. It is not employee-performance telemetry.

## Token And Cost Evaluation

`run_evidence_review_token_cost_comparison()` compares:

- current cross-artifact synthesis
- governed evidence review
- retrieve-everything baseline

The comparison records initial context tokens, retrieval tokens, final context tokens, retrieval rounds, latency, cost estimate, citation validity, next-action validity, human-review frequency, and quality-per-token placeholders.

## UI

The AI Runtime page now exposes governed evidence review diagnostics. Mission Control surfaces review-specific signals, including evidence review availability, incomplete review, contradictions, sufficient next steps, blocked actions, draft confirmation state, human review requirements, and stale evidence.

## QA

Phase 6 adds:

- `qa_ai_operated_evidence_review()`
- `qa_knowledge_compilation_runtime_phase6()`

The QA covers sessions, scopes, binders, retrieval, findings, sufficiency, action candidates, ranking, Class 1 navigation, Class 2 draft confirmation, citations, hallucinated references, model routing, audit records, Mission Control data, AI Runtime data, token/cost comparison, and competency cases.

## Limitations

Phase 6 does not implement:

- Class 3 or Class 4 operations
- direct project mutation by the LLM
- automatic evidence attachment
- automatic campaign execution
- automatic review submission
- approval
- authority modification
- analytical specification changes
- observational effect estimation
- vector or semantic search
- autonomous planning
- external workflow integration
- identity management

