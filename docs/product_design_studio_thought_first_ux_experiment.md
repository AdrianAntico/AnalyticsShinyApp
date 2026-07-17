# Product Design Studio

Thought-First UX Experiment: design human thinking before designing software.

This document intentionally does not redesign the current interface.

It does not start from pages, cards, tabs, columns, controls, or Bootstrap structure. Those are later consequences. This experiment starts from the user's internal monologue and asks a harder question:

```text
Where does Analytics Workstation interrupt human reasoning?
```

The governing principle is:

```text
The application should never interrupt one human thought with another.
```

The interface exists only to support uninterrupted reasoning. If a visible element cannot be traced to a specific human thought, it is probably misplaced, premature, or unnecessary.

## Method

The method has four steps.

1. Ignore the current UI.
2. Write the user's thoughts in order.
3. Inspect the current UI for forced thought switching.
4. Derive the future experience from the ideal thought sequence.

This is not a layout exercise. It is a cognition exercise.

## Core User Thoughts

### Project

```text
I need a place for this work.
What am I trying to accomplish?
What should I call this work?
Where should it live?
Can I trust that I know where it will be saved?
Create it.
Did it work?
What exists now?
What should I do next?
```

The project thought is about commitment. The user is not thinking about storage providers, workspace roots, RDS files, manifests, or lifecycle state. Those may be real implementation concerns, but they are not the first human concern.

The human concern is:

```text
I am establishing a durable analytical world.
```

### Data

```text
I have data.
Can I bring it in?
Did it load correctly?
What is in it?
Is it the right shape?
Does it have the fields I need?
Is anything obviously wrong?
Can I start analysis now?
```

The data thought is about orientation. The user is not yet asking for advanced profiling, transformation lineage, or modeling readiness. The first question is whether the dataset is present, recognizable, and usable.

The human concern is:

```text
Do I have the raw material for this investigation?
```

### Workflow

```text
Where am I in the analytical journey?
What have I already done?
What has not been done yet?
What should happen next?
Why is that the next step?
Can I go there directly?
```

The workflow thought is not about the registry. It is not about implemented, planned, or experimental modules. Those are software truths. The user wants a route.

The human concern is:

```text
What is the next sensible analytical move?
```

### Evidence

```text
What do we know?
What supports that?
What is weak?
What contradicts it?
What is missing?
Do we know enough to act?
If not, what evidence would matter most?
```

The evidence thought is about sufficiency. The user is not asking for artifact metadata first. Metadata matters after the claim is clear.

The human concern is:

```text
Can this conclusion survive scrutiny?
```

### Decision

```text
What are we deciding?
What are the real alternatives?
What happens if we do nothing?
What is the expected upside?
What is the risk?
Who has authority?
What evidence supports the recommendation?
What uncertainty remains?
What should we do?
What should we review later?
```

The decision thought is about accountability. The user is not thinking about semantic objects, workflow artifacts, or valuation rows. They are trying to move from evidence to responsible action.

The human concern is:

```text
What action is justified, and can we defend it later?
```

### Artifact

```text
What am I looking at?
Why does it exist?
What does it show?
How trustworthy is it?
What should I notice?
What are its limitations?
Where did it come from?
What can I do with it?
```

The artifact thought is investigative. The user should feel as if they opened a piece of evidence, not a saved output. The artifact is not the end of a module. It is a clue in an investigation.

The human concern is:

```text
What does this evidence tell me?
```

### Knowledge

```text
What do I need to understand?
Where is the authoritative explanation?
How does this concept relate to the system?
What should I read next?
Can I return to where I was?
```

The knowledge thought is about comprehension. The user is not trying to manage documentation. They are trying to stabilize meaning.

The human concern is:

```text
Help me understand the system without leaving the system.
```

### Mission

```text
What needs my attention?
Is anything blocked?
Is anything failing?
What changed recently?
What is the highest-priority risk?
What should I do now?
```

The mission thought is about situational awareness. The user is not asking for every status at equal weight. They want the thing that matters now.

The human concern is:

```text
What deserves my attention first?
```

### Guide

```text
I am here.
What kind of work am I trying to do?
What does this system help me with?
Where should I begin?
Why that path?
What should I learn only if I need it?
```

The guide thought is about orientation and confidence. It should not feel like documentation, chat, or a menu. It should feel like a senior person asking the right first question.

The human concern is:

```text
Help me begin without making me understand the whole system.
```

### Export

```text
What do I need to share?
Who is it for?
What evidence is included?
What format do they need?
Where will it be saved?
Did export succeed?
Can I open or send it?
```

