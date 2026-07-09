# Analytics Workstation Knowledge Library Architecture

## Purpose

The Analytics Workstation Knowledge Library is the authoritative knowledge surface inside Analytics Workstation.

It exposes the product's own institutional knowledge:

- Product Vision
- Manifesto
- Canonical Ontology
- Concept Dependency Graph
- Architecture Causality
- Context Optimization Policy
- Evidence Routing Policy
- Information Encoding Policy
- Knowledge State Architecture
- Execution Mode / Delegation Policy
- Book Compiler
- Source Chapters
- Guide Architecture
- Research studies
- QA and validation history
- implementation references

The Library exists because Analytics Workstation is no longer only an application with documentation. It is becoming a self-documenting analytical operating environment.

## Philosophy

The Guide teaches.

The Knowledge Library preserves.

The Guide is contextual.

The Knowledge Library is authoritative.

The Guide recommends.

The Knowledge Library explains.

The Guide helps users decide what to do next. The Knowledge Library helps users understand why the system works the way it does.

Together with the Book, these become three complementary human-facing knowledge layers:

```text
Guide
  teaches in context

Knowledge Library
  explains and navigates the canonical knowledge base

Book
  preserves the long-form intellectual argument
```

The Knowledge Library should not be treated as an afterthought or a static documentation page. It should be a first-class part of the workstation because the architecture itself is part of the product.

## Non-Goals

This architecture does not implement:

- a search engine
- a UI page
- a book renderer
- download generation
- GenAI chat
- document indexing
- graph visualization
- autonomous guidance

It defines the intended knowledge product surface.

## Core Responsibilities

The Knowledge Library should allow users to:

- learn the system
- understand architectural decisions
- read the evolving book
- search concepts
- navigate concept relationships
- inspect source material
- understand why the software behaves the way it does
- download reference material
- connect concepts to code, experiments, QA, and chapters
- discover unfinished research questions

The Library should answer different questions than the Guide.

Guide-style question:

> What should I do next in this project?

Library-style question:

> What does Evidence Routing mean, where did it come from, what policies define it, which chapters explain it, and what experiments validate it?

## Relationship To Existing Architecture

### Relationship To The Guide

The Guide should reference the Knowledge Library whenever a contextual explanation needs deeper support.

Example:

```text
Guide: Artifacts become evidence when they have identity, provenance, quality, intent, diagnostics, and relationships.

Actions:
- Open Concept: Artifact
- Read Chapter: Artifacts As Evidence
- Open Architecture: Artifact Model
- Open Related Experiment: Artifact Quality Policy QA
- Open Related Code: artifact model implementation
```

The Guide should not dump the full architecture into the user conversation. It should teach progressively and use the Library as the deeper reference layer.

The Knowledge Library may link back to the Guide for contextual interpretation:

```text
Concept: Decision Readiness

Actions:
- Ask Guide how this applies to the current project
- Ask Guide what evidence is missing
- Ask Guide why the current decision is not ready
```

### Relationship To The Book

The Book is the long-form narrative product.

The Knowledge Library is the navigable knowledge system that contains, references, and organizes the same source material.

The Book should be readable through the Library, but the Library is broader than the Book. It includes concepts, architecture docs, research results, source packs, timelines, implementation links, QA references, and download bundles.

### Relationship To The Book Compiler

The Book Compiler transforms source material into long-form knowledge products.

The Knowledge Library exposes those products and their source relationships.

The compiler asks:

> How do we turn the corpus into chapters, books, source packs, knowledge packs, and derived outputs?

The Library asks:

> How does a user browse, search, understand, and download the canonical knowledge body?

The repository remains the source of truth. The Library should be a projection of repository knowledge, not a separate manually maintained knowledge silo.

### Relationship To The Ontology

The Canonical Ontology is the Library's conceptual spine.

Every major Library object should connect to ontology concepts where possible:

- chapters
- architecture docs
- research studies
- source packs
- QA routines
- examples
- implementation files
- roadmap milestones

The ontology allows search and navigation to move beyond filenames. Users should be able to start with "Artifact" and reach:

- the concept definition
- related concepts
- source chapters
- architecture docs
- policy docs
- experiments
- QA
- implementation references
- future roadmap items

### Relationship To Knowledge State

Knowledge State describes what a project knows.

The Knowledge Library describes what the product knows about itself.

These should remain distinct.

