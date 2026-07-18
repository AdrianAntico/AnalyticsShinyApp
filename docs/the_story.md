# The Genuine Story

This document treats the repository as evidence.

It does not try to sell Analytics Workstation. It tries to explain what the repository shows: what was built, what changed during development, which ideas survived repeated pressure, which claims are supported, and which claims should remain bounded.

The short version is this:

Analytics Workstation became an evidence-governed AI investigation platform because the project kept finding that outputs were not enough. Charts, reports, dashboards, model summaries, and AI responses were all useful, but none of them preserved the reasoning path that makes an analytical recommendation trustworthy.

The repository evolved around that missing object: the investigation.

## Observation

The repository is not organized like a small Shiny dashboard.

It contains a Shiny application, but the app is only one part of the system. The repository also contains:

- a project model;
- data loading and project storage;
- analysis modules;
- artifact generation and quality policy;
- a project artifact collector;
- Artifact Studio;
- Evidence Review;
- Decision Management;
- Semantic and Causal Intelligence surfaces;
- provider-agnostic GenAI services;
- governed action and mutation layers;
- knowledge compilation runtime bundles;
- ReportContracts and a Report Browser;
- a Build Week demonstration;
- deterministic demo data;
- replay;
- claim verification;
- investigation integrity review;
- installer, repair, and uninstall scripts;
- package distribution checks;
- release artifacts;
- architecture, research, product, and demo documentation;
- media exhibits and browser-recorded video.

The implementation is mostly R, Shiny, HTML/CSS, and supporting scripts. The product label is `1.0.0-buildweek`. The package description calls it:

> A local-first analytical workstation for governed investigations, evidence artifacts, belief revision, claim verification, and decision-ready reporting.

That description is consistent with the implementation. The code includes modules named for agent operation, Build Week demo state, ReportContracts, evidence review, project state, GenAI actions, mutation governance, semantic intelligence, causal intelligence, and report browsing. The tests cover Build Week, agent operation, ReportContracts, report browser behavior, report adapters, and package distribution.

The repository also contains a large design and architecture corpus. That corpus repeatedly uses a stable vocabulary: evidence, artifacts, investigation, uncertainty, belief revision, claim verification, integrity review, governance, decision readiness, and deterministic computation before probabilistic reasoning.

The first observation is therefore straightforward:

This repository is not only a local analytics app. It is an attempt to make analytical reasoning durable, inspectable, governed, and communicable.

## Competing Explanations

Several explanations could account for the shape of the repository.

### Explanation 1: It is a dashboard that grew too large

This is plausible at first glance. The app has many pages, modules, reports, tables, plots, and settings. A dashboard can accumulate those things over time.

The evidence weakens this explanation. The repository does not simply add more display surfaces. It repeatedly introduces contracts around evidence, claims, actions, mutation, report semantics, project state, package boundaries, and QA. Many documents argue against treating the app as a dashboard. The Build Week demo is structured around an investigation sequence, not a metric display.

This explanation is insufficient.

### Explanation 2: It is an AutoML or analytics automation tool

This is also plausible. The app integrates AutoQuant, AutoPlots, model readiness, model insights, SHAP, forecasting-adjacent work, feature preparation, and demo analysis modules.

The evidence again weakens the explanation. The repo consistently avoids framing the AI or analytics modules as unchecked automation. The architecture constitution says workflow actions are user-triggered unless explicitly designed otherwise. The GenAI action and mutation layers add risk classification, confirmation, audit, and blocked mutation classes. The Build Week path is intentionally bounded. The final demo checklist says the product should not be treated as a general autonomous analyst.

Analytics automation is present, but it is not the central story.

### Explanation 3: It is a reporting system

This is partly true. Reporting became important enough to justify ReportContracts, report adapters, a Report Browser, media exhibits, and export workflows.

But the reporting docs explicitly separate truth, communication, presentation, and delivery. A `ReportContract` is not the source of analytical truth. It is a semantic human-facing communication contract derived from analysis results and evidence. The report system exists because the investigation needs to be communicated, not because the product is mainly a report generator.

Reporting is a major subsystem, but not the root.

### Explanation 4: It is an LLM wrapper

The repository directly rejects this explanation. GenAI is provider-agnostic, optional, bounded, and often paired with deterministic fallback or mock rehearsal paths. The docs state that GPT-5.6 is used for investigation framing, synthesis, belief-evolution narrative, recommendation explanation, claim verification, and integrity-review language. Deterministic services remain responsible for data generation, EDA, regression, SHAP evidence, validation, replay, report-contract construction, and QA.

