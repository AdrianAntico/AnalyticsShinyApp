# The Knowledge Library

Analytics Workstation now has enough internal knowledge that the knowledge itself needs a product surface.

The system contains a product vision, a manifesto, a canonical ontology, a concept dependency graph, architecture causality, context optimization, evidence routing, information encoding, knowledge state, execution modes, source chapters, research notes, QA contracts, and a Guide. These documents are not peripheral. They are not after-the-fact documentation pasted onto a finished application. They are part of the system's intellectual machinery.

This creates a new requirement. Users should not need to browse the repository to understand the software. Contributors should not need to reconstruct architectural decisions from memory. The Guide should not need to explain every concept from scratch. The Book should not be the only place where the ideas are preserved. The application itself should expose its own knowledge.

That surface is the Knowledge Library.

The Knowledge Library is the authoritative, navigable body of Analytics Workstation knowledge. It is where users learn the system, inspect concepts, read the evolving book, understand architectural decisions, study experiments, trace the history of ideas, and download knowledge products.

It is not another chat interface.

It is not merely a documentation page.

It is the library of the analytical operating environment.

## Guide, Library, Book

The easiest way to understand the Knowledge Library is to separate three human-facing knowledge layers.

The Guide teaches.

The Knowledge Library explains.

The Book preserves.

The Guide is contextual. It knows where the user is, what project is open, what evidence exists, what remains unknown, and what the next step might be. The Guide should speak like a senior analytical mentor. It is allowed to say, "You have enough evidence to inspect this model, but not enough evidence to make a high-confidence recommendation." It teaches inside the current situation.

The Knowledge Library is authoritative. It does not merely answer the next question. It preserves definitions, relationships, architecture, history, research, examples, and references. If the Guide says, "Artifacts become evidence," the Library is where the user can open the Artifact concept, read the chapter on artifacts as evidence, inspect the Artifact Quality Policy, find the collector architecture, and see related QA.

The Book is long-form. It explains the intellectual argument in a durable narrative. It is where the project becomes communicable outside the app. It is where the ideas are made coherent for readers who are not using the product at that moment.

These layers should reinforce one another rather than compete.

```text
Guide
  immediate, contextual, pedagogical

Knowledge Library
  authoritative, navigable, connected

Book
  long-form, preserved, narrative
```

This distinction matters because many products collapse these layers into one. They put a help center next to a chat box and call the problem solved. Analytics Workstation needs something more deliberate because its architecture is itself part of its value.

## Why A Knowledge Library Is Necessary

Traditional applications can sometimes survive with thin documentation. A user sees a button, clicks it, and learns through the result. That model works when the product is mostly a set of actions.

Analytics Workstation is different. It is built around concepts.

Artifact.

Evidence.

Collector.

Knowledge State.

Investigation Plan.

Evidence Routing.

Context Optimization.

Information Encoding.

Render Target.

Marginal Information Gain.

Execution Mode.

Guide.

These are not cosmetic labels. They are product architecture. If a user does not understand them, the application can look like a collection of pages. If a contributor does not understand them, future implementation can drift into local feature work that violates the system's deeper logic.

The Knowledge Library exists to prevent that drift.

It gives the application a memory of itself. It helps people understand not only what the software does, but why it behaves the way it does.

This is especially important because Analytics Workstation is being built around a non-standard product identity. It is not a dashboard. It is not a Shiny app in the ordinary sense. It is not just an automated report generator. It is an evidence-centered analytical operating environment. That identity requires explanation, and the explanation must be available inside the product.

## The Library Is Not A Help Center

A help center usually starts with tasks:

How do I upload a file?

How do I create a chart?

How do I export a report?

Those questions matter, but they are not enough.

The Knowledge Library starts from a deeper premise: the user needs to understand the system's conceptual model.

What is an artifact?

Why is a collector different from a report?

Why does a render target differ from information encoding?

Why should GenAI reason over evidence rather than raw data?

Why does Evidence Routing happen before GenAI reasoning?

Why does Context Optimization care about marginal information gain?

Why is Decision Readiness not the same as model confidence?

Why should deterministic knowledge be computed before probabilistic reasoning is used?