Project Knowledge State:

> What do we know about this dataset, model, decision, or business question?

Product Knowledge Library:

> What does Analytics Workstation mean by artifact, evidence, routing, encoding, readiness, investigation, or execution mode?

In future implementations, the Guide may use both. It may answer a project-specific question by referencing project Knowledge State and then linking to the Library for conceptual explanation.

## Primary Sections

### Welcome

The Welcome section introduces the product identity.

It should explain:

- Analytics Workstation is an evidence-centered analytical operating environment.
- The project is the world.
- Artifacts are evidence.
- The Collector is memory.
- The Guide teaches.
- The Library explains.
- The Book preserves.
- GenAI reasons over evidence rather than raw data.

Candidate content:

- Product Vision
- Manifesto
- Architecture Synthesis executive summary
- "How Analytics Workstation thinks"
- first conceptual map

The Welcome section should orient without overwhelming. It should feel like the front door to the system's philosophy.

### Learn

The Learn section provides role-based learning paths.

Initial paths:

- New User
- Business User
- Data Scientist
- Developer
- Researcher
- Technical Executive

Each path should recommend:

- concepts to learn first
- chapters to read
- architecture docs to inspect
- example workflows
- relevant UI modes
- optional deep dives

Example path: New User

1. Product Vision
2. Manifesto
3. Guide Architecture
4. Artifact Studio overview
5. Mission Control overview
6. Artifacts As Evidence chapter
7. Project Artifact Collector architecture

Example path: Data Scientist

1. Artifacts As Evidence
2. Artifact Quality Policy
3. Table Artifact Architecture
4. Evidence Routing Policy
5. Context Optimization Policy
6. GenAI Context Strategy Research
7. Information Encoding Policy

Example path: Developer

1. Architecture Synthesis
2. Service Result contracts
3. Project Artifact Collector
4. Artifact Model
5. QA contracts
6. Book Compiler Plan
7. Concept Ontology

### Concepts

The Concepts section exposes the Canonical Ontology.

Each concept should eventually have:

- canonical definition
- purpose
- parent concepts
- child concepts
- dependencies
- history
- problem solved
- examples
- related chapters
- related architecture docs
- related research
- related QA
- related code
- maturity
- open questions
- future evolution

Concept pages should make relationships navigable.

Example:

```text
Artifact
  parent: Analytical Evidence System
  children: Table Artifact, Artifact Bundle, Evidence Inspector
  related: Evidence, Collector, Artifact Quality Policy, Render Target
  chapters: Chapter 1, Chapter 5, Chapter 7
  docs: artifact model, collector, quality policy
  experiments: plot sizing gallery, table artifact QA
  code: artifact producer helpers, collector functions
```

The Concepts section is where the Library becomes more than documentation. It becomes a map.

### Architecture

The Architecture section groups architecture documents by theme.

Suggested groups:

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

Example grouping:

Evidence:

- Artifact Model
- Project Artifact Collector
- Artifact Quality Policy
- Table Artifact Architecture
- Producer Semantics

Knowledge:

- Knowledge State Architecture
- Investigation Planning Architecture
- Concept Ontology
- Concept Dependency Graph
- Architecture Causality

Routing and Optimization:

- Evidence Routing Policy
- Context Optimization Policy
- Marginal Information Gain Framework
- Evidence Strategy UX
- Information Encoding Policy

GenAI:

- GenAI Service Architecture
- Provider Architecture
- Context Strategy Research
- Vision-Model Support
- Learning Observability

UX:

- Product Vision
- UI/UX Architecture
- UX Roadmap
- Guide Architecture
- Artifact Studio
- Mission Control
- Command Palette

Book:

- Book Compiler Plan
- Source Packs
- Chapter Mapping
- Manuscript source

### Book

The Book section should expose the evolving manuscript directly.

It should eventually support:

- Markdown reading
- HTML rendering
- PDF
- DOCX
- EPUB
- chapter navigation
- source pack references
- version status
- reading progress
- download

The app should know which manuscript version is current.

Possible book states:

- raw source
- source chapter
- edited chapter
- compiled draft
- reviewed draft
- publication candidate

The Book section should not hide incompleteness. The book is a living manuscript. Source chapters are intentionally overcomplete until edited.

### Research

The Research section preserves experiments, findings, open questions, and calibration work.

It should include:

