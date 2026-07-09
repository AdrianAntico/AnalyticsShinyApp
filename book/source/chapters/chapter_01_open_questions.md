# Chapter 1 Open Questions

This file preserves open questions raised by the source chapter. These should not be prematurely resolved in the polished draft.

## Artifact Value

Which artifact families carry the highest marginal value for common analytical questions?

How should the system estimate whether a plot, table, diagnostic, recommendation, or narrative is critical, recommended, or supplementary?

Can artifact importance be reliably producer-declared, or should it eventually be adjusted by observed use?

## Artifact Quality And Trust

How should Artifact Quality and Trustworthiness relate in UI and routing?

What diagnostics are required before an artifact should be considered trustworthy?

Can trustworthiness be scored generically, or must it remain module-specific?

How should warnings and assumptions be weighted by decision criticality?

## Information Encoding

Which encodings work best for humans, LLMs, thumbnails, executives, and developers?

When does information density become counterproductive?

What is the measurable relationship between label density, annotation density, data-to-pixel ratio, and LLM comprehension?

Can AutoPlots support consumer-aware encoding without parameter explosion?

## LLM Evidence Documents

Should LLM evidence be compiled into one large DOCX or multiple specialized documents?

How do custom GPT upload limits affect document strategy?

Do LLMs perform better with dense screenshots, structured JSON, table previews, or hybrid context?

How should screenshot evidence be paired with backing data?

## Evidence Routing

When should raw data be routed instead of artifacts?

How should the system decide that existing artifacts are sufficient?

What metadata is required for reliable evidence routing?

Should evidence routing be deterministic only at first?

When is probabilistic routing justified?

## Marginal Information Gain

How should MIG be approximated from available telemetry?

How should redundancy be measured across artifacts?

How should decision criticality change the stopping criterion?

How should uncertainty reduction be estimated without overclaiming?

## Retrieval

Should artifact retrieval be metadata-based, embedding-based, graph-based, workflow-stage-based, or hybrid?

How should artifacts be chunked or indexed for LLM retrieval?

Should screenshots be indexed visually, textually, or through generated summaries?

## Learning

What user feedback is realistic to collect?

Can manual scores for usefulness and accuracy become training data for routing?

How much telemetry is needed before strategy recommendations are trustworthy?

How can the system learn without violating privacy/local-first principles?

## Implementation Boundaries

How much artifact metadata should be required at creation time?

How strict should QA be when old modules lack explicit producer semantics?

Should inference remain permanent fallback or only migration support?

When should Delivery Studio become a formal workstation mode?

How should Agentic Lab preview actions before execution?

