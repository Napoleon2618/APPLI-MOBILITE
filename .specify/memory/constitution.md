<!--
Sync Impact Report
- Version change: (none) → 1.0.0
- Modified principles: n/a (initial ratification)
- Added sections:
  - Core Principles: I. Code Quality & Maintainability, II. Test-First Development
    (NON-NEGOTIABLE), III. User Experience Consistency, IV. Performance & Reliability,
    V. Security & Data Privacy
  - Additional Constraints
  - Development Workflow & Quality Gates
  - Governance
- Removed sections: none
- Templates requiring follow-up:
  - .specify/templates/plan-template.md — ⚠ pending manual check that the Constitution
    Check gate references these five principles by name
  - .specify/templates/spec-template.md — ✅ no changes required (principle-agnostic)
  - .specify/templates/tasks-template.md — ✅ no changes required (principle-agnostic)
  - .claude/skills/speckit-*/SKILL.md — ✅ no changes required (read constitution at runtime)
- Deferred items:
  - TODO(RATIFICATION_DATE): confirmed as the date this constitution was first adopted
    (2026-08-20, the date this command was run). Update if an earlier informal ratification
    date should be used instead.
  - Technology stack, target platforms, and compliance requirements were not specified by the
    user at ratification time; Additional Constraints section captures placeholders to be
    refined via a future `/speckit-constitution` amendment once the stack is chosen.
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
**Rationale**: A mobility application is a long-lived, safety- and trust-sensitive product;
uncontrolled complexity and inconsistent style directly increase the rate of defects and
the cost of every future change.

### II. Test-First Development (NON-NEGOTIABLE)
New behavior MUST be covered by automated tests written before or alongside the
implementation; a bug fix MUST include a regression test that fails without the fix and
passes with it. The Red-Green-Refactor cycle MUST be followed for non-trivial logic:
write a failing test, make it pass with the minimum code necessary, then refactor.
Untested code paths that affect trip calculation, routing, pricing, geolocation, or user
data MUST NOT be merged.
**Rationale**: Mobility features (routes, pricing, real-time location) are difficult to
verify manually and have high user-facing impact when wrong; tests are the primary
safeguard against silent regressions.

### III. User Experience Consistency
User-facing flows MUST follow a single, consistent design language and interaction
pattern across the application; new screens MUST reuse existing shared components before
introducing new ones. Error states, loading states, and empty states MUST be handled
explicitly for every user-facing screen — silent failures or blank screens are not
acceptable. Any accessibility requirement (contrast, tap-target size, screen-reader
labeling) applicable to the target platform MUST be met before a UI change ships.
**Rationale**: Riders and drivers depend on the app in time-sensitive, often
outdoor/mobile contexts; inconsistent or unclear UX directly causes missed trips and lost
trust.

### IV. Performance & Reliability
User-facing operations (search, route calculation, booking, real-time tracking) MUST
have an explicit acceptable latency budget, and changes that regress measured performance
beyond that budget MUST NOT be merged without an approved justification. The application
MUST degrade gracefully when network connectivity or upstream services (maps, payments,
geolocation) are unavailable, rather than crashing or hanging. Background/idle resource
usage (battery, data) MUST be considered for any feature that runs while the app is not
in active use.
**Rationale**: Mobility apps are used on mobile networks and devices with constrained
battery and connectivity; performance and resilience are core to the product working at
all, not optional polish.

### V. Security & Data Privacy
Personally identifiable information and location data MUST be handled according to the
principle of least privilege: collected only when needed for a stated feature, stored
only as long as needed, and never logged in plaintext. All external inputs (user input,
third-party APIs, deep links) MUST be validated and sanitized at the boundary. Secrets
and credentials MUST NOT be committed to the repository, and MUST be sourced from a
secrets manager or environment configuration instead.
**Rationale**: Mobility applications inherently process sensitive location and personal
data; a breach or misuse has both regulatory consequences and direct user safety
implications.

## Additional Constraints

Technology stack, target platforms (iOS/Android/web), and specific regulatory or
compliance regimes (e.g., GDPR for EU users) have not yet been fixed for this project.
Until they are, any implementation choice MUST be justified in its own plan/spec rather
than assumed from this constitution. This section MUST be amended via
`/speckit-constitution` as soon as the stack and target platforms are decided, so that
platform-specific constraints (offline support, push notification policy, map provider,
payment provider, minimum OS versions) can be made explicit and enforceable.

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

**Version**: 1.0.0 | **Ratified**: 2026-08-20 | **Last Amended**: 2026-08-20
