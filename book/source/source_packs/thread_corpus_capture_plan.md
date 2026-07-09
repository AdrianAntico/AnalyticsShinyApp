# Thread Corpus Capture Plan

Status: completeness-first source preservation plan  
Purpose: preserve the full intellectual history behind Analytics Workstation and the AI-native analytical systems book before pruning, polishing, or audience-specific rendering.

## Why This Exists

The book cannot rely only on the most recent ChatGPT or Codex context window. The architecture emerged across multiple long conversations, repository changes, experiments, visual QA passes, and documentation tasks. Some of that knowledge exists in the current Codex thread. Some exists in an earlier AutoQuant-origin Codex thread. Some may exist only in the regular ChatGPT web interface or another exported conversation.

The goal is full capture first.

```text
Capture everything
-> classify
-> cluster
-> synthesize
-> prune later
```

This mirrors the Book Compiler Plan:

```text
Truth
-> Knowledge Base
-> Representation
-> Delivery
```

The raw conversation corpus is not the final book. It is source material.

## Corpus Sources

### Source A: Current Codex Thread

Repository context:

```text
C:\Users\Bizon\Documents\GitHub\AnalyticsShinyApp
```

Status:

- available through the current active context and repository artifacts
- not fully exported as a raw transcript yet
- many task prompts are present in the active conversation context
- many results are preserved in generated docs, code, QA outputs, and final summaries

Capture strategy:

- preserve the high-level chronology in `thread_corpus_inventory.md`
- preserve task prompts when available from current context
- link each task to created docs/code
- later export raw transcript if the Codex app exposes it or if the user provides it

### Source B: Original AutoQuant-Origin Codex Thread

Thread id:

```text
019f28e3-50a4-7141-bd00-6267c32b0abe
```

Title:

```text
Create Shiny app skeleton
```

Original working directory:

```text
C:\Users\Bizon\Documents\GitHub\AutoQuant
```

Status:

- listed by Codex thread tools
- readable by pagination
- contains the origin of the Analytics Shiny App / AnalyticsShinyApp project extraction
- includes the initial doctrine around AutoPlots-powered local-first Shiny/Electron app development
- includes handoff to the AnalyticsShinyApp repo/thread

Capture strategy:

- page through the thread and record all turns
- preserve full prompts when possible
- extract decisions, doctrine, implementation milestones, and file changes
- treat this as historical source material for the early "why this became a workstation" chapters

### Source C: AnalyticsShinyApp Continuation Codex Thread

Thread id:

```text
019f2de2-6fed-7372-afd6-a4167be8b344
```

Title:

```text
Continue app work
```

Working directory:

```text
C:\Users\Bizon\Documents\GitHub\AnalyticsShinyApp
```

Status:

- readable by Codex thread tools
- contains a broad ecosystem audit and likely additional continuation history
- contains handoff metadata from the AutoQuant-origin thread

Capture strategy:

- page through the thread
- preserve source decisions and architecture transitions
- connect to repository docs and git history

### Source D: Regular ChatGPT Web Thread(s)

Status:

- not automatically accessible from this Codex environment unless exported or pasted
- user reports the original web thread went defunct and the current web interface is only aware of the most recent thread

Capture strategy:

- user should export or paste the web thread if possible
- store raw export under a future ignored/raw-source location or summarized source pack
- do not treat missing web-only material as captured until it exists in the repo

Recommended future location:

```text
book/source/raw_conversations/
```

Possible files:

```text
chatgpt_original_thread_export.md
chatgpt_followup_thread_export.md
codex_current_thread_export.md
codex_autoquant_origin_thread_export.md
```

## Capture Levels

### Level 0: Raw Transcript

Preserve the conversation as close to original as possible.

Includes:

- user prompts
- assistant responses
- tool outputs where relevant
- file references
- dates
- thread ids
- repo cwd

Use when available.

### Level 1: Chronological Inventory

Summarize every task turn in order.

Includes:

- task title
- date/order
- repo
- requested work
- output artifacts
- files changed
- QA run
- conceptual contribution

Use when raw transcript is too large or unavailable.

### Level 2: Concept Cluster

Group material by concept:

- Artifact Model
- Collector
- Render Targets
- Information Encoding
- Evidence Routing
- Context Optimization
- MIG
- GenAI
- UX modes
- AutoPlots composites
- Book Compiler

Use for Source Packs.

### Level 3: Manuscript Source

Transform clusters into long-form chapter drafts.

Use for:

- `book/source/part_*.md`
- white papers
- GPT knowledge packs

## Non-Negotiable Completeness Rules

1. Do not prune during capture.
2. Preserve uncertainty and contradictions.
3. Preserve user corrections.
4. Preserve failed paths when they influenced the architecture.
5. Preserve terminology migrations.
6. Preserve "why" decisions, not only final "what" artifacts.
7. Preserve QA failures and known gaps.
8. Preserve model/provider limitations.
9. Preserve visual QA feedback.
10. Preserve source provenance for every chapter claim when possible.

## What Counts As Source

Conversation source:

- task prompts
- user corrections
- assistant plans
- final summaries
- visual QA notes
- conceptual breakthroughs

Repository source:

- docs
- code
- README changes
- QA functions
- generated reports
- experiment outputs
- screenshots
- source packs
- git commits

External source:

- exported ChatGPT web threads
- model/provider setup notes
- local experiment outputs
- screenshots from manual review

## Immediate Capture Actions

1. Preserve this plan.
2. Preserve `thread_corpus_inventory.md` with the current known chronology.
3. Page through readable Codex threads and append turn inventories.
4. Add source pack references for each major architecture concept.
5. Ask user for exported ChatGPT web threads if material exists only there.
6. Later create raw transcript files when export access exists.

## Known Access Boundary

This Codex environment can inspect local Codex threads exposed by the app's thread tools.

It cannot automatically inspect the regular ChatGPT web interface conversation history unless the user exports or pastes that content into the workspace.

Therefore, any web-only thread is not captured until it is copied into the repo.

## Desired End State

The desired end state is a complete book source corpus:

```text
book/source/
  README.md
  part_01_foundations.md
  source_packs/
    thread_corpus_capture_plan.md
    thread_corpus_inventory.md
    glossary_source_pack.md
    artifacts_source_pack.md
    collector_source_pack.md
    mig_source_pack.md
    genai_source_pack.md
  raw_conversations/
    ...
```

The corpus should be deliberately overcomplete. Trimming comes later.

