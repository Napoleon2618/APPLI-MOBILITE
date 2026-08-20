alter table public.session_log enable row level security;

-- A client reads their own history.
create policy session_log_select_self on public.session_log
  for select to authenticated
  using (client_id = auth.uid());

-- A coach reads the history of the clients attached to them.
create policy session_log_select_by_coach on public.session_log
  for select to authenticated
  using (client_id in (select id from public.client where coach_id = auth.uid()));

-- A client can only log a completion for themselves, and only for a
-- session that belongs to their own coach.
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

-- No UPDATE/DELETE policy: session_log is write-once (data-model.md).