These questions are not feature questions. They are architecture questions. The Library should answer them.

A help center helps users operate software. The Knowledge Library helps users understand an analytical system.

## The Repository As Source Of Truth

The Library should not become a second documentation universe.

The repository remains the source of truth. The Library is a product surface over that source. This distinction is essential.

If the Library becomes manually authored inside the app, it will eventually diverge from the docs, book source, ontology, roadmap, experiments, and code. Then the product will have two competing memories. That would defeat the purpose.

Instead, the Library should be generated, indexed, or projected from repository knowledge:

- architecture docs
- policy docs
- ontology entries
- source chapters
- source packs
- research outputs
- QA contracts
- roadmap milestones
- implementation references
- chronology files
- empirical findings

The user should experience this as a coherent knowledge system, but the source should remain traceable.

This also makes the Library compatible with the Book Compiler. The same canonical body of knowledge can produce:

- in-app Library pages
- long-form book chapters
- GPT knowledge packs
- white papers
- conference material
- onboarding packs
- developer reference bundles

The content should not be duplicated by audience. It should be encoded differently by audience.

## The Library And The Ontology

The Canonical Ontology should be the spine of the Knowledge Library.

A folder of Markdown files is useful to developers. It is not enough for users. Users need relationships.

The ontology gives the Library a conceptual map. It can tell the user that Artifact relates to Evidence, Artifact Bundle, Project Artifact Collector, Artifact Quality Policy, Render Target, Information Encoding, Artifact Studio, and Evidence Inspector. It can tell the user that Context Optimization depends on Context Strategy, Evidence Routing, Marginal Information Gain, GenAI Telemetry, and Information Transfer. It can tell the user that the Guide is related to Knowledge State, Mission Control, Evidence Strategy, Execution Mode, and GenAI status.

This relationship structure changes the experience from browsing documents to navigating knowledge.

Consider a user who searches for "collector." In a normal documentation site, they might see a list of files containing the word. In the Knowledge Library, they should see:

- Concept: Project Artifact Collector
- Architecture: Project Artifact Collector architecture
- Policy: Artifact Quality Policy
- Related concept: Collector Manifest
- Related concept: Render Target
- Related mode: Artifact Studio
- Related chapter: Artifacts As Evidence
- Related source: collector implementation
- Related QA: collector creation, append behavior, duplicate protection, DOCX integrity
- Related future work: Delivery Studio and knowledge packs

This is the difference between document search and knowledge navigation.

## The Primary Sections

The first version of the Library should be organized around stable user purposes rather than implementation folders.

### Welcome

The Welcome section is the front door.

It should explain the identity of Analytics Workstation in plain language:

This is an evidence-centered analytical operating environment.

The project is the world.

Artifacts are evidence.

The Collector is memory.

The Guide teaches.

The Library explains.

The Book preserves.

GenAI reasons over evidence.

The Welcome section should include the Product Vision and Manifesto, but it should not force a new user through a wall of text. It should make the software's worldview understandable quickly and then offer paths into deeper material.

### Learn

The Learn section should provide role-based learning paths.

A new user does not need the same path as a developer. A business user does not need the same path as a researcher. A technical executive needs the product argument, not the implementation details of every QA contract.

Initial learning paths should include:

- New User
- Business User
- Data Scientist
- Developer
- Researcher
- Technical Executive

The New User path should explain the core operating model: project, evidence, artifacts, collector, Mission Control, Artifact Studio, Guide, and Delivery.

The Business User path should emphasize decisions, evidence sufficiency, recommendations, confidence, decision readiness, and reports.

The Data Scientist path should emphasize artifact semantics, model readiness, model assessment, SHAP, information encoding, evidence routing, context optimization, and GenAI experiments.

The Developer path should emphasize service results, architecture contracts, QA, producer semantics, collector integration, table artifacts, and render targets.

The Researcher path should emphasize open questions, experiments, information transfer, marginal information gain, routing calibration, and learning observability.

The Technical Executive path should emphasize why the product exists, what problem it solves, how it differs from dashboards and notebooks, and how the architecture supports future AI-native analytical systems.

