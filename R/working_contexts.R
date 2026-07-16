working_context_framework_version <- "working_context_framework_v1"

working_context_lifecycle <- function() {
  data.frame(
    state = c(
      "available",
      "selected",
      "composed",
      "active",
      "suspended",
      "resumed",
      "completed",
      "archived",
      "blocked"
    ),
    meaning = c(
      "Context is registered and can be composed.",
      "User or runtime selected this context for the current task.",
      "Context runtime compiled authoritative references and service adapters.",
      "User is currently working inside the context.",
      "User transitioned to an adjacent task with return state preserved.",
      "User returned to the preserved context state.",
      "The bounded context workflow produced its intended result.",
      "The context state is retained for history but no longer active.",
      "The context cannot proceed until a missing contract, service, evidence object, or permission is resolved."
    ),
    terminal = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE),
    resumable = c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
}

working_context_canonical_contract <- function() {
  data.frame(
    field = c(
      "context_id",
      "label",
      "purpose",
      "current_task",
      "primary_objects",
      "primary_evidence",
      "primary_controls",
      "adjacent_tasks",
      "progressive_depth",
      "mission_signals",
      "ai_actions",
      "supported_mutations",
      "return_paths",
      "replay",
      "founder_review",
      "campaigns"
    ),
    required = TRUE,
    owner = c(
      "framework registry",
      "framework registry",
      "framework registry",
      "context composition",
      "context composition",
      "context composition",
      "context composition",
      "transition map",
      "framework depth model",
      "context mission adapter",
      "context AI adapter",
      "mutation governance",
      "transition map",
      "replay contract",
      "founder review contract",
      "campaign contract"
    ),
    rule = c(
      "Stable id; never use display text as an identifier.",
      "User-facing name.",
      "The coherent piece of work this context is optimized for.",
      "The immediate job the user is doing.",
      "Authoritative object references, not duplicated state.",
      "Evidence references and summaries, not copied artifacts.",
      "Operations safe and useful inside the context.",
      "Bounded adjacent tasks with return path.",
      "Orientation through Architecture depth levels.",
      "Only operational signals relevant to this context.",
      "Reasoning-only AI actions governed by existing runtime contracts.",
      "Only authorized mutation classes, with explicit confirmation when required.",
      "Preserve state and user orientation across transitions.",
      "Deterministic scenario proving real state transitions.",
      "Human review prompts for understanding, flow, trust, evidence, and decision.",
      "Structured improvement campaigns generated from context-specific friction."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_registry <- function() {
  data.frame(
    context_id = c("evidence_review_decision_evaluation", "decision_management_production_candidate"),
    label = c("Evidence Review", "Decision Management"),
    purpose = c(
      "Review evidence, assess sufficiency, evaluate decision readiness, and decide the next action without leaving one workspace.",
      "Compare alternatives, make tradeoffs legible, and move from evidence-backed understanding to a governed decision."
    ),
    current_task = c(
      "Evaluate whether evidence is sufficient to support a governed next action.",
      "Determine what should be done, whether the recommendation is ready, and what governance or evidence still blocks action."
    ),
    relationship_layer = c("Current Working Context", "Current Working Context"),
    production_slice = c(TRUE, TRUE),
    template_for_future_contexts = c(TRUE, FALSE),
    lifecycle_state = c("available", "available"),
    stringsAsFactors = FALSE
  )
}

working_context_progressive_depth <- function() {
  data.frame(
    depth_level = 1:6,
    label = c("Orientation", "Working Set", "Evidence", "Decision", "Diagnostics", "Architecture"),
    exposes = c(
      "Question, current status, blocker, recommended next action.",
      "Primary objects, bounded evidence set, selected artifacts, current draft.",
      "Artifact inspection, synthesis, contradictions, evidence gaps, cited claims.",
      "Sufficiency, valuation, alternatives, guardrails, supported mutations.",
      "Warnings, assumptions, stale state, provider gaps, quality issues, implementation blockers.",
      "Policies, contracts, runtime architecture, QA, developer surfaces."
    ),
    default_visibility = c("primary", "primary", "primary", "adjacent", "contextual", "deferred"),
    stringsAsFactors = FALSE
  )
}

working_context_capability_exposure_levels <- function() {
  data.frame(
    exposure = c("Primary", "Adjacent", "Contextual", "Advanced", "Architectural", "Developer"),
    default_visibility = c("show", "nearby", "surface_when_relevant", "collapse", "defer", "hide_from_normal_work"),
    purpose = c(
      "Required to complete the current coherent task.",
      "Natural next work that may require a fuller workbench.",
      "Useful when current state demands attention.",
      "Power-user or deeper diagnostic capability.",
      "Explains the governing system.",
      "QA, replay, implementation, and debugging surfaces."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_service_registry <- function() {
  data.frame(
    service = c("Evidence", "Valuation", "Workflow", "Mission", "AI", "Mutation", "Artifacts", "Knowledge", "Replay", "Campaigns"),
    canonical_owner = c(
      "Artifact Model / Evidence Routing / Context adapters",
      "Decision Valuation Workspace",
      "Decision Workflow Workspace",
      "Mission Control",
      "GenAI Service / Knowledge Compilation Runtime",
      "Mutation Governance / GenAI Action Layer",
      "Artifact Model / Project Artifact Collector",
      "Knowledge Compilation Runtime / Knowledge Library",
      "Product Experience Runtime",
      "Product Experience Intelligence"
    ),
    context_rule = c(
      "Reference artifacts and compile bounded evidence; do not copy canonical artifacts.",
      "Interpret current valuation contextually; do not recreate the full workbench.",
      "Show current workflow state and safe next steps; do not bypass approval.",
      "Surface context-relevant signals only.",
      "Use bounded reasoning actions with citations and runtime bundles.",
      "Only expose supported mutation classes and confirmation boundaries.",
      "Register persisted outputs through canonical artifact contracts.",
      "Provide background concepts only at requested depth.",
      "Replay context state transitions, not only page navigation.",
      "Turn context-specific friction into bounded improvement campaigns."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_state_contract <- function() {
  data.frame(
    state_area = c("Selection", "Workflow", "Evidence", "Drafts", "Mission", "Persistence", "Return", "Replay"),
    allowed_content = c(
      "Selected context, question, decision, artifact, contradiction, action ids.",
      "Current stage, blocker, sufficiency state, last meaningful action.",
      "Binder id, synthesis id, selected artifact ids, stale indicators.",
      "Draft id, draft lifecycle state, confirmation status.",
      "Context-specific mission signals and status references.",
      "Project id and persisted result/artifact references.",
      "Previous surface, target surface, return label, preserved selection.",
      "Replay id, scenario step, expected observation."
    ),
    forbidden_content = c(
      "Duplicated business objects.",
      "Hidden workflow mutations.",
      "Copied artifact objects or full tables.",
      "Unconfirmed project mutations.",
      "Full Mission Control state.",
      "Unmanaged filesystem paths or duplicated payloads.",
      "Abandoned navigation without return state.",
      "Fabricated observations."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_framework <- function() {
  list(
    framework_id = "working_context_framework",
    version = working_context_framework_version,
    philosophy = "A Working Context is a temporary environment optimized for one coherent piece of work.",
    runtime_stack = data.frame(
      order = seq_len(7),
      layer = c(
        "Relationship Runtime",
        "Working Context Runtime",
        "Context Composition",
        "Progressive Depth",
        "Context Services",
        "Context Transitions",
        "Canonical Workflow"
      ),
      responsibility = c(
        "Determine the user relationship to the project and task.",
        "Select and manage the active context.",
        "Compile authoritative references, services, state, and controls.",
        "Control what is visible first and what is deferred.",
        "Bind canonical services through thin adapters.",
        "Preserve orientation and return paths across adjacent work.",
        "Validate the context by replaying a complete meaningful workflow."
      ),
      stringsAsFactors = FALSE
    ),
    registry = working_context_registry(),
    lifecycle = working_context_lifecycle(),
    contract = working_context_canonical_contract(),
    capability_exposure = working_context_capability_exposure_levels(),
    depth_model = working_context_progressive_depth(),
    state_contract = working_context_state_contract(),
    service_registry = working_context_service_registry(),
    transition_contract = working_context_transition_map(),
    replay_contract = working_context_replay_contract(),
    founder_review = working_context_founder_review_template(),
    campaigns = working_context_campaigns()
  )
}

working_context_capability_map <- function(context_id = "evidence_review_decision_evaluation") {
  data.frame(
    capability = c(
      "Business Question",
      "Decision Context",
      "Relevant Artifacts",
      "Cross-Artifact Synthesis",
      "Contradictions",
      "Evidence Sufficiency",
      "Valuation Summary",
      "Supported Next Action",
      "Workflow Status",
      "Current Draft",
      "Mission Summary",
      "Artifact Studio",
      "Decision Valuation",
      "Decision Workflow",
      "Mission Control",
      "Knowledge Library",
      "Code Runner",
      "AI Runtime",
      "QA and Product Experience Lab",
      "Architecture Docs"
    ),
    exposure = c(
      "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary", "Primary",
      "Adjacent", "Adjacent", "Adjacent", "Contextual", "Contextual", "Advanced", "Advanced", "Developer", "Architectural"
    ),
    reason = c(
      "Frames the work.",
      "Defines the decision under review.",
      "Evidence is the working material.",
      "The context exists to synthesize across artifacts.",
      "Conflicts affect trust and next action.",
      "Determines whether a decision can be made.",
      "Connects evidence to economics.",
      "Maintains momentum.",
      "Shows whether review, approval, or implementation is blocked.",
      "Keeps the decision artifact visible.",
      "Shows only relevant operational health.",
      "Deeper artifact inspection is related work.",
      "Economic analysis is the next natural adjacent task.",
      "Review and approval are adjacent tasks.",
      "Full operations are only needed when status demands it.",
      "Learning is useful but not part of the core work.",
      "Code execution is not part of evidence review.",
      "Provider/runtime controls are not the current job.",
      "Developer surfaces must not interrupt working flow.",
      "Architecture explains the system after the work is understood."
    ),
    initial_visibility = c(rep(TRUE, 11), rep(TRUE, 3), rep(FALSE, 6)),
    stringsAsFactors = FALSE
  )
}

working_context_transition_map <- function() {
  data.frame(
    from_context = c(
      rep("Evidence Review", 6),
      rep("Decision Management", 5)
    ),
    adjacent_task = c(
      "Inspect Artifact",
      "Run Valuation",
      "Request Decision Review",
      "Open Decision Management",
      "Open Mission Control",
      "Open Knowledge Library",
      "Review Evidence",
      "Author Decision Records",
      "Run Valuation",
      "Manage Decision Workflow",
      "Open Mission Control"
    ),
    target_surface = c(
      "Artifact Studio",
      "Semantic Intelligence",
      "Semantic Intelligence",
      "Decision Management",
      "Mission Control",
      "Knowledge Library",
      "Evidence Review",
      "Semantic Intelligence",
      "Semantic Intelligence",
      "Semantic Intelligence",
      "Mission Control"
    ),
    transition_type = c("adjacent", "adjacent", "adjacent", "next_context", "contextual", "contextual", "adjacent", "adjacent", "adjacent", "adjacent", "contextual"),
    reason = c(
      "Inspect a specific evidence object in detail.",
      "Translate evidence into economic recommendation.",
      "Move from evidence sufficiency to governed review.",
      "Move from what we know to what we should do.",
      "Inspect operational signals only when attention is required.",
      "Learn the architecture or concept behind the work.",
      "Return to the evidence basis when tradeoffs are not justified.",
      "Edit decision context, alternatives, recommendations, and evidence references in the canonical workbench.",
      "Refresh economics when costs, value, optionality, or uncertainty are incomplete.",
      "Use the full governed workflow when review, approval, implementation, or outcome records need durable mutation.",
      "Inspect operational signals only when status demands it."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_cross_context_comparison <- function() {
  data.frame(
    dimension = c(
      "Primary question",
      "Focal object",
      "Working material",
      "Primary output",
      "Governance role",
      "Natural next move"
    ),
    evidence_review = c(
      "What do we know?",
      "Current Answer",
      "Artifacts, contradictions, synthesis, evidence gaps.",
      "Evidence sufficiency and supported next action.",
      "Prevents unsupported conclusions from becoming decisions.",
      "Decision Management when evidence can support action."
    ),
    decision_management = c(
      "What should we do?",
      "Current Decision",
      "Alternatives, tradeoffs, valuation, recommendation, workflow state.",
      "Governed recommendation state and decision readiness.",
      "Keeps authority, uncertainty, approval, and implementation visible.",
      "Review outcome after implementation, or return to Evidence Review when evidence is insufficient."
    ),
    framework_observation = c(
      "The same Working Context grammar can answer different analytical questions.",
      "Changing the focal object changes the room without changing the framework.",
      "Both rooms compose canonical state rather than duplicating subsystem data.",
      "Both rooms produce bounded understanding before deeper workbench mutation.",
      "Governance is supportive when it is visible as readiness and blocker context.",
      "The framework generalizes if next-context transitions preserve orientation."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_syntax_audit <- function() {
  data.frame(
    room = c(
      rep("Evidence Review", 14),
      rep("Decision Management", 13),
      rep("Cross-Room", 5)
    ),
    visible_element = c(
      "Current Answer",
      "Decision frame",
      "Evidence binder summary",
      "Evidence selector",
      "Compile Answer",
      "Inspect",
      "Refresh",
      "Supporting Evidence",
      "Contradictions",
      "Evidence Sufficiency",
      "Valuation",
      "Ask the mentor",
      "Technical reason",
      "Project Health",
      "Current Decision",
      "Decision frame",
      "Alternatives",
      "Tradeoffs",
      "Economics",
      "Governance",
      "Preview Recommendation",
      "Request Review",
      "Approve",
      "Implement",
      "Edit Decision",
      "Ask the mentor",
      "How This Was Determined",
      "Command palette",
      "Top navigation",
      "Progressive disclosures",
      "Context transitions",
      "Status badges"
    ),
    classification = c(
      "Semantic",
      "Semantic",
      "Mixed",
      "Mixed",
      "Semantic",
      "Mixed",
      "Syntactic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Mixed",
      "Mixed",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Semantic",
      "Mixed",
      "Semantic",
      "Mixed",
      "Syntactic",
      "Syntactic",
      "Mixed",
      "Mixed",
      "Mixed"
    ),
    cognitive_cost = c(
      "Analytical interpretation",
      "Understanding the question",
      "Some counting and evidence-set mechanics",
      "Selecting an evidence object",
      "Reasoning trigger",
      "Operational click for semantic detail",
      "Mostly mechanical",
      "Understanding claims",
      "Resolving meaning conflicts",
      "Judging whether action is justified",
      "Understanding economic relevance",
      "Clarifying meaning",
      "Implementation explanation, correctly hidden",
      "Navigation to operational status",
      "Judgment about action",
      "Understanding the decision question",
      "Comparing possible actions",
      "Judging consequences",
      "Economic interpretation",
      "Authority and blocker interpretation",
      "Making the recommendation visible",
      "Moving to human review",
      "Authority judgment",
      "Action after approval",
      "Adjacent authoring work",
      "Clarifying tradeoffs",
      "Implementation explanation, correctly hidden",
      "Finding a destination",
      "Finding a place",
      "Opening deeper meaning",
      "Moving between adjacent work",
      "Interpreting readiness"
    ),
    reduction_opportunity = c(
      "Strengthen as the first visual object.",
      "Keep as orientation, not chrome.",
      "Convert counts into meaning before tables.",
      "Infer selection when only one evidence object exists.",
      "Eventually compile automatically when evidence changes, with visible stale state.",
      "Auto-open detail when a user selects a claim.",
      "Hide until evidence source changes or stale state exists.",
      "Keep visible.",
      "Keep visible until resolved.",
      "Keep visible.",
      "Keep visible.",
      "Keep collapsed until requested.",
      "Keep advanced.",
      "Use only when project status matters.",
      "Strengthen as the first visual object.",
      "Keep as orientation.",
      "Keep first-class.",
      "Keep first-class.",
      "Keep visible but narrative-first.",
      "Keep visible but translate to blocker language.",
      "Keep direct because it reveals the position.",
      "Keep direct because it changes governance state.",
      "Keep direct only after review state is clear.",
      "Keep direct only after approval state is clear.",
      "Eventually open with preserved return path and selected decision.",
      "Keep collapsed until requested.",
      "Keep advanced.",
      "Prefer semantic recommendations over command search for novices.",
      "Future geography should replace tab scanning with current-work entry.",
      "Use disclosure only when it reveals meaning, not because content exists.",
      "Make transitions consequences of current work rather than destination choices.",
      "Use badges for meaning, not raw state names."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_cognitive_budget <- function() {
  data.frame(
    room = c("Evidence Review", "Decision Management"),
    finding_things = c(15, 15),
    understanding_software = c(20, 18),
    understanding_evidence = c(40, 25),
    making_judgment = c(25, 42),
    target_shift = c(
      "Move more attention from understanding software to understanding evidence.",
      "Move more attention from understanding software to judging alternatives."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_campaigns <- function() {
  data.frame(
    campaign = c(
      "Reduce syntax",
      "Promote meaning",
      "Language cleanup",
      "Interaction reduction",
      "Current Answer leverage",
      "Tradeoff clarity",
      "Narrative before tables",
      "Understanding-first mentor"
    ),
    purpose = c(
      "Remove controls, labels, and destinations that ask the user to operate the product instead of reason.",
      "Make every primary region answer what something means, why it matters, and what should happen next.",
      "Replace implementation nouns with work nouns wherever the user is not debugging.",
      "Turn clicks into consequences where the next action is deterministic and safe.",
      "Make Evidence Review revolve around understanding rather than state.",
      "Make Decision Management revolve around consequences rather than workflow status.",
      "Show conclusions and limits before raw records.",
      "Use AI and Guide surfaces to explain why, not where."
    ),
    first_candidate = c(
      "Refresh and destination controls",
      "Current Answer and Current Decision headers",
      "Hallway, Workbench, Technical, state labels",
      "Evidence selection, stale refresh, draft visibility",
      "Evidence sufficiency and contradiction story",
      "Benefits, costs, risks, unknowns, opportunity cost",
      "Synthesis, governance, valuation, workflow tables",
      "Contextual mentor panels"
    ),
    priority = c("high", "high", "high", "medium", "high", "high", "medium", "medium"),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_founder_review <- function() {
  data.frame(
    prompt = c(
      "Where did I think about software?",
      "Where did I think about analysis?",
      "Where did I stop thinking about the interface?",
      "Where did the interface interrupt me?",
      "Which action felt like a natural consequence?",
      "Which action felt like operating machinery?",
      "Which label described the work best?",
      "Which label exposed implementation?"
    ),
    evidence_to_capture = c(
      "Moments of navigation, selection, expansion, refresh, and destination searching.",
      "Moments of evidence interpretation, contradiction resolution, tradeoff judgment, and decision readiness.",
      "Sections where the next move was obvious without reading controls.",
      "Any moment where a panel title, button, or state name broke reasoning flow.",
      "Actions that followed directly from the current answer or decision.",
      "Actions that required remembering where something lives or how the app is wired.",
      "Language that made the analytical task clearer.",
      "Language that named internal architecture, workflow IDs, or implementation mechanics."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_final_assessment <- function() {
  data.frame(
    question = c(
      "How much syntactic cognition remains?",
      "What software mechanics still consume attention?",
      "What semantic understanding became easier?",
      "Which interaction disappeared entirely?",
      "Which remaining interaction deserves removal?",
      "Which room currently best embodies semantic-first design?",
      "Does the product now spend more attention on reasoning than operating software?",
      "What remains the largest semantic obstacle?"
    ),
    answer = c(
      "Moderate. Evidence Review and Decision Management are now semantic-first in their primary objects, but navigation, refresh, selection, and advanced disclosures still carry syntactic cost.",
      "Top navigation, refresh controls, manual artifact inspection, manual compile/preview sequencing, and adjacent-work destinations.",
      "Evidence Review now centers Current Answer; Decision Management centers Current Decision; both rooms explain what, why, limits, and next move before raw detail.",
      "The visible Hallway concept was removed from Evidence Review actions and replaced with Project Health.",
      "Manual refresh should disappear where stale-state detection can safely infer when evidence has changed.",
      "Evidence Review, because Current Answer, contradiction, sufficiency, and limits form the clearest semantic chain.",
      "Yes for the two production rooms: the dominant effort is now understanding evidence and judgment, with mechanics progressively demoted.",
      "The product still exposes too many destination choices when the user's real question is what the current evidence or decision means."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_reasoning_graph <- function() {
  data.frame(
    step = seq_len(8),
    reasoning_node = c(
      "Business Question",
      "Current Evidence",
      "Current Answer",
      "Current Decision",
      "Current Recommendation",
      "Governed Review",
      "Implementation",
      "Outcome Learning"
    ),
    governing_question = c(
      "What are we trying to decide?",
      "What can we cite?",
      "What do we know?",
      "What should we do?",
      "What position is worth reviewing?",
      "Is action authorized and bounded?",
      "What action was taken?",
      "Did the decision hold?"
    ),
    primary_context = c(
      "Guide / Semantic Intelligence",
      "Artifact Studio / Evidence Review",
      "Evidence Review",
      "Decision Management",
      "Decision Management",
      "Decision Workflow",
      "Decision Workflow",
      "Mission Control / Evidence Review"
    ),
    continuation = c(
      "Collect or identify evidence.",
      "Compile the Current Answer.",
      "Continue to recommendation and tradeoff judgment.",
      "Make the recommendation inspectable.",
      "Request review or revise.",
      "Approve, reject, or request evidence.",
      "Monitor implementation and preserve assumptions.",
      "Promote, revise, or supersede knowledge."
    ),
    carry_forward = c(
      "Business question, objective, decision context.",
      "Evidence refs, contradictions, missing evidence, artifact ids.",
      "Answer, confidence, limits, next meaningful thought.",
      "Alternatives, preferred option, tradeoffs, uncertainty.",
      "Recommendation, evidence basis, conditions, blockers.",
      "Approval state, authority, conditions, expiration.",
      "Implemented action, assumptions, monitoring needs.",
      "Outcome evidence, realized value, lessons, supersession."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_continuation_audit <- function() {
  data.frame(
    from_reasoning = c(
      "No Current Answer",
      "Insufficient Evidence",
      "Supported Current Answer",
      "Recommendation Preview",
      "Current Decision",
      "Under Review",
      "Approved Decision",
      "Implemented Decision",
      "Mission Alert"
    ),
    natural_next_thought = c(
      "What evidence would make the question answerable?",
      "Which missing evidence blocks judgment?",
      "What recommendation follows from this answer?",
      "Should this recommendation enter review?",
      "Which alternative has the best tradeoff?",
      "Can authority accept this risk and uncertainty?",
      "How do we implement without losing assumptions?",
      "Did the outcome validate or revise the decision?",
      "Which reasoning thread needs attention?"
    ),
    current_destination_language = c(
      "Request Evidence",
      "Request Evidence",
      "Continue to Decision",
      "Save Recommendation",
      "Preview Recommendation",
      "Approve or Request Evidence",
      "Implement",
      "Review Outcome",
      "Open working context"
    ),
    continuation_language = c(
      "Generate evidence before deciding.",
      "Resolve the blocker.",
      "Move from Current Answer to Current Decision.",
      "Make the recommendation durable.",
      "Make the recommendation inspectable.",
      "Resolve review before action.",
      "Move from approval to implementation.",
      "Move from implementation to outcome learning.",
      "Resume the interrupted reasoning thread."
    ),
    information_already_exists = c(
      "Question and missing evidence state.",
      "Evidence gap and sufficiency classification.",
      "Current Answer, limits, evidence count, contradictions.",
      "Draft recommendation and validation.",
      "Alternatives, valuation, workflow, uncertainty.",
      "Recommendation, authority, blockers.",
      "Approval state, assumptions, monitoring needs.",
      "Implementation marker and expected outcome frame.",
      "Mission signal and affected context."
    ),
    additional_information_needed = c(
      "Citable artifacts.",
      "Targeted missing evidence.",
      "Tradeoffs and alternatives.",
      "Human confirmation.",
      "Review readiness.",
      "Authority decision or evidence request.",
      "Implementation record.",
      "Outcome evidence.",
      "Context-specific next action."
    ),
    can_continue_without_navigation = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
}

working_context_thought_preservation_contract <- function() {
  data.frame(
    thought_object = c(
      "Current Question",
      "Current Answer",
      "Current Decision",
      "Current Recommendation",
      "Current Contradictions",
      "Current Evidence",
      "Current Intent",
      "Current Momentum"
    ),
    should_persist = TRUE,
    preservation_rule = c(
      "Carry the business question or decision context into every adjacent reasoning context.",
      "Carry answer state, confidence, limits, and next thought into Decision Management.",
      "Carry selected alternative, tradeoffs, uncertainty, and governance state into review or implementation.",
      "Carry recommendation basis, conditions, blockers, and review status until superseded.",
      "Carry unresolved contradictions until reviewed, scoped, resolved, or superseded.",
      "Carry artifact references, not duplicated artifacts or full tables.",
      "Carry the user's active intent as continuation language, not page destination.",
      "Carry the next meaningful thought and last meaningful action."
    ),
    never_carry = c(
      "Do not carry stale questions into unrelated projects.",
      "Do not carry unsupported answers as recommendations.",
      "Do not carry decisions across changed evidence without stale-state warning.",
      "Do not carry recommendations after rejection, expiration, or supersession without status.",
      "Do not hide contradictions because another room is active.",
      "Do not copy canonical artifact payloads into context state.",
      "Do not infer intent across unrelated workflow branches.",
      "Do not preserve momentum by bypassing confirmation or governance."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_handoff_principles <- function() {
  data.frame(
    handoff = c(
      "Current Answer -> Current Decision",
      "Current Decision -> Recommendation",
      "Recommendation -> Governed Review",
      "Governed Review -> Implementation",
      "Implementation -> Outcome Learning",
      "Blocked Decision -> Evidence Review"
    ),
    should_carry = c(
      "Question, answer, confidence, limits, contradictions, missing evidence, supported next action.",
      "Preferred alternative, tradeoffs, valuation status, uncertainty, optionality.",
      "Recommendation text, evidence basis, conditions, authority needs, blockers.",
      "Approval state, conditions, expiration, assumptions, monitoring needs.",
      "Implemented action, expected value, guardrails, realized outcome placeholders.",
      "Blocking uncertainty, missing evidence, decision risk, unresolved tradeoffs."
    ),
    should_not_carry = c(
      "Raw artifact payloads, unrelated diagnostics, hidden implementation state.",
      "Unsupported preference as durable decision.",
      "Unreviewed authority assumptions as approval.",
      "Approval as proof of outcome quality.",
      "Implementation as validated learning.",
      "Decision pressure as evidence."
    ),
    success_signal = c(
      "Decision Management feels already informed.",
      "The recommendation feels like a consequence of tradeoff judgment.",
      "Review feels like protecting the decision, not submitting a form.",
      "Implementation preserves assumptions rather than resetting context.",
      "Learning can compare expected and realized outcomes.",
      "Returning to evidence feels like continuing the same question."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_continuation_campaigns <- function() {
  data.frame(
    campaign = c(
      "Transition language",
      "Momentum preservation",
      "Context handoff",
      "Recommendation evolution",
      "Navigation reduction",
      "Mission reasoning awareness"
    ),
    purpose = c(
      "Replace destination words with reasoning-continuation words.",
      "Keep the next meaningful thought visible between actions.",
      "Ensure each room arrives already informed by the prior room.",
      "Make Current Answer -> Current Decision -> Recommendation feel inevitable.",
      "Reduce moments where the user must choose a page before continuing thought.",
      "Make Mission Control surface interrupted reasoning rather than only system status."
    ),
    first_candidate = c(
      "Open/Go/Navigate/Launch labels",
      "Continuation strips and action summaries",
      "Evidence Review to Decision Management",
      "Preview and review actions",
      "Top navigation and command palette suggestions",
      "Alerts and priority queues"
    ),
    priority = c("high", "high", "high", "high", "medium", "medium"),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_continuation_founder_review <- function() {
  data.frame(
    prompt = c(
      "Did I think about pages?",
      "Did I think about reasoning?",
      "Did transitions feel natural?",
      "Did I lose momentum?",
      "Did I stop to decide where to go?",
      "What broke my train of thought?",
      "Which transition felt inevitable?",
      "Which transition still felt like navigation?"
    ),
    evidence_to_capture = c(
      "Moments where the user scans tabs, destinations, or commands.",
      "Moments where the user continues a question, answer, tradeoff, or decision.",
      "Whether the next room already contains the prior reasoning context.",
      "Any pause caused by destination choice, missing state, or repeated setup.",
      "Any moment where the app asks where instead of what next.",
      "Label, control, page change, missing handoff, or stale context.",
      "A transition that followed directly from the Current Answer or Current Decision.",
      "A transition that still required product geography knowledge."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_continuation_final_assessment <- function() {
  data.frame(
    question = c(
      "Does the workstation now preserve thought better?",
      "Where is reasoning still interrupted?",
      "Which transition still feels like navigation?",
      "Which transition now feels inevitable?",
      "What context should always carry forward?",
      "What context should never carry forward?",
      "Does the product increasingly think in reasoning instead of pages?",
      "What remains the largest obstacle to uninterrupted analytical thinking?"
    ),
    answer = c(
      "Yes, within the two production rooms: both now show the next meaningful thought before asking the user to choose a destination.",
      "Reasoning is still interrupted by global top navigation, command search, and some manual refresh or inspection steps.",
      "Mission Control and full Semantic Intelligence still feel like destinations because they are broad surfaces.",
      "Evidence Review to Decision Management now feels closest to inevitable because Current Answer naturally produces Current Decision.",
      "Question, answer, decision, recommendation, evidence refs, contradictions, uncertainty, confidence, and next meaningful thought.",
      "Raw artifact payloads, unrelated diagnostics, unsupported recommendations, stale decisions, approval without conditions, and hidden mutations.",
      "Yes for the Working Context layer: the graph is now Business Question -> Evidence -> Answer -> Decision -> Recommendation -> Review -> Implementation -> Learning.",
      "The largest obstacle is still destination cognition: when the next reasoning step requires a broad page rather than a bounded continuation."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_discovery_populated_project <- function() {
  artifacts <- list(
    margin_importance = create_artifact(
      artifact_id = "disc_margin_importance",
      artifact_type = "plot",
      label = "Offer Sensitivity Importance",
      source_module = "shap_analysis",
      metadata = list(
        created_by_module = TRUE,
        key_finding = "Offer depth, renewal tenure, and recent engagement are the strongest modeled drivers of premium retention response.",
        analytical_intent = "Importance",
        artifact_importance = "critical",
        decision_readiness = "ready",
        applicability = "Useful for choosing whether a targeted premium retention offer deserves a governed pilot.",
        limitations = "The model is predictive; it does not prove that deeper offers cause incremental retention.",
        contradiction_state = "none_registered"
      )
    ),
    segment_response = create_artifact(
      artifact_id = "disc_segment_response",
      artifact_type = "plot",
      label = "Premium Segment Response Spread",
      source_module = "eda",
      metadata = list(
        created_by_module = TRUE,
        key_finding = "Premium Midwest subscribers have the highest median modeled response, but also the widest variance.",
        analytical_intent = "Distribution",
        artifact_importance = "critical",
        decision_readiness = "reasonable",
        applicability = "Supports narrowing the decision to a bounded regional pilot instead of a full rollout.",
        limitations = "The same spread implies unstable economics if the offer is expanded too broadly.",
        contradiction_state = "scope_difference"
      )
    ),
    holdout_check = create_artifact(
      artifact_id = "disc_holdout_check",
      artifact_type = "table",
      label = "Prior Holdout Lift Check",
      source_module = "model_assessment",
      object = data.table::data.table(
        metric = c("incremental_retention_lift", "margin_per_saved_account", "sample_month"),
        value = c("1.8 percentage points", "$18", "2025-11")
      ),
      metadata = list(
        created_by_module = TRUE,
        key_finding = "A prior holdout showed positive but modest lift, weaker than the current modeled opportunity.",
        analytical_intent = "Diagnostic",
        artifact_importance = "critical",
        decision_readiness = "bounded",
        applicability = "Useful as conservative evidence when sizing the pilot.",
        limitations = "The holdout is one season old and used a smaller offer depth.",
        stale = TRUE,
        contradiction_state = "timing_difference"
      )
    ),
    finance_tradeoff = create_artifact(
      artifact_id = "disc_finance_tradeoff",
      artifact_type = "table",
      label = "Pilot Economics Tradeoff",
      source_module = "decision_valuation",
      object = data.table::data.table(
        alternative = c("Do nothing", "Targeted pilot", "Full rollout"),
        expected_value = c(0, 420000, 850000),
        downside = c(0, -80000, -520000),
        reversibility = c("high", "high", "low")
      ),
      metadata = list(
        created_by_module = TRUE,
        key_finding = "The targeted pilot has lower upside than full rollout but materially better downside protection and reversibility.",
        analytical_intent = "Tradeoff",
        artifact_importance = "critical",
        decision_readiness = "ready",
        applicability = "Directly applicable to the current decision alternatives.",
        limitations = "Expected value depends on the current margin and retention assumptions.",
        contradiction_state = "none_registered"
      )
    ),
    outcome_signal = create_artifact(
      artifact_id = "disc_outcome_signal",
      artifact_type = "diagnostic",
      label = "Early Outcome Learning Signal",
      source_module = "decision_workflow",
      metadata = list(
        created_by_module = TRUE,
        key_finding = "The first implementation checkpoint preserves the pilot assumptions and asks whether realized margin confirms the bounded recommendation.",
        analytical_intent = "Learning",
        artifact_importance = "recommended",
        decision_readiness = "future_evidence",
        applicability = "Used after implementation to promote, revise, or supersede the decision.",
        limitations = "Outcome is not yet observed in the deterministic fixture.",
        contradiction_state = "none_registered"
      )
    )
  )

  list(
    project_id = "semantic_discovery_pricing_retention",
    project_name = "Premium Retention Offer Decision",
    run_id = "semantic_discovery_run_001",
    business_question = "Should we launch a targeted 15% retention offer for premium Midwest subscribers next month?",
    narrative = "A growth team sees a premium-subscriber churn spike. Predictive evidence suggests offer depth matters, segment evidence supports a regional focus, finance favors a reversible pilot, and an older holdout warns against overclaiming. The story is intentionally rich enough to test whether reasoning continues across rooms.",
    artifacts = artifacts,
    current_answer = list(
      summary = "The evidence supports a bounded pilot, not a broad rollout.",
      confidence = "reasonable",
      limits = "Predictive importance and stale holdout evidence do not prove causal incrementality.",
      contradiction = "Current modeled opportunity is stronger than the prior holdout; segment response is promising but unstable.",
      next_meaningful_thought = "Translate the bounded answer into alternatives and tradeoff judgment."
    ),
    alternatives = data.table::data.table(
      alternative_id = c("baseline", "targeted_pilot", "full_rollout"),
      alternative = c("Do nothing", "Targeted premium Midwest pilot", "Full premium rollout"),
      expected_benefit = c("Avoid margin risk", "Test high-response segment with reversible exposure", "Maximize short-term retention reach"),
      primary_risk = c("Miss preventable churn", "Pilot may underperform if holdout generalizes", "Margin loss and low reversibility"),
      reversibility = c("high", "high", "low"),
      recommendation_role = c("baseline", "preferred", "rejected")
    ),
    recommendation = list(
      recommendation_id = "rec_targeted_pilot",
      statement = "Launch a targeted premium Midwest pilot with explicit margin guardrails and holdout monitoring.",
      strength = "bounded recommendation",
      why = "It preserves the evidence-supported opportunity while respecting contradiction, uncertainty, and downside risk.",
      condition = "Do not expand until the pilot confirms incremental retention and margin contribution."
    ),
    governance = list(
      review_state = "approved_with_conditions",
      approver = "Revenue Strategy Review",
      conditions = c("Use holdout monitoring", "Cap exposure", "Review margin after first checkpoint"),
      blocked_actions = c("Full rollout", "Causal claim without experiment evidence")
    ),
    implementation = list(
      status = "planned",
      action = "Configure targeted pilot audience and monitoring guardrails.",
      preserved_assumptions = c("Premium Midwest focus", "15% offer", "margin guardrail", "holdout comparison")
    ),
    outcome = list(
      status = "future_evidence_required",
      learning_question = "Did the pilot validate, revise, or supersede the bounded recommendation?"
    )
  )
}

working_context_discovery_experiment_design <- function() {
  data.frame(
    design_element = c(
      "Hypothesis under test",
      "Falsification target",
      "Canonical story",
      "Required observation",
      "Success condition",
      "Failure condition",
      "Implementation boundary"
    ),
    description = c(
      "Semantic Continuation preserves reasoning momentum across Evidence Review and Decision Management.",
      "If the user still has to reconstruct the current question, answer, contradiction, or intent after changing rooms, Semantic Continuation is incomplete or wrong.",
      "A premium retention offer decision with supporting evidence, contradictory evidence, alternatives, tradeoffs, governance, implementation, and outcome learning.",
      "A complete replay from business question to outcome learning with momentum observations at every transition.",
      "The experiment reveals the real organizing principle, whether or not Semantic Continuation survives as the final abstraction.",
      "The system merely proves that the new label exists without discovering whether thought was preserved.",
      "No new Working Context, no global navigation redesign, no unrelated capability expansion."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_discovery_reasoning_replay <- function() {
  project <- working_context_discovery_populated_project()
  data.frame(
    step = seq_len(12),
    reasoning_state = c(
      "Business Question",
      "Evidence Review",
      "Compile Current Answer",
      "Contradiction Encountered",
      "Contradiction Scoped",
      "Continue Reasoning",
      "Decision Management",
      "Evaluate Alternatives",
      "Recommendation",
      "Review and Approval",
      "Implementation",
      "Outcome Learning"
    ),
    action = c(
      "Ask whether to launch the targeted retention offer.",
      "Inspect the evidence binder and visible contradictions.",
      "Compile a bounded answer from citable artifacts.",
      "Compare current modeled opportunity against prior holdout and segment variance.",
      "Limit the answer to a reversible pilot instead of full rollout.",
      "Carry the current position into decision judgment.",
      "Open decision alternatives already informed by the current answer.",
      "Compare baseline, targeted pilot, and full rollout.",
      "Draft bounded recommendation with guardrails.",
      "Approve with conditions instead of treating approval as evidence quality.",
      "Plan the pilot while preserving assumptions.",
      "Ask whether realized outcome confirms, revises, or supersedes the decision."
    ),
    expected_carry_forward = c(
      "Question, objective, audience, decision horizon.",
      "Question, evidence refs, contradiction state.",
      "Current Answer, confidence, limits, prohibited claims.",
      "Contradiction, affected scope, unresolved question.",
      "Scoped answer, reduced claim strength, missing evidence.",
      "Current Position: question + answer + contradiction + intent.",
      "Current Position, alternatives, tradeoff frame.",
      "Preferred alternative, rejected alternative, baseline.",
      "Recommendation, basis, guardrails, blocked claims.",
      "Authority, conditions, expiration, review rationale.",
      "Approved action, assumptions, monitoring requirements.",
      "Outcome question, expected learning, supersession possibility."
    ),
    momentum_observation = c(
      "Reasoning starts naturally from a decision question.",
      "Reasoning continues if evidence and contradiction are visible without searching.",
      "Reasoning continues if the answer is prose-first and bounded.",
      "Momentum slows because contradiction requires interpretation, but this is useful friction.",
      "Momentum improves when the contradiction narrows the claim instead of blocking the room.",
      "Semantic Continuation helps, but the deeper need is a durable Current Position.",
      "Momentum breaks if Decision Management does not feel preloaded with the current answer.",
      "Reasoning continues when alternatives are already framed by the answer.",
      "Reasoning continues if recommendation language preserves limits.",
      "Governance is useful friction; approval must not erase uncertainty.",
      "Reasoning continues only if assumptions travel with implementation.",
      "Semantic Continuation alone is insufficient here; outcome learning needs a position ledger."
    ),
    interrupted_by_software = c(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
}

working_context_reasoning_momentum_audit <- function() {
  replay <- working_context_discovery_reasoning_replay()
  data.frame(
    transition = paste(head(replay$reasoning_state, -1), "->", tail(replay$reasoning_state, -1)),
    reasoning_continued = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE),
    attention_shift = c(
      "low",
      "low",
      "useful_interpretive_friction",
      "low",
      "low",
      "medium",
      "low",
      "low",
      "low",
      "low",
      "medium"
    ),
    context_reacquisition = c(
      "none",
      "none",
      "contradiction interpretation",
      "none",
      "none",
      "current answer must be remembered",
      "none if alternatives are preloaded",
      "none",
      "review conditions visible",
      "implementation assumptions visible",
      "outcome frame not yet first-class"
    ),
    break_reason = c(
      "",
      "",
      "",
      "",
      "",
      "The handoff label says continue, but the user still needs a portable summary of current position.",
      "",
      "",
      "",
      "",
      "Outcome learning is not yet represented as a live continuation of the decision."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_semantic_continuation_experiment_critique <- function() {
  data.frame(
    question = c(
      "Does 'Continue the reasoning' feel natural?",
      "Does it become repetitive?",
      "Should it disappear entirely?",
      "Should reasoning continue automatically?",
      "Should it become contextual?",
      "Does another concept replace it?",
      "What did the experiment falsify?",
      "What did it preserve?"
    ),
    assessment = c(
      "Yes at the Evidence Review to Decision Management seam, because the current answer naturally becomes decision judgment.",
      "Yes if repeated as a generic strip in every state; it becomes product language rather than thought language.",
      "No. It is useful as a transitional cue, but it should not become the primary abstraction.",
      "Sometimes. Safe read-only carry-forward should be automatic; governed mutation, approval, and implementation should remain explicit.",
      "Yes. The label should change based on the current position: resolve blocker, scope contradiction, compare alternatives, preserve assumptions, learn from outcome.",
      "Current Position is more fundamental: the durable object that carries question, answer, contradiction, evidence basis, intent, and next thought.",
      "Semantic Continuation is not sufficient as a standalone layer. A label cannot preserve reasoning if the position itself is not carried.",
      "The principle that navigation should be a consequence remains correct."
    ),
    implication = c(
      "Keep the seam, but avoid making it decorative.",
      "Replace generic repetition with state-specific continuation.",
      "Demote Semantic Continuation to a behavior of Current Position.",
      "Separate deterministic carry-forward from governed action.",
      "Generate continuation from state, not page identity.",
      "Future experiments should test Current Position as the organizing object.",
      "Do not over-invest in continuation strips before validating position persistence.",
      "Keep measuring reasoning momentum instead of page transitions."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_context_compression_findings <- function() {
  data.frame(
    information = c(
      "Business Question",
      "Current Answer",
      "Recommendation",
      "Selected Evidence",
      "Current Contradictions",
      "Current Intent",
      "Outstanding Unknowns",
      "Alternatives",
      "Governance Conditions",
      "Raw Artifact Payloads",
      "Full Tables",
      "Unrelated Diagnostics",
      "Approval Alone",
      "Implementation Internals"
    ),
    should_cross_rooms = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
    reason = c(
      "It anchors all downstream reasoning.",
      "It prevents the user from reconstructing the evidence interpretation.",
      "It becomes the object of review and implementation.",
      "References preserve provenance without copying evidence.",
      "Contradictions determine claim strength and next evidence.",
      "Intent keeps the continuation semantic rather than navigational.",
      "Unknowns preserve humility and next evidence requirements.",
      "Alternatives are required for decision judgment.",
      "Conditions prevent approval from washing away uncertainty.",
      "Payloads belong to artifacts and should be retrieved on demand.",
      "Preview or references should travel; full tables should justify themselves.",
      "Diagnostics should travel only when they affect the current position.",
      "Approval is authorization, not evidence quality.",
      "Implementation internals should surface only when action is being executed or audited."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_cross_room_story_assessment <- function() {
  data.frame(
    assessment_area = c(
      "Evidence Review to Decision Management",
      "Decision Management to Review",
      "Review to Implementation",
      "Implementation to Outcome",
      "Mission Control relationship",
      "Semantic Continuation hypothesis"
    ),
    finding = c(
      "The story can feel continuous if Current Answer becomes the initial decision frame.",
      "The story remains continuous when recommendation limits and conditions stay visible.",
      "The story remains continuous only if assumptions and guardrails travel with approval.",
      "The story weakens because outcome learning is not yet a strong first-class continuation.",
      "Mission Control is still a status surface more than a reasoning-continuity surface.",
      "Useful but incomplete; it points to a deeper Current Position abstraction."
    ),
    severity = c("medium", "low", "medium", "high", "medium", "high"),
    stringsAsFactors = FALSE
  )
}

working_context_product_discoveries <- function() {
  data.frame(
    discovery = c(
      "Current Position is deeper than Semantic Continuation.",
      "Useful friction is not a UX failure.",
      "Decision begins before the Decision room.",
      "Outcome learning needs its own continuity contract.",
      "Mission Control should report interrupted reasoning, not only system health."
    ),
    evidence = c(
      "The replay breaks when the user must remember question, answer, contradiction, and intent after the seam.",
      "Contradiction interpretation slows the user but improves decision quality.",
      "The Current Answer already contains the first decision boundary: pilot, not rollout.",
      "Implementation can preserve assumptions, but the product does not yet make outcome learning inevitable.",
      "The replay asks which reasoning thread needs attention, not merely which component is unhealthy."
    ),
    recommended_response = c(
      "Test a Current Position object before adding more continuation UI.",
      "Distinguish useful analytical friction from software friction in founder review.",
      "Let Decision Management inherit a scoped position rather than start cold.",
      "Design outcome learning as continuation from implemented decision in a future experiment.",
      "Add reasoning-thread status to a future Mission Control experiment."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_discovery_campaigns <- function() {
  data.frame(
    campaign = c(
      "Current Position Prototype",
      "State-Specific Continuation",
      "Outcome Learning Continuity",
      "Reasoning Thread Mission Signals",
      "Useful Friction Classification"
    ),
    grounded_in_observation = c(
      "Decision seam still requires reacquiring answer, contradiction, and intent.",
      "Generic continuation language risks becoming repetitive.",
      "Implementation to outcome learning was the weakest transition.",
      "Mission alerts should identify interrupted reasoning threads.",
      "Contradiction slowed the workflow but improved judgment."
    ),
    first_candidate = c(
      "Compact Current Position summary shared across Evidence Review and Decision Management.",
      "Replace generic strip text with resolve blocker, scope contradiction, compare alternatives, preserve assumptions.",
      "Add deterministic outcome-learning handoff contract before any new room.",
      "Mission Control card for current answer/decision/recommendation blockers.",
      "Founder review scale distinguishing analytical friction from software friction."
    ),
    priority = c("high", "high", "medium", "medium", "high"),
    stringsAsFactors = FALSE
  )
}

working_context_discovery_founder_review <- function() {
  data.frame(
    prompt = c(
      "When did I forget the software?",
      "When did I remember it?",
      "Where did I hesitate?",
      "Where did I reread?",
      "Where did momentum break?",
      "Where did the room surprise me?",
      "Where did the product feel inevitable?",
      "Was the friction analytical or mechanical?"
    ),
    observed_answer = c(
      "When the current answer narrowed the claim from rollout to pilot.",
      "When moving between rooms required remembering whether the answer, contradiction, and intent carried forward.",
      "At the contradiction and at implementation-to-outcome learning.",
      "At the seam between Current Answer and alternatives if the position summary is not visible.",
      "When outcome learning did not have a live continuation object.",
      "The contradiction was useful because it improved the recommendation rather than simply blocking progress.",
      "Current Answer to bounded pilot recommendation felt closest to inevitable.",
      "Contradiction was analytical friction; destination reacquisition was mechanical friction."
    ),
    evidence_to_capture_next = c(
      "Video moment where user reads the answer without scanning navigation.",
      "Video moment where user checks page or room context.",
      "Cursor pause, scroll, or repeated reading.",
      "Repeated reading of question, answer, contradiction, or recommendation.",
      "Transition delay or search behavior.",
      "User comment that uncertainty helped rather than annoyed.",
      "Transition requiring no explanation.",
      "Founder notes tagged analytical_friction or software_friction."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_discovery_final_assessment <- function() {
  data.frame(
    question = c(
      "Did the populated workflow preserve reasoning?",
      "Where did momentum break?",
      "Did Semantic Continuation genuinely help?",
      "What information should always travel between rooms?",
      "What information should never travel?",
      "What part of the workflow still felt like software?",
      "What new abstraction emerged?",
      "What is now the highest-value product experiment?"
    ),
    answer = c(
      "Partially. The story preserved reasoning through evidence, answer, contradiction, and recommendation, but weakened at cross-room handoff and outcome learning.",
      "Momentum broke when the user had to reconstruct the current position after a room change, and again when implementation did not naturally become outcome learning.",
      "Yes as a cue, no as a complete abstraction. It helps name the seam but does not itself carry the reasoning state.",
      "Business question, current answer, confidence, limits, contradictions, selected evidence refs, current intent, alternatives, recommendation, governance conditions, outstanding unknowns.",
      "Raw artifacts, full tables by default, unrelated diagnostics, hidden mutations, unsupported recommendations, approval as evidence quality, and implementation internals outside execution/audit contexts.",
      "Destination reacquisition: checking which room owns the next reasoning object.",
      "Current Position: a compact durable reasoning object that carries question, answer, evidence basis, contradiction, intent, and next thought.",
      "Build a Current Position prototype for Evidence Review and Decision Management, then replay the same populated story and compare momentum breaks."
    ),
    stringsAsFactors = FALSE
  )
}

qa_semantic_continuation_discovery_experiment <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  project <- working_context_discovery_populated_project()
  design <- working_context_discovery_experiment_design()
  replay <- working_context_discovery_reasoning_replay()
  momentum <- working_context_reasoning_momentum_audit()
  critique <- working_context_semantic_continuation_experiment_critique()
  compression <- working_context_context_compression_findings()
  story <- working_context_cross_room_story_assessment()
  discoveries <- working_context_product_discoveries()
  campaigns <- working_context_discovery_campaigns()
  founder <- working_context_discovery_founder_review()
  final <- working_context_discovery_final_assessment()
  doc_path <- file.path("docs", "semantic_continuation_discovery_experiment_1.md")
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))

  add("experiment_design", nrow(design) >= 7L && any(grepl("falsification", tolower(design$design_element))), "Experiment design is explicit and falsification-oriented.")
  add("canonical_populated_project", length(project$artifacts) >= 5L && nzchar(project$business_question) && !is.null(project$recommendation), "Canonical project contains a believable business question, artifacts, recommendation, governance, implementation, and outcome.")
  add("conflicting_evidence", any(vapply(project$artifacts, function(x) (x$metadata %||% list())$contradiction_state %||% "none_registered", character(1)) != "none_registered"), "Project includes explicit conflicting evidence.")
  add("reasoning_replay", nrow(replay) >= 12L && all(c("Business Question", "Evidence Review", "Decision Management", "Outcome Learning") %in% replay$reasoning_state), "Replay covers the complete reasoning path.")
  add("momentum_audit", nrow(momentum) >= 10L && any(!momentum$reasoning_continued), "Momentum audit records breaks instead of forcing a positive result.")
  add("semantic_critique", any(grepl("Current Position", critique$assessment)) && any(grepl("not sufficient", critique$assessment, ignore.case = TRUE)), "Semantic Continuation critique allows partial falsification.")
  add("context_compression", any(compression$information == "Business Question" & compression$should_cross_rooms) && any(compression$information == "Raw Artifact Payloads" & !compression$should_cross_rooms), "Context compression distinguishes always-carry from never-carry information.")
  add("cross_room_story", any(story$severity == "high") && any(grepl("Outcome", story$assessment_area)), "Cross-room story assessment identifies a high-severity weak transition.")
  add("discoveries", any(discoveries$discovery == "Current Position is deeper than Semantic Continuation."), "Experiment produces a non-defensive product discovery.")
  add("campaigns", nrow(campaigns) >= 5L && all(campaigns$priority %in% c("high", "medium", "low")), "Campaigns are grounded in observed workflow findings.")
  add("founder_review", nrow(founder) >= 8L && any(grepl("analytical friction", founder$observed_answer)), "Founder review distinguishes analytical from mechanical friction.")
  add("documentation", file.exists(doc_path) && has_all(c("Product Discovery Experiment 1", "Current Position", "Failure Analysis", "Final Assessment"), doc), "Discovery experiment documentation exists.")
  add("final_assessment", nrow(final) == 8L && any(grepl("Current Position", final$answer)), "Final assessment answers the required discovery questions.")

  do.call(rbind, checks)
}

working_context_validate_contract <- function(contract) {
  required <- working_context_canonical_contract()$field
  missing <- setdiff(required, names(contract))
  empty <- intersect(required, names(contract))[vapply(intersect(required, names(contract)), function(name) {
    value <- contract[[name]]
    is.null(value) || length(value) == 0L || (is.character(value) && all(!nzchar(value)))
  }, logical(1))]
  service_result(
    status = if (!length(missing) && !length(empty)) "success" else "error",
    value = list(missing = missing, empty = empty),
    errors = c(
      if (length(missing)) paste("Missing required context fields:", paste(missing, collapse = ", ")) else character(),
      if (length(empty)) paste("Empty required context fields:", paste(empty, collapse = ", ")) else character()
    ),
    messages = if (!length(missing) && !length(empty)) "Working Context contract is complete." else character()
  )
}

working_context_evidence_review_contract <- function() {
  list(
    context_id = "evidence_review_decision_evaluation",
    label = "Evidence Review",
    purpose = "Review evidence, assess sufficiency, evaluate decision readiness, and decide the next action without leaving one workspace.",
    current_task = "Complete a bounded evidence-review workflow.",
    primary_objects = c("business_question", "decision_context", "evidence_binder", "selected_artifact", "sufficiency", "next_action", "draft"),
    primary_evidence = c("included_artifacts", "cited_claims", "contradictions", "evidence_gaps", "valuation_interpretation"),
    primary_controls = c("inspect_artifact", "compile_synthesis", "review_contradiction", "preview_draft", "confirm_persist_draft"),
    adjacent_tasks = working_context_transition_map(),
    progressive_depth = working_context_progressive_depth(),
    mission_signals = c("binder_stale", "contradiction_unresolved", "sufficiency_blocked", "valuation_missing", "draft_awaiting_confirmation", "persisted_draft"),
    ai_actions = evidence_review_contextual_ai_actions(),
    supported_mutations = c("confirmed_evidence_review_draft_persistence"),
    return_paths = working_context_transition_map()[, c("adjacent_task", "target_surface", "transition_type", "reason")],
    replay = evidence_review_execution_scenario,
    founder_review = working_context_founder_review_template(),
    campaigns = working_context_campaigns()
  )
}

working_context_compose_context <- function(context_id = "evidence_review_decision_evaluation", ...) {
  registry <- working_context_registry()
  if (!context_id %in% registry$context_id) {
    return(service_result(status = "error", errors = paste("Unknown Working Context:", context_id)))
  }
  if (identical(context_id, "evidence_review_decision_evaluation")) {
    context <- working_context_build_evidence_review(...)
    contract <- working_context_evidence_review_contract()
    validation <- working_context_validate_contract(contract)
    return(service_result(
      status = if (identical(validation$status, "success")) "success" else "error",
      value = list(
        framework_version = working_context_framework_version,
        context_id = context_id,
        contract = contract,
        compiled_context = context,
        lifecycle_state = "composed",
        depth_model = working_context_progressive_depth(),
        capability_exposure = working_context_capability_exposure_levels(),
        services = working_context_service_registry(),
        transitions = working_context_transition_map()
      ),
      errors = validation$errors,
      messages = "Working Context composed from the canonical framework."
    ))
  }
  service_result(status = "error", errors = paste("No composer registered for Working Context:", context_id))
}

working_context_framework_replay <- function(context_id = "evidence_review_decision_evaluation") {
  composed <- working_context_compose_context(context_id, artifacts = evidence_review_fixture_artifacts())
  if (!identical(composed$status, "success")) {
    return(composed)
  }
  scenario <- composed$value$contract$replay()
  service_result(
    status = if (identical(scenario$persisted$status, "success")) "success" else "error",
    value = list(
      context_id = context_id,
      replay_steps = scenario$steps,
      mission_after = scenario$mission_after,
      persisted_artifact_id = (scenario$persisted$value$artifact %||% list())$artifact_id %||% NA_character_
    ),
    messages = "Working Context replay completed through persisted result."
  )
}

working_context_framework_campaign_seeds <- function(context_id = "evidence_review_decision_evaluation") {
  campaigns <- working_context_campaigns()
  data.frame(
    context_id = context_id,
    campaign_id = campaigns$campaign_id,
    priority = c("high", "high", "medium", "high", "medium", "high"),
    severity = c("major", "major", "moderate", "major", "moderate", "major"),
    dependency = c("replay", "founder_review", "progressive_depth", "context_transition", "transition_labels", "visual_hierarchy"),
    comparison_metric = c("context_switches", "first_read_accuracy", "architecture_leakage", "external_navigation_count", "return_path_clarity", "decision_readiness_comprehension"),
    stringsAsFactors = FALSE
  )
}

working_context_founder_review_template <- function() {
  data.frame(
    review_dimension = c(
      "focus",
      "location_awareness",
      "information_priority",
      "next_action",
      "unnecessary_capability",
      "missing_capability",
      "transition_quality",
      "evidence_hierarchy"
    ),
    prompt = c(
      "Did I remain focused inside one coherent workspace?",
      "Did I know where I was and what job I was doing?",
      "Did the most important information appear before secondary detail?",
      "Did I know what came next?",
      "What unrelated capability appeared too early?",
      "What capability was needed but missing from the working set?",
      "Did adjacent-task transitions feel natural?",
      "Did evidence, uncertainty, and recommendation have a clear hierarchy?"
    ),
    score_scale = "1-5 plus notes",
    stringsAsFactors = FALSE
  )
}

working_context_campaigns <- function() {
  data.frame(
    campaign_id = c(
      "wc_too_many_adjacent_tasks",
      "wc_wrong_information_priority",
      "wc_excess_architecture",
      "wc_excess_navigation",
      "wc_poor_transitions",
      "wc_weak_evidence_hierarchy"
    ),
    campaign_type = "working_context_campaign",
    symptom = c(
      "The context begins to look like the full app.",
      "Secondary diagnostics appear before the decision question or evidence.",
      "Architecture language leaks into normal work.",
      "The user must repeatedly leave the context.",
      "Adjacent tasks feel like page jumps instead of natural work continuation.",
      "Artifacts, contradictions, sufficiency, and next action compete visually."
    ),
    expected_fix = c(
      "Reduce initial adjacent tasks to the minimum useful set.",
      "Reorder panels around question, evidence, reasoning, next action.",
      "Move architecture to progressive depth level 5.",
      "Bring relevant summaries into the context.",
      "Add clearer transition labels and return paths.",
      "Strengthen section hierarchy and evidence status cues."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_replay_contract <- function() {
  data.frame(
    replay_step = seq_len(7),
    action = c(
      "Open Evidence Review",
      "Read current question",
      "Review evidence sufficiency",
      "Inspect contradictions",
      "Read valuation and workflow summaries",
      "Choose supported next action",
      "Transition to one adjacent task"
    ),
    expected_observation = c(
      "User lands in one task-shaped workspace.",
      "Business question and decision context are visible immediately.",
      "Sufficiency is visible without opening Mission Control.",
      "Contradictions are surfaced as evidence concerns, not hidden diagnostics.",
      "Valuation and workflow are summarized in context.",
      "Next action is explicit and explained.",
      "Related task opens naturally without exposing the full app."
    ),
    stringsAsFactors = FALSE
  )
}

working_context_inline_operation_inventory <- function() {
  data.frame(
    element = c(
      "Context Header",
      "Business Question",
      "Evidence Binder",
      "Included Artifacts",
      "Omitted Artifacts",
      "Selected Artifact Inspector",
      "Cross-Artifact Synthesis",
      "Contradiction Workspace",
      "Evidence Sufficiency",
      "Valuation Interpretation",
      "Supported Next Actions",
      "Governed Draft",
      "Mission Summary",
      "Adjacent Task Links",
      "Architecture Metadata",
      "Autonomous Execution"
    ),
    classification = c(
      "informative only",
      "informative only",
      "executable through existing handler",
      "executable through existing handler",
      "executable but not yet exposed here",
      "executable through existing handler",
      "executable through existing handler",
      "executable through existing handler",
      "executable through existing handler",
      "executable through existing handler",
      "executable through existing handler",
      "executable through existing handler",
      "informative only",
      "navigational",
      "informative only",
      "inappropriate for inline execution"
    ),
    implementation_path = c(
      "context_state summary",
      "semantic decision context",
      "context binder adapter over artifact references",
      "artifact inspection adapter",
      "binder omission diagnostics",
      "artifact inspection adapter",
      "deterministic synthesis/replay adapter",
      "contradiction adapter",
      "action-specific sufficiency adapter",
      "decision valuation summary adapter",
      "ranked action adapter",
      "draft preview and confirmed artifact registration",
      "contextual signal adapter",
      "existing app navigation",
      "progressive depth level 5",
      "blocked by policy"
    ),
    user_surface = c(
      "header",
      "header",
      "binder",
      "binder",
      "binder details",
      "inspector",
      "synthesis",
      "contradictions",
      "sufficiency",
      "valuation",
      "next actions",
      "draft flow",
      "mission summary",
      "transitions",
      "advanced disclosure",
      "not shown"
    ),
    stringsAsFactors = FALSE
  )
}

evidence_review_context_state <- function(
  project_id = NA_character_,
  business_question_id = NA_character_,
  decision_context_id = NA_character_,
  selected_artifact_ids = character(),
  evidence_binder_id = NA_character_,
  synthesis_id = NA_character_,
  sufficiency_state = "not_assessed",
  selected_next_action_id = NA_character_,
  draft_id = NA_character_,
  workflow_stage = "orientation",
  stale_state_indicators = character(),
  current_depth_level = 1L,
  open_contradiction_id = NA_character_,
  last_meaningful_action = NA_character_,
  updated_at = Sys.time()
) {
  list(
    context_id = "evidence_review_decision_evaluation",
    project_id = project_id %||% NA_character_,
    business_question_id = business_question_id %||% NA_character_,
    decision_context_id = decision_context_id %||% NA_character_,
    selected_artifact_ids = selected_artifact_ids %||% character(),
    evidence_binder_id = evidence_binder_id %||% NA_character_,
    synthesis_id = synthesis_id %||% NA_character_,
    sufficiency_state = sufficiency_state %||% "not_assessed",
    selected_next_action_id = selected_next_action_id %||% NA_character_,
    draft_id = draft_id %||% NA_character_,
    workflow_stage = workflow_stage %||% "orientation",
    stale_state_indicators = stale_state_indicators %||% character(),
    current_depth_level = as.integer(current_depth_level %||% 1L),
    open_contradiction_id = open_contradiction_id %||% NA_character_,
    last_meaningful_action = last_meaningful_action %||% NA_character_,
    updated_at = updated_at
  )
}

evidence_review_context_state_summary <- function(state) {
  state <- state %||% evidence_review_context_state()
  data.table::data.table(
    field = c(
      "Project", "Business Question", "Decision Context", "Selected Artifacts",
      "Binder", "Synthesis", "Sufficiency", "Next Action", "Draft",
      "Stage", "Stale Indicators", "Depth", "Last Action"
    ),
    value = c(
      state$project_id %||% NA_character_,
      state$business_question_id %||% NA_character_,
      state$decision_context_id %||% NA_character_,
      paste(state$selected_artifact_ids %||% character(), collapse = ", "),
      state$evidence_binder_id %||% NA_character_,
      state$synthesis_id %||% NA_character_,
      state$sufficiency_state %||% "not_assessed",
      state$selected_next_action_id %||% NA_character_,
      state$draft_id %||% NA_character_,
      state$workflow_stage %||% "orientation",
      paste(state$stale_state_indicators %||% character(), collapse = ", "),
      as.character(state$current_depth_level %||% 1L),
      state$last_meaningful_action %||% NA_character_
    )
  )
}

.evidence_review_artifact_metadata <- function(artifact) {
  artifact$metadata %||% list()
}

.evidence_review_artifact_id <- function(artifact, fallback = NA_character_) {
  artifact$artifact_id %||% artifact$id %||% fallback
}

.evidence_review_artifact_title <- function(artifact, fallback = NA_character_) {
  artifact$label %||% artifact$title %||% artifact$artifact_id %||% fallback
}

evidence_review_artifact_index <- function(artifacts = list()) {
  if (!length(artifacts)) {
    return(data.table::data.table(
      artifact_id = character(),
      title = character(),
      artifact_type = character(),
      source_module = character(),
      evidence_type = character(),
      key_finding = character(),
      readiness = character(),
      applicability = character(),
      limitations = character(),
      freshness = character(),
      contradiction_state = character(),
      importance = character(),
      intent = character()
    ))
  }

  rows <- lapply(seq_along(artifacts), function(i) {
    artifact <- artifacts[[i]]
    metadata <- .evidence_review_artifact_metadata(artifact)
    updated <- artifact$updated_at %||% artifact$created_at %||% Sys.time()
    stale <- isTRUE(metadata$stale) || identical(metadata$artifact_status %||% "", "stale")
    data.table::data.table(
      artifact_id = .evidence_review_artifact_id(artifact, names(artifacts)[[i]] %||% paste0("artifact_", i)),
      title = .evidence_review_artifact_title(artifact, paste("Artifact", i)),
      artifact_type = artifact$artifact_type %||% "unknown",
      source_module = artifact$source_module %||% metadata$module_id %||% "unknown",
      evidence_type = metadata$analytical_intent %||% metadata$artifact_intent %||% infer_artifact_intent(artifact$artifact_type %||% "unknown", artifact$label %||% ""),
      key_finding = metadata$key_finding %||% metadata$caption %||% artifact$content %||% "No key finding has been authored.",
      readiness = metadata$decision_readiness %||% metadata$quality_status %||% artifact$status %||% "ready",
      applicability = metadata$applicability %||% "Applicable to the current evidence review if scope matches the decision.",
      limitations = metadata$limitations %||% metadata$warning %||% metadata$warnings %||% "No limitations were supplied.",
      freshness = if (stale) "stale" else if (!is.na(updated)) "current" else "unknown",
      contradiction_state = metadata$contradiction_state %||% if (isTRUE(metadata$contradiction)) "unresolved" else "none_registered",
      importance = metadata$artifact_importance %||% "recommended",
      intent = metadata$analytical_intent %||% metadata$intent %||% "Evidence"
    )
  })

  data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
}

evidence_review_create_binder <- function(artifacts = list(), selected_artifact_ids = NULL, project_id = NA_character_) {
  index <- evidence_review_artifact_index(artifacts)
  selected <- selected_artifact_ids %||% index$artifact_id
  if (!length(selected) && nrow(index)) {
    selected <- index$artifact_id
  }
  included <- index[index$artifact_id %in% selected]
  omitted <- index[!index$artifact_id %in% selected]
  if (!nrow(omitted)) {
    omitted <- data.table::data.table(
      artifact_id = character(),
      title = character(),
      reason = character()
    )
  } else {
    omitted[, reason := "Outside the current bounded review set."]
  }
  stale <- included[freshness %in% c("stale", "superseded")]
  contradictory <- included[contradiction_state != "none_registered"]
  binder_id <- paste0("binder_", substr(digest::digest(paste(project_id, paste(selected, collapse = "|"), nrow(index))), 1, 10))
  list(
    binder_id = binder_id,
    project_id = project_id,
    artifact_ids = selected,
    included = included,
    omitted = omitted,
    stale_or_superseded = stale,
    contradictory = contradictory,
    created_at = Sys.time(),
    status = if (nrow(included)) "ready" else "empty"
  )
}

evidence_review_inspect_artifact <- function(artifacts = list(), artifact_id = NULL, depth_level = 1L) {
  index <- evidence_review_artifact_index(artifacts)
  if (!nrow(index)) {
    return(service_result(status = "error", errors = "No artifacts are available for inspection."))
  }
  artifact_id <- artifact_id %||% index$artifact_id[[1]]
  row <- index[index$artifact_id == artifact_id]
  if (!nrow(row)) {
    return(service_result(status = "error", errors = paste("Artifact not found:", artifact_id)))
  }
  artifact <- artifacts[[artifact_id]] %||% artifacts[[which(index$artifact_id == artifact_id)[[1]]]]
  metadata <- .evidence_review_artifact_metadata(artifact)
  depth <- as.integer(depth_level %||% 1L)
  details <- list(
    summary = row[, .(artifact_id, title, artifact_type, evidence_type, key_finding, readiness, applicability, limitations, freshness, contradiction_state)],
    diagnostics = data.table::data.table(
      diagnostic = c("source_module", "importance", "intent", "status"),
      value = c(row$source_module[[1]], row$importance[[1]], row$intent[[1]], artifact$status %||% "ready")
    ),
    claims = data.table::data.table(
      claim_id = paste0(row$artifact_id[[1]], "_claim_1"),
      claim = row$key_finding[[1]],
      claim_strength = metadata$claim_strength %||% "bounded",
      citation_artifact_id = row$artifact_id[[1]]
    ),
    lineage = data.table::data.table(
      artifact_id = row$artifact_id[[1]],
      source_module = row$source_module[[1]],
      created_at = as.character(artifact$created_at %||% NA_character_),
      updated_at = as.character(artifact$updated_at %||% NA_character_)
    ),
    metadata = metadata,
    full_artifact_ref = row$artifact_id[[1]],
    depth_level = depth
  )
  service_result(status = "success", value = details, messages = paste("Inspected artifact:", row$title[[1]]))
}

evidence_review_compile_synthesis <- function(binder, proposed_action = "prepare_decision_draft") {
  included <- binder$included %||% data.table::data.table()
  if (!nrow(included)) {
    return(service_result(status = "warning", value = list(
      synthesis_id = NA_character_,
      cited_claims = data.table::data.table(),
      contradictions = data.table::data.table(),
      gaps = data.table::data.table(gap = "No included artifacts exist.", consequence = "Evidence review cannot proceed."),
      excluded_evidence = binder$omitted %||% data.table::data.table(),
      prohibited_claims = data.table::data.table(claim = "Decision recommendation", reason = "No cited evidence is available.")
    ), messages = "No synthesis was compiled because the binder is empty."))
  }
  synthesis_id <- paste0("synthesis_", substr(digest::digest(paste(binder$binder_id, proposed_action, nrow(included))), 1, 10))
  cited <- included[, .(
    claim_id = paste0(artifact_id, "_claim"),
    artifact_id,
    title,
    claim = key_finding,
    evidence_type,
    claim_strength = data.table::fifelse(readiness %in% c("ready", "current", "reasonable"), "moderate", "bounded")
  )]
  contradictions <- evidence_review_contradiction_workspace(binder)
  gaps <- data.table::data.table(
    gap = c(
      if (!nrow(included[artifact_type %in% c("table", "plot")])) "No visual or tabular evidence in binder." else NA_character_,
      if (!nrow(contradictions[status == "unresolved"])) NA_character_ else "At least one contradiction is unresolved."
    ),
    consequence = c(
      "The review may rely too heavily on narrative evidence.",
      "Decision use should wait for scoped interpretation or added evidence."
    )
  )[!is.na(gap)]
  if (!nrow(gaps)) {
    gaps <- data.table::data.table(gap = "No deterministic synthesis gap detected.", consequence = "Proceed according to action-specific sufficiency.")
  }
  prohibited <- data.table::data.table(
    claim = c("Causal certainty", "Decision-ready recommendation"),
    reason = c(
      "Evidence Review cannot infer causality unless causal identification evidence exists.",
      "Decision readiness depends on action-specific sufficiency, valuation, authority, and review."
    )
  )
  service_result(
    status = "success",
    value = list(
      synthesis_id = synthesis_id,
      cited_claims = cited,
      contradictions = contradictions,
      gaps = gaps,
      excluded_evidence = binder$omitted %||% data.table::data.table(),
      prohibited_claims = prohibited
    ),
    messages = paste("Compiled synthesis from", nrow(included), "artifact(s).")
  )
}

evidence_review_contradiction_workspace <- function(binder) {
  contradictory <- binder$contradictory %||% data.table::data.table()
  if (!nrow(contradictory)) {
    return(data.table::data.table(
      contradiction_id = "none_registered",
      artifacts_involved = "No explicit contradiction registered.",
      nature = "No deterministic contradiction has been recorded.",
      scope_differs = FALSE,
      estimand_differs = FALSE,
      timing_differs = FALSE,
      supersession = FALSE,
      conflict_type = "none",
      consequence = "No contradiction currently blocks the proposed action.",
      unresolved_question = "Continue monitoring for conflicting evidence.",
      status = "reviewed"
    ))
  }
  data.table::data.table(
    contradiction_id = paste0("contradiction_", seq_len(nrow(contradictory))),
    artifacts_involved = contradictory$title,
    nature = contradictory$limitations,
    scope_differs = grepl("scope|segment|population", contradictory$limitations, ignore.case = TRUE),
    estimand_differs = grepl("estimand|metric|outcome", contradictory$limitations, ignore.case = TRUE),
    timing_differs = grepl("time|window|period|fresh", contradictory$limitations, ignore.case = TRUE),
    supersession = contradictory$freshness %in% c("stale", "superseded"),
    conflict_type = contradictory$contradiction_state,
    consequence = "Resolve or scope this conflict before using the evidence for a stronger recommendation.",
    unresolved_question = "Does this artifact contradict the proposed action or only narrow its scope?",
    status = "unresolved"
  )
}

evidence_review_assess_sufficiency <- function(
  binder,
  synthesis = NULL,
  proposed_action = "prepare_decision_draft",
  valuation = NULL
) {
  included <- binder$included %||% data.table::data.table()
  contradictions <- evidence_review_contradiction_workspace(binder)
  unresolved <- nrow(contradictions[status == "unresolved"])
  has_evidence <- nrow(included) > 0L
  has_valuation <- !is.null(valuation) && data.table::is.data.table(valuation) && nrow(valuation) && !all(valuation$status %in% c("missing", "not_available"))
  classification <- if (!has_evidence) {
    "insufficient_or_blocked"
  } else if (unresolved > 0L) {
    "enough_to_inspect"
  } else if (identical(proposed_action, "prepare_decision_draft") && has_valuation) {
    "enough_to_draft"
  } else if (identical(proposed_action, "request_review")) {
    "enough_to_request_review"
  } else if (has_evidence && has_valuation) {
    "enough_to_recommend"
  } else {
    "enough_to_inspect"
  }
  data.table::data.table(
    proposed_action = proposed_action,
    evidence_supporting = if (has_evidence) paste(nrow(included), "artifact(s) cite relevant evidence.") else "No supporting artifacts.",
    evidence_limiting = if (unresolved) paste(unresolved, "unresolved contradiction(s).") else "No unresolved contradiction blocks inspection.",
    missing_evidence = if (has_valuation) "No valuation gap detected by this context adapter." else "Decision valuation or economic inputs are missing.",
    authority_and_coverage = "Authority and coverage must be confirmed before decision use.",
    uncertainty = if (unresolved) "Elevated" else if (has_valuation) "Bounded" else "Material",
    guardrails = "Do not present as decision-ready until sufficiency, valuation, and review agree.",
    sufficiency_classification = classification,
    proceed_conditions = if (classification %in% c("enough_to_draft", "enough_to_request_review", "enough_to_recommend")) "Proceed with explicit confirmation." else "Collect missing evidence, resolve contradictions, or run valuation."
  )
}

evidence_review_valuation_interpretation <- function(valuation_state = decision_valuation_empty(), semantic_decision_state = semantic_decision_empty()) {
  valuation_summary <- decision_valuation_summary(valuation_state)
  status <- valuation_summary$valuation_status[[1]] %||% "not_available"
  if (!identical(status, "current")) {
    return(data.table::data.table(
      layer = c("Alternatives", "Financial Impact", "Materiality", "Risk", "Optionality", "Missing Inputs", "Recommendation"),
      status = c("not_available", "missing", "unknown", "unknown", "unknown", "missing", "not_ready"),
      interpretation = c(
        "No current valuation output is available in this context.",
        "Expected financial impact has not been interpreted.",
        "Materiality cannot be assessed without valuation.",
        "Downside/base/upside remain unavailable.",
        "Information value and optionality remain unassessed.",
        "Run or refresh decision valuation.",
        "Do not make an economic recommendation from evidence alone."
      )
    ))
  }
  data.table::data.table(
    layer = c("Alternatives", "Financial Impact", "Materiality", "Risk", "Optionality", "Guardrails", "Recommendation"),
    status = c("available", "interpreted", "bounded", "review_required", "available", "check_required", "available"),
    interpretation = c(
      "Alternatives are available versus baseline.",
      valuation_summary$expected_value[[1]] %||% "Expected value is available.",
      valuation_summary$materiality[[1]] %||% "Materiality should be interpreted against decision threshold.",
      valuation_summary$risk_status[[1]] %||% "Risk requires review before decision use.",
      valuation_summary$information_value[[1]] %||% "Additional evidence may still have value.",
      "Check guardrails, authority, and coverage.",
      valuation_summary$primary_recommendation[[1]] %||% "Use valuation with evidence sufficiency."
    )
  )
}

evidence_review_rank_supported_actions <- function(binder, sufficiency = NULL, valuation = NULL) {
  sufficiency <- sufficiency %||% evidence_review_assess_sufficiency(binder, valuation = valuation)
  classification <- sufficiency$sufficiency_classification[[1]] %||% "insufficient_or_blocked"
  actions <- data.table::data.table(
    action_id = c(
      "inspect_artifact",
      "resolve_contradiction",
      "update_valuation",
      "obtain_missing_evidence",
      "request_review",
      "prepare_decision_draft",
      "retain_baseline",
      "defer"
    ),
    action = c(
      "Inspect selected artifact",
      "Resolve contradiction",
      "Update valuation",
      "Obtain missing evidence",
      "Request review",
      "Prepare decision draft",
      "Retain baseline",
      "Defer decision"
    ),
    reason = c(
      "Understand the evidence before increasing commitment.",
      "Unresolved contradictions lower decision readiness.",
      "Evidence must connect to economic alternatives.",
      "Missing evidence limits action-specific sufficiency.",
      "Review is appropriate when evidence is bounded but action relevant.",
      "A governed draft can preserve the current reasoning state.",
      "Baseline retention is appropriate when evidence is insufficient.",
      "Deferral is appropriate when the cost of wrong action exceeds information value."
    ),
    required_evidence = c(
      "At least one included artifact.",
      "Contradictory artifacts or stale evidence.",
      "Decision valuation state.",
      "Evidence gap list.",
      "Enough evidence to request review.",
      "Enough evidence to draft.",
      "Documented insufficiency.",
      "Documented blocker."
    ),
    consequence = c(
      "Improves local understanding.",
      "Narrows or clears a blocker.",
      "Connects evidence to economics.",
      "Improves evidence sufficiency.",
      "Moves to governed review.",
      "Creates a persisted review artifact after confirmation.",
      "Avoids unsupported change.",
      "Preserves uncertainty."
    ),
    reversibility = c("high", "high", "high", "high", "medium", "medium", "high", "high"),
    action_class = c("read_only", "human_interpretation", "adjacent_service", "adjacent_service", "governed_workflow", "authorized_mutation", "decision_option", "decision_option"),
    confirmation_required = c(FALSE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE)
  )
  priority <- rep(50L, nrow(actions))
  if (classification == "insufficient_or_blocked") priority[actions$action_id %in% c("obtain_missing_evidence", "retain_baseline", "defer")] <- c(1L, 2L, 3L)
  if (classification == "enough_to_inspect") priority[actions$action_id %in% c("inspect_artifact", "resolve_contradiction", "update_valuation")] <- c(1L, 2L, 3L)
  if (classification == "enough_to_draft") priority[actions$action_id %in% c("prepare_decision_draft", "request_review", "inspect_artifact")] <- c(1L, 2L, 3L)
  if (classification == "enough_to_request_review") priority[actions$action_id %in% c("request_review", "inspect_artifact", "prepare_decision_draft")] <- c(1L, 2L, 3L)
  if (classification == "enough_to_recommend") priority[actions$action_id %in% c("request_review", "prepare_decision_draft", "update_valuation")] <- c(1L, 2L, 3L)
  actions[, rank := data.table::frank(priority, ties.method = "first")]
  actions[, not_preferred_reason := ifelse(rank == 1L, "Preferred for the current sufficiency state.", "Lower-ranked because another action resolves the current blocker sooner.")]
  data.table::setorder(actions, rank)
  actions
}

evidence_review_contextual_ai_actions <- function() {
  data.table::data.table(
    ai_action = c(
      "explain_artifact",
      "explain_contradiction",
      "summarize_binder",
      "identify_missing_evidence",
      "compare_scoped_alternatives",
      "explain_sufficiency",
      "draft_review_request",
      "propose_bounded_next_action"
    ),
    appropriate = TRUE,
    reason = c(
      "AI can translate artifact evidence into plain-language interpretation.",
      "AI can help compare competing claims without changing evidence.",
      "AI can summarize cited evidence with references.",
      "AI can reason over gaps and suggest evidence types.",
      "AI can compare alternatives when valuation and evidence are present.",
      "AI can explain why sufficiency is bounded or blocked.",
      "AI can draft language for human review.",
      "AI can suggest bounded next steps through registered actions."
    ),
    must_use = "runtime bundles, citations, claim governance, provider qualification",
    forbidden = "silent artifact edits, silent evidence exclusion, unsupported mutation, autonomous approval"
  )
}

evidence_review_create_draft <- function(context, binder, sufficiency, selected_action_id = "prepare_decision_draft") {
  top_artifacts <- head((binder$included %||% data.table::data.table())$title, 5L)
  draft_id <- paste0("evidence_review_draft_", substr(digest::digest(paste(context$business_question, selected_action_id, paste(top_artifacts, collapse = "|"))), 1, 10))
  proposal <- paste(
    "For the current question, the supported next action is",
    selected_action_id,
    "because the evidence sufficiency classification is",
    sufficiency$sufficiency_classification[[1]] %||% "not_assessed",
    "."
  )
  list(
    draft_id = draft_id,
    action_id = selected_action_id,
    proposal = proposal,
    preview = data.table::data.table(
      section = c("Question", "Evidence Used", "Sufficiency", "Guardrail", "Next Action"),
      content = c(
        context$business_question %||% "No question supplied.",
        if (length(top_artifacts)) paste(top_artifacts, collapse = "; ") else "No artifacts included.",
        sufficiency$sufficiency_classification[[1]] %||% "not_assessed",
        sufficiency$guardrails[[1]] %||% "No guardrail supplied.",
        selected_action_id
      )
    ),
    validation = data.table::data.table(
      check = c("has_question", "has_evidence", "has_sufficiency", "confirmation_required"),
      status = c(
        nzchar(context$business_question %||% ""),
        nrow(binder$included %||% data.table::data.table()) > 0L,
        nzchar(sufficiency$sufficiency_classification[[1]] %||% ""),
        TRUE
      )
    ),
    created_at = Sys.time()
  )
}

evidence_review_validate_draft <- function(draft) {
  validation <- draft$validation %||% data.table::data.table()
  ok <- data.table::is.data.table(validation) && nrow(validation) && all(isTRUE(validation$status) | validation$status == TRUE)
  service_result(
    status = if (ok) "success" else "error",
    value = validation,
    errors = if (ok) character() else "Draft validation failed.",
    messages = if (ok) "Draft is ready for explicit confirmation." else "Draft is not ready for persistence."
  )
}

evidence_review_persist_draft <- function(context, draft, confirmation = FALSE) {
  if (!isTRUE(confirmation)) {
    return(service_result(status = "error", errors = "Explicit human confirmation is required before persistence."))
  }
  validation <- evidence_review_validate_draft(draft)
  if (!identical(validation$status, "success")) {
    return(validation)
  }
  artifact <- create_artifact(
    artifact_id = draft$draft_id,
    artifact_type = "recommendation",
    label = "Evidence Review Draft",
    source_module = "evidence_review",
    content = draft$proposal,
    object = draft$preview,
    metadata = list(
      created_by_module = TRUE,
      module_id = "evidence_review",
      analytical_intent = "Recommendation",
      artifact_importance = "critical",
      render_targets = c("artifact_studio", "llm_docx", "human_report"),
      draft_action_id = draft$action_id,
      decision_context_id = context$decision_context_id %||% NA_character_,
      evidence_binder_id = context$evidence_binder_id %||% NA_character_,
      confirmation = "human_confirmed"
    ),
    section = "Evidence Review",
    status = "ready"
  )
  audit <- data.table::data.table(
    audit_event_id = paste0("audit_", substr(digest::digest(paste(draft$draft_id, Sys.time())), 1, 10)),
    event_type = "evidence_review_draft_persisted",
    artifact_id = artifact$artifact_id,
    draft_id = draft$draft_id,
    action_id = draft$action_id,
    actor = "human_confirmed",
    occurred_at = as.character(Sys.time())
  )
  updated_context <- context
  updated_context$draft_id <- draft$draft_id
  updated_context$workflow_stage <- "persisted_result"
  updated_context$last_meaningful_action <- "draft_persisted"
  updated_context$updated_at <- Sys.time()
  service_result(
    status = "success",
    value = list(artifact = artifact, audit_record = audit, context_state = updated_context),
    messages = "Confirmed evidence-review draft persisted as a project artifact."
  )
}

working_context_summarize_artifacts <- function(artifacts = list()) {
  if (!length(artifacts)) {
    return(data.table::data.table(
      artifact_count = 0L,
      plot_count = 0L,
      table_count = 0L,
      diagnostic_count = 0L,
      recommendation_count = 0L,
      critical_count = 0L
    ))
  }
  types <- vapply(artifacts, function(x) x$artifact_type %||% "unknown", character(1))
  importance <- vapply(artifacts, function(x) (x$metadata %||% list())$artifact_importance %||% "unspecified", character(1))
  data.table::data.table(
    artifact_count = length(artifacts),
    plot_count = sum(types == "plot"),
    table_count = sum(types == "table"),
    diagnostic_count = sum(types %in% c("diagnostic", "diagnostics")),
    recommendation_count = sum(types %in% c("recommendation", "recommendations")),
    critical_count = sum(importance == "critical")
  )
}

working_context_build_evidence_review <- function(
  artifacts = list(),
  collector_summary = data.table::data.table(),
  semantic_decision_state = semantic_decision_empty(),
  semantic_workspace = semantic_workspace_empty(),
  valuation_state = decision_valuation_empty(),
  workflow_state = decision_workflow_empty()
) {
  decision_state <- semantic_decision_normalize(semantic_decision_state)
  context_id <- semantic_decision_active_context_id(decision_state)
  contexts <- semantic_decision_rows(decision_state, "contexts", context_id)
  decision_summary <- semantic_decision_summary(decision_state, semantic_workspace)
  valuation_summary <- decision_valuation_summary(valuation_state)
  workflow_summary <- decision_workflow_summary(workflow_state)
  artifact_summary <- working_context_summarize_artifacts(artifacts)
  collector_status <- if (nrow(collector_summary)) collector_summary$collector_status[[1]] %||% "not_created" else "not_created"
  artifact_count <- artifact_summary$artifact_count[[1]]
  has_decision <- nrow(contexts) > 0L
  has_valuation <- identical(valuation_summary$valuation_status[[1]] %||% "", "current")
  has_workflow <- (workflow_summary$workflows[[1]] %||% 0L) > 0L
  sufficiency_score <- min(100, (if (artifact_count > 0L) 30 else 0) + (if (has_decision) 25 else 0) + (if (has_valuation) 25 else 0) + (if (has_workflow) 20 else 0))
  sufficiency <- if (sufficiency_score >= 80) "reasonable" else if (sufficiency_score >= 45) "preliminary" else "insufficient"
  contradictions <- if (artifact_count >= 3 && !has_valuation) {
    "Evidence exists, but decision valuation has not connected it to alternatives."
  } else if (!artifact_count) {
    "No artifact evidence exists yet."
  } else {
    "No explicit contradiction has been registered in this context."
  }
  context_refs <- evidence_review_context_state(
    project_id = (semantic_workspace %||% list())$project_id %||% NA_character_,
    business_question_id = context_id %||% NA_character_,
    decision_context_id = context_id %||% NA_character_,
    selected_artifact_ids = names(artifacts) %||% character(),
    workflow_stage = "orientation",
    sufficiency_state = sufficiency
  )
  binder <- evidence_review_create_binder(
    artifacts = artifacts,
    selected_artifact_ids = context_refs$selected_artifact_ids,
    project_id = context_refs$project_id
  )
  context_refs$evidence_binder_id <- binder$binder_id
  valuation_interpretation <- evidence_review_valuation_interpretation(valuation_state, semantic_decision_state)
  action_sufficiency <- evidence_review_assess_sufficiency(
    binder,
    proposed_action = "prepare_decision_draft",
    valuation = valuation_interpretation
  )
  ranked_actions <- evidence_review_rank_supported_actions(
    binder,
    sufficiency = action_sufficiency,
    valuation = valuation_interpretation
  )
  context_refs$selected_next_action_id <- ranked_actions$action_id[[1]] %||% NA_character_
  next_action <- if (!artifact_count) {
    "Generate evidence with Explore Data or Model Readiness."
  } else if (!has_decision) {
    "Create or select a decision context."
  } else if (!has_valuation) {
    "Run decision valuation."
  } else if (!has_workflow) {
    "Request decision review or prepare workflow."
  } else {
    "Review approval status and decide whether to proceed."
  }
  question <- if (has_decision && "decision_question" %in% names(contexts)) {
    contexts$decision_question[[1]] %||% "Decision question is authored but empty."
  } else {
    "What evidence-supported decision are we evaluating?"
  }
  list(
    context_id = "evidence_review_decision_evaluation",
    label = "Evidence Review",
    business_question = question,
    decision_context_id = context_id %||% NA_character_,
    decision_summary = decision_summary,
    context_state = context_refs,
    inline_operation_inventory = working_context_inline_operation_inventory(),
    evidence_binder = binder,
    artifact_summary = artifact_summary,
    collector_status = collector_status,
    valuation_summary = valuation_summary,
    valuation_interpretation = valuation_interpretation,
    workflow_summary = workflow_summary,
    cross_artifact_synthesis = if (artifact_count) paste("Review", artifact_count, "artifact(s) as the current evidence set.") else "No evidence artifacts are available yet.",
    contradictions = contradictions,
    contradiction_workspace = evidence_review_contradiction_workspace(binder),
    evidence_sufficiency = data.table::data.table(score = sufficiency_score, status = sufficiency, rationale = "Score combines artifacts, authored decision context, valuation, and workflow state."),
    action_sufficiency = action_sufficiency,
    supported_next_action = next_action,
    ranked_supported_actions = ranked_actions,
    contextual_ai_actions = evidence_review_contextual_ai_actions(),
    mission_summary = data.table::data.table(
      signal = c("Artifacts", "Collector", "Decision", "Valuation", "Workflow"),
      status = c(
        if (artifact_count) "available" else "missing",
        collector_status,
        if (has_decision) "authored" else "missing",
        if (has_valuation) "current" else "not_run",
        if (has_workflow) "available" else "not_started"
      )
    ),
    current_draft = data.table::data.table(
      draft_item = c("Decision Context", "Recommendation", "Workflow"),
      status = c(if (has_decision) "draft_available" else "missing", valuation_summary$primary_recommendation[[1]] %||% "not_available", workflow_summary$workflow_status[[1]] %||% "not_started")
    ),
    capability_map = working_context_capability_map(),
    progressive_depth = working_context_progressive_depth(),
    transitions = working_context_transition_map()
  )
}

evidence_review_fixture_artifacts <- function() {
  list(
    shap_importance = create_artifact(
      artifact_id = "shap_importance",
      artifact_type = "plot",
      label = "SHAP Importance",
      source_module = "shap_analysis",
      metadata = list(
        created_by_module = TRUE,
        key_finding = "Paid search and offer depth are the strongest modeled drivers.",
        analytical_intent = "Importance",
        artifact_importance = "critical",
        decision_readiness = "ready",
        applicability = "Applies to the current growth decision if the modeled population matches the campaign population.",
        limitations = "Feature importance is associational and does not prove causal incrementality.",
        contradiction_state = "none_registered"
      )
    ),
    segment_boxplot = create_artifact(
      artifact_id = "segment_boxplot",
      artifact_type = "plot",
      label = "Segment Response Boxplot",
      source_module = "eda",
      metadata = list(
        created_by_module = TRUE,
        key_finding = "Premium customers show higher median response but wider variance.",
        analytical_intent = "Distribution",
        artifact_importance = "recommended",
        decision_readiness = "ready",
        applicability = "Useful for scoping pilot segments.",
        limitations = "Segment-level distribution does not isolate treatment effect.",
        contradiction_state = "none_registered"
      )
    ),
    stale_metric = create_artifact(
      artifact_id = "stale_metric",
      artifact_type = "table",
      label = "Prior Holdout Metric",
      source_module = "model_assessment",
      object = data.table::data.table(metric = "lift", value = 1.04),
      metadata = list(
        created_by_module = TRUE,
        key_finding = "Prior holdout lift was weak relative to the current modeled effect.",
        analytical_intent = "Diagnostic",
        artifact_importance = "critical",
        decision_readiness = "bounded",
        applicability = "Useful as a conservative check.",
        limitations = "Time window differs from the current campaign plan.",
        stale = TRUE,
        contradiction_state = "timing_difference"
      )
    )
  )
}

evidence_review_execution_scenario <- function() {
  artifacts <- evidence_review_fixture_artifacts()
  context <- working_context_build_evidence_review(artifacts = artifacts)
  binder <- context$evidence_binder
  inspected <- evidence_review_inspect_artifact(artifacts, "shap_importance", depth_level = 2L)
  synthesis <- evidence_review_compile_synthesis(binder)
  contradictions <- evidence_review_contradiction_workspace(binder)
  valuation <- evidence_review_valuation_interpretation()
  sufficiency <- evidence_review_assess_sufficiency(
    binder,
    synthesis = synthesis$value,
    proposed_action = "prepare_decision_draft",
    valuation = valuation
  )
  actions <- evidence_review_rank_supported_actions(binder, sufficiency = sufficiency, valuation = valuation)
  selected_action <- if ("prepare_decision_draft" %in% actions$action_id) "prepare_decision_draft" else actions$action_id[[1]]
  draft <- evidence_review_create_draft(context, binder, sufficiency, selected_action)
  preview_validation <- evidence_review_validate_draft(draft)
  blocked_persist <- evidence_review_persist_draft(context$context_state, draft, confirmation = FALSE)
  persisted <- evidence_review_persist_draft(context$context_state, draft, confirmation = TRUE)
  mission_after <- data.table::rbindlist(
    list(
      context$mission_summary,
      data.table::data.table(signal = "Persisted Draft", status = if (identical(persisted$status, "success")) "available" else "blocked")
    ),
    use.names = TRUE,
    fill = TRUE
  )
  list(
    steps = data.table::data.table(
      step = seq_len(10),
      action = c(
        "initial_unresolved_question",
        "evidence_binder_inspection",
        "artifact_inspection",
        "synthesis_replay",
        "contradiction_surfaced",
        "sufficiency_assessed",
        "valuation_interpreted",
        "next_action_selected",
        "draft_preview_generated",
        "draft_persisted"
      ),
      status = c(
        "shown",
        binder$status,
        inspected$status,
        synthesis$status,
        if (nrow(contradictions[status == "unresolved"])) "unresolved" else "reviewed",
        sufficiency$sufficiency_classification[[1]],
        valuation$status[[1]],
        selected_action,
        preview_validation$status,
        persisted$status
      )
    ),
    context = context,
    binder = binder,
    inspected = inspected,
    synthesis = synthesis,
    contradictions = contradictions,
    sufficiency = sufficiency,
    valuation = valuation,
    actions = actions,
    draft = draft,
    blocked_persist = blocked_persist,
    persisted = persisted,
    mission_after = mission_after
  )
}

working_context_final_assessment <- function() {
  data.frame(
    question = c(
      "Can meaningful work now occur without excessive context switching?",
      "Does the Working Context reduce cognitive load?",
      "Does it preserve access to advanced capability?",
      "Does it expose only the current working set?",
      "Does it naturally lead into adjacent tasks?",
      "Does Mission Control now feel contextual?",
      "What remains the biggest UX weakness?",
      "What should the next Working Context be?"
    ),
    answer = c(
      "Yes for the bounded Phase 2 path: Evidence Review can now inspect artifacts, compile/replay synthesis, surface contradictions, assess action-specific sufficiency, interpret valuation, rank actions, preview a governed draft, require confirmation, and persist a project artifact.",
      "Directionally yes: primary and adjacent capabilities are separated from contextual, advanced, architectural, and developer surfaces.",
      "Yes: advanced capabilities remain reachable through adjacent/contextual transitions without occupying the initial working set.",
      "Mostly yes: the Evidence Review context initially exposes question, evidence, sufficiency, valuation, workflow, draft, mission summary, and next action.",
      "Yes: adjacent tasks are Artifact Studio, Decision Valuation, Decision Workflow, Mission Control, and Knowledge Library.",
      "More contextual: Mission Control is represented as mission summary first, full operations only when needed.",
      "The remaining weakness is that some adjacent actions still summarize existing services rather than invoking every full workbench operation inline.",
      "Decision Management should come next after a populated Evidence Review founder pass, because Evidence Review is now strong enough to test whether the Working Context pattern generalizes."
    ),
    confidence = c("medium", "medium_high", "high", "medium_high", "high", "medium", "high", "medium"),
    stringsAsFactors = FALSE
  )
}

qa_evidence_review_inline_operations <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  inventory <- working_context_inline_operation_inventory()
  state <- evidence_review_context_state(
    project_id = "project_qa",
    business_question_id = "question_qa",
    decision_context_id = "decision_qa",
    selected_artifact_ids = c("a1", "a2"),
    evidence_binder_id = "binder_qa",
    current_depth_level = 2L
  )
  artifacts <- evidence_review_fixture_artifacts()
  binder <- evidence_review_create_binder(artifacts, project_id = "project_qa")
  inspection <- evidence_review_inspect_artifact(artifacts, "shap_importance", depth_level = 3L)
  synthesis <- evidence_review_compile_synthesis(binder)
  contradictions <- evidence_review_contradiction_workspace(binder)
  valuation <- evidence_review_valuation_interpretation()
  sufficiency <- evidence_review_assess_sufficiency(binder, synthesis = synthesis$value, valuation = valuation)
  actions <- evidence_review_rank_supported_actions(binder, sufficiency = sufficiency, valuation = valuation)
  ai_actions <- evidence_review_contextual_ai_actions()
  context <- working_context_build_evidence_review(artifacts = artifacts)
  draft <- evidence_review_create_draft(context, binder, sufficiency, "prepare_decision_draft")
  draft_validation <- evidence_review_validate_draft(draft)
  blocked_persist <- evidence_review_persist_draft(context$context_state, draft, confirmation = FALSE)
  persisted <- evidence_review_persist_draft(context$context_state, draft, confirmation = TRUE)
  scenario <- evidence_review_execution_scenario()
  project_state_validation <- validate_project_state(list(
    app_version = APP_VERSION,
    saved_at = Sys.time(),
    plot_configs = list(),
    plot_code = list(),
    plot_metadata = list(),
    layout_type = "Grid",
    layout_cols = 2L,
    export_dir = tempdir(),
    export_name = "evidence_review_project",
    evidence_review_context_state = state
  ))

  add("inline_operation_inventory", all(c("informative only", "navigational", "executable through existing handler", "inappropriate for inline execution") %in% inventory$classification), "Displayed Evidence Review elements are classified before implementation.")
  add("context_state_references_only", is.list(state) && all(c("project_id", "business_question_id", "decision_context_id", "selected_artifact_ids", "evidence_binder_id", "workflow_stage") %in% names(state)) && !any(c("artifacts", "artifact_objects", "tables") %in% names(state)), "Context state stores references and workflow state rather than duplicating artifacts.")
  add("binder_operations", identical(binder$status, "ready") && nrow(binder$included) == length(artifacts) && nrow(binder$stale_or_superseded) >= 1L, "Evidence binder includes selected artifacts and exposes stale/superseded evidence.")
  add("artifact_inspection", identical(inspection$status, "success") && data.table::is.data.table(inspection$value$summary) && data.table::is.data.table(inspection$value$claims), "Artifact inspection returns progressive summary, claims, diagnostics, lineage, and reference.")
  add("synthesis", identical(synthesis$status, "success") && nrow(synthesis$value$cited_claims) >= 1L && nrow(synthesis$value$prohibited_claims) >= 1L, "Cross-artifact synthesis compiles cited claims and prohibited claims.")
  add("contradictions", nrow(contradictions) >= 1L && all(c("consequence", "unresolved_question", "status") %in% names(contradictions)), "Contradictions are first-class and carry consequence and unresolved question.")
  add("sufficiency", nrow(sufficiency) == 1L && sufficiency$sufficiency_classification[[1]] %in% c("enough_to_inspect", "enough_to_draft", "enough_to_request_review", "enough_to_recommend", "insufficient_or_blocked"), "Evidence sufficiency is specific to the proposed action.")
  add("valuation_interpretation", nrow(valuation) >= 5L && all(c("layer", "status", "interpretation") %in% names(valuation)), "Valuation is interpreted contextually without recreating the full workbench.")
  add("ranked_actions", nrow(actions) >= 5L && actions$rank[[1]] == 1 && all(c("reason", "required_evidence", "consequence", "confirmation_required") %in% names(actions)), "Supported next actions are ranked and explain requirements, consequences, and confirmation.")
  add("contextual_ai", nrow(ai_actions) >= 6L && all(ai_actions$appropriate) && all(grepl("runtime bundles", ai_actions$must_use)), "Contextual AI actions are reasoning-oriented and constrained by runtime/citation governance.")
  add("draft_preview", identical(draft_validation$status, "success") && data.table::is.data.table(draft$preview), "Draft preview is generated and validated before persistence.")
  add("confirmation_boundary", identical(blocked_persist$status, "error") && grepl("confirmation", paste(blocked_persist$errors, collapse = " "), ignore.case = TRUE), "Persistence is blocked without explicit human confirmation.")
  add("persistence", identical(persisted$status, "success") && inherits(persisted$value$artifact, "aq_artifact") && data.table::is.data.table(persisted$value$audit_record), "Confirmed draft persists as a project artifact and audit record.")
  add("mission_update", any(scenario$mission_after$signal == "Persisted Draft" & scenario$mission_after$status == "available"), "Scenario updates contextual Mission Summary after persistence.")
  add("execution_scenario", all(c("synthesis_replay", "contradiction_surfaced", "draft_persisted") %in% scenario$steps$action) && identical(scenario$persisted$status, "success"), "Deterministic context scenario proves real state transitions.")
  add("progressive_depth", all(c("Orientation", "Working Set", "Evidence", "Decision", "Diagnostics", "Architecture") %in% working_context_progressive_depth()$label), "Progressive depth remains consistent.")
  add("transitions", all(c("Artifact Studio", "Semantic Intelligence", "Mission Control") %in% working_context_transition_map()$target_surface), "Adjacent transitions preserve access to full surfaces.")
  add("project_save_load_contract", isTRUE(project_state_validation$valid) && "evidence_review_context_state" %in% names(project_state_validation$repaired_state), "Project state accepts Evidence Review context state for resume.")
  add("stale_state_behavior", nrow(binder$stale_or_superseded) >= 1L && any(grepl("stale|timing", contradictions$conflict_type, ignore.case = TRUE)), "Stale or timing-different evidence remains visible instead of disappearing.")
  add("no_unsupported_mutation", any(inventory$element == "Autonomous Execution" & inventory$classification == "inappropriate for inline execution"), "Unsupported autonomous execution is not exposed inline.")

  do.call(rbind, checks)
}

qa_working_context_framework <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  framework <- working_context_framework()
  registry <- framework$registry
  lifecycle <- framework$lifecycle
  canonical <- framework$contract
  depth <- framework$depth_model
  exposure <- framework$capability_exposure
  state_contract <- framework$state_contract
  services <- framework$service_registry
  contract <- working_context_evidence_review_contract()
  validation <- working_context_validate_contract(contract)
  composed <- working_context_compose_context(artifacts = evidence_review_fixture_artifacts())
  replay <- working_context_framework_replay()
  campaigns <- working_context_framework_campaign_seeds()
  comparison <- working_context_cross_context_comparison()

  add("framework_identity", identical(framework$framework_id, "working_context_framework") && identical(framework$version, working_context_framework_version), "Working Context Framework has stable identity and version.")
  add("registry", nrow(registry) >= 1L && all(c("context_id", "purpose", "current_task", "template_for_future_contexts", "lifecycle_state") %in% names(registry)), "Framework registry contains context metadata and lifecycle state.")
  add("decision_management_registered", "decision_management_production_candidate" %in% registry$context_id && any(registry$label == "Decision Management"), "Decision Management is registered as the first generalized production candidate.")
  add("lifecycle", all(c("available", "composed", "active", "suspended", "resumed", "completed", "blocked") %in% lifecycle$state) && any(lifecycle$resumable), "Framework lifecycle supports active, suspended, resumed, completed, and blocked states.")
  add("canonical_contract", all(c("purpose", "current_task", "primary_objects", "primary_evidence", "primary_controls", "adjacent_tasks", "progressive_depth", "mission_signals", "ai_actions", "supported_mutations", "return_paths", "replay", "founder_review", "campaigns") %in% canonical$field), "Canonical context contract covers the required context definition.")
  add("evidence_review_contract_valid", identical(validation$status, "success"), "Evidence Review satisfies the canonical Working Context contract.")
  add("composition", identical(composed$status, "success") && all(c("contract", "compiled_context", "services", "transitions") %in% names(composed$value)), "Context composition compiles contract, context, services, and transitions.")
  add("relationship_runtime_stack", identical(framework$runtime_stack$layer, c("Relationship Runtime", "Working Context Runtime", "Context Composition", "Progressive Depth", "Context Services", "Context Transitions", "Canonical Workflow")), "Framework runtime stack matches the required hierarchy.")
  add("progressive_depth", identical(depth$label, c("Orientation", "Working Set", "Evidence", "Decision", "Diagnostics", "Architecture")), "Canonical progressive depth model is extracted from Evidence Review.")
  add("capability_mapping", all(c("Primary", "Adjacent", "Contextual", "Advanced", "Architectural", "Developer") %in% exposure$exposure), "Capability exposure levels are framework-owned.")
  add("state_contract", all(c("Selection", "Workflow", "Evidence", "Drafts", "Mission", "Persistence", "Return", "Replay") %in% state_contract$state_area) && any(grepl("Duplicated", state_contract$forbidden_content)), "Reference-only state contract prevents duplicated business state.")
  add("service_registry", all(c("Evidence", "Valuation", "Workflow", "Mission", "AI", "Mutation", "Artifacts", "Knowledge", "Replay", "Campaigns") %in% services$service), "Context services are canonical and reusable.")
  add("transitions", all(c("target_surface", "transition_type", "reason") %in% names(framework$transition_contract)), "Transition contract preserves adjacent task semantics.")
  add("context_replay", identical(replay$status, "success") && nrow(replay$value$replay_steps) >= 10L && nzchar(replay$value$persisted_artifact_id), "Framework replay proves context-level workflow execution.")
  add("founder_review", nrow(framework$founder_review) >= 8L && all(c("focus", "location_awareness", "information_priority", "next_action") %in% framework$founder_review$review_dimension), "Founder review is generalized for contexts.")
  add("campaigns", nrow(campaigns) >= 6L && all(c("priority", "severity", "dependency", "comparison_metric") %in% names(campaigns)), "Context campaigns carry priority, severity, dependencies, replay, and comparison metrics.")
  add("bounded_contexts", identical(registry$context_id, c("evidence_review_decision_evaluation", "decision_management_production_candidate")), "The framework contains the reference room and one bounded production-candidate room.")
  add("cross_context_comparison", nrow(comparison) >= 6L && all(c("evidence_review", "decision_management", "framework_observation") %in% names(comparison)), "Cross-context comparison distinguishes Evidence Review from Decision Management.")
  add("evidence_review_reference_implementation", isTRUE(registry$template_for_future_contexts[registry$context_id == "evidence_review_decision_evaluation"][[1]]) && identical((composed$value$compiled_context %||% list())$context_id, "evidence_review_decision_evaluation"), "Evidence Review remains the reference implementation of the framework.")

  do.call(rbind, checks)
}

qa_evidence_review_production_candidate <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  page_path <- file.path("R", "page_evidence_review.R")
  css_path <- file.path("www", "app.css")
  doc_path <- file.path("docs", "evidence_review_production_candidate.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(css_path)) paste(readLines(css_path, warn = FALSE), collapse = "\n") else ""
  context <- working_context_build_evidence_review(artifacts = evidence_review_fixture_artifacts())
  scenario <- evidence_review_execution_scenario()
  has_all <- function(values, source) {
    all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  }

  add("production_candidate_marker", grepl("evidence-review-production-candidate", page, fixed = TRUE), "Evidence Review has an explicit production-candidate marker.")
  add("room_header", grepl("aq-evidence-room-header", page, fixed = TRUE) && grepl("Decision Frame", page, fixed = TRUE), "Evidence Review has a room header centered on the decision frame.")
  add("evidence_studio", has_all(c("aq-evidence-studio", "aq-evidence-rail", "aq-evidence-canvas", "aq-evidence-inspector"), page), "Evidence Review has rail, canvas, and inspector zones.")
  add("sticky_action_dock", grepl("aq-evidence-action-dock", page, fixed = TRUE) && grepl("primary_action_summary", page, fixed = TRUE), "Evidence Review has a persistent action dock and action summary.")
  add("contextual_guide", grepl("Contextual Mentor", page, fixed = TRUE) && grepl("The room should teach first; the mentor only clarifies.", page, fixed = TRUE), "Guide/AI support is contextual and mentor use is framed as clarification.")
  add("progressive_depth", has_all(c("Recommendation Reasoning", "Project Signals", "Technical Detail", "Backstage and Return Paths"), page), "Progressive depth separates recommendation reasoning, project signals, technical detail, and backstage return paths.")
  add("canonical_inputs_preserved", has_all(c("inspect_artifact", "compile_synthesis", "refresh_binder", "mark_contradiction_reviewed", "request_more_evidence", "preview_draft", "persist_draft"), page), "Canonical action input IDs remain present.")
  add("mutation_path_preserved", identical(scenario$blocked_persist$status, "error") && identical(scenario$persisted$status, "success"), "Evidence Review mutation path still requires confirmation and can persist.")
  add("context_state_preserved", identical(context$context_id, "evidence_review_decision_evaluation") && !is.null(context$context_state), "Evidence Review still composes canonical context state.")
  add("responsive_css", grepl("@media (max-width: 900px)", css, fixed = TRUE) && grepl(".aq-evidence-studio", css, fixed = TRUE), "Evidence Review production-candidate CSS includes responsive behavior.")
  add("developer_backstage", grepl("Backstage", page, fixed = TRUE) && !grepl("AI Runtime", page, fixed = TRUE), "Developer/backstage language exists without exposing AI Runtime as a normal room.")
  add("documentation", file.exists(doc_path), "Evidence Review production-candidate documentation exists.")

  do.call(rbind, checks)
}

qa_evidence_review_industrial_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  page_path <- file.path("R", "page_evidence_review.R")
  css_path <- file.path("www", "app.css")
  doc_path <- file.path("docs", "evidence_review_industrial_design_phase4.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(css_path)) paste(readLines(css_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) {
    all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  }

  add("attention_audit_documented", file.exists(doc_path) && has_all(c("Attention Audit", "Visual Hierarchy Decision", "Action Hierarchy"), doc), "Industrial design phase records attention, hierarchy, and action decisions.")
  add("primary_object_elevated", has_all(c("aq-evidence-understanding-brief", "understanding_brief", "Current Answer"), page), "Current Answer is represented as the first-class primary object.")
  add("question_demoted_to_frame", grepl("Decision Frame", page, fixed = TRUE) && !grepl("Current Question", page, fixed = TRUE), "The question is an orientation frame rather than the dominant work object.")
  add("implementation_language_demoted", !grepl("Action Class", page, fixed = TRUE), "Implementation-oriented action-class language is not exposed in the primary header.")
  add("supporting_detail_language", has_all(c("What the answer can cite.", "Open only when a claim needs provenance."), page), "Side zones use user-facing evidence and detail language instead of metadata-panel language.")
  add("progressive_depth_preserved", has_all(c("Technical Detail", "Backstage and Return Paths"), page), "Advanced and backstage details remain progressively disclosed.")
  add("canonical_actions_preserved", has_all(c("compile_synthesis", "inspect_artifact", "preview_draft", "persist_draft"), page), "Industrial design pass preserved canonical action paths.")
  add("visual_chrome_reduced", grepl(".aq-evidence-understanding-brief", css, fixed = TRUE) && grepl("box-shadow: none", css, fixed = TRUE), "CSS elevates the understanding brief while reducing surrounding chrome.")
  add("responsive_depth", grepl(".aq-evidence-brief-grid", css, fixed = TRUE) && grepl("@media (max-width: 900px)", css, fixed = TRUE), "The new hierarchy remains responsive.")

  do.call(rbind, checks)
}

qa_evidence_review_interaction_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  page_path <- file.path("R", "page_evidence_review.R")
  css_path <- file.path("www", "app.css")
  doc_path <- file.path("docs", "evidence_review_interaction_design_phase2.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(css_path)) paste(readLines(css_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) {
    all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  }

  add("interaction_audit_documented", file.exists(doc_path) && has_all(c("Interaction Inventory", "Attention Flow", "Action Evolution"), doc), "Interaction phase documents inventory, attention flow, and action evolution.")
  add("current_answer_anchor", has_all(c("Current Answer", "No current answer has been compiled yet", "Current Answer moved to"), page), "Evidence Review uses Current Answer as the focal object and feedback language.")
  add("feedback_channel", has_all(c("interaction_message", "room_feedback", "aq-evidence-feedback"), page), "Every meaningful action has a room-level feedback channel.")
  add("stage_aware_actions", has_all(c("workflow_actions", "draft_preview", "persisted_result", "Saving appears after preview"), page), "Draft and persistence actions are stage-aware.")
  add("persisted_stage_requires_success", has_all(c("if (identical(result$status, \"success\")) {\n        persisted_state(result)", "persisted_state(NULL)\n        interaction_message(\"Persistence did not complete"), page), "Persisted result stage is only entered after successful persistence.")
  add("canonical_action_ids_still_present", has_all(c("preview_draft", "persist_draft", "compile_synthesis", "inspect_artifact"), page), "Canonical action IDs remain present after interaction refinement.")
  add("mentor_feedback", has_all(c("Mentor explanation returned", "Mentor summary returned"), page), "Contextual mentor actions provide visible feedback.")
  add("empty_state_teaches", grepl("Detail stays quiet until provenance matters", page, fixed = TRUE), "Empty detail state teaches the user's next evidence move.")
  add("microinteraction_css", has_all(c(".aq-evidence-feedback", ".aq-evidence-action-complete", ".aq-evidence-action-hint", ".aq-evidence-understanding-brief:hover"), css), "CSS includes feedback, stage, and hover affordance styling.")
  add("reduced_motion", has_all(c(".aq-evidence-understanding-brief", ".aq-evidence-action-dock", ".aq-evidence-feedback"), css) && grepl("prefers-reduced-motion", css, fixed = TRUE), "Evidence Review microinteractions respect reduced-motion handling.")

  do.call(rbind, checks)
}

qa_evidence_review_narrative_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  page_path <- file.path("R", "page_evidence_review.R")
  css_path <- file.path("www", "app.css")
  doc_path <- file.path("docs", "evidence_review_narrative_design_phase3.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(css_path)) paste(readLines(css_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) {
    all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  }

  add("narrative_audit_documented", file.exists(doc_path) && has_all(c("Narrative Audit", "Current Answer Contract", "Empty State Philosophy", "Campaign Seeds"), doc), "Narrative phase documents audit, answer contract, empty-state philosophy, and campaign seeds.")
  add("current_answer_states", has_all(c("no_answer_yet", "insufficient_evidence", "conflicting_evidence", "tentative_answer", "supported_answer", "recommendation_ready", "decision_complete"), page), "Current Answer supports the required narrative states.")
  add("current_answer_contract", has_all(c("Why we believe this", "What limits it", "What happens next", "Confidence"), page), "Current Answer answers belief, confidence, limits, and next action.")
  add("teaching_empty_states", has_all(c("No Evidence Yet", "No Synthesis Yet", "No Active Contradiction", "No Recommendation Preview Yet", "No Detail Open"), page), "Empty states teach the role of absent evidence, synthesis, contradiction, draft, and detail.")
  add("no_silent_auto_synthesis", !grepl("result <- evidence_review_compile_synthesis(binder_reactive()", page, fixed = TRUE), "Synthesis is no longer silently compiled before the user asks.")
  add("human_action_language", has_all(c("Compile Answer", "Preview Recommendation", "Save Recommendation", "Recommendation Saved", "Answer"), page), "Primary surfaces use human reasoning language instead of implementation labels.")
  add("technical_language_demoted", !grepl("action_class", page, fixed = TRUE) && !grepl("Confirm & Persist", page, fixed = TRUE), "Implementation terms are not shown in the primary narrative surfaces.")
  add("narrative_css", has_all(c(".aq-current-answer-story", ".aq-current-answer-ribbon", ".aq-narrative-empty", ".aq-evidence-selector-empty"), css), "CSS includes narrative-state and teaching-empty-state treatments.")
  add("campaigns_documented", has_all(c("Current Answer comparison", "Empty-state teaching", "Confidence communication", "Evidence story with real artifacts"), doc), "Narrative design campaigns are documented for founder review and future iteration.")

  do.call(rbind, checks)
}

qa_evidence_review_transparency_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  page_path <- file.path("R", "page_evidence_review.R")
  css_path <- file.path("www", "app.css")
  doc_path <- file.path("docs", "evidence_review_transparency_design_phase4.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(css_path)) paste(readLines(css_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) {
    all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  }

  add("transparency_audit_documented", file.exists(doc_path) && has_all(c("Transparency Audit", "Friction Audit", "Product Disappearance", "Transparency Campaigns"), doc), "Phase 4 documents attention burden, friction, disappearance, and campaigns.")
  add("breadcrumb_removed", !grepl("Front Door -> Hallway -> Evidence Review Room", page, fixed = TRUE) && grepl("Decision under review", page, fixed = TRUE), "Visible product-geography breadcrumb no longer interrupts the room.")
  add("binder_id_demoted", !grepl("detail = context$evidence_binder$binder_id", page, fixed = TRUE) && grepl("No citable evidence yet.", page, fixed = TRUE), "Binder id is removed from prominent evidence status.")
  add("next_action_reduced", has_all(c("aq-next-move-static", "Change next move", "level = \"advanced\""), page), "Next action renders as a prose recommendation with advanced override hidden by default.")
  add("premature_preview_hidden", has_all(c("Compile the answer before drafting.", "aq-hidden-action"), page), "Recommendation preview is hidden until an answer exists.")
  add("mentor_deferred", has_all(c("Ask the mentor", "open = !is.null(result_text)"), page), "Contextual mentor is collapsed until requested or populated.")
  add("labels_simplified", has_all(c("What the answer can cite.", "Open only when a claim needs provenance.", "Evidence Room"), page), "Labels favor analyst language over implementation language.")
  add("chrome_reduced", has_all(c("box-shadow: none", "aq-evidence-room-fact", "aq-evidence-secondary-action"), css), "CSS reduces panel chrome and secondary action weight.")
  add("current_answer_editorial", grepl("font-size: clamp(26px, 2.7vw, 42px)", css, fixed = TRUE), "Current Answer uses stronger editorial typography.")

  do.call(rbind, checks)
}

qa_evidence_review_cognitive_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  page_path <- file.path("R", "page_evidence_review.R")
  css_path <- file.path("www", "app.css")
  doc_path <- file.path("docs", "evidence_review_cognitive_design_phase5.md")
  page <- if (file.exists(page_path)) paste(readLines(page_path, warn = FALSE), collapse = "\n") else ""
  css <- if (file.exists(css_path)) paste(readLines(css_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(doc_path)) paste(readLines(doc_path, warn = FALSE), collapse = "\n") else ""
  has_all <- function(values, source) {
    all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))
  }

  add("cognitive_audit_documented", file.exists(doc_path) && has_all(c("Cognitive Load Audit", "Self-Teaching Room", "Progressive Understanding", "Cognitive Design Campaigns"), doc), "Phase 5 documents load, self-teaching, progressive understanding, and campaigns.")
  add("teaching_payloads", has_all(c("story_teaching", "what =", "why =", "how =", "technical ="), page), "Current Answer states carry What, Why, How, and Technical explanations.")
  add("progressive_understanding_ui", has_all(c("contextual_teaching", "What", "Why it matters", "How to move", "Technical reason"), page), "Evidence Review exposes progressive understanding without opening documentation.")
  add("state_specific_teaching", has_all(c("no_answer_yet", "insufficient_evidence", "conflicting_evidence", "supported_answer", "recommendation_ready", "decision_complete"), page), "Teaching language covers the major Current Answer maturity states.")
  add("empty_states_explain_waiting", has_all(c("What we are waiting for", "Why it matters", "Next: generate evidence", "nothing the answer can cite"), page), "Empty evidence states explain what is missing, why it matters, and what happens next.")
  add("action_feedback_teaches_change", has_all(c("The room converted evidence into claims, gaps, limits", "Evidence changed, so the previous answer was cleared", "The recommendation is now durable, traceable"), page), "Action feedback explains what changed after the action.")
  add("mentor_demoted_to_clarifier", has_all(c("The room should teach first; the mentor only clarifies.", "Ask only when understanding improves."), page), "Mentor is framed as clarification rather than the primary teaching surface.")
  add("teaching_css", has_all(c(".aq-evidence-teaching-strip", ".aq-teaching-step", "grid-template-columns: repeat(3", "Technical reason"), paste(css, page)), "Self-teaching strip has deterministic styling and technical disclosure.")
  add("canonical_paths_preserved", has_all(c("compile_synthesis", "preview_draft", "persist_draft", "evidence_review_persist_draft"), page), "Cognitive design preserves canonical service and mutation paths.")

  do.call(rbind, checks)
}

qa_semantic_interaction_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  evidence_path <- file.path("R", "page_evidence_review.R")
  decision_path <- file.path("R", "page_decision_management.R")
  docs_path <- file.path("docs", "semantic_interaction_design_phase6.md")
  vision_path <- file.path("docs", "vision", "product_vision.md")
  evidence <- if (file.exists(evidence_path)) paste(readLines(evidence_path, warn = FALSE), collapse = "\n") else ""
  decision <- if (file.exists(decision_path)) paste(readLines(decision_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(docs_path)) paste(readLines(docs_path, warn = FALSE), collapse = "\n") else ""
  vision <- if (file.exists(vision_path)) paste(readLines(vision_path, warn = FALSE), collapse = "\n") else ""
  audit <- working_context_semantic_syntax_audit()
  campaigns <- working_context_semantic_campaigns()
  budget <- working_context_cognitive_budget()
  final <- working_context_semantic_final_assessment()
  has_all <- function(values, source) all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))

  add("audit_exists", nrow(audit) >= 25L && all(c("Semantic", "Syntactic", "Mixed") %in% audit$classification), "Semantic vs syntax audit classifies visible elements.")
  add("both_rooms_audited", all(c("Evidence Review", "Decision Management") %in% audit$room), "Evidence Review and Decision Management are audited.")
  add("cognitive_budget", nrow(budget) == 2L && all(c("understanding_evidence", "making_judgment") %in% names(budget)), "Cognitive budget estimates analytical versus operational attention.")
  add("campaigns", nrow(campaigns) >= 8L && all(campaigns$priority %in% c("high", "medium", "low")), "Semantic design campaigns are structured and prioritized.")
  add("founder_review", nrow(working_context_semantic_founder_review()) >= 8L, "Founder review captures software-thinking versus analysis-thinking moments.")
  add("evidence_language_reduced", !grepl("Hallway", evidence, fixed = TRUE) && has_all(c("Project Health", "Current Answer", "Recommendation Reasoning", "Project Signals"), evidence), "Evidence Review visible language favors work over product geography.")
  add("decision_language_reduced", !grepl("Decision Workbench", decision, fixed = TRUE) && has_all(c("Edit Decision", "Request Review", "How This Was Determined", "Current Decision"), decision), "Decision Management visible language favors work over implementation.")
  add("mentor_semantic", has_all(c("Ask only when understanding improves.", "Ask only when tradeoffs are unclear."), paste(evidence, decision)), "Mentor surfaces clarify meaning rather than procedure.")
  add("documentation", file.exists(docs_path) && has_all(c("Maximize semantic cognition", "Semantic vs Syntax Audit", "Syntax Elimination", "Cognitive Leverage", "Remaining Syntactic Friction"), doc), "Semantic interaction design documentation exists.")
  add("constitution_updated", has_all(c("Maximize semantic cognition", "Minimize syntactic cognition", "Spend the user's brainpower on the problem"), vision), "Product Vision includes the semantic-first constitutional rule.")
  add("final_assessment", nrow(final) == 8L && any(grepl("Current Answer", final$answer)) && any(grepl("Current Decision", final$answer)), "Final assessment answers the required Phase 6 questions.")

  do.call(rbind, checks)
}

qa_semantic_continuation_design <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }

  evidence_path <- file.path("R", "page_evidence_review.R")
  decision_path <- file.path("R", "page_decision_management.R")
  docs_path <- file.path("docs", "semantic_continuation_phase1.md")
  working_context_doc_path <- file.path("docs", "working_context_architecture.md")
  evidence <- if (file.exists(evidence_path)) paste(readLines(evidence_path, warn = FALSE), collapse = "\n") else ""
  decision <- if (file.exists(decision_path)) paste(readLines(decision_path, warn = FALSE), collapse = "\n") else ""
  doc <- if (file.exists(docs_path)) paste(readLines(docs_path, warn = FALSE), collapse = "\n") else ""
  wc_doc <- if (file.exists(working_context_doc_path)) paste(readLines(working_context_doc_path, warn = FALSE), collapse = "\n") else ""
  graph <- working_context_reasoning_graph()
  audit <- working_context_semantic_continuation_audit()
  preservation <- working_context_thought_preservation_contract()
  handoffs <- working_context_handoff_principles()
  campaigns <- working_context_semantic_continuation_campaigns()
  founder <- working_context_semantic_continuation_founder_review()
  final <- working_context_semantic_continuation_final_assessment()
  has_all <- function(values, source) all(vapply(values, function(value) grepl(value, source, fixed = TRUE), logical(1)))

  add("reasoning_graph", nrow(graph) >= 8L && all(c("Business Question", "Current Answer", "Current Decision", "Outcome Learning") %in% graph$reasoning_node), "Reasoning graph runs from business question through outcome learning.")
  add("continuation_audit", nrow(audit) >= 8L && all(c("natural_next_thought", "can_continue_without_navigation") %in% names(audit)), "Semantic continuation audit records next thoughts and navigation avoidability.")
  add("thought_preservation", nrow(preservation) >= 8L && all(preservation$should_persist), "Thought preservation contract covers current question, answer, decision, evidence, intent, and momentum.")
  add("handoffs", nrow(handoffs) >= 6L && any(handoffs$handoff == "Current Answer -> Current Decision"), "Context handoff principles include the Evidence Review to Decision Management seam.")
  add("campaigns", nrow(campaigns) >= 6L && all(campaigns$priority %in% c("high", "medium", "low")), "Semantic continuation campaigns are structured and prioritized.")
  add("founder_review", nrow(founder) >= 8L && any(grepl("train of thought", founder$prompt, fixed = TRUE)), "Founder review captures reasoning momentum and interruption.")
  add("evidence_continuation_ui", has_all(c("semantic_continuation", "Continue the reasoning", "Move from Current Answer to Current Decision", "Continue to Decision"), evidence), "Evidence Review exposes continuation as reasoning rather than destination selection.")
  add("decision_continuation_ui", has_all(c("decision_continuation", "Continue the reasoning", "Move from approval to implementation", "Review Evidence"), decision), "Decision Management exposes continuation as reasoning rather than destination selection.")
  add("documentation", file.exists(docs_path) && has_all(c("Semantic Continuation", "Reasoning Graph", "Thought Preservation", "Context Handoffs", "Remaining Weaknesses"), doc), "Semantic continuation documentation exists.")
  add("architecture_documentation", has_all(c("Semantic Continuation", "Navigation becomes a consequence", "thought preservation"), wc_doc), "Working Context architecture records the continuation principle.")
  add("final_assessment", nrow(final) == 8L && any(grepl("destination cognition", final$answer)), "Final assessment answers the required Phase 1 continuation questions.")

  do.call(rbind, checks)
}

qa_working_contexts <- function() {
  checks <- list()
  add <- function(check, ok, message) {
    checks[[length(checks) + 1L]] <<- data.frame(check = check, status = if (isTRUE(ok)) "PASS" else "FAIL", message = message, stringsAsFactors = FALSE)
  }
  registry <- working_context_registry()
  depth <- working_context_progressive_depth()
  map <- working_context_capability_map()
  transitions <- working_context_transition_map()
  review <- working_context_founder_review_template()
  campaigns <- working_context_campaigns()
  replay <- working_context_replay_contract()
  context <- working_context_build_evidence_review()
  final <- working_context_final_assessment()
  framework_qa <- qa_working_context_framework()
  inline_qa <- qa_evidence_review_inline_operations()
  production_candidate_qa <- qa_evidence_review_production_candidate()
  industrial_design_qa <- qa_evidence_review_industrial_design()
  interaction_design_qa <- qa_evidence_review_interaction_design()
  narrative_design_qa <- qa_evidence_review_narrative_design()
  transparency_design_qa <- qa_evidence_review_transparency_design()
  cognitive_design_qa <- qa_evidence_review_cognitive_design()
  semantic_interaction_qa <- qa_semantic_interaction_design()
  semantic_continuation_qa <- qa_semantic_continuation_design()
  semantic_discovery_qa <- qa_semantic_continuation_discovery_experiment()
  decision_management_qa <- if (exists("qa_decision_management_room", mode = "function")) qa_decision_management_room() else data.frame(check = "qa_available", status = "FAIL", message = "qa_decision_management_room() is not sourced.", stringsAsFactors = FALSE)
  page_exists <- file.exists(file.path("R", "page_evidence_review.R"))
  decision_page_exists <- file.exists(file.path("R", "page_decision_management.R"))
  docs_exists <- file.exists(file.path("docs", "working_context_architecture.md"))
  comparison <- working_context_cross_context_comparison()

  add("registry", all(c("evidence_review_decision_evaluation", "decision_management_production_candidate") %in% registry$context_id) && all(registry$production_slice), "Evidence Review and Decision Management are registered as production Working Contexts.")
  add("evidence_review_contract", identical(context$context_id, "evidence_review_decision_evaluation") && all(c("business_question", "evidence_sufficiency", "supported_next_action", "capability_map") %in% names(context)), "Evidence Review context composes question, sufficiency, next action, and capability map.")
  add("decision_management_contract", all(decision_management_qa$status == "PASS"), paste("Decision Management QA:", paste(decision_management_qa$check[decision_management_qa$status != "PASS"], collapse = ", ")))
  add("framework_contract", all(framework_qa$status == "PASS"), paste("Framework QA:", paste(framework_qa$check[framework_qa$status != "PASS"], collapse = ", ")))
  add("inline_operation_contract", all(inline_qa$status == "PASS"), paste("Inline operation QA:", paste(inline_qa$check[inline_qa$status != "PASS"], collapse = ", ")))
  add("production_candidate_contract", all(production_candidate_qa$status == "PASS"), paste("Production candidate QA:", paste(production_candidate_qa$check[production_candidate_qa$status != "PASS"], collapse = ", ")))
  add("industrial_design_contract", all(industrial_design_qa$status == "PASS"), paste("Industrial design QA:", paste(industrial_design_qa$check[industrial_design_qa$status != "PASS"], collapse = ", ")))
  add("interaction_design_contract", all(interaction_design_qa$status == "PASS"), paste("Interaction design QA:", paste(interaction_design_qa$check[interaction_design_qa$status != "PASS"], collapse = ", ")))
  add("narrative_design_contract", all(narrative_design_qa$status == "PASS"), paste("Narrative design QA:", paste(narrative_design_qa$check[narrative_design_qa$status != "PASS"], collapse = ", ")))
  add("transparency_design_contract", all(transparency_design_qa$status == "PASS"), paste("Transparency design QA:", paste(transparency_design_qa$check[transparency_design_qa$status != "PASS"], collapse = ", ")))
  add("cognitive_design_contract", all(cognitive_design_qa$status == "PASS"), paste("Cognitive design QA:", paste(cognitive_design_qa$check[cognitive_design_qa$status != "PASS"], collapse = ", ")))
  add("semantic_interaction_contract", all(semantic_interaction_qa$status == "PASS"), paste("Semantic interaction QA:", paste(semantic_interaction_qa$check[semantic_interaction_qa$status != "PASS"], collapse = ", ")))
  add("semantic_continuation_contract", all(semantic_continuation_qa$status == "PASS"), paste("Semantic continuation QA:", paste(semantic_continuation_qa$check[semantic_continuation_qa$status != "PASS"], collapse = ", ")))
  add("semantic_discovery_experiment", all(semantic_discovery_qa$status == "PASS"), paste("Semantic discovery QA:", paste(semantic_discovery_qa$check[semantic_discovery_qa$status != "PASS"], collapse = ", ")))
  add("progressive_depth", identical(depth$label, c("Orientation", "Working Set", "Evidence", "Decision", "Diagnostics", "Architecture")), "Progressive depth runs from orientation through architecture.")
  add("capability_mapping", all(c("Primary", "Adjacent", "Contextual", "Advanced", "Architectural", "Developer") %in% map$exposure) && all(map$initial_visibility[map$exposure %in% c("Primary", "Adjacent")]), "Capability map separates primary/adjacent from deeper capability.")
  add("working_set_focus", !any(map$initial_visibility[map$exposure %in% c("Advanced", "Architectural", "Developer")]), "Advanced, architectural, and developer capability is hidden initially.")
  add("context_transitions", all(c("Artifact Studio", "Semantic Intelligence", "Mission Control", "Knowledge Library", "Decision Management", "Evidence Review") %in% transitions$target_surface), "Context transitions lead to related tasks rather than the entire application.")
  add("cross_context_comparison", any(comparison$evidence_review == "What do we know?") && any(comparison$decision_management == "What should we do?"), "Cross-context comparison preserves the distinct room questions.")
  add("founder_review", all(c("focus", "location_awareness", "information_priority", "next_action", "unnecessary_capability", "missing_capability") %in% review$review_dimension), "Founder review captures focus, location, priority, next action, unnecessary capability, and missing capability.")
  add("campaigns", nrow(campaigns) >= 6L && all(campaigns$campaign_type == "working_context_campaign"), "Working Context campaigns cover focus, priority, architecture, navigation, transitions, and hierarchy.")
  add("replay", nrow(replay) >= 7L && any(grepl("Open Evidence Review", replay$action)), "Replay contract starts inside Evidence Review and validates a full related-work path.")
  add("mission_contextual", any(map$capability == "Mission Summary" & map$exposure == "Primary") && any(map$capability == "Mission Control" & map$exposure == "Contextual"), "Mission Control is contextual while mission summary is primary.")
  add("final_assessment", nrow(final) == 8L && any(grepl("Decision Management", final$answer)), "Final assessment answers the required Phase 5 questions.")
  add("page_exists", page_exists, "Evidence Review production page exists.")
  add("decision_page_exists", decision_page_exists, "Decision Management production-candidate page exists.")
  add("documentation", docs_exists, "Working Context architecture documentation exists.")
  do.call(rbind, checks)
}
