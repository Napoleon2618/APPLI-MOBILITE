<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0
- Modified principles:
  - II. Test-First Development (NON-NEGOTIABLE) — domain correction: replaced transport
    examples ("trip calculation, routing, pricing, geolocation") with the project's actual
    domain (exercise content, progression tracking, session/workout data).
  - III. User Experience Consistency — rationale corrected: removed "riders and drivers /
    missed trips" transport framing, replaced with mobility-exercise user framing
    (at-home/gym users following a routine).
  - IV. Performance & Reliability — corrected example operations and dependencies from
    transport concerns (route calculation, booking, maps, payments, geolocation) to the
    actual domain (exercise library browsing, media/video playback, progress sync, local
    storage).
  - V. Security & Data Privacy — corrected from location/trip-data framing to user
    account and progress data; explicitly states no sensitive medical/health data is
    processed and no regulatory compliance regime is currently known to apply.
- Added sections: none (Additional Constraints materially expanded, not newly added)
- Removed sections: none
- Materially expanded guidance:
  - Additional Constraints — target platforms fixed to iOS and Android; a cross-platform
    default approach is now mandated (with a justified-exception path for native), and the
    regulatory-compliance placeholder is resolved to "none known at this stage." Specific
    frameworks/languages remain explicitly deferred to `/speckit-plan`.
- Templates requiring follow-up:
  - .specify/templates/plan-template.md — ⚠ pending manual check that the Constitution
    Check gate reflects the cross-platform-by-default constraint when the first plan is run
  - .specify/templates/spec-template.md — ✅ no changes required (principle-agnostic)
  - .specify/templates/tasks-template.md — ✅ no changes required (principle-agnostic)
  - .claude/skills/speckit-*/SKILL.md — ✅ no changes required (read constitution at runtime)
- Deferred items:
  - Specific technology stack (framework/language for the cross-platform implementation)
    intentionally left open; MUST be decided and justified in `/speckit-plan`.
-->

# APPLI-MOBILITE Constitution

## Core Principles

### I. Code Quality & Maintainability
Code MUST be readable, consistently formatted, and reviewed before merging to the main
branch. Every change MUST pass linting and static analysis configured for the project
before it is considered mergeable. Functions and modules MUST have a single, clear
responsibility; duplication MUST be refactored into shared code once it appears a third
time (rule of three), not preemptively. Public interfaces (APIs, shared components,
libraries) MUST be documented well enough for another contributor to use them without
reading their implementation.
**Rationale**: A mobility (physical exercise) application is a long-lived, trust-sensitive
product; uncontrolled complexity and inconsistent style directly increase the rate of
defects and the cost of every future change.

### II. Test-First Development (NON-NEGOTIABLE)
New behavior MUST be covered by automated tests written before or alongside the
implementation; a bug fix MUST include a regression test that fails without the fix and
passes with it. The Red-Green-Refactor cycle MUST be followed for non-trivial logic:
write a failing test, make it pass with the minimum code necessary, then refactor.
Untested code paths that affect exercise/routine content, progression tracking, session
logging, or user data MUST NOT be merged.
**Rationale**: Exercise progression and session history are difficult to verify manually
and directly shape what a user is guided to do next; tests are the primary safeguard
against silent regressions that would give a user incorrect content or lose their
progress.

### III. User Experience Consistency
User-facing flows MUST follow a single, consistent design language and interaction
pattern across the application; new screens MUST reuse existing shared components before
introducing new ones. Error states, loading states, and empty states MUST be handled
explicitly for every user-facing screen — silent failures or blank screens are not
acceptable. Any accessibility requirement (contrast, tap-target size, screen-reader
labeling) applicable to the target platform MUST be met before a UI change ships.
**Rationale**: Users follow mobility/exercise routines hands-on and often mid-session
(mid-stretch, mid-workout); inconsistent or unclear UX breaks concentration and directly
discourages continued use.