The export thought is about delivery. The user is no longer investigating; they are packaging a communicable result.

The human concern is:

```text
Turn this evidence into something someone else can consume.
```

## Thought Switching Audit

This audit names where the current application asks the user to change thoughts before the current thought has finished.

### Project Interruptions

Ideal thought:

```text
I need a project.
What should it be called?
Where should it live?
Create it.
Did it work?
What next?
```

Observed interruptions:

```text
Project
-> Workspace
-> Provider
-> Location mode
-> Path mechanics
-> Project file
-> Collector
-> AI readiness
-> Project
```

The Project page has improved dramatically, but it still carries traces of software organization. The duplicate-output warning found during browser validation is a technical symptom of the same product problem: more than one surface is still trying to own the same project confirmation thought.

Interruption class:

- infrastructure before commitment;
- repeated confirmation surfaces;
- technical state before human success state.

Design implication:

The user should complete the thought "I created or opened a project" before seeing collector, evidence memory, AI readiness, or advanced saved-file mechanics.

### Data Interruptions

Ideal thought:

```text
I have data.
Load it.
Did it load?
What does it contain?
Can I analyze it?
```

Observed interruptions:

```text
Data
-> File type mechanics
-> Dataset status
-> Preview
-> Next action
-> Possible module path
```

This page is close to the correct thought sequence when empty. The risk appears after data is loaded: tables can dominate and spill, turning orientation into horizontal navigation. The user thought changes from "what is in my data?" to "how do I operate this table?"

Interruption class:

- data preview becomes table mechanics;
- next action competes with orientation;
- table width can pull attention away from meaning.

Design implication:

The first loaded-data state should answer "what did I load?" before showing many rows. Preview rows should serve recognition, not become the primary workspace.

### Workflow Interruptions

Ideal thought:

```text
Where am I?
What has happened?
What is next?
Why?
Take me there.
```

Observed interruptions:

```text
Workflow
-> Stage registry
-> Module implementation status
-> Artifact counts
-> Report plan counts
-> Code hooks
-> Workflow
```

The current workflow surface exposes a useful truth too early: the system knows stages as registry entries. The user does not want a registry. They want a path.

Interruption class:

- implementation status before journey state;
- module concepts before user action;
- code hooks before ordinary next step.

Design implication:

Workflow should read like an itinerary first and a registry second. "You are here" and "go here next" should complete before the app exposes stage internals.

### Evidence Interruptions

Ideal thought:

```text
What is the claim?
What supports it?
What weakens it?
Do we know enough?
What evidence is missing?
```

Observed interruptions:

```text
Evidence claim
-> Action dock
-> Evidence categories
-> Contradictions
-> Sufficiency
-> Valuation
-> Detail
```

Evidence Review is one of the best-aligned pages because it already begins from reasoning rather than software. The remaining risk is density: multiple types of epistemic information can appear as peer concepts before the primary claim is stable.

Interruption class:

- claim, action, sufficiency, valuation, and contradictions can compete;
- detail can appear as another object rather than depth.

Design implication:

Evidence Review should behave like a courtroom sequence: claim first, admissible evidence second, cross-examination third, sufficiency fourth, action last.

### Decision Interruptions

Ideal thought:

```text
What are we deciding?
What are the alternatives?
What does evidence justify?
What are the tradeoffs?
Who must approve?
What action do we take?
How will we remember the outcome?
```

Observed interruptions:

```text
Decision
-> Evidence Review link
-> Semantic editing
-> Project health
-> Alternatives
-> Tradeoffs
-> Economics
-> Governance
-> Detail
```

Decision Management is conceptually strong, but it risks splitting the decision thought into specialized professional sub-thoughts before the user has emotionally landed on the decision itself.

Interruption class:

- related workrooms appear before the decision question;
- economics and governance can appear as separate domains rather than parts of one accountable choice.

Design implication:

The page should first ask "what decision is on the table?" and "what are the options?" Everything else should attach to an option or to readiness.

### Artifact Interruptions

Ideal thought:

```text
What is this artifact?
What does it show?
Can I trust it?
What should I do with it?
```

Observed interruptions:

```text
Artifact
-> Filters
-> Gallery
-> Inspector
-> Filmstrip
-> Metadata
-> Backing assets
```

Artifact Studio is valuable and visually distinct, but the user can still begin in collection-management thought instead of evidence-reading thought. Filters are powerful, but they are not the first question when a user opens an artifact.

Interruption class:

- browsing controls before selected evidence;
- evidence volume before evidence meaning;
- metadata can overwhelm interpretation.