The AI layer matters, but the product is not reducible to AI chat.

### Explanation 5: It is an evidence-governed investigation platform

This explanation fits the most evidence.

The product preserves uncertainty, competing explanations, evidence, belief updates, recommendation changes, claim verification, integrity review, decision readiness, and reportable investigation state. The code and documentation both support this explanation. The Build Week demo operationalizes it. The media exhibits and README now present it directly.

This is the strongest current explanation.

## Evidence

The repository contains several categories of evidence for the final interpretation.

### Product evidence

The application has a stable shell, branded home experience, project workspace, data workspace, analysis surfaces, evidence surfaces, decision surfaces, delivery surfaces, AI runtime, and Knowledge Library. The shell was reorganized into workspaces and utilities rather than a flat list of pages. This supports the claim that the product became more than isolated Shiny tabs.

The Build Week demo is the clearest product evidence. It is a bounded, replayable investigation over deterministic synthetic data. It has preflight, launch, reset, replay, claim verification, and Report Browser integration. The guide describes the desired viewer sequence:

```text
Objective
-> Observation
-> Uncertainty
-> Competing Explanations
-> Selected Investigation
-> Evidence
-> Belief Revision
-> Recommendation Evolution
-> Claim Verification
-> Integrity Review
-> Decision Readiness
-> Why Should I Believe This?
```

That sequence is not a dashboard flow. It is an investigation flow.

### Architecture evidence

The architecture synthesis defines Analytics Workstation as an evidence-centered analytical operating environment. It distinguishes projects, artifacts, information encoding, render targets, evidence routing, context optimization, GenAI, observability, and learning.

The reporting architecture separates:

```text
Truth
  CanonicalAnalysisResult

Communication
  ReportContract

Presentation
  PresentationProfile

Delivery
  ReportRenderer
```

This separation matters because it shows a recurring pattern: when a concept could be collapsed into a simpler implementation, the repository often separates it if the distinction protects meaning, trust, or future portability.

The architecture constitution records boundaries between AnalyticsShinyApp, AutoQuant, AutoPlots, Rodeo, PolarsFE, Benchmarks, and shinyelectron. It also defines contract-first rules such as `service_result()`, artifact creation, report plans referencing artifact IDs, generated code calling exported package APIs, and Code Runner as the only execution system.

### Governance evidence

The GenAI action and mutation layers show a conservative response to increased AI capability. The runtime classifies mutations, assesses risk, assigns governance requirements, validates, confirms, calls existing handlers, audits, and tracks lifecycle. Execution-class and authority-changing mutations remain blocked in the documented phase.

This supports a specific claim: the repository did not treat AI capability as sufficient justification for AI authority. It built contracts around what AI may know, propose, persist, or mutate.

### Evidence and claim evidence

The Build Week demo uses deterministic evidence generation, ReportContracts, evidence references, belief revisions, recommendation evolution, and a claim verification path. The `agent_operation` code includes integrity review construction and report assembly. Tests cover the Build Week path and agent operation behavior.

The investigation integrity review is especially important. It asks whether the recommendation survived alternative explanations, contradictory evidence, gaps, assumptions, sensitivity, generalizability limits, and decision robustness. This is the strongest evidence that the product applies its own evidential standards to its conclusions.

### QA and release evidence

The repository includes testthat coverage, QA helpers, startup dependency checks, package distribution tests, release notes, a Windows installer, repair and uninstall scripts, dependency installation guidance, media assets, and release checksums.

This does not prove production maturity in a commercial sense. It does show that the project moved from prototype behavior toward release-candidate behavior. The release notes call the package `1.0.0-buildweek` and describe the scope as a Windows-oriented per-user desktop product with known limitations.

### Development evidence

The development documents show repeated phases of architecture, product experience, governance, package integration, reporting, and demo preparation. The commit history includes many generic update messages, so it is not a detailed narrative by itself. The richer evidence is in the documents and code.

The existing `docs/development_ordeal.md` records a key development observation:

> We used the economic compression created by AI-assisted implementation to fund philosophical rigor.

That sentence is supported by the repository in a bounded way. The repository contains more architecture, policy, QA, design iteration, and governance than a small Shiny app would usually contain. It also contains many generated implementation phases. However, it should be treated as an observation from this project, not a universal law about all AI-assisted software development.

## Belief Revision

The likely story changed as the project developed.

The initial working interpretation appears to have been closer to:

```text
Build a local analytics workstation around plotting, artifacts, reports, and AutoQuant/AutoPlots.
```

That interpretation was not abandoned; it became a substrate. The project still has data loading, plotting, analysis modules, artifacts, layout, export, and package integration.

