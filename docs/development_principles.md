# Development Principles

These principles are not aspirational slogans. They are recurring rules reflected in the repository.

## Evidence Before Conclusions

The product should preserve why a recommendation exists. Claims should point to evidence, diagnostics, limitations, and methodology whenever possible.

Obligation: do not add summaries or recommendations that cannot be traced to supporting state.

## Keep It Real

Unsupported capabilities should be unavailable, disabled, or explicitly degraded. They should not look functional while silently doing nothing.

Obligation: tests and UI should distinguish missing packages, missing providers, unavailable endpoints, and unsupported workflows.

## Deterministic First, Probabilistic Where Useful

Deterministic facts should be computed deterministically. GenAI belongs where synthesis, judgment, framing, or explanation is genuinely useful.

Obligation: do not ask an AI model to replace a calculation that the application can compute directly.

## Show, Do Not Merely Tell

The repository should demonstrate product quality through runnable demos, screenshots, tests, diagnostics, and release artifacts.

Obligation: important claims in documentation should be backed by code, QA, screenshots, or explicit limitations.

## Progressive Disclosure

Users and contributors should encounter the right depth at the right time. The first screen, first paragraph, or first diagnostic should answer the immediate question before exposing lower-level detail.

Obligation: avoid long undifferentiated metadata panels and contributor docs that require archaeology before action.

## Architecture Before Implementation

Large features should fit existing contracts before adding new ones. New abstractions should earn their keep.

Obligation: prefer a small adapter or service that fits the current model over a parallel subsystem.

## Coherence Over Feature Count

More capabilities are not automatically better. The product should feel like one workstation rather than a pile of modules.

Obligation: avoid duplicate controls, duplicate state, and multiple names for the same concept.

## Package Reality Matters

The app is now an installable package. Source-tree shortcuts are development conveniences, not the release contract.

Obligation: use package resource helpers and user-state helpers instead of local checkout paths.

## Failure Should Teach

Errors should identify what failed and what the user or contributor can do next.

Obligation: silent failure is a bug unless the operation is explicitly optional and reported as unavailable.

## Craft Is Part Of Trust

The interface should reward curiosity without compromising rigor. Visual polish, empty states, and presentation quality help users trust that the system was made carefully.

Obligation: visual changes should improve comprehension or confidence, not decorate for its own sake.