Design implication:

Artifact Studio should increasingly behave like "open evidence, then browse" rather than "filter a database, then inspect."

### Knowledge Interruptions

Ideal thought:

```text
I need to understand something.
Show me the authoritative source.
Let me move through it.
Show related concepts only when helpful.
Let me return.
```

Observed interruptions:

```text
Knowledge
-> Navigator stats
-> Section picker
-> Document picker
-> Reader
-> Context panel
-> Author mode
```

The Knowledge Library still carries document-management gravity. The reader is the human thought. Version counts, source chapters, architecture versions, and author actions are useful but can interrupt reading if they appear before the user's comprehension task.

Interruption class:

- library administration before reading;
- metadata before meaning;
- author mode visible during reader mode.

Design implication:

Knowledge Library should begin with "continue understanding" and defer collection statistics, author actions, and source management.

### Mission Interruptions

Ideal thought:

```text
What needs my attention?
Why?
What should I do?
Did anything fail?
What changed?
```

Observed interruptions:

```text
Mission
-> Health
-> Priority
-> System status
-> Alerts
-> Decisions
-> Async jobs
-> GenAI
-> Timeline
```

Mission Control is close to the right mental model, but it can still show many forms of status as if they are equally important. A control room works only when the room knows what matters now.

Interruption class:

- parallel status surfaces compete for attention;
- operational categories before priority;
- AI status can appear as a peer to project state even when no project exists.

Design implication:

Mission Control should be ruthless: one current priority, one reason, one recommended action, then everything else.

### Guide Interruptions

Ideal thought:

```text
I am new or returning.
What kind of situation am I in?
What should I do first?
Why?
What can I learn later?
```

Observed interruptions:

```text
Guide
-> Business question
-> Workspace state
-> Recommendation
-> Primary actions
-> Investigation
-> Learning architecture
-> Health
-> AI assistance
```

Guide is directionally strong because it starts with intent. The risk is that it tries to teach the entire operating philosophy too early. A senior mentor does not explain the whole architecture before asking what decision the user is trying to make.

Interruption class:

- education before orientation is complete;
- many starting points can recreate menu thinking;
- architecture concepts can compete with first action.

Design implication:

The first Guide state should feel like a conversation with a mentor: "What situation are you in?" Then it should reveal only the path that situation implies.

### Export Interruptions

Ideal thought:

```text
What do I need to share?
Who is it for?
What will be included?
Where will it go?
Export it.
Did it work?
```

Observed interruptions:

```text
Export
-> Output directory
-> HTML
-> R code
-> Report plans
-> Artifact file mechanics
```

Export currently behaves like a file writer. The human thought is delivery. The difference matters because delivery includes audience, contents, format, destination, and receipt.

Interruption class:

- file settings before audience;
- format before contents;
- no strong receipt thought after export.

Design implication:

Export should become a delivery confirmation sequence: audience, package, destination, receipt.

## Mental Storyboards

These are not wireframes. They are thought sequences.

### Project Storyboard

Frame 1:

```text
I need a project for this work.
```

The system asks for the minimum commitment: name or open existing.

Frame 2:

```text
Where should this work live?
```

The system offers only real available location choices. Unsupported choices do not pretend to exist.

Frame 3:

```text
Create it.
```

The system confirms the exact destination before creation.

Frame 4:

```text
It exists. What now?
```

The system shows project identity, recent confirmation, and the next action.

Recommended experience:

Project should feel like setting up a durable room. The room should be empty but ready. The user should not meet storage architecture until the room exists.

Rejected concepts:

- showing collector details before project creation;
- making location provider selection feel like a product concept;
- asking for project file mechanics before the user has a project.

### Data Storyboard

Frame 1:

```text
I have data.
```

The system invites upload/open.

Frame 2:

```text
Did it load?
```

The system gives a simple receipt: file name, rows, columns, detected date fields, possible target fields.

Frame 3:

```text
What is in it?
```

The system shows compact recognition: column families, sample rows, missingness hints.

Frame 4:

```text
Can I analyze it?
```

The system proposes the next analytical step.

Recommended experience:

Data should not become a spreadsheet. It should become an intake receipt plus recognition surface.

Rejected concepts:

- leading with a large scrollable table;
- treating file-type support as the main story;
- asking for analysis configuration before data recognition.

### Workflow Storyboard

Frame 1:

```text
Where am I?
```

The system marks the current analytical stage.

Frame 2:

```text
What has been done?
```

The system shows completed evidence, not module completion for its own sake.

