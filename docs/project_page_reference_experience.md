# Project Page Reference Experience

Purpose: lock the Project page as the first mature reference pattern before propagating the design system across Analytics Workstation.

The final governing principle is:

```text
One object.
Multiple chapters.
Persistent context.
```

The Project is not a page, dashboard, form, storage console, or stack of cards. It is one primary object experienced through chapters.

## Reference Pattern

```text
Persistent Project Object
  always visible
  preserves orientation
  shows the current project state

Project Chapters
  Lifecycle
  Current Project
  Activity
  Administration
```

The object remains. Only the chapter changes.

## Persistent Context

The persistent Project summary must keep the user oriented before and after any chapter change.

Always visible:

- Project Name
- Current Status
- Project Location
- Dataset
- Evidence
- Current Next Action
- Most Recent Activity

This prevents the user from reconstructing project state after switching chapters.

## Chapter Model

| Chapter | Question answered | Why it exists |
|---|---|---|
| Lifecycle | How do I create, open, save, preserve, or close this project? | Project lifecycle is one mental task and should not require moving elsewhere. |
| Current Project | What is open and what does it contain? | The user needs a concise inventory of the active project. |
| Activity | What changed and where should I resume? | Activity is project memory in human language. |
| Administration | What advanced project systems exist? | Operational depth remains available without becoming the default experience. |

These are chapters in one book, not tabs between unrelated pages.

## Lifecycle Dependency Chain

The Lifecycle chapter must follow the real project dependency order.

For a new project:

```text
Choose intent: Create New Project
-> Choose or confirm Project Location
-> Name the project
-> Preview the resolved destination
-> Create Project
-> Save, bundle, move, or close afterward
```

For an existing project:

```text
Choose intent: Open Existing Project
-> Choose existing Project Location
-> Let the app discover project.rds
-> Open Project
```

The UI must not show Create, Open, Save, and Close as four equal actions when no project is open. Create Project remains disabled until the selected Project Location is confirmed and the Project Name produces a valid destination. Open Project remains disabled until a saved project is detected. Save and Close appear as active lifecycle actions only after a project is open.

## Backend Leak Audit

| Term | Decision |
|---|---|
| Project Location | Keep as the primary user-facing storage concept. |
| Project File | Demote to advanced saved-file disclosure. It supports load/save mechanics but is not the main mental model. |
| Project Folder | Reword as Project Location where possible. |
| Folder Path | Reword as Project Location in primary UI. |
| Workspace | Avoid in primary Project UI. Allowed in lower-level technical feedback where existing storage helpers still emit it. |
| Provider | Avoid in primary Project UI. Use Location Type instead. |
| Manifest | Technical/admin only. |
| Bundle | Keep only as Portable Project Bundle inside Lifecycle because portability is a lifecycle concern. |
| Index | Technical/admin only. |

The primary model is:

```text
Project Location
```

not:

```text
Project File + Project Folder + Folder Path + Workspace Provider
```

## Concept Map

```text
Project
  persistent context
    identity
    status
    location
    data
    evidence
    next action
    recent activity

  chapters
    Lifecycle
      intent
      location
      name
      destination preview
      create
      open
      save
      close
      portable bundle
      advanced saved file

    Current Project
      data
      evidence
      project location
      progress
      next action

    Activity
      project messages
      recent events
      resume point

    Administration
      AI assistance
      evidence strategy
      persisted results
      feature experiments
      jobs
      ledgers
      remediation
      audit
      technical signals
```

## Scroll Audit

The previous one-surface design still stacked multiple complete concepts vertically:

- lifecycle;
- location;
- project contents;
- progress;
- activity;
- administration.

That was more coherent than a grid, but still too much continuous scrolling. The final reference uses pagination so only one active workspace is open below persistent context.

## Composition Rules

- The persistent object summary is dominant.
- Chapter selection is compact and object-scoped.
- Each chapter answers one complete question.
- No chapter should reintroduce information already available in persistent context.
- Two-column layouts are allowed only inside a chapter when they compress a single concept without creating peer surfaces.
- Advanced systems are a chapter, not a top-level default surface.

## Rejected Layouts

### Single Long Editorial Surface

Rejected because it still required scrolling through unrelated concepts and made narrow layouts heavy.

### Project Tabs

Rejected because tabs make the user feel they have left the Project for another page.

### Separate Location Page

Rejected because location is part of lifecycle.

### Administration as Default Surface

Rejected because operational systems are necessary but not the Project's primary story.

### Primary Project File Field

Rejected because it exposes internal persistence mechanics before the user needs them.

## Founder Review

Review against these questions:

- Does the page feel like one Project object?
- Does the persistent summary keep orientation across chapters?
- Does each chapter complete one coherent mental task?
- Does Project Location now feel like the only primary storage concept?
- Is Project File sufficiently demoted?
- Does pagination feel better than long scrolling?
- What still leaks implementation?
- What still fragments one concept?

## Remaining Weaknesses

- Move Project and Save As are not yet implemented as distinct safe operations. Existing save/open/portable bundle paths are preserved.
- Some low-level helper copy still uses workspace terminology in technical/admin feedback.
- Administration opens legacy subsystem surfaces whose internal designs are not yet object/chapter based.
- The floating Guide can overlap lower content in narrow layouts; that remains a shell-level issue.

## Screenshot Set

Current reference screenshots live in:

```text
exports/project_reference_object_chapters/
```

Expected states:

- `01_project_lifecycle_desktop.png`
- `02_project_current_desktop.png`
- `03_project_activity_desktop.png`
- `04_project_administration_desktop.png`
- `05_project_lifecycle_narrow.png`

Lifecycle correction screenshots live in:

```text
exports/project_lifecycle_correction/
```

Expected states:

- `01_create_before_location.png`
- `02_create_valid_location_no_name.png`
- `03_create_ready_to_create.png`
- `04_create_success.png`
- `05_open_before_location.png`
- `06_existing_project_detected.png`
- `07_open_success.png`
- `08_project_open_with_save_close.png`
- `09_lifecycle_narrow_responsive.png`

## Validation

Validate with:

```r
source("app.R")
app_env$qa_founder_testing_remediation()
app_env$qa_ui_consistency()
app_env$qa_cross_system_invariants()
```

Also validate:

- desktop Lifecycle chapter;
- desktop Current Project chapter;
- desktop Activity chapter;
- desktop Administration chapter;
- narrow Lifecycle layout;
- `git diff --check`.
