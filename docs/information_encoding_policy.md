# Information Encoding Policy

Analytics Workstation distinguishes render target from information encoding.

The same analytical artifact may need different encodings depending on the consumer. A human report, an LLM evidence bundle, an Artifact Studio thumbnail, and an executive briefing may all refer to the same artifact, but the information should be encoded differently.

## Core Principle

Separate:

```text
Analytical Artifact
-> Information Encoding
-> Render Target
```

The analytical artifact remains identical. Only its encoding changes.

## Purpose

The purpose of an analytical artifact is efficient transfer of analytical information.

Beauty is useful when it improves comprehension, but beauty is not the primary objective. The encoding should optimize for the consumer.

```text
Human       -> interactive understanding
LLM         -> information density
Thumbnail   -> recognition
Executive   -> decision support
Developer   -> traceability
```

## Consumer Types

Initial consumer types:

- `human`
- `llm`
- `thumbnail`
- `presentation`
- `executive`
- `developer`

Future consumers may be added without changing the underlying artifact model.

## Human Encoding

Optimize for:

- readability
- visual hierarchy
- spacing
- larger fonts
- interaction
- presentation quality
- progressive disclosure
- exploration

Human encoding should help users inspect and understand without overwhelming them.

## LLM Encoding

Optimize for:

- information density
- annotation density
- compact legends
- smaller fonts when still readable
- more labels
- more reference lines
- combined analytical views
- higher data-to-pixel ratio
- less decorative whitespace
- maximum information transfer

Visual beauty is secondary. Analytical density is primary.

LLM encoding should help the model recover meaning from compact evidence with minimal token, image, and attention cost.

## Thumbnail Encoding

Optimize for:

- recognition
- visual identity
- fast scanning
- artifact browsing

Thumbnail encoding should not attempt to communicate every analytical detail. It should help the user recognize and select the artifact.

## Presentation Encoding

Optimize for:

- clear visual hierarchy
- readable titles and labels
- audience-friendly pacing
- concise supporting detail
- slide/report composition

Presentation encoding sits between human exploration and executive summary. It should be polished, but still evidence-grounded.

## Executive Encoding

Optimize for:

- decision support
- major findings
- risk
- recommendations
- minimal statistical detail

Executive encoding should make the decision, confidence, caveats, and recommended next action obvious.

## Developer Encoding

Optimize for:

- debugging
- traceability
- metadata
- diagnostics
- raw analytical detail

Developer encoding should expose provenance, policy decisions, sidecar paths, diagnostic fields, and failure reasons.

## Composite Analytical Views

Composite views exist to increase analytical information transfer.

Examples:

- bar + line
- importance + cumulative contribution
- histogram + density
- scatter + smoother
- scatter + marginals
- SHAP dependence + binned mean
- boxplot + mean
- trend + confidence bands
- trend + anomalies

These are not decorative. They intentionally increase analytical density by combining related analytical signals into one evidence object.

Composite views should be used when the combined view communicates more useful information than separate artifacts for the intended consumer.

## AutoPlots V2 Direction

This policy does not implement AutoPlots changes.

Future AutoPlots APIs should support:

- simple defaults
- consumer-aware encoding
- composite analytical views
- minimal API complexity
- explicit composite plot helpers

Avoid parameter explosion. Prefer a small number of clear consumer or composite helpers over many low-level knobs.

Future examples:

```text
AutoPlots::ImportanceCumulative(...)
AutoPlots::HistogramDensity(...)
AutoPlots::ScatterWithMarginals(...)
AutoPlots::ShapDependenceBinnedMean(...)
AutoPlots::TrendAnomaly(...)
```

The app should continue calling high-level AutoPlots functions and should not reach into AutoPlots internals.

## Information Density

Information density should become measurable over time.

Possible future metrics:

- estimated labels
- annotation count
- reference lines
- analytical dimensions
- legend complexity
- data-to-pixel ratio
- information density score

These are research concepts. No automatic optimization is implemented by this policy.

## Relationship To Context Optimization

Information Encoding becomes an upstream optimization layer:

```text
Raw Data
-> Analytical Artifact
-> Information Encoding
-> Evidence Routing
-> Context Strategy
-> GenAI
```

Better encoding should reduce downstream context cost. For example, an LLM-encoded SHAP dependence view may communicate nonlinearity, binned averages, sparse regions, and caveats in one screenshot, reducing the need for separate context fragments.

## Relationship To Render Targets

Render target answers where the artifact goes.

Information encoding answers how the artifact should be represented for the consumer.

Examples:

- `llm_docx` render target may use `llm` encoding.
- `human_report` render target may use `human` or `presentation` encoding.
- Artifact Studio gallery may use `thumbnail` encoding.
- Artifact Studio inspector may use `human`, `developer`, or `llm` encoding depending on inspection mode.

Do not use render target as a substitute for encoding policy.

## Future Research

Future experiments should compare:

- human encoding
- LLM encoding
- question type
- artifact family
- information transfer
- analytical quality
- token usage
- latency

This should become part of the broader information-transfer experiment framework.

## Non-Goals

This policy does not:

- modify AutoPlots
- implement composite plots
- redesign render targets
- alter existing artifacts
- automatically optimize encodings
- add Agentic Lab behavior

## Acceptance Contract

Analytics Workstation should treat this as the canonical sequence:

```text
Analytical Artifact
-> Information Encoding
-> Render Target
```

Future AutoPlots, artifact collector, LLM DOCX, and Artifact Studio work should build on this policy rather than inventing ad hoc LLM-specific or report-specific plot modifications.