### Concepts

The Concepts section is the ontology made readable.

Each concept should eventually have a page.

That page should include:

- definition
- purpose
- parent concepts
- child concepts
- dependencies
- origin
- problem solved
- implementation status
- validation status
- maturity
- examples
- related chapters
- related architecture docs
- related research
- related QA
- related code
- open questions

The concept page should make the system feel connected.

If a user opens Decision Readiness, the page should explain that this is evidence confidence, not model confidence. It should relate to Knowledge State, Evidence Sufficiency, Investigation Planning, Evidence Routing, and the Guide. It should point to examples where a project has enough evidence for a preliminary recommendation but not enough for a critical decision.

If a user opens Information Encoding, the page should explain that analytical artifact, information encoding, and render target are separate. It should point to Human Encoding, LLM Encoding, Thumbnail Encoding, and future AutoPlots work. It should explain why the same artifact may need different representations for a human report, an LLM DOCX, and a gallery thumbnail.

### Architecture

The Architecture section should organize architecture documents by theme.

The repository's file structure is useful, but it is not always the best product structure. A user trying to understand "how evidence works" should not need to know which folder contains which policy.

Architecture should be grouped around product concepts:

- Evidence
- Knowledge
- Investigation
- Routing
- Optimization
- GenAI
- Execution
- Observability
- UX
- Research
- Book and Knowledge Products

This makes the Library teach the shape of the system.

### Book

The Book section should expose the evolving manuscript.

The current book source is intentionally overcomplete. That is good. The Library should not hide the fact that early source chapters are raw. It should label them accurately:

- raw source
- source chapter
- edited chapter
- compiled draft
- reviewed draft
- publication candidate

The Book section should eventually support Markdown, HTML, PDF, DOCX, and EPUB, but it should not require all render targets at first. A Markdown reader with chapter navigation and cross-links would already be valuable.

The Book section matters because it turns the system's architecture into a communicable argument. It is where the philosophy becomes transmissible.

### Research

The Research section should preserve experiments.

Analytics Workstation is not pretending that every architectural question is already settled. Some concepts are deterministic and stable. Others are research hypotheses. The Library should make that distinction visible.

Research entries should include:

- question
- hypothesis
- method
- artifacts used
- provider or model used where relevant
- findings
- limitations
- next experiment
- current status

This is important for GenAI context strategy research, image-vs-data studies, evidence routing calibration, plot sizing, information encoding, and marginal information gain.

The Research section should help the product remain honest. It should preserve uncertainty rather than smoothing it away.

### Timeline

The Timeline section should show how the architecture evolved.

This is not merely a history feature. It is a reasoning feature.

The system's architecture did not appear fully formed. It emerged through AutoNLS validation, AutoQuant SHAP integration, artifact collector work, Word export constraints, plot sizing failures, GenAI experiments, information transfer studies, evidence routing, context optimization, knowledge state, investigation planning, execution modes, Guide design, and now Knowledge Library design.

Seeing that evolution helps future contributors understand why the system is shaped the way it is.

It also preserves alternatives. For example, the system did not start with "Knowledge Library" as a concept. It appeared only after the documentation corpus became large enough that the app itself needed to expose institutional knowledge. That origin matters.

### Search

Search should be global and ontology-aware.

The user should be able to search:

- concepts
- chapters
- architecture docs
- policies
- research
- experiments
- QA
- roadmap
- implementation references

But search should not be only string matching. It should understand concept relationships.

If the user searches "why can't I make a recommendation yet?", the system should know that this relates to Decision Readiness, Knowledge State, Evidence Sufficiency, Investigation Planning, missing evidence, and the Guide.

This does not require GenAI at first. It can begin with deterministic metadata, tags, headings, and concept relationships. GenAI can later make search more conversational, but the Library should not depend on it.

### Downloads

The Library should eventually support downloads.

Possible downloads:

- full book
- individual chapters
- architecture docs
- research papers
- white papers
- knowledge packs
- source packs
- GPT knowledge-base bundles
- role-specific onboarding packs
- custom documentation bundles

