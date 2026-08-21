alter table public.exercise_body_zone enable row level security;
alter table public.exercise_pain_sign enable row level security;
alter table public.session_exercise enable row level security;

-- exercise_body_zone: scoped via the parent exercise's coach_id.
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

-- exercise_pain_sign: same shape as above.
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

-- session_exercise: scoped via the parent session's coach_id.
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

-- No UPDATE policy for exercise_body_zone / exercise_pain_sign: association
-- rows are only ever inserted or deleted, never updated in place.