Frame 3:

```text
What is next?
```

The system names one recommended next move.

Frame 4:

```text
Why?
```

The system explains the missing evidence or decision need.

Frame 5:

```text
Take me there.
```

The system opens the right surface.

Recommended experience:

Workflow should feel like a guided itinerary through evidence production.

Rejected concepts:

- registry table as primary object;
- code hooks as first-class ordinary workflow controls;
- planned modules competing with implemented next steps.

### Evidence Storyboard

Frame 1:

```text
What claim are we evaluating?
```

The system states the claim plainly.

Frame 2:

```text
What supports it?
```

The system presents strongest evidence.

Frame 3:

```text
What weakens it?
```

The system presents contradictions, caveats, and missing evidence.

Frame 4:

```text
Do we know enough?
```

The system assesses sufficiency.

Frame 5:

```text
What should happen next?
```

The system recommends act, defer, collect more evidence, or reject the claim.

Recommended experience:

Evidence Review should feel like reasoned scrutiny, not a dashboard. It should let one claim pass through support, challenge, sufficiency, and action.

Rejected concepts:

- showing all evidence categories at equal priority;
- making metadata visually peer to reasoning;
- beginning with artifact inventory rather than a claim.

### Decision Storyboard

Frame 1:

```text
What are we deciding?
```

The system names the decision question.

Frame 2:

```text
What are the options?
```

The system presents the alternatives including doing nothing.

Frame 3:

```text
What does the evidence justify?
```

The system connects evidence to each alternative.

Frame 4:

```text
What is the tradeoff?
```

The system compares benefit, cost, risk, reversibility, and authority.

Frame 5:

```text
What do we do?
```

The system produces a governed decision action or asks for more evidence.

Frame 6:

```text
How will we learn from it?
```

The system attaches review and follow-up.

Recommended experience:

Decision should feel like a consequential choice under uncertainty. The page should not make the user assemble decision meaning from economic, semantic, and workflow fragments.

Rejected concepts:

- starting with semantic editing;
- separating economics and governance before alternatives are understood;
- hiding baseline/no-action comparison.

### Artifact Storyboard

Frame 1:

```text
What is this?
```

The system identifies the artifact in human language.

Frame 2:

```text
What does it show?
```

The system highlights the main finding.

Frame 3:

```text
Can I trust it?
```

The system shows quality, completeness, diagnostics, and caveats.

Frame 4:

```text
What can I do with it?
```

The system offers inspect, cite, export, compare later, or use in decision.

Frame 5:

```text
Where did it come from?
```

The system reveals provenance and backing files.

Recommended experience:

Artifact Studio should increasingly treat the selected artifact as the primary object and browsing as secondary.

Rejected concepts:

- filters before meaning;
- filmstrip as decoration rather than memory;
- metadata visible before interpretation.

### Knowledge Storyboard

Frame 1:

```text
I need to understand this concept.
```

The system opens the most relevant explanation.

Frame 2:

```text
Where am I in the knowledge base?
```

The system gives a lightweight location marker.

Frame 3:

```text
What should I read next?
```

The system shows related concepts and chapters.

Frame 4:

```text
Can I get back to my work?
```

The system preserves return context.

Recommended experience:

Knowledge Library should feel like a reading room inside the product, not a documentation file browser.

Rejected concepts:

- statistics before reading;
- author tools competing with reader tools;
- table of contents becoming a separate navigation problem.

### Mission Storyboard

Frame 1:

```text
What needs attention?
```

The system names the highest-priority item.

Frame 2:

```text
Why does it matter?
```

The system explains consequence.

Frame 3:

```text
What action resolves or advances it?
```

The system provides one next action.

Frame 4:

```text
What else should I know?
```

The system reveals secondary queues.

Recommended experience:

Mission Control should be an attention-management surface. Its primary job is not to show all statuses. Its job is to protect attention.

Rejected concepts:

- equal-weight status grids;
- AI/provider status as always prominent;
- timeline before current priority.

### Guide Storyboard

Frame 1:

```text
What situation am I in?
```

The system offers human situations: I have data, I have a question, I have a model, I have an existing project, I want to learn.

Frame 2:

```text
What should I do first?
```

The system recommends one path.

Frame 3:

```text
Why?
```

The system gives a short reason.

Frame 4:

```text
What do I need to know now?
```

The system teaches only the concept needed for the next step.

Recommended experience:

Guide should be a mentor, not a homepage. It should ask one orienting question and then reduce the next move.

Rejected concepts:

- full architecture introduction before intent;
- many equal primary actions;
- treating Guide as documentation or chat.

