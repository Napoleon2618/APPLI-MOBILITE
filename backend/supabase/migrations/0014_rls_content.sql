-- Helper: resolves the coach_id scope for the current authenticated user,
-- whether they are the coach themselves or one of that coach's clients.
-- SECURITY DEFINER so it can be used safely inside RLS policies without
-- recursive-policy-evaluation surprises (standard Supabase RLS pattern).
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

-- Content tables (body_zone, pain_sign, exercise, session, daily_formula)
-- all share the same shape of policy: any authenticated user scoped to a
-- coach (the coach themselves, or one of their clients) can SELECT; only
-- the owning coach can INSERT/UPDATE/DELETE their own rows.
--
-- NOTE on `exercise`: this SELECT policy does not filter archived_at — an
-- archived exercise is not secret, only excluded from active-list *queries*
-- at the application layer, so a client's session history can still resolve
-- it (contracts/data-access.md, FR-023).
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