But the center moved.

Artifact work changed outputs into evidence. The collector changed generated assets into project memory. Information encoding separated artifact identity from representation. Evidence routing and context optimization made GenAI context a governed problem rather than a prompt-length problem. Knowledge State and Investigation Planning distinguished evidence from knowledge and business questions from analytical plans. GenAI actions and mutation governance made AI operation a contract problem. Reporting work separated analytical truth from human communication. Build Week compressed those layers into a single visible investigation.

The working belief therefore revised from:

```text
This app helps analysts create outputs.
```

to:

```text
This workstation helps analysts preserve and inspect the reasoning path from objective to evidence-backed recommendation.
```

and finally, for the Build Week release:

```text
Analytics Workstation conducts bounded, evidence-governed investigations that can revise recommendations as evidence accumulates and challenge their own conclusions before asking for trust.
```

That final sentence is a fair current description if the words "bounded" and "Build Week release" remain understood. It would be oversold if presented as a finished general-purpose autonomous analyst.

## The Product

Analytics Workstation is currently a local-first analytical workstation and Build Week demonstration product.

It can:

- launch as a Shiny app and Windows-oriented desktop workflow;
- load and inspect data;
- use analysis modules that produce artifacts;
- preserve evidence artifacts and metadata;
- route users through project, analysis, evidence, decision, delivery, AI, and knowledge surfaces;
- run a deterministic Build Week investigation;
- represent GPT-5.6 through a provider-agnostic contract;
- degrade to mock rehearsal for deterministic QA;
- preserve inquiry state, competing explanations, belief revisions, recommendation evolution, claim verification, and integrity review;
- produce validated semantic ReportContracts;
- display reports through a Report Browser;
- replay campaign state without rerunning analytics;
- package itself for Windows-oriented installation and repair.

It is not yet:

- a signed native Windows installer;
- a general autonomous analyst;
- a general-purpose workflow engine;
- a replacement for AutoQuant, AutoPlots, Rodeo, or other first-party packages;
- a claim that every AI-generated recommendation is trustworthy;
- a completed commercial product.

Those limits are not incidental. Many of them are intentional boundaries.

## The Experiment

The project is also a documented experiment in AI-assisted software engineering.

The supported observation is not that AI writes perfect software. The repository shows many corrections, reversals, QA expansions, UI defects, dependency issues, and framing changes. The supported observation is narrower and more interesting:

AI-assisted implementation reduced the cost of trying architectural ideas, which made architectural judgment more important, not less.

Several patterns recur:

1. A practical issue appeared.
2. The easiest shortcut was often rejected.
3. A contract or policy was introduced.
4. The contract was tested or documented.
5. The product later had to prove that the contract improved the experience.

This cycle occurred around artifacts, evidence routing, GenAI, action governance, remediation, knowledge compilation, reporting, product experience, package dependencies, and release engineering.

Implementation became cheaper enough that the project could explore more possibilities. That did not remove the need for taste, restraint, sequencing, or skepticism. In several places, the user explicitly stopped further abstraction and demanded visible product improvement. That correction is part of the evidence.

The experiment therefore did not prove that AI eliminates engineering judgment. It suggests the opposite: when implementation gets cheaper, the scarce resource shifts toward deciding what deserves to exist.

## The Development Philosophy

The repository's development philosophy can be inferred from repeated choices:

- Compute deterministic facts deterministically.
- Use probabilistic AI for ambiguity, synthesis, explanation, and judgment.
- Preserve evidence before presenting conclusions.
- Treat artifacts as evidence, not disposable outputs.
- Keep claims traceable to evidence, diagnostics, methodology, assumptions, and limitations.
- Make uncertainty visible.
- Allow recommendations to change when evidence changes.
- Govern AI actions through contracts, risk classification, confirmation, audit, and lifecycle.
- Separate truth, communication, presentation, and delivery.
- Treat QA and dependency checks as product behavior, not afterthoughts.
- Build product surfaces that reward curiosity without weakening rigor.

These principles are supported by the code, docs, tests, and demo path. They also explain why the repository is larger than a normal demonstration app.

## What Changed

Several things changed during development.

The unit of value changed from output to evidence.

The primary UX question changed from "which page should I open?" to "what should I investigate next?"

The AI role changed from possible assistant to bounded operator inside service, context, action, and mutation contracts.

Reports changed from export artifacts into semantic communication contracts.

Documentation changed from after-the-fact explanation into design material and historical evidence.

Product design changed from page-by-page cleanup into a stronger requirement: the philosophy had to produce a better product, not merely better diagrams.

