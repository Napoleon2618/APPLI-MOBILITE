---

description: "Task list for feature implementation"
---

# Tasks: Navigation par 3 modes vers les séances d'exercices

**Input**: Design documents from `/specs/001-exercise-navigation-modes/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. The constitution (Principle II, NON-NEGOTIABLE) mandates test-first
development for this project, so test tasks are part of every phase below, not optional.

**Organization**: Tasks are grouped by user story (from spec.md) to enable independent
implementation and testing of each story. Authentication (login/signup/password reset) is
infrastructure required by every story rather than a story of its own in spec.md, so it
lives in the Foundational phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story this task belongs to (US1–US5); Setup, Foundational and
  Polish tasks carry no story label
- File paths are relative to the repository root, per `plan.md`'s Project Structure
  (`mobile/` = Flutter app, `backend/supabase/` = migrations/seed/config)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization for the Flutter app and the Supabase backend config.

- [ ] T001 Create project structure per `plan.md` (`mobile/`, `backend/supabase/`) at the repository root
- [ ] T002 [P] Initialize the Flutter project in `mobile/` with dependencies: `supabase_flutter`, `drift`, `sqflite`, `go_router`, `flutter_lints` (`mobile/pubspec.yaml`)
- [ ] T003 [P] Initialize the local Supabase project in `backend/supabase/` (`supabase init`, `backend/supabase/config.toml`)
- [ ] T004 [P] Configure lint/format rules in `mobile/analysis_options.yaml` (Principle I — code quality gate)
- [ ] T005 [P] Set up environment configuration for the Supabase URL/anon key in `mobile/lib/core/config/env.dart` and `mobile/.env.example`, ensuring no secret is committed (Principle V)

**Checkpoint**: Project scaffolding exists and builds; ready for Foundational work.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema, RLS isolation, auth, theming, routing and offline cache that
every user story depends on. **No user story work may begin before this phase is complete.**

- [ ] T006 Create migration for `coach` table in `backend/supabase/migrations/0001_coach.sql` (per `data-model.md`)
- [ ] T007 Create migration for `client` table (FK `coach_id`) in `backend/supabase/migrations/0002_client.sql`
- [ ] T008 [P] Create migration for `body_zone` table in `backend/supabase/migrations/0003_body_zone.sql`
- [ ] T009 [P] Create migration for `pain_sign` table in `backend/supabase/migrations/0004_pain_sign.sql`
- [ ] T010 Create migration for `exercise` table, including `youtube_video_url`, in `backend/supabase/migrations/0005_exercise.sql`
- [ ] T011 [P] Create migration for `exercise_body_zone` association table in `backend/supabase/migrations/0006_exercise_body_zone.sql`
- [ ] T012 [P] Create migration for `exercise_pain_sign` association table in `backend/supabase/migrations/0007_exercise_pain_sign.sql`
- [ ] T013 Create migration for `session` table in `backend/supabase/migrations/0008_session.sql`
- [ ] T014 Create migration for `session_exercise` association table (with `position`) in `backend/supabase/migrations/0009_session_exercise.sql`
- [ ] T015 Create migration for `daily_formula` table (unique `coach_id`+`date`) in `backend/supabase/migrations/0010_daily_formula.sql`
- [ ] T016 Create migration for `session_log` table in `backend/supabase/migrations/0011_session_log.sql`
- [ ] T017 Write RLS policies for `coach`/`client` tables in `backend/supabase/migrations/0012_rls_coach_client.sql` (per `contracts/data-access.md`)
- [ ] T018 Write RLS policies for content tables (`body_zone`, `pain_sign`, `exercise`, `session`, `daily_formula`) in `backend/supabase/migrations/0013_rls_content.sql`
- [ ] T019 Write RLS policies and same-coach consistency checks for association tables in `backend/supabase/migrations/0014_rls_associations.sql`
- [ ] T020 Write RLS policies for `session_log` in `backend/supabase/migrations/0015_rls_session_log.sql`
- [ ] T021 [P] Write RLS isolation test scenarios in `backend/supabase/tests/rls_isolation_test.sql` (multi-coach isolation, per `contracts/data-access.md`)
- [ ] T022 [P] Write local-dev seed data in `backend/supabase/seed/seed.sql` (coach, client, zones, signs, exercises, session, daily formula — per `quickstart.md` prerequisites)
- [ ] T023 Configure the Supabase Auth password-reset email template in `backend/supabase/config.toml` / `backend/supabase/templates/recovery.html` (FR-020)
- [ ] T024 Wire the Flutter app entrypoint and Supabase client initialization in `mobile/lib/main.dart`
- [ ] T025 [P] Implement theme tokens for light/dark mode and the "sport intense x nature organique" identity in `mobile/lib/core/theme/app_theme.dart` (FR-011, FR-012)
- [ ] T026 [P] Implement the local SQLite cache schema (drift) in `mobile/lib/core/offline/local_database.dart` (Principle IV)
- [ ] T027 [P] Implement the offline sync queue for deferred writes (e.g. session completions) in `mobile/lib/core/offline/sync_queue.dart`
- [ ] T028 Implement auth session state (current user, role, coach_id) in `mobile/lib/features/auth/auth_state.dart`
- [ ] T029 Build the login screen (email + password) in `mobile/lib/features/auth/login_screen.dart` (FR-019)
- [ ] T030 [P] Build the client signup screen (email, password, coach rattachement) in `mobile/lib/features/auth/signup_screen.dart` (FR-018, FR-021)
- [ ] T031 [P] Build the forgot/reset-password screens in `mobile/lib/features/auth/reset_password_screen.dart` (FR-020)
- [ ] T032 Implement `go_router` with a role-based route guard (coach vs. client) in `mobile/lib/core/router/app_router.dart` (FR-010)
- [ ] T033 [P] Define Dart data models for all entities in `mobile/lib/data/models/` (`coach.dart`, `client.dart`, `body_zone.dart`, `pain_sign.dart`, `exercise.dart`, `session.dart`, `daily_formula.dart`, `session_log.dart`)
- [ ] T034 Implement the base repository abstraction (Supabase remote + local cache fallback) in `mobile/lib/data/repositories/base_repository.dart`
- [ ] T035 [P] Widget test: unauthenticated user is routed to the login screen, in `mobile/test/widget/auth_routing_test.dart`
- [ ] T036 [P] Integration test: login, wrong-password error, and password-reset flow (quickstart Scenario 6) in `mobile/test/integration/auth_flow_test.dart`

**Checkpoint**: Schema, RLS isolation, auth, theming, routing and offline cache are in
place and tested. All five user stories can now be built independently on top of this.

---

## Phase 3: User Story 1 - Suivre la formule du jour (Priority: P1) 🎯 MVP

**Goal**: A client opens the app and is immediately shown a ready-to-follow session, with
no selection step, and can complete it end to end.

**Independent Test**: With a seeded client account and coach content (including a daily
formula for today), open the app and verify a session is shown, can be played through to
completion, and produces a `session_log` entry.

- [ ] T037 [P] [US1] Integration test: daily-formula flow end-to-end, incl. zero-selection requirement (quickstart Scenario 1) in `mobile/test/integration/daily_formula_flow_test.dart`
- [ ] T038 [P] [US1] Widget test: home screen shows today's session without any selection step, in `mobile/test/widget/daily_formula_screen_test.dart`
- [ ] T039 [US1] Implement `DailyFormulaRepository` (fetch today's daily formula + ordered session exercises, scoped to the client's coach) in `mobile/lib/data/repositories/daily_formula_repository.dart`
- [ ] T040 [US1] Implement `SessionLogRepository.logCompletion` (writes `source_mode = 'daily_formula'`, offline-queued via T027) in `mobile/lib/data/repositories/session_log_repository.dart`
- [ ] T041 [US1] Build the daily-formula home screen (auto-loads today's session) in `mobile/lib/features/daily_formula/daily_formula_screen.dart`
- [ ] T042 [US1] Build the session player screen (step through ordered exercises) in `mobile/lib/features/daily_formula/session_player_screen.dart`
- [ ] T043 [US1] Build the session-completed confirmation view in `mobile/lib/features/daily_formula/session_complete_view.dart`
- [ ] T044 [US1] Handle the "no daily formula for today" fallback/empty state (FR-015, edge case) in `mobile/lib/features/daily_formula/daily_formula_screen.dart`

**Checkpoint**: User Story 1 is independently functional and demoable as the MVP.

---

## Phase 4: User Story 2 - Gérer le contenu en tant que coach (Priority: P2)

**Goal**: A coach can create and organize exercises, sessions, zone/pain-sign
associations, and the daily formula — and this content is never visible to another
coach's clients.

**Independent Test**: As a coach, create an exercise, associate it with a zone and a
pain sign, add it to a session, and designate that session as the daily formula for a
date — without depending on any client-side action. Then verify a second coach's client
never sees this content.

- [ ] T045 [P] [US2] Integration test: coach creates exercise + associations + session + daily formula (quickstart Scenario 2, steps 1-4) in `mobile/test/integration/coach_content_flow_test.dart`
- [ ] T046 [P] [US2] Integration test: multi-coach content isolation (quickstart Scenario 2, steps 5-6; spec US2 acceptance scenario 5) in `mobile/test/integration/multi_coach_isolation_test.dart`
- [ ] T047 [P] [US2] Widget test: a client-role user is blocked from coach-content routes (spec US2 acceptance scenario 4) in `mobile/test/widget/coach_route_guard_test.dart`
- [ ] T048 [P] [US2] Implement `ExerciseRepository` (CRUD, coach-scoped, incl. `youtube_video_url`) in `mobile/lib/data/repositories/exercise_repository.dart`
- [ ] T049 [P] [US2] Implement `BodyZoneRepository` (CRUD, coach-scoped) in `mobile/lib/data/repositories/body_zone_repository.dart`
- [ ] T050 [P] [US2] Implement `PainSignRepository` (CRUD, coach-scoped) in `mobile/lib/data/repositories/pain_sign_repository.dart`
- [ ] T051 [US2] Implement `SessionRepository` (CRUD + ordered exercise assignment, coach-scoped) in `mobile/lib/data/repositories/session_repository.dart`
- [ ] T052 [US2] Extend `DailyFormulaRepository` with `setForDate` (coach designates a session for a date) in `mobile/lib/data/repositories/daily_formula_repository.dart`
- [ ] T053 [US2] Build the coach content dashboard (role-gated entry point) in `mobile/lib/features/coach_content/coach_home_screen.dart`
- [ ] T054 [US2] Build the exercise create/edit form, including the `youtube_video_url` field, in `mobile/lib/features/coach_content/exercise_form_screen.dart`
- [ ] T055 [US2] Build the zone/pain-sign association picker within the exercise form in `mobile/lib/features/coach_content/exercise_associations_widget.dart`
- [ ] T056 [US2] Build the session builder screen (ordered exercise picker) in `mobile/lib/features/coach_content/session_form_screen.dart`
- [ ] T057 [P] [US2] Build the zone management screen (list/create/edit) in `mobile/lib/features/coach_content/body_zone_manage_screen.dart`
- [ ] T058 [P] [US2] Build the pain-sign management screen (list/create/edit) in `mobile/lib/features/coach_content/pain_sign_manage_screen.dart`
- [ ] T059 [US2] Build the daily-formula scheduling screen (assign a session to a date) in `mobile/lib/features/coach_content/daily_formula_scheduler_screen.dart`

**Checkpoint**: Coaches can fully manage their own content, isolated from other coaches;
User Stories 1 and 2 together are independently demoable.

---

## Phase 5: User Story 3 - Explorer les exercices par zone corporelle (Priority: P3)

**Goal**: A client picks a body zone and sees exercises targeted to it.

**Independent Test**: Select a body zone from the proposed list and verify only
exercises associated with that zone (by the coach) are shown, including the empty-state
message when a zone has no associated exercise.

- [ ] T060 [P] [US3] Integration test: browse by body zone, incl. empty-zone message (quickstart Scenario 3) in `mobile/test/integration/body_zone_browse_test.dart`
- [ ] T061 [US3] Extend `BodyZoneRepository` with `listExercisesForZone` (read, client-scoped to their coach) in `mobile/lib/data/repositories/body_zone_repository.dart`
- [ ] T062 [US3] Build the zone selection screen in `mobile/lib/features/body_zone/body_zone_select_screen.dart`
- [ ] T063 [US3] Build the zone results screen with the explicit empty-state message (FR-015) in `mobile/lib/features/body_zone/body_zone_results_screen.dart`
- [ ] T064 [P] [US3] Build the shared exercise detail screen/widget in `mobile/lib/features/body_zone/exercise_detail_screen.dart`

**Checkpoint**: Body-zone navigation works end to end, independently of US4/US5.

---

## Phase 6: User Story 4 - Explorer les exercices par signe de douleur (Priority: P4)

**Goal**: A client selects a plain-language pain sign from a predefined list and sees
adapted exercises, with no medical terminology anywhere in the flow.

**Independent Test**: Select a pain sign from the predefined, non-medical list and
verify the exercises shown match those associated by the coach, with no clinical term
anywhere in the selection flow.

- [ ] T065 [P] [US4] Integration test: browse by pain sign, predefined list only (no free text), no clinical terms present (quickstart Scenario 4) in `mobile/test/integration/pain_sign_browse_test.dart`
- [ ] T066 [US4] Extend `PainSignRepository` with `listExercisesForSign` (read, client-scoped to their coach) in `mobile/lib/data/repositories/pain_sign_repository.dart`
- [ ] T067 [US4] Build the pain-sign selection screen (predefined list, no free-text input — FR-016) in `mobile/lib/features/pain_sign/pain_sign_select_screen.dart`
- [ ] T068 [US4] Build the pain-sign results screen with empty-state + alternative suggestion (FR-015, spec US4 acceptance scenario 2) in `mobile/lib/features/pain_sign/pain_sign_results_screen.dart`

**Checkpoint**: Pain-sign navigation works end to end, independently of US3/US5.

---

## Phase 7: User Story 5 - Suivre sa progression (Priority: P5)

**Goal**: A client sees sessions followed and a regularity indicator, on one screen,
without excessive gamification.

**Independent Test**: Complete several sessions across several days, then verify a
regularity summary and session-followed count are visible on a single screen.

- [ ] T069 [P] [US5] Widget test: progress screen shows count + regularity on one screen, with limited gamification elements (quickstart Scenario 5) in `mobile/test/widget/progress_screen_test.dart`
- [ ] T070 [US5] Implement `ProgressRepository` (aggregate `session_log` into a count + regularity/streak) in `mobile/lib/data/repositories/progress_repository.dart`
- [ ] T071 [US5] Build the progress screen (single-screen summary, SC-004) in `mobile/lib/features/progress/progress_screen.dart`

**Checkpoint**: All five user stories are independently functional and demoable.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validate the cross-cutting requirements that span every story.

- [ ] T072 [P] Accessibility audit (contrast, tap-target size, screen-reader labels) across all screens per Principle III
- [ ] T073 [P] End-to-end offline validation pass (quickstart Scenario 7); fix any gap found in `mobile/lib/core/offline/`
- [ ] T074 [P] End-to-end theme-persistence validation pass (quickstart Scenario 8, SC-006)
- [ ] T075 Run the full `quickstart.md` validation pass across all 8 scenarios and fix any regression found
- [ ] T076 [P] Wire `flutter analyze` and `flutter test` into CI per the constitution's Development Workflow & Quality Gates
- [ ] T077 Update project setup docs (README or `mobile/README.md`) with `supabase start`, migrations, seed, and `flutter run` instructions

---

## Dependencies & Execution Order

- **Phase 1 (Setup)** has no dependencies — start here.
- **Phase 2 (Foundational)** depends on Phase 1 and **blocks every user story** (schema,
  RLS isolation, auth, theming, routing, offline cache are all shared prerequisites).
- **Phase 3 (US1)** depends only on Phase 2. Independently testable and shippable as the
  MVP.
- **Phase 4 (US2)** depends only on Phase 2. Independent of US1, but in practice US1 is
  more convincing to demo once US2 has produced real content (both can be built in
  either order; sequencing US1 → US2 here purely reflects spec.md priority).
- **Phase 5 (US3)**, **Phase 6 (US4)**, **Phase 7 (US5)** each depend only on Phase 2 and
  on the content created via US2 existing at test time (seed data or US2 already built) —
  they do not depend on each other or on US1.
- **Phase 8 (Polish)** depends on all user stories being complete.

```text
Setup (P1) → Foundational (P2, BLOCKS ALL) → US1 (P1) ─┐
                                            → US2 (P2) ─┤
                                            → US3 (P3) ─┼→ Polish
                                            → US4 (P4) ─┤
                                            → US5 (P5) ─┘
