alter table public.coach enable row level security;
alter table public.client enable row level security;

-- coach: a coach reads/updates their own row.
create policy coach_select_self on public.coach
  for select
  to authenticated
  using (id = auth.uid());

-- coach: a client reads the coach they are attached to (display_name etc.
-- are not sensitive, so full-row read is granted rather than a
-- column-restricted view, per Principle I — avoid unnecessary complexity).
create policy coach_select_by_client on public.coach
  for select
  to authenticated
  using (id = (select coach_id from public.client where id = auth.uid()));

create policy coach_update_self on public.coach
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- client: a client reads/updates their own row.
create policy client_select_self on public.client
  for select
  to authenticated
  using (id = auth.uid());

-- client: a coach reads the clients attached to them.
create policy client_select_by_coach on public.client
  for select
  to authenticated
  using (coach_id = auth.uid());

create policy client_update_self on public.client
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- FR-021 defense in depth: coach_id must not be changeable by the client
-- after creation, even if an UPDATE policy above would otherwise allow it.
revoke update (coach_id) on public.client from authenticated;

-- No INSERT policy for coach/client: both are only ever created through the
-- privileged provisioning paths (redeem_invite_code, create-client-account
-- Edge Function), which run with elevated privileges and bypass RLS —
-- see 0018_fn_redeem_invite_code.sql and contracts/auth.md.