Downloads should be traceable. A knowledge pack should record what it includes, when it was generated, which commit it came from, which concepts it covers, and which audience it targets.

This is how the Library becomes a source for many external forms without duplicating content.

## Cross Linking As A Product Principle

The Knowledge Library should be densely cross-linked.

Every important object should connect outward:

Artifact should connect to Evidence.

Evidence should connect to Collector.

Collector should connect to Render Target.

Render Target should connect to Information Encoding.

Information Encoding should connect to Context Optimization.

Context Optimization should connect to Evidence Routing.

Evidence Routing should connect to GenAI.

GenAI should connect to Observability.

Observability should connect to Learning.

Learning should connect back to Knowledge State.

This structure mirrors the analytical intelligence loop.

The Library should prevent users from feeling lost. Each page should answer:

- What am I looking at?
- Why does it matter?
- What does it depend on?
- What depends on it?
- Where is it explained in the book?
- Where is it specified architecturally?
- What research supports it?
- What remains uncertain?
- Where is it implemented?

That is the difference between a documentation repository and a knowledge environment.

## The Library And GenAI

The Knowledge Library must work without GenAI.

This point keeps recurring because it is central to the product philosophy. Deterministic knowledge should be computed and retrieved deterministically. Probabilistic reasoning should be reserved for ambiguity, synthesis, judgment, and uncertain prioritization.

The Library can provide deterministic navigation, deterministic concept pages, deterministic chapter lists, deterministic architecture grouping, and deterministic downloads. None of that requires an LLM.

GenAI becomes useful when the user asks for synthesis:

- Compare Evidence Routing and Context Optimization.
- Explain this concept for an MBA user.
- Summarize the Knowledge State architecture in five minutes.
- Build a reading path for a data scientist.
- Generate a knowledge pack for a conference talk.

Even then, GenAI should reason over curated Library objects. It should not become the source of truth.

The Library gives GenAI better context. GenAI gives the Library better explanation.

## The Library And Future GPT Knowledge Bases

One of the long-term goals is to produce knowledge packs that can be used by custom GPTs or other AI systems.

The Knowledge Library is the natural source for those packs.

Instead of manually uploading arbitrary DOCX files, the system should eventually assemble knowledge packs from canonical concepts, chapters, architecture docs, research findings, and source packs.

Different packs may target different needs:

- full architecture pack
- executive summary pack
- developer onboarding pack
- GenAI research pack
- AutoPlots and visualization pack
- Artifact Model pack
- book manuscript pack

The key is traceability. Each pack should know where it came from.

This aligns with the broader architecture: artifacts are evidence, the collector is memory, the book compiler turns source into narrative, and the Library turns institutional knowledge into navigable product experience.

## What The Library Must Not Become

The Library must not become a dumping ground.

If it simply lists every Markdown file, it will not solve the problem. Users will still need to infer structure.

The Library must not become an AI answer box.

If it is merely a chat interface over docs, it will lose authority. Chat can explain; it should not replace canonical references.

The Library must not become detached from the repository.

If it has its own manually maintained content model, it will drift.

The Library must not hide uncertainty.

Some parts of Analytics Workstation are stable. Others are research. The Library should make maturity visible.

The Library must not flatten audiences.

Business users, data scientists, developers, researchers, and executives need different pathways through the same knowledge.

## Why This Matters

The Knowledge Library makes the product more coherent.

It acknowledges that the architecture is part of the user experience. It gives users a place to learn the system without being thrown into source files. It gives contributors a way to understand why decisions were made. It gives the Guide a place to point when an explanation needs depth. It gives the Book a home inside the product. It gives future knowledge packs a canonical source.

Most importantly, it makes documentation a first-class artifact.

Analytics Workstation is built around the idea that analytical work should produce evidence, not disposable outputs. The same principle applies to the product itself. Its conversations, design decisions, experiments, policies, chapters, and validation results are evidence of the system's evolution.

The Knowledge Library preserves that evidence.

It turns the software's own history and architecture into something users can inspect, learn from, and trust.

If the Guide is how the system teaches in the moment, and the Book is how the system explains itself to the world, the Knowledge Library is the place where the system remembers what it knows.