```

## Parallel Execution Examples

**Within Foundational (Phase 2)**, after the schema-dependent chain (T006→T007,
T010→T011/T012, T013→T014, all before T015/T016) is done, these are independent:

```text
T021 [P] RLS isolation test scenarios (backend/supabase/tests/)
T022 [P] Seed data (backend/supabase/seed/seed.sql)
T025 [P] Theme tokens (mobile/lib/core/theme/)
T026 [P] Local SQLite cache schema (mobile/lib/core/offline/)
T030 [P] Signup screen (mobile/lib/features/auth/signup_screen.dart)
T031 [P] Reset-password screens (mobile/lib/features/auth/reset_password_screen.dart)
T033 [P] Dart data models (mobile/lib/data/models/)
```

**Once Phase 2 is complete**, US1, US2, US3, US4 and US5 can be assigned to different
developers/agents and built in parallel, since none of their repositories or screens
share a file:

```text
Developer A: Phase 3 (US1) — T037-T044
Developer B: Phase 4 (US2) — T045-T059
Developer C: Phase 5 (US3) — T060-T064  (needs US2 content or seed data to test against)
Developer D: Phase 6 (US4) — T065-T068  (needs US2 content or seed data to test against)
Developer E: Phase 7 (US5) — T069-T071  (needs US1 or seed session_log rows to test against)
```

**Within US2**, the four repository tasks are independent of each other:

```text
T048 [P] ExerciseRepository
T049 [P] BodyZoneRepository
T050 [P] PainSignRepository
(T051 SessionRepository depends on Exercise existing conceptually, but is a distinct file)
```

## Implementation Strategy

**MVP first**: Complete Phase 1 (Setup) → Phase 2 (Foundational) → Phase 3 (US1). This
delivers the app's core promise (open the app, follow today's session) and is
independently demoable, per spec.md's own P1 rationale.

**Incremental delivery**: Add Phase 4 (US2) next — without it, US1 has no way to get
real content beyond seed data, and it is the direct prerequisite for US3/US4's content to
exist in a non-seeded environment. Then US3, US4 and US5 can be delivered in any order
(spec.md priority order P3 → P4 → P5 is a reasonable default) since each is independently
testable against existing coach content. Close with Phase 8 (Polish) once all five
stories are in.