- image-vs-data studies
- context strategy experiments
- plot-type-aware research
- Evidence Routing calibration
- Context Optimization policy research
- AutoPlots composite view audit
- plot sizing gallery
- GenAI telemetry experiments
- async processing spikes
- UX research sprint

Research entries should distinguish:

- hypothesis
- method
- data/source
- finding
- limitation
- next experiment
- status

The Research section is important because many Analytics Workstation concepts are intentionally probabilistic. The Library should preserve not only what is known, but also what is uncertain and why.

### Timeline

The Timeline section should eventually show architecture evolution.

Possible timeline events:

- first AutoNLS redesign
- AutoQuant SHAP integration
- Artifact Model emergence
- Project Artifact Collector
- Render Targets
- Artifact Quality Policy
- Table Artifact Architecture
- Producer Semantics
- UI Workstation pivot
- Artifact Studio
- Mission Control
- Command Palette
- GenAI Provider Layer
- Context Strategy Research
- Evidence Routing
- Knowledge State
- Investigation Planning
- Execution Modes
- Guide Architecture
- Knowledge Library

Timeline events should connect to:

- source prompts
- architecture docs
- implementation changes
- QA validation
- empirical findings
- open questions

The goal is not nostalgia. The goal is traceability. Future contributors should see how the architecture emerged and why alternatives were rejected.

### Search

Search should eventually span:

- concepts
- chapters
- architecture docs
- research
- experiments
- examples
- QA
- roadmap
- code references

The search should be ontology-aware.

Examples:

- Searching "routing" should find Evidence Routing, Context Optimization, Evidence Strategy, Context Strategy, GenAI telemetry, and related chapters.
- Searching "artifact" should find Artifact, Artifact Studio, Artifact Quality Policy, Artifact Collector, Table Artifact Architecture, Artifact Studio demo seed, and Chapter 1.
- Searching "why SHAP" should surface Guide explanations, SHAP Analysis architecture, Evidence Routing, and relevant research.

The first implementation can be deterministic and file-based. Future implementations may use indexed search, semantic search, or GenAI-assisted retrieval, but the architecture should not depend on GenAI.

### Downloads

Downloads should eventually include:

- full book
- individual chapters
- architecture docs
- research reports
- white papers
- knowledge packs
- source packs
- GPT knowledge-base bundles
- role-specific onboarding packets
- custom documentation bundles

The download system should preserve traceability. A downloaded knowledge pack should know which source files, commit, chapters, concepts, and experiments produced it.

### Cross Linking

Cross linking is essential.

The Library should not become a folder browser. It should make relationships explicit.

Example relationship chain:

```text
Artifact
  -> Chapter 1: Artifacts As Evidence
  -> Artifact Model Architecture
  -> Artifact Quality Policy
  -> Project Artifact Collector
  -> Plot Sizing Gallery
  -> Artifact Studio
  -> QA Artifact Quality Policy
  -> implementation references
  -> related concepts
```

Every major page should answer:

- What is this?
- Why does it exist?
- What depends on it?
- What does it depend on?
- Where is it explained in the book?
- Where is it implemented?
- What experiments validate or challenge it?
- What remains open?

## Knowledge Object Model

The Library should eventually operate over a standardized knowledge object model.

Potential object types:

- concept
- architecture_doc
- policy_doc
- source_chapter
- book_section
- research_study
- experiment_result
- qa_contract
- roadmap_item
- implementation_reference
- source_pack
- timeline_event
- download_bundle

Each knowledge object should have:

- id
- title
- object_type
- summary
- source_path
- status
- maturity
- related_concepts
- related_docs
- related_chapters
- related_code
- related_experiments
- related_qa
- last_updated
- source_commit
- tags

This object model is not implemented in this task. It is the future contract that allows the Library, Guide, Book Compiler, and GPT knowledge packs to use the same canonical knowledge base.

## UI Concepts

This section evaluates possible layouts. No implementation is implied.

### Library Page

A dedicated Knowledge Library mode.

Strengths:

- clear product identity
- easy to explain
- enough room for browsing, reading, search, and cross-links
- matches the importance of the knowledge system

Weaknesses:

- may feel separate from active work if not connected to the Guide
- can become a documentation portal if poorly designed

Best use:

- primary home for architecture, book, research, and concepts

### Knowledge Explorer

A concept-first explorer organized around ontology relationships.

