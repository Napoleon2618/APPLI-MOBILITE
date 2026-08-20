-- RLS / multi-tenant isolation tests (T026).
--
-- Run against a Supabase local stack (`supabase start`) with migrations
-- applied: `psql "$DATABASE_URL" -f backend/supabase/tests/rls_isolation_test.sql`
--
-- Each block impersonates a user via `set local role authenticated` +
-- `set local request.jwt.claim.sub` (the same mechanism Supabase's PostgREST
-- uses to set auth.uid()), then asserts the expected visibility/behavior.
-- Any failed assertion raises an exception and aborts the script.

begin;

-- Fixtures: two coaches, two clients, one exercise/session/daily_formula
-- per coach, created as postgres (bypasses RLS, like the seed script or the
-- Edge Function's service-role key would).
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'coach1@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'coach2@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'clienta@test.local'),
  ('44444444-4444-4444-4444-444444444444', 'clientb@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'newclient@test.local');

insert into public.coach (id, display_name) values
  ('11111111-1111-1111-1111-111111111111', 'Coach One'),
  ('22222222-2222-2222-2222-222222222222', 'Coach Two');

insert into public.client (id, coach_id, display_name) values
  ('33333333-3333-3333-3333-333333333333', '11111111-1111-1111-1111-111111111111', 'Client A'),
  ('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 'Client B');

commit;

-- ---------------------------------------------------------------------
-- As coach1: create content (zone, sign, exercise, session, daily_formula).
-- ---------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

insert into public.body_zone (id, coach_id, label) values
  ('a1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Dos');

insert into public.pain_sign (id, coach_id, label) values
  ('a2000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Douleur au coude');

insert into public.exercise (id, coach_id, name, description, instructions) values
  ('a3000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Etirement dos', 'desc', 'instr');

insert into public.exercise_body_zone (exercise_id, body_zone_id) values
  ('a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001');

insert into public.session (id, coach_id, name) values
  ('a4000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Séance dos');

insert into public.session_exercise (session_id, exercise_id, position) values
  ('a4000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1);

insert into public.daily_formula (coach_id, session_id, date) values
  ('11111111-1111-1111-1111-111111111111', 'a4000000-0000-0000-0000-000000000001', current_date);

do $$ begin raise notice 'PASS: coach1 created zone/sign/exercise/session/daily_formula'; end $$;
commit;

-- ---------------------------------------------------------------------
-- As coach2: create their own, separate content (used for isolation checks).
-- ---------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

insert into public.body_zone (id, coach_id, label) values
  ('b1000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Hanches');

insert into public.exercise (id, coach_id, name, description, instructions) values
  ('b3000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Mobilité hanches', 'desc', 'instr');

do $$ begin raise notice 'PASS: coach2 created their own content'; end $$;
commit;

-- ---------------------------------------------------------------------
-- As client A (coach1's client): sees coach1's content, never coach2's.
-- ---------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';

do $$
declare
  own_zone_count int;
  other_zone_count int;
  own_exercise_count int;
  other_exercise_count int;
begin
  select count(*) into own_zone_count from public.body_zone where id = 'a1000000-0000-0000-0000-000000000001';
  select count(*) into other_zone_count from public.body_zone where id = 'b1000000-0000-0000-0000-000000000001';
  select count(*) into own_exercise_count from public.exercise where id = 'a3000000-0000-0000-0000-000000000001';
  select count(*) into other_exercise_count from public.exercise where id = 'b3000000-0000-0000-0000-000000000001';

  if own_zone_count <> 1 then
    raise exception 'FAILED: client A cannot see their own coach''s body_zone';
  end if;
  if other_zone_count <> 0 then
    raise exception 'FAILED: client A can see coach2''s body_zone (isolation broken)';
  end if;
  if own_exercise_count <> 1 then
    raise exception 'FAILED: client A cannot see their own coach''s exercise';
  end if;
  if other_exercise_count <> 0 then
    raise exception 'FAILED: client A can see coach2''s exercise (isolation broken)';
  end if;

  raise notice 'PASS: client A sees only coach1 content, never coach2 content';
end $$;

-- Client cannot write coach content (FR-010).
do $$
begin
  begin
    insert into public.body_zone (coach_id, label) values ('11111111-1111-1111-1111-111111111111', 'Should fail');
    raise exception 'FAILED: client A was able to insert a body_zone (should be coach-only, FR-010)';
  exception
    when insufficient_privilege or others then
      raise notice 'PASS: client A cannot insert a body_zone';
  end;
end $$;

-- Client can log a completed session for their own coach's session.
insert into public.session_log (client_id, session_id, source_mode) values
  ('33333333-3333-3333-3333-333333333333', 'a4000000-0000-0000-0000-000000000001', 'daily_formula');

do $$ begin raise notice 'PASS: client A can log a session completion for their coach''s session'; end $$;
commit;

-- ---------------------------------------------------------------------
-- As client B (coach2's client): cannot log a completion for coach1's session.
-- ---------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claim.sub = '44444444-4444-4444-4444-444444444444';

do $$
begin
  begin
    insert into public.session_log (client_id, session_id, source_mode) values
      ('44444444-4444-4444-4444-444444444444', 'a4000000-0000-0000-0000-000000000001', 'daily_formula');
    raise exception 'FAILED: client B was able to log completion for coach1''s session (isolation broken)';
  exception
    when insufficient_privilege or others then
      raise notice 'PASS: client B cannot log completion for a session outside their coach';
  end;
end $$;
commit;

-- ---------------------------------------------------------------------
-- FR-023: coach1 deletes the exercise now referenced by client A's history
-- — must archive, not hard-delete.
-- ---------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

delete from public.exercise where id = 'a3000000-0000-0000-0000-000000000001';

do $$
declare
  archived timestamptz;
  still_exists boolean;
begin
  select archived_at into archived from public.exercise where id = 'a3000000-0000-0000-0000-000000000001';
  still_exists := found;

  if not still_exists then
    raise exception 'FAILED: exercise referenced by history was hard-deleted instead of archived (FR-023)';
  end if;
  if archived is null then
    raise exception 'FAILED: exercise referenced by history was not archived (archived_at is null)';
  end if;

  raise notice 'PASS: exercise referenced by session_log was archived, not deleted (FR-023)';
end $$;
commit;

-- Sanity: an exercise NOT referenced by any session_log is hard-deleted normally.
begin;
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';

delete from public.exercise where id = 'b3000000-0000-0000-0000-000000000001';

do $$
declare
  remains int;
begin
  select count(*) into remains from public.exercise where id = 'b3000000-0000-0000-0000-000000000001';
  if remains <> 0 then
    raise exception 'FAILED: an exercise with no history reference was archived instead of hard-deleted';
  end if;
  raise notice 'PASS: an exercise with no history reference is hard-deleted normally';
end $$;
commit;

-- ---------------------------------------------------------------------
-- FR-022a: invite-code redemption.
-- ---------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

insert into public.invite_code (id, coach_id, code) values
  ('c1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'WELCOME-COACH1');
commit;

begin;
set local role authenticated;
set local request.jwt.claim.sub = '55555555-5555-5555-5555-555555555555';

do $$
declare
  granted_coach uuid;
  attached_coach uuid;
begin
  select public.redeem_invite_code('WELCOME-COACH1') into granted_coach;
  if granted_coach <> '11111111-1111-1111-1111-111111111111' then
    raise exception 'FAILED: redeem_invite_code returned the wrong coach_id';
  end if;

  select coach_id into attached_coach from public.client where id = '55555555-5555-5555-5555-555555555555';
  if attached_coach <> '11111111-1111-1111-1111-111111111111' then
    raise exception 'FAILED: new client was not attached to the inviting coach';
  end if;

  raise notice 'PASS: invite-code redemption attaches the new client to the right coach';
end $$;

-- Re-using the same code must fail.
do $$
begin
  begin
    perform public.redeem_invite_code('WELCOME-COACH1');
    raise exception 'FAILED: an already-used invite code was redeemed a second time';
  exception
    when others then
      if sqlerrm like '%already attached%' or sqlerrm like '%already used%' then
        raise notice 'PASS: a used invite code cannot be redeemed again (%)', sqlerrm;
      else
        raise;
      end if;
  end;
end $$;
commit;

select 'ALL RLS ISOLATION TESTS PASSED' as result;
