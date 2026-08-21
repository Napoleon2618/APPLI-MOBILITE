-- THERAFORMY — consolidated schema for pasting into the Supabase Dashboard's
-- SQL Editor (Dashboard → SQL Editor → New query), as an alternative to
-- `supabase db push`. This is migrations 0001-0018 concatenated, in order,
-- unchanged in substance.
--
-- Safe to run more than once: every statement is idempotent (CREATE TABLE
-- IF NOT EXISTS, CREATE OR REPLACE FUNCTION, DROP POLICY IF EXISTS before
-- every CREATE POLICY, etc.), so re-running this whole script after a
-- partial failure — or just to double-check — will not error or duplicate
-- anything. Run this BEFORE 02_seed.sql (in backend/supabase/seed/seed.sql).
--
-- The whole script runs as one transaction: if anything fails partway,
-- nothing from this run is kept.

begin;

-- ============================================================
-- 0001_coach.sql
-- ============================================================
create extension if not exists pgcrypto;

create table if not exists public.coach (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

comment on table public.coach is
  'A coach account (admin/content role), owner of its own content space (data-model.md).';

-- ============================================================
-- 0002_client.sql
-- ============================================================
create table if not exists public.client (
  id uuid primary key references auth.users (id) on delete cascade,
  coach_id uuid not null references public.coach (id) on delete restrict,
  display_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists client_coach_id_idx on public.client (coach_id);

comment on table public.client is
  'A client account (consultation role), attached to exactly one coach (FR-021).';
comment on column public.client.coach_id is
  'Fixed at creation, not modifiable by the client afterwards (FR-021).';

-- ============================================================
-- 0003_body_zone.sql
-- ============================================================
create table if not exists public.body_zone (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now()
);

create index if not exists body_zone_coach_id_idx on public.body_zone (coach_id);

comment on table public.body_zone is
  'Anatomical location category defined by a coach (e.g. back, shoulders, hips).';

-- ============================================================
-- 0004_pain_sign.sql
-- ============================================================
create table if not exists public.pain_sign (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now()
);

create index if not exists pain_sign_coach_id_idx on public.pain_sign (coach_id);

comment on table public.pain_sign is
  'Plain-language, non-medical pain description defined by a coach (FR-009, FR-016).';

-- ============================================================
-- 0005_exercise.sql
-- ============================================================
create table if not exists public.exercise (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  name text not null,
  description text not null,
  instructions text not null,
  youtube_video_url text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists exercise_coach_id_idx on public.exercise (coach_id);
create index if not exists exercise_active_idx on public.exercise (coach_id) where archived_at is null;

comment on table public.exercise is
  'A mobility/stretching exercise created by a coach.';
comment on column public.exercise.youtube_video_url is
  'Demonstration video hosted on YouTube; no video file is stored in Supabase Storage (data-model.md).';
comment on column public.exercise.archived_at is
  'Set instead of a hard delete when the exercise is referenced by a session_log (FR-023). Terminal state, not reversible in this spec.';

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists exercise_set_updated_at on public.exercise;
create trigger exercise_set_updated_at
  before update on public.exercise
  for each row
  execute function public.set_updated_at();

-- ============================================================
-- 0006_exercise_body_zone.sql
-- ============================================================
create table if not exists public.exercise_body_zone (
  exercise_id uuid not null references public.exercise (id) on delete cascade,
  body_zone_id uuid not null references public.body_zone (id) on delete cascade,
  primary key (exercise_id, body_zone_id)
);

comment on table public.exercise_body_zone is
  'Many-to-many association between exercise and body_zone (data-model.md).';

create or replace function public.check_exercise_body_zone_same_coach()
returns trigger
language plpgsql
as $$
declare
  exercise_coach uuid;
  zone_coach uuid;
begin
  select coach_id into exercise_coach from public.exercise where id = new.exercise_id;
  select coach_id into zone_coach from public.body_zone where id = new.body_zone_id;
  if exercise_coach is null or zone_coach is null or exercise_coach <> zone_coach then
    raise exception 'exercise and body_zone must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists exercise_body_zone_same_coach on public.exercise_body_zone;
create trigger exercise_body_zone_same_coach
  before insert or update on public.exercise_body_zone
  for each row
  execute function public.check_exercise_body_zone_same_coach();

-- ============================================================
-- 0007_exercise_pain_sign.sql
-- ============================================================
create table if not exists public.exercise_pain_sign (
  exercise_id uuid not null references public.exercise (id) on delete cascade,
  pain_sign_id uuid not null references public.pain_sign (id) on delete cascade,
  primary key (exercise_id, pain_sign_id)
);

comment on table public.exercise_pain_sign is
  'Many-to-many association between exercise and pain_sign (data-model.md).';

create or replace function public.check_exercise_pain_sign_same_coach()
returns trigger
language plpgsql
as $$
declare
  exercise_coach uuid;
  sign_coach uuid;
begin
  select coach_id into exercise_coach from public.exercise where id = new.exercise_id;
  select coach_id into sign_coach from public.pain_sign where id = new.pain_sign_id;
  if exercise_coach is null or sign_coach is null or exercise_coach <> sign_coach then
    raise exception 'exercise and pain_sign must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists exercise_pain_sign_same_coach on public.exercise_pain_sign;
create trigger exercise_pain_sign_same_coach
  before insert or update on public.exercise_pain_sign
  for each row
  execute function public.check_exercise_pain_sign_same_coach();

-- ============================================================
-- 0008_session.sql
-- ============================================================
create table if not exists public.session (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create index if not exists session_coach_id_idx on public.session (coach_id);

comment on table public.session is
  'An ordered set of exercises created by a coach.';

-- ============================================================
-- 0009_session_exercise.sql
-- ============================================================
create table if not exists public.session_exercise (
  session_id uuid not null references public.session (id) on delete cascade,
  exercise_id uuid not null references public.exercise (id) on delete cascade,
  position integer not null,
  primary key (session_id, exercise_id),
  unique (session_id, position)
);

comment on table public.session_exercise is
  'Ordered many-to-many association between session and exercise (data-model.md).';
comment on column public.session_exercise.position is
  'Execution order within the session.';

create or replace function public.check_session_exercise_same_coach()
returns trigger
language plpgsql
as $$
declare
  session_coach uuid;
  exercise_coach uuid;
begin
  select coach_id into session_coach from public.session where id = new.session_id;
  select coach_id into exercise_coach from public.exercise where id = new.exercise_id;
  if session_coach is null or exercise_coach is null or session_coach <> exercise_coach then
    raise exception 'session and exercise must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists session_exercise_same_coach on public.session_exercise;
create trigger session_exercise_same_coach
  before insert or update on public.session_exercise
  for each row
  execute function public.check_session_exercise_same_coach();

-- ============================================================
-- 0010_daily_formula.sql
-- ============================================================
create table if not exists public.daily_formula (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  session_id uuid not null references public.session (id) on delete restrict,
  date date not null,
  unique (coach_id, date)
);

create index if not exists daily_formula_coach_id_idx on public.daily_formula (coach_id);

comment on table public.daily_formula is
  'Association between a date and a session for a given coach (FR-006). One per coach per date.';

create or replace function public.check_daily_formula_same_coach()
returns trigger
language plpgsql
as $$
declare
  session_coach uuid;
begin
  select coach_id into session_coach from public.session where id = new.session_id;
  if session_coach is null or session_coach <> new.coach_id then
    raise exception 'daily_formula.session_id must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists daily_formula_same_coach on public.daily_formula;
create trigger daily_formula_same_coach
  before insert or update on public.daily_formula
  for each row
  execute function public.check_daily_formula_same_coach();

-- ============================================================
-- 0011_session_log.sql
-- ============================================================
create table if not exists public.session_log (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.client (id) on delete cascade,
  session_id uuid not null references public.session (id) on delete restrict,
  completed_at timestamptz not null default now(),
  source_mode text not null check (source_mode in ('daily_formula', 'body_zone', 'pain_sign'))
);

create index if not exists session_log_client_id_idx on public.session_log (client_id);
create index if not exists session_log_session_id_idx on public.session_log (session_id);

comment on table public.session_log is
  'Record that a client followed a session on a given date (FR-013). Write-once, never updated.';
comment on column public.session_log.source_mode is
  'Which navigation mode led to this followed session — for later product analysis.';

create or replace function public.archive_instead_of_delete_exercise()
returns trigger
language plpgsql
as $$
declare
  is_referenced_by_history boolean;
begin
  select exists (
    select 1
    from public.session_exercise se
    join public.session_log sl on sl.session_id = se.session_id
    where se.exercise_id = old.id
  ) into is_referenced_by_history;

  if is_referenced_by_history then
    update public.exercise set archived_at = now() where id = old.id;
    return null;
  end if;

  return old;
end;
$$;

drop trigger if exists exercise_archive_instead_of_delete on public.exercise;
create trigger exercise_archive_instead_of_delete
  before delete on public.exercise
  for each row
  execute function public.archive_instead_of_delete_exercise();

-- ============================================================
-- 0012_invite_code.sql
-- ============================================================
create table if not exists public.invite_code (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  code text not null unique,
  created_at timestamptz not null default now(),
  used_at timestamptz,
  used_by_client_id uuid references public.client (id) on delete set null
);

create index if not exists invite_code_coach_id_idx on public.invite_code (coach_id);

comment on table public.invite_code is
  'Coach-generated token letting a client self-register and auto-attach to that coach (FR-022a).';
comment on column public.invite_code.used_at is
  'Set once, at first (and only) successful redemption via redeem_invite_code().';

-- ============================================================
-- 0013_rls_coach_client.sql
-- ============================================================
alter table public.coach enable row level security;
alter table public.client enable row level security;

drop policy if exists coach_select_self on public.coach;
create policy coach_select_self on public.coach
  for select
  to authenticated
  using (id = auth.uid());

drop policy if exists coach_select_by_client on public.coach;
create policy coach_select_by_client on public.coach
  for select
  to authenticated
  using (id = (select coach_id from public.client where id = auth.uid()));

drop policy if exists coach_update_self on public.coach;
create policy coach_update_self on public.coach
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

drop policy if exists client_select_self on public.client;
create policy client_select_self on public.client
  for select
  to authenticated
  using (id = auth.uid());

drop policy if exists client_select_by_coach on public.client;
create policy client_select_by_coach on public.client
  for select
  to authenticated
  using (coach_id = auth.uid());

drop policy if exists client_update_self on public.client;
create policy client_update_self on public.client
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

revoke update (coach_id) on public.client from authenticated;

-- ============================================================
-- 0014_rls_content.sql
-- ============================================================
create or replace function public.my_coach_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select id from public.coach where id = auth.uid()),
    (select coach_id from public.client where id = auth.uid())
  )
$$;

grant execute on function public.my_coach_id() to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['body_zone', 'pain_sign', 'exercise', 'session', 'daily_formula']
  loop
    execute format('alter table public.%I enable row level security', t);

    execute format('drop policy if exists %I_select on public.%I', t, t);
    execute format(
      'create policy %I_select on public.%I for select to authenticated using (coach_id = public.my_coach_id())',
      t, t
    );
    execute format('drop policy if exists %I_coach_insert on public.%I', t, t);
    execute format(
      'create policy %I_coach_insert on public.%I for insert to authenticated with check (coach_id = auth.uid())',
      t, t
    );
    execute format('drop policy if exists %I_coach_update on public.%I', t, t);
    execute format(
      'create policy %I_coach_update on public.%I for update to authenticated using (coach_id = auth.uid()) with check (coach_id = auth.uid())',
      t, t
    );
    execute format('drop policy if exists %I_coach_delete on public.%I', t, t);
    execute format(
      'create policy %I_coach_delete on public.%I for delete to authenticated using (coach_id = auth.uid())',
      t, t
    );
  end loop;
end $$;

-- ============================================================
-- 0015_rls_associations.sql
-- ============================================================
alter table public.exercise_body_zone enable row level security;
alter table public.exercise_pain_sign enable row level security;
alter table public.session_exercise enable row level security;

drop policy if exists exercise_body_zone_select on public.exercise_body_zone;
create policy exercise_body_zone_select on public.exercise_body_zone
  for select to authenticated
  using (exists (
    select 1 from public.exercise e
    where e.id = exercise_id and e.coach_id = public.my_coach_id()
  ));

drop policy if exists exercise_body_zone_coach_insert on public.exercise_body_zone;
create policy exercise_body_zone_coach_insert on public.exercise_body_zone
  for insert to authenticated
  with check (exists (
    select 1 from public.exercise e
    where e.id = exercise_id and e.coach_id = auth.uid()
  ));

drop policy if exists exercise_body_zone_coach_delete on public.exercise_body_zone;
create policy exercise_body_zone_coach_delete on public.exercise_body_zone
  for delete to authenticated
  using (exists (
    select 1 from public.exercise e
    where e.id = exercise_id and e.coach_id = auth.uid()
  ));

drop policy if exists exercise_pain_sign_select on public.exercise_pain_sign;
create policy exercise_pain_sign_select on public.exercise_pain_sign
  for select to authenticated
  using (exists (
    select 1 from public.exercise e
    where e.id = exercise_id and e.coach_id = public.my_coach_id()
  ));

drop policy if exists exercise_pain_sign_coach_insert on public.exercise_pain_sign;
create policy exercise_pain_sign_coach_insert on public.exercise_pain_sign
  for insert to authenticated
  with check (exists (
    select 1 from public.exercise e
    where e.id = exercise_id and e.coach_id = auth.uid()
  ));

drop policy if exists exercise_pain_sign_coach_delete on public.exercise_pain_sign;
create policy exercise_pain_sign_coach_delete on public.exercise_pain_sign
  for delete to authenticated
  using (exists (
    select 1 from public.exercise e
    where e.id = exercise_id and e.coach_id = auth.uid()
  ));

drop policy if exists session_exercise_select on public.session_exercise;
create policy session_exercise_select on public.session_exercise
  for select to authenticated
  using (exists (
    select 1 from public.session s
    where s.id = session_id and s.coach_id = public.my_coach_id()
  ));

drop policy if exists session_exercise_coach_insert on public.session_exercise;
create policy session_exercise_coach_insert on public.session_exercise
  for insert to authenticated
  with check (exists (
    select 1 from public.session s
    where s.id = session_id and s.coach_id = auth.uid()
  ));

drop policy if exists session_exercise_coach_update on public.session_exercise;
create policy session_exercise_coach_update on public.session_exercise
  for update to authenticated
  using (exists (
    select 1 from public.session s
    where s.id = session_id and s.coach_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.session s
    where s.id = session_id and s.coach_id = auth.uid()
  ));

drop policy if exists session_exercise_coach_delete on public.session_exercise;
create policy session_exercise_coach_delete on public.session_exercise
  for delete to authenticated
  using (exists (
    select 1 from public.session s
    where s.id = session_id and s.coach_id = auth.uid()
  ));

-- ============================================================
-- 0016_rls_session_log.sql
-- ============================================================
alter table public.session_log enable row level security;

drop policy if exists session_log_select_self on public.session_log;
create policy session_log_select_self on public.session_log
  for select to authenticated
  using (client_id = auth.uid());

drop policy if exists session_log_select_by_coach on public.session_log;
create policy session_log_select_by_coach on public.session_log
  for select to authenticated
  using (client_id in (select id from public.client where coach_id = auth.uid()));

drop policy if exists session_log_insert_self on public.session_log;
create policy session_log_insert_self on public.session_log
  for insert to authenticated
  with check (
    client_id = auth.uid()
    and exists (
      select 1
      from public.session s
      join public.client c on c.coach_id = s.coach_id
      where s.id = session_id and c.id = auth.uid()
    )
  );

-- ============================================================
-- 0017_rls_invite_code.sql
-- ============================================================
alter table public.invite_code enable row level security;

drop policy if exists invite_code_select_own on public.invite_code;
create policy invite_code_select_own on public.invite_code
  for select to authenticated
  using (coach_id = auth.uid());

drop policy if exists invite_code_insert_own on public.invite_code;
create policy invite_code_insert_own on public.invite_code
  for insert to authenticated
  with check (coach_id = auth.uid());

-- ============================================================
-- 0018_fn_redeem_invite_code.sql
-- ============================================================
create or replace function public.redeem_invite_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.invite_code%rowtype;
  v_caller uuid := auth.uid();
  v_caller_email text;
begin
  if v_caller is null then
    raise exception 'not authenticated';
  end if;

  if exists (select 1 from public.client where id = v_caller) then
    raise exception 'this account is already attached to a coach';
  end if;
  if exists (select 1 from public.coach where id = v_caller) then
    raise exception 'a coach account cannot redeem an invite code';
  end if;

  select * into v_invite from public.invite_code where code = p_code for update;

  if not found then
    raise exception 'invalid invite code';
  end if;
  if v_invite.used_at is not null then
    raise exception 'invite code already used';
  end if;

  select email into v_caller_email from auth.users where id = v_caller;

  insert into public.client (id, coach_id, display_name)
  values (v_caller, v_invite.coach_id, coalesce(v_caller_email, 'Client'));

  update public.invite_code
    set used_at = now(), used_by_client_id = v_caller
    where id = v_invite.id;

  return v_invite.coach_id;
end;
$$;

grant execute on function public.redeem_invite_code(text) to authenticated;

commit;