Strengths:

- makes architecture navigable
- supports concept graph and dependency exploration
- encourages non-linear learning

Weaknesses:

- can overwhelm new users
- graph interfaces are easy to make visually impressive but cognitively weak

Best use:

- Concepts section and advanced exploration

### Search-First Library

A search box is the primary entry point.

Strengths:

- fast for experts
- supports direct lookup
- works well as the library grows

Weaknesses:

- weak onboarding
- assumes users know what to search for

Best use:

- persistent Library search and command palette integration

### Book Reader

A reading interface for source chapters and compiled book outputs.

Strengths:

- makes the manuscript feel real
- supports long-form learning
- helps technical executives and researchers understand the full argument

Weaknesses:

- less useful for quick lookup
- requires strong cross-linking to avoid becoming isolated

Best use:

- Book section

### Documentation Browser

A tree navigation over docs and source files.

Strengths:

- simple
- faithful to repository structure
- easy to implement

Weaknesses:

- exposes file organization rather than concept organization
- weak product experience

Best use:

- developer fallback view or source inspector

### Concept Graph

A visual graph of concepts and dependencies.

Strengths:

- can reveal relationships
- aligns with ontology and dependency graph
- useful for architecture discussion

Weaknesses:

- graph interfaces can become visual noise
- not ideal as the default learning surface

Best use:

- optional view inside Concepts

## Recommended Product Direction

Use a layered Library:

1. Welcome: product identity and manifesto.
2. Learn: role-based paths.
3. Concepts: ontology-backed concept pages.
4. Architecture: grouped canonical docs.
5. Book: readable manuscript and compiled outputs.
6. Research: experiments, findings, open questions.
7. Timeline: architecture evolution.
8. Search: ontology-aware global lookup.
9. Downloads: books, docs, packs, and future custom bundles.

The default should be approachable, not encyclopedic. The depth should be available immediately when needed.

## Guide And Library Interaction Patterns

The Guide should be able to link into the Library using stable references:

- `open_concept`
- `open_chapter`
- `open_architecture_doc`
- `open_research_study`
- `open_experiment`
- `open_qa_reference`
- `open_related_code`

The Library should be able to call back into the Guide:

- `ask_guide_about_current_project`
- `ask_guide_for_next_step`
- `ask_guide_to_explain_current_concept`
- `ask_guide_how_this_applies`

These are interaction concepts only. They should not be implemented here.

## Content Governance

The repository remains the source of truth.

The Library should not encourage editing knowledge directly inside the app until a governance model exists.

Future governance questions:

- Which docs are canonical?
- Which docs are historical?
- Which docs are derived?
- Which docs are research?
- Which knowledge objects can be generated?
- Which knowledge objects require review?
- How are stale docs detected?
- How are concept definitions versioned?
- How are download bundles traced to source?

The Book Compiler Plan already defines a documentation hierarchy. The Knowledge Library should expose and operationalize that hierarchy.

## Relationship To GenAI

The Library must work without GenAI.

Without GenAI, it can still provide:

- deterministic navigation
- concept pages
- chapter reading
- architecture browsing
- search over known metadata
- downloads

With GenAI, it can additionally support:

- natural-language concept lookup
- guided reading suggestions
- summarization of long docs
- comparison of related concepts
- question answering grounded in Library objects
- generation of custom knowledge packs

GenAI should not become the source of truth. It should be a retrieval and explanation layer over curated knowledge objects.

## Future Knowledge Packs

The Library should eventually support knowledge packs for:

- Custom GPT upload
- internal onboarding
- conference talks
- white papers
- technical executive briefings
- developer onboarding
- role-specific training
- external documentation

Knowledge packs should be traceable. They should list:

- included concepts
- included chapters
- included docs
- included experiments
- generation timestamp
- source commit
- intended audience
- compression strategy

This aligns the Library with the Book Compiler and prevents knowledge products from becoming one-off exports.

## Success Criteria

The Knowledge Library succeeds when:

- users can learn the system without reading the repository manually
- concepts are searchable and navigable
- architectural decisions are understandable
- the evolving book is accessible from inside the product
- research and experiments remain connected to product decisions
- the Guide can link to authoritative explanations
- contributors can understand why the software behaves as it does
- documentation becomes a first-class product surface

The Library should make the workstation feel more coherent, not heavier. It should reduce cognitive load by making the product's knowledge structure visible.