### IV. Performance & Reliability
User-facing operations (browsing the exercise library, starting/playing a routine,
syncing progress) MUST have an explicit acceptable latency budget, and changes that
regress measured performance beyond that budget MUST NOT be merged without an approved
justification. The application MUST degrade gracefully when network connectivity or
upstream services (content delivery, progress sync) are unavailable — previously loaded
content and locally recorded progress MUST remain usable offline rather than causing a
crash or hang. Background/idle resource usage (battery, data) MUST be considered for any
feature that runs while the app is not in active use.
**Rationale**: Exercise sessions are frequently run on mobile devices with imperfect
connectivity (home, gym, outdoors) and often with the screen actively watched during
movement; performance and offline resilience are core to the product being usable at all,
not optional polish.

### V. Security & Data Privacy
User account data and exercise progress data MUST be handled according to the principle
of least privilege: collected only when needed for a stated feature, stored only as long
as needed, and never logged in plaintext. All external inputs (user input, third-party
APIs, deep links) MUST be validated and sanitized at the boundary. Secrets and
credentials MUST NOT be committed to the repository, and MUST be sourced from a secrets
manager or environment configuration instead. The application does not process sensitive
medical or health data — only exercise content and user-entered progress/session data —
and no specific regulatory compliance regime (e.g., health-data regulation) is known to
apply at this stage; general data-minimization and secure-handling practice above still
applies regardless. If a future feature introduces a new category of sensitive data
(e.g., health metrics, biometric data), this constitution MUST be amended before that
feature is implemented, so the applicable compliance requirements can be made explicit.
**Rationale**: Even without a known regulatory trigger, account and progress data are
personal to the user and a breach or misuse would still damage user trust and could carry
consequences the project has not yet had reason to formally assess.

## Additional Constraints

Target platforms are iOS and Android. A cross-platform implementation approach is
REQUIRED by default: it maximizes shared code and a single consistent UI/interaction
layer across both platforms, directly supporting Principle I (avoid duplicated
maintenance across two native codebases) and Principle III (one design language instead
of two divergent native ones). A native, platform-specific implementation for a given
feature or module MUST be treated as an exception and explicitly justified in that
feature's plan (e.g., a capability that is unavailable, degraded, or unacceptably slow
through the cross-platform toolchain). The specific framework and language are NOT fixed
by this constitution and MUST be selected and justified in `/speckit-plan` for the first
feature that requires it; the choice should honor the cross-platform-by-default
constraint above unless the plan documents a justified exception.

No regulatory compliance regime is currently known to apply to this project: it does not
process sensitive medical/health data, only exercise content and user progress data (see
Principle V). This is not a permanent exemption — if the data processed by the
application changes in kind, this section and Principle V MUST be revisited via
`/speckit-constitution` before implementation proceeds under the new requirement.

## Development Workflow & Quality Gates

All changes MUST go through code review before merging; the reviewer MUST verify
compliance with the Core Principles above, not only correctness. Automated checks
(tests, lint, type-check where applicable) MUST pass in CI before a change is merged.
Any deviation from a Core Principle MUST be explicitly called out and justified in the
pull request description; unexplained deviations MUST be treated as blocking review
feedback. Feature work MUST proceed through the Spec Kit workflow
(`/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`) so that
intent, design, and tasks are traceable before code is written.

## Governance

This constitution supersedes any conflicting informal practice. Amendments are made via
the `/speckit-constitution` command, which MUST update the version according to semantic
versioning (MAJOR for backward-incompatible governance or principle removal/redefinition,
MINOR for a new principle or materially expanded guidance, PATCH for clarifications and
wording fixes) and MUST record a Sync Impact Report describing what changed. Every pull
request MUST be checked for compliance with this constitution during review; unresolved
non-compliance MUST block merge unless an explicit, documented exception is granted.
Complexity introduced against a Core Principle MUST be justified in writing in the
relevant plan or PR. Day-to-day development guidance that is not itself governance
belongs in project docs (e.g., CLAUDE.md, README.md), not in this file.

**Version**: 1.1.0 | **Ratified**: 2026-08-20 | **Last Amended**: 2026-08-20