### Export Storyboard

Frame 1:

```text
Who is this for?
```

The system asks audience or render target.

Frame 2:

```text
What evidence should they receive?
```

The system shows selected package contents.

Frame 3:

```text
Where should it go?
```

The system confirms destination.

Frame 4:

```text
Export it.
```

The system writes the package.

Frame 5:

```text
Did it work?
```

The system shows a delivery receipt.

Recommended experience:

Export should feel like handing off evidence, not operating a file-output panel.

Rejected concepts:

- format toggles before audience;
- destination before package contents;
- success messages without a durable receipt.

## Recommended Experience Direction

The next product leap is not "better pages." It is a thought choreography layer.

The application should move from:

```text
Page -> controls -> output -> status
```

to:

```text
Thought -> completion -> transition -> next thought
```

The most important design question becomes:

```text
What thought is the user trying to finish right now?
```

Only after that is answered should the product decide whether the user needs a button, table, chart, text field, inspector, action, or transition.

## New Abstraction: Thought Contract

A new abstraction emerges from this exercise:

```text
Thought Contract
```

A Thought Contract defines:

- the user's current thought;
- what would complete that thought;
- what evidence or feedback proves it completed;
- what thought naturally follows;
- what concepts must be deferred until later.

This is not a software architecture contract yet. It is a product design contract. It should precede page design.

Example:

```text
Thought: I need a project.
Completion: project exists or an existing project is open.
Proof: name, location, recent activity, saved state.
Next thought: I need data or evidence.
Defer: collector internals, manifest, AI readiness, project file mechanics.
```

## Page Priority Assessment

### Where The Application Most Interrupts Thought

1. Workflow interrupts path-thinking with registry-thinking.
2. Export interrupts delivery-thinking with file-setting-thinking.
3. Knowledge Library interrupts reading-thinking with library-management-thinking.
4. Artifact Studio can interrupt evidence-reading with collection-management.
5. Semantic and Causal Intelligence interrupt business/causal reasoning with dense authoring mechanics.

### Where The Application Forces Software Thinking

- Storage/provider concepts on Project.
- Module identity on Analysis Modules.
- Stage registry on Workflow.
- Report plan mechanics on Layout.
- Export file mechanics on Export.
- Author mode and source statistics on Knowledge Library.
- Runtime, task routing, and diagnostics on AI Runtime.
- Developer/replay artifacts on Product Experience.

Some of these are appropriate on developer surfaces. They are interruptions only when they appear before the user's primary thought is complete.

### Page That Suffers Most

Workflow suffers most conceptually.

It should be the purest "what next?" page, but it still exposes the system's internal map. A user should not need to understand implemented stages, code hooks, artifact counts, and report-plan counts before understanding where to go.

### Page That Already Aligns Well

Evidence Review aligns best.

It already thinks in claims, support, contradictions, sufficiency, and action. It is closest to reasoning choreography rather than software organization.

Guide also aligns directionally because it begins from user intent, but it still risks teaching too much too soon.

### First Page To Redesign From This Method

Workflow should be redesigned first.

Reason:

- It is central to user movement.
- It currently carries a high thought-interruption load.
- It can become the bridge between Guide, Data, Evidence, Decision, Artifact Studio, and Export.
- Improving it would reduce confusion across the whole product without requiring a shell redesign.

The second candidate is Export, because it can be made dramatically better by reframing from "write files" to "deliver evidence."

### What Surprised Me

The biggest surprise is that Project is no longer the most important page to redesign. It was the first visible pain point, but the deeper issue is now transition quality.

The product is becoming powerful enough that the main risk is not whether a page is understandable in isolation. The risk is whether the user can move from one thought to the next without being pulled into software cognition.

The application does not need another layout sweep.

It needs thought continuity.

## Open Questions

- Should Thought Contracts become formal product artifacts before UI implementation?
- Should every major mode have a "current thought" visible only during design QA, not in production?
- Should Golden Workflow recordings be scored by thought interruption count?
- Should Guide become the system that detects the user's current thought and routes accordingly?
- Should pages eventually be replaced by thought stages in some workflows?
- How should developer surfaces preserve technical truth without polluting ordinary user reasoning?
- What is the minimum visible information needed to complete each thought?

## Completion Criterion

This phase succeeds if future design work stops asking:

```text
How should this page look?
```

and starts asking:

```text
What thought is the user trying to complete?
What interrupts it?
What proves it is complete?
What thought follows?
```

The app should not merely become more polished.

It should become less interruptive.