## Open Questions

- Should the first implementation be a full workstation mode or a lightweight Library drawer?
- How much source repository structure should be exposed to non-developer users?
- What metadata should be required for every knowledge object?
- Should concept pages be generated from the ontology or manually curated?
- Should the Book section show raw source chapters, edited chapters, or both?
- How should stale documentation be detected?
- What is the right boundary between Library search and Guide conversation?
- Should custom knowledge packs be generated from the Book Compiler or from the Library object model?
- How should implementation references be presented without overwhelming business users?
- Should the Library eventually support annotation and review workflows?

## Initial Milestones

Architecture only in this task. Future implementation could proceed in stages:

1. Knowledge inventory: deterministic index of docs, chapters, concepts, and research.
2. Library shell: Welcome, Learn, Concepts, Architecture, Book, Research.
3. Concept pages: generated from ontology entries.
4. Cross-links: concept-to-doc, doc-to-chapter, chapter-to-source.
5. Book reader: Markdown source chapter reader.
6. Search: deterministic filename, title, heading, and concept search.
7. Downloads: static book and chapter downloads.
8. Guide integration: "Read more" and "Open concept" links.
9. Timeline: architecture evolution from source packs and chronology.
10. Knowledge packs: role-specific and GPT-ready bundles.

## Phase 1 Implementation

Phase 1 implements the first usable Knowledge Library page inside Analytics Workstation.

The goal is immediate author usability: sit inside the workstation, browse the evolving manuscript, read chapters, inspect architecture docs, and review the institutional knowledge corpus without leaving the app.

Implemented capabilities:

- top-level `Knowledge Library` workstation page
- three-column layout:
  - left Knowledge Navigator
  - center Markdown reader
  - right Context Panel
- repository-backed document discovery
- sections for Welcome, Book, Architecture, Concepts, Research, Experiments, Timeline, Roadmap, and Open Questions
- automatic discovery from `book/source/`, `docs/`, roadmap docs, research docs, source packs, and experiment summaries where present
- Markdown rendering through `commonmark` when available
- fallback Markdown rendering path for basic display
- heading, list, table, code block, link, and blockquote styling through the dark workstation design system
- table of contents extracted from Markdown headings
- current reading summary
- recent document tracking for the current session
- Continue Reading control
- Download Markdown for the selected source file
- author-mode controls:
  - Open Source File
  - Open Folder
  - Reveal in Explorer
  - Refresh Library
- book status metrics:
  - Book Version
  - Source Chapters
  - Words
  - Estimated Pages
  - Concept Count
  - Architecture Version
  - Ontology Version
- deterministic placeholder Context Panel:
  - Related Concepts
  - Related Chapters
  - Architecture Docs
  - Open Questions
  - Future Work
  - Implementation Status
- Command Palette entry for opening the Knowledge Library
- `qa_knowledge_library()`

Phase 1 deliberately does not implement:

- full-text search
- semantic search
- GPT summaries
- Guide integration
- concept graph visualization
- annotation
- notes
- editing
- PDF/DOCX/EPUB book generation
- custom knowledge packs
- version history

The page should be treated as the first reader-oriented projection of the repository knowledge base, not the final Knowledge Library.

## Phase 1 Current Boundaries

The Library is read-only.

The repository remains the source of truth.

The Context Panel uses deterministic placeholder relationships rather than a full ontology graph.

Recent documents are tracked only for the current Shiny session.

Search is represented as a disabled/placeholder input so the layout reserves space without implying the feature exists.

Book downloads beyond the currently selected Markdown file remain in the Book Compiler roadmap.

## Future Implementation Roadmap

Phase 2 should make concept pages real. Ontology entries should become navigable objects with definitions, relationships, chapters, docs, research, QA, implementation references, maturity, and open questions.

Phase 3 should add deterministic full-text search across titles, headings, concepts, and file paths. This should not require GenAI.

Phase 4 should add Guide integration. Guide responses should be able to open Library concepts, chapters, architecture docs, and research entries.

Phase 5 should add persistent reading state, annotations, and notes for author review.

Phase 6 should connect to the Book Compiler for generated book outputs, knowledge packs, GPT bundles, and audience-specific downloads.

Phase 7 may add semantic search or GenAI-assisted summaries over curated Library objects. GenAI should remain an explanatory layer over repository truth, not the source of truth.