Packaging changed the project mindset from developer app to release candidate.

## What Remained Constant

Several ideas survived almost every phase:

- The product should help with analytical work, not generic task management.
- First-party package boundaries matter.
- AutoQuant and AutoPlots should be installed and called through package APIs, not copied into the app.
- The app should fail visibly and gracefully instead of hiding missing capabilities.
- Evidence should be preserved with provenance.
- AI should not silently mutate important project state.
- QA should accompany architectural changes.
- The user should remain able to inspect why the system reached a conclusion.

These constants make the project more coherent than the number of phases might suggest.

## What Was Learned

The repository supports several lessons.

Outputs are inadequate when the important question is trust. A report or chart can be correct and still fail to preserve why it matters, what it rules out, and what uncertainty remains.

Evidence becomes more useful when it has identity, provenance, purpose, quality, and relationships.

AI becomes more useful when it is given bounded evidence and explicit responsibilities, not arbitrary access to raw data and application state.

Governance is not only for high-stakes production systems. It becomes useful as soon as AI begins proposing actions, persisting results, or shaping recommendations.

Replay matters because a trustworthy investigation should be inspectable after the fact.

Product experience matters because architectural rigor does not communicate itself. The interface must make the investigation legible.

Installation and dependency handling are part of trust. Silent missing packages are not just developer inconvenience; they can erase capabilities invisibly.

The development process itself can become an artifact. In this repository, docs, tests, media, release notes, and implementation history are part of the evidence for what was learned.

## Remaining Questions

Several questions remain open.

How well does the Build Week investigation generalize to real customer data?

How much of the GPT-5.6 path has been validated under live provider conditions versus mock rehearsal and deterministic QA?

Which parts of the broader architecture are implementation-ready, and which remain research scaffolding?

How should the app balance a rich workstation surface with a focused product narrative?

Which first-party package capabilities should move into public package APIs, and which should remain private product orchestration?

How should evidence routing, context optimization, and integrity review be evaluated empirically over time?

What is the smallest commercial product that preserves the core philosophy without overwhelming users?

These are not failures. They are the next investigations.

## Integrity Review

Before finalizing this story, the same standards should be applied to it.

### Does the claim exceed the evidence?

The claim that Analytics Workstation is an evidence-governed investigation platform is supported by docs, code, demo flow, tests, and README positioning.

The claim that it is a complete general-purpose autonomous analyst would exceed the evidence. This document avoids that claim.

The claim that AI-assisted implementation changed the cost structure of this project is supported by the development history and corpus, but it should remain local to this project. It is not presented as a universal law.

### Does the story undersell?

It would undersell the project to call it only a Shiny dashboard, a report generator, or an LLM wrapper. The repository contains too many explicit contracts around evidence, claims, investigations, reports, governance, and replay for those labels to be accurate.

### Are major claims supported?

The main claims are supported by repository artifacts:

- evidence-governed investigation: Build Week demo, agent operation, claim verification, integrity review, ReportContracts;
- deterministic/probabilistic split: GenAI docs, Build Week guide, design principles;
- governance: GenAI action layer, mutation runtime, audit and lifecycle docs;
- productization: installer scripts, release notes, package distribution tests;
- development experiment: architecture docs, design docs, source packs, development ordeal.

### What should a careful reader conclude?

A careful reader should not conclude that Analytics Workstation is finished in every direction. They should conclude that the repository records a serious attempt to build analytics software around evidence, investigation, governance, and bounded AI reasoning, and that the development process itself became a structured experiment in what AI-assisted implementation makes possible.

## Final Narrative

Analytics Workstation began as a practical analytics workstation and became something more specific: a local-first environment for evidence-governed investigation.

The central problem was not how to generate another chart, report, or AI summary. The central problem was how to preserve the reasoning path that makes an analytical recommendation trustworthy.

The repository's answer is operational rather than rhetorical. It creates artifacts, preserves evidence, records inquiry state, compares explanations, revises beliefs, evolves recommendations, verifies claims, challenges conclusions, and packages the resulting investigation into semantic reports. It uses AI where ambiguity and synthesis are useful, while keeping deterministic analytics, validation, replay, and QA in deterministic services.

The development process mirrored the product. As AI-assisted implementation made coding cheaper, the hard work shifted toward judgment: which concepts deserved contracts, which capabilities required governance, which surfaces communicated the idea, which abstractions were real, and which should be deferred.

That is the genuine story the repository supports.

Analytics Workstation is not simply an app that uses AI to explain analytics. It is an attempt to make analytical trust inspectable.
